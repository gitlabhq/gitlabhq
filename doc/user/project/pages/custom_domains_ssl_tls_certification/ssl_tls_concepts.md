---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pages SSL/TLS certificates
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

Every GitLab Pages project on GitLab.com is available under
HTTPS for the default Pages domain (`*.gitlab.io`). Once you set
up your Pages project with your custom (sub)domain, if you want
it secured by HTTPS, you must issue a certificate for that
(sub)domain and install it on your project.

NOTE:
Certificates are **not** required to add to your custom
(sub)domain on your GitLab Pages project, though they are
highly recommendable.

Let's start with an introduction to the importance of HTTPS.

## Why should you care about HTTPS?

This might be your first question. If our sites are hosted by GitLab Pages,
they are static, hence we are not dealing with server-side scripts
nor credit card transactions, then why do we need secure connections?

When HTTPS came out in 1990, [SSL](https://en.wikipedia.org/wiki/Transport_Layer_Security#SSL_1.0.2C_2.0_and_3.0) was considered a "special"
security measure, necessary just for big companies like banks and shopping sites
with financial transactions.

<!-- vale gitlab_base.Spelling = NO -->

Now we have a different picture. [According to Josh Aas](https://letsencrypt.org/2015/10/29/phishing-and-malware.html), Executive Director at [Internet Security Research Group (ISRG)](https://en.wikipedia.org/wiki/Internet_Security_Research_Group):

<!-- vale gitlab_base.rulename = YES -->

> _We've since come to realize that HTTPS is important for almost all websites. It's important for any website that allows people to sign in with a password, any website that [tracks its users](https://www.washingtonpost.com/news/the-switch/wp/2013/12/10/nsa-uses-google-cookies-to-pinpoint-targets-for-hacking/) in any way, any website that [doesn't want its content altered](https://arstechnica.com/tech-policy/2014/09/why-comcasts-javascript-ad-injections-threaten-security-net-neutrality/), and for any site that offers content people might not want others to know they are consuming. We've also learned that any site not secured by HTTPS [can be used to attack other sites](https://krebsonsecurity.com/2015/04/dont-be-fodder-for-chinas-great-cannon/)._

Therefore, the reason why certificates are so important is that they encrypt
the connection between the **client** (you, your visitors)
and the **server** (where you site lives), through a keychain of
authentications and validations.

## Organizations supporting HTTPS

There is a huge movement in favor of securing all the web. W3C fully
[supports the cause](https://w3ctag.github.io/web-https/) and explains very well
the reasons for that. Richard Barnes, a writer for Mozilla Security Blog,
suggested that [Firefox would deprecate HTTP](https://blog.mozilla.org/security/2015/04/30/deprecating-non-secure-http/),
and would no longer accept unsecured connections. Recently, Mozilla published a
[communication](https://blog.mozilla.org/security/2016/03/29/march-2016-ca-communication/)
reiterating the importance of HTTPS.

## Issuing Certificates

GitLab Pages accepts certificates provided in the [PEM](https://knowledge.digicert.com/quovadis) format, issued by
[Certificate Authorities](https://en.wikipedia.org/wiki/Certificate_authority) or as
[self-signed certificates](https://en.wikipedia.org/wiki/Self-signed_certificate). [Self-signed certificates are typically not used](https://www.mcafee.com/blogs/other-blogs/mcafee-labs/self-signed-certificates-secure-so-why-ban/)
for public websites for security reasons and to ensure that browsers trust your site's certificate.

There are various kinds of certificates, each one
with a certain security level. A static personal website doesn't
require the same security level as an online banking web app,
for instance.

There are some certificate authorities that
offer free certificates, aiming to make the internet more secure
to everyone. The most popular is [Let's Encrypt](https://letsencrypt.org/),
which issues certificates trusted by most of browsers, it's open
source, and free to use. See [GitLab Pages integration with Let's Encrypt](../custom_domains_ssl_tls_certification/lets_encrypt_integration.md) to enable HTTPS on your custom domain.

Similarly popular are [certificates issued by Cloudflare](https://www.cloudflare.com/application-services/products/ssl/),
which also offers a [free CDN service](https://blog.cloudflare.com/cloudflares-free-cdn-and-you/).
Their certs are valid up to 15 years. See the tutorial on
[how to add a Cloudflare Certificate to your GitLab Pages website](https://about.gitlab.com/blog/2017/02/07/setting-up-gitlab-pages-with-cloudflare-certificates/).
