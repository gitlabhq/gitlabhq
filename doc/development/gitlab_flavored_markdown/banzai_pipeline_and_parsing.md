---
stage: Plan
group: Knowledge
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
description: The Banzai pipeline and parsing.
title: The Banzai pipeline and parsing
---

<!-- vale gitlab.GitLabFlavoredMarkdown = NO -->

Parsing and rendering [GitLab Flavored Markdown](_index.md) into HTML involves different components:

- Banzai pipeline and it's various filters
- Markdown parser

The backend does all the processing for GLFM to HTML. This provides several benefits:

- Security: We run robust sanitization which removes unknown tags, classes and ids.
- References: Our reference syntax requires access to the database to resolve issues, etc, as well as redacting references in which the user has no access.
- Consistency: We want to provide users with a consistent experience, which includes full support of the GLFM syntax and styling. Having a single place where the processing is done allows us to provide that.
- Caching: We cache the HTML in our database when possible, such as for issue or MR descriptions, or comments.
- Quick actions: We use a specialized pipeline to process quick actions, so that we can better detect them in Markdown text.

The frontend handles certain aspects when displaying:

- Math blocks
- Mermaid blocks
- Enforcing certain limits, such as excessive number of math or mermaid blocks.

## The Banzai pipeline

Named after the [surf reef break](https://en.wikipedia.org/wiki/Banzai_Pipeline) in Hawaii, the Banzai pipeline consists of various filters ([lib/banzai/filters](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/banzai/filter)) where Markdown and HTML is transformed in each one, in a pipeline fashion. Various pipelines ([lib/banzai/pipeline](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/banzai/pipeline)) are defined, each with a different sequence of filters, such as `AsciiDocPipeline`, `EmailPipeline`.

The [html-pipeline](https://github.com/gjtorikian/html-pipeline) gem implements the pipeline/filter mechanism.

The primary pipeline is the `FullPipeline`, which is a combination of the `PlainMarkdownPipeline` and the `GfmPipeline`.

### `PlainMarkdownPipeline`

This pipeline contains the filters for transforming raw Markdown into HTML, handled primarily by the `Filter::MarkdownFilter`.

#### `Filter::MarkdownFilter`

This filter interfaces with the actual Markdown parser. The parser uses our [`gitlab-glfm-markdown`](https://gitlab.com/gitlab-org/ruby/gems/gitlab-glfm-markdown) Ruby gem that uses the [`comrak`](https://github.com/kivikakk/comrak) Rust crate.

Text is passed into this filter, and by calling the specified parser engine, generates the corresponding basic HTML.

### `GfmPipeline`

This pipeline contains all the filters that perform the additional transformations on raw HTML into what we consider rendered GLFM.
A Nokogiri document gets passed into each of these filters, and they perform the various transformations.
For example, `EmojiFitler`, `CommitTrailersFilter`, or `SanitizationFilter`.
Anything that can't be handled by the initial Markdown parsing gets handled by these filters.

Of specific note is the `SanitizationFilter`. This is critical for providing safe HTML from possibly malicious input.

### `PostProcessPipeline`

The output from the `FullPipeline` gets cached in the database. However references have already been resolved. Based on
a users' permissions, they may not be able to see those references. `PostProcessPipeline` is responsible for redacting any
confidential information based on user permissions. These changes are never cached, as they need to get recomputed each time
they are displayed.

### `SingleLinePipeline`

The `SingleLinePipeline` is used for single-line text fields like issuable titles. It is configured in the `Issuable` concern with
`cache_markdown_field :title, pipeline: :single_line`.

Unlike the `FullPipeline`, this pipeline does not run the Markdown parser (`MarkdownFilter`). It processes plain text through a minimal set of filters:

- `HtmlEntityFilter` - escapes HTML entities, treating the input as plain text.
- `EmojiFilter` - converts `:emoji:` shortcodes.
- `CustomEmojiFilter` - converts custom emoji shortcodes.
- `AutolinkFilter` - auto-links URLs.
- `ExternalLinkFilter` - processes external links.
- reference filters - resolve GitLab references like `#123`, `@user`, and `!456`.

This means titles do not support bold, italic, code spans, Markdown links, or any other standard Markdown formatting. For more information about what
formatting is available in titles, see [work item and merge request titles](../../user/markdown.md#work-item-and-merge-request-titles).

### Performance

It's important to not only have the filters run as fast as possible, but to ensure that they don't take too long in general.
For this we use several techniques:

- For certain filters that can take a long time, we use a Ruby timeout with `Gitlab::RenderTimeout.timeout` in [TimeoutFilterHandler](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/banzai/filter/concerns/timeout_filter_handler.rb).
  This allows us to interrupt the actual processing if it takes too long.
  In general, using Ruby `timeout` is [not considered safe](https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/).
  We therefore only use it when absolutely necessary, preferring to fix an actual performance problem rather then using a timeout.
- [PipelineTimingCheck](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/banzai/filter/concerns/pipeline_timing_check.rb) allows us to keep track of the cumulative amount of time the pipeline is taking. When we reach a maximum, we can then skip any remaining filters.
  For nearly all filters, it's generally ok to skip them in a case like this in order to show the user _something_, rather than nothing.

  However, there are a couple instances where this is not advisable.
  For example in the `SanitizationFilter`, if that filter does not complete, then we can't show the HTML to the user since there could still be unsanitized HTML.
  In those cases, we have to show an error message.

There is also a `rake` task that can be used for benchmarking. See the [Performance Guidelines](../performance.md#banzai-pipelines-and-filters)

## Markdown parser

We use our [`gitlab-glfm-markdown`](https://gitlab.com/gitlab-org/ruby/gems/gitlab-glfm-markdown) Ruby gem that uses the [`comrak`](https://github.com/kivikakk/comrak) Rust crate.

`comrak` provides 100% compatibility with GFM and CommonMark while allowing additional extensions to be added to it. For example, we were able to implement our multi-line blockquote and wikilink syntax directly in `comrak`. The goal is to move more of the Ruby filters into either `comrak` (if it makes sense) or into `gitlab-glfm-markdown`.

For more information about the various options that get passed into `comrak`, see [`glfm_markdown.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/banzai/filter/markdown_engines/glfm_markdown.rb#L12-L52).

## Caching

The output from the main pipelines get cached in the database, or on occasion in Redis. `CacheMarkdownField` is used
for managing the proper `_html` columns. For example, if there is a `description` column, then a `description_html` column
is managed. If `description_html` is empty, then it hasn't been computed for `description` yet. If it's not empty, then
you are guaranteed that `description_html` is the rendered version of `description`.

Each table that contains a Markdown field also contains a `cached_markdown_version` column. This indicates which
"version" of Markdown it was rendered with. This value controls whether or not already cached HTML may need to get
re-rendered. This can happen if for instance something changes how we render HTML, and we need all cached HTML to be rebuilt.

There are two values which control this. One is the primary application version,
`Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION`. If this is changed in the file, then all cached HTML fields will
get re-rendered, across all installations.

There is also an application level setting, `local_markdown_version`, which allows an administrator to invalidate the cache.
This is documented in [Markdown Cache](../../administration/invalidate_markdown_cache.md). This
might be needed if, for example, a system setting gets changed, such as a new PlantUML server is used and the administrator wants all
fields to use the new value. The documentation also mentions how you could reset just a project, etc.

### Phased rollout of `CACHE_COMMONMARK_VERSION` bumps

Bumping `Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION` historically put heavy strain on the database, because every row with cached Markdown got re-rendered and rewritten on the first read after the bump. The rollout mechanism splits the load across a configurable window using two pieces:

- The `CACHE_COMMONMARK_VERSION_PREVIOUS` constant in `lib/gitlab/markdown_cache.rb`. In steady state (no rollout in progress) this is `nil`, and the mechanism is dormant: `latest_cached_markdown_version` always returns the current shifted version, the feature flag below is ignored, and reads of stale rows are rewritten on the spot, as they were before the mechanism existed.
- The `markdown_cache_stochastic_rollout_<version>` feature flag, a definition-less `markdown_cache`-type flag whose name embeds the target cache version (for example, `markdown_cache_stochastic_rollout_34`). While `CACHE_COMMONMARK_VERSION_PREVIOUS`
  is set, the flag's `percentage_of_time` value controls how aggressively the new version is exposed:
  - At `n%`, the roll returns the new shifted version for approximately `n%` of reads and the previous shifted version otherwise. Different records roll independently; the roll is memoised per model instance.
  - A read that rolls "current" against a row at the previous version triggers `refresh_markdown_cache!`, which rewrites the row.
  - A read that rolls "previous" against a row already at "current" is treated as fresh by `cached_html_up_to_date?`: a persisted version at least as new as the rolled version means no work is needed.
  - Writes always land at the new shifted version, regardless of the roll. This uses `cached_markdown_version_for_write`, which never consults the flag. The flag controls only which reads trigger a rewrite, not what version any given write produces. So new rows and content edits upgrade rows organically during a rollout, on top of the read-driven upgrades the flag controls.
- The `gitlab_markdown_cache_version_upgrades_total` counter, labeled by class, increments inside `save_markdown` only when the write actually advances the row's `cached_markdown_version`. It excludes attempted-but-suppressed writes and same-version content-resync writes.

You can view the `gitlab_markdown_cache_version_upgrades_total` counter using the [Markdown Cache Version Upgrades dashboard](https://dashboards.gitlab.net/d/general-markdown-cache-version-upgrades/general3a-markdown-cache-version-upgrades?orgId=1&from=now-3h&to=now&timezone=utc&var-PROMETHEUS_DS=mimir-gitlab-gprd&var-environment=gprd&refresh=5m) in Grafana.

#### Why percentage-of-time randomness

The flag uses `percentage_of_time` (a "random" gate), not an actor-based gate, by design. The load-shedding goal is that at `n%`, approximately `n%` of read traffic triggers an upgrade write, so the migration progresses as a smooth, throttled stream proportional to read load. We considered two alternatives:

- Per-request actor (`Feature.current_request`): sticky for the duration of one Rack request/Sidekiq job/ActionCable execution. A single request that touches many cached Markdown rows (issue list, MR list, search results) would upgrade _all_ of them in one window at `n%`, producing per-request write bursts proportional to row count rather than smooth load distribution.
- Synthetic per-record actor (`def flipper_id = "...:#{record.id}"`): at `n%`, a fixed `n%` of rows are eligible for upgrade, and the remaining `(100−n)%` are excluded until the percentage is raised. At `1%`, `99%` of hot rows would never migrate. This breaks the desirable "low percentage means slow (but eventual) migration; high percentage means faster" property; instead, each increment of the percentage would eventually top out as all selected (hot) rows are written, meaning you'd want to bump the flag by very small increments all the way up to 100%!

Percentage-of-time randomness gives the desired "slow but eventually covers everything" semantics at any positive percentage: different records roll independently of one another, and a record that rolls "previous" in one request can roll "current" in a later one, so read rows converge over time. The `--random` chatops flag is deprecated for general use because callers usually want a stable answer per actor, and per-call inconsistency surprises most callers; here we use `--random` deliberately: independent rolls across records are what spread the migration load, so the deprecation rationale does not apply.

#### Rollout procedure for a `CACHE_COMMONMARK_VERSION` bump

Two MRs and feature flag adjustments are required for the rollout. The example bumps from `33` to `34`, so the flag is `markdown_cache_stochastic_rollout_34`:

1. **MR1: start the rollout.** In `lib/gitlab/markdown_cache.rb`:
   - Bump `CACHE_COMMONMARK_VERSION` (for example, from `33` to `34`).
   - Set `CACHE_COMMONMARK_VERSION_PREVIOUS` from `nil` to the old version (`33` in this example).

   The version-stamped flag has never been set, so it is disabled: all reads roll "previous" and no cache invalidations are forced. New writes start using the new version.

1. **Enable `percentage_of_time` at a low value** (for example, `1`) on the version-stamped flag through chatops.

   ```slack
   /chatops gitlab run feature set markdown_cache_stochastic_rollout_34 1 --random
   ```

   You **must use the `--random` option** for this flag. Using `--actors` with it is a no-op. This flag is explicitly designed to be used with the `--random` option.

1. **Ramp.** Watch `gitlab_markdown_cache_version_upgrades_total` and database write rate. Increase the percentage gradually (for example, `5`, `25`, `50`, `100`) as headroom allows.

   ```slack
   /chatops gitlab run feature set markdown_cache_stochastic_rollout_34 5 --random
   ```

1. **Observe convergence.** At `100%`, every read of a row still at the previous version triggers a rewrite. The counter rises and then tapers as the hot population converges. Cold rows that are never read remain at the previous version indefinitely; this is intentional and harmless because nothing reads them, and they get picked up automatically on the next bump.

1. **MR2: finalize the rollout.** Set `CACHE_COMMONMARK_VERSION_PREVIOUS` back to `nil`. The system returns to steady state: with `CACHE_COMMONMARK_VERSION_PREVIOUS` at `nil` the flag is ignored, and any remaining row at the previous version is treated as stale and rewritten on first read at natural read rate.

1. **Clean up the flag.** After MR2 is fully deployed, delete the version-stamped flag through chatops.

   ```slack
   /chatops gitlab run feature delete markdown_cache_stochastic_rollout_34
   ```

For unconditional, immediate invalidation (for example, a critical security fix in the renderer), administrators can still bump `local_markdown_version` through the application setting, which forces every row to be re-rendered on next read regardless of the application version.

For more information, see [issue 330313](https://gitlab.com/gitlab-org/gitlab/-/work_items/330313) and [issue 597379](https://gitlab.com/gitlab-org/gitlab/-/work_items/597379).

## Debugging

Usually the easiest way to debug the various pipelines and filters is to run them from the Rails console. This way you can set a `binding.pry` in a filter and step through the code.

Because of `TimeoutFilterHandler` and `PipelineTimingCheck`, it can be a challenge to debug the filters. There is a special environment variable, `GITLAB_DISABLE_MARKDOWN_TIMEOUT`, that when set disables any timeout checking in the filters. This is also available for customers in the rare instance that a [GitLab Self-Managed instance](../../administration/environment_variables.md) wishes to bypass those checks.

```ruby
text = 'Some test **Markdown**'
html = Banzai.render(text, project: nil)
```

This renders the Markdown in relation to no project. Or you can render it in the context of a project:

```ruby
project = Project.first
text = 'Some test **Markdown**'
html = Banzai.render(text, project: project)
```

The `render` method takes the `text` and a `context` hash, which provides various options for rendering. For example you can use `pipeline: :ascii_doc` to run the `AsciiDocPipeline`. The `FullPipeline` is the default.

If you specify `debug_timing: true`, then you will receive a list of filters and how long each takes.

```ruby
Banzai.render(text, project: nil, debug_timing: true)

D, [2024-12-20T13:35:24.246463 #34584] DEBUG -- : 0.000012_s (0.000012_s): NormalizeSourceFilter [PreProcessPipeline]
D, [2024-12-20T13:35:24.246543 #34584] DEBUG -- : 0.000007_s (0.000019_s): TruncateSourceFilter [PreProcessPipeline]
D, [2024-12-20T13:35:24.246589 #34584] DEBUG -- : 0.000028_s (0.000047_s): FrontMatterFilter [PreProcessPipeline]
D, [2024-12-20T13:35:24.246662 #34584] DEBUG -- : 0.000005_s (0.000005_s): IncludeFilter [FullPipeline]
D, [2024-12-20T13:35:24.246816 #34584] DEBUG -- : 0.000088_s (0.000101_s): MarkdownFilter [FullPipeline]
...
D, [2024-12-20T13:35:24.252338 #34584] DEBUG -- : 0.000013_s (0.004394_s): CustomEmojiFilter [FullPipeline]
D, [2024-12-20T13:35:24.252504 #34584] DEBUG -- : 0.000095_s (0.004489_s): TaskListFilter [FullPipeline]
D, [2024-12-20T13:35:24.252558 #34584] DEBUG -- : 0.000028_s (0.004517_s): SetDirectionFilter [FullPipeline]
D, [2024-12-20T13:35:24.252623 #34584] DEBUG -- : 0.000045_s (0.004562_s): SyntaxHighlightFilter [FullPipeline]
```

Use `debug: true` for even more detail per filter.
