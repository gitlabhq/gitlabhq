# Security

## Avoid inline scripts and styles

Inline scripts and styles should be avoided in almost all cases. In an effort to protect users from [XSS vulnerabilities](https://en.wikipedia.org/wiki/Cross-site_scripting), we will be disabling inline scripts using Content Security Policy.

## Including external resources

External fonts, CSS, and JavaScript should never be used with the exception of Google Analytics and Piwik - and only when the instance has enabled it. Assets should always be hosted and served locally from the GitLab instance. Embedded resources via `iframes` should never be used except in certain circumstances such as with ReCaptcha, which cannot be used without an `iframe`.

## Resources for security testing

- [Mozilla's HTTP Observatory CLI](https://github.com/mozilla/http-observatory-cli)
- [Qualys SSL Labs Server Test](https://www.ssllabs.com/ssltest/analyze.html)
