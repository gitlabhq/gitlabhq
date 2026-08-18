---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: S/MIME로 발신 이메일에 서명하기
description: 발신 이메일에 대해 S/MIME을 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab에서 보낸 알림 이메일은 보안 강화를 위해 S/MIME로 서명할 수 있습니다.

S/MIME 인증서와 TLS/SSL 인증서는 다르며 다양한 목적으로 사용됩니다:  TLS는 보안 채널을 생성하는 반면 S/MIME은 메시지 자체에 서명하거나 암호화합니다.

## S/MIME 서명 활성화 {#enable-smime-signing}

이 설정을 명시적으로 활성화해야 하며 단일 키 및 인증서 파일 쌍을 제공해야 합니다:

- 두 파일 모두 PEM 형식이어야 합니다.
- 키 파일은 GitLab이 사용자 개입 없이 읽을 수 있도록 암호화되지 않아야 합니다.
- RSA 키만 지원됩니다.

선택적으로 각 서명에 포함될 CA 인증서 번들(PEM 형식)을 제공할 수 있습니다. 이는 일반적으로 중간 CA입니다.

> [!warning]
> 개인 키의 액세스 수준과 제3자에 대한 가시성에 유의하세요.

Linux 패키지 설치의 경우:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 파일 경로를 조정합니다:

   ```ruby
   gitlab_rails['gitlab_email_smime_enabled'] = true
   gitlab_rails['gitlab_email_smime_key_file'] = '/etc/gitlab/ssl/gitlab_smime.key'
   gitlab_rails['gitlab_email_smime_cert_file'] = '/etc/gitlab/ssl/gitlab_smime.crt'
   # Optional
   gitlab_rails['gitlab_email_smime_ca_certs_file'] = '/etc/gitlab/ssl/gitlab_smime_cas.crt'
   ```

1. 파일을 저장하고 [GitLab 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)을(를) 선택하여 변경 사항을 적용합니다.

키는 GitLab 시스템 사용자(`git`, 기본값)가 읽을 수 있어야 합니다.

자체 컴파일 설치의 경우:

1. `config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   email_smime:
     # Uncomment and set to true if you need to enable email S/MIME signing (default: false)
     enabled: true
     # S/MIME private key file in PEM format, unencrypted
     # Default is '.gitlab_smime_key' relative to Rails.root (the root of the GitLab app).
     key_file: /etc/pki/smime/private/gitlab.key
     # S/MIME public certificate key in PEM format, will be attached to signed messages
     # Default is '.gitlab_smime_cert' relative to Rails.root (the root of the GitLab app).
     cert_file: /etc/pki/smime/certs/gitlab.crt
     # S/MIME extra CA public certificates in PEM format, will be attached to signed messages
     # Optional
     ca_certs_file: /etc/pki/smime/certs/gitlab_cas.crt
   ```

1. 파일을 저장하고 [GitLab 재시작](restart_gitlab.md#self-compiled-installations)을(를) 선택하여 변경 사항을 적용합니다.

키는 GitLab 시스템 사용자(`git`, 기본값)가 읽을 수 있어야 합니다.

### S/MIME PKCS #12 형식을 PEM 인코딩으로 변환하는 방법 {#how-to-convert-smime-pkcs-12-format-to-pem-encoding}

일반적으로 S/MIME 인증서는 이진 공개 키 암호 표준(PKCS) #12 형식(`.pfx` 또는 `.p12` 확장자)으로 처리되며, 이는 다음을 단일 암호화된 파일에 포함합니다:

- 공개 인증서
- 중간 인증서(있는 경우)
- 개인 키

PKCS #12 파일에서 PEM 인코딩의 필수 파일을 내보내려면 `openssl` 명령을 사용할 수 있습니다:

```shell
#-- Extract private key in PEM encoding (no password, unencrypted)
openssl pkcs12 -in gitlab.p12 -nocerts -nodes -out gitlab.key

#-- Extract certificates in PEM encoding (full certs chain including CA)
openssl pkcs12 -in gitlab.p12 -nokeys -out gitlab.crt
```
