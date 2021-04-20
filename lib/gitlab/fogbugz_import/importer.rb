# frozen_string_literal: true

module Gitlab
  module FogbugzImport
    class Importer
      attr_reader :project, :repo

      def initialize(project)
        @project = project

        import_data = project.import_data.try(:data)
        repo_data = import_data['repo'] if import_data
        if repo_data
          @repo = FogbugzImport::Repository.new(repo_data)
          @known_labels = Set.new
        else
          raise Projects::ImportService::Error, "Unable to find project import data credentials for project ID: #{@project.id}"
        end
      end

      def execute
        return true unless repo.valid?

        client = Gitlab::FogbugzImport::Client.new(token: fb_session[:token], uri: fb_session[:uri])

        @cases = client.cases(@repo.id.to_i)
        @categories = client.categories

        import_cases

        true
      end

      private

      def fb_session
        @import_data_credentials ||= project.import_data.credentials[:fb_session] if project.import_data && project.import_data.credentials
      end

      def user_map
        @user_map ||= begin
          user_map = {}
          import_data = project.import_data.try(:data)
          stored_user_map = import_data['user_map'] if import_data
          user_map.update(stored_user_map) if stored_user_map

          user_map
        end
      end

      def import_labels
        @categories['categories']['category'].each do |label|
          create_label(label['sCategory'])
          @known_labels << name
        end
      end

      def nice_label_color(name)
        case name
        when 'Blocker'
          '#ff0000'
        when 'Crash'
          '#ffcfcf'
        when 'Major'
          '#deffcf'
        when 'Minor'
          '#cfe9ff'
        when 'Bug'
          '#d9534f'
        when 'Feature'
          '#44ad8e'
        when 'Technical Task'
          '#4b6dd0'
        else
          '#e2e2e2'
        end
      end

      def create_label(name)
        params = { title: name, color: nice_label_color(name) }
        ::Labels::FindOrCreateService.new(nil, project, params).execute(skip_authorization: true)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def user_info(person_id)
        user_hash = user_map[person_id.to_s]

        user_name = ''
        gitlab_id = nil

        unless user_hash.nil?
          user_name = user_hash['name']
          if user = User.find_by(id: user_hash['gitlab_user'])
            user_name = "@#{user.username}"
            gitlab_id = user.id
          end
        end

        { name: user_name, gitlab_id: gitlab_id }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def import_cases
        return unless @cases

        while bug = @cases.shift
          author = user_info(bug['ixPersonOpenedBy'])[:name]
          date = DateTime.parse(bug['dtOpened'])

          comments = bug['events']['event']

          content = format_content(opened_content(comments))
          body = format_issue_body(author, date, content)

          labels = []
          [bug['sCategory'], bug['sPriority']].each do |label|
            unless label.blank?
              labels << label

              unless @known_labels.include?(label)
                create_label(label)
                @known_labels << label
              end
            end
          end

          assignee_id = user_info(bug['ixPersonAssignedTo'])[:gitlab_id]
          author_id = user_info(bug['ixPersonOpenedBy'])[:gitlab_id] || project.creator_id

          issue = Issue.create!(
            iid:          bug['ixBug'],
            project_id:   project.id,
            title:        bug['sTitle'],
            description:  body,
            author_id:    author_id,
            assignee_ids: [assignee_id],
            state:        bug['fOpen'] == 'true' ? 'opened' : 'closed',
            created_at:   date,
            updated_at:   DateTime.parse(bug['dtLastUpdated'])
          )

          issue_labels = ::LabelsFinder.new(nil, project_id: project.id, title: labels).execute(skip_authorization: true)
          issue.update_attribute(:label_ids, issue_labels.pluck(:id))

          import_issue_comments(issue, comments)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def opened_content(comments)
        while comment = comments.shift
          if comment['sVerb'] == 'Opened'
            return comment['s']
          end
        end
        ''
      end

      def import_issue_comments(issue, comments)
        Note.transaction do
          while comment = comments.shift
            verb = comment['sVerb']

            next if verb == 'Opened'

            content = format_content(comment['s'])
            attachments = format_attachments(comment['rgAttachments'])
            updates = format_updates(comment)

            next if content.blank? && attachments.empty? && updates.empty?

            author = user_info(comment['ixPerson'])[:name]
            author_id = user_info(comment['ixPerson'])[:gitlab_id] || project.creator_id
            date = DateTime.parse(comment['dt'])

            body = format_issue_comment_body(
              comment['ixBugEvent'],
              author,
              date,
              content,
              attachments,
              updates
            )

            note = Note.create!(
              project_id:     project.id,
              noteable_type:  "Issue",
              noteable_id:    issue.id,
              author_id:      author_id,
              note:           body
            )

            note.update_attribute(:created_at, date)
            note.update_attribute(:updated_at, date)
          end
        end
      end

      def linkify_issues(str)
        str = str.gsub(/([Ii]ssue) ([0-9]+)/, '\1 #\2')
        str.gsub(/([Cc]ase) ([0-9]+)/, '\1 #\2')
      end

      def escape_for_markdown(str)
        str = str.gsub(/^#/, "\\#")
        str = str.gsub(/^-/, "\\-")
        str = str.gsub("`", "\\~")
        str = str.delete("\r")
        str.gsub("\n", "  \n")
      end

      def format_content(raw_content)
        return raw_content if raw_content.nil?

        linkify_issues(escape_for_markdown(raw_content))
      end

      def format_attachments(raw_attachments)
        return [] unless raw_attachments

        attachments = case raw_attachments['attachment']
                      when Array
                        raw_attachments['attachment']
                      when Hash
                        [raw_attachments['attachment']]
                      else
                        []
                      end

        attachments.map! { |a| format_attachment(a) }
        attachments.compact
      end

      def format_attachment(attachment)
        link = build_attachment_url(attachment['sURL'])

        res = ::Projects::DownloadService.new(project, link).execute

        return if res.nil?

        res[:markdown]
      end

      def build_attachment_url(rel_url)
        uri = fb_session[:uri]
        token = fb_session[:token]
        "#{uri}/#{rel_url}&token=#{token}"
      end

      def format_updates(comment)
        updates = []

        if comment['sChanges']
          updates << "*Changes: #{linkify_issues(comment['sChanges'].chomp)}*"
        end

        if comment['evtDescription']
          updates << "*#{comment['evtDescription']}*"
        end

        updates
      end

      def format_issue_body(author, date, content)
        body = []
        body << "*By #{author} on #{date} (imported from FogBugz)*"
        body << '---'

        if content.blank?
          content = '*(No description has been entered for this issue)*'
        end

        body << content

        body.join("\n\n")
      end

      def format_issue_comment_body(id, author, date, content, attachments, updates)
        body = []
        body << "*By #{author} on #{date} (imported from FogBugz)*"
        body << '---'

        if content.blank?
          content = "*(No comment has been entered for this change)*"
        end

        body << content

        if updates.any?
          body << '---'
          body += updates
        end

        if attachments.any?
          body << '---'
          body += attachments
        end

        body.join("\n\n")
      end
    end
  end
end
