module EE
  module Banzai
    module ReferenceParser
      module EpicParser
        # rubocop: disable CodeReuse/ActiveRecord
        def records_for_nodes(nodes)
          @epics_for_nodes ||= grouped_objects_for_nodes(
            nodes,
            ::Epic.includes(
              :author,
              :group
            ),
            self.class.data_attribute
          )
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
