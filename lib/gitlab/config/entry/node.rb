# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # Base abstract class for each configuration entry node.
      #
      class Node
        InvalidError = Class.new(StandardError)

        attr_reader :config, :metadata
        attr_accessor :key, :parent, :default, :description

        def initialize(config, **metadata)
          @config = config
          @metadata = metadata
          @entries = {}

          yield(self) if block_given?

          self.class.aspects.to_a.each do |aspect|
            instance_exec(&aspect)
          end
        end

        def [](key)
          @entries[key] || Entry::Undefined.new
        end

        def compose!(deps = nil)
          return unless valid?

          yield if block_given?
        end

        def leaf?
          @entries.none?
        end

        def descendants
          @entries.values
        end

        def ancestors
          @parent ? @parent.ancestors + [@parent] : []
        end

        def opt(key)
          opt = metadata[key]
          opt = @parent.opt(key) if opt.nil? && @parent
          opt
        end

        def valid?
          errors.none?
        end

        def errors
          []
        end

        def value
          if leaf?
            @config
          else
            meaningful = @entries.select do |_key, value|
              value.specified? && value.relevant?
            end

            Hash[meaningful.map { |key, entry| [key, entry.value] }]
          end
        end

        def specified?
          true
        end

        def relevant?
          true
        end

        def location
          name = @key.presence || self.class.name.to_s.demodulize
                                      .underscore.humanize.downcase

          ancestors.map(&:key).append(name).compact.join(':')
        end

        def inspect
          val = leaf? ? config : descendants
          unspecified = specified? ? '' : '(unspecified) '
          "#<#{self.class.name} #{unspecified}{#{key}: #{val.inspect}}>"
        end

        def hash?
          @config.is_a?(Hash)
        end

        def string?
          @config.is_a?(String)
        end

        def integer?
          @config.is_a?(Integer)
        end

        def self.default(**)
        end

        def self.aspects
          @aspects ||= []
        end

        def self.with_aspect(blk)
          self.aspects.append(blk)
        end

        private

        attr_reader :entries
      end
    end
  end
end
