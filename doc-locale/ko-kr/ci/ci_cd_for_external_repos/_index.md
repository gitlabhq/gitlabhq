---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 리포지토리에 대한 CI/CD
description: "GitHub, Bitbucket 및 기타 외부 리포지토리와 함께 GitLab CI/CD를 사용합니다."
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD는 [GitHub](github_integration.md), [Bitbucket Cloud](bitbucket_integration.md) 또는 다른 Git 서버와 함께 사용할 수 있습니다. 일부 [알려진 이슈](#known-issues)가 있습니다.

전체 프로젝트를 GitLab으로 이동하는 대신, 외부 리포지토리를 연결하여 GitLab CI/CD의 이점을 얻을 수 있습니다.

외부 리포지토리를 연결하면 [리포지토리 미러링](../../user/project/repository/mirror/_index.md)이 설정되고 이슈, 머지 리퀘스트, wiki, snippet이 비활성화된 경량 프로젝트가 생성됩니다. 이러한 기능들은 [나중에 다시 활성화할 수 있습니다](../../user/project/settings/_index.md#configure-project-features-and-permissions).

## 외부 리포지토리에 연결 {#connect-to-an-external-repository}

외부 리포지토리에 연결하려면:

1. 오른쪽 상단 모서리에서 **새로 만들기** ({{< icon name="plus" >}}) 및 **새 프로젝트/리포지토리**를 선택합니다.
1. **외부 리포지토리에 대한 CI/CD 실행**을 선택합니다.
1. **GitHub** 또는 **리포지토리 URL**을 선택합니다.
1. 필드를 완성하세요.

**외부 리포지토리에 대한 CI/CD 실행** 옵션을 사용할 수 없는 경우:

- GitLab 인스턴스에 구성된 가져오기 원본이 없을 수 있습니다. 관리자에게 [가져오기 원본 구성](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)을 확인하도록 요청합니다.
- [프로젝트 미러링](../../user/project/repository/mirror/_index.md)이 비활성화되어 있을 수 있습니다. 비활성화된 경우 관리자만 **외부 리포지토리에 대한 CI/CD 실행** 옵션을 사용할 수 있습니다. 관리자에게 [프로젝트 미러링 구성](../../administration/settings/visibility_and_access_controls.md#enable-project-mirroring)을 확인하도록 요청합니다.

## 외부 Pull Request에 대한 파이프라인 {#pipelines-for-external-pull-requests}

GitHub의 [외부 리포지토리](github_integration.md)와 함께 GitLab CI/CD를 사용할 때 Pull Request의 컨텍스트에서 파이프라인을 실행할 수 있습니다.

GitHub의 원격 브랜치에 변경 사항을 푸시하면 GitLab CI/CD는 브랜치에 대한 파이프라인을 실행할 수 있습니다. 그러나 해당 브랜치에 대한 Pull Request를 열거나 업데이트할 때 다음을 원할 수 있습니다:

- 추가 작업을 실행합니다.
- 특정 작업을 실행하지 않습니다.

예를 들어:

```yaml
always-run:
  script: echo 'this should always run'

on-pull-requests:
  script: echo 'this should run on pull requests'
  rules:
    - if: $CI_PIPELINE_SOURCE == "external_pull_request_event"

except-pull-requests:
  script: echo 'This should not run for pull requests, but runs in other cases.'
  rules:
    - if: $CI_PIPELINE_SOURCE == "external_pull_request_event"
      when: never
    - when: on_success
```

### 외부 Pull Request에 대한 파이프라인 실행 {#pipeline-execution-for-external-pull-requests}

GitHub에서 리포지토리를 가져올 때 GitLab은 `push` 및 `pull_request` 이벤트에 대한 웹후크를 구독합니다. `pull_request` 이벤트가 수신되면 Pull Request 데이터가 저장되고 참조로 유지됩니다. Pull Request가 방금 생성되었다면 GitLab은 즉시 외부 pull request에 대한 파이프라인을 생성합니다.

Pull Request에서 참조하는 브랜치에 변경 사항이 푸시되고 Pull Request가 아직 열려 있으면 외부 pull request에 대한 파이프라인이 생성됩니다.

이 경우 GitLab CI/CD는 2개의 파이프라인을 생성합니다. 브랜치 푸시에 대한 하나와 외부 pull request에 대한 하나입니다.

Pull Request가 닫힌 후에는 같은 브랜치에 새로운 변경 사항이 푸시되더라도 외부 pull request에 대한 파이프라인이 생성되지 않습니다.

### 추가 사전 정의된 변수 {#additional-predefined-variables}

외부 pull request에 대한 파이프라인을 사용함으로써 GitLab은 추가 [사전 정의된 변수](../variables/predefined_variables.md)를 파이프라인 작업에 노출합니다.

변수 이름은 `CI_EXTERNAL_PULL_REQUEST_`으로 시작합니다.

### 알려진 이슈 {#known-issues}

이 기능은 다음을 지원하지 않습니다:

- GitHub Enterprise에 필요한 [수동 연결 방법](github_integration.md#connect-manually)입니다. 통합이 수동으로 연결된 경우 외부 pull request는 [파이프라인을 트리거하지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/323336#note_884820753).
- 포크 리포지토리에서의 Pull Request입니다. [포크 리포지토리의 Pull Request는 무시됩니다](https://gitlab.com/gitlab-org/gitlab/-/issues/5667).

GitLab이 2개의 파이프라인을 생성하기 때문에, 열려 있는 Pull Request를 참조하는 원격 브랜치에 변경 사항이 푸시되면 두 파이프라인이 모두 GitHub 통합을 통해 Pull Request의 상태에 기여합니다. 외부 pull request에서만 파이프라인을 실행하고 브랜치에서는 실행하지 않으려면 작업 사양에 `except: [branches]`을 추가할 수 있습니다. [자세히 알아보기](https://gitlab.com/gitlab-org/gitlab/-/issues/24089#workaround).

## 문제 해결 {#troubleshooting}

- [끌어오기 미러링이 파이프라인을 트리거하지 않습니다](../../user/project/repository/mirror/troubleshooting.md#pull-mirroring-is-not-triggering-pipelines).
- [미러링 시 하드 오류 수정](../../user/project/repository/mirror/pull.md#fix-hard-failures-when-mirroring).
