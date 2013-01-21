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
  #  avatar: true will prepend the avatar image
  #  size:   size of the avatar image in px
  def author_link(options = {})
    person_link(options.merge source: :author)
  end

  # Just like #author_link but for the committer.
  def committer_link(options = {})
    person_link(options.merge source: :committer)
  end

  protected

  def no_commit_message
    "--no commit message"
  end

  # Private: Returns a link to a person. If the person has a matching user and
  # is a member of the current @project it will link to the team member page.
  # Otherwise it will link to the person email as specified in the commit.
  #
  # options:
  #  source: one of :author or :committer
  #  avatar: true will prepend the avatar image
  #  size:   size of the avatar image in px
  def person_link(options = {})
    source_name = send "#{options[:source]}_name".to_sym
    source_email = send "#{options[:source]}_email".to_sym
    text = if options[:avatar]
            avatar = h.image_tag h.gravatar_icon(source_email, options[:size]), class: "avatar #{"s#{options[:size]}" if options[:size]}", width: options[:size], alt: ""
            %Q{#{avatar} <span class="commit-#{options[:source]}-name">#{source_name}</span>}
          else
            source_name
          end
    team_member = @project.try(:team_member_by_name_or_email, source_name, source_email)

    if team_member.nil?
      h.mail_to source_email, text.html_safe, class: "commit-#{options[:source]}-link"
    else
      h.link_to text, h.project_team_member_path(@project, team_member), class: "commit-#{options[:source]}-link"
    end
  end
end
