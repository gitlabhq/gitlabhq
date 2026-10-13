---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab에서 SSH 키 사용하기
description: GitLab 리포지토리에 대한 보안 인증과 통신을 위해 SSH 키를 사용합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

SSH 키를 사용하여 매번 사용자 이름과 비밀번호를 입력하지 않고도 GitLab으로 안전하게 인증합니다.

GitLab에서 SSH 키를 사용하려면 다음을 수행해야 합니다:

1. 로컬 시스템에서 SSH 키 쌍을 생성합니다.
1. SSH 키를 GitLab 계정에 추가합니다.
1. GitLab 연결을 확인합니다.

그러면 [SSH로 리포지토리 복제](../topics/git/clone.md#clone-with-ssh)할 수 있습니다. 한 개의 SSH 키로 계정이 액세스할 수 있는 모든 프로젝트와 그룹에 인증합니다. 각 프로젝트마다 별도의 키가 필요하지 않습니다. 특정 리포지토리에 다른 키를 사용하려면 [다양한 리포지토리에 다양한 키 사용](ssh_advanced.md#use-different-keys-for-different-repositories)을 참조하세요.

> [!note]
> 하드웨어 보안 키, 다중 계정 또는 Microsoft Windows와 같은 덜 일반적인 설정의 경우 [고급 SSH 키 구성](ssh_advanced.md)을 참조하세요.

## SSH 키란 무엇입니까 {#what-are-ssh-keys}

SSH는 공개 키와 개인 키라는 두 개의 키를 사용합니다.

- 공개 키를 배포할 수 있습니다.
- 개인 키는 보호되어야 합니다.

공개 키를 업로드하여 기밀 데이터를 공개하는 것은 불가능합니다. SSH 공개 키를 복사하거나 업로드해야 할 경우 실수로 개인 키를 복사하거나 업로드하지 않았는지 확인하세요.

개인 키를 사용하여 [커밋에 서명](project/repository/signed_commits/ssh.md)할 수 있으므로 GitLab 사용과 데이터를 더욱 안전하게 만듭니다. 이 서명은 공개 키를 사용하는 누구나 확인할 수 있습니다.

자세한 내용은 [비대칭 암호화(공개 키 암호화라고도 함)](https://en.wikipedia.org/wiki/Public-key_cryptography)를 참조하세요.

## 사전 요구 사항 {#prerequisites}

GitLab과 통신하기 위해 SSH를 사용하려면 다음이 필요합니다:

- GNU/Linux, macOS 및 Windows 10에 사전 설치된 OpenSSH 클라이언트입니다.
- SSH 버전 6.5 이상입니다. 이전 버전에서는 보안이 없는 MD5 서명을 사용했습니다.

> [!note]
> 시스템에 설치된 SSH 버전을 보려면 `ssh -V`를 실행하세요.

## 지원되는 SSH 키 유형 {#supported-ssh-key-types}

GitLab과 통신하려면 다음 SSH 키 유형을 사용할 수 있습니다:

| 알고리즘           | 참고 |
| ------------------- | ----- |
| ED25519(권장) | RSA 키보다 더 안전하고 성능이 좋습니다. OpenSSH 6.5(2014)에서 도입되었으며 대부분의 운영 체제에서 사용할 수 있습니다. 모든 FIPS 시스템에서 완전히 지원되지 않을 수 있습니다. 자세한 내용은 [이슈 367429](https://gitlab.com/gitlab-org/gitlab/-/issues/367429)를 참조하세요. |
| ED25519_SK          | 로컬 클라이언트와 GitLab 서버 모두에서 OpenSSH 8.2 이상이 필요합니다. |
| ECDSA_SK            | 로컬 클라이언트와 GitLab 서버 모두에서 OpenSSH 8.2 이상이 필요합니다. |
| RSA                 | ED25519보다 덜 안전합니다. 사용할 경우 GitLab에서는 최소 4096비트의 키 크기를 권장합니다. Go 제한으로 인해 최대 키 길이는 8192비트입니다. 기본 키 크기는 `ssh-keygen` 버전에 따라 다릅니다. |
| ECDSA               | [보안 문제](https://leanpub.com/gocrypto/read#leanpub-auto-ecdsa)는 DSA와도 ECDSA 키에 적용됩니다. |

## 기존 SSH 키 쌍 확인 {#check-for-existing-ssh-key-pairs}

키 쌍을 생성하기 전에 키 쌍이 이미 있는지 확인하세요.

1. 홈 디렉터리로 이동합니다.
1. `.ssh/` 하위 디렉터리로 이동합니다. `.ssh/` 하위 디렉터리가 없으면 홈 디렉터리에 없거나 이전에 `ssh`를 사용하지 않은 것입니다. 후자의 경우 [SSH 키 쌍을 생성](#generate-an-ssh-key-pair)해야 합니다.
1. 다음 형식 중 하나로 파일이 있는지 확인합니다:

   | 알고리즘             | 공개 키 | 개인 키 |
   |-----------------------|------------|-------------|
   |  ED25519(권장)  | `id_ed25519.pub` | `id_ed25519` |
   |  ED25519_SK           | `id_ed25519_sk.pub` | `id_ed25519_sk` |
   |  ECDSA_SK             | `id_ecdsa_sk.pub` | `id_ecdsa_sk` |
   |  RSA(최소 4096비트 키 크기) | `id_rsa.pub` | `id_rsa` |
   |  DSA(더 이상 사용되지 않음)     | `id_dsa.pub` | `id_dsa` |
   |  ECDSA                | `id_ecdsa.pub` | `id_ecdsa` |

## SSH 키 쌍 생성 {#generate-an-ssh-key-pair}

기존 SSH 키 쌍이 없으면 새 쌍을 생성합니다:

1. 터미널을 엽니다.
1. `ssh-keygen -t`을 키 유형 및 선택적 주석과 함께 실행하여 나중에 키를 식별하는 데 도움을 줍니다. 일반적인 옵션은 주석으로 이메일 주소를 사용하는 것입니다. 주석이 `.pub` 파일에 포함됩니다.

   예를 들어 ED25519의 경우:

   ```shell
   ssh-keygen -t ed25519 -C "<comment>"
   ```

   4096비트 RSA의 경우:

   ```shell
   ssh-keygen -t rsa -b 4096 -C "<comment>"
   ```

1. <kbd>Enter</kbd> 키를 누르세요. 다음과 유사한 출력이 표시됩니다:

   ```plaintext
   Generating public/private ed25519 key pair.
   Enter file in which to save the key (/home/user/.ssh/id_ed25519):
   ```

1. [배포 키](project/deploy_keys/_index.md)를 생성하거나 다른 키를 저장하는 특정 디렉터리에 저장하려는 경우가 아니면 제안된 파일 이름과 디렉터리를 수락합니다.

   SSH 키 쌍을 [특정 호스트](ssh_advanced.md#use-ssh-keys-in-another-directory)에 지정할 수도 있습니다.

1. [암호](https://www.ssh.com/academy/ssh/passphrase)를 지정합니다:

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   파일 저장 위치에 대한 정보를 포함한 확인이 표시됩니다. 공개 키와 개인 키가 생성됩니다.

1. 개인 SSH 키를 `ssh-agent`에 추가합니다.

   예를 들어 ED25519의 경우:

   ```shell
   ssh-add ~/.ssh/id_ed25519
   ```

## GitLab 계정에 SSH 키 추가 {#add-an-ssh-key-to-your-gitlab-account}

GitLab에서 SSH를 사용하려면 공개 키를 GitLab 계정으로 복사합니다. GitLab은 개인 키에 액세스할 수 없습니다.

SSH 키를 추가하면 GitLab에서 알려진 손상된 키 목록에 대해 검사합니다. 관련된 개인 키가 공개적으로 알려져 있고 계정 액세스에 사용될 수 있으므로 손상된 키를 추가할 수 없습니다. 이 제한은 구성할 수 없습니다.

키가 차단되면 [새 SSH 키 쌍을 생성](#generate-an-ssh-key-pair)합니다.

GitLab 계정에 SSH 키를 추가하려면:

1. 공개 키 파일의 내용을 복사합니다. 수동으로 수행하거나 스크립트를 사용할 수 있습니다.

   이 예제에서는 `id_ed25519.pub`을 파일 이름으로 바꿉니다. 예를 들어 RSA의 경우 `id_rsa.pub`를 사용합니다.

   {{< tabs >}}

   {{< tab title="macOS" >}}

   ```shell
   tr -d '\n' < ~/.ssh/id_ed25519.pub | pbcopy
   ```

   {{< /tab >}}

   {{< tab title="Linux(xclip 패키지 필요)" >}}

   ```shell
   xclip -sel clip < ~/.ssh/id_ed25519.pub
   ```

   {{< /tab >}}

   {{< tab title="Windows의 Git Bash" >}}

   ```shell
   cat ~/.ssh/id_ed25519.pub | clip
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **SSH 키**를 선택합니다.
1. **새 키 추가**를 선택합니다.
1. **키** 상자에 공개 키의 내용을 붙여넣습니다. 수동으로 키를 복사한 경우 `ssh-rsa`, `ssh-dss`, `ecdsa-sha2-nistp256`, `ecdsa-sha2-nistp384`, `ecdsa-sha2-nistp521`, `ssh-ed25519`, `sk-ecdsa-sha2-nistp256@openssh.com` 또는 `sk-ssh-ed25519@openssh.com`로 시작하는 전체 키를 복사했는지 확인하고 설명으로 끝날 수 있습니다.
1. **제목** 상자에 `Work Laptop` 또는 `Home Workstation`와 같은 설명을 입력합니다.
1. 선택 사항입니다. 키의 **사용 유형**을 선택합니다. `Authentication` 또는 `Signing` 또는 둘 다에 사용할 수 있습니다. `Authentication & Signing`이 기본값입니다.
1. 선택 사항입니다. **만료일**을 업데이트하여 기본 만료일을 수정합니다. 자세한 내용은 [SSH 키 만료](#ssh-key-expiration)를 참조하세요.
1. **키 추가**를 선택합니다.

## SSH 연결 확인 {#verify-your-ssh-connection}

SSH 키가 올바르게 추가되었고 GitLab 인스턴스에 연결할 수 있는지 확인합니다:

1. 올바른 서버에 연결되도록 SSH 호스트 키 지문을 식별합니다:
   - GitLab.com의 경우 [SSH 호스트 키 지문](gitlab_com/_index.md#ssh-host-keys-fingerprints) 문서를 참조하세요.
   - GitLab Self-Managed 또는 GitLab Dedicated의 경우 `https://gitlab.example.com/help/instance_configuration#ssh-host-keys-fingerprints`을 참조하세요. 여기서 `gitlab.example.com`는 GitLab 인스턴스 URL입니다.
1. 터미널을 열고 이 명령을 실행합니다:
   - GitLab.com의 경우 `ssh -T git@gitlab.com`를 사용합니다.
   - GitLab Self-Managed 또는 GitLab Dedicated의 경우 `ssh -T git@gitlab.example.com`를 사용하세요. 여기서 `gitlab.example.com`는 GitLab 인스턴스 URL입니다.

기본적으로 연결은 `git` 사용자 이름을 사용하지만 GitLab Self-Managed 또는 GitLab Dedicated 관리자는 [사용자 이름을 변경](https://docs.gitlab.com/omnibus/settings/configuration/#change-the-name-of-the-git-user-or-group)할 수 있습니다.

1. 첫 번째 연결에서 GitLab 호스트의 신뢰성을 확인해야 할 수도 있습니다. 다음과 같은 메시지가 나타나면 화면 프롬프트를 따릅니다:

   ```plaintext
   The authenticity of host 'gitlab.example.com (35.231.145.151)' can't be established.
   ECDSA key fingerprint is SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw.
   Are you sure you want to continue connecting (yes/no)?
   ```

   환영 메시지를 받아야 합니다.

   ```plaintext
   Welcome to GitLab, <username>!
   ```

   메시지가 나타나지 않으면 [SSH 연결 문제 해결](ssh_troubleshooting.md#general-ssh-troubleshooting)을 할 수 있습니다.

## SSH 키 보기 {#view-your-ssh-keys}

계정에 대한 SSH 키를 보려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **SSH 키**를 선택합니다.

기존 SSH 키는 페이지 하단에 나열됩니다. 정보에 다음이 포함됩니다:

- 키의 제목
- 공개 지문
- 허용된 사용 유형
- 생성 날짜
- 마지막 사용 날짜
- 만료 날짜

## SSH 키 제거 {#remove-an-ssh-key}

SSH 키를 해지하거나 삭제하여 계정에서 영구적으로 제거할 수 있습니다.

SSH 키를 사용하여 커밋에 서명하는 경우 SSH 키를 제거하면 추가 영향이 있습니다. 자세한 내용은 [제거된 SSH 키로 서명된 커밋](project/repository/signed_commits/ssh.md#signed-commits-with-removed-ssh-keys)을 참조하세요.

### SSH 키 해지 {#revoke-an-ssh-key}

SSH 키가 손상된 경우 키를 해지합니다.

사전 요구 사항:

- SSH 키에는 `Signing` 또는 `Authentication & Signing` 사용 유형이 있어야 합니다.

SSH 키를 해지하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **SSH 키**를 선택합니다.
1. 해지하려는 SSH 키 옆에서 **해지**를 선택합니다.
1. **해지**를 선택합니다.

### SSH 키 삭제 {#delete-an-ssh-key}

SSH 키를 삭제하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **SSH 키**를 선택합니다.
1. 삭제하려는 키 옆에서 **삭제**({{< icon name="remove" >}})를 선택합니다.
1. **삭제**를 선택합니다.

## SSH 키 만료 {#ssh-key-expiration}

계정에 SSH 키를 추가할 때 만료 날짜를 설정할 수 있습니다. 이 선택적 설정은 보안 위반의 위험을 제한하는 데 도움이 됩니다.

SSH 키가 만료된 후에는 인증이나 커밋 서명에 더 이상 사용할 수 없습니다. [새 SSH 키를 생성](#generate-an-ssh-key-pair)하고 [계정에 추가](#add-an-ssh-key-to-your-gitlab-account)해야 합니다.

GitLab Self-Managed 및 GitLab Dedicated에서 관리자는 만료 날짜를 보고 [키 삭제](../administration/credentials_inventory.md#delete-ssh-keys)할 때 참고용으로 사용할 수 있습니다.

GitLab은 만료되는 SSH 키를 매일 확인하고 알림을 보냅니다:

- 만료 7일 전 UTC 01:00입니다.
- 만료 날짜에 UTC 02:00입니다.

## 관련 항목 {#related-topics}

- [SSH 키를 다른 디바이스로 이동](ssh_advanced.md#move-an-ssh-key-to-another-device)
- [서비스 계정의 SSH 키](profile/service_accounts.md)
- [SSH 문제 해결](ssh_troubleshooting.md)
