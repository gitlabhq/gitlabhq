# frozen_string_literal: true

module Integrations
  module ChatMessage
    class GroupMentionMessage < BaseMessage
      ISSUE_KIND = 'issue'
      MR_KIND    = 'merge_request'
      NOTE_KIND  = 'note'

      KNOWN_KINDS = [ISSUE_KIND, MR_KIND, NOTE_KIND].freeze

      def initialize(params)
        super
        params = HashWithIndifferentAccess.new(params)

        @group_name, @group_url = params[:mentioned].values_at(:name, :url)
        @detail = nil

        obj_attr = params[:object_attributes]
        obj_kind = obj_attr[:object_kind]
        raise NotImplementedError unless KNOWN_KINDS.include?(obj_kind)

        case obj_kind
        when 'issue'
          @source_name, @title = get_source_for_issue(obj_attr)
          @detail = obj_attr[:description]
        when 'merge_request'
          @source_name, @title = get_source_for_merge_request(obj_attr)
          @detail = obj_attr[:description]
        when 'note'
          if params[:commit]
            @source_name, @title = get_source_for_commit(params[:commit])
          elsif params[:issue]
            @source_name, @title = get_source_for_issue(params[:issue])
          elsif params[:merge_request]
            @source_name, @title = get_source_for_merge_request(params[:merge_request])
          else
            raise NotImplementedError
          end

          @detail = obj_attr[:note]
        end

        @source_url = obj_attr[:url]
      end

      def attachments
        if markdown
          detail
        else
          [{ text: format(detail), color: attachment_color }]
        end
      end

      def activity
        {
          title: "Group #{group_link} was mentioned in #{source_link}",
          subtitle: "of #{project_link}",
          text: strip_markup(formatted_title),
          image: user_avatar
        }
      end

      private

      attr_reader :group_name, :group_url, :source_name, :source_url, :title, :detail

      def get_source_for_commit(params)
        commit_sha = Commit.truncate_sha(params[:id])
        ["commit #{commit_sha}", params[:title]]
      end

      def get_source_for_issue(params)
        ["issue ##{params[:iid]}", params[:title]]
      end

      def get_source_for_merge_request(params)
        ["merge request !#{params[:iid]}", params[:title]]
      end

      def message
        "Group #{group_link} was mentioned in #{source_link} of #{project_link}: *#{formatted_title}*"
      end

      def formatted_title
        strip_markup(title.lines.first.chomp)
      end

      def group_link
        link(group_name, group_url)
      end

      def source_link
        link(source_name, source_url)
      end

      def project_link
        link(project_name, project_url)
      end
    end
  end
end
