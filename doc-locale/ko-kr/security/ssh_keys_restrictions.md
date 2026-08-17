---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: SSH 키 제한 사항 구성
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

`ssh-keygen`은 사용자가 768비트 정도의 RSA 키를 생성할 수 있으며, 이는 미국 NIST와 같은 표준 그룹의 권장 키 크기보다 훨씬 낮으며 안전하지 않습니다. GitLab을 배포하는 일부 조직에서는 내부 보안 정책을 충족하거나 규정 준수를 위해 최소 키 강도를 적용해야 합니다.

마찬가지로 GitLab은 이전의 DSA보다 ED25519, ED25519_SK, ECDSA, ECDSA_SK 또는 RSA를 사용할 것을 강력히 권장합니다. 관리자는 보안을 유지하기 위해 허용되는 SSH 키 알고리즘을 제한하는 것을 강력히 고려해야 합니다.

GitLab을 사용하면 허용되는 SSH 키 기술을 제한하고 각 기술에 대한 최소 키 길이를 지정할 수 있습니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

SSH 키 제한 사항을 구성하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장하고 각 키 유형에 대해 원하는 값을 설정합니다:
   - **RSA SSH keys**.
   - **DSA SSH keys**.
   - **ECDSA SSH keys**.
   - **ED25519 SSH keys**.
   - **ECDSA_SK SSH keys**.
   - **ED25519_SK SSH keys**.
1. **변경 사항 저장**을 선택합니다.

키 유형에 대한 제한이 적용되면 사용자는 요구 사항을 충족하지 않는 새 SSH 키를 업로드할 수 없습니다. 요구 사항을 충족하지 않는 기존 키는 비활성화되지만 제거되지 않으며 사용자는 해당 키를 사용하여 코드를 가져오거나 푸시할 수 없습니다.

제한된 키가 있는 경우 경고 아이콘({{< icon name="warning" >}})이 프로필의 **SSH 키** 섹션에 표시됩니다. 해당 키가 제한된 이유를 알아보려면 아이콘 위에 마우스를 올립니다.

## 기본 설정 {#default-settings}

기본적으로 GitLab.com 및 GitLab Self-Managed의 [지원되는 키 유형](../user/ssh.md#supported-ssh-key-types)에 대한 설정은 다음과 같습니다:

- DSA SSH 키는 금지됩니다.
- RSA SSH 키는 허용됩니다.
- ECDSA SSH 키는 허용됩니다.
- ED25519 SSH 키는 허용됩니다.
- ECDSA_SK SSH 키는 허용됩니다.
- ED25519_SK SSH 키는 허용됩니다.

## GitLab 서버에서 SSH 설정 무시 {#override-ssh-settings-on-the-gitlab-server}

GitLab은 시스템에 설치된 SSH 데몬과 통합되고 `git` 사용자(일반적으로 이름 지정됨)를 지정하며 모든 액세스 요청이 이를 통해 처리됩니다. SSH를 통해 GitLab 서버에 연결하는 사용자는 사용자 이름 대신 SSH 키로 식별됩니다.

GitLab 서버에서 수행되는 SSH 클라이언트 작업은 이 사용자로 실행됩니다. 이 SSH 구성을 수정할 수 있습니다. 예를 들어 이 사용자가 인증 요청에 사용할 개인 SSH 키를 지정할 수 있습니다. 그러나 이 방법은 지원되지 않으며 심각한 보안 위험을 야기하므로 강력히 권장되지 않습니다.

GitLab은 이 조건을 확인하고 서버가 이와 같이 구성되면 이 섹션으로 연결합니다. 예를 들어:

```shell
$ gitlab-rake gitlab:check

Git user has default SSH configuration? ... no
  Try fixing it:
  mkdir ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa ~/gitlab-check-backup-1504540051
  sudo mv /var/lib/git/.ssh/id_rsa.pub ~/gitlab-check-backup-1504540051
  For more information see:
  doc/user/ssh.md#overriding-ssh-settings-on-the-gitlab-server
  Please fix the error above and rerun the checks.
```

> [!warning]
> 가능한 한 빨리 사용자 지정 구성을 제거합니다. 이러한 사용자 지정은 명시적으로 지원되지 않으며 언제든지 작동을 중지할 수 있습니다.

## GitLab SSH 소유권 및 권한 확인 {#verify-gitlab-ssh-ownership-and-permissions}

GitLab SSH 폴더 및 파일에는 다음 권한이 있어야 합니다:

- 폴더 `/var/opt/gitlab/.ssh/`은 `git` 그룹 및 `git` 사용자가 소유해야 하며 권한이 `700`로 설정되어야 합니다.
- `authorized_keys` 파일의 권한을 `600`로 설정해야 합니다.
- `authorized_keys.lock` 파일의 권한을 `644`로 설정해야 합니다.

이러한 권한이 올바른지 확인하려면 다음을 실행합니다:

```shell
stat -c "%a %n" /var/opt/gitlab/.ssh/.
```

### 권한 설정 {#set-permissions}

권한이 잘못된 경우 애플리케이션 서버에 로그인하고 다음을 실행합니다:

```shell
cd /var/opt/gitlab/
chown git:git /var/opt/gitlab/.ssh/
chmod 700  /var/opt/gitlab/.ssh/
chmod 600  /var/opt/gitlab/.ssh/authorized_keys
chmod 644  /var/opt/gitlab/.ssh/authorized_keys.lock
```
