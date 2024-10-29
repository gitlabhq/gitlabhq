# frozen_string_literal: true

module Gitlab
  class EncryptedRedisCommand < EncryptedCommandBase
    DISPLAY_NAME = "Redis"
    EDIT_COMMAND_NAME = "gitlab:redis:secret:edit"

    class << self
      def all_redis_instance_class_names
        Gitlab::Redis::ALL_CLASSES.map do |c|
          normalized_instance_name(c)
        end
      end

      def normalized_instance_name(instance)
        if instance.is_a?(Class)
          # Gitlab::Redis::SharedState => sharedstate
          instance.name.demodulize.to_s.downcase
        else
          # Drop all hyphens, underscores, and spaces from the name
          # eg.: shared_state => sharedstate
          instance.gsub(/[-_ ]/, '').downcase
        end
      end

      def encrypted_secrets(**args)
        if args[:instance_name]
          instance_class = Gitlab::Redis::ALL_CLASSES.find do |instance|
            normalized_instance_name(instance) == normalized_instance_name(args[:instance_name])
          end

          unless instance_class
            error_message = <<~MSG
            Specified instance name #{args[:instance_name]} does not exist.
            The available instances are #{all_redis_instance_class_names.join(', ')}."
            MSG

            raise error_message
          end
        else
          instance_class = Gitlab::Redis::Cache
        end

        instance_class.encrypted_secrets
      end

      def encrypted_file_template
        <<~YAML
          # password: '123'
        YAML
      end
    end
  end
end
