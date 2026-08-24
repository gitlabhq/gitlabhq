---
stage: Release Notes
group: Monthly Release
date: 2024-06-20
title: "GitLab 17.1 릴리스 정보"
description: "GitLab 17.1 릴리스, 모델 레지스트리 베타 버전으로 출시"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 6월 20일에 GitLab 17.1이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

누구나 [GitLab 커뮤니티 기여자를 추천](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)할 수 있습니다! 활동적인 후보자들을 지지해주거나 새로운 추천을 추가해주세요! 🙌

Shubham Kumar는 [17.1 동안 7개의 이슈를 완료](https://gitlab.com/dashboard/issues?sort=due_date_desc&state=closed&assignee_username%5B%5D=imskr&milestone_title=17.1)했으며 2021년부터 GitLab에 지속적으로 기여해 오고 있습니다. 현재 50개 이상의 병합된 기여를 달성했습니다! Shubham은 [GitLab Hero](https://contributors.gitlab.com/docs/previous-heroes)이며 Google Summer of Code의 이전 기여자입니다.

Shubham은 GitLab의 선임 제품 관리자인 [Christina Lohr](https://gitlab.com/lohrc)에 의해 추천되었습니다. "Shubham은 지난 몇 주와 몇 개월 동안 많은 이슈를 도와주었으며, 특히 API 제공에서 격차를 해결하는 데 도움을 주었습니다"라고 Christina가 말합니다. "Shubham이 추진하는 모든 추가 기능에 대해 충분히 빠르게 릴리스 포스트를 작성할 수 없습니다!"

"오픈 소스 커뮤니티는 놀랍습니다"라고 Shubham이 말합니다. "이 기회와 인정에 감사하며, GitLab 플랫폼에 계속 기여할 수 있기를 기대합니다."

Joe Snyder는 GitLab의 주요 제품 관리자인 [Kai Armstrong](https://gitlab.com/phikai)에 의해 [이메일에 포함되지 않도록 차이점 제한](https://gitlab.com/gitlab-org/gitlab/-/issues/24733) 기능을 구축한 것으로 추천되었습니다. 이 기여는 GitLab 15.3으로 거슬러 올라가는 10개 이상의 머지 리퀘스트를 포함했습니다. "이것은 많은 마일스톤, 복잡한 마이그레이션, 그리고 이를 지원하기 위한 제품 변경이 필요했던 거대한 기능입니다"라고 Kai가 말합니다. "Joe는 마일스톤 동안 많은 유지보수자 및 협업자와 함께 피곤함 없이 이 작업을 완료했습니다."

GitLab의 제품 관리자인 [Jocelyn Eillis](https://gitlab.com/jocelynjane)는 [`build:resource_group`에서 중첩된 변수가 확장되지 않는 버그를 수정하기 위한 추가 작업을 강조하여 Joe의 추천을 지지했습니다.](https://gitlab.com/gitlab-org/gitlab/-/issues/361438) "이 버그는 이슈 자체의 문서화된 고객 수요 외에도 23개의 투표를 받았습니다"라고 Jocelyn이 말합니다. "검토자 피드백에 대한 빠른 대응은 이것을 GitLab 17.1에 포함할 수 있게 해주었습니다!"

이것은 Joe가 이전에 [GitLab 16.6](https://about.gitlab.com/releases/2023/11/16/gitlab-16-6-released/#mvp)에서 수상한 후 두 번째 GitLab MVP입니다. Joe는 [Kitware](https://www.kitware.com/)의 선임 R&D 엔지니어이며 2021년부터 GitLab에 기여해 오고 있습니다.

## 주요 기능 {#primary-features}

### 모델 레지스트리 베타 버전으로 사용 가능 {#model-registry-available-in-beta}

<!-- categories: MLOps -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/ml/model_registry/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9423)

{{< /details >}}

GitLab은 이제 공식적으로 모델 레지스트리를 베타로 첫 번째 클래스 개념으로 지원합니다. UI를 통해 직접 모델을 추가 및 편집하거나 MLflow 통합을 사용하여 GitLab을 모델 레지스트리 백엔드로 사용할 수 있습니다.

모델 레지스트리는 데이터 과학 팀이 머신러닝 모델과 관련 메타데이터를 관리하는 데 도움을 주는 허브입니다. 조직이 훈련된 머신러닝 모델을 저장, 버전 관리, 문서화 및 발견할 수 있는 중앙 집중식 위치로 역할을 합니다. 전체 모델 수명 주기에 걸쳐 더 나은 협업, 재현성 및 거버넌스를 보장합니다.

우리는 모델 레지스트리를 팀이 모델을 협업, 배포, 모니터링 및 지속적으로 훈련할 수 있도록 하는 초석 개념으로 생각하며, 여러분의 피드백에 매우 관심이 있습니다. 우리의 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/465405)에 의견을 남겨주시면 연락드리겠습니다!

### VS Code에서 여러 GitLab Duo 코드 제안 보기 {#see-multiple-gitlab-duo-code-suggestions-in-vs-code}

<!-- categories: Editor Extensions, Code Suggestions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/repository/code_suggestions/_index.md#view-multiple-code-suggestions) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1325)

{{< /details >}}

VS Code의 GitLab Duo 코드 제안은 이제 여러 제안이 가능한지 여부를 표시합니다. 제안 위에 마우스를 올리고 화살표 또는 키보드 단축키를 사용하여 제안을 순환하면 됩니다.

### 암호 푸시 보호 베타 버전으로 사용 가능 {#secret-push-protection-available-in-beta}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/application_security/secret_detection/secret_push_protection/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/12729)

{{< /details >}}

암호, 키 또는 API 토큰과 같은 시크릿이 실수로 Git 리포지토리에 커밋되면 리포지토리 액세스 권한이 있는 모든 사람이 악의적인 목적으로 시크릿의 사용자를 사칭할 수 있습니다. 이 위험을 해결하기 위해 대부분의 조직은 노출된 시크릿을 취소하고 교체하도록 요구하지만, 시크릿이 먼저 푸시되는 것을 방지하여 수정 시간을 절약하고 위험을 줄일 수 있습니다.

암호 푸시 보호는 GitLab에 푸시된 각 커밋의 내용을 확인합니다. [시크릿이 감지되면](../../user/application_security/secret_detection/secret_push_protection/_index.md#detected-secrets), 푸시가 차단되고 다음을 포함한 커밋에 대한 정보가 표시됩니다:

- 시크릿을 포함하는 커밋 ID입니다.
- 시크릿을 포함하는 파일 이름 및 줄 번호입니다.
- 시크릿의 유형입니다.

테스트를 위해 암호 푸시 보호를 건너뛰어야 합니까? 암호 푸시 감지를 건너뛰면 GitLab이 감사 이벤트를 기록하므로 조사할 수 있습니다.

암호 푸시 보호는 GitLab.com에서 Dedicated 고객을 위한 베타 기능으로 사용 가능하며 [프로젝트별로](../../user/application_security/secret_detection/secret_push_protection/_index.md#enable-secret-push-protection-in-a-project) 활성화할 수 있습니다. [이슈 467408](https://gitlab.com/gitlab-org/gitlab/-/issues/467408)에 피드백을 제공하여 암호 푸시 보호를 개선할 수 있습니다.

### GitLab Runner 자동 스케일러가 일반적으로 사용 가능 {#gitlab-runner-autoscaler-is-generally-available}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](https://docs.gitlab.com/runner/runner_autoscale/) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29221)

{{< /details >}}

GitLab의 이전 버전에서 일부 고객은 공용 클라우드 플랫폼의 가상 머신 인스턴스에서 GitLab Runner에 대한 자동 스케일링 솔루션이 필요했습니다. 이러한 고객들은 레거시 [Docker Machine 실행기](https://docs.gitlab.com/runner/configuration/autoscale/) 또는 클라우드 제공자 기술을 사용하여 함께 연결된 사용자 지정 솔루션에 의존해야 했습니다.

오늘, 우리는 GitLab Runner 자동 스케일러의 일반 공급 가능성을 발표하게 되어 기쁩니다. GitLab Runner 자동 스케일러는 GitLab에서 개발한 taskscaler 및 [fleeting](https://docs.gitlab.com/runner/fleet_scaling/fleeting/) 기술과 Google Compute Engine의 클라우드 제공자 플러그인으로 구성됩니다.

### GitLab 커넥터 애플리케이션이 Snowflake 마켓플레이스에서 사용 가능 {#gitlab-connector-application-now-available-on-the-snowflake-marketplace}

<!-- categories: Audit Events, Compliance Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../integration/snowflake.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13004)

{{< /details >}}

감사 이벤트는 GitLab에서 생성되고 저장됩니다. 이 릴리스 이전에는 감사 이벤트를 GitLab 내에서만 액세스할 수 있었으며, GitLab UI를 사용하여 결과를 검토하거나 구조화된 JSON으로 모든 감사 이벤트를 받도록 스트리밍 대상을 설정할 수 있었습니다.

그러나 고객들은 타사 대상(예: Snowflake와 같은 SIEM 솔루션)에 감사 이벤트를 보유할 수 있기를 원했으므로 다음을 더 쉽게 할 수 있습니다:

- GitLab을 포함한 조직의 여러 시스템에서 모든 감사 이벤트 데이터를 확인, 결합, 조작 및 보고합니다.
- 자신이 관심 있는 특정 감사 이벤트만 보고 빠르게 자신이 관심 있는 질문에 답합니다.
- GitLab 내에서 일어나는 모든 것을 완전히 파악할 수 있으며 나중에 검토할 수 있습니다.

고객을 지원하기 위해 감사 이벤트 API를 사용하는 [Snowflake 마켓플레이스](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector)를 위한 GitLab 커넥터 애플리케이션을 만들었습니다. 이 기능을 사용하려면 고객이 Snowflake 마켓플레이스를 사용하여 애플리케이션을 배포하고 관리해야 합니다.

### 개선된 Wiki 사용자 경험 {#improved-wiki-user-experience}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/wiki/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/452225)

{{< /details >}}

GitLab 17.1의 Wiki 기능은 더욱 통합되고 효율적인 워크플로를 제공합니다:

- [더 쉽고 빠른 클론 생성](https://gitlab.com/gitlab-org/gitlab/-/issues/281830). 새로운 리포지토리 클론 버튼을 사용합니다. 이는 협업을 개선하고 편집 또는 보기를 위한 Wiki 콘텐츠에 대한 액세스 속도를 높입니다.
- [더 명백한 삭제 옵션](https://gitlab.com/gitlab-org/gitlab/-/issues/335169)을 더 잘 발견할 수 있는 위치에 있습니다. 이는 이를 검색하는 데 소요되는 시간을 줄이고 Wiki 페이지를 관리할 때 발생할 수 있는 오류나 혼동을 최소화합니다.
- [빈 페이지를 유효하게 허용](https://gitlab.com/gitlab-org/gitlab/-/issues/221061)하여 유연성을 개선합니다. 필요할 때 빈 자리 표시자를 만듭니다. Wiki 콘텐츠의 더 나은 계획 및 구성에 집중하고 나중에 빈 페이지를 채웁니다.

이러한 개선 사항은 Wiki 워크플로의 사용 편의성, 발견성 및 콘텐츠 관리를 향상시킵니다. Wiki 경험이 효율적이고 사용자 친화적이기를 원합니다. 리포지토리 복제를 더 접근 가능하게 만들고, 더 나은 가시성을 위해 핵심 옵션을 재배치하고, 빈 자리 표시자 생성을 허용함으로써 사용자의 필요를 더 잘 충족하기 위해 플랫폼을 개선하고 있습니다.

### 새로운 Value Stream Management 보고서 생성기 도구 {#new-value-stream-management-report-generator-tool}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/analytics/value_streams_dashboard.md#schedule-reports) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/10880)

{{< /details >}}

Value Stream Management를 위한 새로운 보고서 생성 도구의 추가로 소프트웨어 개발 생명 주기(SDLC) 최적화에서 의사 결정권자가 더욱 효율적이고 효과적일 수 있도록 지원합니다.

이제 [DevSecOps 비교 메트릭 보고서](https://gitlab.com/components/vsd-reports-generator#example-for-monthly-executive-value-streams-report) 또는 [AI Impact 분석](https://about.gitlab.com/releases/2024/05/16/gitlab-17-0-released/#ai-impact-analytics-in-the-value-streams-dashboard) 보고서를 자동으로, 적극적으로, 그리고 GitLab 이슈에 관련 정보와 함께 전달되도록 예약할 수 있습니다. 예약된 보고서를 사용하면 관리자가 필요한 대시보드를 수동으로 검색하는 데 시간을 보내는 대신 인사이트를 분석하고 정보에 입각한 결정을 내리는 데 집중할 수 있습니다.

[CI/CD 카탈로그](https://gitlab.com/explore/catalog)를 사용하여 예약된 보고서 도구에 액세스할 수 있습니다.

### 서명과 연결된 컨테이너 이미지 {#container-images-linked-to-signatures}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/packages/container_registry/_index.md#container-image-signatures) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/7856)

{{< /details >}}

GitLab 컨테이너 레지스트리는 이제 서명된 컨테이너 이미지를 해당 서명과 연결합니다. 이 개선으로 사용자가 더 쉽게 할 수 있습니다:

- 서명된 이미지와 서명되지 않은 이미지를 식별합니다.
- 컨테이너 이미지와 연결된 서명을 찾고 검증합니다.

이 개선 사항은 GitLab.com에서만 일반적으로 사용 가능합니다. 자체 관리 지원은 베타 버전이며 사용자가 베타 버전이기도 한 [차세대 컨테이너 레지스트리](../../administration/packages/container_registry_metadata_database.md)를 활성화해야 합니다.

### 수동 작업에 대한 확인 필요 {#require-confirmation-for-manual-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/jobs/job_control.md#require-confirmation-for-manual-jobs) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/18906)

{{< /details >}}

수동 작업을 사용하여 프로덕션에 배포하는 것과 같은 CI 파이프라인에서 매우 중요한 작업을 트리거할 수 있습니다. 이 릴리스에서는 실행되기 전에 확인이 필요하도록 수동 작업을 구성할 수 있습니다. `manual_confirmation`을 `when: manual`와 함께 사용하여 작업을 수동으로 실행할 때 UI에 확인 대화상자를 표시합니다. 수동 작업에 대한 확인이 필요하면 추가적인 보안 및 제어 계층이 제공됩니다.

이 커뮤니티 기여에 대해 [Phawin](https://gitlab.com/lifez)에게 특별히 감사드립니다!

### 그룹에 대한 러너 플릿 대시보드 {#runner-fleet-dashboard-for-groups}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/runners/runner_fleet_dashboard_groups.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/424789)

{{< /details >}}

그룹 수준에서 자체 관리 러너 플릿의 운영자는 한눈에 러너 플릿 인프라에 대한 중요한 질문에 빠르게 답할 수 있는 관찰성과 능력이 필요합니다. 그룹에 대한 러너 플릿 대시보드를 사용하면 GitLab UI에서 직접 러너 플릿 관찰성과 실행 가능한 인사이트를 얻을 수 있습니다. 이제 러너 상태를 빠르게 결정할 수 있으며, 조직의 목표 서비스 수준 목표에서 러너 사용 메트릭 및 CI/CD 작업 큐 서비스 기능에 대한 인사이트를 얻을 수 있습니다.

GitLab.com의 고객들은 현재 그룹에 사용 가능한 모든 플릿 대시보드 메트릭을 사용할 수 있습니다. 자체 관리 고객은 대부분의 플릿 대시보드 메트릭을 사용할 수 있지만 **Runner usage** 및 **작업을 선택하기 위해 대기 시간** 메트릭을 사용하려면 ClickHouse 분석 데이터베이스를 구성해야 합니다.

## 규모 및 배포 {#scale-and-deployments}

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.1은 [Ubuntu Noble 24.04](../../install/package/_index.md) 지원을 위한 패키지를 포함합니다.

### 그룹 및 프로젝트에 대한 새로운 GraphQL API 인수 `markedForDeletionOn` {#new-graphql-api-argument-markedfordeletionon-for-groups-and-projects}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/graphql/reference/_index.md#querygroups) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/463809)

{{< /details >}}

이제 새로운 GraphQL API 인수 `markedForDeletionOn`을(를) 사용하여 특정 날짜에 삭제 표시된 그룹 또는 프로젝트를 나열할 수 있습니다.

이 커뮤니티 기여에 대해 [@imskr](https://gitlab.com/imskr)에게 감사합니다!

### 그룹 및 프로젝트 배지에 대한 새로운 자리 표시자 {#new-placeholders-for-group-and-project-badges}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/badges.md#placeholders) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/22278)

{{< /details >}}

이제 네 가지 새로운 자리 표시자를 사용하여 배지 링크 및 이미지 URL을 만들 수 있습니다:

- `%{project_namespace}` - 프로젝트 네임스페이스의 전체 경로 참조
- `%{group_name}` - 그룹 이름 참조
- `%{gitlab_server}` - 그룹 또는 프로젝트의 서버 이름 참조
- `%{gitlab_pages_domain}` - 그룹 또는 프로젝트의 도메인 이름 참조

이 커뮤니티 기여에 대해 [@TamsilAmani](https://gitlab.com/TamsilAmani)에게 감사합니다!

### 배지에 대한 새로운 `%{latest_tag}` 자리 표시자 {#new-latest_tag-placeholder-for-badges}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/badges.md#placeholders) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/26420)

{{< /details >}}

이제 `%{latest_tag}` 자리 표시자를 사용하여 배지 링크 및 이미지 URL을 만들 수 있습니다. 이 자리 표시자는 리포지토리에 대해 게시된 최신 태그를 참조합니다.

이 커뮤니티 기여에 대해 [@TamsilAmani](https://gitlab.com/TamsilAmani)에게 감사합니다!

### Groups API를 사용하여 `marked_for_deletion_on` 날짜로 그룹 필터링 {#filter-groups-by-marked_for_deletion_on-date-with-the-groups-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/groups.md#list-groups) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/429315)

{{< /details >}}

이제 Groups API에서 `marked_for_deletion_on` 속성을 사용하여 응답을 필터링할 수 있으며, 특정 날짜에 삭제 표시된 그룹을 반환합니다.

이 커뮤니티 기여에 대해 [@imskr](https://gitlab.com/imskr)에게 감사합니다!

### GraphQL API를 사용하여 사용자의 기여 프로젝트 나열 {#list-contributed-projects-of-a-user-with-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/graphql/reference/_index.md#usercontributedprojects) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/450191)

{{< /details >}}

이제 새로운 GraphQL API 필드 `User.contributedProjects`을(를) 사용하여 사용자가 기여한 프로젝트를 나열할 수 있습니다.

이 커뮤니티 기여에 대해 [@yasuk](https://gitlab.com/yasuk)에게 감사합니다!

### Members API를 사용하여 사용자 이름으로 멤버 추가 {#add-members-by-username-with-the-members-api}

<!-- categories: User Management, Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/group_members.md#add-a-group-member) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/28208)

{{< /details >}}

이전에는 Members API를 사용할 때 사용자 ID로만 그룹 및 프로젝트에 멤버를 추가할 수 있었습니다. 이 릴리스에서는 이제 사용자 이름으로도 멤버를 추가할 수 있습니다.

이 커뮤니티 기여에 대해 [@imskr](https://gitlab.com/imskr)에게 감사합니다!

### Explore에서 정렬 및 필터링 기능 업데이트 {#updated-sorting-and-filtering-functionality-in-explore}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance)

{{< /details >}}

그룹 및 프로젝트 Explore 페이지의 정렬 및 필터링 기능을 업데이트했습니다. 필터링 표시줄이 더 넓어져 가독성이 향상되었습니다.

프로젝트에 대한 Explore 페이지에서 이제 **이름**, **만든 날짜**, **업데이트 날짜** 및 **별점**을(를) 포함하는 표준화된 정렬 옵션을 사용할 수 있으며, 오름차순 또는 내림차순으로 정렬하는 네비게이션 요소가 있습니다. 언어 필터가 필터 메뉴로 이동되었습니다. 새로운 **비활성** 탭에 보관된 프로젝트가 표시되어 더 집중된 검색을 할 수 있습니다. 또한 **역할** 필터를 사용하여 사용자가 소유자인 프로젝트를 검색할 수 있습니다.

그룹에 대한 Explore 페이지에서 정렬 옵션을 표준화하여 **이름**, **만든 날짜** 및 **업데이트 날짜**를 포함하도록 했으며, 오름차순 또는 내림차순으로 정렬하는 네비게이션 요소를 추가했습니다.

이러한 변경 사항에 대한 피드백을 [이슈 438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322)에서 환영합니다.

### 개선된 가시성 수준 선택 {#improved-visibility-level-selection}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/public_access.md#change-group-visibility) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/455668)

{{< /details >}}

이전에는 그룹 또는 프로젝트의 일반 설정이 허용된 가시성 수준만 표시했습니다. 이 보기는 사용자가 다른 옵션을 사용할 수 없는 이유를 이해하려고 할 때 혼동하기도 했으며, 정보가 잘못 표시될 수 있었습니다. 새 보기는 모든 가시성 수준을 표시하며 선택할 수 없는 옵션을 회색으로 표시합니다. 또한 팝오버는 옵션을 사용할 수 없는 이유에 대해 추가 컨텍스트를 제공합니다. 예를 들어 관리자가 가시성 수준을 제한했거나 프로젝트 또는 상위 그룹의 가시성 설정과 충돌할 수 있으므로 가시성 수준을 사용할 수 없습니다.

이러한 변경 사항이 원하는 가시성 옵션을 선택하는 데 있어 충돌을 해결하는 데 도움이 되기를 바랍니다. 이 커뮤니티 기여에 대해 [@gerardo-navarro](https://gitlab.com/gerardo-navarro)에게 감사합니다!

### Projects API를 사용하여 `marked_for_deletion_on` 날짜로 프로젝트 필터링 {#filter-projects-by-marked_for_deletion_on-date-with-the-projects-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/projects.md#list-all-projects) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/463939)

{{< /details >}}

이제 Projects API에서 `marked_for_deletion_on` 속성을 사용하여 응답을 필터링할 수 있으며, 특정 날짜에 삭제 표시된 프로젝트를 반환합니다.

이 커뮤니티 기여에 대해 [@imskr](https://gitlab.com/imskr)에게 감사합니다!

### 웹후크 생성에 대한 감사 이벤트 {#audit-event-on-webhook-creation}

<!-- categories: Notifications, Audit Events -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/audit_event_types.md#webhooks) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/8068)

{{< /details >}}

감사 이벤트는 GitLab에서 수행되는 중요한 작업의 기록을 만듭니다. 지금까지 사용자가 시스템, 그룹 또는 프로젝트 웹후크를 추가할 때 감사 이벤트가 생성되지 않았습니다.

이 릴리스에서는 사용자가 시스템, 그룹 또는 프로젝트 웹후크를 만들 때에 대한 감사 이벤트를 추가했습니다.

### REST API를 사용하여 실행 중인 직접 전송 마이그레이션 취소 {#use-rest-api-to-cancel-a-running-direct-transfer-migration}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/bulk_imports.md#cancel-a-migration) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438281)

{{< /details >}}

지금까지 실행 중인 직접 전송 마이그레이션을 취소하려면 [Rails 콘솔에 액세스해야 했습니다](../../user/group/import/direct_transfer_migrations.md#cancel-a-running-migration).

이 릴리스에서는 관리자가 REST API를 사용하여 마이그레이션을 취소할 수 있는 기능을 추가했습니다.

### REST API를 사용하여 그룹 훅 테스트 {#test-group-hooks-with-the-rest-api}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/group_webhooks.md#trigger-a-test-group-hook) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/455589)

{{< /details >}}

이전에는 REST API를 사용하여 프로젝트 훅만 테스트할 수 있었습니다. 이 릴리스에서는 지정된 그룹에 대한 테스트 훅을 트리거할 수도 있습니다.

이 엔드포인트에는 그룹 훅당 분당 3개의 요청이라는 특별한 속도 제한이 있습니다. 자체 관리 GitLab 및 GitLab Dedicated에서 이 제한을 비활성화하려면 관리자가 `web_hook_test_api_endpoint_rate_limit` 기능 플래그를 비활성화할 수 있습니다.

이 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150486)를 주신 [Phawin](https://gitlab.com/lifez)에게 감사합니다!

### API를 사용하여 선택한 프로젝트 관계 다시 가져오기 {#re-import-a-chosen-project-relation-by-using-the-api}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/project_import_export.md#import-project-resources) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/455889)

{{< /details >}}

같은 유형의 많은 항목이 있는 내보내기 파일에서 프로젝트를 가져올 때(예: 머지 리퀘스트 또는 파이프라인) 이러한 항목 중 일부가 가져와지지 않는 경우가 있습니다.

이 릴리스에서는 이미 가져온 항목을 건너뛰면서 명명된 관계를 다시 가져오는 API 엔드포인트를 추가했습니다. API는 다음을 모두 필요로 합니다:

- 프로젝트 내보내기 아카이브입니다.
- 유형입니다. 이슈, 머지 리퀘스트, 파이프라인 또는 마일스톤입니다.

### 직접 전송으로 가져올 때 상속된 멤버십 구조 유지 {#keep-inherited-membership-structure-when-importing-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/import/direct_transfer_migrations.md#user-membership-mapping) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/458834)

{{< /details >}}

지금까지 [상속된 멤버십](../../user/project/members/_index.md#membership-types)은 직접 전송으로 마이그레이션할 때 안정적으로 가져와지지 않았습니다. 이는 프로젝트의 상속된 멤버가 직접 멤버로 가져와졌다는 것을 의미했습니다.

이 릴리스부터 GitLab은 이제 프로젝트 멤버십을 마이그레이션하기 전에 먼저 그룹 멤버십을 마이그레이션합니다. 이것은 소스 GitLab 인스턴스의 상속된 멤버십을 복제합니다.

### REST API를 사용하여 사용자 지정 웹후크 헤더 설정 {#use-the-rest-api-to-set-custom-webhook-headers}

<!-- categories: Source Code Management, Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/project_webhooks.md#set-a-custom-header) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/455528)

{{< /details >}}

GitLab 16.11에서는 [웹후크를 만들거나 편집할 때 사용자 지정 헤더를 추가](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#custom-webhook-headers)하는 기능을 도입했습니다.

이 릴리스에서는 GitLab REST API를 사용하여 사용자 지정 웹후크 헤더를 설정할 수 있습니다.

이 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768)를 주신 [Niklas](https://gitlab.com/Taucher2003)에게 감사합니다!

### 백업에 디스크에 저장된 외부 머지 리퀘스트 차이가 포함됨 {#backups-include-external-merge-request-diffs-stored-on-disk}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/backup_restore/backup_gitlab.md#backup-command)

{{< /details >}}

`gitlab-backup` 도구는 이제 로컬 디스크에 저장된 [외부 머지 리퀘스트 차이](../../administration/merge_request_diffs.md) 백업을 지원합니다. `gitlab-backup` 도구는 객체 저장소에 저장된 파일을 백업하지 않습니다. 따라서 외부 머지 차이가 객체 저장소에 저장되어 있으면 수동으로 백업해야 합니다.

Cloud Native Hybrid 환경용 `backup-utility`은 이미 외부 머지 리퀘스트 차이 백업을 지원했으며 이 기능은 변경되지 않았습니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 코드 검토 이메일에서 차이 미리 보기 비활성화 {#disable-diff-previews-in-code-review-emails}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/group/manage.md#disable-diff-previews-in-email-notifications)

{{< /details >}}

머지 리퀘스트의 코드를 검토하고 코드 줄에 주석을 달면 GitLab이 참여자에게 이메일 알림에 차이의 몇 줄을 포함합니다. 일부 조직 정책은 이메일을 덜 안전한 시스템으로 취급하거나 이메일을 위한 자체 인프라를 제어하지 않을 수 있습니다. 이는 소스 코드의 IP 또는 액세스 제어에 대한 위험을 초래할 수 있습니다.

그룹 및 프로젝트에서 새로운 설정을 사용하여 조직이 머지 리퀘스트 이메일에서 차이 미리 보기를 제거할 수 있습니다. 이렇게 하면 민감한 정보가 GitLab 외부에서 사용 가능한 상태가 되지 않도록 할 수 있습니다.

[Joe Snyder](https://gitlab.com/joe-snyder)가 이를 기여해주셔서 정말 감사합니다!

### 관리자가 부분 이메일 주소로 사용자를 검색할 수 있음 {#administrators-can-search-users-by-partial-email-address}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/admin_area.md#administering-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/20381)

{{< /details >}}

이제 관리자는 Admin Area의 사용자 개요에서 부분 이메일 주소로 사용자를 검색할 수 있습니다. 예를 들어 특정 이메일 도메인으로 사용자를 필터링하여 특정 기관의 모든 사용자를 찾을 수 있습니다. 이 기능은 권한 없는 사용자가 다른 계정의 이메일 주소에 액세스하는 것을 방지하기 위해 관리자로 제한됩니다.

이 커뮤니티 기여에 대해 [@zzaakiirr](https://gitlab.com/zzaakiirr)에게 감사합니다!

### 릴리스 페이지에 릴리스 RSS 아이콘 표시 {#show-release-rss-icon-on-releases-page}

<!-- categories: Release Orchestration -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/releases/_index.md#track-releases-with-an-rss-feed) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/30988)

{{< /details >}}

새로운 릴리스가 게시될 때 알림을 받고 싶습니까? GitLab은 이제 릴리스용 RSS 피드를 제공합니다. 프로젝트 릴리스 페이지의 RSS 아이콘을 사용하여 릴리스 피드를 구독할 수 있습니다.

[Martin Schurz](https://gitlab.com/schurzi)에게 기여해주셔서 감사합니다!

### 사용자 지정 역할을 위한 새로운 권한 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/custom_roles/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

GitLab 17.1에서는 다음 새로운 권한을 가진 사용자 지정 역할을 만들 수 있습니다:

- [머지 리퀘스트 설정 관리](../../user/custom_roles/abilities.md#code-review-workflow)
- [통합 관리](../../user/custom_roles/abilities.md#integrations)
- [배포 토큰 관리](../../user/custom_roles/abilities.md#continuous-delivery)
- [CRM 연락처 읽기](../../user/custom_roles/abilities.md#team-planning)

사용자 지정 역할을 사용하면 동등한 권한을 가진 사용자를 만들어 소유자 역할을 가진 사용자 수를 줄일 수 있습니다. 이렇게 하면 그룹의 특정 요구 사항에 맞게 조정된 역할을 정의하고 불필요한 권한 상승을 방지할 수 있습니다.

### 머지 리퀘스트 승인 정책이 실패 열림/닫힘 (정책 편집기) {#merge-request-approval-policies-fail-openclosed-policy-editor}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#fallback_behavior) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13227)

{{< /details >}}

이전 [반복](https://gitlab.com/groups/gitlab-org/-/epics/10816)을 기반으로 정책 편집기 내에서 보안 정책을 실패 열림 또는 실패 닫힘으로 전환할 수 있도록 하는 새로운 옵션을 도입하고 있습니다. 이 개선 사항은 정책 편집기 보기 내에서 더 간단한 구성을 허용하도록 YAML 지원을 확장합니다.

예를 들어, 실패 열림으로 구성된 머지 리퀘스트 정책은 기준을 평가하기에 충분한 증거가 없는 경우 머지 리퀘스트가 병합될 수 있습니다. 증거 부족은 프로젝트에서 분석기가 활성화되지 않았거나 분석기가 정책을 평가하기 위한 결과를 생성하지 못했기 때문일 수 있습니다. 이 접근 방식은 팀이 적절한 스캔 실행 및 강제를 보장하기 위해 노력하면서 정책의 점진적 롤아웃을 허용합니다.

### 프로젝트 소유자가 만료되는 액세스 토큰 알림을 받음 {#project-owners-receive-expiring-access-token-notifications}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../security/tokens/_index.md#project-access-tokens) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/460818)

{{< /details >}}

이제 직접 멤버십을 가진 프로젝트 소유자와 유지보수자 모두 프로젝트 액세스 토큰이 만료될 예정일 때 이메일 알림을 받습니다. 이전에는 프로젝트 유지보수자만 이 알림을 받았습니다. 이렇게 하면 더 많은 사람들이 토큰 만료 예정 시간을 알고 있을 수 있습니다.

기여해주신 [Jacob Henner](https://gitlab.com/arcesium-henner)에게 감사합니다!

### 이미지 업로드 시 붙여넣은 이미지 축소 {#downscale-pasted-images-on-image-upload}

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/markdown.md#change-image-or-video-dimensions) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/419913)

{{< /details >}}

GitLab 17.1은 업로드 중에 축소될 수 있도록 고해상도 이미지 처리를 개선합니다. 이전에는 이미지가 원본 크기로 표시되어 최적이 아닌 표시 품질이 발생했습니다. 이 개선 사항은 큰 이미지가 포함된 페이지의 시각적 흐름을 깨뜨리지 않도록 합니다.

### 리치 텍스트 편집기에서 끌 수 있는 미디어 {#draggable-media-in-the-rich-text-editor}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/rich_text_editor.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/452233)

{{< /details >}}

이전에는 리치 텍스트 편집기에서 미디어를 이동하려면 각 항목을 수동으로 복사하고 붙여넣어야 했습니다. 이로 인해 이슈, 에픽 및 위키에 미디어를 포함하는 속도가 느려지기도 했습니다. GitLab 17.1에서는 이제 리치 텍스트 편집기에서 미디어를 끌어다 놓을 수 있어 편집 중 효율성이 크게 향상됩니다.

### GitLab API 호출에서 상호 TLS 지원 {#pages-support-for-mutual-tls-in-gitlab-api-calls}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/pages/_index.md#support-mutual-tls-when-calling-the-gitlab-api) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548)

{{< /details >}}

GitLab을 [SSL 인증서를 사용한 클라이언트 인증 강제](https://docs.gitlab.com/omnibus/settings/ssl/#enable-2-way-ssl-client-authentication)하도록 구성할 수 있습니다. 그러나 GitLab Pages 서비스는 클라이언트 인증서를 사용하도록 구성할 수 없었고 내부 API에 대한 호출이 거부되었기 때문에 해당 기능과 호환되지 않았습니다.

GitLab 17.1부터 GitLab Pages에 대한 클라이언트 인증서를 구성할 수 있습니다. 이렇게 하면 GitLab API를 사용한 클라이언트 인증을 활성화하여 GitLab 인스턴스의 보안을 강화할 수 있습니다.

### 이름을 바꿀 때 Wiki 페이지를 새 URL로 리디렉션 {#redirect-wiki-pages-to-new-url-when-renamed}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/wiki/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/257892)

{{< /details >}}

GitLab 17.1은 Wiki 페이지 리디렉션에 중요한 개선을 도입합니다. Wiki 페이지의 이름을 바꾸면 이전 페이지에 액세스하려는 사람은 자동으로 새 페이지로 리디렉션되어 모든 기존 링크가 기능하도록 유지됩니다. 이 개선 사항은 페이지 이름 변경 관리를 위한 워크플로를 간소화하고 전반적인 지식 관리 경험을 향상시킵니다.

### 업데이트된 Pages UI {#updated-pages-ui}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/pages/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153250)

{{< /details >}}

GitLab 17.1에서 Pages 사용자 인터페이스를 개선했습니다. 개선 사항에는 더 효율적인 화면 공간 사용이 포함됩니다. 이러한 UI 개선 사항은 Pages를 관리할 때 사용자 환경 및 효율성을 개선하는 데 중점을 두고 있습니다.

### 컨테이너 이미지의 마지막 발행 날짜 표시 {#display-the-last-published-date-for-container-images}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Silver, Gold
- 링크: [문서](../../user/packages/container_registry/_index.md#view-the-container-registry) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/290949)

{{< /details >}}

이전에는 컨테이너 레지스트리 사용자 인터페이스에서 발행 타임스탬프가 정확하지 않은 경우가 많았습니다. 이는 이 중요한 데이터에 의존하여 컨테이너 이미지를 찾고 유효성을 검사할 수 없음을 의미했습니다.

GitLab 17.1에서는 정확한 `last_published_at` 타임스탬프를 포함하도록 UI를 업데이트했습니다. **배포 > Container Registry**로 이동하여 태그를 선택하여 자세한 내용을 확인할 수 있습니다. 마지막 발행 날짜는 페이지 맨 위에서 확인할 수 있습니다.

이 개선 사항은 GitLab.com에서만 일반적으로 사용 가능합니다. 자체 관리 지원은 베타 버전이며 베타 버전인 [차세대 컨테이너 레지스트리](../../administration/packages/container_registry_metadata_database.md)를 활성화한 인스턴스에서만 사용 가능합니다.

### 컨테이너 레지스트리 태그를 발행 날짜로 정렬 {#sort-container-registry-tags-by-publish-date}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/packages/container_registry/_index.md#view-the-container-registry) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/7856)

{{< /details >}}

GitLab 컨테이너 레지스트리를 사용하여 파이프라인과 함께 소스 코드 옆에 Docker 또는 OCI 이미지를 보고, 푸시 및 풀 합니다. 컨테이너 이미지를 빌드한 후 정확하게 빌드되었는지 확인하고 유효성을 검사해야 하는 경우가 많습니다. 많은 고객의 경우 사용자 인터페이스를 사용하여 올바른 컨테이너 이미지를 찾기가 어려울 수 있습니다.

이제 컨테이너 레지스트리 태그 목록을 발행 날짜로 정렬할 수 있습니다. 이 기능을 사용하여 가장 최근에 발행된 컨테이너 이미지를 빠르게 찾고 유효성을 검사할 수 있습니다.

이 개선 사항은 GitLab.com에서만 일반적으로 사용 가능합니다. 자체 관리 지원은 베타 버전이며, 베타 버전이기도 한 차세대 컨테이너 레지스트리가 필요하기 때문입니다. 자세히 알아보려면 [컨테이너 레지스트리 메타데이터 데이터베이스 설명서](../../administration/packages/container_registry_metadata_database.md)를 참조하세요.

### 더욱 부드러운 워크플로를 위한 실시간 보드 업데이트 {#real-time-board-updates-for-a-smoother-workflow}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/issue_board.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/468187)

{{< /details >}}

[보드](../../user/project/issue_board.md)에서 이슈를 업데이트할 때 더 부드러운 경험을 느낄 수 있습니다! 사이드바에서 수행한 변경 사항이 보드 자체에 즉시 나타나므로 더 이상 새로 고칠 필요가 없습니다. 이 반응형 보드 경험은 워크플로를 간소화하여 변경 사항을 실시간으로 반영되는 것을 보면서 빠르게 업데이트할 수 있습니다.

### 작업에 대한 추적 시간 {#track-time-on-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/time_tracking.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438577)

{{< /details >}}

이 릴리스에서는 [빠른 작업](../../user/project/quick_actions.md)을 사용하거나 작업의 사이드바에 있는 시간 추적 위젯에서 작업에 대한 시간 추정을 설정하고 소요 시간을 기록할 수 있습니다. 작업에 소요된 시간은 작업의 시간 추적 보고서로 볼 수 있습니다.

### 에픽의 진행률 백분율 이해 {#understand-an-epics-progress-percentage}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/epics/manage_epics.md#manage-issues-assigned-to-an-epic) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/5163)

{{< /details >}}

이제 하위 항목의 가중치 완료를 기반으로 에픽의 전체 진행 상황을 쉽게 볼 수 있습니다. 계층 구조 위젯의 새로운 진행률 롤업을 통해 에픽의 전체 작업 범위를 이해하고 진행 상황을 추적하기가 더 쉬워집니다.

### API 보안 테스팅 분석기 업데이트 {#api-security-testing-analyzer-updates}

<!-- categories: API Security -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/api_security_testing/configuration/variables.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/14170)

{{< /details >}}

GitLab 17.1은 API 보안 테스팅에 대해 다음 구성 변수를 추가합니다:

1. `APISEC_SUCCESS_STATUS_CODES`은 API 보안 테스팅 스캔 작업이 통과했는지 여부를 정의하는 HTTP 성공 상태 코드의 쉼표로 구분된 목록을 만듭니다.
1. `APISEC_TARGET_CHECK_DISABLED`은 스캔이 시작되기 전에 대상 API를 사용할 수 있을 때까지 기다리는 것을 비활성화합니다.
1. `APISEC_TARGET_CHECK_STATUS_CODE`은 API 대상 가용성 확인에 대해 예상되는 상태 코드를 지정합니다. 제공하지 않으면 500이 아닌 상태 코드는 스캐너에서 허용됩니다.

이러한 새로운 변수는 스캔이 성공적으로 실행되도록 보장하기 위해 더 큰 사용자 정의 및 유연성을 제공합니다.

DAST API는 16.10에서 API 보안 테스팅으로 이름이 변경되었습니다. 변수 이름은 이제 `APISEC` 접두사로 시작합니다. 이전에는 `DAST_API`로 시작했습니다. `DAST_API` 접두사가 있는 변수는 18.0(2025년 5월)까지 지원됩니다. 구성이 예상대로 작동하도록 하려면 가능한 한 빨리 변수 이름을 업데이트해야 합니다.

### 레지스트리용 컨테이너 스캔 {#container-scanning-for-registry}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/container_scanning/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/2340)

{{< /details >}}

GitLab Composition Analysis는 이제 레지스트리용 컨테이너 스캔을 지원합니다.

프로젝트에서 레지스트리용 컨테이너 스캔을 활성화했고 컨테이너 이미지를 프로젝트의 컨테이너 레지스트리에 푸시하면 GitLab이 해당 태그와 스캔 제한을 확인합니다.

태그가 `latest`이고 스캔 수가 제한(하루 50회 스캔) 미만이면 GitLab은 이미지에서 `container_scanning` 작업을 실행하는 새로운 파이프라인을 만듭니다. 파이프라인은 이미지를 레지스트리에 푸시한 사용자와 연결됩니다.

스캔 작업은 GitLab에 업로드된 CycloneDX SBOM을 생성합니다. 지속적인 취약성 스캔 기능이 활성화되고 SBOM에서 감지된 패키지를 스캔합니다.

참고: 취약성 스캔은 새로운 권고가 게시될 때만 수행됩니다. 이는 [패키지 메타데이터가 동기화](../../administration/settings/security_and_compliance.md)될 때 발생합니다.

항상 그렇듯이 새로 릴리스된 기능에 대한 피드백을 감사합니다. 피드백을 제공하려면 이 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/466117)에 댓글을 달아주세요.

### Fuzz 테스팅 분석기 업데이트 {#fuzz-testing-analyzer-updates}

<!-- categories: Fuzz Testing -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/api_fuzzing/configuration/variables.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)

{{< /details >}}

GitLab 17.1은 Fuzz 테스팅에 대해 다음 구성 변수를 추가합니다:

1. `FUZZAPI_SUCCESS_STATUS_CODES`은 Fuzz 테스팅 작업이 통과했는지 여부를 정의하는 HTTP 성공 상태 코드의 쉼표로 구분된 목록을 만듭니다.
1. `FUZZAPI_TARGET_CHECK_SKIP`은 스캔이 시작되기 전에 대상 API를 사용할 수 있을 때까지 기다리는 것을 비활성화합니다.
1. `FUZZAPI_TARGET_CHECK_STATUS_CODE`은 API 대상 가용성 확인에 대해 예상되는 상태 코드를 지정합니다. 제공하지 않으면 500이 아닌 상태 코드는 스캐너에서 허용됩니다.

이러한 새로운 변수는 스캔이 실행되도록 보장하기 위해 더 큰 사용자 정의 및 유연성을 제공합니다.

### 사용자 정의 변수를 재정의할 수 있는 사용자에 대한 향상된 제어 {#enhanced-control-over-who-can-override-user-defined-variables}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/variables/_index.md#restrict-pipeline-variables) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/440338)

{{< /details >}}

사용자 정의 변수를 재정의할 수 있는 사용자를 더 잘 제어하기 위해 `ci_pipeline_variables_minimum_role` 프로젝트 설정을 도입하고 있습니다. 이 새로운 설정은 기존 [`restrict_user_defined_variables`](../../ci/variables/_index.md#restrict-pipeline-variables) 설정보다 더 큰 유연성을 제공합니다. 이제 재정의 권한을 사용자 없음으로 제한하거나 최소 Developer, Maintainer 또는 Owner 역할이 있는 사용자만 제한할 수 있습니다.

### GitLab Runner 17.1 릴리스 {#gitlab-runner-171-released}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](https://docs.gitlab.com/runner) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36942)

{{< /details >}}

오늘 GitLab Runner 17.1을 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 경량의 확장성 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [GCP Compute Engine용 GitLab Runner fleeting 플러그인](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29221)

#### 버그 수정 {#bug-fixes}

- [러너 헬퍼 이미지에 진입점이 누락됨](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37689)

모든 변경 사항의 목록은 GitLab Runner [변경 로그](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-1-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.1)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.1)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.1)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
