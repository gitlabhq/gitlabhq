---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 의존성의 동작 분석
description: "Libbehave는 머지 리퀘스트에 추가된 새로운 종속성을 검사하여 위험한 동작을 찾고 각 동작에 위험도 점수를 할당합니다. 결과는 작업 출력, 머지 리퀘스트 댓글 및 작업 아티팩트에 표시됩니다."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

Libbehave는 머지 리퀘스트 파이프라인 중에 종속성을 검사하여 새로 추가된 라이브러리와 잠재적으로 위험한 동작을 식별하는 실험 기능입니다. 종속성 검사가 알려진 취약점을 찾는 반면 Libbehave는 종속성이 나타내는 기능과 동작에 대한 인사이트를 제공합니다.

Libbehave가 감지한 각 기능에는 다음 중 하나의 "위험도" 점수가 할당됩니다:

- 정보성: 위험이 없지만 종속성의 기능을 분류하는 데 도움이 될 수 있습니다(예: JSON 사용).
- 낮음: 작은 위험이지만 종속성이 암호화 사용 같은 보안에 민감한 작업을 수행하는 것을 강조할 수 있습니다.
- 중간: 중간 수준의 위험이며, 파일 시스템과 상호 작용하거나 민감한 데이터가 저장되거나 액세스될 수 있는 환경 변수를 읽는 데 사용될 수 있습니다.
- 높음: 가장 높은 수준의 위험이며, 이러한 동작은 OS 명령 실행 또는 동적으로 코드를 평가하는 것 같은 보안 취약점에서 자주 악용됩니다.

Libbehave가 감지하는 기능:

- OS 명령 실행
- 동적 코드 실행(eval)
- 파일 읽기/쓰기
- 네트워크 소켓 열기
- 아카이브 읽기/확장(ZIP/tar/Gzip)
- HTTP 클라이언트, Redis, Elastic Cache, 관계형 관리 데이터베이스(RMDB) 서버, SSH, Git을 사용하여 외부 서비스와 상호 작용
- 다양한 형식으로 데이터 직렬화: XML, YAML, MessagePack, Protocol Buffers, JSON 및 언어별 형식
- 템플릿팅
- 인기 있는 프레임워크
- 파일 업로드/다운로드

