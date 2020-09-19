# frozen_string_literal: true

module Atlassian
  module JiraConnect
    module Serializers
      class FileEntity < Grape::Entity
        include Gitlab::Routing

        expose :path do |file|
          file.deleted_file? ? file.old_path : file.new_path
        end
        expose :changeType do |file|
          if file.new_file?
            'ADDED'
          elsif file.deleted_file?
            'DELETED'
          elsif file.renamed_file?
            'MOVED'
          else
            'MODIFIED'
          end
        end
        expose :added_lines, as: :linesAdded
        expose :removed_lines, as: :linesRemoved

        expose :url do |file, options|
          file_path = if file.deleted_file?
                        File.join(options[:commit].parent_id, file.old_path)
                      else
                        File.join(options[:commit].id, file.new_path)
                      end

          project_blob_url(options[:project], file_path)
        end
      end
    end
  end
end
