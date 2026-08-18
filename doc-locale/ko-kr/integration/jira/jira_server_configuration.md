---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab에서 Jira 이슈 통합을 인증하기 위해 Jira 사용자, 그룹 및 권한 체계를 생성합니다."
title: '튜토리얼: Jira 자격 증명 생성'
---

이 자습서에서는 전용 Jira 사용자를 설정하고 Jira 이슈 통합에 필요한 권한을 부여합니다. 모든 단계는 GitLab이 아니라 Jira에서 수행됩니다.

이 자습서를 완료한 후 여기서 생성한 Jira 사용자명과 비밀번호를 사용하여 GitLab에서 Jira 이슈 통합을 구성합니다.

Jira 자격 증명을 생성하려면:

1. [Jira 사용자 생성](#create-a-jira-user)
1. [사용자를 위한 Jira 그룹 생성](#create-a-jira-group-for-the-user)
1. [그룹에 대한 권한 체계 생성](#create-a-permission-scheme-for-the-group)
1. [권한 체계를 프로젝트에 할당](#assign-the-permission-scheme-to-your-projects)

## 시작하기 전에 {#before-you-begin}

- **Jira administrators** 또는 **Jira System administrators** [전역 권한](https://confluence.atlassian.com/adminjiraserver/managing-global-permissions-938847142.html)이 있어야 합니다.

## Jira 사용자 생성 {#create-a-jira-user}

Jira 사용자를 생성하려면:

1. 우측 상단 모서리에서 **Administration** > **User management**를 선택합니다.
1. [새 사용자 계정 생성](https://confluence.atlassian.com/adminjiraserver/create-edit-or-remove-a-user-938847025.html#Create,edit,orremoveauser-CreateusersmanuallyinJira)(Jira 프로젝트에 대한 쓰기 액세스 포함):

   - **이메일 주소**에 유효한 이메일 주소를 입력합니다.
   - **사용자명**에 `gitlab`를 입력합니다.
   - **비밀번호**에 비밀번호를 입력합니다. Jira 이슈 통합은 SAML과 같은 SSO를 지원하지 않습니다.

1. **사용자 생성**을 선택합니다.

기존 사용자 계정을 사용할 수도 있으며, 사용자가 필요한 권한이 있는 그룹에 속해 있어야 합니다.

`gitlab` 사용자를 생성했으므로 이제 사용자에 대한 그룹을 생성할 차례입니다.

## 사용자를 위한 Jira 그룹 생성 {#create-a-jira-group-for-the-user}

사용자를 위한 Jira 그룹을 생성하려면:

1. 우측 상단 모서리에서 **Administration** > **User management**를 선택합니다.
1. 왼쪽 사이드바에서 **그룹**을 선택합니다.
1. **그룹 추가** 섹션에서 그룹의 이름을 입력한 후(예: `gitlab-developers`) **그룹 추가**를 선택합니다.
1. `gitlab` 사용자를 `gitlab-developers` 그룹에 추가하려면 **Edit members**을 선택합니다. `gitlab-developers` 그룹이 선택된 그룹으로 표시됩니다.
   <!-- vale gitlab_base.BadPlurals = NO -->
1. **Add members to selected group(s)** 섹션에 `gitlab`를 입력합니다.
   <!-- vale gitlab_base.BadPlurals = YES -->
1. **Add selected users**를 선택합니다. `gitlab` 사용자가 그룹 구성원으로 표시됩니다.

`gitlab` 사용자를 `gitlab-developers` 그룹에 추가했으므로 이제 그룹에 대한 권한 체계를 생성할 차례입니다.

## 그룹에 대한 권한 체계 생성 {#create-a-permission-scheme-for-the-group}

Jira 이슈 통합은 프로젝트를 탐색하고, 이슈를 생성 및 편집하고, 의견을 추가할 수 있는 권한이 필요합니다. 이러한 작업에 필요한 권한만 부여합니다.

권한 체계를 생성하려면:

1. 우측 상단 모서리에서 **Administration** > **이슈**를 선택합니다.
1. 왼쪽 사이드바에서 **Permission schemes**를 선택합니다.
1. **Add permission scheme**를 선택합니다.
1. **Add permission scheme** 대화 상자에서 필드를 작성합니다.
1. **추가**를 선택합니다.
1. **Permission schemes** 페이지의 **조치** 열에서 새 체계에 대한 **권한**을 선택합니다.
1. 다음 각 권한에 대해 **편집**을 선택하고, `gitlab-developers` 그룹에 권한을 부여한 후, **Grant**를 선택합니다:

   - **Browse Projects**
   - **Create Issues**
   - **Edit Issues**
   - **Add Comments**

권한 체계를 구성했으므로 이제 이를 Jira 프로젝트에 할당할 차례입니다.

## 권한 체계를 프로젝트에 할당 {#assign-the-permission-scheme-to-your-projects}

권한 체계는 최소한 하나의 프로젝트와 연결될 때까지 효과가 없습니다. Jira 이슈 통합이 액세스하길 원하는 각 Jira 프로젝트에 대해 이 단계를 반복합니다.

권한 체계를 프로젝트에 할당하려면:

1. 우측 상단 모서리에서 **Administration** > **프로젝트**를 선택합니다.
1. 구성할 프로젝트를 선택합니다.
1. **프로젝트 설정**에서 **권한**을 선택합니다.
1. **조치** > **Use a different scheme**을 선택합니다.
1. 생성한 체계를 선택한 후 **Associate**을 선택합니다.

완료되었습니다! 이제 GitLab으로 이동하여 여기서 생성한 `gitlab` 사용자명과 비밀번호를 사용하여 [Jira 이슈 통합을 구성](configure.md)합니다.
