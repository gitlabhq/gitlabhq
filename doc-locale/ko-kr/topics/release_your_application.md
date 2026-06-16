---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "환경, 패키지, 검토 앱, GitLab Pages."
title: 애플리케이션 배포 및 릴리스
---

배포는 애플리케이션이 최종 목표 인프라에 배포되는 소프트웨어 전달 프로세스의 단계입니다.

애플리케이션을 내부적으로 또는 공개적으로 배포할 수 있습니다. 검토 앱에서 릴리스를 미리 보고, 기능 플래그를 사용하여 기능을 점진적으로 릴리스합니다.

{{< cards >}}

- [시작하기](../user/get_started/get_started_deploy_release.md)
- [패키지 및 레지스트리](../user/packages/_index.md)
- [환경](../ci/environments/_index.md)
- [배포](../ci/environments/deployments.md)
- [릴리스](../user/project/releases/_index.md)
- [애플리케이션 점진적 배포](../ci/environments/incremental_rollouts.md)
- [기능 플래그](../operations/feature_flags.md)
- [GitLab Pages](../user/project/pages/_index.md)

{{< /cards >}}

## 관련 항목 {#related-topics}

- [Auto DevOps](autodevops/_index.md)는 GitLab CI/CD를 사용하여 애플리케이션을 구축, 테스트, 린트, 패키지, 배포, 보안 및 모니터링하는 전체 소프트웨어 공급망을 지원하는 자동화된 CI/CD 기반 워크플로입니다. 대다수의 사용 사례를 충족하는 즉시 사용 가능한 템플릿 세트를 제공합니다.
- [Auto Deploy](autodevops/stages.md#auto-deploy)는 GitLab CI/CD를 사용한 소프트웨어 배포에 전담하는 DevOps 스테이지입니다. Auto Deploy는 EC2 및 ECS 배포에 대한 내장 지원을 제공합니다.
- [GitLab agent for Kubernetes](../user/clusters/agent/install/_index.md)를 사용하여 Kubernetes 클러스터에 배포합니다.
- Docker 이미지를 사용하여 GitLab CI/CD에서 AWS 명령을 실행하고, [AWS에 배포](../ci/cloud_deployment/_index.md)를 용이하게 하는 템플릿을 사용합니다.
- GitLab CI/CD를 사용하여 러너가 액세스할 수 있는 모든 유형의 인프라를 대상으로 합니다. [사용자 및 미리 정의된 환경 변수](../ci/variables/_index.md)와 CI/CD 템플릿은 다양한 배포 전략을 설정하는 데 지원합니다.
- GitLab [Cloud Seed](../cloud_seed/_index.md)를 사용하여 배포 자격 증명을 설정하고 최소한의 마찰로 애플리케이션을 Google Cloud Run에 배포합니다.
