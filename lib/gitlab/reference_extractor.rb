module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :users, :labels, :issues, :merge_requests, :snippets, :commits, :commit_ranges

    include Markdown

    def initialize
      @users, @labels, @issues, @merge_requests, @snippets, @commits, @commit_ranges =
        [], [], [], [], [], [], []
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

    def labels_for(project = nil)
      labels.map do |entry|
        project.labels.where(id: entry[:id]).first
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

    def commit_ranges_for(project = nil)
      commit_ranges.map do |entry|
        repo = entry[:project].repository if entry[:project]
        if repo && should_lookup?(project, entry[:project])
          from_id, to_id = entry[:id].split(/\.{2,3}/, 2)
          [repo.commit(from_id), repo.commit(to_id)]
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
        project.nil? || entry_project.default_issues_tracker?
      end
    end
  end
end
