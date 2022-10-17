# frozen_string_literal: true

module RuboCop
  module PathUtil
    def match_path?(pattern, path)
      case pattern
      when String
        matched = if /[*{}]/.match?(pattern)
                    File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
                  else
                    pattern == path
                  end

        matched || hidden_file_in_not_hidden_dir?(pattern, path)
      when Regexp
        begin
          pattern.match?(path)
        rescue ArgumentError => e
          return false if e.message.start_with?('invalid byte sequence')

          raise e
        end
      end
    end
  end
end
