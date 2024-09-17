# frozen_string_literal: true

require 'forwardable'

module GitlabSettings
  class Options
    extend Forwardable

    def_delegators :@options,
      :count,
      :deep_stringify_keys,
      :deep_symbolize_keys,
      :default_proc,
      :dig,
      :each_key,
      :each_pair,
      :each_value,
      :each,
      :empty?,
      :fetch_values,
      :fetch,
      :filter,
      :keys,
      :length,
      :map,
      :member?,
      :merge,
      :reject,
      :select,
      :size,
      :slice,
      :stringify_keys,
      :symbolize_keys,
      :transform_keys,
      :transform_values,
      :value?,
      :values_at,
      :values

    # Recursively build GitlabSettings::Options
    def self.build(obj)
      case obj
      when Hash
        new(obj.transform_values { |value| build(value) })
      when Array
        obj.map { |value| build(value) }
      else
        obj
      end
    end

    def initialize(value)
      @options = value.deep_stringify_keys
    end

    def [](key)
      @options[key.to_s]
    end

    def []=(key, value)
      @options[key.to_s] = self.class.build(value)
    end

    def key?(key)
      @options.key?(key.to_s)
    end
    alias_method :has_key?, :key?

    # Some configurations use the 'default' key, like:
    # https://gitlab.com/gitlab-org/gitlab/-/blob/c4d5c77c87494bb320fa7fdf19b0e4d7d52af1d1/spec/support/helpers/stub_configuration.rb#L96
    # But since `default` is also a method in Hash, this can be confusing and
    # raise an exception instead of returning nil, as expected in some places.
    # To avoid that, we use #default always as a possible internal key
    def default
      @options['default']
    end

    # For backward compatibility, like:
    # https://gitlab.com/gitlab-org/gitlab/-/blob/adf67e90428670aaa955731f3bdeafb8b3a874cd/lib/gitlab/database/health_status/indicators/patroni_apdex.rb#L58
    def with_indifferent_access
      to_hash.with_indifferent_access
    end

    def dup
      self.class.build(to_hash)
    end

    def merge(other)
      self.class.build(to_hash.merge(other.deep_stringify_keys))
    end

    def merge!(other)
      @options = to_hash.merge(other.deep_stringify_keys)
    end

    def reverse_merge!(other)
      @options = to_hash.reverse_merge(other.deep_stringify_keys)
    end

    def deep_merge(other)
      self.class.build(to_hash.deep_merge(other.deep_stringify_keys))
    end

    def deep_merge!(other)
      @options = to_hash.deep_merge(other.deep_stringify_keys)
    end

    def is_a?(klass)
      return true if klass == Hash

      super(klass)
    end

    def to_hash
      @options.deep_transform_values do |option|
        case option
        when self.class
          option.to_hash
        else
          option
        end
      end
    end
    alias_method :to_h, :to_hash

    # Don't alter the internal keys
    def stringify_keys!
      error_msg = "Warning: Do not mutate #{self.class} objects: `#{__method__}`"

      log_and_raise_dev_exception(error_msg, method: __method__)

      to_hash.deep_stringify_keys
    end
    alias_method :deep_stringify_keys!, :stringify_keys!

    # Don't alter the internal keys
    def symbolize_keys!
      error_msg = "Warning: Do not mutate #{self.class} objects: `#{__method__}`"

      log_and_raise_dev_exception(error_msg, method: __method__)

      to_hash.deep_symbolize_keys
    end
    alias_method :deep_symbolize_keys!, :symbolize_keys!

    def method_missing(name, *args, &block)
      name_string = +name.to_s

      if name_string.chomp!("=")
        return self[name_string] = args.first if key?(name_string)
      elsif key?(name_string)
        return self[name_string]
      end

      if @options.respond_to?(name)
        error_msg = "Calling a hash method on #{self.class}: `#{name}`"

        log_and_raise_dev_exception(error_msg, method: name)

        return @options.public_send(name, *args, &block) # rubocop: disable GitlabSecurity/PublicSend
      end

      raise ::GitlabSettings::MissingSetting, "option '#{name}' not defined"
    end

    def respond_to_missing?(name, include_all = false)
      return true if key?(name)

      @options.respond_to?(name, include_all)
    end

    private

    # We can't call Gitlab::ErrorTracking.track_and_raise_for_dev_exception
    # because that method will attempt to load ApplicationContext and
    # fail to load User since the Devise is not yet set up in
    # `config/initialiers/8_devise.rb`.
    def log_and_raise_dev_exception(message, extra = {})
      raise message unless Rails.env.production?

      # Gitlab::BacktraceCleaner drops config/initializers, so we just limit the
      # backtrace to the first 10 lines.
      payload = extra.merge(message: message, caller: caller[0..10])
      Gitlab::AppJsonLogger.warn(payload)
    end
  end
end
