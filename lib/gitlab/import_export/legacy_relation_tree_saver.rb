# frozen_string_literal: true

module Gitlab
  module ImportExport
    class LegacyRelationTreeSaver
      include Gitlab::ImportExport::CommandLineUtil

      def serialize(exportable, relations_tree)
        Gitlab::ImportExport::FastHashSerializer
          .new(exportable, relations_tree)
          .execute
      end

      def save(tree, dir_path, filename)
        mkdir_p(dir_path)

        tree_json = ::JSON.generate(tree)

        File.write(File.join(dir_path, filename), tree_json)
      end
    end
  end
end
