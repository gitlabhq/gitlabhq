---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 머지 리퀘스트 검토에서 AI가 사용할 지침을 사용자 지정합니다.
title: Agent Platform의 검토 지침 맞춤설정
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/545136)된 GitLab 18.2에서 [베타](../../../policy/development_stages_support.md#beta) [기능 플래그](../../../administration/feature_flags/_index.md)로 `duo_code_review_custom_instructions` 이름으로 제공되었습니다. 기본적으로 비활성화되었습니다.
- 기능 플래그 `duo_code_review_custom_instructions`가 GitLab 18.3에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199802).
- 기능 플래그 `duo_code_review_custom_instructions`가 GitLab 18.4에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202262).
- 통합 패턴(예: `{rb,ts}`)이 `fileFilters`에 GitLab 19.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237952)되었습니다.

{{< /history >}}

머지 리퀘스트를 검토할 때 참조할 수 있는 표준을 제공하기 위한 사용자 정의 검토 지침을 만듭니다.

예를 들어 GitLab Duo가 Ruby 파일에 대한 Ruby 스타일 규칙에 집중하고 Go 파일에 대한 Go 스타일 규칙에 집중하도록 안내할 수 있습니다.

> [!note]
> 사용자 정의 검토 지침은 AI 검토자를 위한 지침이며 강제되는 정책이 아닙니다. GitLab Duo는 이 지침을 검토의 컨텍스트로 사용하지만 모든 지침이 모든 경우에 적용된다고 보장할 수 없습니다. 보안 제어, 규정 준수 의무 또는 일관된 강제 실행이 필요한 다른 요구 사항에는 사용자 정의 지침을 의존하지 마세요.

GitLab Duo는 사용자 지정 검토 지침을 표준 검토 기준에 대체하는 대신 추가합니다.

Code Review 플로우는 프로젝트, 그룹 또는 인스턴스에 대한 사용자 정의 검토 지침을 지원합니다.

## 프로젝트의 사용자 지정 검토 지침 구성 {#configure-custom-review-instructions-for-a-project}

사용자 지정 머지 리퀘스트 검토 지침을 구성하려면:

