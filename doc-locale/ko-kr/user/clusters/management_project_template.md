---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 클러스터 애플리케이션 관리
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 클러스터 관리 프로젝트 템플릿을 제공하며, 이를 사용하여 프로젝트를 생성할 수 있습니다. 프로젝트에는 GitLab과 통합되고 GitLab 기능을 확장하는 클러스터 애플리케이션이 포함되어 있습니다. 프로젝트에 표시된 패턴을 사용하여 사용자 정의 클러스터 애플리케이션을 확장할 수 있습니다.

> [!note]
> 프로젝트 템플릿은 수정 없이 GitLab.com에서 작동합니다. GitLab Self-Managed 인스턴스를 사용 중이라면 `.gitlab-ci.yml` 파일을 수정해야 합니다.

## 에이전트와 매니페스트에 동일한 프로젝트 사용 {#use-one-project-for-the-agent-and-your-manifests}

아직 에이전트를 사용하여 클러스터를 GitLab과 연결하지 않은 경우:

1. [클러스터 관리 프로젝트 템플릿에서 프로젝트 생성](#create-a-project-based-on-the-cluster-management-project-template).
1. [에이전트의 프로젝트 구성](agent/install/_index.md).
1. 프로젝트 설정에서 [환경 변수](../../ci/variables/_index.md#for-a-project)를 `$KUBE_CONTEXT` 이름으로 생성하고 값을 `path/to/agent-configuration-project:your-agent-name`으로 설정합니다.
1. 필요에 따라 [파일 구성](#configure-the-project).

## 에이전트와 매니페스트에 별도의 프로젝트 사용 {#use-separate-projects-for-the-agent-and-your-manifests}

이미 에이전트를 구성하고 클러스터를 GitLab과 연결한 경우:

1. [클러스터 관리 프로젝트 템플릿에서 프로젝트 생성](#create-a-project-based-on-the-cluster-management-project-template).
1. 에이전트를 구성한 프로젝트에서 [새 프로젝트에 대한 에이전트 액세스 권한 부여](agent/ci_cd_workflow.md#authorize-agent-access).
1. 새 프로젝트에서 [환경 변수](../../ci/variables/_index.md#for-a-project)를 `$KUBE_CONTEXT` 이름으로 생성하고 값을 `path/to/agent-configuration-project:your-agent-name`으로 설정합니다.
1. 새 프로젝트에서 필요에 따라 [파일 구성](#configure-the-project).

## 클러스터 관리 프로젝트 템플릿을 기반으로 프로젝트 생성 {#create-a-project-based-on-the-cluster-management-project-template}

클러스터 관리 프로젝트 템플릿에서 프로젝트를 생성하려면:

1. 오른쪽 상단 모서리에서 **새로 만들기** ({{< icon name="plus" >}}) 및 **새 프로젝트/리포지토리**를 선택합니다.
1. **템플릿으로 부터 생성**을 선택합니다.
1. 템플릿 목록에서 **GitLab 클러스터 관리** 옆에 있는 **템플릿 사용**을 선택합니다.
1. 프로젝트 세부 사항을 입력합니다.
1. **프로젝트 생성**을 선택합니다.
1. 새 프로젝트에서 필요에 따라 [파일 구성](#configure-the-project).

## 프로젝트 구성 {#configure-the-project}

클러스터 관리 템플릿을 사용하여 프로젝트를 생성한 후 다음을 구성할 수 있습니다:

- [`.gitlab-ci.yml` 파일](#the-gitlab-ciyml-file).
- [주 `helmfile.yml` 파일](#the-main-helmfileyml-file).
- [기본 제공 애플리케이션이 있는 디렉토리](#built-in-applications).

### `.gitlab-ci.yml` 파일 {#the-gitlab-ciyml-file}

`.gitlab-ci.yml` 파일:

- Helm 버전 3인지 확인합니다.
- 프로젝트에서 활성화된 애플리케이션을 배포합니다.

파이프라인 정의를 편집하고 확장할 수 있습니다.

파이프라인에 사용되는 기본 이미지는 [cluster-applications](https://gitlab.com/gitlab-org/cluster-integration/cluster-applications) 프로젝트에서 빌드됩니다. 이 이미지에는 [Helm v3 릴리스](https://helm.sh/docs/intro/using_helm/#three-big-concepts)를 지원하기 위한 Bash 유틸리티 스크립트 세트가 포함되어 있습니다.

GitLab Self-Managed 인스턴스를 사용 중이라면 `.gitlab-ci.yml` 파일을 수정해야 합니다. 특히, `Automatic package upgrades` 주석으로 시작하는 섹션은 GitLab Self-Managed 인스턴스에서 작동하지 않습니다. `include`이 GitLab.com 프로젝트를 참조하기 때문입니다. 이 주석 아래의 모든 내용을 제거하면 파이프라인이 성공합니다.

### 주 `helmfile.yml` 파일 {#the-main-helmfileyml-file}

템플릿에는 [Helmfile](https://github.com/helmfile/helmfile)이 포함되어 있으며 [Helm v3](https://helm.sh/)으로 클러스터 애플리케이션을 관리하는 데 사용할 수 있습니다.

이 파일에는 각 앱에 대한 다른 Helm 파일의 경로 목록이 있습니다. 기본적으로 모두 주석 처리되어 있으므로 클러스터에서 사용하려는 앱의 경로를 주석 해제해야 합니다.

기본적으로 이러한 하위 경로의 각 `helmfile.yaml`에는 `installed: true` 속성이 있습니다. 즉, 클러스터의 상태와 Helm 릴리스에 따라 Helmfile은 파이프라인이 실행될 때마다 앱을 설치하거나 업데이트하려고 시도합니다. 이 속성을 `installed: false`으로 변경하면 Helmfile은 클러스터에서 이 앱을 제거하려고 시도합니다. Helmfile의 작동 방식에 대해 [자세히 알아보기](https://helmfile.readthedocs.io/en/latest/).

### 기본 제공 애플리케이션 {#built-in-applications}

템플릿에는 각 애플리케이션에 대해 구성된 `applications` 디렉토리와 `helmfile.yaml`이 포함되어 있습니다.

[기본 제공 지원 애플리케이션](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/tree/main/applications)은 다음과 같습니다:

- [Cert-manager](../infrastructure/clusters/manage/management_project_applications/certmanager.md)
- [러너](../infrastructure/clusters/manage/management_project_applications/runner.md)
- [Ingress](../infrastructure/clusters/manage/management_project_applications/ingress.md)
- [Vault](../infrastructure/clusters/manage/management_project_applications/vault.md)

각 애플리케이션에는 `applications/{app}/values.yaml` 파일이 있습니다. GitLab 러너의 경우 파일은 `applications/{app}/values.yaml.gotmpl`입니다.

이 파일에서 앱의 Helm 차트에 대한 기본값을 정의할 수 있습니다. 일부 앱에는 이미 정의된 기본값이 있습니다.
