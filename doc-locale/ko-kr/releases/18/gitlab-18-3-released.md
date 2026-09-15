---
stage: Release Notes
group: Monthly Release
date: 2025-08-21
title: "GitLab 18.3 릴리스 정보"
description: "Duo Agent Platform in Visual Studio (베타)를 포함하여 GitLab 18.3 릴리스됨"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025년 8월 21일에 GitLab 18.3이 다음 기능과 함께 릴리스되었습니다.

또한 이달의 주목할 만한 기여자를 포함한 모든 기여자에게 감사드립니다.

## 이달의 주목할 만한 기여자: Ahmed Kashkoush {#this-months-notable-contributor-ahmed-kashkoush}

18.3 버전에서 저희는 [Ahmed Kashkoush](https://gitlab.com/ahmad-kashkoush)를 주목할 만한 기여자로 인정하게 되어 기쁩니다!

Ahmed는 이번 여름 [Google Summer of Code 참여](https://gitlab.com/ahmad-kashkoush/gsoc-2025-final-report)를 통해 [GitLab Web IDE](https://gitlab.com/gitlab-org/gitlab-web-ide)에 뛰어난 기여자로서의 입지를 다졌습니다. 그는 지속적으로 필수적인 Git 작업을 제공하여 오랫동안 커뮤니티에서 요청해온 문제들을 직접 해결했습니다. 그의 다섯 가지 실질적인 머지 리퀘스트에는 [커밋 및 강제 푸시 기능](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/497), [업데이트 확인 메시지](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/540), [커밋 수정 기능](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/507), [브랜치 생성 작업](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/534), 그리고 [브랜치 삭제 기능](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/539)이 포함됩니다.

새 기능을 구현하는 것 외에도 Ahmed는 Web IDE에서 기존 커밋을 수정하기 위한 5년 이상 된 기능 요청을 해결했으며, 이 기능은 커뮤니티로부터 24개의 추천을 받았습니다. 종합적인 브랜치 관리 구현은 Web IDE를 로컬 개발 환경과 기능 동등성에 더 가깝게 만들어 사용자들이 기본 Git 작업을 위해 인터페이스 간에 전환할 필요를 제거했습니다. Ahmed의 작업은 Web IDE를 개발자에게 더 접근 가능하게 만들어 "모두가 기여할 수 있습니다"라는 [GitLab의 미션](https://handbook.gitlab.com/handbook/company/mission/)을 직접 지원합니다.

Ahmed는 GitLab의 Staff Frontend Engineer인 [Enrique Alcántara](https://gitlab.com/ealcantara)에 의해 추천되었으며, 그는 Google Summer of Code 프로그램 내내 멘토로 역할을 했습니다. "Ahmed는 실제 사용자의 문제 해결에 헌신적입니다"라고 Enrique는 말합니다. "그의 작업은 집중력 있는 기여자가 핵심 GitLab 기능 개선에 미칠 수 있는 영향을 보여줍니다."

Ahmed의 기여는 오픈 소스 개발에서 멘토십과 커뮤니티 협력의 힘을 보여주며 로컬 설정에 관계없이 GitLab을 개발자에게 더 접근 가능하게 만듭니다.

Ahmed님, GitLab Web IDE에 대한 뛰어난 기여를 감사드립니다!

## 주요 기능 {#primary-features}

### Duo Agent Platform in Visual Studio (베타) {#duo-agent-platform-in-visual-studio-beta}

<!-- categories: Editor Extensions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 링크: [설명서](../../user/duo_agent_platform/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/179)

{{< /details >}}

Visual Studio용 Duo Agent Platform의 공개 베타 릴리스를 발표하게 되어 기쁩니다! 이번 릴리스를 통해 Visual Studio 사용자는 이제 IDE 내에서 Duo Agent Platform의 고급 AI 기반 기능에 액세스할 수 있습니다.

Duo Agent Platform은 워크플로우에 두 가지 강력한 기능을 제공합니다:

- **에이전트 채팅**: 파일 생성 및 편집, 패턴 매칭 및 grep을 사용한 코드베이스 검색, 코드에 대한 즉각적인 답변 취득과 같은 대화형 작업을 빠르게 수행합니다. 모두 Visual Studio를 벗어나지 않고도 가능합니다.
- **Agent flows**: 종합적인 계획 및 구현 지원으로 더 크고 복잡한 작업을 처리합니다. 에이전트 플로우는 고수준의 아이디어를 아키텍처 및 코드로 전환하는 데 도움을 주며, 이슈, 머지 리퀘스트, 커밋, CI/CD 파이프라인, 보안 등 GitLab 리소스를 활용합니다.

두 기능 모두 설명서, 코드 패턴, 프로젝트 정보 전반에 걸친 지능형 검색을 제공하므로 빠른 편집에서 심층 프로젝트 분석으로 원활하게 이동할 수 있습니다.

오늘 Visual Studio에서 Duo Agent Platform 베타를 시험해 보고 개발 워크플로우에서 새로운 수준의 생산성과 AI 지원을 경험하세요.

### GLQL로 구동되는 임베디드 뷰 {#embedded-views-powered-by-glql}

<!-- categories: Markdown, Wiki, Team Planning -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/glql/_index.md#embedded-views) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

이번 릴리스는 GLQL로 구동되는 임베디드 뷰를 일반 가용 상태로 도입합니다. GitLab 데이터의 동적이고 쿼리 가능한 뷰를 만들고 작업이 진행되는 위치에 임베드합니다: wiki 페이지, 에픽 설명, 이슈 댓글, 머지 리퀘스트에서.

임베디드 뷰는 팀이 여러 위치 간에 탐색하지 않고도 작업 진행 상황을 추적할 수 있는 안정적인 기초를 제공합니다. 친숙한 구문을 사용하여 이슈, 머지 리퀘스트, 에픽 및 기타 작업 항목을 쿼리한 다음 사용자 정의 가능한 필드 및 필터링을 사용하여 결과를 표 또는 목록으로 표시합니다.

임베디드 뷰는 정적 문서를 프로젝트 데이터로 최신 상태를 유지하는 살아있는 대시보드로 변환하여 팀이 컨텍스트를 유지하고 워크플로우 전반에서 협력을 개선하는 데 도움을 줍니다.

임베디드 뷰를 계속 개선하면서 귀하의 피드백을 환영합니다. [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509792)에서 귀하의 의견과 제안을 공유해 주세요.

### 직접 전송을 통한 마이그레이션 {#migration-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/group/import/direct_transfer_migrations.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11398)

{{< /details >}}

직접 전송을 통한 마이그레이션은 이제 일반적으로 사용 가능합니다. GitLab 그룹 및 프로젝트를 GitLab 인스턴스 간에 직접 전송으로 마이그레이션하려면 GitLab UI 또는 [REST API](../../api/bulk_imports.md)를 사용할 수 있습니다.

[내보내기 파일을 업로드하여 마이그레이션](../../user/project/settings/import_export.md#migrate-projects-by-uploading-an-export-file)하는 것과 비교하면 직접 전송:

- 대규모 프로젝트에서 더 안정적으로 작동합니다.
- 소스 및 대상 인스턴스 간의 더 큰 버전 격차를 포함한 마이그레이션을 지원합니다.
- 마이그레이션 프로세스 및 결과에 대한 더 나은 통찰력을 제공합니다.

GitLab.com에서는 직접 전송을 통한 마이그레이션이 기본적으로 활성화됩니다. GitLab Self-Managed 및 GitLab Dedicated에서 관리자가 [기능을 활성화](../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)해야 합니다.

### CI/CD 작업 토큰에 대한 세밀한 권한 {#fine-grained-permissions-for-cicd-job-tokens}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../ci/jobs/fine_grained_permissions.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15258)

{{< /details >}}

파이프라인 보안이 더욱 유연해졌습니다. 작업 토큰은 파이프라인의 리소스에 액세스할 수 있는 임시 자격증명입니다. 지금까지 이러한 토큰은 사용자로부터 전체 권한을 상속받아 종종 불필요하게 광범위한 액세스 기능을 초래했습니다.

새로운 작업 토큰에 대한 세밀한 권한 기능을 통해 작업 토큰이 프로젝트 내에서 액세스할 수 있는 특정 리소스를 정확하게 제어할 수 있습니다. 이를 통해 CI/CD 워크플로우에서 최소 권한 원칙을 구현하여 CI/CD 토큰으로 프로젝트에 액세스할 때 이 작업을 완료하는 데 필요한 최소한의 액세스 권한만 부여할 수 있습니다.

파이프라인의 장기 토큰 의존성을 줄이기 위해 [추가 세밀한 권한](https://gitlab.com/groups/gitlab-org/-/epics/6310)을 추가하기 위해 적극적으로 작업 중입니다.

### GitLab Duo Self-Hosted에서 사용 가능한 코드 검토 (베타) {#code-review-available-on-gitlab-duo-self-hosted-beta}

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../administration/gitlab_duo_self_hosted/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/524929)

{{< /details >}}

이제 GitLab Duo Self-Hosted에서 GitLab Duo 코드 검토를 사용할 수 있습니다. 이 기능은 GitLab Duo Self-Hosted의 베타 단계이며 Mistral, Meta Llama, Anthropic Claude, OpenAI GPT 모델 계열을 지원합니다.

GitLab Duo Self-Hosted의 코드 검토를 사용하여 데이터 주권을 손상시키지 않으면서 개발 프로세스를 가속화합니다. 코드 검토가 머지 리퀘스트를 검토하면 잠재적인 버그를 식별하고 직접 적용할 수 있는 개선 사항을 제안합니다. 코드 검토를 사용하여 변경 사항을 반복하고 개선한 후 사람이 검토하도록 요청합니다.

코드 검토에 대한 피드백을 [이슈 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)에서 제공하세요.

### GitLab Duo 코드 검토를 위한 지침 사용자 지정 {#customize-instructions-for-gitlab-duo-code-review}

<!-- categories: Code Review Workflow -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 추가 기능: Duo Enterprise
- 링크: [문서](../../user/project/merge_requests/duo_in_merge_requests.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/545136)

{{< /details >}}

GitLab Duo 코드 검토의 사용자 지정 지침으로 프로젝트 전체의 일관된 코드 검토 표준을 적용합니다. glob 패턴을 사용하여 다양한 파일 유형에 대한 특정 검토 기준을 정의하여 가장 중요한 위치에서 언어별 규칙이 적용되도록 합니다.

사용자 지정 지침을 사용하면 다음을 수행할 수 있습니다:

- 팀의 코드 검토 표준 설명
- glob 패턴을 사용하여 파일별 지침 정의
- 사용자 지정 지침을 참조하는 명확하게 레이블이 지정된 피드백 관찰

리포지토리에 `.GitLab/duo/mr-review-instructions.YAML` 파일을 생성하고 사용자 지정 지침을 입력하기만 하면 됩니다. GitLab Duo는 이러한 지침을 검토에 자동으로 통합하며 피드백을 제공할 때 특정 지침 그룹을 인용합니다.

[피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)에서 의견과 제안을 공유하여 이 기능을 개선하도록 도와주세요.

### GitLab Duo Self-Hosted에 자신의 모델 가져오기 (베타) {#bring-your-own-models-to-gitlab-duo-self-hosted-beta}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/517581)

{{< /details >}}

GitLab Duo Self-Hosted는 이제 GitLab Duo 기능에 사용할 자신의 모델을 가져올 수 있게 합니다. 이 기능은 베타 단계이며 GitLab Duo Enterprise가 있는 모든 GitLab Self-Managed 고객이 사용할 수 있습니다. 인스턴스 관리자는 지원되는 GitLab Duo 기능에 사용할 호환 가능한 모델을 구성할 수 있습니다.

이 기능은 GitLab Duo Self-Hosted를 더욱 유연하게 만들지만, GitLab은 모든 GitLab Duo 기능이 모든 호환 가능한 모델에서 작동한다는 보장을 할 수 없습니다. 인스턴스 관리자는 선택한 모델의 호환성 및 성능을 검증할 책임이 있습니다. GitLab은 사용자가 선택한 특정 모델 또는 플랫폼에서 발생하는 이슈에 대해 기술 지원을 제공하지 않습니다.

### GitLab Duo Self-Hosted의 하이브리드 모델 선택 (베타) {#hybrid-model-selection-on-gitlab-duo-self-hosted-beta}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [설명서](../../administration/gitlab_duo_self_hosted/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17192)

{{< /details >}}

이제 GitLab Duo Self-Hosted에서 GitLab AI 공급업체 모델과 개인적으로 구성된 자체 호스팅 모델을 혼합하여 사용할 수 있습니다. 이 기능은 베타 단계이며 GitLab Self-Managed의 모든 GitLab Duo Enterprise 고객이 사용할 수 있습니다.

GitLab Duo Self-Hosted의 하이브리드 모델을 사용하면 GitLab Self-Managed 인스턴스 관리자는 이제 기능별로 자체 호스팅 모델 및 자체 호스팅 AI 게이트웨이 또는 GitLab AI 공급업체 모델 및 GitLab 호스팅 AI 게이트웨이를 선택할 수 있습니다. 이를 통해 관리자가 보안 및 확장성 요구 사항을 균형 있게 조정할 수 있습니다. 하이브리드 모델 선택에 대한 피드백을 제공하려면 [이슈 561048](https://gitlab.com/gitlab-org/gitlab/-/issues/561048)을 참조하세요.

### 규정 준수 프레임워크 제어 위반 표면 (베타) {#surfacing-violations-of-compliance-framework-controls-beta}

<!-- categories: Compliance Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

이전에는 규정 준수 위반 보고서가 그룹의 모든 프로젝트에 대한 머지 리퀘스트 활동의 높은 수준의 뷰를 제공했습니다. 사용 가능한 규정 준수 위반은 다음과 같은 책임 분리 문제와 관련되어 있습니다:

- 머지 리퀘스트의 작성자가 자신의 머지 리퀘스트를 승인한 경우를 감지합니다.
- 머지 리퀘스트가 두 개 미만의 승인으로 병합된 경우입니다.

그러나 사용자 피드백에 따르면 사용자들이 위반 분류가 혼란스럽고 이해하기 어렵다고 느꼈으며, 이는 실제 규정 준수 사용 사례와 잘 맞지 않기 때문입니다.

GitLab 18.3은 책임 분리를 넘어 규정 준수 프레임워크의 규정 준수 제어 및 요구사항 위반을 포함하도록 확대하여 위반 보고서를 크게 향상시킵니다. 각 사용자 지정 규정 준수 프레임워크 제어에는 위반에 대한 상세한 컨텍스트를 제공하는 관련 감사 이벤트가 있습니다: 누가 위반을 저질렀는지, 언제 발생했는지, 어떻게 해결할지입니다. 여기에는 사용자의 이름 및 IP 주소와 실행 가능한 수정 제안이 포함됩니다.

이러한 개선 사항은 규정 준수 관리자에게 더욱 강력하고 관련성 있는 컨텍스트를 제공하여 조직이 특정 규정 준수 프레임워크를 준수하도록 보장하며, 동시에 규정 준수 미준수를 효과적으로 식별, 수정, 방지할 수 있다는 확신을 제공합니다.

### 새로운 Web IDE 소스 제어 작업 {#new-web-ide-source-control-operations}

<!-- categories: Web IDE -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/project/web_ide/_index.md#use-source-control)

{{< /details >}}

Web IDE의 추가 소스 제어 기능을 발표하게 되어 기쁩니다. 브라우저를 벗어나지 않고도 Git 워크플로우를 더 효율적으로 관리할 수 있습니다. **Source Control** 패널에서 이제 다음을 수행할 수 있습니다:

- 브랜치를 생성하고 삭제합니다.
- 기존 브랜치를 기반으로 브랜치를 생성합니다.
- 빠른 수정을 위해 마지막 커밋을 수정합니다.
- 인터페이스에서 직접 변경 사항을 강제 푸시합니다.

이러한 개선 사항은 Git 작업을 손끝에 가져옵니다. 귀하가 사용할 수 있는 기능에 대한 정보는 [소스 제어 사용](../../user/project/web_ide/_index.md#use-source-control)을 참조하세요.

### GitLab CI/CD에 대한 AWS Secrets Manager 지원 {#aws-secrets-manager-support-for-gitlab-cicd}

<!-- categories: Secrets Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../ci/secrets/aws_secrets_manager.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17822)

{{< /details >}}

AWS Secrets Manager에 저장된 보안 정보를 이제 쉽게 검색하여 CI/CD 작업에서 사용할 수 있습니다. AWS와의 새로운 통합은 GitLab CI/CD를 통해 AWS Secrets Manager와 상호 작용하는 프로세스를 단순화하여 AWS 고객이 빌드 및 배포 프로세스를 간소화하도록 도와줍니다!

[Markus Siebert](https://gitlab.com/m-s-db)와 [Henry Sachs](https://gitlab.com/DerAstronaut)가 [GitLab의 Co-Create 프로그램](https://about.gitlab.com/community/co-create/)을 통해 이 기능을 구축하도록 도와주셨으므로 감사드립니다!

### 사용자 지정 운영자 역할 {#custom-admin-role}

<!-- categories: Permissions -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](../../user/custom_roles/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

사용자 지정 역할은 GitLab Self-Managed 및 GitLab Dedicated 인스턴스의 영역에 세밀한 권한을 제공합니다. 전체 액세스를 부여하는 대신 관리자는 이제 사용자가 필요한 특정 기능에만 액세스할 수 있는 특화된 역할을 생성할 수 있습니다. 이 기능은 조직이 관리 기능에 대해 최소 권한 원칙을 구현하고, 과권한 액세스로 인한 보안 위험을 줄이며, 운영 효율성을 개선하도록 도와줍니다.

질문이 있거나 구현 경험을 공유하고 싶거나 잠재적 개선 사항에 대해 당사 팀과 직접 소통하고 싶다면 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/509376)를 참조하세요.

## 에이전틱 코어 {#agentic-core}

### GitLab Duo Self-Hosted에서 사용할 수 있는 더 많은 모델 {#more-models-available-for-use-with-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed
- 추가 기능: Duo Enterprise
- 링크: [문서](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/560016)

{{< /details >}}

GitLab Duo Enterprise가 있는 GitLab Self-Managed 고객은 이제 GitLab Duo Self-Hosted에서 Anthropic Claude 4를 사용할 수 있습니다. Claude 4는 AWS Bedrock에서 지원됩니다. 오픈 소스 OpenAI GPT OSS 20B 및 120B가 실험 모델로 추가되었으며 vLLM, Azure OpenAI, AWS Bedrock에서 사용할 수 있습니다. GitLab Duo Self-Hosted에서 이러한 모델 사용에 대한 피드백을 남기려면 [이슈 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918)을 참조하세요.

## 규모 및 배포 {#scale-and-deployments}

### 귀하의 작업에서 그룹의 새로운 탐색 환경 {#new-navigation-experience-for-groups-in-your-work}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/group/_index.md#group-visibility) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/502487)

{{< /details >}}

**귀하의 작업** 안의 그룹 개요에 대한 중요한 개선 사항을 발표하게 되어 기쁘며, 그룹을 발견하고 액세스하는 방법을 간소화하도록 설계되었습니다. 새 탭 인터페이스는 접근 가능한 그룹의 포괄적인 보기를 제공하는 **멤버** 탭과 삭제 대기 중인 그룹을 추적하는 **비활성** 탭을 제공합니다. 또한 적절한 권한을 가진 사용자를 위해 목록 보기에 **편집** 및 **삭제** 작업을 추가하여 그룹 관리를 간소화했습니다. 이러한 개선 사항이 가장 중요한 그룹을 찾고 관리하기 더 쉽게 만들기를 바랍니다.

이번 업데이트에 대한 의견을 소중히 여깁니다! [에픽 18401](https://gitlab.com/groups/gitlab-org/-/epics/18401)의 논의에 참여하여 새 탐색 시스템 경험을 공유하세요.

### 개선된 **운영자** 영역 프로젝트 목록 {#enhanced-admin-area-projects-list}

<!-- categories: Groups & Projects -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](../../administration/admin_area.md#administering-projects) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/17782)

{{< /details >}}

**운영자** 영역 프로젝트 목록을 업그레이드하여 GitLab 관리자에게 더욱 일관된 경험을 제공합니다:

- 지연된 삭제 보호: 프로젝트 삭제는 이제 GitLab 전체에서 사용되는 동일한 안전한 삭제 흐름을 따르므로 의도치 않은 데이터 손실을 방지합니다.
- 더 빠른 상호 작용: 페이지 다시 로드 없이 프로젝트를 필터링, 정렬, 페이지 매김하여 더욱 반응성 있는 경험을 제공합니다.
- 일관된 인터페이스: 프로젝트 목록이 이제 GitLab 전체의 다른 프로젝트 목록의 모양과 동작과 일치합니다.

이 업데이트는 관리자 경험을 GitLab 디자인 표준과 일치하도록 하고 데이터를 보호하기 위한 중요한 안전 기능을 추가합니다. 향후 프로젝트 관리 개선 사항은 플랫폼 전체의 모든 프로젝트 목록에 자동으로 표시됩니다.

## 통합 DevOps 및 보안 {#unified-devops-and-security}

### 종속성 검사 분석기의 개선된 파일 위치 정보 {#improved-file-location-information-for-dependency-scanning-analyzer}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#customizing-behavior-with-the-cicd-template) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/537716)

{{< /details >}}

종속성을 소스로 추적할 수 있는 것은 특히 취약성 수정을 위해 중요합니다. 이전에는 종속성 검사 분석기가 때때로 만료되면 삭제되는 작업 아티팩트에 연결되었습니다. 이로 인해 종속성의 소스로 다시 추적하기가 어려웠습니다. 종속성 검사 분석기는 이제 을 도입한 프로젝트 파일에 연결할 수 있습니다. 이 옵션을 활성화하면 목록 및 취약성 보고서의 링크가 신뢰할 수 있습니다. 사용자는 종속성 검사 작업에 대해 `DS_FF_LINK_COMPONENTS_TO_GIT_FILES=true`을 설정하여 이 기능을 활성화할 수 있습니다.

### 라이선스 정보에 대한 사용자 정의 소스 {#user-defined-source-for-license-information}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#use-cyclonedx-report-as-a-source-of-license-information) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/501662)

{{< /details >}}

사용자는 이제 라이선스 정보의 소스 우선순위를 선택할 수 있습니다 - GitLab 라이선스 데이터베이스 또는 CycloneDX SBOM 보고서입니다. 이는 사용자에게 오픈 소스 에 대한 라이선스 정보를 소싱하는 데 있어 더 많은 유연성을 제공합니다. 라이선스 정보의 소스를 정의하고자 하는 사용자는 [보안 구성 UI](../../user/application_security/detect/security_configuration.md#with-the-ui)를 사용하여 선택을 할 수 있습니다. 기본적으로 라이선스 정보의 소스로 SBOM 데이터를 사용합니다.

### 간결한 DAST 작업 출력 {#concise-dast-job-output}

<!-- categories: DAST -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/dast/browser/troubleshooting.md#what-is-dast-doing) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18342)

{{< /details >}}

GitLab 18.3은 동적 애플리케이션 보안 테스트 작업 출력에 여러 개선 사항을 도입합니다.

이 개선된 작업 출력은 검사 결과를 이해하고 오류를 해결하는 데 도움이 되는 명확하고 구조화된 정보를 제공합니다.

작업 출력의 각 섹션은 간결하고 직관적이며, 출력 하단에 문제 해결 설명서에 대한 링크가 있습니다. 간결한 작업 출력을 재정의하려면 DAST 구성에서 `DAST_FF_DIAGNOSTIC_JOB_OUTPUT: "true"`을 설정합니다.

### 인스턴스 수준 규정 준수 및 정책 관리 (베타) {#instance-level-compliance-and-policy-management-beta}

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)

{{< /details >}}

엔터프라이즈 사용자는 여러 최상위 그룹에서 규정 준수 프레임워크 및 보안 정책을 관리하고자 합니다. 이는 인스턴스의 모든 그룹이 다음의 경우가 종종 있을 때입니다:

- 동일한 규정 준수 프레임워크를 공유합니다. 예를 들어, 그룹의 모든 프로젝트가 ISO 27001 표준을 준수해야 합니다.
- 유사한 정책을 적용합니다. 예를 들어, 모든 그룹이 동일한 파이프라인 실행 정책을 공유할 때입니다.

GitLab 18.3을 사용하면 규정 준수 및 보안 정책 관리가 이제 GitLab Self-Managed 인스턴스에 베타로 제공됩니다. 이제 단일 최상위 그룹에서 규정 준수 프레임워크 및 보안 정책을 생성, 구성, 할당하고 GitLab Self-Managed 인스턴스의 다른 모든 최상위 그룹 전체에 적용할 수 있습니다.

규정 준수 및 보안 정책 최상위 그룹을 사용할 때 규정 준수 프레임워크 및 보안 정책을 관리하고 편집할 수 있는 단일 정보 소스를 갖습니다. 그룹 관리자는 이러한 규정 준수 프레임워크 및 보안 정책을 해당 그룹 내의 모든 프로젝트에 적용할 수 있습니다.

선택한 최상위 규정 준수 및 보안 정책 그룹에서 주요 프레임워크 및 정책을 관리할 때 GitLab Self-Managed 인스턴스 전체의 주요 규정 준수 및 보안 요구 사항을 관리하고 적용하기가 더 쉬워집니다. 그러나 그룹은 해당 그룹에서 발생할 수 있는 특정 상황이나 워크플로우를 해결하기 위해 자신의 규정 준수 프레임워크 및 보안 정책을 생성할 수 있는 능력을 유지합니다.

GitLab.com 및 GitLab Dedicated 고객은 이미 단일 최상위 그룹 또는 네임스페이스 내에서 정책을 중앙에서 관리할 수 있으므로 이 기능은 GitLab Self-Managed 고객을 위한 것입니다.

### 얕은 복제로 더 빠른 워크스페이스 시작 {#faster-workspace-startup-with-shallow-cloning}

<!-- categories: Workspaces -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/workspace/_index.md#shallow-cloning)

{{< /details >}}

워크스페이스는 이제 얕은 복제를 사용하여 시작 시간을 단축합니다. 초기화 중에 GitLab은 전체 Git 히스토리 대신 최신 커밋 히스토리만 다운로드합니다. 워크스페이스가 시작된 후 Git은 얕은 복제를 백그라운드에서 전체 복제로 변환합니다.

이 기능은 모든 새 워크스페이스에 자동으로 적용되며 구성이 필요 없으며 개발 워크플로우에 영향을 주지 않습니다.

### GitLab 관리 OpenTofu 및 Terraform 상태를 위한 새로운 CLI 명령 {#new-cli-commands-for-gitlab-managed-opentofu-and-terraform-states}

<!-- categories: GitLab CLI, Infrastructure as Code -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/infrastructure/iac/terraform_state.md) \| [관련 이슈](https://gitlab.com/gitlab-org/cli/-/issues/7954)

{{< /details >}}

GitLab CLI (`glab`)는 이제 새로운 최상위 명령인 `opentofu`을 포함합니다. `opentofu` 명령은 GitLab 관리 OpenTofu 및 Terraform 상태를 지원하기 위해 `terraform` 및 `tf` 명령에 별칭으로 지정됩니다.

다음 명령이 추가되었습니다:

- `glab opentofu init`: 상태 백엔드를 로컬로 초기화합니다.
- `glab opentofu state list`: 프로젝트의 모든 상태를 나열합니다.
- `glab opentofu state download`: 최신 상태 또는 특정 버전을 다운로드합니다.
- `glab opentofu state delete`: 전체 상태 또는 특정 버전을 삭제합니다.
- `glab opentofu state lock`: 상태를 잠급니다.
- `glab opentofu state unlock`: 상태를 잠금 해제합니다.

`opentofu` 명령을 사용하여 상태를 관리하려면 최소 `glab` 1.66 이상이 있어야 합니다.

### Kubernetes 1.33 지원 {#kubernetes-133-support}

<!-- categories: Deployment Management -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/538906)

{{< /details >}}

GitLab은 이제 Kubernetes 버전 1.33을 완벽하게 지원합니다. 앱을 Kubernetes에 배포하는 경우 연결된 클러스터를 최신 버전으로 업그레이드하고 모든 기능을 활용할 수 있습니다.

자세한 내용은 [GitLab 기능에 대한 지원되는 Kubernetes 버전](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)을 참조하세요.

### OAuth 앱이 SSO 인증을 지원함 {#oauth-apps-support-sso-authentication}

<!-- categories: Pages, System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../api/oauth2.md#authorization-code-flow)

{{< /details >}}

OAuth 애플리케이션은 이제 조직의 단일 로그인 요구사항과 원활하게 통합될 수 있습니다. 이전에는 사용자가 두 번 인증해야 했습니다: 먼저 GitLab으로, 그 다음 SSO로, 불필요한 마찰과 복잡성을 야기했습니다.

이제 OAuth 애플리케이션은 필요할 때 SSO 인증을 자동으로 트리거하도록 권한 부여 요청에 매개변수를 지정할 수 있습니다. 이는 다음을 제공합니다:

- 사용자를 위한 통합 인증 경험
- 조직의 SSO 정책 자동 준수
- 모든 GitLab 통합 간 일관된 보안
- 매개변수 추가만으로 개발자를 위한 간단한 구현

OAuth 통합은 이제 SSO 정책을 자동으로 준수하므로 보안을 유지하면서 혼란스러운 인증 워크플로우를 제거합니다.

### GitLab Pages 사이트에 대한 고유 도메인 기본값 제어 {#control-unique-domains-default-for-gitlab-pages-sites}

<!-- categories: Pages -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../administration/pages/_index.md#disable-unique-domains-by-default)

{{< /details >}}

관리자는 이제 새 GitLab Pages 사이트의 고유 도메인에 대한 기본 동작을 설정할 수 있습니다. 기본적으로 새 Pages 사이트는 고유 도메인 URL(예: `my-project-1a2b3c.example.com`)을 사용하여 사이트 간 쿠키 공유를 방지합니다.

인스턴스에 대한 이 새 설정을 사용하면 새 Pages 사이트가 경로 기반 URL(예: `my-namespace.example.com/my-project`)을 기본적으로 사용하도록 설정할 수 있습니다. 이는 조직이 GitLab Pages 동작을 워크플로우 및 보안 요구사항과 맞추도록 도와줍니다.

사용자는 여전히 개별 프로젝트에 대해 이 설정을 재정의할 수 있으며 기존 Pages 사이트는 영향을 받지 않습니다.

### Wiki 기능 개선 {#enhancements-to-wiki-functionality}

<!-- categories: Wiki -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/discussions/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/16403)

{{< /details >}}

이번 릴리스는 세 가지 주요 개선 사항이 포함된 향상된 wiki 환경을 소개합니다: 이제 wiki 페이지를 구독하고, 페이지를 편집하는 동안 wiki 댓글을 보고, wiki 페이지 댓글을 정렬할 수 있습니다.

이러한 개선 사항은 팀이 문서에 대해 더욱 효과적으로 협력하도록 다음을 제공합니다:

- 컨텍스트에서 직접 콘텐츠를 논의합니다.
- 개선 사항 및 수정 제안을 합니다.
- 문서를 정확하고 최신 상태로 유지합니다.
- 지식과 전문성을 공유합니다.

이러한 업데이트를 통해 GitLab wiki는 직접 피드백과 논의를 통해 프로젝트와 함께 발전하는 살아있는 문서가 됩니다.

### 에픽 담당자, 마일스톤 등을 일괄 편집 {#bulk-edit-epic-assignees-milestones-and-more}

<!-- categories: Portfolio Management -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/group/epics/manage_epics.md#bulk-edit-epics) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11901)

{{< /details >}}

이제 그룹에서 더 많은 에픽 속성을 일괄 편집할 수 있습니다. 레이블 외에도 이제 여러 에픽에 대한 담당자, 건강 상태, 구독, 기밀성, 마일스톤을 한 번에 업데이트할 수 있습니다.

이 개선 사항을 통해 여러 에픽에 동일한 변경 사항을 동시에 적용하여 많은 수의 에픽을 관리하는 것이 더 빨라집니다.

### API를 통해 파이프라인 실행 정책에 CI/CD 구성 액세스 권한 부여 {#grant-pipeline-execution-policies-access-to-cicd-configurations-via-api}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../api/projects.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/524124)

{{< /details >}}

Projects REST API를 사용하여 새 `spp_repository_pipeline_access` 필드를 사용하여 보안 정책 프로젝트에서 **파이프라인 실행 정책** 설정을 프로그래밍 방식으로 활성화 또는 비활성화합니다. 이전에는 이 설정을 GitLab UI를 통해서만 관리할 수 있었습니다. 이 개선 사항을 통해 이제 다음을 수행할 수 있습니다:

- 현재 **파이프라인 실행 정책** 상태를 `GET`합니다.
- 설정을 프로그래밍 방식으로 활성화 또는 비활성화하려면 `PUT`합니다.

이 개선 사항은 팀이 규모에 따라 보안 정책을 관리하는 더 나은 자동화 및 통합 워크플로우를 활성화합니다.

### 취약성 보고서에서 OWASP 2021별로 그룹화 {#group-by-owasp-2021-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [문서](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

프로젝트 및 그룹의 취약성 보고서에서 이제 을 OWASP Top 10 2021 범주별로 그룹화할 수 있습니다. GitLab.com 및 GitLab Dedicated 인스턴스에만 사용 가능합니다.

### 검사 실행 정책 템플릿 {#scan-execution-policy-templates}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/policies/scan_execution_policies.md#scan-execution-policy-editor) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/11919)

{{< /details >}}

검사 실행 정책 템플릿은 일반적인 사용 사례를 기반으로 을 빠르게 생성하는 데 도움이 됩니다. 세 가지 템플릿 중에서 선택합니다:

- 머지 리퀘스트 보안
- 예약된 검사
- 릴리스 보안

템플릿을 선택하면 템플릿에서 활성화할 GitLab 보안 검사를 선택하여 즉시 시작할 수 있습니다. 더 고급 사용 사례가 있는 경우 사용자 지정 구성으로 전환하여 특정 브랜치, 패턴, 파이프라인 소스 등으로 정책을 확장할 수 있습니다.

### 보안 정책 감사 이벤트 {#security-policy-audit-events}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/compliance/audit_event_streaming.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/15869)

{{< /details >}}

GitLab Ultimate는 이제 각 보안 정책 프로젝트 내에서 정리되고 중앙 집중식 보안 정책 관리를 위한 종합적인 감사 이벤트를 제공합니다.

보안 팀은 이제 다음을 수행할 수 있습니다:

- 상세한 메타데이터를 사용하여 모든 정책 수정을 추적합니다.
- 검사 및 파이프라인 실행 실패를 포함한 적용 실패를 모니터링합니다.
- 건너뛴 실행 및 파이프라인 실행 파이프라인을 모니터링합니다.
- 정책 위반으로 병합된 를 포함하여 각 프로젝트 내의 정책 위반을 감지합니다.
- 제한을 초과할 때 경고를 받습니다.
- 정책 구성 오류를 감지합니다.
- 대용량 시나리오에 대해 스트리밍 전용 옵션을 사용합니다.

새 감사 이벤트는 다음을 포함합니다:

- [security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_create.yml).yml)
- [security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_delete.yml).yml)
- [security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_update.yml).yml)
- [security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_merge_request_merged_with_policy_violations.yml).yml)
- [security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml).yml)
- [security_policies_limit_exceeded](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml)
- [security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_violations_detected.yml).yml) (스트리밍 전용)
- [security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_failed.yml).yml) (스트리밍 전용)
- [security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_skipped.yml).yml) (스트리밍 전용)
- [merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/[merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/merge_request_branch_bypassed_by_security_policy.yml).yml)

