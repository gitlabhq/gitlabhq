# frozen_string_literal: true

module QA
  module Resource
    module Repository
      class Branch < Base
        attr_accessor :name, :ref

        attribute :project do
          Project.fabricate_via_api! do |resource|
            resource.name = 'branch-project'
            resource.initialize_with_readme = true
          end
        end

        def initialize
          @name = 'test'
          @ref = Runtime::Env.default_branch
        end

        def fabricate!
          raise NotImplementedError
        end

        def fabricate_via_api!
          resource_web_url(api_get)
        rescue ResourceNotFoundError
          super
        end

        def api_get_path
          "/projects/#{project.id}/repository/branches/#{name}"
        end

        def api_delete_path
          api_get_path
        end

        def api_post_path
          "/projects/#{project.id}/repository/branches"
        end

        def api_post_body
          {
            branch: name,
            ref: ref
          }
        end
      end
    end
  end
end
