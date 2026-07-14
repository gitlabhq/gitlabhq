---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
description: 많은 사용자가 있는 GitLab 인스턴스를 위해 더 빠른 SSH 인증 방법을 구성합니다.
title: SSH 키 빠른 조회
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

사용자 수가 증가하면 OpenSSH가 `authorized_keys` 파일을 통해 선형 검색을 수행하여 사용자를 인증하기 때문에 SSH 작업이 느려집니다. 이 프로세스는 상당한 시간과 디스크 I/O를 필요로 하며, 이는 리포지토리에 푸시하거나 풀을 시도하는 사용자를 지연시킵니다. 사용자가 키를 자주 추가하거나 제거하면 운영 체제가 `authorized_keys` 파일을 캐시하지 않을 수 있으며, 이로 인해 반복된 디스크 읽기가 발생합니다.

`authorized_keys` 파일 대신 GitLab Shell을 구성하여 SSH 키를 조회할 수 있습니다. GitLab 데이터베이스에서 조회가 인덱싱되어 있기 때문에 더 빠릅니다.

> [!note]
> 표준(배포 키) 사용자의 경우 [SSH 인증서](ssh_certificates.md) 사용을 고려하세요. 이는 데이터베이스 조회보다 빠르지만 `authorized_keys` 파일의 직접적인 대체는 아닙니다.

## Geo에 빠른 조회가 필요함 {#fast-lookup-is-required-for-geo}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Cloud Native GitLab](https://docs.gitlab.com/charts/)과 달리, 기본적으로 Linux 패키지 설치는 `git` 사용자의 홈 디렉토리에 위치한 `authorized_keys` 파일을 관리합니다. 대부분의 설치에서 이 파일은 `/var/opt/gitlab/.ssh/authorized_keys` 아래에 위치합니다. 다음 명령을 사용하여 시스템에서 `authorized_keys`를 찾으세요:

```shell
getent passwd git | cut -d: -f6 | awk '{print $1"/.ssh/authorized_keys"}'
```

`authorized_keys` 파일에는 GitLab에 액세스할 수 있는 사용자의 모든 공개 SSH 키가 포함되어 있습니다. 그러나 단일 정보 출처를 유지하려면 [Geo](../geo/_index.md)를 SSH 지문 조회를 데이터베이스 조회로 수행하도록 구성해야 합니다.

[Geo를 설정](../geo/setup/_index.md)할 때, 기본 노드와 보조 노드 모두에 대해 아래 단계를 따라야 합니다. 기본 노드에서 **`authorized keys` 파일에 쓰기**를 선택하지 마세요. 데이터베이스 복제가 작동하면 보조 노드에 자동으로 반영됩니다.

## 빠른 조회 설정 {#set-up-fast-lookup}

GitLab Shell은 GitLab 데이터베이스에 대한 빠르고 인덱싱된 조회로 SSH 사용자를 인증하는 방법을 제공합니다. GitLab Shell은 SSH 키의 지문을 사용하여 사용자가 GitLab에 액세스할 수 있는 권한이 있는지 확인합니다.

빠른 조회는 다음 SSH 서버에서 활성화할 수 있습니다:

- [`gitlab-sshd`](gitlab_sshd.md)
- OpenSSH

각 서비스에 대해 별도의 포트를 사용하여 두 서비스를 동시에 실행할 수 있습니다.

### `gitlab-sshd` 포함 {#with-gitlab-sshd}

설정 정보는 [`gitlab-sshd`](gitlab_sshd.md)를 참조하세요. `gitlab-sshd`가 활성화되면 GitLab Shell과 `gitlab-sshd`는 빠른 조회를 자동으로 사용하도록 구성됩니다.

### OpenSSH {#with-openssh}

전제 조건:

- OpenSSH 6.9 이상이어야 합니다. `AuthorizedKeysCommand`은 지문을 수락해야 합니다. 버전을 확인하려면 `sshd -V`를 실행하세요.
- 관리자 액세스.

OpenSSH로 빠른 조회를 설정하려면:

