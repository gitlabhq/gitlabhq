---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Git 서브모듈을 사용하여 상대 URL, 절대 URL, CI/CD 변수를 통해 다른 리포지토리의 코드를 CI/CD 파이프라인에 포함시킵니다."
title: GitLab CI/CD로 Git 서브모듈 사용하기
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Git 서브모듈](https://git-scm.com/book/en/v2/Git-Tools-Submodules)을(를) 사용하여 Git 리포지토리를 다른 Git 리포지토리의 하위 디렉터리로 유지합니다. 다른 리포지토리를 프로젝트에 복제하고 커밋을(를) 별도로 유지할 수 있습니다.

## `.gitmodules` 파일 구성 {#configure-the-gitmodules-file}

Git 서브모듈을 사용하는 경우 프로젝트에 `.gitmodules` 파일이 있어야 합니다. GitLab CI/CD 작업에서 이를 구성할 수 있는 여러 옵션이 있습니다.

### 절대 URL 사용 {#using-absolute-urls}

{{< history >}}

- GitLab Runner 15.11에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3198).

{{< /history >}}

예를 들어, 생성된 `.gitmodules` 구성은 다음과 같을 수 있습니다(다음 조건 하에):

- 프로젝트가 `https://gitlab.com/secret-group/my-project`에 있습니다.
- 프로젝트가 `https://gitlab.com/group/project`에 의존하며, 이를 서브모듈로 포함하려고 합니다.
- `git@gitlab.com:secret-group/my-project.git`과(와) 같은 SSH 주소로 소스를 체크아웃합니다.

```ini
[submodule "project"]
  path = project
  url = git@gitlab.com:group/project.git
```

이 경우 [`GIT_SUBMODULE_FORCE_HTTPS`](configure_runners.md#rewrite-submodule-urls-to-https) 변수를 사용하여 러너가 서브모듈을 복제하기 전에 URL을 HTTPS로 변환하도록 지시합니다.

또는 로컬에서도 HTTPS를 사용하는 경우 HTTPS URL을 구성할 수 있습니다:

```ini
[submodule "project"]
  path = project
  url = https://gitlab.com/group/project.git
```

이 경우 추가 변수를 구성할 필요는 없지만 로컬로 복제하기 위해 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)을(를) 사용해야 합니다.

### 상대 URL 사용 {#using-relative-urls}

> [!warning]
> 상대 URL을 사용하는 경우 서브모듈이 포크 워크플로에서 잘못 확인될 수 있습니다. 프로젝트에 포크가 있을 것으로 예상되면 대신 절대 URL을 사용하세요.

서브모듈이 동일한 GitLab 서버에 있는 경우 `.gitmodules` 파일에서 상대 URL을 사용할 수도 있습니다:

```ini
[submodule "project"]
  path = project
  url = ../../project.git
```

이전 구성은 소스를 복제할 때 사용할 URL을 자동으로 추론하도록 Git에 지시합니다. 모든 CI/CD CI/CD 작업에서 HTTPS를 사용하여 복제할 수 있으며 로컬로 복제하기 위해 SSH를 계속 사용할 수 있습니다.

동일한 GitLab 서버에 없는 서브모듈의 경우 항상 전체 URL을 사용하세요:

```ini
[submodule "project-x"]
  path = project-x
  url = https://gitserver.com/group/project-x.git
```

## CI/CD 작업에서 Git 서브모듈 사용 {#use-git-submodules-in-cicd-jobs}

전제 조건:

