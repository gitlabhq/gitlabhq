module Gitlab
  module Email
    module Message
      class RepositoryPush
        attr_accessor :recipient
        attr_reader :author_id, :ref, :action

        include Gitlab::Application.routes.url_helpers

        delegate :namespace, :name_with_namespace, to: :project, prefix: :project
        delegate :name, to: :author, prefix: :author
        delegate :username, to: :author, prefix: :author

        def initialize(notify, project_id, recipient, opts = {})
          raise ArgumentError, 'Missing options: author_id, ref, action' unless
            opts[:author_id] && opts[:ref] && opts[:action]

          @notify = notify
          @project_id = project_id
          @recipient = recipient
          @opts = opts.dup

          @author_id = @opts.delete(:author_id)
          @ref = @opts.delete(:ref)
          @action = @opts.delete(:action)
        end

        def project
          @project ||= Project.find(@project_id)
        end

        def author
          @author ||= User.find(@author_id)
        end

        def commits
          @commits ||= (Commit.decorate(compare.commits, project) if compare)
        end

        def diffs
          @diffs ||= (compare.diffs if compare)
        end

        def diffs_count
          diffs.count if diffs
        end

        def compare
          @opts[:compare]
        end

        def compare_timeout
          diffs.overflow? if diffs
        end

        def reverse_compare?
          @opts[:reverse_compare] || false
        end

        def disable_diffs?
          @opts[:disable_diffs] || false
        end

        def send_from_committer_email?
          @opts[:send_from_committer_email] || false
        end

        def action_name
          @action_name ||=
            case @action
            when :create
              'pushed new'
            when :delete
              'deleted'
            else
              'pushed to'
            end
        end

        def ref_name
          @ref_name ||= Gitlab::Git.ref_name(@ref)
        end

        def ref_type
          @ref_type ||= Gitlab::Git.tag_ref?(@ref) ? 'tag' : 'branch'
        end

        def target_url
          if @action == :push && commits
            if commits.length > 1
              namespace_project_compare_url(project_namespace,
                                            project,
                                            from: Commit.new(compare.base, project),
                                            to:   Commit.new(compare.head, project))
            else
              namespace_project_commit_url(project_namespace,
                                           project, commits.first)
            end
          else
            unless @action == :delete
              namespace_project_tree_url(project_namespace,
                                         project, ref_name)
            end
          end
        end

        def reply_to
          if send_from_committer_email? && @notify.can_send_from_user_email?(author)
            author.email
          else
            Gitlab.config.gitlab.email_reply_to
          end
        end

        def subject
          subject_text = '[Git]'
          subject_text << "[#{project.path_with_namespace}]"
          subject_text << "[#{ref_name}]" if @action == :push
          subject_text << ' '

          if @action == :push && commits
            if commits.length > 1
              subject_text << "Deleted " if reverse_compare?
              subject_text << "#{commits.length} commits: #{commits.first.title}"
            else
              subject_text << "Deleted 1 commit: " if reverse_compare?
              subject_text << commits.first.title
            end
          else
            subject_action = action_name.dup
            subject_action[0] = subject_action[0].capitalize
            subject_text << "#{subject_action} #{ref_type} #{ref_name}"
          end
        end
      end
    end
  end
end
