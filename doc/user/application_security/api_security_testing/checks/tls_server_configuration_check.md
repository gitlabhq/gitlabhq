---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: TLS server configuration
---

## Description

Check for various TLS Server configuration issues. Checks TLS versions, hmacs, ciphers and compression algs supported by server.

## Remediation

Insufficient transport layer protection allows communication to be exposed to untrusted third-parties, providing an attack vector to compromise a web application and/or steal sensitive information. Websites typically use Secure Sockets Layer/Transport Layer Security (SSL/TLS) to provide encryption at the transport layer. However, unless the website is configured to use SSL/TLS and configured to use SSL/TLS properly, the website may be vulnerable to traffic interception and modification.

SSL/TLS as a protocol have gone through several revisions over the years. Each new version adds features and fixes weaknesses in the protocol. Over time some versions of the protocol are broken so badly as to become vulnerabilities if supported. It's recommended to support only the most recent TLS versions such as TLS 1.3 (2018), and TLS 1.2 (2008).

Compression has been linked to side-channel attacks on TLS connections. Disabling compression can prevent these attacks. One attack in particular, CRIME ("Compression Ratio Info-leak Made Easy") can be prevented. CRIME is an attack that targets clients, but if the server does not support compression the attack is mitigated.

Historically, high grade cryptography was restricted from export to outside the United States. Because of this, websites were configured to support weak cryptographic options for those clients that were restricted to only using weak ciphers. Weak ciphers are vulnerable to attack because of the relative ease of breaking them; less than two weeks on a typical home computer
and a few seconds using dedicated hardware.

Today, all modern browsers and websites use much stronger encryption, but some websites are still configured to support outdated weak ciphers. Because of this, an attacker may be able to force the client to downgrade to a weaker cipher when connecting to the website, allowing the attacker to break the weak encryption. For this reason, the server should be configured to only accept strong ciphers and not provide service to any client that requests using a weaker cipher. In addition, some websites are misconfigured to choose a weaker cipher even when the client will support a much stronger one. OWASP offers a guide to testing for SSL/TLS issues, including weak cipher support and misconfiguration, and there are other resources and tools as well.

## Links

- [OWASP](https://owasp.org/Top10/A02_2021-Cryptographic_Failures/)
- [CWE](https://cwe.mitre.org/data/definitions/934.html)
