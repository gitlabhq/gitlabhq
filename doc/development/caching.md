---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Caching guidelines
---

This document describes the various caching strategies in use at GitLab, how to implement
them effectively, and various gotchas. This material was extracted from the excellent
[Caching Workshop](https://gitlab.com/gitlab-org/create-stage/-/issues/12820).

## What is a cache?

A faster store for data, which is:

- Used in many areas of computing.
  - Processors have caches, hard disks have caches, lots of things have caches!
- Often closer to where you want the data to finally end up.
- A simpler store for data.
- Temporary.

## What is fast?

The goal for every web page should be to return in under 100 ms:

- This is achievable, but you need caching on a modern application.
- Larger responses take longer to build, and caching becomes critical to maintaining a constant speed.
- Cache reads are typically sub-1 ms. There is very little that this doesn't improve.
- It's no good only being fast on subsequent page loads, as the initial experience
  is important too, so this isn't a complete solution.
- User-specific data makes this challenging, and presents the biggest challenge
  in refactoring existing applications to meet this speed goal.
- User-specific caches can still be effective but they just result in fewer cache
  hits than generic caches shared between users.
- We're aiming to always have a majority of a page load pulled from the cache.

## Why use a cache?

- To make things faster!
- To avoid IO.
  - Disk reads.
  - Database queries.
  - Network requests.
- To avoid recalculation of the same result multiple times:
  - View rendering.
  - JSON rendering.
  - Markdown rendering.
- To provide redundancy. In some cases, caching can help disguise failures elsewhere,
  such as CloudFlare's "Always Online" feature
- To reduce memory consumption. Processing less in Ruby but just fetching big strings
- To save money. Especially true in cloud computing, where processors are expensive compared to RAM.

## Doubts about caching

- Some engineers are opposed to caching except as a last resort, considering it to
  be a hack, and that the real solution is to improve the underlying code to be faster.
- This is could be fed by fear of cache expiry, which is understandable.
- But caching is _still faster_.
- You must use both techniques to achieve true performance:
  - There's no point caching if the initial cold write is so slow it times out, for example.
  - But there are few cases where caching isn't a performance boost.
- However, you can totally use caching as a quick hack, and that's cool too.
  Sometimes the "real" fix takes months, and caching takes only a day to implement.

### Caching at GitLab

Despite downsides to Redis caching, you should still feel free to make good use of the
caching setup inside the GitLab application and on GitLab.com. Our
[forecasting for cache utilization](https://gitlab-com.gitlab.io/gl-infra/tamland/forecasting/)
indicates we have plenty of headroom.

## Workflow

## Methodology

1. Cache as close to your final user as possible. as often as possible.
   - Caching your view rendering is by far the best performance improvement.
1. Try to cache as much data for as many users as possible:
   - Generic data can be cached for everyone.
   - You must keep this in mind when building new features.
1. Try to preserve cache data as much as possible:
   - Use nested caches to maintain as much cached data as possible across expires.
1. Perform as few requests to the cache as possible:
   - This reduces variable latency caused by network issues.
   - Lower overhead for each read on the cache.

### Identify what benefits from caching

Is the cache being added "worthy"? This can be hard to measure, but you can consider:

- How large is the cached data?
  - This might affect what type of cache storage you should use, such as storing
    large HTML responses on disk rather than in RAM.
- How much I/O, CPU, and response time is saved by caching the data?
  - If your cached data is large but the time taken to render it is low, such as
    dumping a big chunk of text into the page, this might indicate the best place to cache it.
- How often is this data accessed?
  - Caching frequently-accessed data usually has a greater effect.
- How often does this data change?
  - If the cache rotates before the cache is read again, is this cache actually useful?

### Tools

#### Investigation

- The performance bar is your first step when investigating locally and in production.
  Look for expensive queries, excessive Redis calls, etc.
- Generate a flamegraph: add `?performance_bar=flamegraph` to the URL to help find
  the methods where time is being spent.
- Dive into the Rails logs:
  - Look closely at render times of partials too.
  - To measure the response time alone, you can parse the JSON logs using `jq`:
    - `tail -f log/development_json.log | jq ".duration_s"`
    - `tail -f log/api_json.log | jq ".duration_s"`
  - Some pointers for items to watch when you tail `development.log`:
    - `tail -f log/development.log | grep "cache hits"`
    - `tail -f log/development.log | grep "Rendered "`
- After you're looking in the right place:
  - Remove or comment out sections of code until you find the cause.
  - Use `binding.pry` to poke about in live requests. This requires a
    [foreground web process](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/pry.md).

#### Verification

- Grafana, in particular the following dashboards:
  - [`api: Rails Controller`](https://dashboards.gitlab.net/d/api-rails-controller/api-rails-controller?orgId=1)
  - [`web: Rails Controller`](https://dashboards.gitlab.net/d/web-rails-controller/web-rails-controller?orgId=1)
  - [`redis-cache: Overview`](https://dashboards.gitlab.net/d/redis-cache-main/redis-cache-overview?orgId=1)
- Logs
  - For situations where Grafana charts don't cover what you need, use Kibana instead.
- Feature flags:
  - It's nearly always worth using a feature flag when adding a cache.
  - Toggle it on and off and watch the wiggly lines in Grafana.
  - Expect response times to go up initially as the caches warm.
  - The effect isn't obvious until you're running the flag at 100%.
- Performance bar:
  - Use this locally and look for the cache calls in the Redis list.
  - Also use this in production to verify your cache keys are what you expect.
- Flamegraphs:
  - Append `?performance_bar=flamegraph` to the page

## Cache levels

### High level

- HTTP caching:
  - Use ETags and expiry times to instruct browsers to serve their own cached versions.
  - This _does_ still hit Rails, but skips the view layer.
- HTTP caching in a reverse proxy cache:
  - Same as above, but with a `public` setting.
  - Instead of the browser, this instructs a reverse proxy (such as NGINX, HAProxy, Varnish) to serve a cached version.
  - Subsequent requests never hit Rails.
- HTML page caching:
  - Write a HTML file to disk
  - Web server (such as NGINX, Apache, Caddy) serves the HTML file itself, skipping Rails.
- View or action caching
  - Rails writes the entire rendered view into its cache store and serves it back.
- Fragment caching:
  - Cache parts of a view in the Rails cache store.
  - Cached parts are inserted into the view as it renders.

### Low level

1. Method caching:
   - Calling the same method multiple times but only calculating the value once.
   - Stored in Ruby memory.
   - `@article ||= Article.find(params[:id])`
   - `strong_memoize_attr :method_name`
1. Request caching:
   - Return the same value for a key for the duration of a web request.
   - `Gitlab::SafeRequestStore.fetch`
1. Read-through or write-through SQL caching:
   - Cache sitting in front of the database.
   - Rails does this within a request for the same query.
1. Novelty caches.
1. Hyper-specific caches for one use case.

### Rails' built-in caching helpers

This is well-documentation in the [Rails guides](https://guides.rubyonrails.org/caching_with_rails.html)

- HTML page caching and action caching are no longer included by default, but they are still useful.
- The Rails guides call HTTP caching
  [Conditional GET](https://guides.rubyonrails.org/caching_with_rails.html#conditional-get-support).
- For Rails' cache store, remember two very important (and almost identical) methods:
  - `cache` in views, which is almost an alias for:
  - `Rails.cache.fetch`, which you can use everywhere.
- `cache` includes a "template tree digest" which changes when you modify your view files.

#### Rails cache options

##### `expires_in`

This sets the Time To Live (TTL) for the cache entry, and is the single most useful
(and most commonly used) cache option. This is supported in most Rails caching helpers.

##### `race_condition_ttl`

This option prevents multiple uncached hits for a key at the same time.
The first process that finds the key expired bumps the TTL by this amount, and it
then sets the new cache value.

Used when a cache key is under very heavy load to prevent multiple simultaneous
writes, but should be set to a low value, such as 10 seconds.

### When to use HTTP caching

Use conditional GET caching when the entire response is cacheable:

- No privacy risk when you aren't using public caches. You're only caching what
  the user sees, for that user, in their browser.
- Particularly useful on [endpoints that get polled](polling.md).
- Good examples:
  - A list of discussions that we poll for updates. Use the last created entry's `updated_at` value for the `etag`.
  - API endpoints.

#### Possible downsides

- Users and API libraries can ignore the cache.
- Sometimes Chrome does weird things with caches.
- You forget it exists in development mode and get angry when your changes aren't appearing.
- In theory using conditional GET caching makes sense everywhere, but in practice it can
  sometimes cause odd issues.

### When to use view or action caching

This is no longer very commonly used in the Rails world:

- Support for it was removed from the Rails core.
- Usually better to look at reverse proxy caching or conditional GET responses.
- However it offers a somewhat simple way of emulating HTML page caching without
  writing to disk, which makes it useful in cloud environments.
- Stores rather large chunks of markup in the cache store.
- We do have a custom implementation of this available on the API, where it is more
  useful, in `cache_action`.

### When to use fragment caching

All the time!

- Probably the most useful caching type to use in Rails, as it allows you to cache sections
  of views, entire partials, collections of partials.
- Rendered collections of partials should be engineered with the goal of using
  `cached: true` on them.
- It's faster to cache around the render call for a partial than inside the partial,
  but then you lose out on the template tree digest, which means the caches don't expire
  automatically when you update that partial.
- Beware of introducing lots of cache calls, such as placing a cache call inside a loop.
  Sometimes it's unavoidable, but there are options for getting around this, like the partial collection caching.
- View rendering, and JSON generation, are slow, and should be cached wherever possible.

### When to use method caching

- Use instance variables, or [`StrongMemoize`](utilities.md#strongmemoize).
- Useful when the same value is needed multiple times in a request.
- Can be used to prevent multiple cache calls for the same key.
- Can cause issues with ActiveRecord objects where a value doesn't change until you call
  reload, which tends to crop up in the test suite.

### When to use request caching

- Similar usage pattern to method caching but can be used across multiple methods.
- Standardized way of storing something for the duration of a request.
- As the lookup is similar to a cache lookup (in the GitLab implementation), we can use
  the same key for both. This is how `Gitlab::Cache.fetch_once` works.

#### Possible downsides

- Adding new attributes to a cached object using `Gitlab::Cache::JsonCache`
  and `Gitlab::SafeRequestStore`, for example, can lead to stale data issues
  where the cache data doesn't have the appropriate value for the new attribute
  (see this past [incident](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6372)).

### When to use SQL caching

Rails uses this automatically for identical queries in a request, so no action is
needed for that use case.

- However, using a gem like `identity_cache` has a different purpose: caching queries
  across multiple requests.
- Avoid using on single object lookups, like `Article.find(params[:id])`.
- Sometimes it's not possible to use the result, as it provides a read-only object.
- It can also cache relationships, useful in situations where we want to return a
  list of things but don't care about filtering or ordering them differently.

### When to use a novelty cache

If you've exhausted other options, and must cache something that's really awkward,
it's time to look at a custom solution:

- Examples in GitLab include `RepositorySetCache`, `RepositoryHashCache` and `AvatarCache`.
- Where possible, you should avoid creating custom cache implementations as it adds
  inconsistency.
- Can be extremely effective. For example, the caching around `merged_branch_names`,
  using [RepositoryHashCache](https://gitlab.com/gitlab-org/gitlab/-/issues/30536#note_290824711).

## Cache expiration

### How Redis expires keys

In short: the oldest stuff is replaced with new stuff:

- A [useful article](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/) about configuring Redis as an LRU cache.
- Lots of options for different cache eviction strategies.
- You probably want `allkeys-lru`, which is functionally similar to Memcached.
- In Redis 4.0 and later, [allkeys-lfu is available](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/),
  which is similar but different.
- We handle all explicit deletes using `UNLINK` instead of `DEL` now, which allows Redis to
  reclaim memory in its own time, rather than immediately.
  - This marks a key as deleted and returns a successful value quickly,
    but actually deletes it later.

### How Rails expires keys

- Rails prefers using TTL and cache key expiry to using explicit deletes.
- Cache keys include a template tree digest by default when fragment caching in
  views, which ensure any changes to the template automatically expire the cache.
  - This isn't true in helpers, though, as a warning.
- Rails has two cache key methods on ActiveRecord objects: `cache_key_with_version` and `cache_key`.
  The first one is used by default in version 5.2 and later, and is the standard behavior from before;
  it includes the `updated_at` timestamp in the key.

#### Cache key components

Example found in the `application.log`:

```plaintext
cache(@project, :tag_list)
views/projects/_home_panel:462ad2485d7d6957e03ceba2c6717c29/projects/16-2021031614242546945
2/tag_list
```

1. The view name and template tree digest
   `views/projects/_home_panel:462ad2485d7d6957e03ceba2c6717c29`
1. The model name, ID, and `updated_at` values
   `projects/16-20210316142425469452`
1. The symbol we passed in, converted to a string
   `tag_list`

### Look for

- User-specific data
  - This is the most important!
  - This isn't always obvious, particularly in views.
  - You must trawl every helper method that's used in the area you want to cache.
- Time-specific data, such as "Billy posted this 8 minutes ago".
- Records being updated but not triggering the `updated_at` field to change
- Rails helpers roll the template digest into the keys in views, but this doesn't happen elsewhere, such as in helpers.
- `Grape::Entity` makes effective caching extremely difficult in the API layer. More on this later.
- Don't use `break` or `return` inside the fragment cache helper in views - it never writes a cache entry.
- Reordering items in a cache key that could return old data:
  - such as having two values that could return `nil` and swapping them around.
  - Use hashes, like `{ project: nil }` instead.
- Rails calls `#cache_key` on members of an array to find the keys, but it doesn't call it on values of hashes.
