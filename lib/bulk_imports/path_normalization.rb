# frozen_string_literal: true

module BulkImports
  module PathNormalization
    private

    def normalize_path(path)
      return path.downcase if Gitlab::Regex.oci_repository_path_regex.match?(path)

      path = path.parameterize.downcase

      # remove invalid characters from end and start of path
      delete_invalid_edge_characters(delete_invalid_edge_characters(path))
      # remove invalid multiplied characters
      delete_invalid_multiple_characters(path)
    end

    def delete_invalid_edge_characters(path)
      path.reverse!
      path.each_char do |char|
        break path unless char.match(Gitlab::Regex.oci_repository_path_regex).nil?

        path.delete_prefix!(char)
      end
    end

    def delete_invalid_multiple_characters(path)
      path.gsub!('-_', '-') if path.include?('-_')
      path.gsub!('_-', '-') if path.include?('_-')
      path
    end
  end
end
