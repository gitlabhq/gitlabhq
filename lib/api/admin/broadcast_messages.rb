# frozen_string_literal: true

module API
  module Admin
    class BroadcastMessages < ::API::Base
      include PaginationParams

      feature_category :notifications
      urgency :low

      resource :broadcast_messages do
        helpers do
          def find_message
            System::BroadcastMessage.find(params[:id])
          end
        end

        desc 'Get all broadcast messages' do
          detail 'This feature was introduced in GitLab 8.12.'
          success Entities::System::BroadcastMessage
        end
        params do
          use :pagination
        end
        get do
          messages = System::BroadcastMessage.all.order_id_desc

          present paginate(messages), with: Entities::System::BroadcastMessage
        end

        desc 'Create a broadcast message' do
          detail 'This feature was introduced in GitLab 8.12.'
          success Entities::System::BroadcastMessage
        end
        params do
          requires :message, type: String, desc: 'Message to display'
          optional :starts_at, type: DateTime, desc: 'Starting time', default: -> { Time.zone.now }
          optional :ends_at, type: DateTime, desc: 'Ending time', default: -> { 1.hour.from_now }
          optional :color, type: String, desc: 'Background color (Deprecated. Use "theme" instead.)'
          optional :font, type: String, desc: 'Foreground color (Deprecated. Use "theme" instead.)'
          optional :target_access_levels,
            type: Array[Integer],
            coerce_with: Validations::Types::CommaSeparatedToIntegerArray.coerce,
            values: System::BroadcastMessage::ALLOWED_TARGET_ACCESS_LEVELS,
            desc: 'Target user roles'
          optional :target_path, type: String, desc: 'Target path'
          optional :broadcast_type, type: String, values: System::BroadcastMessage.broadcast_types.keys, desc: 'Broadcast type. Defaults to banner', default: -> {
                                                                                                                                                                'banner'
                                                                                                                                                              }
          optional :dismissable, type: Boolean, desc: 'Is dismissable'
          optional :theme, type: String, values: System::BroadcastMessage.themes.keys, desc: 'The theme for the message'
        end
        post do
          authenticated_as_admin!

          message = System::BroadcastMessage.create(declared_params(include_missing: false))

          if message.persisted?
            present message, with: Entities::System::BroadcastMessage
          else
            render_validation_error!(message)
          end
        end

        desc 'Get a specific broadcast message' do
          detail 'This feature was introduced in GitLab 8.12.'
          success Entities::System::BroadcastMessage
        end
        params do
          requires :id, type: Integer, desc: 'Broadcast message ID'
        end
        get ':id' do
          message = find_message

          present message, with: Entities::System::BroadcastMessage
        end

        desc 'Update a broadcast message' do
          detail 'This feature was introduced in GitLab 8.12.'
          success Entities::System::BroadcastMessage
        end
        params do
          requires :id, type: Integer, desc: 'Broadcast message ID'
          optional :message, type: String, desc: 'Message to display'
          optional :starts_at, type: DateTime, desc: 'Starting time'
          optional :ends_at, type: DateTime, desc: 'Ending time'
          optional :color, type: String, desc: 'Background color (Deprecated. Use "theme" instead.)'
          optional :font, type: String, desc: 'Foreground color (Deprecated. Use "theme" instead.)'
          optional :target_access_levels,
            type: Array[Integer],
            coerce_with: Validations::Types::CommaSeparatedToIntegerArray.coerce,
            values: System::BroadcastMessage::ALLOWED_TARGET_ACCESS_LEVELS,
            desc: 'Target user roles'
          optional :target_path, type: String, desc: 'Target path'
          optional :broadcast_type, type: String, values: System::BroadcastMessage.broadcast_types.keys,
            desc: 'Broadcast Type'
          optional :dismissable, type: Boolean, desc: 'Is dismissable'
          optional :theme, type: String, values: System::BroadcastMessage.themes.keys, desc: 'The theme for the message'
        end
        put ':id' do
          authenticated_as_admin!

          message = find_message

          if message.update(declared_params(include_missing: false))
            present message, with: Entities::System::BroadcastMessage
          else
            render_validation_error!(message)
          end
        end

        desc 'Delete a broadcast message' do
          detail 'This feature was introduced in GitLab 8.12.'
          success Entities::System::BroadcastMessage
        end
        params do
          requires :id, type: Integer, desc: 'Broadcast message ID'
        end
        delete ':id' do
          authenticated_as_admin!

          message = find_message

          destroy_conditionally!(message)
        end
      end
    end
  end
end
