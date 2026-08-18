---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 배포
description: "배포, 롤백, 안전성 및 승인."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

코드 버전을 환경에 배포하면 배포를 생성합니다. 일반적으로 환경당 활성 배포는 한 개뿐입니다.

GitLab:

- 각 환경에 대한 배포의 전체 기록을 제공합니다.
- 배포를 추적하므로 항상 서버에 배포된 것을 알 수 있습니다.

프로젝트와 연결된 [Kubernetes](../../user/infrastructure/clusters/_index.md)와 같은 배포 서비스가 있으면 배포를 지원하는 데 사용할 수 있습니다.

배포가 생성된 후 사용자에게 롤아웃할 수 있습니다.

## 수동 배포 구성 {#configure-manual-deployments}

배포를 수동으로 시작하도록 요구하는 작업을 생성할 수 있습니다. 예를 들어:

```yaml
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
```

`when: manual` 작업:

- GitLab UI에서 작업에 대한 **실행** ({{< icon name="play" >}}) 버튼을 표시하고, **`<environment>`에 수동으로 배포할 수 있음**이라는 텍스트를 표시합니다.
- `deploy_prod` 작업을 수동으로 트리거해야 합니다.

**실행** ({{< icon name="play" >}}) 버튼을 파이프라인, 환경, 배포, 및 작업 보기에서 찾을 수 있습니다.

## 배포당 새로 포함된 머지 리퀘스트 추적 {#track-newly-included-merge-requests-per-deployment}

GitLab은 배포당 새로 포함된 머지 리퀘스트를 추적할 수 있습니다. 배포가 성공하면 시스템이 최신 배포와 이전 배포 간의 커밋 차이를 계산합니다. [배포 API](../../api/deployments.md#list-all-merge-requests-associated-with-a-deployment)를 사용하여 추적 정보를 가져오거나 [머지 리퀘스트 페이지](../../user/project/merge_requests/_index.md)의 병합 후 파이프라인에서 확인할 수 있습니다.

추적을 활성화하려면 환경을 다음 중 하나로 구성합니다:

- [환경 이름](../yaml/_index.md#environmentname)이 `/`이 있는 폴더를 사용하지 않습니다(수명이 긴 환경 또는 최상위 환경).
- [환경 티어](_index.md#deployment-tier-of-environments)는 `production` 또는 `staging` 중 하나입니다.

  `.gitlab-ci.yml`에서 [`environment` 키워드](../yaml/_index.md#environment)를 사용하는 구성 예시입니다:

  ```yaml
  # Trackable
  environment: production
  environment: production/aws
  environment: development

  # Non Trackable
  environment: review/$CI_COMMIT_REF_SLUG
  environment: testing/aws
  ```

구성 변경은 새 배포에만 적용됩니다. 기존 배포 레코드는 머지 리퀘스트를 연결하거나 연결 해제할 수 없습니다.

## 로컬에서 배포 확인 {#check-out-deployments-locally}

각 배포에 대해 Git 리포지토리에 참조가 저장되므로 현재 환경의 상태를 파악하기 위해 `git fetch`만 하면 됩니다.

Git 구성에서 `[remote "<your-remote>"]` 블록에 추가 가져오기 줄을 추가합니다:

```plaintext
fetch = +refs/environments/*:refs/remotes/origin/environments/*
```

## 이전 배포 아카이브 {#archive-old-deployments}

프로젝트에서 새 배포가 발생하면 GitLab이 [배포에 대한 특수 Git 참조](#check-out-deployments-locally)를 생성합니다. 이러한 Git 참조는 원격 GitLab 리포지토리에서 채워지므로 `git-fetch` 및 `git-pull`와 같은 일부 Git 작업이 프로젝트의 배포 수가 증가함에 따라 느려질 수 있습니다.

Git 작업의 효율성을 유지하기 위해 GitLab은 최근 배포 참조(최대 50,000개)만 유지하고 이전 배포 참조의 나머지를 삭제합니다. 아카이브된 배포는 UI 또는 API를 사용하여 감사 목적으로 계속 사용 가능합니다. 커밋 SHA를 지정하여 리포지토리에서 배포된 커밋을 계속 가져올 수 있습니다(예: `git checkout <deployment-sha>`). 아카이브 후에도 마찬가지입니다.

> [!note]
> GitLab은 모든 커밋을 [`keep-around` 참조](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)로 보존하므로 배포된 커밋이 가비지 수집되지 않습니다. 배포 참조에서 참조되지 않더라도 마찬가지입니다.

## 배포 롤백 {#deployment-rollback}

특정 커밋에서 배포를 롤백하면 새 배포가 생성됩니다. 이 배포는 자신의 고유한 작업 ID를 가집니다. 롤백하려는 커밋을 가리킵니다.

롤백이 성공하려면 배포 프로세스가 작업의 `script`에 정의되어야 합니다.

[배포 작업](../jobs/_index.md#deployment-jobs)만 실행됩니다. 이전 작업이 배포 시 재생성해야 하는 아티팩트를 생성하는 경우 파이프라인 페이지에서 필요한 작업을 수동으로 실행해야 합니다. 예를 들어 Terraform을 사용하고 `plan` 및 `apply` 명령이 여러 작업으로 분리되어 있으면 배포하거나 롤백하려면 작업을 수동으로 실행해야 합니다.

### 배포 재시도 또는 롤백 {#retry-or-roll-back-a-deployment}

배포에 문제가 있으면 다시 시도하거나 롤백할 수 있습니다.

배포를 재시도하거나 롤백하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. 환경을 선택합니다.
1. 배포 이름의 오른쪽:
   - 배포를 재시도하려면 **환경에 재배포**를 선택합니다.
   - 배포로 롤백하려면 이전에 성공한 배포 옆에서 **롤백 환경**을 선택합니다.

> [!note]
> 프로젝트에서 [이전 배포 작업을 방지](deployment_safety.md#prevent-outdated-deployment-jobs)한 경우 롤백 버튼이 숨겨지거나 비활성화될 수 있습니다. 이 경우 [롤백 배포를 위한 작업 재시도](deployment_safety.md#job-retries-for-rollback-deployments)를 참조하세요.

## 관련 항목 {#related-topics}

- [환경](_index.md)
- [배포를 위한 다운스트림 파이프라인](../pipelines/downstream_pipelines.md#downstream-pipelines-for-deployments)
- [GitLab CI/CD를 사용하여 여러 환경에 배포(블로그 게시물)](https://about.gitlab.com/blog/ci-deployment-and-environments/)
- [검토 앱](../review_apps/_index.md)
- [외부 배포 도구의 배포 추적](external_deployment_tools.md)

## 문제 해결 {#troubleshooting}

배포로 작업할 때 다음 이슈가 발생할 수 있습니다.

### 배포 참조를 찾을 수 없음 {#deployment-refs-are-not-found}

GitLab은 Git 리포지토리를 성능 있게 유지하기 위해 [이전 배포 참조를 삭제](#archive-old-deployments)합니다.

GitLab Self-Managed에서 아카이브된 Git 참조를 복원해야 하는 경우 관리자에게 Rails 콘솔에서 다음 명령을 실행하도록 요청합니다:

```ruby
Project.find_by_full_path(<your-project-full-path>).deployments.where(archived: true).each(&:create_ref)
```

GitLab은 성능상의 우려로 인해 향후 이 지원을 중단할 수 있습니다. [GitLab 이슈 추적기](https://gitlab.com/gitlab-org/gitlab/-/issues/new)에서 이슈를 열어 이 기능의 동작을 논의할 수 있습니다.
