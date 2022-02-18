---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# DAST browser-based crawler vulnerability checks **(ULTIMATE)**

The [DAST browser-based crawler](../browser_based.md) provides a number of vulnerability checks that are used to scan for vulnerabilities in the site under test.

| ID | Check | Severity | Type |
|:---|:------|:---------|:-----|
| [1004.1](1004.1.md) | Sensitive cookie without HttpOnly attribute | Low | Passive |
| [16.1](16.1.md) | Missing Content-Type header | Low | Passive |
| [16.2](16.2.md) | Server header exposes version information | Low | Passive |
| [16.3](16.3.md) | X-Powered-By header exposes version information | Low | Passive |
| [16.4](16.4.md) | X-Backend-Server header exposes server information | Info | Passive |
| [16.5](16.5.md) | AspNet header exposes version information | Low | Passive |
| [16.6](16.6.md) | AspNetMvc header exposes version information | Low | Passive |
| [200.1](200.1.md) | Exposure of sensitive information to an unauthorized actor (private IP address) | Low | Passive |
| [548.1](548.1.md) | Exposure of information through directory listing | Low | Passive |
| [614.1](614.1.md) | Sensitive cookie without Secure attribute | Low | Passive |
| [693.1](693.1.md) | Missing X-Content-Type-Options: nosniff | Low | Passive |
