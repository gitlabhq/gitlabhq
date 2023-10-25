# frozen_string_literal: true

module Gitlab
  module Seeders
    module Ci
      module Catalog
        class ResourceSeeder
          # Initializes the class
          #
          # @param [String] Path of the group to find
          # @param [Integer] Number of resources to create
          def initialize(group_path:, seed_count:)
            @group = Group.find_by_full_path(group_path)
            @seed_count = seed_count
            @current_user = @group&.first_owner
          end

          def seed
            if @group.nil?
              warn 'ERROR: Group was not found.'
              return
            end

            @seed_count.times do |i|
              create_ci_catalog_resource(i)
            end
          end

          private

          def create_project(name, index)
            project = ::Projects::CreateService.new(
              @current_user,
              description: "This is Catalog resource ##{index}",
              name: name,
              namespace_id: @group.id,
              path: name,
              visibility_level: @group.visibility_level
            ).execute

            if project.saved?
              project
            else
              warn project.errors.full_messages.to_sentence
              nil
            end
          end

          def create_template_yml(project)
            template_content = <<~YAML
            spec:
              inputs:
                stage:
                  default: test
            ---
            component-job:
              script: echo job 1
              stage: $[[ inputs.stage ]]
            YAML

            project.repository.create_file(
              @current_user,
              'template.yml',
              template_content,
              message: 'Add template.yml',
              branch_name: project.default_branch_or_main
            )
          end

          def create_readme(project, index)
            project.repository.create_file(
              @current_user,
              '/README.md',
              "## Component stuff #{index}",
              message: 'Add README.md',
              branch_name: project.default_branch_or_main
            )
          end

          def create_ci_catalog(project)
            result = ::Ci::Catalog::AddResourceService.new(project, @current_user).execute
            if result.success?
              result.payload
            else
              warn "Project '#{project.name}' could not be converted to a Catalog resource"
              nil
            end
          end

          def create_ci_catalog_resource(index)
            name = "ci_seed_resource_#{index}"

            if Project.find_by_name(name).present?
              warn "Project '#{name}' already exists!"
              return
            end

            project = create_project(name, index)

            return unless project

            create_readme(project, index)
            create_template_yml(project)

            return unless create_ci_catalog(project)

            warn "Project '#{name}' was saved successfully!"
          end
        end
      end
    end
  end
end
