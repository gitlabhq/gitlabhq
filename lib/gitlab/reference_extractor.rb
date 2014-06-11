module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :users, :issues, :merge_requests, :snippets, :commits

    include Markdown

    def initialize
      @users, @issues, @merge_requests, @snippets, @commits = [], [], [], [], []
    end

    def analyze string
      parse_references(string.dup)
    end

    # Given a valid project, resolve the extracted identifiers of the requested type to
    # model objects.

    def users_for project
      users.map do |identifier|
        project.users.where(username: identifier).first
      end.reject(&:nil?)
    end

    def issues_for project
      issues.map do |identifier|
        project.issues.where(iid: identifier).first
      end.reject(&:nil?)
    end

    def merge_requests_for project
      merge_requests.map do |identifier|
        project.merge_requests.where(iid: identifier).first
      end.reject(&:nil?)
    end

    def snippets_for project
      snippets.map do |identifier|
        project.snippets.where(id: identifier).first
      end.reject(&:nil?)
    end

    def commits_for project
      repo = project.repository
      return [] if repo.nil?

      commits.map do |identifier|
        repo.commit(identifier)
      end.reject(&:nil?)
    end

    private

    def reference_link(type, identifier, project)
      # Append identifier to the appropriate collection.
      send("#{type}s") << identifier
    end
  end
end
