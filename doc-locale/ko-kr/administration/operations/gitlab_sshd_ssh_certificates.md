---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: gitlab-sshd를 사용하여 신뢰할 수 있는 CA 키를 통해 인스턴스 수준의 SSH 인증서 인증을 구성합니다.
title: "`gitlab-sshd`를 사용한 인스턴스 수준의 SSH 인증서"
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab-shell/-/merge_requests/1396).

{{< /history >}}

GitLab Self-Managed 인스턴스가 `gitlab-sshd`를 사용하는 경우 인스턴스 수준의 SSH 인증서 인증을 구성할 수 있습니다.

- CA(인증 기관) 인증서를 사용하여 SSH 인증을 중앙에서 관리합니다.
- Rails API 호출이나 데이터베이스 변경이 필요하지 않습니다.

이 방식은 OpenSSH `TrustedUserCAKeys` 지시문의 `gitlab-sshd` 동등 방식이며 [OpenSSH 기반 SSH 인증서 설정](ssh_certificates.md)의 대안입니다.

## `gitlab_sshd` 인증 워크플로우 {#gitlab_sshd-authentication-workflow}

`gitlab_sshd` 인증 워크플로우는 다음 프로세스를 따릅니다.

1. 관리자가 CA 키 쌍을 생성합니다.
1. 관리자가 `config.yml`에서 `sshd.trusted_user_ca_keys` 아래에 CA 공개 키 파일 경로를 추가합니다.
1. 관리자가 CA 개인 키로 사용자의 SSH 공개 키에 서명합니다. 인증서 `KeyId`이 사용자의 GitLab 사용자 이름으로 설정됩니다.
1. 사용자가 인증서로 연결할 때:
   - `gitlab-sshd`는 인증서 서명 및 만료 기한을 검증합니다.
   - `gitlab-sshd`는 `KeyId`을 추출하고 이를 GitLab 사용자 이름으로 사용합니다.
   - 표준 GitLab 액세스 확인이 진행됩니다(사용자 존재 여부, 프로젝트 권한).

`gitlab-sshd` 프로세스는 인증서 검증 자체에 대해 Rails API 또는 데이터베이스 호출이 필요하지 않습니다. `/allowed` 엔드포인트는 여전히 모든 SSH 연결과 마찬가지로 인증을 위해 호출됩니다.

## 다른 SSH 인증서 방법과의 비교 {#comparison-with-other-ssh-certificate-methods}

GitLab은 여러 SSH 인증서 인증 방식을 지원합니다:

| 기능 | 인스턴스 수준(`gitlab-sshd`) | 인스턴스 수준(OpenSSH) | 그룹 수준 |
|---|---|---|---|
| 구성 위치 | `config.yml` | `sshd_config` | GitLab API/UI |
| SSH 서버 | `gitlab-sshd` | OpenSSH | `gitlab-sshd` |
| 제공 | GitLab Self-Managed | GitLab Self-Managed | GitLab.com |
| 계층 | Free, Premium, Ultimate | Free, Premium, Ultimate | Premium, Ultimate |
| 범위 | 인스턴스 전체(네임스페이스 제한 없음) | 인스턴스 전체(네임스페이스 제한 없음) | 최상위 그룹 |
| 사용자 이름 매핑 | 인증서 `KeyId` | `AuthorizedPrincipalsCommand`를 통한 인증서 Key ID | API를 통한 인증서 ID |
| 엔터프라이즈 사용자 요구 사항 | 아니요 | 아니요 | 예 |
| 설명서 | 이 페이지 | [OpenSSH `AuthorizedPrincipalsCommand`](ssh_certificates.md) | [그룹 SSH 인증서](../../user/group/ssh_certificates.md) |

## 필수 요구 사항 {#prerequisites}

인스턴스 수준의 SSH 인증서를 구성하기 전에:

