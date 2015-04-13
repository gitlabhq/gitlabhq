module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :project, :current_user, :references

    include ::Gitlab::Markdown

    def initialize(project, current_user = nil)
      @project = project
      @current_user = current_user
    end

    def can?(user, action, subject)
      Ability.abilities.allowed?(user, action, subject)
    end

    def analyze(text)
      text = text.dup

      # Remove preformatted/code blocks so that references are not included
      text.gsub!(%r{<pre>.*?</pre>|<code>.*?</code>}m) { |match| '' }
      text.gsub!(%r{^```.*?^```}m) { |match| '' }

      @references = Hash.new { |hash, type| hash[type] = [] }
      parse_references(text)
    end

    # Given a valid project, resolve the extracted identifiers of the requested type to
    # model objects.

    def users
      references[:user].uniq.map do |project, identifier|
        if identifier == "all"
          project.team.members.flatten
        elsif namespace = Namespace.find_by(path: identifier)
          if namespace.is_a?(Group)
            namespace.users
          else
            namespace.owner
          end
        end
      end.flatten.compact.uniq
    end

    def labels
      references[:label].uniq.map do |project, identifier|
        project.labels.where(id: identifier).first
      end.compact.uniq
    end

    def issues
      references[:issue].uniq.map do |project, identifier|
        if project.default_issues_tracker?
          project.issues.where(iid: identifier).first
        end
      end.compact.uniq
    end

    def merge_requests
      references[:merge_request].uniq.map do |project, identifier|
        project.merge_requests.where(iid: identifier).first
      end.compact.uniq
    end

    def snippets
      references[:snippet].uniq.map do |project, identifier|
        project.snippets.where(id: identifier).first
      end.compact.uniq
    end

    def commits
      references[:commit].uniq.map do |project, identifier|
        repo = project.repository
        repo.commit(identifier) if repo
      end.compact.uniq
    end

    def commit_ranges
      references[:commit_range].uniq.map do |project, identifier|
        repo = project.repository
        if repo
          from_id, to_id = identifier.split(/\.{2,3}/, 2)
          [repo.commit(from_id), repo.commit(to_id)]
        end
      end.compact.uniq
    end

    private

    def reference_link(type, identifier, project, _)
      references[type] << [project, identifier]
    end
  end
end
