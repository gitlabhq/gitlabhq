---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Gravatar, Libravatar 또는 사용자 지정 서비스를 사용하여 사용자 프로필용 아바타 서비스를 설정합니다."
title: GitLab에서 Libravatar 서비스 사용
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 기본적으로 [Gravatar](https://gravatar.com) 아바타 서비스를 지원합니다.

Libravatar는 아바타(프로필 사진)를 다른 웹사이트에 전달하는 또 다른 서비스입니다. Libravatar API는 [Gravatar를 기반으로 설계](https://wiki.libravatar.org/api/)되었으므로 Libravatar 아바타 서비스 또는 자신의 Libravatar 서버로 전환할 수 있습니다.

## Libravatar 서비스를 자신의 서비스로 변경 {#change-the-libravatar-service-to-your-own-service}

[`gitlab.yml` gravatar 섹션](https://gitlab.com/gitlab-org/gitlab/-/blob/68dac188ec6b1b03d53365e7579422f44cbe7a1c/config/gitlab.yml.example#L469-476)에서 다음과 같이 구성 옵션을 설정합니다:

Linux 패키지 설치의 경우:

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['gravatar_enabled'] = true
   #### For HTTPS
   gitlab_rails['gravatar_ssl_url'] = "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   #### Use this line instead for HTTP
   # gitlab_rails['gravatar_plain_url'] = "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   ```

1. 변경 사항을 적용하려면 `sudo gitlab-ctl reconfigure`을 실행합니다.

자체 컴파일 설치의 경우:

1. `config/gitlab.yml`을(를) 편집합니다:

   ```yaml
     gravatar:
       enabled: true
       # default: https://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon
       plain_url: "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
       # default: https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon
       ssl_url: "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   ```

1. 파일을 저장한 후 [다시 시작](restart_gitlab.md#self-compiled-installations)하여 GitLab 변경 사항이 적용되도록 합니다.

## Libravatar 서비스를 기본값(Gravatar)으로 설정 {#set-the-libravatar-service-to-default-gravatar}

Linux 패키지 설치의 경우:

1. `gitlab_rails['gravatar_ssl_url']` 또는 `gitlab_rails['gravatar_plain_url']`를 `/etc/gitlab/gitlab.rb`에서 삭제합니다.
1. 변경 사항을 적용하려면 `sudo gitlab-ctl reconfigure`을 실행합니다.

자체 컴파일 설치의 경우:

1. `gravatar:` 섹션을 `config/gitlab.yml`에서 제거합니다.
1. 파일을 저장한 후 [다시 시작](restart_gitlab.md#self-compiled-installations)하여 GitLab 변경 사항을 적용합니다.

## Gravatar 서비스 사용 안 함 {#disable-gravatar-service}

Gravatar를 사용 안 함으로 설정하려면(예: 타사 서비스를 금지하려면) 다음 단계를 완료합니다:

Linux 패키지 설치의 경우:

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['gravatar_enabled'] = false
   ```

1. 변경 사항을 적용하려면 `sudo gitlab-ctl reconfigure`을 실행합니다.

자체 컴파일 설치의 경우:

1. `config/gitlab.yml`을(를) 편집합니다:

   ```yaml
     gravatar:
       enabled: false
   ```

1. 파일을 저장한 후 [다시 시작](restart_gitlab.md#self-compiled-installations)하여 GitLab 변경 사항을 적용합니다.

### 자신의 Libravatar 서버 {#your-own-libravatar-server}

[자신의 Libravatar 서비스를 실행](https://wiki.libravatar.org/running_your_own/)하는 경우 구성에서 URL은 다르지만 GitLab이 URL을 올바르게 구문 분석할 수 있도록 동일한 자리 표시자를 제공해야 합니다.

예를 들어 `https://libravatar.example.com`에서 서비스를 호스팅하고 `gitlab.yml`에 제공해야 하는 `ssl_url`은 다음과 같습니다:

`https://libravatar.example.com/avatar/%{hash}?s=%{size}&d=identicon`

## 누락된 이미지의 기본 URL {#default-url-for-missing-images}

[Libravatar는 다양한 세트](https://wiki.libravatar.org/api/)를 지원하며 이는 Libravatar 서비스에서 찾을 수 없는 사용자 이메일 주소에 대한 누락된 이미지를 제공합니다.

`identicon` 이외의 세트를 사용하려면 URL의 `&d=identicon` 부분을 지원되는 다른 세트로 바꿉니다. 예를 들어 `retro` 세트를 사용할 수 있으며, 이 경우 URL은 `ssl_url: "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=retro"`처럼 보입니다.

## Microsoft Office 365 사용 예 {#usage-examples-for-microsoft-office-365}

사용자가 Office 365 사용자인 경우 `GetPersonaPhoto` 서비스를 사용할 수 있습니다. 이 서비스는 로그인이 필요하므로 이 사용 사례는 모든 사용자가 Office 365에 액세스할 수 있는 엔터프라이즈 설치에서 가장 유용합니다.

```ruby
gitlab_rails['gravatar_plain_url'] = 'http://outlook.office.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
gitlab_rails['gravatar_ssl_url'] = 'https://outlook.office.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
```
