module Rouge
  module Lexers
    class Plantuml < Lexer
      title "A passthrough lexer used for PlantUML input"
      desc "A boring lexer that doesn't highlight anything"

      tag 'plantuml'
      mimetypes 'text/plain'

      default_options token: 'Text'

      def token
        @token ||= Token[option :token]
      end

      def stream_tokens(string, &b)
        yield self.token, string
      end
    end
  end
end
