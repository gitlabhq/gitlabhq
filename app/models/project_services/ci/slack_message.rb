require 'slack-notifier'

module Ci
  class SlackMessage
    include Gitlab::Application.routes.url_helpers

    def initialize(commit)
      @commit = commit
    end

    def pretext
      ''
    end

    def color
      attachment_color
    end

    def fallback
      format(attachment_message)
    end

    def attachments
      fields = []

      commit.latest_builds.each do |build|
        next if build.allow_failure?
        next unless build.failed?
        fields << {
          title: build.name,
          value: "Build <#{namespace_project_build_url(build.gl_project.namespace, build.gl_project, build)}|\##{build.id}> failed in #{build.duration.to_i} second(s)."
        }
      end

      [{
         text: attachment_message,
         color: attachment_color,
         fields: fields
       }]
    end

    private

    attr_reader :commit

    def attachment_message
      out = "<#{ci_project_url(project)}|#{project_name}>: "
      out << "Commit <#{builds_namespace_project_commit_url(commit.gl_project.namespace, commit.gl_project, commit.sha)}|\##{commit.id}> "
      out << "(<#{commit_sha_link}|#{commit.short_sha}>) "
      out << "of <#{commit_ref_link}|#{commit.ref}> "
      out << "by #{commit.git_author_name} " if commit.git_author_name
      out << "#{commit_status} in "
      out << "#{commit.duration} second(s)"
    end

    def format(string)
      Slack::Notifier::LinkFormatter.format(string)
    end

    def project
      commit.project
    end

    def project_name
      project.name
    end

    def commit_sha_link
      "#{project.gitlab_url}/commit/#{commit.sha}"
    end

    def commit_ref_link
      "#{project.gitlab_url}/commits/#{commit.ref}"
    end

    def attachment_color
      if commit.success?
        'good'
      else
        'danger'
      end
    end

    def commit_status
      if commit.success?
        'succeeded'
      else
        'failed'
      end
    end
  end
end