이 개선 사항은 정책 변경, 구성 오류, 적용 간격에 액세스할 수 있도록 하여 보안 태세를 강화하므로 더 빠른 사건 대응 및 철저한 감사 기능이 가능합니다.

### 서비스 계정 및 액세스 토큰 승인 정책 예외 {#service-account-and-access-token-exceptions-for-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [설명서](../../user/application_security/policies/merge_request_approval_policies.md#access-token-and-service-account-exceptions) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/18112)

{{< /details >}}

새 **Service Account & Access Token Exceptions** 기능을 통해 필요할 때 머지 리퀘스트 승인 정책을 우회할 수 있는 서비스 계정 및 액세스 토큰을 지정할 수 있습니다. 이는 알려진 자동화에 대한 마찰을 제거하면서 보안 제어를 보존합니다.

**주요 기능은 다음을 포함합니다:**

- 자동화된 워크플로우 지원: CI/CD 파이프라인, 끌어오기 미러링, 자동화된 버전 업데이트에 대한 승인 요구사항을 무시하도록 특정 서비스 계정, 봇 사용자, 그룹 액세스 토큰, 프로젝트 액세스 토큰을 구성합니다. 서비스 계정은 승인된 토큰을 사용하여 보호된 브랜치에 직접 푸시할 수 있으므로 사용자 제한을 유지하면서도 가능합니다.
- 응급 액세스 및 감사: 종합적인 감사 추적으로 중요 사건에 대한 break-glass 시나리오를 활성화합니다. 모든 우회 이벤트는 컨텍스트 및 추론을 포함한 상세 감사 로그를 생성하므로 중단 또는 보안 수정 중 신속한 대응을 허용하면서 규정 준수 요구사항을 지원합니다.
- GitOps 통합: 리포지토리 미러링, 외부 CI 시스템 (Jenkins, CloudBees), 자동화된 변경 로그 생성, GitFlow 릴리스 프로세스를 포함한 일반적인 자동화 과제를 차단 해제합니다. 서비스 계정은 특정 프로젝트 및 브랜치에 범위가 지정된 토큰 기반 액세스를 사용하여 필요한 최소 권한을 받습니다.

