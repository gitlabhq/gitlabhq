# frozen_string_literal: true

module Gitlab
  # Resolves which page entrypoint (Vue 2 or Vue 3) to serve for pages
  # that are rolling out Vue 3 behind a feature flag. Used by
  # `WebpackHelper` and `ViteHelper` at request time.
  #
  # The source of truth is the `vue3_migration.yml` files co-located with
  # each page entry under `app/assets/javascripts/pages/**` (and EE / JH
  # equivalents). Only entries with `status: rollout` need runtime
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

    # Brace-expansion globs that walk CE, EE, and JH page roots in one pass.
    # The leading brace expands to each edition's prefix; missing editions
    # simply return no matches.
    VUE3_MIGRATION_PAGES_GLOB = '{,ee/,jh/}app/assets/javascripts/pages'
    VUE3_MIGRATION_GLOB =
      "#{VUE3_MIGRATION_PAGES_GLOB}/**/#{VUE3_MIGRATION_FILENAME}".freeze

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

      # Hash of entry name (e.g. `pages.projects.jobs.show`) to feature
      # flag name, for entries with `status: rollout`.
      def definitions
        @definitions ||= load_all!
      end

      def reload!
        @definitions = load_all!
      end

      def clear_memoization!
        @definitions = nil
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

        Dir.glob(Rails.root.join(VUE3_MIGRATION_GLOB)).each do |file|
          doc = YAML.safe_load_file(file)

          # The schema is enforced by the validator spec; here we only
          # surface obviously-malformed files so we don't crash a request.
          next unless doc.is_a?(Hash) && doc['status'] == VUE3_MIGRATION_STATUS_ROLLOUT

          # Shadowed CE/EE/JH files are enforced identical by
          # `spec/lib/gitlab/vue3_migration_files_spec.rb`, so later
          # edition matches overriding earlier ones is inconsequential.
          result[entry_name_from_file(file)] = doc['feature_flag']
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

      def entry_name_from_file(file)
        match = file.to_s.match(%r{app/assets/javascripts/pages/(.+)/[^/]+\z})
        raise "Unexpected vue3_migration.yml path: #{file}" unless match

        "pages.#{match[1].tr('/', '.')}"
      end
    end
  end
end
