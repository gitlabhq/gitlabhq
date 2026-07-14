---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 코드 인텔리전스
description: LSIF 또는 SCIP 인덱서를 사용하여 코드 인텔리전스를 설정하고 코드 네비게이션 기능을 활성화합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

코드 인텔리전스는 다음을 포함하여 대화형 개발 환경(IDE)에 공통적인 코드 네비게이션 기능을 추가합니다.

- 유형 시그니처 및 기호 설명서입니다.
- 정의로 이동합니다.

코드 인텔리전스는 GitLab에 기본 제공되며 [LSIF](https://lsif.dev/)(언어 서버 인덱스 형식)에 의해 구동되며, 이는 사전 계산된 코드 인텔리전스 데이터를 위한 파일 형식입니다. GitLab은 프로젝트당 하나의 LSIF 파일을 처리하며, 코드 인텔리전스는 브랜치당 다양한 LSIF 파일을 지원하지 않습니다.

[SCIP](https://github.com/sourcegraph/scip/)는 소스 코드 인덱싱을 위한 도구의 다음 진화입니다. 이를 사용하여 다음과 같은 코드 네비게이션 기능을 구동할 수 있습니다.

- 정의로 이동
- 참조 찾기

GitLab은 코드 인텔리전스에 대해 SCIP를 기본 지원하지 않습니다. 그러나 [SCIP CLI](https://github.com/sourcegraph/scip/blob/main/docs/CLI.md)를 사용하여 SCIP 도구로 생성된 인덱스를 LSIF 호환 파일로 변환할 수 있습니다. 기본 SCIP 지원에 대한 논의는 [이슈 412981](https://gitlab.com/gitlab-org/gitlab/-/issues/412981)을 참조하세요.

향후 코드 인텔리전스 개선 사항의 진행 상황은 [에픽 4212](https://gitlab.com/groups/gitlab-org/-/epics/4212)를 참조하세요.

## 코드 인텔리전스 구성 {#configure-code-intelligence}

전제 조건:

- 프로젝트의 언어에 대해 호환되는 인덱서가 있는지 확인했습니다.
  - [LSIF 인덱서](https://lsif.dev/#implementations-server)
  - [SCIP 인덱서](https://github.com/sourcegraph/scip/#tools-using-scip)

언어가 어떻게 가장 잘 지원되는지 확인하려면 [Sourcegraph에서 권장하는 인덱서](https://sourcegraph.com/docs/code-search/code-navigation/writing_an_indexer#sourcegraph-recommended-indexers)를 검토하세요.

### CI/CD 구성 요소를 사용하여 {#with-the-cicd-component}

{{< history >}}

- Python 지원이 GitLab 17.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/301111)되었습니다.
- .Net/C# 지원이 GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/372243)되었습니다.

{{< /history >}}

GitLab은 [CI/CD 구성 요소](../../ci/components/_index.md)를 제공하여 `.gitlab-ci.yml` 파일에서 코드 인텔리전스를 구성합니다. 이 구성 요소는 다음 언어를 지원합니다.

- Go 버전 1.21 이상
- TypeScript 또는 JavaScript
- Java 8, 11, 17, 21
- Python
- .Net/C#

이 구성 요소에 더 많은 언어를 기여하려면 [코드 인텔리전스 구성 요소 프로젝트](https://gitlab.com/components/code-intelligence)에서 머지 리퀘스트를 열어주세요.

1. 프로젝트의 `.gitlab-ci.yml`에 GitLab CI/CD 구성 요소를 추가합니다. 예를 들어, 이 작업은 Go용 LSIF 아티팩트를 생성합니다.

   ```yaml
   include:
     - component: ${CI_SERVER_FQDN}/components/code-intelligence/golang-code-intel@v0.0.3
       inputs:
         golang_version: ${GO_VERSION}
   ```

1. [코드 인텔리전스 구성 요소](https://gitlab.com/components/code-intelligence)의 구성 지침을 확인하려면 지원되는 각 언어의 `README`를 확인하세요.
1. 자세한 내용은 [구성 요소 사용](../../ci/components/_index.md#use-a-component)을 참조하세요.

### CI/CD 작업 코드 인텔리전스 추가 {#add-cicd-jobs-for-code-intelligence}

코드 인텔리전스를 프로젝트에 활성화하려면 프로젝트의 `.gitlab-ci.yml`에 GitLab CI/CD 작업을 추가합니다.

{{< tabs >}}

{{< tab title="SCIP 인덱서 사용" >}}

1. 프로젝트의 `.gitlab-ci.yml` 구성에 작업을 추가합니다. 이 작업은 SCIP 인덱스를 생성하고 GitLab에서 사용하기 위해 LSIF로 변환합니다.

   ```yaml
   "code_navigation":
      rules:
      - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH # the job only needs to run against the default branch
      image: node:latest
      stage: test
      allow_failure: true # recommended
      script:
         - npm install -g @sourcegraph/scip-typescript
         - npm install
         - scip-typescript index
         - |
            env \
            TAG="v0.4.0" \
            OS="$(uname -s | tr '[:upper:]' '[:lower:]')" \
            ARCH="$(uname -m | sed -e 's/x86_64/amd64/')" \
            bash -c 'curl --location "https://github.com/sourcegraph/scip/releases/download/$TAG/scip-$OS-$ARCH.tar.gz"' \
            | tar xzf - scip
         - chmod +x scip
         - ./scip convert --from index.scip --to dump.lsif
      artifacts:
         reports:
            lsif: dump.lsif
   ```

1. CI/CD 구성에 따라 작업을 수동으로 실행하거나 기존 파이프라인의 일부로 실행될 때까지 기다릴 수 있습니다.

{{< /tab >}}

{{< tab title="LSIF 인덱서 사용" >}}

1. 작업(`code_navigation`)을 `.gitlab-ci.yml` 구성에 추가하여 인덱스를 생성합니다.

   ```yaml
   code_navigation:
      rules:
      - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH # the job only needs to run against the default branch
     image: sourcegraph/lsif-go:v1
     allow_failure: true # recommended
     script:
       - lsif-go
     artifacts:
       reports:
         lsif: dump.lsif
   ```

1. CI/CD 구성에 따라 작업을 수동으로 실행하거나 기존 파이프라인의 일부로 실행될 때까지 기다릴 수 있습니다.

{{< /tab >}}

{{< /tabs >}}

> [!note]
> GitLab은 코드 생성 작업에 의해 생성된 아티팩트를 [(`ci_max_artifact_size_lsif`)](../../administration/cicd/limits.md#maximum-file-size-per-type-of-artifact) 아티팩트 애플리케이션 제한에 따라 200MB로 제한합니다. GitLab Self-Managed 인스턴스에서 인스턴스 관리자가 이 값을 변경할 수 있습니다.

## 코드 인텔리전스 결과 보기 {#view-code-intelligence-results}

작업이 성공한 후 리포지토리를 검색하여 코드 인텔리전스 정보를 확인합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **리포지토리**를 선택합니다.
1. 리포지토리의 파일로 이동합니다. 파일 이름을 알고 있다면 다음 중 하나를 선택합니다.
   - `/~` 키보드 단축키를 입력하여 파일 찾기를 열고 파일의 이름을 입력합니다.
   - 오른쪽 상단에서 **파일 찾기**를 선택합니다.
1. 코드 라인을 가리킵니다. 코드 인텔리전스 정보가 있는 해당 라인의 항목이 아래에 점선으로 표시됩니다.

   ![코드 인텔리전스](img/code_intelligence_v17_0.png)

1. 항목을 선택하여 이에 대한 자세한 정보를 알아봅니다.

## 참조 찾기 {#find-references}

코드 인텔리전스를 사용하여 프로젝트의 모든 객체 사용을 확인합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **리포지토리**를 선택합니다.
1. 리포지토리의 파일로 이동합니다. 파일 이름을 알고 있다면 다음 중 하나를 선택합니다.
   - `/~` 키보드 단축키를 입력하여 파일 찾기를 열고 파일의 이름을 입력합니다.
   - 오른쪽 상단에서 **파일 찾기**를 선택합니다.
1. 객체를 가리킨 후 선택합니다.
1. 대화 상자에서 다음을 선택합니다.
   - **정의**를 선택하여 이 객체의 정의를 확인합니다.
   - **참조**를 선택하여 이 객체를 사용하는 파일의 목록을 확인합니다.

   ![이 변수는 이 프로젝트에서 두 번 참조됩니다.](img/code_intelligence_refs_v17_6.png)
