---
stage: Release Notes
group: Monthly Release
date: 2023-10-22
title: "GitLab 16.5 릴리스 정보"
description: "GitLab 16.5는 규정 준수 표준 준수 보고서와 함께 릴리스됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023년 10월 22일에 GitLab 16.5가 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Thorben Westerhuys {#this-months-notable-contributor-thorben-westerhuys}

Thorben은 [24시간 형식으로 시간을 표시하는 사용자 기본 설정을 추가하는](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130789) 머지 리퀘스트에서의 진행 중인 작업으로 인정받았습니다. 이 기능은 16.6에서 계획되었으며 사용자에게 12시간과 24시간 시간 형식 중에서 선택할 수 있는 옵션을 제공합니다.

GitLab의 제품 관리자인 Magdalena Frankiewicz는 Thorben을 지명했으며 이 기능의 이슈가 190개 이상의 업보트와 함께 7년 동안 열려있었음을 언급했습니다. GitLab의 스태프 백엔드 엔지니어인 Peter Leitzen은 [시간 형식과 관련된 백엔드 코드를 리팩토링하는](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130794) Thorben의 작업도 강조했습니다.

Thorben은 높은 해상도의 지리 데이터를 함께 제공하는 3D 웹 플랫폼인 LUUCY의 CTO입니다. 그는 도시 계획과 관련된 주제에 대한 지역 공간 데이터 컨설팅 회사인 cividi의 전직 CTO입니다.

Thorben과 GitLab 커뮤니티의 나머지 일원들의 기여에 감사합니다 🙌

## 주요 기능 {#primary-features}

### 규정 준수 표준 준수 보고서 {#compliance-standards-adherence-report}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

규정 준수 센터에는 이제 표준 준수 보고서를 위한 새로운 탭이 포함되어 있습니다. 이 보고서는 초기에 GitLab 모범 사례 표준을 포함하며, 그룹의 프로젝트가 표준에 포함된 점검 요구 사항을 충족하지 못할 때를 표시합니다. 초기에 표시되는 세 가지 점검은:

- 승인 규칙이 MR에서 최소 2명의 승인자를 요구하도록 존재함
- 승인 규칙이 MR 작성자가 머지하는 것을 허용하지 않도록 존재함
- 승인 규칙이 MR의 커미터가 머지하는 것을 허용하지 않도록 존재함

보고서에는 프로젝트별로 각 점검의 상태에 대한 세부 정보가 포함되어 있습니다. 점검이 마지막으로 실행된 시간, 점검이 적용되는 표준, 보고서에 표시될 수 있는 모든 오류나 문제를 해결하는 방법도 표시됩니다. 향후 반복은 더 많은 점검을 추가하고 더 많은 규정 및 표준을 포함하는 범위를 확장할 것입니다. 또한 조직에 가장 중요한 프로젝트나 표준에 집중할 수 있도록 보고서를 그룹화하고 필터링하기 위한 개선 사항을 추가할 계획입니다.

### 머지 리퀘스트의 대상 브랜치를 설정하기 위한 규칙 생성 {#create-rules-to-set-target-branches-for-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/repository/branches/_index.md#configure-workflows-for-target-branches)

{{< /details >}}

일부 프로젝트는 개발을 위해 `develop` 및 `qa`와 같은 여러 장기 브랜치를 사용합니다. 이러한 프로젝트에서는 프로젝트의 프로덕션 상태를 나타내기 때문에 `main`를 기본 브랜치로 유지하고 싶을 수 있습니다. 하지만 개발 작업은 머지 리퀘스트가 `develop` 또는 `qa`를 대상으로 하기를 기대합니다. 대상 브랜치 규칙은 머지 리퀘스트가 프로젝트 및 개발 워크플로우에 적합한 브랜치를 대상으로 하도록 도움이 됩니다.

