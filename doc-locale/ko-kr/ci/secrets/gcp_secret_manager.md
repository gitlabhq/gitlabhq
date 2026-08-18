---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab CI/CD 파이프라인에서 GCP Secret Manager 시크릿을 사용하는 방법을 알아봅니다
title: GitLab CI/CD에서 GCP Secret Manager 시크릿 사용
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 및 GitLab Runner 16.8에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/11739)되었습니다.

{{< /history >}}

GitLab CI/CD 파이프라인에서 [Google Cloud(GCP) Secret Manager](https://cloud.google.com/security/products/secret-manager)에 저장된 시크릿을 사용할 수 있습니다.

GitLab과 GCP Secret Manager를 사용하는 플로우는 다음과 같습니다:

1. GitLab이 CI/CD 작업에 ID 토큰을 발급합니다.
1. 러너가 ID 토큰을 사용하여 GCP에 인증합니다.
1. GCP가 GitLab으로 ID 토큰을 확인합니다.
1. GCP가 단기 액세스 토큰을 발급합니다.
1. 러너가 액세스 토큰을 사용하여 시크릿 데이터에 액세스합니다.
1. GCP가 액세스 토큰의 주체에 대한 IAM 시크릿 권한을 확인합니다.
1. GCP가 시크릿 데이터를 러너로 반환합니다.

GitLab과 GCP Secret Manager를 사용하려면 다음을 수행해야 합니다:

- [GCP Secret Manager](https://cloud.google.com/security/products/secret-manager)에 저장된 시크릿이 있습니다.
- [GCP Workload Identity Federation](#configure-gcp-iam-workload-identity-federation-wif)을 구성하여 GitLab을 ID 공급자로 포함합니다.
- [GCP IAM](#grant-access-to-gcp-iam-principal) 권한을 구성하여 GCP Secret Manager에 대한 액세스 권한을 부여합니다.
- [GitLab CI/CD와 GCP Secret Manager](#configure-gitlab-cicd-to-use-gcp-secret-manager-secrets)를 구성합니다.

## GCP IAM Workload Identity Federation(WIF) 구성 {#configure-gcp-iam-workload-identity-federation-wif}

GCP IAM WIF는 GitLab에서 발급한 ID 토큰을 인식하고 적절한 주체를 할당하도록 구성되어야 합니다. 주체는 Secret Manager 리소스에 대한 액세스를 승인하는 데 사용됩니다:

1. GCP Console에서 **IAM & Admin** > **Workload Identity Federation**으로 이동합니다.
1. **CREATE POOL**을 선택하고 고유한 이름으로 새 ID 풀을 만듭니다(예: `gitlab-pool`).
1. **ADD PROVIDER**를 선택하여 ID 풀에 새 OIDC 공급자를 고유한 이름으로 추가합니다(예: `gitlab-provider`).
   1. **Issuer (URL)**을 GitLab URL로 설정합니다(예: `https://gitlab.com`).
   1. **Default audience**를 선택하거나, 사용자 지정 대상을 위해 **Allowed audiences**를 선택합니다. 이는 GitLab CI/CD ID 토큰의 `aud`에서 사용됩니다.
1. **Attribute Mapping**에서 다음 매핑을 만듭니다. 여기서:

   - `attribute.X`은 Google 토큰의 클레임으로 포함할 특성의 이름입니다.
   - `assertion.X`은 [GitLab 클레임](../cloud_services/_index.md#id-token-authentication-for-cloud-services)에서 추출할 값입니다.

   | 특성(Google)         | 주장(GitLab) |
   |-------------------------------|-------------------------|
   | `google.subject`              | `assertion.sub`         |
   | `attribute.gitlab_project_id` | `assertion.project_id`  |

## GCP IAM 주체에 액세스 권한 부여 {#grant-access-to-gcp-iam-principal}

WIF를 설정한 후 WIF 주체에 Secret Manager의 시크릿에 대한 액세스 권한을 부여해야 합니다.

1. GCP Console에서 **보안** > **Secret Manager**로 이동합니다.
1. 액세스 권한을 부여할 시크릿의 이름을 선택하여 시크릿 세부 정보를 봅니다.
1. **PERMISSIONS** 탭에서 **GRANT ACCESS**를 선택하여 WIF 공급자를 통해 생성된 주체 집합에 액세스 권한을 부여합니다. 외부 ID 형식은 다음과 같습니다:

   ```plaintext
   principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.gitlab_project_id/GITLAB_PROJECT_ID
   ```

   이 예에서:

   - `PROJECT_NUMBER`: Google Cloud 프로젝트 번호(ID 아님)로, [프로젝트 대시보드](https://console.cloud.google.com/home/dashboard)에서 확인할 수 있습니다.
   - `POOL_ID`: 첫 번째 섹션에서 생성한 Workload Identity 풀의 ID(이름 아님)입니다(예: `gitlab-pool`).
   - `GITLAB_PROJECT_ID`: [프로젝트 개요 페이지](../../user/project/working_with_projects.md#find-the-project-id)에서 확인할 수 있는 GitLab 프로젝트 ID입니다.

1. **Secret Manager Secret Accessor** 역할을 할당합니다.

## GCP Secret Manager 시크릿을 사용하도록 GitLab CI/CD 구성 {#configure-gitlab-cicd-to-use-gcp-secret-manager-secrets}

GCP Secret Manager에 대한 세부 정보를 제공하려면 [이러한 CI/CD 변수를 추가](../variables/_index.md#for-a-project)해야 합니다:

- `GCP_PROJECT_NUMBER`: GCP [Project Number](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
- `GCP_WORKLOAD_IDENTITY_FEDERATION_POOL_ID`: WIF Pool ID입니다(예: `gitlab-pool`).
- `GCP_WORKLOAD_IDENTITY_FEDERATION_PROVIDER_ID`: WIF Provider ID입니다(예: `gitlab-provider`).

그러면 `gcp_secret_manager` 키워드로 정의하여 CI/CD 작업에서 GCP Secret Manager에 저장된 시크릿을 사용할 수 있습니다:

```yaml
job_using_gcp_sm:
  id_tokens:
    GCP_ID_TOKEN:
      # `aud` must match the audience defined in the WIF Identity Pool.
      aud: https://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${GCP_WORKLOAD_IDENTITY_FEDERATION_POOL_ID}/providers/${GCP_WORKLOAD_IDENTITY_FEDERATION_PROVIDER_ID}
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: my-project-secret  # This is the name of the secret defined in GCP Secret Manager
        version: 1               # optional: default to `latest`.
      token: $GCP_ID_TOKEN
```

### 다른 GCP 프로젝트에서 시크릿 사용 {#use-secrets-from-a-different-gcp-project}

{{< history >}}

- GitLab 17.0에서 [도입](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37487)되었습니다.

{{< /history >}}

GCP의 시크릿 이름은 프로젝트별입니다. 기본적으로 `gcp_secret_manager:name`에 이름이 지정된 시크릿은 `GCP_PROJECT_NUMBER`에 지정된 프로젝트에서 읽습니다.

WIF 풀을 포함하는 프로젝트와 다른 프로젝트에서 시크릿을 읽으려면 `projects/<project-number>/secrets/<secret-name>`로 형식이 지정된 정규화된 시크릿 이름을 사용합니다.

예를 들어, `my-project-secret`이 GCP 프로젝트 번호 `123456789`에 있으면 다음과 같이 시크릿에 액세스할 수 있습니다:

```yaml
job_using_gcp_sm:
  # ... as previously configured ...
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: projects/123456789/secrets/my-project-secret  # fully-qualified name of the secret defined in GCP Secret Manager
        version: 1                                          # optional: defaults to `latest`.
      token: $GCP_ID_TOKEN
```

## 문제 해결 {#troubleshooting}

### 오류: `google.subject`의 매핑된 특성 크기가 127바이트 제한을 초과합니다 {#error-the-size-of-mapped-attribute-googlesubject-exceeds-the-127-bytes-limit}

긴 브랜치 경로는 [`assertion.sub` 특성](id_token_authentication.md#token-payload)이 127자보다 길어지기 때문에 작업이 이 오류로 실패하도록 할 수 있습니다:

```plaintext
ERROR: Job failed (system failure): resolving secrets: failed to exchange sts token: googleapi: got HTTP response code 400 with body:
{"error":"invalid_request","error_description":"The size of mapped attribute google.subject exceeds the 127 bytes limit.
Either modify your attribute mapping or the incoming assertion to produce a mapped attribute that is less than 127 bytes."}
```

긴 브랜치 경로는 다음과 같은 원인으로 발생할 수 있습니다:

- 깊게 중첩된 서브그룹입니다.
- 긴 그룹, 리포지토리, 또는 브랜치 이름입니다.

예를 들어, `gitlab-org/gitlab` 브랜치의 경우, 페이로드는 `project_path:gitlab-org/gitlab:ref_type:branch:ref:{branch_name}`입니다. 문자열을 127자 미만으로 유지하려면 브랜치 이름이 76자 이하여야 합니다. 이 제한은 Google Cloud IAM에 의해 부과되며 [Google issue #264362370](https://issuetracker.google.com/issues/264362370?pli=1)에서 추적됩니다.

이 이슈의 유일한 해결 방법은 [브랜치와 리포지토리에 대해 더 짧은 이름을 사용](https://github.com/google-github-actions/auth/blob/main/docs/TROUBLESHOOTING.md#subject-exceeds-the-127-byte-limit)하는 것입니다.

### `The secrets provider can not be found. Check your CI/CD variables and try again.` 메시지 {#the-secrets-provider-can-not-be-found-check-your-cicd-variables-and-try-again-message}

GCP Secret Manager에 액세스하도록 구성된 작업을 시작할 때 이 오류가 나타날 수 있습니다:

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

필수 변수 중 하나 이상이 정의되지 않았기 때문에 작업을 만들 수 없습니다:

- `GCP_PROJECT_NUMBER`
- `GCP_WORKLOAD_IDENTITY_FEDERATION_POOL_ID`
- `GCP_WORKLOAD_IDENTITY_FEDERATION_PROVIDER_ID`

### `WARNING: Not resolved: no resolver that can handle the secret` 경고 {#warning-not-resolved-no-resolver-that-can-handle-the-secret-warning}

Google Cloud Secret Manager 통합을 사용하려면 최소한 GitLab 16.8 및 GitLab Runner 16.8이 필요합니다. 이 경고는 16.8 이전 버전의 러너에 의해 작업이 실행될 때 나타납니다.
