module QA
  module Scenario
    module Test
      module Sanity
        class Selectors < Scenario::Template
          include Scenario::Bootable

          PAGE_MODULES = [QA::Page]

          def perform(*)
            validators = PAGE_MODULES.map do |pages|
              Page::Validator.new(pages)
            end

            validators.map(&:errors).flatten.tap do |errors|

            end

            validators.each(&:validate!)
          end
        end
      end
    end
  end
end
