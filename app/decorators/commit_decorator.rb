class CommitDecorator < ApplicationDecorator
  decorates :commit

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
  # In case this first line is longer than 80 characters, it is cut off
  # after 70 characters and ellipses (`&hellp;`) are appended.
  def title
    title = safe_message

    return no_commit_message if title.blank?

    title_end = title.index(/\n/)
    if (!title_end && title.length > 80) || (title_end && title_end > 80)
      title[0..69] << "&hellip;".html_safe
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
    if (!title_end && description.length > 80) || (title_end && title_end > 80)
      "&hellip;".html_safe << description[70..-1]
    else
      description.split(/\n/, 2)[1].try(:chomp)
    end
  end

  protected

  def no_commit_message
    "--no commit message"
  end
end
