# frozen_string_literal: true

module API
  class BroadcastMessages < ::API::Base
    include PaginationParams

    feature_category :navigation

    resource :broadcast_messages do
      helpers do
        def find_message
          BroadcastMessage.find(params[:id])
        end
      end

      desc 'Get all broadcast messages' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::BroadcastMessage
      end
      params do
        use :pagination
      end
      get do
        messages = BroadcastMessage.all.order_id_desc

        present paginate(messages), with: Entities::BroadcastMessage
      end

      desc 'Create a broadcast message' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::BroadcastMessage
      end
      params do
        requires :message, type: String, desc: 'Message to display'
        optional :starts_at, type: DateTime, desc: 'Starting time', default: -> { Time.zone.now }
        optional :ends_at, type: DateTime, desc: 'Ending time', default: -> { 1.hour.from_now }
        optional :color, type: String, desc: 'Background color'
        optional :font, type: String, desc: 'Foreground color'
        optional :target_path, type: String, desc: 'Target path'
        optional :broadcast_type, type: String, values: BroadcastMessage.broadcast_types.keys, desc: 'Broadcast type. Defaults to banner', default: -> { 'banner' }
        optional :dismissable, type: Boolean, desc: 'Is dismissable'
      end
      post do
        authenticated_as_admin!

        message = BroadcastMessage.create(declared_params(include_missing: false))

        if message.persisted?
          present message, with: Entities::BroadcastMessage
        else
          render_validation_error!(message)
        end
      end

      desc 'Get a specific broadcast message' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::BroadcastMessage
      end
      params do
        requires :id, type: Integer, desc: 'Broadcast message ID'
      end
      get ':id' do
        message = find_message

        present message, with: Entities::BroadcastMessage
      end

      desc 'Update a broadcast message' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::BroadcastMessage
      end
      params do
        requires :id, type: Integer, desc: 'Broadcast message ID'
        optional :message, type: String, desc: 'Message to display'
        optional :starts_at, type: DateTime, desc: 'Starting time'
        optional :ends_at, type: DateTime, desc: 'Ending time'
        optional :color, type: String, desc: 'Background color'
        optional :font, type: String, desc: 'Foreground color'
        optional :target_path, type: String, desc: 'Target path'
        optional :broadcast_type, type: String, values: BroadcastMessage.broadcast_types.keys, desc: 'Broadcast Type'
        optional :dismissable, type: Boolean, desc: 'Is dismissable'
      end
      put ':id' do
        authenticated_as_admin!

        message = find_message

        if message.update(declared_params(include_missing: false))
          present message, with: Entities::BroadcastMessage
        else
          render_validation_error!(message)
        end
      end

      desc 'Delete a broadcast message' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::BroadcastMessage
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
