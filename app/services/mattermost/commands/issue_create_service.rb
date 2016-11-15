module Mattermost
  module Commands
    class IssueCreateService < IssueService
      def execute
        title, description = parse_command

        present Issues::CreateService.new(project, current_user, title: title, description: description).execute
      end

      private

      def parse_command
        match = params[:text].match(/\Aissue create (?<title>.*)\n*/)
        title = match[:title]
        description = match.post_match

        [title, description]
      end
    end
  end
end