- 작업 파이프라인에서 서브모듈을 복제하기 위해 [`CI_JOB_TOKEN`](../jobs/ci_job_token.md)을(를) 사용하는 경우 서브모듈 리포지토리에서 코드를 가져오기 위해 Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- [CI/CD 작업 토큰 액세스](../jobs/ci_job_token.md#control-job-token-access-to-your-project)는 업스트림 서브모듈 프로젝트에서 올바르게 구성되어야 합니다.

서브모듈이 CI/CD 작업에서 올바르게 작동하도록 하려면:

1. `GIT_SUBMODULE_STRATEGY` 변수를 `normal` 또는 `recursive`으(로) 설정하여 러너에 [작업 전에 서브모듈 가져오기](configure_runners.md#git-submodule-strategy)를 지시할 수 있습니다:

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
   ```

1. 동일한 GitLab 서버에 위치하고 Git 또는 SSH URL로 구성된 서브모듈의 경우 [`GIT_SUBMODULE_FORCE_HTTPS`](configure_runners.md#rewrite-submodule-urls-to-https) 변수를 설정했는지 확인하세요.

1. `GIT_SUBMODULE_DEPTH`을(를) 사용하여 [`GIT_DEPTH`](configure_runners.md#shallow-cloning) 변수와 무관하게 서브모듈의 복제 깊이를 구성합니다:

   ```yaml
   variables:
     GIT_SUBMODULE_DEPTH: 1
   ```

1. [`GIT_SUBMODULE_PATHS`](configure_runners.md#sync-or-exclude-specific-submodules-from-ci-jobs)을(를) 사용하여 어떤 서브모듈을 동기화할지 제어하기 위해 특정 서브모듈을 필터링하거나 제외할 수 있습니다.

   ```yaml
   variables:
     GIT_SUBMODULE_PATHS: submoduleA submoduleB
   ```

1. [`GIT_SUBMODULE_UPDATE_FLAGS`](configure_runners.md#git-submodule-update-flags)을(를) 사용하여 고급 체크아웃 동작을 제어하기 위한 추가 플래그를 제공할 수 있습니다.

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
     GIT_SUBMODULE_UPDATE_FLAGS: --jobs 4
   ```

### 중첩된 서브모듈 체크아웃 {#check-out-nested-submodules}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5912) GitLab Runner 18.6.

{{< /history >}}

중첩된 서브모듈은 자신의 서브모듈을 포함하는 서브모듈입니다. 리포지토리의 모든 서브모듈이 아닌 특정 중첩된 서브모듈만 체크아웃해야 할 수 있습니다.

GitLab Runner 18.6 이상은 빌드 디렉터리를 오염시키지 않도록 Git 구성(인증 정보 포함)을 별도 파일로 외부화합니다. 서브모듈 디렉터리로 이동하여 Git 명령을 실행하면 `GIT_SUBMODULE_STRATEGY`에 따라 모든 서브모듈에 대해 메인 리포지토리의 구성이 자동으로 상속됩니다:

- `GIT_SUBMODULE_STRATEGY: normal`이(가) 사용되면 최상위 서브모듈이 초기화됩니다.
- `GIT_SUBMODULE_STRATEGY: recursive`이(가) 사용되면 모든 중첩된 서브모듈이 초기화됩니다.

중첩된 서브모듈의 부분 집합을 체크아웃하려면:

1. `GIT_SUBMODULE_STRATEGY`을(를) `normal`로 설정합니다:

   ```yaml
      variables:
        GIT_SUBMODULE_STRATEGY: normal
   ```

1. 작업에서 외부화된 구성을 명시적으로 전달합니다:

   ```yaml
      my-job:
        script:
          - git submodule sync
          - git submodule update --init
          - cd path/to/submodule-with-nested-submodule
          - git -c "include.path=$(git -C $CI_PROJECT_DIR config include.path)" submodule update --init nested-submodule
   ```

`git -C $CI_PROJECT_DIR config include.path` 명령은 메인 리포지토리에서 외부화된 구성 파일의 경로를 검색합니다. 이렇게 하면 중첩된 서브모듈을 체크아웃할 때 인증 정보 및 기타 설정을 사용할 수 있습니다.

## 다른 GitLab 인스턴스에서 서브모듈 사용 {#use-submodules-from-another-gitlab-instance}

서브모듈이 메인 프로젝트와 다른 GitLab 인스턴스에서 호스팅되는 경우 현재 인스턴스의 `CI_JOB_TOKEN`은(는) 외부 인스턴스에 인증할 수 없습니다. 외부 인스턴스에서 생성된 토큰을 사용하여 인증해야 합니다.

외부 GitLab 인스턴스로 인증하기 위한 두 가지 주요 방법이 있습니다:

- URL 재작성: Git URL을 수정하여 인증 자격 증명을 포함시킵니다.
- Git 자격 증명 도우미: Git이 필요할 때 자동으로 사용하는 인증 정보를 저장합니다.

선택한 인증 방법은 GitLab 러너 실행기 유형에 따라 달라집니다:

- 컨테이너화된 실행기(Docker 또는 Kubernetes): 각 작업은 격리된 컨테이너에서 실행되므로 전역 Git 구성 변경은 현재 작업에만 영향을 미치며 컨테이너가 제거될 때 자동으로 정리됩니다.

- Shell 실행기: 작업이(가) 러너 호스트 시스템에서 직접 실행되므로 전역 Git 구성 변경이 작업 간에 지속됩니다. 다른 작업에서 다른 인증 정보를 사용하는 경우 인증 충돌이 발생할 수 있습니다.

> [!warning]
> Shell 실행기를 사용할 때 인증 자격 증명을 유지하는 `git config --global` 명령을 피하세요. 이러한 설정은 작업 간에 활성 상태를 유지하며 다른 작업에서 다른 인증 정보를 사용하는 경우 인증 실패 또는 보안 이슈가 발생할 수 있습니다.

다음 토큰 유형 중 하나를 사용할 수 있습니다:

- [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)
- [배포 토큰](../../user/project/deploy_tokens/_index.md)
- [프로젝트 액세스 토큰](../../user/project/settings/project_access_tokens.md)

### URL 재작성을 사용한 인증 구성 {#configure-authentication-with-url-rewriting}

URL 재작성을 사용한 인증을 구성하려면:

1. `.gitmodules` 파일에서 서브모듈에 절대 HTTPS URL을 사용합니다:

   ```ini
   [submodule "external-project"]
     path = external-project
     url = https://other-gitlab.example.com/group/project.git
   ```

1. 외부 GitLab 인스턴스에서 `read_repository` 범위로 토큰을 생성합니다.
1. 메인 프로젝트에서 토큰을 [마스킹된 CI/CD 변수](../variables/_index.md#mask-a-cicd-variable)로 추가합니다. 예를 들어 `EXTERNAL_GITLAB_TOKEN`로 이름을 지정합니다.
1. `.gitlab-ci.yml` 파일에서 실행기 유형에 따라 인증을 구성합니다:

   컨테이너화된 실행기(Docker 또는 Kubernetes):

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive

   my-job:
     before_script:
       - git config --global url."https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com/".insteadOf "https://other-gitlab.example.com/"
     script:
       - echo "Submodules are fetched with authentication"
       - ls -la external-project/
   ```

   Shell 실행기:

   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: none

   my-job:
     before_script:
       - parent_include_path=$(git -C $CI_PROJECT_DIR config include.path)
       - git -c "include.path=${parent_include_path}" -c "url.https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com/.insteadOf=https://other-gitlab.example.com/" submodule update --init --recursive --force
     script:
       - echo "Submodules are fetched with authentication"
       - ls -la external-project/
   ```

   `<username>`을(를) 토큰과 연결된 GitLab 사용자 이름으로 바꿉니다.

   컨테이너화된 실행기에서만 모든 작업에 대해 인증을 전역으로 구성하려면:

   ```yaml
   hooks:
     pre_get_sources_script:
       - git config --global url."https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com/".insteadOf "https://other-gitlab.example.com/"
   ```

### Git 자격 증명 도우미를 사용한 인증 구성 {#configure-authentication-with-git-credential-helper}

Git 자격 증명 도우미를 사용한 인증을 구성하려면:

1. 외부 GitLab 인스턴스에서 `read_repository` 범위로 토큰을 생성합니다.
1. 메인 프로젝트에서 토큰을 [마스킹된 CI/CD 변수](../variables/_index.md#mask-a-cicd-variable)로 추가합니다. 예를 들어 `EXTERNAL_GITLAB_TOKEN`로 이름을 지정합니다.
1. `.gitlab-ci.yml` 파일에서 실행기 유형에 따라 자격 증명 도우미를 구성합니다:

   컨테이너화된 실행기(Docker 또는 Kubernetes):

   ```yaml
   my-job:
     before_script:
       - git config --global credential.helper store
       - echo "https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com" >> ~/.git-credentials
     script:
       - echo "Submodules are fetched with authentication"
       - ls -la external-project/
   ```

   Shell 실행기:

   ```yaml
   my-job:
     before_script:
       - TEMP_CREDS=$(mktemp)
       - echo "https://<username>:${EXTERNAL_GITLAB_TOKEN}@other-gitlab.example.com" > "$TEMP_CREDS"
       - git config credential.helper "store --file=$TEMP_CREDS"
       - trap "rm -f $TEMP_CREDS" EXIT
     script:
       - echo "Submodules are fetched with authentication"
       - ls -la external-project/
   ```

   `<username>`을(를) 토큰과 연결된 GitLab 사용자 이름으로 바꿉니다.

## 문제 해결 {#troubleshooting}

### `.gitmodules` 파일을 찾을 수 없음 {#cant-find-the-gitmodules-file}

`.gitmodules` 파일은 일반적으로 숨겨진 파일이므로 찾기 어려울 수 있습니다. 특정 OS에 대한 설명서를 확인하여 숨겨진 파일을 찾고 표시하는 방법을 알아볼 수 있습니다.

`.gitmodules` 파일이 없으면 서브모듈 설정이 [`git config`](https://www.atlassian.com/git/tutorials/setting-up-a-repository/git-config) 파일에 있을 가능성이 있습니다.

### 오류: `fatal: run_command returned non-zero status` {#error-fatal-run_command-returned-non-zero-status}

이 오류는 서브모듈로 작업할 때 작업에서 발생할 수 있으며 `GIT_STRATEGY`이(가) `fetch`로 설정되어 있습니다.

`GIT_STRATEGY`을(를) `clone`로 설정하면 이슈가 해결됩니다.

### 오류: `fatal: could not read Username for 'https://gitlab.com': No such device or address` {#error-fatal-could-not-read-username-for-httpsgitlabcom-no-such-device-or-address}

CI/CD 작업이 서브모듈로 복제, 가져오기 또는 다른 Git 작업을 시도할 때 이 오류가 발생할 수 있습니다. 이 이슈는 다음과 같은 경우에 발생합니다:

- 서브모듈 디렉터리 내에서 Git 명령(예: `git fetch`)을 실행합니다. 외부화된 Git 구성이 모든 Git 작업에 대해 자동으로 상속되지 않을 수 있습니다.
- 중첩된 서브모듈로 작업합니다. GitLab Runner 18.6 이상은 Git 구성을 외부화하기 때문에 서브모듈에 의해 자동으로 상속되지 않을 수 있습니다.
- `https://gitlab.com`을(를) 참조하는 서브모듈이 있는 GitLab에서 호스팅하는 러너를 사용합니다. `CI_SERVER_FQDN`이(가) `gitlab.com`과(와) 다르기 때문입니다. 러너는 초기 체크아웃 중에 Git URL 치환을 자동으로 수행하지만 서브모듈 디렉터리 내의 후속 Git 작업에는 적용되지 않을 수 있습니다.

이 이슈를 해결하려면:

- 중첩된 서브모듈의 경우 [중첩된 서브모듈 체크아웃](#check-out-nested-submodules)을(를) 참조하세요.
- 서브모듈 디렉터리 내의 Git 작업의 경우 외부화된 구성을 명시적으로 전달합니다:

  ```yaml
    my-job:
      script:
        - cd path/to/submodule
        - git -c "include.path=$(git -C $CI_PROJECT_DIR config include.path)" fetch origin
  ```

- GitLab에서 호스팅하는 러너 또는 서브모듈 내의 여러 Git 작업이 있는 작업의 경우 `CI_JOB_TOKEN`을(를) 사용하여 URL 치환을 구성합니다:

  ```yaml
  my-job:
    script:
      - cd path/to/submodule
      - git -c "include.path=$(git -C $CI_PROJECT_DIR config include.path)" -c "url.https://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_FQDN}/.insteadOf=https://gitlab.com/" fetch origin
  ```

  실행기별 구성 옵션은 [다른 GitLab 인스턴스에서 서브모듈 사용](#use-submodules-from-another-gitlab-instance)을(를) 참조하세요.
