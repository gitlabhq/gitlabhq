module API
  class BroadcastMessages < Grape::API
    include PaginationParams

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
        requires :message,   type: String,   desc: 'Message to display'
        optional :starts_at, type: DateTime, desc: 'Starting time', default: -> { Time.zone.now }
        optional :ends_at,   type: DateTime, desc: 'Ending time',   default: -> { 1.hour.from_now }
        optional :color,     type: String,   desc: 'Background color'
        optional :font,      type: String,   desc: 'Foreground color'
      end
      post do
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
        requires :id,        type: Integer,  desc: 'Broadcast message ID'
        optional :message,   type: String,   desc: 'Message to display'
        optional :starts_at, type: DateTime, desc: 'Starting time'
        optional :ends_at,   type: DateTime, desc: 'Ending time'
        optional :color,     type: String,   desc: 'Background color'
        optional :font,      type: String,   desc: 'Foreground color'
      end
      put ':id' do
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
        message = find_message

        destroy_conditionally!(message)
      end
    end
  end
end
