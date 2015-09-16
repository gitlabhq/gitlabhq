module Ci
  class HipChatMessage
    attr_reader :build

    def initialize(build)
      @build = build
    end

    def to_s
      lines = Array.new
      lines.push("<a href=\"#{Ci::RoutesHelper.ci_project_url(project)}\">#{project.name}</a> - ")
      
      if commit.matrix?
        lines.push("<a href=\"#{Ci::RoutesHelper.ci_project_ref_commits_url(project, commit.ref, commit.sha)}\">Commit ##{commit.id}</a></br>")
      else
        first_build = commit.builds_without_retry.first
        lines.push("<a href=\"#{Ci::RoutesHelper.ci_project_build_url(project, first_build)}\">Build '#{first_build.name}' ##{first_build.id}</a></br>")
      end
      
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
