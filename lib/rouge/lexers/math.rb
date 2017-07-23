module Rouge
  module Lexers
    class Math < PlainText
      title "A passthrough lexer used for LaTeX input"
      desc "PLEASE REFACTOR - this should be handled by SyntaxHighlightFilter"
      tag 'math'
    end
  end
end
