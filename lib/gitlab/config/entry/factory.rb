# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # Factory class responsible for fabricating entry objects.
      #
      class Factory
        InvalidFactory = Class.new(StandardError)

        def initialize(entry)
          @entry = entry
          @metadata = {}
          @attributes = { default: entry.default }
        end

        def value(value)
          @value = value
          self
        end

        def metadata(metadata)
          @metadata.merge!(metadata.compact)
          self
        end

        def with(attributes)
          @attributes.merge!(attributes.compact)
          self
        end

        def description
          @attributes[:description]
        end

        def inheritable?
          @attributes[:inherit]
        end

        def reserved?
          @attributes[:reserved]
        end

        def create!
          raise InvalidFactory unless defined?(@value)

          ##
          # We assume that unspecified entry is undefined.
          # See issue #18775.
          #
          if @value.nil?
            Entry::Unspecified.new(fabricate_unspecified)
          else
            fabricate(@entry, @value)
          end
        end

        private

        def fabricate_unspecified
          ##
          # If entry has a default value we fabricate concrete node
          # with default value.
          #
          default = @attributes.fetch(:default)

          if default.nil?
            fabricate(Entry::Undefined)
          else
            fabricate(@entry, default)
          end
        end

        def fabricate(entry, value = nil)
          entry.new(value, @metadata) do |node|
            node.key = @attributes[:key]
            node.parent = @attributes[:parent]
            node.default = @attributes[:default]
            node.description = @attributes[:description]
          end
        end
      end
    end
  end
end
