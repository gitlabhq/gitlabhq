module EE
  module ProjectMirrorEntity
    extend ActiveSupport::Concern

    prepended do
      expose :mirror
      expose :import_url
      expose :username_only_import_url
      expose :mirror_user_id
      expose :mirror_trigger_builds
      expose :only_mirror_protected_branches
      expose :mirror_overwrites_diverged_branches

      expose :import_data_attributes do |project|
        import_data = project.import_data
        next nil unless import_data.present?

        data = import_data.as_json(
          only: :id,
          methods: %i[
            auth_method
            ssh_known_hosts
            ssh_known_hosts_verified_at
            ssh_known_hosts_verified_by_id
            ssh_public_key
          ]
        )

        data[:ssh_known_hosts_fingerprints] = import_data.ssh_known_hosts_fingerprints.as_json

        data
      end
    end
  end
end
