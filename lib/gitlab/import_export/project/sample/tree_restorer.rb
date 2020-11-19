# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      module Sample
        class TreeRestorer < Project::TreeRestorer
          def relation_tree_restorer_class
            RelationTreeRestorer
          end

          def relation_factory
            RelationFactory
          end
        end
      end
    end
  end
end
