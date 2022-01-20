# frozen_string_literal: true

TERRAFORM_FILE_VERSION = 1

# Create sample terraform states in existing projects
Gitlab::Seeder.quiet do
  tfdata = {terraform_version: '0.14.1'}.to_json

  Project.not_mass_generated.find_each do |project|
    # Create as the project's creator
    user = project.creator
    # Set a build job source, if one exists for the project
    build = project.builds.last

    remote_state_handler = ::Terraform::RemoteStateHandler.new(project, user, name: project.path, lock_id: nil)

    remote_state_handler.handle_with_lock do |state|
      # Upload a file if a version does not already exist
      state.update_file!(CarrierWaveStringFile.new(tfdata), version: TERRAFORM_FILE_VERSION, build: build) if state.latest_version.nil?
    end

    # rubocop:disable Rails/Output
    print '.'
    # rubocop:enable Rails/Output
  end
end
