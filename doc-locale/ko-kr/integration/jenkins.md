---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jenkins
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [옮겨짐](https://gitlab.com/gitlab-org/gitlab/-/issues/246756) \- GitLab Free 13.7 버전에서.

{{< /history >}}

[Jenkins](https://www.jenkins.io/)는 프로젝트 빌드, 배포 및 자동화를 지원하는 오픈 소스 자동화 서버입니다.

다음과 같은 경우 GitLab과 Jenkins 통합을 사용해야 합니다:

- 나중에 Jenkins에서 CI를 [GitLab CI/CD](../ci/_index.md)로 마이그레이션할 계획이 있지만 임시 솔루션이 필요합니다.
- [Jenkins 플러그인](https://plugins.jenkins.io/)에 투자했으며 Jenkins를 계속 사용하여 앱을 빌드하도록 선택합니다.

이 통합은 GitLab에 변경 사항을 푸시할 때 Jenkins 빌드를 트리거할 수 있습니다.

이 통합을 사용하여 Jenkins에서 GitLab CI/CD 파이프라인을 트리거할 수 없습니다. 대신 Jenkins 작업에서 [파이프라인 트리거 API 엔드포인트](../api/pipeline_triggers.md)를 사용하고 [파이프라인 트리거 토큰](../ci/triggers/_index.md#create-a-pipeline-trigger-token)으로 인증합니다.

Jenkins 통합을 구성한 후 코드를 리포지토리에 푸시하거나 GitLab에서 머지 리퀘스트를 생성할 때 Jenkins에서 빌드를 트리거합니다. Jenkins 파이프라인 상태는 머지 리퀘스트 위젯 및 GitLab 프로젝트의 홈 페이지에 표시됩니다.

<i class="fa-youtube-play" aria-hidden="true"></i> GitLab Jenkins 통합의 개요를 보려면 [Jira 이슈 및 Jenkins 파이프라인을 포함한 GitLab 워크플로우](https://youtu.be/Jn-_fyra7xQ)를 참조하세요.

GitLab으로 Jenkins 통합을 구성하려면:

- GitLab 프로젝트에 Jenkins 액세스 권한을 부여합니다.
- Jenkins 서버를 구성합니다.
- Jenkins 프로젝트를 구성합니다.
- GitLab 프로젝트를 구성합니다.

## GitLab 프로젝트에 Jenkins 액세스 권한 부여 {#grant-jenkins-access-to-the-gitlab-project}

1. 개인, 프로젝트 또는 그룹 액세스 토큰을 생성합니다.

   - [개인 액세스 토큰 생성](../user/profile/personal_access_tokens.md#create-a-personal-access-token) \- 해당 사용자의 모든 Jenkins 통합에서 토큰을 사용합니다.
   - [프로젝트 액세스 토큰 생성](../user/project/settings/project_access_tokens.md#create-a-project-access-token) \- 프로젝트 수준에서만 토큰을 사용합니다. 예를 들어 다른 프로젝트의 Jenkins 통합에 영향을 주지 않고 프로젝트에서 토큰을 취소할 수 있습니다.
   - [그룹 액세스 토큰 생성](../user/group/settings/group_access_tokens.md#create-a-group-access-token) \- 해당 그룹의 모든 프로젝트의 모든 Jenkins 통합에서 토큰을 사용합니다.

1. 액세스 토큰 범위를 **API**로 설정합니다.
1. 액세스 토큰 값을 복사하여 Jenkins 서버를 구성합니다.

## Jenkins 서버 구성 {#configure-the-jenkins-server}

GitLab에 대한 연결을 인증하도록 Jenkins 플러그인을 설치하고 구성합니다.

1. Jenkins 서버에서 **Manage Jenkins** > **Manage Plugins**를 선택합니다.
1. **사용 가능** 탭을 선택합니다. `gitlab-plugin`를 검색하고 선택하여 설치합니다. 플러그인을 설치하는 다른 방법은 [Jenkins GitLab 문서](https://plugins.jenkins.io/gitlab-plugin/)를 참조하세요.
1. **Manage Jenkins** > **Configure System**을 선택합니다.
1. **GitLab** 섹션에서 **Enable authentication for '/project' end-point**를 선택합니다.
1. **추가**를 선택한 다음 **Jenkins Credential Provider**를 선택합니다.
1. **GitLab API token**을 토큰 유형으로 선택합니다.
1. **API Token**에 [GitLab에서 복사한 액세스 토큰 값을 붙여넣고](#grant-jenkins-access-to-the-gitlab-project) **추가**를 선택합니다.
1. GitLab 서버의 URL을 **GitLab host URL**에 입력합니다.
1. 연결을 테스트하려면 **Test Connection**을 선택합니다.

자세한 정보는 [Jenkins-to-GitLab 인증](https://github.com/jenkinsci/gitlab-plugin#jenkins-to-gitlab-authentication)을 참조하세요.

## Jenkins 프로젝트 구성 {#configure-the-jenkins-project}

빌드를 실행할 Jenkins 프로젝트를 설정합니다.

1. Jenkins 인스턴스에서 **New Item**을 선택합니다.
1. 프로젝트의 이름을 입력합니다.
1. **Freestyle** 또는 **파이프라인**을 선택한 다음 **확인**를 선택합니다. Jenkins 플러그인이 GitLab의 빌드 상태를 업데이트하므로 freestyle 프로젝트를 선택해야 합니다. 파이프라인 프로젝트에서는 GitLab의 상태를 업데이트하도록 스크립트를 구성해야 합니다.
1. 드롭다운 목록에서 GitLab 연결을 선택합니다.
1. **Build when a change is pushed to GitLab**을 선택합니다.
1. 다음 확인란을 선택합니다:
   - **Accepted Merge Request Events**
   - **Closed Merge Request Events**
1. 빌드 상태를 GitLab에 보고하는 방법을 지정합니다:
   - freestyle 프로젝트를 생성한 경우 **Post-build Actions** 섹션에서 **Publish build status to GitLab**를 선택합니다.
   - 파이프라인 프로젝트를 생성한 경우 Jenkins Pipeline 스크립트를 사용하여 GitLab의 상태를 업데이트해야 합니다.

     Jenkins Pipeline 스크립트 예시:

      ```groovy
      pipeline {
         agent any

         stages {
            stage('gitlab') {
               steps {
                  echo 'Notify GitLab'
                  updateGitlabCommitStatus name: 'build', state: 'pending'
                  updateGitlabCommitStatus name: 'build', state: 'success'
               }
            }
         }
      }
      ```

      더 많은 Jenkins Pipeline 스크립트 예시는 [GitHub의 Jenkins GitLab 플러그인 리포지토리](https://github.com/jenkinsci/gitlab-plugin#scripted-pipeline-jobs)를 참조하세요.

## GitLab 프로젝트 구성 {#configure-the-gitlab-project}

다음 방법 중 하나로 GitLab과 Jenkins의 통합을 구성합니다.

### Jenkins 서버 URL 사용 {#with-a-jenkins-server-url}

GitLab에 Jenkins 서버 URL 및 인증 정보를 제공할 수 있는 경우 Jenkins 통합에 대해 이 접근 방식을 사용해야 합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **Jenkins**를 선택합니다.
1. **활성** 확인란을 선택합니다.
1. GitLab이 Jenkins 빌드를 트리거하도록 할 이벤트를 선택합니다:
   - Push
   - 머지 리퀘스트
   - Tag push
1. **Jenkins 서버 URL**을 입력합니다.
1. 선택 사항. **SSL 검증 활성화** 확인란을 선택 해제하여 [SSL 검증](../user/project/integrations/_index.md#ssl-verification)을 비활성화합니다.
1. **프로젝트 이름**을 입력합니다. 프로젝트 이름은 URL에 친화적이어야 하며 공백은 밑줄로 바뀝니다. 프로젝트 이름이 올바른지 확인하려면 Jenkins 프로젝트를 보는 동안 브라우저의 주소 표시줄에서 복사합니다.
1. Jenkins 서버에 인증이 필요한 경우 **사용자명**과 **비밀번호**를 입력합니다.
1. 선택 사항. **테스트 설정**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 웹후크 사용 {#with-a-webhook}

[GitLab에 Jenkins 서버 URL 및 인증 정보를 제공](#with-a-jenkins-server-url)할 수 없는 경우 웹후크를 구성하여 GitLab과 Jenkins를 통합할 수 있습니다.

1. Jenkins 작업의 구성에서 GitLab 구성 섹션의 **고급**를 선택합니다.
1. **Secret Token** 아래에서 **생성**를 선택합니다.
1. 토큰을 복사하고 작업 구성을 저장합니다.
1. GitLab에서:
   - [프로젝트에 대한 웹후크 생성](../user/project/integrations/webhooks.md#configure-webhooks)
   - 트리거 URL (예: `https://JENKINS_URL/project/YOUR_JOB`)을 입력합니다.
   - 토큰을 **Secret Token**에 붙여넣습니다.
1. 웹후크를 테스트하려면 **테스트**를 선택합니다.

## 관련 항목 {#related-topics}

- [GitLab Jenkins 통합](https://about.gitlab.com/solutions/jenkins/)
- [Jenkins에서 GitLab CI/CD로 마이그레이션하는 방법](../ci/migration/jenkins.md)
- [Jenkins에서 GitLab: CI/CD 환경을 현대화하는 최고의 가이드](https://about.gitlab.com/blog/jenkins-gitlab-ultimate-guide-to-modernizing-cicd-environment/)

## 문제 해결 {#troubleshooting}

### 오류: `Connection failed. Please check your settings` {#error-connection-failed-please-check-your-settings}

GitLab을 구성할 때 `Connection failed. Please check your settings`와 같은 오류가 발생할 수 있습니다.

이 이슈에는 여러 가능한 원인과 해결책이 있습니다:

| 원인                                                            | 해결책  |
|------------------------------------------------------------------|-------------|
| GitLab이 주소에서 Jenkins 인스턴스에 도달할 수 없습니다.  | GitLab Self-Managed의 경우 GitLab 인스턴스에 제공된 도메인에서 Jenkins 인스턴스를 ping합니다. |
| Jenkins 인스턴스가 로컬 주소에 있으며 [GitLab 설치의 허용 목록](../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)에 포함되지 않습니다. | GitLab 설치의 허용 목록에 인스턴스를 추가합니다. |
| Jenkins 인스턴스의 자격 증명에 충분한 액세스 권한이 없거나 유효하지 않습니다. | 자격 증명에 충분한 액세스 권한을 부여하거나 유효한 자격 증명을 생성합니다. |
| **Enable authentication for `/project` end-point** 확인란이 [Jenkins 플러그인 구성](#configure-the-jenkins-server)에서 선택되지 않았습니다. | 확인란을 선택합니다. |

### 오류: `Could not connect to the CI server` {#error-could-not-connect-to-the-ci-server}

GitLab이 [Commit Status API](../api/commits.md#commit-status)를 통해 Jenkins에서 빌드 상태 업데이트를 받지 못한 경우 머지 리퀘스트에서 `Could not connect to the CI server`와 같은 오류가 발생할 수 있습니다.

이 이슈는 Jenkins가 제대로 구성되지 않았거나 API를 통해 상태를 보고하는 중에 오류가 발생했을 때 발생합니다.

이 이슈를 해결하려면:

1. GitLab API 액세스를 위해 [Jenkins 서버 구성](#configure-the-jenkins-server)을 합니다.
1. [Jenkins 프로젝트 구성](#configure-the-jenkins-project)을 하고 freestyle 프로젝트를 생성한 경우 "Publish build status to GitLab" 빌드 후 작업을 선택했는지 확인합니다.

### 머지 리퀘스트 이벤트가 Jenkins 파이프라인을 트리거하지 않습니다 {#merge-request-event-does-not-trigger-a-jenkins-pipeline}

요청이 기본적으로 10초로 설정된 [웹후크 시간 제한](../user/gitlab_com/_index.md#webhooks)을 초과할 때 이 이슈가 발생할 수 있습니다.

이 이슈에 대해 다음을 확인합니다:

- 요청 실패에 대한 통합 웹후크 로그입니다.
- `/var/log/gitlab/gitlab-rails/production.log`에서 다음과 같은 메시지를 확인합니다:

  ```plaintext
  WebHook Error => Net::ReadTimeout
  ```

  또는

  ```plaintext
  WebHook Error => execution expired
  ```

GitLab Self-Managed에서는 [웹후크 시간 제한 값을 증가시켜](../administration/instance_limits.md#webhook-timeout) 이 이슈를 해결할 수 있습니다.

### Jenkins에서 작업 로그 활성화 {#enable-job-logs-in-jenkins}

통합 이슈를 해결하기 위해 Jenkins에서 작업 로그를 활성화하여 빌드에 대한 자세한 내용을 볼 수 있습니다.

Jenkins에서 작업 로그를 활성화하려면:

1. **대시보드** > **Manage Jenkins** > **System Log**로 이동합니다.
1. **Add new log recorder**를 선택합니다.
1. 로그 레코더의 이름을 입력합니다.
1. 다음 화면에서 **추가**를 선택하고 `com.dabsquared.gitlabjenkins`를 입력합니다.
1. Log Level이 **전체**인지 확인하고 **저장**를 선택합니다.

로그를 보려면:

1. 빌드를 실행합니다.
1. **대시보드** > **Manage Jenkins** > **System Log**로 이동합니다.
1. 로거를 선택하고 로그를 확인합니다.
