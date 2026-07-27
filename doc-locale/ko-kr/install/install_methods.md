---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Linux, Helm, Docker, Operator, source, 또는 scripts."
title: 설치 방법
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

여러 [클라우드 제공자](cloud_providers.md)에서 GitLab을 설치하거나 다음 방법 중 하나를 사용할 수 있습니다.

## Linux 패키지 {#linux-package}

Linux 패키지에는 공식 `deb`및 `rpm` 패키지가 포함됩니다. 이 패키지에는 GitLab 및 PostgreSQL, Redis, Sidekiq을 포함한 종속 구성 요소가 있습니다.

가장 성숙하고 확장 가능한 방법을 원하는 경우 사용하세요. 이 버전은 GitLab.com에서도 사용됩니다.

자세한 정보는 다음을 참조하세요.

- [Linux 패키지](package/_index.md)
- [참조 아키텍처](../administration/reference_architectures/_index.md)
- [시스템 요구 사항](requirements.md)
- [지원되는 Linux 운영 체제](package/_index.md#supported-platforms)

## Helm 차트 {#helm-chart}

차트를 사용하여 Kubernetes에서 GitLab의 클라우드 네이티브 버전 및 해당 구성 요소를 설치합니다.

인프라가 Kubernetes에 있고 작동 방식에 익숙한 경우 사용하세요.

이 설치 방법을 사용하기 전에 다음을 고려하세요:

- 관리, 관찰성, 및 기타 개념은 일반적인 배포와 다릅니다.
- 관리 및 문제 해결에는 Kubernetes 지식이 필요합니다.
- 더 작은 설치의 경우 비용이 더 많이 들 수 있습니다.
- 기본 설치는 대부분의 서비스가 중복 방식으로 배포되기 때문에 단일 노드 Linux 패키지 배포보다 더 많은 리소스가 필요합니다.

자세한 내용은 [Helm 차트](https://docs.gitlab.com/charts/)를 참조하세요.

## GitLab Operator {#gitlab-operator}

Kubernetes에서 GitLab의 클라우드 네이티브 버전 및 해당 구성 요소를 설치하려면 GitLab Operator를 사용하세요. 이 설치 및 관리 방법은 [Kubernetes Operator 패턴](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)을 따릅니다.

인프라가 Kubernetes 또는 [OpenShift](openshift_and_gitlab/_index.md)에 있고 Operators의 작동 방식에 익숙한 경우 사용하세요.

이 설치 방법은 Helm 차트 설치 방법 이상의 추가 기능을 제공하며, [GitLab 업그레이드 단계](https://docs.gitlab.com/operator/gitlab_upgrades/)의 자동화가 포함됩니다. Helm 차트의 고려 사항도 여기에 적용됩니다.

[GitLab Operator 알려진 이슈](https://docs.gitlab.com/operator/#known-issues)에 의해 제한되는 경우 Helm 차트 설치 방법을 고려하세요.

자세한 내용은 [GitLab Operator](https://docs.gitlab.com/operator/)를 참조하세요.

## Docker {#docker}

Docker 컨테이너에 GitLab 패키지를 설치합니다.

Docker에 익숙한 경우 사용하세요.

자세한 내용은 [Docker](docker/_index.md)를 참조하세요.

## Self-compiled {#self-compiled}

GitLab 및 해당 구성 요소를 처음부터 설치합니다.

이전 방법 중 플랫폼에서 사용할 수 있는 것이 없는 경우 사용하세요. \*BSD와 같은 지원되지 않는 시스템에 사용할 수 있습니다.

자세한 내용은 [자체 컴파일 설치](self_compiled/_index.md)를 참조하세요.

## GitLab Environment Toolkit (GET) {#gitlab-environment-toolkit-get}

[GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#documentation)는 의견이 반영된 Terraform 및 Ansible 스크립트 모음입니다.

GET을 사용하여 선택된 주요 클라우드 제공자(GCP, AWS, Azure)에서 [참조 아키텍처](../administration/reference_architectures/_index.md)를 따르는 확장된 GitLab 환경을 배포할 수 있습니다.

이 설치 방법은 일부 [제한 사항](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#missing-features-to-be-aware-of)이 있으며, 프로덕션 환경의 경우 수동 설정이 필요합니다.

## 지원되지 않는 Linux 배포판 및 Unix 계열 운영 체제 {#unsupported-linux-distributions-and-unix-like-operating-systems}

다음 운영 체제에서 [자체 컴파일 설치](self_compiled/_index.md)는 가능하지만 지원되지 않습니다:

- Arch Linux
- FreeBSD
- Gentoo
- macOS

## Microsoft Windows {#microsoft-windows}

GitLab은 Linux 기반 운영 체제를 위해 개발되었습니다. Microsoft Windows에서 실행되지 않으며 근시일 내에 이를 지원할 계획이 없습니다. 최신 개발 상황은 [이슈 22337](https://gitlab.com/gitlab-org/gitlab/-/issues/22337)을 참조하세요. GitLab을 실행하기 위해 가상 머신 사용을 고려하세요.
