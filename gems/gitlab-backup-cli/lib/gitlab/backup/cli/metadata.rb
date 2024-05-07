# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Metadata
        autoload :BackupMetadata, 'gitlab/backup/cli/metadata/backup_metadata'
        autoload :Serializer, 'gitlab/backup/cli/metadata/serializer'
        autoload :Deserializer, 'gitlab/backup/cli/metadata/deserializer'
      end
    end
  end
end
