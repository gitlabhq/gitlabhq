---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Snowflake
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.1에서 감사 이벤트에 대해 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/451328).

{{< /history >}}

Snowflake [GitLab Data Connector](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector)는 데이터를 [Snowflake](https://www.snowflake.com/en/)로 가져옵니다.

Snowflake에서 모든 데이터를 보고, 결합하고, 조작하고, 보고할 수 있습니다. GitLab Data Connector는 [GitLab REST API](../api/rest/_index.md)를 기반으로 하며 Snowflake와 GitLab 구성이 모두 필요합니다.

## 전제 조건 {#prerequisites}

1. GitLab 개인 액세스 토큰이 없는 경우:
   1. GitLab에 로그인하세요.
   1. [개인 액세스 토큰 생성](../user/profile/personal_access_tokens.md#create-a-personal-access-token)하기 위해 나열된 단계를 따르세요.
1. Snowflake에서 [외부 액세스 통합](https://docs.snowflake.com/en/developer-guide/external-network-access/creating-using-external-network-access)을 생성합니다. 자세한 내용은 `snowflake-connector` 프로젝트의 [설정 설명서](https://gitlab.com/gitlab-org/software-supply-chain-security/compliance/engineering/snowflake-connector#setup)를 참조하세요.
1. Snowflake에서 [웨어하우스](https://docs.snowflake.com/en/user-guide/warehouses-tasks#creating-a-warehouse)를 생성합니다.

## GitLab Data Connector 구성 {#configure-the-gitlab-data-connector}

1. Snowflake에 로그인하세요.
1. **Data Products** > **Marketplace**를 선택합니다.
1. **GitLab Data Connector**를 검색합니다.
1. **Data Products** > **Apps**를 선택합니다.
1. **GitLab Data Connector**를 선택합니다.
1. GitLab Data Connector가 실행될 [웨어하우스](https://docs.snowflake.com/en/user-guide/warehouses)를 선택합니다.
1. **Start Configuration**을 선택합니다.
1. **Grant privileges**를 선택합니다.
1. 대상 웨어하우스 및 스키마를 입력합니다. 원하는 웨어하우스 및 스키마일 수 있습니다.
1. **구성**을 선택합니다.
1. 외부 액세스 통합을 입력합니다.
1. GitLab 개인 액세스 토큰 비밀이 저장된 경로를 입력합니다.
1. GitLab 인스턴스의 도메인을 입력합니다. 예를 들어, `gitlab.com`입니다.
1. **연결**을 선택합니다.
1. 그룹 이름을 입력합니다. 예를 들어, `my-group`입니다.
1. **Finalize configurator**를 선택합니다.
1. **구성**을 선택합니다.

## 프로젝트 및 그룹 사용 {#enable-projects-and-groups}

GitLab Data Connector를 구성한 후 감사 이벤트가 Snowflake로 수집될 프로젝트 또는 그룹을 지정해야 합니다. 최소 1개의 프로젝트 또는 그룹을 추가하지 않으면 데이터가 수집되지 않습니다.

### 프로젝트 사용 {#enable-projects}

감사 이벤트를 수집하려는 프로젝트를 추가하려면:

1. Snowflake에 로그인하세요.
1. **Data Products** > **Apps**를 선택합니다.
1. **GitLab Data Connector**를 선택합니다.
1. **Enabled Projects** 탭을 선택합니다.
1. 사용할 프로젝트의 경로를 입력합니다. 예를 들어, `my-group/my-project`입니다.
1. **추가**를 선택합니다.
1. 추가 프로젝트마다 반복합니다.

### 그룹 사용 {#enable-groups}

감사 이벤트를 수집하려는 그룹을 추가하려면:

1. Snowflake에 로그인하세요.
1. **Data Products** > **Apps**를 선택합니다.
1. **GitLab Data Connector**를 선택합니다.
1. **Enabled Groups** 탭을 선택합니다.
1. 사용할 그룹의 경로를 입력합니다. 예를 들어, `my-group`입니다.
1. **추가**를 선택합니다.
1. 추가 그룹마다 반복합니다.

## Snowflake에서 데이터 보기 {#view-data-in-snowflake}

1. Snowflake에 로그인하세요.
1. **Data** > **데이터베이스**를 선택합니다.
1. 이전에 구성된 웨어하우스를 선택합니다.

## 문제 해결 {#troubleshooting}

### Snowflake에 데이터가 표시되지 않음 {#no-data-appearing-in-snowflake}

Snowflake에 데이터가 표시되지 않으면 다음을 확인하세요:

- **Enabled Projects** 또는 **Enabled Groups** 탭에 최소 1개의 프로젝트 또는 그룹을 추가하지 않았습니다. 자세한 내용은 [프로젝트 및 그룹 사용](#enable-projects-and-groups)을 참조하세요.
- GitLab 개인 액세스 토큰에 감사 이벤트를 읽기 위한 필수 범위가 없습니다.
- GitLab Data Connector용으로 구성된 Snowflake 웨어하우스가 일시 중지되었습니다.
