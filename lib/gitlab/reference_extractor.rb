module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :project, :current_user, :references

    include Markdown

    def initialize(project, current_user = nil)
      @project = project
      @current_user = user

      @references = Hash.new { [] }
    end

    def can?(user, action, subject)
      # When extracting references, no user means access to everything.
      return true if user.nil?

      Ability.abilities.allowed?(user, action, subject)
    end

    def analyze(text)
      text = text.dup

      # Remove preformatted/code blocks so that references are not included
      text.gsub!(%r{<pre>.*?</pre>|<code>.*?</code>}m) { |match| '' }
      text.gsub!(%r{^```.*?^```}m) { |match| '' }

      parse_references(text)
    end

    # Given a valid project, resolve the extracted identifiers of the requested type to
    # model objects.

    def users
      references[:users].map do |entry|
        if entry[:id] == "all"
          project.team.members.flatten
        elsif namespace = Namespace.find_by(path: entry[:id])
          if namespace.is_a?(Group)
            namespace.users
          else
            namespace.owner
          end
        end
      end.flatten.compact
    end

    def labels
      references[:labels].map do |entry|
        project.labels.where(id: entry[:id]).first
      end.compact
    end

    def issues
      references[:issues].map do |entry|
        if should_lookup?(entry[:project])
          entry[:project].issues.where(iid: entry[:id]).first
        end
      end.compact
    end

    def merge_requests
      references[:merge_requests].map do |entry|
        if should_lookup?(entry[:project])
          entry[:project].merge_requests.where(iid: entry[:id]).first
        end
      end.compact
    end

    def snippets
      references[:snippets].map do |entry|
        project.snippets.where(id: entry[:id]).first
      end.compact
    end

    def commits
      references[:commits].map do |entry|
        repo = entry[:project].repository if entry[:project]
        if should_lookup?(entry[:project])
          repo.commit(entry[:id]) if repo
        end
      end.compact
    end

    def commit_ranges
      references[:commit_ranges].map do |entry|
        repo = entry[:project].repository if entry[:project]
        if repo && should_lookup?(entry[:project])
          from_id, to_id = entry[:id].split(/\.{2,3}/, 2)
          [repo.commit(from_id), repo.commit(to_id)]
        end
      end.compact
    end

    private

    def reference_link(type, identifier, project, user, _)
      references[type] << { project: project, id: identifier }
    end

    def should_lookup?(entry_project)
      if entry_project.nil?
        false
      else
        project.nil? || entry_project.default_issues_tracker?
      end
    end
  end
end
