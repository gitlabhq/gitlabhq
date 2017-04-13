module Github
  class Import
    class MergeRequest < ::MergeRequest
      self.table_name = 'merge_requests'

      self.reset_callbacks :save
      self.reset_callbacks :commit
      self.reset_callbacks :update
      self.reset_callbacks :validate
    end

    class Issue < ::Issue
      self.table_name = 'issues'

      self.reset_callbacks :save
      self.reset_callbacks :commit
      self.reset_callbacks :update
      self.reset_callbacks :validate
    end

    class Note < ::Note
      self.table_name = 'notes'

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
        project.repository.add_remote('github', "https://881a01d03026458e51285a4c7038c9fe4daa5561@github.com/#{owner}/#{repo}.git")
        project.repository.set_remote_as_mirror('github')
        project.repository.fetch_remote('github', forced: true)
        project.repository.remove_remote('github')
      rescue Gitlab::Shell::Error => e
        error(:project, "https://github.com/#{owner}/#{repo}.git", e.message)
      end

      # Fetch labels
      url = "/repos/#{owner}/#{repo}/labels"

      loop do
        response = Github::Client.new.get(url)

        response.body.each do |raw|
          begin
            label = Github::Representation::Label.new(raw)
            next if project.labels.where(title: label.title).exists?

            project.labels.create!(title: label.title, color: label.color)
          rescue => e
            error(:label, label.url, e.message)
          end
        end

        break unless url = response.rels[:next]
      end

      # Fetch milestones
      url = "/repos/#{owner}/#{repo}/milestones"

      loop do
        response = Github::Client.new.get(url, state: :all)

        response.body.each do |raw|
          begin
            milestone = Github::Representation::Milestone.new(raw)
            next if project.milestones.where(iid: milestone.iid).exists?

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

        break unless url = response.rels[:next]
      end

      # Fetch pull requests
      url = "/repos/#{owner}/#{repo}/pulls"

      loop do
        response = Github::Client.new.get(url, state: :all, sort: :created, direction: :asc)

        response.body.each do |raw|
          pull_request  = Github::Representation::PullRequest.new(project, raw)
          merge_request = MergeRequest.find_or_initialize_by(iid: pull_request.iid, source_project_id: project.id)
          next unless merge_request.new_record? && pull_request.valid?

          begin
            restore_source_branch(pull_request) unless pull_request.source_branch_exists?
            restore_target_branch(pull_request) unless pull_request.target_branch_exists?

            merge_request.iid               = pull_request.iid
            merge_request.title             = pull_request.title
            merge_request.description       = pull_request.description
            merge_request.source_project    = pull_request.source_project
            merge_request.source_branch     = pull_request.source_branch_name
            merge_request.source_branch_sha = pull_request.source_branch_sha
            merge_request.target_project    = pull_request.target_project
            merge_request.target_branch     = pull_request.target_branch_name
            merge_request.target_branch_sha = pull_request.target_branch_sha
            merge_request.state             = pull_request.state
            merge_request.milestone_id      = milestone_id(pull_request.milestone)
            merge_request.author_id         = user_id(pull_request.author, project.creator_id)
            merge_request.assignee_id       = user_id(pull_request.assignee)
            merge_request.created_at        = pull_request.created_at
            merge_request.updated_at        = pull_request.updated_at
            merge_request.save(validate: false)

            merge_request.merge_request_diffs.create
          rescue => e
            error(:pull_request, pull_request.url, e.message)
          ensure
            clean_up_restored_branches(pull_request)
          end
        end

        break unless url = response.rels[:next]
      end

      # Fetch issues
      url = "/repos/#{owner}/#{repo}/issues"

      loop do
        response = Github::Client.new.get(url, state: :all, sort: :created, direction: :asc)

        response.body.each do |raw|
          representation = Github::Representation::Issue.new(raw)

          next if representation.pull_request?
          next if Issue.where(iid: representation.iid, project_id: project.id).exists?

          begin
            issue              = Issue.new
            issue.iid          = representation.iid
            issue.project_id   = project.id
            issue.title        = representation.title
            issue.description  = representation.description
            issue.state        = representation.state
            issue.milestone_id = milestone_id(representation.milestone)
            issue.author_id    = user_id(representation.author, project.creator_id)
            issue.assignee_id  = user_id(representation.assignee)
            issue.created_at   = representation.created_at
            issue.updated_at   = representation.updated_at
            issue.save(validate: false)
          rescue => e
            error(:issue, representation.url, e.message)
          end
        end

        break unless url = response.rels[:next]
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
