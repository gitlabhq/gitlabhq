---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
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

The `Gitlab::Json.safe_parse` class method is deprecated. For parsing untrusted
input, use [`Gitlab::Json::SafeParser`](#gitlabjsonsafeparser) instead.

## `Gitlab::Json::SafeParser`

`Gitlab::Json::SafeParser` is a thin wrapper around `Oj::Parser.safe` that
enforces structural limits on JSON parsing and converts low-level parser
errors into user-safe `JSON::ParserError` messages. Use it whenever you parse
JSON from an untrusted source.

### Underlying parser

`Gitlab::Json::SafeParser` uses Oj's newer `Oj::Parser.safe` parser.
`Gitlab::Json.parse` and the deprecated `Gitlab::Json.safe_parse` use
`Oj.load` in `:rails` mode. These are two distinct Oj parsers, and behavior
may differ in:

- Supported options. `Gitlab::Json::SafeParser` accepts only the keys defined
  in `PARSE_LIMITS`. Options such as `symbolize_keys` that work with
  `Gitlab::Json.parse` are not forwarded.
- Handling of edge-case values, such as very large numeric values,
  `NaN` and `Infinity`, duplicate keys, and trailing data.
- Exact error message text for malformed JSON.

Test representative payloads when migrating from `Gitlab::Json.parse` or
`Gitlab::Json.safe_parse`, and update assertions that depend on
parser-specific behavior or error strings.

### Parse limits

`Gitlab::Json::SafeParser` validates the input against a configurable set of
limits. The defaults come from `PARSE_LIMITS` in `Gitlab::Json`:

| Option                | Default | Description                                                       |
|-----------------------|---------|-------------------------------------------------------------------|
| `max_depth`           | 32      | Maximum nesting depth.                                            |
| `max_array_size`      | 50,000  | Maximum number of elements in a single array.                     |
| `max_hash_size`       | 50,000  | Maximum number of key-value pairs in a single hash.               |
| `max_total_elements`  | 100,000 | Maximum total number of parsed elements across the payload.       |
| `max_json_size_bytes` | 20 MB   | Maximum size of the input JSON string in bytes.                   |

Passing any other key raises `Gitlab::Json::SafeParser::UnknownConfigurationError`.

### Parse untrusted JSON

For almost all use cases, `Gitlab::Json::SafeParser.parse` is the right
choice. It handles parser caching, limit merging, and error wrapping for
you. Calls with the same limits reuse the same underlying parser:

```ruby
Gitlab::Json::SafeParser.parse(payload)

Gitlab::Json::SafeParser.parse(
  payload,
  max_depth: 10,
  max_json_size_bytes: 1.megabyte
)
```

`.parse` allocates one parser per unique combination of limits and caches
it in the current thread for that thread's lifetime. Reusing the same
limits across calls reuses the same parser, whether those limits are the
defaults or a fixed custom set. The cost to watch for is *varying* limits,
for example, computing limits from a request or a payload, because each
new combination adds another entry to the thread's cache. If you need
custom limits, pick a stable set and stick with it. If your workflow
genuinely needs limits that vary per call, allocate a dedicated parser
with [`.new`](#advanced-dedicated-parser-instance) instead, so the cache
does not grow.

### Advanced: dedicated parser instance

Most code should not use `.new`. The returned instance is bound to the
thread that allocated it, and the underlying `Oj::Parser.safe` is not
thread-safe. The caller is fully responsible for keeping the instance
thread-affine. Sharing it across threads, fibers, or workers raises
`Gitlab::Json::SafeParser::ConcurrencyError` at parse time, not at
allocation. Use `.new` only when you have a clearly single-threaded
workflow that benefits from owning a dedicated parser for its lifetime,
such as a script or a job that processes many payloads with the same
custom limits.

If you have decided you need a dedicated instance, allocate it with `.new`:

```ruby
parser = Gitlab::Json::SafeParser.new(max_array_size: 1_000)
parser.parse(payload)
```

### Error handling

`parse` raises `JSON::ParserError` for malformed JSON, payload-size
violations, and limit violations. The error messages are safe to surface to
users:

- `Parameters nested too deeply`
- `Array parameter too large`
- `Hash parameter too large`
- `Too many total parameters`
- `JSON body too large`

For guidance on when to parse safely and how to handle errors in request
flows, see the
[JSON parsing section in the secure coding guidelines](secure_coding_guidelines/_index.md#json-parsing).

## `Gitlab::Json::PrecompiledJson`

This class is used by our hooks into the Grape framework to ensure that
already-generated JSON is not then run through JSON generation
a second time when returning the response.

## `Gitlab::Json::LimitedEncoder`

This class can be used to generate JSON but fail with an error if the
resulting JSON would be too large. The default limit for the `.encode`
method is 25 MB, but this can be customized when using the method.
