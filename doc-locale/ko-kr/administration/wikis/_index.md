---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 위키 설정
description: 위키 설정을 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab 인스턴스의 위키 설정을 조정합니다.

## 위키 페이지 콘텐츠 크기 제한 {#wiki-page-content-size-limit}

위키 페이지에 대한 최대 콘텐츠 크기 제한을 설정할 수 있습니다. 이 제한은 기능의 남용을 방지할 수 있습니다. 기본값은 **5242880 Bytes**(5MB)입니다.

### 어떻게 작동하나요? {#how-does-it-work}

콘텐츠 크기 제한은 GitLab UI 또는 API를 통해 위키 페이지를 생성하거나 업데이트할 때 적용됩니다. Git으로 푸시한 로컬 변경 사항은 유효성 검사되지 않습니다.

기존 위키 페이지를 손상시키지 않도록 제한은 위키 페이지를 다시 편집하고 콘텐츠가 변경될 때까지 적용되지 않습니다.

### 위키 페이지 콘텐츠 크기 제한 구성 {#wiki-page-content-size-limit-configuration}

이 설정은 [**운영자** 영역 설정](../settings/_index.md)을 통해 사용할 수 없습니다. 이 설정을 구성하려면 Rails 콘솔 또는 [애플리케이션 설정 API](../../api/settings.md)를 사용합니다.

> [!note]
> 제한 값은 바이트 단위여야 합니다. 최소값은 1024 바이트입니다.

#### Rails 콘솔을 통해 {#through-the-rails-console}

Rails 콘솔을 통해 이 설정을 구성하려면:

1. Rails 콘솔을 시작합니다:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. 위키 페이지 최대 콘텐츠 크기를 업데이트합니다:

   ```ruby
   ApplicationSetting.first.update!(wiki_page_max_content_bytes: 5.megabytes)
   ```

현재 값을 검색하려면 Rails 콘솔을 시작하고 실행합니다:

  ```ruby
  Gitlab::CurrentSettings.wiki_page_max_content_bytes
  ```

#### API를 통해 {#through-the-api}

Application Settings API를 통해 위키 페이지 크기 제한을 설정하려면 명령을 사용합니다. [다른 설정을 업데이트](../../api/settings.md#update-application-settings)하는 방법과 동일하게:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?wiki_page_max_content_bytes=5242880"
```

API를 사용하여 [현재 값을 검색](../../api/settings.md#retrieve-details-on-current-application-settings)할 수도 있습니다:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings"
```

### 위키 리포지토리 크기 줄이기 {#reduce-wiki-repository-size}

위키는 [네임스페이스 스토리지 크기](../settings/account_and_limit_settings.md)의 일부로 계산되므로 위키 리포지토리를 최대한 간결하게 유지해야 합니다.

리포지토리를 압축할 수 있는 도구에 대한 자세한 내용은 [리포지토리 크기 줄이기](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)에 대한 설명서를 참조합니다.

## AsciiDoc의 URI 포함 허용 {#allow-uri-includes-for-asciidoc}

{{< history >}}

- GitLab 16.1에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/348687).

{{< /history >}}

포함 지시문은 별도의 페이지 또는 외부 URL에서 콘텐츠를 가져와 현재 문서의 콘텐츠의 일부로 표시합니다. AsciiDoc 포함을 활성화하려면 Rails 콘솔 또는 API를 통해 기능을 활성화합니다.

### Rails 콘솔을 통해 {#through-the-rails-console-1}

Rails 콘솔을 통해 이 설정을 구성하려면:

1. Rails 콘솔을 시작합니다:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. 위키를 업데이트하여 AsciiDoc의 URI 포함을 허용합니다:

   ```ruby
   ApplicationSetting.first.update!(wiki_asciidoc_allow_uri_includes: true)
   ```

포함 항목이 활성화되어 있는지 확인하려면 Rails 콘솔을 시작하고 실행합니다:

  ```ruby
  Gitlab::CurrentSettings.wiki_asciidoc_allow_uri_includes
  ```

### API를 통해 {#through-the-api-1}

[애플리케이션 설정 API](../../api/settings.md#update-application-settings)를 통해 AsciiDoc의 URI 포함을 허용하도록 위키를 설정하려면 `curl` 명령을 사용합니다:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/application/settings?wiki_asciidoc_allow_uri_includes=true"
```

## 관련 항목 {#related-topics}

- [위키에 대한 사용자 설명서](../../user/project/wiki/_index.md)
- [프로젝트 위키 API](../../api/wikis.md)
- [그룹 위키 API](../../api/group_wikis.md)
