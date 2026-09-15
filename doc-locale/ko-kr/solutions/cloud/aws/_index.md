---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: AWS 솔루션
---

이 문서는 Amazon Web Services(AWS)에서 GitLab을 활용하는 방법과 AWS에서 GitLab을 실행하는 방법과 관련된 솔루션을 다룹니다.

- [AWS의 GitLab 파트너십 인증 및 지정](gitlab_aws_partner_designations.md)
- [GitLab AWS 통합 인덱스](gitlab_aws_integration.md)
- [AWS EKS의 GitLab 인스턴스](gitlab_instance_on_aws.md)
- [AWS의 Gitaly에 대한 SRE 고려 사항](gitaly_sre_for_aws.md)
- [AWS에서 단일 EC2 인스턴스에 GitLab 프로비전](gitlab_single_box_on_aws.md)

## 클라우드 플랫폼 잘 설계된 규정 준수 {#cloud-platform-well-architected-compliance}

테스트 기반 아키텍처 검증은 클라우드 솔루션 구현의 기본 개념입니다:

- 클라우드 솔루션 구현은 GitLab 참조 아키텍처 규정 준수를 유지하고 [GitLab 성능 도구](https://gitlab.com/gitlab-org/quality/performance)(GPT) 보고서를 제공하여 이에 대한 준수를 보여줍니다.
- 클라우드 솔루션 구현은 기술 공급업체에 의해 검증되거나 기여될 수 있습니다. 예를 들어, AWS용 구현 패턴은 AWS에서 공식적으로 검토될 수 있습니다.
- 클라우드 솔루션 구현은 GitLab에 적합한지 확인하기 위해 클라우드 플랫폼 PaaS 서비스를 지정하고 테스트할 수 있습니다. 이 테스트는 조정될 수 있으며 참조 아키텍처에 대한 이러한 기술의 검증을 지원할 수 있습니다. 예를 들어, PostgreSQL 및 Redis와 같은 최상위 PaaS의 런타임 버전 호환성 및 가용성 검증.
- 클라우드 솔루션 구현은 플랫폼 제한 사항에 대한 검증된 테스트를 제공할 수 있습니다. 예를 들어 Gitaly 클러스터(Praefect)가 특정 클라우드 플랫폼 가용 영역 지연 시간 및 처리량 특성에서 올바르게 작동할 수 있도록 보장하거나 Gitaly 서버가 무결성을 유지하면서 작동할 수 있는 사용 가능한 플랫폼 파트너 로컬 디스크 성능 수준을 검증합니다.

## AWS 알려진 문제 목록 {#aws-known-issues-list}

알려진 문제는 GitLab 내에서 그리고 고객이 보고한 문제에서 수집됩니다. 고객은 GitLab이 특별히 설계되지 않았으며 지속적인 테스트도 이루어지지 않은 다양한 "서비스형" 구성 요소로 GitLab을 성공적으로 구현합니다. GitLab이 파트너 기술을 매우 진지하게 다루고 있지만, 여기서 알려진 문제를 강조하는 것은 구현자의 편의를 위한 것이며 GitLab이 특정 호환성을 목표로 하거나 문제가 발생하는 파트너 기술에서의 실행을 보장하지 않음을 의미합니다. 개별 문제를 참조하여 주어진 알려진 문제에 대한 GitLab의 입장 및 계획을 이해합니다.

전체 목록은 [GitLab AWS 알려진 문제 목록](https://gitlab.com/gitlab-com/alliances/aws/public-tracker/-/issues?label_name[]=AWS+Known+Issue)을 참조하세요.

## GitLab과 AWS를 사용하기 위한 작동 코드 예제가 포함된 패턴 {#patterns-with-working-code-examples-for-using-gitlab-with-aws}

[AWS용 Guided Explorations 하위 그룹](https://gitlab.com/guided-explorations/aws)에는 다양한 작동 예제 프로젝트가 포함되어 있습니다.

## 플랫폼 파트너 특이성 {#platform-partner-specificity}

클라우드 솔루션 구현은 플랫폼 특정 용어, 모범 사례 아키텍처 및 플랫폼 특정 빌드 매니페스트를 활성화합니다:

- 클라우드 솔루션 구현은 더 많은 공급업체 특정입니다. 예를 들어, vCPU 또는 기타 일반화된 측정 방식 대신 특정 컴퓨팅 인스턴스/VM/노드를 권고합니다.
- 클라우드 솔루션 구현은 해당 공급업체에 대한 좋은 아키텍처를 구현하는 데 중점을 둡니다.
- 클라우드 솔루션 구현은 구현 패턴이 대상으로 하는 인프라에 구축하는 것에 익숙한 대상 사용자를 위해 작성됩니다. 예를 들어, 구현 패턴이 GCP용인 경우 GCP의 특정 용어(PaaS 서비스의 특정 이름 사용 포함)가 사용됩니다.
- 클라우드 솔루션 구현은 사용 가능한 PaaS 버전이 GitLab과 호환되는지 테스트하고 검증할 수 있습니다(예: PostgreSQL, Redis 등).

## AWS 플랫폼 서비스형(PaaS) 사양 및 사용 {#aws-platform-as-a-service-paas-specification-and-usage}

플랫폼 서비스형(PaaS) 옵션은 클라우드 플랫폼이 제공하는 가치의 큰 부분이며, 운영상 복잡성을 단순화하고 고급의 매우 가용성이 높은 기술 서비스를 운영하는 데 필요한 SRE 및 보안 기술을 감소시킵니다. 클라우드 솔루션 구현은 파트너 PaaS 옵션에 대해 사전 검증될 수 있습니다.

- 클라우드 솔루션 구현은 구현자가 어떤 PaaS 옵션이 작동하는지 이해하고 단일 플랫폼이 동일한 GitLab 역할에 대해 여러 PaaS 옵션을 가지고 있을 때 PaaS 솔루션 간에 선택하는 방법을 이해하도록 지원합니다.
- 예를 들어, 참조 아키텍처가 GitLab 아웃바운드 이메일 서비스에 활용되는 기술이나 크기 조정 방법에 대한 특정 권장 사항이 없는 경우, 참조 구현은 클라우드 공급자의 서비스형 이메일(PaaS)을 사용하거나 특정 설정으로도 사용할 것을 권고할 수 있습니다.

[AWS 서비스를 사용하여 GitLab 인프라 배포](gitlab_instance_on_aws.md)에서 자세히 알아볼 수 있습니다.

## 비용 최적화 엔지니어링 {#cost-optimizing-engineering}

비용 엔지니어링은 클라우드 아키텍처의 기본 측면이며 플랫폼에서 사용할 수 있는 절감 기능이 확장된 컴퓨팅을 구축하는 방법에 강한 영향을 미칩니다.

- 클라우드 솔루션 구현은 플랫폼 공급자가 제공하는 절감 모델을 위해 특별히 엔지니어링될 수 있습니다. AWS의 예는 예약 인스턴스를 활용하기 위해 특정 인스턴스 유형의 발생을 최대화하는 것입니다.
- 클라우드 솔루션 구현은 적절한 경우 적절한 고객 지침과 함께 임시 컴퓨팅을 활용할 수 있습니다. 예를 들어, 임시 컴퓨팅의 러너에 전용된 Kubernetes 노드 그룹(컴퓨팅 유형을 나타내기 위한 적절한 GitLab Runner 태깅 포함).
- 클라우드 솔루션 구현은 공급업체별 비용 계산기를 포함할 수 있습니다.

## 실행 가능성 및 자동화 가능성 방향 {#actionability-and-automatability-orientation}

클라우드 솔루션 구현은 빌드 지침 및 자동화 코드의 소스로 사용할 수 있는 세부 사항 한 단계 더 가까이 있습니다:

- 클라우드 솔루션 구현은 구현자가 주어진 참조 아키텍처에 대해 GitLab을 구현하는 데 필요한 공급업체별 리소스 목록을 생성할 수 있게 합니다.
- 클라우드 솔루션 구현은 구현자가 수동 지침을 사용하거나 참조 구현을 구축하기 위한 자동화를 만들 수 있게 합니다.

## 의도된 대상 및 기여자 {#intended-audiences-and-contributors}

이 정보의 주요 대상과 기여자는 다음으로 구성된 GitLab **Implementation Eco System**입니다:

GitLab 구현 커뮤니티:

- 고객
- GitLab 채널 파트너(통합자)
- 플랫폼 파트너

GitLab 내부 구현 팀:

- 품질/배포/자체 관리
- 제휴 관계
- 교육
- 지원
- 전문 서비스
- 공공 부문
