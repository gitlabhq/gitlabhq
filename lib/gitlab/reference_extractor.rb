module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :project, :current_user, :references

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
            namespace.users if can?(current_user, :read_group, namespace)
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

    NAME_STR = Gitlab::Regex::NAMESPACE_REGEX_STR
    PROJ_STR = "(?<project>#{NAME_STR}/#{NAME_STR})"

    REFERENCE_PATTERN = %r{
      (?<prefix>\W)?                         # Prefix
      (                                      # Reference
         @(?<user>#{NAME_STR})               # User name
        |~(?<label>\d+)                      # Label ID
        |(?<issue>([A-Z\-]+-)\d+)            # JIRA Issue ID
        |#{PROJ_STR}?\#(?<issue>([a-zA-Z\-]+-)?\d+) # Issue ID
        |#{PROJ_STR}?!(?<merge_request>\d+)  # MR ID
        |\$(?<snippet>\d+)                   # Snippet ID
        |(#{PROJ_STR}@)?(?<commit_range>[\h]{6,40}\.{2,3}[\h]{6,40}) # Commit range
        |(#{PROJ_STR}@)?(?<commit>[\h]{6,40}) # Commit ID
      )
      (?<suffix>\W)?                         # Suffix
    }x.freeze

    TYPES = %i(user issue label merge_request snippet commit commit_range).freeze

    def parse_references(text, project = @project)
      # parse reference links
      text.gsub!(REFERENCE_PATTERN) do |match|
        type = TYPES.detect { |t| $~[t].present? }

        actual_project = project
        project_prefix = nil
        project_path = $LAST_MATCH_INFO[:project]
        if project_path
          actual_project = ::Project.find_with_namespace(project_path)
          actual_project = nil unless can?(current_user, :read_project, actual_project)
          project_prefix = project_path
        end

        parse_result($LAST_MATCH_INFO, type,
                     actual_project, project_prefix) || match
      end
    end

    # Called from #parse_references.  Attempts to build a gitlab reference
    # link.  Returns nil if +type+ is nil, if the match string is an HTML
    # entity, if the reference is invalid, or if the matched text includes an
    # invalid project path.
    def parse_result(match_info, type, project, project_prefix)
      prefix = match_info[:prefix]
      suffix = match_info[:suffix]

      return nil if html_entity?(prefix, suffix) || type.nil?
      return nil if project.nil? && !project_prefix.nil?

      identifier = match_info[type]
      ref_link = reference_link(type, identifier, project, project_prefix)

      if ref_link
        "#{prefix}#{ref_link}#{suffix}"
      else
        nil
      end
    end

    # Return true if the +prefix+ and +suffix+ indicate that the matched string
    # is an HTML entity like &amp;
    def html_entity?(prefix, suffix)
      prefix && suffix && prefix[0] == '&' && suffix[-1] == ';'
    end

    def reference_link(type, identifier, project, _)
      references[type] << [project, identifier]
    end
  end
end
