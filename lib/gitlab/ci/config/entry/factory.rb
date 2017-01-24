module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Factory class responsible for fabricating entry objects.
        #
        class Factory
          class InvalidFactory < StandardError; end

          def initialize(entry)
            @entry = entry
            @metadata = {}
            @attributes = {}
          end

          def value(value)
            @value = value
            self
          end

          def metadata(metadata)
            @metadata.merge!(metadata)
            self
          end

          def with(attributes)
            @attributes.merge!(attributes)
            self
          end

          def create!
            raise InvalidFactory unless defined?(@value)

            ##
            # We assume that unspecified entry is undefined.
            # See issue #18775.
            #
            if @value.nil?
              Entry::Unspecified.new(
                fabricate_unspecified
              )
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
            if @entry.default.nil?
              fabricate(Entry::Undefined)
            else
              fabricate(@entry, @entry.default)
            end
          end

          def fabricate(entry, value = nil)
            entry.new(value, @metadata).tap do |node|
              node.key = @attributes[:key]
              node.parent = @attributes[:parent]
              node.description = @attributes[:description]
            end
          end
        end
      end
    end
  end
end
