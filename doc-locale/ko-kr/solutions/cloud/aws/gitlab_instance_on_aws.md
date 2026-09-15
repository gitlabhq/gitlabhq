---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: AWS에서 GitLab 인스턴스 프로비저닝
description: AWS에서 GitLab 인스턴스를 프로비저닝하기 위해 사용할 수 있는 코드 기반 인프라 도구 및 적격 AWS 관리형 서비스입니다.
---

## AWS에서 GitLab 인스턴스 설치를 위한 Infrastructure as Code 활용 {#available-infrastructure-as-code-for-gitlab-instance-installation-on-aws}

[GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/README.md)는 의견이 반영된 Terraform 및 Ansible 스크립트 모음입니다. 이 스크립트는 선택한 클라우드 제공자에서 Linux 패키지 또는 Cloud Native Hybrid 환경 배포를 지원하며, GitLab 개발자가 [GitLab Dedicated](../../../subscriptions/gitlab_dedicated/_index.md)에 사용합니다(예: ).

GitLab Environment Toolkit를 사용하여 AWS에서 Cloud Native Hybrid 환경을 배포할 수 있습니다. 하지만 필수 사항이 아니며 모든 유효한 조합을 지원하지 않을 수 있습니다. 그렇다면 스크립트는 그대로 제공되며 필요에 따라 수정할 수 있습니다.

### 2개 및 3개 영역 고가용성 {#two-and-three-zone-high-availability}

GitLab Reference Architectures는 일반적으로 3개 영역 중복을 권장하지만, AWS Well Architected 프레임워크는 2개 영역 중복을 AWS Well Architected로 간주합니다. 개별 구현은 최종 구성을 위해 2개 및 3개 영역 구성의 비용을 자체 고가용성 요구 사항에 비교해야 합니다.

Gitaly Cluster (Praefect)는 일관성 투표 시스템을 사용하여 동기화된 노드 간에 강력한 일관성을 구현합니다. 구현된 가용성 영역 수와 관계없이, 짝수 개의 노드로 인한 투표 교착 상태를 방지하기 위해 클러스터에 최소 3개의 Gitaly 및 3개의 Praefect 노드가 항상 필요합니다.

## 모든 GitLab 구현에 적합한 AWS PaaS {#aws-paas-qualified-for-all-gitlab-implementations}

Linux 패키지 또는 Cloud Native Hybrid 구현을 모두 사용하는 구현의 경우, 다음 GitLab 서비스 역할은 AWS Services (PaaS)에서 수행할 수 있습니다. 인스턴스 규모에 따라 사전 구성된 크기 조정이 필요한 모든 PaaS 솔루션도 인스턴스별 규모 Bill of Materials 목록에 나열됩니다. 특정 크기 조정이 필요하지 않은 PaaS는 BOM 목록에서 반복되지 않습니다(예: AWS Certification Manager).

이 서비스들은 GitLab으로 테스트되었습니다.

로그 집계, 아웃바운드 이메일 등 일부 서비스는 GitLab에서 지정하지 않지만, 제공되는 경우 표시됩니다.

| GitLab 서비스                                              | AWS PaaS (테스트됨)              |
| ------------------------------------------------------------ | ------------------------------ |
| <u>Reference Architectures에서 언급된 테스트된 PaaS</u>      |                                |
| **PostgreSQL Database**                                      | Amazon RDS PostgreSQL          |
| **Redis Caching**                                            | Redis ElastiCache              |
| **Gitaly Cluster (Git Repository Storage)**<br />(Praefect 및 PostgreSQL 포함) | ASG 및 인스턴스              |
| **All GitLab storages besides Git Repository Storage**<br />(S3 호환 Git-LFS 포함) | AWS S3                         |
|                                                              |                                |
| <u>보조 서비스를 위한 테스트된 PaaS</u>                 |                                |
| **Front End Load Balancing**                                 | AWS ELB                        |
| **Internal Load Balancing**                                  | AWS ELB                        |
| **Outbound Email Services**                                  | AWS Simple Email Service (SES) |
| **Certificate Authority and Management**                     | AWS Certificate Manager (ACM)  |
| **DNS**                                                      | AWS Route53 (테스트됨)           |
| **GitLab and Infrastructure Log Aggregation**                | AWS CloudWatch Logs            |
| **Infrastructure Performance Metrics**                       | AWS CloudWatch Metrics         |
|                                                              |                                |
| <u>보조 서비스 및 구성</u>              |                                |
| **Prometheus for GitLab**                                    | AWS EKS (Cloud Native 전용)    |
| **Grafana for GitLab**                                       | AWS EKS (Cloud Native 전용)    |
| **Encryption (In Transit / At Rest)**                        | AWS KMS                        |
| **Secrets Storage for Provisioning**                         | AWS Secrets Manager            |
| **Configuration Data for Provisioning**                      | AWS Parameter Store            |
| **AutoScaling Kubernetes**                                   | EKS AutoScaling Agent          |
