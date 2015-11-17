module Gitlab
  module Email
    class RepositoryPush
      attr_reader :compare, :reverse_compare, :send_from_cmmitter_email, :disable_diffs,
                  :action, :ref, :author_id

      def initialize(project_id, recipient, opts = {})
        raise ArgumentError, 'Missing arguments: author_id, ref, action' unless
          opts[:author_id] && opts[:ref] && opts[:action]

        @project_id = project_id
        @recipient = recipient

        @author_id = opts[:author_id]
        @ref = opts[:ref]
        @action = opts[:action]

        @compare = opts[:compare] || nil
        @reverse_compare = opts[:reverse_compare] || false
        @send_from_committer_email = opts[:send_from_committer_email] || false
        @disable_diffs = opts[:disable_diffs] || false

        @author = author
        @project = project
        @commits = commits
        @diffs = diffs
        @ref_name = ref_name
        @ref_type = ref_type
        @action_name = action_name
      end

      def project
        Project.find(@project_id)
      end

      def author
        User.find(@author_id)
      end

      def commits
        Commit.decorate(@compare.commits, @project) if @compare
      end

      def diffs
        @compare.diffs if @compare
      end

      def action_name
        case @action
        when :create
          'pushed new'
        when :delete
          'deleted'
        else
          'pushed to'
        end
      end

      def subject
        subject_text = '[Git]'
        subject_text << "[#{@project.path_with_namespace}]"
        subject_text << "[#{@ref_name}]" if @action == :push
        subject_text << ' '

        if @action == :push
          if @commits.length > 1
            subject_text << "Deleted " if @reverse_compare
            subject_text << "#{@commits.length} commits: #{@commits.first.title}"
          else
            subject_text << "Deleted 1 commit: " if @reverse_compare
            subject_text << @commits.first.title
          end
        end

        subject_action = @action_name.dup
        subject_action[0] = subject_action[0].capitalize
        subject_text << "#{subject_action} #{@ref_type} #{@ref_name}"
      end

      def ref_name
        Gitlab::Git.ref_name(@ref)
      end

      def ref_type
        Gitlab::Git.tag_ref?(@ref) ? 'tag' : 'branch'
      end

      def target_url
        if action == :push
          if @commits.length > 1
            namespace_project_compare_url(@project.namespace,
                                          @project,
                                          from: Commit.new(@compare.base, @project),
                                          to:   Commit.new(@compare.head, @project))
          else
            namespace_project_commit_url(@project.namespace,
                                         @project, @commits.first)
          end
        end

        if action != :delete && action != :push
          namespace_project_tree_url(@project.namespace,
                                     @project, @ref_name)
        end
      end

      def reply_to
        if @send_from_committer_email && can_send_from_user_email?(@author)
          @author.email
        else
          Gitlab.config.gitlab.email_reply_to
        end
      end
    end
  end
end
