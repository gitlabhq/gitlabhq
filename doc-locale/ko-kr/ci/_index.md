---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 애플리케이션을 빌드하고 테스트합니다.
title: GitLab CI/CD 시작하기
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD는 지속적으로 빌드, 테스트, 배포하고 반복적인 코드 변경을 모니터링하는 연속적인 소프트웨어 개발 방법입니다.

이 반복적인 프로세스는 버그가 있거나 실패한 이전 버전을 기반으로 새 코드를 개발할 가능성을 줄이는 데 도움이 됩니다. GitLab CI/CD는 개발 주기의 초기 단계에서 버그를 발견할 수 있으며, 프로덕션에 배포된 코드가 설정된 코드 표준을 준수하도록 돕습니다.

이 프로세스는 더 큰 워크플로의 일부입니다:

![계획, 생성, 검증, 보안, 릴리스 및 모니터링 스테이지가 있는 GitLab DevSecOps 수명 주기](img/get_started_cicd_v16_11.png)

## 1단계:  파이프라인 구성 {#step-1-configure-your-pipeline}

GitLab CI/CD를 사용하려면 프로젝트의 루트에 `.gitlab-ci.yml` 파일로 시작합니다. 이 파일은 CI/CD 파이프라인 중에 실행될 스테이지, 작업 및 스크립트를 지정합니다. 이는 고유한 사용자 지정 구문이 있는 YAML 파일입니다.

기본적으로 파일의 이름은 `.gitlab-ci.yml`이지만 모든 파일 이름을 사용할 수 있습니다.

이 파일에서 변수, 작업 간 종속성을 정의하고 각 작업을 실행할 시기와 방법을 지정합니다.

파이프라인은 `.gitlab-ci.yml` 파일에 정의되며 파일이 러너에서 실행될 때 동작합니다.

파이프라인은 스테이지와 작업으로 구성됩니다:

- 스테이지는 실행 순서를 정의합니다. 일반적인 스테이지는 `build`, `test`, `deploy`일 수 있습니다.
- 작업은 각 스테이지에서 수행할 작업을 지정합니다. 예를 들어, 작업은 코드를 컴파일하거나 테스트할 수 있습니다.

파이프라인은 커밋 또는 병합과 같은 다양한 이벤트에 의해 트리거되거나 일정에 따라 실행될 수 있습니다. 파이프라인에서 광범위한 도구 및 플랫폼과 통합할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [튜토리얼: 첫 GitLab CI/CD 파이프라인 생성 및 실행](quick_start/_index.md)
- [파이프라인](pipelines/_index.md)

## 2단계:  러너 찾기 또는 생성 {#step-2-find-or-create-runners}

러너는 작업을 실행하는 에이전트입니다. 이러한 에이전트는 물리적 머신 또는 가상 인스턴스에서 실행될 수 있습니다. `.gitlab-ci.yml` 파일에서 작업을 실행할 때 사용할 컨테이너 이미지를 지정할 수 있습니다. 러너는 이미지를 로드하고 프로젝트를 복제한 다음 작업을 로컬로 또는 컨테이너에서 실행합니다.

GitLab.com을 사용하는 경우 Linux, Windows, macOS의 러너를 이미 사용할 수 있습니다. 필요한 경우 자신의 러너를 등록할 수도 있습니다.

GitLab.com을 사용하지 않는 경우 다음을 수행할 수 있습니다:

- 러너를 등록하거나 GitLab Self-Managed 인스턴스에 이미 등록된 러너를 사용합니다.
- 로컬 머신에서 러너를 생성합니다.

자세한 정보는 다음을 참조하세요:

- [자신의 프로젝트 러너 생성, 등록 및 실행](../tutorials/create_register_first_runner/_index.md)

## 3단계:  CI/CD 변수와 표현식 사용 {#step-3-use-cicd-variables-and-expressions}

GitLab CI/CD 변수는 구성 설정 및 암호나 API 키와 같은 민감한 정보를 저장하고 파이프라인의 작업에 전달하는 데 사용하는 키-값 쌍입니다.

GitLab CI/CD 표현식을 사용하면 파이프라인 구성에 데이터를 동적으로 주입할 수 있습니다. 사용 가능한 데이터는 표현식 컨텍스트에 따라 달라집니다. 예를 들어, `inputs` 컨텍스트는 상위 파일에서 또는 파이프라인이 실행될 때 구성 파일에 전달된 정보에 액세스할 수 있습니다.

### CI/CD 변수 {#cicd-variables}

다른 곳에서 정의된 값을 작업에 액세스할 수 있도록 하여 CI/CD 변수로 작업을 사용자 지정합니다. CI/CD 변수를 `.gitlab-ci.yml` 파일에 하드코딩하거나 프로젝트 설정에서 설정하거나 동적으로 생성할 수 있습니다. 프로젝트, 그룹 또는 인스턴스에 대해 정의할 수 있습니다.

다음과 같은 유형의 변수를 사용할 수 있습니다:

- 사용자 지정 변수:  UI, API 또는 구성 파일에서 생성하고 관리하는 변수입니다.
- 미리 정의된 변수:  현재 작업, 파이프라인 및 환경에 대한 정보를 제공하기 위해 GitLab이 자동으로 설정하는 변수입니다.

보안 설정으로 변수를 구성할 수 있습니다:

- 보호된 변수:  보호된 브랜치 또는 태그에서 실행 중인 작업에 대한 액세스를 제한합니다.
- 마스킹된 변수:  작업 로그에서 변수 값을 숨겨 민감한 정보가 노출되지 않도록 합니다.

자세한 정보는 다음을 참조하세요:

- [CI/CD 변수](variables/_index.md)

### CI/CD 표현식 {#cicd-expressions}

CI/CD 표현식은 `$[[ ]]` 구문을 사용하며 파이프라인을 생성할 때 검증됩니다. 파이프라인 편집기에서 변경 사항을 커밋하기 전에 표현식을 검증할 수도 있습니다.

표현식은 다양한 컨텍스트를 기반으로 동적 구성을 활성화합니다:

- **Inputs context** (`$[[ inputs.INPUT_NAME ]]`):  `include:inputs`를 통해 또는 새 파이프라인이 실행될 때 구성 파일에 전달된 유형 매개변수에 액세스합니다.
- **Matrix context** (`$[[ matrix.IDENTIFIER ]]`):  작업 종속성의 행렬 값에 액세스하여 행렬 작업 간 1:1 매핑을 만듭니다.

자세한 정보는 다음을 참조하세요:

- [CI 표현식](yaml/expressions.md)

## 4단계:  CI/CD 구성 요소 사용 {#step-4-use-cicd-components}

CI/CD 구성 요소는 재사용 가능한 파이프라인 구성 단위입니다. CI/CD 구성 요소를 사용하여 전체 파이프라인 구성 또는 더 큰 파이프라인의 작은 부분을 구성합니다.

`include:component`를 사용하여 파이프라인 구성에 구성 요소를 추가할 수 있습니다.

재사용 가능한 구성 요소는 중복을 줄이고, 유지 보수성을 개선하며, 프로젝트 전체의 일관성을 촉진하는 데 도움이 됩니다. 구성 요소 프로젝트를 생성하고 CI/CD 카탈로그에 게시하여 여러 프로젝트에 구성 요소를 공유합니다.

GitLab에는 일반적인 작업 및 통합을 위한 CI/CD 구성 요소 템플릿도 있습니다.

자세한 정보는 다음을 참조하세요:

- [CI/CD 구성 요소](components/_index.md)