머지 리퀘스트를 생성할 때 규칙은 브랜치의 이름을 확인합니다. 브랜치 이름이 규칙과 일치하면 머지 리퀘스트는 규칙에서 지정한 브랜치를 대상으로 사전 선택합니다. 브랜치 이름이 일치하지 않으면 머지 리퀘스트는 프로젝트의 기본 브랜치를 대상으로 합니다.

### 이슈 스레드 해결 {#resolve-an-issue-thread}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/discussions/_index.md#resolve-a-thread) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)

{{< /details >}}

많은 스레드가 있는 장기 실행 이슈는 읽고 추적하기 어려울 수 있습니다. 이제 토론 주제가 결론에 도달했을 때 이슈의 스레드를 해결할 수 있습니다.

### 반선형 히스토리를 사용한 빠른 머지 트레인 {#fast-forward-merge-trains-with-semi-linear-history}

<!-- categories: Merge Trains -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/pipelines/merge_trains.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/26996)

{{< /details >}}

16.4에서 [빠른 머지 트레인](https://about.gitlab.com/releases/2023/09/22/gitlab-16-4-released/#fast-forward-merge-support-for-merge-trains)을 릴리스했으며, 계속해서 모든 [머지 방법](../../user/project/merge_requests/methods/_index.md)을 지원하고 싶습니다. 이제 반선형 커밋 히스토리를 유지하고 싶다면 반선형 빠른 머지 트레인을 사용할 수 있습니다.

## 규모 및 배포 {#scale-and-deployments}

### 고급 검색으로 에픽 찾기 {#find-epics-with-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/search/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/250699)

{{< /details >}}

GitLab의 에픽 인기도는 계속 증가하고 있습니다. 이전에는 에픽을 찾기가 다른 콘텐츠 유형보다 약간 더 어려웠습니다. 이 릴리스에서는 고급 검색을 사용할 때 에픽을 검색하고 결과를 볼 수 있습니다.

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.5 `.deb` Linux 패키지가 [gzip에서 xz 압축으로 전환](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8197)되어 더 작은 패키지 크기가 생성됩니다. 이 변경으로 인해 설치 중에 압축 해제 시간이 느려질 수 있습니다.
- GitLab 16.5에는 [Mattermost 9.0](https://docs.mattermost.com/install/self-managed-changelog.html#release-v9-0-major-release)이 포함되어 있습니다. 이 버전은 사용되지 않는 Insights 기능을 제거하고 [Mattermost Boards 및 다양한 플러그인이 커뮤니티 지원으로 전환](https://forum.mattermost.com/t/upcoming-product-changes-to-boards-and-various-plugins/16669)되었습니다.
- GitLab 16.5는 [GitLab SELinux 정책 모듈을 이동](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/7165)시켜 `/opt/gitlab/embedded/selinux/rhel/7/`에서 `/opt/gitlab/embedded/selinux`로 변경하여 모듈이 RHEL 7용만이 아님을 반영합니다.

### Jira 개발 패널의 머지 리퀘스트의 검토자 정보 {#reviewer-information-for-merge-requests-in-the-jira-development-panel}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../integration/jira/development_panel.md#information-displayed-in-the-development-panel) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/364273)

{{< /details >}}

[Jira Cloud용 GitLab 앱](../../integration/jira/connect-app.md)을 사용하면 GitLab과 Jira Cloud를 연결하여 실시간으로 개발 정보를 동기화할 수 있습니다. Jira 개발 패널에서 이 정보를 볼 수 있습니다. 이전에는 검토자가 머지 리퀘스트에 할당되었을 때 검토자 정보가 Jira 개발 패널에 표시되지 않았습니다. 이 릴리스에서는 Jira Cloud용 GitLab 앱을 사용할 때 검토자 이름, 이메일 및 승인 상태가 Jira 개발 패널에 표시됩니다.

### 컨텍스트 변경이 이제 더 쉬워졌습니다 {#changing-context-just-got-easier}

<!-- categories: Navigation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

왼쪽 사이드바에서 검색 버튼을 찾기 어렵고 프로젝트 및 기본 설정과 같은 항목 간에 변경하기 어렵다는 피드백을 받았습니다. 이 릴리스에서는 버튼을 더 눈에 띄게 만들었습니다. 이렇게 하면 검색 가능성이 향상되고 워크플로우가 단일 터치 포인트로 간소화됩니다.

**Search or go to…** 버튼을 선택하거나 / 또는 s를 입력하여 키보드 단축키로 시도할 수 있습니다.

### 릴리스가 삭제될 때 웹후크가 이제 트리거됨 {#webhook-now-triggered-when-a-release-is-deleted}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhook_events.md#release-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/418113)

{{< /details >}}

릴리스 이벤트를 사용하여 릴리스 객체를 모니터링하고 변경 사항에 반응할 수 있습니다. 이전에는 웹후크가 릴리스가 생성 또는 업데이트될 때만 트리거되었습니다. 규제가 많은 산업에서는 릴리스 삭제가 모니터링되고 후속 조치되어야 하는 중요한 이벤트입니다. GitLab 16.5에서 릴리스가 삭제될 때 웹후크가 이제 트리거됩니다.

### 재설계된 Service Desk 이슈 목록 {#redesigned-service-desk-issues-list}

<!-- categories: Service Desk -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/service_desk/using_service_desk.md)

{{< /details >}}

Service Desk 이슈 목록을 더 빠르고 부드럽게 로드하도록 재설계했습니다. 이제 일반 이슈 목록과 더 밀접하게 일치합니다. 사용 가능한 기능은 다음과 같습니다:

- 이슈 목록의 동일한 정렬 및 순서 지정 옵션입니다.
- OR 연산자 및 이슈 ID로 필터링을 포함한 동일한 필터입니다.

### Geo는 모든 구성 요소에 대한 대량 재동기화 및 재검증 버튼을 추가합니다 {#geo-adds-bulk-resync-and-reverify-buttons-for-all-components}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/geo/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/8212)

{{< /details >}}

이제 Geo 관리 UI의 버튼을 통해 Geo에서 관리하는 모든 데이터 구성 요소에 대해 대량 재동기화 또는 재검증을 트리거할 수 있습니다. 버튼을 선택하면 해당 구성 요소와 관련된 모든 데이터 항목에 작업이 적용됩니다. 이전에는 Rails 콘솔에 로그인해야만 가능했습니다. 이러한 작업은 이제 더 접근 가능하며, 저장 위치 이동과 같이 전체 재동기화 또는 특정 구성 요소의 재검증이 필요한 대규모 변경을 사항 및 적용하는 경험이 개선되었습니다.

### 클라우드에서 리포지토리 데이터 백업 및 복원 {#back-up-and-restore-repository-data-in-the-cloud}

<!-- categories: Gitaly, Backup/Restore of GitLab instances -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/backup_restore/backup_gitlab.md#create-server-side-repository-backups) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10826)

{{< /details >}}

GitLab 백업 및 복원 기능은 이제 객체 저장소에 리포지토리 데이터를 저장하는 것을 지원합니다. 이 업데이트는 적절한 위치에 수동으로 저장해야 하는 대용량 tarball을 생성하는 데 사용되는 중간 단계를 제거하여 성능을 개선합니다.

이 업데이트를 통해 리포지토리 백업은 선택한 객체 저장소 위치(Amazon S3, Google Cloud Storage, Azure Cloud Data Storage, MinIO 등)에 저장됩니다. 이 변경은 Gitaly 인스턴스에서 데이터를 수동으로 이동할 필요를 제거합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 배포 승인 및 승인 규칙 변경 사항을 감사 이벤트에 통합 {#integrate-deployment-approval-and-approval-rule-changes-into-audit-events}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/audit_event_types.md#environment-management) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415603)

{{< /details >}}

규제 산업의 배포는 규정 준수의 중심 주제입니다. 이전 릴리스에서는 배포 승인이 감사 이벤트의 일부가 아니었으므로 승인 규칙이 언제 어떻게 변경되었는지 알기 어려웠습니다.

GitLab은 이제 배포 승인 및 승인 규칙 변경 사항에 대한 새로운 감사 이벤트 세트를 제공합니다. 이 이벤트는 배포 승인 규칙이 변경되거나 보호 환경에 대한 승인 규칙이 변경될 때 발생합니다.

### API를 사용하여 사용자의 SAML 및 SCIM ID 삭제 {#use-the-api-to-delete-a-users-saml-and-scim-identities}

<!-- categories: User Management -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../api/scim.md#delete-a-single-scim-identity) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/423592)

{{< /details >}}

이전에는 그룹 소유자가 SAML 또는 SCIM ID를 프로그래밍 방식으로 삭제할 수 없었습니다. 이로 인해 사용자 프로비저닝 및 로그인 프로세스의 이슈를 해결하기 어려웠습니다. 이제 그룹 소유자는 새로운 엔드포인트를 사용하여 이러한 ID를 삭제할 수 있습니다.

기여해 주신 [jgao1025](https://gitlab.com/jgao1025)님께 감사합니다!

### 규정 준수 위반 보고서 내보내기 {#export-the-compliance-violations-report}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

규정 준수 위반 보고서에는 많은 정보가 포함될 수 있습니다. 이전에는 GitLab UI에서만 정보를 볼 수 있었습니다. 개별 이슈의 경우에는 좋지만 예를 들어 다음이 필요한 경우 까다로울 수 있습니다:

- 릴리스를 위한 현재 규정 준수 상태의 아티팩트를 생성합니다. 예를 들어 감사자에게 위반이 0개였음을 증명합니다.
- 데이터를 다른 데이터 세트와 집계하거나 다른 도구에서 처리합니다.

GitLab 16.5에서는 이제 규정 준수 위반 보고서에 포함된 항목 목록을 CSV 형식으로 내보낼 수 있습니다.

### 새로운 사용자 지정 가능한 권한 {#new-customizable-permissions}

<!-- categories: User Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/17364)

{{< /details >}}

그룹 멤버 및 프로젝트 액세스 토큰을 관리할 수 있는 사용자 지정 권한이 사용자 지정 역할 프레임워크에 추가되었습니다. 이러한 사용자 지정 권한을 모든 기본 역할에 추가하여 사용자 지정 역할을 생성할 수 있습니다. 특정 작업 집합을 완수하는 데 필요한 사용자 지정 권한만으로 사용자 지정 역할을 생성하면 사용자에게 유지 관리자 및 소유자와 같이 매우 높은 권한이 있는 역할을 불필요하게 할당할 필요가 없습니다.

### Google Cloud Logging에 대한 인스턴스 수준 감사 이벤트 스트리밍 {#instance-level-audit-event-streaming-to-google-cloud-logging}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/compliance/audit_event_reports.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11061)

{{< /details >}}

이전에는 Google Cloud Logging에 대해 최상위 그룹 스트리밍 감사 이벤트만 구성할 수 있었습니다.

GitLab 16.5에서는 Google Cloud Logging에 대한 지원을 인스턴스 수준 스트리밍 대상으로 확장했습니다.

### 구성 가능한 잠금 사용자 정책 {#configurable-locked-user-policy}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../security/unlock_user.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/27048)

{{< /details >}}

관리자는 이제 실패한 로그인 시도 횟수와 사용자가 잠금되는 기간을 선택하여 인스턴스에 대한 잠금 사용자 정책을 구성할 수 있습니다. 예를 들어 5번의 실패한 로그인 시도는 사용자를 60분 동안 잠금합니다. 이렇게 하면 관리자가 보안 및 규정 준수 요구 사항을 충족하는 잠금 사용자 정책을 정의할 수 있습니다. 이전에는 로그인 시도 횟수와 잠금 사용자 시간 기간을 구성할 수 없었습니다.

### 스트리밍 감사 이벤트의 헤더 활성화 및 비활성화 {#activate-and-deactivate-headers-for-streaming-audit-events}

<!-- categories: Audit Events -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/compliance/audit_event_reports.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/11109)

{{< /details >}}

이전에는 감사 이벤트 스트리밍 대상에 추가된 HTTP 헤더를 일시적으로 비활성화하고 싶어도 삭제해야 했습니다.

GitLab 16.5에서는 GitLab UI의 **활성** 확인란을 사용하여 각 헤더를 개별적으로 켜고 끌 수 있습니다. 이를 다음과 같이 사용할 수 있습니다:

- 다양한 헤더를 테스트합니다.
- 헤더를 일시적으로 비활성화합니다.
- 동일한 헤더의 두 버전 사이를 전환합니다.

### 현재 인증된 사용자를 위한 개인 액세스 토큰 생성 API {#api-to-create-pat-for-currently-authenticated-user}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../api/users.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/425171)

{{< /details >}}

이제 `user/personal_access_tokens`의 새로운 REST API 엔드포인트를 사용하여 현재 인증된 사용자를 위한 새 개인 액세스 토큰을 생성할 수 있습니다. 이 토큰의 범위는 보안상의 이유로 `k8s_proxy`로 제한되므로 Kubernetes용 에이전트를 사용하여 Kubernetes API 호출만 수행할 수 있습니다. 이전에는 인스턴스 관리자만 [API를 통해 개인 액세스 토큰을 생성](../../api/users.md)할 수 있었습니다.

### 취약성 보고서 상태 및 심각도로 그룹화 {#vulnerability-report-grouping-by-status-and-severity}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/vulnerability_report/_index.md#group-vulnerabilities) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10164)

{{< /details >}}

사용자는 취약성을 보다 효율적으로 분류할 수 있도록 취약성을 그룹화할 수 있는 능력을 요구합니다. 이 릴리스에서는 심각도 또는 상태로 그룹화할 수 있습니다. 이를 통해 그룹이나 프로젝트에 있는 확인된 취약성의 수, 또는 여전히 분류되어야 하는 취약성의 수와 같은 질문에 더 잘 답할 수 있습니다.

### 개별 wiki 페이지를 PDF로 내보내기 {#export-individual-wiki-pages-as-pdf}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/wiki/_index.md#export-a-wiki-page) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/414691)

{{< /details >}}

GitLab 16.5부터 개별 wiki 페이지를 PDF 파일로 내보낼 수 있습니다. 이제 팀 지식 공유가 훨씬 더 원활합니다. wiki를 PDF로 내보내기는 다양한 사용 사례에 사용할 수 있습니다. 예를 들어 wiki에 보관된 기술 설명서의 사본을 제공하거나 wiki의 정보를 프로젝트 상태와 함께 공유합니다. 일부 조직에서 이러한 도구 사용이 금지되어 있어 또 다른 과제를 만들기 때문에 Markdown 파일을 PDF로 변환하는 대체 도구를 활용할 필요가 더 이상 없습니다. 이 기능에 기여해 주신 JiHu에게 감사합니다!

### 빠른 작업으로 하위 항목을 추가합니다 {#add-a-child-task-objective-or-key-result-with-a-quick-action}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/quick_actions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/420797)

{{< /details >}}

이제 `/add_child` 빠른 작업을 사용하여 작업, 목표 또는 OKR에 대한 하위 항목을 추가할 수 있습니다.

### 작업, 목표 및 OKR의 연결된 항목 위젯 {#linked-items-widget-in-tasks-objectives-and-key-results}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/okrs.md#linked-items-in-okrs) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/416558)

{{< /details >}}

이 릴리스에서는 [작업](../../user/tasks.md#linked-items-in-tasks) 및 [OKR](../../user/okrs.md#linked-items-in-okrs)을 "관련", "차단됨" 또는 "차단 중"으로 연결하여 종속적이고 관련된 작업 항목 간의 추적 가능성을 제공할 수 있습니다.

[에픽](https://gitlab.com/groups/gitlab-org/-/epics/9290) 및 [이슈](https://gitlab.com/groups/gitlab-org/-/epics/9584)를 작업 항목 프레임워크로 마이그레이션할 때 모든 이러한 유형 간의 연결이 가능합니다.

### 빠른 작업으로 작업, 목표 또는 OKR을 위한 상위 항목 설정 {#set-a-parent-for-a-task-objective-or-key-result-with-a-quick-action}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/quick_actions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/420798)

{{< /details >}}

이제 `/set_parent` 빠른 작업을 사용하여 작업, 목표 또는 OKR에 대한 상위 항목을 설정할 수 있습니다.

### DAST 분석기 업데이트 {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dast/browser/checks/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11426)

{{< /details >}}

16.5 릴리스 마일스톤 동안 브라우저 기반 DAST에 대해 기본적으로 다음 활성 점검을 활성화했습니다:

- 점검 78.1은 ZAP 점검 90020을 대체하며 명령 주입을 식별합니다. 이는 대상 애플리케이션 서버에서 임의의 OS 명령을 실행하여 악용될 수 있습니다. 이것은 전체 시스템 손상으로 이어질 수 있는 중요한 취약성입니다.
- 점검 611.1은 ZAP 점검 90023을 대체하며 외부 XML 엔티티 주입(XXE)을 식별합니다. 이는 애플리케이션의 XML 파서가 외부 리소스를 포함하도록 하여 악용될 수 있습니다.
- 점검 94.4는 ZAP 점검 90019를 대체하며 "서버 측 코드 주입(NodeJS)"을 식별합니다. 이는 임의의 JavaScript 코드를 주입하여 서버에서 실행되도록 하여 악용될 수 있습니다.
- 점검 113.1은 ZAP 점검 40003을 대체하며 "HTTP 헤더의 CRLF 시퀀스 부정 중립화('HTTP Response Splitting')"을 식별합니다. 이는 캐리지 리턴/라인 피드(CRLF) 문자를 삽입하여 HTTP 응답에 임의 데이터를 주입하여 악용될 수 있습니다.

### 작업 API 엔드포인트 속도 제한을 구성 가능하게 만들기 {#make-jobs-api-endpoint-rate-limit-configurable}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/settings/user_and_ip_rate_limits.md#maximum-authenticated-requests-to-projectidjobs-per-minute) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/395702)

{{< /details >}}

`project/:id/jobs` API 엔드포인트에 대한 속도 제한이 최근에 추가되었으며 사용자당 분당 600개의 요청으로 기본 설정됩니다. 후속 반복으로 이 제한을 구성 가능하게 만들어 인스턴스 관리자가 요구 사항에 가장 적합한 제한을 설정할 수 있습니다.

### GitLab 러너 16.5 {#gitlab-runner-165}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab 러너 16.5도 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [AWS EC2 인스턴스용 GitLab Runner fleeting 플러그인 - Beta](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29404)

#### 버그 수정 {#bug-fixes}

- [러너 관리자 k8s pod 종료로 인해 고아 워커 pod 발생](https://gitlab.com/gitlab-org/gitlab/-/issues/390645)
- [GitLab Runner 15.8.0이 특수 문자로 된 브랜치를 체크아웃할 수 없음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29606)
- [GitLab Runner가 arm64 컴퓨팅 호스트에서 arm64 헬퍼 이미지가 아닌 x86-64 헬퍼 이미지를 끌어옴](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27768)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-5-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.5)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.5)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.5)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
