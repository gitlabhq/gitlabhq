# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      class ReviewerResolver # rubocop:disable Graphql/ResolverType -- not a GraphQL resolver
        # Machine accounts that commit to SSOT docs but should never be pinged as "authors" can report `bot: false`.
        # GitLab machine-account handles conventionally end in `-bot`, so exclude both the explicit list and suffix.
        NON_PINGABLE_USERNAMES = %w[
          service-modelops-agent-principles-distiller
          gitlab-bot
        ].freeze
        NON_PINGABLE_USERNAME_SUFFIX = '-bot'

        # `Repository.commits(ref:, path:)` is `calls_gitaly!` and costs ~12 complexity against the API 250-point cap.
        # 13 aliases is the empirical ceiling, so batching at 10 fits a 15-source principle like `backend-ruby`.
        AUTHOR_LOOKUP_BATCH_SIZE = 10
        AUTHOR_LOOKUP_PAGE_SIZE = 100
        MAX_SSOT_AUTHORS = 3
        OWNER_TEAM_PAGE_SIZE = 100
        OWNER_TEAM_MAX_PAGES = 5

        OWNER_TEAM_MEMBERS_QUERY = <<~GRAPHQL.freeze
          query($fullPath: ID!, $after: String) {
            group(fullPath: $fullPath) {
              groupMembers(relations: [DIRECT], first: #{OWNER_TEAM_PAGE_SIZE}, after: $after) {
                nodes {
                  user {
                    id username bot state
                    status { availability }
                    reviewRequestedMergeRequests(state: opened) { count }
                  }
                }
                pageInfo { hasNextPage endCursor }
              }
            }
          }
        GRAPHQL

        def initialize(workflow:, distillation_base_sha:)
          @workflow = workflow
          @distillation_base_sha = distillation_base_sha
        end

        # Resolves people who changed the SSOT docs backing the given principles since each was last distilled.
        # The cap is shared by MR mentions and reviewer assignment so both route to the same people.
        # Best-effort: a GraphQL failure logs and contributes no authors rather than failing the MR.
        def ssot_authors(affected_entries)
          affected_entries.values.flat_map { |entry| ssot_authors_for_entry(entry) }
            .uniq { |author| author[:username] }
            .first(MAX_SSOT_AUTHORS)
        end

        # Resolves one available owner-team member when no SSOT author can be found.
        # Best-effort: CODEOWNERS remains the approval authority, so a failed lookup must not block publication.
        def owner_team_reviewer(team)
          group_handles, user_handles = team.to_s.split.partition { |handle| handle.include?('/') }
          members = group_handles.flat_map { |handle| group_members(handle) }
          members.concat(user_members(user_handles))
          members.min_by { |member| [member[:review_count], member[:username]] }
        end

        private

        attr_reader :workflow, :distillation_base_sha

        def group_members(handle)
          members = []
          after = nil

          OWNER_TEAM_MAX_PAGES.times do |page|
            data = group_members_page(handle, after)
            return warn_unresolvable_owner_team(handle) if data.nil? && page.zero?
            return warn_partial_owner_team_members(handle, members) unless data

            group = data['group']
            return warn_unresolvable_owner_team(handle) if group.nil? && page.zero?
            return warn_partial_owner_team_members(handle, members) unless group

            group_members = group['groupMembers'] || {}
            members.concat(group_members['nodes'].to_a.filter_map { |node| pingable_owner_team_member(node['user']) })

            page_info = group_members['pageInfo'] || {}
            return members unless page_info['hasNextPage']

            after = page_info['endCursor']
          end

          warn_truncated_owner_team_members(handle)
          members
        rescue StandardError => e
          warn Rainbow("WARNING: could not resolve owner team #{handle} (#{e.message})").yellow
          []
        end

        def group_members_page(handle, after)
          workflow.query_graphql(OWNER_TEAM_MEMBERS_QUERY, fullPath: handle.delete_prefix('@'), after: after)
        end

        def user_members(handles)
          return [] if handles.empty?

          data = workflow.query_graphql(<<~GRAPHQL, usernames: handles.map { |handle| handle.delete_prefix('@') })
            query($usernames: [String!]) {
              users(usernames: $usernames) {
                nodes {
                  id username bot state
                  status { availability }
                  reviewRequestedMergeRequests(state: opened) { count }
                }
              }
            }
          GRAPHQL
          return [] unless data

          data.dig('users', 'nodes').to_a.filter_map { |user| pingable_owner_team_member(user) }
        rescue StandardError => e
          warn Rainbow("WARNING: could not resolve owner team members (#{e.message})").yellow
          []
        end

        def warn_unresolvable_owner_team(handle)
          warn Rainbow("WARNING: could not resolve owner team #{handle}; leaving MR without a fallback reviewer").yellow
          []
        end

        def warn_partial_owner_team_members(handle, members)
          warn Rainbow("WARNING: could not fully resolve owner team #{handle}; " \
            'selecting from partial member list').yellow
          members
        end

        def warn_truncated_owner_team_members(handle)
          warn Rainbow("WARNING: #{handle} has more than #{OWNER_TEAM_MAX_PAGES * OWNER_TEAM_PAGE_SIZE} " \
            'direct members; ' \
            'selecting from partial member list').yellow
        end

        def pingable_owner_team_member(user)
          return unless user && user['bot'] != true && user['state'] == 'active'
          return if user.dig('status', 'availability') == 'BUSY'

          username = user['username'].to_s
          return if username.empty? || non_pingable_username?(username)

          id = user['id'].to_s.split('/').last
          return unless id.match?(/\A\d+\z/)

          { username: username, id: id.to_i, review_count: user.dig('reviewRequestedMergeRequests', 'count').to_i }
        end

        def non_pingable_username?(username)
          normalized_username = username.downcase
          NON_PINGABLE_USERNAMES.include?(normalized_username) ||
            normalized_username.end_with?(NON_PINGABLE_USERNAME_SUFFIX)
        end

        # Authors of commits touching this principle's SSOT paths in prior_sha..distillation_base_sha.
        # The range walk happens server-side, so the shallow CI clone does not limit it.
        # `Commit.author` resolves via `User.by_any_email(confirmed: true)`, so private and secondary emails match too.
        # Empty when no prior SHA is reachable (e.g. first distillation), no commits match, or the range cannot resolve.
        def ssot_authors_for_entry(affected_entry)
          return [] unless affected_entry

          prior_sha = affected_entry[:prior_sha]
          return [] if prior_sha.nil? || prior_sha.empty?

          sources = affected_entry[:changed_sources] || []
          baseline_path = affected_entry.dig(:config, 'baseline')
          paths = sources.map { |source| source['path'] }
          paths.unshift(baseline_path) if baseline_path
          return [] if paths.empty?

          commit_range = "#{prior_sha}..#{distillation_base_sha}"

          paths.each_slice(AUTHOR_LOOKUP_BATCH_SIZE).flat_map do |batch|
            pingable_authors_for_paths(commit_range, batch)
          end.uniq
        end

        # One GraphQL round trip per path batch, each an aliased `commits` field, to stay under the complexity limit.
        # Returns [] (logged) on any GraphQL failure, including an unreachable ref.
        def pingable_authors_for_paths(commit_range, paths)
          aliases = paths.each_with_index.to_h { |path, index| ["p#{index}", path] }
          path_vars = aliases.keys.map { |alias_name| "$path_#{alias_name}: String!" }.join(', ')

          query = <<~GRAPHQL
            query($fullPath: ID!, $range: String!, #{path_vars}) {
              project(fullPath: $fullPath) {
                repository {
                  #{aliases.keys.map { |alias_name| commits_alias_fragment(alias_name) }.join("\n")}
                }
              }
            }
          GRAPHQL

          variables = { fullPath: workflow.catalog_project_path, range: commit_range }
          aliases.each { |alias_name, path| variables["path_#{alias_name}"] = path }

          data = workflow.query_graphql(query, variables)
          return [] unless data

          repository = data.dig('project', 'repository') || {}
          aliases.flat_map do |alias_name, path|
            pingable_authors_from_commits(repository[alias_name], path)
          end.uniq
        end

        def commits_alias_fragment(alias_name)
          "#{alias_name}: commits(ref: $range, path: $path_#{alias_name}, first: #{AUTHOR_LOOKUP_PAGE_SIZE}) " \
            '{ nodes { author { id username bot } } pageInfo { hasNextPage } }'
        end

        # Extracts pingable authors from one `commits` connection: drops unlinked commits, bots, and deny-listed users.
        # Warns when the connection has more pages than AUTHOR_LOOKUP_PAGE_SIZE: pagination is not implemented here, so
        # authors beyond the first page are missed rather than pinged.
        def pingable_authors_from_commits(commits_connection, path)
          return [] unless commits_connection

          if commits_connection.dig('pageInfo', 'hasNextPage')
            warn Rainbow("WARNING: #{path} has more than #{AUTHOR_LOOKUP_PAGE_SIZE} commits in range; " \
              'some SSOT authors may not be pinged').yellow
          end

          nodes = commits_connection['nodes'] || []

          nodes.filter_map do |node|
            author = node['author']
            next unless author
            next if author['bot'] == true

            username = author['username'].to_s
            next if username.empty?
            next if non_pingable_username?(username)

            id = author['id'].to_s.split('/').last
            unless id.match?(/\A\d+\z/)
              warn Rainbow("WARNING: could not resolve reviewer ID for SSOT author @#{username}").yellow
              id = nil
            end

            { username: username, id: id&.to_i }
          end
        end
      end
    end
  end
end
