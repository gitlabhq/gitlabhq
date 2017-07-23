module Gitlab
  module Conflict
    class Parser
      UnresolvableError = Class.new(StandardError)
      UnmergeableFile = Class.new(UnresolvableError)
      UnsupportedEncoding = Class.new(UnresolvableError)

      # Recoverable errors - the conflict can be resolved in an editor, but not with
      # sections.
      ParserError = Class.new(StandardError)
      UnexpectedDelimiter = Class.new(ParserError)
      MissingEndDelimiter = Class.new(ParserError)

      def parse(text, our_path:, their_path:, parent_file: nil)
        raise UnmergeableFile if text.blank? # Typically a binary file
        raise UnmergeableFile if text.length > 200.kilobytes

        text.force_encoding('UTF-8')

        raise UnsupportedEncoding unless text.valid_encoding?

        line_obj_index = 0
        line_old = 1
        line_new = 1
        type = nil
        lines = []
        conflict_start = "<<<<<<< #{our_path}"
        conflict_middle = '======='
        conflict_end = ">>>>>>> #{their_path}"

        text.each_line.map do |line|
          full_line = line.delete("\n")

          if full_line == conflict_start
            raise UnexpectedDelimiter unless type.nil?

            type = 'new'
          elsif full_line == conflict_middle
            raise UnexpectedDelimiter unless type == 'new'

            type = 'old'
          elsif full_line == conflict_end
            raise UnexpectedDelimiter unless type == 'old'

            type = nil
          elsif line[0] == '\\'
            type = 'nonewline'
            lines << Gitlab::Diff::Line.new(full_line, type, line_obj_index, line_old, line_new, parent_file: parent_file)
          else
            lines << Gitlab::Diff::Line.new(full_line, type, line_obj_index, line_old, line_new, parent_file: parent_file)
            line_old += 1 if type != 'new'
            line_new += 1 if type != 'old'

            line_obj_index += 1
          end
        end

        raise MissingEndDelimiter unless type.nil?

        lines
      end
    end
  end
end
