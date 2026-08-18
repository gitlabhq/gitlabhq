---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Bitbucket Cloud 리포지토리를 GitLab CI/CD에 연결하세요.
title: Bitbucket Cloud 리포지토리에서 GitLab CI/CD 사용하기
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD는 다음 방법으로 Bitbucket Cloud와 함께 사용할 수 있습니다:

1. [CI/CD 프로젝트](_index.md)를 생성합니다.
1. Git 리포지토리를 URL로 연결합니다.

Bitbucket Cloud 리포지토리에서 GitLab CI/CD를 사용하려면:

1. Bitbucket에서 [**App password**](https://support.atlassian.com/bitbucket-cloud/docs/create-an-app-password/)를 생성하여 Bitbucket에서 커밋 빌드 상태를 설정하는 스크립트를 인증합니다. 리포지토리 쓰기 권한이 필요합니다.

   ![App password 생성 인터페이스를 보여주는 Bitbucket Cloud 페이지입니다.](img/bitbucket_app_password_v10_6.png)

1. Bitbucket에서 리포지토리의 **Clone**을 선택한 후 `git clone` 다음에 시작하는 URL을 복사합니다.
1. GitLab에서 프로젝트를 생성합니다:

   1. 오른쪽 상단 모서리에서 **새로 만들기** ({{< icon name="plus" >}}) 및 **새 프로젝트/리포지토리**를 선택합니다.
   1. **외부 리포지토리에 대한 CI/CD 실행**을 선택합니다.
   1. **리포지토리 URL**을 선택합니다.
   1. 필드를 완성합니다:
      - **Git 리포지토리 URL**에 Bitbucket 리포지토리의 URL을 입력합니다. `@username`를 제거해야 합니다.
      - **사용자명**에 App password와 연결된 사용자명을 입력합니다.
      - **비밀번호**에 Bitbucket의 App password를 입력합니다.

   GitLab이 리포지토리를 가져오고 [Pull 미러링](../../user/project/repository/mirror/pull.md)을 활성화합니다. 프로젝트에서 **설정** > **리포지토리** > **리포지토리 미러링**으로 이동하여 미러링이 작동 중인지 확인할 수 있습니다.

1. GitLab에서 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)을 생성하여 `api` 범위를 가집니다. 토큰은 Bitbucket에서 생성된 웹후크로부터의 요청을 인증하고 새로운 커밋을 GitLab에 알리는 데 사용됩니다.

1. Bitbucket의 **설정** > **Webhooks**에서 새로운 웹후크를 생성하여 GitLab에 새로운 커밋을 알립니다.

1. 웹후크 URL을 [GitLab pull 미러링](../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project) 엔드포인트로 설정하고 방금 생성한 개인 액세스 토큰을 인증에 사용합니다.

   ```plaintext
   https://gitlab.example.com/api/v4/projects/:project_id/mirror/pull?private_token=<your_personal_access_token>
   ```

   웹후크 트리거는 **Repository Push**로 설정해야 합니다.

   ![GitLab 미러링을 위한 웹후크 구성을 표시하는 Bitbucket Cloud 리포지토리 설정 페이지입니다.](img/bitbucket_webhook_v10_6.png)

   저장한 후 Bitbucket 리포지토리에 변경 사항을 푸시하여 웹후크를 테스트합니다.

