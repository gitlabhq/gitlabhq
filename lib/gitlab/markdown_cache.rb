# frozen_string_literal: true

module Gitlab
  module MarkdownCache
    # Increment this number to invalidate cached HTML from Markdown documents.
    # Even when reverting an MR, we should increment this because we only
    # persist the cache when the new version is higher.
    #
    # Bumping this value historically put strain on the database, as every row
    # with cached Markdown got re-rendered and rewritten on first read after
    # the bump. To make safe bumps possible, this module supports a phased
    # rollout driven by the `markdown_cache_stochastic_rollout_<version>`
    # feature flag and the `CACHE_COMMONMARK_VERSION_PREVIOUS` constant below.
    #
    # DO NOT bump this without following the rollout procedure in
    # `doc/development/gitlab_flavored_markdown/banzai_pipeline_and_parsing.md`.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/597379.
    CACHE_COMMONMARK_VERSION       = 34
    CACHE_COMMONMARK_VERSION_START = 10

    # Set to the previous `CACHE_COMMONMARK_VERSION` only during a rollout
    # window. `nil` in steady state means "no rollout active": calls to
    # `latest_cached_markdown_version` always return the current shifted
    # version, the feature flag is ignored, and reads with stale HTML are
    # rewritten on the spot. Writes always use the current shifted version
    # via `cached_markdown_version_for_write`, regardless of rollout state;
    # the flag controls read-side staleness only.
    #
    # See `doc/development/gitlab_flavored_markdown/banzai_pipeline_and_parsing.md`
    # for the full rollout procedure.
    CACHE_COMMONMARK_VERSION_PREVIOUS = 33

    CACHE_COMMONMARK_VERSION_SHIFTED = CACHE_COMMONMARK_VERSION << 16
    CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED =
      CACHE_COMMONMARK_VERSION_PREVIOUS ? CACHE_COMMONMARK_VERSION_PREVIOUS << 16 : nil

    BaseError = Class.new(StandardError)
    UnsupportedClassError = Class.new(BaseError)

    # Used for staleness checks: during a phased rollout, this rolls via
    # `current_shifted_version` and may return the previous shifted version.
    #
    # To get the version a write should use, refer to
    # `cached_markdown_version_for_write` instead.
    #
    # We could be called by a method that is inside the Gitlab::CurrentSettings
    # object. In this case we need to pass in the local_markdown_version in order
    # to avoid an infinite loop. See usage in `app/models/concerns/cache_markdown_field.rb`
    # Otherwise pass in `nil`.
    def self.latest_cached_markdown_version(local_version:)
      local_version = resolved_local_version(local_version)

      current_shifted_version | local_version
    end

    # The version any write should use. Always the current shifted version,
    # regardless of any ongoing cache roll: we are running the new code,
    # so writes (new rows, content edits) always use the new version.
    def self.cached_markdown_version_for_write(local_version:)
      local_version = resolved_local_version(local_version)

      CACHE_COMMONMARK_VERSION_SHIFTED | local_version
    end

    # The full version a row at the previous version carries, i.e. what a write
    # would have produced during that version's lifetime.
    # Returns nil outside a rollout, when there is no previous version.
    # Used to classify upgrades in `upgrade_kind`.
    def self.previous_cached_markdown_version(local_version:)
      return if CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED.nil?

      CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED | resolved_local_version(local_version)
    end

    def self.resolved_local_version(local_version)
      local_version || Gitlab::CurrentSettings.current_application_settings.local_markdown_version
    end
    private_class_method :resolved_local_version

    # The shifted (high-bits) portion of the cache version this call should
    # treat as current. In steady state, always returns
    # `CACHE_COMMONMARK_VERSION_SHIFTED`. During a rollout, the
    # `markdown_cache_stochastic_rollout_<version>` flag is consulted with
    # `percentage_of_time` semantics, rolling per call between current and
    # previous.
    #
    # Per-call independence is by design and is the load-shedding mechanism:
    # at n%, we want approximately n% of *read traffic* to trigger an upgrade
    # write, so the migration completes in a smooth, throttled stream. The
    # usual alternatives (current-request actor, synthetic per-record actor)
    # do not have this property; see "Why percentage-of-time randomness" in
    # `doc/development/gitlab_flavored_markdown/banzai_pipeline_and_parsing.md`
    # for a fuller analysis.
    def self.current_shifted_version
      return CACHE_COMMONMARK_VERSION_SHIFTED if CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED.nil?

      if stochastic_rollout_enabled?
        CACHE_COMMONMARK_VERSION_SHIFTED
      else
        CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED
      end
    end
    private_class_method :current_shifted_version

    # The flag name embeds the target cache version, so every bump uses its own
    # flag. A fresh flag starts disabled, so a percentage left set on a previous
    # bump's flag cannot carry into the next one. The flag has no YAML
    # definition; see the `markdown_cache` feature flag type.
    def self.stochastic_rollout_enabled?
      # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- name is version-stamped by design
      # rubocop:disable Gitlab/FeatureFlagWithoutActor -- percentage-of-time rolling without an actor is the load-shedding mechanism
      Feature.enabled?(
        :"markdown_cache_stochastic_rollout_#{CACHE_COMMONMARK_VERSION}",
        type: :markdown_cache,
        default_enabled_if_undefined: false
      )
      # rubocop:enable Gitlab/FeatureFlagWithoutActor
      # rubocop:enable Gitlab/FeatureFlagKeyDynamic
    end
    private_class_method :stochastic_rollout_enabled?

    # Counter for cached markdown rows that were actually upgraded to a higher
    # `cached_markdown_version`. Incremented inside `save_markdown` after the
    # write guard passes and only when the new version is higher than the
    # load-time persisted version. This excludes attempted-but-suppressed writes
    # and same-version content-resync writes.
    #
    # Labeled by `class` and by `kind` (see `upgrade_kind`).
    def self.version_upgrade_counter
      @version_upgrade_counter ||= Gitlab::Metrics.counter(
        :gitlab_markdown_cache_version_upgrades_total,
        'Number of rows whose cached_markdown_version was advanced to a higher value'
      )
    end

    # Classifies an upgrade by the row's load-time persisted version, for the
    # `kind` label on `version_upgrade_counter`. A row sitting at the previous
    # version is the rollout's target population (`rollout`); anything older, or
    # versionless, is a straggler we catch up regardless of rollout state
    # (`backfill`).
    #
    # Outside a rollout `previous_cached_markdown_version` is nil and every
    # upgrade is a `backfill`.
    def self.upgrade_kind(persisted_version, local_version: nil)
      return :backfill if persisted_version.nil?

      if persisted_version == previous_cached_markdown_version(local_version: local_version)
        :rollout
      else
        :backfill
      end
    end
  end
end
