---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "GitLab Duo Workflow를 사용하여 Java 코딩 스타일 가이드라인을 프로젝트에 자동으로 적용하는 방법을 설명하는 가이드입니다. 구성, 실행 및 샘플 사용 사례가 포함되어 있습니다."
title: "Duo Workflow 사용 사례: 코딩 스타일 적용"
---

{{< details >}}

- 티어: Ultimate과 GitLab Duo Workflow
- 제공 서비스: GitLab.com
- 상태:  실험적 기능

{{< /details >}}

## 시작하기 {#getting-started}

### 솔루션 구성 요소 다운로드 {#download-the-solution-component}

1. 계정 팀에서 초대 코드를 받습니다.
1. 초대 코드를 사용하여 [솔루션 구성 요소 웹스토어](https://cloud.gitlab-accelerator-marketplace.com)에서 솔루션 구성 요소를 다운로드합니다.

## Duo Workflow 사용 사례: 스타일 가이드를 사용하여 Java 애플리케이션 개선 {#duo-workflow-use-case-improve-java-application-with-style-guide}

이 문서는 프롬프트와 컨텍스트 라이브러리가 포함된 GitLab Duo Workflow 솔루션을 설명합니다. 이 솔루션의 목적은 정의된 스타일을 기반으로 애플리케이션 코딩을 개선하는 것입니다.

이 솔루션은 GitLab 이슈를 프롬프트로 제공하고 스타일 가이드를 컨텍스트로 사용하여 GitLab Duo Workflow를 사용하여 코드베이스에 Java 스타일 가이드라인을 자동화하도록 설계되었습니다. 프롬프트와 컨텍스트 라이브러리를 통해 Duo Workflow는 다음을 수행할 수 있습니다:

1. GitLab 리포지토리에 저장된 중앙 집중식 스타일 가이드 콘텐츠에 액세스합니다.
1. 도메인별 코딩 표준을 이해하고
1. 기능을 유지하면서 Java 코드에 일관된 형식을 적용합니다.

GitLab Duo Workflow에 대한 자세한 정보는 [여기 문서](../../../user/duo_agent_platform/_index.md)를 검토하세요.

### 주요 이점 {#key-benefits}

- **Enforces consistent style**
- **Automates style application**
- **Maintains code functionality** 및 가독성 향상
- **Integrates with GitLab for VS Code** 원활한 구현
- **Reduces code review time** 스타일 문제 해결에 소비되는 시간
- **Serves as a learning tool**

### 샘플 결과 {#sample-result}

올바르게 구성되면 프롬프트가 코드를 엔터프라이즈 표준과 일치하도록 변환하며, 이 diff에 표시된 변환과 유사합니다:

![지침, 작업 분석 및 해결 단계를 표시하는 Duo Workflow 보기](img/duoworkflow-style_output_v17_10.png)

![Duo Workflow에 의한 스타일 가이드 변환 후 일관된 형식을 가진 업데이트된 코드 스니펫](img/duoworkflow_style_code_transform_v17_10.png)

## 솔루션 프롬프트 및 컨텍스트 라이브러리 구성 {#configure-the-solution-prompt-and-context-library}

### 기본 설정 {#basic-setup}

에이전트 워크플로우를 실행하여 애플리케이션에 스타일을 검토 및 적용하려면 이 사용 사례 프롬프트와 컨텍스트 라이브러리를 설정해야 합니다.

1. **Set up the prompt and context library** `Enterprise Code Quality Standards` 에이전트 프로젝트를 복제하여
1. **Create a GitLab issue** `Review and Apply Style` 라이브러리 파일 `.gitlab/workflows/java-style-workflow.md`의 프롬프트 콘텐츠 포함
1. **이슈** `Review and Apply Style` [구성 섹션](#configuration-guide)에서 자세히 설명한 대로 워크플로우 변수 구성
1. **In your VS code** 프로젝트 `Enterprise Code Quality Standards`를 사용하여 간단한 [워크플로우 프롬프트](#example-duo-workflow-prompt)로 Duo Workflow를 시작합니다.
1. **Work with the Duo Workflow** 제안된 계획 및 자동화된 작업을 검토하고 필요한 경우 워크플로우에 추가 입력을 추가합니다.
1. **Review and commit** 리포지토리에

### Duo Workflow 프롬프트 예제 {#example-duo-workflow-prompt}

```yaml
Follow the instructions in issue <issue_reference_id> for the file <path/file_name.java>. Make sure to access any issues or GitLab projects mentioned in the issue to retrieve all necessary information.
```

이 간단한 프롬프트는 Duo Workflow에 다음을 지시하기 때문에 강력합니다:

1. 특정 이슈 ID의 자세한 요구사항을 읽습니다.
1. 참조된 스타일 가이드 리포지토리에 액세스합니다.
1. 가이드라인을 지정된 파일에 적용합니다.
1. 이슈의 모든 지침을 따릅니다.

## 구성 가이드 {#configuration-guide}

프롬프트는 솔루션 패키지의 `.gitlab/workflows/java-style-workflow.md` 파일에 정의됩니다. 이 파일은 워크플로우 에이전트에 계획을 작성하도록 지시하는 GitLab 이슈를 만들기 위한 템플릿으로 제공되어 애플리케이션의 스타일 가이드 검토를 자동화하고 변경 사항을 적용합니다.

`.gitlab/workflows/java-style-workflow.md`의 첫 번째 섹션에서 프롬프트에 대해 구성해야 할 변수를 정의합니다.

### 변수 정의 {#variable-definition}

변수는 `.gitlab/workflows/java-style-workflow.md` 파일에 직접 정의됩니다. 이 파일은 AI 어시스턴트에 지시하는 GitLab 이슈를 만들기 위한 템플릿으로 제공됩니다. 새 콘텐츠로 이슈를 생성하기 전에 이 파일의 변수를 수정합니다.

#### 1\. 컨텍스트로서의 스타일 가이드 리포지토리 {#1-style-guide-repository-as-the-context}

프롬프트는 조직의 스타일 가이드 리포지토리를 가리키도록 구성해야 합니다. `java-style-prompt.md` 파일에서 다음 변수를 바꿉니다:

- `{{GITLAB_INSTANCE}}`: GitLab 인스턴스 URL (예: `https://gitlab.example.com`)
- `{{STYLE_GUIDE_PROJECT_ID}}`: Java 스타일 가이드가 포함된 GitLab 프로젝트 ID
- `{{STYLE_GUIDE_PROJECT_NAME}}`: 스타일 가이드 프로젝트의 표시 이름
- `{{STYLE_GUIDE_BRANCH}}`: 최신 스타일 가이드를 포함하는 브랜치 (기본값: main)
- `{{STYLE_GUIDE_PATH}}`: 리포지토리 내 스타일 가이드 문서의 경로

예제:

```yaml
GITLAB_INSTANCE=https://gitlab.example.com
STYLE_GUIDE_PROJECT_ID=gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards
STYLE_GUIDE_PROJECT_NAME=Enterprise Java Standards
STYLE_GUIDE_BRANCH=main
STYLE_GUIDE_PATH=coding-style/java/guidelines/java-coding-standards.md
```

#### 2\. 스타일 개선을 적용할 대상 리포지토리 {#2-target-repository-to-apply-style-improvement}

동일한 `java-style-prompt.md` 파일에서 스타일 가이드를 적용할 파일을 구성합니다:

- `{{TARGET_PROJECT_ID}}`: Java 프로젝트의 GitLab ID
- `{{TARGET_FILES}}`: 대상으로 지정할 특정 파일 또는 패턴 (예: "src/main/java/\*\*/\*.java")

예제:

```yaml
TARGET_PROJECT_ID=royal-reserve-bank
TARGET_FILES=asset-management-api/src/main/java/com/royal/reserve/bank/asset/management/api/service/AssetManagementService.java
```

### AI-생성 코드에 대한 중요 참고사항 {#important-notes-about-ai-generated-code}

**⚠️ Important Disclaimer**:

GitLab for VS Code는 비결정적인 Agentic AI를 사용합니다. 즉:

- 동일한 입력이어도 실행 간에 결과가 달라질 수 있습니다.
- AI 어시스턴트의 스타일 가이드라인에 대한 이해 및 적용이 매번 약간씩 다를 수 있습니다.
- 이 문서에서 제공되는 예제는 설명용이며 실제 결과는 다를 수 있습니다.

**Best Practices for Working with AI-Generated Code Changes**:

1. **Always review generated code**: 철저한 인간의 검토 없이 AI-생성 변경 사항을 병합하지 않습니다.
1. **Follow proper merge request processes**: 표준 코드 검토 절차를 사용합니다.
1. **Run all tests**: 병합하기 전에 모든 단위 및 통합 테스트를 통과하는지 확인합니다.
1. **Verify style compliance**: 변경 사항이 스타일 가이드 예상과 일치하는지 확인합니다.
1. **Incremental application**: 처음에는 더 작은 파일 집합에 스타일 변경을 적용하는 것을 고려합니다.

이 도구는 코드 검토 프로세스에서 인간의 판단을 대체하지 않고 개발자를 지원하기 위한 것입니다.

## 단계별 구현 {#step-by-step-implementation}

1. **Create a Style Guide Issue**

   - 프로젝트에서 새 이슈를 생성합니다 (예: 이슈 #3)
   - 적용할 스타일 가이드라인에 대한 자세한 정보를 포함합니다.
   - 해당하는 경우 외부 스타일 가이드 리포지토리를 참조합니다.
   - 다음과 같은 요구사항을 지정합니다:

     ```yaml
     Task: Code Style Update
     Description: Apply the enterprise standard Java style guidelines to the codebase.
     Reference Style Guide: Enterprise Java Style Guidelines (https://gitlab.com/gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards/-/blob/main/coding-style/java/guidelines/java-coding-standards.md)
     Constraints:
     - Adhere to Enterprise Standard Java Style Guide
     - Maintain Functionality
     - Implement automated style checks
     ```

1. **Configure the Prompt**

   - `java-style-prompt.md`에서 템플릿을 복사합니다.
   - 모든 구성 변수를 작성합니다.
   - 프로젝트별 예외 또는 요구사항을 추가합니다.

1. **Execute via GitLab for VS Code**

   - 구성된 프롬프트를 Duo Workflow에 제출합니다.
   - Duo Workflow는 샘플 워크플로우 실행에서 볼 수 있는 다단계 프로세스를 실행합니다:

     - 특정 도구를 사용하여 작업 계획 (`run_read_only_git_command`, `read_file`, `find_files`, `edit_file`)
     - 참조된 이슈에 액세스합니다.
     - 엔터프라이즈 Java 스타일 가이드를 검색합니다.
     - 현재 코드 구조를 분석합니다.
     - 지정된 파일에 스타일 가이드라인을 적용합니다.
     - 변경 사항이 기능을 유지하는지 확인합니다.
     - 변경 사항의 상세 보고서를 제공합니다.

1. **Review and Implement**

   - 제안된 변경 사항을 검토합니다.
   - 코드베이스에 변경 사항을 구현합니다.
   - 테스트를 실행하여 기능이 유지되는지 확인합니다.
   - GitLab for VS Code 인터페이스를 통해 작업 진행 상황을 모니터링합니다.

## 샘플 워크플로우 실행 {#sample-workflow-execution}

올바르게 구성되면 GitLab for VS Code 확장은 스타일 가이드라인을 적용하기 위한 상세한 계획을 실행합니다. 워크플로우 실행의 샘플은 다음과 같습니다:

### 샘플 워크플로우 계획 {#sample-workflow-plan}

AI 어시스턴트는 먼저 특정 도구를 사용하여 실행 계획을 만듭니다:

1. Enterprise Java Standards 프로젝트에서 콘텐츠를 검색하여 `https://gitlab.com/gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards.git`의 파일 `coding-style/java/guidelines/java-coding-standards.md`에 대해 `run_read_only_git_command`를 사용하여 Java 스타일 가이드라인에 액세스하고, 다음이 지원합니다: `run_read_only_git_command`
1. `AssetManagementService.java`의 현재 콘텐츠를 `read_file` 도구를 사용하여 읽고 분석하여 구조를 이해하고 스타일 업데이트가 필요한 영역을 파악하고, `read_file`이 지원합니다.
1. find_files를 사용하여 프로젝트의 유사한 파일을 검색하여 관련 서비스 클래스 전체에서 일관된 스타일 적용을 보장하고, `find_files`이 지원합니다.
1. edit_file 도구를 사용하여 AssetManagementService.java를 편집하여 스타일 가이드라인을 적용합니다. 다음에 초점을 맞춥니다:

   - 패키지 및 import 구성
   - 클래스 및 메서드 문서
   - 코드 들여쓰기 및 간격
   - 주석 배치
   - 메서드 매개 변수 형식, `edit_file`이 지원합니다.

1. 모든 Lombok 주석 (@Service, @RequiredArgsConstructor, @Slf4j)이 grep_files를 사용하여 스타일 가이드에 따라 적절하게 형식화되었는지 확인하여 코드베이스 전체의 주석 패턴을 확인하고, `grep_files`이 지원합니다.

### 샘플 분석 출력 {#sample-analysis-output}

어시스턴트는 파일 및 요구사항을 분석합니다:

이슈 #3과 `AssetManagementService.java` 파일을 분석했습니다. 찾은 내용은 다음과 같습니다:

1. 이슈 #3은 Royal Banking 코드베이스에 엔터프라이즈 표준 Java 스타일 가이드라인을 적용하는 것입니다.
1. `AssetManagementService.java` 파일은 `asset-management-api` 모듈에 위치합니다.
1. 스타일 가이드라인은 `gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards`의 별도 GitLab 프로젝트에 저장됩니다.
1. 현재 `AssetManagementService.java` 파일에는 다음이 포함됩니다:

   1. 패키지 및 import 문
   1. Spring 주석이 있는 서비스 클래스
   1. 자산 가용성을 확인하는 하나의 공개 메서드
   1. Lombok 주석
   1. Javadoc 주석

이슈는 다음을 요구합니다:

1. 엔터프라이즈 표준 Java 스타일 가이드라인에 따른 형식
1. 자동화된 스타일 체크 구현
1. 기존 기능 유지
1. 스타일 업데이트 후 모든 테스트 통과 확인

구현을 진행하려면 다음이 필요합니다:

1. Enterprise Java Standards 프로젝트에서 Java 스타일 가이드라인 액세스
1. AssetManagementService.java에 스타일 가이드라인 적용
1. 변경 사항이 기능에 영향을 주지 않는지 확인
1. 업데이트 후 모든 테스트 통과 확인

### 샘플 구현 결과 {#sample-implementation-result}

실행 후 어시스턴트는 변경 사항의 설명과 함께 변환된 코드를 제공합니다:

1. 적용된 스타일 가이드라인 요약
1. 적절하게 형식화된 변환된 코드
1. 주요 스타일 변경에 대한 설명
1. 자동화된 스타일 강제 실행에 대한 권장사항

변경 사항에는 일반적으로 다음이 포함됩니다:

- 표준화된 import 순서
- 연산자 주변의 일관된 간격
- 적절한 Javadoc 형식
- 표준화된 메서드 매개 변수 정렬
- 일관된 중괄호 배치

모두 코드가 원래 기능을 유지하도록 보장합니다.

## 샘플 자습서 사용 사례: Royal Reserve Bank Java 프로젝트 {#sample-tutorial-use-case-royal-reserve-bank-java-project}

이 리포지토리에는 실제 시나리오에서 스타일 가이드 적용의 작동 방식을 보여주는 뱅킹 자습서 예제가 포함되어 있습니다. Royal Reserve Bank 프로젝트는 여러 Java 서비스가 있는 마이크로서비스 아키텍처를 따릅니다:

- 계정 API
- 자산 관리 API
- 거래 API
- 알림 API
- API 게이트웨이
- 구성 서버
- 발견 서버

샘플 예제는 `AssetManagementService.java` 클래스에 엔터프라이즈 스타일 가이드라인을 적용하여 다음에 대한 적절한 형식을 보여줍니다:

1. Import 구성
1. Javadoc 표준
1. 메서드 매개 변수 정렬
1. 변수 명명 규칙
1. 예외 처리 패턴

## 조직에 맞게 사용자 정의 {#customizing-for-your-organization}

조직의 요구사항에 맞게 이 프롬프트를 조정하려면:

1. **Style Guide Replacement**

   - 조직의 스타일 가이드 리포지토리를 가리킵니다.
   - 특정 스타일 가이드 문서를 참조합니다.

1. **Target File Selection**

   - 스타일 가이드를 적용할 특정 파일 또는 패턴을 선택합니다.
   - 초기 구현을 위해 높은 가시성의 코드 파일을 우선 순위를 지정합니다.

1. **Additional Validation**

   - 사용자 정의 검증 요구사항을 추가합니다.
   - 표준 스타일 규칙의 예외를 지정합니다.

1. **Integration with CI/CD**

   - CI/CD 파이프라인의 일부로 실행되도록 프롬프트를 구성합니다.
   - 지속적인 준수를 보장하기 위해 자동화된 스타일 체크를 설정합니다.

## 문제 해결 {#troubleshooting}

일반적인 문제 및 해결 방법:

- **접근이 거부되었습니다**: AI 에이전트가 두 리포지토리 모두에 액세스할 수 있는 적절한 권한을 가지고 있는지 확인합니다.
- **Missing Style Guide**: 스타일 가이드 경로 및 브랜치가 정확한지 확인합니다.
- **Functionality Changes**: 스타일 변경을 적용한 후 모든 테스트를 실행하여 기능을 확인합니다.

## 기여 {#contributing}

다음을 수행하여 이 프롬프트를 향상시킬 수 있습니다:

- 더 많은 스타일 규칙 설명 추가
- 다양한 Java 프로젝트 유형에 대한 예제 생성
- 검증 워크플로우 개선
- 추가 정적 분석 도구와의 통합 추가
