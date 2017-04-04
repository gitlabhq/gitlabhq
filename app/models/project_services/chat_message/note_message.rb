module ChatMessage
  class NoteMessage < BaseMessage
    attr_reader :user_name
    attr_reader :user_avatar
    attr_reader :project_name
    attr_reader :project_url
    attr_reader :note
    attr_reader :note_url
    attr_reader :comment_attrs

    def initialize(params)
      params = HashWithIndifferentAccess.new(params)

      super(params)

      @user_name = params[:user][:name]
      @user_avatar = params[:user][:avatar_url]
      @project_name = params[:project_name]
      @project_url = params[:project_url]

      obj_attr = HashWithIndifferentAccess.new(params[:object_attributes])
      @note = obj_attr[:note]
      @note_url = obj_attr[:url]
      @comment_attrs = comment_params(obj_attr[:noteable_type], params)
    end

    def activity
      MicrosoftTeams::Activity.new(
        "#{user_name} #{link('commented on ' + comment_attrs[:target], note_url)}",
        "to: #{project_link}",
        comment_attrs[:title],
        user_avatar
      ).to_json
    end

    def attachments
      markdown_format ? note : description_message
    end

    private

    def message
      "#{user_name} #{link('commented on ' + comment_attrs[:target], note_url)} in #{project_link}: *#{comment_attrs[:title]}*"
    end

    def comment_params(noteable_type, params)
      params = HashWithIndifferentAccess.new(params)

      case noteable_type
      when "Commit"
        create_commit_note(params[:commit])
      when "Issue"
        create_issue_note(params[:issue])
      when "MergeRequest"
        create_merge_note(params[:merge_request])
      when "Snippet"
        create_snippet_note(params[:snippet])
      end
    end

    def format_title(title)
      title.lines.first.chomp
    end

    def create_issue_note(issue)
      { target: "issue ##{issue[:iid]}", title: format_title(issue[:title]) }
    end

    def create_commit_note(commit)
      commit_sha = Commit.truncate_sha(commit[:id])

      { target: "commit #{commit_sha}", title: format_title(commit[:message]) }
    end

    def create_merge_note(merge_request)
      { target: "merge request !#{merge_request[:iid]}", title: format_title(merge_request[:title]) }
    end

    def create_snippet_note(snippet)
      { target: "snippet ##{snippet[:id]}", title: format_title(snippet[:title]) }
    end

    def description_message
      [{ text: format(note), color: attachment_color }]
    end

    def project_link
      link(project_name, project_url)
    end
  end
end
