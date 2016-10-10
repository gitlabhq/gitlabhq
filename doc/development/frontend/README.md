# Frontend Development Guidelines

This document describes various guidelines to ensure consistency and quality
across GitLab's frontend team.

## Overview

GitLab is built on top of [Ruby on Rails][rails] using [Haml][haml] with
[Hamlit][hamlit]. Be wary of [the limitations that come with using
Hamlit][hamlit-limits]. We also use [SCSS][scss] and plain JavaScript with
[ES6 by way of Babel][es6].

The asset pipeline is [Sprockets][sprockets], which handles the concatenation,
minification, and compression of our assets.

[jQuery][jquery] is used throughout the application's JavaScript, with
[Vue.js][vue] for particularly advanced, dynamic elements.

### Vue

For more complex frontend features, we recommend using Vue.js. It shares
some ideas with React.js as well as Angular.

To get started with Vue, read through [their documentation][vue-docs].

## Performance

### Resources

- [WebPage Test][web-page-test] for testing site loading time and size.
- [Google PageSpeed Insights][pagespeed-insights] grades web pages and provides feedback to improve the page.
- [Profiling with Chrome DevTools][google-devtools-profiling]
- [Browser Diet][browser-diet] is a community-built guide that catalogues practical tips for improving web page performance.

### Page-specific JavaScript

Certain pages may require the use of a third party library, such as [d3][d3] for
the User Activity Calendar and [Chart.js][chartjs] for the Graphs pages. These
libraries increase the page size significantly, and impact load times due to
bandwidth bottlenecks and the browser needing to parse more JavaScript.

In cases where libraries are only used on a few specific pages, we use
"page-specific JavaScript" to prevent the main `application.js` file from
becoming unnecessarily large.

Steps to split page-specific JavaScript from the main `application.js`:

1. Create a directory for the specific page(s), e.g. `graphs/`.
1. In that directory, create a `namespace_bundle.js` file, e.g. `graphs_bundle.js`.
1. In `graphs_bundle.js` add the line `//= require_tree .`, this adds all other files in the directory to the bundle.
1. Add any necessary libraries to `app/assets/javascripts/lib/`, all files directly descendant from this directory will be precompiled as separate assets, in this case `chart.js` would be added.
1. Add the new "bundle" file to the list of precompiled assets in
`config/application.rb`.
  - For example: `config.assets.precompile << "graphs/graphs_bundle.js"`.
1. Move code reliant on these libraries into the `graphs` directory.
1. In the relevant views, add the scripts to the page with the following:

```haml
- content_for :page_specific_javascripts do
  = page_specific_javascript_tag('lib/chart.js')
  = page_specific_javascript_tag('graphs/graphs_bundle.js')
```

The above loads `chart.js` and `graphs_bundle.js` for this page only. `chart.js`
is separated from the bundle file so it can be cached separately from the bundle
and reused for other pages that also rely on the library. For an example, see
[this Haml file][page-specific-js-example].

### Minimizing page size

A smaller page size means the page loads faster (especially important on mobile
and poor connections), the page is parsed more quickly by the browser, and less
data is used for users with capped data plans.

General tips:

- Don't add new fonts.
- Prefer font formats with better compression, e.g. WOFF2 is better than WOFF, which is better than TTF.
- Compress and minify assets wherever possible (For CSS/JS, Sprockets does this for us).
- If some functionality can reasonably be achieved without adding extra libraries, avoid them.
- Use page-specific JavaScript as described above to dynamically load libraries that are only needed on certain pages.

## Accessibility

### Resources

[Chrome Accessibility Developer Tools][chrome-accessibility-developer-tools]
are useful for testing for potential accessibility problems in GitLab.

Accessibility best-practices and more in-depth information is available on
[the Audit Rules page][audit-rules] for the Chrome Accessibility Developer Tools.

## Security

### Resources

[Mozilla’s HTTP Observatory CLI][observatory-cli] and the
[Qualys SSL Labs Server Test][qualys-ssl] are good resources for finding
potential problems and ensuring compliance with security best practices.

<!-- Uncomment these sections when CSP/SRI are implemented.
### Content Security Policy (CSP)

Content Security Policy is a web standard that intends to mitigate certain
forms of Cross-Site Scripting (XSS) as well as data injection.

Content Security Policy rules should be taken into consideration when
implementing new features, especially those that may rely on connection with
external services.

GitLab's CSP is used for the following:

- Blocking plugins like Flash and Silverlight from running at all on our pages.
- Blocking the use of scripts and stylesheets downloaded from external sources.
- Upgrading `http` requests to `https` when possible.
- Preventing `iframe` elements from loading in most contexts.

Some exceptions include:

- Scripts from Google Analytics and Piwik if either is enabled.
- Connecting with GitHub, Bitbucket, GitLab.com, etc. to allow project importing.
- Connecting with Google, Twitter, GitHub, etc. to allow OAuth authentication.

