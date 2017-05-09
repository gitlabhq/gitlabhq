module Gitlab
  class Highlight
    def self.highlight(blob_name, blob_content, repository: nil, plain: false)
      new(blob_name, blob_content, repository: repository).
        highlight(blob_content, continue: false, plain: plain)
    end

    def self.highlight_lines(repository, ref, file_name)
      blob = repository.blob_at(ref, file_name)
      return [] unless blob

      blob.load_all_data!(repository)
      highlight(file_name, blob.data, repository: repository).lines.map!(&:html_safe)
    end

    attr_reader :blob_name

    def initialize(blob_name, blob_content, repository: nil)
      @formatter = Rouge::Formatters::HTMLGitlab
      @repository = repository
      @blob_name = blob_name
      @blob_content = blob_content
    end

    def highlight(text, continue: true, plain: false)
      highlighted_text = highlight_text(text, continue: continue, plain: plain)
      highlighted_text = link_dependencies(text, highlighted_text) if blob_name
      autolink_strings(text, highlighted_text)
    end

    def lexer
      @lexer ||= custom_language || begin
        Rouge::Lexer.guess(filename: @blob_name, source: @blob_content).new
      rescue Rouge::Guesser::Ambiguous => e
        e.alternatives.sort_by(&:tag).first
      end
    end

    private

    def custom_language
      language_name = @repository && @repository.gitattribute(@blob_name, 'gitlab-language')

      return nil unless language_name

      Rouge::Lexer.find_fancy(language_name)
    end

    def highlight_text(text, continue: true, plain: false)
      if plain
        highlight_plain(text)
      else
        highlight_rich(text, continue: continue)
      end
    end

    def highlight_plain(text)
      @formatter.format(Rouge::Lexers::PlainText.lex(text)).html_safe
    end

    def highlight_rich(text, continue: true)
      @formatter.format(lexer.lex(text, continue: continue), tag: lexer.tag).html_safe
    rescue
      highlight_plain(text)
    end

    def link_dependencies(text, highlighted_text)
      Gitlab::DependencyLinker.link(blob_name, text, highlighted_text)
    end

    def autolink_strings(text, highlighted_text)
      raw_lines = text.lines

      # TODO: Don't run pre-processing pipeline, because this may break the highlighting
      linked_text = Banzai.render(
        ERB::Util.html_escape(text),
        pipeline: :autolink,
        autolink_emails: true
      ).html_safe

      linked_lines = linked_text.lines

      highlighted_lines = highlighted_text.lines

      highlighted_lines.map!.with_index do |rich_line, i|
        matches = []
        linked_lines[i].scan(/(?<start><a[^>]+>)(?<content>[^<]+)(?<end><\/a>)/) { matches << Regexp.last_match }
        next rich_line if matches.empty?

        raw_line = raw_lines[i]
        marked_line = rich_line.html_safe

        matches.each do |match|
          marker = StringRegexMarker.new(raw_line, marked_line)

          regex = /#{Regexp.escape(match[:content])}/

          marked_line = marker.mark(regex) do |text, left:, right:|
            "#{match[:start]}#{text}#{match[:end]}"
          end
        end

        marked_line
      end

      highlighted_lines.join.html_safe
    end
  end
end
