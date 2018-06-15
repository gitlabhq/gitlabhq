module QA
  module Factory
    module Resource
      class Group < Factory::Base
        attr_accessor :path, :description
        attr_reader :api_object

        dependency Factory::Resource::Sandbox, as: :sandbox

        product :id do |factory|
          factory.api_object ? factory.api_object[:id] : raise("unknown id")
        end

        def initialize
          @path = Runtime::Namespace.name
          @description = "QA test run at #{Runtime::Namespace.time}"
        end

        def api_get
          response = get(Runtime::API::Request.new(api_client, "/groups/#{path}").url)
          JSON.parse(response.body, symbolize_names: true)
        end

        def api_post!
          response = post(
            Runtime::API::Request.new(api_client, '/groups').url,
            parent_id: sandbox.id,
            path: path,
            name: path)
          JSON.parse(response.body, symbolize_names: true)
        end

        def fabricate_via_api!
          @api_object = api_post!

          @api_object[:web_url]
        end

        def fabricate!
          sandbox.visit!

          Page::Group::Show.perform do |group_show|
            if group_show.has_subgroup?(path)
              group_show.go_to_subgroup(path)
            else
              group_show.go_to_new_subgroup

              Page::Group::New.perform do |group_new|
                group_new.set_path(path)
                group_new.set_description(description)
                group_new.set_visibility('Public')
                group_new.create
              end

              # Ensure that the group was actually created
              group_show.wait(time: 1) do
                group_show.has_text?(path) &&
                  group_show.has_new_project_or_subgroup_dropdown?
              end
            end
          end
        end
      end
    end
  end
end
