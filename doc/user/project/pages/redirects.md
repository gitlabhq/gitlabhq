---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages redirects
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

In GitLab Pages, you can configure rules to forward one URL to another using
[Netlify style](https://docs.netlify.com/routing/redirects/#syntax-for-the-redirects-file)
HTTP redirects.

Not all
[special options offered by Netlify](https://docs.netlify.com/routing/redirects/redirect-options/)
are supported.

| Feature                                           | Supported              | Example |
|---------------------------------------------------|------------------------|---------|
| [Redirects (`301`, `302`)](#redirects)            | **{check-circle}** Yes | `/wardrobe.html /narnia.html 302` |
| [Rewrites (`200`)](#rewrites)                     | **{check-circle}** Yes | `/* / 200` |
| [Splats](#splats)                                 | **{check-circle}** Yes | `/news/*  /blog/:splat` |
| [Placeholders](#placeholders)                     | **{check-circle}** Yes | `/news/:year/:month/:date /blog-:year-:month-:date.html` |
| Rewrites (other than `200`)                       | **{dotted-circle}** No | `/en/* /en/404.html 404` |
| Query parameters                                  | **{dotted-circle}** No | `/store id=:id  /blog/:id  301` |
| Force ([shadowing](https://docs.netlify.com/routing/redirects/rewrites-proxies/#shadowing)) | **{dotted-circle}** No | `/app/  /app/index.html  200!` |
| [Domain-level redirects](#domain-level-redirects) | **{check-circle}** Yes | `http://blog.example.com/* https://www.example.com/blog/:splat 301` |
| Redirect by country or language                   | **{dotted-circle}** No | `/  /anz     302  Country=au,nz` |
| Redirect by role                                  | **{dotted-circle}** No | `/admin/*  200!  Role=admin` |

NOTE:
The [matching behavior test cases](https://gitlab.com/gitlab-org/gitlab-pages/-/blob/master/internal/redirects/matching_test.go)
are a good resource for understanding how GitLab implements rule matching in
detail. Community contributions are welcome for any edge cases that aren't included in
this test suite!

## Create redirects

To create redirects, create a configuration file named `_redirects` in the
`public/` directory of your GitLab Pages site.

- All paths must start with a forward slash `/`.
- A default status code of `301` is applied if no [status code](#http-status-codes) is provided.
- The `_redirects` file has a file size limit and a maximum number of rules per project,
  configured at the instance level. Only the first matching rules within the configured maximum are processed.
  The default file size limit is 64 KB, and the default maximum number of rules is 1,000.
- If your GitLab Pages site uses the default domain name (such as
  `namespace.gitlab.io/project-slug`) you must prefix every rule with the path:

  ```plaintext
  /project-slug/wardrobe.html /project-slug/narnia.html 302
  ```

- If your GitLab Pages site uses [custom domains](custom_domains_ssl_tls_certification/_index.md),
  no project path prefix is needed. For example, if your custom domain is `example.com`,
  your `_redirects` file would look like:

  ```plaintext
  /wardrobe.html /narnia.html 302
  ```

## Files override redirects

Files take priority over redirects. If a file exists on disk, GitLab Pages serves
the file instead of your redirect. For example, if the files `hello.html` and
`world.html` exist, and the `_redirects` file contains the following line, the redirect
is ignored because `hello.html` exists:

```plaintext
/project-slug/hello.html /project-slug/world.html 302
```

GitLab does not support Netlify
[force option](https://docs.netlify.com/routing/redirects/rewrites-proxies/#shadowing)
to change this behavior.

## HTTP status codes

A default status code of `301` is applied if no status code is provided, but
you can explicitly set your own. The following HTTP codes are supported:

- **301**: Permanent redirect.
- **302**: Temporary redirect.
- **200**: Standard response for successful HTTP requests. Pages
  serves the content in the `to` rule if it exists, without changing the URL in
  the address bar.

## Redirects

To create a redirect, add a rule that includes a `from` path, a `to` path,
and an [HTTP status code](#http-status-codes):

```plaintext
# 301 permanent redirect
/old/file.html /new/file.html 301

# 302 temporary redirect
/old/another_file.html /new/another_file.html 302
```

## Rewrites

> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/619) in GitLab 15.2.

Provide a status code of `200` to serve the content of the `to` path when the
request matches the `from`:

```plaintext
/old/file.html /new/file.html 200
```

This status code can be used in combination with [splat rules](#splats) to dynamically
rewrite the URL.

## Domain-level redirects

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/936) in GitLab 16.8 [with a flag](../../../administration/feature_flags.md) named `FF_ENABLE_DOMAIN_REDIRECT`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/3395) in GitLab 16.9.
> - [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1087) in GitLab 16.10.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1097) in GitLab 17.4. Feature flag `FF_ENABLE_DOMAIN_REDIRECT` removed.

To create a domain-level redirect, add a domain-level path (beginning with `http://`
or `https://`) to either:

- The `to` path only.
- The `from` and `to` paths.

The supported [HTTP status codes](#http-status-codes) are `301` and `302`:

```plaintext
# 301 permanent redirect
http://blog.example.com/file_1.html https://www.example.com/blog/file_1.html 301
/file_2.html https://www.example.com/blog/file_2.html 301

# 302 temporary redirect
http://blog.example.com/file_3.html https://www.example.com/blog/file_3.html 302
/file_4.html https://www.example.com/blog/file_4.html 302
```

Domain-level redirects can be used in combination with [splat rules](#splats) (including splat placeholders)
to dynamically rewrite the URL path.

## Splats

A rule with an asterisk (`*`) in its `from` path, known as a splat, matches
anything at the start, middle, or end of the requested path. This example
matches anything after `/old/` and rewrites it to `/new/file.html`:

```plaintext
/old/* /new/file.html 200
```

### Splat placeholders

The content matched by a `*` in a rule's `from` path can be injected into the
`to` path using the `:splat` placeholder:

```plaintext
/old/* /new/:splat 200
```

In this example, a request to `/old/file.html` serves the contents of `/new/file.html`
with a `200` status code.

If a rule's `from` path includes multiple splats, the value of the first splat
match replaces any `:splat`s in the `to` path.

### Splat matching behavior

Splats are "greedy" and match as many characters as possible:

```plaintext
/old/*/file /new/:splat/file 301
```

In this example, the rule redirects `/old/a/b/c/file` to `/new/a/b/c/file`.

Splats also match empty strings, so the previous rule redirects
`/old/file` to `/new/file`.

### Rewrite all requests to a root `index.html`

NOTE:
If you are using [GitLab Pages integration with Let's Encrypt](custom_domains_ssl_tls_certification/lets_encrypt_integration.md),
you must enable it before adding this rule. Otherwise, the redirection breaks the Let's Encrypt
integration. For more details, see
[GitLab Pages issue 649](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/649).

Single page applications (SPAs) often perform their own routing using
client-side routes. For these applications, it's important that _all_ requests
are rewritten to the root `index.html` so that the routing logic can be handled
by the JavaScript application. You can do this with a `_redirects`
rule like:

```plaintext
/* /index.html 200
```

## Placeholders

Use placeholders in rules to match portions of the requested URL and use these
matches when rewriting or redirecting to a new URL.

A placeholder is formatted as a `:` character followed by a string of letters
(`[a-zA-Z]+`) in both the `from` and `to` paths:

```plaintext
/news/:year/:month/:date/:slug /blog/:year-:month-:date-:slug 200
```

This rule instructs Pages to respond to a request for `/news/2021/08/12/file.html` by
serving the content of `/blog/2021-08-12-file.html` with a `200`.

### Placeholder matching behavior

Compared to [splats](#splats), placeholders are more limited in how much content
they match. Placeholders match text between forward slashes
(`/`), so use placeholders to match single path segments.

In addition, placeholders do not match empty strings. A rule like the following
would **not** match a request URL like `/old/file`:

```plaintext
/old/:path /new/:path
```

## Debug redirect rules

If a redirect isn't working as expected, or you want to check your redirect syntax, visit
`[your pages url]/_redirects`. The `_redirects` file isn't served directly, but your browser
displays a numbered list of your redirect rules, and whether the rule is valid or invalid:

```plaintext
11 rules
rule 1: valid
rule 2: valid
rule 3: error: splats are not supported
rule 4: valid
rule 5: error: placeholders are not supported
rule 6: valid
rule 7: error: no domain-level redirects to outside sites
rule 8: error: url path must start with forward slash /
rule 9: error: no domain-level redirects to outside sites
rule 10: valid
rule 11: valid
```

## Differences from Netlify implementation

Most supported `_redirects` rules behave the same in both GitLab and Netlify.
However, there are some minor differences:

- **All rule URLs must begin with a slash:**

  Netlify does not require URLs to begin with a forward slash:

  ```plaintext
  # Valid in Netlify, invalid in GitLab
  */path /new/path 200
  ```

  GitLab validates that all URLs begin with a forward slash. A valid
  equivalent of the previous example:

  ```plaintext
  # Valid in both Netlify and GitLab
  /old/path /new/path 200
  ```

- **All placeholder values are populated:**

  Netlify only populates placeholder values that appear in the `to` path:

  ```plaintext
  /old /new/:placeholder
  ```

  Given a request to `/old`:

  - Netlify redirects to `/new/:placeholder` (with a literal `:placeholder`).
  - GitLab redirects to `/new/`.
