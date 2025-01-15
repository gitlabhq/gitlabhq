# frozen_string_literal: true

module ActiveContext
  module Concerns
    module Queue
      def self.included(base)
        base.extend(ClassMethods)
        base.register!
      end

      module ClassMethods
        def number_of_shards
          raise NotImplementedError
        end

        def register!
          ActiveContext::Queues.register!(redis_key, shards: number_of_shards)
        end

        def redis_key
          "#{prefix}:{#{queue_name}}"
        end

        def queue_name
          name_elements[-1].underscore
        end

        def prefix
          name_elements[..-2].join('_').downcase
        end

        def name_elements
          name.to_s.split('::')
        end
      end
    end
  end
end
