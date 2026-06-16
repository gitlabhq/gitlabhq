# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      module AutoMr
        # MR description has a 1 MB hard limit; multiple per-principle patches
        # may be embedded, so each must stay well under that.
        DIFF_MAX_LINES = 200
        DIFF_MAX_BYTES = 8_192

        def distillation_base_sha
          @distillation_base_sha ||= resolve_distillation_base_sha
        end

        # Returns [text, truncated?]. Caps at DIFF_MAX_LINES or DIFF_MAX_BYTES,
        # whichever hits first.
        def truncate_diff(text)
          lines = text.lines
          truncated = false

          if lines.size > DIFF_MAX_LINES
            lines = lines.first(DIFF_MAX_LINES)
            truncated = true
          end

          result = lines.join
          if result.bytesize > DIFF_MAX_BYTES
            # scrub: byteslice can split a multi-byte char; downstream JSON would blow up otherwise.
            result = result.byteslice(0, DIFF_MAX_BYTES).scrub
            result = result.sub(/[^\n]*\z/, '') # trim partial trailing line
            truncated = true
          end

          [result, truncated]
        end

        # Fans out the distilled changes into one MR per team group plus
        # a separate "tooling" MR for the global routing-table files. Each
        # team's MR touches only that team's distilled files, so CODEOWNERS
        # routes the approval to the right reviewers (the global tooling files
        # would otherwise pull every MR back to the broad `/.ai/` owners).
        #
        # Teams are published independently: one team's failure is logged and
        # the run continues with the rest, then a non-zero exit is raised at
        # the end so the scheduled job surfaces the partial failure.
        def create_branch_and_mr(distilled_contents, affected, auto_mr_cfg)
          # UTC date as identifier; same-day re-runs reuse each branch and
          # update the existing MR (see find_open_mr_iid).
          date = Time.now.utc.strftime('%Y%m%d')
          project_id = ENV.fetch(Env::CI_PROJECT_ID) do
            abort Rainbow("ERROR: #{Env::CI_PROJECT_ID} env var is required when --push is given").red
          end
          api_token = ENV.fetch(Env::GITLAB_API_TOKEN) do
            abort Rainbow("ERROR: #{Env::GITLAB_API_TOKEN} not set, cannot create MR").red
          end

          base_branch = workflow.default_branch

          # Fetch every prior SHA once up front so each team branch can embed
          # its SSOT diffs without re-fetching.
          prefetch_prior_shas!(affected)

          teams = manifest.group_principles_by_team(distilled_contents.keys)
          failures = []

          teams.each do |team, names|
            team_contents = distilled_contents.slice(*names)
            team_affected = affected.slice(*names)
            publish_team_branch(
              team, team_contents, team_affected, base_branch, project_id, api_token, date, auto_mr_cfg
            )
          rescue StandardError => e
            warn Rainbow("ERROR: team '#{team}' failed: #{e.message}").red
            cleanup_branch(base_branch, team_branch_name(auto_mr_cfg, date, team))
            failures << team
          end

          begin
            publish_tooling_branch(base_branch, project_id, api_token, date, auto_mr_cfg)
          rescue StandardError => e
            warn Rainbow("ERROR: tooling MR failed: #{e.message}").red
            cleanup_branch(base_branch, tooling_branch_name(auto_mr_cfg, date))
            failures << 'tooling'
          end

          return if failures.empty?

          abort Rainbow("\nERROR: #{failures.size} MR(s) failed: #{failures.join(', ')}").red
        end

        # Builds, pushes, and opens/updates a single team's MR. Raises on any
        # git/API failure so the caller can record the team and continue.
        def publish_team_branch(team, contents, affected, base_branch, project_id, api_token, date, auto_mr_cfg)
          branch = team_branch_name(auto_mr_cfg, date, team)

          checkout_fresh_branch(branch, base_branch)

          # Writes deferred to here so the publish branch is the only diff.
          paths_to_commit = contents.map do |name, content|
            manifest.principles_path(name).tap do |path|
              File.write(Workspace.safe_join(path), content)
            end
          end

          system('git', '-C', Workspace.path, 'add', '-f', *paths_to_commit, exception: true)

          # A same-day re-run can reset the branch to identical content; in
          # that case `git commit` would exit non-zero ("nothing to commit")
          # and the per-team rescue would record a spurious failure. Skip the
          # team MR instead (mirrors the guard in publish_tooling_branch).
          unless git_has_staged_changes?
            puts Rainbow("  #{team}: principles already up to date; skipping team MR.").faint
            cleanup_branch(base_branch, branch)
            return
          end

          commit_and_push(branch, project_id, api_token, <<~MSG.chomp)
        Update #{team} AI development principles from SSOT

        Updated: #{contents.keys.join(', ')}

        This commit was auto-generated by gitlab-ai-principles-distiller
        based on recent changes to development documentation.
          MSG

          title = "#{format(auto_mr_cfg['title_template'], date: date)} — #{team}"
          create_mr(branch, project_id, api_token, contents, affected, auto_mr_cfg, team: team, title: title)
        end

        # Builds, pushes, and opens/updates the tooling MR carrying the global
        # routing-table files (AGENTS.md, CLAUDE.md, both SKILL.md). These are
        # regenerated in-branch so they never leak into the per-team branches.
        def publish_tooling_branch(base_branch, project_id, api_token, date, auto_mr_cfg)
          branch = tooling_branch_name(auto_mr_cfg, date)

          checkout_fresh_branch(branch, base_branch)

          # Regenerate the global artifacts now that we're on the tooling
          # branch, so the diff lands here rather than in any team branch.
          regenerate_static_artifacts

          existing = Manifest::TOOLING_PATHS.select { |p| stageable_tooling_path?(p) }

          # `git add -f` with no paths errors out (and `exception: true` would
          # raise), so skip the tooling MR when none of the routing-table files
          # exist on disk (e.g. AGENTS.md is absent, so nothing was generated).
          if existing.empty?
            puts Rainbow('  No tooling files found on disk; skipping tooling MR.').faint
            cleanup_branch(base_branch, branch)
            return
          end

          system('git', '-C', Workspace.path, 'add', '-f', *existing, exception: true)

          unless git_has_staged_changes?
            puts Rainbow('  Tooling files already up to date; skipping tooling MR.').faint
            cleanup_branch(base_branch, branch)
            return
          end

          commit_and_push(branch, project_id, api_token, <<~MSG.chomp)
        Update AI principles routing tables (tooling)

        Regenerates AGENTS.md, CLAUDE.md, and the gitlab-coding-principles
        SKILL.md files from the principles manifest.

        This commit was auto-generated by gitlab-ai-principles-distiller.
          MSG

          title = "#{format(auto_mr_cfg['title_template'], date: date)} — tooling"
          create_tooling_mr(branch, project_id, api_token, auto_mr_cfg, title)
        end

        def team_branch_name(auto_mr_cfg, date, team)
          "#{auto_mr_cfg['branch_prefix']}-#{date}-#{manifest.team_slug(team)}"
        end

        def tooling_branch_name(auto_mr_cfg, date)
          "#{auto_mr_cfg['branch_prefix']}-#{date}-tooling"
        end

        # Branch off origin/<default_branch> (not the current HEAD) so the MR
        # diff contains only our files. The CI before_script fetches
        # origin/<default_branch> for us. `-B` resets the branch if a prior
        # team iteration left it around.
        def checkout_fresh_branch(branch, base_branch)
          base_ref = "origin/#{base_branch}"
          system('git', '-C', Workspace.path, 'checkout', '--no-track', '-B', branch, base_ref, exception: true)
        end

        def commit_and_push(branch, project_id, api_token, commit_msg)
          system('git', '-C', Workspace.path, 'commit', '-m', commit_msg, exception: true)
          # --force is safe here: the branch is auto-generated and always
          # rebuilt from origin/<default_branch>, so only our own prior
          # commit can be lost. (--force-with-lease would require a prefetch.)
          push_url = push_remote_url(project_id)
          env = git_push_env(api_token, push_url)
          system(env, 'git', '-C', Workspace.path, 'push', '--force', push_url,
            "#{branch}:#{branch}", exception: true)
        end

        def git_has_staged_changes?
          !system('git', '-C', Workspace.path, 'diff', '--cached', '--quiet')
        end

        # A tooling path is stageable only if it exists AND no directory
        # *within the workspace* on the way to it is a symlink. `git add`
        # refuses paths "beyond a symbolic link", which happens here because
        # some repos symlink `.agents/skills` -> `.claude/skills`: the file is
        # real but its canonical location is staged via the `.claude/...`
        # entry, so skipping the symlinked alias avoids the `exit 128` without
        # losing content.
        #
        # The comparison is anchored at the resolved workspace root so a
        # symlink *in the workspace path itself* (e.g. macOS `/tmp` ->
        # `/private/tmp`, or a CI runner mounting the workspace through a
        # symlink) does not cause every tooling path to be filtered out.
        def stageable_tooling_path?(relative_path)
          full = Workspace.safe_join(relative_path)
          return false unless File.exist?(full)

          dir = File.dirname(full)
          relative_dir = File.dirname(relative_path)
          workspace_path = File.realpath(Workspace.path)
          expected = relative_dir == '.' ? workspace_path : File.join(workspace_path, relative_dir)

          File.realpath(dir) == expected
        rescue Errno::ENOENT
          false
        end

        # Returns to the base branch, warning (rather than failing silently) if
        # the checkout does not succeed so a stuck working tree is visible.
        def checkout_base_or_warn(base_branch)
          return if system('git', '-C', Workspace.path, 'checkout', base_branch)

          warn Rainbow("  WARNING: checkout to #{base_branch} failed; " \
            'the working tree may still be on the publish branch').yellow
        end

        def cleanup_branch(base_branch, branch)
          base_branch ||= workflow.default_branch

          checkout_base_or_warn(base_branch)

          return if system('git', '-C', Workspace.path, 'branch', '-D', branch)

          warn Rainbow("  WARNING: cleanup deletion of branch #{branch} failed; " \
            'remove it manually if unwanted').yellow
        end

        # Renders the per-principle section embedded in the auto-MR
        # description: principle heading, source-file commit-history links,
        # and a fenced `git diff prior_sha..origin/<default_branch>`.
        def principle_diff_section(name, affected_entry, default_branch)
          sources = affected_entry&.dig(:changed_sources) || []
          prior_sha = affected_entry&.dig(:prior_sha)
          baseline_path = affected_entry&.dig(:config)&.dig('baseline')
          project_url = "#{workflow.gitlab_host}/#{workflow.catalog_project_path}"

          lines = ["#### `#{name}`"]

          if sources.any?
            lines << ''
            lines << "<details><summary>Source files (#{sources.size})</summary>"
            lines << ''
            sources.each do |source|
              path = source['path']
              commits_url = "#{project_url}/-/commits/#{default_branch}/#{path}"
              lines << "- [`#{path}`](#{commits_url})"
            end
            lines << ''
            lines << '</details>'
          end

          paths = sources.map { |s| s['path'] } # -- standalone script without Rails
          paths.unshift(baseline_path) if baseline_path
          diff_text, truncated = compute_principle_diff(prior_sha, default_branch, paths)

          if diff_text
            # 4-backtick fence: ```diff/```ruby blocks inside SSOT files
            # would otherwise close the outer fence early.
            # Resolved SHA (not branch name): range stays meaningful as
            # master moves on.
            target_sha = distillation_base_sha
            lines << ''
            lines << "<details><summary>SSOT diff since previous distillation " \
              "(#{prior_sha[0, 12]} \u2192 #{target_sha[0, 12]})</summary>"
            lines << ''
            lines << '````diff'
            lines << diff_text.chomp

            if truncated
              lines << ''
              lines << "... (diff truncated at #{DIFF_MAX_LINES} lines / #{DIFF_MAX_BYTES / 1024} KB; " \
                'use the per-file commit-history links above for the full picture)'
            end

            lines << '````'
            lines << ''
            lines << '</details>'
          end

          lines.join("\n")
        end

        private

        # CI runners only have origin/<branch>, not a local <branch> ref.
        # Try remote-tracking first, then local, then HEAD as a fallback.
        def resolve_distillation_base_sha
          branch = workflow.default_branch
          ["origin/#{branch}", branch].each do |ref|
            out = IO.popen(['git', '-C', Workspace.path, 'merge-base', 'HEAD', ref], err: File::NULL, &:read).strip
            return out unless out.empty?
          end
          IO.popen(['git', '-C', Workspace.path, 'rev-parse', 'HEAD'], err: File::NULL, &:read).strip
        end

        # CI's shallow clone doesn't include prior SHAs from weeks ago.
        # Fetch each unique prior_sha so `git diff <prior_sha>..origin/master`
        # resolves later. Relies on GitLab.com's
        # `uploadpack.allowReachableSHA1InWant=true` for direct-SHA fetches.
        def prefetch_prior_shas!(affected)
          shas = affected.values.filter_map { |entry| entry[:prior_sha] }.uniq
          return if shas.empty?

          shas.each do |sha|
            next if sha_present_locally?(sha)

            puts Rainbow("    prefetching #{sha[0, 12]} for diff embedding...").faint
            success = system('git', '-C', Workspace.path, 'fetch', '--depth=1', 'origin', sha,
              out: File::NULL, err: File::NULL)

            unless success
              warn Rainbow("    WARNING: could not fetch #{sha[0, 12]}; diff embedding will fall back").yellow
            end
          end
        end

        def sha_present_locally?(sha)
          system('git', '-C', Workspace.path, 'cat-file', '-e', "#{sha}^{commit}", out: File::NULL, err: File::NULL)
        end

        # Returns [diff_text, truncated?]. diff_text is nil when prior_sha
        # is unreachable or the diff is empty.
        def compute_principle_diff(prior_sha, default_branch, paths)
          return [nil, false] if prior_sha.nil? || prior_sha.empty? || paths.empty?
          return [nil, false] unless sha_present_locally?(prior_sha)

          target_ref = "origin/#{default_branch}"
          cmd = ['git', '-C', Workspace.path, 'diff', "#{prior_sha}..#{target_ref}", '--', *paths]
          out = IO.popen(cmd, err: File::NULL, &:read)
          return [nil, false] if out.nil? || out.strip.empty?

          truncate_diff(out)
        end

        # Returns the iid of an open MR for the given source branch, or nil.
        # `order_by=created_at&sort=desc` is explicit because the API default
        # is implementation-defined.
        def find_open_mr_iid(encoded_project, source_branch, api_token)
          uri = URI("#{workflow.gitlab_host}/api/v4/projects/#{encoded_project}/merge_requests")
          uri.query = URI.encode_www_form(state: 'opened', source_branch: source_branch,
            order_by: 'created_at', sort: 'desc')

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = 60

          request = Net::HTTP::Get.new(uri)
          request['PRIVATE-TOKEN'] = api_token
          response = http.request(request)
          return nil unless response.is_a?(Net::HTTPSuccess)

          mrs = JSON.parse(response.body)
          mrs.first&.fetch('iid', nil)
        end

        # Returns the plain HTTPS push URL with no embedded credentials.
        # Authentication is supplied separately via `git_push_env`, which
        # injects an `Authorization: Bearer` header through `GIT_CONFIG_*`
        # env vars so the token never lands in argv, the URL, or git's reflog.
        def push_remote_url(project_path_or_id)
          host = URI(workflow.gitlab_host).host || 'gitlab.com'
          # CI_PROJECT_ID is numeric, not usable as a URL path.
          project_path = ENV.fetch(Env::CI_PROJECT_PATH, nil)
          if project_path.nil? || project_path.empty?
            if project_path_or_id.to_s.match?(/\A\d+\z/)
              abort Rainbow("ERROR: #{Env::CI_PROJECT_PATH} env var is required for git push " \
                "(numeric #{Env::CI_PROJECT_ID} alone is not enough)").red
            end

            project_path = project_path_or_id.to_s
          end

          "https://#{host}/#{project_path}.git"
        end

        # Injects the API token as an HTTP Basic `Authorization` header via
        # `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_*`/`GIT_CONFIG_VALUE_*` env vars
        # (https://git-scm.com/docs/git-config#Documentation/git-config.txt-GITCONFIGCOUNT).
        # This keeps the token out of:
        # - argv (no `git -c http.extraHeader=...` and no credentialed URL).
        # - the remote URL and git's reflog.
        # Returns the env hash to pass to the push `system` call.
        #
        # The header is scoped to the host (`http.https://<host>.extraHeader`),
        # not the full repo URL. git matches `http.<url>.*` by URL prefix on
        # whole path segments, so a key scoped to `.../gitlab` does NOT match a
        # request to `.../gitlab.git`. That mismatch left the header unapplied
        # and the push fell back to anonymous, yielding a 403. A host-scoped
        # key applies to every request to that host, which is what we want for
        # a single-remote push.
        #
        # The scheme must be HTTP Basic (`oauth2:<token>`, base64-encoded), not
        # `Bearer`: GitLab's smart-HTTP git endpoint authenticates PATs via
        # Basic auth. A `Bearer` header is silently ignored, so the request
        # falls through to git's Basic challenge with no credentials and the
        # remote returns `HTTP Basic: Access denied`. (`PRIVATE-TOKEN` is
        # REST-only and also rejected on git push.)
        #
        # Appends to any existing `GIT_CONFIG_*` entries injected by the parent
        # environment (e.g. GitLab Runner) rather than overwriting them.
        def git_push_env(api_token, push_url)
          abort Rainbow("ERROR: #{Env::GITLAB_API_TOKEN} is empty, cannot push").red if api_token.to_s.empty?

          host_scope = URI(push_url).then { |u| "#{u.scheme}://#{u.host}" }
          # `pack('m0')`: strict base64 with no trailing newline.
          basic_credentials = ["oauth2:#{api_token}"].pack('m0')
          next_index = ENV.fetch('GIT_CONFIG_COUNT', '0').to_i

          {
            'GIT_CONFIG_COUNT' => (next_index + 1).to_s,
            "GIT_CONFIG_KEY_#{next_index}" => "http.#{host_scope}.extraHeader",
            "GIT_CONFIG_VALUE_#{next_index}" => "Authorization: Basic #{basic_credentials}"
          }
        end

        def create_mr(branch, project_id, api_token, changed_principles, affected, auto_mr_cfg, team:, title:)
          default_branch = workflow.default_branch
          sections = changed_principles.keys.map do |name|
            principle_diff_section(name, affected[name], default_branch)
          end.join("\n\n")

          project_url = "#{workflow.gitlab_host}/#{workflow.catalog_project_path}"
          manifest_url = "#{project_url}/-/blob/#{default_branch}/.ai/principles/manifest.yml"
          ci_yml_url = "#{project_url}/-/blob/#{default_branch}/.gitlab/ci/sync-principles.gitlab-ci.yml"

          description = <<~DESC
        ## Summary

        This MR updates the **#{team}** AI development principles based on
        recent changes to the development documentation (SSOT). It is one of
        several team-scoped MRs from this run; the global routing tables
        (AGENTS.md, CLAUDE.md, SKILL.md) are updated in a separate tooling MR.
        #{review_request_section(changed_principles.keys, team)}
        ### Updated principles and their source-doc changes

        #{sections}

        ### How this works

        A [scheduled CI job](#{ci_yml_url}) detects changes to `doc/development/`
        files listed in [`.ai/principles/manifest.yml`](#{manifest_url}), then
        uses the GitLab Duo Agent Platform Workflow API to distill updated
        principles for the affected domains.
        #{job_line}
        Please review the checklist changes to ensure they accurately
        reflect the documentation updates.
          DESC

          submit_mr(branch, default_branch, project_id, api_token, auto_mr_cfg, title, description)
        end

        # Opens/updates the tooling MR carrying the regenerated global routing
        # tables. Routed to the broad `/.ai/` owners (no SSOT-team content).
        def create_tooling_mr(branch, project_id, api_token, auto_mr_cfg, title)
          default_branch = workflow.default_branch
          project_url = "#{workflow.gitlab_host}/#{workflow.catalog_project_path}"
          manifest_url = "#{project_url}/-/blob/#{default_branch}/.ai/principles/manifest.yml"

          description = <<~DESC
        ## Summary

        This MR regenerates the global AI-principles routing tables from
        [`.ai/principles/manifest.yml`](#{manifest_url}): `AGENTS.md`,
        `CLAUDE.md`, and the `gitlab-coding-principles` SKILL.md files.

        These files embed the routing table for **all** principles, so they
        are kept separate from the per-team principle MRs in this run.
        #{job_line}
        No distilled principle content changes here — only the generated
        routing tables.
          DESC

          submit_mr(branch, default_branch, project_id, api_token, auto_mr_cfg, title, description)
        end

        def job_line
          job_url = ENV.fetch(Env::CI_JOB_URL, nil)
          return '' if job_url.nil? || job_url.empty?

          "\nThis MR was generated by #{job_url}\n"
        end

        # Renders the "Request a review from" section listing the primary
        # owner team (which CODEOWNERS routes the approval to) plus any
        # secondary teams for the principles in this MR whose SSOT docs span
        # more than one owner. Returns '' when there are no secondary teams,
        # so single-owner MRs stay terse (the owner already approves via
        # CODEOWNERS). Secondary teams are deduped and exclude the primary.
        def review_request_section(principle_names, team)
          secondary = principle_names
            .flat_map { |name| manifest.principle_secondary_teams(name) }
            .reject { |handle| handle.to_s.strip.empty? || handle == team }
            .uniq
          return '' if secondary.empty?

          <<~SECTION

            ### Request a review from

            Approval is routed to #{team} via CODEOWNERS. Some SSOT docs in
            this MR also affect other teams — please request a review from:

            #{secondary.map { |handle| "- #{handle}" }.join("\n")}
          SECTION
        end

        # Shared create-or-update with same-day idempotency: an open MR for the
        # same source branch is updated in place rather than failing on a 409.
        def submit_mr(branch, default_branch, project_id, api_token, auto_mr_cfg, title, description)
          encoded_project = URI.encode_www_form_component(project_id)
          existing_mr_iid = find_open_mr_iid(encoded_project, branch, api_token)
          body = {
            title: title,
            # Collapse runs of blank lines so an empty `job_line` (when
            # CI_JOB_URL is unset) doesn't leave a spurious gap mid-paragraph.
            description: description.gsub(/\n{3,}/, "\n\n"),
            labels: Array(auto_mr_cfg['labels']).join(','),
            remove_source_branch: auto_mr_cfg.fetch('remove_source_branch', true)
          }

          host = workflow.gitlab_host
          if existing_mr_iid
            response = workflow.put_json(
              "#{host}/api/v4/projects/#{encoded_project}/merge_requests/#{existing_mr_iid}",
              headers: { 'PRIVATE-TOKEN' => api_token },
              body: body
            )
            action = 'updated'
          else
            response = workflow.post_json(
              "#{host}/api/v4/projects/#{encoded_project}/merge_requests",
              headers: { 'PRIVATE-TOKEN' => api_token },
              body: body.merge(source_branch: branch, target_branch: default_branch)
            )
            action = 'created'
          end

          unless response.is_a?(Net::HTTPSuccess)
            # Raise (not abort) so the per-team rescue in create_branch_and_mr
            # can record this team and continue with the others.
            raise "Failed to #{action.delete_suffix('ed')} MR: #{response.code} #{response.body.slice(0, 200)}"
          end

          puts "\n#{Rainbow("MR #{action}: #{JSON.parse(response.body)['web_url']}").green}"
        end
      end
    end
  end
end
