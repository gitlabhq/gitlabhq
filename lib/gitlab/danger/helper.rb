# frozen_string_literal: true

require_relative 'teammate'

module Gitlab
  module Danger
    module Helper
      RELEASE_TOOLS_BOT = 'gitlab-release-tools-bot'
      DRAFT_REGEX = /\A*#{Regexp.union(/(?i)(\[WIP\]\s*|WIP:\s*|WIP$)/, /(?i)(\[draft\]|\(draft\)|draft:|draft\s\-\s|draft$)/)}+\s*/i.freeze

      # Returns a list of all files that have been added, modified or renamed.
      # `git.modified_files` might contain paths that already have been renamed,
      # so we need to remove them from the list.
      #
      # Considering these changes:
      #
      # - A new_file.rb
      # - D deleted_file.rb
      # - M modified_file.rb
      # - R renamed_file_before.rb -> renamed_file_after.rb
      #
      # it will return
      # ```
      # [ 'new_file.rb', 'modified_file.rb', 'renamed_file_after.rb' ]
      # ```
      #
      # @return [Array<String>]
      def all_changed_files
        Set.new
          .merge(git.added_files.to_a)
          .merge(git.modified_files.to_a)
          .merge(git.renamed_files.map { |x| x[:after] })
          .subtract(git.renamed_files.map { |x| x[:before] })
          .to_a
          .sort
      end

      # Returns a string containing changed lines as git diff
      #
      # Considering changing a line in lib/gitlab/usage_data.rb it will return:
      #
      # [ "--- a/lib/gitlab/usage_data.rb",
      #   "+++ b/lib/gitlab/usage_data.rb",
      #   "+      # Test change",
      #   "-      # Old change" ]
      def changed_lines(changed_file)
        diff = git.diff_for_file(changed_file)
        return [] unless diff

        diff.patch.split("\n").select { |line| %r{^[+-]}.match?(line) }
      end

      def all_ee_changes
        all_changed_files.grep(%r{\Aee/})
      end

      def ee?
        # Support former project name for `dev` and support local Danger run
        %w[gitlab gitlab-ee].include?(ENV['CI_PROJECT_NAME']) || Dir.exist?(File.expand_path('../../../ee', __dir__))
      end

      def gitlab_helper
        # Unfortunately the following does not work:
        # - respond_to?(:gitlab)
        # - respond_to?(:gitlab, true)
        gitlab
      rescue NameError
        nil
      end

      def release_automation?
        gitlab_helper&.mr_author == RELEASE_TOOLS_BOT
      end

      def project_name
        ee? ? 'gitlab' : 'gitlab-foss'
      end

      def markdown_list(items)
        list = items.map { |item| "* `#{item}`" }.join("\n")

        if items.size > 10
          "\n<details>\n\n#{list}\n\n</details>\n"
        else
          list
        end
      end

      # @return [Hash<String,Array<String>>]
      def changes_by_category
        all_changed_files.each_with_object(Hash.new { |h, k| h[k] = [] }) do |file, hash|
          categories_for_file(file).each { |category| hash[category] << file }
        end
      end

      # Determines the categories a file is in, e.g., `[:frontend]`, `[:backend]`, or  `%i[frontend engineering_productivity]`
      # using filename regex and specific change regex if given.
      #
      # @return Array<Symbol>
      def categories_for_file(file)
        _, categories = CATEGORIES.find do |key, _|
          filename_regex, changes_regex = Array(key)

          found = filename_regex.match?(file)
          found &&= changed_lines(file).any? { |changed_line| changes_regex.match?(changed_line) } if changes_regex

          found
        end

        Array(categories || :unknown)
      end

      # Returns the GFM for a category label, making its best guess if it's not
      # a category we know about.
      #
      # @return[String]
      def label_for_category(category)
        CATEGORY_LABELS.fetch(category, "~#{category}")
      end

      CATEGORY_LABELS = {
        docs: "~documentation", # Docs are reviewed along DevOps stages, so don't need roulette for now.
        none: "",
        qa: "~QA",
        test: "~test ~Quality for `spec/features/*`",
        engineering_productivity: '~"Engineering Productivity" for CI, Danger',
        ci_template: '~"ci::templates"'
      }.freeze
      # First-match win, so be sure to put more specific regex at the top...
      CATEGORIES = {
        [%r{usage_data\.rb}, %r{^(\+|-).*(count|distinct_count)\(.*\)(.*)$}] => [:database, :backend],

        %r{\Adoc/.*(\.(md|png|gif|jpg))\z} => :docs,
        %r{\A(CONTRIBUTING|LICENSE|MAINTENANCE|PHILOSOPHY|PROCESS|README)(\.md)?\z} => :docs,

        %r{\A(ee/)?app/(assets|views)/} => :frontend,
        %r{\A(ee/)?public/} => :frontend,
        %r{\A(ee/)?spec/(javascripts|frontend)/} => :frontend,
        %r{\A(ee/)?vendor/assets/} => :frontend,
        %r{\A(ee/)?scripts/frontend/} => :frontend,
        %r{(\A|/)(
          \.babelrc |
          \.eslintignore |
          \.eslintrc(\.yml)? |
          \.nvmrc |
          \.prettierignore |
          \.prettierrc |
          \.scss-lint.yml |
          \.stylelintrc |
          \.haml-lint.yml |
          \.haml-lint_todo.yml |
          babel\.config\.js |
          jest\.config\.js |
          package\.json |
          yarn\.lock |
          config/.+\.js
        )\z}x => :frontend,

        %r{(\A|/)(
          \.gitlab/ci/frontend\.gitlab-ci\.yml
        )\z}x => %i[frontend engineering_productivity],

        %r{\A(ee/)?db/(?!fixtures)[^/]+} => :database,
        %r{\A(ee/)?lib/gitlab/(database|background_migration|sql|github_import)(/|\.rb)} => :database,
        %r{\A(app/models/project_authorization|app/services/users/refresh_authorized_projects_service)(/|\.rb)} => :database,
        %r{\A(ee/)?app/finders/} => :database,
        %r{\Arubocop/cop/migration(/|\.rb)} => :database,

        %r{\A(\.gitlab-ci\.yml\z|\.gitlab\/ci)} => :engineering_productivity,
        %r{\A\.codeclimate\.yml\z} => :engineering_productivity,
        %r{\Alefthook.yml\z} => :engineering_productivity,
        %r{\A\.editorconfig\z} => :engineering_productivity,
        %r{Dangerfile\z} => :engineering_productivity,
        %r{\A(ee/)?(danger/|lib/gitlab/danger/)} => :engineering_productivity,
        %r{\A(ee/)?scripts/} => :engineering_productivity,
        %r{\Atooling/} => :engineering_productivity,
        %r{(CODEOWNERS)} => :engineering_productivity,
        %r{(tests.yml)} => :engineering_productivity,

        %r{\Alib/gitlab/ci/templates} => :ci_template,

        %r{\A(ee/)?spec/features/} => :test,
        %r{\A(ee/)?spec/support/shared_examples/features/} => :test,
        %r{\A(ee/)?spec/support/shared_contexts/features/} => :test,
        %r{\A(ee/)?spec/support/helpers/features/} => :test,

        %r{\A(ee/)?app/(?!assets|views)[^/]+} => :backend,
        %r{\A(ee/)?(bin|config|generator_templates|lib|rubocop)/} => :backend,
        %r{\A(ee/)?spec/} => :backend,
        %r{\A(ee/)?vendor/} => :backend,
        %r{\A(Gemfile|Gemfile.lock|Rakefile)\z} => :backend,
        %r{\A[A-Z_]+_VERSION\z} => :backend,
        %r{\A\.rubocop((_manual)?_todo)?\.yml\z} => :backend,
        %r{\Afile_hooks/} => :backend,

        %r{\A(ee/)?qa/} => :qa,

        # Files that don't fit into any category are marked with :none
        %r{\A(ee/)?changelogs/} => :none,
        %r{\Alocale/gitlab\.pot\z} => :none,
        %r{\Adata/whats_new/} => :none,

        # GraphQL auto generated doc files and schema
        %r{\Adoc/api/graphql/reference/} => :backend,

        # Fallbacks in case the above patterns miss anything
        %r{\.rb\z} => :backend,
        %r{(
          \.(md|txt)\z |
          \.markdownlint\.json
        )}x => :none, # To reinstate roulette for documentation, set to `:docs`.
        %r{\.js\z} => :frontend
      }.freeze

      def new_teammates(usernames)
        usernames.map { |u| Gitlab::Danger::Teammate.new('username' => u) }
      end

      def sanitize_mr_title(title)
        title.gsub(DRAFT_REGEX, '').gsub(/`/, '\\\`')
      end

      def draft_mr?
        return false unless gitlab_helper

        DRAFT_REGEX.match?(gitlab_helper.mr_json['title'])
      end

      def security_mr?
        return false unless gitlab_helper

        gitlab_helper.mr_json['web_url'].include?('/gitlab-org/security/')
      end

      def cherry_pick_mr?
        return false unless gitlab_helper

        /cherry[\s-]*pick/i.match?(gitlab_helper.mr_json['title'])
      end

      def stable_branch?
        return false unless gitlab_helper

        /\A\d+-\d+-stable-ee/i.match?(gitlab_helper.mr_json['target_branch'])
      end

      def mr_has_labels?(*labels)
        return false unless gitlab_helper

        labels = labels.flatten.uniq
        (labels & gitlab_helper.mr_labels) == labels
      end

      def labels_list(labels, sep: ', ')
        labels.map { |label| %Q{~"#{label}"} }.join(sep)
      end

      def prepare_labels_for_mr(labels)
        return '' unless labels.any?

        "/label #{labels_list(labels, sep: ' ')}"
      end

      def changed_files(regex)
        all_changed_files.grep(regex)
      end

      def has_database_scoped_labels?(current_mr_labels)
        current_mr_labels.any? { |label| label.start_with?('database::') }
      end

      def has_ci_changes?
        changed_files(%r{\A(\.gitlab-ci\.yml|\.gitlab/ci/)}).any?
      end
    end
  end
end
