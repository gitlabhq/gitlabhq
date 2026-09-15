# frozen_string_literal: true

module CollaborativeEditing
  class BaseChannel < ApplicationCable::Channel
    MESSAGE_TYPE_SYNC = 'sync'
    MESSAGE_TYPE_AWARENESS = 'awareness'
    MESSAGE_TYPE_SNAPSHOT = 'snapshot'

    MAX_PAYLOAD_BYTES = 1.megabyte

    REVALIDATE_ACCESS_EVERY = 1.minute

    periodically :revalidate_access, every: REVALIDATE_ACCESS_EVERY

    def subscribed
      container = find_container
      return reject unless container && feature_enabled?(container)
      return reject unless authorized?(container)

      document = find_document(container)
      return reject unless document

      @container = container
      @stream_key = document_key(container, document)
      @store = Gitlab::CollaborativeEditing::DocumentStore.new(@stream_key)

      stream_from stream_name
      transmit_initial_state
    end

    def receive(data)
      return unless @stream_key
      return unless valid_payload?(data)
      return if rate_limited?

      case data['type']
      when MESSAGE_TYPE_SYNC
        handle_sync(data)
      when MESSAGE_TYPE_AWARENESS
        broadcast(data, identity: true)
      when MESSAGE_TYPE_SNAPSHOT
        handle_snapshot(data)
      end
    end

    private

    attr_reader :store

    def authorization_scopes
      [:api]
    end

    def find_container
      raise NotImplementedError
    end

    def feature_enabled?(_container)
      raise NotImplementedError
    end

    def authorized?(_container)
      raise NotImplementedError
    end

    def find_document(_container)
      raise NotImplementedError
    end

    def document_key(_container, _document)
      raise NotImplementedError
    end

    def stream_name
      "collaborative_editing:#{@stream_key}"
    end

    def transmit_initial_state
      updates = store.updates

      transmit({
        type: 'init',
        updates: updates,
        seed: updates.empty? && store.claim_seed
      })
    end

    def handle_sync(data)
      result = store.append(data['payload'])

      if result.full?
        transmit({ type: 'document_full' })
      else
        broadcast(data)
      end

      return unless result.compact?

      transmit({ type: 'request_snapshot', token: result.compaction_token })
    end

    def handle_snapshot(data)
      store.replace(data['payload'], data['token'])
    end

    def broadcast(data, identity: false)
      message = data.slice('type', 'payload', 'clientId')
      message['user'] = current_user_identity if identity

      ActionCable.server.broadcast(stream_name, message)
    end

    def current_user_identity
      @current_user_identity ||= {
        id: current_user.id,
        name: current_user.name,
        avatarUrl: current_user.avatar_url(only_path: false)
      }
    end

    def valid_payload?(data)
      payload = data['payload']

      payload.is_a?(String) &&
        payload.bytesize <= MAX_PAYLOAD_BYTES &&
        data['clientId'].is_a?(Integer)
    end

    def rate_limited?
      Gitlab::ApplicationRateLimiter.throttled?(
        :collaborative_editing_update,
        scope: [current_user, @stream_key]
      )
    end

    def revalidate_access
      return unless @container

      return if feature_enabled?(@container) && authorized?(@container)

      @container = nil
      @stream_key = nil
      @store = nil

      unsubscribe_from_channel
    end
  end
end
