module Gitlab
  module GoogleCodeImport
    class Importer
      attr_reader :project, :repo, :closed_statuses

      NICE_LABEL_COLOR_HASH =
        {
          'Status: New'        => '#428bca',
          'Status: Accepted'   => '#5cb85c',
          'Status: Started'    => '#8e44ad',
          'Priority: Critical' => '#ffcfcf',
          'Priority: High'     => '#deffcf',
          'Priority: Medium'   => '#fff5cc',
          'Priority: Low'      => '#cfe9ff',
          'Type: Defect'       => '#d9534f',
          'Type: Enhancement'  => '#44ad8e',
          'Type: Task'         => '#4b6dd0',
          'Type: Review'       => '#8e44ad',
          'Type: Other'        => '#7f8c8d'
        }.freeze

      def initialize(project)
        @project = project

        import_data = project.import_data.try(:data)
        repo_data = import_data["repo"] if import_data
        @repo = GoogleCodeImport::Repository.new(repo_data)

        @closed_statuses = []
        @known_labels = Set.new
      end

      def execute
        return true unless repo.valid?

        import_status_labels

        import_labels

        import_issues

        true
      end

      private

      def user_map
        @user_map ||= begin
          user_map = Hash.new do |hash, user|
            # Replace ... by \.\.\., so `johnsm...@gmail.com` isn't autolinked.
            Client.mask_email(user).sub("...", "\\.\\.\\.")
          end

          import_data = project.import_data.try(:data)
          stored_user_map = import_data["user_map"] if import_data
          user_map.update(stored_user_map) if stored_user_map

          user_map
        end
      end

      def import_status_labels
        repo.raw_data["issuesConfig"]["statuses"].each do |status|
          closed = !status["meansOpen"]
          @closed_statuses << status["status"] if closed

          name = nice_status_name(status["status"])
          create_label(name)
          @known_labels << name
        end
      end

      def import_labels
        repo.raw_data["issuesConfig"]["labels"].each do |label|
          name = nice_label_name(label["label"])
          create_label(name)
          @known_labels << name
        end
      end

      def import_issues
        return unless repo.issues

        while raw_issue = repo.issues.shift
          author  = user_map[raw_issue["author"]["name"]]
          date    = DateTime.parse(raw_issue["published"]).to_formatted_s(:long)

          comments = raw_issue["comments"]["items"]
          issue_comment = comments.shift

          content     = format_content(issue_comment["content"])
          attachments = format_attachments(raw_issue["id"], 0, issue_comment["attachments"])

          body = format_issue_body(author, date, content, attachments)
          labels = import_issue_labels(raw_issue)

          assignee_id = nil
          if raw_issue.key?("owner")
            username = user_map[raw_issue["owner"]["name"]]

            if username.start_with?("@")
              username = username[1..-1]

              if user = User.find_by(username: username)
                assignee_id = user.id
              end
            end
          end

          issue = Issue.create!(
            iid:          raw_issue['id'],
            project_id:   project.id,
            title:        raw_issue['title'],
            description:  body,
            author_id:    project.creator_id,
            assignee_ids: [assignee_id],
            state:        raw_issue['state'] == 'closed' ? 'closed' : 'opened'
          )

          issue_labels = ::LabelsFinder.new(nil, project_id: project.id, title: labels).execute(skip_authorization: true)
          issue.update_attribute(:label_ids, issue_labels.pluck(:id))

          import_issue_comments(issue, comments)
        end
      end

      def import_issue_labels(raw_issue)
        labels = []

        raw_issue["labels"].each do |label|
          name = nice_label_name(label)
          labels << name

          unless @known_labels.include?(name)
            create_label(name)
            @known_labels << name
          end
        end

        labels << nice_status_name(raw_issue["status"])
        labels
      end

      def import_issue_comments(issue, comments)
        Note.transaction do
          while raw_comment = comments.shift
            next if raw_comment.key?("deletedBy")

            content     = format_content(raw_comment["content"])
            updates     = format_updates(raw_comment["updates"])
            attachments = format_attachments(issue.iid, raw_comment["id"], raw_comment["attachments"])

            next if content.blank? && updates.blank? && attachments.blank?

            author  = user_map[raw_comment["author"]["name"]]
            date    = DateTime.parse(raw_comment["published"]).to_formatted_s(:long)

            body = format_issue_comment_body(
              raw_comment["id"],
              author,
              date,
              content,
              updates,
              attachments
            )

            # Needs to match order of `comment_columns` below.
            Note.create!(
              project_id:     project.id,
              noteable_type:  "Issue",
              noteable_id:    issue.id,
              author_id:      project.creator_id,
              note:           body
            )
          end
        end
      end

      def nice_label_color(name)
        NICE_LABEL_COLOR_HASH[name] ||
          case name
          when /\AComponent:/
            '#fff39e'
          when /\AOpSys:/
            '#e2e2e2'
          when /\AMilestone:/
            '#fee3ff'
          when *closed_statuses.map { |s| nice_status_name(s) }
            '#cfcfcf'
          else
            '#e2e2e2'
          end
      end

      def nice_label_name(name)
        name.sub("-", ": ")
      end

      def nice_status_name(name)
        "Status: #{name}"
      end

      def linkify_issues(s)
        s = s.gsub(/([Ii]ssue) ([0-9]+)/, '\1 #\2')
        s = s.gsub(/([Cc]omment) #([0-9]+)/, '\1 \2')
        s
      end

      def escape_for_markdown(s)
        # No headings and lists
        s = s.gsub(/^#/, "\\#")
        s = s.gsub(/^-/, "\\-")

        # No inline code
        s = s.gsub("`", "\\`")

        # Carriage returns make me sad
        s = s.delete("\r")

        # Markdown ignores single newlines, but we need them as <br />.
        s = s.gsub("\n", "  \n")

        s
      end

      def create_label(name)
        params = { name: name, color: nice_label_color(name) }
        ::Labels::FindOrCreateService.new(nil, project, params).execute(skip_authorization: true)
      end

      def format_content(raw_content)
        linkify_issues(escape_for_markdown(raw_content))
      end

      def format_updates(raw_updates)
        updates = []

        if raw_updates.key?("status")
          updates << "*Status: #{raw_updates["status"]}*"
        end

        if raw_updates.key?("owner")
          updates << "*Owner: #{user_map[raw_updates["owner"]]}*"
        end

        if raw_updates.key?("cc")
          cc = raw_updates["cc"].map do |l|
            deleted = l.start_with?("-")
            l = l[1..-1] if deleted
            l = user_map[l]
            l = "~~#{l}~~" if deleted
            l
          end

          updates << "*Cc: #{cc.join(", ")}*"
        end

        if raw_updates.key?("labels")
          labels = raw_updates["labels"].map do |l|
            deleted = l.start_with?("-")
            l = l[1..-1] if deleted
            l = nice_label_name(l)
            l = "~~#{l}~~" if deleted
            l
          end

          updates << "*Labels: #{labels.join(", ")}*"
        end

        if raw_updates.key?("mergedInto")
          updates << "*Merged into: ##{raw_updates["mergedInto"]}*"
        end

        if raw_updates.key?("blockedOn")
          blocked_ons = raw_updates["blockedOn"].map do |raw_blocked_on|
            format_blocking_updates(raw_blocked_on)
          end

          updates << "*Blocked on: #{blocked_ons.join(", ")}*"
        end

        if raw_updates.key?("blocking")
          blockings = raw_updates["blocking"].map do |raw_blocked_on|
            format_blocking_updates(raw_blocked_on)
          end

          updates << "*Blocking: #{blockings.join(", ")}*"
        end

        updates
      end

      def format_blocking_updates(raw_blocked_on)
        name, id = raw_blocked_on.split(":", 2)

        deleted = name.start_with?("-")
        name = name[1..-1] if deleted

        text =
          if name == project.import_source
            "##{id}"
          else
            "#{project.namespace.full_path}/#{name}##{id}"
          end

        text = "~~#{text}~~" if deleted
        text
      end

      def format_attachments(issue_id, comment_id, raw_attachments)
        return [] unless raw_attachments

        raw_attachments.map do |attachment|
          next if attachment["isDeleted"]

          filename = attachment["fileName"]
          link = "https://storage.googleapis.com/google-code-attachments/#{@repo.name}/issue-#{issue_id}/comment-#{comment_id}/#{filename}"

          text = "[#{filename}](#{link})"
          text = "!#{text}" if filename =~ /\.(png|jpg|jpeg|gif|bmp|tiff)\z/i
          text
        end.compact
      end

      def format_issue_comment_body(id, author, date, content, updates, attachments)
        body = []
        body << "*Comment #{id} by #{author} on #{date}*"
        body << "---"

        if content.blank?
          content = "*(No comment has been entered for this change)*"
        end

        body << content

        if updates.any?
          body << "---"
          body += updates
        end

        if attachments.any?
          body << "---"
          body += attachments
        end

        body.join("\n\n")
      end

      def format_issue_body(author, date, content, attachments)
        body = []
        body << "*By #{author} on #{date} (imported from Google Code)*"
        body << "---"

        if content.blank?
          content = "*(No description has been entered for this issue)*"
        end

        body << content

        if attachments.any?
          body << "---"
          body += attachments
        end

        body.join("\n\n")
      end
    end
  end
end
