# frozen_string_literal: true

module Gitlab
  module Graphql
    module Representation
      class SubmoduleTreeEntry < SimpleDelegator
        include GlobalID::Identification

        class << self
          def decorate(submodules, tree)
            repository = tree.repository
            submodule_links = Gitlab::SubmoduleLinks.new(repository)

            submodules.map do |submodule|
              self.new(submodule, submodule_links.for(submodule, tree.sha))
            end
          end
        end

        def initialize(submodule, submodule_links)
          @submodule_links = submodule_links

          super(submodule)
        end

        def web_url
          @submodule_links&.web
        end

        def tree_url
          @submodule_links&.tree
        end
      end
    end
  end
end
