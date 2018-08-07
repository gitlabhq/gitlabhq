module EE
  module Boards
    module Lists
      module ListService
        # When adding a new licensed type, make sure to also add
        # it on license.rb with the pattern "board_<list_type>_lists"
        LICENSED_LIST_TYPES = [:assignee, :milestone].freeze

        extend ::Gitlab::Utils::Override

        override :execute
        def execute(board)
          not_available_lists =
            list_type_features_availability(board).select { |_, available| !available }

          if not_available_lists.any?
            super.where.not(list_type: not_available_lists.keys)
          else
            super
          end
        end

        private

        def list_type_features_availability(board)
          parent = board.parent

          {}.tap do |hash|
            LICENSED_LIST_TYPES.each do |list_type|
              list_type_key = ::List.list_types[list_type]
              hash[list_type_key] = parent&.feature_available?(:"board_#{list_type}_lists")
            end
          end
        end
      end
    end
  end
end
