---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파이프라인 비밀 탐지
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

파이프라인 비밀 탐지는 파일이 Git 리포지토리에 커밋되고 GitLab으로 푸시된 후 스캔합니다.

[파이프라인 비밀 탐지를 활성화](#getting-started)한 후 스캔은 `secret_detection` 이름의 CI/CD 작업에서 실행됩니다. 스캔을 실행하고 [파이프라인 비밀 탐지 JSON 보고서 아티팩트](../../../../ci/yaml/artifacts_reports.md#artifactsreportssecret_detection)를 모든 GitLab 티어에서 볼 수 있습니다.

GitLab Ultimate를 사용하면 파이프라인 비밀 탐지 결과가 처리되므로 다음을 수행할 수 있습니다:

- [머지 리퀘스트 보고서](../../../project/merge_requests/reports.md), [파이프라인 보안 보고서](../../detect/security_scanning_results.md), [취약성 보고서](../../vulnerability_report/_index.md)에서 이를 볼 수 있습니다.
- 승인 워크플로우에서 이를 사용합니다.
- 보안 대시보드에서 이를 검토합니다.
- [공개 리포지토리의 누출에 자동으로 대응](../automatic_response.md)합니다.
- [보안 정책](../../policies/_index.md)을 사용하여 프로젝트 전체에 일관된 비밀 탐지 규칙을 적용합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 이 파이프라인 비밀 탐지 설명서의 대화형 읽기 및 실습 데모를 보려면:

- [GitLab 애플리케이션 보안에서 비밀 탐지를 활성화하는 방법 1부/2](https://youtu.be/dbMxeO6nJCE?feature=shared)
- [GitLab 애플리케이션 보안에서 비밀 탐지를 활성화하는 방법 2부/2](https://youtu.be/VL-_hdiTazo?feature=shared)

<i class="fa-youtube-play" aria-hidden="true"></i> 다른 대화형 읽기 및 실습 데모를 보려면 [GitLab 애플리케이션 보안 시작 재생목록](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)을 참조합니다.

## 가용성 {#availability}

다양한 기능이 다양한 [GitLab 티어](https://about.gitlab.com/pricing/)에서 사용 가능합니다.

| 기능                                                              | Free 및 Premium | Ultimate |
|:------------------------------------------------------------------------|:------------------|:------------|
| [분석기 동작 사용자 지정](configure.md#customize-analyzer-behavior) | {{< yes >}}       | {{< yes >}} |
| [출력](#secret-detection-results) 다운로드                            | {{< yes >}}       | {{< yes >}} |
| 머지 리퀘스트 보고서에서 새 발견 항목 확인                               | {{< no >}}        | {{< yes >}} |
| 파이프라인의 **보안** 탭에서 식별된 비밀 보기              | {{< no >}}        | {{< yes >}} |
| [취약성 관리](../../vulnerability_report/_index.md)          | {{< no >}}        | {{< yes >}} |
| [보안 대시보드에 액세스](../../security_dashboard/_index.md)     | {{< no >}}        | {{< yes >}} |
| [분석기 규칙 집합 사용자 지정](configure.md#customize-analyzer-rulesets) | {{< no >}}        | {{< yes >}} |
| [보안 정책 활성화](../../policies/_index.md)                    | {{< no >}}        | {{< yes >}} |

## 시작하기 {#getting-started}

파이프라인 비밀 탐지를 시작하려면 파일럿 프로젝트를 선택하고 분석기를 활성화합니다.

전제 조건:

- [`docker`](https://docs.gitlab.com/runner/executors/docker/) 또는 [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) 실행기가 있는 Linux 기반 러너가 있습니다. GitLab.com의 호스팅된 러너를 사용하는 경우 이는 기본적으로 활성화됩니다.
  - Windows 러너는 지원되지 않습니다.
  - amd64 이외의 CPU 아키텍처는 지원되지 않습니다.
- `.gitlab-ci.yml` 파일이 있으며 `test` 스테이지를 포함합니다.

다음 중 하나를 사용하여 비밀 탐지 분석기를 활성화합니다:

- `.gitlab-ci.yml` 파일을 수동으로 편집합니다. CI/CD 구성이 복잡한 경우 이 방법을 사용합니다.
- 자동으로 구성된 머지 리퀘스트를 사용합니다. CI/CD 구성이 없거나 구성이 최소한인 경우 이 방법을 사용합니다.
- [검사 실행 정책](../../policies/scan_execution_policies.md)에서 파이프라인 비밀 탐지를 활성화합니다.

처음으로 프로젝트에서 비밀 탐지 스캔을 실행하는 경우 분석기를 활성화한 직후에 과거 스캔을 실행해야 합니다.

파이프라인 비밀 탐지를 활성화한 후 [분석기 설정을 사용자 지정](configure.md)할 수 있습니다.

### `.gitlab-ci.yml` 파일을 수동으로 편집 {#edit-the-gitlab-ciyml-file-manually}

이 방법은 기존 `.gitlab-ci.yml` 파일을 수동으로 편집해야 합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 편집기**를 선택합니다.
1. `.gitlab-ci.yml` 파일의 하단에 다음을 복사하여 붙여넣습니다:

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml
   ```

1. **검증** 탭을 선택한 후 **파이프라인 검증**을 선택합니다. **시뮬레이션이 성공적으로 완료되었습니다.** 메시지는 파일이 유효함을 나타냅니다.
1. **편집** 탭을 선택합니다.
1. 선택 사항. **커밋 메시지** 텍스트 상자에서 커밋 메시지를 사용자 지정합니다.
1. **브랜치** 텍스트 상자에 기본 브랜치 이름을 입력합니다.
1. **Commit changes**를 선택합니다.

파이프라인에는 이제 파이프라인 비밀 탐지 작업이 포함됩니다. 분석기를 활성화한 후 [과거 스캔 실행](#run-a-historic-scan)을 고려합니다.

### 자동으로 구성된 머지 리퀘스트 사용 {#use-an-automatically-configured-merge-request}

이 방법은 파이프라인 비밀 탐지 템플릿을 포함하는 `.gitlab-ci.yml` 파일을 추가하기 위해 머지 리퀘스트를 자동으로 준비합니다. 머지 리퀘스트를 병합하여 파이프라인 비밀 탐지를 활성화합니다.

파이프라인 비밀 탐지를 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **파이프라인 비밀 탐지** 행에서 **머지 리퀘스트로 설정**을 선택합니다.
1. 선택 사항. 필드를 완성하세요.
1. **머지 리퀘스트 생성**을 선택합니다.
1. 머지 리퀘스트를 검토하고 병합합니다.

파이프라인에는 이제 파이프라인 비밀 탐지 작업이 포함됩니다.

## 범위 {#coverage}

파이프라인 비밀 탐지는 범위와 실행 시간을 균형 있게 최적화됩니다. 현재 리포지토리 상태와 향후 커밋만 비밀로 스캔됩니다. 리포지토리 기록에 이미 있는 비밀을 식별하려면 파이프라인 비밀 탐지를 활성화한 후 한 번 과거 스캔을 실행합니다. 스캔 결과는 파이프라인이 완료된 후에만 사용 가능합니다.

정확히 비밀로 스캔되는 항목은 파이프라인 유형과 추가 구성이 설정되었는지에 따라 달라집니다.

기본적으로 파이프라인을 실행할 때:

- 브랜치에서:
  - **기본 브랜치**에서 Git 작업 트리가 스캔됩니다. 이는 현재 리포지토리 상태가 일반적인 디렉터리인 것처럼 스캔됨을 의미합니다.
  - **feature branch**에서:
    - 분석기 버전 `v7.35.0` 이상에서는 병합 기반에서 최신 커밋까지의 모든 커밋 내용(분기가 분산된 후 브랜치에 고유한 모든 커밋)이 스캔됩니다. 이 동작은 병합 기반을 사용할 수 있을 때 모든 기능 브랜치 파이프라인에 적용됩니다.
    - GitLab 19.1 이상은 [미리 정의된 CI 변수](../../../../ci/variables/predefined_variables.md) `CI_COMMIT_DEFAULT_BRANCH_BASE_SHA`를 통해 병합 기반 SHA를 노출합니다.
    - GitLab 19.1 이전 버전이거나 병합 기반을 사용할 수 없는 경우 분석기는 이전 동작으로 폴백됩니다:
      - 새로운 기능 브랜치에서는 최신 커밋만 스캔됩니다. 브랜치의 이전 커밋은 스캔에 포함되지 않습니다.
      - 기존 기능 브랜치에서는 마지막으로 푸시된 커밋에서 최신 커밋까지의 모든 커밋이 스캔됩니다.

    > [!note]
    > 브랜치 분산 지점에서 모든 커밋을 매번 스캔하려면 [머지 리퀘스트 파이프라인](../../../../ci/pipelines/merge_request_pipelines.md)을 활성화합니다.
- **머지 리퀘스트**에서 브랜치의 모든 커밋의 내용이 스캔됩니다. 분석기가 모든 커밋에 액세스할 수 없는 경우 부모에서 최신 커밋까지의 모든 커밋 내용이 스캔됩니다. 모든 커밋을 스캔하려면 [머지 리퀘스트 파이프라인](../../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)을 활성화해야 합니다.

기본 동작을 재정의하려면 [사용 가능한 CI/CD 변수](configure.md#available-cicd-variables)를 사용합니다.

### 분석기가 커밋을 가져오는 방법 {#how-the-analyzer-fetches-commits}

기본적으로 GitLab이 리포지토리를 처음 복제할 때 가장 최근 커밋("얕은 복제")만 가져옵니다. 초기 복제 후 추가 커밋이 필요한 경우 분석기는 최적화된 전략을 사용하여 자동으로 가져옵니다:

- 머지 리퀘스트의 경우 분석기는 병합 기반 후 커밋된 변경 사항만 검색하므로 데이터 전송이 최소화됩니다.
- `--since` 또는 `--max-count`와 같은 로그 옵션이 지정되면 분석기는 필요한 커밋만 가져옵니다.
- 과거 스캔 중에 분석기는 전체 리포지토리 기록을 가져옵니다. 리포지토리가 얕게 복제된 경우 분석기는 `--unshallow` 옵션을 사용합니다.

분석기가 필요한 커밋을 가져올 수 없으면 사용 가능한 데이터 스캔으로 폴백됩니다:

- 강제 푸시 후 분석기는 리포지토리의 현재 상태만 스캔합니다.
- 네트워크 장애가 있으면 분석기는 초기 복제 후 사용 가능한 커밋을 스캔합니다.
- 시간 초과가 있으면 분석기는 부분 커밋 기록으로 스캔을 계속합니다.

이러한 폴백은 제한된 환경에서도 파이프라인이 성공적으로 완료되도록 합니다.

### 초기 리포지토리 복제 깊이 {#initial-repository-clone-depth}

러너의 [`GIT_DEPTH`](../../../../ci/runners/configure_runners.md#shallow-cloning)는 초기에 복제되는 커밋 수를 제어합니다. 파이프라인 비밀 탐지는 필요할 때 추가 커밋을 자동으로 가져오므로 일반적으로 이 설정을 조정할 필요가 없습니다.

제한된 네트워크 환경에서 누락된 커밋으로 인한 지속적인 문제가 발생하면 문제 해결을 참조하여 해결 방법을 확인합니다.

### 과거 스캔 실행 {#run-a-historic-scan}

기본적으로 파이프라인 비밀 탐지는 Git 리포지토리의 현재 상태만 스캔합니다. 리포지토리 기록에 포함된 비밀은 감지되지 않습니다. 과거 스캔을 실행하여 Git 리포지토리의 모든 커밋과 브랜치에서 비밀을 확인합니다.

파이프라인 비밀 탐지를 활성화한 후 한 번만 과거 스캔을 실행해야 합니다. 과거 스캔은 특히 길고 Git 기록이 있는 큰 리포지토리의 경우 오래 걸릴 수 있습니다. 초기 과거 스캔을 완료한 후 파이프라인의 일부로 표준 파이프라인 비밀 탐지만 사용합니다.

[검사 실행 정책](../../policies/scan_execution_policies.md#scanner-behavior)으로 파이프라인 비밀 탐지를 활성화하면 기본적으로 첫 번째 예약된 스캔은 과거 스캔입니다.

과거 스캔을 실행하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. **새 파이프라인**을 선택합니다.
1. CI/CD 변수를 추가합니다:
   1. 드롭다운 목록에서 **변수**를 선택합니다.
   1. **입력 변수 키** 상자에 `SECRET_DETECTION_HISTORIC_SCAN`를 입력합니다.
   1. **입력 변수 값** 상자에 `true`를 입력합니다.
1. **새 파이프라인**을 선택합니다.

### 취약성 추적 중복 {#duplicate-vulnerability-tracking}

{{< details >}}

- 계층: Ultimate
- 제공 서비스:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/434096)되었습니다.

{{< /history >}}

비밀 탐지는 고급 취약성 추적 알고리즘을 사용하여 파일이 리팩터링되거나 이동할 때 중복 발견 항목과 취약성이 생성되지 않도록 합니다.

새로운 발견 항목이 생성되지 않는 경우:

- 비밀이 파일 내에서 이동됩니다.
- 중복 비밀이 파일 내에 나타납니다.

취약성 추적 중복은 파일 기준으로 작동합니다. 동일한 비밀이 두 개의 서로 다른 파일에 나타나면 두 개의 발견 항목이 생성됩니다.

자세한 내용은 기밀 프로젝트 `https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`를 참조하세요. 이 프로젝트는 GitLab 팀 구성원만 사용할 수 있습니다.

#### 지원되지 않는 워크플로우 {#unsupported-workflows}

취약성 추적 중복은 다음 워크플로우를 지원하지 않습니다:

- 기존 발견 항목에 추적 서명이 없고 새로운 발견 항목과 동일한 위치를 공유하지 않습니다.
- 특정 비밀은 전체 비밀 값이 아닌 접두사를 검색하여 감지됩니다. 이러한 비밀 유형의 경우 동일한 유형의 모든 감지 및 동일한 파일은 단일 발견 항목으로 보고됩니다.

  예를 들어 SSH 개인 키는 접두사 `-----BEGIN OPENSSH PRIVATE KEY-----`으로 감지됩니다. 동일한 파일에 여러 SSH 개인 키가 있으면 파이프라인 비밀 탐지는 하나의 발견 항목만 생성합니다.
- 과거 스캔을 실행하거나 기존 커밋에서 파이프라인 비밀 탐지를 활성화할 때 동일한 스캔 중에 한 커밋에서 비밀이 도입되고 나중에 커밋에서 수정되는 경우 가장 최근의 비밀 값만 취약성 보고서에 나타납니다.

### 감지된 비밀 {#detected-secrets}

파이프라인 비밀 탐지는 리포지토리의 콘텐츠에서 특정 패턴을 스캔합니다. 각 패턴은 특정 유형의 비밀과 일치하며 TOML 구문을 사용하여 규칙에서 지정됩니다. GitLab은 기본 규칙 집합을 유지합니다.

GitLab Ultimate를 사용하면 필요에 따라 이러한 규칙을 확장할 수 있습니다. 예를 들어 사용자 정의 접두사를 사용하는 개인 액세스 토큰은 기본적으로 감지되지 않지만 규칙을 사용자 지정하여 이러한 토큰을 식별할 수 있습니다. 자세한 내용은 [분석기 규칙 집합 사용자 지정](configure.md#customize-analyzer-rulesets)을 참조합니다.

파이프라인 비밀 탐지가 감지하는 비밀을 확인하려면 [감지된 비밀](../detected_secrets.md)을 참조합니다. 안정적이고 높은 신뢰도의 결과를 제공하기 위해 파이프라인 비밀 탐지는 URL과 같은 특정 컨텍스트에서만 비밀번호 또는 기타 비정형 비밀을 찾습니다.

비밀이 감지되면 취약성이 생성됩니다. 비밀이 스캔된 파일에서 제거되고 파이프라인 비밀 탐지를 다시 실행한 경우에도 취약성은 "여전히 감지됨"으로 유지됩니다. 이는 누출된 비밀이 취소될 때까지 보안 위험으로 계속 존재하기 때문입니다. 제거된 비밀도 Git 기록에 유지됩니다. Git 리포지토리 기록에서 비밀을 제거하려면 [리포지토리에서 텍스트 제거](../../../project/repository/repository_size.md#redact-text-from-repository)를 참조합니다.

### 제외된 항목 {#excluded-items}

성능을 개선하기 위해 파이프라인 비밀 탐지는 비밀을 포함할 가능성이 낮은 특정 파일 유형 및 디렉터리를 자동으로 제외합니다.

다음 항목이 제외됩니다:

| 카테고리                            | 제외된 항목                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|-------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 구성 파일             | 파일: `gitleaks.toml`, `verification-metadata.xml`, `Database.refactorlog`, `.editorconfig`, `.gitattributes`                                                                                                                                                                                                                                                                                                                                             |
| 미디어 및 바이너리 파일           | 확장: `.bmp`, `.gif`, `.svg`, `.jpg/.jpeg`, `.png`, `.tiff/.tif`, `.webp`, `.ico`, `.heic`<br/>글꼴: `.eot`, `.otf`, `.ttf`, `.woff`, `.woff2`<br/>문서: `.doc/.docx`, `.xls/.xlsx`, `.ppt/.pptx`, `.pdf`<br/>오디오/비디오: `.mp3`, `.mp4`, `.wav`, `.flac`, `.aac`, `.ogg`, `.avi`, `.mkv`, `.mov`, `.wmv`, `.flv`, `.webm`<br/>아카이브: `.zip`, `.rar`, `.7z`, `.tar`, `.gz`, `.bz2`, `.xz`, `.dmg`, `.iso`<br/>실행 파일: `.exe`, `.gltf` |
| Visual Studio 파일             | 확장: `.socket`, `.vsidx`, `.suo`, `.wsuo`, `.dll`, `.pdb`                                                                                                                                                                                                                                                                                                                                                                                           |
| 패키지 잠금 파일              | 파일: `deno.lock`, `npm-shrinkwrap.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Pipfile.lock`, `poetry.lock`, `gradle.lockfile`, `Cargo.lock`, `composer.lock`                                                                                                                                                                                                                                                                             |
| Go 언어 파일               | 확장: `go.mod`, `go.sum`, `go.work`, `go.work.sum`<br/>디렉터리: `vendor/` (다음에서 Go 모듈의 경우만: `github.com`, `golang.org`, `google.golang.org`, `gopkg.in`, `istio.io`, `k8s.io`, `sigs.k8s.io`)<br/>파일: `vendor/modules.txt`                                                                                                                                                                                                            |
| Ruby 파일                      | 디렉터리: `.bundle/`, `gems/`, `specifications/`<br/>확장: `.gem` `gems/` 디렉터리의 파일, `.gemspec` `specifications/` 디렉터리의 파일                                                                                                                                                                                                                                                                                                     |
| 빌드 도구 래퍼             | 파일: `gradlew`, `gradlew.bat`, `mvnw`, `mvnw.cmd`<br/>디렉터리: `.mvn/wrapper/`<br/>특정: `MavenWrapperDownloader.java` in Maven 래퍼 디렉터리                                                                                                                                                                                                                                                                                                |
| 종속성 디렉터리          | 디렉터리: `node_modules/`, `bower_components/`, `packages/`                                                                                                                                                                                                                                                                                                                                                                                             |
| 빌드 출력 디렉터리        | 디렉터리: `target/`, `build/`, `bin/`, `obj/`                                                                                                                                                                                                                                                                                                                                                                                                           |
| 공급업체 디렉터리             | 디렉터리: `vendor/bundle/`, `vendor/ruby/`, `vendor/composer/`                                                                                                                                                                                                                                                                                                                                                                                          |
| Python 캐시 파일              | 확장: `.pyc`, `.pyo`<br/>디렉터리: `__pycache__/`                                                                                                                                                                                                                                                                                                                                                                                                 |
| Python 도구 캐시              | 디렉터리: `.pytest_cache/`, `.mypy_cache/`, `.tox/`                                                                                                                                                                                                                                                                                                                                                                                                     |
| Python 가상 환경     | 디렉터리: `venv/`, `virtualenv/`, `.venv/`, `env/`                                                                                                                                                                                                                                                                                                                                                                                                      |
| Python 설치 디렉터리 | 디렉터리: `lib/python[version]/`, `lib64/python[version]/`, `python[version]/lib/`, `python[version]/Lib/`                                                                                                                                                                                                                                                                                                                                              |
| Python 패키지 메타데이터        | 버전과 `.dist-info`으로 끝나는 패키지 이름                                                                                                                                                                                                                                                                                                                                                                                                         |
| JavaScript 라이브러리            | 파일: `angular*.js`, `bootstrap*.js`, `jquery*.js`, `jquery-ui*.js`, `plotly*.js`, `swagger-ui*.js` <br/>소스 맵: 해당 `.js.map` 파일                                                                                                                                                                                                                                                                                                       |
| 축소/번들된 자산         | 확장: `.min.js`, `.min.css`, `.bundle.js`, `.bundle.css`, `.map` (소스 맵 파일)                                                                                                                                                                                                                                                                                                                                                                  |
| 컴파일된 파일                  | 확장: `.class`, `.o`, `.obj`, `.jar`, `.war` (웹 아카이브), `.ear`                                                                                                                                                                                                                                                                                                                                                                                   |
| 캐시 디렉터리             | 디렉터리: `.cache/`, `.coverage/`, `.pytest_cache/`, `.mypy_cache/`, `.tox/`                                                                                                                                                                                                                                                                                                                                                                            |
| 생성된 설명서         | 디렉터리: `htmlcov/`, `coverage/`, `_build/`, `_site/`, `docs/_build/`                                                                                                                                                                                                                                                                                                                                                                                  |
| 버전 제어 및 IDE           | 디렉터리: `.git/`, `.svn/`, `.hg/`, `.bzr/` (버전 제어), `.vscode/`, `.idea/`, `.eclipse/`, `.vs/` (IDE)                                                                                                                                                                                                                                                                                                                                         |
| 운영 체제 파일          | 파일: `.DS_Store`, `Thumbs.db`                                                                                                                                                                                                                                                                                                                                                                                                                            |

## 비밀 탐지 결과 {#secret-detection-results}

파이프라인 비밀 탐지는 `gl-secret-detection-report.json` 파일을 작업 아티팩트로 출력합니다. 파일에는 감지된 비밀이 포함됩니다. GitLab 외부에서 처리하기 위해 파일을 [다운로드](../../../../ci/jobs/job_artifacts.md#download-job-artifacts)할 수 있습니다.

자세한 내용은 [보고서 파일 스키마](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/secret-detection-report-format.json)와 [예제 보고서 파일](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/qa/expect/secrets/gl-secret-detection-report.json)을 참조합니다.

### 추가 출력 {#additional-output}

{{< details >}}

- 계층: Ultimate

{{< /details >}}

작업 결과는 다음에도 보고됩니다:

- [머지 리퀘스트 보고서](../../../project/merge_requests/reports.md): 머지 리퀘스트에서 도입된 새로운 발견 항목을 표시합니다.
- [파이프라인 보안 보고서](../../detect/security_scanning_results.md): 최신 파이프라인 실행에서 모든 발견 항목을 표시합니다.
- [취약성 보고서](../../vulnerability_report/_index.md): 모든 보안 발견 항목의 중앙 관리를 제공합니다.
- 보안 대시보드: 프로젝트와 그룹 전체의 모든 취약성에 대한 조직 차원의 가시성을 제공합니다.

## 결과 이해 {#understanding-the-results}

파이프라인 비밀 탐지는 리포지토리에서 발견된 잠재적 비밀에 대한 자세한 정보를 제공합니다. 각 비밀에는 누출된 비밀의 유형과 수정 지침이 포함됩니다.

결과를 검토할 때:

1. 주변 코드를 확인하여 감지된 패턴이 실제로 비밀인지 결정합니다.
1. 감지된 값이 작동 자격 증명인지 테스트합니다.
1. 리포지토리의 가시성과 비밀의 범위를 고려합니다.
1. 활성, 높은 권한 비밀부터 시작합니다.

### 일반적인 감지 카테고리 {#common-detection-categories}

파이프라인 비밀 탐지에 의한 감지는 종종 세 가지 카테고리 중 하나로 분류됩니다:

- **True positives**: 회전되고 제거해야 할 정당한 비밀입니다. 예를 들어:
  - 활성 API 키, 데이터베이스 비밀번호, 인증 토큰
  - 개인 키 및 인증서
  - 서비스 계정 자격 증명
- **False positives**: 실제 비밀이 아닌 감지된 패턴입니다. 예를 들어:
  - 설명서의 예제 값
  - 테스트 데이터 또는 모의 자격 증명
  - 자리 표시자 값이 있는 구성 템플릿
- **Historical findings**: 이전에 커밋되었지만 활성화되지 않을 수 있는 비밀입니다. 이러한 감지:
  - 현재 상태를 결정하기 위해 조사가 필요합니다.
  - 예방 조치로 계속 회전해야 합니다.

## 누출된 비밀 수정 {#remediate-a-leaked-secret}

비밀이 감지되면 즉시 회전해야 합니다. GitLab은 누출된 특정 유형의 비밀을 [자동으로 취소](../automatic_response.md)하려고 시도합니다. 자동으로 취소되지 않는 비밀의 경우 수동으로 수행해야 합니다.

[리포지토리 기록에서 비밀을 제거](../../../project/repository/repository_size.md#purge-files-from-repository-history)하는 것은 누출을 완전히 해결하지 못합니다. 원래 비밀은 리포지토리의 기존 포크 또는 복제본에 유지됩니다.

누출된 비밀에 대응하는 방법에 대한 지침을 보려면 취약성 보고서에서 취약성을 선택합니다.

## 최적화 {#optimization}

조직 전체에서 파이프라인 비밀 탐지를 배포하기 전에 구성을 최적화하여 거짓 양성을 줄이고 특정 환경에 대한 정확도를 개선합니다.

거짓 양성은 경보 피로를 만들고 도구에 대한 신뢰를 감소시킬 수 있습니다. 사용자 정의 규칙 집합 구성(Ultimate만 해당)을 사용하는 것을 고려합니다:

- 코드베이스에 특정한 알려진 안전 패턴을 제외합니다.
- 비밀이 아닌 경우 자주 트리거하는 규칙의 민감도를 조정합니다.
- 조직별 비밀 형식에 대한 사용자 정의 규칙을 추가합니다.

대규모 리포지토리 또는 많은 프로젝트가 있는 조직의 성능을 최적화하려면 다음을 검토합니다:

- 스캔 범위 관리:
  - 프로젝트에서 과거 스캔을 실행한 후 과거 스캔을 끕니다.
  - 저사용 기간 동안 과거 스캔을 예약합니다.
- 리소스 할당:
  - 더 큰 리포지토리를 위해 충분한 러너 리소스를 할당합니다.
  - 보안 스캔 워크로드를 위해 전담 러너를 고려합니다.
  - 스캔 기간을 모니터링하고 리포지토리 크기를 기준으로 최적화합니다.

### 최적화 변경 사항 테스트 {#testing-optimization-changes}

조직 차원에서 최적화를 적용하기 전에:

1. 최적화가 정당한 비밀을 놓치지 않는지 확인합니다.
1. 거짓 양성 감소 및 스캔 성능 개선을 추적합니다.
1. 효과적인 최적화 패턴의 기록을 유지합니다.

## 배포 및 확장 {#roll-out}

파이프라인 비밀 탐지를 점진적으로 구현해야 합니다. 조직 전체에서 기능을 배포하기 전에 도구의 동작을 이해하기 위해 소규모 파일럿으로 시작합니다.

파이프라인 비밀 탐지를 배포할 때 다음 지침을 따릅니다:

1. 파일럿 프로젝트를 선택합니다. 적절한 프로젝트에는 다음이 있습니다:
   - 정기적인 커밋을 통한 활성 개발입니다.
   - 관리 가능한 코드베이스 크기입니다.
   - GitLab CI/CD에 익숙한 팀입니다.
   - 구성에서 반복하려는 의지입니다.
1. 간단하게 시작합니다. 파일럿 프로젝트에서 기본 설정으로 파이프라인 비밀 탐지를 활성화합니다.
1. 결과를 모니터링합니다. 일반적인 발견 항목을 이해하기 위해 1~2주 동안 분석기를 실행합니다.
1. 감지된 비밀을 해결합니다. 발견된 정당한 비밀을 모두 수정합니다.
1. 구성을 조정합니다. 초기 결과에 따라 설정을 조정합니다.
1. 구현을 문서화합니다. 일반적인 거짓 양성 및 수정 패턴을 기록합니다.

## FIPS 활성화 이미지 {#fips-enabled-images}

{{< history >}}

- GitLab 14.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/6479)되었습니다.

{{< /history >}}

기본 스캐너 이미지는 크기와 유지 보수를 위해 기본 Alpine 이미지를 기반으로 구축됩니다. GitLab은 FIPS 지원 [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) 버전의 이미지를 제공합니다.

FIPS 지원 이미지를 사용하려면:

- `SECRET_DETECTION_IMAGE_SUFFIX` 변수를 `-fips`로 설정합니다.
- 기본 이미지 이름에 `-fips` 확장자를 추가합니다.

예를 들어:

```yaml
variables:
  SECRET_DETECTION_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml
```

## 문제 해결 {#troubleshooting}

### 디버그 수준 로깅 {#debug-level-logging}

디버그 수준 로깅은 문제 해결에 도움이 될 수 있습니다. 자세한 내용은 [디버그 수준 로깅](../../troubleshooting_application_security.md#turn-on-debug-level-logging)을 참조합니다.

#### 경고: `gl-secret-detection-report.json: no matching files` {#warning-gl-secret-detection-reportjson-no-matching-files}

이에 대한 정보는 [일반 애플리케이션 보안 문제 해결 섹션](../../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload)을 참조합니다.

#### 오류: `Couldn't run the gitleaks command: exit status 2` {#error-couldnt-run-the-gitleaks-command-exit-status-2}

이 오류는 분석기가 필요한 커밋에 액세스할 수 없음을 나타냅니다. 분석기는 대부분의 경우 누락된 커밋을 자동으로 가져오지만 제한된 환경에서 문제가 발생할 수 있습니다.

문제를 진단하려면 [디버그 수준 로깅](../../troubleshooting_application_security.md#turn-on-debug-level-logging)을 활성화하고 다음을 찾습니다:

```plaintext
ERRO[2020-11-18T18:05:52Z] object not found
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Couldn't run the gitleaks command: exit status 2
[ERRO] [secrets] [2020-11-18T18:05:52Z] ▶ Gitleaks analysis failed: exit status 2
```

이 이슈를 해결하려면:

- 대부분의 경우 조치가 필요하지 않습니다. 분석기가 자동으로 가져오도록 합니다.
- 제한된 네트워크의 경우 초기 복제 깊이를 늘립니다:

  ```yaml
  secret_detection:
    variables:
      GIT_DEPTH: 100  # or 0 to clone everything
  ```

- 대규모 리포지토리의 경우 스캔 범위를 제한합니다:

  ```yaml
  secret_detection:
    variables:
      SECRET_DETECTION_LOG_OPTIONS: "--max-count=50"
  ```

#### 오류: `ERR fatal: ambiguous argument` {#error-err-fatal-ambiguous-argument}

파이프라인 비밀 탐지는 `ERR fatal: ambiguous argument` 오류 메시지와 함께 실패할 수 있습니다(리포지토리의 기본 브랜치가 작업이 트리거된 브랜치와 관련이 없는 경우). 자세한 내용은 [!352014](https://gitlab.com/gitlab-org/gitlab/-/issues/352014) 문제를 참조합니다.

문제를 해결하려면 리포지토리에서 [기본 브랜치 설정](../../../project/repository/branches/default.md#change-the-default-branch-name-for-a-project)이 올바른지 확인합니다. `secret-detection` 작업을 실행하는 브랜치와 관련된 기록이 있는 브랜치로 설정해야 합니다.

#### `exec /bin/sh: exec format error` 작업 로그의 메시지 {#exec-binsh-exec-format-error-message-in-job-log}

GitLab 파이프라인 비밀 탐지 분석기는 `amd64` CPU [아키텍처에서만 실행을 지원](#getting-started)합니다. 이 메시지는 작업이 `arm`과 같은 다른 아키텍처에서 실행 중임을 나타냅니다.

#### 오류: `fatal: detected dubious ownership in repository at '/builds/<project dir>'` {#error-fatal-detected-dubious-ownership-in-repository-at-buildsproject-dir}

비밀 탐지는 종료 상태 128으로 실패할 수 있습니다. 이는 Docker 이미지의 사용자 변경으로 인해 발생할 수 있습니다.

예를 들어:

```shell
$ /analyzer run
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ GitLab secrets analyzer v6.0.1
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Detecting project
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Analyzer will attempt to analyze all projects in the repository
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Loading ruleset for /builds....
[WARN] [secrets] [2024-06-06T07:28:13Z] ▶ /builds/....secret-detection-ruleset.toml not found, ruleset support will be disabled.
[INFO] [secrets] [2024-06-06T07:28:13Z] ▶ Running analyzer
[FATA] [secrets] [2024-06-06T07:28:13Z] ▶ get commit count: exit status 128
```

이 문제를 해결하려면 다음과 같이 `before_script`을 추가합니다:

```yaml
before_script:
    - git config --global --add safe.directory "$CI_PROJECT_DIR"
```

이 문제에 대한 자세한 내용은 [이슈 465974](https://gitlab.com/gitlab-org/gitlab/-/issues/465974)를 참조합니다.

#### `GIT_DEPTH` 조정이 스캔되는 항목을 변경하지 않음 {#adjusting-git_depth-doesnt-change-what-gets-scanned}

이것은 예상된 동작입니다. `GIT_DEPTH`은 초기 복제를 위한 러너 변수입니다. 분석기 동작을 변경하지 않습니다.

비밀 탐지 분석기는 다음 항목을 기반으로 스캔할 항목을 결정합니다:

- 파이프라인 유형 (푸시, 머지 리퀘스트, 예약됨)
- 브랜치 컨텍스트 (기본, 새로운, 기존)
- 구성 (`SECRET_DETECTION_LOG_OPTIONS`, `SECRET_DETECTION_HISTORIC_SCAN`)

예를 들어 30개의 커밋만 스캔하려면:

```yaml
secret_detection:
  variables:
    # Scan the last 30 commits
    SECRET_DETECTION_LOG_OPTIONS: "--max-count=30"
```

지난 2주의 커밋만 스캔하려면:

```yaml
secret_detection:
  variables:
    # Scan commits made in the last two weeks
    SECRET_DETECTION_LOG_OPTIONS: "--since=2.weeks"
```

`HEAD~10`에서 `HEAD`까지의 커밋만 스캔하려면:

```yaml
secret_detection:
  variables:
    # Scan commits from HEAD~10 to HEAD
    SECRET_DETECTION_LOG_OPTIONS: "HEAD~10..HEAD"
```

전체 옵션 목록은 [Git 로그 옵션](https://git-scm.com/docs/git-log) 설명서를 참조합니다.

#### 강제 푸시 감지 {#force-push-detection}

강제 푸시 후 다음을 볼 수 있습니다:

```plaintext
Failed to retrieve all the commits from the last Git push event due to a force push
```

이것은 예상된 동작입니다. 스캔은 현재 리포지토리 상태를 사용하여 계속됩니다.

#### 리포지토리 신뢰 구성 {#repository-trust-configuration}

다음 메시지를 볼 수 있습니다:

```plaintext
Added project directory to Git safe.directory configuration
```

이는 컨테이너화된 환경의 일반적인 보안 구성을 나타냅니다. 조치가 필요하지 않습니다.
