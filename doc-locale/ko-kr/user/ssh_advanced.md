---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 고급 SSH 키 구성
description: GitLab 리포지토리에 대한 보안 인증과 통신을 위해 SSH 키를 사용합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

특수화된 워크플로우를 위해 고급 SSH 키 옵션을 구성합니다.
> [!note]
> GitLab 계정으로 기본 SSH 키 사용에 대한 정보는 [GitLab에서 SSH 키 사용](ssh.md)을 참조하세요.

## FIDO2 하드웨어 보안 키에 대한 SSH 키 쌍 생성 {#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key}

ED25519_SK 또는 ECDSA_SK SSH 키를 생성하려면 OpenSSH 8.2 이상을 사용해야 합니다:

1. 하드웨어 보안 키를 컴퓨터에 삽입합니다.
1. 터미널을 엽니다.
1. `ssh-keygen -t`을 키 유형 및 선택적 주석과 함께 실행하여 나중에 키를 식별하는 데 도움을 줍니다. 일반적인 옵션은 주석으로 이메일 주소를 사용하는 것입니다. 주석이 `.pub` 파일에 포함됩니다.

   예를 들어 ED25519_SK의 경우:

   ```shell
   ssh-keygen -t ed25519-sk -C "<comment>"
   ```

   ECDSA_SK의 경우:

   ```shell
   ssh-keygen -t ecdsa-sk -C "<comment>"
   ```

   보안 키가 FIDO2 상주 키를 지원하는 경우 SSH 키를 생성할 때 이 옵션을 활성화할 수 있습니다:

   ```shell
   ssh-keygen -t ed25519-sk -O resident -C "<comment>"
   ```

   `-O resident`은 키를 FIDO 인증기 자체에 저장해야 함을 나타냅니다. 상주 키는 [`ssh-add -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-add.1#K) 또는 [`ssh-keygen -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-keygen#K)에 의해 보안 키에서 직접 로드할 수 있으므로 새 컴퓨터로 가져오기가 더 쉽습니다.

1. <kbd>Enter</kbd> 키를 누르세요. 다음과 유사한 출력이 표시됩니다:

   ```plaintext
   Generating public/private ed25519-sk key pair.
   You may need to touch your authenticator to authorize key generation.
   ```

1. 하드웨어 보안 키의 버튼을 터치합니다.
1. 제안된 파일 이름과 디렉토리를 적용합니다:

   ```plaintext
   Enter file in which to save the key (/home/user/.ssh/id_ed25519_sk):
   ```

1. [암호](https://www.ssh.com/academy/ssh/passphrase)를 지정합니다:

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   파일 저장 위치에 대한 정보를 포함한 확인이 표시됩니다.

공개 키와 개인 키가 생성됩니다. [GitLab 계정에 공개 SSH 키 추가](ssh.md#add-an-ssh-key-to-your-gitlab-account)합니다.

## 1Password를 사용하여 SSH 키 쌍 생성 {#generate-an-ssh-key-pair-with-1password}

[1Password](https://1password.com/)와 [1Password 브라우저 확장](https://support.1password.com/getting-started-browser/)을 사용하여 다음 중 하나를 수행할 수 있습니다:

- 새 SSH 키를 자동으로 생성합니다.
- 1Password 보관함의 기존 SSH 키를 사용하여 GitLab으로 인증합니다.

1. GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **SSH 키**를 선택합니다.
1. **새 키 추가**를 선택합니다.
1. **키**를 선택하면 1Password 도우미가 나타나야 합니다.
1. 1Password 아이콘을 선택하고 1Password을 잠금 해제합니다.
1. **SSH 키 생성**을 선택하거나 기존 SSH 키를 선택하여 공개 키를 입력할 수 있습니다.
1. **제목** 입력란에 `Work Laptop` 또는 `Home Workstation`와 같은 설명을 입력합니다.
1. 선택 사항입니다. 키의 **사용 유형**을 선택합니다. `Authentication` 또는 `Signing` 또는 둘 다에 사용할 수 있습니다. `Authentication & Signing`이 기본값입니다.
1. 선택 사항입니다. **만료일**을 업데이트하여 기본 만료일을 수정합니다.
1. **키 추가**를 선택합니다.

1Password와 SSH 키 사용에 대한 자세한 정보는 [1Password 설명서](https://developer.1password.com/docs/ssh/get-started/)를 참조하세요.

## 엔터프라이즈 사용자를 위한 SSH 키 비활성화 {#disable-ssh-keys-for-enterprise-users}

{{< history >}}

- GitLab 18.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/30343)되었습니다.

{{< /history >}}

사전 요구 사항:

- 엔터프라이즈 사용자가 속한 그룹에 대한 소유자 역할이 있어야 합니다.

그룹의 [엔터프라이즈 사용자](enterprise_user/_index.md)의 SSH 키를 비활성화하면:

- 엔터프라이즈 사용자가 새 SSH 키를 추가하는 것을 방지합니다.
- 엔터프라이즈 사용자의 기존 SSH 키를 비활성화합니다.

이것은 그룹의 관리자인 엔터프라이즈 사용자에게도 적용됩니다.

엔터프라이즈 사용자의 SSH 키를 비활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **권한 및 그룹 기능**을 확장합니다.
1. **엔터프라이즈 사용자** 아래에서 **SSH 키 비활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## RSA 키 쌍을 더 안전한 형식으로 업그레이드 {#upgrade-your-rsa-key-pair-to-a-more-secure-format}

OpenSSH 버전이 6.5~7.8 사이인 경우, 터미널을 열고 이 명령을 실행하여 개인 RSA SSH 키를 더 안전한 OpenSSH 형식으로 저장할 수 있습니다:

```shell
ssh-keygen -o -f ~/.ssh/id_rsa
```

또는 다음 명령으로 더 안전한 암호화 형식의 새 RSA 키를 생성할 수 있습니다:

```shell
ssh-keygen -o -t rsa -b 4096 -C "<comment>"
```

## SSH 키 암호 업데이트 {#update-your-ssh-key-passphrase}

SSH 키의 암호를 업데이트할 수 있습니다:

1. 터미널을 열고 이 명령을 실행합니다:

   ```shell
   ssh-keygen -p -f /path/to/ssh_key
   ```

1. 프롬프트에서 암호를 입력하고 <kbd>Enter</kbd> 키를 누르세요.

## 단일 GitLab 인스턴스에서 다양한 계정 사용 {#use-different-accounts-on-a-single-gitlab-instance}

여러 계정을 사용하여 GitLab의 단일 인스턴스에 연결할 수 있습니다. [이전 항목](#use-different-keys-for-different-repositories)의 명령을 사용하여 이 작업을 수행할 수 있습니다. 그러나 `IdentitiesOnly`를 `yes`로 설정하더라도 `Host` 블록 외부에 `IdentityFile`가 있으면 로그인할 수 없습니다.

대신 `~/.ssh/config` 파일의 호스트에 별칭을 지정할 수 있습니다.

- `Host`의 경우 `user_1.gitlab.com` 및 `user_2.gitlab.com`와 같은 별칭을 사용합니다. 고급 구성은 유지하기가 더 어렵지만 `git remote`와 같은 도구를 사용할 때 이러한 문자열을 이해하기가 더 쉽습니다.
- `IdentityFile`의 경우 개인 키 경로를 사용합니다.

```conf
# User1 Account Identity
Host <user_1.gitlab.com>
  Hostname gitlab.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/<example_ssh_key1>

# User2 Account Identity
Host <user_2.gitlab.com>
  Hostname gitlab.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/<example_ssh_key2>
```

이제 `user_1`에 대한 리포지토리를 복제하려면 `git clone` 명령에 `user_1.gitlab.com`를 사용합니다:

```shell
git clone git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

`origin`로 별칭이 지정된 이전에 복제한 리포지토리를 업데이트하려면:

```shell
git remote set-url origin git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

> [!note]
> 개인 키와 공개 키에는 민감한 데이터가 포함됩니다. 파일에 대한 권한이 읽기는 가능하지만 다른 사용자가 접근할 수 없도록 설정합니다.

## 다양한 리포지토리에 대해 다양한 키 사용 {#use-different-keys-for-different-repositories}

각 리포지토리에 대해 다른 키를 사용할 수 있습니다.

터미널을 열고 이 명령을 실행합니다:

```shell
git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/private-key-filename-for-this-repository -F /dev/null"
```

이 명령은 SSH 에이전트를 사용하지 않으며 Git 2.10 이상이 필요합니다. `ssh` 명령 옵션에 대한 자세한 정보는 `ssh` 및 `ssh_config`의 `man` 페이지를 참조하세요.

## 다른 디렉토리에서 SSH 키 사용 {#use-ssh-keys-in-another-directory}

SSH 키 쌍이 기본 디렉토리에 없는 경우, 개인 키를 저장한 위치를 가리키도록 SSH 클라이언트를 구성합니다.

1. 터미널을 열고 이 명령을 실행합니다:

   ```shell
   eval $(ssh-agent -s)
   ssh-add <directory to private SSH key>
   ```

1. 이러한 설정을 `~/.ssh/config` 파일에 저장합니다. 예를 들어:

   ```conf
   # GitLab.com
   Host gitlab.com
     PreferredAuthentications publickey
     IdentityFile ~/.ssh/gitlab_com_rsa

   # Private GitLab instance
   Host gitlab.company.com
     PreferredAuthentications publickey
     IdentityFile ~/.ssh/example_com_rsa
   ```

이러한 설정에 대한 자세한 정보는 SSH 구성 설명서의 [`man ssh_config`](https://man.openbsd.org/ssh_config) 페이지를 참조하세요.

공개 SSH 키는 계정에 바인딩되므로 GitLab에 고유해야 합니다. SSH로 코드를 푸시할 때 사용하는 유일한 식별자는 SSH 키입니다. 단일 사용자에게 고유하게 매핑되어야 합니다.

## SSH 키를 다른 장치로 이동 {#move-an-ssh-key-to-another-device}

개인 키 파일을 복사하여 여러 장치에서 동일한 SSH 키를 사용할 수 있습니다. GitLab에서 아무것도 변경할 필요가 없습니다.

> [!note]
> 더 나은 보안을 위해 대신 각 장치에 대해 [새 SSH 키 생성](ssh.md#generate-an-ssh-key-pair)을 고려하세요. 이는 손실되거나 손상된 장치의 영향을 제한합니다.

SSH 키를 다른 장치로 이동하려면:

1. 원본 장치에서 [기존 SSH 키 쌍을 찾으세요](ssh.md#check-for-existing-ssh-key-pairs).
1. 파일을 새 장치의 `~/.ssh/` 디렉토리로 복사합니다.

   > [!warning]
   > 이메일, 채팅 또는 암호화되지 않은 클라우드 동기화 서비스를 통해 개인 키를 절대 보내지 마세요. 암호 관리자 또는 암호화된 USB 드라이브와 같은 암호화된 전송 방법을 사용합니다.

1. 새 장치에서 터미널을 엽니다.
1. 개인 키를 읽을 수 있도록 권한을 설정합니다. 예를 들어 ED25519의 경우:

   ```shell
   chmod 600 ~/.ssh/id_ed25519
   ```

1. SSH 에이전트에 키를 추가합니다:

   ```shell
   eval $(ssh-agent -s)
   ssh-add ~/.ssh/id_ed25519
   ```

1. 키가 GitLab으로 인증되는지 확인합니다. 자세한 정보는 [SSH 연결 확인](ssh.md#verify-your-ssh-connection)을 참조하세요.

FIDO2 하드웨어 보안 키에 저장된 SSH 키의 경우 개인 키 파일을 복사하지 마세요. 대신 `ssh-add -K`로 보안 키에서 키를 가져옵니다. 자세한 정보는 [FIDO2 하드웨어 보안 키에 대한 SSH 키 쌍 생성](#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key)을 참조하세요.

Microsoft Windows에서 WSL과 Git for Windows 환경은 다른 홈 디렉토리를 사용합니다. 자세한 정보는 [Microsoft Windows에서 SSH 사용](#use-ssh-on-microsoft-windows)을 참조하세요.

## Eclipse에서 EGit으로 SSH 사용 {#use-ssh-with-egit-on-eclipse}

[EGit](https://projects.eclipse.org/projects/technology.egit)를 사용하는 경우 [Eclipse에 SSH 키 추가](https://wiki.eclipse.org/EGit/User_Guide/#Eclipse_SSH_Configuration)할 수 있습니다.

## Microsoft Windows에서 SSH 사용 {#use-ssh-on-microsoft-windows}

Windows 10에서는 [Windows Subsystem for Linux(WSL)](https://learn.microsoft.com/en-us/windows/wsl/install)을 [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install#update-to-wsl-2)와 함께 사용할 수 있으며, 이는 `git` 및 `ssh`을 사전 설치하거나 [Windows용 Git](https://gitforwindows.org)을 설치하여 PowerShell을 통해 SSH를 사용할 수 있습니다.

WSL에서 생성된 SSH 키는 Git for Windows에서 직접 사용할 수 없으며, 그 반대도 마찬가지입니다. 둘 다 다른 홈 디렉토리를 가지고 있기 때문입니다:

- WSL: `/home/<user>`
- Windows용 Git: `C:\Users\<user>`

`.ssh/` 디렉토리를 복사하여 동일한 키를 사용하거나 각 환경에서 키를 생성할 수 있습니다.

Windows 11을 실행 중이고 [Windows용 OpenSSH](https://learn.microsoft.com/en-us/windows-server/administration/OpenSSH/openssh-overview)를 사용하는 경우 `HOME` 환경 변수가 올바르게 설정되었는지 확인하세요. 그렇지 않으면 개인 SSH 키를 찾지 못할 수 있습니다.

다른 도구는 다음과 같습니다:

- [Cygwin](https://www.cygwin.com)
- [PuTTYgen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) 0.81 이상(이전 버전은 [공개 공격에 취약](https://www.openwall.com/lists/oss-security/2024/04/15/6)함)

## Git over SSH에 대한 2단계 인증 사용 {#use-two-factor-authentication-for-git-over-ssh}

[Git over SSH](../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations)에 2FA를 사용할 수 있습니다. `ED25519_SK` 또는 `ECDSA_SK` SSH 키를 사용해야 합니다. 자세한 정보는 [지원되는 SSH 키 유형](ssh.md#supported-ssh-key-types)을 참조하세요.
