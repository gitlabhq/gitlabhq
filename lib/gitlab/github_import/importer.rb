module Gitlab
  module GithubImport
    class Importer
      attr_reader :project

      def initialize(project)
        @project = project
        @formatter = Gitlab::ImportFormatter.new
      end

      def execute
        client = octo_client(project.creator.github_access_token)

        #Issues && Comments
        client.list_issues(project.import_source, state: :all).each do |issue|
          if issue.pull_request.nil?

            body = @formatter.author_line(issue.user.login, issue.body)

            if issue.comments > 0
              body += @formatter.comments_header

              client.issue_comments(project.import_source, issue.number).each do |c|
                body += @formatter.comment_to_md(c.user.login, c.created_at, c.body)
              end
            end

            project.issues.create!(
              description: body,
              title: issue.title,
              state: issue.state == 'closed' ? 'closed' : 'opened',
              author_id: gl_user_id(project, issue.user.id)
            )
          end
        end
      end

      private

      def octo_client(access_token)
        ::Octokit.auto_paginate = true
        ::Octokit::Client.new(access_token: access_token)
      end

      def gl_user_id(project, github_id)
        user = User.joins(:identities).
          find_by("identities.extern_uid = ? AND identities.provider = 'github'", github_id.to_s)
        (user && user.id) || project.creator_id
      end
    end
  end
end
