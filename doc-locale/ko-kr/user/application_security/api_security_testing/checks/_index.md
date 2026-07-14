---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API 보안 테스팅 취약성 확인
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [이름이 변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/457449) \- GitLab 17.0에서 **DAST API vulnerability checks**에서 **API security testing vulnerability checks**으로 변경되었습니다.

{{< /history >}}

[API 보안 테스팅](../_index.md)은 테스트 대상 API의 취약성을 검사하는 데 사용되는 취약성 확인을 제공합니다.

## 수동 확인 {#passive-checks}

| 확인                                                                        | 심각도 | 유형    | 프로필 |
|:-----------------------------------------------------------------------------|:---------|:--------|:---------|
| [애플리케이션 정보 확인](application_information_check.md)            | 중간   | 수동 | 수동, 수동-빠른, 활성-빠른, 활성-전체, 빠른, 전체 |
| [평문 인증 확인](cleartext_authentication_check.md)          | 높음     | 수동 | 수동, 수동-빠른, 활성-빠른, 활성-전체, 빠른, 전체 |
| [JSON 하이재킹](json_hijacking_check.md)                                    | 중간   | 수동 | 수동, 수동-빠른, 활성-빠른, 활성-전체, 빠른, 전체 |
| [민감한 정보](sensitive_information_disclosure_check.md)           | 높음     | 수동 | 수동, 수동-빠른, 활성-빠른, 활성-전체, 빠른, 전체 |
| [세션 쿠키](session_cookie_check.md)                                    | 중간   | 수동 | 수동, 수동-빠른, 활성-빠른, 활성-전체, 빠른, 전체 |

## 활성 확인 {#active-checks}

| 확인                                                                        | 심각도 | 유형    | 프로필 |
|:-----------------------------------------------------------------------------|:---------|:--------|:---------|
| [CORS](cors_check.md)                                                        | 중간   | 활성  | 활성-전체, 전체 |
| [DNS 리바인딩](dns_rebinding_check.md)                                      | 중간   | 활성  | 활성-전체, 전체 |
| [프레임워크 디버그 모드](framework_debug_mode_check.md)                        | 높음     | 활성  | 활성-빠른, 활성-전체, 빠른, 전체 |
| [Heartbleed OpenSSL 취약성](heartbleed_open_ssl_check.md)             | 높음     | 활성  | 활성-전체, 전체 |
| [HTML 삽입 확인](html_injection_check.md)                              | 중간   | 활성  | 활성-빠른, 활성-전체, 빠른, 전체 |
| [안전하지 않은 HTTP 메서드](insecure_http_methods_check.md)                      | 중간   | 활성  | 활성-빠른, 활성-전체, 빠른, 전체 |
| [JSON 삽입](json_injection_check.md)                                    | 중간   | 활성  | 활성-빠른, 활성-전체, 빠른, 전체 |
| [오픈 리다이렉트](open_redirect_check.md)                                      | 중간   | 활성  | 활성-전체, 전체 |
| [OS 명령 삽입](os_command_injection_check.md)                        | 높음     | 활성  | 활성-빠른, 활성-전체, 빠른, 전체 |
| [경로 이동](path_traversal_check.md)                                    | 높음     | 활성  | 활성-전체, 전체 |
| [민감한 파일](sensitive_file_disclosure_check.md)                         | 중간   | 활성  | 활성-전체, 전체 |
| [Shellshock](shellshock_check.md)                                            | 높음     | 활성  | 활성-전체, 전체 |
| [SQL 삽입](sql_injection_check.md)                                      | 높음     | 활성  | 활성-빠른, 활성-전체, 빠른, 전체 |
| [TLS 구성](tls_server_configuration_check.md)                       | 높음     | 활성  | 활성-전체, 전체 |
| [인증 토큰](authentication_token_check.md)                        | 높음     | 활성  | 활성-빠른, 활성-전체, 빠른, 전체 |
| [XML 외부 엔티티](xml_external_entity_check.md)                          | 높음     | 활성  | 활성-전체, 전체 |
| [XML 삽입](xml_injection_check.md)                                      | 중간   | 활성  | 활성-빠른, 활성-전체, 빠른, 전체 |

## 프로필별 API 보안 테스팅 확인 {#api-security-testing-checks-by-profile}

### 수동-빠른 {#passive-quick}

- [애플리케이션 정보 확인](application_information_check.md)
- [평문 인증 확인](cleartext_authentication_check.md)
- [JSON 하이재킹](json_hijacking_check.md)
- [민감한 정보](sensitive_information_disclosure_check.md)
- [세션 쿠키](session_cookie_check.md)

