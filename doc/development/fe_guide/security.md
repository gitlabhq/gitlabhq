---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Security
---

## Resources

[Mozilla's HTTP Observatory CLI](https://github.com/mozilla/http-observatory-cli) and
[Qualys SSL Labs Server Test](https://www.ssllabs.com/ssltest/analyze.html) are good resources for finding
potential problems and ensuring compliance with security best practices.

## Including external resources

External fonts, CSS, and JavaScript should never be used with the exception of
Google Analytics and Matomo - and only when the instance has enabled it. Assets
should always be hosted and served locally from the GitLab instance. Embedded
resources via `iframes` should never be used except in certain circumstances
such as with reCAPTCHA, which cannot be used without an `iframe`.

## Avoiding inline scripts and styles

In order to protect users from [XSS vulnerabilities](https://en.wikipedia.org/wiki/Cross-site_scripting), we intend to disable
inline scripts in the future using Content Security Policy.

While inline scripts can make something easier, they're also a security concern. If
user-supplied content is unintentionally left un-sanitized, malicious users can
inject scripts into the web app.

Inline styles should be avoided in almost all cases, they should only be used
when no alternatives can be found. This allows reusability of styles as well as
readability.

### Sanitize HTML output

If you need to output raw HTML, you should sanitize it.

If you are using Vue, you can use the[`v-safe-html` directive](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/vue_shared/directives/safe_html.js).

For other use cases, wrap a preconfigured version of [`dompurify`](https://www.npmjs.com/package/dompurify)
that also allows the icons to be rendered:

```javascript
import { sanitize } from '~/lib/dompurify';

const unsafeHtml = '<some unsafe content ... >';

// ...

element.appendChild(sanitize(unsafeHtml));
```

This `sanitize` function takes the same configuration as the
original.

### Fixing Security Issues

When refactoring old code, it's important that we don't accidentally remove specs written to catch security issues which might still be relevant.

We should mark specs with `#security` in either the `describe` or `it` blocks to communicate to the engineer reading the code that by removing these specs could have severe consequences down the road, and you are removing code that could catch a reintroduction of a security issue.
