module Ci
  module CommitsHelper
    def commit_status_css_class(commit)
      return 'build-info' unless commit

      case commit.status
      when 'success'
        'build-success'
      when 'failed', 'canceled'
        'build-danger'
      when 'skipped'
        'build-disabled'
      else
        'build-warning'
      end
    end

    def ci_commit_path(commit)
      ci_project_ref_commits_path(commit.project, commit.ref, commit.sha)
    end

    def commit_link(commit)
      link_to(commit.short_sha, ci_commit_path(commit))
    end

    def truncate_first_line(message, length = 50)
      truncate(message.each_line.first.chomp, length: length) if message
    end

    def ci_commit_title(commit)
      content_tag :span do
        link_to(
          simple_sanitize(commit.project.name), ci_project_path(commit.project)
        ) + ' @ ' +
          gitlab_commit_link(@project, @commit.sha)
      end
    end
  end
end
