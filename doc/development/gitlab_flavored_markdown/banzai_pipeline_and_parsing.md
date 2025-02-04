---
stage: Plan
group: Knowledge
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "The Banzai pipeline and parsing."
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

This filter interfaces with the actual Markdown parser. The primary parser uses our [`gitlab-glfm-markdown`](https://gitlab.com/gitlab-org/ruby/gems/gitlab-glfm-markdown) Ruby gem that uses the [`comrak`](https://github.com/kivikakk/comrak) Rust crate.

A secondary deprecated parser engine uses the [`commonmarker`](https://github.com/gjtorikian/commonmarker/releases/tag/v0.23.11) Ruby gem to interact with the [`cmark-gfm`](https://github.com/github/cmark-gfm) library.

Text is passed into this filter, and by calling the specified parser engine, generates the corresponding basic HTML.

### `GfmPipeline`

This pipeline contains all the filters that perform the additional transformations on raw HTML into what we consider rendered GLFM.
A Nokogiri document gets passed into each of these filters, and they perform the various transformations.
For example, `EmojiFitler`, `CommitTrailersFilter`, or `SanitizationFilter`.
Anything that can't be handled by the initial Markdown parsing gets handled by these filters.

Of specific note is the `SanitizationFilter`. This is critical for providing safe HTML from possibly malicious input.

### Performance

It's important to not only have the filters run as fast as possible, but to ensure that they don't take too long in general.
For this we use several techniques:

- For certain filters that can take a long time, we use a Ruby timeout with `Gitlab::RenderTimeout.timeout` in [TimeoutFilterHandler](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/banzai/filter/concerns/timeout_filter_handler.rb).
  This allows us to interrupt the actual processing if it takes too long.
  It's **important** to note that in general using Ruby `timeout` is [not considered safe](https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/).
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

Please see [glfm_markdown.rb](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/banzai/filter/markdown_engines/glfm_markdown.rb#L12-L34) for the various options that get passed into `comrak`.

## Debugging

Usually the easiest way to debug the various pipelines and filters is to run them from the Rails console. This way you can set a `binding.pry` in a filter and step through the code.

Because of `TimeoutFilterHandler` and `PipelineTimingCheck`, it can be a challenge to debug the filters. There is a special environment variable, `GITLAB_DISABLE_MARKDOWN_TIMEOUT`, that when set disables any timeout checking in the filters. This is also available for customers in the rare instance that a [self-managed instance](../../administration/environment_variables.md) wishes to bypass those checks.

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
D, [2024-12-20T13:35:24.246684 #34584] DEBUG -- : 0.000003_s (0.000008_s): MarkdownPreEscapeLegacyFilter [FullPipeline]
D, [2024-12-20T13:35:24.246699 #34584] DEBUG -- : 0.000002_s (0.000010_s): DollarMathPreLegacyFilter [FullPipeline]
D, [2024-12-20T13:35:24.246715 #34584] DEBUG -- : 0.000003_s (0.000013_s): BlockquoteFenceLegacyFilter [FullPipeline]
D, [2024-12-20T13:35:24.246816 #34584] DEBUG -- : 0.000088_s (0.000101_s): MarkdownFilter [FullPipeline]
...
D, [2024-12-20T13:35:24.252338 #34584] DEBUG -- : 0.000013_s (0.004394_s): CustomEmojiFilter [FullPipeline]
D, [2024-12-20T13:35:24.252504 #34584] DEBUG -- : 0.000095_s (0.004489_s): TaskListFilter [FullPipeline]
D, [2024-12-20T13:35:24.252558 #34584] DEBUG -- : 0.000028_s (0.004517_s): SetDirectionFilter [FullPipeline]
D, [2024-12-20T13:35:24.252623 #34584] DEBUG -- : 0.000045_s (0.004562_s): SyntaxHighlightFilter [FullPipeline]
```

Use `debug: true` for even more detail per filter.
