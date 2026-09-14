# frozen_string_literal: true

module Gitlab
  # Resolves which entrypoint (Vue 2 or Vue 3) to serve for entries that
  # are rolling out Vue 3 behind a feature flag. Used by `WebpackHelper`
  # and `ViteHelper` at request time.
  #
  # The source of truth is the metadata beside each entry file. The file
  # name says which entry file it describes: `vue3_migration.yml` is the
  # `index.js` of a page under `app/assets/javascripts/pages/**`, and
  # `<name>.vue3_migration.yml` is the `<name>.js` global bundle under
  # `app/assets/javascripts/entrypoints/` (and EE / JH equivalents).
  # Only entries with `status: rollout` need runtime
  # metadata (the feature flag switches between the `<entry>` and
  # `<entry>.vue3` bundles); `migrated` pages build Vue 3 under the
  # original entry name and resolve with no lookup, and pages without a
  # `vue3_migration.yml` sibling are Vue 2 only.
  #
  # In development and test the YAML files are read directly. In
  # production they are not available (packaged builds such as Omnibus
  # strip `app/assets` from the Rails app), so the webpack build compiles
  # them into `vue3_migration.json` next to its `manifest.json`
  # (see `config/plugins/vue3_migration_manifest_plugin.js`), which every
  # distribution ships. A missing manifest raises `ManifestLoadError`
  # rather than silently serving Vue 2.
  #
  # The schema for the YAML files is documented in
  # `config/helpers/vue3_migration_file_validation.js` and enforced by
  # `spec/lib/gitlab/vue3_migration_files_spec.rb`.
  module Vue3Migration
    # Canonical constants for the Vue 3 migration metadata format.
    # Keep them in sync with the JS equivalents in
    # `config/helpers/vue3_migration_file_validation.js`.
    VUE3_MIGRATION_FILENAME = 'vue3_migration.yml'

    # Compiled runtime manifest emitted by the webpack build. Keep in sync
    # with `config/webpack.config.js` and `config/rspack.config.mjs`.
    VUE3_MIGRATION_MANIFEST_FILENAME = 'vue3_migration.json'

    VUE3_MIGRATION_STATUS_ROLLOUT  = 'rollout'
    VUE3_MIGRATION_STATUS_MIGRATED = 'migrated'

    VUE3_MIGRATION_ALLOWED_STATUSES = [
      VUE3_MIGRATION_STATUS_ROLLOUT,
      VUE3_MIGRATION_STATUS_MIGRATED
    ].freeze

    VUE3_MIGRATION_ALLOWED_KEYS = %w[status feature_flag group migration_issue].freeze

    ROOT_PATH = File.expand_path('../..', __dir__)
    JS_ROOTS = %w[app/assets/javascripts ee/app/assets/javascripts jh/app/assets/javascripts].freeze

    # A migration file sits beside the entry module it describes, wherever that
    # is. The leading brace expands to each edition; missing editions match nothing.
    VUE3_MIGRATION_GLOB = "{,ee/,jh/}app/assets/javascripts/**/*#{VUE3_MIGRATION_FILENAME}".freeze

    # `vue3_migration.yml` describes `index.js`, `<name>.vue3_migration.yml` describes `<name>.js`.
    VUE3_MIGRATION_FILE_RE = /\A(?:(?<entry>.+)\.)?#{Regexp.escape(VUE3_MIGRATION_FILENAME)}\z/

    # Hand-declared bundles. Read as text in development and test; production
    # never derives entry names, it reads the compiled manifest.
    ENTRY_POINTS_FILE = 'config/helpers/entry_points.js'
    # Matches both `name: './x.js',` and the conditional `baseEntryPoints.name = './x.js';`.
    ENTRY_POINT_LINE_RE = %r{^\s*(?:baseEntryPoints\.)?(?<name>\w+)\s*[:=]\s*'\./(?<module>[^']+)'}
    # `default: ['./main']`: prepended to every page entry, never a bundle of its own.
    DEFAULT_ENTRY_LINE_RE = %r{^\s*default:\s*\['\./(?<module>[^']+)'\]}

    # Raised in production when the compiled manifest cannot be read.
    class ManifestLoadError < StandardError
      def initialize(message, orig)
        super("#{message}\n\n(original error #{orig.class.name}: #{orig})")
      end
    end

    class << self
      # Resolve the entrypoint name to use at request time given the
      # current feature flag state and a user.
      #
      # Entries rolling out Vue 3 resolve to `${name}.vue3` when their
      # feature flag is enabled. Everything else (Vue 2 only pages and
      # `migrated` pages alike) returns `name` unchanged, so callers can
      # use this transparently.
      def entrypoint_for(name, current_user: nil)
        feature_flag = definitions[name]
        return name unless feature_flag

        # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- the flag name is declared in
        # `vue3_migration.yml` for each page; the corresponding flag definition lives in
        # `config/feature_flags/**/<name>.yml` and is verified by
        # `spec/lib/gitlab/vue3_migration_files_spec.rb`.
        if Feature.enabled?(feature_flag.to_sym, current_user)
          "#{name}.vue3"
        else
          name
        end
        # rubocop:enable Gitlab/FeatureFlagKeyDynamic
      end

      # Whether `name` is switched by a feature flag, so `entrypoint_for`
      # needs an actor for it.
      def rollout?(name)
        definitions.key?(name)
      end

      # The entry module a migration file describes: `index.js` for a bare
      # `vue3_migration.yml`, `<name>.js` for `<name>.vue3_migration.yml`.
      def entry_file_for(file)
        match = File.basename(file.to_s).match(VUE3_MIGRATION_FILE_RE)
        raise "Unexpected #{VUE3_MIGRATION_FILENAME} name: #{file}" unless match

        File.join(File.dirname(file.to_s), "#{match[:entry] || 'index'}.js")
      end

      # The bundler entry name a migration file describes, looked up in
      # `entry_modules`. Mirrors `entryNameFromFile` in
      # `config/helpers/vue3_migration_loader.js`.
      def entry_name_for(file)
        module_file = relative_to_root(entry_file_for(file))

        if module_file == main_module
          raise "#{file} cannot be migrated this way: `main` has no bundle of its own. " \
            "Use the `?vue3` import documented as Option 2 in doc/development/fe_guide/vue3_migration.md."
        end

        entry_modules.fetch(module_file) do
          raise "#{file} describes #{module_file}, which is not a bundler entry. " \
            "Entries are the values of #{ENTRY_POINTS_FILE} and every pages/**/index.js."
        end
      end

      # Repo-relative entry module path -> bundler entry name, for every entry
      # the bundler knows. Mirrors `entryModules` in the JS loader.
      def entry_modules
        @entry_modules ||= begin
          index = {}

          entry_points_lines.each do |line|
            match = line.match(ENTRY_POINT_LINE_RE)
            index[File.join(JS_ROOTS.first, match[:module])] = match[:name] if match
          end

          JS_ROOTS.each do |root|
            Dir.glob(File.join(ROOT_PATH, root, 'pages/**/index.js')).each do |file|
              rel = relative_to_root(file).delete_prefix("#{root}/")
              index[File.join(root, rel)] = rel.delete_suffix('/index.js').tr('/', '.')
            end
          end

          index
        end
      end

      # Module path of the `default` entry, read from `entry_points.js` like the index.
      def main_module
        @main_module ||= begin
          match = entry_points_lines.filter_map { |line| line.match(DEFAULT_ENTRY_LINE_RE) }.first
          raise "No `default` entry found in #{ENTRY_POINTS_FILE}" unless match

          File.join(JS_ROOTS.first, "#{match[:module]}.js")
        end
      end

      def entry_points_lines
        File.readlines(File.join(ROOT_PATH, ENTRY_POINTS_FILE))
      end

      # Hash of entry name (e.g. `pages.projects.jobs.show`) to feature
      # flag name, for entries with `status: rollout`.
      def definitions
        @definitions ||= load_all!
      end

      def reload!
        clear_memoization!
        definitions
      end

      def clear_memoization!
        @definitions = nil
        @entry_modules = nil
        @main_module = nil
      end

      private

      def load_all!
        if Gitlab.dev_or_test_env?
          load_from_source_files
        else
          load_from_compiled_manifest
        end
      end

      # Reads the co-located YAML files. Only available where the full
      # source tree is present, so this is used in development and test;
      # it stays correct under both the webpack and Vite dev servers.
      def load_from_source_files
        result = {}

        Dir.glob(File.join(ROOT_PATH, VUE3_MIGRATION_GLOB)).each do |file|
          doc = YAML.safe_load_file(file)

          # The schema is enforced by the validator spec; here we only
          # surface obviously-malformed files so we don't crash a request.
          next unless doc.is_a?(Hash) && doc['status'] == VUE3_MIGRATION_STATUS_ROLLOUT

          # Shadowed CE/EE/JH files are enforced identical by
          # `spec/lib/gitlab/vue3_migration_files_spec.rb`, so later
          # edition matches overriding earlier ones is inconsequential.
          result[entry_name_for(file)] = doc['feature_flag']
        end

        result
      end

      # Reads the manifest compiled by the webpack build from the same
      # location as `manifest.json`. Raises rather than falling back:
      # a production build without the manifest is mis-packaged, and
      # silently serving Vue 2 would make that impossible to detect
      # (`manifest.json` itself raises in the same situation).
      def load_from_compiled_manifest
        data = Gitlab::Webpack::FileLoader.load(VUE3_MIGRATION_MANIFEST_FILENAME)

        Gitlab::Json::SafeParser.parse(data).transform_values { |entry| entry['feature_flag'] }
      rescue Gitlab::Webpack::FileLoader::BaseError => e
        raise ManifestLoadError.new(
          "Could not load compiled #{VUE3_MIGRATION_MANIFEST_FILENAME} from #{e.uri}.\n\n" \
            "Have you run `rake gitlab:assets:compile`?",
          e.original_error
        )
      end

      def relative_to_root(file)
        file.to_s.delete_prefix("#{ROOT_PATH}/")
      end
    end
  end
end
