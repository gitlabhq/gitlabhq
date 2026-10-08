---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보안 용어집
description: GitLab의 보안 기능과 관련된 용어의 정의입니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 용어집은 GitLab의 보안 기능과 관련된 용어의 정의를 제공합니다. 일부 용어는 다른 곳에서 다른 의미를 가질 수 있지만, 이 정의는 GitLab에만 해당됩니다.

## 분석기 {#analyzer}

보안 취약성을 위해 [스캔 대상 유형](#scan-target-type)을 분석하는 소프트웨어입니다. 내부적으로 필요한 구성 매개 변수를 수집하고 대상을 [스캐너](#scanner)가 스캔 작업을 실행하기 위한 표준화된 형식으로 변환하는 데 필요한 데이터 변환을 수행하는 일을 담당합니다. 마지막으로 호출자가 요구하는 형식의 보고서를 생성합니다.

CI/CD 기반 분석기는 CI/CD 작업을 사용하여 GitLab에 통합됩니다. CI/CD 기반 분석기에서 생성된 보고서는 작업이 완료된 후 아티팩트로 게시됩니다. GitLab은 이 보고서를 수집하므로 사용자가 발견된 취약성을 시각화하고 관리할 수 있습니다. 생성된 보고서는 [보안 보고서 형식](#secure-report-format)을 준수합니다.

많은 GitLab 분석기는 Docker를 사용하여 래핑된 스캐너를 실행하는 표준 접근 방식을 따릅니다. 예를 들어, `semgrep` 이미지는 스캐너 `Semgrep`를 래핑하는 분석기입니다. 그러나 일부 분석기는 별도의 컨테이너가 아닌 GitLab Rails 또는 기타 대상 환경 내에서 직접 실행됩니다.

## 공격 표면 {#attack-surface}

공격에 취약한 애플리케이션의 다양한 위치입니다. 보안 제품은 스캔 중에 공격 표면을 검색하고 찾습니다. 각 제품은 공격 표면을 다르게 정의합니다. 예를 들어, SAST는 파일과 줄 번호를 사용하고, DAST는 URL을 사용합니다.

## 구성 요소 {#component}

소프트웨어 프로젝트의 일부를 구성하는 소프트웨어 구성 요소입니다. 예제에는 라이브러리, 드라이버, 데이터 및 [더 많은 항목](https://cyclonedx.org/docs/1.5/json/#components_items_type)이 포함됩니다.

## 코퍼스 {#corpus}

퍼저가 실행되는 동안 생성되는 의미 있는 테스트 케이스의 집합입니다. 각 의미 있는 테스트 케이스는 테스트된 프로그램에서 새로운 커버리지를 생성합니다. 코퍼스를 재사용하고 후속 실행에 전달해야 합니다.

## CNA {#cna}

[CVE](#cve) 번호 지정 기관(CNA)은 [Mitre Corporation](https://cve.mitre.org/)에서 각각의 범위 내에서 제품 또는 서비스의 취약성에 [CVE](#cve)를 할당할 권한이 있는 전 세계의 조직입니다. [GitLab은 CNA입니다](https://about.gitlab.com/security/cve/).

## CVE {#cve}

Common Vulnerabilities and Exposures(CVE®)는 공개적으로 알려진 사이버 보안 취약성에 대한 일반 식별자의 목록입니다. 이 목록은 [Mitre Corporation](https://cve.mitre.org/)에서 관리합니다.

## CVSS {#cvss}

Common Vulnerability Scoring System(CVSS)은 컴퓨터 시스템 보안 취약성의 심각도를 평가하기 위한 무료의 개방형 업계 표준입니다.

## CWE {#cwe}

Common Weakness Enumeration(CWE™)은 보안 영향을 미치는 일반적인 소프트웨어 및 하드웨어 약점 유형의 커뮤니티 개발 목록입니다. 약점은 소프트웨어 또는 하드웨어 구현, 코드, 설계 또는 아키텍처의 결함, 오류, 버그, 취약성 또는 기타 오류입니다. 해결하지 않으면 약점으로 인해 시스템, 네트워크 또는 하드웨어가 공격에 취약할 수 있습니다. CWE 목록 및 관련 분류 분류는 이러한 약점을 CWE 관점에서 식별하고 설명하는 데 사용할 수 있는 언어입니다.

## 중복 제거 {#deduplication}

카테고리의 프로세스가 발견 항목이 동일하거나 노이즈 감소가 필요할 정도로 충분히 유사하다고 판단하는 경우, 하나의 발견 항목만 유지되고 나머지는 제거됩니다. [중복 제거 프로세스](../detect/vulnerability_deduplication.md)에 대해 자세히 알아보세요.

## 종속성 그래프 내보내기 {#dependency-graph-export}

종속성 그래프 내보내기는 프로젝트에서 사용하는 직접 및 간접 종속성과 이들 간의 관계를 나열합니다. 패키지 관리자 명령(예: `go mod graph` 또는 `mvn dependency:tree`)으로 생성되고 파일로 출력됩니다.

관련 용어: [잠금 파일](#lockfile).

## 종속성 버전 충돌 {#dependency-version-conflict}

종속성 버전 충돌은 종속성 버전 제약 조건을 만족할 수 없을 때 발생합니다.

다음을 고려하세요:

- 종속성 X는 `packageA`를 정확히 버전 1.0.0에서 필요로 합니다.
- 종속성 Y는 `packageA` 버전 1.0.1 이상을 필요로 합니다.

이 예에서는 `packageA`의 버전이 두 제약 조건을 모두 만족할 수 없으므로 종속성 버전 충돌이 발생합니다.

## 종속성 버전 비호환성 {#dependency-version-incompatibility}

종속성 버전 비호환성은 패키지의 버전이 버전 제약 조건을 만족하지 않을 때 발생합니다.

다음을 고려하세요:

- `packageA`의 버전은 `1.0.0` 및 `1.0.1`입니다.
- 종속성 X는 `packageA` 버전 1.0.1 이상을 필요로 합니다.

이 예에서 `packageA` 버전 `1.0.0`는 버전 제약 조건을 만족하지 않으므로 호환되지 않습니다. 그러나 `packageA` 버전 `1.0.1`는 제약 조건을 만족합니다.

## 중복 발견 항목 {#duplicate-finding}

여러 번 보고되는 정당한 발견 항목입니다. 이는 다양한 스캐너가 동일한 발견 항목을 검색하거나 단일 스캔이 실수로 동일한 발견 항목을 두 번 이상 보고할 때 발생할 수 있습니다.

## 거짓 양성 {#false-positive}

존재하지 않지만 존재하는 것으로 잘못 보고되는 발견 항목입니다.

## 발견 항목 {#finding}

분석기에 의해 프로젝트에서 식별되는 취약할 가능성이 있는 자산입니다. 자산에는 소스 코드, 바이너리 패키지, 컨테이너, 종속성, 네트워크, 애플리케이션 및 인프라가 포함되지만 이에 국한되지 않습니다.

발견 항목은 스캐너가 MR/기능 분기에서 식별하는 모든 잠재적 취약성 항목입니다. 기본 분기로 병합한 후에만 발견 항목이 [취약성](#vulnerability)이 됩니다.

취약성 발견 항목과 상호 작용할 수 있는 두 가지 방법이 있습니다.

1. 취약성 발견 항목에 대한 이슈 또는 머지 리퀘스트를 열 수 있습니다.
1. 취약성 발견 항목을 해제할 수 있습니다. 발견 항목을 해제하면 기본 보기에서 숨겨집니다.

## 그룹화 {#grouping}

중복 제거 대상이 아닌 관련성이 있을 가능성이 있는 다양한 발견 항목이 있을 때 취약성을 시각적으로 그룹으로 구성하는 유연하고 비파괴적인 방법입니다. 예를 들어, 함께 평가해야 할 발견 항목, 동일한 조치로 수정할 발견 항목, 또는 동일한 소스에서 나온 발견 항목을 포함할 수 있습니다.

## 식별자 {#identifier}

식별자는 Common Vulnerabilities and Exposures(CVE) 또는 Common Weakness Enumeration(CWE)과 같은 외부 데이터베이스의 취약성에 대한 ID입니다. 취약성은 여러 식별자를 가질 수 있습니다. 식별자는 유형(예: `CVE`) 및 ID(예: `CVE-2021-44228`)로 구성됩니다.

## 중요하지 않은 발견 항목 {#insignificant-finding}

특정 고객이 신경 쓰지 않는 정당한 발견 항목입니다.

## 알려진 영향을 받은 구성 요소 {#known-affected-component}

취약성을 악용할 수 있기 위한 요구 사항과 일치하는 구성 요소입니다. 예를 들어, `packageA@1.0.3`는 이름, 패키지 유형 및 `FAKECVE-2023-0001`의 영향을 받는 버전 또는 버전 범위 중 하나와 일치합니다.

## 위치 지문 {#location-fingerprint}

발견 항목의 위치 지문은 공격 표면의 각 위치마다 고유한 텍스트 값입니다. 각 보안 제품은 공격 표면의 유형에 따라 이를 정의합니다. 예를 들어, SAST는 파일 경로 및 줄 번호를 포함합니다.

## 잠금 파일 {#lockfile}

애플리케이션의 직접 및 간접 종속성과 해당 버전 번호를 나열하는 파일입니다. 재현성을 목적으로 하며, 애플리케이션의 종속성을 설치하는 모든 사용자가 정확히 동일한 버전을 얻도록 보장합니다. `Gemfile.lock`과 같은 일부 잠금 파일은 종속성 관계 정보도 포함하지만 이는 요구 사항이 아닙니다.

관련 용어: [종속성 그래프 내보내기](#dependency-graph-export).

## 패키지 관리자 및 패키지 유형 {#package-managers-and-package-types}

### 패키지 관리자 {#package-managers}

패키지 관리자는 프로젝트 종속성을 관리하는 시스템입니다.

패키지 관리자는 새 종속성(패키지라고도 함)을 설치하는 방법, 패키지가 파일 시스템에 저장되는 위치를 관리하고 자신의 패키지를 게시할 수 있는 기능을 제공합니다.

### 패키지 유형 {#package-types}

각 패키지 관리자, 플랫폼, 유형 또는 에코시스템은 소프트웨어 패키지를 식별, 찾고 프로비저닝하기 위한 자체 규칙 및 프로토콜이 있습니다.

다음 표는 GitLab 문서 및 소프트웨어 도구에서 참조되는 일부 패키지 관리자 및 유형의 비완전한 목록입니다.

<style>
table.package-managers-and-types tr:nth-child(even) {
    background-color: transparent;
}

table.package-managers-and-types td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.package-managers-and-types tr td:first-child {
    border-left: 0;
}

table.package-managers-and-types tr td:last-child {
    border-right: 0;
}

table.package-managers-and-types ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}
</style>

<table class="package-managers-and-types">
  <thead>
    <tr>
      <th>패키지 유형</th>
      <th>패키지 관리자</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>gem</td>
      <td><a href="https://bundler.io/">Bundler</a></td>
    </tr>
    <tr>
      <td>Packagist</td>
      <td><a href="https://getcomposer.org/">Composer</a></td>
    </tr>
    <tr>
      <td>Conan</td>
      <td><a href="https://conan.io/">Conan</a></td>
    </tr>
    <tr>
      <td>go</td>
      <td><a href="https://go.dev/blog/using-go-modules">go</a></td>
    </tr>
    <tr>
      <td rowspan="3">maven</td>
      <td><a href="https://gradle.org/">Gradle</a></td>
    </tr>
    <tr>
      <td><a href="https://maven.apache.org/">Maven</a></td>
    </tr>
    <tr>
      <td><a href="https://www.scala-sbt.org">sbt</a></td>
    </tr>
    <tr>
      <td rowspan="2">npm</td>
      <td><a href="https://www.npmjs.com">npm</a></td>
    </tr>
    <tr>
      <td><a href="https://classic.yarnpkg.com/en">yarn</a></td>
    </tr>
    <tr>
      <td>NuGet</td>
      <td><a href="https://www.nuget.org/">NuGet</a></td>
    </tr>
    <tr>
      <td rowspan="4">PyPI</td>
      <td><a href="https://setuptools.pypa.io/en/latest/">Setuptools</a></td>
    </tr>
    <tr>
      <td><a href="https://pip.pypa.io/en/stable/">pip</a></td>
    </tr>
    <tr>
      <td><a href="https://pipenv.pypa.io/en/latest/">Pipenv</a></td>
    </tr>
    <tr>
      <td><a href="https://python-poetry.org/">Poetry</a></td>
    </tr>
  </tbody>
</table>

## 파이프라인 보안 탭 {#pipeline-security-tab}

연결된 CI 파이프라인에서 발견된 발견 항목을 표시하는 페이지입니다.

## 가능하게 영향을 받는 구성 요소 {#possibly-affected-component}

취약성에 의해 가능하게 영향을 받을 수 있는 소프트웨어 구성 요소입니다. 예를 들어, 프로젝트에서 알려진 취약성을 스캔할 때 구성 요소는 먼저 이름과 [패키지 유형](https://github.com/package-url/purl-spec/blob/main/PURL-TYPES.rst)과 일치하는지 평가됩니다. 이 단계에서 이들은 취약성에 의해 가능하게 영향을 받을 수 있으며, 영향을 받는 버전 범위에 포함되는 것이 확인된 후에만 [알려진 영향을 받는 항목](#known-affected-component)입니다.

## 사후 필터 {#post-filter}

사후 필터는 스캐너 결과의 노이즈를 줄이고 수동 작업을 자동화하는 데 도움이 됩니다. 스캐너 결과를 기반으로 취약성 데이터를 업데이트하거나 수정하는 기준을 지정할 수 있습니다. 예를 들어 발견 항목을 거짓 양성일 가능성으로 플래그하고 더 이상 감지되지 않는 취약성을 자동으로 해결할 수 있습니다. 이는 영구적인 조치가 아니며 변경될 수 있습니다.

발견 항목을 자동으로 해결하는 것은 [에픽 7478](https://gitlab.com/groups/gitlab-org/-/epics/7478)에서 추적되며 저비용 스캔에 대한 지원은 [에픽 7886](https://gitlab.com/groups/gitlab-org/-/epics/7886)에서 제안됩니다.

## 사전 필터 {#pre-filter}

분석이 발생하기 전에 대상을 필터링하기 위해 수행되는 되돌릴 수 없는 조치입니다. 일반적으로 사용자가 범위와 노이즈를 줄이고 분석 속도를 높이도록 제공됩니다. GitLab이 건너뛰거나 제외된 코드 또는 자산과 관련된 항목을 저장하지 않으므로 기록이 필요한 경우 수행하지 않아야 합니다.

예제: `DS_EXCLUDED_PATHS`은(는) `Exclude files and directories from the scan based on the paths provided.`해야 합니다.

## 기본 식별자 {#primary-identifier}

첫 번째 [식별자](#identifier)는 기본 식별자입니다. 기본 식별자는 안정적이어야 합니다. 후속 스캔은 취약성의 위치가 변경되었을 수 있는 경우에도 동일한 발견 항목에 대해 동일한 값을 반환해야 합니다.

## 프로세서 {#processor}

입력을 수락하고 입력 데이터를 수정하거나 출력으로 추가 메타데이터를 첨부하여 지정된 기준에 따라 변환하는 소프트웨어입니다. 프로세서는 스캐너 작업을 지원하기 위해 존재하며 스캔 전/후 단계에서 일반적으로 사용됩니다. [필터](#pre-filter)와 달리 프로세서는 비즈니스 논리를 기반으로 워크플로 계속 또는 종료를 제어하기 위한 의사 결정 기능이 없습니다. 대신 무조건 변환을 수행하고 결과를 전달합니다.

### 전처리기 {#pre-processor}

전처리기는 일반적으로 입력 형식 정규화, 추가 컨텍스트로 스캔 대상 강화, 대상별 변환 적용 또는 구성 매개 변수 강화와 같은 데이터 준비 작업을 수행합니다. 스캐너가 스캔 작업에 최적화된 올바르게 형식화되고 향상된 입력을 받도록 보장합니다.

### 후처리기 {#post-processor}

후처리기는 [스캐너](#scanner)가 작업을 완료한 후 스캔 결과에 지능형 분석을 적용합니다. 후처리기는 취약성 분류, 거짓 양성 필터링, 심각도 조정 및 컨텍스트 강화와 같은 작업을 통해 원본 스캐너 출력을 향상합니다. 스캔 결과는 처리된 결과가 [분석기](#analyzer)로 반환되기 전에 여러 후처리기를 순서대로 통과할 수 있습니다.

## 도달 가능성 {#reachability}

도달 가능성은 프로젝트에서 종속성으로 나열된 [구성 요소](#component)가 실제로 코드베이스에서 사용되는지 여부를 나타냅니다.

## 보고서 발견 항목 {#report-finding}

분석기에서 생성한 보고서에만 존재하며 아직 데이터베이스에 저장되지 않은 [발견 항목](#finding)입니다. 보고서 발견 항목은 데이터베이스로 가져온 후 [취약성 발견 항목](#vulnerability-finding)이 됩니다.

## 스캔 유형(보고서 유형) {#scan-type-report-type}

스캔 유형을 설명합니다. 다음 중 하나여야 합니다:

- `api_fuzzing`
- `container_scanning`
- `coverage_fuzzing`
- `dast`
- `dependency_scanning`
- `sast`
- `secret_detection`

이 목록은 스캐너가 추가되면서 변경될 수 있습니다.

## 스캔 대상 유형 {#scan-target-type}

스캔을 실행하기 위한 범위 경계로 작동하는 개별 콘텐츠 또는 아티팩트 단위입니다. 각 스캔 대상 유형은 정의된 스캔 제약 조건을 가진 독립적인 엔티티를 나타냅니다. 스캔 대상 유형의 특정 인스턴스(예: 특정 Git 리포지토리 또는 컨테이너 이미지)를 "스캔 대상"이라고 합니다. 스캔 대상 유형의 예제에는 Git 리포지토리, 파일 시스템, 컨테이너 등이 포함됩니다.

## 스캐너 {#scanner}

스캔 대상에서 보안 취약성을 스캔하는 소프트웨어([스캔 대상 유형](#scan-target-type)의 인스턴스)입니다. 일반적으로 분석기에서 필요한 스캔 구성 매개 변수 및 스캔 페이로드를 수신하는 상태 비저장 구성 요소입니다. 결과 스캔 보고서는 반드시 [보안 보고서 형식](#secure-report-format)에 있을 필요는 없습니다. 스캐너는 추가 프로세서(예: 시크릿 검색 스캐너)가 있는 하나 이상의 스캔 엔진을 래핑하는 정교한 구성 요소일 수 있으며, Trivy와 같이 독립형 스캔 엔진만큼 간단할 수 있습니다.

## 보안 제품 {#secure-product}

GitLab에서 일등급 지원을 받는 애플리케이션 보안의 특정 영역과 관련된 기능 그룹입니다.

제품에는 컨테이너 스캔, 종속성 검사, 동적 애플리케이션 보안 테스트(DAST), 시크릿 검색, 정적 애플리케이션 보안 테스트(SAST) 및 퍼즈 테스팅이 포함됩니다.

이 각 제품은 일반적으로 하나 이상의 분석기를 포함합니다.

## 보안 보고서 형식 {#secure-report-format}

보안 제품이 JSON 보고서를 생성할 때 준수하는 표준 보고서 형식입니다. 형식은 [JSON 스키마](https://gitlab.com/gitlab-org/security-products/security-report-schemas)로 설명됩니다.

## 보안 대시보드 {#security-dashboard}

프로젝트, 그룹 또는 GitLab 인스턴스의 모든 취약성에 대한 개요를 제공합니다. 취약성은 프로젝트의 기본 브랜치에서 발견된 발견 항목에서만 생성됩니다.

## 시드 코퍼스 {#seed-corpus}

퍼즈 대상에 초기 입력으로 제공되는 테스트 케이스 집합입니다. 이는 일반적으로 퍼즈 대상의 속도를 실질적으로 높입니다. 이는 수동으로 생성된 테스트 케이스 또는 이전 실행에서 퍼즈 대상 자체로 자동 생성될 수 있습니다.

## 공급업체 {#vendor}

분석기를 유지하는 당사자입니다. 따라서 공급업체는 스캐너를 GitLab에 통합하고 진화함에 따라 호환성을 유지할 책임이 있습니다. 공급업체는 오픈 코어 또는 OSS 프로젝트를 제공 서비스의 기본 솔루션으로 사용하는 경우와 같이 스캐너의 작성자 또는 유지보수자일 필요는 없습니다. GitLab 배포 또는 GitLab 구독의 일부로 포함된 스캐너의 경우 공급업체는 GitLab으로 나열됩니다.

## 취약성 {#vulnerability}

해당 환경의 보안에 부정적인 영향을 미치는 결함입니다. 취약성은 오류 또는 약점을 설명하며, 오류가 위치한 위치를 설명하지 않습니다([발견 항목](#finding) 참조).

각 취약성은 고유한 발견 항목에 매핑됩니다.

취약성은 기본 브랜치에 존재합니다. 발견 항목([발견 항목](#finding) 참조)은 스캐너가 MR/기능 분기에서 식별하는 모든 잠재적 취약성 항목입니다. 기본 분기로 병합한 후에만 발견 항목이 취약성이 됩니다.

## 취약성 발견 항목 {#vulnerability-finding}

[보고서 발견 항목](#report-finding)이 데이터베이스에 저장되면 취약성 [발견 항목](#finding)이 됩니다.

## 취약성 추적 {#vulnerability-tracking}

발견 항목의 수명 주기를 이해할 수 있도록 스캔에서 발견 항목을 일치시키는 책임을 다룹니다. 엔지니어 및 보안 팀은 이 정보를 사용하여 코드 변경 사항을 병합할지 여부를 결정하고 미해결 발견 항목과 도입 시점을 확인합니다.

취약성은 위치 지문, 기본 식별자 및 보고서 유형을 비교하여 추적됩니다.

## 취약성 발생 {#vulnerability-occurrence}

더 이상 사용되지 않음, [발견 항목](#finding)을 참조하세요.
