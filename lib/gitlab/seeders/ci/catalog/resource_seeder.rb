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
          # @param[Boolean] If the created resources should be published or not, defaults to false
          def initialize(group_path:, seed_count:, publish:)
            @group = Group.find_by_full_path(group_path)
            @seed_count = seed_count
            @publish = publish
            @current_user = @group&.first_owner
          end

          def seed
            return warn 'ERROR: Group was not found.' if @group.nil?

            @seed_count.times do |i|
              seed_catalog_resource(i)
            end
          end

          private

          def create_project(name, index)
            project = ::Projects::CreateService.new(
              @current_user,
              description: "This is Catalog resource ##{index}",
              name: name,
              namespace_id: @group.id,
              organization_id: @group.organization_id,
              path: name,
              visibility_level: @group.visibility_level
            ).execute

            return project if project&.saved?

            warn project&.errors&.full_messages&.to_sentence || "Project '#{name}' could not be created."
            nil
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

            project.repository.create_dir(
              @current_user,
              'templates',
              message: 'Add template dir',
              branch_name: project.default_branch_or_main
            )

            project.repository.create_file(
              @current_user,
              'templates/component.yml',
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

          def create_catalog_resource(project)
            result = ::Ci::Catalog::Resources::CreateService.new(project, @current_user).execute
            if result.success?
              result.payload
            else
              warn "Catalog resource could not be created for Project '#{project.name}': #{result.errors.join}"
              nil
            end
          end

          # Creates a release, which also creates a CI/CD catalog resource version
          # via Releases::CreateService (see app/services/releases/create_service.rb).
          def create_release(project, tag)
            result = ::Releases::CreateService.new(
              project,
              @current_user,
              tag: tag,
              ref: project.default_branch_or_main,
              name: "Release #{tag}",
              description: "Release #{tag}",
              legacy_catalog_publish: true
            ).execute

            return if result[:status] == :success

            warn "Release '#{tag}' could not be created for Project '#{project.name}': #{result[:message]}"
          end

          def seed_catalog_resource(index)
            name = "ci_seed_resource_#{index}"
            existing_project = Project.find_by_name(name)

            if existing_project.present? && existing_project.group.path == @group.path
              warn "Project '#{@group.path}/#{name}' already exists!"
              return
            end

            project = create_project(name, index)

            return unless project

            create_readme(project, index)
            create_template_yml(project)

            new_catalog_resource = create_catalog_resource(project)
            return unless new_catalog_resource

            if @publish
              create_release(project, 'v1.0.0')
              create_release(project, 'v1.1.0') if index == 0
              new_catalog_resource.publish!
            end

            warn "Project '#{@group.path}/#{name}' was saved successfully!"
          end
        end
      end
    end
  end
end