1. 리포지토리의 루트에 `.gitlab/duo` 디렉터리가 없으면 생성합니다.
1. `.gitlab/duo` 디렉터리에서 `mr-review-instructions.yaml` 파일을 생성합니다.
1. 다음 형식을 사용하여 사용자 지정 지침을 추가합니다.

   ```yaml
   instructions:
     - name: <instruction_group_name>
       fileFilters:
         - <glob_pattern_1>
         - <glob_pattern_2>
         - !<exclude_pattern>  # Exclude files matching this pattern
       instructions: |
         <your_custom_review_instructions>
   ```

   `fileFilters` 섹션은 선택적입니다. 이 섹션의 글로브 패턴을 사용하여 지침을 특정 파일로 지정합니다. `fileFilters`를 생략하거나 비워두면 GitLab Duo는 머지 리퀘스트의 모든 파일에 지침을 적용합니다.

   예를 들어:

   ```yaml
   instructions:
     - name: Ruby Style Guide
       fileFilters:
         - "*.rb"           # Ruby files in the root directory
         - "lib/**/*.rb"    # Ruby files in lib and its subdirectories
         - "!spec/**/*.rb"  # Exclude test files
       instructions: |
         1. Ensure all methods have proper documentation
         2. Follow Ruby style guide conventions
         3. Prefer symbols over strings for hash keys

     - name: TypeScript Source Files
       fileFilters:
         - "**/*.ts"        # Typescript files in any directory
         - "!**/*.test.ts"  # Exclude test files
         - "!**/*.spec.ts"  # Exclude spec files
       instructions: |
         1. Ensure proper TypeScript types (avoid 'any')
         2. Follow naming conventions
         3. Document complex functions

     - name: All Files Except Tests
       fileFilters:
         - "!**/*.test.*"   # Exclude all test files
         - "!**/*.spec.*"   # Exclude all spec files
         - "!test/**/*"     # Exclude test directories
         - "!spec/**/*"     # Exclude spec directories
       instructions: |
         1. Follow consistent code style
         2. Add meaningful comments for complex logic
         3. Ensure proper error handling

     - name: Test Coverage
       fileFilters:
         - "spec/**/*_spec.rb" # Ruby test files in spec directory
       instructions: |
         1. Test both happy paths and edge cases
         2. Include error scenarios
         3. Use shared examples to reduce duplication

     - name: Database Migrations
       fileFilters:
         - "db/migrate/**/*.rb"
         - "db/post_migrate/**/*.rb"
       instructions: |
         1. Follow the migration safety guidelines in
            https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/database/avoiding_downtime_in_migrations.md
         2. Apply the team checklist in docs/migrations-checklist.md

     - name: All Files
       fileFilters:
         - "**/*"   # All files in the repository
       instructions: |
         1. Explain the "why" behind each suggestion
   ```

   지침의 파일 참조에 대한 자세한 내용은 [지침의 파일 참조](#reference-files-in-instructions)를 참조하세요.

   glob 구문 예제는 [파일 패턴 참조](#file-pattern-reference)를 확인하세요.

1. 선택 사항:  [Code Owner](../../project/codeowners/_index.md) 항목을 추가하여 `mr-review-instructions.yaml` 파일의 변경 사항을 보호합니다.

   ```markdown
   [GitLab Duo]
   .gitlab/duo @default-owner @tech-lead
   ```

1. [머지 리퀘스트를 생성](../../project/merge_requests/creating_merge_requests.md)하여 변경 사항을 검토하고 병합합니다.

   - GitLab Duo는 파일 패턴이 일치할 때 사용자 지정 지침을 자동으로 적용합니다.
   - 여러 지침 그룹을 단일 파일에 적용할 수 있습니다. 파일이 두 개 이상 그룹의 `fileFilters`와 일치하면 Code Review 플로우는 일치하는 모든 그룹의 지침을 적용합니다.
   - 사용자 지정 지침에 의해 트리거된 검토 의견의 경우 GitLab Duo는 다음 형식을 사용합니다.

     ```plaintext
     According to custom instructions in '[instruction_name]': [feedback comments]
     ```

     `instruction_name` 값은 `.gitlab/duo/mr-review-instructions.yaml` 파일의 `name` 속성에 해당합니다. 표준 GitLab Duo 의견은 이 형식을 사용하지 않습니다.
     <br><br>
     GitLab Duo가 이슈를 찾지 못하면 검토 요약 의견을 남깁니다. 사용자 지정 지침은 이 요약 의견에 적용되지 않습니다.
1. 선택 사항: 
   - 피드백을 검토하고 필요에 따라 지침을 개선합니다.
   - 패턴을 테스트하여 의도한 파일과 일치하는지 확인합니다.

## 그룹의 사용자 지정 검토 지침 구성 {#configure-custom-review-instructions-for-a-group}

{{< history >}}

- GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230090)되었습니다.

{{< /history >}}

템플릿으로 사용할 프로젝트를 지정하여 그룹의 사용자 지정 검토 지침을 정의할 수 있습니다. 템플릿 프로젝트에는 그룹 및 서브그룹의 모든 프로젝트에 적용되는 검토 지침이 포함된 `.gitlab/duo/mr-review-instructions.yaml` 파일이 있어야 합니다.

GitLab Duo가 코드 검토를 수행할 때, 최상위 그룹의 지침과 개별 프로젝트에 정의된 지침을 결합합니다.

전제 조건:

- 최상위 그룹의 Owner 역할.
- 그룹 내 프로젝트에 템플릿으로 사용하려는 사용자 지정 검토 지침이 포함되어 있어야 합니다.

그룹의 사용자 지정 검토 지침을 구성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반** > **GitLab Duo 기능**을 선택하세요.
1. **Customize code review** 아래에서 그룹의 검토 지침이 있는 `.gitlab/duo/mr-review-instructions.yaml` 파일을 포함하는 프로젝트를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 인스턴스에 대한 사용자 정의 검토 지침 구성 {#configure-custom-review-instructions-for-an-instance}

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237573)되었습니다.

{{< /history >}}

GitLab Self-Managed 및 GitLab Dedicated에서 템플릿으로 사용할 프로젝트를 지정하여 인스턴스 전체 사용자 정의 검토 지침을 정의할 수 있습니다. 템플릿 프로젝트는 인스턴스의 모든 프로젝트에 적용되는 검토 지침이 있는 `.gitlab/duo/mr-review-instructions.yaml` 파일을 포함해야 합니다.

GitLab Duo가 코드를 검토할 때 인스턴스 지침을 그룹 및 프로젝트 지침과 결합합니다.

전제 조건:

- 인스턴스의 관리자 액세스 권한
- 인스턴스의 프로젝트에는 템플릿으로 사용할 사용자 정의 검토 지침이 포함되어 있습니다.

인스턴스에 대한 사용자 정의 검토 지침을 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **Customize code review for all groups in this instance** 아래에서 검토 지침이 있는 `.gitlab/duo/mr-review-instructions.yaml` 파일을 포함하는 프로젝트를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 지침의 파일 참조 {#reference-files-in-instructions}

내용을 복제하는 대신 사용자 정의 지침에서 다른 파일을 참조할 수 있습니다. Code Review 플로우는 사전 스캔 단계 중에 참조된 파일을 읽고 관련 지침을 추출합니다.

사용자 정의 지침은 두 가지 파일 참조 패턴을 지원합니다:

- 머지 리퀘스트와 같은 프로젝트의 파일: `docs/security-checklist.md`과 같은 리포지토리 상대 경로를 사용합니다.
- 같은 GitLab 인스턴스의 다른 프로젝트의 파일: `https://gitlab.example.com/group/project/-/blob/main/docs/style-guide.md`과 같은 전체 GitLab blob URL을 사용합니다. URL은 머지 리퀘스트와 같은 GitLab 인스턴스를 가리켜야 하며 `/-/blob/<ref>/<path>` 형식을 사용해야 합니다.

예를 들어:

```yaml
instructions:
  - name: Database Migrations
    fileFilters:
      - "db/migrate/**/*.rb"
    instructions: |
      1. Follow the migration guidelines in
         https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/database/avoiding_downtime_in_migrations.md
      2. Reference the team checklist in docs/db-checklist.md
```

### 파일 참조의 제한 {#limitations-of-file-references}

파일 참조 확인에는 다음과 같은 제한이 있습니다:

- 동일한 GitLab 인스턴스만 해당합니다. 다른 GitLab 인스턴스를 가리키는 URL, GitLab Self-Managed 인스턴스의 공개 GitLab, 또는 Confluence나 공개 문서 사이트와 같은 비 GitLab 사이트는 가져오지 않습니다.
- `/-/blob/<ref>/<path>`로 형식이 지정된 Blob URL만 해당합니다. Wiki 페이지, 이슈, 원본 URL 및 스니펫은 가져오지 않습니다.
- 경로를 벗겨낸 경우 동일 프로젝트입니다. `docs/security.md`과 같은 경로를 벗긴 경로는 머지 리퀘스트와 동일한 프로젝트에 대해 확인됩니다. 전체 GitLab blob URL을 사용하여 다른 프로젝트의 파일을 참조합니다.
- 최선의 노력, 보장되지 않음. Code Review 플로우는 지침 텍스트를 기반으로 가져올 참조를 결정합니다. 존재하지 않는 경로 또는 파서가 거부하는 URL과 같이 확인하지 못하는 참조는 자동으로 건너뜁니다.
- Code Review 플로우는 원본 파일이 아닌 요약을 사용합니다. 사전 스캔 단계 중에 가져온 내용을 요약하고 검토 중에 요약을 사용합니다. 동일한 머지 리퀘스트의 두 검토는 다른 요약을 생성할 수 있습니다.

Code Review 플로우에서 정확한 파일 내용을 사용하고 요약이 아닌 경우 파일을 참조하는 대신 `instructions:` 필드에 직접 포함시킵니다. 인라인 지침은 작성된 대로 사용됩니다.

## 모범 사례 {#best-practices}

사용자 지정 검토 지침을 작성할 때:

- 구체적이고 실행 가능해야 합니다. Code Review 플로우는 각 규칙을 diff와 비교합니다. 예를 들어 "공개 메서드에 YARD 문서가 있는지 확인"과 같은 구체적인 규칙은 유용한 주석을 생성하지만 "코드를 잘 문서화"하는 것과 같은 추상적인 지침은 그렇지 않습니다.
- 명확성을 위해 지침에 번호를 매깁니다.
- 가장 중요한 표준에 집중합니다. 모든 규칙의 텍스트는 검토 프롬프트의 일부가 되므로 가치가 낮은 규칙의 긴 목록은 신호를 추가하지 않고 프롬프트를 부풀립니다.
- 도움이 되는 경우 "이유"를 설명합니다.
- 간단한 지침부터 시작하여 필요에 따라 복잡성을 추가합니다.
- Code Review 플로우가 기본적으로 적용하지 않을 프로젝트별 표준에 집중합니다. 사용자 정의 지침은 표준 검토 기준을 대체하지 않고 추가합니다. "오류 처리 추가" 또는 "의미 있는 이름 사용"과 같은 일반적인 조언은 보통 이미 포함되어 있습니다. 사용자 정의 지침을 프로젝트만 알 수 있는 것에 사용합니다: 내부 API, 아키텍처 규칙, 도메인별 패턴
- 지침을 명령이 아닌 지침으로 작성하세요. 지침은 GitLab Duo가 따라야 하는 정책이 아닌 검토 행동을 형성하는 힌트입니다. "항상 플래그" 또는 "절대 허용 안 함"과 같은 표현을 피하세요. 이 표현은 협력자를 행동이 보장된다고 생각하도록 잘못 인도할 수 있습니다.
- 파일 패턴이 규칙의 실제 범위를 반영하도록 합니다. Code Review 플로우는 각 지침을 각 `fileFilters` 참조와 함께 읽고 해당 패턴과 일치하는 파일에만 규칙을 적용합니다. 예를 들어 "Rails 컨트롤러"에 대한 규칙이 `**/*.rb`로 범위가 지정되면 gem, 스크립트 및 테스트뿐 아니라 컨트롤러에도 적용됩니다. 대신 `app/controllers/**/*.rb`을 사용합니다.
- 정확한 표현이 중요하지 않은 지침에만 외부 파일 참조를 사용하고, 그렇지 않으면 세부 정보를 `instructions:` 필드에 규칙으로 직접 포함합니다. Code Review 플로우는 참조된 파일에 대한 요약을 생성하고 사용하지만 `instructions`에 정의된 정확한 표현을 사용합니다.

예를 들어:

```yaml
instructions: |
  1. All public functions must include docstrings with parameter descriptions
  2. Use parameterized queries to prevent SQL injection
  3. Validate user input before processing (check type, length, format)
  4. Include error handling for all external API calls
  5. Avoid hardcoded credentials - use environment variables
```

언어별 예제는 [사용 사례 예제](#use-case-examples)를 참조하세요.

## 파일 패턴 참조 {#file-pattern-reference}

특정 파일을 대상으로 지정하려면 `fileFilters`에서 glob 패턴을 사용합니다.

예를 들어 Ruby 파일이 포함된 프로젝트의 경우 다음과 같습니다.

| 패턴 | 일치 |
| --- | --- |
| `**/*.rb`       | 모든 디렉터리의 모든 Ruby 파일 |
| `*.rb`          | 루트 디렉터리의 Ruby 파일만 |
| `lib/**/*.rb`   | `lib` 디렉터리 및 해당 하위 디렉터리의 Ruby 파일 |
| `!**/*.test.rb` | 모든 Ruby 테스트 파일 제외 |
| `!spec/**/*.rb` | `spec` 디렉터리 및 해당 하위 디렉터리의 모든 Ruby 파일 제외 |
| `!tests/**/*`   | `tests` 디렉터리 및 해당 하위 디렉터리의 모든 파일 제외 |
| `**/*.{js,jsx}` | 모든 디렉터리의 JavaScript 및 JSX 파일(GitLab 19.1 이상) |

다음 예제는 `**/*.rb`과 `*.rb`의 차이점을 보여줍니다.

```plaintext
project/
├── app.rb              ← matched by both *.rb and **/*.rb
├── lib/
│   └── helper.rb       ← matched only by **/*.rb
└── app/
    └── models/
        └── user.rb     ← matched only by **/*.rb
```

- `*.rb`는 app.rb만 일치합니다
- `**/*.rb`는 세 파일 모두와 일치합니다

`mr-review-instructions.yaml` 파일의 경우 `**/*.rb`는 검토 지침이 루트 디렉터리뿐만 아니라 프로젝트 구조의 모든 위치에 있는 Ruby 파일에 적용되도록 합니다.

## 사용 사례 예제 {#use-case-examples}

<!-- 2025-11-12 Use case examples are maintained by DevRel, @dnsmichi
Inspired by the reference in <https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml?ref_type=heads>
-->

{{< tabs >}}

{{< tab title="어셈블리" >}}

```yaml
instructions:
  - name: Assembly Style Guide
    fileFilters:
      - "**/*.asm"
      - "**/*.s"
      - "**/*.S"
    instructions: |
      1. Document the target architecture (x86-64, ARM, RISC-V, AVR, etc.) at the top
      2. Use meaningful labels and comment all non-obvious instructions
      3. Document register usage and calling conventions
      4. Align code sections properly for readability
      5. Include memory layout and stack usage documentation
```

{{< /tab >}}

{{< tab title="C" >}}

```yaml
instructions:
  - name: C Style Guide
    fileFilters:
      - "**/*.c"
      - "**/*.h"
    instructions: |
      1. goto is not allowed
      2. Avoid using global variables
      3. Use meaningful variable names
      4. Add comments for complex logic
```

{{< /tab >}}

{{< tab title="C++" >}}

```yaml
instructions:
  - name: C++ Style Guide
    fileFilters:
      - "**/*.cpp"
      - "**/*.{h,hpp}"
    instructions: |
      1. Ensure all methods have proper documentation
      2. Use smart pointers for dynamic memory management
      3. Avoid raw pointers
```

{{< /tab >}}

{{< tab title="C#" >}}

```yaml
instructions:
  - name: C# Style Guide
    fileFilters:
      - "**/*.cs"
    instructions: |
      1. Follow Microsoft C# coding conventions
      2. Use XML documentation comments for public APIs
      3. Prefer async/await for asynchronous operations
      4. Use nullable reference types appropriately
      5. Follow .NET naming conventions (PascalCase for public members)
```

{{< /tab >}}

{{< tab title="COBOL" >}}

```yaml
instructions:
  - name: COBOL Style Guide
    fileFilters:
      - "**/*.CBL"
      - "**/*.cbl"
      - "**/*.COB"
      - "**/*.cob"
    instructions: |
      1. Use clear and meaningful names for variables and procedures
      2. Prefer COBOL-85 syntax where possible
      3. Use proper division structure (IDENTIFICATION, ENVIRONMENT, DATA, PROCEDURE)
      4. Document all paragraphs and sections with meaningful comments
      5. Use 88-level condition names for boolean flags and status codes
      6. Avoid GO TO statements, prefer PERFORM for structured programming
      7. Use proper error handling with declaratives or status code checking
      8. Define working storage variables with appropriate PICTURE clauses
      9. Use meaningful paragraph names that describe the operation
      10. For mainframe integration, document JCL dependencies and file layouts
```

{{< /tab >}}

{{< tab title="Go" >}}

```yaml
instructions:
  - name: Go Style Guide
    fileFilters:
      - "**/*.go"
    instructions: |
      1. Use idiomatic Go practices
      2. Ensure all public functions and types have documentation
      3. Prefer standard library packages over third-party ones when possible
```

{{< /tab >}}

{{< tab title="Java" >}}

```yaml
instructions:
  - name: Java Style Guide
    fileFilters:
      - "**/*.java"
    instructions: |
      1. Do not modernize Java 8 code to Java 11+ features, unless there is a GitLab issue or task specifically requesting modernization
      2. All public classes must have Javadoc describing purpose and usage
      3. All public methods must have Javadoc with @param and @return tags
      4. Include code examples in main class Javadoc
      5. All public methods must have at least one test case
```

{{< /tab >}}

{{< tab title="JavaScript/TypeScript" >}}

```yaml
instructions:
  - name: JavaScript/TypeScript Files
    fileFilters:
      - "src/**/*.js"
      - "src/**/*.jsx"
      - "src/**/*.ts"
      - "src/**/*.tsx"
      - "!**/*.test.js"
      - "!**/*.test.ts"
      - "!**/*.spec.js"
      - "!**/*.spec.ts"
    instructions: |
      1. Use const/let instead of var
      2. Prefer async/await over promise chains
      3. Add JSDoc comments for complex functions
      4. Ensure proper error handling in async code
      5. Avoid any 'any' types in TypeScript
```

{{< /tab >}}

{{< tab title="Kotlin" >}}

```yaml
instructions:
  - name: Kotlin Style Guide
    fileFilters:
      - "**/*.kt"
      - "**/*.kts"
    instructions: |
      1. Follow Kotlin coding conventions
      2. Prefer immutability (val over var)
      3. Use coroutines for asynchronous operations
      4. Leverage Kotlin's null safety features
      5. Document public APIs with KDoc
```

{{< /tab >}}

{{< tab title="MATLAB" >}}

```yaml
instructions:
  - name: MATLAB Style Guide
    fileFilters:
      - "**/*.m"
    instructions: |
      1. Use descriptive variable and function names with camelCase convention
      2. Vectorize operations instead of using loops where possible
      3. Document functions with H1 line and help text comments
      4. Preallocate arrays before loops to improve performance
      5. Use proper error handling with try-catch blocks and error() function
```

{{< /tab >}}

{{< tab title="Perl" >}}

```yaml
instructions:
  - name: Perl Style Guide
    fileFilters:
      - "**/*.pl"
      - "**/*.pm"
    instructions: |
      1. Follow idiomatic Perl practices
      2. Ensure proper module documentation
      3. Use strict and warnings pragmas
```

{{< /tab >}}

{{< tab title="PHP" >}}

```yaml
instructions:
  - name: PHP Style Guide
    fileFilters:
      - "**/*.php"
    instructions: |
      1. Follow PSR-12 coding standard
      2. Use type declarations for function parameters and return types
      3. Ensure compatibility with PHP 8+
      4. Use proper error handling and exceptions
      5. Document classes and methods with PHPDoc
```

{{< /tab >}}

{{< tab title="Python" >}}

```yaml
instructions:
  - name: Python Source Files
    fileFilters:
      - "**/*.py"
      - "!tests/**/*.py"
      - "!test_*.py"
    instructions: |
      1. All functions must have docstrings with parameters and return types
      2. Use type hints for function signatures
      3. Follow PEP 8 style conventions
      4. Ensure proper exception handling
      5. Avoid using bare 'except' clauses

  - name: Python Tests
    fileFilters:
      - "tests/**/*.py"
      - "test_*.py"
    instructions: |
      1. Use pytest fixtures for common setup
      2. Test names should clearly describe the scenario being tested
      3. Include assertions for both expected outcomes and edge cases
      4. Mock external dependencies appropriately
```

{{< /tab >}}

{{< tab title="Ruby" >}}

```yaml
instructions:
  - name: Ruby Style Guide
    fileFilters:
      - "*.rb"
      - "lib/**/*.rb"
      - "!spec/**/*.rb"  # Exclude test files
    instructions: |
      1. Follow Ruby style guide conventions
      2. Prefer symbols over strings for hash keys
      3. Use snake_case for methods/variables, SCREAMING_SNAKE_CASE for constants, CamelCase for classes
      4. Prefer Ruby 3.0+ features (pattern matching, endless methods) where appropriate
      5. Use proper error handling - raise exceptions over returning nil for errors
      6. Write idiomatic Ruby - use blocks, enumerables, and Ruby idioms over procedural patterns
      7. Use meaningful method names - use ? for predicates, ! for dangerous methods
      8. Prefer keyword arguments for methods with multiple parameters
      9. All public methods should have corresponding RSpec/Minitest tests
      10. Manage dependencies with Gemfile and ensure version compatibility
      11. Document thread-safe code and use proper synchronization for concurrent operations
      12. Handle signals (SIGTERM, SIGINT) properly for daemon processes
```

{{< /tab >}}

{{< tab title="R" >}}

```yaml
instructions:
  - name: R Style Guide
    fileFilters:
      - "**/*.r"
      - "**/*.R"
    instructions: |
      1. Follow tidyverse style guide conventions
      2. Use snake_case for variable and function names
      3. Document functions with roxygen2 comments
      4. Prefer vectorized operations over loops
      5. Use proper error handling with tryCatch and stop()
```

{{< /tab >}}

{{< tab title="Rust" >}}

```yaml
instructions:
  - name: Rust Style Guide
    fileFilters:
      - "**/*.rs"
    instructions: |
      1. Follow Rust idioms and conventions
      2. Use proper error handling with Result and Option types
      3. Avoid unsafe code unless absolutely necessary and well-documented
      4. Ensure all public items have documentation comments
```

{{< /tab >}}

{{< tab title="Scala" >}}

```yaml
instructions:
  - name: Scala Style Guide
    fileFilters:
      - "**/*.scala"
    instructions: |
      1. Follow Scala style guide conventions
      2. Prefer immutable data structures (val over var)
      3. Use pattern matching effectively for control flow
      4. Document public APIs with ScalaDoc
      5. Use proper error handling with Try, Either, or Option types
```

{{< /tab >}}

{{< tab title="Shell" >}}

```yaml
instructions:
  - name: Shell Script Style Guide
    fileFilters:
      - "**/*.sh"
      - "**/*.bash"
      - "**/*.zsh"
      - "**/*.ksh"
    instructions: |
      1. Always quote variables to prevent word splitting ("$var" not $var)
      2. Use proper error handling with set -euo pipefail at script start
      3. Document script purpose, parameters, and exit codes in header comments
      4. Prefer [[ ]] over [ ] for conditional tests
      5. Use meaningful function names and avoid complex one-liners
```

{{< /tab >}}

{{< tab title="SQL" >}}

```yaml
instructions:
  - name: SQL Style Guide
    fileFilters:
      - "**/*.sql"
    instructions: |
      1. Use uppercase for SQL keywords (SELECT, FROM, WHERE, JOIN)
      2. Always specify column names explicitly instead of using SELECT *
      3. For PostgreSQL use SERIAL/RETURNING, for MySQL use AUTO_INCREMENT, for Oracle use SEQUENCE
      4. For NoSQL (MongoDB) use proper indexing and aggregation pipelines to avoid N+1 queries
      5. Document database-specific features and expected performance characteristics
      6. Use proper indentation for complex queries and subqueries
```

{{< /tab >}}

{{< tab title="VHDL" >}}

```yaml
instructions:
  - name: VHDL Style Guide
    fileFilters:
      - "**/*.vhd"
      - "**/*.vhdl"
    instructions: |
      1. Follow IEEE VHDL coding standards
      2. Use meaningful signal and entity names with clear prefixes
      3. Document all entities, architectures, and processes with comments
      4. Use synchronous design practices with proper clock and reset handling
      5. Avoid combinational loops and ensure proper timing constraints
```

{{< /tab >}}

{{< tab title="구성 파일" >}}

```yaml
instructions:
  - name: Configuration Files
    fileFilters:
      - "*.yaml"
      - "*.yml"
      - "*.json"
      - "config/**/*"
      - "!.gitlab/**/*"
    instructions: |
      1. Do not include sensitive data (passwords, API keys)
      2. Use environment variables for environment-specific values
      3. Document all configuration options
      4. Validate configuration schema if possible
```

{{< /tab >}}

{{< tab title="코드 기반 인프라" >}}

```yaml
instructions:
  - name: Ansible Style Guide
    fileFilters:
      - "*.yaml"
      - "*.yml"
      - "playbooks/**/*.yaml"
      - "roles/**/*.yaml"
    instructions: |
      1. Use meaningful play and task names that describe the action
      2. Prefer modules over shell/command tasks when possible
      3. Use variables and defaults for reusability across environments
      4. Implement idempotency - tasks should be safe to run multiple times
      5. Use handlers for service restarts and notifications
      6. Document playbook purpose, required variables, and dependencies

  - name: Dockerfile Style Guide
    fileFilters:
      - "Dockerfile"
      - "*.dockerfile"
      - "Dockerfile.*"
    instructions: |
      1. Use specific base image tags, avoid 'latest'
      2. Minimize layers by combining RUN commands with && where logical
      3. Use multi-stage builds to reduce final image size
      4. Run containers as non-root user for security
      5. Use .dockerignore to exclude unnecessary files
      6. Document exposed ports, volumes, and environment variables

  - name: GitLab CI/CD Style Guide
    fileFilters:
      - ".gitlab-ci.yml"
      - "**/.gitlab-ci.yml"
    instructions: |
      1. Use job extends instead of YAML anchors for reusability
      2. Always use rules instead of only/except for job conditions
      3. Define appropriate caching strategies for dependencies
      4. Use stages to organize pipeline workflow logically
      5. Include security scanning templates (SAST, dependency scanning, secret detection)
      6. Document job purpose, required variables, and dependencies in comments

  - name: Helm Chart Style Guide
    fileFilters:
      - "Chart.yaml"
      - "values.yaml"
      - "templates/**/*.yaml"
    instructions: |
      1. Use semantic versioning for chart versions
      2. Provide sensible defaults in values.yaml with comments
      3. Use template functions for conditional logic and loops
      4. Include NOTES.txt with post-installation instructions
      5. Validate charts with helm lint before committing
      6. Document all configurable values and their purpose

  - name: Kubernetes Style Guide
    fileFilters:
      - "*.yaml"
      - "*.yml"
      - "k8s/**/*.yaml"
      - "kubernetes/**/*.yaml"
    instructions: |
      1. Use explicit API versions and avoid deprecated APIs
      2. Always define resource limits and requests for containers
      3. Use namespaces to organize resources logically
      4. Define liveness and readiness probes for all deployments
      5. Use ConfigMaps and Secrets instead of hardcoded values
      6. Document resource purpose and dependencies in metadata annotations

  - name: Terraform/OpenTofu Style Guide
    fileFilters:
      - "*.tf"
      - "*.tfvars"
    instructions: |
      1. Use consistent naming conventions for resources (environment_service_resource)
      2. Organize code into modules for reusability
      3. Use variables with descriptions and validation rules
      4. Define outputs for important resource attributes
      5. Use remote state with locking for team collaboration
      6. Document module purpose, inputs, outputs, and provider requirements
```

{{< /tab >}}

{{< /tabs >}}

### 예제 프로젝트 {#example-projects}

더 많은 사용자 지정 검토 지침 사용 사례는 다음 프로덕션 예제를 참조합니다.

- [`gitlab-org/gitlab`에서의 GitLab 개발](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/duo/mr-review-instructions.yaml)
- [GitLab 핸드북](https://gitlab.com/gitlab-com/content-sites/handbook/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)
- [GitLab 웹사이트](https://gitlab.com/gitlab-com/marketing/digital-experience/about-gitlab-com/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)
- [개발자 옹호: Tanuki IoT 플랫폼](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)

## 문제 해결 {#troubleshooting}

`mr-review-instructions.yaml`로 작업할 때 다음과 같은 문제가 발생할 수 있습니다.

### Code Review 플로우가 지침을 건너뛰거나 일반 검토를 반환합니다 {#code-review-flow-skips-instructions-or-returns-a-generic-review}

Code Review 플로우가 사용자 정의 지침을 건너뛰거나 일반 검토를 반환하면 파일에 구조적 문제가 있을 수 있습니다. 사용자 정의 지침 린터를 사용하여 문제를 식별합니다.

#### 사용자 정의 지침 린터 실행 {#run-the-custom-instructions-linter}

사용자 정의 지침 린터는 `mr-review-instructions.yaml` 파일을 검증하는 데 도움이 됩니다.

린터가 확인하는 항목:

- 잘못된 YAML 구문.
- 누락되었거나 예상치 못한 최상위 키.
- 누락되었거나 비어 있는 필수 필드(`name`, `instructions`).
- 명령 항목의 알 수 없는 키(예: `rules` 대신 `instructions`).
- `fileFilters` 값이 목록이 아니거나 문자열이 아니거나 빈 항목이 포함됩니다.
- 누락되었거나 비어 있는 `fileFilters`이므로 지침이 모든 파일에 적용됩니다(정보).
- 명령 항목 전체에서 중복 `name` 값.

> [!note]
> 린터는 파일만 읽고 수정하지 않습니다. GitLab 또는 Rails 종속성이 없으며 Ruby가 설치되어 있는 모든 곳에서 실행됩니다.

전제 조건:

- Ruby 3.0 이상.

GitLab 서버에서 린터를 Rake 작업으로 실행하려면 `<path>`을(를) `mr-review-instructions.yaml` 파일의 경로로 바꿉니다. 예를 들어:

```shell
sudo gitlab-rake "gitlab:duo:lint_review_instructions[<path>]"
```

Ruby가 설치되어 있는 모든 머신에서 린터를 독립 실행형 스크립트로 실행하려면:

1. [`review_instructions_linter.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/review_instructions_linter.rb)를 다운로드합니다.
1. 린터를 실행합니다. `<path>`을(를) `mr-review-instructions.yaml` 파일의 경로로 바꿉니다.

   ```shell
   ruby -r ./review_instructions_linter.rb -e '
     linter = Gitlab::Duo::Administration::ReviewInstructionsLinter.new(ARGV[0]).run
     linter.issues.each { |issue| puts issue }
     exit(linter.valid? ? 0 : 1)
   ' <path>
   ```

경로를 생략하면 린터는 작업 디렉터리에서 `.gitlab/duo/mr-review-instructions.yaml`로 기본설정됩니다. 린터는 오류가 발견되지 않으면 상태 `0`로 종료되고, 그 외의 경우 `1`으로 종료됩니다. 경고 및 정보 메시지는 0이 아닌 종료를 발생하지 않습니다.

예를 들어, 이 잘못된 파일은 `rules` 대신 `instructions`를 사용하고 `fileFilters`을(를) 생략합니다:

```yaml
instructions:
  - name: "General"
    rules: "Do something"
```

린터가 보고하는 내용:

```plaintext
[ERROR E009] Field 'instructions' must be a non-empty string at instructions[0]
[WARNING W003] Unknown keys: "rules"; expected name, instructions, fileFilters at instructions[0]
[INFO I001] Missing 'fileFilters'; the instruction applies to every file at instructions[0]
```

보고된 오류를 수정하고 오류가 없을 때까지 린터를 다시 실행합니다.

#### 린터 메시지 코드 {#linter-message-codes}

각 메시지에는 도움을 요청할 때 참조할 수 있는 안정적인 코드가 포함되어 있습니다. `E`로 시작하는 코드는 오류이고, `W`로 시작하는 코드는 경고이며, `I`로 시작하는 코드는 유효하지만 주목할 만한 행동에 대한 정보 메모입니다.

| 코드 | 설명 |
| ---- | ----------- |
| `E001` | 파일이 주어진 경로에 존재하지 않습니다. |
| `E003` | 파일에 잘못된 YAML 구문이 포함되어 있습니다. |
| `E004` | 최상위 YAML 값이 매핑이 아닙니다. |
| `E005` | 최상위 `instructions` 키가 누락되었습니다. |
| `E006` | `instructions` 값이 목록이 아닙니다. |
| `E007` | `instructions` 아래의 항목이 매핑이 아닙니다. |
| `E008` | 항목의 `name` 필드가 누락되었거나 비어 있거나 문자열이 아닙니다. |
| `E009` | 항목의 `instructions` 필드가 누락되었거나 비어 있거나 문자열이 아닙니다. |
| `E011` | 항목의 `fileFilters` 값이 목록이 아닙니다. |
| `E013` | 항목의 `fileFilters`에 숫자와 같은 문자열이 아닌 값이 포함되어 있습니다. |
| `E014` | 항목의 `fileFilters`에 빈 문자열이 포함되어 있습니다. |
| `W001` | 파일에 알 수 없는 최상위 키가 포함되어 있습니다. |
| `W002` | `instructions` 목록이 비어 있으므로 지침이 적용되지 않습니다. |
| `W003` | 항목에 `name`, `instructions` 및 `fileFilters` 이외의 키가 포함되어 있습니다. |
| `W004` | 둘 이상의 항목이 동일한 `name`을(를) 공유합니다. |
| `W007` | 파일이 비어 있으므로 지침이 적용되지 않습니다. |
| `I001` | 항목에 `fileFilters` 필드가 누락되어 있으므로 지침이 모든 파일에 적용됩니다. |
| `I002` | 항목의 `fileFilters` 목록이 비어 있으므로 지침이 모든 파일에 적용됩니다. |

## 관련 항목 {#related-topics}

- [머지 리퀘스트에서의 GitLab Duo](../../project/merge_requests/duo_in_merge_requests.md)
- [Code Review 플로우](../flows/foundational_flows/code_review.md)
