# frozen_string_literal: true

module Gitlab
  module Changelog
    # A release to add to a changelog.
    class Release
      attr_reader :version

      def initialize(version:, date:, config:)
        @version = version
        @date = date
        @config = config
        @entries = Hash.new { |h, k| h[k] = [] }

        # This ensures that entries are presented in the same order as the
        # categories Hash in the user's configuration.
        @config.categories.values.each do |category|
          @entries[category] = []
        end
      end

      def add_entry(
        title:,
        commit:,
        category:,
        author: nil,
        merge_request: nil
      )
        # When changing these fields, keep in mind that this needs to be
        # backwards compatible. For example, you can't just remove a field as
        # this will break the changelog generation process for existing users.
        entry = {
          'title' => title,
          'commit' => {
            'reference' => commit.to_reference(full: true),
            'trailers' => commit.trailers
          }
        }

        if author
          entry['author'] = {
            'reference' => author.to_reference(full: true),
            'contributor' => @config.contributor?(author)
          }
        end

        if merge_request
          entry['merge_request'] = {
            'reference' => merge_request.to_reference(full: true)
          }
        end

        @entries[@config.category(category)] << entry
      end

      def to_markdown
        state = TemplateParser::EvalState.new
        data = { 'categories' => entries_for_template }

        # While not critical, we would like release sections to be separated by
        # an empty line in the changelog; ensuring it's readable even in its
        # raw form.
        #
        # Since it can be a bit tricky to get this right in a template, we
        # enforce an empty line separator ourselves.
        markdown =
          begin
            @config.template.evaluate(state, data).strip
          rescue TemplateParser::ParseError => e
            raise Error, e.message
          end

        # The release header can't be changed using the Liquid template, as we
        # need this to be in a known format. Without this restriction, we won't
        # know where to insert a new release section in an existing changelog.
        "## #{@version} (#{release_date})\n\n#{markdown}\n\n"
      end

      def header_start_pattern
        /^##\s*#{Regexp.escape(@version)}/
      end

      private

      def release_date
        @config.format_date(@date)
      end

      def entries_for_template
        rows = []

        @entries.each do |category, entries|
          next if entries.empty?

          rows << {
            'title' => category,
            'count' => entries.length,
            'single_change' => entries.length == 1,
            'entries' => entries
          }
        end

        rows
      end
    end
  end
end
