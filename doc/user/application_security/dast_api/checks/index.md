---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# DAST API vulnerability checks

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

[DAST API](../index.md) provides vulnerability checks that are used to
scan for vulnerabilities in the API under test.

## Passive checks

| Check                                                                        | Severity | Type    |  Profiles |
|:-----------------------------------------------------------------------------|:---------|:--------|:---------|
| [Application information check](application_information_check.md)               | Medium   | Passive | Passive, Passive-Quick, Active-Quick, Active Full, Quick, Full |
| [Cleartext authentication check](cleartext_authentication_check.md)          | High     | Passive | Passive, Passive-Quick, Active-Quick, Active Full, Quick, Full |
| [JSON hijacking](json_hijacking_check.md)                                    | Medium   | Passive | Passive, Passive-Quick, Active-Quick, Active Full, Quick, Full |
| [Sensitive information](sensitive_information_disclosure_check.md)           | High     | Passive | Passive, Passive-Quick, Active-Quick, Active Full, Quick, Full |
| [Session cookie](session_cookie_check.md)                                    | Medium   | Passive | Passive, Passive-Quick, Active-Quick, Active Full, Quick, Full |

## Active checks

| Check                                                                        | Severity | Type    | Profiles  |
|:-----------------------------------------------------------------------------|:---------|:--------|:---------|
| [CORS](cors_check.md)                                                        | Medium   | Active  | Active Full, Full |
| [DNS rebinding](dns_rebinding_check.md)                                      | Medium   | Active  | Active Full, Full |
| [Framework debug mode](framework_debug_mode_check.md)                        | High     | Active  | Active-Quick, Active Full, Quick, Full |
| [Heartbleed OpenSSL vulnerability](heartbleed_open_ssl_check.md)             | High     | Active  | Active Full, Full |
| [HTML injection check](html_injection_check.md)                              | Medium   | Active  | Active-Quick, Active Full, Quick, Full |
| [Insecure HTTP methods](insecure_http_methods_check.md)                      | Medium   | Active  | Active-Quick, Active Full, Quick, Full |
| [JSON injection](json_injection_check.md)                                    | Medium   | Active  | Active-Quick, Active Full, Quick, Full |
| [Open redirect](open_redirect_check.md)                                      | Medium   | Active  | Active Full, Full |
| [OS command injection](os_command_injection_check.md)                        | High     | Active  | Active-Quick, Active Full, Quick, Full |
| [Path traversal](path_traversal_check.md)                                    | High     | Active  | Active Full, Full |
| [Sensitive file](sensitive_file_disclosure_check.md)                         | Medium   | Active  | Active Full, Full |
| [Shellshock](shellshock_check.md)                                            | High     | Active  | Active Full, Full |
| [SQL injection](sql_injection_check.md)                                      | High     | Active  | Active-Quick, Active Full, Quick, Full |
| [TLS configuration](tls_server_configuration_check.md)                       | High     | Active  | Active Full, Full |
| [Authentication token](authentication_token_check.md)                        | High     | Active  | Active-Quick, Active Full, Quick, Full |
| [XML external entity](xml_external_entity.md)                                | High     | Active  | Active Full, Full |
| [XML injection](xml_injection_check.md)                                      | Medium   | Active  | Active-Quick, Active Full, Quick, Full |

## DAST API checks by profile

### Passive-Quick

- [Application information check](application_information_check.md)
- [Cleartext authentication check](cleartext_authentication_check.md)
- [JSON hijacking](json_hijacking_check.md)
- [Sensitive information](sensitive_information_disclosure_check.md)
- [Session cookie](session_cookie_check.md)

### Active-Quick

- [Application information check](application_information_check.md)
- [Cleartext authentication check](cleartext_authentication_check.md)
- [Framework debug mode](framework_debug_mode_check.md)
- [HTML injection check](html_injection_check.md)
- [Insecure HTTP methods](insecure_http_methods_check.md)
- [JSON hijacking](json_hijacking_check.md)
- [JSON injection](json_injection_check.md)
- [OS command injection](os_command_injection_check.md)
- [Sensitive information](sensitive_information_disclosure_check.md)
- [Session cookie](session_cookie_check.md)
- [SQL injection](sql_injection_check.md)
- [Authentication token](authentication_token_check.md)
- [XML injection](xml_injection_check.md)

### Active-Full

- [Application information check](application_information_check.md)
- [Cleartext authentication check](cleartext_authentication_check.md)
- [CORS](cors_check.md)
- [DNS rebinding](dns_rebinding_check.md)
- [Framework debug mode](framework_debug_mode_check.md)
- [Heartbleed OpenSSL vulnerability](heartbleed_open_ssl_check.md)
- [HTML injection check](html_injection_check.md)
- [Insecure HTTP methods](insecure_http_methods_check.md)
- [JSON hijacking](json_hijacking_check.md)
- [JSON injection](json_injection_check.md)
- [Open redirect](open_redirect_check.md)
- [OS command injection](os_command_injection_check.md)
- [Path traversal](path_traversal_check.md)
- [Sensitive file](sensitive_file_disclosure_check.md)
- [Sensitive information](sensitive_information_disclosure_check.md)
- [Session cookie](session_cookie_check.md)
- [Shellshock](shellshock_check.md)
- [SQL injection](sql_injection_check.md)
- [TLS configuration](tls_server_configuration_check.md)
- [Authentication token](authentication_token_check.md)
- [XML injection](xml_injection_check.md)
- [XML external entity](xml_external_entity.md)

### Quick

- [Application information check](application_information_check.md)
- [Cleartext authentication check](cleartext_authentication_check.md)
- [Framework debug mode](framework_debug_mode_check.md)
- [HTML injection check](html_injection_check.md)
- [Insecure HTTP methods](insecure_http_methods_check.md)
- [JSON hijacking](json_hijacking_check.md)
- [JSON injection](json_injection_check.md)
- [OS command injection](os_command_injection_check.md)
- [Sensitive information](sensitive_information_disclosure_check.md)
- [Session cookie](session_cookie_check.md)
- [SQL injection](sql_injection_check.md)
- [Authentication token](authentication_token_check.md)
- [XML injection](xml_injection_check.md)

### Full

- [Application information check](application_information_check.md)
- [Cleartext authentication check](cleartext_authentication_check.md)
- [CORS](cors_check.md)
- [DNS rebinding](dns_rebinding_check.md)
- [Framework debug mode](framework_debug_mode_check.md)
- [Heartbleed OpenSSL vulnerability](heartbleed_open_ssl_check.md)
- [HTML injection check](html_injection_check.md)
- [Insecure HTTP methods](insecure_http_methods_check.md)
- [JSON hijacking](json_hijacking_check.md)
- [JSON injection](json_injection_check.md)
- [Open redirect](open_redirect_check.md)
- [OS command injection](os_command_injection_check.md)
- [Path traversal](path_traversal_check.md)
- [Sensitive file](sensitive_file_disclosure_check.md)
- [Sensitive information](sensitive_information_disclosure_check.md)
- [Session cookie](session_cookie_check.md)
- [Shellshock](shellshock_check.md)
- [SQL injection](sql_injection_check.md)
- [TLS configuration](tls_server_configuration_check.md)
- [Authentication token](authentication_token_check.md)
- [XML injection](xml_injection_check.md)
- [XML external entity](xml_external_entity.md)
