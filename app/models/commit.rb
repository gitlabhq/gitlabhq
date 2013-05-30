class Commit
  include ActiveModel::Conversion
  include StaticModel
  extend ActiveModel::Naming
  include Mentionable

  attr_mentionable :safe_message

  # Safe amount of files with diffs in one commit to render
  # Used to prevent 500 error on huge commits by suppressing diff
  #
  DIFF_SAFE_SIZE = 100

  def self.decorate(commits)
    commits.map { |c| self.new(c) }
  end

  attr_accessor :raw

  def initialize(raw_commit)
    raise "Nil as raw commit passed" unless raw_commit

    @raw = raw_commit
  end

  def id
    @raw.id
  end

  # Returns a string describing the commit for use in a link title
  #
  # Example
  #
  #   "Commit: Alex Denisov - Project git clone panel"
  def link_title
    "Commit: #{author_name} - #{title}"
  end

  # Returns the commits title.
  #
  # Usually, the commit title is the first line of the commit message.
  # In case this first line is longer than 100 characters, it is cut off
  # after 80 characters and ellipses (`&hellp;`) are appended.
  def title
    title = safe_message

    return no_commit_message if title.blank?

    title_end = title.index(/\n/)
    if (!title_end && title.length > 100) || (title_end && title_end > 100)
      title[0..79] << "&hellip;".html_safe
    else
      title.split(/\n/, 2).first
    end
  end

  # Returns the commits description
  #
  # cut off, ellipses (`&hellp;`) are prepended to the commit message.
  def description
    description = safe_message

    title_end = description.index(/\n/)
    if (!title_end && description.length > 100) || (title_end && title_end > 100)
      "&hellip;".html_safe << description[80..-1]
    else
      description.split(/\n/, 2)[1].try(:chomp)
    end
  end

  # Regular expression that identifies commit message clauses that trigger issue closing.
  def issue_closing_regex
    @issue_closing_regex ||= Regexp.new(Gitlab.config.gitlab.issue_closing_pattern)
  end

  # Discover issues should be closed when this commit is pushed to a project's
  # default branch.
  def closes_issues project
    md = issue_closing_regex.match(safe_message)
    if md
      extractor = Gitlab::ReferenceExtractor.new
      extractor.analyze(md[0])
      extractor.issues_for(project)
    else
      []
    end
  end

  # Mentionable override.
  def gfm_reference
    "commit #{sha[0..5]}"
  end

  def method_missing(m, *args, &block)
    @raw.send(m, *args, &block)
  end

  def respond_to?(method)
    return true if @raw.respond_to?(method)

    super
  end
end