이 개선 사항은 엄격한 보안 정책을 유지하면서 최신 DevOps 자동화 요구 사항에 유연성을 제공하므로 사용자 지정 해결 방법을 제거하면서 거버넌스 제어를 보존합니다.

### SAML SSO 세션 시간 초과 속성 지원 {#saml-sso-support-for-session-timeout-attribute}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/group/saml_sso/_index.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/262074)

{{< /details >}}

GitLab은 이제 Identity Provider (IdP)의 SAML assertion에서 `SessionNotOnOrAfter` 속성을 자동으로 감지하고 존중합니다. 이 속성이 있으면 GitLab은 IdP에 의해 지정된 시간에 만료되도록 사용자 세션을 설정하여 조직 전체에서 일관된 세션 관리를 보장합니다. 이 기능은 구성 변경이 필요하지 않습니다 - IdP에서 속성을 제공하면 GitLab은 지정된 만료 시간을 자동으로 준수합니다.

### 추가 서비스 계정 이메일 구성 옵션 {#additional-service-account-email-configuration-options}

<!-- categories: System Access -->

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/profile/service_accounts.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/537976)

{{< /details >}}

기본적으로 GitLab은 새 서비스 계정에 대해 이메일 주소를 자동으로 생성합니다. 조직은 이제 UI를 통해 서비스 계정에 대한 사용자 정의 이메일 주소를 할당할 수 있습니다. 이전에는 서비스 계정 API를 통해서만 사용자 정의 이메일 구성이 가능했습니다. 이 변경으로 조직이 지정된 이메일 주소로 알림을 더 잘 라우팅할 수 있습니다.

