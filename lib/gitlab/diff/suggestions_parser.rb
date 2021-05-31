# frozen_string_literal: true

module Gitlab
  module Diff
    class SuggestionsParser
      # Matches for instance "-1", "+1" or "-1+2".
      SUGGESTION_CONTEXT = /^(\-(?<above>\d+))?(\+(?<below>\d+))?$/.freeze

      CSS   = 'pre.language-suggestion'
      XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS).freeze

      class << self
        # Returns an array of Gitlab::Diff::Suggestion which represents each
        # suggestion in the given text.
        #
        def parse(text, position:, project:, supports_suggestion: true)
          return [] unless position.complete?

          html = Banzai.render(text, project: nil,
                                     no_original_data: true,
                                     suggestions_filter_enabled: supports_suggestion)
          doc = Nokogiri::HTML(html)
          suggestion_nodes = doc.xpath(XPATH)

          return [] if suggestion_nodes.empty?

          diff_file = position.diff_file(project.repository)

          suggestion_nodes.map do |node|
            lang_param = node['data-lang-params']

            lines_above, lines_below = nil

            if lang_param && suggestion_params = fetch_suggestion_params(lang_param)
              lines_above = suggestion_params[:above]
              lines_below = suggestion_params[:below]
            end

            Gitlab::Diff::Suggestion.new(node.text,
                                         line: position.new_line,
                                         above: lines_above.to_i,
                                         below: lines_below.to_i,
                                         diff_file: diff_file)
          end
        end

        private

        def fetch_suggestion_params(lang_param)
          lang_param.match(SUGGESTION_CONTEXT)
        end
      end
    end
  end
end
