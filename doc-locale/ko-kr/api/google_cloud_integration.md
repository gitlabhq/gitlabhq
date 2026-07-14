---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Google Cloud 통합 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태:  실험적 기능

{{< /details >}}

이 API를 사용하여 Google Cloud 통합과 상호작용합니다. 자세한 정보는 [GitLab and Google Cloud integration](../ci/gitlab_google_cloud_integration/_index.md)을 참고하세요.

## 프로젝트 수준의 Google Cloud 통합 스크립트 {#project-level-google-cloud-integration-scripts}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141870) in GitLab 16.10. 이 기능은 [실험](../policy/development_stages_support.md)입니다.

{{< /history >}}

### 워크로드 ID 페더레이션 생성 스크립트 {#workload-identity-federation-creation-script}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141870) in GitLab 16.10.

{{< /history >}}

프로젝트의 Maintainer 또는 Owner 역할을 가진 사용자는 다음 엔드포인트를 사용하여 Google Cloud에서 워크로드 ID 페더레이션을 생성하고 구성하는 셸 스크립트를 쿼리할 수 있습니다:

```plaintext
GET /projects/:id/google_cloud/setup/wlif.sh
```

지원되는 속성:

| 속성                                         | 유형             | 필수 | 설명                                                                                                      |
|---------------------------------------------------|------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                                              | 정수          | 예      | 프로젝트의 ID입니다.                                                                                                |
| `google_cloud_project_id`                         | 문자열           | 예      | 워크로드 ID 페더레이션의 Google Cloud Project ID입니다.                                                    |
| `google_cloud_workload_identity_pool_id`          | 문자열           | 아니요       | 생성할 Google Cloud 워크로드 ID 풀의 ID입니다. `gitlab-wlif`으로 기본값이 설정됩니다.                              |
| `google_cloud_workload_identity_pool_display_name`| 문자열           | 아니요       | 생성할 Google Cloud 워크로드 ID 풀의 표시 이름입니다. `WLIF for GitLab integration`으로 기본값이 설정됩니다.   |
| `google_cloud_workload_identity_pool_provider_id` | 문자열           | 아니요       | 생성할 Google Cloud 워크로드 ID 풀 공급자의 ID입니다. `gitlab-wlif-oidc-provider`으로 기본값이 설정됩니다.       |
| `google_cloud_workload_identity_pool_provider_display_name`| 문자열  | 아니요       | 생성할 Google Cloud 워크로드 ID 풀 공급자의 표시 이름입니다. `GitLab OIDC provider`으로 기본값이 설정됩니다. |

요청 예시:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/wlif.sh"
```

### Google Cloud 통합을 설정하는 스크립트 {#script-to-set-up-a-google-cloud-integration}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144787) in GitLab 16.10.

{{< /history >}}

프로젝트의 Maintainer 또는 Owner 역할을 가진 사용자는 다음 엔드포인트를 사용하여 Google Cloud 통합을 설정하는 셸 스크립트를 쿼리할 수 있습니다:

```plaintext
GET /projects/:id/google_cloud/setup/integrations.sh
```

[Google Artifact Management integration](../user/project/integrations/google_artifact_management.md)만 지원됩니다. 이 스크립트는 Google Artifact Registry에 액세스하기 위한 IAM 정책을 생성합니다:

- [Artifact Registry Reader](https://cloud.google.com/artifact-registry/docs/access-control#roles) 역할은 최소한 Reporter 역할을 가진 멤버에게 부여됩니다.
- [Artifact Registry Writer](https://cloud.google.com/artifact-registry/docs/access-control#roles) 역할은 최소한 Developer 역할을 가진 멤버에게 부여됩니다.

지원되는 속성:

| 속성                                   | 유형    | 필수 | 설명                                                                 |
|---------------------------------------------|---------|----------|-----------------------------------------------------------------------------|
| `id`                                        | 정수 | 예      | GitLab 프로젝트의 ID입니다.                                                           |
| `enable_google_cloud_artifact_registry`     | 부울 | 예      | Google Artifact Management 통합을 활성화해야 하는지를 나타내는 플래그입니다. |
| `google_cloud_artifact_registry_project_id` | 문자열  | 예      | Artifact Registry의 Google Cloud Project ID입니다.                          |

요청 예시:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/integrations.sh"
```

### 러너 프로비저닝을 위해 Google Cloud 프로젝트를 구성하는 스크립트 {#script-to-configure-a-google-cloud-project-for-runner-provisioning}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145525) in GitLab 16.10.

{{< /history >}}

프로젝트의 Maintainer 또는 Owner 역할을 가진 사용자는 다음 엔드포인트를 사용하여 러너 프로비저닝 및 실행을 위해 Google Cloud 프로젝트를 구성하는 셸 스크립트를 쿼리할 수 있습니다:

```plaintext
GET /projects/:id/google_cloud/setup/runner_deployment_project.sh
```

이 스크립트는 지정된 Google Cloud 프로젝트에서 준비 구성 단계를 수행하며, 필수 서비스를 활성화하고 `GRITProvisioner` 역할 및 `grit-provisioner` 서비스 계정을 생성합니다.

지원되는 속성:

| 속성                 | 유형    | 필수 | 설명                            |
|---------------------------|---------|----------|----------------------------------------|
| `id`                      | 정수 | 예      | GitLab 프로젝트의 ID입니다.            |
| `google_cloud_project_id` | 문자열  | 예      | Google Cloud 프로젝트의 ID입니다.    |

요청 예시:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/runner_deployment_project.sh?google_cloud_project_id=<your_google_cloud_project_id>"
```
