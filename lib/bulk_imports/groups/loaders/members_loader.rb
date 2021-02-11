# frozen_string_literal: true

module BulkImports
  module Groups
    module Loaders
      class MembersLoader
        def initialize(*); end

        def load(context, data)
          return unless data

          context.group.members.create!(data)
        end
      end
    end
  end
end
