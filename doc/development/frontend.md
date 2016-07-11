# Frontend Guidelines

This document describes various guidelines to follow to ensure good and
consistent performance of GitLab.

## Performance

### Per-page JavaScript

Per-page JavaScript is JavaScript that is loaded only where necessary.

There are some potential problems to per-page JavaScript as well. For one,

### Minimizing page size

A smaller page size means the page loads faster (especially important on mobile
and poor connections), the page is parsed faster by the browser, and less data is used for
users with capped data plans.

General tips:

- Don't add fonts that are unnecessary.
- Prefer font formats with better compression, e.g. WOFF2 is better than WOFF is better than TFF.
- Compress and minify assets wherever possible (For CSS/JS, Sprockets does this for us).
- If a piece of functionality can be reasonably done without adding extra libraries, prefer not to use extra libraries.
- Use per-page JavaScripts as described above to remove libraries that are only loaded on certain pages.

## Accessibility

The [Chrome Accessibility Developer Tools][chrome-accessibility-developer-tools]
are useful for testing for potential accessibility problems in GitLab.

Accessibility best-practices and more in-depth information is available on
[the Audit Rules page][audit-rules] for the Chrome Accessibility Developer Tools.

## Security

### Content Security Policy



### Subresource Integrity



### Including external resources

External fonts, CSS, JavaScript should never be used with the exception of
Google Analytics - and only when the instance has enabled it. Assets should
always be hosted and served locally from the GitLab instance. Embedded resources
via `iframes` should never be used except in certain circumstances such as with
ReCaptcha, which cannot reasonably be used without an iframe.

### Avoiding inline scripts and styles

While inline scripts can be useful, they're also a security concern. If
user-supplied content is unintentionally left un-sanitized, malicious users can
inject scripts into the site.

[chrome-accessibility-developer-tools]: https://github.com/GoogleChrome/accessibility-developer-tools
[audit-rules]: https://github.com/GoogleChrome/accessibility-developer-tools/wiki/Audit-Rules
