# frozen_string_literal: true

module Gitlab
  module ImportExport
    class LegacyRelationTreeSaver
      include Gitlab::ImportExport::CommandLineUtil

      def serialize(exportable, relations_tree)
        Gitlab::ImportExport::FastHashSerializer
          .new(exportable, relations_tree, batch_size: batch_size(exportable))
          .execute
      end

      def save(tree, dir_path, filename)
        mkdir_p(dir_path)

        tree_json = ::JSON.generate(tree)

        File.write(File.join(dir_path, filename), tree_json)
      end

      private

      def batch_size(exportable)
        Gitlab::ImportExport::Json::StreamingSerializer.batch_size(exportable)
      end
    end
  end
end
