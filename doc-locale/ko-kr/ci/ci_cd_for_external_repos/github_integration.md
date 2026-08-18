---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitHub 리포지토리를 GitLab CI/CD에 연결하세요.
title: GitHub 리포지토리로 GitLab CI/CD 사용하기
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD는 **GitHub.com**과 **GitHub Enterprise**로 [CI/CD 프로젝트](_index.md)를 생성하여 GitHub 리포지토리를 GitLab에 연결할 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> [GitHub 리포지토리로 GitLab CI/CD 파이프라인 사용하기](https://www.youtube.com/watch?v=qgl3F2j-1cI)의 비디오를 확인하세요.

> [!note]
> [GitHub 제한](https://gitlab.com/gitlab-org/gitlab/-/issues/9147)으로 인해 [GitHub OAuth](../../integration/github.md#enable-github-oauth-in-gitlab)는 외부 CI/CD 리포지토리로 GitHub 인증에 사용할 수 없습니다.

## 개인 액세스 토큰으로 연결 {#connect-with-personal-access-token}

개인 액세스 토큰은 GitHub.com 리포지토리를 GitLab에 연결하는 데만 사용할 수 있으며, GitHub 사용자는 [소유자 역할](https://docs.github.com/en/get-started/learning-about-github/access-permissions-on-github)을 가져야 합니다.

GitHub를 통해 일회성 인증을 수행하여 GitLab에 리포지토리 접근을 허가하려면:

1. GitHub에서 토큰을 생성합니다:
   1. <https://github.com/settings/tokens/new>을 엽니다.
   1. 개인 액세스 토큰을 생성합니다.
   1. **토큰 설명**을 입력하고 범위를 업데이트하여 `repo`과 `admin:repo_hook`을 허가하면 GitLab이 프로젝트에 접근하고, 커밋 상태를 업데이트하며, GitLab에 새 커밋을 알리는 웹후크를 생성할 수 있습니다.
1. GitLab에서 프로젝트를 생성합니다:
   1. 오른쪽 상단 모서리에서 **새로 만들기** ({{< icon name="plus" >}}) 및 **새 프로젝트/리포지토리**를 선택합니다.
   1. **외부 리포지토리에 대한 CI/CD 실행**을 선택합니다.
   1. **GitHub**를 선택합니다.
   1. **개인 액세스 토큰**에 토큰을 붙여넣습니다.
   1. **List Repositories**을 선택합니다.
   1. **연결**을 선택하여 리포지토리를 선택합니다.
1. GitHub에서 `.gitlab-ci.yml`을 추가하여 [GitLab CI/CD를 구성](../quick_start/_index.md)합니다.

GitLab:

1. 프로젝트를 가져옵니다.
1. [끌어오기 미러링](../../user/project/repository/mirror/pull.md)을 활성화합니다.
1. [GitHub 프로젝트 연동](../../user/project/integrations/github.md)을 활성화합니다.
1. GitHub에서 GitLab에 새 커밋을 알리는 웹후크를 생성합니다.

## 수동으로 연결 {#connect-manually}

**GitHub Enterprise**를 **GitLab.com**과 함께 사용하려면 이 방법을 사용하세요.

GitLab CI/CD를 리포지토리에 수동으로 활성화하려면:

1. GitHub에서 토큰을 생성합니다:
   1. <https://github.com/settings/tokens/new>을 엽니다.
   1. 개인 액세스 토큰을 생성합니다.
   1. **토큰 설명**을 입력하고 범위를 업데이트하여 `repo`을 허가하면 GitLab이 프로젝트에 접근하고 커밋 상태를 업데이트할 수 있습니다.
1. GitLab에서 프로젝트를 생성합니다:
   1. 오른쪽 상단 모서리에서 **새로 만들기** ({{< icon name="plus" >}}) 및 **새 프로젝트/리포지토리**를 선택합니다.
   1. **외부 리포지토리에 대한 CI/CD 실행** 및 **리포지토리 URL**을 선택합니다.
   1. **Git 리포지토리 URL** 필드에서 GitHub 리포지토리의 HTTPS URL을 입력합니다. 프로젝트가 비공개인 경우, 방금 생성한 개인 액세스 토큰을 인증에 사용합니다.
   1. 다른 모든 필드를 입력하고 **프로젝트 생성**을 선택합니다. GitLab이 폴링 기반 끌어오기 미러링을 자동으로 구성합니다.
1. GitLab에서 [GitHub 프로젝트 연동](../../user/project/integrations/github.md)을 활성화합니다:
   1. 좌측 사이드바에서 **설정** > **연동**을 선택합니다.
   1. **활성** 확인란을 선택합니다.
   1. 개인 액세스 토큰과 HTTPS 리포지토리 URL을 양식에 붙여넣고 **저장**을 선택합니다.
1. GitLab에서 `API` 범위가 있는 개인 액세스 토큰을 생성하여 GitHub 웹후크를 인증해 GitLab에 새 커밋을 알립니다.
1. GitHub의 **설정** > **Webhooks**에서 GitLab에 새 커밋을 알리는 웹후크를 생성합니다.

   웹후크 URL을 GitLab API에 설정하여 [끌어오기 미러링을 트리거](../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)하고, 방금 생성한 GitLab 개인 액세스 토큰을 사용합니다:

   ```plaintext
   https://gitlab.com/api/v4/projects/<NAMESPACE>%2F<PROJECT>/mirror/pull?private_token=<PERSONAL_ACCESS_TOKEN>
   ```

   **Let me select individual events** 옵션을 선택한 다음, **풀 리퀘스트** 및 **푸시** 확인란을 선택합니다. 이 설정은 [외부 풀 리퀘스트에 대한 파이프라인](_index.md#pipelines-for-external-pull-requests)에 필요합니다.

1. GitHub에서 `.gitlab-ci.yml`을 추가하여 GitLab CI/CD를 구성합니다.
