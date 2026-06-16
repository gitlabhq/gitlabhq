---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 인프라 관리를 위한 모범 사례를 활용하세요.
title: 인프라 관리 시작하기
---

DevOps 및 SRE 접근 방식의 증가로 인해 인프라 관리가 코드화되고 자동화되었습니다. 이제 인프라 관리에서 소프트웨어 개발 모범 사례를 활용할 수 있습니다.

기존 운영 팀의 일일 작업은 변경되었으며 기존 소프트웨어 개발과 더 유사합니다. 동시에 소프트웨어 엔지니어는 배포 및 전달을 포함한 전체 DevOps 수명 주기를 제어할 가능성이 더 높습니다.

GitLab은 인프라 관리 관행을 가속화하고 단순화하기 위한 다양한 기능을 제공합니다.

인프라 관리는 더 큰 워크플로의 일부입니다:

![GitLab DevOps 수명 주기의 릴리스 섹션에서 인프라 관리](img/get_started_managing_infrastructure_v16_11.png)

## 1단계:  코드를 사용하여 인프라 관리 {#step-1-use-code-to-manage-your-infrastructure}

GitLab은 코드 기반 인프라 파이프라인을 실행하고 다양한 프로세스를 지원하기 위해 Terraform과 깊이 있게 통합되어 있습니다. Terraform은 클라우드 인프라 프로비저닝의 표준으로 간주됩니다. 다양한 GitLab 통합이 다음을 도와줍니다:

- 설정 없이 빠르게 시작하세요.
- 코드 변경과 동일한 방식으로 머지 리퀘스트의 인프라 변경 사항에 대해 협업하세요.
- 모듈 레지스트리를 사용하여 확장하세요.

자세한 정보는 다음을 참조하세요:

- [코드 기반 인프라](../infrastructure/iac/_index.md)

## 2단계:  Kubernetes 클러스터와 상호 작용 {#step-2-interact-with-kubernetes-clusters}

GitLab과 Kubernetes의 통합은 클러스터 애플리케이션을 설치, 구성, 관리, 배포 및 문제 해결하는 데 도움이 됩니다. GitLab Kubernetes 에이전트를 사용하면 방화벽 뒤의 클러스터에 연결하고, API 엔드포인트에 실시간으로 액세스하고, 프로덕션 및 비프로덕션 환경을 위한 풀 기반 또는 푸시 기반 배포를 수행할 수 있으며, 더 많은 작업을 수행할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [클라우드에서 Kubernetes 클러스터 생성](../clusters/create/_index.md)
- [Kubernetes 클러스터를 GitLab과 연결](../clusters/agent/_index.md)

## 3단계:  런북으로 절차 문서화 {#step-3-document-procedures-with-runbooks}

런북은 시작, 중지, 디버깅 또는 시스템 문제 해결과 같은 작업을 수행하는 방법을 설명하는 문서화된 절차의 모음입니다. GitLab에서 런북은 Markdown으로 생성됩니다. 텍스트, 코드 스니펫, 이미지 및 링크를 포함한 다양한 요소를 포함할 수 있습니다.

GitLab의 런북은 CI/CD 파이프라인 및 이슈와 같은 다른 GitLab 기능과 통합됩니다. 파이프라인이 성공하거나 이슈가 생성될 때와 같이 특정 이벤트 또는 조건에 따라 런북을 자동으로 트리거할 수 있습니다. 또한 사용자는 런북을 이슈, 머지 리퀘스트 및 기타 GitLab 객체에 연결할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [GitLab에서 실행 가능한 런북이 작동하는 방식](../project/clusters/runbooks/_index.md)
