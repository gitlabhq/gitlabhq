# frozen_string_literal: true

require_relative 'teammate'

module Gitlab
  module Danger
    module Helper
      RELEASE_TOOLS_BOT = 'gitlab-release-tools-bot'

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

      def ee?
        # Support former project name for `dev` and support local Danger run
        %w[gitlab gitlab-ee].include?(ENV['CI_PROJECT_NAME']) || Dir.exist?('../../ee')
      end

      def gitlab_helper
        # Unfortunately the following does not work:
        # - respond_to?(:gitlab)
        # - respond_to?(:gitlab, true)
        gitlab
      rescue NoMethodError
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
          hash[category_for_file(file)] << file
        end
      end

      # Determines the category a file is in, e.g., `:frontend` or `:backend`
      # @return[Symbol]
      def category_for_file(file)
        _, category = CATEGORIES.find { |regexp, _| regexp.match?(file) }

        category || :unknown
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
        engineering_productivity: '~"Engineering Productivity" for CI, Danger'
      }.freeze
      CATEGORIES = {
        %r{\Adoc/} => :none, # To reinstate roulette for documentation, set to `:docs`.
        %r{\A(CONTRIBUTING|LICENSE|MAINTENANCE|PHILOSOPHY|PROCESS|README)(\.md)?\z} => :none, # To reinstate roulette for documentation, set to `:docs`.

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
          karma\.config\.js |
          webpack\.config\.js |
          package\.json |
          yarn\.lock |
          \.gitlab/ci/frontend\.gitlab-ci\.yml
        )\z}x => :frontend,

        %r{\A(ee/)?db/(?!fixtures)[^/]+} => :database,
        %r{\A(ee/)?lib/gitlab/(database|background_migration|sql|github_import)(/|\.rb)} => :database,
        %r{\A(app/models/project_authorization|app/services/users/refresh_authorized_projects_service)(/|\.rb)} => :database,
        %r{\Arubocop/cop/migration(/|\.rb)} => :database,

        %r{\A(\.gitlab-ci\.yml\z|\.gitlab\/ci)} => :engineering_productivity,
        %r{Dangerfile\z} => :engineering_productivity,
        %r{\A(ee/)?(danger/|lib/gitlab/danger/)} => :engineering_productivity,
        %r{\A(ee/)?scripts/} => :engineering_productivity,

        %r{\A(ee/)?app/(?!assets|views)[^/]+} => :backend,
        %r{\A(ee/)?(bin|config|generator_templates|lib|rubocop)/} => :backend,
        %r{\A(ee/)?spec/features/} => :test,
        %r{\A(ee/)?spec/(?!javascripts|frontend)[^/]+} => :backend,
        %r{\A(ee/)?vendor/(?!assets)[^/]+} => :backend,
        %r{\A(ee/)?vendor/(languages\.yml|licenses\.csv)\z} => :backend,
        %r{\A(Gemfile|Gemfile.lock|Procfile|Rakefile)\z} => :backend,
        %r{\A[A-Z_]+_VERSION\z} => :backend,
        %r{\A\.rubocop(_todo)?\.yml\z} => :backend,

        %r{\A(ee/)?qa/} => :qa,

        # Files that don't fit into any category are marked with :none
        %r{\A(ee/)?changelogs/} => :none,
        %r{\Alocale/gitlab\.pot\z} => :none,

        # Fallbacks in case the above patterns miss anything
        %r{\.rb\z} => :backend,
        %r{\.(md|txt)\z} => :none, # To reinstate roulette for documentation, set to `:docs`.
        %r{\.js\z} => :frontend
      }.freeze

      def new_teammates(usernames)
        usernames.map { |u| Gitlab::Danger::Teammate.new('username' => u) }
      end

      def missing_database_labels(current_mr_labels)
        labels = if has_database_scoped_labels?(current_mr_labels)
                   ['database']
                 else
                   ['database', 'database::review pending']
                 end

        labels - current_mr_labels
      end

      def security_mr?
        return false unless gitlab_helper

        gitlab_helper.mr_json['web_url'].include?('/gitlab-org/security/')
      end

      private

      def has_database_scoped_labels?(current_mr_labels)
        current_mr_labels.any? { |label| label.start_with?('database::') }
      end
    end
  end
end
