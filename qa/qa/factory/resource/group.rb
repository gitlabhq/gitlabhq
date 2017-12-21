module QA
  module Factory
    module Resource
      class Group < Factory::Base
        attr_writer :path, :description

        dependency Factory::Resource::Sandbox, as: :sandbox

        def initialize
          @path = Runtime::Namespace.name
          @description = "QA test run at #{Runtime::Namespace.time}"
        end

        def fabricate!
          sandbox.visit!

          Page::Group::Show.perform do |page|
            if page.has_subgroup?(@path)
              page.go_to_subgroup(@path)
            else
              page.go_to_new_subgroup

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
end
