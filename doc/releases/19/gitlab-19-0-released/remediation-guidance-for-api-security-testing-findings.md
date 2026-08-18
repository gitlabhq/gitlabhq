---
title: Remediation guidance for API security testing findings
stage: application_security_testing
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/api_security_testing/checks/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/584601"
categories: [ API Security ]
weight: 40
---

API security vulnerability reports now include remediation guidance for each finding.
Previously, API security testing identified vulnerabilities but provided no
guidance on how to fix them. Developers had to research remediation steps
independently. Now, each finding includes vulnerability-specific remediation steps and
references to relevant OWASP and CWE identifiers directly in the vulnerability report.

Remediation guidance is now included for the following checks:

- [Application information](../../../user/application_security/api_security_testing/checks/application_information_check.md)
- [Cleartext authentication](../../../user/application_security/api_security_testing/checks/cleartext_authentication_check.md)
- [CORS](../../../user/application_security/api_security_testing/checks/cors_check.md)
- [DNS rebinding](../../../user/application_security/api_security_testing/checks/dns_rebinding_check.md)
- [Framework debug mode](../../../user/application_security/api_security_testing/checks/framework_debug_mode_check.md)
- [Heartbleed OpenSSL vulnerability](../../../user/application_security/api_security_testing/checks/heartbleed_open_ssl_check.md)
- [HTML injection](../../../user/application_security/api_security_testing/checks/html_injection_check.md)
- [Insecure HTTP methods](../../../user/application_security/api_security_testing/checks/insecure_http_methods_check.md)
- [JSON hijacking](../../../user/application_security/api_security_testing/checks/json_hijacking_check.md)
- [JSON injection](../../../user/application_security/api_security_testing/checks/json_injection_check.md)
- [Open redirect](../../../user/application_security/api_security_testing/checks/open_redirect_check.md)
- [OS command injection](../../../user/application_security/api_security_testing/checks/os_command_injection_check.md)
- [Path traversal](../../../user/application_security/api_security_testing/checks/path_traversal_check.md)
- [Sensitive file](../../../user/application_security/api_security_testing/checks/sensitive_file_disclosure_check.md)
- [Sensitive information](../../../user/application_security/api_security_testing/checks/sensitive_information_disclosure_check.md)
- [Session cookie](../../../user/application_security/api_security_testing/checks/session_cookie_check.md)
- [Shellshock](../../../user/application_security/api_security_testing/checks/shellshock_check.md)
- [SQL injection](../../../user/application_security/api_security_testing/checks/sql_injection_check.md)
- [TLS configuration](../../../user/application_security/api_security_testing/checks/tls_server_configuration_check.md)
- [Authentication token](../../../user/application_security/api_security_testing/checks/authentication_token_check.md)
- [XML injection](../../../user/application_security/api_security_testing/checks/xml_injection_check.md)
