---
stage: Release Notes
group: Monthly Release
date: 2025-04-17
title: "GitLab 17.11 릴리스 정보"
description: "요구 사항 및 컴플라이언스 컨트롤을 사용하여 컴플라이언스 프레임워크 사용자 지정 - GitLab 17.11 릴리스됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 4월 17일에 GitLab 17.11이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Heidi Berry {#this-months-notable-contributor-heidi-berry}

17.11에서 저희는 [Heidi Berry](https://gitlab.com/heidi.berry)를 저희의 주목할 만한 기여자로 인정하게 되어 기쁩니다!

Heidi는 [GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab) 및 [client-go](https://gitlab.com/gitlab-org/api/client-go) 프로젝트의 뛰어난 기여자였습니다. 지난 여러 릴리스 동안 그녀는 [Group SAML 링크가 있는 사용자 지정 역할](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/1949) 사용 기능, [그룹을 위한 브랜치 보호 기본값 설정](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2113) 지원, 그리고 [서비스 계정 토큰의 자동 토큰 로테이션](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2206)을 포함한 높은 요청이 있는 기능을 일관되게 제공했습니다.

기능 개발 이외에도 Heidi는 유지 보수 활동에서 중요한 역할을 했습니다 - [이슈 백로그 정제 지원](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/issues/1035#note_2305643918), [가독성 개선을 위한 오래된 테스트 업데이트](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2298), 및 [더 나은 예시로 문서 개선](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2201). client-go에 대한 그녀의 기여는 특히 가치가 있습니다. 이 라이브러리는 고객과 GitLab이 GitLab과 상호 작용하기 위해 사용하는 많은 다운스트림 프로젝트(Terraform 제공자 및 glab 포함)에 전력을 공급합니다.

"오픈 소스 기여를 시도해본 적이 있다면 client-go와 terraform-provider-GitLab을 시도해보세요"라고 Heidi는 말합니다. "시작할 수 있도록 좋은 문서와 도움을 줄 준비가 된 지지하는 유지 관리자들이 있습니다. 저는 이러한 프로젝트를 사용하여 실용적인 방식으로 Go 언어를 배우는 것을 즐겼습니다."

Heidi는 Kingland의 엔터프라이즈 아키텍트이자 GitLab 커뮤니티 코어팀 회원인 또 다른 커뮤니티 기여자 [Patrick Rice](https://gitlab.com/PatrickRice)에 의해 지명되었습니다. Patrick는 다음과 같이 말합니다: "17 릴리스 주기 전반에 걸쳐 현재까지 100개 이상의 병합된 기여와 더 많은 이슈 댓글이 있는 Heidi는 GitLab과 Terraform에 큰 도움이 되었습니다. 기여해주셔서 정말 감사합니다!"

"Heidi는 놀라운 일을 합니다"라고 GitLab의 Deploy::Environments 시니어 백엔드 엔지니어인 [Timo Furrer](https://gitlab.com/timofurrer)가 말했습니다. "그녀는 정기적으로 추가 노력을 기울이고 client-go에서 필요한 SDK 코드를 구현합니다. Heidi는 많은 코드를 기여할 뿐 아니라 이슈 분류도 도와줍니다. 그것은 엄청난 도움이며 커뮤니티 기반 프로젝트들이 지속될 수 있는 이유입니다."

Heidi는 The Co-operative Group의 리드 소프트웨어 엔지니어이며, 개발자 경험을 효율적이고 안전하며 최대한 간단하게 만드는 것을 도와줍니다.

Heidi, GitLab에 대한 엄청난 기여를 해주셔서 감사합니다!

## 주요 기능 {#primary-features}

### 요구 사항 및 컴플라이언스 컨트롤을 사용하여 컴플라이언스 프레임워크 사용자 지정 {#customize-compliance-frameworks-with-requirements-and-compliance-controls}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/compliance/compliance_center/compliance_status_report.md)

{{< /details >}}

이전에는 GitLab의 컴플라이언스 프레임워크를 레이블로 생성하여 프로젝트가 특정 컴플라이언스 요구 사항을 갖고 있거나 추가 감시가 필요함을 식별할 수 있었습니다. 이 레이블은 보안 정책이 그룹 내의 모든 프로젝트에 적용될 수 있도록 하기 위한 범위 지정 메커니즘으로 사용될 수 있었습니다.

이 릴리스에서 저희는 컴플라이언스 관리자가 '요구 사항'을 통해 GitLab에서 더 심층적인 컴플라이언스 모니터링을 수행할 수 있는 새로운 방법을 소개합니다.

요구 사항과 함께, 사용자 지정 컴플라이언스 프레임워크의 일부로서 조직이 따라야 하는 여러 컴플라이언스 표준, 법률 및 규정의 특정 요구 사항을 정의할 수 있습니다.

또한 저희가 제공하는 컴플라이언스 컨트롤(이전에는 컴플라이언스 검사로 알려짐)의 수를 5개에서 50개 이상으로 확대하고 있습니다! 이 50개의 기본 제공(OOTB) 컨트롤을 컴플라이언스 프레임워크 요구 사항에 매핑할 수 있습니다.

이러한 컨트롤은 GitLab 인스턴스 전체의 특정 프로젝트, 보안 및 머지 리퀘스트 설정을 검사하여 SOC2, NIST, ISO 27001 및 GitLab CIS 벤치마크와 같은 여러 컴플라이언스 표준, 법률 및 규정에 따른 요구 사항을 충족할 수 있도록 도와줍니다.

이러한 컨트롤의 준수는 표준 준수 리포트에 반영되며, 이는 요구 사항과 이러한 요구 사항에 대한 컨트롤 매핑을 고려하도록 재설계되었습니다.

OOTB 컨트롤 확대에 더하여, 저희는 이제 사용자가 요구 사항을 외부 컨트롤에 매핑할 수 있도록 허용합니다. 외부 컨트롤은 GitLab 플랫폼 외부에 존재하는 항목, 프로그램 또는 시스템일 수 있습니다. 이러한 매핑을 통해 컴플라이언스 모니터링 및 감사 증거 요구 사항과 관련하여 GitLab 컴플라이언스 센터를 단일 진실 공급원으로 사용할 수 있습니다.

### GitLab Eclipse 플러그인이 베타로 제공됨 {#gitlab-eclipse-plugin-available-in-beta}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](https://docs.gitlab.com/editor_extensions/eclipse/setup/) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/89)

{{< /details >}}

저희는 [Eclipse Marketplace](https://marketplace.eclipse.org/content/gitlab-eclipse)에서 이제 제공되는 GitLab Eclipse 플러그인의 베타 릴리스를 발표하게 되어 기쁩니다. 이 강력한 새 플러그인은 GitLab의 Duo 기능을 Eclipse IDE에 직접 확장하여 Duo Chat 및 AI 기반 코드 제안에 대한 원활한 액세스를 제공합니다.

플러그인이 현재 베타 단계에 있으므로 저희는 인증 옵션 확대 및 최종 사용자 경험 개선을 포함하여 기능을 적극적으로 개선하고 있습니다. 귀하의 피드백은 매우 중요합니다. GitLab Eclipse 플러그인을 더욱 향상시키는 데 도움을 주시기 위해 [이슈 162](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/162)에 피드백을 추가하여 의견을 공유해 주세요.

### 더 많은 GitLab Duo 기능이 이제 GitLab Duo Self-Hosted에서 사용 가능 {#more-gitlab-duo-features-now-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17072)

{{< /details >}}

이제 GitLab Self-Managed 인스턴스에서 GitLab Duo Self-Hosted를 통해 더 많은 [GitLab Duo](https://about.gitlab.com/gitlab-duo/) 기능을 사용할 수 있습니다. 다음 기능은 베타로 제공됩니다:

- [근본 원인 분석](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)
- [취약성 설명](../../user/application_security/analyze/duo.md)
- [취약성 해결](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)
- [AI 영향 대시보드](../../user/analytics/duo_and_sdlc_trends.md)
- [토론 요약](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)
- [머지 리퀘스트 커밋 메시지](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)
- [머지 리퀘스트 요약](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes)
- [GitLab Duo for the CLI](https://docs.gitlab.com/editor_extensions/gitlab_cli/#gitlab-duo-for-the-cli)

[코드 검토 요약](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review)은 GitLab Duo Self-Hosted에서도 실험으로 제공됩니다.

### Self-Managed 인스턴스의 Web IDE를 위한 확장 마켓플레이스 {#extension-marketplace-for-web-ide-on-self-managed-instances}

<!-- categories: Web IDE -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../administration/settings/vscode_extension_marketplace.md)

{{< /details >}}

저희는 자체 관리 사용자를 위해 Web IDE에서 확장 마켓플레이스를 출시하게 되어 기쁩니다. 확장 마켓플레이스를 통해 타사 확장을 발견, 설치 및 관리하여 개발 경험을 향상시킬 수 있습니다.

기본적으로 GitLab 인스턴스는 Open VSX 확장 레지스트리를 사용하도록 구성됩니다. 이를 활성화하려면 [기본 확장 레지스트리 사용](../../administration/settings/vscode_extension_marketplace.md#enable-the-extension-registry) 단계를 따르세요.

자신의 커스텀 레지스트리를 사용하려면 [커스텀 확장 레지스트리 연결](../../administration/settings/vscode_extension_marketplace.md#modify-the-extension-registry) 옵션도 있습니다. 이를 통해 사용 가능한 확장을 관리할 수 있는 더 많은 유연성을 제공합니다.

확장 마켓플레이스를 활성화한 후 개별 사용자는 여전히 사용을 선택해야 합니다. 사용자는 **연동** 섹션에서 [Preferences](https://gitlab.com/-/profile/preferences) 설정으로 이동하여 수행할 수 있습니다.

일부 확장은 로컬 런타임 환경이 필요하며 웹 전용 버전과 호환되지 않는다는 점을 주목하는 것이 중요합니다. 그럼에도 불구하고 수천 개의 사용 가능한 확장 중에서 선택하여 생산성을 높이고 워크플로우를 사용자 지정할 수 있습니다.

### GitLab Duo with Amazon Q가 일반적으로 사용 가능함 {#gitlab-duo-with-amazon-q-is-generally-available}

<!-- categories: Code Suggestions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../user/duo_amazon_q/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16879)

{{< /details >}}

저희는 포괄적인 GitLab AI 기반 DevSecOps 플랫폼을 자율 Amazon Q AI 에이전트와 단일 통합 솔루션으로 통합하는 결합 제품인 GitLab Duo with Amazon Q의 일반 공급 가능성을 발표하게 되어 기쁩니다. GitLab Duo with Amazon Q는 AI 에이전트를 개발 워크플로우에 직접 통합하여 개발자가 도구를 전환하지 않고도 주요 작업을 가속화할 수 있습니다. GitLab DevSecOps 플랫폼 내의 지능형 어시스턴트로 역할을 하면서 이러한 에이전트는 코드 생성, 테스트, 검토 및 Java 현대화 같은 시간 소비 프로세스를 자동화하여 팀이 보안 및 품질 표준을 유지하면서 혁신에 집중할 수 있도록 도와줍니다.

GitLab Duo with Amazon Q는 개발팀에 주요 이점을 제공합니다:

- 아이디어에서 코드로 기능 개발을 간소화합니다: `/q dev`을 사용하면 이슈 설명을 몇 분 내에 병합 준비가 된 코드로 변환할 수 있습니다.
- 번거로움 없이 레거시 코드를 현대화합니다: `/q transform`을 사용하여 전체 Java 현대화 프로세스를 자동화합니다.
- 품질을 희생하지 않고 코드 검토를 가속화합니다: `/q review`을 사용하여 머지 리퀘스트에서 직접 코드 품질 및 보안에 대한 즉각적인 지능형 피드백을 받습니다.
- 테스트를 자동화하여 자신감 있게 배포합니다: `/q test`을 사용하여 애플리케이션 로직을 이해하는 포괄적인 단위 테스트를 생성합니다.

### 보호된 컨테이너 태그로 보안 강화 {#enhance-security-with-protected-container-tags}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/container_registry/protected_container_tags.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/523893)

{{< /details >}}

컨테이너 레지스트리는 최신 DevSecOps 팀의 중요한 인프라입니다. 지금까지 Developer 역할 이상의 GitLab 사용자는 자신의 프로젝트의 모든 컨테이너 태그를 푸시하고 삭제할 수 있었으며, 이는 프로덕션 중요 컨테이너 이미지의 우발적이거나 승인되지 않은 변경의 위험을 초래했습니다.

보호된 컨테이너 태그를 통해 이제 특정 컨테이너 태그를 누가 푸시하거나 삭제할 수 있는지에 대한 세분화된 제어가 가능합니다. 다음을 수행할 수 있습니다.

- 프로젝트당 최대 5개의 보호 규칙을 생성합니다.
- RE2 정규식 패턴을 사용하여 `latest`과 같은 태그, 시맨틱 버전(예: `v1.0.0`) 또는 안정적인 릴리스 태그(예: `main-stable`)를 보호합니다.
- 푸시 및 삭제 작업을 Maintainer, Owner 또는 Administrator 역할로 제한합니다.
- 정리 정책에 의해 보호된 태그가 제거되지 않도록 방지합니다.

이 기능은 차세대 컨테이너 레지스트리를 필요로 하며, 이미 GitLab.com에서 기본적으로 활성화되어 있습니다. GitLab Self-Managed 인스턴스의 경우 보호된 컨테이너 태그를 사용하려면 [메타데이터 데이터베이스](../../administration/packages/container_registry_metadata_database.md)를 활성화해야 합니다.

### 보호된 Maven 패키지로 레지스트리 보호 {#safeguard-your-registry-with-protected-maven-packages}

<!-- categories: Package Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/packages/package_registry/package_protection_rules.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/323969)

{{< /details >}}

저희는 GitLab 패키지 레지스트리의 보안 및 안정성을 강화하기 위해 보호된 Maven 패키지에 대한 지원을 도입하게 되어 기쁩니다. 패키지의 우발적인 수정은 전체 개발 프로세스를 방해할 수 있습니다. 보호된 패키지를 통해 가장 중요한 종속성을 의도하지 않은 변경으로부터 보호할 수 있습니다.

GitLab 17.11에서 이제 보호 규칙을 생성하여 Maven 패키지를 보호할 수 있습니다. 패키지가 보호 규칙과 일치하면 지정된 사용자만 패키지의 새 버전을 푸시할 수 있습니다. 패키지 보호 규칙은 우발적인 덮어쓰기를 방지하고, 규제 요구 사항 준수를 개선하며, 수동 감독의 필요성을 줄입니다.

[보호된 패키지](https://gitlab.com/groups/gitlab-org/-/epics/5574) Maven 및 기타 패키지 형식에 대한 지원은 모두 `gerardo-navarro` 및 Siemens 팀의 커뮤니티 기여입니다. Gerardo와 Siemens의 나머지 팀이 GitLab에 많은 기여를 주셔서 감사합니다! Gerardo와 Siemens 팀이 이 변경에 기여한 방법에 대해 자세히 알고 싶으시면 Gerardo가 외부 기여자로서의 경험을 바탕으로 GitLab에 기여하기 위한 학습 내용과 모범 사례를 공유하는 이 [동영상](https://www.youtube.com/watch?v=5-nQ1_Mi7zg)을 확인하세요.

### 에픽, 이슈 및 작업 사용자 지정 필드 {#epic-issue-and-task-custom-fields}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/work_items/custom_fields.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/14904)

{{< /details >}}

이 릴리스에서는 이슈, 에픽, 작업, 목표 및 주요 결과를 위해 텍스트, 숫자, 단일 선택 및 다중 선택 사용자 지정 필드를 구성할 수 있습니다. 지금까지 레이블이 작업 항목을 분류하는 주요 방법이었지만 사용자 지정 필드는 계획 아티팩트에 구조화된 메타데이터를 추가하기 위한 더 사용자 친화적인 접근 방식을 제공합니다.

사용자 지정 필드는 최상위 그룹에서 구성되며 모든 하위 그룹 및 프로젝트에 계단식으로 적용됩니다. 필드를 하나 이상의 작업 항목 유형으로 매핑하고 이슈 및 에픽 목록의 사용자 지정 필드 값으로 필터링할 수 있습니다.

### 새로운 이슈 모양이 이제 일반적으로 사용 가능 {#new-issue-look-now-generally-available}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/issues/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/525547)

{{< /details >}}

이 릴리스부터 새로운 이슈 모양이 일반적으로 사용 가능하며 기존 이슈 경험을 대체합니다. 이슈는 이제 에픽 및 작업과 공통 프레임워크를 공유하며 실시간 업데이트 및 워크플로우 개선을 특징으로 합니다:

- **Drawer view:** 목록이나 보드에서 항목을 드로어에서 열어 현재 컨텍스트를 벗어나지 않고 빠르게 확인할 수 있습니다. 상단의 버튼을 통해 전체 페이지 보기로 확장할 수 있습니다.
- **Change type:** "유형 변경" 작업을 사용하여 에픽, 이슈 및 작업 간에 유형을 변환합니다("에픽으로 승격" 대체).
- **시작일:** 이슈는 이제 시작 날짜를 지원하여 에픽 및 작업과의 기능을 정렬합니다.
- **Ancestry:** 전체 계층은 제목 위와 사이드바의 상위 필드 위에 있습니다. 관계를 관리하려면 새로운 빠른 작업 명령 `/set_parent`, `/remove_parent`, `/add_child` 및 `/remove_child`을 사용하세요.
- **Controls:** 모든 작업은 이제 상단 메뉴(수직 줄임표)에서 액세스할 수 있으며 스크롤할 때 고정 헤더에서 표시 상태를 유지합니다.
- **Development:** 모든 개발 항목(머지 리퀘스트, 브랜치 및 기능 플래그)과 관련된 이슈 또는 작업이 이제 단일의 편리한 목록으로 통합됩니다.
- **Layout:** UI 개선사항은 이슈, 에픽, 작업 및 머지 리퀘스트 간의 더 원활한 환경을 만들어 워크플로우를 더 효율적으로 탐색할 수 있도록 도와줍니다.
- **Linked items:** 작업, 이슈 및 에픽 간에 개선된 링크 옵션으로 관계를 생성합니다. 드래그 앤 드롭으로 링크 유형을 변경하고 레이블 및 종료된 항목의 표시 유형을 전환합니다.

### 서비스 계정 UI {#service-accounts-ui}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/profile/service_accounts.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9965)

{{< /details >}}

이제 GitLab UI에서 서비스 계정을 생성하고 관리하기 위한 전용 공간을 사용할 수 있습니다. 이 인터페이스를 통해 GitLab 리소스에 대한 자동화된 액세스를 생성, 모니터링 및 제어할 수 있습니다. 이전에는 이 기능을 API에서만 사용할 수 있었습니다.

### 자동 Duo Pro 및 Duo Enterprise 사용자 할당 {#automated-duo-pro-and-duo-enterprise-seat-assignment}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../user/group/saml_sso/group_sync.md#manage-gitlab-duo-seat-assignment) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/502496)

{{< /details >}}

이제 SAML 그룹 동기화를 통해 사용자에게 Duo Pro 또는 Duo Enterprise 사용자를 자동으로 할당할 수 있습니다. GitLab 그룹에 사용 가능한 Duo Pro 또는 Duo Enterprise 사용자가 있는 한, 신원 제공자에서 매핑된 모든 사용자가 자동으로 사용자를 할당받습니다. 이는 사용자 할당을 관리하는 노력을 줄입니다.

### CI/CD 파이프라인 입력 {#cicd-pipeline-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../ci/inputs/_index.md#for-a-pipeline)

{{< /details >}}

CI/CD 변수는 동적 CI/CD 워크플로우에 필수적이며 환경 변수, 컨텍스트 변수, 도구 구성 및 매트릭스 변수를 포함하여 많은 용도로 사용됩니다. 그러나 개발자는 때때로 CI/CD 변수를 사용하여 [파이프라인 변수](../../ci/variables/_index.md#use-pipeline-variables)를 파이프라인에 주입하여 파이프라인 동작을 수동으로 수정하는데, 이는 파이프라인 변수의 높은 우선 순위로 인한 몇 가지 위험이 있습니다.

GitLab 17.11 이상에서는 이제 `inputs`을 사용하여 파이프라인 변수 대신 파이프라인 동작을 안전하게 수정할 수 있으며, 예약된 파이프라인, 다운스트림 파이프라인, 트리거된 파이프라인 및 기타 경우를 포함합니다. 입력은 개발자에게 CI/CD 작업 런타임에 동적 콘텐츠를 주입하기 위한 더 구조화되고 유연한 솔루션을 제공합니다. 입력으로 전환한 후 [파이프라인 변수에 대한 액세스를 완전히 비활성화](../../ci/variables/_index.md#restrict-pipeline-variables)할 수 있습니다.

이를 시도하고 이 전용 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/533802)를 통해 피드백을 공유해 주시면 감사하겠습니다.

## 에이전틱 코어 {#agentic-core}

### GitLab Duo Chat이 이제 Anthropic Claude Sonnet 3.7 사용 {#gitlab-duo-chat-now-uses-anthropic-claude-sonnet-37}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [문서](../../user/gitlab_duo_chat/examples.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/521034)

{{< /details >}}

GitLab Duo Chat은 이제 기본 모델로 Anthropic Claude Sonnet 3.7을 사용하며, 대부분의 질문에 대답하기 위해 Claude 3.5 Sonnet을 대체합니다.

Claude 3.7 Sonnet은 코딩 및 추론 기능을 크게 개선했으며, 코드 설명, 코드 생성, 텍스트 데이터 처리 및 복잡한 DevSecOps 질문에 대한 답변에 훨씬 더 효과적입니다. 이러한 영역에서 더 상세하고 정확한 Chat 응답을 알 수 있을 것입니다.

이 업그레이드는 모든 Chat 기능에 적용되며 전체 Chat 인터페이스에서 일관되고 개선된 경험을 보장합니다.

### 열린 파일을 GitLab Duo Self-Hosted 코드 제안의 컨텍스트로 이용 가능 {#open-files-as-context-now-available-on-gitlab-duo-self-hosted-code-suggestions}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../user/project/repository/code_suggestions/context.md#using-open-files-as-context) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16611)

{{< /details >}}

GitLab Duo Self-Hosted에서는 이제 코드 제안을 사용할 때 [IDE의 탭에서 열린 파일](../../user/project/repository/code_suggestions/context.md#using-open-files-as-context)을 컨텍스트로 사용할 수 있습니다.

### GitLab Duo Self-Hosted의 AI 기반 기능에 대해 개별 모델 선택 {#select-individual-models-for-ai-powered-features-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17099)

{{< /details >}}

GitLab Duo Self-Hosted에서는 이제 GitLab Self-Managed 인스턴스의 각 GitLab Duo 기능 및 부기능에 대해 지원되는 개별 모델을 선택하고 구성할 수 있습니다.

피드백을 남기려면 [이슈 524175](https://gitlab.com/gitlab-org/gitlab/-/issues/524175)로 이동하세요.

### Llama 3 모델이 GitLab Duo Chat 및 코드 제안에 대해 일반적으로 사용 가능 {#llama-3-models-generally-available-for-gitlab-duo-chat-and-code-suggestions}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15678)

{{< /details >}}

Llama 3 모델은 이제 GitLab Duo Self-Hosted와 함께 일반적으로 사용 가능하여 GitLab Duo Chat 및 코드 제안을 지원합니다.

GitLab Duo Self-Hosted에서 이러한 모델 사용에 대한 피드백을 남기려면 [이슈 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918)을 참조하세요.

### GitLab Duo Chat에서 여러 대화 관리 {#manage-multiple-conversations-in-gitlab-duo-chat}

<!-- categories: Duo Chat -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/gitlab_duo_chat/_index.md#have-multiple-conversations) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16108)

{{< /details >}}

GitLab Duo Chat과의 여러 대화가 이제 GitLab Self-Managed 인스턴스에서 웹 UI로 사용 가능합니다. 새로운 대화를 생성하고, 대화 기록을 찾아보고, 컨텍스트를 잃지 않고 대화 간에 전환할 수 있습니다.

개인정보 보호를 위해 30일 동안 활동이 없는 대화는 자동으로 삭제되며 언제든지 대화를 수동으로 삭제할 수 있습니다. GitLab Self-Managed에서는 관리자가 대화 보관 기간을 줄일 수 있습니다.

[이슈 526013](https://gitlab.com/gitlab-org/gitlab/-/issues/526013)에서 경험을 공유해 주세요.

## 규모 및 배포 {#scale-and-deployments}

### 이제 자동 비활성화된 모든 웹후크가 자동으로 다시 활성화됨 {#all-auto-disabled-webhooks-now-automatically-re-enable}

<!-- categories: Notifications -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/integrations/webhooks.md#auto-disabled-webhooks) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/396577)

{{< /details >}}

이 릴리스에서 `4xx` 오류를 반환하는 웹후크가 이제 자동으로 다시 활성화됩니다. 모든 오류(`4xx`, `5xx` 또는 서버 오류)가 동일한 방식으로 처리되어 보다 예측 가능한 동작과 더 쉬운 문제 해결이 가능합니다. 이 변경 사항은 [이 블로그 게시물](https://about.gitlab.com/blog/gitlab-webhooks-get-smarter-with-self-healing-capabilities/)에서 발표되었습니다.

실패한 웹후크는 일시적으로 1분 동안 비활성화되며 최대 24시간까지 확장됩니다. 웹후크가 40회 연속으로 실패한 후에는 이제 영구적으로 비활성화됩니다.

GitLab 17.10 이전에 영구적으로 비활성화된 웹후크는 데이터 마이그레이션을 거쳤습니다.

- GitLab.com의 경우 이러한 변경 사항이 자동으로 적용됩니다.
- GitLab Self-Managed 및 GitLab Dedicated의 경우 이러한 변경 사항은 `auto_disabling_webhooks``ops` 플래그가 활성화된 인스턴스에만 영향을 미칩니다.

이 [커뮤니티 기여](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329)를 주신 [Phawin](https://gitlab.com/lifez)에게 감사합니다!

### 가져오기 중 고스트 사용자 기여가 자동으로 매핑됨 {#ghost-user-contributions-auto-mapped-during-imports}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/import/mapping/post_migration_mapping.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/514014)

{{< /details >}}

이전에는 고스트 사용자 기여가 수동 재할당이 필요한 자리 표시자 참조를 만들어 마이그레이션 중에 추가 작업을 만들었습니다. 이제 새로운 [기여 및 멤버십 매핑 기능](../../user/import/mapping/post_migration_mapping.md)을 사용하는 가져오기, 직접 전송 마이그레이션, GitHub, Bitbucket Server 및 Gitea 가져오기는 고스트 사용자 기여를 더 지능적으로 처리합니다. GitLab으로 콘텐츠를 가져올 때 소스 인스턴스의 고스트 사용자가 이전에 만든 기여가 이제 자동으로 대상 인스턴스의 고스트 사용자로 매핑됩니다.

이 개선으로 인해 고스트 사용자 기여에 대해 불필요한 자리 표시자 사용자 생성이 제거되어 사용자 매핑 인터페이스의 혼란을 줄이고 마이그레이션 프로세스를 단순화합니다.

### GitLab.com으로 가져올 때 기여 재할당에 대한 SAML 검증 {#saml-verification-for-contribution-reassignment-when-importing-to-gitlabcom}

<!-- categories: Importers -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/import/mapping/reassignment.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/513686)

{{< /details >}}

이 마일스톤에서 GitLab.com으로 가져올 때 기여 재할당에 SAML 검증 검사를 추가했습니다. 이러한 검사는 SAML SSO가 활성화된 그룹의 재할당 오류를 방지합니다.

GitLab.com으로 가져오고 GitLab.com 그룹에 SAML SSO를 사용하는 경우 모든 사용자는 기여 및 멤버십을 재할당할 수 있으려면 SAML ID를 GitLab.com 계정에 연결해야 합니다. SAML ID를 검증하지 않은 사용자에게 기여를 재할당하면 오류 메시지가 표시됩니다. 이러한 메시지는 그룹 멤버십이 올바르게 속성되도록 하기 위해 취해야 할 단계를 설명합니다.

### 운영자 영역에서 자리 표시자 사용자 필터링 {#filter-placeholder-users-in-admin-area}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/admin_area.md#administering-users) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/521974)

{{< /details >}}

이전에는 가져오기 중에 생성된 자리 표시자 사용자가 **운영자** 영역 **사용자** 페이지에 명확한 구분 없이 일반 사용자와 함께 표시되었습니다.

이 릴리스에서 관리자는 이제 **사용자** 영역의 **운영자** 페이지 검색 상자에서 자리 표시자 계정을 필터링할 수 있습니다. 이를 수행하려면 드롭다운 목록에서 `Type`을 선택한 다음 `Placeholder`를 선택합니다.

### 자리 표시자 사용자 제한이 그룹 사용 할당량에 나타남 {#placeholder-user-limits-appear-in-group-usage-quotas}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/import/mapping/post_migration_mapping.md#placeholder-user-limits) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/486691)

{{< /details >}}

GitLab.com으로 가져오는 경우 자리 표시자 사용자는 최상위 그룹당 제한됩니다. 이러한 제한은 GitLab 라이선스 및 사용자 수에 따라 달라집니다. 이 릴리스에서는 최상위 그룹의 자리 표시자 사용자 사용 및 제한을 UI에서 확인할 수 있습니다.

현재 사용 및 제한을 보려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹을 찾으세요. 이 그룹은 최상위 수준이어야 합니다.
1. **설정 > Usage Quotas**을 선택합니다.
1. **가져오기** 탭을 선택합니다.

### Geo - 새로운 복제 가능 보기 {#geo---new-replicables-view}

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](../../administration/geo/_index.md)

{{< /details >}}

저희는 Geo의 복제 가능 보기에 대한 새로운 모양과 느낌을 소개합니다. 새로운 경험은 GitLab의 나머지 부분과 더 잘 정렬되며 Geo 보조 사이트의 동기화 및 검증 상태를 검토할 수 있는 더 간소화되고 덜 복잡한 인터페이스를 제공합니다. 또한 이제 각 복제 가능 항목에 대한 클릭 스루 상세 보기가 있어 기본 및 보조 체크섬, 오류 세부 정보 등과 같은 정보를 제공합니다. 이 정보는 Geo 동기화 이슈 해결을 훨씬 더 쉽게 만들 것입니다.

### Linux 패키지 개선사항 {#linux-package-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](https://docs.gitlab.com/omnibus/) \| [관련 이슈](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8504)

{{< /details >}}

GitLab 18.0에서는 최소 지원 PostgreSQL 버전이 버전 16이 됩니다. 이러한 변경을 준비하기 위해 [PostgreSQL Cluster](../../administration/postgresql/replication_and_failover.md)를 사용하지 않는 인스턴스에서 GitLab 17.11로 업그레이드하면 PostgreSQL을 자동으로 버전 16으로 업그레이드하려고 시도합니다.

[PostgreSQL Cluster](../../administration/postgresql/replication_and_failover.md)를 사용하거나 [이 자동 업그레이드를 거부](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)하는 경우, GitLab 18.0으로 업그레이드할 수 있으려면 [PostgreSQL 16으로 수동 업그레이드](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)해야 합니다.

### 배포 전 이벤트 데이터 공유를 비활성화하는 옵트아웃 토글 {#pre-deployment-opt-out-toggle-to-disable-event-data-sharing}

<!-- categories: Application Instrumentation -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../administration/settings/event_data.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)

{{< /details >}}

GitLab 18.0에서는 GitLab Self-Managed 및 GitLab Dedicated 인스턴스에서 이벤트 수준 제품 사용 데이터 수집을 활성화할 계획입니다. 집계된 데이터와 달리 이벤트 수준 데이터는 GitLab에 사용 패턴을 더 깊이 있게 파악하여 플랫폼의 사용자 경험을 개선하고 기능 채택을 증가시킬 수 있습니다.

GitLab 17.11부터는 이벤트 데이터 수집이 시작되기 전에 거부할 수 있는 기능을 갖게 되어 사전에 참여를 선택할 수 있습니다. 자세한 내용 및 옵트아웃 방법에 대한 정보는 문서를 참조하세요.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 시크릿 푸시 보호 및 파이프라인 시크릿 검색에 대한 증가된 규칙 적용 {#increased-rule-coverage-for-secret-push-protection-and-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/secret_detection/detected_secrets.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/534106)

{{< /details >}}

GitLab 시크릿 검색은 17개의 새로운 시크릿 푸시 보호 규칙 및 12개의 새로운 파이프라인 시크릿 검색 규칙을 포함하여 상당한 업데이트를 받았습니다. 일부 기존 규칙도 품질을 개선하고 거짓 양성을 줄이도록 업데이트되었습니다. 자세한 내용은 [변경 로그](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/CHANGELOG.md#v090)에서 v0.9.0을 참조하세요.

### Python 지원을 통한 정적 도달성 베타 {#static-reachability-beta-with-python-support}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/application_security/dependency_scanning/static_reachability.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15781)

{{< /details >}}

Composition Analysis 팀은 Python에 대한 정적 도달성 베타 지원을 릴리스했습니다. 이 베타 릴리스는 안정성 및 관찰성 강화에 중점을 두고 더 쉬운 구성을 통해 더 나은 사용자 경험을 제공합니다.

정적 도달성은 소프트웨어 구성 분석(SCA) 결과를 강화합니다. GitLab Advanced SAST에서 지원하는 정적 도달성은 프로젝트 소스 코드를 스캔하여 어떤 오픈 소스 종속성이 사용 중인지 식별합니다.

정적 도달성에서 생성된 데이터를 분류 및 개선 의사 결정의 일부로 사용할 수 있습니다. 정적 도달성 데이터는 CVSS 및 EPSS 점수는 물론 KEV 표시기와도 함께 사용하여 취약성에 대한 보다 집중된 보기를 제공할 수 있습니다.

이 기능에 대한 피드백을 환영합니다. 질문, 의견이 있거나 저희 팀과 소통하고 싶으신 경우 이 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/535498)를 참조하세요.

### 반영된 XSS 검사에 대한 동적 분석 지원 {#dynamic-analysis-support-for-reflected-xss-checks}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dast/browser/checks/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/525861)

{{< /details >}}

동적 분석 팀은 [CWE-79](https://cwe.mitre.org/data/definitions/79.html)에 대한 검사를 도입했습니다. 이 작업을 통해 저희 DAST 스캐너는 반영된 XSS 공격을 검사할 수 있습니다.

반영된 XSS 검사는 기본적으로 활성화됩니다. 이 검사를 끄려면 구성에서 `DAST_FF_XSS_ATTACK: false`을 설정하세요. 질문 또는 피드백이 있으면 [이슈 525861](https://gitlab.com/gitlab-org/gitlab/-/issues/525861)을 참조하세요.

### 코드 제안에서 가져온 파일을 컨텍스트로 사용 {#use-imported-files-as-context-in-code-suggestions}

<!-- categories: Code Suggestions -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 추가 기능: Duo Pro, Duo Enterprise
- 링크: [설명서](../../user/project/repository/code_suggestions/context.md#using-imported-files-as-context) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/58)

{{< /details >}}

GitLab Duo 코드 제안은 이제 IDE의 가져온 파일을 사용하여 제안의 품질을 강화하고 개선할 수 있습니다. 가져온 파일은 프로젝트에 대한 추가 컨텍스트를 제공합니다. 가져온 파일 컨텍스트는 JavaScript 및 TypeScript 파일에 대해 지원됩니다.

### 컴플라이언스 프레임워크를 생성할 때 프로젝트 할당 {#assign-projects-when-creating-compliance-frameworks}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate, Premium
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/compliance/compliance_frameworks/_index.md#apply-a-compliance-framework-to-a-project) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/500520)

{{< /details >}}

과거에는 컴플라이언스 프레임워크를 생성한 후 컴플라이언스 센터의 **프로젝트** 탭으로 이동하지 않고 프로젝트에 새로운 컴플라이언스 프레임워크를 할당할 수 없었습니다. 이 상황은 그룹에서 새로운 컴플라이언스 프레임워크를 생성하는 데 불필요한 마찰을 초래했습니다.

GitLab 17.11에서 컴플라이언스 프레임워크를 생성할 때, 생성되기 전에 여러 프로젝트를 컴플라이언스 프레임워크에 할당하는 옵션을 제공하는 새로운 단계를 도입했습니다.

이 새로운 기능:

- 컴플라이언스 프레임워크 생성 워크플로우에 머물러 있도록 도와줍니다.
- 컴플라이언스 프레임워크가 그룹의 프로젝트와 함께 작동하여 전체 그룹의 컴플라이언스 준수를 모니터링하고 적용하는 것을 이해할 수 있도록 지도를 제공합니다.

### Kubernetes 1.32 지원 {#kubernetes-132-support}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509283)

{{< /details >}}

이 릴리스는 2024년 12월에 릴리스된 Kubernetes 버전 1.32에 대한 완전한 지원을 추가합니다. 앱을 Kubernetes에 배포하는 경우 이제 연결된 클러스터를 최신 버전으로 업그레이드하고 모든 기능을 활용할 수 있습니다.

[저희의 Kubernetes 지원 정책 및 기타 지원되는 Kubernetes 버전](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)에 대해 자세히 알아볼 수 있습니다.

### Switchboard에서 여러 신원 제공자를 통해 SAML 단일 로그인 구성 {#configure-saml-single-sign-on-with-multiple-identity-providers-in-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- 티어: Gold
- 링크: [설명서](../../administration/dedicated/configure_instance/authentication/saml.md)

{{< /details >}}

이제 GitLab Dedicated 인스턴스에 대해 최대 10개의 신원 제공자(IdP)에 대한 SAML 단일 로그인(SSO)을 구성할 수 있습니다.

GitLab Dedicated 인스턴스에서 사용 가능한 모든 SAML 구성 옵션을 각 개별 IdP에 대해 구성할 수 있습니다.

이전에 여러 IdP를 구성했다면 이제 Switchboard에서 직접 모든 기존 SAML 구성을 확인하고 편집할 수 있습니다.

### 종속성 프록시에 대한 Docker Hub 인증 UI {#docker-hub-authentication-ui-for-the-dependency-proxy}

<!-- categories: Container Registry -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [문서](../../user/packages/dependency_proxy/_index.md#authenticate-with-docker-hub) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/521954)

{{< /details >}}

저희는 GitLab 종속성 프록시에서 Docker Hub 인증에 대한 UI 지원을 발표하게 되어 기쁩니다. 이 기능은 처음에 GraphQL API 지원 전용으로 GitLab 17.10에서 도입되었으며 이제 더 쉬운 구성을 위한 사용자 인터페이스를 포함합니다.

이 개선을 통해 이제 그룹 설정 페이지에서 직접 Docker Hub 인증을 구성할 수 있으며, 다음을 도와줍니다:

- 속도 제한으로 인한 파이프라인 실패를 방지합니다.
- 프라이빗 Docker Hub 이미지에 액세스합니다.
- Docker Hub 자격 증명, [개인 액세스 토큰](https://docs.docker.com/security/for-developers/access-tokens/) 또는 [조직 액세스 토큰](https://docs.docker.com/security/for-admins/access-tokens/)을 안전하게 저장합니다.

이 간소화된 접근 방식을 통해 GraphQL API를 사용하지 않고도 CI/CD 파이프라인에서 Docker Hub 이미지에 대한 중단 없는 액세스를 유지하기가 더 쉬워집니다.

### 가중치별로 진행 중인 작업 제한 설정 {#set-work-in-progress-limits-by-weight}

<!-- categories: Team Planning -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/project/issue_board.md#work-in-progress-limits) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/119208)

{{< /details >}}

이제 이슈 수에 더하여 가중치별로 진행 중인 작업 제한을 설정할 수 있으므로 팀의 워크로드를 관리할 때 더 많은 유연성을 제공합니다.

이슈의 수보다는 각 작업의 복잡성 또는 노력을 기반으로 작업 흐름을 제어합니다. 이슈 가중치를 노력을 나타내기 위해 사용하는 팀은 이제 주어진 보드 목록의 이슈 총 가중치를 제한함으로써 과도한 약속을 하지 않도록 할 수 있습니다.

이 기능을 사용하여 팀의 생산성을 최적화하고 다양한 작업 복잡성을 고려한 더 균형 잡힌 워크플로우를 만듭니다.

### 개선된 wiki 사이드바 스타일링 {#improved-wiki-sidebar-styling}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/wiki/_index.md#customize-sidebar)

{{< /details >}}

사용자 지정 wiki 사이드바는 이제 제목 크기 감소 및 목록에 대한 왼쪽 패딩 개선으로 개선된 스타일링을 특징으로 합니다. 이러한 인체공학적 개선은 `_sidebar` wiki 페이지를 통해 생성된 사용자 지정 네비게이션의 가독성을 개선합니다.

사용자 지정 사이드바는 팀이 wiki 콘텐츠를 고유한 기술 자료 구조에 맞게 구성하는 데 도움이 됩니다. 이 스타일 업데이트를 통해 사이드바를 더 쉽게 스캔할 수 있으므로 팀 멤버가 관련 정보를 더 빠르게 찾을 수 있도록 도와주는 더 명확한 시각적 계층 구조를 만듭니다.

### GLQL 보기에 마지막 댓글을 열로 표시 {#display-last-comment-as-a-column-in-glql-views}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/glql/fields.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/512154)

{{< /details >}}

GLQL 보기는 이제 이슈 또는 머지 리퀘스트의 마지막 댓글을 열로 표시하는 것을 지원합니다. `lastComment`을(를) GLQL 쿼리의 필드로 포함하면 현재 컨텍스트를 벗어나지 않고 최근 업데이트를 볼 수 있습니다.

이전에는 각 이슈 또는 머지 리퀘스트를 개별적으로 열어 마지막 댓글을 봐야 했으므로 시간이 걸렸고 진행 상황을 빠르게 파악하기가 어려웠습니다. 이 개선은 진행 중인 대화 및 상태 업데이트에 대한 한눈에 파악할 수 있는 가시성을 제공함으로써 팀이 모멘텀을 유지할 수 있도록 도와줍니다.

이 개선 사항 및 일반적인 GLQL 보기에 대한 피드백은 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509791)에서 환영합니다.

### GitLab Pages를 위한 Nuxt 프로젝트 템플릿 {#nuxt-project-template-for-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/project/pages/getting_started/pages_new_project_template.md)

{{< /details >}}

GitLab은 가장 인기 있는 정적 사이트 생성자(SSG)에 대한 템플릿을 제공하며 이제 Vue.js 위에 구축된 강력한 프레임워크인 Nuxt를 사용하여 GitLab Pages 사이트를 생성할 수 있습니다. Nuxt는 구성 오버헤드가 적은 최신의 고성능 웹 애플리케이션을 구축하려는 팀에 특히 중요합니다.

이 추가는 초기 설정 및 구성에 시간을 소비하지 않고 기본 제공 CI/CD 파이프라인 및 최신 개발 경험으로 Pages 사이트를 빠르게 시작할 수 있는 옵션을 확대합니다.

### 프로젝트 종속성 목록에 대한 CycloneDX 내보내기 {#cyclonedx-export-for-the-project-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_list/_index.md#export) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/524733)

{{< /details >}}

많은 조직은 이제 규제 요구 사항을 충족하고 소프트웨어 공급망의 보안을 더욱 강화하기 위해 소프트웨어 자재 명세서(SBOM)를 필요로 합니다. 이전에는 GitLab에서 종속성 목록을 JSON 또는 CSV 파일로만 내보낼 수 있었습니다. 이제 GitLab은 종속성 목록을 널리 채택된 CycloneDX 형식으로 내보내어 SBOM을 생성할 수 있습니다.

SBOM을 CycloneDX 파일로 직접 다운로드하려면 종속성 목록에서 **내보내기** > **CycloneDX로 내보내기 (JSON)**을 선택합니다.

### 종속성 목록 및 취약성 리포트 내보내기에 대한 이메일 배송 {#email-delivery-for-dependency-list-and-vulnerability-report-export}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_list/_index.md#export) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/513149)

{{< /details >}}

이전에는 종속성 목록 또는 취약성 리포트를 내보낼 때 내보내기가 완료되어야 리포트를 다운로드할 수 있을 때까지 페이지에 남아 있어야 했습니다.

이제 종속성 목록 또는 취약성 리포트 내보내기가 완료되면 다운로드 링크가 있는 이메일 알림을 받습니다.

### CSV 형식으로 종속성 목록 내보내기 {#export-dependency-list-in-csv-format}

<!-- categories: Dependency Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/dependency_list/_index.md#export) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/435843)

{{< /details >}}

이전에는 GitLab에서 종속성 목록을 CSV 파일로 내보낼 수 없었습니다. 이제 종속성 목록을 다운로드할 때 새로운 CSV 옵션을 선택하여 목록을 이 형식으로 내보낼 수 있습니다.

### 도구 필터가 스캐너 및 리포트 유형 필터로 대체됨 {#tool-filter-replaced-with-scanner-and-report-type-filters}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/application_security/vulnerability_report/_index.md#report-type-filter) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/503371)

{{< /details >}}

이전에는 취약성 리포트의 **tool** 검색 필터를 통해 스캐너 유형(예: ESLint 또는 Gemnasium) 및 리포트 유형(예: SAST 또는 컨테이너 스캔)을 포함하는 단일 도구 그룹을 기반으로 결과를 필터링할 수 있었습니다.

적절한 도구를 더 쉽게 찾을 수 있도록 **tool** 필터를 **scanner** 필터 및 **report type** 필터로 대체했습니다. 이제 각 도구 유형을 기반으로 검색을 필터링할 수 있습니다.

### CI/CD 작업에 대해 `source` 값 저장 및 필터링 {#store-and-filter-a-source-value-for-cicd-jobs}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../api/jobs.md#retrieve-a-job-by-job-id) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11796)

{{< /details >}}

GitLab 17.11은 CI/CD 작업의 소스 속성을 추적하여 빌드 아티팩트의 원점을 검증할 수 있는 새로운 기능을 소개합니다. 이 개선은 보안 및 컴플라이언스 워크플로우에 특히 중요합니다. 예를 들어 조직은 소프트웨어 공급망 보안 조치를 구현하거나 컴플라이언스 목적을 위해 보안 스캔의 검증 가능한 증거를 요구할 수 있습니다.

GitLab의 작업은 이제 다음에서 생성되었는지 식별하는 `source` 값을 저장하고 표시합니다:

- 스캔 실행 정책
- 파이프라인 실행 정책
- 정규 파이프라인

`source` 속성은 **빌드** > **작업** 페이지에서 새 필터 옵션을 사용하여, Jobs API를 사용하거나 아티팩트 검증을 위해 ID 토큰 `claims`를 통해 액세스할 수 있습니다.

이 새로운 기능을 통해 이제 다음을 수행할 수 있습니다:

- 보안 스캔 결과의 신뢰성을 검증합니다.
- 소스 유형별로 작업을 필터링하여 정책 적용 스캔을 빠르게 식별합니다.
- 새로운 ID 토큰 클레임을 사용하여 아티팩트의 암호화 검증을 구현합니다.
- 적절한 감사 추적을 통해 컴플라이언스 요구 사항이 충족되는지 확인합니다.

보안 및 컴플라이언스 팀은 이 기능을 활용할 수 있습니다:

- 작업 페이지의 새 필터를 사용하여 정책 적용 작업만 봅니다.
- Jobs API의 `source` 필드에 액세스하여 작업을 자동화합니다.
- 새 ID 토큰 클레임을 사용하여 아티팩트 검증을 구현합니다:
  - `job_source`: 작업의 출처를 식별합니다.
  - `job_policy_ref_uri`: 정책 파일(정책 정의 작업의 경우)을 가리킵니다.
  - `job_policy_ref_sha`: 정책의 git 커밋 SHA를 포함합니다.

### 액세스 토큰에 대한 향상된 정렬 옵션 {#enhanced-sorting-options-for-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/personal_access_tokens.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/519716)

{{< /details >}}

이제 UI 및 API에서 액세스 토큰에 대한 추가 정렬 옵션이 있습니다. 이러한 정렬 옵션은 GitLab의 기존 토큰 관리 기능을 보완하여 액세스 토큰 인벤토리를 더 잘 제어하고 액세스 토큰 보안을 더 잘 유지할 수 있습니다. 새로운 정렬 옵션에는 다음이 포함됩니다:

- 만료 날짜별 정렬(오름차순): 가장 먼저 만료되는 토큰을 봅니다.
- 만료 날짜별 정렬(내림차순): 가장 오래 남은 수명을 가진 토큰을 봅니다.
- 마지막 사용 날짜별 정렬(오름차순): 최근에 사용되지 않은 토큰을 봅니다.
- 마지막 사용 날짜별 정렬(내림차순): 가장 최근에 사용된 토큰을 봅니다.

### 서비스 계정 관리를 위한 토큰 통계 {#token-statistics-for-service-account-management}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../user/profile/service_accounts.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/520472)

{{< /details >}}

서비스 계정의 토큰 관리 인터페이스는 이제 토큰 인벤토리에 대한 한눈에 파악할 수 있는 정보를 제공하는 유용한 통계 대시보드를 포함합니다. 이 정보는 토큰의 상태를 평가하고 주의가 필요한 토큰을 식별하는 데 도움이 될 수 있습니다. 통계 대시보드에는 4가지 주요 지표가 포함됩니다:

- 활성 토큰: 활성 토큰의 총 수를 봅니다
- 만료 예정 토큰: 앞으로 2주 내에 만료되는 토큰을 식별합니다
- 취소된 토큰: 수동으로 취소된 토큰을 추적합니다
- 만료된 토큰: 이전에 만료된 토큰을 모니터링합니다 [Chaitanya Sonwane](https://gitlab.com/chaitanyason9)에게 기여해주셔서 감사합니다!

### 실패한 작업에 대한 개선된 파이프라인 그래프 시각화 {#improved-pipeline-graph-visualization-for-failed-jobs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/pipelines/_index.md#view-pipelines)

{{< /details >}}

이제 새로운 시각적 표시기로 파이프라인 그래프에서 실패한 작업을 빠르게 식별할 수 있습니다. 실패한 작업 그룹은 파이프라인 그래프에서 강조 표시되고 실패한 작업은 각 스테이지의 상단에 그룹화됩니다. 이 개선된 시각화는 복잡한 파이프라인 구조를 검색할 필요 없이 파이프라인 실패를 문제 해결할 수 있도록 도와줍니다.

### 취소 중인 상태에서 고착한 CI/CD 작업 강제 취소 {#force-cancel-cicd-jobs-stuck-in-canceling-state}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [문서](../../ci/jobs/_index.md#force-cancel-a-job) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/467107)

{{< /details >}}

CI/CD 작업은 때때로 '취소 중' 상태에서 고착하여 배포 또는 공유 리소스 액세스를 차단할 수 있습니다.

Maintainer [역할](../../user/permissions.md)을 가진 사용자는 이제 작업 로그 페이지에서 직접 이러한 고착 작업을 강제 취소할 수 있으므로 문제가 있는 작업을 적절히 종료할 수 있습니다.

### 프로젝트에서 러너 관리 개선 {#improved-runner-management-in-projects}

<!-- categories: Fleet Visibility -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../ci/runners/runners_scope.md#project-runners)

{{< /details >}}

이제 프로젝트에서 러너를 더 효율적으로 관리할 수 있습니다. 러너는 단일 열 레이아웃으로 표시되고 이전 2열 보기 대신 자체 목록으로 구성됩니다.

이 개선된 구성을 통해 러너를 더 쉽게 찾고 관리할 수 있으며, 할당된 프로젝트 목록, 러너 관리자 및 러너가 실행한 작업 등의 새로운 기능이 포함됩니다. GitLab 18.0에 대해 계획된 추가 러너 관리 개선 사항에 대한 정보는 [이슈 33803](https://gitlab.com/gitlab-org/gitlab/-/issues/33803)을 참조하세요.

### GitLab Runner 17.11 {#gitlab-runner-1711}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

저희는 또한 오늘 GitLab Runner 17.11을 릴리스하고 있습니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 새로운 기능 {#whats-new}

- [Code sign GitLab Runner Windows executables](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2483)

#### 버그 수정 {#bug-fixes}

- [GitLab Runner 17.10.0에서 Git 구성을 정리하면 오류가 발생합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38681)
- [`FF_DISABLE_UMASK_FOR_KUBERNETES_EXECUTOR` 플래그가 `umask` 명령을 비활성화하지 않습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38382)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-11-stable/CHANGELOG.md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.11)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.11)
- [UI 개선](https://papercuts.gitlab.com/?milestone=17.11)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
