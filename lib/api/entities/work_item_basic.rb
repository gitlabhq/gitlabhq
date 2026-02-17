# frozen_string_literal: true

module API
  module Entities
    class WorkItemBasic < Grape::Entity
      include ::API::Entities::WorkItems::ConditionalExposureHelpers
      include ::Gitlab::Utils::StrongMemoize

      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :global_id,
        documentation: { type: 'String', example: 'gid://gitlab/WorkItem/1' } do |work_item|
        work_item.to_gid.to_s
      end
      expose :iid,
        documentation: { type: 'Integer', example: 1 }
      expose :title, documentation: { type: 'String', example: 'Fix the bug' }
      expose_field :state,
        documentation: { type: 'String', example: 'opened' }
      expose_field :confidential,
        documentation: { type: 'Boolean', example: false }
      expose_field :imported?, as: :imported,
        documentation: { type: 'Boolean', example: false }
      expose_field :hidden?, as: :hidden,
        documentation: { type: 'Boolean', example: false }
      expose_field :lock_version,
        documentation: { type: 'Integer', example: 0 }
      expose_field :created_at,
        documentation: { type: 'DateTime', example: '2022-08-17T12:46:35.053Z' }
      expose_field :updated_at,
        documentation: { type: 'DateTime', example: '2022-11-14T17:22:01.470Z' }
      expose_field :closed_at,
        documentation: { type: 'DateTime', example: '2022-11-15T08:30:55.232Z' },
        expose_nil: true
      expose_field :title_html,
        documentation: { type: 'String', example: '<p>Fix the bug</p>' },
        expose_nil: true

      expose_field :author,
        using: ::API::Entities::UserBasic,
        documentation: { type: 'Entities::UserBasic' }

      expose_field :work_item_type, as: :work_item_type, using: ::API::Entities::WorkItems::Type,
        documentation: { type: 'Entities::WorkItems::Type' },
        expose_nil: true do |work_item, _options|
        work_item.work_item_type
      end

      expose_field :create_note_email,
        documentation: { type: 'String', example: 'issue-1@example.com' },
        expose_nil: true do |work_item, options|
        work_item.creatable_note_email_address(options[:current_user])
      end

      expose_field :duplicated_to_work_item_url,
        documentation: { type: 'String', example: 'https://gitlab.example.com/groups/gitlab-org/-/work_items/2' },
        expose_nil: true do |_work_item|
        work_item_presenter.duplicated_to_work_item_url
      end

      expose_field :moved_to_work_item_url,
        documentation: { type: 'String', example: 'https://gitlab.example.com/groups/gitlab-org/-/work_items/3' },
        expose_nil: true do |_work_item|
        work_item_presenter.moved_to_work_item_url
      end

      expose_field :reference,
        documentation: { type: 'String', example: 'gitlab-org#1' } do |work_item|
        work_item.to_reference(full: true)
      end

      expose_field :web_url,
        documentation: { type: 'String',
                         example: 'https://gitlab.example.com/groups/gitlab-org/-/work_items/1' },
        if: ->(_work_item, options) { options.fetch(:include_web_url, true) } do |work_item|
        Gitlab::UrlBuilder.build(work_item)
      end

      expose_field :web_path,
        documentation: { type: 'String', example: '/groups/gitlab-org/-/work_items/1' },
        if: ->(_work_item, options) { options.fetch(:include_web_path, true) } do |work_item|
        Gitlab::UrlBuilder.build(work_item, only_path: true)
      end

      expose_field :user_permissions,
        using: ::API::Entities::WorkItems::Permissions,
        documentation: { type: 'Entities::WorkItems::Permissions' } do |work_item|
        work_item
      end

      expose_field :features,
        using: ::API::Entities::WorkItems::Features::Entity,
        documentation: { type: 'Entities::WorkItems::Features::Entity' },
        expose_nil: true,
        if: ->(_work_item, options) { options[:requested_features].present? } do |work_item|
        work_item
      end

      private

      def work_item_presenter
        WorkItemPresenter.new(object, current_user: current_user)
      end
      strong_memoize_attr :work_item_presenter

      def current_user
        options[:current_user]
      end
    end
  end
end
