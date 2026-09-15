---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 종속성 검사 문제 해결
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

종속성 검사로 작업할 때 다음과 같은 문제가 발생할 수 있습니다.

## 디버그 수준 로깅 {#debug-level-logging}

디버그 수준 로깅은 문제 해결에 도움이 될 수 있습니다. 자세한 내용은 [디버그 수준 로깅](../../troubleshooting_application_security.md#turn-on-debug-level-logging)을 참조하세요.

## 로컬 환경에서 분석기 실행 {#run-the-analyzer-in-a-local-environment}

파이프라인을 실행하지 않고 로컬에서 종속성 검사 분석기를 실행하여 문제를 디버깅하거나 동작을 검증할 수 있습니다.

예를 들어 Python 분석기를 실행하려면:

```shell
cd project-git-repository

docker run \
   --interactive --tty --rm \
   --volume "$PWD":/tmp/app \
   --env CI_PROJECT_DIR=/tmp/app \
   --env SECURE_LOG_LEVEL=debug \
   -w /tmp/app \
   registry.gitlab.com/security-products/gemnasium-python:5 /analyzer run
```

이 명령은 디버그 수준 로깅으로 분석기를 실행하고 로컬 리포지토리를 마운트하여 종속성을 분석합니다. `registry.gitlab.com/security-products/gemnasium-python:5`을(를) 프로젝트의 언어 및 종속성 관리자에 적합한 스캐너 `image:tag` 조합으로 바꿀 수 있습니다.

### 특정 언어 또는 패키지 관리자의 누락된 지원 해결 {#working-around-missing-support-for-certain-languages-or-package-managers}

[지원되는 언어](_index.md#supported-languages-and-package-managers)에 언급된 대로 일부 종속성 정의 파일은 아직 지원되지 않습니다. 그러나 언어, 패키지 관리자 또는 타사 도구가 정의 파일을 지원되는 형식으로 변환할 수 있다면 종속성 검사를 구현할 수 있습니다.

일반적으로 접근 방식은 다음과 같습니다:

1. `.gitlab-ci.yml` 파일에서 전용 변환기 작업을 정의합니다. 적절한 Docker 이미지, 스크립트 또는 둘 다를 사용하여 변환을 수행합니다.
1. 해당 작업이 변환된 지원되는 파일을 아티팩트로 업로드하도록 합니다.
1. [`dependencies: [<your-converter-job>]`](../../../../ci/yaml/_index.md#dependencies)을(를) `dependency_scanning` 작업에 추가하여 변환된 정의 파일을 사용합니다.

예를 들어 `pyproject.toml` 파일만 있는 Poetry 프로젝트는 `poetry.lock` 파일을 다음과 같이 생성할 수 있습니다.

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

stages:
  - test

gemnasium-python-dependency_scanning:
  # Work around https://gitlab.com/gitlab-org/gitlab/-/issues/32774
  before_script:
    - pip install "poetry>=1,<2"  # Or via another method: https://python-poetry.org/docs/#installation
    - poetry update --lock # Generates the lockfile to be analyzed.
```

## 종속성 검사 작업이 예상치 않게 실행 중 {#dependency-scanning-jobs-are-running-unexpectedly}

[종속성 검사 CI 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)은 [`rules:exists`](../../../../ci/yaml/_index.md#rulesexists) 구문을 사용합니다. 이 지시문은 10000개 검사로 제한되며 이 숫자에 도달한 후 항상 `true`을(를) 반환합니다. 이로 인해 리포지토리의 파일 수에 따라 스캐너가 프로젝트를 지원하지 않더라도 종속성 검사 작업이 트리거될 수 있습니다. 이 제한 사항에 대한 자세한 내용은 [`rules:exists` 설명서](../../../../ci/yaml/_index.md#rulesexists)를 참조하세요.

## 오류: `dependency_scanning is used for configuration only, and its script should not be executed` {#error-dependency_scanning-is-used-for-configuration-only-and-its-script-should-not-be-executed}

자세한 내용은 [애플리케이션 보안 테스트 문제 해결](../../troubleshooting_application_security.md#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed)을(를) 참조하세요.

## Java 기반 프로젝트를 위한 여러 인증서 가져오기 {#import-multiple-certificates-for-java-based-projects}

`gemnasium-maven` 분석기는 `keytool`을(를) 사용하여 `ADDITIONAL_CA_CERT_BUNDLE` 변수의 내용을 읽으며, 이는 단일 인증서 또는 인증서 체인을 가져옵니다. 여러 관련 없는 인증서는 무시되고 `keytool`에 의해 첫 번째 인증서만 가져옵니다.

분석기에 여러 관련 없는 인증서를 추가하려면 `gemnasium-maven-dependency_scanning` 작업의 정의에서 이와 같은 `before_script`을(를) 선언할 수 있습니다:

```yaml
gemnasium-maven-dependency_scanning:
  before_script:
    - . $HOME/.bashrc # make the java tools available to the script
    - OIFS="$IFS"; IFS=""; echo $ADDITIONAL_CA_CERT_BUNDLE > multi.pem; IFS="$OIFS" # write ADDITIONAL_CA_CERT_BUNDLE variable to a PEM file
    - csplit -z --digits=2 --prefix=cert multi.pem "/-----END CERTIFICATE-----/+1" "{*}" # split the file into individual certificates
    - for i in `ls cert*`; do keytool -v -importcert -alias "custom-cert-$i" -file $i -trustcacerts -noprompt -storepass changeit -keystore /opt/asdf/installs/java/adoptopenjdk-11.0.7+10.1/lib/security/cacerts 1>/dev/null 2>&1 || true; done # import each certificate using keytool (note the keystore location is related to the Java version being used and should be changed accordingly for other versions)
    - unset ADDITIONAL_CA_CERT_BUNDLE # unset the variable so that the analyzer doesn't duplicate the import
```

## 종속성 검사 작업이 메시지 `strconv.ParseUint: parsing "0.0": invalid syntax`로 실패합니다. {#dependency-scanning-job-fails-with-message-strconvparseuint-parsing-00-invalid-syntax}

Docker-in-Docker는 지원되지 않으며 이를 호출하려고 시도하는 것이 이 오류의 가능한 원인입니다.

이 오류를 해결하려면 종속성 검사에 대해 Docker-in-Docker를 비활성화합니다. CI/CD 파이프라인에서 실행되는 각 분석기에 대해 개별 `<analyzer-name>-dependency_scanning` 작업이 생성됩니다.

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_DISABLE_DIND: "true"
```

## 메시지 `<file> does not exist in <commit SHA>` {#message-file-does-not-exist-in-commit-sha}

파일의 종속성의 `Location`이(가) 표시되면 링크의 경로는 특정 Git SHA로 이동합니다.

그러나 종속성 검사 도구가 검토한 잠금 파일이 캐시된 경우 해당 링크를 선택하면 리포지토리 루트로 리디렉션되며 다음 메시지가 표시됩니다: `<file> does not exist in <commit SHA>`.

잠금 파일은 빌드 단계 중에 캐시되고 스캔이 수행되기 전에 종속성 검사 작업에 전달됩니다. 캐시가 분석기 실행 전에 다운로드되므로 `CI_BUILDS_DIR` 디렉터리의 잠금 파일이 존재하면 종속성 검사 작업이 트리거됩니다.

이 경고를 방지하려면 잠금 파일을 커밋해야 합니다.

## `DS_MAJOR_VERSION` 또는 `DS_ANALYZER_IMAGE`을(를) 설정한 후 더 이상 최신 Docker 이미지를 얻지 못함 {#you-no-longer-get-the-latest-docker-image-after-setting-ds_major_version-or-ds_analyzer_image}

`DS_MAJOR_VERSION` 또는 `DS_ANALYZER_IMAGE`을(를) 특정 이유로 수동으로 설정했고 이제 최신 패치된 버전의 분석기를 다시 가져오도록 구성을 업데이트해야 하는 경우 `.gitlab-ci.yml` 파일을 편집하고 다음 중 하나를 수행합니다:

- `DS_MAJOR_VERSION`을(를) [종속성 검사 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml#L17)에서 참조하는 버전과 일치하도록 설정합니다.
- `DS_ANALYZER_IMAGE` 변수를 직접 하드코딩한 경우 [종속성 검사 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)에서 찾은 최신 줄과 일치하도록 변경합니다. 줄 번호는 편집한 검사 작업에 따라 다릅니다.

  예를 들어 `gemnasium-maven-dependency_scanning` 작업은 최신 `gemnasium-maven` Docker 이미지를 가져옵니다. 이는 `DS_ANALYZER_IMAGE`이(가) `"$SECURE_ANALYZERS_PREFIX/gemnasium-maven:$DS_MAJOR_VERSION"`로 설정되었기 때문입니다.

## setuptools 프로젝트의 종속성 검사가 `use_2to3 is invalid` 오류로 실패함 {#dependency-scanning-of-setuptools-project-fails-with-use_2to3-is-invalid-error}

[2to3](https://docs.python.org/3/library/2to3.html)에 대한 지원이 `setuptools` 버전 `v58.0.0`에서 [제거](https://setuptools.pypa.io/en/latest/history.html#v58-0-0)되었습니다. 종속성 검사(`python 3.9` 실행)은 `setuptools` 버전 `58.1.0+`을(를) 사용하며, `2to3`을(를) 지원하지 않습니다. 따라서 `setuptools`에 의존하는 `lib2to3` 종속성은 이 메시지와 함께 실패합니다:

```plaintext
error in <dependency name> setup command: use_2to3 is invalid
```

이 오류를 해결하려면 분석기의 `setuptools` 버전을 다운그레이드합니다(예: `v57.5.0`):

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - pip install setuptools==57.5.0
```

## psycopg2를 사용하는 프로젝트의 종속성 검사가 `pg_config executable not found` 오류로 실패함 {#dependency-scanning-of-projects-using-psycopg2-fails-with-pg_config-executable-not-found-error}

`psycopg2`에 의존하는 Python 프로젝트 검사가 이 메시지와 함께 실패할 수 있습니다:

```plaintext
Error: pg_config executable not found.
```

[psycopg2](https://pypi.org/project/psycopg2/)는 `libpq-dev` Debian 패키지에 의존하며, 이는 `gemnasium-python` Docker 이미지에 설치되어 있지 않습니다. 이 오류를 해결하려면 `before_script`에 `libpq-dev` 패키지를 설치하세요:

```yaml
gemnasium-python-dependency_scanning:
  before_script:
    - apt-get update && apt-get install -y libpq-dev
```

## `NoSuchOptionException``CI_JOB_TOKEN`과(와) 함께 `poetry config http-basic`을(를) 사용할 때 {#nosuchoptionexception-when-using-poetry-config-http-basic-with-ci_job_token}

이 오류는 자동으로 생성된 `CI_JOB_TOKEN`이(가) 하이픈(`-`)으로 시작할 때 발생할 수 있습니다. 이 오류를 방지하려면 [Poetry의 구성 조언](https://python-poetry.org/docs/repositories/#configuring-credentials)을 따르세요.

## 오류: 프로젝트에 미해결 종속성이 있음 {#error-project-has-unresolved-dependencies}

다음 오류 메시지는 `build.gradle` 또는 `build.gradle.kts` 파일로 인해 발생한 Gradle 종속성 해결 문제를 나타냅니다:

- `project has unresolved dependencies: ["dependency_name:version"]`

`gemnasium-maven`은(는) 미해결 종속성을 처리하는 방법을 제어하는 데 사용할 수 있는 `DS_GRADLE_RESOLUTION_POLICY` 환경 변수를 지원합니다. 기본적으로 미해결 종속성이 발생하면 검사가 실패합니다. 그러나 환경 변수 `DS_GRADLE_RESOLUTION_POLICY`을(를) `"none"`로 설정하여 검사가 계속되고 부분 결과를 생성하도록 허용할 수 있습니다.

`build.gradle` 파일을 수정하는 방법에 대한 지침은 [Gradle 종속성 해결 설명서](https://docs.gradle.org/current/userguide/dependency_resolution.html)를 참조하세요. 자세한 내용은 [이슈 482650](https://gitlab.com/gitlab-org/gitlab/-/issues/482650)을(를) 참조하세요.

또한 Kotlin 2.0.0의 알려진 문제가 종속성 해결에 영향을 미치며, 이는 Kotlin 2.0.20에서 수정될 예정입니다. 자세한 내용은 [이 이슈](https://github.com/gradle/github-dependency-graph-gradle-plugin/issues/140#issuecomment-2230255380)를 참조하세요.

## Go 프로젝트 검사 시 빌드 제약 조건 설정 {#setting-build-constraints-when-scanning-go-projects}

종속성 검사는 `linux/amd64` 컨테이너에서 실행됩니다. 결과적으로 Go 프로젝트를 위해 생성된 빌드 목록에는 이 환경과 호환되는 종속성이 포함됩니다. 배포 환경이 `linux/amd64`이 아니면 최종 종속성 목록에 호환되지 않는 추가 모듈이 포함될 수 있습니다. 종속성 목록에 배포 환경과만 호환되는 모듈이 생략될 수도 있습니다. 이 문제를 방지하려면 `GOOS` 및 `GOARCH` [환경 변수](https://go.dev/ref/mod#minimal-version-selection)를 설정하여 빌드 프로세스를 배포 환경의 운영 체제 및 아키텍처를 대상으로 하도록 구성할 수 있습니다. `.gitlab-ci.yml` 파일의

예를 들어:

```yaml
variables:
  GOOS: "darwin"
  GOARCH: "arm64"
```

`GOFLAGS` 변수를 사용하여 빌드 태그 제약 조건을 제공할 수도 있습니다:

```yaml
variables:
  GOFLAGS: "-tags=test_feature"
```

## Go 프로젝트의 종속성 검사가 거짓 양성을 반환함 {#dependency-scanning-of-go-projects-returns-false-positives}

`go.sum` 파일에는 프로젝트의 [빌드 목록](https://go.dev/ref/mod#glos-build-list)을 생성하는 동안 고려된 모든 모듈의 항목이 포함되어 있습니다. `go.sum` 파일에는 여러 모듈 버전이 포함되어 있지만 `go build`에서 사용하는 [MVS](https://go.dev/ref/mod#minimal-version-selection) 알고리즘은 하나만 선택합니다. 결과적으로 종속성 검사에서 `go.sum`을(를) 사용하면 거짓 양성을 보고할 수 있습니다.

거짓 양성을 방지하기 위해 Gemnasium은 Go 프로젝트의 빌드 목록을 생성할 수 없는 경우에만 `go.sum`을(를) 사용합니다. `go.sum`이(가) 선택되면 경고가 발생합니다:

```shell
[WARN] [Gemnasium] [2022-09-14T20:59:38Z] ▶ Selecting "go.sum" parser for "/test-projects/gitlab-shell/go.sum". False positives may occur. See https://gitlab.com/gitlab-org/gitlab/-/issues/321081.
```

## `ssh`을(를) 사용하려고 시도할 때 `Host key verification failed` {#host-key-verification-failed-when-trying-to-use-ssh}

모든 `gemnasium` 이미지에 `openssh-client`을(를) 설치한 후 `ssh`을(를) 사용하면 `Host key verification failed` 메시지가 나타날 수 있습니다. 설정 중에 `~`를 사용하여 사용자 디렉터리를 나타내는 경우 이미지를 빌드할 때 `$HOME`을(를) `/tmp`로 설정하면 이가 발생할 수 있습니다. 이 문제는 [`gemnasium-python` 이미지를 사용할 때 SSH를 통한 프로젝트 복제 실패](https://gitlab.com/gitlab-org/gitlab/-/issues/374571)에 설명되어 있습니다. `openssh-client`은(는) `/root/.ssh/known_hosts`을(를) 찾을 것으로 예상하지만 이 경로는 존재하지 않습니다. 대신 `/tmp/.ssh/known_hosts`이(가) 존재합니다.

이것은 `openssh-client`이(가) 사전 설치된 `gemnasium-python`에서 해결되었지만 다른 이미지에서 `openssh-client`을(를) 처음부터 설치할 때 문제가 발생할 수 있습니다. 이를 해결하려면 다음 중 하나를 수행할 수 있습니다:

1. 키와 호스트를 설정할 때 절대 경로(`/root/.ssh/known_hosts` 대신 `~/.ssh/known_hosts`)를 사용합니다.
1. `UserKnownHostsFile`을(를) `ssh` 구성에 추가하여 관련 `known_hosts` 파일을 지정합니다. 예: `echo 'UserKnownHostsFile /tmp/.ssh/known_hosts' >> /etc/ssh/ssh_config`.

## `ERROR: THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE` {#error-these-packages-do-not-match-the-hashes-from-the-requirements-file}

이 오류는 `requirements.txt` 파일의 패키지 해시가 다운로드된 패키지의 해시와 일치하지 않을 때 발생합니다. 보안 조치로 `pip`은(는) 패키지가 손상되었다고 가정하고 설치를 거부합니다. 이를 해결하려면 요구 사항 파일에 포함된 해시가 올바른지 확인하세요. [`pip-compile`](https://pip-tools.readthedocs.io/en/stable/)에서 생성한 요구 사항 파일의 경우 `pip-compile --generate-hashes`을(를) 실행하여 해시가 최신 상태인지 확인하세요. [`pipenv`](https://pipenv.pypa.io/)에서 생성한 `Pipfile.lock`을(를) 사용하는 경우 `pipenv verify`을(를) 실행하여 잠금 파일에 최신 패키지 해시가 포함되어 있는지 확인하세요.

## `ERROR: In --require-hashes mode, all requirements must have their versions pinned with ==` {#error-in---require-hashes-mode-all-requirements-must-have-their-versions-pinned-with-}

이 오류는 GitLab Runner가 사용하는 것과 다른 플랫폼에서 요구 사항 파일이 생성된 경우 발생합니다. 다른 플랫폼을 대상으로 하는 지원은 [이슈 416376](https://gitlab.com/gitlab-org/gitlab/-/issues/416376)에서 추적됩니다.

## 편집 가능 플래그로 인해 Python 종속성 검사가 중단될 수 있음 {#editable-flags-can-cause-dependency-scanning-for-python-to-hang}

`requirements.txt` 파일에서 [`-e/--editable`](https://pip.pypa.io/en/stable/cli/pip_install/#install-editable) 플래그를 사용하여 현재 디렉터리를 대상으로 하면 Gemnasium Python 종속성 검사 스캐너가 `pip3 download`을(를) 실행할 때 중단되는 문제가 발생할 수 있습니다. 이 명령은 대상 프로젝트를 빌드하는 데 필요합니다.

이 문제를 해결하려면 Python에 대해 종속성 검사를 실행할 때 `-e/--editable` 플래그를 사용하지 마세요.

## SBT로 메모리 부족 오류 처리 {#handling-out-of-memory-errors-with-sbt}

Scala 프로젝트에서 종속성 검사를 사용하는 동안 SBT로 메모리 부족 오류가 발생하면 [`SBT_CLI_OPTS`](_index.md#analyzer-specific-settings) 환경 변수를 설정하여 이를 해결할 수 있습니다. 구성 예는 다음과 같습니다:

```yaml
variables:
  SBT_CLI_OPTS: "-J-Xmx8192m -J-Xms4192m -J-Xss2M"
```

Kubernetes 실행기를 사용하는 경우 기본 Kubernetes 리소스 설정을 재정의해야 할 수 있습니다. 메모리 문제를 방지하기 위해 컨테이너 리소스를 조정하는 방법에 대한 자세한 내용은 [Kubernetes 실행기 설명서](https://docs.gitlab.com/runner/executors/kubernetes/#overwrite-container-resources)를 참조하세요.

## NPM 프로젝트에 `package-lock.json` 파일이 없음 {#no-package-lockjson-file-in-npm-projects}

기본적으로 종속성 검사 작업은 리포지토리에 `package-lock.json` 파일이 있을 때만 실행됩니다. 그러나 일부 NPM 프로젝트는 Git 리포지토리에 저장하는 대신 빌드 프로세스 중에 `package-lock.json` 파일을 생성합니다.

이러한 프로젝트의 종속성을 검사하려면:

1. 빌드 작업에서 `package-lock.json` 파일을 생성합니다.
1. 생성된 파일을 아티팩트로 저장합니다.
1. 종속성 검사 작업을 수정하여 아티팩트를 사용하고 규칙을 조정합니다.

예를 들어 구성이 다음과 같이 보일 수 있습니다:

```yaml
include:
  - template: Dependency-Scanning.gitlab-ci.yml

build:
  script:
    - npm i
  artifacts:
    paths:
      - package-lock.json  # Store the generated package-lock.json as an artifact

gemnasium-dependency_scanning:
  needs: ["build"]
  rules:
    - if: "$DEPENDENCY_SCANNING_DISABLED == 'true' || $DEPENDENCY_SCANNING_DISABLED == '1'"
      when: never
    - if: "$DS_EXCLUDED_ANALYZERS =~ /gemnasium([^-]|$)/"
      when: never
    - if: $CI_COMMIT_BRANCH && $GITLAB_FEATURES =~ /\bdependency_scanning\b/ && $CI_GITLAB_FIPS_MODE == "true"
      variables:
        DS_IMAGE_SUFFIX: "-fips"
        DS_REMEDIATE: 'false'
    - if: "$CI_COMMIT_BRANCH && $GITLAB_FEATURES =~ /\\bdependency_scanning\\b/"
```

## 파이프라인에 추가된 종속성 검사 작업 없음 {#no-dependency-scanning-job-added-to-the-pipeline}

종속성 검사 작업은 규칙을 사용하여 종속성이 있는 잠금 파일 또는 빌드 도구 관련 파일이 존재하는지 확인합니다. 이러한 파일이 감지되지 않으면 파이프라인의 다른 작업에서 잠금 파일이 생성되더라도 작업이 파이프라인에 추가되지 않습니다.

이 상황이 발생하면 리포지토리에 [지원되는 파일](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)이 포함되어 있거나 지원되는 파일이 런타임에 생성된다는 것을 나타내는 파일이 포함되어 있는지 확인하세요. 종속성 검사 작업을 트리거하기 위해 리포지토리에 이러한 파일을 추가할 수 있는지 고려하세요.

리포지토리에 실제로 이러한 파일이 포함되어 있고 작업이 여전히 트리거되지 않는다고 생각하는 경우 다음 정보와 함께 [이슈를 열기](https://gitlab.com/gitlab-org/gitlab/-/issues/new)를 수행하세요:

- 사용 중인 언어 및 빌드 도구입니다.
- 제공하는 잠금 파일의 종류와 생성되는 위치입니다.

[종속성 검사 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml#L269-270)에 직접 기여할 수도 있습니다.

## 종속성 검사가 `gradlew: permission denied`로 실패합니다. {#dependency-scanning-fails-with-gradlew-permission-denied}

`permission denied` `gradlew`의 오류는 일반적으로 `gradlew`이 실행 가능 비트가 설정되지 않은 상태로 리포지토리에 체크인되었음을 나타냅니다. 오류는 다음 메시지와 함께 작업에 나타날 수 있습니다:

```plaintext
[FATA] [gemnasium-maven] [2024-11-14T21:55:59Z] [/go/src/app/cmd/gemnasium-maven/main.go:65] ▶ fork/exec /builds/path/to/gradlew: permission denied
```

`chmod +ux gradlew`을(를) 로컬로 실행하여 Git 리포지토리에 푸시하여 파일을 실행 가능하게 만듭니다.

## 지원되지 않는 Gradle 버전으로 인해 종속성 검사 nebula 잠금 생성이 실패함 {#dependency-scanning-nebula-lock-creation-fails-due-to-unsupported-gradle-version}

지원되지 않는 Gradle 버전(9.0 이상)으로 [dependency.lockfiles](../dependency_scanning_sbom/_index.md#dependency-lock-plugin)을(를) 생성하려고 시도할 때 다음 오류가 발생합니다:

```plaintext
FAILURE: Build failed with an exception.
* Where:
Initialization script '/builds/gitlab-org/app/app/nebula.gradle' line: 11
* What went wrong:
Failed to notify build listener.
> org/gradle/util/NameMatcher
```

gradle 빌드를 Gradle 8.10.2로 다운그레이드해 보세요.

## 종속성 검사 스캐너는 더 이상 `Gemnasium`이 아닙니다. {#dependency-scanning-scanner-is-no-longer-gemnasium}

역사적으로 종속성 검사에서 사용되는 스캐너는 `Gemnasium`이며 이것이 사용자가 [취약성 페이지](../../vulnerabilities/_index.md)에서 볼 수 있는 것입니다.

[SBOM을 사용한 종속성 검사](../dependency_scanning_sbom/_index.md) 출시로 `Gemnasium` 스캐너는 기본 제공 `GitLab SBoM Vulnerability Scanner`으로 교체되었습니다. 이 새로운 스캐너는 더 이상 CI/CD 작업에서 실행되지 않고 GitLab 플랫폼 내에서 실행됩니다. 두 스캐너가 동일한 결과를 제공할 것으로 예상되지만 SBOM 검사가 기존 종속성 검사 CI/CD 작업 후에 발생하므로 기존 취약성은 새 `GitLab SBoM Vulnerability Scanner`로 스캐너 값이 업데이트됩니다.

`GitLab SBoM Vulnerability Scanner`은(는) GitLab 기본 제공 종속성 검사 기능의 유일한 예상 값입니다.

## 최신 SBOM을 기반으로 업데이트되지 않는 프로젝트 종속성 검사 목록 {#dependency-list-for-project-not-being-updated-based-on-latest-sbom}

SBOM을 생성할 파이프라인에 실패한 작업이 있으면 `DeleteNotPresentOccurrencesService`이(가) 실행되지 않아 종속성 검사 목록이 변경되거나 업데이트되지 않습니다. SBOM을 업로드하는 다른 성공적인 작업이 있고 파이프라인 전체가 성공적이더라도 이것이 발생할 수 있습니다. 이는 관련 보안 검사 작업이 실패할 때 종속성 검사 목록에서 종속성이 실수로 제거되는 것을 방지하기 위해 설계되었습니다. 프로젝트 종속성 검사 목록이 예상대로 업데이트되지 않으면 파이프라인에서 실패한 SBOM 관련 작업을 확인하고 수정하거나 제거하세요.

## 종속성 검사가 `open /etc/ssl/certs/ca-certificates.crt: permission denied`로 실패합니다. {#dependency-scanning-fails-with-open-etcsslcertsca-certificatescrt-permission-denied}

이 오류는 일반적으로 컨테이너를 실행하는 사용자가 `root` 그룹에 속하지 않음을 나타냅니다. 사용자가 `id`을(를) 실행하여 그룹에 속하는지 확인하세요.

```shell
$ id
uid=1000(node) gid=0(root) groups=0(root),1000(node)
```

OpenShift를 실행 중이거나 Kubernetes 실행기를 사용하는 경우 그룹 ID(GID) 0을 사용하여 실행기를 실행하도록 구성했는지 확인하세요.

```toml
[[runners]]
[runners.kubernetes]
    [runners.kubernetes.pod_security_context]
    run_as_non_root = true
    run_as_group = 0
```

## 사용자 지정되거나 병합된 CycloneDX SBOM에 대해 취약성 검사가 결과를 생성하지 않음 {#vulnerability-scanning-produces-no-results-for-custom-or-merged-cyclonedx-sboms}

종속성 검사 CI/CD 작업이 성공하고 SBOM 구성 요소가 종속성 검사 목록에 나타나지만 파이프라인 보안 탭에서는 취약성이 보고되지 않습니다.

GitLab 18.10 이상에서 보안 탭은 다음 메시지를 표시합니다: "SBOM 보고서는 취약성 검사에 필요한 필수 GitLab 메타데이터 속성이 누락되었습니다."

이 문제는 SBOM에 필수 [GitLab CycloneDX 속성](../../../../development/sec/cyclonedx_property_taxonomy.md)이 누락되었을 때 발생합니다. 이러한 속성이 없으면 취약성 스캐너가 SBOM의 구성 요소에 대한 발견을 구성할 수 없습니다. 종속성 검사 목록은 여전히 채워지지만 취약성은 보고되지 않습니다.

이는 일반적으로 다음의 경우에 발생합니다:

- 여러 SBOM이 `cyclonedx merge`을(를) 사용하여 병합되며, 이는 메타데이터 속성을 제거합니다.
- 타사 SBOM 생성기에 GitLab별 속성이 포함되지 않습니다.
- `gitlab:meta:schema_version` 속성(`1`이어야 함)이 `metadata.properties`에서 누락되었습니다.

### 취약성 검사에 필요한 속성 {#required-properties-for-vulnerability-scanning}

| 속성 | 위치 | 설명 |
|---|---|---|
| `gitlab:meta:schema_version` | `metadata.properties` | `1`로 설정해야 합니다. |
| `gitlab:dependency_scanning:input_file:path` | `metadata.properties` 또는 각 구성 요소의 `properties` | 종속성을 생성하기 위해 분석된 잠금 파일의 경로입니다. 어느 것도 존재하지 않으면 해당 구성 요소에 대해 취약성 발견이 생성되지 않습니다. GitLab 18.10 이상에서는 파이프라인 보안 탭에 오류가 표시됩니다. |

이 문제를 해결하려면 다음 접근 방식 중 하나를 선택하세요:

- 각 SBOM을 별도로 업로드합니다.

  병합하는 대신 각 SBOM을 별도 [`artifacts: reports: cyclonedx:`](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) 항목으로 업로드합니다. 이것은 각 파일에서 GitLab별 속성을 유지합니다.
- 타사 SBOM에 속성을 추가합니다.

  타사 도구에서 생성한 SBOM은 일반적으로 GitLab별 속성을 포함하지 않습니다. 취약성 검사를 활성화하려면 SBOM이 `metadata.properties`에 다음을 포함하는지 확인하세요:

  - `gitlab:meta:schema_version`을(를) `1`로 설정합니다.
  - `gitlab:dependency_scanning:input_file:path`을(를) 잠금 파일의 리포지토리 상대 경로(예: `package-lock.json` 또는 `src/Gemfile.lock`)로 설정합니다.

  SBOM에 여러 잠금 파일의 구성 요소가 포함된 경우 메타데이터가 아닌 각 구성 요소의 `properties` 배열에 `input_file:path`을(를) 설정하여 각 구성 요소가 올바른 소스 파일을 가리킵니다. 지원되는 속성의 전체 목록은 [GitLab CycloneDX 속성 분류](../../../../development/sec/cyclonedx_property_taxonomy.md)를 참조하세요.

자세한 내용은 [이슈 542813](https://gitlab.com/gitlab-org/gitlab/-/work_items/542813) 및 [머지 리퀘스트 221549](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221549)를 참조하세요.

## 취약성 검사가 모든 종속성에 대해 잘못된 입력 파일을 표시함 {#vulnerability-scanning-shows-wrong-input-file-for-all-dependencies}

취약성 보고서 또는 종속성 검사 목록의 모든 종속성이 다른 잠금 파일에서 비롯되었음에도 불구하고 동일한 입력 파일 경로를 표시합니다.

이 문제는 `gitlab:dependency_scanning:input_file:path` 속성이 구성 요소별이 아닌 `metadata.properties`에 설정된 경우 발생합니다. [속성 분류](../../../../development/sec/cyclonedx_property_taxonomy.md)에 따르면 메타데이터 수준 속성이 문서의 모든 객체에 적용되므로 단일 값이 모든 구성 요소를 재정의합니다.

이 문제를 해결하려면 `input_file:path`을(를) 최상위 메타데이터가 아닌 각 구성 요소의 `properties` 배열에 개별적으로 설정합니다. `input_file:path` 속성은 특히 여러 잠금 파일의 구성 요소가 포함된 병합된 SBOM에 중요합니다.

## 오류: `node with package name <package_name> does not exist` {#error-node-with-package-name-package_name-does-not-exist}

이 문제는 일반적으로 nuget인 패키지 관리자가 패키지를 찾을 수 없을 때 발생합니다. 이는 애플리케이션을 빌드하는 데 사용되는 이미지가 종속성 검사를 실행하는 데 사용되는 이미지와 다를 때 발생할 수 있습니다.

이 문제를 해결하려면 종속성 검사가 애플리케이션을 빌드하는 데 사용하는 것과 동일한 .NET SDK 이미지를 사용합니다. 다음을 실행하여 정확한 이미지를 찾을 수 있습니다:

```shell
curl --silent "https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/-/raw/master/build/gemnasium/alpine/Dockerfile" | grep "vrange-nuget-build" | grep "FROM"
```

현재 이미지 버전에 대해 위에 연결된 Dockerfile을 확인하세요.
