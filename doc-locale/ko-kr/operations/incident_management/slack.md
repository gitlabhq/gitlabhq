---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Slack용 GitLab 앱을 사용하여 Slack에서 직접 GitLab 이슈를 관리합니다. 여기에는 이슈 선언, 빠른 작업 사용, 알림 수신이 포함됩니다."
title: Slack을 위한 이슈 관리
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태:  베타

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/344856) GitLab 15.7에서 [플래그](../../administration/feature_flags/_index.md) 이름 `incident_declare_slash_command`. 기본적으로 비활성화되어 있습니다.
- [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/378072) GitLab 15.10에서 [베타](../../policy/development_stages_support.md#beta).

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용 준비가 되지 않았습니다.

많은 팀이 Slack의 이슈 중에 경고를 수신하고 실시간으로 협업합니다. Slack용 GitLab 앱을 사용하여:

- Slack에서 GitLab 이슈를 생성합니다.
- 이슈 알림을 수신합니다.

Slack용 이슈 관리는 GitLab.com에서만 사용 가능합니다.

최신 정보를 유지하려면 [에픽 1211](https://gitlab.com/groups/gitlab-org/-/epics/1211)을 따릅니다.

## Slack에서 이슈 관리 {#manage-an-incident-from-slack}

전제 조건:

1. [Slack용 GitLab 앱](../../user/project/integrations/gitlab_slack_application.md)을 설치합니다. 이러한 방식으로 Slack에서 슬래시 명령을 사용하여 GitLab 이슈를 생성하고 업데이트할 수 있습니다.
1. [Slack 알림](../../user/project/integrations/gitlab_slack_application.md#slack-notifications)을 활성화합니다. `Incident` 이벤트에 대한 알림을 활성화하고 Slack 채널을 정의하여 관련 알림을 수신해야 합니다.
1. GitLab이 귀하의 Slack 사용자를 대신하여 작업을 수행하도록 인증합니다. 각 사용자는 이슈 슬래시 명령을 사용하기 전에 이를 수행해야 합니다.

   인증 플로우를 시작하려면 비-이슈 [Slack 슬래시 명령](../../user/project/integrations/gitlab_slack_application.md#slash-commands)(예: `/gitlab <project-alias> issue show <id>`)을 실행해 봅니다. 선택하는 `<project-alias>`는 Slack용 GitLab 앱이 설정된 프로젝트여야 합니다. 선택 대화 상자의 프로젝트 제한은 100개입니다. 자세한 내용은 [이슈 377548](https://gitlab.com/gitlab-org/gitlab/-/issues/377548)을 참조합니다.

## 이슈 선언 {#declare-an-incident}

Slack에서 GitLab 이슈를 선언하려면:

1. Slack의 모든 채널이나 DM에서 `/gitlab incident declare` 슬래시 명령을 입력합니다.
1. 모달에서 다음을 포함한 관련 이슈 세부 정보를 선택합니다:

   - 이슈 제목과 설명.
   - 이슈를 생성할 프로젝트.
   - 이슈의 심각도.

   프로젝트에 기존 [이슈 템플릿](alerts.md#trigger-actions-from-alerts)이 있는 경우 해당 템플릿이 자동으로 설명 텍스트 상자에 적용됩니다. 템플릿은 설명 텍스트 상자가 비어 있는 경우에만 적용됩니다.

   설명 텍스트 상자에 [빠른 작업](../../user/project/quick_actions.md)을 포함할 수도 있습니다. 예를 들어 `/link https://example.slack.com/archives/123456789 Dedicated Slack channel`을 입력하면 생성하는 이슈에 전용 Slack 채널이 추가됩니다. 이슈에 대한 빠른 작업의 전체 목록은 [GitLab 빠른 작업 사용](#use-gitlab-quick-actions)을 참조합니다.
1. 선택 사항. 기존 Zoom 회의에 대한 링크를 추가합니다.
1. **생성**을 선택합니다.

이슈가 성공적으로 생성되면 Slack에 확인 알림이 표시됩니다.

### GitLab 빠른 작업 사용 {#use-gitlab-quick-actions}

Slack에서 GitLab 이슈를 생성할 때 설명 텍스트 상자에 [빠른 작업](../../user/project/quick_actions.md)을 사용합니다. 다음 빠른 작업이 가장 관련이 있을 수 있습니다:

| 명령                  | 설명                               |
| ------------------------ | ----------------------------------------- |
| `/assign @user1 @user2`  | GitLab 이슈에 담당자를 추가합니다.  |
| `/label ~label1 ~label2` | GitLab 이슈에 레이블을 추가합니다.       |
| `/link <URL> <text>`     | 전용 Slack 채널, 런북 또는 기타 관련 리소스에 대한 링크를 이슈의 `Related resources` 섹션에 추가합니다. |
| `/zoom <URL>`            | Zoom 회의 링크를 이슈에 추가합니다. |

## Slack에 GitLab 이슈 알림 전송 {#send-gitlab-incident-notifications-to-slack}

이슈에 대한 [알림을 활성화](#manage-an-incident-from-slack)한 경우 이슈가 열리거나, 닫히거나, 업데이트될 때마다 선택한 Slack 채널로 알림을 받아야 합니다.
