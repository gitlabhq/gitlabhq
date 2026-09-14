---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 종속성 검사
description: "종속성, 수정, 구성, 분석기 및 보고서."
---

<style>
table.ds-table tr:nth-child(even) {
    background-color: transparent;
}

table.ds-table td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.ds-table tr td:first-child {
    border-left: 0;
}

table.ds-table tr td:last-child {
    border-right: 0;
}

table.ds-table ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}

table.no-vertical-table-lines td {
    border-left: none;
    border-right: none;
    border-bottom: 1px solid #f0f0f0;
}

table.no-vertical-table-lines tr {
    border-top: none;
}
</style>

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Gemnasium 분석기를 기반으로 하는 기능은 GitLab 17.9에서 더 이상 사용되지 않으며 GitLab 20.0에서 제거될 것으로 예상됩니다. 그러나 제거 일정은 아직 확정되지 않았으며 필요에 따라 계속 Gemnasium을 사용할 수 있습니다. 자세한 내용은 [에픽 15961](https://gitlab.com/groups/gitlab-org/-/epics/15961)을 참조하세요.

는 CI/CD 에 통합되고 애플리케이션의 에서 을 식별하기 위해 자동으로 실행됩니다. 를 병합하기 전에 스캔하면 에서 보안 문제를 즉시 파악할 수 있습니다. 이는 코드를 병합하기 전에 잠재적인 에 대해 정보에 입각한 결정을 내리는 데 도움이 될 수 있습니다.

기본적으로 는 런타임, 개발 및 () 을 포함하여 코드의 모든 을 분석합니다. 선택적으로 스캔에서 개발 을 제외할 수 있습니다.

- <i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [종속성 검사 - Advanced Security Testing](https://www.youtube.com/watch?v=TBnfbGk4c4o)을 참조하세요.<!-- Video published on 2024-04-06 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> 이 설명서의 대화형 읽기 및 방법 데모를 보려면 [종속성 검사 사용 자습서 실습 GitLab Application Security 3부](https://www.youtube.com/watch?v=ii05cMbJ4xQ)를 참조하세요.<!-- Video published on 2023-09-19 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> 다른 대화형 읽기 및 방법 데모를 보려면 [GitLab Application Security 시작하기 재생목록](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)을 참조하세요.<!-- Video published on 2023-09-19 -->

외부의 스캔을 보려면 [지속적 스캔](../../continuous_vulnerability_scanning/_index.md)을 참조하세요.

## 종속성 검사 활성화 {#turn-on-dependency-scanning}

프로젝트에서 를 켜려면 다음 단계를 따르세요.

분석기를 활성화하려면 다음 중 하나를 수행하세요:

- [Auto DevOps](../../../../topics/autodevops/_index.md)를 활성화합니다. 여기에는 가 포함됩니다.
- 사전 구성된 를 사용하세요.
- [검사 실행 정책](../../policies/scan_execution_policies.md)을 만들어 종속성 검사를 강제합니다.
- `.gitlab-ci.yml` 파일을 수동으로 편집합니다.
- [CI/CD 구성 요소 사용](#use-cicd-components)

### 사전 구성된 {#use-a-preconfigured-merge-request}

이 방법은 `.gitlab-ci.yml` 파일에 템플릿을 포함하는 를 자동으로 준비합니다. 그러면 를 병합하여 를 활성화합니다.

> [!note]
> 이 방법은 기존 `.gitlab-ci.yml` 파일이 없거나 최소 구성 파일이 있을 때 가장 잘 작동합니다. GitLab 구성 파일이 복잡하면 올바르게 구문 분석되지 않을 수 있으며 오류가 발생할 수 있습니다. 그 경우 대신 [수동](#edit-the-gitlab-ciyml-file-manually) 방법을 사용하세요.

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.
- `test` 는 `.gitlab-ci.yml` 파일에 필요합니다.
- Self-Managed 러너의 경우, [`docker`](https://docs.gitlab.com/runner/executors/docker/) 또는 [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) 실행기가 있는 러너가 필요합니다.
- GitLab.com의 호스팅 러너에서는 이 구성이 기본적으로 활성화되어 있습니다.

를 켜려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **의존성 스캔** 행에서 **머지 리퀘스트로 설정**을 선택하세요.
1. **머지 리퀘스트 생성**을 선택합니다.
1. 를 검토한 후 **머지**를 선택하세요.

에는 이제 이 포함됩니다.

### `.gitlab-ci.yml` 파일을 수동으로 편집 {#edit-the-gitlab-ciyml-file-manually}

이 방법은 기존 `.gitlab-ci.yml` 파일을 수동으로 편집해야 합니다. GitLab CI/CD 구성 파일이 복잡한 경우 이 방법을 사용하세요.

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.
- `test` 는 `.gitlab-ci.yml` 파일에 필요합니다.
- Self-Managed 러너의 경우, [`docker`](https://docs.gitlab.com/runner/executors/docker/) 또는 [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) 실행기가 있는 러너가 필요합니다.
- GitLab.com의 호스팅 러너에서는 이 구성이 기본적으로 활성화되어 있습니다.

를 켜려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 편집기**를 선택합니다.
1. `.gitlab-ci.yml` 파일이 없으면 **Configure pipeline**을 선택한 후 예제 콘텐츠를 삭제하세요.
1. 다음을 복사하여 `.gitlab-ci.yml` 파일의 하단에 붙여넣으세요. `include` 줄이 이미 있으면 아래에 `template` 줄만 추가하세요.

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.gitlab-ci.yml
   ```

1. **검증** 탭을 선택한 후 **파이프라인 검증**을 선택합니다.

   **시뮬레이션이 성공적으로 완료되었습니다** 메시지는 파일이 유효함을 확인합니다.
1. **편집** 탭을 선택합니다.
1. 필드를 완성하세요. **브랜치** 필드에 기본 브랜치를 사용하지 마세요.
1. **이 변경 사항으로 새로운 머지 리퀘스트 시작** 확인란을 선택한 후 **변경 사항 커밋**을 선택합니다.
1. 표준 워크플로에 따라 필드를 완성한 후 **머지 리퀘스트 생성**을 선택합니다.
1. 표준 워크플로에 따라 머지 리퀘스트를 검토하고 편집한 후 **머지**를 선택합니다.

에는 이제 이 포함됩니다.

### CI/CD 구성 요소 사용 {#use-cicd-components}

> [!note]
> 종속성 검사 CI/CD 구성 요소는 Android 프로젝트만 지원합니다.

[CI/CD 구성 요소](../../../../ci/components/_index.md)를 사용하여 애플리케이션의 종속성 검사를 수행하세요. 지침은 각 의 README 파일을 참조하세요.

#### 사용 가능한 {#available-cicd-components}

<https://gitlab.com/explore/catalog/components/dependency-scanning> 참조

이 단계를 완료한 후 다음을 수행할 수 있습니다:

- [결과 이해](#understanding-the-results) 방법에 대해 자세히 알아보세요.
- 더 많은 프로젝트로 [확대](#roll-out)할 계획을 세우세요.

## 결과 이해 {#understanding-the-results}

결과는 여러 형식으로 사용할 수 있습니다. UI, 상세한 스캔 보고서 또는 스캔 중에 생성된 소프트웨어 Bill of Materials(SBOM)에서 직접 확인하세요.

### 에서 검토 {#review-vulnerabilities-in-the-pipeline}

에서 감지된 을 검토하고 가 병합되기 전에 조치를 취하세요.

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

에서 결과를 검토하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 파이프라인을 선택합니다.
1. **보안** 탭을 선택합니다.
1. 을 선택하여 다음을 포함한 세부 정보를 확인하세요:
   - 상태:  취약성이 심사되었는지 또는 해결되었는지 여부를 나타냅니다.
   - 설명:  취약성의 원인, 잠재적 영향 및 권장 수정 단계를 설명합니다.
   - 심각도:  영향에 따라 6가지 수준으로 분류됩니다. [심각도 수준에 대해 자세히 알아보기](../../vulnerabilities/severities.md).
   - CVSS : 에 매핑되는 숫자 값을 제공합니다.
   - EPSS: 실제로 이 악용될 가능성을 보여줍니다.
   - 알려진 익스플로잇(KEV) 있음: 주어진 이 악용되었음을 나타냅니다.
   - 프로젝트: 이 식별된 를 강조합니다.
   - 보고서 유형 / 스캐너: 출력 유형과 출력을 생성하는 데 사용되는 스캐너를 설명합니다.
   - 도달 가능: 취약한 이 코드에 사용되는지 여부를 나타냅니다.
   - 스캐너:  취약성을 감지한 분석기를 식별합니다.
   - 위치:  취약한 이 있는 파일의 이름을 지정합니다.
   - 링크: 이 다양한 권고 데이터베이스에 분류된 증거입니다.
   - 식별자:  CVE 식별자와 같은 을 분류하는 데 사용되는 참조 목록입니다.

### 종속성 검사 보고서 {#dependency-scanning-report}

는 모든 의 세부 정보를 포함하는 보고서를 출력합니다. 보고서는 내부적으로 처리되고 결과는 UI에 표시됩니다. 보고서는 또한 의 아티팩트로 출력되며 `gl-dependency-scanning-report.json`이라고 명명되며 항상 의 루트에서 생성됩니다.

보고서에 대한 자세한 내용은 [보고서 스키마](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/dependency-scanning-report-format.json)를 참조하세요.

### CycloneDX 소프트웨어 BOM(SBOM) {#cyclonedx-software-bill-of-materials}

는 감지하는 각 지원 잠금 파일 또는 빌드 파일에 대해 [CycloneDX](https://cyclonedx.org/) 소프트웨어 Bill of Materials(SBOM)를 출력합니다.

CycloneDX SBOM:

- 이름: `gl-sbom-<package-type>-<package-manager>.cdx.json`
- 종속성 검사 작업의 작업 아티팩트로 제공됩니다.
- 감지된 잠금 파일 또는 빌드 파일과 동일한 디렉토리에 저장됩니다.

예를 들어, 프로젝트 구조가 다음과 같은 경우:

```plaintext
.
├── ruby-project/
│   └── Gemfile.lock
├── ruby-project-2/
│   └── Gemfile.lock
├── php-project/
│   └── composer.lock
└── go-project/
    └── go.sum
```

그러면 Gemnasium 는 다음 CycloneDX SBOM을 생성합니다:

```plaintext
.
├── ruby-project/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── ruby-project-2/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── php-project/
│   ├── composer.lock
│   └── gl-sbom-packagist-composer.cdx.json
└── go-project/
    ├── go.sum
    └── gl-sbom-go-go.cdx.json
```

## 배포 및 확장 {#roll-out}

단일 에 대한 결과에 확신이 있으면 추가 로 구현을 확장할 수 있습니다:

- 에서 설정을 적용하려면 [실행 스캔 실행](../../detect/security_configuration.md#create-a-shared-configuration)을 사용하세요.
- 특수한 요구 사항이 있는 경우, [오프라인 환경](../../offline_deployments/_index.md)에서 SBOM 기반 종속성 검사를 실행할 수 있습니다.

## 지원되는 언어 및 패키지 관리자 {#supported-languages-and-package-managers}

> [!note]
> 는 컴파일러 및 인터프리터의 런타임 설치를 지원하지 않습니다.

다음 언어 및 관리자는 에서 지원됩니다:

<!-- markdownlint-disable MD044 -->
<table class="ds-table">
  <thead>
    <tr>
      <th>언어</th>
      <th>언어 버전</th>
      <th>패키지 관리자</th>
      <th>지원되는 파일</th>
      <th><a href="#how-multiple-files-are-processed">여러 파일을 처리하나요?</a></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>.NET</td>
      <td rowspan="2">모든 버전</td>
      <td rowspan="2"><a href="https://www.nuget.org/">NuGet</a></td>
      <td rowspan="2"><a href="https://learn.microsoft.com/en-us/nuget/consume-packages/package-references-in-project-files#enabling-lock-file"><code>packages.lock.json</code></a></td>
      <td rowspan="2">Y</td>
    </tr>
    <tr>
      <td>C#</td>
    </tr>
    <tr>
      <td>C</td>
      <td rowspan="2">모든 버전</td>
      <td rowspan="2"><a href="https://conan.io/">Conan</a></td>
      <td rowspan="2"><a href="https://docs.conan.io/en/latest/versioning/lockfiles.html"><code>conan.lock</code></a></td>
      <td rowspan="2">Y</td>
    </tr>
    <tr>
      <td>C++</td>
    </tr>
    <tr>
      <td>Go</td>
      <td>모든 버전</td>
      <td><a href="https://go.dev/">Go</a></td>
      <td>
        <ul>
          <li><code>go.sum</code></li>
        </ul>
      </td>
      <td>Y</td>
    </tr>
    <tr>
      <td rowspan="2">Java 및 Kotlin</td>
      <td rowspan="2">
        8 LTS, 11 LTS, 17 LTS 또는 21 LTS<sup>1</sup>
      </td>
      <td><a href="https://gradle.org/">Gradle</a><sup>2</sup></td>
      <td>
        <ul>
            <li><code>build.gradle</code></li>
            <li><code>build.gradle.kts</code></li>
        </ul>
      </td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a><sup>6</sup></td>
      <td><code>pom.xml</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td rowspan="3">JavaScript 및 TypeScript</td>
      <td rowspan="3">모든 버전</td>
      <td><a href="https://www.npmjs.com/">npm</a></td>
      <td>
        <ul>
            <li><code>package-lock.json</code></li>
            <li><code>npm-shrinkwrap.json</code></li>
        </ul>
      </td>
      <td>Y</td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en/">yarn</a></td>
      <td><code>yarn.lock</code></td>
      <td>Y</td>
    </tr>
    <tr>
      <td><a href="https://pnpm.io/">pnpm</a><sup>3</sup></td>
      <td><code>pnpm-lock.yaml</code></td>
      <td>Y</td>
    </tr>
    <tr>
      <td>PHP</td>
      <td>모든 버전</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
      <td><code>composer.lock</code></td>
      <td>Y</td>
    </tr>
    <tr>
      <td rowspan="5">Python</td>
      <td rowspan="5">3.11<sup>7</sup></td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a><sup>8</sup></td>
      <td><code>setup.py</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
      <td>
        <ul>
            <li><code>requirements.txt</code></li>
            <li><code>requirements.pip</code></li>
            <li><code>requires.txt</code></li>
        </ul>
      </td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
      <td>
        <ul>
            <li><a href="https://pipenv.pypa.io/en/latest/pipfile.html#example-pipfile"><code>Pipfile</code></a></li>
            <li><a href="https://pipenv.pypa.io/en/latest/pipfile.html#example-pipfile-lock"><code>Pipfile.lock</code></a></li>
        </ul>
      </td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a><sup>4</sup></td>
      <td><code>poetry.lock</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td><a href="https://docs.astral.sh/uv/">uv</a><sup>11</sup></td>
      <td><code>uv.lock</code></td>
      <td>Y</td>
    </tr>
    <tr>
      <td>Ruby</td>
      <td>모든 버전</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
      <td>
        <ul>
            <li><code>Gemfile.lock</code></li>
            <li><code>gems.locked</code></li>
        </ul>
      </td>
      <td>Y</td>
    </tr>
    <tr>
      <td>Scala</td>
      <td>모든 버전</td>
      <td><a href="https://www.scala-sbt.org/">sbt</a><sup>5</sup></td>
      <td><code>build.sbt</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td>Swift</td>
      <td>모든 버전</td>
      <td><a href="https://swift.org/package-manager/">Swift Package Manager</a></td>
      <td><code>Package.resolved</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td>CocoaPods<sup>9</sup></td>
      <td>모든 버전</td>
      <td><a href="https://cocoapods.org/">CocoaPods</a></td>
      <td><code>Podfile.lock</code></td>
      <td>N</td>
    </tr>
    <tr>
      <td>Dart<sup>10</sup></td>
      <td>모든 버전</td>
      <td><a href="https://pub.dev/">Pub</a></td>
      <td><code>pubspec.lock</code></td>
      <td>N</td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-disable MD029 -->

**각주**:

1. [sbt](https://www.scala-sbt.org/)에 대한 Java 21 LTS는 버전 1.9.7로 제한됩니다. 더 많은 sbt 버전에 대한 지원은 [430335](https://gitlab.com/gitlab-org/gitlab/-/issues/430335)에서 추적할 수 있습니다. FIPS 모드가 활성화된 경우 지원되지 않습니다.
2. FIPS 모드가 활성화된 경우 Gradle은 지원되지 않습니다.
3. pnpm 잠금 파일은 번들 을 저장하지 않으므로 보고된 이 npm 또는 yarn과 다를 수 있습니다.
4. `poetry.lock` 파일 없이 프로젝트에 대한 지원은 [32774](https://gitlab.com/gitlab-org/gitlab/-/issues/32774)에서 추적됩니다.
5. sbt 1.0.x에 대한 지원은 GitLab 16.8에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/415835)으로 표시되었으며 GitLab 17.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/436985)되었습니다.
6. 3.8.8 이하의 Maven에 대한 지원은 GitLab 16.9에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/438772)으로 표시되었으며 GitLab 17.0에서 제거되었습니다.
7. 이전 Python 버전에 대한 지원은 GitLab 16.9에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/441201)으로 표시되었으며 GitLab 17.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/441491)되었습니다.
8. `pip`과 `setuptools` 모두 설치 관리자가 필요하므로 보고서에서 제외됩니다.
9. 권고 없이 SBOM만 해당합니다. [468764](https://gitlab.com/gitlab-org/gitlab/-/issues/468764)를 참조하세요.
10. 라이센스 감지 없음. [17037](https://gitlab.com/groups/gitlab-org/-/epics/17037)를 참조하세요.
11. 잠금 파일에 환경 마커가 다른 동일 패키지 항목이 여러 개 포함된 경우(예: Python <3.11에 대해 numpy==2.2.6, Python ≥3.11에 대해 numpy==2.4.1), 첫 번째 항목만 구문 분석되어 보고됩니다.

<!-- markdownlint-enable MD029 -->
<!-- markdownlint-enable MD044 -->

## 지원되는 개발 {#supported-development-dependencies}

다음 언어 및 패키지 관리자에 대해 개발 감지가 지원됩니다:

<!-- vale gitlab_base.Substitutions = NO -->
<!-- markdownlint-disable MD044 -->

| 언어                  | 패키지 관리자 | 파일 |
|---------------------------|-----------------|-------|
| C/C++/Fortran/Go/Python/R | conda           | `conda-lock.yml` |
| Java                      | Maven           | `maven.graph.json` |
| Java/Kotlin               | Gradle          | `dependencies.lock`, `dependencies.direct.lock`, `gradle-html-dependency-report.js`, `gradle.lockfile` |
| JavaScript/TypeScript     | npm             | `package-lock.json`, `npm-shrinkwrap.json` |
| JavaScript/TypeScript     | pnpm            | `pnpm-lock.yaml` |
| PHP                       | Composer        | `composer.lock` |
| Python                    | Pipenv          | `Pipfile.lock` |
| Python                    | Poetry          | `poetry.lock` |
| Python                    | uv              | `uv.lock` |

<!-- markdownlint-enable MD044 -->
<!-- vale gitlab_base.Substitutions = YES -->

## 에서 실행 {#running-jobs-in-merge-request-pipelines}

[에서 보안 스캔 도구 사용](../../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines) 참조

## 분석기 동작 사용자 정의 {#customizing-analyzer-behavior}

종속성 검사를 사용자 정의하려면 [CI/CD 변수](#available-cicd-variables)를 사용하세요.

> [!warning]
> GitLab 분석기에 대한 모든 사용자 정의 설정은 기본 브랜치에 병합하기 전에 머지 리퀘스트에서 먼저 테스트하세요. 테스트를 거치지 않으면 수많은 거짓 양성을 포함하여 예상치 못한 결과가 발생할 수 있습니다.

### 무시 {#overriding-dependency-scanning-jobs}

정의를 무시하려면 (예: `variables` 또는 `dependencies`와 같은 속성을 변경하려면) 무시할 항목과 동일한 이름의 새 을 선언하세요. 템플릿 포함 선언 뒤에 이 새 작업을 배치하고 그 아래에 추가 키를 지정합니다.

예를 들어 이는 `gemnasium` 분석기에 대해 취약한 의 자동 을 비활성화합니다:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  variables:
    DS_REMEDIATE: "false"
```

`dependencies: []` 속성을 무시하려면 앞서 설명한 대로 무시 을 추가하고 이 속성을 대상으로 지정하세요:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  dependencies: ["build"]
```

### 사용 가능한 CI/CD 변수 {#available-cicd-variables}

를 사용하여 [사용자 정의](#customizing-analyzer-behavior) 동작을 수행할 수 있습니다.

#### 글로벌 분석기 설정 {#global-analyzer-settings}

다음 는 글로벌 설정의 구성을 허용합니다.

| CI/CD 변수             | 설명 |
| ----------------------------|------------ |
| `ADDITIONAL_CA_CERT_BUNDLE` | 신뢰할 CA 인증서 번들입니다. 여기에 제공된 인증서 번들은 `git`, `yarn` 또는 `npm`과 같은 스캔 프로세스 중에 다른 도구에서도 사용됩니다. 자세한 내용은 [사용자 정의 TLS 인증 기관(CA)](#custom-tls-certificate-authority)을 참조하세요. |
| `DS_EXCLUDED_ANALYZERS`     | 종속성 검사에서 제외할 분석기(이름별)를 지정합니다. 자세한 내용은 [분석기](#analyzers)를 참조하세요. |
| `DS_EXCLUDED_PATHS`         | 경로를 기반으로 스캔에서 파일 및 디렉터리를 제외합니다. 쉼표로 구분된 패턴 목록입니다. 패턴은 글로브(지원되는 패턴은 [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) 참조)이거나 파일 또는 폴더 경로(예: `doc,spec`)일 수 있습니다. 부모 디렉터리도 패턴과 일치합니다. 이는 스캔이 실행되기 전에 적용되는 사전 필터입니다. 기본값: `"spec, test, tests, tmp"`. |
| `DS_IMAGE_SUFFIX`           | 이미지 이름에 추가된 접미사. (GitLab 팀 구성원은 이 기밀 에서 더 많은 정보를 볼 수 있습니다: `https://gitlab.com/gitlab-org/gitlab/-/issues/354796`). FIPS 모드가 활성화되면 자동으로 `"-fips"`로 설정됩니다. |
| `DS_MAX_DEPTH`              | 분석기가 스캔할 지원되는 파일을 검색할 디렉터리 깊이 수준을 정의합니다. 값이 `-1`이면 깊이에 관계없이 모든 디렉터리를 스캔합니다 기본값: `2`. |
| `SECURE_ANALYZERS_PREFIX`   | 공식 기본 이미지(프록시)를 제공하는 Docker 레지스트리 이름을 재정의합니다. |

#### 분석기별 설정 {#analyzer-specific-settings}

다음 는 특정 분석기의 동작을 구성합니다.

| CI/CD 변수                       | 분석기           | 기본값                      | 설명 |
|--------------------------------------|--------------------|------------------------------|-------------|
| `GEMNASIUM_DB_LOCAL_PATH`            | `gemnasium`        | `/gemnasium-db`              | 로컬 Gemnasium 데이터베이스에 대한 경로입니다. |
| `GEMNASIUM_DB_UPDATE_DISABLED`       | `gemnasium`        | `"false"`                    | `gemnasium-db` 권고 데이터베이스에 대한 자동 업데이트를 비활성화합니다. 사용 방법은 [GitLab 권고 데이터베이스 접근](#access-to-the-gitlab-advisory-database)을 참조하세요. |
| `GEMNASIUM_DB_REMOTE_URL`            | `gemnasium`        | `https://gitlab.com/gitlab-org/security-products/gemnasium-db.git` | GitLab 권고 데이터베이스를 가져오기 위한 URL입니다. |
| `GEMNASIUM_DB_REF_NAME`              | `gemnasium`        | `master`                     | 원격 데이터베이스의 이름입니다. `GEMNASIUM_DB_REMOTE_URL`이 필요합니다. |
| `GEMNASIUM_IGNORED_SCOPES`           | `gemnasium`        |                              | 무시할 Maven 의 쉼표로 구분된 목록입니다. 자세한 내용은 [Maven 설명서](https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Scope)를 참조하세요. |
| `DS_REMEDIATE`                       | `gemnasium`        | `"true"`, FIPS 모드에서는 `"false"` | 취약한 의 자동 을 활성화합니다. FIPS 모드에서는 지원되지 않습니다. |
| `DS_REMEDIATE_TIMEOUT`               | `gemnasium`        | `5m`                         | 자동 타임아웃입니다. |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED`     | `gemnasium`        | `"true"`                     | 공급된 JavaScript (패키지 관리자에서 관리하지 않는 )에서 을 감지할 수 있도록 합니다. 이 기능을 사용하려면 JavaScript 잠금 파일이 에 있어야 하며, 그렇지 않으면 가 실행되지 않고 공급된 파일이 스캔되지 않습니다.<br>는 [Retire.js](https://github.com/RetireJS/retire.js) 를 사용하여 제한된 집합을 감지합니다. 감지되는 에 대한 세부 정보는 [Retire.js](https://github.com/RetireJS/retire.js/blob/master/repository/jsrepository.json)를 참조하세요. |
| `DS_INCLUDE_DEV_DEPENDENCIES`        | `gemnasium`        | `"true"`                     | `"false"`로 설정하면 개발 및 해당 이 보고되지 않습니다. Composer, Maven, npm, pnpm, Pipenv 또는 Poetry를 사용하는 만 지원됩니다. |
| `GOOS`                               | `gemnasium`        | `"linux"`                    | Go 코드를 컴파일할 운영 체제입니다. |
| `GOARCH`                             | `gemnasium`        | `"amd64"`                    | Go 코드를 컴파일할 프로세서의 아키텍처입니다. |
| `GOFLAGS`                            | `gemnasium`        |                              | `go build` 도구에 전달되는 입니다. |
| `GOPRIVATE`                          | `gemnasium`        |                              | 소스에서 가져올 및 의 목록입니다. 자세한 내용은 Go [설명서](https://go.dev/ref/mod#private-modules)를 참조하세요. |
| `DS_JAVA_VERSION`                    | `gemnasium-maven`  | `17`                         | Java의 버전입니다. 사용 가능한 버전: `8`, `11`, `17`, `21`. |
| `MAVEN_CLI_OPTS`                     | `gemnasium-maven`  | `"-DskipTests --batch-mode"` | 분석기에서 `maven`에 전달되는 명령줄 인수의 목록입니다. [사용](#authenticate-with-a-private-maven-repository)의 예를 참조하세요. |
| `GRADLE_CLI_OPTS`                    | `gemnasium-maven`  |                              | 분석기에서 `gradle`에 전달되는 명령줄 인수의 목록입니다. |
| `GRADLE_PLUGIN_INIT_PATH`            | `gemnasium-maven`  | `"gemnasium-init.gradle"`    | Gradle 초기화 스크립트의 경로를 지정합니다. 초기화 스크립트는 호환성을 보장하기 위해 `allprojects { apply plugin: 'project-report' }`을 포함해야 합니다. |
| `DS_GRADLE_RESOLUTION_POLICY`        | `gemnasium-maven`  | `"failed"`                   | Gradle 해결 엄격함을 제어합니다. `"none"`을 허용하여 부분 결과를 허용하거나 `"failed"`을 받아 해결 실패 시 스캔을 실패하게 합니다. |
| `SBT_CLI_OPTS`                       | `gemnasium-maven`  |                              | 분석기가 `sbt`에 전달하는 명령줄 인수의 목록입니다. |
| `PIP_INDEX_URL`                      | `gemnasium-python` | `https://pypi.org/simple`    | Python Package Index의 기본 URL입니다. |
| `PIP_EXTRA_INDEX_URL`                | `gemnasium-python` |                              | `PIP_INDEX_URL`에 추가로 사용할 패키지 인덱스의 [추가 URL](https://pip.pypa.io/en/stable/reference/pip_install/#cmdoption-extra-index-url) 배열입니다. 쉼표로 구분합니다. **경고**: 이 환경 를 사용할 때 [다음 보안 고려 사항](#python-projects)을 읽으세요. |
| `PIP_REQUIREMENTS_FILE`              | `gemnasium-python` |                              | 스캔할 Pip 요구 사항 파일입니다. 이것은 경로가 아닌 파일 이름입니다. 이 환경 가 설정되면 지정된 파일만 스캔됩니다. |
| `PIPENV_PYPI_MIRROR`                 | `gemnasium-python` |                              | 설정하면 Pipenv에서 사용하는 PyPi 인덱스를 [미러](https://github.com/pypa/pipenv/blob/v2022.1.8/pipenv/environments.py#L263)로 재정의합니다. |
| `DS_PIP_VERSION`                     | `gemnasium-python` |                              | 특정 pip 버전 설치를 강제로 수행합니다 (예: `"19.3"`). 그렇지 않으면 Docker 이미지에 설치된 pip가 사용됩니다. |
| `DS_PIP_DEPENDENCY_PATH`             | `gemnasium-python` |                              | Python pip 을 로드할 경로입니다. |

#### 기타 {#other-variables}

이전 표는 사용할 수 있는 모든 의 완전한 목록이 아닙니다. 지원되고 테스트된 모든 특정 GitLab 및 분석기 를 포함합니다. 환경 같은 많은 다른 를 전달하고 올바르게 작동할 수 있습니다. 이 목록은 크고 완전히 문서화되지 않았습니다.

예를 들어 비 GitLab 환경 변수 `HTTPS_PROXY`을 모든 종속성 검사 작업에 전달하려면 [`.gitlab-ci.yml` 파일의 CI/CD 변수](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)로 설정하세요. 다음과 같이:

```yaml
variables:
  HTTPS_PROXY: "https://squid-proxy:3128"
```

> [!note]
> Gradle 는 프록시를 사용하려면 [추가 변수](#use-a-proxy-with-gradle-projects) 설정이 필요합니다.

또는 와 같은 특정 에서 사용할 수 있습니다:

```yaml
dependency_scanning:
  variables:
    HTTPS_PROXY: $HTTPS_PROXY
```

모든 가 테스트되지 않았으므로 일부는 작동하고 다른 것은 작동하지 않을 수 있습니다. 작동하지 않는 것이 필요한 경우 [기능 요청 제출](https://gitlab.com/gitlab-org/gitlab/-/issues/new?description_template=Feature%20proposal%20-%20detailed&issue[title]=Docs%20feedback%20-%20feature%20proposal:%20Write%20your%20title)하거나 코드에 기여하여 사용하도록 설정하세요.

### 사용자 정의 TLS 인증 기관(CA) {#custom-tls-certificate-authority}

종속성 검사 시 분석기 컨테이너 이미지와 함께 제공되는 기본값 대신 사용자 정의 TLS 인증서를 SSL/TLS 연결에 사용할 수 있습니다.

사용자 정의 인증서 에 대한 지원은 다음 버전에 도입되었습니다.

| 분석기           | 버전                                                                                                |
|--------------------|--------------------------------------------------------------------------------------------------------|
| `gemnasium`        | [v2.8.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/releases/v2.8.0)        |
| `gemnasium-maven`  | [v2.9.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven/-/releases/v2.9.0)  |
| `gemnasium-python` | [v2.7.0](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python/-/releases/v2.7.0) |

#### 사용자 정의 TLS 사용 {#use-a-custom-tls-certificate-authority}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

사용자 정의 TLS 을 사용하려면:

- [X.509 PEM 공개 키 인증서의 텍스트 표현](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)을 `ADDITIONAL_CA_CERT_BUNDLE`에 할당하세요.

예를 들어 `.gitlab-ci.yml` 파일에서 인증서를 구성하려면:

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

### Maven 로 인증 {#authenticate-with-a-private-maven-repository}

종속성 검사 분석기가 비공개 Maven 리포지토리로 인증할 수 있도록 하려면 CI/CD 파이프라인에서 자격 증명을 구성해야 합니다. 인증 없이는 분석기가 에 접근할 수 없으며 스캔이 실패합니다.

> [!warning]
> `.gitlab-ci.yml` 파일에 자격 증명을 추가하지 마세요.

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

분석기가 Maven 로 인증할 수 있도록 하려면:

1. [프로젝트 CI/CD 변수 생성](../../../../ci/variables/_index.md#for-a-project). 이름은 `MAVEN_CLI_OPTS`이고 자격 증명을 포함하도록 값을 설정하세요.

   예를 들어 `mysettings.xml` 설정 파일, `myuser` 사용자 이름 및 `verysecret` 암호가 있다고 가정하면 다음과 같이 `MAVEN_CLI_OPTS` 를 설정합니다:

   `--settings mysettings.xml -Drepository.password=verysecret -Drepository.user=myuser`
1. `mysettings.xml` Maven 설정 파일을 구성을 사용하여 만듭니다. 파일 이름은 1단계에서 `--settings` 옵션에 지정한 값과 일치해야 합니다.

   ```xml
   <!-- mysettings.xml -->
   <settings>
       ...
       <servers>
           <server>
               <id>private_server</id>
               <username>${repository.user}</username>
               <password>${repository.password}</password>
           </server>
       </servers>
   </settings>
   ```

### FIPS 활성화 이미지 {#fips-enabled-images}

GitLab은 또한 Gemnasium 이미지의 [FIPS 지원 Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) 버전을 제공합니다. GitLab 에서 FIPS 모드가 활성화되면 Gemnasium 스캔 은 자동으로 FIPS 지원 이미지를 사용합니다. FIPS 지원 이미지로 수동으로 전환하려면 `DS_IMAGE_SUFFIX`을 `"-fips"`으로 설정하세요.

Gradle 에 대한 및 Yarn 에 대한 자동 은 FIPS 모드에서 지원되지 않습니다.

FIPS 지원 이미지는 RedHat의 UBI 마이크로를 기반으로 합니다. `dnf` 또는 `microdnf`와 같은 패키지 관리자가 없으므로 런타임에 를 설치할 수 없습니다.

### 오프라인 환경 {#offline-environment}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

제한된, 제한된 또는 간헐적인 인터넷 외부 리소스 액세스 환경의 의 경우 이 성공적으로 실행되도록 일부 조정이 필요합니다. 자세한 내용은 [오프라인 환경](../../offline_deployments/_index.md)을(를) 참조하세요.

전제 조건:

- 관리자 액세스 권한.
- `docker` 또는 `kubernetes` 를 가진 GitLab 
- 분석기 이미지의 로컬 
- [GitLab 권고 데이터베이스](https://gitlab.com/gitlab-org/security-products/gemnasium-db)에 대한 액세스
- [패키지 메타데이터 데이터베이스](../../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)에 대한 액세스

#### 분석기 이미지의 로컬 사본 {#local-copies-of-analyzer-images}

모든 [지원되는 언어 및 프레임워크](#supported-languages-and-package-managers)에 를 사용하려면:

1. `registry.gitlab.com`에서 다음 기본 분석기 이미지를 [Docker](../../../packages/container_registry/_index.md)로 가져오세요:

   ```plaintext
   registry.gitlab.com/security-products/gemnasium:6
   registry.gitlab.com/security-products/gemnasium:6-fips
   registry.gitlab.com/security-products/gemnasium-maven:6
   registry.gitlab.com/security-products/gemnasium-maven:6-fips
   registry.gitlab.com/security-products/gemnasium-python:6
   registry.gitlab.com/security-products/gemnasium-python:6-fips
   ```

   Docker 이미지를 로컬 오프라인 Docker 레지스트리로 가져오는 프로세스는 **네트워크 보안 정책**에 따라 다릅니다. 외부 리소스를 가져오거나 일시적으로 액세스할 수 있는 승인된 프로세스에 대해서는 IT 담당자에게 문의하세요. 이 는 [정기적으로 업데이트](../../detect/vulnerability_scanner_maintenance.md)되며 정기적으로 다운로드할 수 있습니다.
1. 로컬 분석기를 사용하도록 GitLab CI/CD를 구성합니다.

   CI/CD 변수 `SECURE_ANALYZERS_PREFIX`의 값을 로컬 Docker 레지스트리로 설정하세요. 이 예에서는 `docker-registry.example.com`입니다.

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "docker-registry.example.com/analyzers"
   ```

#### GitLab 권고 데이터베이스에 접근 {#access-to-the-gitlab-advisory-database}

[GitLab 권고 데이터베이스](https://gitlab.com/gitlab-org/security-products/gemnasium-db)는 `gemnasium`, `gemnasium-maven` 및 `gemnasium-python` 분석기에서 사용하는 데이터의 입니다. 이 분석기의 Docker 이미지에는 데이터베이스의 이 포함되어 있습니다. 은 스캔을 시작하기 전에 데이터베이스와 동기화되어 분석기가 최신 데이터를 가지도록 합니다.

환경에서 GitLab 권고 데이터베이스의 기본 에 액세스할 수 없습니다. 대신 GitLab 에서 접근할 수 있는 곳에 데이터베이스를 해야 합니다. 또한 사용자 고유의 에 따라 데이터베이스를 수동으로 업데이트해야 합니다.

데이터베이스를 하기 위한 사용 가능한 옵션은 다음과 같습니다:

- [GitLab 권고 데이터베이스의 사용](#use-a-copy-of-the-gitlab-advisory-database).
- [GitLab 권고 데이터베이스의 사용](#use-a-copy-of-the-gitlab-advisory-database).

##### GitLab 권고 데이터베이스의 사용 {#use-a-clone-of-the-gitlab-advisory-database}

GitLab 권고 데이터베이스의 을 사용하는 것이 가장 효율적인 방법이므로 권장됩니다.

GitLab 권고 데이터베이스의 을 하려면:

1. GitLab 에서 HTTP로 액세스할 수 있는 에 GitLab 권고 데이터베이스를 하세요.
1. `.gitlab-ci.yml` 파일에서 CI/CD 변수 `GEMNASIUM_DB_REMOTE_URL`의 값을 Git 리포지토리의 URL로 설정하세요.

예를 들어:

```yaml
variables:
  GEMNASIUM_DB_REMOTE_URL: https://users-own-copy.example.com/gemnasium-db.git
```

##### GitLab 권고 데이터베이스의 사용 {#use-a-copy-of-the-gitlab-advisory-database}

GitLab 권고 데이터베이스의 을 사용하려면 분석기가 다운로드하는 파일을 해야 합니다.

GitLab 권고 데이터베이스의 을 사용하려면:

1. GitLab 에서 HTTP로 액세스할 수 있는 에 GitLab 권고 데이터베이스의 를 다운로드하세요. 는 `https://gitlab.com/gitlab-org/security-products/gemnasium-db/-/archive/master/gemnasium-db-master.tar.gz`에 있습니다.
1. `.gitlab-ci.yml` 파일을 업데이트하세요.

   - CI/CD 변수 `GEMNASIUM_DB_LOCAL_PATH`을 데이터베이스의 로컬 사본을 사용하도록 설정하세요.
   - `GEMNASIUM_DB_UPDATE_DISABLED`을 데이터베이스 업데이트를 비활성화하도록 설정하세요.
   - 스캔 시작 전에 권고 데이터베이스를 다운로드하고 추출하세요.

   ```yaml
   variables:
     GEMNASIUM_DB_LOCAL_PATH: ./gemnasium-db-local
     GEMNASIUM_DB_UPDATE_DISABLED: "true"

   dependency_scanning:
     before_script:
       - wget https://local.example.com/gemnasium_db.tar.gz
       - mkdir -p $GEMNASIUM_DB_LOCAL_PATH
       - tar -xzvf gemnasium_db.tar.gz --strip-components=1 -C $GEMNASIUM_DB_LOCAL_PATH
   ```

### Gradle 에서 사용 {#use-a-proxy-with-gradle-projects}

Gradle 는 `HTTP(S)_PROXY` 환경 를 읽지 않습니다. 자세한 내용은 [Gradle 11065](https://github.com/gradle/gradle/issues/11065)를 참조하세요.

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

Gradle 에서 를 사용하도록 하려면:

- `GRADLE_CLI_OPTS` CI/CD 변수를 사용하여 프록시 옵션을 지정하세요:

  ```yaml
  variables:
    GRADLE_CLI_OPTS: "-Dhttps.proxyHost=squid-proxy -Dhttps.proxyPort=3128 -Dhttp.proxyHost=squid-proxy -Dhttp.proxyPort=3128 -Dhttp.nonProxyHosts=localhost"
  ```

### Maven 에서 사용 {#use-a-proxy-with-maven-projects}

Maven은 `HTTP(S)_PROXY` 환경 를 읽지 않습니다. 대신 Maven 설정 파일을 사용해야 합니다.

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

Maven 종속성 스캐너가 프록시를 사용하도록 구성하려면:

1. 에 `mysettings.xml` 파일을 만듭니다. 해당 파일에서 Maven 설정을 구성하세요.

   구성을 지정하는 방법에 대한 세부 정보는 [Maven 설명서](https://maven.apache.org/guides/mini/guide-proxies.html)를 참조하세요.
1. `MAVEN_CLI_OPTS` CI/CD 변수를 프로젝트의 `.gitlab-ci.yml` 파일에서 설정 파일 `mysettings.xml`을 참조하도록 정의하세요.

   ```yaml
   variables:
     MAVEN_CLI_OPTS: "--settings mysettings.xml"
   ```

### 언어 및 패키지 관리자의 특정 설정 {#specific-settings-for-languages-and-package-managers}

특정 언어 및 패키지 관리자를 구성하기 위해 다음 섹션을 참조하세요.

#### Python (pip) {#python-pip}

분석기가 실행되기 전에 Python 를 설치해야 하는 경우 스캔 의 `before_script`에서 `pip install --user`을 사용해야 합니다. `--user` 는 이 디렉토리에 설치되도록 합니다. `--user` 옵션을 전달하지 않으면 가 전역적으로 설치되며 스캔되지 않고 을 나열할 때 표시되지 않습니다.

#### Python (setuptools) {#python-setuptools}

분석기가 실행되기 전에 Python 를 설치해야 하는 경우 스캔 의 `before_script`에서 `python setup.py install --user`을 사용해야 합니다. `--user` 는 이 디렉토리에 설치되도록 합니다. `--user` 옵션을 전달하지 않으면 가 전역적으로 설치되며 스캔되지 않고 을 나열할 때 표시되지 않습니다.

PyPi 에 자체 서명된 인증서를 사용하는 경우 (앞선 `.gitlab-ci.yml` 템플릿 제외) 추가 구성이 필요하지 않습니다. 그러나 에 도달할 수 있도록 `setup.py`을 업데이트해야 합니다. 다음은 구성 예입니다:

1. `setup.py`을 업데이트하여 `install_requires` 목록의 각 에 대해 를 가리키는 `dependency_links` 속성을 만듭니다:

   ```python
   install_requires=['pyparsing>=2.0.3'],
   dependency_links=['https://pypi.example.com/simple/pyparsing'],
   ```

1. URL에서 인증서를 가져와 에 추가하세요:

   ```shell
   printf "\n" | openssl s_client -connect pypi.example.com:443 -servername pypi.example.com | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > internal.crt
   ```

1. `setup.py`을 새로 다운로드한 인증서로 지정하세요:

   ```python
   import setuptools.ssl_support
   setuptools.ssl_support.cert_paths = ['internal.crt']
   ```

#### Python (Pipenv) {#python-pipenv}

제한된 네트워크 연결 환경에서 실행 중인 경우 PyPi 를 사용하려면 `PIPENV_PYPI_MIRROR` 를 구성해야 합니다. 이 는 기본 및 개발 을 모두 포함해야 합니다.

```yaml
variables:
  PIPENV_PYPI_MIRROR: https://pypi.example.com/simple
```

<!-- markdownlint-disable MD044 -->
또는 를 사용할 수 없는 경우 필요한 를 Pipenv 환경 에 로드할 수 있습니다. 이 옵션의 경우 는 `Pipfile.lock`을 에 확인하고 기본 및 개발 를 에 로드해야 합니다. 이 방법을 수행하는 방법의 예는 [python-pipenv](https://gitlab.com/gitlab-org/security-products/tests/python-pipenv/-/blob/41cc017bd1ed302f6edebcfa3bc2922f428e07b6/.gitlab-ci.yml#L20-42) 예를 참조하세요.
<!-- markdownlint-enable MD044 -->

## 감지 {#dependency-detection}

는 에서 사용되는 언어를 자동으로 감지합니다. 감지된 언어와 일치하는 모든 분석기가 실행됩니다. 일반적으로 분석기 선택을 사용자 정의할 필요가 없습니다. 분석기를 지정하지 않으면 최고의 범위를 위해 전체 선택이 자동으로 사용되므로 더 이상 사용되지 않음 또는 제거 시 조정할 필요가 없습니다. 그러나 `DS_EXCLUDED_ANALYZERS`을 사용하여 선택을 무시할 수 있습니다.

언어 감지는 CI/CD 작업 [`rules`](../../../../ci/yaml/_index.md#rules)를 통해 리포지토리에서 [지원되는 종속성 파일](#how-analyzers-are-triggered)의 존재를 감지합니다.

Java 및 Python의 경우 지원되는 파일이 감지되면 는 를 빌드하고 목록을 얻기 위해 일부 Java 또는 Python 을 실행하려고 시도합니다. 다른 모든 의 경우 은 를 먼저 빌드할 필요 없이 목록을 얻기 위해 구문 분석됩니다.

모든 직접 및 이 분석되며 의 깊이에 제한이 없습니다.

### 분석기 {#analyzers}

는 다음의 공식 [Gemnasium 기반](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) 분석기를 지원합니다:

- `gemnasium`
- `gemnasium-maven`
- `gemnasium-python`

분석기는 Docker 이미지로 게시되며, 는 각 분석을 위해 전용 를 시작합니다. 또한 사용자 정의 보안 를 통합할 수 있습니다.

Gemnasium의 새 버전이 출시될 때마다 각 분석기가 업데이트됩니다.

### 분석기가 정보를 얻는 방법 {#how-analyzers-obtain-dependency-information}

GitLab 분석기는 다음 두 방법 중 하나를 사용하여 정보를 얻습니다:

1. [을 직접 구문 분석합니다.](#obtaining-dependency-information-by-parsing-lockfiles)
1. [정보 파일을 생성하기 위해 관리자 또는 빌드 도구를 실행한 다음 구문 분석합니다.](#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)

#### 을 구문 분석하여 정보 얻기 {#obtaining-dependency-information-by-parsing-lockfiles}

다음 관리자는 GitLab 분석기가 직접 구문 분석할 수 있는 을 사용합니다:

<table class="ds-table no-vertical-table-lines">
  <thead>
    <tr>
      <th>패키지 관리자</th>
      <th>지원되는 파일 형식 버전</th>
      <th>테스트된 관리자 버전</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Bundler</td>
      <td>해당 없음</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/ruby-bundler/default/Gemfile.lock#L118">1.17.3</a>, <a href="https://gitlab.com/gitlab-org/security-products/tests/ruby-bundler/-/blob/bundler2-FREEZE/Gemfile.lock#L118">2.1.4</a>
      </td>
    </tr>
    <tr>
      <td>Composer</td>
      <td>해당 없음</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/php-composer/default/composer.lock">1.x</a>
      </td>
    </tr>
    <tr>
      <td>Conan</td>
      <td>0.4</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/c-conan/default/conan.lock#L38">1.x</a>
      </td>
    </tr>
    <tr>
      <td>Go</td>
      <td>해당 없음</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/go-modules/gosum/default/go.sum">1.x</a>
      </td>
    </tr>
    <tr>
      <td>NuGet</td>
      <td>v1, v2</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/csharp-nuget-dotnetcore/default/src/web.api/packages.lock.json#L2">4.9</a>
      </td>
    </tr>
    <tr>
      <td>npm</td>
      <td>v1, v2, v3</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/default/package-lock.json#L4">6.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-npm/lockfileVersion2/package-lock.json#L4">7.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/npm/fixtures/lockfile-v3/simple/package-lock.json#L4">9.x</a>
      </td>
    </tr>
    <tr>
      <td>pnpm</td>
      <td>v5, v6, v9</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-pnpm/default/pnpm-lock.yaml#L1">7.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/pnpm/fixtures/v6/simple/pnpm-lock.yaml#L1">8.x</a> <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/pnpm/fixtures/v9/simple/pnpm-lock.yaml#L1">9.x</a>
      </td>
    </tr>
    <tr>
      <td>yarn</td>
      <td>버전 1, 2, 3, 4<sup>1</sup></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/classic/default/yarn.lock#L2">1.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/berry/v2/default/yarn.lock">2.x</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/js-yarn/berry/v3/default/yarn.lock">3.x</a>
      </td>
    </tr>
    <tr>
      <td>Poetry</td>
      <td>v1</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/qa/fixtures/python-poetry/default/poetry.lock">1.x</a>
      </td>
    </tr>
    <tr>
      <td>uv</td>
      <td>v0.x</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/master/scanner/parser/uv/fixtures/simple/uv.lock">0.x</a>
      </td>
    </tr>
  </tbody>
</table>

**각주**:

1. Yarn Berry에 대해 다음 기능이 지원되지 않습니다:

   - 워크스페이스
   - `yarn patch`

   , 또는 둘 다를 포함하는 Yarn 파일은 여전히 처리되지만 이러한 기능은 무시됩니다.

#### 구문 분석 가능한 파일을 생성하기 위해 관리자를 실행하여 정보 얻기 {#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file}

다음 관리자를 지원하기 위해 GitLab 분석기는 두 단계로 진행됩니다:

1. 정보를 내보내기 위해 관리자 또는 특정 을 실행합니다.
1. 내보낸 정보를 구문 분석합니다.

<table class="ds-table no-vertical-table-lines">
  <thead>
    <tr>
      <th>패키지 관리자</th>
      <th>사전 설치 버전</th>
      <th>테스트된 버전</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>sbt</td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L4">1.6.2</a></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L794-798">1.1.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L800-805">1.2.8</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L722-725">1.3.12</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L722-725">1.4.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L742-746">1.5.8</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L748-762">1.6.2</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L764-768">1.7.3</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L770-774">1.8.3</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L776-781">1.9.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/.gitlab/ci/gemnasium-maven.gitlab-ci.yml#L111-121">1.9.7</a>
      </td>
    </tr>
    <tr>
      <td>maven</td>
      <td><a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.3.1/build/gemnasium-maven/debian/config/.tool-versions#L3">3.9.8</a></td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.3.1/spec/gemnasium-maven_image_spec.rb#L92-94">3.9.8</a><sup>1</sup>
      </td>
    </tr>
    <tr>
      <td>Gradle</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">6.7.1</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">7.6.4</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-maven/debian/config/.tool-versions#L5">8.8</a><sup>2</sup>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L316-321">5.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L323-328">6.7</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L330-335">6.9</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L337-341">7.6</a>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-maven_image_spec.rb#L343-347">8.8</a>
      </td>
    </tr>
    <tr>
      <td>setuptools</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.4.1/build/gemnasium-python/requirements.txt#L41">70.3.0</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.4.1/spec/gemnasium-python_image_spec.rb#L294-316">70.3.0 이상</a>
      </td>
    </tr>
    <tr>
      <td>pip</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-python/debian/Dockerfile#L21">24</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L77-90">24</a>
      </td>
    </tr>
    <tr>
      <td>Pipenv</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium-python/requirements.txt#L23">2023.11.15</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L243-256">2023.11.15</a><sup>3</sup>, <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/spec/gemnasium-python_image_spec.rb#L219-241">2023.11.15</a>
      </td>
    </tr>
    <tr>
      <td>Go</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium/alpine/Dockerfile#L91-93">1.21</a>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/blob/v5.2.14/build/gemnasium/alpine/Dockerfile#L91-93">1.21</a><sup>4</sup>
      </td>
    </tr>
  </tbody>
</table>

**각주**:

1. 이 는 `.tool-versions` 파일에 지정된 maven의 기본 버전을 사용합니다.
1. Java의 다른 버전은 Gradle의 다른 버전을 필요로 합니다. 이전 표에 나열된 Gradle 버전은 분석기 이미지에 사전 설치되어 있습니다. 분석기가 사용하는 Gradle 버전은 에서 `gradlew` (Gradle ) 파일을 사용하는지 여부에 따라 다릅니다:
   - 에서 `gradlew` 파일을 사용하지 않는 경우 분석기는 `DS_JAVA_VERSION` 에 의해 지정된 Java 버전을 기반으로 사전 설치된 Gradle 버전 중 하나로 자동으로 전환합니다 (기본 버전은 17).

     Java 버전 8 및 11의 경우 Gradle 6.7.1이 자동으로 선택되고 Java 17은 Gradle 7.6.4를 사용하며 Java 21은 Gradle 8.8을 사용합니다.
   - 에서 `gradlew` 파일을 사용하는 경우 분석기 이미지에 사전 설치된 Gradle 버전은 무시되고 `gradlew` 파일에 지정된 버전이 대신 사용됩니다.
1. 이 는 `Pipfile.lock` 파일이 발견되면 Gemnasium에서 이 파일에 나열된 정확한 버전을 스캔하는 데 사용됨을 확인합니다.
1. `go build`의 구현으로 인해 Go 빌드 는 네트워크 액세스, `go mod download`를 사용하여 사전 로드된 mod 또는 공급된 을 필요로 합니다. 자세한 내용은 [및 컴파일에 대한 Go 설명서](https://pkg.go.dev/cmd/go#hdr-Compile_packages_and_dependencies)를 참조하세요.

## 분석기가 트리거되는 방식 {#how-analyzers-are-triggered}

GitLab은 [`rules:exists`](../../../../ci/yaml/_index.md#rulesexists)에 의존하여 에서 [지원되는 파일](#supported-languages-and-package-managers)의 존재에 의해 감지된 언어에 대해 관련 분석기를 시작합니다. 의 루트에서 최대 2개의 디렉토리 수준이 검색됩니다. 예를 들어 `gemnasium-dependency_scanning` 은 에 `Gemfile`, `api/Gemfile` 또는 `api/client/Gemfile`이 포함되어 있으면 활성화되지만 `api/v1/client/Gemfile`이 유일한 지원되는 파일인 경우는 아닙니다.

## 여러 파일을 처리하는 방법 {#how-multiple-files-are-processed}

> [!note]
> 여러 파일을 스캔하는 동안 문제가 발생한 경우 [이](https://gitlab.com/gitlab-org/gitlab/-/issues/337056)에 의견을 기여하세요.

### Python {#python}

GitLab은 요구 사항 파일 또는 이 감지된 디렉토리에서만 하나의 설치를 실행합니다. 은 감지된 첫 번째 파일에 대해서만 `gemnasium-python`에 의해 분석됩니다. 파일은 다음 순서로 검색됩니다:

1. `requirements.txt`, `requirements.pip` 또는 `requires.txt` (Pip를 사용하는 ).
1. `Pipfile` 또는 `Pipfile.lock` (Pipenv를 사용하는 ).
1. `poetry.lock` (Poetry를 사용하는 ).
1. `setup.py` (Setuptools를 사용하는 ).

검색은 루트 디렉토리에서 시작한 다음 루트 디렉토리에서 빌드를 찾지 못한 경우 하위 디렉토리와 함께 계속됩니다. 따라서 루트 디렉토리의 Poetry 은 하위 디렉토리의 Pipenv 파일보다 먼저 감지됩니다.

### Java 및 Scala {#java-and-scala}

GitLab은 빌드 파일이 감지된 디렉토리에서만 하나의 빌드를 실행합니다. 여러 Gradle, Maven 또는 sbt 빌드를 포함하거나 이들의 조합을 포함하는 대규모 의 경우 `gemnasium-maven`은 감지된 첫 번째 빌드 파일에 대해서만 을 분석합니다. 빌드 파일은 다음 순서로 검색됩니다:

1. 단일 또는 [다중 모듈](https://maven.apache.org/pom.html#Aggregation) Maven 프로젝트의 `pom.xml`입니다.
1. `build.gradle` 또는 `build.gradle.kts` (단일 또는 [다중 프로젝트](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html) Gradle 빌드).
1. `build.sbt` (단일 또는 [다중 프로젝트](https://www.scala-sbt.org/1.x/docs/Multi-Project.html) sbt 빌드).

검색은 루트 디렉토리에서 시작한 다음 루트 디렉토리에서 빌드를 찾지 못한 경우 하위 디렉토리와 함께 계속됩니다. 따라서 루트 디렉토리의 sbt 빌드 파일은 하위 디렉토리의 Gradle 빌드 파일보다 먼저 감지됩니다. [다중 모듈](https://maven.apache.org/pom.html#Aggregation) Maven 프로젝트와 다중 프로젝트 [Gradle](https://docs.gradle.org/current/userguide/intro_multi_project_builds.html) 및 [sbt](https://www.scala-sbt.org/1.x/docs/Multi-Project.html) 빌드의 경우, 부모 빌드 파일에서 선언된 경우 하위 모듈 및 하위 프로젝트 파일이 분석됩니다.

### JavaScript {#javascript}

다음 분석기가 실행되며 각각은 여러 파일을 처리할 때 다른 동작을 합니다:

- [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)

  여러 지원
- [Retire.js](https://retirejs.github.io/retire.js/)

  여러 지원 안 함. 여러 이 있을 때 `Retire.js`은 디렉토리 트리를 알파벳순으로 탐색하는 동안 발견된 첫 번째 을 분석합니다.

`gemnasium` 분석기 스캔은 JavaScript 에 대해 공급된 (즉, 에 확인되었지만 관리자에서 관리하지 않는 것)를 지원합니다.

### Go {#go}

여러 파일 지원. `go.mod` 파일이 감지되면 분석기는 [빌드 목록](https://go.dev/ref/mod#glos-build-list)을 생성하려고 시도하며 [최소 버전 선택](https://go.dev/ref/mod#glos-minimal-version-selection)을 사용합니다. 실패하면 분석기는 대신 `go.mod` 파일 내의 을 구문 분석하려고 시도합니다.

요구 사항으로서 `go.mod` 파일은 `go mod tidy` 을 사용하여 정리해야 의 적절한 관리를 보장합니다. 감지된 모든 `go.mod` 파일에 대해 가 반복됩니다.

### PHP, C, C++, .NET, C#, Ruby, JavaScript {#php-c-c-net-c35-ruby-javascript}

이러한 언어의 분석기는 여러 을 지원합니다.

### 추가 언어에 대한 지원 {#support-for-additional-languages}

추가 언어, 관리자 및 파일에 대한 지원은 다음 에서 추적됩니다:

| 관리자    | 언어 | 지원되는 파일 | 도구 | 이슈 |
| ------------------- | --------- | --------------- | ---------- | ----- |
| [Poetry](https://python-poetry.org/) | Python | `pyproject.toml` | [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) | [GitLab#32774](https://gitlab.com/gitlab-org/gitlab/-/issues/32774) |

## 경고 {#warnings}

모든 의 가장 최근 버전과 모든 관리자 및 언어의 가장 최근 지원 버전을 사용하세요. 이전 버전을 사용하면 지원되지 않는 버전이 더 이상 활성 보안 보고 및 보안 수정 백포트의 이점을 얻지 못할 수 있으므로 보안 위험이 증가합니다.

### Gradle {#gradle-projects}

Gradle 에 대한 HTML 보고서를 생성할 때 `reports.html.destination` 또는 `reports.html.outputLocation` 속성을 무시하지 마세요. 이렇게 하면 가 올바르게 작동하지 않습니다.

### Maven {#maven-projects}

격리된 네트워크에서 중앙 가 인 경우 (`<mirror>` 지시문으로 명시적으로 설정됨) Maven 빌드는 `gemnasium-maven-plugin` 을 찾지 못할 수 있습니다. 이 문제는 Maven이 기본적으로 (`/root/.m2`)를 검색하지 않고 중앙 에서 가져오려고 시도하기 때문에 발생합니다. 결과는 누락된 에 대한 오류입니다.

#### 해결 방법 {#workaround}

이 문제를 해결하려면 `<pluginRepositories>` 섹션을 `settings.xml` 파일에 추가하세요. 이렇게 하면 Maven이 에서 플러그인을 찾을 수 있습니다.

시작하기 전에 다음을 고려하세요:

- 이 해결 방법은 기본 Maven 중앙 가 에 미러되는 환경에만 적용됩니다.
- 이 해결 방법을 적용한 후 Maven은 플러그인에 대한 를 검색하며, 이는 일부 환경에서 보안 영향을 미칠 수 있습니다. 이것이 조직의 보안 정책과 일치하는지 확인하세요.

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

`settings.xml` 파일을 수정하려면 다음 단계를 따르세요:

1. Maven `settings.xml` 파일을 찾습니다. 이 파일은 일반적으로 다음 위치 중 하나에 있습니다:

   - `/root/.m2/settings.xml` (루트 ).
   - `~/.m2/settings.xml` (일반 ).
   - `${maven.home}/conf/settings.xml` 설정.

1. 파일에 기존 `<pluginRepositories>` 섹션이 있는지 확인하세요.
1. `<pluginRepositories>` 섹션이 이미 있으면 다음 `<pluginRepository>` 요소만 안에 추가하세요. 그렇지 않으면 전체 `<pluginRepositories>` 섹션을 추가하세요:

   ```xml
     <pluginRepositories>
       <pluginRepository>
           <id>local2</id>
           <name>local repository</name>
           <url>file:///root/.m2/repository/</url>
       </pluginRepository>
     </pluginRepositories>
   ```

1. Maven 빌드 또는 를 다시 실행하세요.

### Python {#python-projects}

[`PIP_EXTRA_INDEX_URL`](https://pipenv.pypa.io/en/latest/indexes.html) 환경 를 사용할 때 [CVE-2018-20225](https://nvd.nist.gov/vuln/detail/CVE-2018-20225)로 기록된 가능한 익스플로잇으로 인해 각별한 주의를 기울여야 합니다:

> [!warning]
> pip(모든 버전)에서 발견된 문제는 사용자가 색인에서 를 얻으려고 한 경우에도 버전 번호가 가장 높은 버전을 설치하기 때문입니다. 이는 `PIP_EXTRA_INDEX_URL` 옵션 사용에만 영향을 미치며 익스플로잇을 하려면 가 색인에 이미 있지 않아야 합니다 (따라서 공격자가 임의의 버전 번호로 를 거기에 놓을 수 있음).

### 버전 번호 구문 분석 {#version-number-parsing}

경우에 따라 의 버전이 보안 권고의 영향을 받는 에 있는지 확인할 수 없습니다.

예를 들어:

- 버전을 알 수 없습니다.
- 버전이 유효하지 않습니다.
- 버전을 파싱하거나 범위와 비교할 수 없습니다.
- 버전이 브랜치인 경우입니다. 예: `dev-master` 또는 `1.5.x`.
- 비교되는 버전이 모호합니다. 예를 들어 `1.0.0-20241502`을 `1.0.0-2`과 비교할 수 없습니다. 한 버전에는 타임스탬프가 포함되어 있고 다른 버전에는 포함되지 않기 때문입니다.

이러한 경우 분석기는 종속성을 건너뛰고 로그에 메시지를 출력합니다.

GitLab 분석기는 가정을 하지 않습니다. 잘못된 양성 또는 잘못된 음성이 발생할 수 있기 때문입니다. 자세한 내용은 [이슈 442027](https://gitlab.com/gitlab-org/gitlab/-/issues/442027)을 참조하세요.

## Swift 프로젝트 빌드 {#build-swift-projects}

Swift Package Manager(SPM)는 Swift 코드 배포를 관리하기 위한 공식 도구입니다. Swift 빌드 시스템과 통합되어 종속성 다운로드, 컴파일 및 링크 프로세스를 자동화합니다.

SPM으로 Swift 프로젝트를 빌드할 때 다음 모범 사례를 따릅니다.

1. `Package.resolved` 파일을 포함합니다.

   `Package.resolved` 파일은 종속성을 특정 버전으로 고정합니다. 이 파일을 리포지토리에 항상 커밋하여 다양한 환경에서 일관성을 보장합니다.

   ```shell
   git add Package.resolved
   git commit -m "Add Package.resolved to lock dependencies"
   ```

1. Swift 프로젝트를 빌드하려면 다음 명령을 사용합니다:

   ```shell
   # Update dependencies
   swift package update

   # Build the project
   swift build
   ```

1. CI/CD를 구성하려면 `.gitlab-ci.yml` 파일에 이 단계를 추가합니다:

   ```yaml
   swift-build:
     stage: build
     script:
       - swift package update
       - swift build
   ```

1. 선택 사항. 자체 서명된 인증서로 프라이빗 Swift 패키지 리포지토리를 사용하는 경우 프로젝트에 인증서를 추가하고 Swift가 신뢰하도록 구성해야 할 수 있습니다:

   1. 인증서를 가져옵니다:

      ```shell
      echo | openssl s_client -servername your.repo.url -connect your.repo.url:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END
      CERTIFICATE-/p' > repo-cert.crt
      ```

   1. Swift 패키지 매니페스트(`Package.swift`)에 다음 줄을 추가합니다:

      ```swift
      import Foundation

      #if canImport(Security)
      import Security
      #endif

      extension Package {
          public static func addCustomCertificate() {
              guard let certPath = Bundle.module.path(forResource: "repo-cert", ofType: "crt") else {
                  fatalError("Certificate not found")
              }
              SecCertificateAddToSystemStore(SecCertificateCreateWithData(nil, try! Data(contentsOf: URL(fileURLWithPath: certPath)) as CFData)!)
          }
      }

      // Call this before defining your package
      Package.addCustomCertificate()
      ```

항상 클린 환경에서 빌드 프로세스를 테스트하여 종속성이 올바르게 지정되고 자동으로 해결되도록 합니다.

## CocoaPods 프로젝트 빌드 {#build-cocoapods-projects}

CocoaPods는 Swift 및 Objective-C Cocoa 프로젝트를 위한 인기 있는 종속성 관리자입니다. iOS, macOS, watchOS 및 tvOS 프로젝트에서 외부 라이브러리를 관리하기 위한 표준 형식을 제공합니다.

CocoaPods를 종속성 관리에 사용하는 프로젝트를 빌드할 때 다음 모범 사례를 따릅니다.

1. `Podfile.lock` 파일을 포함합니다.

   `Podfile.lock` 파일은 종속성을 특정 버전으로 고정하는 데 필수적입니다. 이 파일을 리포지토리에 항상 커밋하여 다양한 환경에서 일관성을 보장합니다.

   ```shell
   git add Podfile.lock
   git commit -m "Add Podfile.lock to lock CocoaPods dependencies"
   ```

1. 다음 중 하나를 사용하여 프로젝트를 빌드할 수 있습니다:

   - `xcodebuild` 명령줄 도구:

     ```shell
     # Install CocoaPods dependencies
     pod install

     # Build the project
     xcodebuild -workspace YourWorkspace.xcworkspace -scheme YourScheme build
     ```

   - Xcode IDE:

     1. Xcode에서 `.xcworkspace` 파일을 엽니다.
     1. 대상 스킴을 선택합니다.
     1. **제품** > **빌드**를 선택합니다. <kbd>⌘</kbd>+<kbd>B</kbd>를 눌러도 됩니다.
   - [fastlane](https://fastlane.tools/)(iOS 및 Android 앱의 빌드 및 릴리스를 자동화하기 위한 도구):

     1. `fastlane`을 설치합니다:

        ```shell
        sudo gem install fastlane
        ```

     1. 프로젝트에서 `fastlane`을 구성합니다:

        ```shell
        fastlane init
        ```

     1. `fastfile`에 레인을 추가합니다:

        ```ruby
        lane :build do
          cocoapods
          gym(scheme: "YourScheme")
        end
        ```

     1. 빌드를 실행합니다:

        ```shell
        fastlane build
        ```

   - 프로젝트에서 CocoaPods와 Carthage를 모두 사용하는 경우 Carthage를 사용하여 종속성을 빌드할 수 있습니다:

     1. CocoaPods 종속성을 포함하는 `Cartfile`을 만듭니다.
     1. 다음을 실행합니다:

        ```shell
        carthage update --platform iOS
        ```

1. 선호하는 방법에 따라 프로젝트를 빌드하도록 CI/CD를 구성합니다.

   예를 들어 `xcodebuild`을 사용합니다:

   ```yaml
   cocoapods-build:
     stage: build
     script:
       - pod install
       - xcodebuild -workspace YourWorkspace.xcworkspace -scheme YourScheme build
   ```

1. 선택 사항. 프라이빗 CocoaPods 리포지토리를 사용하는 경우 프로젝트에 접근하도록 구성해야 할 수 있습니다:

   1. 프라이빗 spec 리포지토리를 추가합니다:

      ```shell
      pod repo add REPO_NAME SOURCE_URL
      ```

   1. Podfile에서 소스를 지정합니다:

      ```ruby
      source 'https://github.com/CocoaPods/Specs.git'
      source 'SOURCE_URL'
      ```

1. 선택 사항. 프라이빗 CocoaPods 리포지토리에서 SSL을 사용하는 경우 SSL 인증서가 올바르게 구성되었는지 확인합니다:

   - 자체 서명된 인증서를 사용하는 경우 시스템의 신뢰할 수 있는 인증서에 추가합니다. `.netrc` 파일에서 SSL 구성을 지정할 수도 있습니다:

     ```netrc
     machine your.private.repo.url
       login your_username
       password your_password
     ```

1. Podfile을 업데이트한 후 `pod install`을 실행하여 종속성을 설치하고 워크스페이스를 업데이트합니다.

Podfile을 업데이트한 후 항상 `pod install`을 실행하여 모든 종속성이 올바르게 설치되고 워크스페이스가 업데이트되도록 합니다.

## 취약성 데이터베이스에 기여하기 {#contributing-to-the-vulnerability-database}

취약성을 찾으려면 [`GitLab advisory database`](https://advisories.gitlab.com/)을 검색할 수 있습니다. [새로운 취약성을 제출](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md)할 수도 있습니다.
