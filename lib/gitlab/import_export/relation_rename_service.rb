# frozen_string_literal: true

# This class is intended to help with relation renames within Gitlab versions
# and allow compatibility between versions.
# If you have to change one relationship name that is imported/exported,
# you should add it to the RENAMES constant indicating the old name and the
# new one.
# The behavior of these renamed relationships should be transient and it should
# only last one release until you completely remove the renaming from the list.
#
# When importing, this class will check the hash and:
# - if only the old relationship name is found, it will rename it with the new one
# - if only the new relationship name is found, it will do nothing
# - if it finds both, it will use the new relationship data
#
# When exporting, this class will duplicate the keys in the resulting file.
# This way, if we open the file in an old version of the exporter it will work
# and also it will with the newer versions.
module Gitlab
  module ImportExport
    class RelationRenameService
      RENAMES = {
        'pipelines' => 'ci_pipelines' # Added in 11.6, remove in 11.7
      }.freeze

      def self.rename(tree_hash)
        return unless tree_hash&.present?

        RENAMES.each do |old_name, new_name|
          old_entry = tree_hash.delete(old_name)

          next if tree_hash[new_name]
          next unless old_entry

          tree_hash[new_name] = old_entry
        end
      end

      def self.add_new_associations(tree_hash)
        RENAMES.each do |old_name, new_name|
          next if tree_hash.key?(old_name)

          tree_hash[old_name] = tree_hash[new_name]
        end
      end
    end
  end
end
