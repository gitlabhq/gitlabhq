---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: TLSのサポート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでは、トランスポートレイヤーセキュリティ（TLS）を採用して、インターネットを介したデータのキーとなる情報の安全性を保護することにより、ユーザーとプラットフォーム間のデータ伝送のセキュリティを優先しています。

サイバーセキュリティの脅威が進化し続ける中、GitLabは、最高水準のセキュリティを維持することに引き続き取り組んでいます。GitLabは、GitLabサービスとのすべての通信で、利用可能な最新かつ最も安全な暗号化方式を使用するように、TLSサポートを定期的に更新しています。

このドキュメントでは、データの安全性を維持するために使用されるバージョンや暗号スイートなど、GitLabの現在のTLSサポートの概要を説明します。

## サポートされているプロトコル {#supported-protocols}

GitLabは、安全な通信のためにTLS 1.2バージョン以降をサポートしています。つまり、TLS 1.2とTLS 1.3は完全にサポートされており、GitLabでの使用が推奨されます。

TLS 1.1、TLS 1.0、およびSSLのすべてのバージョンなどの古いプロトコルは、既知のセキュリティ脆弱性のためサポートされていません。TLS 1.2以降の使用を強制することで、GitLabはすべてのデータ伝送とプラットフォームとのインタラクションに対して高レイヤーのセキュリティを確保します。

## サポートされている暗号スイート {#supported-cipher-suites}

GitLabは、複数の暗号スイートをサポートしています。次の各暗号スイートは安全であるとみなされ、`A`の[SSLサーバー評価](https://github.com/ssllabs/research/wiki/SSL-Server-Rating-Guide)があります。

| プロトコルバージョン | 暗号スイート |
|------------------|--------------|
| TLSv1.3 | TLS_AKE_WITH_AES_128_GCM_SHA256 |
| TLSv1.3 | TLS_AKE_WITH_AES_256_GCM_SHA384 |
| TLSv1.3 | TLS_AKE_WITH_CHACHA20_POLY1305_SHA256 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256-draft |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA |
| TLSv1.2 | TLS_RSA_WITH_AES_128_GCM_SHA256 |
| TLSv1.2 | TLS_RSA_WITH_AES_128_CBC_SHA |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA |
| TLSv1.2 | TLS_RSA_WITH_AES_256_GCM_SHA384 |
| TLSv1.2 | TLS_RSA_WITH_AES_256_CBC_SHA |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256 |
| TLSv1.2 | TLS_RSA_WITH_AES_128_CBC_SHA256 |
| TLSv1.2 | TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384 |
| TLSv1.2 | TLS_RSA_WITH_AES_256_CBC_SHA256 |

## 証明書の要件 {#certificate-requirements}

さらに、OpenSSL 3では、[デフォルトのセキュリティレベルがレベル1から2に引き上げられ](https://docs.openssl.org/3.0/man3/SSL_CTX_set_security_level/#default-callback-behaviour)、セキュリティの最小ビット数が80から112に引き上げられました。その結果、2048ビット未満のRSA、DSA、DHキーと、224ビット未満のECCキーは禁止されています。GitLabは、ビット数が不十分な署名付き証明書を使用するサービスへの接続に失敗し、`certificate key too weak`エラーメッセージが返されます。

少なくとも128ビットのセキュリティを使用する必要があります。つまり、少なくとも3072ビットのRSA、DSA、DHキーと、256ビットを超えるECCキーを使用します。

| キーの種類 | キーの長さ（ビット） | ステータス      |
|----------|-------------------|-------------|
| RSA      | 1024              | 禁止  |
| RSA      | 2048              | サポート対象   |
| RSA      | 3072              | 推奨 |
| RSA      | 4096              | 推奨 |
| DSA      | 1024              | 禁止  |
| DSA      | 2048              | サポート対象   |
| DSA      | 3072              | 推奨 |
| ECC      | 192               | 禁止  |
| ECC      | 224               | サポート対象   |
| ECC      | 256               | 推奨 |
| ECC      | 384               | 推奨 |

## OpenSSLバージョンとTLS要件 {#openssl-version-and-tls-requirements}

GitLab 17.7以降では、OpenSSLバージョン3を使用します。Linuxパッケージに同梱されているすべてのコンポーネントは、OpenSSL 3と互換性があります。ただし、GitLab 17.7にアップグレードする前に、[OpenSSL 3ガイド](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3.html)を使用して、外部インテグレーションの互換性を特定して評価してください。

## `close_notify`のOpenSSL 3要件の回避 {#bypassing-the-openssl-3-requirement-for-close_notify}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181759)され、GitLab 17.9.1、17.8.4、および17.7.6にバックポートされました。

{{< /history >}}

[RFC 52460](https://www.rfc-editor.org/rfc/rfc5246#section-7.2.1)では、SSL接続は`close_notify`メッセージで終了する必要があります。OpenSSL 3は、これをセキュリティ対策として実施します。サードパーティのS3プロバイダーなどの一部のサービスは、この実施により`unexpected eof while reading`エラーをレポートする場合があります。

この要件は、`SSL_IGNORE_UNEXPECTED_EOF` [環境変数](../administration/environment_variables.md)を`true`に設定することで無効にできます。これは一時的な回避策としてのみ意図されています。これを無効にすると、トランケーション攻撃に対するセキュリティ脆弱性が発生する可能性があります。
