---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CycloneDX 파일의 라이선스 스캐닝
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 레거시 라이선스 컴플라이언스 분석기(`License-Scanning.gitlab-ci.yml`)는 GitLab 17.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/439162)되었습니다.
- GitLab 17.5에서는 라이선스 정보의 데이터 소스로 CycloneDX 보고서 아티팩트를 사용하는 기능이 도입되었습니다. 이 기능은 기능 플래그 `license_scanning_with_sbom_licenses`를 따라 릴리스되었으며 기본적으로 사용 중지됩니다.
- GitLab 17.6에서는 라이선스 정보의 데이터 소스로 CycloneDX 보고서 아티팩트를 사용하는 것이 기본적으로 설정되었습니다. `license_scanning_with_sbom_licenses` 기능 플래그는 필요한 경우 기능을 사용 중지하기 위해 여전히 존재했습니다.
- GitLab 17.8에서 기능 플래그 `license_scanning_with_sbom_licenses`는 제거되었습니다.

{{< /history >}}

사용되는 라이선스를 탐지하기 위해 라이선스 규정 준수는 [종속성 검사 작업](../../application_security/dependency_scanning/_index.md) 실행  및 해당 작업으로 생성된 [CycloneDX](https://cyclonedx.org/) SBOM(소프트웨어 자재 명세서)의 분석에 의존합니다. 이 검사 방식은 [SPDX 목록](https://spdx.org/licenses/)에 정의된 대로 600가지 이상의 다양한 라이선스 유형을 파싱하고 식별할 수 있습니다. 타사 검사기는 [지원되는 언어](#supported-languages-and-package-managers)에 대한 CycloneDX 보고서 아티팩트를 생성하고 GitLab CycloneDX 속성 분류를 따르는 한 종속성 목록을 생성하는 데 사용될 수 있습니다. 다른 라이선스를 제공할 수 있는 기능은 [에픽 10861](https://gitlab.com/groups/gitlab-org/-/epics/10861)에서 추적됩니다.

> [!note]
> 라이선스 스캐닝 기능은 외부 데이터베이스에 수집되고 GitLab 인스턴스와 자동으로 동기화되는 공개적으로 사용 가능한 패키지 메타데이터에 의존합니다. 이 데이터베이스는 미국에서 호스팅되는 다중 지역 Google Cloud Storage 버킷입니다. 검사는 GitLab 인스턴스 내에서만 실행됩니다. 컨텍스트 정보(예: 프로젝트 종속성 목록)는 외부 서비스로 전송되지 않습니다.

## 구성 {#configuration}

CycloneDX 파일에 대한 라이선스 검사를 사용으로 설정하려면 다음을 수행합니다.

- 종속성 검사 템플릿 사용
  - [종속성 검사](../../application_security/dependency_scanning/dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)를 활성화하고 사전 요구 사항이 충족되는지 확인합니다.
  - GitLab Self-Managed에서는 **운영자** 영역에서 GitLab 인스턴스에 대해 [동기화할 패키지 레지스트리 메타데이터 선택](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)을 수행할 수 있습니다. 이 데이터 동기화가 작동하려면 GitLab 인스턴스에서 `storage.googleapis.com` 도메인으로 아웃바운드 네트워크 트래픽을 허용해야 합니다. 네트워크 연결이 제한적이거나 없는 경우 [오프라인 환경에서 실행](#running-in-an-offline-environment) 설명서 섹션을 참조하여 자세한 안내를 확인하세요.
- 또는 해당 패키지 레지스트리에 [CI/CD 구성 요소](../../../ci/components/_index.md)를 사용합니다.

## 지원되는 언어 및 패키지 관리자 {#supported-languages-and-package-managers}

{{< history >}}

- Swift 지원이 GitLab 17.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/506756)되었습니다.
- Dart 지원이 GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/18351)되었습니다.

{{< /history >}}

라이선스 스캐닝은 다음 언어 및 패키지 관리자에서 지원됩니다.

