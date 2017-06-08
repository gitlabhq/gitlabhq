module Rouge
  module Lexers
    class Plantuml < PlainText
      title "A passthrough lexer used for PlantUML input"
      desc "PLEASE REFACTOR - this should be handled by SyntaxHighlightFilter"
      tag 'plantuml'
    end
  end
end
