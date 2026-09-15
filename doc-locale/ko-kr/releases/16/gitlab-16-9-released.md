---
stage: Release Notes
group: Monthly Release
date: 2024-02-15
title: "GitLab 16.9 릴리스 정보"
description: "GitLab 16.9가 출시되었으며 GitLab Duo Chat 베타가 이제 Premium에서 사용 가능합니다"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024년 2월 15일 GitLab 16.9가 다음 기능과 함께 출시되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이번 달의 주목할 만한 기여자 {#this-months-notable-contributor}

Ravi는 GitLab의 Vulnerability Research 그룹과 적극적으로 협력하여 [GitLab SAST](https://gitlab.com/gitlab-org/security-products/sast-rules)의 높은 거짓 양성 결과를 해결하고 있습니다.

Ravi는 GitLab의 Customer Success Manager인 [Rohan Shah](https://gitlab.com/rmsrohan)에 의해 추천되었으며, GitLab SAST에서 사용되는 [감지 규칙](../../user/application_security/sast/rules.md)에 대한 Ravi의 중요한 개선 사항을 언급했습니다. GitLab의 Senior Vulnerability Researcher인 [Dinesh Bolkensteyn](https://gitlab.com/dbolkensteyn)은 "Ravi의 피드백은 정확하고 직접 실행 가능하며 많은 SAST 규칙을 개선할 수 있도록 해주었습니다"라고 덧붙였습니다.

Ravi Dharmawan(별칭 ravidhr)은 GoTo Group에서 Information Security Architect로 일하고 있습니다. 주로 보안 설계 검토, 소스 코드 검토 및 침투 테스트를 담당합니다. Ravi는 OSCP + eWPTXv2 인증을 받았습니다.

Ian은 [GitLab Forum에서 사용자를 지원](https://forum.gitlab.com/u/iwalker/activity)하는 작업으로 인정받은 첫 번째 GitLab MVP입니다. GitLab의 Senior Developer Advocate인 [Michael Friedrich](https://gitlab.com/dnsmichi)와 Developer Advocate인 [Fatima Sarah Khalid](https://gitlab.com/sugaroverflow)는 모두 GitLab을 설정하고 사용하는 사용자들을 위해 질문에 답변함으로써 커뮤니티를 위해 포럼을 더 나은 장소로 만들기 위한 지속적인 노력에 대해 Ian을 추천했습니다.

Ian은 UpWare Sp. z o.o.에서 System and Security Consultant로 일하고 있으며, 주로 Red Hat OpenShift 및 Linux 관련 업무를 담당합니다. Red Hat Certified RHCSA + RHCE이며 2017년 이후로 자체 호스팅 GitLab 설치를 관리, 유지 및 지원해 왔습니다. Ian은 3년 이상 GitLab 포럼에서 정기적으로 활동하고 있으며 2,600개 이상의 유용한 답변, 480개의 유용한 커뮤니티 중재 플래그 및 240개의 솔루션을 제공했습니다.

Ravi와 Ian에게 감사드립니다! 🙌

## 주요 기능 {#primary-features}

### GitLab Duo Chat 베타가 이제 Premium에서 사용 가능합니다 {#gitlab-duo-chat-beta-now-available-in-premium}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/gitlab_duo_chat/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11251)

{{< /details >}}

16.8에서 GitLab Duo Chat을 자체 관리형 인스턴스에서 사용할 수 있게 했습니다. 16.9에서는 베타 상태인 동안 Chat을 Premium 고객에게 제공합니다.

GitLab Duo Chat은 다음을 수행할 수 있습니다:

- 이슈, 에픽 및 코드를 설명하거나 요약합니다.
- "이 이슈에서 제안된 솔루션과 관련하여 댓글에서 제기된 모든 논거를 수집하세요"와 같은 이러한 아티팩트에 대한 구체적인 질문에 답변합니다.
- 이러한 아티팩트의 정보를 기반으로 코드나 콘텐츠를 생성합니다. 예를 들어 "이 코드에 대한 문서를 작성해 주실 수 있나요?"
- 프로세스를 시작하도록 도와줍니다. 예를 들어 "GitLab CI/CD 파이프라인에서 Ruby on Rails 애플리케이션을 테스트하고 구축하기 위한 .GitLab-ci.yml 구성 파일을 생성합니다"
- 초보자이든 전문가이든 모든 DevSecOps 관련 질문에 답변합니다. 예를 들어 "REST API에 대한 Dynamic Application Security Testing을 설정하려면 어떻게 해야 하나요?"
- 후속 질문에 답변하여 이전의 모든 시나리오를 반복적으로 작업할 수 있습니다.

GitLab Duo Chat은 베타 기능으로 사용 가능합니다. VS Code용 Web IDE 및 GitLab Workflow 확장에도 실험 기능으로 통합되어 있습니다. 이러한 IDE에서는 [테스트 작성과 같은 표준 작업을 더 빠르게 수행하는 데 도움이 되는 사전 정의된 채팅 명령](../../user/gitlab_duo_chat/examples.md)을 사용할 수도 있습니다.

제품 내에서 또는 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)를 통해 GitLab Duo Chat 경험에 대한 피드백을 제공하여 이러한 기능을 성숙하게 하는 데 도움을 줄 수 있습니다.

### 머지 리퀘스트에서 변경 요청 {#request-changes-on-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/project/merge_requests/reviews/_index.md#submit-a-review)

{{< /details >}}

머지 리퀘스트 검토의 마지막 부분은 결과를 전달하는 것입니다. 승인은 명확했지만 댓글 남기기는 그렇지 않았습니다. 작성자가 댓글을 읽고 댓글이 순수하게 정보 제공용인지 필요한 변경 사항을 설명하는 것인지 결정해야 했습니다. 이제 검토를 완료할 때 세 가지 옵션 중에서 선택할 수 있습니다:

- **댓글**: 명시적으로 승인하지 않고 일반적인 피드백을 제출합니다.
- **승인**: 피드백을 제출하고 변경 사항을 승인합니다.
- **변경 요청**: 병합 전에 처리되어야 하는 피드백을 제출합니다.

사이드바에 검토 결과가 이름 옆에 표시됩니다. 현재 **변경 요청**으로 검토를 종료해도 머지 리퀘스트가 병합되는 것을 차단하지는 않지만 머지 리퀘스트의 다른 참가자에게 추가 컨텍스트를 제공합니다.

**변경 요청** 기능에 대한 피드백을 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/438573)에서 남길 수 있습니다.

### CI/CD 변수 사용자 인터페이스 개선 {#improvements-to-the-cicd-variables-user-interface}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/variables/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)

{{< /details >}}

GitLab 16.9에서는 CI/CD 변수 사용자 경험에 대한 일련의 개선 사항을 출시했습니다. 다음 변경 사항을 통해 변수 생성 흐름을 개선했습니다:

- [변수 값이 요구 사항을 충족하지 않을 때 개선된 검증](https://gitlab.com/gitlab-org/gitlab/-/issues/365934)
- [변수 생성 중 도움말 텍스트](https://gitlab.com/gitlab-org/gitlab/-/issues/410220)
- [변수 양식에서 값 필드 크기 조정 허용](https://gitlab.com/gitlab-org/gitlab/-/issues/434667)

기타 개선 사항에는 변수 관리를 지원하기 위한 그룹 및 프로젝트 변수에 대한 새로운 [선택적 설명 필드](https://gitlab.com/gitlab-org/gitlab/-/issues/378938)가 포함됩니다. 또한 [여러 변수를 추가하거나 편집](https://gitlab.com/gitlab-org/gitlab/-/issues/434666)하기가 더 쉬워져 소프트웨어 개발 워크플로의 마찰을 줄이고 개발자가 업무를 보다 효율적으로 수행할 수 있게 했습니다.

이러한 변경 사항에 대한 [피드백](https://gitlab.com/gitlab-org/gitlab/-/issues/441177)은 항상 소중하고 감사합니다.

### 자동 취소 파이프라인 옵션 확장 {#expanded-options-for-auto-canceling-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/yaml/_index.md#workflowauto_cancelon_new_commit) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/412473)

{{< /details >}}

현재 [자동 취소 중복 파이프라인 기능](../../ci/pipelines/settings.md#auto-cancel-redundant-pipelines)을 사용하려면 취소할 수 있는 작업을 [`interruptible: true`](../../ci/yaml/_index.md#interruptible)로 설정하여 파이프라인을 취소할 수 있는지 여부를 결정해야 합니다. 하지만 이는 GitLab이 파이프라인 취소를 시도할 때 활성으로 실행 중인 작업에만 적용됩니다. 아직 시작되지 않은 작업("대기 중" 상태)은 `interruptible` 설정과 관계없이 취소해도 안전한 것으로 간주됩니다.

이러한 유연성 부족은 자동 취소 파이프라인 기능으로 취소할 수 있는 정확한 작업을 더 잘 제어하려는 사용자를 방해합니다. 이러한 제한을 해결하기 위해 `auto_cancel:on_new_commit` 키워드 도입을 발표하게 되어 기쁩니다. 이는 작업 취소에 대한 보다 세분화된 제어를 제공합니다. 레거시 동작이 작동하지 않은 경우 이제 작업이 아직 시작되지 않았더라도 `interruptible: true`으로 명시적으로 설정된 작업만 취소하도록 파이프라인을 구성할 수 있는 옵션이 있습니다. 작업을 자동으로 취소되지 않도록 설정할 수도 있습니다.

## 규모 및 배포 {#scale-and-deployments}

### 고급 검색을 위한 동시 코드 인덱싱 작업 제한 {#limit-concurrent-code-indexing-jobs-for-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../integration/advanced_search/elasticsearch.md#advanced-search-configuration) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/435402)

{{< /details >}}

GitLab 관리자는 이제 동시에 실행할 수 있는 Elasticsearch 코드 인덱싱 백그라운드 작업의 최대 개수를 설정할 수 있습니다. 이전에는 전용 Sidekiq 프로세스를 생성하여만 동시 작업 수를 제한할 수 있었습니다.

### 그룹 및 프로젝트 멤버 관리를 위한 사용자 지정 가이드라인 {#custom-guidelines-for-managing-group-and-project-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../administration/appearance.md#member-guidelines) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/433093)

{{< /details >}}

관리자는 이제 그룹 또는 프로젝트의 **멤버** 페이지에서 멤버를 관리할 권한이 있는 사용자에게 표시되는 텍스트 가이드라인을 추가할 수 있습니다. 관리자는 **외관** 섹션의 **Admin Area** 설정에서 이러한 가이드라인에 액세스할 수 있습니다.

가이드라인은 그룹 또는 프로젝트의 멤버를 관리하기 위해 외부 도구를 사용하는 팀에 도움이 됩니다. 예를 들어 가이드라인은 개별 멤버의 멤버십을 관리하는 대신 사용자가 사용해야 하는 미리 정의된 그룹에 연결할 수 있습니다.

이 커뮤니티 기여에 대해 @bufferoverflow에게 감사드립니다!

### 직접 전송에 대한 가져오기 통계 표시 {#show-import-stats-for-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/import/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/437874)

{{< /details >}}

직접 전송으로 완료된 GitLab 그룹 및 프로젝트 마이그레이션에는 배지(**완료**, **부분적으로 완료됨**, **실패함**)가 표시되어 마이그레이션의 일반적인 결과를 사용자에게 알립니다. 사용자는 **See failures** 링크를 클릭하여 가져오지 않은 항목 목록에 액세스할 수도 있었습니다.

그러나 부분적으로 가져온 프로젝트의 경우 각 유형의 항목이 몇 개나 성공적으로 가져왔는지, 몇 개가 그렇지 않은지 빠르게 파악할 수 있는 방법이 없었습니다.

이 릴리스에서는 그룹 및 프로젝트에 대한 가져오기 결과 통계를 추가했습니다. 통계에 액세스하려면 직접 전송 기록 페이지에서 **상세정보** 링크를 선택합니다.

### 그룹 수준에서 Jira 이슈 활성화 {#enable-jira-issues-at-the-group-level}

<!-- categories: Settings -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../integration/jira/configure.md#view-jira-issues) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/325715)

{{< /details >}}

이 릴리스에서는 GitLab 그룹의 모든 프로젝트에 대해 Jira 이슈를 활성화할 수 있습니다. 이전에는 각 GitLab 프로젝트에 대해서만 Jira 이슈를 개별적으로 활성화할 수 있었습니다.

### GitLab for Slack 앱에 대한 REST API 지원 {#rest-api-support-for-the-gitlab-for-slack-app}

<!-- categories: Settings -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../api/group_integrations.md#gitlab-for-slack-app) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/364440)

{{< /details >}}

이 릴리스에서는 GitLab for Slack 앱에 대한 REST API 지원을 추가했습니다.

API에서 GitLab for Slack 앱을 만들 수 없습니다. 대신 GitLab UI에서 [앱을 설치](../../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)해야 합니다. 그런 다음 통합 설정을 검색하고 프로젝트에 대한 앱을 업데이트하거나 비활성화할 수 있습니다.

### REST API를 통한 GitLab 사용 현황 데이터 액세스 {#access-gitlab-usage-data-through-the-rest-api}

<!-- categories: Application Instrumentation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../api/usage_data.md#export-service-ping-data) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/12251)

{{< /details >}}

자체 관리 사용자는 이제 REST API 연결을 통해 Service Ping 데이터에 원활하게 액세스하여 다운스트림 시스템과의 직접 통합을 용이하게 할 수 있습니다. 이는 이전의 파일 다운로드 방법에 비한 중요한 개선입니다. 새로운 방식은 자체 관리 사용자에게 GitLab 사용 데이터로부터 사용자 지정 분석을 수행하고 구체적인 인사이트를 도출할 수 있는 보다 효율적이고 실시간적인 수단을 제공합니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### SSH 인증서를 사용하여 커밋 인증 및 서명 {#authenticate-and-sign-commits-with-ssh-certificates}

<!-- categories: Source Code Management -->

{{< details >}}

- 티어: Silver, Gold
- 링크: [설명서](../../user/group/ssh_certificates.md)

{{< /details >}}

이전에는 GitLab.com의 Git 액세스 제어 옵션이 사용자 계정에서 설정한 자격 증명에 의존했습니다. 이제 SSH 인증서만 사용하여 Git 액세스를 가능하게 하는 프로세스를 설정할 수 있습니다. 이러한 인증서를 사용하여 커밋에 서명할 수도 있습니다.

### GitLab 에이전트에서 사용자당 워크스페이스 제한 {#limit-workspaces-per-user-on-the-gitlab-agent}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

GitLab 16.8에서는 워크스페이스당 CPU 및 메모리 사용량을 제한하기 위한 Kubernetes용 GitLab 에이전트 설정을 도입했습니다.

이제 16.9에서는 사용자당 워크스페이스 수를 제한할 수도 있습니다. 이 새로운 설정을 사용하면 클라우드 리소스를 더욱 제어할 수 있으며 개별 개발자가 클라우드 지출을 늘리는 것을 방지할 수 있습니다.

### 사용자가 실패한 배포에서 부분적인 리소스를 정리할 수 있도록 허용 {#allow-users-to-cleanup-partial-resources-from-failed-deployments}

<!-- categories: Environment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/environments/_index.md#run-a-pipeline-job-when-environment-is-stopped) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/435128)

{{< /details >}}

Environment [`auto_stop_in`](../../ci/yaml/_index.md#environmentauto_stop_in) 기능을 마지막 완료된 파이프라인에서 작업을 실행하도록 업데이트했으며, 마지막 성공한 파이프라인에서가 아닙니다. 이는 성공적인 파이프라인이 없어서 자동 중지 작업이 실행될 수 없는 엣지 케이스를 피합니다.

이 동작은 일부 상황에서 주요 변경 사항으로 간주될 수 있습니다. 새로운 동작은 현재 기능 플래그 뒤에 있으며, 17.0에서는 기본값이 될 것이며, 동시에 구식 동작을 GitLab 18.0에서 제거될 예정입니다. 첫 17.x 업그레이드에서 주요 변경 사항의 위험을 최소화하기 위해 모든 사용자가 지금 바로 전환을 시작하거나 기능 플래그를 구성할 것을 권장합니다.

### Kubernetes 1.29 지원 {#kubernetes-129-support}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/435293)

{{< /details >}}

이 릴리스는 2023년 12월에 출시된 Kubernetes 버전 1.29에 대한 완전한 지원을 추가합니다. 앱을 Kubernetes에 배포하는 경우 이제 연결된 클러스터를 최신 버전으로 업그레이드하고 모든 기능을 활용할 수 있습니다.

Kubernetes 지원 정책 및 기타 지원되는 Kubernetes 버전에 대해 자세히 알아볼 수 있습니다.

### UI 및 API를 통해 액세스 가능한 엔터프라이즈 사용자 이메일 주소 {#enterprise-user-email-address-accessible-through-ui-and-api}

<!-- categories: User Management -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/enterprise_user/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/391453)

{{< /details >}}

[엔터프라이즈 사용자](../../user/enterprise_user/_index.md)가 있는 그룹 소유자는 이제 사용자 관리 UI 및 [그룹 및 프로젝트 멤버 API](../../api/group_members.md)를 모두 사용하여 해당 사용자의 이메일 주소를 볼 수 있습니다. 이전에는 프로비저닝된 사용자의 이메일 주소만 반환되었습니다.

### LDAP 그룹 동기화를 통해 그룹에서 서비스 계정 추가 또는 제거 {#add-or-remove-service-accounts-from-groups-with-ldap-group-sync}

<!-- categories: User Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/group/access_and_permissions.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/425947)

{{< /details >}}

이전에는 그룹에 LDAP 동기화가 활성화되어 있으면 관리자는 그룹에서 사용자를 초대하거나 제거할 수 없었습니다. 이제 관리자는 그룹 및 프로젝트 멤버 API를 사용하여 서비스 계정 사용자를 LDAP 동기화를 사용하는 그룹으로 초대하거나 해당 사용자를 그룹에서 제거할 수 있습니다. 관리자는 여전히 인간 사용자를 LDAP 동기화를 사용하는 그룹으로 초대하거나 해당 사용자를 그룹에서 제거할 수 없습니다. 이는 LDAP 그룹 동기화가 인간 사용자 계정 멤버십의 단일 소스이면서 LDAP 동기화 그룹에 자동화를 추가하기 위해 서비스 계정을 사용할 수 있는 유연성을 허용합니다.

### 사용자 지정 역할 업데이트 또는 삭제에 대한 감사 이벤트 {#audit-event-for-updating-or-deleting-a-custom-role}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/compliance/audit_event_reports.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/437672)

{{< /details >}}

GitLab은 이제 사용자 지정 역할이 업데이트되거나 삭제될 때 감사 이벤트를 기록합니다. 이 이벤트는 권한 에스컬레이션의 경우 권한이 추가되었거나 변경되었는지 식별하는 데 중요합니다.

### 만료된 SAML SSO 세션에 대한 개선된 UX {#improved-ux-for-expired-saml-sso-sessions}

<!-- categories: System Access -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [문서](../../user/group/saml_sso/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/414475)

{{< /details >}}

SAML SSO 인증이 필요한 그룹에 속해 있지만 해당 그룹에 대한 유효한 세션이 없으면 세션을 새로 고치도록 표시하는 배너가 표시됩니다. 이전에는 세션이 만료되었을 때 이슈 및 머지 리퀘스트가 표시되지 않았지만 사용자에게 명확하지 않았습니다. 이제 사용자가 모든 작업 항목을 보기 위해 다시 인증해야 할 때 사용자에게 명확합니다.

### 표준 준수 보고서 개선 {#standards-adherence-report-improvements}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11053)

{{< /details >}}

[표준 준수 보고서](../../user/compliance/compliance_center/_index.md)는 [준수 센터](../../user/compliance/compliance_center/_index.md) 내에 있으며 준수 팀이 준수 현황을 모니터링할 수 있는 대상입니다.

GitLab 16.5에서는 GitLab Standard를 사용하여 보고서를 도입했습니다. 이는 모든 준수 팀이 모니터링해야 하는 일반적인 준수 요구 사항 집합입니다. 이 표준은 어떤 프로젝트가 이러한 요구 사항을 충족하는지, 어떤 것이 미달되는지, 그리고 이를 준수하는 방법을 이해하는 데 도움이 됩니다. 시간이 지남에 따라 더 많은 표준을 보고에 도입할 예정입니다.

이 마일스톤에서는 보고를 더욱 견고하고 실행 가능하게 만들 몇 가지 개선 사항을 추가했습니다. 여기에는 다음이 포함됩니다:

- 검사별로 결과 그룹화
- 프로젝트, 검사 및 표준별로 필터링
- CSV로 내보내기(이메일을 통해 전달)
- 페이지 분할 개선

### 리치 텍스트 편집기 광범위한 가용성 {#rich-text-editor-broader-availability}

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/rich_text_editor.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/7098)

{{< /details >}}

GitLab 16.2에서는 [리치 텍스트 편집기를 출시](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/)했으며, 이는 일반 텍스트 편집기의 대안입니다. 리치 텍스트 편집기는 "WYSIWYG(보는 것이 얻는 것입니다)" 편집 인터페이스와 추가 개발을 위한 확장 가능한 기초를 제공합니다. 그러나 이 릴리스까지 리치 텍스트 편집기는 이슈, 에픽 및 머지 리퀘스트에서만 사용할 수 있었습니다.

GitLab 16.9에서는 리치 텍스트 편집기를 이제 다음에서 사용할 수 있습니다:

- [요구 사항 설명](https://gitlab.com/gitlab-org/gitlab/-/issues/407493)
- [취약성 결과](https://gitlab.com/gitlab-org/gitlab/-/issues/407491)
- [릴리스 설명](https://gitlab.com/gitlab-org/gitlab/-/issues/407494)
- [디자인 메모](https://gitlab.com/gitlab-org/gitlab/-/issues/407505)

리치 텍스트 편집기에 대한 향상된 액세스를 통해 이전 Markdown 경험 없이도 보다 효율적으로 협업할 수 있습니다.

### 중복 Terraform 모듈 허용 {#allow-duplicate-terraform-modules}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/terraform_module_registry/_index.md#allow-duplicate-terraform-modules) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/368040)

{{< /details >}}

GitLab 패키지 레지스트리를 사용하여 Terraform 모듈을 게시하고 다운로드할 수 있습니다. 기본적으로 프로젝트당 동일한 모듈 이름 및 버전을 두 번 이상 게시할 수 없습니다.

그러나 특히 릴리스의 경우 중복 업로드를 허용하고 싶을 수 있습니다. 이 릴리스에서 GitLab은 패키지 레지스트리에 대한 그룹 설정을 확장하여 중복 모듈을 허용하거나 거부할 수 있습니다.

### 그룹 또는 하위 그룹에서 Terraform 모듈 검증 {#validate-terraform-modules-from-your-group-or-subgroup}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/package_registry/_index.md#view-packages) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/352041)

{{< /details >}}

GitLab Terraform 레지스트리를 사용할 때는 모든 모듈의 cross-프로젝트 보기를 가지는 것이 중요합니다. 최근까지 사용자 인터페이스는 프로젝트 수준에서만 사용할 수 있었습니다. 그룹이 복잡한 구조를 가지고 있다면 모듈을 찾고 검증하는 데 어려움이 있을 수 있습니다.

GitLab 16.9부터 GitLab에서 모든 그룹 및 하위 그룹 모듈을 볼 수 있습니다. 가시성이 증가하면 레지스트리를 더 잘 이해할 수 있으며 이름 충돌 가능성이 감소합니다.

### 보드 진행 중인 작업 라인 {#boards-work-in-progress-line}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/project/issue_board.md#work-in-progress-limits) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/440540)

{{< /details >}}

이제 보드 목록에서 진행 중인 작업 제한을 시각화할 수 있습니다. 한계가 초과되었을 때 목록에 표시기 라인이 나타나 한계를 초과한 항목을 파악하고 목록을 그에 따라 관리하는 데 도움이 됩니다.

### 사용자 지정 Value Stream Analytics를 위한 새 단계 이벤트 {#new-stage-events-for-custom-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/431934)

{{< /details >}}

[GitLab에서 개발 워크플로의 추적](https://about.gitlab.com/blog/value-stream-total-time-chart/)을 개선하기 위해 Value Stream Analytics는 새로운 단계 이벤트 `Issue first added to iteration`로 확장되었습니다. 이 이벤트를 사용하여 너무 먼저 계획하는 팀의 민첩성 부족이나 반복에서 롤오버되는 이슈가 있는 팀의 실행 이슈로 인한 이슈를 감지할 수 있습니다. 예를 들어, `Issue first added to iteration`에서 시작하여 `Issue first assigned`로 끝나는 "Planned" 단계를 이제 추가할 수 있습니다.

### Operational Container Scanning 개선 {#improvements-to-operational-container-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/clusters/agent/vulnerabilities.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11968)

{{< /details >}}

Operational Container Scanning(OCS)에 대한 보고 및 안정성 개선을 했습니다. 특히 Trivy 보고서 크기 제한이 증가하여 사용자에게 보다 안정적인 환경을 제공합니다. Trivy 보고서 크기를 10MB에서 100MB로 확장하면 보고서 크기 제한으로 제약을 받던 고객이 클러스터에서 컨테이너 이미지를 보호하는 데 OCS를 활용할 수 있습니다.

OCS의 이 변경으로 `gitlab-agent`을 FIPS 모드에서 실행하는 사용자는 Operational Container Scanning을 실행할 수 없습니다. 자세한 내용은 문서를 참조하고 [\#440849](https://gitlab.com/gitlab-org/gitlab/-/issues/440849) 이슈에서 피드백을 제공하세요.

### DAST 분석기 업데이트 {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dast/browser/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/12685)

{{< /details >}}

16.9 릴리스 마일스톤 동안 다음 버그를 해결했습니다:

- 브라우저가 새 페이지로 전환되었을 때 캐시된 리소스에 대한 응답 본문을 가져오려고 할 때 브라우저 기반 DAST 오류 발생. 자세한 내용은 [이슈를 참조](https://gitlab.com/gitlab-org/gitlab/-/issues/435175)하세요.
- 브라우저 기반 DAST 크롤링 작업이 병렬로 실행되지 않아 성능 저하 발생. 자세한 내용은 [이슈를 참조](https://gitlab.com/gitlab-org/gitlab/-/issues/435325)하세요.

### 더 높은 품질의 결과를 위해 업데이트된 SAST 규칙 {#updated-sast-rules-for-higher-quality-results}

<!-- categories: SAST -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/application_security/sast/rules.md#important-rule-changes) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10971)

{{< /details >}}

40개 이상의 기본 GitLab SAST 규칙을 업데이트했습니다:

- C#, Go, Java, JavaScript 및 Python의 감지 논리 규칙을 업데이트하여 참 양성 결과(올바르게 식별된 취약성)를 증가시키고 거짓 음성 결과(잘못 식별된 취약성)를 감소시킵니다.
- C#, Go, Java 및 Python 규칙에 대해 [OWASP 매핑](https://gitlab.com/gitlab-org/gitlab/-/issues/438561)을 추가합니다.

규칙 변경 사항은 Semgrep 기반 GitLab SAST [분석기](../../user/application_security/sast/analyzers.md)의 업데이트된 버전에 포함됩니다. 이 업데이트는 SAST 분석기를 특정 버전으로 [고정](../../user/application_security/sast/_index.md)하지 않는 한 GitLab 16.0 이상에서 자동으로 적용됩니다. [에픽 10907](https://gitlab.com/groups/gitlab-org/-/epics/10907)에서 더 많은 SAST 규칙 개선을 진행 중입니다.

### VS Code에서 보다 자세한 보안 결과 {#more-detailed-security-findings-in-vs-code}

<!-- categories: Editor Extensions, API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis, Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../editor_extensions/visual_studio_code/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/10996)

{{< /details >}}

Visual Studio Code(VS Code)용 [GitLab Workflow 확장](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#security-findings)에서 보안 결과를 표시하는 방식을 개선했습니다. 이전에 표시되지 않았던 보안 결과의 더 많은 세부 정보를 이제 볼 수 있습니다:

- 리치 텍스트 형식이 포함된 전체 설명입니다.
- 취약성의 해결책(사용 가능한 경우).
- 코드베이스에서 문제가 발생하는 위치에 대한 링크.
- 발견된 취약성 유형에 대한 추가 정보 링크.

또한 다음을 했습니다:

- 결과가 준비되기 전에 확장 프로그램이 보안 검사의 상태를 표시하는 방식을 개선했습니다.
- 다른 사용성 개선을 했습니다.

### 파이프라인 또는 작업 취소할 수 있는 역할 제어 {#control-which-roles-can-cancel-pipelines-or-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/410634)

{{< /details >}}

조직에서 파이프라인을 취소할 수 있는 사용자 역할을 제어하고 싶을 수 있습니다. 이전에는 파이프라인을 실행할 수 있는 모든 사용자가 파이프라인을 취소할 수도 있었습니다. 이제 프로젝트 Maintainer는 파이프라인 및 작업 취소를 특정 역할로 제한하거나 취소를 완전히 방지하는 설정을 업데이트할 수 있습니다!

### Fleet Dashboard: 인스턴스 러너당 사용된 컴퓨팅 분 수를 프로젝트 메트릭 카드당 {#fleet-dashboard-compute-minutes-used-on-instance-runners-per-project-metric-card}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../ci/runners/runner_fleet_dashboard.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/421457)

{{< /details >}}

GitLab Runner Fleet을 대규모로 관리할 때 러너에서 컴퓨팅 분을 가장 많이 사용하는 프로젝트를 아는 것이 중요하다고 하셨습니다. 귀사의 경우 이 정보는 팀이 CI/CD 파이프라인을 최적화하는 데 도움이 되며 Fleet 비용 최적화에 대한 올바른 결정을 내리는 데도 도움이 됩니다.

이제 프로젝트 메트릭 카드별 러너 컴퓨팅 사용량은 이전에 출시된 CI/CD 컴퓨팅 분 CSV 내보내기 기능의 보완으로 Runner Fleet Dashboard에서 사용 가능합니다. GitLab 환경에서 인스턴스 러너 분을 가장 많이 사용하는 최상위 프로젝트와 가장 많이 사용되는 인스턴스 러너를 볼 수 있습니다.

### GitLab Runner 16.9 {#gitlab-runner-169}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

또한 GitLab Runner 16.9를 오늘 출시합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 다시 보내는 가볍고 확장성이 높은 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [Kubernetes API 재시도를 구성 가능하게 하기](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37349)

#### 버그 수정 {#bug-fixes}

- [임의 경고: \*\*\*를 제거하지 못했습니다: 디렉토리가 비어있지 않음](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3185)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-9-stable/CHANGELOG.md)에 있습니다.

### 브랜치 기반 파이프라인에 대한 MR 링크 표시 {#show-mr-link-for-branch-based-pipelines}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/pipelines/_index.md#view-pipelines) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/416134)

{{< /details >}}

브랜치 파이프라인을 사용하는 경우 이제 파이프라인 상세 페이지에서 관련 머지 리퀘스트를 빠르게 보고 액세스할 수 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.9)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.9)
- [UI 개선](https://papercuts.gitlab.com/?milestone=16.9)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
