---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Google Cloud 워크로드 ID 페더레이션 및 IAM 정책
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

{{< history >}}

- [GitLab 16.10에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141127)되었으며 [기능 플래그](../administration/feature_flags/_index.md) 이름은 `google_cloud_support_feature_flag`입니다.
- GitLab 17.1에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)되었습니다. `google_cloud_support_feature_flag` 기능 플래그가 제거되었습니다.

{{< /history >}}

[Google Artifact Management 통합](../user/project/integrations/google_artifact_management.md)과 같은 Google Cloud 통합을 사용하려면 [워크로드 ID 풀과 공급자](https://cloud.google.com/iam/docs/workload-identity-federation)를 생성하고 구성해야 합니다. Google Cloud 통합은 워크로드 ID 페더레이션을 사용하여 OpenID Connect(OIDC)를 통해 JSON Web Token(JWT) 토큰을 사용함으로써 GitLab 워크로드에 Google Cloud 리소스에 대한 액세스 권한을 부여합니다.

## 워크로드 ID 페더레이션 {#workload-identity-federation}

워크로드 ID 페더레이션을 사용하면 ID 및 액세스 관리(IAM)를 사용하여 외부 ID에 [IAM 역할](https://cloud.google.com/iam/docs/overview#roles)을 부여할 수 있습니다.

기본적으로 Google Cloud 외부에서 실행되는 애플리케이션은 Google Cloud 리소스에 액세스하기 위해 [서비스 계정 키](https://cloud.google.com/iam/docs/service-account-creds#key-types)를 사용했습니다. 그러나 서비스 계정 키는 강력한 자격 증명이며 올바르게 관리하지 않으면 보안 위험을 초래할 수 있습니다.

ID 페더레이션을 사용하면 ID 및 액세스 관리(IAM)를 사용하여 서비스 계정을 요청하지 않고 외부 ID에 IAM 역할을 직접 부여할 수 있습니다. 이 방식은 서비스 계정 및 해당 키와 관련된 유지 관리 및 보안 부담을 제거합니다.

## 워크로드 ID 풀 {#workload-identity-pools}

_워크로드 ID 풀_은 Google Cloud에서 Google이 아닌 ID를 관리할 수 있게 해주는 엔티티입니다.

Google Cloud의 GitLab 통합은 Google Cloud에 인증하기 위한 워크로드 ID 풀을 설정하는 과정을 안내합니다. 이 설정에는 GitLab 역할 특성을 Google Cloud IAM 정책의 IAM 클레임에 매핑하는 작업이 포함됩니다. Google Cloud의 GitLab 통합에 사용 가능한 GitLab 특성의 전체 목록은 [OIDC 사용자 지정 클레임](#oidc-custom-claims)을 참조하세요.

## 워크로드 ID 풀 공급자 {#workload-identity-pool-providers}

_워크로드 ID 풀 공급자_는 Google Cloud와 ID 공급자(IdP) 간의 관계를 설명하는 엔티티입니다. GitLab은 Google Cloud의 GitLab 통합을 위한 워크로드 ID 풀의 IdP입니다.

외부 워크로드에 대한 ID 페더레이션에 대한 자세한 내용은 [워크로드 ID 페더레이션](https://cloud.google.com/iam/docs/workload-identity-federation)을 참조하세요.

기본 Google Cloud의 GitLab 통합은 GitLab 조직 수준에서 GitLab에서 Google Cloud로의 인증을 설정하려고 한다고 가정합니다. 프로젝트별로 Google Cloud에 대한 액세스를 제어하려면 워크로드 ID 풀 공급자에 대한 IAM 정책을 구성해야 합니다. GitLab 조직에서 Google Cloud에 액세스할 수 있는 사용자를 제어하는 방법에 대한 자세한 내용은 [IAM을 사용한 액세스 제어](https://cloud.google.com/docs/gitlab)를 참조하세요.

## 워크로드 ID 페더레이션을 사용한 GitLab 인증 {#gitlab-authentication-with-workload-identity-federation}

워크로드 ID 풀 및 공급자가 GitLab 역할 및 권한을 IAM 역할에 매핑하도록 설정된 후 [`identity`](../ci/yaml/_index.md#identity) 키워드를 `google_cloud`로 설정하여 Google Cloud에서 인증을 위해 GitLab에서 Google Cloud로 워크로드를 배포할 러너를 프로비저닝할 수 있습니다.

Google Cloud의 GitLab 통합을 사용한 러너 프로비저닝에 대한 자세한 내용은 [Google Cloud에서 러너 프로비저닝](../ci/runners/provision_runners_google_cloud.md) 튜토리얼을 참조하세요.

## 워크로드 ID 페더레이션 생성 및 구성 {#create-and-configure-a-workload-identity-federation}

워크로드 ID 페더레이션을 설정하려면 다음 중 하나를 수행할 수 있습니다:

- 안내식 설정을 위해 GitLab UI를 사용합니다.
- Google Cloud CLI를 사용하여 워크로드 ID 페더레이션을 수동으로 설정합니다.

### GitLab UI 사용 {#with-the-gitlab-ui}

GitLab UI를 사용하여 워크로드 ID 페더레이션을 설정하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. Google Cloud IAM 통합을 찾고 **구성**을 선택합니다.
1. **Guided setup**을 선택하고 지시사항을 따릅니다.

### Google Cloud CLI 사용 {#with-the-google-cloud-cli}

전제 조건:

- Google Cloud CLI는 Google Cloud에서 [설치 및 인증](https://cloud.google.com/sdk/docs/install)되어야 합니다.
- Google Cloud에서 워크로드 ID 페더레이션을 관리할 [권한](https://cloud.google.com/iam/docs/manage-workload-identity-pools-providers#required-roles)이 있어야 합니다.

1. 다음 명령으로 워크로드 ID 풀을 생성합니다. 이 값을 바꿉니다:

   - `<your_google_cloud_project_id>`을(를) [Google Cloud 프로젝트 ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)로 바꿉니다. 보안을 개선하려면 리소스 및 CI/CD 프로젝트와 별도로 ID 관리를 위한 전용 프로젝트를 사용합니다.
   - `<your_identity_pool_id>`을(를) 풀에 사용할 ID로 바꾸십시오. ID는 4~32자의 소문자, 숫자 또는 하이픈이어야 합니다. 충돌을 피하려면 고유한 ID를 사용합니다. GitLab 프로젝트 ID 또는 프로젝트 경로를 포함해야 합니다. 이렇게 하면 IAM 정책 관리가 용이합니다. 예를 들어, `gitlab-my-project-name`입니다.

   ```shell
   gcloud iam workload-identity-pools create <your_identity_pool_id> \
            --project="<your_google_cloud_project_id>" \
            --location="global" \
            --display-name="Workload identity pool for GitLab project ID"
   ```

1. 다음 명령으로 워크로드 ID 풀에 OIDC 공급자를 추가합니다. 이 값을 바꿉니다:

   - `<your_identity_provider_id>`을(를) 공급자에 사용할 ID로 바꿉니다. ID는 4~32자의 소문자, 숫자 또는 하이픈이어야 합니다. 충돌을 피하려면 ID 풀에서 고유한 ID를 사용합니다. 예를 들어, `gitlab`입니다.
   - `<your_google_cloud_project_id>`을(를) [Google Cloud 프로젝트 ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)로 바꿉니다.
   - `<your_identity_pool_id>`을(를) 이전 단계에서 생성한 워크로드 ID 풀의 ID로 바꿉니다.
   - `<your_issuer_uri>`을(를) ID 공급자 발급자 URI로 바꾸십시오. 이 URI는 수동 설정을 선택할 때 IAM 통합 페이지에서 복사할 수 있으며 값과 정확히 일치해야 합니다. 매개 변수에는 최상위 그룹의 경로를 포함해야 합니다. 예를 들어 프로젝트가 `my-root-group/my-subgroup/project-a` 아래에 있으면 `issuer-uri`을(를) `https://auth.gcp.gitlab.com/oidc/my-root-group`로 설정해야 합니다.

   ```shell
   gcloud iam workload-identity-pools providers create-oidc "<your_identity_provider_id>" \
         --location="global" \
         --project="<your_google_cloud_project_id>" \
         --workload-identity-pool="<your_identity_pool_id>" \
         --issuer-uri="<your_issuer_uri>" \
         --display-name="GitLab OIDC provider" \
         --attribute-mapping="attribute.guest_access=assertion.guest_access,\
   attribute.reporter_access=assertion.reporter_access,\
   attribute.developer_access=assertion.developer_access,\
   attribute.maintainer_access=assertion.maintainer_access,\
   attribute.owner_access=assertion.owner_access,\
   attribute.namespace_id=assertion.namespace_id,\
   attribute.namespace_path=assertion.namespace_path,\
   attribute.project_id=assertion.project_id,\
   attribute.project_path=assertion.project_path,\
   attribute.user_id=assertion.user_id,\
   attribute.user_login=assertion.user_login,\
   attribute.user_email=assertion.user_email,\
   attribute.user_access_level=assertion.user_access_level,\
   google.subject=assertion.sub"
   ```

   `attribute-mapping` 매개 변수에는 JWT ID 토큰에 포함된 OIDC 사용자 지정 클레임과 ID 및 액세스 관리(IAM) 정책의 액세스 권한을 부여하는 데 사용되는 해당 ID 특성 간의 매핑이 포함되어야 합니다. 자세한 내용은 [지원되는 OIDC 사용자 지정 클레임](google_cloud_iam.md#oidc-custom-claims)을 참조하고 Google Cloud에 대한 [액세스 제어](https://cloud.google.com/docs/gitlab#control-access-google)를 사용하세요.

특정 GitLab 프로젝트 또는 그룹에 대한 [ID 토큰 액세스](https://cloud.google.com/iam/docs/workload-identity-federation#mapping)를 제한하려면 속성 조건을 사용합니다. 프로젝트의 경우 속성 `assertion.project_id`을(를) 사용하고 그룹의 경우 속성 `assertion.namespace_id`을(를) 사용합니다. 자세한 내용은 속성 조건을 [정의](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#gitlab-saas_2)하는 방법에 대한 Google Cloud 설명서를 참조하세요. 속성 조건을 정의한 후 [워크로드 ID 공급자를 업데이트](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#update_attribute_condition_on_a_workload_identity_provider)할 수 있습니다.

워크로드 ID 풀과 공급자를 생성한 후 GitLab에서 설정을 완료하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **연동**을 선택합니다.
1. Google Cloud IAM 통합을 찾고 **구성**을 선택합니다.
1. **Manual setup**을 선택합니다.
1. 필드를 완성하세요.
   - **[프로젝트 ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)** \- 워크로드 ID 풀과 공급자를 생성한 Google Cloud 프로젝트입니다. 예: `my-sample-project-191923`.
   - **[프로젝트 번호](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)** \- 동일한 Google Cloud 프로젝트입니다. 예: `314053285323`.
   - **풀 ID** \- 이 통합을 위해 생성한 워크로드 ID 풀의 ID입니다.
   - **공급자 ID** \- 이 통합을 위해 생성한 워크로드 ID 공급자의 ID입니다.

### OIDC 사용자 지정 클레임 {#oidc-custom-claims}

ID 토큰에는 다음과 같은 사용자 지정 클레임이 포함됩니다:

| 클레임 이름              | 시기                      | 설명                                                                                              |
| ----------------------- | ------------------------- | -------------------------------------------------------------------------------------------------------- |
| `namespace_id`          | 프로젝트 이벤트 중         | 그룹 또는 사용자 수준 네임스페이스의 ID입니다.                                                                 |
| `namespace_path`        | 프로젝트 이벤트 중         | 그룹 또는 사용자 수준 네임스페이스의 경로입니다.                                                               |
| `project_id`            | 프로젝트 이벤트 중         | 프로젝트의 ID입니다.                                                                                       |
| `project_path`          | 프로젝트 이벤트 중         | 프로젝트의 경로입니다.                                                                                     |
| `root_namespace_id`     | 그룹 이벤트 중           | 최상위 그룹 또는 사용자 수준 네임스페이스의 ID입니다.                                                            |
| `root_namespace_path`   | 그룹 이벤트 중           | 최상위 그룹 또는 사용자 수준 네임스페이스의 경로입니다.                                                          |
| `user_id`               | 사용자 트리거 이벤트 중    | 사용자의 ID입니다.                                                                                          |
| `user_login`            | 사용자 트리거 이벤트 중    | 사용자의 사용자 이름입니다.                                                                                    |
| `user_email`            | 사용자 트리거 이벤트 중    | 사용자의 이메일입니다.                                                                                       |
| `ci_config_ref_uri`     | CI/CD 파이프라인 실행 중 | 최상위 CI 파이프라인 정의에 대한 ref 경로입니다.                                                    |
| `ci_config_sha`         | CI/CD 파이프라인 실행 중 | `ci_config_ref_uri`의 Git 커밋 SHA입니다.                                                              |
| `job_id`                | CI/CD 파이프라인 실행 중 | CI 작업의 ID입니다.                                                                                        |
| `pipeline_id`           | CI/CD 파이프라인 실행 중 | CI 파이프라인의 ID입니다.                                                                                   |
| `pipeline_source`       | CI/CD 파이프라인 실행 중 | CI 파이프라인 소스입니다.                                                                                      |
| `project_visibility`    | CI/CD 파이프라인 실행 중 | 파이프라인이 실행 중인 프로젝트의 가시성입니다.                                             |
| `ref`                   | CI/CD 파이프라인 실행 중 | CI 작업의 Git ref입니다.                                                                                  |
| `ref_path`              | CI/CD 파이프라인 실행 중 | CI 작업의 정규화된 ref입니다.                                                                      |
| `ref_protected`         | CI/CD 파이프라인 실행 중 | Git ref가 보호되는지 여부입니다.                                                                             |
| `ref_type`              | CI/CD 파이프라인 실행 중 | Git ref 타입입니다.                                                                                            |
| `runner_environment`    | CI/CD 파이프라인 실행 중 | CI 작업에서 사용하는 러너의 유형입니다.                                                                   |
| `runner_id`             | CI/CD 파이프라인 실행 중 | CI 작업을 실행하는 러너의 ID입니다.                                                                   |
| `sha`                   | CI/CD 파이프라인 실행 중 | CI 작업의 커밋 SHA입니다.                                                                           |
| `environment`           | CI/CD 파이프라인 실행 중 | CI 작업이 배포되는 환경입니다.                                                                       |
| `environment_protected` | CI/CD 파이프라인 실행 중 | 배포된 환경이 보호되는지 여부입니다.                                                                    |
| `environment_action`    | CI/CD 파이프라인 실행 중 | CI 작업에 지정된 환경 작업입니다.                                                              |
| `deployment_tier`       | CI/CD 파이프라인 실행 중 | CI 작업이 지정하는 환경의 배포 티어입니다.                                                 |
| `user_access_level`     | 사용자 트리거 이벤트 중    | `guest`, `reporter`, `developer`, `maintainer`, `owner` 값을 가진 사용자의 역할입니다.                 |
| `guest_access`          | 사용자 트리거 이벤트 중    | 사용자가 최소한 `guest` 게스트 역할을 가지고 있는지 여부를 나타내며, "true" 또는 "false" 문자열 값을 가집니다.      |
| `reporter_access`       | 사용자 트리거 이벤트 중    | 사용자가 최소한 `reporter` 게스트 역할을 가지고 있는지 여부를 나타내며, "true" 또는 "false" 문자열 값을 가집니다.   |
| `developer_access`      | 사용자 트리거 이벤트 중    | 사용자가 최소한 `developer` 게스트 역할을 가지고 있는지 여부를 나타내며, "true" 또는 "false" 문자열 값을 가집니다.  |
| `maintainer_access`     | 사용자 트리거 이벤트 중    | 사용자가 최소한 `maintainer` 게스트 역할을 가지고 있는지 여부를 나타내며, "true" 또는 "false" 문자열 값을 가집니다. |
| `owner_access`          | 사용자 트리거 이벤트 중    | 사용자가 최소한 `owner` 게스트 역할을 가지고 있는지 여부를 나타내며, "true" 또는 "false" 문자열 값을 가집니다.      |

이 클레임은 [ID 토큰 클레임](../ci/secrets/id_token_authentication.md#token-payload)의 상위 집합입니다. 모든 값은 문자열 형식입니다. ID 토큰 클레임 설명서에서 자세한 내용과 예시 값을 확인하세요.

## Google Cloud에 대한 액세스 제어 {#control-access-to-google-cloud}

[워크로드 ID 페더레이션을 설정](#create-and-configure-a-workload-identity-federation)할 때 많은 표준 GitLab 클레임(예: `user_access_level`)이 자동으로 Google Cloud 특성에 매핑됩니다.

GitLab 조직에서 Google Cloud에 액세스할 수 있는 사용자를 더 사용자 지정할 수 있습니다. 이를 위해 [CEL(Common Expression Language)](https://github.com/google/cel-spec/blob/master/doc/intro.md#introduction)을 사용하여 Google Cloud의 GitLab 통합을 위한 [OIDC 사용자 지정 속성](#oidc-custom-claims)을 기반으로 주체를 설정합니다.

예를 들어 GitLab에서 `maintainer` 역할을 가진 사용자가 GitLab 프로젝트 `gitlab-org/my-project`에서 Google Artifact Registry로 아티팩트를 푸시할 수 있도록 허용하려면:

1. Google Cloud 콘솔에 로그인하고 [**Workload Identity Federation** 페이지](https://console.cloud.google.com/iam-admin/workload-identity-pools?supportedpurview=project)로 이동합니다.
1. **이름 표시** 열에서 워크로드 ID 풀을 선택합니다.
1. **Providers** 섹션에서 편집하려는 워크로드 ID 공급자 옆의 **편집**({{< icon name="pencil" >}})을 선택하여 **공급자 세부 정보**를 엽니다.
1. **Attribute mapping** 섹션에서 **Add mapping**를 선택합니다.
1. **Google N** 텍스트 상자에 다음을 입력합니다:

   ```shell
   attribute.my_project_maintainer
   ```

1. **OIDC N** 텍스트 상자에 다음 CEL 표현식을 입력합니다:

   ```shell
   assertion.maintainer_access=="true" && assertion.project_path=="gitlab-org/my-project"
   ```

1. **저장**을 선택합니다.

   Google 특성 `my_project_maintainer`은 GitLab 클레임 `maintainer_access==true` 및 `project_path=="gitlab-org/my-project"`에 매핑됩니다.
1. Google Cloud 콘솔에서 [**IAM** 페이지](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project)로 이동합니다.
1. **액세스 권한 부여**를 선택합니다.
1. **New principals** 텍스트 상자에 `attribute.my_project_maintainer/true`를 포함하는 주체 집합을 다음 형식으로 입력합니다:

   ```shell
   principalSet://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_ID>/attribute.my_project_maintainer/true
   ```

   다음을 바꿉니다:

   - `<PROJECT_NUMBER>`을(를) Google Cloud 프로젝트 번호로 바꿉니다. 프로젝트 번호를 찾으려면 [프로젝트 식별](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)을 참조하세요.
   - `<POOL_ID>`을(를) 워크로드 ID 풀 ID로 바꿉니다.

1. **역할 선택** 드롭다운 목록에서 **Google Artifact Registry Writer role**(`roles/artifactregistry.writer`)을 선택합니다.
1. **저장**을 선택합니다.

이 역할은 GitLab의 `maintainer` 역할을 가진 프로젝트 `gitlab-org/my-project`의 주체 집합에 부여됩니다.

다른 GitLab 프로젝트에서 Google Artifact Registry로 아티팩트를 푸시하지 못하도록 방지하려면 Google Cloud 콘솔에서 IAM 정책을 확인하고 필요에 따라 역할을 제거하거나 편집할 수 있습니다.

## IAM 정책 보기 {#view-your-iam-policies}

Google Cloud 콘솔에 로그인하고 [**IAM** 페이지](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project)로 이동합니다.

**View by principals** 또는 **View by roles**를 선택할 수 있습니다.
