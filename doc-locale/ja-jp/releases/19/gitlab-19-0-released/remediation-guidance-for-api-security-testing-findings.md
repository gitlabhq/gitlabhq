---
title: APIセキュリティテストの検出結果に対する修正ガイダンス
stage: application_security_testing
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/application_security/api_security_testing/checks/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/584601"
categories: [ API Security ]
weight: 40
---

APIセキュリティの脆弱性レポートに、各検出結果に対する修正ガイダンスが含まれるようになりました。
これまで、APIセキュリティテストは脆弱性を特定するものの、修正方法に関するガイダンスは提供されていませんでした。そのため、デベロッパーは修正手順を独自に調査する必要がありました。今回のリリースで、各検出結果に脆弱性固有の修正手順が含まれるようになり、関連するOWASPおよびCWE識別子が脆弱性レポートに直接表示されます。

以下のチェックに対して修正ガイダンスが追加されました。

- [アプリケーション情報](../../../user/application_security/api_security_testing/checks/application_information_check.md)
- [平文認証](../../../user/application_security/api_security_testing/checks/cleartext_authentication_check.md)
- [CORS](../../../user/application_security/api_security_testing/checks/cors_check.md)
- [DNSリバインディング](../../../user/application_security/api_security_testing/checks/dns_rebinding_check.md)
- [フレームワークデバッグモード](../../../user/application_security/api_security_testing/checks/framework_debug_mode_check.md)
- [Heartbleed OpenSSL脆弱性](../../../user/application_security/api_security_testing/checks/heartbleed_open_ssl_check.md)
- [HTMLインジェクション](../../../user/application_security/api_security_testing/checks/html_injection_check.md)
- [脆弱なHTTPメソッド](../../../user/application_security/api_security_testing/checks/insecure_http_methods_check.md)
- [JSONハイジャッキング](../../../user/application_security/api_security_testing/checks/json_hijacking_check.md)
- [JSONインジェクション](../../../user/application_security/api_security_testing/checks/json_injection_check.md)
- [オープンリダイレクト](../../../user/application_security/api_security_testing/checks/open_redirect_check.md)
- [OSコマンドインジェクション](../../../user/application_security/api_security_testing/checks/os_command_injection_check.md)
- [パストラバーサル](../../../user/application_security/api_security_testing/checks/path_traversal_check.md)
- [機密ファイル](../../../user/application_security/api_security_testing/checks/sensitive_file_disclosure_check.md)
- [機密情報](../../../user/application_security/api_security_testing/checks/sensitive_information_disclosure_check.md)
- [セッションCookie](../../../user/application_security/api_security_testing/checks/session_cookie_check.md)
- [Shellshock](../../../user/application_security/api_security_testing/checks/shellshock_check.md)
- [SQLインジェクション](../../../user/application_security/api_security_testing/checks/sql_injection_check.md)
- [TLS設定](../../../user/application_security/api_security_testing/checks/tls_server_configuration_check.md)
- [認証トークン](../../../user/application_security/api_security_testing/checks/authentication_token_check.md)
- [XMLインジェクション](../../../user/application_security/api_security_testing/checks/xml_injection_check.md)
