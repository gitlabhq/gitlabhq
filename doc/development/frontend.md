# Frontend Guidelines

This document describes various guidelines to follow to ensure good and
consistent performance of GitLab.

## Performance

### Page-specific JavaScript

Certain pages may require the use of a third party library, such as [d3][d3] for
the User Activity Calendar and [Chart.js][chartjs] for the Graphs pages. These
libraries increase the page size significantly, and impact load times due to
bandwidth bottlenecks and the browser needing to parse more JavaScript.

In cases where libraries are only used on a few specific pages, we use
"Page-specific JavaScript" to prevent the main `application.js` file from
becoming unnecessarily large.

Steps to split page-specific JavaScript from the main `application.js`:

1. Create a directory for the specific page(s), e.g. `graphs/`.
1. In that directory, create a `namespace_bundle.js` file, e.g. `graphs_bundle.js`.
1. Add the new "bundle" file to the list of precompiled assets in
`config/application.rb`.
  - For example: `config.assets.precompile << "graphs/graphs_bundle.js"`.
1. Add any necessary libraries to `app/assets/javascripts/lib/`, all files directly descendant from this directory will be precompiled as separate assets. In this case, `chart.js` would be added.
1. In the relevant views, add the scripts to the page with the following:

```haml
- content_for :page_specific_javascripts do
  = page_specific_javascript_tag('lib/chart.js')
  = page_specific_javascript_tag('graphs/graphs_bundle.js')
```

The above loads `chart.js` and `graphs_bundle.js` for only this page. `chart.js` is separated from the bundle file so it can be cached separately from the bundle and reused for other pages that also rely on the library.

### Minimizing page size

A smaller page size means the page loads faster (especially important on mobile
and poor connections), the page is parsed more quickly by the browser, and less
data is used for users with capped data plans.

General tips:

- Don't add fonts that are unnecessary.
- Prefer font formats with better compression, e.g. WOFF2 is better than WOFF is better than TFF.
- Compress and minify assets wherever possible (For CSS/JS, Sprockets does this for us).
- If a piece of functionality can be reasonably done without adding extra libraries, prefer not to use extra libraries.
- Use page-specific JavaScripts as described above to dynamically load libraries that are only needed on certain pages.

## Accessibility

The [Chrome Accessibility Developer Tools][chrome-accessibility-developer-tools]
are useful for testing for potential accessibility problems in GitLab.

Accessibility best-practices and more in-depth information is available on
[the Audit Rules page][audit-rules] for the Chrome Accessibility Developer Tools.

## Security

### Including external resources

External fonts, CSS, and JavaScript should never be used with the exception of
Google Analytics and Piwik - and only when the instance has enabled it. Assets
should always be hosted and served locally from the GitLab instance. Embedded
resources via `iframes` should never be used except in certain circumstances
such as with ReCaptcha, which cannot be used without an `iframe`.

### Avoiding inline scripts and styles

In order to protect users from [XSS vulnerabilities][xss], our intention is to
disable inline scripts entirely using Content Security Policy at some point in
the future.

While inline scripts can be useful, they're also a security concern. If
user-supplied content is unintentionally left un-sanitized, malicious users can
inject scripts into the site.

Inline styles should be avoided in almost all cases, they should only be used
when no alternatives can be found. This allows reusability of styles as well as
readability.

[d3]: https://d3js.org/
[chartjs]: http://www.chartjs.org/
[chrome-accessibility-developer-tools]: https://github.com/GoogleChrome/accessibility-developer-tools
[audit-rules]: https://github.com/GoogleChrome/accessibility-developer-tools/wiki/Audit-Rules
[xss]: https://en.wikipedia.org/wiki/Cross-site_scripting
