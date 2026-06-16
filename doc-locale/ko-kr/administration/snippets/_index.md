---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 인스턴스에 대한 스니펫 설정을 구성합니다.
title: 스니펫
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

인스턴스에서 스니펫 남용을 방지하려면 사용자가 스니펫을 생성하거나 업데이트할 때 적용되는 최대 스니펫 크기를 구성합니다. 기존 스니펫은 사용자가 스니펫을 업데이트하고 콘텐츠가 변경되지 않는 한 제한의 영향을 받지 않습니다.

기본 제한은 52428800바이트(50MB)입니다.

## 코드 조각 크기 제한 구성 {#configure-the-snippet-size-limit}

코드 조각 크기 제한을 구성하려면 Rails 콘솔 또는 [Application settings API](../../api/settings.md)를 사용하세요.

제한은 바이트 단위여야 합니다.

이 설정은 [**운영자** 영역 설정](../settings/_index.md)에서 사용할 수 없습니다.

### Rails 콘솔 사용 {#use-the-rails-console}

Rails 콘솔을 통해 이 설정을 구성하려면:

1. [Rails 콘솔 시작](../operations/rails_console.md#starting-a-rails-console-session)하세요.
1. 코드 조각 최대 파일 크기 업데이트:

   ```ruby
   ApplicationSetting.first.update!(snippet_size_limit: 50.megabytes)
   ```

현재 값을 검색하려면 Rails 콘솔을 시작하고 실행하세요:

  ```ruby
  Gitlab::CurrentSettings.snippet_size_limit
  ```

### API 사용 {#use-the-api}

Application Settings API를 사용하여 제한을 설정하려면 ([다른 설정 업데이트](../../api/settings.md#update-application-settings)와 유사하게) 다음 명령을 사용하세요:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/application/settings?snippet_size_limit=52428800"
```

API에서 [현재 값을 검색](../../api/settings.md#retrieve-details-on-current-application-settings)하려면:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/settings"
```

## 관련 항목 {#related-topics}

- [사용자 코드 조각](../../user/snippets.md)