1. GitLab의 **설정** > **CI/CD** > **변수**에서 Bitbucket API를 통해 Bitbucket과의 통신을 허용하는 변수를 추가합니다:

   - `BITBUCKET_ACCESS_TOKEN`: 이전에 생성한 Bitbucket app 비밀번호입니다. 이 변수는 [마스킹](../variables/_index.md#mask-a-cicd-variable)되어야 합니다.
   - `BITBUCKET_USERNAME`: Bitbucket 계정의 사용자명입니다.
   - `BITBUCKET_NAMESPACE`: GitLab 및 Bitbucket 네임스페이스가 다른 경우 이 변수를 설정합니다.
   - `BITBUCKET_REPOSITORY`: GitLab 및 Bitbucket 프로젝트 이름이 다른 경우 이 변수를 설정합니다.

1. Bitbucket에서 파이프라인 상태를 Bitbucket으로 푸시하는 스크립트를 추가합니다. 스크립트는 Bitbucket에서 생성되지만 미러링 프로세스는 이를 GitLab 미러로 복사합니다. GitLab CI/CD 파이프라인이 스크립트를 실행하고 상태를 Bitbucket으로 다시 푸시합니다.

   `build_status` 파일을 생성하여 다음 스크립트를 삽입하고 터미널에서 `chmod +x build_status`를 실행하여 스크립트를 실행 가능하게 만듭니다.

   ```shell
   #!/usr/bin/env bash

   # Push GitLab CI/CD build status to Bitbucket Cloud

   if [ -z "$BITBUCKET_ACCESS_TOKEN" ]; then
      echo "ERROR: BITBUCKET_ACCESS_TOKEN is not set"
   exit 1
   fi
   if [ -z "$BITBUCKET_USERNAME" ]; then
       echo "ERROR: BITBUCKET_USERNAME is not set"
   exit 1
   fi
   if [ -z "$BITBUCKET_NAMESPACE" ]; then
       echo "Setting BITBUCKET_NAMESPACE to $CI_PROJECT_NAMESPACE"
       BITBUCKET_NAMESPACE=$CI_PROJECT_NAMESPACE
   fi
   if [ -z "$BITBUCKET_REPOSITORY" ]; then
       echo "Setting BITBUCKET_REPOSITORY to $CI_PROJECT_NAME"
       BITBUCKET_REPOSITORY=$CI_PROJECT_NAME
   fi

   BITBUCKET_API_ROOT="https://api.bitbucket.org/2.0"
   BITBUCKET_STATUS_API="$BITBUCKET_API_ROOT/repositories/$BITBUCKET_NAMESPACE/$BITBUCKET_REPOSITORY/commit/$CI_COMMIT_SHA/statuses/build"
   BITBUCKET_KEY="ci/gitlab-ci/$CI_JOB_NAME"

   case "$BUILD_STATUS" in
   running)
      BITBUCKET_STATE="INPROGRESS"
      BITBUCKET_DESCRIPTION="The build is running!"
      ;;
   passed)
      BITBUCKET_STATE="SUCCESSFUL"
      BITBUCKET_DESCRIPTION="The build passed!"
      ;;
   failed)
      BITBUCKET_STATE="FAILED"
      BITBUCKET_DESCRIPTION="The build failed."
      ;;
   esac

   echo "Pushing status to $BITBUCKET_STATUS_API..."
   curl --request POST "$BITBUCKET_STATUS_API" \
   --user $BITBUCKET_USERNAME:$BITBUCKET_ACCESS_TOKEN \
   --header "Content-Type:application/json" \
   --silent \
   --data "{ \"state\": \"$BITBUCKET_STATE\", \"key\": \"$BITBUCKET_KEY\", \"description\":
   \"$BITBUCKET_DESCRIPTION\",\"url\": \"$CI_PROJECT_URL/-/jobs/$CI_JOB_ID\" }"
   ```

1. Bitbucket에서 `.gitlab-ci.yml` 파일을 생성하여 스크립트를 사용하여 파이프라인 성공 및 실패를 Bitbucket으로 푸시합니다. 이전에 추가된 스크립트와 유사하게 이 파일은 미러링 프로세스의 일부로 GitLab 리포지토리로 복사됩니다.

   ```yaml
   stages:
     - test
     - ci_status

   unit-tests:
     script:
       - echo "Success. Add your tests!"

   success:
     stage: ci_status
     before_script:
       - ""
     after_script:
       - ""
     script:
       - BUILD_STATUS=passed BUILD_KEY=push ./build_status
     when: on_success

   failure:
     stage: ci_status
     before_script:
       - ""
     after_script:
       - ""
     script:
       - BUILD_STATUS=failed BUILD_KEY=push ./build_status
     when: on_failure
   ```

GitLab은 이제 Bitbucket의 변경 사항을 미러하도록 구성되고 `.gitlab-ci.yml`에서 구성된 CI/CD 파이프라인을 실행하며 상태를 Bitbucket으로 푸시합니다.
