---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: JSON development guidelines
---

At GitLab we handle a lot of JSON data. To best ensure we remain performant
when handling large JSON encodes or decodes, we use our own JSON class
instead of the default methods.

## `Gitlab::Json`

This class should be used in place of any calls to the default `JSON` class,
`.to_json` calls, and the like. It implements the majority of the public
methods provided by `JSON`, such as `.parse`, `.generate`, `.dump`, etc, and
should be entirely identical in its response.

The difference being that by sending all JSON handling through `Gitlab::Json`
we can change the gem being used in the background. We use `oj`
instead of the `json` gem, which uses C extensions and is therefore notably
faster.

This class came into existence because, due to the age of the GitLab application,
it was proving impossible to just replace the `json` gem with `oj` by default because:

- The number of tests with exact expectations of the responses.
- The subtle variances between different JSON processors, particularly
  around formatting.

The `Gitlab::Json` class takes this into account and can
vary the adapter based on the use case, and account for outdated formatting
expectations.

## `Gitlab::Json::PrecompiledJson`

This class is used by our hooks into the Grape framework to ensure that
already-generated JSON is not then run through JSON generation
a second time when returning the response.

## `Gitlab::Json::LimitedEncoder`

This class can be used to generate JSON but fail with an error if the
resulting JSON would be too large. The default limit for the `.encode`
method is 25 MB, but this can be customized when using the method.
