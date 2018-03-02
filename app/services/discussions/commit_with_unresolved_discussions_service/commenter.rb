module Discussions
  class CommitWithUnresolvedDiscussionsService
    class Commenter
      # Commenters can be strings or lambdas.
      # Use a string for single-line comments: each line will be prefixed
      # Use a lambda for multi-line comments: it will be called with the full text
      COMMENTERS = {
        double_slash: '// ', # Substitution applied to each line
        double_stroke: '-- ', # Substitution applied to each line
        pound:        '# ',
        percent:      '% ',
        quote:        "'",
        bang:         '!',
        semicolon:    ';',
        xml:          lambda { |text| "<!--\n#{text}-->" }
      }.freeze

      # Maps Rouge lexer (language) tags to commenters.
      COMMENT_TYPES_BY_LANG = {
        default: :double_slash,

        actionscript: :double_slash,
        c: :double_slash,
        csharp: :double_slash,
        d: :double_slash,
        cpp: :double_slash,
        fsharp: :double_slash,
        go: :double_slash,
        php: :double_slash,
        java: :double_slash,
        kotlin: :double_slash,
        javascript: :double_slash,
        objective_c: :double_slash,
        rust: :double_slash,
        scala: :double_slash,
        swift: :double_slash,
        sass: :double_slash,

        markdown: :xml,
        html: :xml,
        xml: :xml,

        shell: :pound,
        perl: :pound,
        python: :pound,
        powershell: :pound,
        r: :pound,
        ruby: :pound,
        make: :pound,
        elixir: :pound,
        yaml: :pound,

        tex: :percent,
        prolog: :percent,
        matlab: :percent,
        erlang: :percent,

        vb: :quote,

        fortran: :bang,

        lisp: :semicolon,
        common_lisp: :semicolon,
        clojure: :semicolon,
        scheme: :semicolon,

        haskell: :double_stroke,
        sql: :double_stroke,
        lua: :double_stroke,
      }.freeze

      attr_reader :format

      def initialize(comment_type = :default)
        @format = COMMENTERS[comment_type] || COMMENTERS[:default]
      end

      def self.for_lang(lang)
        comment_type = COMMENT_TYPES_BY_LANG[lang] || COMMENT_TYPES_BY_LANG[:default]
        new(comment_type)
      end

      def self.for_blob(blob)
        lexer = Gitlab::Highlight.new(blob.name, blob.data, repository: blob.project.repository).lexer
        for_lang(lexer.tag.to_sym)
      end

      def apply(text)
        # Lambdas are used for multi-line comments, strings for single-line. See comment by the COMMENTERS constant.
        if format.respond_to?(:call)
          format.call(text) << "\n"
        else
          # With single line comments, we insert an extra newline at the end to
          # create some distance between the comment and the next line of code.
          text = "#{text}\n"
          text.gsub(/^/, format)
        end
      end
    end
  end
end
