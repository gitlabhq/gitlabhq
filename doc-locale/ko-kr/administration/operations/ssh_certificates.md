---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenSSH AuthorizedPrincipalsCommand을 사용한 사용자 조회
description: SSH 인증서 인증을 위해 승인된 주체(Principal)를 구성합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab Self-Managed 인스턴스의 기본 SSH 인증을 사용하려면 사용자가 SSH 공개 키를 먼저 업로드해야 SSH 전송을 사용할 수 있습니다.

회사 환경과 같은 중앙 집중식 환경에서는 이 요구사항이 운영 오버헤드를 발생시킬 수 있습니다. 특히 발급 후 24시간 내에 만료되는 SSH 키와 같이 SSH 키가 임시적인 경우 더욱 그렇습니다.

이런 경우 외부 자동화 프로세스가 지속적으로 새로운 키를 GitLab에 업로드해야 합니다.

> [!warning]
> OpenSSH 버전 6.9+ 이상이 필요합니다. `AuthorizedKeysCommand`가 지문을 허용할 수 있어야 하기 때문입니다. 서버의 OpenSSH 버전을 확인하세요.

OpenSSH 대신 `gitlab-sshd`을 사용하는 경우 OpenSSH를 요구하지 않고 `gitlab-sshd` 구성 파일에서 직접 인스턴스 수준의 SSH 인증서 인증을 구성할 수 있습니다. 자세한 내용은 [`gitlab-sshd`를 사용한 인스턴스 수준의 SSH 인증서](gitlab_sshd_ssh_certificates.md)를 참조하세요.

GitLab.com 그룹 소유자인 경우 GitLab SSH 서버를 사용하며 OpenSSH 구성을 요구하지 않는 그룹 범위의 SSH 인증서 기능을 사용해야 합니다. 자세한 내용은 [그룹 SSH 인증서 관리](../../user/group/ssh_certificates.md)를 참조하세요.

## OpenSSH 인증서를 사용하는 이유는 무엇입니까? {#why-use-openssh-certificates}

OpenSSH 인증서를 사용하면 키를 소유한 GitLab 사용자에 대한 정보가 키 자체에 인코딩됩니다. OpenSSH는 사용자가 개인 CA 서명 키에 액세스해야 하므로 사용자가 이를 위조할 수 없음을 보장합니다.

올바르게 설정하면 사용자 SSH 키를 GitLab에 업로드해야 한다는 요구사항이 완전히 제거됩니다.

## GitLab Shell을 통해 SSH 인증서 조회 설정 {#setting-up-ssh-certificate-lookup-via-gitlab-shell}

