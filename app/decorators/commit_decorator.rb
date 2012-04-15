class CommitDecorator < ApplicationDecorator
  decorates :commit

  # Returns the commits title.
  #
  # Usually, the commit title is the first line of the commit message.
  # In case this first line is longer than 80 characters, it is cut off
  # after 70 characters and ellipses (`&hellp;`) are appended.
  def title
    title_end = safe_message.index(/\n/)
    if (!title_end && safe_message.length > 80) || (title_end && title_end > 80)
      safe_message[0..69] << "&hellip;".html_safe
    else
      safe_message.split(/\n/, 2).first
    end
  end

  # Returns the commits description
  #
  # cut off, ellipses (`&hellp;`) are prepended to the commit message.
  def description
    title_end = safe_message.index(/\n/)
    if (!title_end && safe_message.length > 80) || (title_end && title_end > 80)
      "&hellip;".html_safe << safe_message[70..-1]
    else
      safe_message.split(/\n/, 2)[1].try(:chomp)
    end
  end

  def breadcrumbs

  end
end