<!-- markdownlint-disable MD044 -->
<table class="supported-languages">
  <thead>
    <tr>
      <th>언어</th>
      <th>패키지 관리자</th>
      <th>종속성 검사 템플릿</th>
      <th>CI/CD 구성 요소</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>.NET</td>
      <td rowspan="2"><a href="https://www.nuget.org/">NuGet</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td>C#</td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td>C</td>
      <td rowspan="2"><a href="https://conan.io/">Conan</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td>C++</td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td>Dart</td>
      <td><a href="https://pub.dev/">pub</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td>Go<sup>1</sup></td>
      <td><a href="https://go.dev/">Go</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td rowspan="3">Java</td>
      <td><a href="https://gradle.org/">Gradle</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td><a href="https://developer.android.com/">Android</a></td>
      <td>예</td>
      <td><a href="https://gitlab.com/components/android-dependency-scanning">예</a></td>
    </tr>
    <tr>
      <td rowspan="3">JavaScript 및 TypeScript</td>
      <td><a href="https://www.npmjs.com/">npm</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td><a href="https://pnpm.io/">pnpm</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en/">yarn</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td>PHP</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td rowspan="4">Python</td>
      <td><a href="https://setuptools.readthedocs.io/en/latest/">setuptools</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td>Ruby</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td>Rust</td>
      <td><a href="https://doc.rust-lang.org/cargo/">cargo</a></td>
      <td>아니요</td>
      <td><a href="https://gitlab.com/components/dependency-scanning#generating-cargo-sboms">예</a></td>
    </tr>
    <tr>
      <td>Scala</td>
      <td><a href="https://www.scala-sbt.org/">sbt</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
    <tr>
      <td>Swift</td>
      <td><a href="https://developer.apple.com/swift/">sbt</a></td>
      <td>예</td>
      <td>아니요</td>
    </tr>
  </tbody>
</table>
<!-- markdownlint-enable MD044 -->

**각주**:

1. Go 표준 라이브러리(예: `stdlib`)는 지원되지 않으며 `unknown` 라이선스로 표시됩니다. 이에 대한 지원은 [이슈 480305](https://gitlab.com/gitlab-org/gitlab/-/issues/480305)에서 추적됩니다.

지원되는 파일 및 버전은 [종속성 검사](../../application_security/dependency_scanning/dependency_scanning_sbom/_index.md#supported-languages-and-files)에서 지원하는 것입니다.

## 데이터 소스 {#data-sources}

지원되는 패키지의 라이선스 정보는 아래 소스에서 얻습니다. GitLab은 원본 데이터에 대한 추가 처리를 수행하며, 여기에는 변형을 정규 라이선스 이름으로 매핑하는 것이 포함됩니다.

| 패키지 관리자 | 소스                                                           |
|-----------------|------------------------------------------------------------------|
| Cargo           | <https://deps.dev/>                                              |
| Conan           | <https://github.com/conan-io/conan-center-index>                 |
| Go              | <https://index.golang.org/>                                      |
| Maven           | <https://storage.googleapis.com/maven-central>                   |
| npm             | <https://deps.dev/>                                              |
| NuGet           | <https://api.nuget.org/v3/catalog0/index.json>                   |
| Packagist       | <https://packagist.org/packages/list.json>                       |
| pub             | <https://pub.dev/>                                               |
| PyPI            | <https://warehouse.pypa.io/api-reference/bigquery-datasets.html> |
| RubyGems        | <https://rubygems.org/versions>                                  |

## 라이선스 표현식 {#license-expressions}

{{< history >}}

- CycloneDX SBOM의 SPDX 라이선스 표현식 지원이 GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/606225)되었습니다.

{{< /history >}}

GitLab은 CycloneDX SBOM의 `expression` 필드에서 SPDX [라이선스 표현식](https://spdx.github.io/spdx-spec/v2-draft/SPDX-license-expressions/)을 읽으며, 사용자 지정 비SPDX 라이선스에 대해 `LicenseRef-[NAME]` 구문을 포함합니다. 컴포넌트의 SBOM 항목에 `expression`이 포함되어 있으면 GitLab은 전체 표현식을 저장하고 평가합니다. 이전에는 라이선스 표현식이 있는 컴포넌트가 `unknown` 라이선스로 표시되었습니다.

라이선스 표현식은 [라이선스 승인 정책](../license_approval_policies.md)에서 지원됩니다. 정책이 컴포넌트의 표현식에서 용어로 나타나는 라이선스를 대상으로 할 때 정책은 전체 표현식에 대해 올바르게 평가됩니다.

## 탐지된 라이선스를 기반으로 병합 요청 차단 {#blocking-merge-requests-based-on-detected-licenses}

사용자는 [라이선스 승인 정책](../license_approval_policies.md)을 구성하여 탐지된 라이선스를 기반으로 병합 요청에 대한 승인을 요구할 수 있습니다.

## 오프라인 환경에서 실행 {#running-in-an-offline-environment}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

인터넷을 통해 외부 리소스에 제한적이거나 제한되거나 간헐적인 액세스가 있는 환경의 인스턴스의 경우 CycloneDX 보고서를 라이선스에 대해 성공적으로 검사하려면 일부 조정이 필요합니다. 자세한 내용은 오프라인 [빠른 시작 가이드](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)를 참조하세요.

## 라이선스 정보의 소스로 CycloneDX 보고서 사용 {#use-cyclonedx-report-as-a-source-of-license-information}

{{< history >}}

- GitLab 17.5에서 [기능 플래그를 사용하여](../../../administration/feature_flags/_index.md) `license_scanning_with_sbom_licenses` 이름으로 도입되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 17.6에서 GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에 사용으로 설정되었습니다.
- GitLab 17.8에서 일반 공개되었습니다. `license_scanning_with_sbom_licenses` 기능 플래그가 제거되었습니다.
- SPDX 라이선스 표현식 지원이 GitLab 19.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/606225)되었습니다.

{{< /history >}}

라이선스 스캐닝은 사용 가능한 경우 CycloneDX JSON SBOM의 [라이선스](https://cyclonedx.org/use-cases/#license-compliance) 필드를 사용합니다. 라이선스 정보를 사용할 수 없으면 외부 라이선스 데이터베이스에서 가져온 라이선스 정보가 사용됩니다. 라이선스 정보는 유효한 SPDX 식별자, 라이선스 이름 또는 SPDX 라이선스 표현식을 사용하여 제공할 수 있습니다. 라이선스 필드 형식에 대한 자세한 내용은 [CycloneDX](https://cyclonedx.org/use-cases/#license-compliance) 사양에서 찾을 수 있습니다.

라이선스 필드를 제공하는 호환되는 CycloneDX SBOM 생성기는 [CycloneDX 도구 센터](https://cyclonedx.org/tool-center/)에서 찾을 수 있습니다.

### 라이선스 정보 소스 구성 {#configure-license-information-source}

{{< history >}}

- GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/501662)되었습니다.

{{< /history >}}

둘 다 사용 가능할 때 사용할 라이선스 정보 소스를 선택합니다.

프로젝트의 원하는 라이선스 정보 소스를 구성하려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **라이선스 정보 소스** 섹션에서 다음 중 하나를 선택합니다.
   - **SBOM** (기본값) - CycloneDX 보고서에서 라이선스 정보를 사용합니다.
     - 검사기는 `/gl-sbom-*.cdx.json`에 위치한 프로젝트의 보고서에서 라이선스 정보를 읽습니다.
     - 라이선스를 덮어쓰려면 이 파일에서 라이선스 데이터를 직접 업데이트합니다.
   - **PMDB** \- 외부 라이선스 데이터베이스에서 라이선스 정보를 사용합니다.

### CycloneDX 파일에 대한 라이선스 검사를 사용 또는 사용 중지 {#enable-or-disable-license-scanning-for-cyclonedx-files}

{{< history >}}

- `license_scanning_for_cyclonedx_setting`라는 이름의 [기능 플래그](../../../administration/feature_flags/_index.md)로 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/500716)되었습니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 19.2에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241413)되었습니다. `license_scanning_for_cyclonedx_setting` 기능 플래그가 제거되었습니다.

