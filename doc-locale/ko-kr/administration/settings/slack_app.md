---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Slack 앱용 GitLab 관리
description: "GitLab Self-Managed 인스턴스에서 Slack 앱용 GitLab을 관리, 구성 및 문제 해결합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 16.2에서 GitLab Self-Managed용으로 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/358872)

{{< /history >}}

> [!note]
> 이 페이지는 Slack 앱용 GitLab의 관리자 문서입니다. 사용자 문서는 [Slack 앱용 GitLab](../../user/project/integrations/gitlab_slack_application.md)을 참조하세요.

Slack App Directory를 통해 배포되는 Slack 앱용 GitLab은 GitLab.com에서만 작동합니다. GitLab Self-Managed에서는 [매니페스트 파일](https://api.slack.com/reference/manifests#creating_apps)에서 Slack 앱용 GitLab의 고유한 사본을 만들고 인스턴스를 구성할 수 있습니다.

앱은 Slack 워크스페이스에만 설치된 비공개 일회용 사본이며 Slack App Directory를 통해 배포되지 않습니다. GitLab Self-Managed 인스턴스에서 [Slack 앱용 GitLab](../../user/project/integrations/gitlab_slack_application.md)을 사용하려면 연동을 활성화해야 합니다.

## Slack 앱용 GitLab 만들기 {#create-a-gitlab-for-slack-app}

전제 조건:

- 최소한 [Slack 워크스페이스 관리자](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack) 이상이어야 합니다.

Slack 앱용 GitLab을 만들려면:

- **GitLab 에서**:

  1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
  1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
  1. **Slack 앱용 GitLab**을 펼칩니다.
  1. **Slack 앱 만들기**를 선택합니다.

그러면 Slack으로 리디렉션되어 다음 단계를 진행합니다.

- **In Slack**:

  1. 앱을 만들 Slack 워크스페이스를 선택한 후 **다음**을 선택합니다.
  1. Slack에서 검토할 앱의 요약을 표시합니다. 전체 매니페스트를 보려면 **Edit Configurations**를 선택합니다. 검토 요약으로 돌아가려면 **다음**을 선택합니다.
  1. **생성**을 선택합니다.
  1. 대화상자를 닫으려면 **확인**을 선택합니다.
  1. **Install to Workspace**를 선택합니다.

## 설정 구성 {#configure-the-settings}

[Slack 앱용 GitLab을 만든](#create-a-gitlab-for-slack-app) 후 GitLab에서 설정을 구성할 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **Slack 앱용 GitLab**을 펼칩니다.
1. **Slack 앱용 GitLab 활성화** 확인란을 선택합니다.
1. Slack 앱용 GitLab의 세부 정보를 입력합니다:
   1. [Slack API](https://api.slack.com/apps)로 이동합니다.
   1. **GitLab (`<your host name>`)**을 검색하여 선택합니다.
   1. **App Credentials**로 스크롤합니다.
1. **변경 사항 저장**을 선택합니다.

## Slack 앱용 GitLab 설치 {#install-the-gitlab-for-slack-app}

{{< history >}}

- 특정 인스턴스 설치가 [GitLab 16.10에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/391526) 되었으며 [플래그](../feature_flags/_index.md) `gitlab_for_slack_app_instance_and_group_level` 이름이 지정되었습니다. 기본적으로 비활성화됨.
- [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820)됨 - GitLab 16.11.
- [GitLab 17.8에서 일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803)해졌습니다. 기능 플래그 `gitlab_for_slack_app_instance_and_group_level` 제거됨.

{{< /history >}}

전제 조건:

- Slack 워크스페이스에 앱을 추가할 수 있는 [적절한 권한](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)을 가져야 합니다.
- [Slack 앱용 GitLab을 만들고](#create-a-gitlab-for-slack-app) [앱 설정을 구성](#configure-the-settings)해야 합니다.

인스턴스 설정에서 Slack 앱용 GitLab을 설치하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **Slack 앱용 GitLab**을 선택합니다.
1. **Slack 앱용 GitLab 설치**를 선택합니다.
1. Slack 확인 페이지에서 **허용**을 선택합니다.

### 구성 테스트 {#test-your-configuration}

Slack 앱용 GitLab 구성을 테스트하려면:

1. Slack 워크스페이스의 채널에 `/gitlab help` 슬래시 명령어를 입력합니다.
1. <kbd>Enter</kbd> 키를 누릅니다.

사용 가능한 슬래시 명령어 목록이 표시됩니다.

프로젝트에 대한 슬래시 명령어를 사용하려면 프로젝트의 [Slack 앱용 GitLab](../../user/project/integrations/gitlab_slack_application.md)을 구성합니다.

## Slack 앱용 GitLab 업데이트 {#update-the-gitlab-for-slack-app}

전제 조건:

- 최소한 [Slack 워크스페이스 관리자](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack) 이상이어야 합니다.

GitLab에서 Slack 앱용 GitLab의 새로운 기능을 릴리스하면 새로운 기능을 사용하기 위해 사본을 수동으로 업데이트해야 할 수 있습니다.

Slack 앱용 GitLab 사본을 업데이트하려면:

- **GitLab 에서**:
  1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
  1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
  1. **Slack 앱용 GitLab**을 펼칩니다.
  1. **최신 매니페스트 파일 다운로드**를 선택하여 `slack_manifest.json`를 다운로드합니다.
- **In Slack**:
  1. [Slack API](https://api.slack.com/apps)로 이동합니다.
  1. **GitLab (`<your host name>`)**을 검색하여 선택합니다.
  1. 왼쪽 사이드바에서 **App Manifest**를 선택합니다.
  1. **JSON** 탭을 선택하여 매니페스트의 JSON 보기로 전환합니다.
  1. GitLab에서 다운로드한 `slack_manifest.json` 파일의 내용을 복사합니다.
  1. JSON 뷰어에 내용을 붙여넣어 기존 내용을 바꿉니다.
  1. **변경 사항 저장**을 선택합니다.

## 연결 요구 사항 {#connectivity-requirements}

Slack 앱용 GitLab 기능을 활성화하려면 네트워크가 GitLab과 Slack 간에 인바운드 및 아웃바운드 연결을 허용해야 합니다.

- [Slack 알림](../../user/project/integrations/gitlab_slack_application.md#slack-notifications)의 경우 GitLab 인스턴스가 `https://slack.com`로 요청을 보낼 수 있어야 합니다.
- [슬래시 명령어](../../user/project/integrations/gitlab_slack_application.md#slash-commands) 및 기타 기능의 경우 GitLab 인스턴스가 `https://slack.com`에서 요청을 받을 수 있어야 합니다.

## 여러 워크스페이스에 대한 지원 활성화 {#enable-support-for-multiple-workspaces}

기본적으로 [Slack 앱용 GitLab을 설치](../../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)할 수 있는 Slack 워크스페이스는 하나뿐입니다. 관리자는 [Slack 앱용 GitLab을 만들](#create-a-gitlab-for-slack-app) 때 이 워크스페이스를 선택합니다.

여러 Slack 워크스페이스를 지원하도록 설정하려면 Slack 앱용 GitLab을 [미등록 배포 앱](https://api.slack.com/distribution#unlisted-distributed-apps)으로 구성해야 합니다. 미등록 배포 앱:

- Slack App Directory에 게시되지 않습니다.
- GitLab 인스턴스에서만 사용할 수 있으며 다른 사이트에서는 사용할 수 없습니다.

Slack 앱용 GitLab을 미등록 배포 앱으로 구성하려면:

1. Slack의 [**Your Apps**](https://api.slack.com/apps) 페이지로 이동하여 Slack 앱용 GitLab을 선택합니다.
1. **Manage Distribution**을 선택합니다.
1. **Share Your App with Other Workspaces** 섹션에서 **Remove Hard Coded Information**을 펼칩니다.
1. **I've reviewed and removed any hard-coded information** 확인란을 선택합니다.
1. **Activate Public Distribution**을 선택합니다.

## 문제 해결 {#troubleshooting}

Slack 앱용 GitLab을 관리할 때 다음과 같은 이슈가 발생할 수 있습니다.

사용자 문서는 [Slack 앱용 GitLab](../../user/project/integrations/gitlab_slack_app_troubleshooting.md)을 참조하세요.

### 슬래시 명령어가 Slack에서 `dispatch_failed`을 반환합니다 {#slash-commands-return-dispatch_failed-in-slack}

슬래시 명령어가 Slack에서 `/gitlab failed with the error "dispatch_failed"`을 반환할 수 있습니다.

이 이슈를 해결하려면 다음을 확인하세요:

- Slack 앱용 GitLab이 제대로 [구성](#configure-the-settings)되어 있고 **Slack 앱용 GitLab 활성화** 확인란이 선택되어 있습니다.
- GitLab 인스턴스가 [Slack으로부터의 요청을 허용](#connectivity-requirements)합니다.