1. `sshd_config` 파일에 다음을 추가하세요:

   ```plaintext
   Match User git    # Apply the AuthorizedKeysCommands to the git user only
     AuthorizedKeysCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-keys-check git %u %k
     AuthorizedKeysCommandUser git
   Match all    # End match, settings apply to all users again
   ```

   이 파일은 일반적으로 다음 위치에 있습니다:

   - Linux 패키지 설치: `/etc/ssh/sshd_config`
   - Docker 설치: `/assets/sshd_config`
   - 직접 컴파일한 설치:  [소스에서 GitLab Shell 설치](../../install/self_compiled/_index.md#install-gitlab-shell)를 위한 지침을 따른 경우, 명령은 `/home/git/gitlab-shell/bin/gitlab-shell-authorized-keys-check`에 위치해야 합니다. 이 명령은 `root`의 소유여야 하고 그룹이나 다른 사람이 쓸 수 없어야 하므로 다른 곳에 래퍼 스크립트를 생성하는 것을 고려하세요. 또한 필요에 따라 이 명령의 소유권을 변경하는 것을 고려하세요. 그러나 이로 인해 `gitlab-shell` 업그레이드 중에 임시 소유권 변경이 필요할 수 있습니다.

1. OpenSSH를 다시 로드하세요:

   ```shell
   # Debian or Ubuntu installations
   sudo service ssh reload

   # CentOS installations
   sudo service sshd reload
   ```

1. SSH가 작동하는지 확인하세요:

   1. `authorized_keys` 파일에서 사용자의 키를 주석 처리하세요. 이를 수행하려면 줄을 `#`로 시작하세요.
   1. 로컬 머신에서 리포지토리를 풀하거나 다음을 실행해 보세요:

      ```shell
      ssh -T git@gitlab.example.com
      ```

      성공한 풀 또는 [환영 메시지](../../user/ssh.md#verify-your-ssh-connection)는 키가 파일에 없기 때문에 GitLab이 데이터베이스에서 키를 찾았다는 의미입니다.

조회 실패가 있으면 `authorized_keys` 파일이 여전히 스캔됩니다. 큰 파일이 존재하는 한 많은 사용자의 Git SSH 성능은 여전히 느릴 수 있습니다.

이를 해결하려면 `authorized_keys` 파일에 대한 쓰기를 비활성화할 수 있습니다:

1. SSH가 작동하는지 확인하세요. 이 단계는 중요합니다. 그렇지 않으면 파일이 빠르게 최신이 아닌 상태가 됩니다.
1. `authorized_keys` 파일에 대한 쓰기를 비활성화하세요:

   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. **설정** > **네트워크**를 선택하세요.
   1. **성능 최적화**를 확장하세요.
   1. **`authorized_keys` 파일을 사용하여 SSH 키 인증** 확인란을 선택 해제하세요.
   1. **변경 사항 저장**을 선택합니다.

1. 변경 사항을 확인하세요:

   1. UI에서 SSH 키를 제거하세요.
   1. 새 키를 추가하세요.
   1. 리포지토리를 풀하려고 시도하세요.

1. `authorized_keys` 파일을 백업하고 삭제하세요. 현재 사용자의 키는 이미 데이터베이스에 있으므로 마이그레이션이나 사용자가 키를 다시 추가할 필요가 없습니다.

### `authorized_keys` 파일 사용으로 돌아가는 방법 {#how-to-go-back-to-using-the-authorized_keys-file}

이 개요는 간단합니다. 자세한 내용은 이전 지침을 참조하세요.

1. `authorized_keys` 파일에 대한 쓰기를 활성화하세요.
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택하세요.
   1. **성능 최적화**를 확장하세요.
   1. **`authorized_keys` 파일을 사용하여 SSH 키 인증** 확인란을 선택하세요.
1. [`authorized_keys` 파일 다시 빌드](../raketasks/maintenance.md#rebuild-authorized_keys-file)하세요.
1. `AuthorizedKeysCommand` 줄을 `/etc/ssh/sshd_config`에서 제거하거나 Linux 패키지 설치에서 Docker를 사용하는 경우 `/assets/sshd_config`에서 제거하세요.
1. `sshd`을 다시 로드하세요: `sudo service sshd reload`.

## SELinux 지원 {#selinux-support}

GitLab은 `authorized_keys` 데이터베이스 조회를 [SELinux](https://en.wikipedia.org/wiki/Security-Enhanced_Linux)로 지원합니다.

SELinux 정책이 정적이므로 GitLab은 내부 웹 서버 포트 변경을 지원하지 않습니다. 관리자는 동적으로 생성되지 않으므로 환경을 위해 특별한 `.te` 파일을 생성해야 합니다.

### 추가 문서 {#additional-documentation}

`gitlab-sshd`에 대한 추가 기술 문서는 GitLab Shell 문서에서 확인할 수 있습니다.

## 문제 해결 {#troubleshooting}

### SSH 트래픽이 느리거나 높은 CPU 로드 {#ssh-traffic-slow-or-high-cpu-load}

SSH 트래픽이 [느리거나](https://github.com/linux-pam/linux-pam/issues/270) 높은 CPU 로드를 유발하는 경우:

- `/var/log/btmp`의 크기를 확인하세요.
- 정기적으로 또는 특정 크기에 도달한 후 회전하는지 확인하세요.

이 파일이 매우 크면 GitLab SSH 빠른 조회가 병목을 더 자주 발생시켜 성능을 더욱 저하시킬 수 있습니다. [`UsePAM`를 `sshd_config`에서 비활성화](https://linux.die.net/man/5/sshd_config)하여 `/var/log/btmp`를 전혀 읽지 않도록 하는 것을 고려하세요.

실행 중인 `sshd: git` 프로세스에서 `strace`과 `lsof`를 실행하면 디버깅 정보가 반환됩니다. IP `x.x.x.x`에 대한 진행 중인 Git over SSH 연결에서 `strace`를 가져오려면 다음을 실행하세요:

```plaintext
sudo strace -s 10000 -p $(sudo netstat -tp | grep x.x.x.x | egrep 'ssh.*: git' | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```

또는 실행 중인 Git over SSH 프로세스의 `lsof`를 가져오세요:

```plaintext
sudo lsof -p $(sudo netstat -tp | egrep 'ssh.*: git' | head -1 | sed -e 's/.*ESTABLISHED *//' -e 's#/.*##')
```
