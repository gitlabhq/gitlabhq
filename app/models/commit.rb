class Commit
  include ActiveModel::Conversion
  include StaticModel
  extend ActiveModel::Naming
  include Mentionable

  attr_mentionable :safe_message

  # Safe amount of changes (files and lines) in one commit to render
  # Used to prevent 500 error on huge commits by suppressing diff
  #
  # User can force display of diff above this size
  DIFF_SAFE_FILES  = 100
  DIFF_SAFE_LINES  = 5000

  # Commits above this size will not be rendered in HTML
  DIFF_HARD_LIMIT_FILES = 1000
  DIFF_HARD_LIMIT_LINES = 50000

  class << self
    def decorate(commits)
      commits.map { |c| self.new(c) }
    end

    # Calculate number of lines to render for diffs
    def diff_line_count(diffs)
      diffs.reduce(0) { |sum, d| sum + d.diff.lines.count }
    end
  end

  attr_accessor :raw

  def initialize(raw_commit)
    raise "Nil as raw commit passed" unless raw_commit

    @raw = raw_commit
  end

  def id
    @raw.id
  end

  def diff_line_count
    @diff_line_count ||= Commit::diff_line_count(self.diffs)
    @diff_line_count
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
    title_end = safe_message.index(/\n/)
    @description ||= if (!title_end && safe_message.length > 100) || (title_end && title_end > 100)
                    "&hellip;".html_safe << safe_message[80..-1]
                  else
                    safe_message.split(/\n/, 2)[1].try(:chomp)
                  end
  end

  def description?
    description.present?
  end

  # Discover issues should be closed when this commit is pushed to a project's
  # default branch.
  def closes_issues project
    Gitlab::ClosingIssueExtractor.closed_by_message_in_project(safe_message, project)
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