- GitLab Self-Managed 인스턴스는 `gitlab-sshd`를 활성화해야 합니다. 자세한 내용은 [`gitlab-sshd` 활성화](gitlab_sshd.md#enable-gitlab-sshd)를 참조하세요.
- CA 키를 생성하고 `config.yml`를 편집하기 위해 서버 파일 시스템에 액세스할 수 있어야 합니다.
- SSH 인증서의 `KeyId` 필드는 정확한 GitLab 사용자 이름과 일치해야 합니다.

## 신뢰할 수 있는 CA 키 구성 {#configure-trusted-ca-keys}

인스턴스 수준의 SSH 인증서 인증을 구성하려면:

1. CA 키 쌍을 생성합니다:

   ```shell
   ssh-keygen -t ed25519 -f ssh_user_ca -C "GitLab SSH User CA"
   ```

   메시지가 표시되면 강력한 암호 문구를 입력하여 CA 개인 키를 보호합니다.

   이 명령은 두 개의 파일을 생성합니다:

   - `ssh_user_ca`:  CA 개인 키.
   - `ssh_user_ca.pub`:  CA 공개 키.

   공개 키만 GitLab 서버로 복사합니다:

   ```shell
   sudo cp ssh_user_ca.pub /etc/gitlab/ssh_user_ca.pub
   ```

   CA 개인 키를 안전한 위치에 저장하세요. 가능하면 GitLab 서버가 아닌 오프라인 시스템에 저장합니다. 개인 키는 사용자 인증서에 서명하기 위해서만 필요합니다.

1. CA 공개 키 파일 경로를 `gitlab-sshd` 구성에 추가합니다.

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   1. `/etc/gitlab/gitlab.rb`을 편집합니다:

      ```ruby
      gitlab_sshd['trusted_user_ca_keys'] = ['/etc/gitlab/ssh_user_ca.pub']
      ```

   1. 파일을 저장하고 GitLab을 재구성합니다:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Helm chart (Kubernetes)" >}}

   1. CA 공개 키를 포함하는 Kubernetes Secret을 생성합니다:

      ```shell
      kubectl create secret generic my-ssh-ca-keys \
        --from-file=ca.pub=ssh_user_ca.pub
      ```

   1. Helm 값을 내보냅니다:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. `gitlab_values.yaml`을 편집하여 비밀을 참조합니다:

      ```yaml
      gitlab:
        gitlab-shell:
          sshDaemon: gitlab-sshd
          config:
            trustedUserCAKeys:
              secret: my-ssh-ca-keys
              keys:
                - ca.pub
      ```

   1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

   Helm 차트 구성에 대한 자세한 내용은 [GitLab Shell 차트 설명서](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#instance-level-ssh-certificates-gitlab-sshd)를 참조하세요.

   {{< /tab >}}

   {{< /tabs >}}

1. `gitlab-sshd`이 성공적으로 시작되었는지 확인하려면 로그를 확인합니다:

   ```plaintext
   Loaded trusted user CA keys for instance-level SSH certificates count=1
   ```

## 사용자에게 SSH 인증서 발급 {#issue-ssh-certificates-for-users}

신뢰할 수 있는 CA 키를 구성한 후 사용자에게 인증서를 발급합니다:

1. 사용자의 공개 SSH 키(예: `id_ed25519.pub`)를 가져옵니다.

1. CA로 사용자의 공개 키에 서명하고 `-I`(ID/KeyId) 플래그를 사용자의 정확한 GitLab 사용자 이름으로 설정합니다:

   ```shell
   ssh-keygen -s ssh_user_ca -I <gitlab-username> -V +1d user-key.pub
   ```

   이 명령은 1일 동안 유효한 인증서 파일(예: `user-key-cert.pub`)을 생성합니다.

   더 긴 유효 기간을 설정하려면 `-V` 플래그를 조정합니다. 예를 들어 30일의 경우 `-V +30d`를 사용하거나 1년의 경우 `-V +52w`를 사용합니다.

1. 인증서 파일을 사용자에게 배포합니다.

1. 사용자가 인증서를 사용하여 연결합니다:

   ```shell
   ssh git@gitlab.example.com
   ```

   인증서 파일이 기본 명명 규칙을 따르면(`<key>-cert.pub`이 `<key>` 옆에 있음) SSH가 자동으로 사용합니다. 또는 인증서를 명시적으로 지정합니다:

   ```shell
   ssh -o CertificateFile=~/.ssh/id_ed25519-cert.pub git@gitlab.example.com
   ```

## 여러 인증 기관 사용 {#use-multiple-certificate-authorities}

CA 교체 또는 다중 CA 설정을 위해 여러 CA 공개 키 파일을 지정할 수 있습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_sshd['trusted_user_ca_keys'] = [
     '/etc/gitlab/ssh_user_ca_current.pub',
     '/etc/gitlab/ssh_user_ca_next.pub'
   ]
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. 두 CA 공개 키를 포함하는 Kubernetes Secret을 생성합니다:

   ```shell
   kubectl create secret generic my-ssh-ca-keys \
     --from-file=ca_current.pub=ssh_user_ca_current.pub \
     --from-file=ca_next.pub=ssh_user_ca_next.pub
   ```

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집하여 비밀을 참조합니다:

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
       config:
         trustedUserCAKeys:
           secret: my-ssh-ca-keys
           keys:
             - ca_current.pub
             - ca_next.pub
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

단일 파일에도 줄당 하나씩 여러 CA 공개 키가 포함될 수 있습니다. `gitlab-sshd`는 파일 전체에서 자동으로 중복 키를 제거합니다.

## 보안 고려 사항 {#security-considerations}

인스턴스 수준의 SSH 인증서는 CA 개인 키를 보유한 모든 사람에게 인증 권한을 부여합니다. 배포하기 전에 다음 보안 고려 사항을 검토하세요.

> [!warning]
> CA 개인 키에 액세스할 수 있는 모든 사람은 인스턴스의 **모두** GitLab 사용자에 대해 인증서에 서명할 수 있습니다. 제한적 파일 권한, 하드웨어 보안 모듈(HSM) 또는 오프라인 환경 등 적절한 액세스 제어로 CA 개인 키를 보호합니다.

### 인증서 해지 없음 {#no-certificate-revocation}

`gitlab-sshd`에는 기본 제공 인증서 해지 메커니즘이 포함되어 있지 않습니다. 인증서 또는 CA 키가 손상된 경우 `trusted_user_ca_keys` 구성에서 CA를 제거하고 새 CA로 인증서를 다시 발급합니다. 단명 인증서(예: 24시간)를 사용하여 노출 기간을 최소화합니다.

### CA 구성 변경에 대한 감사 이벤트 없음 {#no-audit-events-for-ca-configuration-changes}

GitLab은 `config.yml`에서 `trusted_user_ca_keys`에 대한 변경을 감사 이벤트로 기록하지 않습니다. 인프라 모니터링 도구를 사용하여 이 구성 파일의 변경을 모니터링합니다.

`gitlab-sshd`은 `ssh_user`, `public_key_fingerprint`, `signing_ca_fingerprint`, `certificate_identity` 및 `certificate_username`를 포함한 필드와 함께 성공 및 실패한 SSH 인증서 인증 시도를 기록합니다.

### 클러스터형 배포 {#clustered-deployments}

여러 `gitlab-sshd` 노드가 있는 환경에서 모든 노드 전체에서 구성 및 CA 공개 키 파일을 동기화합니다. 일관되지 않은 구성으로 인해 간헐적인 인증 실패가 발생할 수 있습니다. Helm 차트 배포의 경우 Kubernetes Secret이 Pod 전체에서 자동으로 공유됩니다.

## 문제 해결 {#troubleshooting}

### `gitlab-sshd`이 CA 키 추가 후 시작하지 않음 {#gitlab-sshd-fails-to-start-after-adding-ca-keys}

CA 키 파일을 읽을 수 없거나 유효하지 않은 콘텐츠가 포함되어 있으면 `gitlab-sshd`이 시작되지 않습니다. 다음과 같은 오류 메시지에 대해 로그 출력을 확인합니다:

- `failed to load trusted user CA keys`:  파일을 읽을 수 없습니다. 파일이 존재하고 올바른 권한이 있는지 확인합니다(`git` 사용자가 읽을 수 있음).
- `failed to parse trusted user CA key in file`:  파일 콘텐츠가 유효한 SSH 공개 키가 아닙니다. 파일에 OpenSSH 형식의 유효한 공개 키가 포함되어 있는지 확인합니다.
- `trusted_user_ca_keys configured but no valid CA keys were loaded`:  구성은 CA 키 파일을 나열하지만 유효한 키를 포함한 파일이 없습니다.

### `certificate rejected: not a user certificate` {#certificate-rejected-not-a-user-certificate}

인증서는 사용자 인증서 대신 호스트 인증서로 생성되었습니다. `ssh-keygen`로 서명할 때 `-h` 플래그를 사용하지 마세요.

### `certificate KeyId does not match GitLab username format` {#certificate-keyid-does-not-match-gitlab-username-format}

인증서의 `KeyId`이 GitLab 사용자 이름 규칙을 따르지 않습니다. 서명 중에 사용된 `-I` 값이 정확한 GitLab 사용자 이름과 일치하는지 확인합니다.

### `ssh: cert has expired` {#ssh-cert-has-expired}

인증서 유효 기간이 지났습니다. `-V` 플래그를 사용하여 적절한 유효성 기간이 있는 새 인증서를 발급합니다.
