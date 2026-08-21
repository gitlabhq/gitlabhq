---
stage: Release Notes
group: Monthly Release
date: 2025-05-15
title: "GitLab 18.0 릴리스 정보"
description: "GitLab 18.0이 Premium 및 Ultimate와 Duo를 함께 출시되었습니다"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 5월 15일에 GitLab 18.0이 다음 기능과 함께 출시되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Michael Hofer {#this-months-notable-contributor-michael-hofer}

Michael Hofer는 뛰어난 기여자이자 커뮤니티 리더로서 GitLab의 오픈소스 미션을 주도합니다. 올해 [50개 이상의 기여](https://contributors.gitlab.com/users/karras?fromDate=2025-01-01&toDate=2025-05-12)를 통해 OpenBao를 기반으로 하는 GitLab의 Geo 기능과 Secrets Manager를 강화했습니다. 동료 기여자들을 지원하고 커뮤니티 프로젝트를 주도하면서 [4월 해커톤](https://contributors.gitlab.com/hackathon?hackathonName=2025_04)에서 우승했습니다.

"모든 사람이 GitLab에 기여할 수 있다는 점이 정말 감사합니다!"라고 Michael은 말합니다. "팀과 함께 일하는 것이 즐겁고, OpenBao 및 SLSA와 같은 오픈소스 이니셔티브에서 협력할 때 특히 모든 사람이 매우 도움이 됩니다."

Michael은 미션 크리티컬 오픈소스 워크로드의 계획, 구축 및 운영을 전문으로 하는 국제 IT 서비스 제공업체인 [Adfinis](https://adfinis.com/en/)의 CTO입니다. 그는 협업을 촉진하고 조직 전반에서 오픈소스 솔루션을 홍보하는 데 열정적입니다.

최근 Adfinis는 조직을 GitLab의 제품 및 엔지니어링 팀과 짝지어 함께 GitLab을 구축하는 GitLab의 [Co-Create 프로그램](https://about.gitlab.com/community/co-create/)에 참여했습니다. "모든 조직에 Co-Create를 강력히 권장합니다"라고 Michael은 말합니다. "rootless Podman 빌드, Glimmer 구문 강조 표시 및 기타 개선을 포함한 수많은 멋진 기여로 이어졌습니다."

"Geo 팀은 정말로 Michael과 함께 일하는 것을 감사히 여기고 즐깁니다"라고 Michael을 상으로 추천한 GitLab의 엔지니어링 매니저인 [Lucie Zhao](https://gitlab.com/luciezhao)는 말합니다. "지난 몇 마일스톤에서 뛰어난 기여를 통해 우리 팀 내에서 가장 잘 알려진 커뮤니티 기여자가 되었습니다."

GitLab 팀 멤버인 [Lee Tickett](https://gitlab.com/leetickett-gitlab), [Chloe Fons](https://gitlab.com/c_fons), [Alex Scheel](https://gitlab.com/cipherboy-gitlab)이 추천을 지원했습니다. Alex는 "Michael의 OpenBao 리더십은 우리가 GitLab 값과 일치하는 투명성을 갖춘 고객을 위한 시크릿 관리 솔루션을 효과적으로 협업하여 제공할 수 있게 해줍니다."라고 덧붙였습니다.

GitLab을 함께 만들어주신 Michael과 Adfinis 팀에 감사합니다!

## 주요 기능 {#primary-features}

### GitLab Premium 및 Ultimate with Duo {#gitlab-premium-and-ultimate-with-duo}

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../user/gitlab_duo/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)

{{< /details >}}

GitLab Premium with Duo와 GitLab Ultimate with Duo 출시를 발표하게 되어 기쁩니다. GitLab Premium 및 Ultimate는 이제 AI 네이티브 기능을 포함합니다.

GitLab의 AI 네이티브 기능에는 IDE 내 Code Suggestions 및 Chat이 포함됩니다. 개발 팀은 이러한 기능을 사용하여 다음을 수행할 수 있습니다:

- 코드 분석, 이해 및 설명
- 보안 코드를 더 빠르게 작성
- 코드 품질을 유지하기 위한 테스트를 빠르게 생성
- 성능을 개선하거나 특정 라이브러리를 사용하도록 코드를 쉽게 리팩토링

### Repository X-Ray now available on GitLab Duo Self-Hosted {#repository-x-ray-now-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/project/repository/code_suggestions/repository_xray.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17756)

{{< /details >}}

이제 GitLab Duo Self-Hosted에서 Code Suggestions과 함께 Repository X-Ray를 사용할 수 있습니다. 이 기능은 GitLab Duo Self-Hosted에서 베타 상태이며, GitLab Self-Managed 인스턴스에서는 일반적으로 사용 가능합니다.

### Automatic reviews with Duo Code Review {#automatic-reviews-with-duo-code-review}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Review는 검토 프로세스 중에 귀중한 통찰력을 제공하지만 현재 각 머지 리퀘스트에서 수동으로 검토를 요청해야 합니다.

이제 프로젝트의 머지 리퀘스트 설정을 업데이트하여 GitLab Duo Code Review가 머지 리퀘스트에서 자동으로 실행되도록 구성할 수 있습니다. 활성화되면 Duo Code Review는 다음을 제외하고 머지 리퀘스트를 자동으로 검토합니다:

- 머지 리퀘스트가 초안으로 표시된 경우.
- 머지 리퀘스트에 변경 사항이 없는 경우.

자동 검토는 프로젝트의 모든 코드가 검토를 받도록 보장하여 코드베이스 전반에서 코드 품질을 지속적으로 향상시킵니다.

### Code Suggestions prompt caching {#code-suggestions-prompt-caching}

<!-- categories: Code Suggestions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/project/repository/code_suggestions/_index.md#prompt-caching) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17489)

{{< /details >}}

Code Suggestions는 이제 프롬프트 캐싱을 포함합니다. 프롬프트 캐싱은 캐시된 프롬프트 및 입력 데이터의 재처리를 피함으로써 코드 완성 레이턴시를 크게 개선합니다. 캐시된 데이터는 영구 스토리지에 기록되지 않으며, GitLab Duo 설정에서 프롬프트 캐싱을 선택적으로 비활성화할 수 있습니다.

### Improved Duo Code Review context {#improved-duo-code-review-context}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Review는 이제 개선된 분석을 위해 더욱 포괄적인 컨텍스트를 제공합니다. 주요 개선 사항은 다음과 같습니다:

- 머지 리퀘스트의 제목과 설명을 포함하여 제안된 변경 사항의 목적을 더 잘 이해합니다.
- 모든 diffs를 동시에 검사하여 파일 간 관계를 인식하고 거짓 양성을 줄입니다.
- 변경된 파일의 전체 콘텐츠를 제공하여 수정 사항이 기존 코드 패턴에 어떻게 적합한지 이해합니다.

이러한 개선 사항은 부정확한 제안을 줄이고 더욱 관련성 높고 품질 높은 코드 검토를 제공합니다.

## 규모 및 배포 {#scale-and-deployments}

### List only Enterprise users for contributions reassignment on GitLab.com {#list-only-enterprise-users-for-contributions-reassignment-on-gitlabcom}

<!-- categories: Importers -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/import/direct_transfer_migrations.md#user-membership-mapping) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/510673)

{{< /details >}}

이번 릴리스에서는 사용자 선택 드롭다운을 최상위 그룹과 연결된 엔터프라이즈 사용자만으로 좁혀서 자리표 사용자 매핑 환경을 개선했습니다. 이전에는 GitLab.com으로 가져온 후 사용자의 기여도를 재할당할 때 드롭다운 목록에서 플랫폼의 모든 활성 사용자를 볼 수 있었으므로, 특히 SCIM 프로비저닝이 사용자 이름을 수정한 경우 올바른 사용자를 식별하기가 어려웠습니다. 이제 최상위 그룹이 엔터프라이즈 사용자 기능을 사용하는 경우 드롭다운 목록은 조직에서 확인한 사용자만 표시하므로 사용자 재할당 중 오류 가능성을 크게 줄입니다. 동일한 범위는 CSV 기반 재할당에도 적용되어 조직 외부 사용자로의 실수로 인한 할당을 방지합니다.

### Support for multiple workspaces in the GitLab for Slack app {#support-for-multiple-workspaces-in-the-gitlab-for-slack-app}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/424190)

{{< /details >}}

GitLab for Slack 앱은 이제 GitLab Self-Managed 및 GitLab Dedicated 고객을 위한 여러 워크스페이스를 지원합니다. 여러 워크스페이스를 활성화하면 페더레이션 Slack 환경을 갖춘 조직이 모든 워크스페이스에서 원활한 GitLab 통합을 유지할 수 있습니다. 여러 워크스페이스에 대한 지원을 활성화하려면 GitLab for Slack 앱을 [비공개 배포 앱](https://api.slack.com/distribution#unlisted-distributed-apps)으로 구성하세요.

### Delete groups and placeholder users {#delete-groups-and-placeholder-users}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/import/mapping/post_migration_mapping.md#placeholder-user-deletion) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/473256)

{{< /details >}}

GitLab 18.0에서는 최상위 그룹을 삭제할 때 그룹과 연결된 자리표 사용자도 삭제됩니다. 자리표 사용자가 다른 프로젝트와 연결된 경우 최상위 그룹에서만 제거됩니다. 이렇게 하면 불필요한 자리표 사용자가 다른 프로젝트의 기록이나 기여도를 방해하지 않으면서 제거됩니다.

### Internal releases available for GitLab Dedicated {#internal-releases-available-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](https://handbook.gitlab.com/handbook/engineering/releases/internal-releases/) \| [관련 에픽](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1201)

{{< /details >}}

GitLab Dedicated 고객은 고객의 개발 환경 보호를 위해 엄격한 보안 요구 사항과 규정 준수 의무에 대한 최고 수준의 보호가 필요합니다. 오늘 우리는 공개 전에 GitLab Dedicated 인스턴스를 중요 취약성에 대해 수정할 수 있는 새로운 비공개 릴리스인 Internal Releases를 소개하고 있으며, GitLab Dedicated 고객이 이에 노출되지 않도록 보장합니다. 이 새로운 기능은 GitLab.com에 대한 대응과 동일하게 GitLab에서 발견된 중요 취약성에 대한 즉각적인 보호를 제공합니다. 이 새로운 프로세스는 고객 조치가 필요하지 않습니다.

### GitLab chart 9.0 released with breaking changes {#gitlab-chart-90-released-with-breaking-changes}

<!-- categories: Cloud Native Installation, Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](https://docs.gitlab.com/charts/releases/9_0/) \| [관련 이슈](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5927)

{{< /details >}}

- [Breaking change](../../update/deprecations.md#postgresql-14-and-15-no-longer-supported): PostgreSQL 14 및 15에 대한 지원이 제거되었습니다. 업그레이드하기 전에 PostgreSQL 16을 실행 중인지 확인하세요.
- [Breaking change](../../update/deprecations.md#major-update-of-the-prometheus-subchart): 번들된 Prometheus 차트가 15.3에서 27.11로 업데이트되었습니다. Prometheus 차트 업그레이드와 함께 Prometheus 버전이 2.38에서 3.0으로 업데이트되었습니다. 업그레이드를 수행하려면 수동 단계가 필요합니다. Alertmanager, Node Exporter 또는 Pushgateway를 활성화한 경우 Helm 값도 업데이트해야 합니다. 자세한 내용은 [마이그레이션 가이드](https://docs.gitlab.com/charts/releases/9_0.html#prometheus-upgrade)를 참조하세요.
- [Breaking change](../../update/deprecations.md#fallback-support-for-gitlab-nginx-chart-controller-image-v131): 기본 NGINX 컨트롤러 이미지가 버전 1.3.1에서 1.11.2로 업데이트되었습니다. GitLab NGINX 차트를 사용하고 있으며 자신만의 NGINX RBAC 규칙을 설정한 경우 새로운 RBAC 규칙이 있어야 합니다. 자세한 내용은 [업그레이드 가이드](https://docs.gitlab.com/charts/releases/8_0/#upgrade-to-86x-851-843-836)를 참조하세요.

### Event data collection {#event-data-collection}

<!-- categories: Application Instrumentation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../administration/settings/event_data.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)

{{< /details >}}

GitLab 18.0에서는 GitLab Self-Managed 및 GitLab Dedicated 인스턴스에서 이벤트 수준 제품 사용 데이터 수집을 활성화하고 있습니다. 집계된 데이터와 달리 이벤트 수준 데이터는 GitLab에 사용 패턴을 더 깊이 있게 파악하여 플랫폼의 사용자 경험을 개선하고 기능 채택을 증가시킬 수 있습니다. 데이터 공유 설정을 조정하는 방법에 대한 자세한 지침은 설명서를 참조하세요.

### Deletion protection available for all users {#deletion-protection-available-for-all-users}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../administration/settings/visibility_and_access_controls.md#deletion-protection) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17208) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/526405)

{{< /details >}}

프로젝트 및 그룹 지연 삭제는 이제 Free 티어의 사용자를 포함한 모든 GitLab 사용자가 사용할 수 있습니다. 이 필수 안전 기능은 삭제된 그룹 및 프로젝트가 영구적으로 제거되기 전에 유예 기간(GitLab.com에서 7일)을 추가합니다. 이 기능을 사용하면 복잡한 복구 작업 없이 실수로 삭제된 항목을 복구할 수 있습니다.

데이터 안전을 핵심 기능으로 만들어 GitLab은 데이터 손실 이벤트로부터 작업을 더 잘 보호할 수 있습니다.

### Delayed project deletion for user namespaces {#delayed-project-deletion-for-user-namespaces}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/project/working_with_projects.md#delete-a-project) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/536244)

{{< /details >}}

지연된 프로젝트 삭제는 이제 사용자 네임스페이스의 프로젝트(개인 프로젝트)에서 사용할 수 있습니다. 이전에는 이 실수로 인한 데이터 손실 방지 기능이 그룹 네임스페이스에서만 사용 가능했습니다. 사용자 네임스페이스에서 프로젝트를 삭제하면 즉시 삭제되지 않고 인스턴스 설정에 구성된 기간(GitLab.com에서 7일) 동안 "삭제 대기 중" 상태가 됩니다. 이렇게 하면 필요한 경우 프로젝트를 복원할 수 있는 복구 기간이 생깁니다.

이 개선 사항이 GitLab에서 개인 프로젝트를 관리할 때 더 큰 마음의 평화를 제공하기를 바랍니다.

### New `active` parameter for Groups and Projects REST APIs {#new-active-parameter-for-groups-and-projects-rest-apis}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../api/projects.md#list-projects)

{{< /details >}}

Groups 및 Projects REST API에 새로운 `active` 파라미터를 추가했으며, 이를 통해 상태에 따라 그룹을 필터링하는 것을 간단하게 합니다. `true`로 설정하면 보관되지 않은 그룹 또는 삭제하도록 표시되지 않은 프로젝트만 반환됩니다. `false`로 설정하면 보관된 그룹 또는 삭제하도록 표시된 프로젝트만 반환됩니다. 파라미터가 정의되지 않으면 필터링이 적용되지 않습니다. 이 개선 사항을 통해 간단한 API 호출을 통해 특정 상태를 대상으로 하여 워크플로를 효율적으로 관리할 수 있습니다.

Projects API에 이 파라미터를 추가해주신 [@dagaranupam](https://gitlab.com/dagaranupam)님께 감사합니다.

### Rate limits for Groups, Projects, and Users API {#rate-limits-for-groups-projects-and-users-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)

{{< /details >}}

모든 사용자의 플랫폼 안정성과 성능을 개선하기 위해 프로젝트, 그룹 및 사용자에 대한 API 속도 제한을 추가했습니다. 이러한 변경 사항은 우리의 서비스에 영향을 미친 증가된 API 트래픽에 대한 대응입니다.

제한은 평균 사용 패턴을 기반으로 신중하게 설정되었으며 대부분의 사용 사례에 충분한 용량을 제공해야 합니다. 이러한 제한을 초과하면 "429 Too Many Requests" 응답을 받게 됩니다.

특정 속도 제한 및 구현 정보에 대한 완전한 세부 정보는 [관련 블로그 게시물을 읽어주세요](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/).

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### Security scanners now support MR pipelines {#security-scanners-now-support-mr-pipelines}

<!-- categories: API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/detect/roll_out_security_scanning.md)

{{< /details >}}

이제 [Application Security Testing (AST) 스캐너](../../user/application_security/detect/_index.md)를 [머지 리퀘스트(MR) 파이프라인](../../ci/pipelines/merge_request_pipelines.md)에서 실행하도록 선택할 수 있습니다. 파이프라인에 미치는 영향을 최소화하기 위해 이는 제어할 수 있는 옵트인 동작입니다.

이전에는 기본 동작이 스캐너를 활성화하기 위해 [Stable 또는 Latest CI/CD 템플릿 에디션](../../user/application_security/detect/security_configuration.md#template-editions)을 사용했는지 여부에 따라 결정되었습니다:

- Stable 템플릿에서는 스캔 작업이 브랜치 파이프라인에서만 실행되었습니다. MR 파이프라인은 지원되지 않았습니다.
- Latest 템플릿에서는 MR이 열려 있을 때 스캔 작업이 MR 파이프라인에서 실행되었고, 연결된 MR이 없는 경우 브랜치 파이프라인에서 실행되었습니다. 이 동작을 제어할 수 없었습니다.

이제 새로운 옵션인 `AST_ENABLE_MR_PIPELINES`을 사용하면 MR 파이프라인에서 작업을 실행할지 여부를 제어할 수 있습니다. Stable 및 Latest 템플릿 모두의 기본 동작은 동일하게 유지됩니다. 구체적으로:

- Stable 템플릿은 기본적으로 브랜치 파이프라인에서 스캔 작업을 실행하지만 `AST_ENABLE_MR_PIPELINES: "true"`으로 설정하여 MR이 열려 있을 때 대신 MR 파이프라인을 사용할 수 있습니다.
- Latest 템플릿은 기본적으로 MR이 열려 있을 때 MR 파이프라인에서 스캔 작업을 실행하지만 `AST_ENABLE_MR_PIPELINES: "false"`으로 설정하여 대신 브랜치 파이프라인을 사용할 수 있습니다.

이 개선 사항은 API Discovery(`API-Discovery.gitlab-ci.yml`)를 제외한 모든 보안 스캔 템플릿에 영향을 미치며, 이는 현재 기본적으로 MR 파이프라인을 기본값으로 합니다. 또한 API Discovery 템플릿을 GitLab 18.0의 다른 Stable 템플릿과 정렬하고 기본적으로 브랜치 파이프라인을 사용하도록 변경했습니다.

### Display and filter archived projects in the compliance projects report {#display-and-filter-archived-projects-in-the-compliance-projects-report}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate, Premium
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/compliance/compliance_center/compliance_projects_report.md#filter-the-compliance-projects-report) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/500520)

{{< /details >}}

규정 준수 프로젝트 보고서에서 그룹 또는 하위 그룹 내의 프로젝트에 적용된 규정 준수 프레임워크를 볼 수 있습니다.

그러나 보고서는 프로젝트가 보관되었는지 여부를 표시할 수 없었으며, 이는 활성 및 보관된 프로젝트 전체에서 규정 준수를 관리하기 위한 유용한 정보가 될 수 있습니다.

따라서 프로젝트가 보관되었는지 여부를 표시하는 표시기를 추가했습니다. 이를 통해 활성 및 보관된 프로젝트 전체에서 규정 준수 프레임워크를 검토할 때 더 나은 가시성과 컨텍스트를 제공합니다.

이 기능에는 다음이 포함됩니다:

- 규정 준수 프로젝트 보고서의 각 프로젝트에 대한 보관된 상태 배지로 프로젝트가 보관되었는지 여부를 표시합니다.
- 보관됨, 보관되지 않음 또는 모든 프로젝트 간에 전환할 수 있는 필터입니다.

### Create a workspace from merge requests {#create-a-workspace-from-merge-requests}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/workspace/configuration.md#create-a-workspace)

{{< /details >}}

이제 새로운 **워크스페이스내에서 열기** 옵션으로 머지 리퀘스트에서 직접 워크스페이스를 만들 수 있습니다. 이 기능은 머지 리퀘스트의 브랜치와 컨텍스트로 워크스페이스를 자동으로 구성하여 다음을 수행할 수 있습니다:

- 완전히 구성된 환경에서 코드 변경을 검토합니다.
- 머지 리퀘스트 브랜치에서 테스트를 실행하여 기능을 확인합니다.
- 로컬 설정 없이 머지 리퀘스트에 추가 수정을 합니다.

### View open merge requests targeting files {#view-open-merge-requests-targeting-files}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/project/repository/files/_index.md#view-open-merge-requests-for-a-file) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/448868)

{{< /details >}}

이전에는 코드 파일로 작업할 때 다른 브랜치에서 같은 파일을 수정할 수 있는 다른 사람을 볼 수 없었습니다. 이러한 인식 부족으로 인해 머지 충돌, 중복 작업 및 비효율적인 협업이 발생했습니다.

이제 리포지토리에서 보고 있는 파일을 수정하는 모든 열린 머지 리퀘스트를 쉽게 식별할 수 있습니다. 이 기능은 다음을 도와줍니다:

- 잠재적인 머지 충돌을 발생하기 전에 식별합니다.
- 진행 중인 작업의 중복을 피합니다.
- 진행 중인 변경 사항에 대한 가시성을 제공하여 협업을 개선합니다.

배지는 파일을 수정하는 열린 머지 리퀘스트의 수를 표시하며, 배지 위에 마우스를 올리면 이러한 머지 리퀘스트 목록이 있는 팝오버가 표시됩니다.

### Shared Kubernetes namespace for workspaces {#shared-kubernetes-namespace-for-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/workspace/settings.md#shared_namespace)

{{< /details >}}

이제 공유 Kubernetes 네임스페이스에서 GitLab 워크스페이스를 만들 수 있습니다. 이렇게 하면 모든 워크스페이스에 대해 새 네임스페이스를 만들 필요가 없고 에이전트에 대한 상승된 ClusterRole 권한을 부여할 필요가 없습니다. 이 기능을 사용하면 보안 또는 제한된 환경에서 워크스페이스를 더 쉽게 채택할 수 있으며 더 간단한 확장 경로를 제공합니다.

공유 네임스페이스를 활성화하려면 에이전트 구성 파일에서 `shared_namespace` 필드를 설정하여 모든 워크스페이스에 사용할 Kubernetes 네임스페이스를 지정합니다.

[GitLab의 Co-Create 프로그램](https://about.gitlab.com/community/co-create/)을 통해 이 기능을 구축하는 데 도움을 주신 약 6명의 커뮤니티 기여자들께 감사합니다!

### Improved pod status visualizations in the dashboard for Kubernetes {#improved-pod-status-visualizations-in-the-dashboard-for-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../ci/environments/kubernetes_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/525081)

{{< /details >}}

Kubernetes용 대시보드를 사용하여 배포된 애플리케이션을 모니터링할 수 있습니다. 지금까지 `CrashLoopBackOff` 또는 `ImagePullBackOff`와 같은 컨테이너 오류가 있는 포드는 "Pending" 또는 "Running" 상태로 표시되어 `kubectl`를 사용하지 않고 문제 있는 배포를 식별하기 어렵습니다.

GitLab 18.0에서 UI의 오류 상태는 `kubectl` 출력과 유사한 특정 컨테이너의 상태를 표시합니다. 이제 GitLab 인터페이스를 떠나지 않고 실패한 포드를 빠르게 식별하고 문제를 해결할 수 있습니다.

### Exclude packages from license approval rules {#exclude-packages-from-license-approval-rules}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10203)

{{< /details >}}

머지 리퀘스트 승인 정책에서 라이선스 승인 정책에 대한 이 새로운 개선 사항은 법률 및 규정 준수 팀이 어떤 패키지가 특정 라이선스를 사용할 수 있는지에 대해 더 많은 제어 권한을 제공합니다. 이제 조직의 정책에 의해 정상적으로 차단될 라이선스를 사용하더라도 사전 승인된 패키지에 대한 예외를 만들 수 있습니다.

이전에는 라이선스 승인 정책에서 AGPL-3.0과 같은 라이선스를 차단한 경우 조직 전체의 모든 패키지에 대해 차단되었습니다. 이는 다음과 같은 경우 문제를 야기했습니다:

- 법무 팀이 제한된 라이선스를 사용하는 특정 패키지를 사전 승인했습니다.
- 수백 개의 프로젝트에서 동일한 패키지를 사용해야 했습니다.
- 다양한 팀이 다양한 라이선스 예외를 필요로 했습니다.

이 릴리스를 통해 필요한 예외를 허용하면서 엄격한 라이선스 거버넌스를 유지할 수 있으므로 승인 병목 현상과 수동 검토를 크게 줄일 수 있습니다. 예를 들어 다음을 수행할 수 있습니다:

- Package URL(PURL) 형식을 사용하여 라이선스 승인 규칙에 대한 패키지별 예외를 정의합니다.
- 특정 패키지(또는 패키지 버전)가 제한된 라이선스를 사용하도록 허용합니다.
- 특정 패키지(또는 패키지 버전)가 일반적으로 허용된 라이선스를 사용하지 못하도록 차단합니다.

예외를 추가하려면 라이선스 승인 정책을 만들거나 편집할 때 다음 워크플로우를 따르세요:

1. 그룹에서 **Security & Compliance** > **정책**으로 이동합니다.
1. 라이선스 승인 정책을 만들거나 편집합니다.
1. 시각적 편집기에서 새 패키지 예외 옵션을 찾거나 YAML 모드에서 구성합니다.
1. 라이선스에 대한 allowlist 또는 denylist 모드를 선택합니다.
1. 정책에 특정 라이선스를 추가합니다.
1. 각 라이선스에 대해 PURL 형식으로 패키지 예외를 정의합니다(예: `pkg:npm/@angular/animation@12.3.1`).
1. 라이선스 규칙에서 이러한 패키지를 포함할지 제외할지 지정합니다.

그러면 정책이 라이선스 규칙을 적용하면서 정의된 예외를 존중하여 조직 전체에서 라이선스 규정 준수에 대한 세밀한 제어를 제공합니다.

### Limit maximum user session length {#limit-maximum-user-session-length}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../administration/settings/account_and_limit_settings.md#set-sessions-to-expire-from-creation-date) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/395038)

{{< /details >}}

관리자는 이제 사용자 세션의 최대 길이를 초기 로그인 또는 마지막 활동에서 계산할지 여부를 선택할 수 있습니다. 사용자는 세션이 종료될 것이라는 알림을 받지만 세션이 만료되거나 세션이 연장되는 것을 방지할 수 없습니다. 이 기능은 기본적으로 비활성화되어 있습니다.

기여해주신 [John Parent](https://gitlab.kitware.com/john.parent)에게 감사드립니다!

### GitLab Query Language views enhancements {#gitlab-query-language-views-enhancements}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/glql/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

GitLab Query Language(GLQL) 뷰에 대한 중요한 개선 사항을 만들었습니다. 이러한 개선 사항에는 다음에 대한 지원이 포함됩니다:

- 모든 날짜 유형에 대한 `>=` 및 `<=` 연산자
- 뷰의 **View actions** 드롭다운
- **새로고침** 작업
- 필드 별칭
- GLQL 테이블의 열을 사용자 지정 이름으로 별칭 지정

이 개선 사항과 일반적인 GLQL 뷰에 대한 피드백을 [issue 509791](https://gitlab.com/gitlab-org/gitlab/-/issues/509791)에서 환영합니다.

### Pages template improvements {#pages-template-improvements}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/project/pages/getting_started/pages_new_project_template.md#project-templates)

{{< /details >}}

GitLab은 [인기 있는 정적 사이트 생성기를 위한 템플릿](https://gitlab.com/pages)을 제공합니다. 점수 프레임워크를 사용하여 사용 가능한 템플릿을 심층적으로 살펴본 후 가장 인기 있는 템플릿만 포함하도록 목록을 개선했습니다.

GitLab Pages에서 사용할 수 있는 템플릿을 개선하면 웹사이트 생성 프로세스가 간소화됩니다. 템플릿을 사용하여 최소한의 기술 전문성으로 전문적인 웹사이트를 시작할 수 있습니다. 개선된 템플릿은 또한 현대적이고 반응형 디자인을 제공하여 맞춤 개발 작업이 필요하지 않습니다.

### Configure Jira issues from vulnerabilities using the Jira integration API {#configure-jira-issues-from-vulnerabilities-using-the-jira-integration-api}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../api/project_integrations.md#jira-issues) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/454574)

{{< /details >}}

이전에는 **프로젝트 설정** 페이지에서 [취약성에서 Jira 이슈 만들기](../../integration/jira/configure.md#create-a-jira-issue-for-a-vulnerability)를 구성해야 했습니다.

이제 프로젝트 통합 API에서 이 통합을 구성할 수 있으므로 설정을 자동화할 수 있습니다.

### Improved traceability of redetected vulnerabilities {#improved-traceability-of-redetected-vulnerabilities}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/vulnerabilities/_index.md#vulnerability-status-values) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/523452)

{{< /details >}}

이전에는 확인된 취약성이 재감지되고 상태가 변경된 경우 취약성 세부 정보에서 상태 변경이 발생한 시기와 이유를 나타내는 정보를 제공하지 않았습니다.

GitLab은 이제 확인된 취약성이 새 스캔에서 나타나기 때문에 상태가 변경될 때 취약성 기록에 시스템 노트를 추가합니다. 이 추가 정보는 사용자가 취약성 상태가 변경된 이유를 이해하는 데 도움이 됩니다.

### Bulk add vulnerabilities to issues from the vulnerability report {#bulk-add-vulnerabilities-to-issues-from-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/vulnerability_report/_index.md#add-vulnerabilities-to-an-existing-issue) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13216)

{{< /details >}}

이 릴리스를 통해 이제 취약성 보고서에서 새로운 또는 기존 GitLab 이슈에 대량으로 취약성을 추가할 수 있습니다. 이제 여러 이슈와 취약성을 함께 연결할 수 있습니다. 또한 관련 취약성이 이제 이슈 페이지 내에 나열됩니다.

### Disable user invitations {#disable-user-invitations}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../administration/settings/visibility_and_access_controls.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/19618)

{{< /details >}}

이제 그룹 또는 프로젝트에 멤버를 초대하는 기능을 제거할 수 있습니다.

- GitLab.com에서 이 설정은 엔터프라이즈 사용자가 있는 그룹의 소유자가 구성하며 최상위 그룹 내의 모든 하위 그룹 또는 프로젝트에 적용됩니다. 이 설정이 활성화되어 있는 동안 어떤 사용자도 초대를 보낼 수 없습니다.
- GitLab Self-Managed에서는 관리자가 이 설정을 구성하며 전체 인스턴스에 적용됩니다. 관리자는 여전히 사용자를 직접 초대할 수 있습니다.

이 기능은 조직이 멤버십 액세스에 대한 엄격한 제어를 유지하는 데 도움이 됩니다.

### LDAP authentication with GitLab username {#ldap-authentication-with-gitlab-username}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/auth/ldap/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/215357)

{{< /details >}}

LDAP 사용자는 이제 GitLab 사용자 이름으로 요청을 인증할 수 있습니다. 이전에는 GitLab 사용자 이름이 LDAP 사용자 이름과 일치하지 않는 경우 GitLab이 인증 오류를 반환했습니다. 이 변경 사항은 사용자가 승인 워크플로를 방해하지 않으면서 GitLab 및 LDAP 시스템에서 별도의 명명 규칙을 유지하는 데 도움이 됩니다.

### Support for SHA256 SAML certificates {#support-for-sha256-saml-certificates}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../integration/saml.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/524624)

{{< /details >}}

GitLab은 이제 Group SAML 인증을 위해 SHA1 및 SHA256 인증서 지문을 자동으로 감지하고 지원합니다. 이는 기존 SHA1 지문과의 하위 호환성을 유지하면서 보다 안전한 SHA256 지문에 대한 지원을 추가합니다. 이 업그레이드는 SHA256을 기본값으로 설정할 예정인 ruby-saml 2.x 릴리스에 대비하기 위해 필수적입니다.

### Granular permissions for job tokens in beta {#granular-permissions-for-job-tokens-in-beta}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/jobs/fine_grained_permissions.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16199)

{{< /details >}}

파이프라인 보안이 더욱 유연해졌습니다. 작업 토큰은 파이프라인의 리소스에 액세스할 수 있는 임시 자격증명입니다. 지금까지 이러한 토큰은 사용자로부터 전체 권한을 상속받아 종종 불필요하게 광범위한 액세스 기능을 초래했습니다.

새로운 [작업 토큰에 대한 세밀한 권한](../../ci/jobs/fine_grained_permissions.md) 베타 기능을 통해 작업 토큰이 프로젝트 내에서 액세스할 수 있는 특정 리소스를 정확하게 제어할 수 있습니다. 이를 통해 CI/CD 워크플로에서 최소 권한의 원칙을 구현하여 각 작업이 작업을 완료하는 데 필요한 최소 액세스만 부여할 수 있습니다.

이 기능에 대한 커뮤니티 피드백을 적극적으로 찾고 있습니다. 질문이 있거나 구현 경험을 공유하거나 잠재적 개선에 대해 당사 팀과 직접 상담하고 싶다면 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/519575)를 방문하세요.

### 사용자 지정 역할을 위한 새로운 권한 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/custom_roles/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14746)

{{< /details >}}

[보호 환경 관리](https://gitlab.com/gitlab-org/gitlab/-/issues/471385) 권한으로 사용자 지정 역할을 만들 수 있습니다. 사용자 지정 역할을 통해 사용자가 작업을 완료하는 데 필요한 특정 권한만 부여할 수 있습니다. 이렇게 하면 그룹의 요구에 맞게 조정된 역할을 정의할 수 있으며 Maintainer 또는 Owner 역할이 필요한 사용자 수를 줄일 수 있습니다.

### New CI/CD analytics view for projects in limited availability {#new-cicd-analytics-view-for-projects-in-limited-availability}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../user/analytics/ci_cd_analytics.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/444468)

{{< /details >}}

재설계된 CI/CD 분석 뷰는 개발 팀이 파이프라인 성능과 안정성을 분석, 모니터링 및 최적화하는 방식을 변환합니다. 개발자는 성능 추세 및 안정성 메트릭을 나타내는 GitLab UI의 직관적인 시각화에 액세스할 수 있습니다. 이러한 통찰력을 프로젝트 리포지토리에 포함시키면 개발자 플로우를 방해하는 컨텍스트 전환이 제거됩니다. 팀은 생산성을 떨어뜨리는 파이프라인 병목 현상을 식별하고 해결할 수 있습니다. 이 개선 사항은 더 빠른 개발 주기, 향상된 협업 및 GitLab에서 CI/CD 워크플로를 최적화하기 위한 데이터 기반 자신감으로 이어집니다.

### GitLab 러너 18.0 {#gitlab-runner-180}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab 러너 18.0도 출시하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [`ConfigurationError` 및 `ExitCodeInvalidConfiguration`을 GitLab 러너 빌드 오류 분류에 추가](https://gitlab.com/gitlab-org/gitlab/-/issues/514297)
- [클라우드 스토리지에 대한 실패한 캐시 업로드에 대한 클라우드 공급자 오류 메시지 개선](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5527)

#### 버그 수정 {#bug-fixes}

- [GitLab 러너가 허용되지 않은 경우에도 캐시된 이미지를 사용할 수 있습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38706)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.0)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
