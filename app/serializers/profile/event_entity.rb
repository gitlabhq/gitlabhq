# frozen_string_literal: true

module Profile
  class EventEntity < Grape::Entity
    include ActionView::Helpers::SanitizeHelper
    include RequestAwareEntity
    include MarkupHelper
    include MergeRequestsHelper
    include EventsHelper

    expose :created_at, if: ->(event) { include_private_event?(event) }
    expose(:action, if: ->(event) { include_private_event?(event) }) { |event| event_action(event) }

    expose :ref, if: ->(event) { event.visible_to_user?(current_user) && event.push_action? } do
      expose(:type) { |event| event.ref_type } # rubocop:disable Style/SymbolProc
      expose(:count) { |event| event.ref_count } # rubocop:disable Style/SymbolProc
      expose(:name) { |event| event.ref_name } # rubocop:disable Style/SymbolProc
      expose(:path) { |event| ref_path(event) }
    end

    expose :commit, if: ->(event) { event.visible_to_user?(current_user) && event.push_action? } do
      expose(:truncated_sha) { |event| Commit.truncate_sha(event.commit_id) }
      expose(:path) { |event| project_commit_path(event.project, event.commit_id) }
      expose(:title) { |event| event_commit_title(event.commit_title) }
      expose(:count) { |event| event.commits_count } # rubocop:disable Style/SymbolProc
      expose(:create_mr_path) { |event| commit_create_mr_path(event) }
      expose(:from_truncated_sha) { |event| commit_from(event) if event.commit_from }
      expose(:to_truncated_sha) { |event| Commit.truncate_sha(event.commit_to) if event.commit_to }

      expose :compare_path, if: ->(event) { event.push_with_commits? && event.commits_count > 1 } do |event|
        project = event.project
        from = event.md_ref? ? event.commit_from : project.default_branch
        project_compare_path(project, from: from, to: event.commit_to)
      end
    end

    expose :author, if: ->(event) { include_private_event?(event) } do
      expose(:id) { |event| event.author.id }
      expose(:name) { |event| event.author.name }
      expose(:path) { |event| event.author.username }
    end

    expose :target, if: ->(event) { event.visible_to_user?(current_user) } do
      expose :target_type

      expose(:title) { |event| event.target_title } # rubocop:disable Style/SymbolProc
      expose :target_url, if: ->(event) { event.target } do |event|
        Gitlab::UrlBuilder.build(event.target, only_path: true)
      end
      expose :reference_link_text, if: ->(event) { event.target&.respond_to?(:reference_link_text) } do |event|
        event.target.reference_link_text
      end
      expose :first_line_in_markdown, if: ->(event) { event.note? && event.target && event.project } do |event|
        first_line_in_markdown(event.target, :note, 150, project: event.project)
      end
      expose :attachment, if: ->(event) { event.note? && event.target&.attachment } do
        expose(:url) { |event| event.target.attachment.url }
      end
    end

    expose :resource_parent, if: ->(event) { event.visible_to_user?(current_user) } do
      expose(:type) { |event| resource_parent_type(event) }
      expose(:full_name) { |event| event.resource_parent&.full_name }
      expose(:full_path) { |event| event.resource_parent&.full_path }
    end

    private

    def current_user
      request.current_user
    end

    def target_user
      request.target_user
    end

    def include_private_event?(event)
      event.visible_to_user?(current_user) || target_user.include_private_contributions?
    end

    def commit_from(event)
      if event.md_ref?
        Commit.truncate_sha(event.commit_from)
      else
        event.project.default_branch
      end
    end

    def event_action(event)
      if event.visible_to_user?(current_user)
        event.action
      elsif target_user.include_private_contributions?
        'private'
      end
    end

    def ref_path(event)
      project = event.project
      commits_link = project_commits_path(project, event.ref_name)
      should_link = if event.tag?
                      project.repository.tag_exists?(event.ref_name)
                    else
                      project.repository.branch_exists?(event.ref_name)
                    end

      should_link ? commits_link : nil
    end

    def commit_create_mr_path(event)
      if event.new_ref? &&
          create_mr_button_from_event?(event) &&
          event.authored_by?(current_user)
        create_mr_path_from_push_event(event)
      end
    end

    def resource_parent_type(event)
      if event.project
        "project"
      elsif event.group
        "group"
      end
    end
  end
end
