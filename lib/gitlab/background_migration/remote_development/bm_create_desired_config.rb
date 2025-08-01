# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      class BmCreateDesiredConfig # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
        # @param [Integer] workspace_id
        # @param [Boolean] dry_run
        # @return [Void]
        def self.create_and_save(workspace_id:, dry_run: false)
          workspace = RemoteDevelopment::Models::BmWorkspace.find(workspace_id)

          result = BackgroundMigration::RemoteDevelopment::WorkspaceOperations::Create::DesiredConfig::BmMain.main(
            {
              params: {
                agent: workspace.agent
              },
              workspace: workspace,
              logger: logger
            }
          )

          validate_and_create_workspace_agentk_state(
            workspace: workspace,
            desired_config: result[:desired_config],
            logger: logger,
            dry_run: dry_run
          )
        end

        # @param [BackgroundMigration::RemoteDevelopment::Models::BMWorkspace] workspace
        # @param [BackgroundMigration::RemoteDevelopment::WorkspaceOperations::BMDesiredConfig] desired_config
        # @param [Gitlab::BackgroundMigration::Logger] logger
        # @param [Boolean] dry_run
        # @return [Void]
        def self.validate_and_create_workspace_agentk_state(workspace:, desired_config:, logger:, dry_run:) # rubocop:disable Metrics/MethodLength -- need it big
          if dry_run
            puts "For workspace_id #{workspace.id}"
            puts "Valid desired_config? #{desired_config.valid?}"
            desired_config.errors.full_messages.each do |message|
              puts message
            end
          end

          unless desired_config.valid?
            logger.error(
              message: "desired_config is invalid",
              error_type: "workspace_agentk_state_migration_error",
              workspace_id: workspace.id,
              validation_error: desired_config.errors.full_messages
            )

            return
          end

          if dry_run
            workspace_agentk_state = RemoteDevelopment::Models::BmWorkspaceAgentkState.new(
              workspace_id: workspace.id,
              project_id: workspace.project_id,
              desired_config: desired_config
            )
            puts "Valid state model? #{workspace_agentk_state.valid?}"

            workspace_agentk_state.errors.full_messages.each do |message|
              puts message
            end
          else
            RemoteDevelopment::Models::BmWorkspaceAgentkState.create!(
              workspace_id: workspace.id,
              project_id: workspace.project_id,
              desired_config: desired_config
            )
          end
        end

        # @return [Gitlab::BackgroundMigration::Logger]
        def self.logger
          @logger ||= Gitlab::BackgroundMigration::Logger.build
        end
      end
    end
  end
end
