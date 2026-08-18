---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Amazon Linux 2에서 Linux 패키지 설치
title: Amazon Linux 2에서 Linux 패키지 설치
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!note]
> [지원되는 플랫폼](_index.md#supported-platforms)에서 지원되는 배포판 및 아키텍처의 전체 목록을 확인하세요.

## 전제 조건 {#prerequisites}

- OS 요구 사항:
  - Amazon Linux 2
- 최소 하드웨어 요구 사항을 알아보려면 [설치 요구 사항](../requirements.md)을 참조하세요.
- 시작하기 전에 [DNS를 올바르게 설정](https://docs.gitlab.com/omnibus/settings/dns/)했는지 확인합니다. 다음 명령에서 `https://gitlab.example.com`를 원하는 GitLab URL로 바꿉니다. GitLab은 해당 주소에서 자동으로 구성되고 시작됩니다.
- `https://` URL의 경우 GitLab은 자동으로 [Let's Encrypt를 사용하여 인증서를 요청](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration)하며, 이는 인바운드 HTTP 액세스와 유효한 호스트 이름이 필요합니다. [자신의 인증서를 사용](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually)하거나 암호화되지 않은 URL의 경우 `http://`(접두사 `s` 제외)를 사용할 수 있습니다.
- Linux 패키지 및 기타 관련 메타데이터 파일은 Google Cloud Storage에서 저장되고 제공됩니다. 방화벽을 사용하는 경우 다음 URL 접두사에 대한 액세스를 허용해야 합니다. - `https://packages.gitlab.com/*` - `https://storage.googleapis.com/packages-ops/*`

## SSH 활성화 및 방화벽 포트 열기 {#enable-ssh-and-open-firewall-ports}

필요한 방화벽 포트(80, 443, 22)를 열고 GitLab에 액세스할 수 있도록 하려면:

1. OpenSSH 서버 데몬을 활성화하고 시작합니다:

   ```shell
   sudo systemctl enable --now sshd
   ```

1. `firewalld`이 설치되어 있으면 방화벽 포트를 엽니다:

   ```shell
   sudo firewall-cmd --permanent --add-service=http
   sudo firewall-cmd --permanent --add-service=https
   sudo firewall-cmd --permanent --add-service=ssh
   sudo systemctl reload firewalld
   ```

## GitLab 패키지 리포지토리 추가 {#add-the-gitlab-package-repository}

GitLab을 설치하려면 먼저 GitLab 패키지 리포지토리를 추가합니다.

1. 필요한 패키지를 설치합니다:

   ```shell
   sudo yum install -y curl
   ```

1. 다음 스크립트를 사용하여 GitLab 리포지토리를 추가합니다(브라우저에 스크립트의 URL을 붙여넣어 `bash`으로 파이핑하기 전에 수행할 작업을 확인할 수 있습니다):

   {{< tabs >}}

   {{< tab title="Enterprise Edition" >}}

   ```shell
   curl --location "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< tab title="Community Edition" >}}

   ```shell
   curl --location "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh" | sudo bash
   ```

   {{< /tab >}}

   {{< /tabs >}}

## 패키지 설치 {#install-the-package}

시스템의 패키지 관리자를 사용하여 GitLab을 설치합니다.

> [!note]
> `EXTERNAL_URL`를 설정하는 것은 선택적이지만 권장됩니다. 설치 중에 설정하지 않으면 [나중에 설정](https://docs.gitlab.com/omnibus/settings/configuration/#configure-the-external-url-for-gitlab)할 수 있습니다.

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

GitLab은 `/etc/gitlab/initial_root_password`에 저장된 루트 관리자 계정용 임의의 비밀번호와 이메일 주소를 24시간 동안 생성합니다. 24시간 후 보안상의 이유로 이 파일이 자동으로 삭제됩니다.

## 초기 로그인 {#initial-sign-in}

GitLab이 설치된 후 설정한 URL로 이동하여 다음 자격 증명을 사용하여 로그인합니다:

- 사용자 이름: `root`
- 비밀번호: `/etc/gitlab/initial_root_password`을 확인합니다.

로그인한 후 [비밀번호](../../user/profile/user_passwords.md#change-your-password)와 [이메일 주소](../../user/profile/_index.md#add-emails-to-your-user-profile)를 변경합니다.

## 고급 구성 {#advanced-configuration}

설치 전에 다음 선택적 환경 변수를 설정하여 GitLab 설치를 사용자 지정할 수 있습니다. **These variables only work during the first installation**하며 후속 재구성 실행에는 영향을 주지 않습니다. 기존 설치의 경우 `/etc/gitlab/initial_root_password`의 비밀번호를 사용하거나 [루트 비밀번호를 재설정](../../security/reset_user_password.md)합니다.

| 변수 | 목적 | 필수 | 예제 |
|----------|---------|----------|---------|
| `EXTERNAL_URL` | GitLab 인스턴스의 외부 URL을 설정합니다. | 권장 | `EXTERNAL_URL="https://gitlab.example.com"` |
| `GITLAB_ROOT_EMAIL` | 루트 관리자 계정의 사용자 지정 이메일 | 선택적 | `GITLAB_ROOT_EMAIL="admin@example.com"` |
| `GITLAB_ROOT_PASSWORD` | 루트 관리자 계정의 사용자 지정 비밀번호(최소 8자) | 선택적 | `GITLAB_ROOT_PASSWORD="strongpassword"` |

GitLab이 설치 중에 유효한 호스트 이름을 감지할 수 없으면 재구성이 자동으로 실행되지 않습니다. 이 경우 필요한 환경 변수를 첫 번째 `gitlab-ctl reconfigure` 명령으로 전달합니다.

> [!warning]
> `/etc/gitlab/gitlab.rb`에서 `gitlab_rails['initial_root_password']`를 설정하여 초기 비밀번호를 설정할 수도 있지만 권장되지 않습니다. 비밀번호가 평문이므로 보안 위험입니다. 이렇게 구성한 경우 설치 후 반드시 제거합니다.

GitLab 에디션을 선택하고 위의 환경 변수로 사용자 지정합니다:

{{< tabs >}}

{{< tab title="Enterprise Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ee
```

{{< /tab >}}

{{< tab title="Community Edition" >}}

```shell
sudo GITLAB_ROOT_EMAIL="admin@example.com" GITLAB_ROOT_PASSWORD="strongpassword" EXTERNAL_URL="https://gitlab.example.com" yum install gitlab-ce
```

{{< /tab >}}

{{< /tabs >}}

## 통신 기본 설정 구성 {#set-up-your-communication-preferences}

저희 [이메일 구독 기본 설정 센터](https://about.gitlab.com/company/preference-center/)를 방문하여 언제 통신할지 알려주세요. 저희는 명시적 이메일 옵트인 정책을 보유하고 있으므로 어떤 이메일을 얼마나 자주 보낼지에 대해 완전히 제어할 수 있습니다.

매월 두 번 저희는 새로운 기능, 통합, 문서 및 개발 팀의 비하인드 스토리를 포함하여 알아야 할 GitLab 뉴스를 보냅니다. 버그 및 시스템 성능과 관련된 중요 보안 업데이트를 받으려면 저희의 전용 보안 뉴스레터에 가입합니다.

> [!note]
> 보안 뉴스레터에 옵트인하지 않으면 보안 경고를 받지 않습니다.

## 권장되는 다음 단계 {#recommended-next-steps}

설치 완료 후 [권장되는 다음 단계(인증 옵션 및 새 사용자 계정 제한 포함)](../next_steps.md)를 고려합니다.
