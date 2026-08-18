---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-Managed와 러너 플릿을 OpenShift에서 실행하고 Kubernetes용 GitLab agent와 통합합니다.
title: OpenShift 지원
---

OpenShift - GitLab 호환성을 세 가지 측면에서 해결할 수 있습니다. 이 페이지는 이러한 측면을 탐색하는 데 도움이 되며 OpenShift 및 GitLab을 시작하기 위한 소개 정보를 제공합니다.

## OpenShift란 무엇입니까 {#what-is-openshift}

OpenShift는 컨테이너 기반 애플리케이션을 개발, 배포 및 관리할 수 있습니다. 온디맨드로 애플리케이션을 생성, 수정 및 배포할 수 있는 셀프서비스 플랫폼을 제공합니다. 이를 통해 더 빠른 개발 및 릴리스 수명 주기가 가능합니다.

## GitLab Self-Managed를 실행하도록 OpenShift 사용 {#use-openshift-to-run-gitlab-self-managed}

GitLab Operator를 사용하여 OpenShift 클러스터에서 GitLab을 실행할 수 있습니다. OpenShift에서 GitLab을 설정하는 방법에 대한 자세한 내용은 [GitLab Operator](https://docs.gitlab.com/operator/)를 참조하세요.

## 러너 플릿을 실행하도록 OpenShift 사용 {#use-openshift-to-run-a-gitlab-runner-fleet}

GitLab Operator에는 러너가 포함되지 않습니다. OpenShift 클러스터에 러너 플릿을 설치하고 관리하려면 [GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator)를 사용하세요.

### GitLab에서 OpenShift로 배포 및 통합 {#deploy-to-and-integrate-with-openshift-from-gitlab}

GitLab에서 OpenShift 위에 사용자 정의 또는 COTS 애플리케이션을 배포하는 것은 [Kubernetes용 GitLab agent](../../user/clusters/agent/_index.md)를 사용하여 지원됩니다.

### 지원되지 않는 GitLab 기능 {#unsupported-gitlab-features}

#### Docker-in-Docker {#docker-in-docker}

OpenShift를 러너 플릿을 실행하는 데 사용할 때 OpenShift의 보안 모델로 인해 일부 GitLab 기능이 지원되지 않습니다. Docker-in-Docker이 필요한 기능은 작동하지 않을 수 있습니다.

Auto DevOps의 경우 다음 기능이 아직 지원되지 않습니다:

- [자동 코드 품질](../../ci/testing/code_quality.md)
- [라이선스 승인 정책](../../user/compliance/license_approval_policies.md)
- 자동 브라우저 성능 테스트
- 자동 빌드
- [운영 컨테이너 스캔](../../user/clusters/agent/vulnerabilities.md) (참고: [컨테이너 스캔](../../user/application_security/container_scanning/_index.md)은 파이프라인에서 지원됩니다)
