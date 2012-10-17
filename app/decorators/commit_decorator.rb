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

  # Returns a link to the commit author. If the author has a matching user and
  # is a member of the current @project it will link to the team member page.
  # Otherwise it will link to the author email as specified in the commit.
  #
  # options:
  #  avatar: true   will prepend avatar image
  def author_link(options)
    text = if options[:avatar]
            avatar = h.image_tag h.gravatar_icon(author_email), class: "avatar", width: 16
            "#{avatar} #{author_name}"
          else
            author_name
          end
    team_member = @project.try(:team_member_by_name_or_email, author_name, author_email)

    if team_member.nil?
      h.mail_to author_email, text.html_safe, class: "commit-author-link"
    else
      h.link_to text, h.project_team_member_path(@project, team_member), class: "commit-author-link"
    end
  end

  protected

  def no_commit_message
    "--no commit message"
  end
end
