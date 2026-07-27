---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 상대 URL에서 GitLab 설치
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 상태:  베타

{{< /details >}}

> [!warning]
> GitLab의 상대 URL 구성은 [Geo와의 알려진 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/456427)가 있으며 [테스트 제한](https://gitlab.com/gitlab-org/gitlab/-/issues/439943)이 있습니다. 상대 URL을 이미 사용 중이고 서브도메인으로 마이그레이션하려면 [마이그레이션 가이드](../administration/operations/migrate_to_subdomain.md)를 참조하세요.

GitLab을 자체 (서브)도메인에 설치해야 하지만, 여러 이유로 인해 때때로 불가능할 수 있습니다. 이 경우 GitLab을 상대 URL에 설치할 수도 있습니다(예: `https://example.com/gitlab`).

이 문서는 소스에서 설치한 경우 상대 URL에서 GitLab을 실행하는 방법을 설명합니다. 소스에서 설치하지 않는 경우 상대 URL을 활성화하려면 [Linux 패키지](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-relative-url-for-gitlab) 또는 [GitLab 차트](https://docs.gitlab.com/charts/charts/globals/#configure-a-relative-url-root)의 상대 URL 설명서를 확인하세요.

처음 GitLab을 설치하는 경우 이 가이드를 [설치 가이드](self_compiled/_index.md)와 함께 사용하세요.

상대 URL이 얼마나 깊게 중첩될 수 있는지에 제한이 없습니다. 예를 들어 `/foo/bar/gitlab/git` 아래에서 GitLab을 제공할 수 있으며 이슈가 없습니다.

기존 GitLab 설치의 URL을 변경하면 모든 원격 URL이 변경되므로 GitLab 인스턴스를 가리키는 로컬 리포지토리에서 수동으로 편집해야 합니다.

상대 URL에서 GitLab을 제공하기 위해 변경해야 하는 구성 파일 목록입니다:

- `/home/git/gitlab/config/initializers/relative_url.rb`
- `/home/git/gitlab/config/gitlab.yml`
- `/home/git/gitlab/config/puma.rb`
- `/home/git/gitlab-shell/config.yml`
- `/etc/default/gitlab`

모든 변경 후 자산을 재컴파일하고 [GitLab을 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)해야 합니다.

## 상대 URL 요구 사항 {#relative-url-requirements}

상대 URL을 사용하여 GitLab을 구성하는 경우 자산(JavaScript, CSS, 글꼴 및 이미지 포함)을 재컴파일해야 하며, 이는 많은 CPU 및 메모리 리소스를 소비할 수 있습니다. 메모리 부족 오류를 방지하려면 컴퓨터에 최소 2GB의 RAM을 사용할 수 있어야 합니다. 이상적으로는 4GB RAM과 4개 또는 8개의 CPU 코어를 가지고 있어야 합니다.

자세한 내용은 [요구 사항](requirements.md) 문서를 참조하세요.

## GitLab에서 상대 URL 활성화 {#enable-relative-url-in-gitlab}

> [!note]
> 상대 URL과 관련하여 웹 서버 구성 파일을 변경하지 마세요. 상대 URL 지원은 GitLab Workhorse에서 구현됩니다.

---

이 프로세스는 다음을 가정합니다:

- GitLab은 `/gitlab` 아래에서 제공됩니다.
- GitLab이 설치된 디렉터리는 `/home/git/`입니다.

GitLab에서 상대 URL을 활성화하려면:

1. 선택 사항. 리소스가 부족하면 다음 명령으로 GitLab 서비스를 종료하여 일부 메모리를 임시로 확보할 수 있습니다:

   ```shell
   sudo service gitlab stop
   ```

1. `/home/git/gitlab/config/initializers/relative_url.rb`을 만듭니다.

   ```shell
   cp /home/git/gitlab/config/initializers/relative_url.rb.sample \
      /home/git/gitlab/config/initializers/relative_url.rb
   ```

   다음 줄을 변경하세요:

   ```ruby
   config.relative_url_root = "/gitlab"
   ```

1. `/home/git/gitlab/config/gitlab.yml`을 편집하고 다음 줄을 주석 해제/변경하세요:

   ```yaml
   relative_url_root: /gitlab
   ```

1. `/home/git/gitlab/config/puma.rb`을 편집하고 다음 줄을 주석 해제/변경하세요:

   ```ruby
   ENV['RAILS_RELATIVE_URL_ROOT'] = "/gitlab"
   ```

1. `/home/git/gitlab-shell/config.yml`을 편집하고 다음 줄에 상대 경로를 추가하세요:

   ```yaml
   gitlab_url: http://127.0.0.1/gitlab
   ```

1. [설치 가이드](self_compiled/_index.md#install-the-service)에 설명된 대로 제공된 systemd 서비스 또는 초기화 스크립트와 기본값 파일을 복사했는지 확인하세요. 그런 다음 `/etc/default/gitlab`을 편집하고 `gitlab_workhorse_options`에서 `-authBackend` 설정이 다음과 같이 읽히도록 설정하세요:

   ```shell
   -authBackend http://127.0.0.1:8080/gitlab
   ```

   > [!note]
   > 사용자 지정 초기화 스크립트를 사용하는 경우 필요에 따라 이전 GitLab Workhorse 설정을 편집해야 합니다.

1. [GitLab을 다시 시작](../administration/restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

## GitLab에서 상대 URL 비활성화 {#disable-relative-url-in-gitlab}

상대 URL을 비활성화하려면:

1. `/home/git/gitlab/config/initializers/relative_url.rb`을 제거합니다.
1. 이전 단계부터 2번부터 시작하여 상대 경로를 포함하지 않는 GitLab URL을 설정하세요.
