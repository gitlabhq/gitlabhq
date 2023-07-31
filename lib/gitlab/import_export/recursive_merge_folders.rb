# frozen_string_literal: true
#
# This class is used by Import/Export to move files and folders from a source folders into a target folders
# that can already have the same folders in it, resolving in a merged folder.
#
# Example:
#
# source path
# |-- tree
# |   |-- project
# |       |-- labels.ndjson
# |-- uploads
# |   |-- folder1
# |   |   |-- image1.png
# |   |-- folder2
# |   |   |-- image2.png
#
# target path
# |-- tree
# |   |-- project
# |       |-- issues.ndjson
# |-- uploads
# |   |-- folder1
# |   |   |-- image3.png
# |   |-- folder3
# |   |   |-- image4.png
#
# target path after merge
# |-- tree
# |   |-- project
# |   |   |-- issues.ndjson
# |   |   |-- labels.ndjson
# |-- uploads
# |   |-- folder1
# |   |   |-- image1.png
# |   |   |-- image3.png
# |   |-- folder2
# |   |   |-- image2.png
# |   |-- folder3
# |   |   |-- image4.png

module Gitlab
  module ImportExport
    class RecursiveMergeFolders
      DEFAULT_DIR_MODE = 0o700

      def self.merge(source_path, target_path)
        Gitlab::PathTraversal.check_path_traversal!(source_path)
        Gitlab::PathTraversal.check_path_traversal!(target_path)
        Gitlab::PathTraversal.check_allowed_absolute_path!(source_path, [Dir.tmpdir])

        recursive_merge(source_path, target_path)
      end

      def self.recursive_merge(source_path, target_path)
        Dir.children(source_path).each do |child|
          source_child = File.join(source_path, child)
          target_child = File.join(target_path, child)

          next if Gitlab::Utils::FileInfo.linked?(source_child)

          if File.directory?(source_child)
            FileUtils.mkdir_p(target_child, mode: DEFAULT_DIR_MODE) unless File.exist?(target_child)
            recursive_merge(source_child, target_child)
          else
            FileUtils.mv(source_child, target_child)
          end
        end
      end

      private_class_method :recursive_merge
    end
  end
end
