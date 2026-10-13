---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SSH 문제 해결
---

SSH 키로 작업할 때 다음과 같은 문제가 발생할 수 있습니다.

## TLS: 8192비트보다 큰 RSA 키가 포함된 인증서를 서버에서 보냄 {#tls-server-sent-certificate-containing-rsa-key-larger-than-8192-bits}

Go는 RSA 키를 최대 8192비트로 제한합니다. 키 길이를 확인하려면:

```shell
openssl rsa -in <your-key-file> -text -noout | grep "Key:"
```

8192비트보다 긴 키를 더 짧은 키로 바꿉니다.

## `git clone`로 인한 비밀번호 입력 프롬프트 {#password-prompt-with-git-clone}

`git clone`을(를) 실행하면 `git@gitlab.example.com's password:`같은 비밀번호 입력 프롬프트가 나타날 수 있습니다. 이는 SSH 설정에 문제가 있음을 나타냅니다.

- SSH 키 쌍을 올바르게 생성하고 공개 SSH 키를 GitLab 프로필에 추가했는지 확인합니다.
- SSH 키 형식이 서버 OS 구성과 호환되는지 확인합니다. 예를 들어 ED25519 키 쌍은 [일부 FIPS 시스템](https://gitlab.com/gitlab-org/gitlab/-/issues/367429)에서 작동하지 않을 수 있습니다.
- `ssh-agent`을(를) 사용하여 개인 SSH 키를 수동으로 등록합니다.
- `ssh -Tv git@example.com`을(를) 실행하여 연결을 디버그해 봅니다. `example.com`를 GitLab URL로 바꿉니다.
- [Microsoft Windows에서 SSH 사용](ssh_advanced.md#use-ssh-on-microsoft-windows)의 모든 지침을 따랐는지 확인합니다.
- [GitLab SSH 소유권 및 권한 확인](../security/ssh_keys_restrictions.md#verify-gitlab-ssh-ownership-and-permissions)을(를) 수행했는지 확인합니다. 여러 호스트가 있는 경우 모든 호스트에서 권한이 올바른지 확인합니다.

## `Could not resolve hostname` 오류 {#could-not-resolve-hostname-error}

[SSH 연결 확인](ssh.md#verify-your-ssh-connection)할 때 다음 오류가 나타날 수 있습니다:

```shell
ssh: Could not resolve hostname gitlab.example.com: nodename nor servname provided, or not known
```

이 오류가 나타나면 SSH가 사용자가 제공한 이름의 호스트를 찾을 수 없습니다. SSH가 해석하려고 시도한 이름은 `Could not resolve hostname` 다음의 텍스트입니다. 해당 이름을 다음 원인과 비교합니다.

| 원인 | 해결 방법 |
|-------|------------|
| 이름에 `gitlab.com:alice/my-project.git`같은 리포지토리 경로가 포함되어 있습니다. 이는 클론 URL을 명령에 복사할 때 발생합니다. | `ssh -T git@gitlab.com`같이 호스트만 사용합니다. |
| 이름이 잘못 입력되었거나 GitLab 인스턴스의 URL이 아닙니다. | 이름을 수정하고 명령을 다시 실행합니다. |
| 네트워크가 이름을 해석할 수 없습니다. 이 원인은 GitLab Self-Managed 및 GitLab Dedicated에서 더 가능성이 높습니다. | 인스턴스에 연결할 수 있는지 확인하고 필요한 VPN에 연결합니다. |
| 터미널이 오래된 이름 해석 캐시를 보유하고 있습니다. | 터미널을 다시 시작한 후 명령을 다시 실행합니다. |

## `Key enrollment failed: invalid format` 오류 {#key-enrollment-failed-invalid-format-error}

[FIDO2 하드웨어 보안 키에 대한 SSH 키 쌍 생성](ssh_advanced.md#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key)할 때 다음 오류가 나타날 수 있습니다:

```shell
Key enrollment failed: invalid format
```

다음을 시도하여 이 문제를 해결할 수 있습니다:

- `ssh-keygen` 명령을 `sudo`을(를) 사용하여 실행합니다.
- FIDO2 하드웨어 보안 키가 제공된 키 유형을 지원하는지 확인합니다.
- `ssh -V`을(를) 실행하여 OpenSSH 버전이 8.2 이상인지 확인합니다.

## 오류: `Permission denied (publickey)` {#error-permission-denied-publickey}

`Permission denied (publickey)` 오류는 일반적으로 다음 중 하나 이상의 문제를 나타냅니다:

- 공개 키가 추가되지 않음: 공개 키가 [GitLab 계정에 추가](ssh.md#add-an-ssh-key-to-your-gitlab-account)되었는지 확인합니다. 이 문제는 새 사용자나 새 머신에서 자주 발생합니다.
- 지원되지 않는 키 유형: 키 유형이 [지원되지 않음](ssh.md#supported-ssh-key-types)이거나 GitLab이 인식하지 못하는 헤더가 포함되어 있습니다.
- 잘못된 개인 키 사용 중: [여러 로컬 SSH 키](ssh.md#check-for-existing-ssh-key-pairs)가 있는 경우 올바른 키가 사용되고 있는지 확인합니다. SSH는 기본적으로 `~/.ssh/id_rsa` 또는 `id_ed25519`로 설정됩니다. [사용할 키를 정의](ssh_advanced.md#use-ssh-keys-in-another-directory)해야 할 수 있습니다.
- 개인 키에 액세스할 수 없음: [확인](ssh.md#check-for-existing-ssh-key-pairs)하여 개인 키가 로컬 기기에서 액세스 가능한지 확인합니다.
- 로컬 권한이 잘못됨: 키의 권한을 확인합니다. 개인 키는 `600`을(를) 사용해야 하며, `.ssh` 디렉터리는 `700`을(를) 사용해야 합니다.
- `ssh-agent`에 로드되지 않은 SSH 키: 키가 로컬 SSH 클라이언트에서 사용 가능한지 확인합니다. 이 문제는 재부팅 후 또는 새 터미널 세션에서 자주 발생합니다.

## 오류: `SSH host keys are not available on this system.` {#error-ssh-host-keys-are-not-available-on-this-system}

GitLab이 호스트 SSH 키에 액세스할 수 없는 경우, `gitlab.example/help/instance_configuration`을(를) 방문하면 인스턴스 SSH 핑거프린트 대신 **SSh 호스트 키 핑거프린트** 헤더 아래에 다음 오류 메시지가 표시됩니다:

```plaintext
SSH host keys are not available on this system. Please use ssh-keyscan command or contact your GitLab administrator for more information.
```

이 오류를 해결하려면:

- Helm 차트(Kubernetes) 배포에서 `values.yaml`을(를) 업데이트하여 [`sshHostKeys.mount`](https://docs.gitlab.com/charts/charts/gitlab/webservice/)을(를) `true`(으)로 설정하고 `webservice` 섹션 아래에 배치합니다.
- GitLab Self-Managed 인스턴스에서 호스트 키에 대해 `/etc/ssh` 디렉터리를 확인합니다.

## 일반 SSH 문제 해결 {#general-ssh-troubleshooting}

이전 섹션이 문제를 해결하지 못하면 SSH 연결을 자세한 정보 모드로 실행합니다. 자세한 정보 모드는 연결에 대한 유용한 정보를 반환할 수 있습니다.

SSH를 자세한 정보 모드로 실행하려면 다음 명령을 사용하고 `gitlab.example.com`을(를) GitLab 인스턴스 URL로 바꿉니다:

```shell
ssh -Tvvv git@gitlab.example.com
```
