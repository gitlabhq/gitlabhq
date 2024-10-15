# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Commands
        class ObjectStorageCommand < Command
          class_option :backup_bucket,
            desc: "When backing up object storage, this is the bucket to backup to",
            required: false,
            type: :string

          class_option :wait_for_completion,
            desc: "Wait for object storage backups to complete",
            type: :boolean,
            default: true

          class_option :registry_bucket,
            desc: "When backing up registry from object storage, this is the source bucket",
            required: false,
            type: :string

          class_option :service_account_file,
            desc: "JSON file containing the Google service account credentials",
            default: "/etc/gitlab/backup-account-credentials.json",
            type: :string
        end
      end
    end
  end
end
