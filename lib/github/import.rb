module Github
  class Import
    class MergeRequest < ::MergeRequest
      self.table_name = 'merge_requests'

      self.reset_callbacks :save
      self.reset_callbacks :commit
      self.reset_callbacks :update
      self.reset_callbacks :validate
    end

    attr_reader :project, :repository, :cached_user_ids, :errors

    def initialize(project)
      @project = project
      @repository = project.repository
      @cached_user_ids = {}
      @errors  = []
    end

    def execute(owner, repo, token)
      # Fetch repository
      begin
        project.create_repository
        project.repository.add_remote('github', "https://#{token}@github.com/#{owner}/#{repo}.git")
        project.repository.set_remote_as_mirror('github')
        project.repository.fetch_remote('github', forced: true)
        project.repository.remove_remote('github')
      rescue Gitlab::Shell::Error => e
        error(:project, "https://github.com/#{owner}/#{repo}.git", e.message)
      end

      # Fetch labels
      labels = Github::Labels.new(owner, repo).fetch

      labels.each do |raw|
        begin
          label = Github::Representation::Label.new(raw)
          project.labels.create!(title: label.title, color: label.color)
        rescue => e
          error(:label, label.url, e.message)
        end
      end

      # Fetch milestones
      milestones = Github::Milestones.new(owner, repo).fetch

      milestones.each do |raw|
        begin
          milestone = Github::Representation::Milestone.new(raw)

          project.milestones.create!(
            iid: milestone.iid,
            title: milestone.title,
            description: milestone.description,
            due_date: milestone.due_date,
            state: milestone.state,
            created_at: milestone.created_at,
            updated_at: milestone.updated_at
          )
        rescue => e
          error(:milestone, milestone.url, e.message)
        end
      end

      # Fetch pull requests
      pull_requests = Github::PullRequests.new(owner, repo).fetch

      pull_requests.each do |raw|
        pull_request = Github::Representation::PullRequest.new(project, raw)
        next unless pull_request.valid?

        begin
          restore_source_branch(pull_request) unless pull_request.source_branch_exists?
          restore_target_branch(pull_request) unless pull_request.target_branch_exists?

          merge_request = MergeRequest.find_or_initialize_by(iid: pull_request.iid, source_project_id: project.id) do |record|
            record.iid               = pull_request.iid
            record.title             = pull_request.title
            record.description       = pull_request.description
            record.source_project    = pull_request.source_project
            record.source_branch     = pull_request.source_branch_name
            record.source_branch_sha = pull_request.source_branch_sha
            record.target_project    = pull_request.target_project
            record.target_branch     = pull_request.target_branch_name
            record.target_branch_sha = pull_request.target_branch_sha
            record.state             = pull_request.state
            record.milestone_id      = milestone_id(pull_request.milestone)
            record.author_id         = user_id(pull_request.author, project.creator_id)
            record.assignee_id       = user_id(pull_request.assignee)
            record.created_at        = pull_request.created_at
            record.updated_at        = pull_request.updated_at
          end

          merge_request.save(validate: false)
          merge_request.merge_request_diffs.create
        rescue => e
          error(:pull_request, pull_request.url, "#{e.message}\n\n#{e.exception.backtrace.join('\n')}")
        ensure
          clean_up_restored_branches(pull_request)
        end
      end

      repository.expire_content_cache

      errors
    end

    private

    def restore_source_branch(pull_request)
      repository.create_branch(pull_request.source_branch_name, pull_request.source_branch_sha)
    end

    def restore_target_branch(pull_request)
      repository.create_branch(pull_request.target_branch_name, pull_request.target_branch_sha)
    end

    def remove_branch(name)
      repository.delete_branch(name)
    rescue Rugged::ReferenceError
      errors << { type: :branch, url: nil, error: "Could not clean up restored branch: #{name}" }
    end

    def clean_up_restored_branches(pull_request)
      return if pull_request.opened?

      remove_branch(pull_request.source_branch_name) unless pull_request.source_branch_exists?
      remove_branch(pull_request.target_branch_name) unless pull_request.target_branch_exists?
    end

    def milestone_id(milestone)
      return unless milestone.present?

      project.milestones.select(:id).find_by(iid: milestone.iid)&.id
    end

    def user_id(user, fallback_id = nil)
      return unless user.present?
      return cached_user_ids[user.id] if cached_user_ids.key?(user.id)

      cached_user_ids[user.id] = find_by_external_uid(user.id) || find_by_email(user.email) || fallback_id
    end

    def find_by_email(email)
      return nil unless email

      ::User.find_by_any_email(email)&.id
    end

    def find_by_external_uid(id)
      return nil unless id

      identities = ::Identity.arel_table

      ::User.select(:id)
            .joins(:identities)
            .where(identities[:provider].eq(:github).and(identities[:extern_uid].eq(id)))
            .first&.id
    end

    def error(type, url, message)
      errors << { type: type, url: Gitlab::UrlSanitizer.sanitize(url), error: message }
    end
  end
end
