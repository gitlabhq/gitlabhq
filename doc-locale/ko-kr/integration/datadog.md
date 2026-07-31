---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Datadog
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Datadog 통합을 사용하면 GitLab 프로젝트를 [Datadog](https://www.datadoghq.com/)에 연결하고, 리포지토리 메타데이터를 동기화하여 Datadog 원격 측정을 강화하고, Datadog에서 머지 리퀘스트에 주석을 달고, CI/CD 파이프라인 및 작업 정보를 Datadog에 보낼 수 있습니다.

## Datadog 계정 연결 {#connect-your-datadog-account}

**운영자** 역할이 있는 사용자는 전체 인스턴스 또는 특정 프로젝트나 그룹에 대한 통합을 구성할 수 있습니다:

1. Datadog API 키가 없는 경우:
   1. Datadog에 로그인합니다.
   1. **연동** 섹션으로 이동합니다.
   1. [APIs 탭](https://app.datadoghq.com/account/settings#api)에서 API 키를 생성합니다. 이 값을 복사합니다. 나중 단계에서 필요합니다.
1. *특정 프로젝트 또는 그룹의 통합의 경우:* GitLab에서 프로젝트 또는 그룹으로 이동합니다.
1. *전체 인스턴스의 통합의 경우:*
   1. 관리자 액세스 권한이 있는 사용자로 GitLab에 로그인합니다.
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **통합 추가**로 스크롤하고 **Datadog**을 선택합니다.
1. **활성**을 선택하여 통합을 활성화합니다.
1. 데이터를 보낼 [**Datadog site**](https://docs.datadoghq.com/getting_started/site/)를 지정합니다.
1. 선택 사항. 데이터를 직접 전송하는 데 사용되는 API URL을 재정의하려면 **API URL**을 제공합니다. 고급 시나리오에서만 사용됩니다.
1. Datadog **API 키**를 제공합니다.

## CI 가시성 구성 {#configure-ci-visibility}

선택적으로 [Datadog CI 가시성](https://www.datadoghq.com/product/ci-cd-monitoring/)을 활성화하여 CI/CD 파이프라인 및 작업 데이터를 Datadog에 보낼 수 있습니다. 이 기능을 사용하여 작업 실패 및 성능 문제를 모니터링하고 이슈를 해결합니다.

자세한 내용은 [Datadog CI 가시성 설명서](https://docs.datadoghq.com/continuous_integration/pipelines/?tab=gitlab)를 참조하세요.

> [!warning]
> Datadog CI 가시성은 커밋자당 가격이 책정됩니다. 이 기능을 사용하면 Datadog 청구서에 영향을 미칠 수 있습니다. 자세한 내용은 [Datadog 가격 페이지](https://www.datadoghq.com/pricing/?product=ci-pipeline-visibility#products)를 참조하세요.

이 기능은 [웹후크](../user/project/integrations/webhooks.md)를 기반으로 하며 GitLab에서만 구성이 필요합니다:

1. 선택 사항. **Enable Pipeline job logs collection**를 선택하여 작업 출력의 로그 수집을 활성화합니다. (GitLab 15.3에서 [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/346339).)
1. 선택 사항. 2개 이상의 GitLab 인스턴스를 사용하는 경우 GitLab 인스턴스를 구별하기 위해 고유한 **서비스** 이름을 제공합니다.
   <!-- vale gitlab_base.Spelling = NO -->
1. 선택 사항. GitLab 인스턴스 그룹(예: 스테이징 및 프로덕션 환경)을 사용하는 경우 **Env** 이름을 제공합니다. 이 값은 통합이 생성하는 각 범위에 첨부됩니다.
   <!-- vale gitlab_base.Spelling = YES -->
1. 선택 사항. 통합이 구성되고 있는 모든 범위에 대한 사용자 지정 태그를 정의하려면 **태그**에 한 줄에 하나의 태그를 입력합니다. 각 줄은 `key:value`의 형식이어야 합니다.
1. 선택 사항. **테스트 설정**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

통합이 데이터를 보낼 때 Datadog 계정의 [CI 가시성](https://app.datadoghq.com/ci) 섹션에서 이를 볼 수 있습니다.

## 관련 항목 {#related-topics}

- [Datadog CI 가시성 설명서](https://docs.datadoghq.com/continuous_integration/)