{{< /history >}}

라이선스 스캐닝은 기본적으로 모든 수집된 CycloneDX SBOM 파일에서 실행됩니다. 보안 구성 페이지에서 프로젝트별로 라이선스 스캐닝을 사용 중지할 수 있습니다. 사용 중지하면 SBOM 수집의 라이선스가 종속성 목록에 `unknown`으로 표시됩니다.

사전 요구 사항:

- 프로젝트에 대해 보안 관리자, 소유자 또는 보안 관리자 역할을 가지고 있어야 합니다.

CycloneDX 파일에 대한 라이선스 검사를 사용 또는 사용 중지하려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **CycloneDX에 대한 라이선스 검색** 섹션에서 토글을 켜거나 끕니다.

## 문제 해결 {#troubleshooting}

### CycloneDX 파일이 검사되지 않으며 결과를 제공하지 않는 것 같습니다 {#a-cyclonedx-file-is-not-being-scanned-and-appears-to-provide-no-results}

CycloneDX 파일이 [CycloneDX JSON 사양](https://cyclonedx.org/docs/1.7/json/)을 준수하는지 확인합니다. 이 사양은 [중복 항목을 허용하지 않습니다](https://cyclonedx.org/docs/1.7/json/#components). 여러 SBOM 파일이 포함된 프로젝트는 각 SBOM 파일을 개별 CI 보고서 아티팩트로 보고하거나 SBOM이 CI 파이프라인의 일부로 병합되는 경우 중복을 제거해야 합니다.

다음과 같이 CycloneDX SBOM 파일을 `CycloneDX JSON specification`에 대해 확인할 수 있습니다.

```shell
$ docker run -it --rm -v "$PWD:/my-cyclonedx-sboms" -w /my-cyclonedx-sboms cyclonedx/cyclonedx-cli:latest cyclonedx validate --input-version v1_4 --input-file gl-sbom-all.cdx.json

Validating JSON BOM...
BOM validated successfully.
```

JSON BOM이 확인에 실패한 경우(예: 중복된 구성 요소가 있기 때문):

```shell
Validation failed: Found duplicates at the following index pairs: "(A, B), (C, D)"
#/properties/components/uniqueItems
```

이 문제는 [jq](https://jqlang.github.io/jq/)를 사용하여 CI 템플릿을 업데이트하여 중복 컴포넌트를 생성하는 작업 정의를 재정의하여 `gl-sbom-*.cdx.json` 보고서에서 중복 컴포넌트를 제거함으로써 해결할 수 있습니다. 예를 들어 다음은 `gemnasium-dependency_scanning` 작업으로 생성된 `gl-sbom-gem-bundler.cdx.json` 보고서 파일에서 중복 컴포넌트를 제거합니다.

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

gemnasium-dependency_scanning:
  after_script:
    - apk update && apk add jq
    - jq '.components |= unique' gl-sbom-gem-bundler.cdx.json > tmp.json && mv tmp.json gl-sbom-gem-bundler.cdx.json
```

### 사용하지 않는 라이선스 데이터 제거 {#remove-unused-license-data}

라이선스 스캐닝 변경(GitLab 15.9에서 출시)은 인스턴스에서 사용 가능한 상당한 양의 추가 디스크 공간이 필요했습니다. 이 문제는 GitLab 16.3에서 [패키지 메타데이터 테이블 디스크 내 풋프린트 축소](https://gitlab.com/groups/gitlab-org/-/epics/10415) 에픽으로 해결되었습니다. 하지만 GitLab 15.9와 16.3 사이에 인스턴스가 라이선스 스캐닝을 실행하고 있었다면 사용되지 않는 데이터를 제거할 수 있습니다.

사용되지 않는 데이터를 제거하려면 다음을 수행합니다.

1. [`package_metadata_synchronization`](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#new-license-compliance-scanner) 기능 플래그가 현재 또는 이전에 사용으로 설정되었는지 확인하고, 그렇다면 사용 중지합니다. [Rails 콘솔](../../../administration/operations/rails_console.md)을 사용하여 다음 명령을 실행합니다.

   ```ruby
   Feature.enabled?(:package_metadata_synchronization) && Feature.disable(:package_metadata_synchronization)
   ```

1. 데이터베이스에 더 이상 사용되지 않는 데이터가 있는지 확인합니다.

   ```ruby
   PackageMetadata::PackageVersionLicense.count
   PackageMetadata::PackageVersion.count
   ```

1. 데이터베이스에 더 이상 사용되지 않는 데이터가 있으면 다음 명령을 순서대로 실행하여 제거합니다.

   ```ruby
   ActiveRecord::Base.connection.execute('SET statement_timeout TO 0')
   PackageMetadata::PackageVersionLicense.delete_all
   PackageMetadata::PackageVersion.delete_all
   ```

### CycloneDX SBOM에 대한 취약성 스캐닝이 결과를 생성하지 않음 {#vulnerability-scanning-produces-no-results-for-a-cyclonedx-sbom}

CycloneDX 파일이 라이선스에 대해 검사되지만 취약성 스캐닝이 결과를 생성하지 않으면 [사용자 지정 또는 병합된 CycloneDX SBOM에 대한 취약성 스캐닝이 결과를 생성하지 않음](../../application_security/dependency_scanning/legacy_dependency_scanning/troubleshooting_dependency_scanning.md#vulnerability-scanning-produces-no-results-for-custom-or-merged-cyclonedx-sboms)을 참조하세요.

### 종속성 라이선스가 알 수 없음 {#dependency-licenses-are-unknown}

오픈 소스 라이선스 정보는 데이터베이스에 저장되며 프로젝트의 종속성에 대한 라이선스를 해결하는 데 사용됩니다. 라이선스 정보가 없거나 해당 데이터를 아직 데이터베이스에서 사용할 수 없으면 종속성의 라이선스가 `unknown`로 표시될 수 있습니다.

파이프라인 완료 시 종속성의 라이선스 조회가 수행되므로, 해당 시간에 이 데이터를 사용할 수 없으면 `unknown` 라이선스가 기록됩니다. 이 라이선스는 후속 파이프라인이 실행될 때까지 표시되며, 그 시점에 다른 라이선스 조회가 수행됩니다. 조회에서 종속성의 라이선스가 변경되었음을 확인하면 새 라이선스가 이 시간에 표시됩니다.
