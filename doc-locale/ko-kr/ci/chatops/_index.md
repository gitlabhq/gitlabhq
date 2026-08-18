---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ChatOps
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab ChatOps를 사용하여 Slack과 같은 채팅 서비스를 통해 CI/CD 작업과 상호작용할 수 있습니다.

많은 조직에서 Slack이나 Mattermost를 사용하여 협업하고, 문제를 해결하고, 작업을 계획합니다. ChatOps를 사용하면 팀과 함께 작업을 논의하고, CI/CD 작업을 실행하고, 작업 출력을 보는 모든 것을 동일한 애플리케이션에서 할 수 있습니다.

## 슬래시 명령 통합 {#slash-command-integrations}

ChatOps를 [`run` 슬래시 명령](../../user/project/integrations/gitlab_slack_application.md#slash-commands)으로 트리거할 수 있습니다.

다음과 같은 통합을 사용할 수 있습니다:

- [Slack용 GitLab 앱](../../user/project/integrations/gitlab_slack_application.md)(Slack에 권장)
- [Mattermost 슬래시 명령](../../user/project/integrations/mattermost_slash_commands.md)

## ChatOps 워크플로우 및 CI/CD 구성 {#chatops-workflow-and-cicd-configuration}

ChatOps는 프로젝트의 기본 브랜치에서 [`.gitlab-ci.yml`](../yaml/_index.md)에서 지정된 작업을 찾습니다. 작업을 찾으면 ChatOps는 지정된 작업만 포함하는 파이프라인을 생성합니다. `when: manual`을 설정하면 ChatOps는 파이프라인을 생성하지만 작업은 자동으로 시작되지 않습니다.

ChatOps로 실행된 작업은 GitLab에서 실행된 작업과 동일한 기능을 가집니다. 작업은 추가 권한 유효성 검사를 수행하기 위해 `GITLAB_USER_ID`와 같은 기존 [CI/CD 변수](../variables/_index.md#predefined-cicd-variables)를 사용할 수 있지만, 이러한 변수는 [재정의](../variables/_index.md#cicd-variable-precedence)할 수 있습니다.

표준 CI/CD 파이프라인의 일부로 작업이 실행되지 않도록 [`rules`](../yaml/_index.md#rules)을 설정해야 합니다.

ChatOps는 다음 [CI/CD 변수](../variables/_index.md#predefined-cicd-variables)를 작업에 전달합니다:

- `CHAT_INPUT` - `run` 슬래시 명령으로 전달된 인수입니다.
- `CHAT_CHANNEL` - 작업이 실행되는 채팅 채널의 이름입니다.
- `CHAT_USER_ID` - 작업을 실행하는 사용자의 채팅 서비스 ID입니다.

작업이 실행될 때:

- 작업이 30분 이내에 완료되면 ChatOps는 작업 출력을 채팅 채널로 보냅니다.
- 작업이 30분 이상 소요되면 데이터를 채널로 보내기 위해 [Slack API](https://api.slack.com/)와 같은 방법을 사용해야 합니다.

### ChatOps에서 작업 제외 {#exclude-a-job-from-chatops}

채팅에서 작업이 실행되는 것을 방지하려면:

- `.gitlab-ci.yml`에서 작업을 `except: [chat]`로 설정합니다.

### ChatOps 응답 사용자 정의 {#customize-the-chatops-reply}

ChatOps는 하나의 명령으로 작업의 출력을 채널로 응답으로 보냅니다. 예를 들어 다음 작업이 실행될 때 채팅 응답은 `Hello world`입니다:

```yaml
stages:
- chatops

hello-world:
  stage: chatops
  rules:
    - if: $CI_PIPELINE_SOURCE == "chat"
  script:
    - echo "Hello World"
```

작업에 여러 명령이 포함되어 있거나 `before_script`이 설정되어 있으면 ChatOps는 명령과 해당 출력을 채널로 보냅니다. 명령은 ANSI 색상 코드로 래핑됩니다.

하나의 명령 출력으로 선택적으로 응답하려면 출력을 `chat_reply` 섹션에 배치합니다. 예를 들어 다음 작업은 현재 디렉터리의 파일을 나열합니다:

```yaml
stages:
- chatops

ls:
  stage: chatops
  rules:
    - if: $CI_PIPELINE_SOURCE == "chat"
  script:
    - echo "This command will not be shown."
    - echo -e "section_start:$( date +%s ):chat_reply\r\033[0K\n$( ls -la )\nsection_end:$( date +%s ):chat_reply\r\033[0K"
```

## ChatOps를 사용하여 CI/CD 작업 실행 {#run-a-cicd-job-using-chatops}

전제 조건:

- 프로젝트에 대한 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.
- 프로젝트가 슬래시 명령 통합을 사용하도록 구성되어 있습니다.

Slack 또는 Mattermost에서 기본 브랜치에서 CI/CD 작업을 실행할 수 있습니다.

CI/CD 작업을 실행하는 슬래시 명령은 프로젝트에 대해 구성된 슬래시 명령 통합에 따라 달라집니다.

- Slack용 GitLab 앱의 경우 `/gitlab <project-name> run <job name> <arguments>`을 사용합니다.
- Slack 또는 Mattermost 슬래시 명령의 경우 `/<trigger-name> run <job name> <arguments>`을 사용합니다.

위치:

- `<job name>`은 실행할 CI/CD 작업의 이름입니다.
- `<arguments>`은 CI/CD 작업에 전달할 인수입니다.
- `<trigger-name>`은 Slack 또는 Mattermost 통합을 위해 구성된 트리거 이름입니다.

ChatOps는 지정된 작업만 포함하는 파이프라인을 예약합니다.

## 관련 항목 {#related-topics}

- GitLab이 GitLab.com과 상호작용하는 데 사용하는 [일반적인 ChatOps 스크립트 리포지토리](https://gitlab.com/gitlab-com/chatops)
- [Slack용 GitLab 앱](../../user/project/integrations/gitlab_slack_application.md)
- [Mattermost 슬래시 명령](../../user/project/integrations/mattermost_slash_commands.md)
