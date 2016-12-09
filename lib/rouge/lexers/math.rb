module Rouge
  module Lexers
    class Math < Lexer
      title "A passthrough lexer used for LaTeX input"
      desc "A boring lexer that doesn't highlight anything"

      tag 'math'
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
