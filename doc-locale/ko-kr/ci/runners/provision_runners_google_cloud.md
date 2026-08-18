---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Google Cloud Compute Engine에서 러너 프로비저닝
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.10에서 `google_cloud_support_feature_flag` [플래그](../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/438316)되었습니다. 이 기능은 [베타](../../policy/development_stages_support.md) 단계입니다.
- [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)(GitLab 17.1) 기능 플래그 `google_cloud_support_feature_flag`이 제거되었습니다.

{{< /history >}}

GitLab.com용 프로젝트 러너 또는 그룹 러너를 만들고 Google Cloud 프로젝트에서 프로비저닝할 수 있습니다. 러너를 만들면 GitLab UI에서 온스크린 지침과 스크립트를 제공하여 Google Cloud 프로젝트에서 러너를 자동으로 프로비저닝합니다.

러너 인증 토큰은 러너를 만들 때 할당됩니다. [GRIT](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit) Terraform 스크립트는 이 토큰을 사용하여 러너를 등록합니다. 러너는 작업 큐에서 작업을 가져올 때 토큰을 사용하여 GitLab으로 인증합니다.

프로비저닝 후 자동 크기 조정 러너 플릿이 Google Cloud에서 CI/CD 작업을 실행할 준비가 됩니다. 러너 매니저는 임시 러너를 자동으로 만듭니다.

전제 조건:

- 그룹 러너: 그룹의 소유자 역할
- 프로젝트 러너: 프로젝트의 유지 관리자 역할
- Google Cloud Platform 프로젝트의 경우: [Owner](https://cloud.google.com/iam/docs/understanding-roles#owner) IAM 역할
- Google Cloud Platform 프로젝트에 [Billing enabled](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project)
- 작동하는 [`gcloud` CLI 도구](https://cloud.google.com/sdk/docs/install)는 Google Cloud 프로젝트의 IAM 역할로 인증됩니다.
- [Terraform v1.5 이상](https://releases.hashicorp.com/terraform/1.5.7/) 및 [Terraform CLI 도구](https://developer.hashicorp.com/terraform/install)
- Bash가 설치된 터미널

그룹 러너 또는 프로젝트 러너를 만들고 Google Cloud에서 프로비저닝하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 새 러너를 만듭니다.
   - 새 그룹 러너를 만들려면 **빌드** > **러너** > **New group runner**를 선택합니다.
   - 새 프로젝트 러너를 만들려면 **설정** > **CI/CD** > **러너** > **New project runner**를 선택합니다.
1. **태그** 섹션의 **태그** 필드에서 러너가 실행할 수 있는 작업을 지정하는 작업 태그를 입력합니다. 태그가 지정된 작업 외에도 태그가 없는 작업에 러너를 사용하려면 **Run untagged**를 선택합니다.
1. 선택 사항. **구성** 섹션에서 러너 설명 및 추가 구성을 추가합니다.
1. **러너 만들기**를 선택합니다.
1. **플랫폼** 섹션에서 **Google Cloud**를 선택합니다.
1. **환경**에서 Google Cloud 환경의 다음 세부 정보를 입력합니다:

   - **Google Cloud 프로젝트 ID**
   - **지역**
   - **Zone**
   - **머신 유형**

1. **Set up GitLab Runner**에서 **설정 방법**을 선택합니다. 대화 상자에서:

   1. 필요한 서비스, 서비스 계정 및 권한을 활성화하려면 **Configure Google Cloud project**에서 각 Google Cloud 프로젝트에 대해 한 번 Bash 스크립트를 실행합니다.
   1. `main.tf` 파일을 만들고 **Install and register GitLab Runner**의 구성을 사용합니다. 스크립트는 [GitLab Runner Infrastructure Toolkit](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit/-/blob/main/docs/scenarios/google/linux/docker-autoscaler-default/index.md)(GRIT)을 사용하여 Google Cloud 프로젝트의 인프라를 프로비저닝하여 러너 매니저를 실행합니다.

      > [!warning]
      > 기본적으로 러너는 CI/CD 작업이 활성화되지 않은 경우에도 VM 인스턴스가 계속 실행될 수 있는 설정으로 구성됩니다. 자동 크기 조정 동작을 제어하고 비용을 줄이려면 매니저 인스턴스의 러너 구성 파일을 찾고 [`[runners.machine]` 섹션](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersmachine-section)을 편집하여 `IdleCount`, `IdleTime` 및 인스턴스 제한과 같은 매개 변수를 조정합니다.

스크립트를 실행한 후 러너 매니저는 러너 인증 토큰과 함께 연결됩니다. 러너 매니저는 온라인으로 표시되고 작업을 수신하기 시작하는 데 최대 1분이 걸릴 수 있습니다.
