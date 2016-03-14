module Projects
  module ImportExport
    extend self

    def export_path(relative_path:)
      File.join(storage_path, "#{Time.now.strftime('%Y-%m-%d_%H-%M-%3N')}_gitlab_export/#{relative_path}")
    end

    def project_atts
      %i(name path description issues_enabled wall_enabled merge_requests_enabled wiki_enabled snippets_enabled visibility_level archived)
    end

    def project_tree
      %i(issues labels milestones releases events) + [snippets, members, merge_requests, commit_statuses]
    end

    private

    def snippets
      { snippets: { except: :expired_at } }
    end

    def merge_requests
      { merge_requests: { include: :merge_request_diff } }
    end

    def commit_statuses
      { commit_statuses: { include: :commit } }
    end

    def members
      { project_members: { include: [user: { only: [:id, :email, :username] }] } }
    end

    def storage_path
      File.join(Settings.shared['path'], 'tmp/project_exports')
    end
  end
end
