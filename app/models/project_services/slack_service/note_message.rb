class SlackService
  class NoteMessage < BaseMessage
    attr_reader :message
    attr_reader :user_name
    attr_reader :project_name
    attr_reader :project_link
    attr_reader :note
    attr_reader :note_url
    attr_reader :title

    def initialize(params)
      params = HashWithIndifferentAccess.new(params)
      @user_name = params[:user][:name]
      @project_name = params[:project_name]
      @project_url = params[:project_url]

      obj_attr = params[:object_attributes]
      obj_attr = HashWithIndifferentAccess.new(obj_attr)
      @note = obj_attr[:note]
      @note_url = obj_attr[:url]
      noteable_type = obj_attr[:noteable_type]

      case noteable_type
      when "Commit"
        create_commit_note(HashWithIndifferentAccess.new(params[:commit]))
      when "Issue"
        create_issue_note(HashWithIndifferentAccess.new(params[:issue]))
      when "MergeRequest"
        create_merge_note(HashWithIndifferentAccess.new(params[:merge_request]))
      when "Snippet"
        create_snippet_note(HashWithIndifferentAccess.new(params[:snippet]))
      end
    end

    def attachments
      description_message
    end

    private

    def format_title(title)
      title.lines.first.chomp
    end

    def create_commit_note(commit)
      commit_sha = commit[:id]
      commit_sha = Commit.truncate_sha(commit_sha)
      commented_on_message(
        "[commit #{commit_sha}](#{@note_url})",
        format_title(commit[:message]))
    end

    def create_issue_note(issue)
      commented_on_message(
        "[issue ##{issue[:iid]}](#{@note_url})",
        format_title(issue[:title]))
    end

    def create_merge_note(merge_request)
      commented_on_message(
        "[merge request ##{merge_request[:iid]}](#{@note_url})",
        format_title(merge_request[:title]))
    end

    def create_snippet_note(snippet)
      commented_on_message(
        "[snippet ##{snippet[:id]}](#{@note_url})",
        format_title(snippet[:title]))
    end

    def description_message
      [{ text: format(@note), color: attachment_color }]
    end

    def project_link
      "[#{@project_name}](#{@project_url})"
    end

    def commented_on_message(target_link, title)
      @message = "#{@user_name} commented on #{target_link} in #{project_link}: *#{title}*"
    end
  end
end
