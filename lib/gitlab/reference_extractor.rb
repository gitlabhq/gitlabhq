module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :users, :issues, :merge_requests, :snippets, :commits

    include Markdown

    def initialize
      @users, @issues, @merge_requests, @snippets, @commits = [], [], [], [], []
    end

    def analyze(string, project)
      parse_references(string.dup, project)
    end

    # Given a valid project, resolve the extracted identifiers of the requested type to
    # model objects.

    def users_for(project)
      users.map do |entry|
        project.users.where(username: entry[:id]).first
      end.reject(&:nil?)
    end

    def issues_for(project = nil)
      issues.map do |entry|
        if should_lookup?(project, entry[:project])
          entry[:project].issues.where(iid: entry[:id]).first
        end
      end.reject(&:nil?)
    end

    def merge_requests_for(project = nil)
      merge_requests.map do |entry|
        if should_lookup?(project, entry[:project])
          entry[:project].merge_requests.where(iid: entry[:id]).first
        end
      end.reject(&:nil?)
    end

    def snippets_for(project)
      snippets.map do |entry|
        project.snippets.where(id: entry[:id]).first
      end.reject(&:nil?)
    end

    def commits_for(project = nil)
      commits.map do |entry|
        repo = entry[:project].repository if entry[:project]
        if should_lookup?(project, entry[:project])
          repo.commit(entry[:id]) if repo
        end
      end.reject(&:nil?)
    end

    private

    def reference_link(type, identifier, project, _)
      # Append identifier to the appropriate collection.
      send("#{type}s") << { project: project, id: identifier }
    end

    def should_lookup?(project, entry_project)
      if entry_project.nil?
        false
      else
        project.nil? || project.id == entry_project.id
      end
    end
  end
end
