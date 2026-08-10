---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jira DVCS 커넥터
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

자신의 Jira 인스턴스를 Jira Data Center 또는 Jira Server에서 자체 호스팅하고 [Jira 개발 패널](../development_panel.md)을 사용하려면 Jira DVCS(분산 버전 관리 시스템) 커넥터를 사용합니다. Jira DVCS 커넥터는 Atlassian에서 개발하고 관리합니다.

Jira DVCS 커넥터를 구성하려면 [DVCS를 사용하여 개발 도구와 통합](https://confluence.atlassian.com/adminjiraserver/integrating-with-development-tools-using-dvcs-1047552689.html)을 참조하세요. Jira DVCS 커넥터는 Jira 8.14 이상의 Jira Data Center 또는 Jira Server에서만 사용할 수 있습니다.

Jira는 실시간 업데이트를 제공하기 위해 GitLab 웹후크를 GitLab 프로젝트에 생성합니다. 이 웹후크를 구성하려면 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다. 자세한 내용은 [웹후크 보안 구성](https://confluence.atlassian.com/adminjiraserver/configuring-webhook-security-1299913153.html)을 참조하세요.

Jira Cloud용 Jira DVCS 커넥터는 GitLab 16.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118126)되었습니다. 대신 [GitLab for Jira Cloud 앱](../connect-app.md)을 사용합니다. 자세한 내용은 [GitLab for Jira Cloud 앱 설치](../connect-app.md#install-the-gitlab-for-jira-cloud-app)를 참조하세요.

## Jira로 가져온 데이터 새로 고침 {#refresh-data-imported-to-jira}

기본적으로 Jira는 GitLab 프로젝트에 대한 커밋과 브랜치를 60분마다 가져옵니다. Jira에서 데이터를 수동으로 새로 고치려면:

1. 통합을 구성한 사용자로 Jira 인스턴스에 로그인합니다.
1. 상단 바의 오른쪽 위에서 **Administration** ({{< icon name="settings" >}}) > **응용 프로그램**을 선택합니다.
1. 왼쪽 사이드바에서 **DVCS accounts**를 선택합니다.
1. DVCS 계정에서 하나 이상의 리포지토리를 새로 고치려면:
   - **For all repositories**의 경우, 계정 옆에서 줄임표({{< icon name="ellipsis_h" >}}) > **Refresh repositories**을 선택합니다.
   - **For a single repository**의 경우:
     1. 계정을 선택합니다.
     1. 새로 고칠 리포지토리에 마우스를 올리고, **마지막 활동** 열에서 **Click to sync repository**합니다({{< icon name="retry" >}}).