### 엔터프라이즈 사용자 개선 사항 {#enterprise-user-enhancements}

<!-- categories: System Access -->

{{< details >}}

- 티어: Silver, Gold
- 제공 서비스: GitLab.com
- 링크: [설명서](../../user/enterprise_user/_index.md) \| [관련 에픽](https://gitlab.com/groups/gitlab-org/-/epics/9262)

{{< /details >}}

GitLab 18.3은 조직이 사용자 개인정보 보호 및 수명 주기 관리에 대한 더 많은 제어를 할 수 있도록 하는 엔터프라이즈 사용자 개선 사항을 도입합니다.

그룹 소유자는 이제 Users API를 사용하여 네임스페이스의 엔터프라이즈 사용자를 삭제할 수 있습니다. 이 파괴적인 작업은 사용자 기여를 연결 해제하고 시스템 전체 Ghost 사용자와 연결합니다. 이 옵션은 자동화된 SCIM 가져오기로 인해 잘못 생성된 사용자를 정리하거나 사용자 이름 및 이메일을 다시 사용해야 하는 페더레이션 환경을 관리하는 데 특히 유용합니다.

또한 조직은 이제 사용자 프로필에서 엔터프라이즈 사용자 이메일을 숨길 수 있어 모든 엔터프라이즈 사용자에 대한 더 광범위한 이메일 개인정보 보호 적용을 제공합니다.

### SSH 키 보안 경고 {#ssh-key-security-warnings}

<!-- categories: System Access -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 링크: [문서](../../user/ssh.md) \| [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/432624)

{{< /details >}}

GitLab은 이제 사용자가 약한 SSH 키를 업로드할 때 UI에 보안 경고를 표시합니다. 이 경고는 오래된 키 유형 또는 충분하지 않은 비트 길이(2048비트 미만)의 키에 나타납니다. 이 변경은 사용자에게 SSH 키 보안 모범 사례를 교육하고 더 강력한 암호화 키 사용을 권장합니다.

### GitLab Runner 18.3 {#gitlab-runner-183}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Dedicated
- 링크: [설명서](https://docs.gitlab.com/runner)

{{< /details >}}

오늘 GitLab Runner 18.3도 릴리스합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

#### 버그 수정 {#bug-fixes}

- [GitLab 18.2.0에서 러너는 캐시 키로 하위 디렉토리 파일을 사용하여 작업 캐시를 끌어올 수 없습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/556464)
- [Docker 실행기가 작업을 간헐적으로 시작하지 못하고 `incorrect username or password` 오류 메시지를 반환합니다.](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38707)
- [`*_get_sources` hook 사용의 `none` 및 `empty` Git 전략 간 불일치](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38703)
- [비 OLM 매니페스트를 사용하여 배포된 Operator가 잘못된 기본 이미지를 가정합니다](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/228)
- [CR에 `app.kubernetes.io/instance` 레이블이 있는 경우 Operator가 잘못된 이름으로 ConfigMap을 생성합니다](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/183)
- [OpenShift 4.9의 Operator 1.10.0이 `gitlab-runner` 네임스페이스에서 러너 ConfigMap을 생성하고 pod를 시작하지 못합니다](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/138)

#### 새로운 기능 {#whats-new}

- [GitLab Runner Operator는 이제 러너 관리자 pod 주석을 지원합니다](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/245)
- [GitLab Runner Operator는 이제 OpenShift 4.19를 지원합니다](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/253)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/CHANGELOG.md).md)에 있습니다.

## 관련 항목 {#related-topics}

- [버그 수정](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [성능 개선](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [UI 개선](https://papercuts.gitlab.com/?milestone=18.3)
- [더 이상 사용되지 않는 항목 및 제거](../../update/deprecations.md)
- [업그레이드 정보](../../update/versions/_index.md)
