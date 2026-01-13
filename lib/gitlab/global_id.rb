# frozen_string_literal: true

module Gitlab
  module GlobalId
    CoerceError = Class.new(ArgumentError)

    def self.build(object = nil, model_name: nil, id: nil, params: nil)
      if object
        model_name ||= object.class.name
        id ||= object.id
      end

      ::URI::GID.build(app: GlobalID.app, model_name: model_name, model_id: id, params: params)
    end

    def self.as_global_id(value, model_name: nil)
      case value
      when GlobalID
        value
      when URI::GID
        GlobalID.new(value)
      when Integer, String
        raise CoerceError, "Cannot coerce #{value.class}" unless model_name.present?

        GlobalID.new(::Gitlab::GlobalId.build(model_name: model_name, id: value))
      else
        raise CoerceError, "Invalid ID. Cannot coerce instances of #{value.class}"
      end
    end

    # Safely locates a record by its Global ID.
    #
    # @param gid [GlobalID, String, nil] the Global ID to locate
    # @param on_error [Proc, nil] optional error handler called with the exception
    # @param options [Hash] additional options passed to GlobalID::Locator.locate
    # @return [Object, nil] the located record, or nil if not found or on error
    #
    # @example Silent failure
    #   safe_locate(gid)
    #
    # @example With error tracking
    #   safe_locate(gid, on_error: ->(e) { Gitlab::ErrorTracking.track_exception(e) })
    #
    # @example With options
    #   safe_locate(gid, options: { only: User })
    #
    def self.safe_locate(gid, on_error: nil, options: {})
      return unless gid

      GlobalID::Locator.locate(gid, options)
    rescue StandardError => err
      on_error&.call(err)

      nil
    end
  end
end
