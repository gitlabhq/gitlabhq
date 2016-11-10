module API
  class BroadcastMessages < Grape::API
    before { authenticate! }
    before { authenticated_as_admin! }

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
        optional :page,     type: Integer, desc: 'Current page number'
        optional :per_page, type: Integer, desc: 'Number of messages per page'
      end
      get do
        messages = BroadcastMessage.all

        present paginate(messages), with: Entities::BroadcastMessage
      end

      desc 'Create a broadcast message' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::BroadcastMessage
      end
      params do
        requires :message,   type: String,   desc: 'Message to display'
        optional :starts_at, type: DateTime, desc: 'Starting time', default: -> { Time.zone.now }
        optional :ends_at,   type: DateTime, desc: 'Ending time',   default: -> { 1.hour.from_now }
        optional :color,     type: String,   desc: 'Background color'
        optional :font,      type: String,   desc: 'Foreground color'
      end
      post do
        create_params = declared(params, include_missing: false).to_h
        message = BroadcastMessage.create(create_params)

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
        requires :id,        type: Integer,  desc: 'Broadcast message ID'
        optional :message,   type: String,   desc: 'Message to display'
        optional :starts_at, type: DateTime, desc: 'Starting time'
        optional :ends_at,   type: DateTime, desc: 'Ending time'
        optional :color,     type: String,   desc: 'Background color'
        optional :font,      type: String,   desc: 'Foreground color'
      end
      put ':id' do
        message = find_message
        update_params = declared(params, include_missing: false).to_h

        if message.update(update_params)
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
        message = find_message

        present message.destroy, with: Entities::BroadcastMessage
      end
    end
  end
end