지원되는 패키지 관리자 유형별 Libbehave 데모는 [Libbehave 데모 프로젝트](https://gitlab.com/gitlab-org/security-products/demos/experiments/libbehave)를 참조하세요.

## 지원되는 언어 및 패키지 관리자 {#supported-languages-and-package-managers}

다음 언어 및 패키지 관리자는 Libbehave에서 지원됩니다:

- C#([NuGet](https://www.nuget.org/))
  - `Directory.Build.props` 파일을 읽습니다(찾은 경우 속성 값 교체).
  - `*.deps.json` 파일을 읽습니다.
  - `**/*.dll` 및 `**/*.exe` 파일을 읽습니다.
- Go
  - `go.mod` 파일을 읽습니다.
- Java([Maven](https://maven.org))
  - `pom.xml` 파일을 읽습니다(찾은 경우 속성 값 교체).
  - `**/gradle.lockfile*` 파일을 읽습니다.
- JavaScript/TypeScript([npmjs](https://npmjs.com))
  - `**/package-lock.json` 파일을 읽습니다.
  - `**/yarn.lock` 파일을 읽습니다.
  - `**/pnpm-lock.yaml` 파일을 읽습니다.
- Python([pypi](https://pypi.org))
  - `**/*requirements*.txt` 파일을 읽습니다.
  - `**/poetry.lock` 파일을 읽습니다.
  - `**/Pipfile.lock` 파일을 읽습니다.
  - `**/setup.py` 파일을 읽습니다.
  - 계란 또는 휠 설치 디렉토리의 패키지를 읽습니다:
    - `**/*dist-info/METADATA`, `**/*egg-info/PKG-INFO`, `**/*DIST-INFO/METADATA` 및 `**/*EGG-INFO/PKG-INFO` 파일을 읽습니다.
- PHP([Composer/Packagist](https://packagist.org/))
  - `**/installed.json` 파일을 읽습니다.
  - `**/composer.lock` 파일을 읽습니다.
  - `**/php/.registry/.channel.*/*.reg"` 파일을 읽습니다.
- Ruby([RubyGems](https://rubygems.org))
  - `**/Gemfile.lock` 파일을 읽습니다.
  - `**/specifications/**/*.gemspec` 파일을 읽습니다.
  - `**/*.gemspec` 파일을 읽습니다.

이전 파일은 소스 브랜치에서 수정된 경우에만 새로운 종속성 분석됩니다.

## Libbehave 활성화 {#enable-libbehave}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 파이프라인은 정의된 소스 및 대상 Git 브랜치를 가진 활성 [머지 리퀘스트 파이프라인](../../../ci/pipelines/merge_request_pipelines.md)의 일부입니다.
- 프로젝트에는 지원되는 [언어](#supported-languages-and-package-managers) 중 하나가 포함됩니다.
- 프로젝트는 소스 또는 기능 브랜치에 새로운 종속성을 추가하고 있습니다.

Libbehave를 활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **Code** > **Repository**를 선택합니다.
1. `.gitlab-ci.yml` 파일을 선택합니다.
1. **Edit** > **Edit single file**를 선택합니다.
1. Libbehave [CI/CD 구성 요소](../../../ci/components/_index.md)를 추가합니다:

   ```yaml
   include:
     - component: $CI_SERVER_FQDN/security-products/experiments/libbehave/libbehave@v0.1.0
       inputs:
         stage: test
   ```

1. **변경 사항 커밋**을 선택합니다.

이 구성은 테스트 스테이지에서 `libbehave-experiment`라는 새로운 작업을 생성합니다.

### 머지 리퀘스트 댓글 구성 {#configure-merge-request-comments}

Libbehave에 대한 머지 리퀘스트 댓글을 구성하려면 프로젝트 액세스 토큰을 구성합니다.

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.
- 프로젝트에 대해 Libbehave가 활성화되었습니다.

머지 리퀘스트 댓글을 구성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **액세스 토큰**을 선택합니다.
1. **새 토큰 추가**를 선택하고 필드를 완성합니다:
   - **토큰 이름**: 예를 들어 `libbehave-bot`와 같은 이름을 입력합니다.
   - **역할**: **게스트**를 선택합니다.
   - **범위 선택**: **API** 체크박스를 선택합니다.
1. [**Create project access token**](../../project/settings/project_access_tokens.md)을 선택합니다.

   프로젝트 액세스 토큰을 클립보드에 복사합니다. 다음 단계에서 필요합니다.
1. **설정** > **CI/CD**를 선택합니다.
1. **변수**를 확장합니다.
1. **변수 추가**를 선택하고 필드를 완성합니다:
   - **키**: `BEHAVE_TOKEN`를 입력합니다.
   - **Value (값)**: 프로젝트 액세스 토큰을 붙여넣습니다.
   - **공개범위**: **마스킹됨**을 선택합니다.
   - **플래그**: **보호 변수** 체크박스를 해제합니다.
1. **변수 추가**를 선택합니다.

CI/CD 구성 요소는 자동으로 `BEHAVE_TOKEN`를 사용하므로 구성 요소 입력에서 지정할 필요가 없습니다.

> [!note]
> 머지 리퀘스트 댓글은 소스 브랜치가 보호된 브랜치이거나 `BEHAVE_TOKEN` 변수에 대해 **보호 변수** 옵션이 선택 해제된 경우에만 나타납니다.

### 사용 가능한 CI/CD 입력 및 변수 {#available-cicd-inputs-and-variables}

CI/CD 변수를 사용하여 Libbehave의 [CI/CD 구성 요소](https://gitlab.com/security-products/experiments/libbehave)를 사용자 지정할 수 있습니다.

다음 변수는 Libbehave가 실행되는 방식의 동작을 구성합니다.

| CI/CD 변수                        | CLI 인수 | 기본값 | 설명                                                            |
|---------------------------------------|--------------|---------|------------------------------------------------------------------------|
| `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME` | `-source`    | `""`    | 비교할 소스 브랜치(예: feature-branch)            |
| `CI_MERGE_REQUEST_TARGET_BRANCH_NAME` | `-target`    | `""`    | 비교할 대상 브랜치(예: main)                      |
| `BEHAVE_TIMEOUT`                      | `-timeout`   | `"30m"` | 패키지 분석 및 다운로드에 허용된 최대 시간(예: 30분)   |
| `BEHAVE_TOKEN`                        | `-token`     | `""`    | 선택 사항. 액세스 토큰(머지 리퀘스트 댓글 생성에 필요)    |
| `CI_PROJECT_ID`                       | `-project`   | `""`    | 선택 사항. 결과와 함께 머지 리퀘스트 노트를 생성할 프로젝트 ID       |
| `CI_MERGE_REQUEST_IID`                | `-mrid`      | `""`    | 선택 사항. 결과와 함께 머지 리퀘스트 노트를 생성할 머지 리퀘스트 ID |

다음 플래그는 사용 가능하지만 테스트되지 않았으므로 기본값으로 두어야 합니다:

| CI/CD 변수         | CLI 인수     | 기본값       | 설명                 |
|------------------------|------------------|---------------|-----------------------------|
| `BEHAVE_RULE_PATHS`    | `-rules`         | `"/dist"`     | 규칙 파일의 경로입니다. |
| `BEHAVE_TARGET_DIR`    | `-dir`           | `""`          | Libbehave를 실행할 대상 디렉토리입니다. |
| `BEHAVE_NO_GIT_IGNORE` | `-no-git-ignore` | `true`        | `.gitignore`의 파일을 검사할지 여부입니다. 인수를 제공하면 스캔하지 않으며, 기본적으로 스캔합니다. |
| `BEHAVE_OUTPUT_PATH`   | `-output`        | `"behaveout"` | 검사 결과, 추출된 아티팩트 및 보고서 결과를 저장할 경로입니다. |
| `BEHAVE_INCLUDE_LANG`  | `-include-lang`  | `""`          | 언어 포함: `csharp`, `go`, `java`, `js`, `php`, `python` 또는 `ruby`, 쉼표로 구분되며 지정되지 않은 다른 언어는 제외됩니다. |
| `BEHAVE_EXCLUDE_LANG`  | `-exclude-lang`  | `""`          | 언어 제외: `csharp`, `go`, `java`, `js`, `php`, `python` 또는 `ruby`, 쉼표로 구분되며 지정되지 않은 다른 언어를 포함합니다. |
| `BEHAVE_EXCLUDE_FILES` | `-exclude-`      | `""`          | 정규식으로 파일 또는 경로를 제외하고, 개별 정규식은 쉼표로 구분됩니다. |

모든 변수가 테스트되지 않았기 때문에 작동하는 것도 있고 그렇지 않은 것도 있을 수 있습니다. 작동하지 않는 것이 필요한 경우 [기능 요청 제출](https://gitlab.com/gitlab-org/gitlab/-/issues/new?description_template=Feature%20proposal%20-%20detailed&issue[title]=Docs%20feedback%20-%20feature%20proposal:%20Write%20your%20title) 또는 코드에 기여하여 사용할 수 있도록 합니다.

## 종속성 감지 및 분석 {#dependency-detection-and-analysis}

Libbehave는 새로 추가된 종속성에 대한 결과를 분석하고 보고하며 [머지 리퀘스트 파이프라인](../../../ci/pipelines/merge_request_pipelines.md)에서 실행됩니다. 즉, 머지 리퀘스트에 새로운 종속성이 포함되지 않으면 Libbehave는 0개 결과를 반환합니다.

감지는 사용되는 언어 및 패키지 관리자에 따라 다릅니다. 기본적으로 지원되는 패키지 관리자는 추가 중인 종속성을 식별하기 위해 패키지 관리자 관련 파일을 구문 분석합니다. 이 정보는 수집되어 각 패키지 관리자 API를 호출하여 식별된 패키지의 아티팩트를 다운로드합니다.

다운로드된 후 종속성은 Semgrep 기반의 정적 분석 방법을 사용하여 구성된 검사 세트로 추출되고 분석됩니다.

Java 및 C#의 경우 정적 분석을 실행하기 전에 바이너리 아티팩트를 역컴파일하는 추가 단계가 수행됩니다.

### 알려진 이슈 {#known-issues}

각 언어에는 자체 알려진 문제가 있습니다.

`Gemfile.lock` 및 `requirements.txt`와 같은 모든 패키지 파일은 명시적 버전을 제공해야 합니다. 버전 범위는 지원되지 않습니다.

#### C# {#c}

- `.props` 또는 `.csproj` 파일의 속성 또는 변수 교체는 중첩된 프로젝트 파일을 고려하지 않습니다. 추출된 변수 및 해당 값의 전역 집합과 일치하는 모든 변수를 교체합니다.
- 다운로드한 종속성을 역컴파일하므로 소스를 라인 변환이 1:1이 아닐 수 있습니다.
- Libbehave는 NuGet 패키지에 존재하는 모든 .NET 버전을 역컴파일합니다. 이것은 향후 최적화될 수 있습니다.
  - 예를 들어 일부 종속성은 다양한 프레임워크 버전(예: net20/Some.dll, net45/Some.dll)을 대상으로 하는 단일 아카이브에 여러 DLL을 패키징합니다.

#### Java {#java}

- `pom.xml` 파일에 대한 [상속](https://maven.apache.org/pom.html#inheritance)을 지원하지 않습니다.
- Maven만 지원하고 사용자 정의 JFrog 또는 기타 아티팩트 저장소는 지원하지 않습니다.
- 다운로드한 종속성을 역컴파일하므로 소스를 라인 변환이 1:1이 아닐 수 있습니다.

#### Python {#python}

- PyPI에서 분석을 위한 소스 패키지를 다운로드하려고 시도합니다. 소스 패키지가 없으면 Libbehave는 대상 OS와 일치하지 않을 수 있는 첫 번째 사용 가능한 `bdist_wheel` 패키지를 다운로드합니다.

## 출력 {#output}

Libbehave는 다음 출력을 생성합니다:

- **Job summary**: 결과 요약은 종속성이 감지한 기능을 빠르게 확인할 수 있도록 CI/CD 출력 작업 콘솔에 직접 출력됩니다.
- **MR comment summary**: 결과 요약은 더 쉬운 검토를 위해 머지 리퀘스트 댓글 노트로 출력됩니다. 이를 위해서는 MR 노트 섹션에 쓸 수 있도록 액세스 토큰을 구성해야 합니다.
- **HTML artifact**: 라이브러리의 검색 가능한 세트와 식별된 기능, 그리고 결과를 유발한 코드의 정확한 라인을 포함하는 HTML 아티팩트입니다.

### 작업 요약 {#job-summary}

작업 요약은 추가 구성이 필요 없으며 성공적인 분석 후 항상 표시됩니다.

작업 요약 출력 예:

```plaintext
# Job output #

[=== libbehave: New packages detected ===]
🔺 4 new packages have been detected in this MR.
[= java - open-vulnerability-clients 6.1.7 =]
The https://mvnrepository.com/artifact/io.github.jeremylong/open-vulnerability-clients package was found to exhibit the following behaviors:
    - 🟧 GzipReadArchive (Risk: Medium)
-----------------
[= java - jdiagnostics 1.0.7 =]
The https://mvnrepository.com/artifact/org.anarres.jdiagnostics/jdiagnostics package was found to exhibit the following behaviors:
    - 🟥 CryptoMD5 (Risk: High)
    - 🟧 WriteFile (Risk: Medium)
    - 🟧 ReadFile (Risk: Medium)
    - 🟧 ReadEnvVars (Risk: Medium)
-----------------
[= java - commons-dbcp2 2.12.0 =]
The https://mvnrepository.com/artifact/org.apache.commons/commons-dbcp2 package was found to exhibit the following behaviors:
    - 🟥 JavaObjectSerialization (Risk: High)
    - 🟧 Passwords (Risk: Medium)
-----------------
[= java - jmockit 1.49 =]
The https://mvnrepository.com/artifact/org.jmockit/jmockit package was found to exhibit the following behaviors:
    - 🟥 JavaObjectSerialization (Risk: High)
    - 🟧 WriteFile (Risk: Medium)
    - 🟧 ReadFile (Risk: Medium)
    - 🟨 CryptoRAND (Risk: Low)
-----------------
```

### 머지 리퀘스트 댓글 요약 {#mr-comment-summary}

**MR comment summary** 출력에는 Libbehave 구성 요소가 구성된 프로젝트에 대해 생성된 게스트 수준 액세스 권한을 가진 액세스 토큰이 필요합니다. 액세스 토큰은 그 후 [프로젝트에 대해 구성](../../../ci/variables/_index.md#for-a-project)해야 합니다. 기능 브랜치는 기본적으로 보호되지 않으므로 **보호 변수** 설정이 지워졌는지 확인합니다. 그렇지 않으면 Libbehave 작업이 액세스 토큰의 값을 읽을 수 없습니다.

![머지 리퀘스트 댓글 요약 출력 예](img/libbehave_mr_comment_v17_4.png)

### HTML 아티팩트 {#html-artifact}

HTML 아티팩트는 작업 아티팩트 출력(`behaveout/gl-libbehave.html`)에 나타나며 작업 아티팩트 다운로드에서 액세스할 수 있습니다.

![HTML 아티팩트 요약 출력](img/libbehave_html_artifact_v17_4.png)

## 오프라인 환경(지원되지 않음) {#offline-environment-not-supported}

Libbehave는 다양한 패키지 관리자에서 직접 종속성을 다운로드하므로 오프라인 환경에서 작동하지 않습니다.

## 문제 해결 {#troubleshooting}

### 작업이 실행되지 않음 {#job-is-not-run}

Libbehave 작업이 실행되지 않으면 프로젝트가 [머지 리퀘스트 파이프라인](../../../ci/pipelines/merge_request_pipelines.md)을 실행하도록 구성되었는지 확인합니다.

### 머지 리퀘스트 댓글이 추가되지 않음 {#merge-request-comment-is-not-being-added}

이는 일반적으로 `BEHAVE_TOKEN`이 설정되지 않았기 때문입니다. 액세스 토큰이 게스트 수준 액세스를 가지고 있으며 **설정** > **CI/CD** 변수 설정에서 **보호 변수** 옵션이 선택 해제되었는지 확인합니다.

#### 오류: `{401 Permission Denied}` {#error-401-permission-denied}

이는 일반적으로 `BEHAVE_TOKEN`이 올바른 값을 포함하지 않았기 때문입니다. 액세스 토큰이 게스트 수준 액세스를 가지고 있는지 확인합니다.
