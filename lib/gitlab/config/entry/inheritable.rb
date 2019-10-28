# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # Entry that represents an inheritable configs.
      #
      module Inheritable
        InheritError = Class.new(Gitlab::Config::Loader::FormatError)

        def compose!(deps = nil, &blk)
          super(deps, &blk)

          inherit!(deps)
        end

        private

        # We inherit config entries from `default:`
        # if the entry has the `inherit: true` flag set
        def inherit!(deps)
          return unless deps

          self.class.nodes.each do |key, factory|
            next unless factory.inheritable?

            new_entry = overwrite_entry(deps, key, self[key])

            entries[key] = new_entry if new_entry&.specified?
          end
        end

        def overwrite_entry(deps, key, current_entry)
          raise NotImplementedError
        end
      end
    end
  end
end
