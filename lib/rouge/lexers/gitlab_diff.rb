Rouge::Token::Tokens.token(:InlineDiff, 'idiff')

module Rouge
  module Lexers
    class GitlabDiff < RegexLexer
      title "GitLab Diff"
      tag 'gitlab_diff'

      state :root do
        rule %r{<span class='idiff'>(.*?)</span>} do |match|
          token InlineDiff, match[1]
        end

        rule /(?:(?!<span class='idiff').)*/m do
          delegate option(:parent_lexer)
        end
      end

      start do
        option(:parent_lexer).reset!
      end
    end
  end
end
