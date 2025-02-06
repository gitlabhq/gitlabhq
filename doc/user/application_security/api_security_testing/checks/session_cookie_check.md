---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Session cookie
---

## Description

Verify session cookie has correct flags and expiration.

## Remediation

Since HTTP is a stateless protocol, web sites commonly use cookies to store
session IDs that uniquely identify a user from request to request. Consequently,
each session ID's confidentiality must be maintained in order to prevent
multiple users from accessing the same account. A stolen session ID can be used
to view another user's account or perform a fraudulent transaction.

- One part of securing session ID's is to property mark them to expire and also
  require the correct set of flags to ensure they are not transmitted in the
  clear or accessible from scripting.
- HttpOnly is an additional flag included in a Set-Cookie HTTP response header.
  Using the HttpOnly flag when generating a cookie helps mitigate the risk of
  client side script accessing the protected cookie (if the browser supports it).
  If the HttpOnly flag (optional) is included in the HTTP response header,
  the cookie cannot be accessed through client side script (again if the browser
  supports this flag). As a result, even if a cross-site scripting (XSS) flaw
  exists, and a user accidentally accesses a link that exploits this flaw, the
  browser will not reveal the cookie to a third party.
- The Secure attribute for sensitive cookies in HTTPS sessions is not set, which
  could cause the user agent to send those cookies in plaintext over an HTTP
  session.
- A session related cookie was identified being used on an insecure transport
  protocol. Insecure transport protocols are those that do not make use of
  SSL/TLS to secure the connection. Examples of such protocols are 'http'.
- Insufficient Session Expiration occurs when a Web application permits an
  attacker to reuse old session credentials or session IDs for authorization.
  Insufficient Session Expiration increases a website's exposure to attacks that
  steal or reuse user's session identifiers. Since HTTP is a stateless protocol,
  websites commonly use cookies to store session IDs that uniquely identify a
  user from request to request. Consequently, each session ID's confidentiality
  must be maintained in order to prevent multiple users from accessing the same
  account. A stolen session ID can be used to view another user's account or
  perform a fraudulent transaction. One part of securing session ID's is to
  property mark them to expire and also require the correct set of flags to
  ensure they are not transmitted in the clear or accessible from scripting.

## Links

- [OWASP](https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/930.html)
