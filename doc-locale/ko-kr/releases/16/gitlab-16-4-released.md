---
stage: Release Notes
group: Monthly Release
date: 2023-09-22
title: "GitLab 16.4 릴리스 정보"
description: "사용자 지정 역할을 포함하여 릴리스된 GitLab 16.4"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023년 9월 22일에 GitLab 16.4가 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Kik {#this-months-notable-contributor-kik}

Kik은 GitLab의 ActivityPub 지원 설계 및 구현 시작에 중요한 역할을 했습니다. 그의 원본 상세 아키텍처 계획은 제품 팀에서 수용되었으며 이제 GitLab 프로젝트에서 [에픽](https://gitlab.com/groups/gitlab-org/-/epics/11247)으로 존재합니다. [첫 번째 머지 리퀘스트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127023)가 최근 머지되었고, 뒤이어 [문서 추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130960)가 진행되었습니다.

이 큰 기능에 대한 지원이 증가함에 따라 Kik은 협업, 반복 및 투명성의 [GitLab 가치](https://handbook.gitlab.com/handbook/values/)의 구현이 되었습니다!

Kik은 7년 이상 GitLab 커뮤니티의 일부로 [첫 번째 이슈](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/4037#note_4651432)를 기록했습니다. 그는 지난 몇 달 동안 좀 더 활동적이 되기로 선택했습니다. 기여에 대해 물었을 때 그는 다음과 같이 말했습니다:

> 강조할 것이 있다면, 아마도 GitLab이 얼마나 가능하게 해주는지, 소스 코드를 볼 수 있게 하고 그것으로 작업할 수 있게 하며, 얼마나 야심차든 기여를 환영하는지입니다. :)

그는 또한 스왕 대신 자신의 이름으로 [나무를 심도록](https://tree-nation.com/trees/view/5119567) 선택하여 우리의 지속 가능성 노력을 개척하는 데 도움을 주기로 선택했습니다. 🌳

Kik님, GitLab을 구축하고 우리의 놀라운 커뮤니티의 일부가 되기로 선택해주셔서 감사합니다! 🙌

## 주요 기능 {#primary-features}

### 사용자 지정 역할 {#customizable-roles}

<!-- categories: User Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/permissions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/393235)

{{< /details >}}

그룹 소유자 또는 관리자는 이제 역할 및 권한 메뉴의 UI를 사용하여 사용자 지정 역할을 만들고 제거할 수 있습니다. 사용자 지정 역할을 만들려면 기존 [기본 역할](../../user/permissions.md#roles) 위에 [권한](../../user/permissions.md)을 추가합니다. 현재 기본 역할에 추가할 수 있는 권한의 수는 제한되어 있으며, [세분화된 보안 권한](https://docs.gitlab.com/#granular-security-permissions), 머지 리퀘스트 승인 능력 및 코드 보기 능력을 포함합니다. 각 마일스톤에서 기존 권한에 추가하여 사용자 지정 역할을 만들 수 있는 새로운 권한이 릴리스됩니다.

### 비공개 프로젝트에 대한 워크스페이스 만들기 {#create-workspaces-for-private-projects}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/workspace/_index.md#personal-access-token)

{{< /details >}}

이전에는 비공개 프로젝트에 대해 [워크스페이스를 만들](../../user/workspace/configuration.md) 수 없었습니다. 비공개 프로젝트를 복제하려면 워크스페이스를 생성한 후에만 인증할 수 있었습니다.

GitLab 16.4를 사용하면 공개 또는 비공개 프로젝트에 대한 워크스페이스를 만들 수 있습니다. 워크스페이스를 만들 때 워크스페이스에서 사용할 개인 액세스 토큰을 얻습니다. 이 토큰을 사용하면 비공개 프로젝트를 복제하고 추가 구성이나 인증 없이 Git 작업을 수행할 수 있습니다.

### GitLab 사용자 ID를 사용하여 로컬에서 클러스터 접근 {#access-clusters-locally-using-your-gitlab-user-identity}

<!-- categories: Environment Management, User Profile -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/clusters/agent/user_access.md#access-a-cluster-with-the-kubernetes-api) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11235)

{{< /details >}}

개발자에게 Kubernetes 클러스터에 대한 액세스를 허용하려면 개발자 클라우드 계정 또는 타사 인증 도구가 필요합니다. 이는 클라우드 ID 및 액세스 관리의 복잡성을 증가시킵니다. 이제 GitLab ID와 Kubernetes 에이전트만을 사용하여 개발자에게 Kubernetes 클러스터에 대한 액세스 권한을 부여할 수 있습니다. 기존 Kubernetes RBAC를 사용하여 클러스터 내의 인증을 관리합니다.

GitLab 파이프라인의 [OIDC 클라우드 인증](../../ci/cloud_services/_index.md) 제공과 함께 이 기능들은 GitLab 사용자가 전용 클라우드 계정 없이 클라우드 리소스에 액세스할 수 있게 하며 보안과 규정을 손상시키지 않습니다.

이 클러스터 액세스의 첫 번째 반복에서는 [Kubernetes 구성을 수동으로 관리](../../user/clusters/agent/user_access.md)해야 합니다. [에픽 11455](https://gitlab.com/groups/gitlab-org/-/epics/11455)는 관련 명령으로 GitLab CLI를 확장하여 설정을 단순화할 것을 제안합니다.

### 그룹/서브그룹 수준 종속성 목록 {#groupsub-group-level-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_list/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/8090)

{{< /details >}}

종속성 목록을 검토할 때 전체 보기를 갖는 것이 중요합니다. 모든 프로젝트에서 종속성을 감시하려는 대규모 조직의 경우 프로젝트 수준에서 종속성을 관리하는 것이 문제가 됩니다. 이번 릴리스를 통해 프로젝트 또는 그룹 수준에서 서브그룹을 포함한 모든 종속성을 볼 수 있습니다. 이 기능은 이제 기본적으로 사용 가능합니다.

### 취약성 대량 상태 업데이트 {#vulnerability-bulk-status-updates}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerability_report/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/4649)

{{< /details >}}

일부 취약성은 대량으로 해결해야 합니다. 거짓 긍정이거나 더 이상 감지되지 않든, 소음을 최소화하고 취약성을 쉽게 분류하는 것이 중요합니다. 이 릴리스를 사용하면 그룹 또는 프로젝트 취약성 보고서에서 여러 취약성에 대한 상태를 대량으로 변경하고 주석을 달 수 있습니다.

### 세분화된 보안 권한 {#granular-security-permissions}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/permissions.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10684)

{{< /details >}}

일부 조직은 보안 팀에 [최소 권한 원칙](https://en.wikipedia.org/wiki/Principle_of_least_privilege)을 준수할 수 있도록 최소한의 필요한 액세스 권한을 부여하려고 합니다. 보안 팀은 코드 업데이트를 작성할 수 없어야 하지만 머지 리퀘스트 승인, 취약성 보기 및 취약성 상태 업데이트를 할 수 있어야 합니다.

GitLab은 이제 사용자가 [보고자](../../user/permissions.md) 역할의 액세스를 기반으로 [사용자 지정 역할을 만들](../../user/permissions.md) 수 있게 하지만 다음의 추가 권한이 있습니다:

- 종속성 목록 보기 (`read_dependency`).
- 보안 대시보드 및 취약성 보고서 보기 (`read_vulnerability`).
- 머지 리퀘스트 승인 (`admin_merge_request`).
- 취약성의 상태 변경 (`admin_vulnerability`).

이 [지원 중단 항목](../../update/deprecations.md#deprecate-change-vulnerability-status-from-the-developer-role)에 나와 있듯이 17.0의 모든 티어에서 개발자 역할에서 취약성 상태를 변경하는 기능을 제거할 계획입니다. 이 제안된 변경에 대한 피드백은 [이슈 424688](https://gitlab.com/gitlab-org/gitlab/-/issues/424668)에서 공유할 수 있습니다.

### 빠른 전진 머지 병합 트레인 지원 {#fast-forward-merge-support-for-merge-trains}

<!-- categories: Merge Trains -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/pipelines/merge_trains.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/4911)

{{< /details >}}

[빠른 전진 머지](../../user/project/merge_requests/methods/_index.md#fast-forward-merge)는 머지 커밋을 피하지만 더 많은 리베이싱을 필요로 하는 일반적이고 인기 있는 머지 방법입니다. 별도로, 머지 트레인은 메인 브랜치로 자주 머지하는 것과 관련된 더 큰 도전 과제를 해결하는 데 도움이 되는 강력한 도구입니다. 불행하게도 이 릴리스 이전에는 머지 트레인과 빠른 전진 머지를 함께 사용할 수 없었습니다.

이 릴리스에서는 자체 관리 관리자가 이제 같은 프로젝트에서 빠른 전진 머지와 머지 트레인을 모두 활성화할 수 있습니다. 머지 트레인의 모든 이점을 얻을 수 있으며, 이는 모든 커밋이 머지되기 전에 함께 작동하도록 보장하며, 빠른 전진 머지의 깔끔한 커밋 이력으로도 가능합니다!

빠른 전진 머지 트레인을 활성화하려면 기능 플래그 `fast_forward_merge_trains_support`을(를) 찾아서 기본적으로 비활성화되어 있고 활성화합니다.

### `id_token`을(를) 전역으로 설정하고 개별 작업에 대한 구성 제거 {#set-id_token-globally-and-eliminate-configuration-for-individual-jobs}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#id_tokens) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/419750)

{{< /details >}}

GitLab 15.9에서 우리는 [JSON 웹 토큰의 이전 버전 지원 중단](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)을 `id_token` 대신에 발표했습니다. 불행하게도 이 변경을 수용하기 위해 작업을 개별적으로 수정해야 했습니다. `id_token`로의 부드러운 전환을 가능하게 하기 위해 GitLab 16.4부터 `id_tokens`을(를) `.gitlab-ci.yml`의 전역 기본값으로 설정할 수 있습니다. 이 기능은 모든 작업에 대해 자동으로 `id_token` 구성을 설정합니다. OpenID Connect (OIDC) 인증을 사용하는 작업은 더 이상 별도의 `id_token`을(를) 설정하도록 요구하지 않습니다.

[`id_token`과(와) OIDC를 사용하여 타사 서비스로 인증](../../ci/secrets/id_token_authentication.md)합니다. 필수 `aud` 하위 키워드는 JWT의 `aud` 클레임을 구성하는 데 사용됩니다.

## 규모 및 배포 {#scale-and-deployments}

### Elasticsearch 인덱스 무결성이 이제 일반적으로 사용 가능 {#elasticsearch-index-integrity-now-generally-available}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../integration/advanced_search/elasticsearch.md#index-integrity) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/214601)

{{< /details >}}

GitLab 16.4를 사용하면 모든 GitLab 사용자가 Elasticsearch 인덱스 무결성을 사용할 수 있습니다. 인덱스 무결성은 누락된 리포지토리 데이터를 감지하고 수정하는 데 도움이 됩니다. 이 기능은 그룹 또는 프로젝트로 범위가 지정된 코드 검색이 결과를 반환하지 않을 때 자동으로 사용됩니다.

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.4는 [OpenSUSE 15.5](https://en.opensuse.org/Release_announcement_15.5)에 대한 패키지를 포함합니다.

### 추가되거나 취소된 이모지 반응에 대한 웹후크 추가 {#add-webhooks-for-added-or-revoked-emoji-reactions}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhook_events.md#emoji-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/290773)

{{< /details >}}

가능한 한 많은 자동화 및 타사 시스템과의 통합 기회를 제공하기 위해 사용자가 이모지 반응을 추가하거나 취소할 때 트리거되는 웹후크를 만드는 지원을 추가했습니다.

예를 들어 새 웹후크를 사용하여 사용자가 이모지로 이슈 또는 머지 리퀘스트에 반응할 때 이메일을 보낼 수 있습니다.

### API를 사용하여 사용자 지정 역할 이름 및 설명 만들기 {#create-custom-role-name-and-description-using-api}

<!-- categories: System Access -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/member_roles.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/416751)

{{< /details >}}

사용자 지정 역할을 만들 때 멤버 역할 API를 사용하여 이름(필수)과 설명(선택 사항)을 추가할 수 있습니다. 기존의 모든 사용자 지정 역할에는 `Custom` 이름이 지정되었으며, API를 사용하여 사용자 지정 역할의 이름을 원하는 이름으로 변경할 수 있습니다.

### 그룹 언급에 대한 Slack 알림 트리거 {#trigger-slack-notifications-for-group-mentions}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/gitlab_slack_application.md#trigger-notifications-for-group-mentions) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/417751)

{{< /details >}}

GitLab은 특정 GitLab 이벤트에 대해 Slack 작업 공간 채널로 메시지를 보낼 수 있습니다. 이 릴리스를 사용하면 이제 다음의 공개 및 비공개 컨텍스트에서 그룹 언급에 대해 [Slack 알림](../../user/project/integrations/gitlab_slack_application.md#notification-events)을 트리거할 수 있습니다:

- 이슈 및 머지 리퀘스트 설명
- 이슈, 머지 리퀘스트 및 커밋에 대한 주석

### 응용 프로그램 설정에서 사용 가능한 구성 가능한 가져오기 제한 확장 {#expand-configurable-import-limits-available-in-application-settings}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/import_and_export_settings.md#timeout-for-decompressing-archived-files) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/421432)

{{< /details >}}

최근에 몇 가지 하드코딩된 가져오기 제한을 구성 가능한 응용 프로그램 설정으로 변환하여 자체 관리 GitLab 관리자가 필요에 따라 이러한 제한을 조정할 수 있게 했습니다.

이 릴리스에서는 보관 파일 압축 해제 시간 초과를 구성 가능한 응용 프로그램 설정으로 추가했습니다.

이 제한은 210초로 하드코딩되었습니다. GitLab.com 및 자체 관리 설치의 경우 기본적으로 이 제한을 210초로 설정했습니다. 자체 관리 GitLab 및 GitLab.com 관리자 모두 필요에 따라 이 제한을 조정할 수 있습니다.

### Service Desk용 사용자 지정 이메일 주소 {#custom-email-address-for-service-desk}

<!-- categories: Service Desk -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/service_desk/configure.md#custom-email-address) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/329990)

{{< /details >}}

Service Desk는 비즈니스와 고객 간의 가장 의미 있는 연결 중 하나입니다. 이제 Service Desk에서 이메일을 보내고 받기 위해 자신의 사용자 지정 이메일 주소를 사용할 수 있습니다. 이 변경으로 브랜드 ID를 유지하고 고객이 올바른 엔티티와 통신하고 있다는 확신을 심어주기가 훨씬 더 쉬워졌습니다.

이 기능은 베타입니다. 베타 기능을 시도하고 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/416637)에서 피드백을 제공하기를 권장합니다.

### Geo는 이제 Cloud Native Hybrid 사이트에서 통합 URL을 지원합니다 {#geo-supports-unified-urls-on-cloud-native-hybrid-sites}

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/geo/secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites) \| [관련 에픽](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3522)

{{< /details >}}

Geo는 이제 [Cloud Native Hybrid](../../administration/reference_architectures/_index.md#cloud-native-hybrid) 사이트에서 통합 URL을 지원하며, 이는 Cloud Native Hybrid 사이트가 기본 사이트와 단일 외부 URL을 공유할 수 있음을 의미합니다. 이는 단일 공통 URL을 사용하여 위치에 따라 최적의 Geo 보조 사이트로 자동으로 이동할 수 있는 원격 팀을 위한 원활한 GitLab UI 및 Git 개발자 환경을 제공합니다. 이 업데이트를 통해 통합 URL은 이제 모든 GitLab 참조 아키텍처에서 지원됩니다.

### Geo는 객체 스토리지를 검증합니다 {#geo-verifies-object-storage}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/geo/replication/object_storage.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/8056)

{{< /details >}}

Geo는 [객체 스토리지 복제가 GitLab에서 관리](../../administration/geo/replication/object_storage.md#enabling-gitlab-managed-object-storage-replication)될 때 객체 스토리지를 검증하는 기능을 추가합니다. 객체 스토리지 데이터 손상을 방지하기 위해 Geo는 기본 및 보조 사이트 간의 파일 크기를 비교합니다. Geo가 재해 복구 전략의 일부이고 GitLab 관리 객체 스토리지 복제를 활성화하면 데이터 손실을 방지합니다. 또한 보조 사이트에 이미 존재할 수 있는 데이터를 복사해야 하는 필요성을 줄입니다. 예를 들어 기존 기본 사항을 보조 사이트로 다시 추가할 때입니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 다운스트림 파이프라인에서 `environment` 키워드 지원 {#support-for-environment-keyword-in-downstream-pipelines}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/pipelines/downstream_pipelines.md#downstream-pipelines-for-deployments) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/369061)

{{< /details >}}

CI/CD 파이프라인 작업에서 다운스트림 파이프라인을(를) 트리거해야 하는 경우 `trigger` 키워드를 사용할 수 있습니다. 배포 관리를 향상하기 위해 이제 `environment` 키워드를 사용할 때 `trigger` 키워드로 환경을 지정할 수 있습니다. 예를 들어 `main` 브랜치에서 `/web-app` 프로젝트에 대한 다운스트림 파이프라인을(를) 트리거할 수 있으며 환경 이름 `dev` 및 지정된 환경 URL을 사용할 수 있습니다.

이전에 CI 및 CD에 대한 별도의 파이프라인을(를) 실행하고 `trigger` 키워드를 사용하여 CD 파이프라인을(를) 시작할 때 환경 세부 정보를 지정할 수 없었습니다. 이는 CI 프로젝트에서 배포를 추적하기 어렵게 했습니다. 환경에 대한 지원 추가는 프로젝트 간에 배포 추적을 단순화합니다.

### 사용자가 적용된 보안 정책에 대한 브랜치 예외를 정의할 수 있도록 허용 {#allow-users-to-define-branch-exceptions-to-enforced-security-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9567)

{{< /details >}}

보안 정책은 GitLab 프로젝트에서 스캔을 실행하도록 적용하고 보안 및 규정 준수를 보장하기 위해 MR 확인/승인도 적용합니다. 브랜치 예외를 통해 정책을 더 세분화하여 적용할 수 있으며 범위를 벗어나는 주어진 브랜치에 대한 적용을 제외할 수 있습니다. 개발자가 번거로운 적용의 영향을 받는 개발 또는 테스트 브랜치를 만드는 경우 보안 팀과 협력하여 보안 정책 내에서 브랜치를 제외할 수 있습니다.

스캔 실행 정책의 경우 [파이프라인](../../user/application_security/policies/scan_execution_policies.md#pipeline-rule-type) 또는 [일정](../../user/application_security/policies/scan_execution_policies.md#schedule-rule-type) 규칙 유형에 대한 예외를 구성할 수 있습니다. 스캔 결과 정책의 경우 [scan_finding](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type) 또는 [license_finding](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type) 규칙 유형에 대해 브랜치 예외를 지정할 수 있습니다.

### 만료되는 액세스 토큰에 대한 알림 {#notifications-for-expiring-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../security/tokens/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/367705)

{{< /details >}}

그룹 및 프로젝트 액세스 토큰은 자동화에 자주 사용됩니다. 관리자 및 그룹 소유자에게 이 토큰 중 하나가 만료에 가까워졌을 때 알려지는 것이 중요하므로 중단을 피할 수 있습니다. 관리자 및 그룹 소유자는 이제 토큰이 만료되기 7일 이상 남았을 때 알림 이메일을 받습니다.

### 액세스가 만료될 때 이메일 알림 {#email-notification-when-access-expires}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/group/_index.md#add-users-to-a-group) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/12704)

{{< /details >}}

사용자는 그룹 또는 프로젝트 액세스가 만료되기 7일 전에 이메일 알림을 받습니다. 이는 액세스 만료 날짜가 설정된 경우에만 적용됩니다. 이전에는 액세스가 만료되었을 때 알림이 없었습니다. 미리 알림은 GitLab 관리자에게 연락하여 지속적인 액세스를 보장할 수 있음을 의미합니다.

### 브라우저 기반 DAST 활성 확인 22.1이 기본적으로 활성화됩니다 {#browser-based-dast-active-check-221-is-enabled-by-default}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dast/browser/checks/_index.md#active-checks) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/392718)

{{< /details >}}

브라우저 기반 DAST 활성 확인 22.1이 기본적으로 활성화되었습니다. ZAP 확인 6을 대체하며, 이는 비활성화되었습니다. 확인 22.1은 "경로 순회"라고 하는 "경로를 제한된 디렉터리로 제한하지 못함"을 식별하며, URL 끝점의 매개 변수에 페이로드를 삽입하여 악용될 수 있으므로 임의의 파일을 읽을 수 있습니다.

### 운영 컨테이너 스캔을 위한 비공개 레지스트리 지원 {#private-registry-support-for-operational-container-scanning}

<!-- categories: Container Scanning -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/vulnerabilities.md#scanning-private-images) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415451)

{{< /details >}}

[운영 컨테이너 스캔](../../user/clusters/agent/vulnerabilities.md)은 이제 비공개 컨테이너 레지스트리에서 이미지에 액세스하고 스캔할 수 있습니다. OCS는 이미지 가져오기 암호를 사용하여 비공개 레지스트리 컨테이너에 액세스합니다.

### pnpm lockfile v6.1에 대한 종속성 및 라이선스 스캔 지원 {#dependency-and-license-scanning-support-for-pnpm-lockfile-v61}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/413903)

{{< /details >}}

[Weyert de Boer](https://gitlab.com/weyert-tapico)의 커뮤니티 기여 덕분에 GitLab 종속성 및 라이선스 스캔은 이제 v6.1 lockfile 형식을 사용하여 pnpm 프로젝트 분석을 지원합니다.

### SAST 분석기 업데이트 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/analyzers.md) \| [관련 이슈](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST는 [많은 보안 분석기](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)를 포함하며, GitLab Static Analysis 팀은 적극적으로 유지보수하고 업데이트하며 지원합니다. 우리는 16.4 릴리스 마일스톤 동안 다음 업데이트를 발표했습니다:

- KICS 기반 분석기를 KICS 스캔 도구 버전 1.7.7로 업데이트했습니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md?ref_type=heads#v415)를 참조하세요.
- Sobelow 기반 분석기를 Sobelow 스캔 도구 버전 0.13.0으로 업데이트했습니다. 또한 분석기의 기본 이미지를 Elixir 1.13으로 업데이트하여 최신 Elixir 릴리스와의 호환성을 개선했습니다. [변경 로그](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/blob/master/CHANGELOG.md?ref_type=heads#v421)를 참조하세요
- PMD Apex 기반 분석기를 PMD 스캔 도구 버전 6.55.0으로 업데이트했습니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/blob/master/CHANGELOG.md?ref_type=heads#v413)를 참조하세요.
- `Security.Misc.IncludeMismatch` 규칙을 제거하도록 PHPCS 보안 감사 기반 분석기를 변경했습니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit/-/blob/master/CHANGELOG.md?ref_type=heads#v411)를 참조하세요.
- Semgrep 기반 분석기에서 사용되는 규칙을 업데이트하여 규칙 오류를 수정하고, 규칙 설명에서 끊어진 링크를 수정하고, 같은 규칙 ID를 가진 Java 및 Scala 규칙 간의 충돌을 해결했습니다. 또한 사용자 지정 규칙 파일의 최대 크기를 10 MB로 늘렸습니다. 자세한 내용은 [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md?ref_type=heads#v4412)를 참조하세요.

[GitLab 관리 SAST 템플릿을 포함](../../user/application_security/sast/_index.md)하고([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) GitLab 16.0 이상을 실행하면 이러한 업데이트를 자동으로 받습니다. 특정 버전의 분석기를 유지하고 자동 업데이트를 방지하려면 [버전을 고정](../../user/application_security/sast/_index.md)할 수 있습니다.

이전 변경사항은 [지난 달 업데이트](https://about.gitlab.com/releases/2023/08/22/gitlab-16-3-released/#sast-analyzer-updates)를 참조하세요.

### 개선된 SAST 취약성 추적 {#improved-sast-vulnerability-tracking}

<!-- categories: SAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/373921)

{{< /details >}}

GitLab SAST [고급 취약성 추적](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)은 코드가 이동함에 따라 결과를 추적하여 심사를 더 효율적으로 만듭니다.

GitLab 16.4에서는 새로운 언어 및 분석기에 대해 고급 취약성 추적을 활성화했습니다. [기존 범위](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)를 제외하고 고급 추적은 이제 다음에 대해 사용 가능합니다:

- SpotBugs 기반 SAST 분석기의 Java.
- PHPCS 보안 감사 기반 SAST 분석기의 PHP.

이는 이전의 확장 및 개선 사항 [GitLab 16.3에서 릴리스](https://about.gitlab.com/releases/2023/08/22/gitlab-16-3-released/#improved-sast-vulnerability-tracking)를 기반으로 합니다. 우리는 [에픽 5144](https://gitlab.com/groups/gitlab-org/-/epics/5144)에서 추가 개선 사항을 추적하고 있습니다.

이 변경 사항은 GitLab SAST의 [업데이트된 버전](https://docs.gitlab.com/#sast-analyzer-updates) [분석기](../../user/application_security/sast/analyzers.md)에 포함됩니다. 프로젝트가 업데이트된 분석기로 스캔된 후 프로젝트의 취약성 결과는 새로운 추적 서명으로 업데이트됩니다. [SAST 분석기를 특정 버전으로 고정](../../user/application_security/sast/_index.md)하지 않은 한 이 업데이트를 받기 위해 조치를 취할 필요가 없습니다.

### 파이프라인 특정 CycloneDX SBOM 내보내기 {#pipeline-specific-cyclonedx-sbom-exports}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/dependency_list_export.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/333463)

{{< /details >}}

CI 파이프라인에서 감지된 모든 구성 요소를 나열하는 CycloneDX SBOM을 다운로드할 수 있는 API를 추가했습니다. 여기에는 응용 프로그램 수준 종속성과 시스템 수준 종속성이 포함됩니다.

### 유지관리자 역할이 있는 사용자는 러너 세부 정보를 볼 수 있습니다 {#users-with-the-maintainer-role-can-view-runner-details}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/permissions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/384179)

{{< /details >}}

그룹의 유지관리자 역할을 가진 사용자는 이제 그룹 러너의 세부 정보를 볼 수 있습니다. 이 역할을 가진 사용자는 그룹 러너를 보고 사용 가능한 러너를 빠르게 결정하거나 자동으로 생성된 러너가 그룹 네임스페이스에 성공적으로 등록되었는지 확인할 수 있습니다.

### macOS 13 (Ventura) macOS 이미지(SaaS 러너용) {#macos-13-ventura-image-for-saas-runners-on-macos}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../ci/runners/hosted_runners/macos.md#supported-macos-images) \| [관련 이슈](https://gitlab.com/gitlab-org/ci-cd/shared-runners/infrastructure/-/issues/101)

{{< /details >}}

팀은 이제 macOS 13에서 Apple 생태계용 애플리케이션을 무결하게 만들고, 테스트하고 배포할 수 있습니다.

macOS의 SaaS 러너를 사용하면 GitLab CI/CD와 통합된 안전한 온디맨드 GitLab 러너 빌드 환경에서 macOS가 필요한 애플리케이션을 빌드하고 배포할 때 개발 팀의 속도를 높일 수 있습니다.

### GitLab 러너 16.4 {#gitlab-runner-164}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

우리는 또한 오늘 GitLab 러너 16.4를 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [러너 Prometheus 메트릭 끝점에 큐 기간 히스토그램 메트릭 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36627)

#### 버그 수정 {#bug-fixes}

- [GitLab 러너 16.3.0에서 정리되지 않은 Kubernetes 러너 포드](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36803)
- [`gitlab-runner-helper` 캐시 다운로드 중에 종료됨](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27984)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-4-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.4)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.4)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.4)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
