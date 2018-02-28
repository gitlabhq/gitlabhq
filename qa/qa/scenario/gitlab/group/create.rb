require 'securerandom'

module QA
  module Scenario
    module Gitlab
      module Group
        class Create < Scenario::Template
          attr_writer :path, :description

          def initialize
            @path = Runtime::Namespace.name
            @description = "QA test run at #{Runtime::Namespace.time}"
          end

          def perform
            Page::Group::New.perform do |group|
              group.set_path(@path)
              group.set_description(@description)
              group.set_visibility('Private')
              group.create
            end
          end
        end
      end
    end
  end
end