### 활성-빠른 {#active-quick}

- [애플리케이션 정보 확인](application_information_check.md)
- [평문 인증 확인](cleartext_authentication_check.md)
- [프레임워크 디버그 모드](framework_debug_mode_check.md)
- [HTML 삽입 확인](html_injection_check.md)
- [안전하지 않은 HTTP 메서드](insecure_http_methods_check.md)
- [JSON 하이재킹](json_hijacking_check.md)
- [JSON 삽입](json_injection_check.md)
- [OS 명령 삽입](os_command_injection_check.md)
- [민감한 정보](sensitive_information_disclosure_check.md)
- [세션 쿠키](session_cookie_check.md)
- [SQL 삽입](sql_injection_check.md)
- [인증 토큰](authentication_token_check.md)
- [XML 삽입](xml_injection_check.md)

### 활성-전체 {#active-full}

- [애플리케이션 정보 확인](application_information_check.md)
- [평문 인증 확인](cleartext_authentication_check.md)
- [CORS](cors_check.md)
- [DNS 리바인딩](dns_rebinding_check.md)
- [프레임워크 디버그 모드](framework_debug_mode_check.md)
- [Heartbleed OpenSSL 취약성](heartbleed_open_ssl_check.md)
- [HTML 삽입 확인](html_injection_check.md)
- [안전하지 않은 HTTP 메서드](insecure_http_methods_check.md)
- [JSON 하이재킹](json_hijacking_check.md)
- [JSON 삽입](json_injection_check.md)
- [오픈 리다이렉트](open_redirect_check.md)
- [OS 명령 삽입](os_command_injection_check.md)
- [경로 이동](path_traversal_check.md)
- [민감한 파일](sensitive_file_disclosure_check.md)
- [민감한 정보](sensitive_information_disclosure_check.md)
- [세션 쿠키](session_cookie_check.md)
- [Shellshock](shellshock_check.md)
- [SQL 삽입](sql_injection_check.md)
- [TLS 구성](tls_server_configuration_check.md)
- [인증 토큰](authentication_token_check.md)
- [XML 삽입](xml_injection_check.md)
- [XML 외부 엔티티](xml_external_entity_check.md)

### 빠른 {#quick}

- [애플리케이션 정보 확인](application_information_check.md)
- [평문 인증 확인](cleartext_authentication_check.md)
- [프레임워크 디버그 모드](framework_debug_mode_check.md)
- [HTML 삽입 확인](html_injection_check.md)
- [안전하지 않은 HTTP 메서드](insecure_http_methods_check.md)
- [JSON 하이재킹](json_hijacking_check.md)
- [JSON 삽입](json_injection_check.md)
- [OS 명령 삽입](os_command_injection_check.md)
- [민감한 정보](sensitive_information_disclosure_check.md)
- [세션 쿠키](session_cookie_check.md)
- [SQL 삽입](sql_injection_check.md)
- [인증 토큰](authentication_token_check.md)
- [XML 삽입](xml_injection_check.md)

### 전체 {#full}

- [애플리케이션 정보 확인](application_information_check.md)
- [평문 인증 확인](cleartext_authentication_check.md)
- [CORS](cors_check.md)
- [DNS 리바인딩](dns_rebinding_check.md)
- [프레임워크 디버그 모드](framework_debug_mode_check.md)
- [Heartbleed OpenSSL 취약성](heartbleed_open_ssl_check.md)
- [HTML 삽입 확인](html_injection_check.md)
- [안전하지 않은 HTTP 메서드](insecure_http_methods_check.md)
- [JSON 하이재킹](json_hijacking_check.md)
- [JSON 삽입](json_injection_check.md)
- [오픈 리다이렉트](open_redirect_check.md)
- [OS 명령 삽입](os_command_injection_check.md)
- [경로 이동](path_traversal_check.md)
- [민감한 파일](sensitive_file_disclosure_check.md)
- [민감한 정보](sensitive_information_disclosure_check.md)
- [세션 쿠키](session_cookie_check.md)
- [Shellshock](shellshock_check.md)
- [SQL 삽입](sql_injection_check.md)
- [TLS 구성](tls_server_configuration_check.md)
- [인증 토큰](authentication_token_check.md)
- [XML 삽입](xml_injection_check.md)
- [XML 외부 엔티티](xml_external_entity_check.md)