We use [the Secure Headers gem][secure_headers] to enable Content
Security Policy headers in the GitLab Rails app.

Some resources on implementing Content Security Policy:

- [MDN Article on CSP][mdn-csp]
- [GitHub’s CSP Journey on the GitHub Engineering Blog][github-eng-csp]
- The Dropbox Engineering Blog's series on CSP: [1][dropbox-csp-1], [2][dropbox-csp-2], [3][dropbox-csp-3], [4][dropbox-csp-4]

### Subresource Integrity (SRI)

Subresource Integrity prevents malicious assets from being provided by a CDN by
guaranteeing that the asset downloaded is identical to the asset the server
is expecting.

The Rails app generates a unique hash of the asset, which is used as the
asset's `integrity` attribute. The browser generates the hash of the asset
on-load and will reject the asset if the hashes do not match.

All CSS and JavaScript assets should use Subresource Integrity. For implementation details,
see the documentation for [the Sprockets implementation of SRI][sprockets-sri].

Some resources on implementing Subresource Integrity:

- [MDN Article on SRI][mdn-sri]
- [Subresource Integrity on the GitHub Engineering Blog][github-eng-sri]

-->

### Including external resources

External fonts, CSS, and JavaScript should never be used with the exception of
Google Analytics and Piwik - and only when the instance has enabled it. Assets
should always be hosted and served locally from the GitLab instance. Embedded
resources via `iframes` should never be used except in certain circumstances
such as with ReCaptcha, which cannot be used without an `iframe`.

### Avoiding inline scripts and styles

In order to protect users from [XSS vulnerabilities][xss], we will disable inline scripts in the future using Content Security Policy.

While inline scripts can be useful, they're also a security concern. If
user-supplied content is unintentionally left un-sanitized, malicious users can
inject scripts into the web app.

Inline styles should be avoided in almost all cases, they should only be used
when no alternatives can be found. This allows reusability of styles as well as
readability.

## Style guides and linting

See the relevant style guides for our guidelines and for information on linting:

- [SCSS][scss-style-guide]

## Testing

Feature tests need to be written for all new features. Regression tests
also need to be written for all bug fixes to prevent them from occurring
again in the future.

See [the Testing Standards and Style Guidelines](testing.md) for more
information.

## Supported browsers

For our currently-supported browsers, see our [requirements][requirements].

[rails]: http://rubyonrails.org/
[haml]: http://haml.info/
[hamlit]: https://github.com/k0kubun/hamlit
[hamlit-limits]: https://github.com/k0kubun/hamlit/blob/master/REFERENCE.md#limitations
[scss]: http://sass-lang.com/
[es6]: https://babeljs.io/
[sprockets]: https://github.com/rails/sprockets
[jquery]: https://jquery.com/
[vue]: http://vuejs.org/
[vue-docs]: http://vuejs.org/guide/index.html
[web-page-test]: http://www.webpagetest.org/
[pagespeed-insights]: https://developers.google.com/speed/pagespeed/insights/
[google-devtools-profiling]: https://developers.google.com/web/tools/chrome-devtools/profile/?hl=en
[browser-diet]: https://browserdiet.com/
[d3]: https://d3js.org/
[chartjs]: http://www.chartjs.org/
[page-specific-js-example]: https://gitlab.com/gitlab-org/gitlab-ce/blob/13bb9ed77f405c5f6ee4fdbc964ecf635c9a223f/app/views/projects/graphs/_head.html.haml#L6-8
[chrome-accessibility-developer-tools]: https://github.com/GoogleChrome/accessibility-developer-tools
[audit-rules]: https://github.com/GoogleChrome/accessibility-developer-tools/wiki/Audit-Rules
[observatory-cli]: https://github.com/mozilla/http-observatory-cli)
[qualys-ssl]: https://www.ssllabs.com/ssltest/analyze.html
[secure_headers]: https://github.com/twitter/secureheaders
[mdn-csp]: https://developer.mozilla.org/en-US/docs/Web/Security/CSP
[github-eng-csp]: http://githubengineering.com/githubs-csp-journey/
[dropbox-csp-1]: https://blogs.dropbox.com/tech/2015/09/on-csp-reporting-and-filtering/
[dropbox-csp-2]: https://blogs.dropbox.com/tech/2015/09/unsafe-inline-and-nonce-deployment/
[dropbox-csp-3]: https://blogs.dropbox.com/tech/2015/09/csp-the-unexpected-eval/
[dropbox-csp-4]: https://blogs.dropbox.com/tech/2015/09/csp-third-party-integrations-and-privilege-separation/
[mdn-sri]: https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity
[github-eng-sri]: http://githubengineering.com/subresource-integrity/
[sprockets-sri]: https://github.com/rails/sprockets-rails#sri-support
[xss]: https://en.wikipedia.org/wiki/Cross-site_scripting
[scss-style-guide]: scss_styleguide.md
[requirements]: ../install/requirements.md#supported-web-browsers
