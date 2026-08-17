---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: TLS 지원
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 전송 계층 보안(TLS)을 사용하여 사용자와 플랫폼 간의 데이터 전송 보안을 우선시하며, 인터넷을 통해 전송되는 정보를 보호합니다.

사이버 보안 위협이 계속 진화함에 따라 GitLab은 최고 수준의 보안을 유지하기 위해 최선을 다하고 있습니다. GitLab은 GitLab 서비스와의 모든 통신이 가장 안전하고 최신의 암호화 방법을 사용하도록 정기적으로 TLS 지원을 업데이트합니다.

이 문서는 데이터를 안전하게 보호하기 위해 사용되는 버전과 암호 스위트를 포함하여 GitLab의 현재 TLS 지원을 설명합니다.

## 지원되는 프로토콜 {#supported-protocols}

GitLab은 안전한 통신을 위해 TLS 1.2 이상의 버전을 지원합니다. 이는 TLS 1.2와 TLS 1.3이 완전히 지원되며 GitLab과 함께 사용하기 위해 권장됨을 의미합니다.

TLS 1.1, TLS 1.0 및 모든 버전의 SSL과 같은 이전 프로토콜은 알려진 보안 취약성으로 인해 지원되지 않습니다. TLS 1.2 이상의 사용을 적용함으로써 GitLab은 모든 데이터 전송 및 플랫폼과의 상호 작용에 대해 높은 수준의 보안을 보장합니다.

## 지원되는 암호 스위트 {#supported-cipher-suites}

GitLab은 다양한 암호 스위트를 지원합니다. 다음의 각 암호 스위트는 안전한 것으로 간주되며 [SSL 서버 평가](https://github.com/ssllabs/research/wiki/SSL-Server-Rating-Guide)가 `A`입니다.

| 프로토콜 버전 | 암호 스위트 |
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

## 인증서 요구 사항 {#certificate-requirements}

OpenSSL 3은 [기본 보안 수준을 레벨 1에서 레벨 2로](https://docs.openssl.org/3.0/man3/SSL_CTX_set_security_level/#default-callback-behaviour) 상향 조정했으며, 보안 비트 수를 80에서 112로 높였습니다. 결과적으로 2048비트보다 짧은 RSA, DSA 및 DH 키와 224비트보다 짧은 ECC 키는 금지됩니다. GitLab은 충분하지 않은 비트로 서명된 인증서를 사용하는 서비스에 연결할 수 없으며 `certificate key too weak` 오류 메시지가 나타납니다.

최소 128비트의 보안을 사용해야 합니다. 이는 최소 3072비트의 RSA, DSA 및 DH 키와 256비트보다 긴 ECC 키를 사용하는 것을 의미합니다.

| 키 유형 | 키 길이(비트) | 상태      |
|----------|-------------------|-------------|
| RSA      | 1024              | 금지됨  |
| RSA      | 2048              | 지원됨   |
| RSA      | 3072              | 권장 |
| RSA      | 4096              | 권장 |
| DSA      | 1024              | 금지됨  |
| DSA      | 2048              | 지원됨   |
| DSA      | 3072              | 권장 |
| ECC      | 192               | 금지됨  |
| ECC      | 224               | 지원됨   |
| ECC      | 256               | 권장 |
| ECC      | 384               | 권장 |

## OpenSSL 버전 및 TLS 요구 사항 {#openssl-version-and-tls-requirements}

GitLab 17.7 이상은 OpenSSL 버전 3을 사용합니다. Linux 패키지와 함께 제공되는 모든 구성 요소는 OpenSSL 3과 호환됩니다. 그러나 GitLab 17.7로 업그레이드하기 전에 [OpenSSL 3 가이드](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3/)를 사용하여 외부 통합의 호환성을 식별하고 평가합니다.

## OpenSSL 3 요구 사항 `close_notify` 무시하기 {#bypassing-the-openssl-3-requirement-for-close_notify}

{{< history >}}

- [GitLab 17.10에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181759)되었으며 GitLab 17.9.1, 17.8.4 및 17.7.6으로 백포트되었습니다.

{{< /history >}}

[RFC 52460에 따라](https://www.rfc-editor.org/rfc/rfc5246#section-7.2.1), SSL 연결은 `close_notify` 메시지로 종료되어야 합니다. OpenSSL 3은 이를 보안 조치로 적용합니다. 타사 S3 제공자와 같은 일부 서비스는 이 적용으로 인해 `unexpected eof while reading` 오류를 보고할 수 있습니다.

이 요구 사항은 `SSL_IGNORE_UNEXPECTED_EOF` [환경 변수](../administration/environment_variables.md)를 `true`로 설정하여 비활성화할 수 있습니다. 이는 임시 해결책으로만 사용하려는 것입니다. 이를 비활성화하면 잘림 공격에 대한 보안 취약성이 발생할 수 있습니다.
