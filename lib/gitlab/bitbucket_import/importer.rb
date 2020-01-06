# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class Importer
      include Gitlab::ShellAdapter

      LABELS = [{ title: 'bug', color: '#FF0000' },
                { title: 'enhancement', color: '#428BCA' },
                { title: 'proposal', color: '#69D100' },
                { title: 'task', color: '#7F8C8D' }].freeze

      attr_reader :project, :client, :errors, :users

      def initialize(project)
        @project = project
        @client = Bitbucket::Client.new(project.import_data.credentials)
        @formatter = Gitlab::ImportFormatter.new
        @labels = {}
        @errors = []
        @users = {}
      end

      def execute
        import_wiki
        import_issues
        import_pull_requests
        handle_errors

        true
      end

      private

      def handle_errors
        return unless errors.any?

        project.import_state.update_column(:last_error, {
          message: 'The remote data could not be fully imported.',
          errors: errors
        }.to_json)
      end

      def store_pull_request_error(pull_request, ex)
        backtrace = Gitlab::BacktraceCleaner.clean_backtrace(ex.backtrace)
        error = { type: :pull_request, iid: pull_request.iid, errors: ex.message, trace: backtrace, raw_response: pull_request.raw }

        Gitlab::ErrorTracking.log_exception(ex, error)

        # Omit the details from the database to avoid blowing up usage in the error column
        error.delete(:trace)
        error.delete(:raw_response)

        errors << error
      end

      def gitlab_user_id(project, username)
        find_user_id(username) || project.creator_id
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_user_id(username)
        return unless username

        return users[username] if users.key?(username)

        users[username] = User.select(:id)
                              .joins(:identities)
                              .find_by("identities.extern_uid = ? AND identities.provider = 'bitbucket'", username)
                              .try(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def repo
        @repo ||= client.repo(project.import_source)
      end

      def import_wiki
        return if project.wiki.repository_exists?

        wiki = WikiFormatter.new(project)

        gitlab_shell.import_wiki_repository(project, wiki)
      rescue StandardError => e
        errors << { type: :wiki, errors: e.message }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def import_issues
        return unless repo.issues_enabled?

        create_labels

        client.issues(repo).each do |issue|
          description = ''
          description += @formatter.author_line(issue.author) unless find_user_id(issue.author)
          description += issue.description

          label_name = issue.kind
          milestone = issue.milestone ? project.milestones.find_or_create_by(title: issue.milestone) : nil

          gitlab_issue = project.issues.create!(
            iid: issue.iid,
            title: issue.title,
            description: description,
            state_id: Issue.available_states[issue.state],
            author_id: gitlab_user_id(project, issue.author),
            milestone: milestone,
            created_at: issue.created_at,
            updated_at: issue.updated_at
          )

          gitlab_issue.labels << @labels[label_name]

          import_issue_comments(issue, gitlab_issue) if gitlab_issue.persisted?
        rescue StandardError => e
          errors << { type: :issue, iid: issue.iid, errors: e.message }
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def import_issue_comments(issue, gitlab_issue)
        client.issue_comments(repo, issue.iid).each do |comment|
          # The note can be blank for issue service messages like "Changed title: ..."
          # We would like to import those comments as well but there is no any
          # specific parameter that would allow to process them, it's just an empty comment.
          # To prevent our importer from just crashing or from creating useless empty comments
          # we do this check.
          next unless comment.note.present?

          note = ''
          note += @formatter.author_line(comment.author) unless find_user_id(comment.author)
          note += comment.note

          begin
            gitlab_issue.notes.create!(
              project: project,
              note: note,
              author_id: gitlab_user_id(project, comment.author),
              created_at: comment.created_at,
              updated_at: comment.updated_at
            )
          rescue StandardError => e
            errors << { type: :issue_comment, iid: issue.iid, errors: e.message }
          end
        end
      end

      def create_labels
        LABELS.each do |label_params|
          label = ::Labels::FindOrCreateService.new(nil, project, label_params).execute(skip_authorization: true)
          if label.valid?
            @labels[label_params[:title]] = label
          else
            raise "Failed to create label \"#{label_params[:title]}\" for project \"#{project.full_name}\""
          end
        end
      end

      def import_pull_requests
        pull_requests = client.pull_requests(repo)

        pull_requests.each do |pull_request|
          description = ''
          description += @formatter.author_line(pull_request.author) unless find_user_id(pull_request.author)
          description += pull_request.description

          source_branch_sha = pull_request.source_branch_sha
          target_branch_sha = pull_request.target_branch_sha
          source_branch_sha = project.repository.commit(source_branch_sha)&.sha || source_branch_sha
          target_branch_sha = project.repository.commit(target_branch_sha)&.sha || target_branch_sha

          merge_request = project.merge_requests.create!(
            iid: pull_request.iid,
            title: pull_request.title,
            description: description,
            source_project: project,
            source_branch: pull_request.source_branch_name,
            source_branch_sha: source_branch_sha,
            target_project: project,
            target_branch: pull_request.target_branch_name,
            target_branch_sha: target_branch_sha,
            state: pull_request.state,
            author_id: gitlab_user_id(project, pull_request.author),
            created_at: pull_request.created_at,
            updated_at: pull_request.updated_at
          )

          import_pull_request_comments(pull_request, merge_request) if merge_request.persisted?
        rescue StandardError => e
          store_pull_request_error(pull_request, e)
        end
      end

      def import_pull_request_comments(pull_request, merge_request)
        comments = client.pull_request_comments(repo, pull_request.iid)

        inline_comments, pr_comments = comments.partition(&:inline?)

        import_inline_comments(inline_comments, pull_request, merge_request)
        import_standalone_pr_comments(pr_comments, merge_request)
      end

      def import_inline_comments(inline_comments, pull_request, merge_request)
        position_map = {}
        discussion_map = {}

        children, parents = inline_comments.partition(&:has_parent?)

        # The Bitbucket API returns threaded replies as parent-child
        # relationships. We assume that the child can appear in any order in
        # the JSON.
        parents.each do |comment|
          position_map[comment.iid] = build_position(merge_request, comment)
        end

        children.each do |comment|
          position_map[comment.iid] = position_map.fetch(comment.parent_id, nil)
        end

        inline_comments.each do |comment|
          attributes = pull_request_comment_attributes(comment)
          attributes[:discussion_id] = discussion_map[comment.parent_id] if comment.has_parent?

          attributes.merge!(
            position: position_map[comment.iid],
            type: 'DiffNote')

          note = merge_request.notes.create!(attributes)

          # We can't store a discussion ID until a note is created, so if
          # replies are created before the parent the discussion ID won't be
          # linked properly.
          discussion_map[comment.iid] = note.discussion_id
        rescue StandardError => e
          errors << { type: :pull_request, iid: comment.iid, errors: e.message }
        end
      end

      def build_position(merge_request, pr_comment)
        params = {
          diff_refs: merge_request.diff_refs,
          old_path: pr_comment.file_path,
          new_path: pr_comment.file_path,
          old_line: pr_comment.old_pos,
          new_line: pr_comment.new_pos
        }

        Gitlab::Diff::Position.new(params)
      end

      def import_standalone_pr_comments(pr_comments, merge_request)
        pr_comments.each do |comment|
          merge_request.notes.create!(pull_request_comment_attributes(comment))
        rescue StandardError => e
          errors << { type: :pull_request, iid: comment.iid, errors: e.message }
        end
      end

      def pull_request_comment_attributes(comment)
        {
          project: project,
          author_id: gitlab_user_id(project, comment.author),
          note: comment_note(comment),
          created_at: comment.created_at,
          updated_at: comment.updated_at
        }
      end

      def comment_note(comment)
        author = @formatter.author_line(comment.author) unless find_user_id(comment.author)

        author.to_s + comment.note.to_s
      end

      def log_base_data
        {
          class: self.class.name,
          project_id: project.id,
          project_path: project.full_path
        }
      end
    end
  end
end
