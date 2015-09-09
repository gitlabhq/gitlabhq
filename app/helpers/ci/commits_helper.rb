module Ci
  module CommitsHelper
    def commit_status_alert_class(commit)
      return unless commit

      case commit.status
      when 'success'
        'alert-success'
      when 'failed', 'canceled'
        'alert-danger'
      when 'skipped'
        'alert-disabled'
      else
        'alert-warning'
      end
    end

    def commit_link(commit)
      link_to(commit.short_sha, ci_project_ref_commits_path(commit.project, commit.ref, commit.sha))
    end

    def truncate_first_line(message, length = 50)
      truncate(message.each_line.first.chomp, length: length) if message
    end
  end
end
