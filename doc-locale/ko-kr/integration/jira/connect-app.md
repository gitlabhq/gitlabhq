---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jira Cloud 앱용 GitLab
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> 관리자 문서는 [Jira Cloud 앱용 GitLab 관리](../../administration/settings/jira_cloud_app.md)를 참조하세요.

[Jira Cloud용 GitLab](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud) 앱을 사용하면 GitLab과 Jira Cloud를 연결하여 개발 정보를 실시간으로 동기화할 수 있습니다. 이 정보는 [Jira 개발 패널](development_panel.md)에서 확인할 수 있습니다.

Jira Cloud 앱용 GitLab을 사용하여 최상위 그룹 또는 하위 그룹을 연결할 수 있습니다. 프로젝트 또는 개인 네임스페이스를 직접 연결할 수는 없습니다.

GitLab.com에서 Jira Cloud 앱용 GitLab을 설정하려면 [Jira Cloud 앱용 GitLab 설치](#install-the-gitlab-for-jira-cloud-app)를 하세요.

앱을 설정한 후에는 Atlassian에서 개발하고 유지 관리하는 [프로젝트 도구 모음](https://support.atlassian.com/jira-software-cloud/docs/what-is-the-connections-feature/)을 사용하여 [GitLab 리포지토리를 Jira 프로젝트로 연결](https://support.atlassian.com/jira-software-cloud/docs/link-repositories-to-a-project/#Link-repositories-using-the-toolchain-feature)할 수 있습니다. 프로젝트 도구 모음은 GitLab과 Jira Cloud 간의 개발 정보 동기화 방식에 영향을 주지 않습니다.

Jira Data Center 또는 Jira Server의 경우, Atlassian에서 개발하고 유지 관리하는 [Jira DVCS 커넥터](dvcs/_index.md)를 사용합니다.

## Jira로 동기화되는 GitLab 데이터 {#gitlab-data-synced-to-jira}

그룹을 연결한 후에는, [Jira 이슈 ID를 언급](development_panel.md#information-displayed-in-the-development-panel)할 때 해당 그룹의 모든 프로젝트에 대해 다음의 GitLab 데이터가 Jira로 동기화됩니다:

- 기존 프로젝트 데이터 (그룹을 연결하기 전):
  - 마지막 400개의 머지 리퀘스트
  - 마지막 400개의 브랜치 및 각 브랜치의 마지막 커밋 (GitLab 15.11 이상)
- 새 프로젝트 데이터 (그룹을 연결한 후):
  - 머지 리퀘스트
    - 머지 리퀘스트 작성자
  - 브랜치
  - 커밋
    - 커밋 작성자
  - 파이프라인
  - 배포
  - 기능 플래그

## Jira Cloud 앱용 GitLab 설치 {#install-the-gitlab-for-jira-cloud-app}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

전제 조건:

- 네트워크는 GitLab과 Jira 간의 인바운드 및 아웃바운드 연결을 허용해야 합니다.
- 특정 [Jira 사용자 요구 사항](../../administration/settings/jira_cloud_app.md#jira-user-requirements)을 충족해야 합니다.

Jira Cloud 앱용 GitLab을 설치하려면:

1. Jira에서 상단 표시줄의 **Apps** > **Explore more apps**를 선택하고 `GitLab for Jira Cloud`을 검색합니다.
1. **Jira Cloud용 GitLab**을 선택한 다음 **Get it now**를 선택합니다.

또는 [Atlassian Marketplace에서 앱 직접 받기](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud)를 선택할 수 있습니다.

이제 [Jira Cloud 앱용 GitLab 구성](#configure-the-gitlab-for-jira-cloud-app)을 할 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [GitLab.com용 Atlassian Marketplace에서 Jira Cloud 앱용 GitLab 설치](https://youtu.be/52rB586_rs8?list=PL05JrBw4t0Koazgli_PmMQCER2pVH7vUT)를 참조하세요.
<!-- Video published on 2024-10-30 -->

위 비디오는 최신 Jira Cloud 인스턴스에서 사용하지 못할 수도 있는 이전 [Universal Plugin Manager 인터페이스](https://community.atlassian.com/forums/Community-Announcements-articles/Cloud-admins-we-re-making-app-management-easier/ba-p/2806285)를 보여줍니다. 다음 지침은 이전 앱 관리 인터페이스와 새로운 앱 관리 인터페이스를 모두 다룹니다.

## Jira Cloud 앱용 GitLab 구성 {#configure-the-gitlab-for-jira-cloud-app}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

{{< history >}}

- **Add namespace**가 GitLab 16.1에서 **그룹 링크**로 [이름 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/331432)되었습니다.

{{< /history >}}

전제 조건:

- GitLab 그룹에 대한 유지관리자 또는 소유자 역할이 있어야 합니다.
- 특정 [Jira 사용자 요구 사항](../../administration/settings/jira_cloud_app.md#jira-user-requirements)을 충족해야 합니다.

Jira Cloud 앱용 GitLab을 하나 이상의 GitLab 그룹으로 연결하여 GitLab에서 Jira로 데이터를 동기화할 수 있습니다. Jira Cloud 앱용 GitLab을 구성하려면:

<!-- markdownlint-disable MD044 -->

1. Jira에서 **Apps** 옆의 수평 줄임표 ({{< icon name="ellipsis_h" >}})를 선택한 후 **Manage your apps**를 선택합니다.
1. 다음 방법 중 하나를 사용하여 앱으로 이동합니다:

   - 중앙 집중식 앱 관리가 있는 인스턴스의 경우:

     1. "앱 관리가 관리로 이동되었습니다"라는 메시지가 표시되면 **Take me there**을 선택합니다. 그렇지 않으면 아래의 **For instances with legacy app management** 지침을 따르세요.
     1. **Installed apps** 탭에서 **GitLab for Jira**을 찾습니다. 앱을 설치한 방법에 따라 앱의 이름이 다릅니다:
        - **GitLab for Jira (gitlab.com)** (Atlassian Marketplace에서 [앱을 설치](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud)한 경우).
        - **Jira용 GitLab (`<gitlab.example.com>`)** ([앱을 수동으로 설치](../../administration/settings/jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)한 경우).
     1. 수평 줄임표 ({{< icon name="ellipsis_h" >}})를 선택한 후 **시작하기**를 선택하여 통합을 구성합니다.

   - 레거시 앱 관리가 있는 인스턴스의 경우:

     1. **GitLab for Jira**을 확장합니다. 앱을 설치한 방법에 따라 앱의 이름이 다릅니다:
        - **GitLab for Jira (gitlab.com)** (Atlassian Marketplace에서 [앱을 설치](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud)한 경우).
        - **Jira용 GitLab (`<gitlab.example.com>`)** ([앱을 수동으로 설치](../../administration/settings/jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)한 경우).
     1. **시작하기**를 선택하여 통합을 구성합니다.

1. 선택 사항. GitLab Self-Managed를 Jira와 연결하려면 **GitLab 버전 변경**을 선택합니다.
   1. 모든 확인란을 선택한 후 **다음**을 선택합니다.
   1. **GitLab 인스턴스 URL**을 입력한 후 **저장**을 선택합니다.
1. **GitLab에 로그인**을 선택합니다.

   > [!note]
   > [엔터프라이즈 사용자](../../user/enterprise_user/_index.md)가 [그룹에 대해 비밀번호 인증이 비활성화](../../user/group/saml_sso/_index.md#disable-password-and-passkey-authentication-for-enterprise-users)된 경우 먼저 그룹의 single sign-on URL로 GitLab에 로그인해야 합니다.

   GitLab을 사용하려면 로그인이 필요하지만, 특정 사용자에게 구성을 연결하지는 않습니다. GitLab 인스턴스는 Jira에서 Jira의 정보를 업데이트하는 데 사용되는 토큰을 받습니다. 자세한 내용은 [Jira에 대한 GitLab 액세스](#gitlab-access-to-jira)를 참조하세요.
1. **권한 부여**를 선택합니다. 이제 그룹 목록이 표시됩니다.
1. **그룹 링크**를 선택합니다.
1. 그룹으로 연결하려면 **링크**를 선택합니다.

<!-- markdownlint-enable MD044 -->

GitLab 그룹으로 연결한 후:

- 해당 그룹의 모든 프로젝트에 대해 Jira로 데이터가 동기화됩니다. 초기 데이터 동기화는 분당 20개 프로젝트의 배치로 진행됩니다. 프로젝트가 많은 그룹의 경우, 일부 프로젝트의 데이터 동기화가 지연될 수 있습니다.
- Jira Cloud 앱용 GitLab 통합이 그룹 및 해당 그룹의 모든 하위 그룹 또는 프로젝트에 대해 자동으로 활성화됩니다. 통합을 통해 [Jira 서비스 관리 구성](#configure-jira-service-management)을 할 수 있습니다.

## Jira 서비스 관리 구성 {#configure-jira-service-management}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/460663)됨 [기능 플래그와 함께](../../administration/feature_flags/_index.md) `enable_jira_connect_configuration` 이름으로 지정됨. 기본적으로 비활성화되었습니다.
- GitLab 17.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467117)합니다. `enable_jira_connect_configuration` 기능 플래그가 제거되었습니다.

{{< /history >}}

> [!note]
> 이 기능은 커뮤니티 기여로 추가되었으며 GitLab 커뮤니티에서만 개발하고 유지 관리합니다.

전제 조건:

- Jira Cloud 앱용 GitLab이 [설치](#install-the-gitlab-for-jira-cloud-app)되어야 합니다.
- Jira Cloud 앱용 GitLab 앱 구성에서 연결할 [GitLab 그룹](#configure-the-gitlab-for-jira-cloud-app).

GitLab을 IT 서비스 프로젝트에 연결하여 배포를 추적할 수 있습니다.

구성은 GitLab의 Jira Cloud 앱용 GitLab 통합에서 진행됩니다. 통합은 [GitLab 그룹이 연결된](#configure-the-gitlab-for-jira-cloud-app) 후 GitLab의 그룹, 하위 그룹 및 프로젝트에 대해 활성화됩니다.

Jira Cloud 앱용 GitLab 통합을 활성화 및 비활성화하는 것은 그룹 연결을 통해 완전히 자동으로 진행되며, GitLab 통합 양식이나 API를 통해서는 진행되지 않습니다.

Jira 서비스 관리에서:

1. 서비스 프로젝트에서 **프로젝트 설정** > **Change management**로 이동합니다.
1. **Connect Pipeline** > **GitLab**을 선택한 후 설정 흐름 끝에서 **서비스 ID**를 복사합니다.

GitLab에서:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. **Jira Cloud 앱용 GitLab**을 선택합니다. 통합이 비활성화된 경우 먼저 [GitLab 그룹을 연결](#configure-the-gitlab-for-jira-cloud-app)하여 그룹, 하위 그룹 및 프로젝트에 대해 Jira Cloud 앱용 GitLab 통합을 활성화합니다.
1. **서비스 ID** 필드에 이 프로젝트로 매핑하려는 서비스 ID를 입력합니다. 여러 서비스 ID를 사용하려면 각 서비스 ID 사이에 쉼표를 추가합니다.

최대 100개의 서비스를 매핑할 수 있습니다.

Jira의 배포 추적에 대한 자세한 내용은 [배포 추적 설정](https://support.atlassian.com/jira-service-management-cloud/docs/set-up-deployment-tracking/)을 참조하세요.

### GitLab을 사용한 배포 게이팅 설정 {#set-up-deployment-gating-with-gitlab}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/473774)되었습니다.

{{< /history >}}

> [!note]
> 이 기능은 커뮤니티 기여로 추가되었으며 GitLab 커뮤니티에서만 개발하고 유지 관리합니다.

승인을 위해 배포 게이팅을 설정하여 GitLab에서 Jira 서비스 관리로 변경 요청을 가져올 수 있습니다. 배포 게이팅을 사용하면 선택한 환경에 대한 모든 GitLab 배포가 자동으로 Jira 서비스 관리로 전송되며, 승인된 경우에만 배포됩니다.

#### 서비스 계정 토큰 생성 {#create-the-service-account-token}

GitLab에서 서비스 계정 토큰을 생성하려면 먼저 개인 액세스 토큰을 생성해야 합니다. 이 토큰은 Jira 서비스 관리에서 GitLab 배포를 관리하는 데 사용되는 서비스 계정 토큰을 인증합니다.

서비스 계정 토큰을 생성하려면:

1. [서비스 계정 사용자 생성](../../api/service_accounts.md#create-an-instance-service-account).
1. 개인 액세스 토큰을 사용하여 [서비스 계정을 그룹 또는 프로젝트에 추가](../../api/group_members.md#add-a-group-member)합니다.
1. [서비스 계정을 보호 환경에 추가](../../ci/environments/protected_environments.md#protecting-environments)합니다.
1. 개인 액세스 토큰을 사용하여 [서비스 계정 토큰 생성](../../api/service_accounts.md#create-a-personal-access-token-for-a-group-service-account)합니다.
1. 서비스 계정 토큰 값을 복사합니다.

#### 배포 게이팅 활성화 {#enable-deployment-gating}

배포 게이팅을 활성화하려면:

- GitLab에서:

  1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
  1. **설정** > **연동**을 선택합니다.
  1. **Jira Cloud 앱용 GitLab**을 선택합니다.
  1. **Deployment gating** 아래에서 **Enable deployment gating** 확인란을 선택합니다.
  1. **Environment tiers** 텍스트 상자에 배포 게이팅을 활성화하려는 환경의 이름을 입력합니다. 쉼표로 구분된 여러 환경 이름을 입력할 수 있습니다 (예: `production, staging, testing, development`). 소문자만 사용합니다.
  1. **변경 사항 저장**을 선택합니다.
- Jira 서비스 관리에서:

  1. [배포 게이팅 설정](https://support.atlassian.com/jira-service-management-cloud/docs/set-up-deployment-gating/).
  1. **서비스 계정 토큰** 텍스트 상자에 [GitLab에서 복사한 서비스 계정 토큰 값 붙여넣기](#create-the-service-account-token).

#### 보호 환경에 서비스 계정 추가 {#add-the-service-account-to-protected-environments}

GitLab에서 보호 환경에 서비스 계정을 추가하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **보호 환경**을 확장한 후 **환경을 보호**를 선택합니다.
1. **환경을 선택하세요** 드롭다운 목록에서 보호할 환경을 선택합니다 (예: **staging**).
1. **배포 허용됨** 드롭다운 목록에서 이 환경에 배포할 수 있는 사용자를 선택합니다 (예: **개발자 + 유지관리자**).
1. **승인자** 드롭다운 목록에서 [생성한 서비스 계정](#create-the-service-account-token)을 선택합니다.
1. **보호**를 선택합니다.

#### 예제 API 요청 {#example-api-requests}

- 서비스 계정 사용자 생성:

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "name=<name_of_your_choice>&username=<username_of_your_choice>"  "<https://gitlab.com/api/v4/groups/<group_id>/service_accounts"
  ```

- 개인 액세스 토큰을 사용하여 서비스 계정을 그룹 또는 프로젝트에 추가:

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
       --data "user_id=<service_account_id>&access_level=30" "https://gitlab.com/api/v4/groups/<group_id>/members"
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
       --data "user_id=<service_account_id>&access_level=30" "https://gitlab.com/api/v4/projects/<project_id>/members"
  ```

- 개인 액세스 토큰을 사용하여 서비스 계정 토큰 생성:

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>"
  "https://gitlab.com/api/v4/groups/<group_id>/service_accounts/<service_account_id>/personal_access_tokens" --data "scopes[]=api,read_user,read_repository" --data "name=service_accounts_token"
  ```

## Jira Cloud 앱용 GitLab 업데이트 {#update-the-gitlab-for-jira-cloud-app}

대부분의 앱 업데이트는 자동으로 수행됩니다. 자세한 내용은 [Atlassian 문서](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/)를 참조하세요.

앱에 추가 권한이 필요한 경우 [Jira에서 업데이트를 수동으로 승인](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/#changes-that-require-manual-customer-approval)해야 합니다.

## Atlassian Connect에서 Forge로 마이그레이션 {#migration-from-atlassian-connect-to-forge}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/592890)되었습니다.

{{< /history >}}

Jira Cloud 앱용 GitLab이 [Atlassian Connect](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/)에서 [Atlassian Forge](https://developer.atlassian.com/platform/forge/)로 마이그레이션되었습니다. 이 변경은 Atlassian의 [Connect 앱 지원 종료 발표](https://www.atlassian.com/blog/developer/announcing-connect-end-of-support-timeline-and-next-steps)를 따릅니다.

기존의 모든 기능이 계속 작동합니다:

- Jira 개발 패널에 브랜치, 커밋, 머지 리퀘스트, 파이프라인, 배포 및 기능 플래그를 동기화합니다.
- Jira 이슈에서 GitLab 브랜치를 생성합니다.
- 시간 추적 및 이슈 전환을 위해 Smart Commits를 사용합니다.
- GitLab.com 및 GitLab Self-Managed 인스턴스를 모두 지원합니다.

[Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud)에서 Jira Cloud 앱용 GitLab을 설치한 경우:

- Forge 버전은 기존 앱의 [주요 업그레이드](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/#changes-that-require-manual-customer-approval)로 표시됩니다.
- Jira 관리자가 업그레이드를 승인해야 합니다.
- 이전에 동기화된 모든 개발 데이터는 자동으로 보존됩니다. Forge 앱은 동일한 앱 식별자를 사용하므로 데이터를 마이그레이션할 필요가 없습니다.
- GitLab 구성을 변경할 필요가 없습니다.

이전에 Connect 기반 **App descriptor URL** 워크플로우를 사용하여 Jira Cloud 앱용 GitLab을 수동으로 설치한 경우 Forge 기반 방법으로 마이그레이션해야 합니다. Atlassian이 [2026-03-31에 Connect 기반 개인 설치를 비활성화](https://www.atlassian.com/blog/developer/announcing-connect-end-of-support-timeline-and-next-steps)했으므로 이전 워크플로우가 더 이상 작동하지 않습니다.

기존 데이터를 마이그레이션하고 보존하려면:

1. [Connect 앱 설명자를 Forge 매니페스트로 변환](https://developer.atlassian.com/platform/adopting-forge-from-connect/how-to-adopt/#part-2--convert-your-descriptor-to-a-manifest)합니다.
1. 변환된 매니페스트를 사용하여 [새 Forge 앱을 등록](https://developer.atlassian.com/platform/adopting-forge-from-connect/how-to-adopt/#part-3--register-and-deploy-your-app-to-your-forge-development-site)합니다.

이러한 단계를 따르면 새 Forge 앱이 원본 `connect.app.key`을 유지합니다. Jira는 이 키를 새 Forge 앱 ID와 함께 사용하여 두 설치를 연결된 것으로 인식하므로 이전에 동기화된 개발 데이터는 그대로 유지됩니다.

변환 후 [Forge 기반 수동 설치 지침](../../administration/settings/jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)을 따라 Atlassian 개발자 계정 아래에 [Jira Cloud 앱용 GitLab Forge 앱](https://gitlab.com/gitlab-org/gitlab-jira-forge)의 개인 복사본을 게시합니다.

Connect에서 Forge로의 전환에 대한 자세한 내용은 [Forge를 채택하는 방법에 대한 Atlassian 가이드](https://developer.atlassian.com/platform/adopting-forge-from-connect/how-to-adopt/)를 참조하세요.

## 보안 고려사항 {#security-considerations}

Jira Cloud 앱용 GitLab은 GitLab과 Jira를 연결합니다. 데이터를 두 애플리케이션 간에 공유해야 하며, 양 방향으로 액세스 권한을 부여해야 합니다.

### Jira에 대한 GitLab 액세스 {#gitlab-access-to-jira}

[Jira Cloud 앱용 GitLab을 구성](#configure-the-gitlab-for-jira-cloud-app)할 때 GitLab은 Jira에서 **shared secret token**을 받습니다. 토큰은 GitLab에 Jira 프로젝트에 대한 `READ`, `WRITE` 및 `DELETE` [앱 범위](https://developer.atlassian.com/cloud/jira/software/scopes-for-connect-apps/#scopes-for-atlassian-connect-apps)를 부여합니다. 이러한 범위는 Jira 프로젝트의 개발 패널에서 정보를 업데이트하는 데 필요합니다. 토큰은 앱이 설치된 Jira 프로젝트 외에 다른 Atlassian 제품에 대한 GitLab 액세스 권한을 부여하지 않습니다.

토큰은 `AES256-GCM`으로 암호화되고 GitLab에 저장됩니다. Jira Cloud 앱용 GitLab이 Jira 프로젝트에서 제거되면 GitLab이 토큰을 삭제합니다.

### GitLab에 대한 Jira 액세스 {#jira-access-to-gitlab}

Jira는 GitLab에 대한 액세스 권한을 얻지 않습니다.

### GitLab에서 Jira로 전송된 데이터 {#data-sent-from-gitlab-to-jira}

Jira로 전송된 모든 데이터는 [Jira로 동기화되는 GitLab 데이터](#gitlab-data-synced-to-jira)를 참조하세요.

Jira로 전송된 특정 데이터 속성에 대한 자세한 내용은 데이터 동기화에 관여하는 [직렬화 클래스](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/atlassian/jira_connect/serializers)를 참조하세요.

### Jira에서 GitLab로 전송된 데이터 {#data-sent-from-jira-to-gitlab}

GitLab은 Jira Cloud 앱용 GitLab을 설치하거나 제거할 때 Jira에서 [수명 주기 이벤트](https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/#lifecycle)를 받습니다. 이벤트에는 후속 수명 주기 이벤트를 확인하고 [Jira로 데이터를 전송](#data-sent-from-gitlab-to-jira)할 때 인증하기 위한 [토큰](#gitlab-access-to-jira)이 포함됩니다. Jira의 수명 주기 이벤트 요청이 [확인](https://developer.atlassian.com/cloud/jira/platform/security-for-connect-apps/#validating-installation-lifecycle-requests)됩니다.

Atlassian Marketplace에서 Jira Cloud 앱용 GitLab을 사용하는 GitLab Self-Managed 인스턴스의 경우 GitLab.com이 수명 주기 이벤트를 처리하고 GitLab Self-Managed 인스턴스로 전달합니다. 자세한 내용은 [앱 수명 주기 이벤트의 GitLab.com 처리](../../administration/settings/jira_cloud_app.md#gitlabcom-handling-of-app-lifecycle-events)를 참조하세요.

### Jira에서 저장한 데이터 {#data-stored-by-jira}

[Jira로 전송된 데이터](#data-sent-from-gitlab-to-jira)는 Jira에서 저장되고 [Jira 개발 패널](development_panel.md)에 표시됩니다.

Jira Cloud 앱용 GitLab이 제거되면 Jira가 이 데이터를 영구적으로 삭제합니다. 이 프로세스는 비동기적으로 진행되며 최대 몇 시간이 걸릴 수 있습니다.

### Atlassian Marketplace의 개인 정보 보호 및 보안 세부 정보 {#privacy-and-security-details-in-the-atlassian-marketplace}

자세한 내용은 [Atlassian Marketplace 목록의 개인 정보 보호 및 보안 세부 정보](https://marketplace.atlassian.com/apps/1221011/gitlab-for-jira-cloud?tab=privacy-and-security&hosting=cloud)를 참조하세요.

## 문제 해결 {#troubleshooting}

Jira Cloud 앱용 GitLab을 사용할 때 다음과 같은 이슈가 발생할 수 있습니다.

관리자 문제 해결은 [Jira Cloud 앱용 GitLab 관리](../../administration/settings/jira_cloud_app_troubleshooting.md)를 참조하세요.

### 오류: `Failed to link group` {#error-failed-to-link-group}

Jira Cloud 앱용 GitLab을 연결할 때 다음 오류가 발생할 수 있습니다:

```plaintext
Failed to link group. Please try again.
```

`403 Forbidden`이 반환되면 권한이 부족하여 Jira에서 사용자 정보를 가져올 수 없습니다.

이 이슈를 해결하려면 특정 [Jira 사용자 요구 사항](../../administration/settings/jira_cloud_app.md#jira-user-requirements)을 충족하는지 확인하세요.

Jira 사용자가 관리자 권한을 가지고 있지만 `site-admins` 또는 `org-admins` 그룹의 명시적 구성원이 아닌 경우 [오류: Jira 사용자가 사이트 또는 조직 관리자가 아님](../../administration/settings/jira_cloud_app_troubleshooting.md#error-the-jira-user-is-not-a-site-or-organization-administrator).

### GitLab 그룹으로 연결한 후 Jira 코드가 작동하지 않음 {#jira-code-does-not-work-after-linking-to-a-gitlab-group}

[Jira Code](https://support.atlassian.com/jira-software-cloud/docs/enable-code/)는 [Jira Cloud 앱용 GitLab을 GitLab 그룹으로 연결](#configure-the-gitlab-for-jira-cloud-app)한 후 작동하지 않을 수 있습니다. 이 이슈를 해결하려면 Bitbucket과 Jira를 모두 구성해야 합니다.

Bitbucket에서:

1. Atlassian 계정으로 로그인합니다.
1. 워크스페이스 이름을 생성하고 입력합니다.

Jira에서:

1. **프로젝트**에서 프로젝트를 선택합니다.
1. **개발** > **코드**를 선택합니다.
1. **Connect Bitbucket** > **Link Bitbucket Cloud workspace**를 선택합니다.
1. Bitbucket에서 생성한 워크스페이스를 선택합니다.
1. **액세스 권한 부여**를 선택합니다.

이제 리포지토리가 Jira Code에 나타나야 합니다.

자세한 내용은 [JRACLOUD-95847 이슈](https://jira.atlassian.com/browse/JRACLOUD-95847)를 참조하세요.
