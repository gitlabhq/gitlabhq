---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Security

## Resources

[Mozilla's HTTP Observatory CLI](https://github.com/mozilla/http-observatory-cli) and
[Qualys SSL Labs Server Test](https://www.ssllabs.com/ssltest/analyze.html) are good resources for finding
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

- Scripts from Google Analytics and Matomo if either is enabled.
- Connecting with GitHub, Bitbucket, GitLab.com, etc. to allow project importing.
- Connecting with Google, Twitter, GitHub, etc. to allow OAuth authentication.

We use [the Secure Headers gem](https://github.com/twitter/secureheaders) to enable Content
Security Policy headers in the GitLab Rails app.

Some resources on implementing Content Security Policy:

- [MDN Article on CSP](https://developer.mozilla.org/en-US/docs/Web/Security/CSP)
- [GitHub's CSP Journey on the GitHub Engineering Blog](http://githubengineering.com/githubs-csp-journey/)
- The Dropbox Engineering Blog's series on CSP: [1](https://blogs.dropbox.com/tech/2015/09/on-csp-reporting-and-filtering/), [2](https://blogs.dropbox.com/tech/2015/09/unsafe-inline-and-nonce-deployment/), [3](https://blogs.dropbox.com/tech/2015/09/csp-the-unexpected-eval/), [4](https://blogs.dropbox.com/tech/2015/09/csp-third-party-integrations-and-privilege-separation/)

### Subresource Integrity (SRI)

Subresource Integrity prevents malicious assets from being provided by a CDN by
guaranteeing that the asset downloaded is identical to the asset the server
is expecting.

The Rails app generates a unique hash of the asset, which is used as the
asset's `integrity` attribute. The browser generates the hash of the asset
on-load and will reject the asset if the hashes do not match.

All CSS and JavaScript assets should use Subresource Integrity.

Some resources on implementing Subresource Integrity:

- [MDN Article on SRI](https://developer.mozilla.org/en-us/docs/web/security/subresource_integrity)
- [Subresource Integrity on the GitHub Engineering Blog](http://githubengineering.com/subresource-integrity/)

-->

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

If you are using Vue, you can use the[`v-safe-html` directive](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/directives-safe-html-directive--default) from GitLab UI.

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
