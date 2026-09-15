---
stage: Release Notes
group: Monthly Release
date: 2024-04-18
title: "GitLab 16.11 릴리스 정보"
description: "GitLab 16.11이 GitLab Duo Chat 일반 공개로 출시됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 4월 18일에 GitLab 16.11이 다음의 기능들과 함께 출시되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

[Ivan Shtyrliaiev](https://gitlab.com/bahek2462774)는 2024년 지금까지 GitLab에 [여섯 가지 기여](https://gitlab.com/groups/gitlab-org/-/merge_requests?scope=all&state=merged&author_username=bahek2462774)를 했습니다. 그는 GitLab의 Principal Product Manager인 [Hannah Sutor](https://gitlab.com/hsutor)에 의해 추천되었으며, [사용자 목록 검색 및 필터 환경 개선](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144907)에 대한 기여를 강조했습니다.

"이것은 가로로 스크롤 가능한 탭 목록에서 2개의 탭과 검색 상자만 있는 훨씬 더 우아한 UX로 변경하는 데 도움이 되는 엄청난 사용자 환경 개선입니다"라고 Hannah가 말했습니다. "이제 사용자는 탭을 가로로 스크롤하지 않고 검색 상자를 통해 필터링할 수 있습니다!"

Ivan은 이 어려운 요청을 처리하고, GitLab UX 팀과 협력하여 제안을 개선하며, 리뷰에 매우 신속하게 대응한 것으로 인정되었습니다. GitLab의 Engineering Manager인 [Adil Farrukh](https://gitlab.com/adil.farrukh)는 추천을 지지했으며, 이 기능이 간단하지 않았고 Ivan이 피드백에 매우 신속하게 대응했다고 지적했습니다. [Eduardo Sanz García](https://gitlab.com/eduardosanz), Sr. GitLab의 Frontend Engineer도 추천을 지지했으며 Ivan의 회복력을 칭찬했습니다.

"Eduardo의 리뷰와 기여가 일어나도록 많은 노력을 기울인 GitLab 팀에 정말 감사합니다"라고 Ivan이 말했습니다. "매우 도움이 되었고 이것이 얼마나 많은 시간이 걸리는지 깨달았습니다."

Ivan은 [Politico](https://www.politico.com/)의 프런트엔드 소프트웨어 엔지니어입니다.

[Baptiste Lalanne](https://gitlab.com/BaptisteLalanne)는 거의 70개의 업보트가 있는 3년 된 이슈를 처리하여 CI/CD 구성에 `retry:exit codes`을 추가하는 [매우 요청이 많던 기능](https://gitlab.com/gitlab-org/gitlab/-/issues/262674)을 기여했습니다. 이 기여는 실패한 파이프라인 작업 및 다양한 종료 코드를 가진 작업을 관리하는 데 있어 향상된 유연성으로 사용자를 지원합니다.

Baptiste는 GitLab의 Product Manager인 [Dov Hershkovitch](https://gitlab.com/dhershkovitch)에 의해 추천되었습니다. "Baptiste의 이 프로젝트에 대한 근면한 작업은 단순한 구현을 넘어 갔습니다"라고 Dov가 말했습니다. "이 성취는 우리 커뮤니티의 협력 강점의 훌륭한 예입니다. Baptiste의 노력을 통해 GitLab은 중요한 필요를 충족했을 뿐만 아니라 개방성과 투명성에 대한 약속을 강화하여 우리의 오픈코어 멘탈리티를 풍요롭게 했습니다."

"이것은 따뜻하고 정말 감사합니다"라고 Baptiste가 말했습니다. "저는 정말로 여가 시간에 계속 기여하고 싶습니다. 저는 정말 좋아합니다."

지난 1년 동안 Baptiste는 GitLab에 6개의 머지 리퀘스트를 병합했으며 다음으로는 [GitLab Runner에 기여](https://docs.gitlab.com/runner/development/)할 계획입니다. Baptiste는 [DataDog](https://www.datadoghq.com/)의 소프트웨어 엔지니어입니다.

최신 MVP인 Ivan과 Baptiste, 그리고 GitLab 커뮤니티의 나머지 기여자분들께 대단히 감사합니다! 🙌

## 주요 기능 {#primary-features}

### GitLab Duo Chat 일반 공개 {#gitlab-duo-chat-now-generally-available}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/gitlab_duo_chat/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13516)

{{< /details >}}

GitLab Duo Chat은 이제 일반 공개되었습니다. 이 릴리스의 일부로 다음과 같은 기능도 일반 공개됩니다:

- 코드 설명은 개발자와 기술 수준이 낮은 사용자가 낯선 코드를 더 빨리 이해하는 데 도움이 됩니다.
- 코드 리팩토링을 통해 개발자는 기존 코드를 단순화하고 개선할 수 있습니다.
- 테스트 생성은 반복적인 작업을 자동화하고 팀이 버그를 더 빨리 찾을 수 있도록 도와줍니다.

사용자는 GitLab UI, Web IDE, VS Code 또는 JetBrains IDE에서 GitLab Duo Chat에 접근할 수 있습니다.

GitLab Duo Chat의 이 릴리스에 대한 자세한 내용은 이 [블로그 게시물](https://about.gitlab.com/blog/gitlab-duo-chat-now-generally-available/)을 참조하세요.

Chat은 현재 모든 Ultimate 및 Premium 사용자가 자유롭게 사용할 수 있습니다. 인스턴스 관리자, 그룹 소유자 및 프로젝트 소유자는 [Duo 기능이 데이터에 접근하고 처리하는 것을 제한](../../user/gitlab_duo/turn_on_off.md)하도록 선택할 수 있습니다.

GitLab Duo Chat은 [GitLab Duo Pro](https://about.gitlab.com/gitlab-duo/#pricing)의 일부입니다. Chat 베타 사용자들이 GitLab Duo Pro를 아직 구매하지 않았을 경우의 전환을 쉽게 하기 위해, Duo Chat은 기존 Premium 및 Ultimate 고객(추가 기능 없음)에게 잠시 계속 이용 가능할 것입니다. Duo Pro 구독자에 대한 액세스 제한 시기는 나중에 공지할 예정입니다.

채팅의 피드백 버튼을 클릭하거나 이슈를 생성하여 GitLab Duo Chat을 언급함으로써 자유롭게 생각을 공유하세요. 여러분의 의견을 듣고 싶습니다!

### GitLab Duo Chat이 JetBrains IDE에서 사용 가능 {#gitlab-duo-chat-available-in-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../editor_extensions/jetbrains_ide/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/307)

{{< /details >}}

GitLab Duo Chat이 JetBrains IDE에서 사용 가능해졌음을 알려드리게 되어 기쁩니다.

GitLab의 AI 기능의 일부로서, Duo Chat은 지원하는 모든 JetBrains IDE로 직접 대화형 채팅 창을 가져오고 코드를 설명하고, 테스트를 작성하고, 기존 코드를 리팩토링할 수 있는 기능으로 개발자 경험을 더욱 간소화합니다.

전체 기능 목록은 [Duo Chat 설명서](../../user/gitlab_duo_chat/_index.md)를 참조하세요.

### 보안 정책 범위 {#security-policy-scopes}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/policies/scan_execution_policies.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/5510)

{{< /details >}}

정책 범위 지정은 정책에 대한 세밀한 관리 및 적용을 제공합니다. 머지 리퀘스트 승인(스캔 결과) 정책 및 스캔 실행 정책 모두에서, 이 새로운 기능을 통해 보안 및 규정 준수 팀은 정책 적용을 규정 준수 프레임워크 또는 그룹의 포함/제외 프로젝트 세트로 범위 지정할 수 있습니다.

현재 보안 정책 프로젝트에서 관리하는 모든 정책이 연결된 모든 그룹, 하위 그룹 및 프로젝트에 적용되는 동안, 정책 범위 지정을 통해 정책별로 해당 적용을 개선할 수 있습니다. 이를 통해 보안 및 규정 준수 팀은 다음을 수행할 수 있습니다:

- 조직 전체에서 정책을 더 쉽게 중앙 집중식으로 관리하면서도 정책을 세밀하게 적용합니다.
- GitLab에서 구현하고 적용 중인 컨트롤이 정의한 규정 준수 프레임워크로 어떻게 롤업되는지 더 잘 이해합니다.
- 규정 준수 센터를 통해 규정 준수 프레임워크에 연결된 정책을 보고 관리합니다.
- 보안 및 규정 준수 상태를 더 잘 정리하고 이해합니다.

### Product Analytics로 사용자를 더 잘 이해하세요 {#understand-your-users-better-with-product-analytics}

<!-- categories: Product Analytics -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/analytics/productivity_analytics.md)

{{< /details >}}

애플리케이션에 대한 사용자의 참여 방식을 이해하는 것은 향후 혁신 및 최적화에 대한 데이터 기반의 의사 결정을 내리기 위해 중요합니다. 상위 비즈니스 핵심 URL의 사용량이 증가하고 있는지, 월간 활성 사용자에서 비정상적인 감소가 있는지, 모바일 Android 기기를 사용하는 고객이 더 많은지 보고 있습니까? 이와 같은 질문에 대한 답변이 있고 GitLab 플랫폼에서 엔지니어링 팀에 접근 가능하게 함으로써 팀은 개발 작업이 사용자 결과에 어떻게 영향을 미치는지 동기화 상태를 유지할 수 있습니다.

GitLab의 새로운 Product Analytics 기능을 통해 애플리케이션을 계측하고, 사용자에 대한 주요 사용량 및 채택 데이터를 수집한 다음 GitLab 내에 표시할 수 있습니다. 대시보드의 데이터를 시각화하고, 보고하고, 다양한 방식으로 필터링하여 사용자에 대한 인사이트를 찾을 수 있습니다. 팀은 이제 고객 사용량의 예상치 못한 하락 또는 급증을 빠르게 식별하고 대응할 수 있으며, 최근 릴리스의 성공을 축하할 수도 있습니다.

Product Analytics를 사용하려면 이 [helm 차트](https://gitlab.com/gitlab-org/analytics-section/product-analytics/helm-charts)를 설치하기 위해 Kubernetes 클러스터가 필요하며 애플리케이션을 계측하여 트래픽을 전송해야 합니다. 그러면 GitLab은 클러스터에 연결하여 시각화를 위한 데이터를 검색합니다.

### 엔터프라이즈 사용자의 개인 액세스 토큰 비활성화 {#disable-personal-access-tokens-for-enterprise-users}

<!-- categories: User Management -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/profile/personal_access_tokens.md#disable-personal-access-tokens-for-enterprise-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)

{{< /details >}}

GitLab.com 그룹 소유자는 이제 그룹의 모든 엔터프라이즈 사용자에 대한 개인 액세스 토큰의 생성 및 사용을 비활성화할 수 있습니다. 개인 액세스 토큰과 관련된 강력한 권한으로 인해 일부 소유자는 보안상의 이유로 이러한 토큰을 비활성화하려고 할 수 있습니다.

이 세밀한 제어는 GitLab.com의 보안과 접근성의 균형을 맞추는 데 있어 옵션을 제공합니다.

### 위키 페이지로의 링크에 대한 자동완성 지원 {#autocomplete-support-for-links-to-wiki-pages}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/markdown.md#gitlab-specific-references) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/442229)

{{< /details >}}

GitLab 16.11에서 위키 페이지로의 링크에 대한 자동완성 지원을 제공하게 되어 기쁩니다! 이 새로운 기능을 통해 에픽과 이슈에서 위키 페이지로 링크하는 것이 이전보다 훨씬 쉬워졌습니다. 단 몇 번의 키 입력만으로 가능합니다.

에픽 및 이슈 댓글에 위키 페이지 URL을 복사하여 붙여넣어야 했던 시대는 지났습니다. 이제 위키 페이지가 있는 그룹 또는 프로젝트로 이동하고, 에픽 또는 이슈에 접근하고, 자동완성 바로 가기를 사용하여 에픽 또는 이슈에서 위키 페이지로 원활하게 링크하세요!

### 프로젝트 개요 페이지의 메타데이터를 위한 사이드바 {#sidebar-for-metadata-on-the-project-overview-page}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/working_with_projects.md)

{{< /details >}}

프로젝트 개요 페이지를 재설계했습니다. 이제 모든 프로젝트 정보 및 링크를 여러 영역이 아닌 하나의 사이드바에서 찾을 수 있습니다.

### Switchboard를 사용하여 변경한 내용에 대한 이메일 알림 {#email-notifications-for-changes-made-using-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../administration/dedicated/configure_instance/users_notifications.md) \| [관련 이슈](https://about.gitlab.com/dedicated/)

{{< /details >}}

Switchboard를 사용하여 테넌트 관리자가 GitLab Dedicated 인스턴스에 대해 만든 구성 변경 사항은 이제 완료되면 이메일 알림을 생성합니다.

Switchboard에서 테넌트를 보거나 편집할 수 있는 모든 사용자는 각 변경 사항에 대한 알림을 받습니다.

### 작업이 실패하면 파이프라인을 즉시 취소하는 옵션 {#option-to-cancel-a-pipeline-immediately-if-any-jobs-fails}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#workflowauto_cancelon_job_failure) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)

{{< /details >}}

작업이 실패한 것을 알게 된 후에는 실패 원인을 작업하는 동안 리소스를 절약하기 위해 파이프라인의 나머지 부분을 수동으로 취소할 수도 있습니다. GitLab 16.11을 사용하면 작업이 실패할 때 파이프라인을 자동으로 취소하도록 구성할 수 있습니다. 실행 시간이 오래 걸리는 큰 파이프라인, 특히 병렬로 실행되는 많은 오래 실행되는 작업이 있는 경우 이것은 리소스 사용량과 비용을 줄이는 효과적인 방법입니다.

파이프라인이 즉시 [다운스트림 파이프라인이 실패하면 취소](../../ci/pipelines/downstream_pipelines.md#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline)하도록 구성할 수도 있으며, 이는 상위 파이프라인 및 다른 모든 다운스트림 파이프라인을 취소합니다.

기능에 기여해주신 [Marco](https://gitlab.com/zillemarco)에게 특별히 감사합니다!

## 규모 및 배포 {#scale-and-deployments}

### Omnibus 개선 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 17.0에서 PostgreSQL의 최소 지원 버전은 14가 됩니다. 이 변경을 준비하기 위해 GitLab 16.11에서 `attempt_auto_pg_upgrade?` 설정을 `true`로 변경했으며, 이것은 PostgreSQL 버전을 14로 자동 업그레이드하려고 시도합니다. 이 프로세스는 마지막으로 최소 지원 PostgreSQL 버전을 상향 조정한 때와 동일합니다.

### 업데이트된 프로젝트 아카이빙 기능 {#updated-project-archiving-functionality}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/working_with_projects.md#archive-a-project)

{{< /details >}}

이제 프로젝트 목록에서 아카이브된 프로젝트를 더 쉽게 식별할 수 있습니다. 16.11부터 아카이브된 프로젝트는 그룹 개요의 **아카이빙됨** 탭에 **아카이빙됨** 배지를 표시합니다. 이 배지는 또한 프로젝트 개요 페이지의 프로젝트 제목의 일부입니다.

경고 메시지는 아카이브된 프로젝트가 읽기 전용임을 명확히 합니다. 이 메시지는 아카이브된 프로젝트의 하위 페이지에서 작업할 때도 이 컨텍스트가 손실되지 않도록 모든 프로젝트 페이지에 표시됩니다.

또한 그룹을 삭제할 때 확인 모달은 이제 실수로 인한 삭제를 방지하기 위해 아카이브된 프로젝트의 수를 나열합니다.

### 사용자 정의 웹후크 헤더 {#custom-webhook-headers}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhooks.md#custom-headers) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/17290)

{{< /details >}}

이전에는 GitLab 웹후크가 사용자 정의 헤더를 지원하지 않았습니다. 이는 특정 이름의 헤더에서 인증 토큰을 수락하는 시스템과 함께 사용할 수 없다는 의미였습니다.

이 릴리스에서 웹후크를 만들거나 편집할 때 최대 20개의 사용자 정의 헤더를 추가할 수 있습니다. 외부 서비스에 대한 인증을 위해 이러한 사용자 정의 헤더를 사용할 수 있습니다.

이 기능과 GitLab 16.10에서 도입된 [사용자 정의 웹후크 템플릿](../../user/project/integrations/webhooks.md#custom-webhook-template)을 통해 이제 사용자 정의 웹후크를 완전히 설계할 수 있습니다. 웹후크를 다음과 같이 구성할 수 있습니다:

- 사용자 정의 페이로드를 게시합니다.
- 필요한 인증 헤더를 추가합니다.

시크릿 토큰 및 URL 변수처럼 대상 URL이 변경되면 사용자 정의 헤더가 재설정됩니다.

이 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146702)를 주신 [Niklas](https://gitlab.com/Taucher2003)에게 감사합니다!

### REST API로 프로젝트 후크 테스트 {#test-project-hooks-with-the-rest-api}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/projects.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/25329)

{{< /details >}}

이전에는 GitLab UI에서만 프로젝트 후크를 테스트할 수 있었습니다. 이 릴리스에서는 REST API를 사용하여 지정된 프로젝트에 대한 테스트 후크를 트리거할 수 있습니다.

이 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147656)를 주신 [Phawin](https://gitlab.com/lifez)에게 감사합니다!

### 그룹 및 인스턴스에 대해 구성 가능한 GitLab for Slack 앱 {#gitlab-for-slack-app-configurable-for-groups-and-instances}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/gitlab_slack_application.md#from-the-project-or-group-settings) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/391526)

{{< /details >}}

이전에는 한 번에 하나의 프로젝트에 대해서만 GitLab for Slack 앱을 구성할 수 있었습니다. 이 릴리스에서는 이제 그룹 또는 인스턴스에 대해 통합을 구성하고 한 번에 많은 프로젝트에 대한 변경을 할 수 있습니다.

이 개선으로 GitLab for Slack 앱이 더 이상 지원되지 않는 [Slack 알림 통합](../../user/project/integrations/slack.md)과 기능 동등성에 더 가까워집니다.

### 구성 가능한 import 작업 제한 {#configurable-import-jobs-limit}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/settings/import_and_export_settings.md#maximum-number-of-simultaneous-import-jobs) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/439286)

{{< /details >}}

지금까지 다음의 import 작업의 최대 수는:

- GitHub importer는 1000이었습니다.
- Bitbucket Cloud 및 Bitbucket Server importer는 100이었습니다.

이러한 제한은 하드 코딩되어 있었으며 변경할 수 없었습니다. 이러한 제한은 import 작업이 대기열에 추가된 것과 같은 속도로 처리될 수 있도록 할 충분하지 않을 수 있기 때문에 import 속도를 늦출 수 있었습니다.

이 릴리스에서는 하드 코딩된 제한을 애플리케이션 설정으로 이동했습니다. GitLab.com의 이러한 제한을 증가시키지는 않지만, 자체 관리되는 GitLab 인스턴스의 관리자는 이제 자신의 필요에 따라 import 작업의 수를 구성할 수 있습니다.

### GitLab Duo로 Product Analytics 데이터 탐색 {#explore-your-product-analytics-data-with-gitlab-duo}

<!-- categories: Product Analytics -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/analytics/productivity_analytics.md)

{{< /details >}}

[Product Analytics는 이제 일반 공개되었으며](https://docs.gitlab.com/#understand-your-users-better-with-product-analytics), 이 릴리스에는 [사용자 정의 시각화 디자이너](../../user/analytics/analytics_dashboards.md)가 포함됩니다. 이를 사용하여 애플리케이션 이벤트 데이터를 탐색하고 대시보드를 구축하여 고객의 사용량 및 채택 패턴을 이해할 수 있습니다.

시각화 디자이너에서 이제 GitLab Duo에 평문 요청을 입력하여 시각화를 빌드하도록 요청할 수 있습니다. 예를 들어 "2024년 월간 활성 사용자 수 표시" 또는 "이번 주 상위 URL 나열"입니다.

Product Analytics의 GitLab Duo는 실험 기능으로 사용할 수 있습니다.

사용자 정의 시각화 디자이너에서 GitLab Duo와 함께 경험하는 것에 대한 피드백을 제공하여 이 기능을 성숙하게 하는 데 도움을 줄 수 있습니다. 이 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/455363)에서 피드백을 제공하세요.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 그룹 댓글 템플릿 {#group-comment-templates}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/comment_templates.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/440817)

{{< /details >}}

조직 전체에서 이슈, 에픽 또는 머지 리퀘스트에 동일한 템플릿 응답을 사용하는 것이 도움이 될 수 있습니다. 이러한 응답은 답변이 필요한 표준 질문, 일반적인 문제에 대한 응답 또는 머지 리퀘스트 리뷰 댓글의 구조를 포함할 수 있습니다.

그룹 댓글 템플릿을 통해 GitLab 전체의 댓글 상자에 적용할 수 있는 저장된 응답을 생성하여 워크플로우 속도를 높일 수 있습니다. 이 새로운 댓글 템플릿 추가를 통해 조직은 중앙 집중식으로 템플릿을 생성하고 관리할 수 있으므로 모든 사용자가 동일한 템플릿의 이점을 얻을 수 있습니다.

댓글 템플릿을 생성하려면 GitLab의 모든 댓글 상자로 이동하여 **댓글 템플릿 삽입 > Manage group comment templates**를 선택하세요. 댓글 템플릿을 생성하면 모든 그룹 멤버가 사용할 수 있습니다. 댓글을 작성할 때 **댓글 템플릿 삽입** 아이콘을 선택하면 저장된 응답이 적용됩니다.

댓글 템플릿의 이 다음 반복에 대해 정말 기대하며 곧 [프로젝트 수준 댓글 템플릿](https://gitlab.com/gitlab-org/gitlab/-/issues/440818)도 추가할 예정입니다. 피드백이 있으시면 [이슈 45120](https://gitlab.com/gitlab-org/gitlab/-/issues/451520)에 남겨주세요.

### Auto DevOps의 빌드 단계 업그레이드됨 {#build-step-of-auto-devops-upgraded}

<!-- categories: Auto DevOps -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../topics/autodevops/troubleshooting.md#builder-sunset-error) \| [관련 이슈](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image/-/issues/73)

{{< /details >}}

Auto DevOps의 Auto Build 구성 요소에서 사용하는 `heroku/buildpacks:20` 이미지가 업스트림에서 더 이상 지원되므로 `heroku/builder:20` 이미지로 이동합니다.

이 주요 변경 사항은 GitLab 주요 릴리스 외부에서 제공되어 업스트림의 주요 변경 사항을 수용합니다. 이 업그레이드로 파이프라인이 손상될 가능성은 낮습니다. 임시 해결 방법으로 `heroku/builder:20` 이미지를 수동으로 구성하고 [빌더 종료 오류를 건너뛸](../../topics/autodevops/troubleshooting.md#skipping-errors) 수 있습니다.

또한 GitLab 17.0에서 `heroku/builder:20`에서 `heroku/builder:22`로 또 다른 주요 업그레이드를 계획 중입니다.

### 사용자 목록 검색 및 필터 개선 {#users-list-search-and-filter-improvements}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/admin_area.md#administering-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)

{{< /details >}}

Admin Area 사용자 페이지가 개선되었습니다.

이전에는 탭이 사용자 목록의 맨 위에 가로로 흩어져 있어 원하는 필터로 이동하기 어려웠습니다.

이제 필터가 검색 상자에 통합되어 사용자를 검색하고 필터링하기가 훨씬 더 쉬워졌습니다.

기여해주신 [Ivan Shtyrliaiev](https://www.linkedin.com/in/bahek2462774/)에게 감사합니다!

### 만료되는 그룹 및 프로젝트 액세스 토큰에 대한 웹후크 알림 {#webhook-notifications-for-expiring-group-and-project-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhook_events.md#project-and-group-access-token-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/426147)

{{< /details >}}

프로젝트 및 그룹 액세스 토큰에 대한 웹후크 이벤트를 이제 사용할 수 있습니다.

이전에는 만료되는 토큰에 대한 알림을 받는 유일한 방법은 이메일이었습니다. 웹후크 이벤트는 트리거되면 액세스 토큰이 만료되기 7일 전에 트리거됩니다.

### 규정 준수 프레임워크에 연결된 보안 정책 표시 {#display-linked-security-policies-in-compliance-frameworks}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_frameworks/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11480)

{{< /details >}}

규정 준수 센터가 규정 준수 관리자를 위한 전쟁터가 되면서 이제 규정 준수 프레임워크를 관리할 수 있으며 보안 정책을 통해 생성되고 규정 준수 프레임워크에 연결된 컨트롤에 대한 인사이트를 얻을 수 있습니다.

규정 준수 대상인 프로젝트에서 실행되도록 보안 스캐너를 적용하고, 2인 승인을 강제하거나, 이러한 광범위한 컨트롤을 통해 취약성 관리 워크플로우를 활성화한 다음 규정 준수 프레임워크로 롤업하여 프레임워크 내의 관련 프로젝트가 컨트롤에 의해 적절히 강제되도록 합니다.

### API로 애플리케이션 시크릿 갱신 {#renew-application-secret-with-api}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../api/applications.md#renew-an-application-secret) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/422420)

{{< /details >}}

이제 Applications API를 사용하여 애플리케이션 시크릿을 갱신할 수 있습니다. 이전에는 UI를 사용해야 했습니다. 이제 API를 사용하여 프로그래밍 방식으로 시크릿을 회전할 수 있습니다.

기여해주신 [Phawin](https://gitlab.com/lifez)에게 감사합니다!

### 위반 데이터로 정책 봇 댓글 확장 {#extend-policy-bot-comment-with-violation-data}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/policies/merge_request_approval_policies.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/433403)

{{< /details >}}

보안 정책 봇은 정책이 프로젝트에 적용될 때, 평가가 완료될 때, MR을 차단하는 위반이 있는 경우를 이해하기 위해 사용자에게 컨텍스트를 제공하며 이를 해결하기 위한 지침을 제공합니다. 이제 봇 댓글의 지원을 확장하여 MR이 정책에 의해 차단될 수 있는 이유에 대한 추가 통찰력을 제공하며 해결 방법에 대한 더 세밀한 피드백을 제공합니다. 댓글로 제공되는 세부 정보에는:

- MR을 특히 차단하는 보안 결과
- 정책 외 라이센스
- "fail closed"로 기본 설정되고 차단 동작이 발생할 수 있는 정책 오류
- 보안 결과의 평가에서 고려 중인 파이프라인에 대한 세부 정보

이러한 추가 세부 정보를 통해 MR의 상태를 더 빨리 파악하고 자가 진단으로 모든 이슈를 해결할 수 있습니다.

### 워크로드 ID 페더레이션으로 Google Cloud에 인증 {#authenticate-to-google-cloud-with-workload-identity-federation}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../integration/google_cloud_iam.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/12758)

{{< /details >}}

워크로드 ID 페더레이션을 통해 서비스 계정 키를 사용하지 않고 GitLab과 Google Cloud 간에 워크로드를 안전하게 연결할 수 있습니다. 이는 보안을 개선합니다. 키는 공격에 대한 벡터를 노출하는 오래 지속되는 자격 증명일 수 있기 때문입니다. 키는 또한 생성, 보안 유지 및 회전을 위한 관리 오버헤드가 발생합니다.

워크로드 ID 페더레이션을 통해 GitLab과 Google Cloud 간에 IAM 역할을 매핑할 수 있습니다.

이 기능은 베타 상태이며 현재 GitLab.com에서만 사용 가능합니다.

### 중복 보안 정책 이슈 해결됨 {#issue-with-duplicate-security-policies-resolved}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/policies/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/416903)

{{< /details >}}

GitLab 16.9 이전 버전에서는 프로젝트가 부모 그룹 또는 하위 그룹에서 보안 정책을 상속받고 동일한 보안 정책 프로젝트에 링크하는 것이 가능했습니다. 그 결과 정책이 정책 목록에서 중복되었습니다.

이 이슈는 해결되었으며 이제 정책이 이미 상속되는 보안 정책 프로젝트에 링크할 수 없습니다.

### 더 많은 사용자 이름 옵션 {#more-username-options}

<!-- categories: User Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/_index.md#change-your-username) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/429283)

{{< /details >}}

사용자 이름에는 비악센트 문자, 숫자, 언더스코어(`_`), 하이픈(`-`) 및 마침표(`.`)만 포함될 수 있습니다. 사용자 이름은 하이픈(`-`)으로 시작하거나 마침표(`.`), `.git` 또는 `.atom`로 끝날 수 없습니다.

사용자 이름 검증은 이제 이 조건을 더 정확하게 설명합니다. 이 개선된 검증은 사용자 이름을 선택할 때 옵션을 더 명확하게 파악할 수 있음을 의미합니다.

기여해주신 [Justin Zeng](https://www.linkedin.com/in/jzeng88/)에게 감사합니다!

### 사이드바에서 GitLab Pages 가시성 개선 {#improved-gitlab-pages-visibility-in-sidebar}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/pages/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/18027)

{{< /details >}}

이전 릴리스에서는 GitLab Pages 사이트가 있는 프로젝트의 경우 사이트 URL을 찾기 어려웠습니다.

GitLab 16.11부터 오른쪽 사이드바에 사이트로의 바로 가기 링크가 있으므로 문서를 확인할 필요 없이 URL을 찾을 수 있습니다.

### Google Artifact Registry를 GitLab 프로젝트에 연결 {#connect-google-artifact-registry-to-your-gitlab-project}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Silver, Gold
- 링크: [설명서](../../user/project/integrations/google_artifact_management.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/12365)

{{< /details >}}

GitLab 컨테이너 레지스트리를 사용하여 소스 코드 및 파이프라인과 함께 Docker 및 OCI 이미지를 보고, 푸시하고, 풀할 수 있습니다. 많은 GitLab 고객의 경우 이것은 `test` 및 `build` 단계 동안 컨테이너 이미지에 대해 잘 작동합니다. 하지만 조직이 프로덕션 이미지를 Google과 같은 클라우드 공급자에게 게시하는 것이 일반적입니다.

이전에는 GitLab에서 Google Artifact Registry로 이미지를 푸시하려면 Artifact Registry에 연결하고 배포할 사용자 정의 스크립트를 만들고 유지 관리해야 했습니다. 이것은 비효율적이고 오류가 발생하기 쉬웠습니다. 또한 모든 컨테이너 이미지를 전체적으로 볼 수 있는 쉬운 방법이 없었습니다.

이제 새로운 Google Artifact Management 기능을 활용하여 GitLab 프로젝트를 Artifact Registry 리포지토리에 쉽게 연결할 수 있습니다. 그런 다음 GitLab CI/CD 파이프라인을 사용하여 Artifact Registry에 이미지를 게시할 수 있습니다. **배포 > Google Artifact Registry**로 이동하여 Artifact Registry에 게시된 이미지를 GitLab에서 볼 수도 있습니다. 이미지에 대한 세부 정보를 보려면 이미지를 선택하기만 하면 됩니다.

이 기능은 베타 상태이며 현재 GitLab.com에서만 사용 가능합니다.

### 색상을 사용하여 에픽을 시각적으로 구분 {#visually-distinguish-epics-using-colors}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/group/epics/manage_epics.md#epic-color) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9033)

{{< /details >}}

조직 전체에서 포트폴리오 관리 기능을 사용하는 능력을 더욱 개선하기 위해 이제 [로드맵](../../user/group/roadmap/_index.md) 및 [에픽 보드](../../user/group/epics/epic_boards.md)에서 색상을 사용하여 에픽을 구분할 수 있습니다.

이 경량이지만 다재다능한 기능을 통해 그룹 소유권, 수명 주기의 단계, 성숙도를 향한 개발 또는 다른 많은 분류 사이를 빠르게 구분합니다.

### 가치 흐름 이벤트는 이제 누적으로 계산할 수 있습니다 {#value-stream-events-can-now-be-calculated-cumulatively}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/value_stream_analytics/_index.md#cumulative-label-event-duration) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/12088)

{{< /details >}}

레이블 이벤트 간의 기간을 계산하는 더 견고한 방법을 도입했습니다. 이 변경은 개발에서 검토 상태 사이를 오가며 머지 리퀘스트의 레이블 변경과 같이 이벤트가 여러 번 발생하는 시나리오를 수용합니다. 이전에는 기간이 첫 번째와 마지막 레이블 이벤트 간의 경과 시간으로 계산되었습니다.

이제 기간이 누적 시간으로 계산되므로 이슈 또는 머지 리퀘스트가 주어진 레이블을 가진 시간만 올바르게 나타냅니다.

### 종속성 검사 SBOM에 대한 종속성 그래프 지원 {#dependency-graph-support-for-dependency-scanning-sboms}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_list/_index.md) \| [관련 에픽](https://gitlab.com/gitlab-org/gitlab/-/issues/366168)

{{< /details >}}

사용자는 종속성 검사 보고서의 일부로 생성된 CycloneDX SBOM의 종속성 그래프 정보에 접근할 수 있습니다. 종속성 그래프 정보는 다음 패키지 관리자에 사용 가능합니다:

- NuGet
- Yarn 1.x
- sbt
- Conan

### Yarn v4에 대한 종속성 검사 지원 {#dependency-scanning-support-for-yarn-v4}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) \| [관련 에픽](https://gitlab.com/gitlab-org/gitlab/-/issues/431752)

{{< /details >}}

종속성 검사는 Yarn v4를 지원합니다. 이 개선으로 분석기가 Yarn v4 잠금 파일을 구문 분석할 수 있습니다.

### DAST 분석기 성능 업데이트 {#dast-analyzer-performance-updates}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/application_security/dast/browser/_index.md) \| [관련 이슈](https://gitlab.com/groups/gitlab-org/-/epics/12194)

{{< /details >}}

16.11 릴리스 마일스톤 동안 다음 DAST 개선을 완료했습니다:

- 탐색기 성능을 개선하기 위해 탐색 경로를 잘라냈으며, 벤치마크 테스트에 따라 스캔 시간을 20% 줄였습니다. 자세한 내용은 [이슈를 참조](https://gitlab.com/gitlab-org/gitlab/-/issues/430815)하세요.
- DAST 보고를 최적화하여 메모리 사용을 줄였으며, DAST 스캔 중 러너 메모리 스파이크를 줄였습니다. 자세한 내용은 [이슈를 참조](https://gitlab.com/gitlab-org/gitlab/-/issues/444180)하세요.

### GitLab에서 Google Compute Engine 러너 생성 자동화 - 공개 베타 {#automate-the-creation-of-google-compute-engine-runners-from-gitlab---public-beta}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../ci/runners/provision_runners_google_cloud.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/13494)

{{< /details >}}

이전에는 Google Compute Engine에서 GitLab 러너를 생성하려면 GitLab과 Google Cloud 간의 여러 컨텍스트 전환이 필요했습니다.

이제 GitLab Runner Infrastructure Toolkit 및 GitLab의 terraform 템플릿을 사용하여 Google Compute Engine에서 GitLab 러너를 쉽게 프로비저닝하여 GitLab 러너를 배포하고 Google Cloud 인프라를 프로비저닝할 수 있습니다. 여러 시스템 간을 전환할 필요가 없습니다.

### 특정 종료 코드를 사용하여 실패한 CI 작업에 대한 자동 재시도 개선 {#improve-automatic-retry-for-failed-ci-jobs-with-specific-exit-codes}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#retry) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/262674)

{{< /details >}}

이전에는 `retry:when`를 `retry:max`와 함께 사용하여 스크립트가 실패할 때처럼 특정 오류가 발생할 때 작업을 재시도하는 횟수를 구성할 수 있었습니다.

이 릴리스에서는 이제 [`retry:exit_codes`](../../ci/yaml/_index.md#retryexit_codes)를 사용하여 특정 스크립트 종료 코드를 기반으로 실패한 작업의 자동 재시도를 구성할 수 있습니다. `retry:exit_codes`를 `retry:when` 및 `retry:max`와 함께 사용하여 파이프라인의 동작을 미세 조정하여 특정 필요에 맞게 하고 파이프라인 실행을 개선할 수 있습니다.

이 커뮤니티 기여를 주신 [Baptiste Lalanne](https://gitlab.com/BaptisteLalanne)에게 감사합니다!

### GitLab 러너 16.11 {#gitlab-runner-1611}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

GitLab 러너 16.11도 오늘 출시합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 버그 수정 {#bug-fixes}

- [충돌: 치명적 오류: 동시 맵 읽기 및 맵 쓰기](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/31077)
- [FF_KUBERNETES_HONOR_ENTRYPOINT 기능이 작동하지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37243)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-11-stable/CHANGELOG.md)에 있습니다.

### Artifactory 및 AWS를 포함한 Expanded Hashicorp Vault Secrets 지원 {#expanded-hashicorp-vault-secrets-support-including-artifactory-and-aws}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/secrets/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)

{{< /details >}}

GitLab과 HashiCorp Vault의 통합이 더 많은 유형의 시크릿을 지원하도록 확장되었습니다. 이제 GitLab 러너 16.11에서 도입된 `generic` 유형의 시크릿 엔진을 선택할 수 있습니다. 이 일반 엔진은 HashiCorp Vault [Artifactory Secrets 플러그인](https://jfrog.com/help/r/jfrog-integrations-documentation/hashicorp-vault-artifactory-secrets-plugin) 및 [AWS 시크릿 엔진](https://developer.hashicorp.com/vault/docs/secrets/aws)을 지원합니다. 이 옵션을 사용하여 필요한 시크릿을 안전하게 검색하고 GitLab CI/CD 파이프라인에서 사용하세요!

이 훌륭한 기여를 주신 [Ivo Ivanov](https://gitlab.com/urbanwax)에게 정말 감사합니다!

### 작업 아티팩트를 다운로드할 수 있는 사람 제어 {#control-who-can-download-job-artifacts}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#artifactsaccess) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/428677)

{{< /details >}}

기본적으로 공개 파이프라인의 CI/CD 작업에서 생성된 모든 아티팩트는 파이프라인에 접근할 수 있는 모든 사용자가 다운로드할 수 있습니다. 그러나 아티팩트를 다운로드하면 안 되거나 더 높은 액세스 수준의 팀 멤버만 다운로드할 수 있는 경우가 있습니다.

따라서 이 릴리스에서는 `artifacts:access` 키워드를 추가했습니다. 이제 사용자는 파이프라인에 접근할 수 있는 모든 사용자가 아티팩트를 다운로드할 수 있는지, Developer 역할 이상의 사용자만 다운로드할 수 있는지 아니면 아무도 다운로드할 수 없는지 제어할 수 있습니다.

### 개선된 파이프라인 세부 정보 페이지 {#improved-pipeline-details-page}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../ci/pipelines/_index.md#view-pipelines)

{{< /details >}}

파이프라인 그래프는 작업 상태, 런타임 업데이트, 다중 프로젝트 파이프라인 및 상위-하위 파이프라인을 보여주는 파이프라인에 대한 포괄적인 개요를 제공합니다.

오늘 우리는 향상된 미학, 그룹화된 작업 시각화, 개선된 모바일 경험 및 기존 보기 내에서 확장된 다운스트림 파이프라인 가시성으로 재설계된 파이프라인 그래프의 출시를 발표하게 되어 기쁩니다.

이를 시도하고 이 전용 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/450676)를 통해 피드백을 공유해 주시면 감사하겠습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.11)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.11)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.11)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
