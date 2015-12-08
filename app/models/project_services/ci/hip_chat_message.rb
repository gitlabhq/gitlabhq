module Ci
  class HipChatMessage
    include Gitlab::Application.routes.url_helpers

    attr_reader :build

    def initialize(build)
      @build = build
    end

    def to_s
      lines = Array.new
      lines.push("<a href=\"#{ci_project_url(project)}\">#{project.name}</a> - ")
      lines.push("<a href=\"#{builds_namespace_project_commit_url(commit.gl_project.namespace, commit.gl_project, commit.sha)}\">Commit ##{commit.id}</a></br>")
      lines.push("#{commit.short_sha} #{commit.git_author_name} - #{commit.git_commit_message}</br>")
      lines.push("#{humanized_status(commit_status)} in #{commit.duration} second(s).")
      lines.join('')
    end

    def status_color(build_or_commit=nil)
      build_or_commit ||= commit_status
      case build_or_commit
      when :success
        'green'
      when :failed, :canceled
        'red'
      else # :pending, :running or unknown
        'yellow'
      end
    end

    def notify?
      [:failed, :canceled].include?(commit_status)
    end


    private

    def commit
      build.commit
    end

    def project
      commit.project
    end

    def build_status
      build.status.to_sym
    end

    def commit_status
      commit.status.to_sym
    end

    def humanized_status(build_or_commit=nil)
      build_or_commit ||= commit_status
      case build_or_commit
      when :pending
        "Pending"
      when :running
        "Running"
      when :failed
        "Failed"
      when :success
        "Successful"
      when :canceled
        "Canceled"
      else
        "Unknown"
      end
    end
  end
end
