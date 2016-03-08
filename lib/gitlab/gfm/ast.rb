module Gitlab
  module Gfm
    ##
    # GitLab Flavoured Markdown
    #  - Abstract Syntax Tree
    #  - Facade
    #
    module Ast
      extend self

      def parse(text)
        Parser.new(text).tree
      end
    end
  end
end