SSH 인증서를 완전히 설정하는 방법은 이 문서의 범위 밖입니다. [OpenSSH의 `PROTOCOL.certkeys`](https://cvsweb.openbsd.org/cgi-bin/cvsweb/src/usr.bin/ssh/PROTOCOL.certkeys?annotate=HEAD) 에서 작동 방식을 확인하거나, 예를 들어 [RedHat의 설명서](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-using_openssh_certificate_authentication)를 참조하세요.

SSH 인증서가 이미 설정되어 있고 CA의 `TrustedUserCAKeys`을 `sshd_config`에 추가했다고 가정합니다. 예를 들면:

```plaintext
TrustedUserCAKeys /etc/security/mycompany_user_ca.pub
```

일반적으로 `TrustedUserCAKeys`은 이러한 설정에서 `Match User git` 아래에 범위가 지정되지 않습니다. 왜냐하면 GitLab 서버 자체에 대한 시스템 로그인에도 사용되기 때문입니다. 하지만 설정은 다를 수 있습니다. CA가 GitLab에만 사용되는 경우 이 설정을 `Match User git` 섹션(아래에 설명)에 배치하는 것을 고려하세요.

해당 CA에서 발급한 SSH 인증서는 **must** GitLab의 해당 사용자 이름에 해당하는 "키 ID"를 가져야 합니다. 예를 들면 (간결함을 위해 일부 출력 생략):

```shell
$ ssh-add -L | grep cert | ssh-keygen -L -f -

(stdin):1:
        Type: ssh-rsa-cert-v01@openssh.com user certificate
        Public key: RSA-CERT SHA256:[...]
        Signing CA: RSA SHA256:[...]
        Key ID: "aearnfjord"
        Serial: 8289829611021396489
        Valid: from 2018-07-18T09:49:00 to 2018-07-19T09:50:34
        Principals:
                sshUsers
                [...]
        [...]
```

엄밀히 말하면 이것이 항상 참은 아닙니다. 예를 들어 일반적으로 `prod-aearnfjord` 사용자로 서버에 로그인하는 SSH 인증서인 경우 `prod-aearnfjord`일 수 있습니다. 하지만 이 경우 제공된 기본값을 사용하는 대신 매핑을 수행하기 위해 자신의 `AuthorizedPrincipalsCommand`을 지정해야 합니다.

중요한 부분은 `AuthorizedPrincipalsCommand`이 "키 ID"를 GitLab 사용자 이름으로 매핑할 수 있어야 한다는 것입니다. 제공되는 기본 명령은 둘 사이에 1=1 매핑이 있다고 가정하기 때문입니다. 이 전체 목적은 기본 공개 키-사용자 이름 매핑과 같은 것에 의존하는 대신 키 자체에서 GitLab 사용자 이름을 추출할 수 있게 하는 것입니다.

그런 다음 `sshd_config`에서 `git` 사용자를 위해 `AuthorizedPrincipalsCommand`을 설정합니다. 이상적으로 GitLab과 함께 제공되는 기본값을 사용할 수 있습니다:

```plaintext
Match User git
    AuthorizedPrincipalsCommandUser root
    AuthorizedPrincipalsCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-principals-check %i sshUsers
```

이 명령은 다음과 같은 출력을 내보냅니다:

```shell
command="/opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell username-{KEY_ID}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty {PRINCIPAL}
```

여기서 `{KEY_ID}`은 스크립트에 전달된 `%i` 인자입니다 (예: `aeanfjord`). `{PRINCIPAL}`은 이에 전달된 주체(Principal)입니다 (예: `sshUsers`).

`sshUsers` 부분을 사용자 정의해야 합니다. GitLab에 로그인할 수 있는 모든 사용자의 키에 포함되도록 보장되는 주체(Principal)이거나, 사용자에게 있는 주체(Principal) 목록 중 하나를 제공해야 합니다. 예를 들면:

```plaintext
    [...]
    AuthorizedPrincipalsCommand /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell-authorized-principals-check %i sshUsers windowsUsers
```

## 주체(Principal) 및 보안 {#principals-and-security}

원하는 만큼 많은 주체(Principal)를 제공할 수 있습니다. 이들은 `AuthorizedPrincipalsFile` 설명서에 설명된 대로 `authorized_keys` 출력의 여러 줄로 변환되며, 이는 `sshd_config(5)`에 있습니다.

일반적으로 OpenSSH와 함께 `AuthorizedKeysCommand`을 사용할 때 주체(Principal)는 해당 서버에 로그인할 수 있는 일종의 "그룹"입니다. 하지만 GitLab을 사용하면 OpenSSH의 요구사항을 충족하기 위해서만 사용되며, 실질적으로는 "키 ID"가 올바른지만 신경 쓰면 됩니다. 추출된 후 GitLab은 해당 사용자를 위해 자체 ACL을 적용합니다 (예: 사용자가 액세스할 수 있는 프로젝트).

따라서 승인하는 항목에 대해 과도하게 관대해도 됩니다. 예를 들어 사용자가 GitLab에 액세스하지 못하는 경우 잘못된 사용자에 대한 메시지가 포함된 오류가 발생합니다.

## `authorized_keys` 파일과의 상호작용 {#interaction-with-the-authorized_keys-file}

이전에 설명한 대로 SSH 인증서가 설정되어 있으면 `authorized_keys` 파일과 함께 사용할 수 있으므로 `authorized_keys` 파일이 폴백으로 작동합니다.

`AuthorizedPrincipalsCommand`이 사용자를 인증할 수 없으면 OpenSSH는 `~/.ssh/authorized_keys` 파일 확인 또는 `AuthorizedKeysCommand` 사용으로 되돌아갑니다. 따라서 SSH 인증서와 함께 [데이터베이스에서 승인된 SSH 키의 빠른 조회](fast_ssh_key_lookup.md)를 사용해야 할 수도 있습니다.

대부분의 사용자의 경우 SSH 인증서는 `AuthorizedPrincipalsCommand`을 사용하여 인증을 처리하며, `~/.ssh/authorized_keys` 파일은 주로 배포 키와 같은 특정 경우에 대한 폴백으로 작동합니다. 하지만 설정에 따라 일반 사용자를 위해 `AuthorizedPrincipalsCommand`만 사용하는 것으로 충분할 수 있습니다. 이러한 경우 `authorized_keys` 파일은 자동화된 배포 키 액세스 또는 기타 특정 시나리오에만 필요합니다.

`authorized_keys` 폴백을 유지 관리하는 것이 사용자 환경에 필요한지 여부를 결정하는 데 도움이 되도록 일반 사용자의 키 개수 (특히 자주 갱신되는 경우)와 배포 키 간의 균형을 고려하세요.

## 기타 보안 주의사항 {#other-security-caveats}

사용자는 여전히 SSH 공개 키를 프로필에 수동으로 업로드하고 `~/.ssh/authorized_keys` 폴백에 의존하여 SSH 인증서 인증을 우회할 수 있습니다.

사용자가 배포 키가 아닌 SSH 키 업로드를 방지하는 설정을 추가하기 위해 [미해결 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/23260)가 있습니다.

이 제한을 적용하는 확인을 직접 작성할 수 있습니다. 예를 들어 `gitlab-shell-authorized-keys-check`에서 반환된 발견된 키-ID가 배포 키인지 확인하는 사용자 정의 `AuthorizedKeysCommand`을 제공합니다 (배포되지 않은 모든 키는 거부되어야 함).

## SSH 키가 부족한 사용자에 대한 글로벌 경고 비활성화 {#disabling-the-global-warning-about-users-lacking-ssh-keys}

기본적으로 GitLab은 SSH 키를 프로필에 업로드하지 않은 사용자에게 "SSH를 통해 프로젝트 코드를 가져올 수 없거나 푸시할 수 없습니다."라는 경고를 표시합니다.

SSH 인증서를 사용할 때 사용자가 자신의 키를 업로드할 것으로 예상되지 않기 때문에 이는 역효과입니다.

이 경고를 전역적으로 비활성화하려면 "응용 프로그램 설정 -> 계정 및 제한 설정"으로 이동하여 "SSH 키 추가 사용자 메시지 표시" 설정을 비활성화합니다.

이 설정은 SSH 인증서와 함께 사용하기 위해 특별히 추가되었지만 다른 이유로 경고를 숨기고 싶으면 사용하지 않고도 해제할 수 있습니다.
