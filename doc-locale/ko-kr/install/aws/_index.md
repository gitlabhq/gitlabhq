---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab에서 제공하는 커뮤니티 AMI를 사용하여 AWS에 GitLab을 설치합니다.
title: Amazon Web Services(AWS)에 GitLab POC 설치
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이 페이지에서는 공식 Linux 패키지를 사용하여 AWS에서 GitLab을 구성하는 일반적인 방법을 안내합니다. 필요에 맞게 사용자 지정해야 합니다.

> [!note]
> 사용자 1,000명 이하인 조직의 경우 권장되는 AWS 설치 방법은 EC2 단일 박스 [Linux 패키지 설치](https://about.gitlab.com/install/)를 시작하고 데이터 백업을 위한 스냅샷 전략을 구현하는 것입니다.

## 프로덕션급 GitLab 시작하기 {#getting-started-for-production-grade-gitlab}

> [!note]
> 이 문서는 개념 증명 안내입니다. 고가용성 구성을 제공하지 않습니다.

이 가이드를 정확히 따르면 비HA 인스턴스가 생성됩니다. AWS에서 프로덕션급 배포를 위해 [참조 아키텍처](../../administration/reference_architectures/_index.md)를 사용하여 규모에 맞는 올바른 구성을 결정합니다. 참조 아키텍처는 Linux 패키지(VM 기반)와 클라우드 네이티브(Kubernetes) 배포 유형을 모두 다룹니다.

## 소개 {#introduction}

대부분의 경우 설정에서 Linux 패키지를 사용하지만 네이티브 AWS 서비스도 활용합니다. Linux 패키지에 포함된 PostgreSQL과 Redis 대신 Amazon RDS와 ElastiCache를 사용합니다.

이 가이드에서는 Virtual Private Cloud와 서브넷을 구성하여 시작하고 나중에 데이터베이스 서버용 RDS, Redis 클러스터용 ElastiCache와 같은 서비스를 통합한 다음 커스텀 스케일링 정책을 사용하여 자동 크기 조정 그룹에서 관리하는 멀티노드 설정을 다룹니다.

## 요구사항 {#requirements}

[AWS](https://docs.aws.amazon.com/) 및 [Amazon EC2](https://docs.aws.amazon.com/ec2/)에 대한 기본 지식 외에도 다음이 필요합니다:

- [AWS 계정](https://console.aws.amazon.com/console/home)
- [SSH 키 생성 또는 업로드](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)하여 SSH를 통해 인스턴스에 연결
- GitLab 인스턴스의 도메인 이름
- 도메인을 보안하기 위한 SSL/TLS 인증서입니다. 아직 SSL/TLS 인증서가 없으면 [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/)(ACM)를 통해 무료 공개 SSL/TLS 인증서를 프로비저닝할 수 있습니다. 이는 만드는 [Elastic Load Balancer](#load-balancer)와 함께 사용할 수 있습니다.

> [!note]
> ACM을 통해 프로비저닝된 인증서는 검증하는 데 몇 시간이 걸릴 수 있습니다. 나중에 지연을 피하려면 가능한 한 빨리 인증서를 요청하세요.

## 아키텍처 {#architecture}

다음 다이어그램은 권장되는 아키텍처를 설명합니다.

![확장된 2개의 가용 영역 및 비HA AWS 아키텍처입니다.](img/aws_ha_architecture_diagram_v17_0.png)

## AWS 비용 {#aws-costs}

GitLab은 다음 AWS 서비스를 사용하며, 가격 정보 링크가 제공됩니다:

- **EC2**: GitLab은 공유 하드웨어에 배포되며 [온디맨드 가격](https://aws.amazon.com/ec2/pricing/on-demand/)이 적용됩니다. GitLab을 전용 또는 예약 인스턴스에서 실행하려면 비용 정보를 보려면 [EC2 가격 페이지](https://aws.amazon.com/ec2/pricing/)를 참조하세요.
- **S3**: GitLab은 S3([가격 페이지](https://aws.amazon.com/s3/pricing/))를 사용하여 백업, 아티팩트 및 LFS 객체를 저장합니다.
- **NLB**: Network Load Balancer([가격 페이지](https://aws.amazon.com/elasticloadbalancing/pricing/))로 GitLab 인스턴스에 요청을 라우팅합니다.
- **RDS**: PostgreSQL을 사용하는 Amazon Relational Database Service([가격 페이지](https://aws.amazon.com/rds/postgresql/pricing/))입니다.
- **ElastiCache**: 메모리 내 캐시 환경([가격 페이지](https://aws.amazon.com/elasticache/pricing/))으로 Redis 구성을 제공합니다.

## IAM EC2 인스턴스 역할 및 프로필 생성 {#create-an-iam-ec2-instance-role-and-profile}

[Amazon S3 객체 저장소](#amazon-s3-object-storage)를 사용 중이므로 EC2 인스턴스는 S3 버킷에 대한 읽기, 쓰기 및 나열 권한을 가져야 합니다. AWS 키를 GitLab 구성에 포함하는 것을 피하기 위해 [IAM 역할](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)을 사용하여 GitLab 인스턴스에 이 액세스를 허용합니다. IAM 역할에 연결할 IAM 정책을 생성해야 합니다:

### IAM 정책 생성 {#create-an-iam-policy}

1. IAM 대시보드로 이동하고 왼쪽 메뉴에서 **정책**을 선택합니다.
1. **정책 생성**을 선택하고, `JSON` 탭을 선택한 다음 정책을 추가합니다. [보안 모범 사례를 따르고 _최소 권한_을 부여](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)하려고 하므로, 역할에 필요한 작업을 수행하는 데 필요한 권한만 제공합니다.
   1. 다이어그램에서 보이는 대로 S3 버킷 이름에 `gl-` 접두사를 붙인다고 가정하고 다음 정책을 추가합니다:

   ```json
   {   "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject",
                   "s3:PutObjectAcl"
               ],
               "Resource": "arn:aws:s3:::gl-*/*"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "s3:ListBucket",
                   "s3:AbortMultipartUpload",
                   "s3:ListMultipartUploadParts",
                   "s3:ListBucketMultipartUploads"
               ],
               "Resource": "arn:aws:s3:::gl-*"
           }
       ]
   }
   ```

   > [!note]
   > 외부 프로세스가 S3 버킷의 객체에 태그를 지정하는 경우(예: AWS GuardDuty 맬웨어 보호), 원본 버킷의 객체 수준 `Action` 목록에 `s3:GetObjectTagging`을 추가하고 대상 버킷에 `s3:PutObjectTagging`를 추가합니다. 이러한 권한이 없으면 GitLab `CopyObject` 작업이 태그된 객체를 복사할 때 `AccessDenied`로 실패합니다.

1. 정책을 검토하려면 **다음**을 선택합니다. 정책에 이름을 지정하고(저희는 `gl-s3-policy`를 사용), **정책 생성**을 선택합니다.

### IAM 역할 생성 {#create-an-iam-role}

1. IAM 대시보드에서 왼쪽 메뉴의 **역할**을 선택하고, **역할 생성**을 선택합니다.
1. **Trusted entity type**의 경우 `AWS service`을 선택합니다. **Use case**에 대해 드롭다운 목록과 라디오 단추 모두에서 `EC2`을 선택하고 **다음**을 선택합니다.
1. 정책 필터에서 이전에 생성한 `gl-s3-policy`을 검색하여 선택한 다음 **다음**을 선택합니다.
1. 역할에 이름을 지정합니다(저희는 `GitLabS3Access`을 사용). 필요한 경우 일부 태그를 추가합니다. **역할 생성**을 선택합니다.

나중에 [시작 템플릿을 생성](#create-a-launch-template)할 때 이 역할을 사용합니다.

> [!note]
> GitLab은 AWS Instance Metadata Service Version 2(IMDSv2)를 지원합니다. GitLab은 사용 가능할 때 자동으로 IMDSv2를 사용하고 필요한 경우 IMDSv1로 폴백합니다. 향상된 보안을 위해 EC2 인스턴스에서 IMDSv2를 안전하게 요구할 수 있습니다.

## 네트워크 구성 {#configuring-the-network}

GitLab 클라우드 인프라를 위한 VPC를 생성하는 것으로 시작한 후, 최소 2개의 [가용 영역(AZ)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)에서 공개 및 비공개 인스턴스를 보유할 서브넷을 생성할 수 있습니다. 공개 서브넷에는 경로 테이블 유지 및 관련 인터넷 게이트웨이가 필요합니다.

### Virtual Private Cloud(VPC) 생성 {#creating-the-virtual-private-cloud-vpc}

이제 제어하는 가상 네트워킹 환경인 VPC를 생성합니다:

1. [Amazon Web Services](https://console.aws.amazon.com/vpc/home)에 로그인합니다.
1. 왼쪽 메뉴에서 **Your VPCs**를 선택한 다음 **Create VPC**을 선택합니다. "Name tag"에 `gitlab-vpc`을 입력하고 "IPv4 CIDR block"에 `10.0.0.0/16`을 입력합니다. 전용 하드웨어가 필요하지 않으면 "Tenancy"를 기본값으로 둘 수 있습니다. 준비되면 **Create VPC**을 선택합니다.

   ![GitLab 클라우드 인프라를 위한 VPC를 생성합니다.](img/create_vpc_v17_0.png)

1. VPC를 선택하고, **조치**를 선택한 다음, **Edit VPC Settings**을 선택하고 **Enable DNS resolution**를 선택합니다. 완료되면 **저장**을 선택합니다.

### 서브넷 {#subnets}

이제 다양한 가용 영역에서 일부 서브넷을 생성해봅시다. 각 서브넷이 방금 생성한 VPC와 연결되어 있고 CIDR 블록이 겹치지 않는지 확인합니다. 이를 통해 중복성을 위해 다중 AZ를 활성화할 수 있습니다.

로드 밸런서 및 RDS 인스턴스와 일치하도록 비공개 및 공개 서브넷을 생성합니다:

1. 왼쪽 메뉴에서 **Subnets**을 선택합니다.
1. **Create subnet**을 선택합니다. IP를 기반으로 설명적인 이름 태그를 지정합니다. 예: `gitlab-public-10.0.0.0`, 이전에 생성한 VPC를 선택하고, 가용 영역을 선택하고(저희는 `us-west-2a`을 사용), IPv4 CIDR 블록에서 24 서브넷 `10.0.0.0/24`을 제공합니다:

   ![서브넷을 생성합니다.](img/create_subnet_v17_0.png)

1. 동일한 단계를 따라 모든 서브넷을 생성합니다:

   | 이름 태그                  | 형식    | 가용 영역 | CIDR 블록    |
   | ------------------------- | ------- | ----------------- | ------------- |
   | `gitlab-public-10.0.0.0`  | 공개  | `us-west-2a`      | `10.0.0.0/24` |
   | `gitlab-private-10.0.1.0` | 비공개 | `us-west-2a`      | `10.0.1.0/24` |
   | `gitlab-public-10.0.2.0`  | 공개  | `us-west-2b`      | `10.0.2.0/24` |
   | `gitlab-private-10.0.3.0` | 비공개 | `us-west-2b`      | `10.0.3.0/24` |

1. 두 개의 공개 서브넷에 대해 **Auto-assign IPv4**를 활성화합니다:
   1. 각 공개 서브넷을 차례로 선택하고, **조치**를 선택한 다음, **Edit subnet settings**을 선택합니다. **Enable auto-assign public IPv4 address** 옵션을 선택하고 저장합니다.

### 인터넷 게이트웨이 {#internet-gateway}

이제 동일한 대시보드에서 인터넷 게이트웨이로 이동하여 새로운 것을 생성합니다:

1. 왼쪽 메뉴에서 **Internet Gateways**를 선택합니다.
1. **Create internet gateway**을 선택하고, 이름 `gitlab-gateway`을 지정한 다음 **생성**을 선택합니다.
1. 테이블에서 이를 선택한 다음 **조치** 드롭다운 목록에서 "VPC에 연결"을 선택합니다.

   ![인터넷 게이트웨이를 생성합니다.](img/create_gateway_v17_0.png)

1. 목록에서 `gitlab-vpc`을 선택하고 **Attach**을 누릅니다.

### NAT 게이트웨이 생성 {#create-nat-gateways}

비공개 서브넷에 배포된 인스턴스는 업데이트를 위해 인터넷에 연결해야 하지만 공개 인터넷에서 도달할 수 없어야 합니다. 이를 달성하기 위해 각각의 공개 서브넷에 배포된 [NAT 게이트웨이](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)를 사용합니다:

1. VPC 대시보드로 이동하고 왼쪽 메뉴 모음에서 **NAT Gateways**를 선택합니다.
1. **Create NAT Gateway**을 선택하고 다음을 완료합니다:
   1. **Availability mode**: `Zonal`을 선택합니다.
   1. **Subnet**: 드롭다운 목록에서 `gitlab-public-10.0.0.0`을 선택합니다.
   1. **Elastic IP Allocation ID**: 기존 Elastic IP를 입력하거나 **Allocate Elastic IP address**을 선택하여 NAT 게이트웨이에 새 IP를 할당합니다.
   1. 필요한 경우 태그를 추가합니다.
   1. **Create NAT Gateway**을 선택합니다.

두 번째 NAT 게이트웨이를 생성하되, 이번에는 두 번째 공개 서브넷인 `gitlab-public-10.0.2.0`에 배치합니다.

### 경로 테이블 {#route-tables}

#### 공개 경로 테이블 {#public-route-table}

공개 서브넷이 이전 단계에서 생성한 인터넷 게이트웨이를 통해 인터넷에 도달할 수 있도록 경로 테이블을 생성해야 합니다.

VPC 대시보드에서:

1. 왼쪽 메뉴에서 **Route Tables**을 선택합니다.
1. **Create Route Table**을 선택합니다.
1. "Name tag"에 `gitlab-public`을 입력하고 "VPC" 아래에서 `gitlab-vpc`을 선택합니다.
1. **생성**을 선택합니다.

이제 인터넷 게이트웨이를 새로운 대상으로 추가하고 모든 대상에서 트래픽을 수신하도록 해야 합니다.

1. 왼쪽 메뉴에서 **Route Tables**을 선택하고 `gitlab-public` 경로를 선택하여 맨 아래에 옵션을 표시합니다.
1. **Routes** 탭을 선택하고, **Edit routes** > **Add route**를 선택한 다음, `0.0.0.0/0`을 대상으로 설정합니다. 대상 열에서 **Internet Gateway**를 선택하고 이전에 생성한 `gitlab-gateway`을 선택합니다. 완료되면 **변경사항 저장**을 선택합니다.

다음으로, **public** 서브넷을 경로 테이블과 연결해야 합니다:

1. **Subnet Associations** 탭을 선택하고 **Edit subnet associations**을 선택합니다.
1. 공개 서브넷만 선택하고 **Save associations**을 선택합니다.

#### 비공개 경로 테이블 {#private-route-tables}

또한 각 비공개 서브넷의 인스턴스가 동일한 가용 영역의 해당 공개 서브넷에 있는 NAT 게이트웨이를 통해 인터넷에 도달할 수 있도록 두 개의 비공개 경로 테이블을 생성해야 합니다.

1. 이전 단계를 따라 두 개의 비공개 경로 테이블을 생성합니다. 이름을 `gitlab-private-a`과 `gitlab-private-b`로 지정합니다.
1. 다음으로, 각 비공개 경로 테이블에 대상이 `0.0.0.0/0`이고 대상이 이전에 생성한 NAT 게이트웨이 중 하나인 새로운 경로를 추가합니다.
   1. `gitlab-public-10.0.0.0`에서 생성한 NAT 게이트웨이를 `gitlab-private-a` 경로 테이블의 새로운 경로에 대한 대상으로 추가합니다.
   1. 마찬가지로, `gitlab-public-10.0.2.0`의 NAT 게이트웨이를 `gitlab-private-b`의 새로운 경로의 대상으로 추가합니다.
1. 마지막으로, 각 비공개 서브넷을 비공개 경로 테이블과 연결합니다.
   1. `gitlab-private-10.0.1.0`을 `gitlab-private-a`와 연결합니다.
   1. `gitlab-private-10.0.3.0`을 `gitlab-private-b`와 연결합니다.

## 로드 밸런서 {#load-balancer}

GitLab 애플리케이션 서버 전체에 인바운드 트래픽을 균등하게 분배하는 로드 밸런서를 생성합니다. 나중에 생성하는 [스케일링 정책](#create-an-auto-scaling-group)에 기반하여, 필요에 따라 인스턴스가 로드 밸런서에 추가되거나 제거됩니다. 또한 로드 밸런서는 인스턴스에 대한 상태 검사를 수행합니다.

AWS는 이 아키텍처에 대해 두 가지 접근 방식을 제공합니다:

- **Network Load Balancer (NLB) only**: 더 작은 배포에 적합한 더 간단한 설정입니다. NLB는 모든 트래픽(포트 22의 SSH, 포트 80의 HTTP, 포트 443의 HTTPS)을 Rail 노드로 직접 처리하며, SSL/TLS 종료는 NLB에서 발생합니다.
- **Hybrid NLB->ALB approach**: 관심 사항을 분리하는 더 확장성 있는 설정입니다. NLB는 TCP 트래픽(포트 22의 SSH)을 처리하고, Application Load Balancer(ALB)는 SSL/TLS 종료를 사용하여 HTTP/HTTPS 트래픽을 처리합니다. 이 접근 방식은 AWS WAF 통합 및 더 나은 트래픽 관리를 가능하게 합니다.

배포에 가장 적합한 접근 방식을 선택합니다:

- NLB 전용:

  ```mermaid
  graph TB
      subgraph Diagram1["NLB Only"]
        U1["Users"]
        NLB1["Network Load Balancer<br/>(Port 22, 80, 443)"]
        R1A["Rails Node 1<br/>(Port 22, 80)"]
        R1B["Rails Node 2<br/>(Port 22, 80)"]

        U1 -->|SSH| NLB1
        U1 -->|HTTP| NLB1
        U1 -->|HTTPS| NLB1
        NLB1 -->|Port 22| R1A
        NLB1 -->|Port 22| R1B
        NLB1 -->|"Port 80, 443"| R1A
        NLB1 -->|"Port 80, 443"| R1B
    end
    ```

- Hybrid NLB/ALB:

  ```mermaid
  graph TB
      subgraph Diagram2["Hybrid NLB/ALB"]
          U2["Users"]
          NLB2["Network Load Balancer<br/>(Port 22, 443)"]
          ALB["Application Load Balancer<br/>(Port 443)"]
          R2A["Rails Node 1<br/>(Port 22, 80)"]
          R2B["Rails Node 2<br/>(Port 22, 80)"]

          U2 -->|SSH| NLB2
          U2 -->|HTTPS| NLB2
          NLB2 -->|Port 22| R2A
          NLB2 -->|Port 22| R2B
          NLB2 -->|Port 443| ALB
          ALB -->|Port 80| R2A
          ALB -->|Port 80| R2B
      end
  ```

{{< tabs >}}

{{< tab title="Network Load Balancer(NLB) 전용" >}}

이 섹션에서는 단일 Network Load Balancer가 모든 트래픽 유형을 처리하여 SSH, HTTP 및 HTTPS를 Rail 노드로 직접 라우팅하는 더 간단한 NLB 전용 접근 방식을 설명합니다.

이 아키텍처를 위해 보안 그룹이 필요합니다:

1. **NLB Security Group**(`gitlab-nlb-sec-group`):
   - 인바운드: 모든 위치에서 TCP 포트 22(또는 SSH에 대한 신뢰할 수 있는 IP 범위로 제한)
   - 인바운드: 모든 위치에서 TCP 포트 80
   - 인바운드: 모든 위치에서 TCP 포트 443
   - 아웃바운드: 모든 트래픽

이 보안 그룹을 생성하려면:

1. EC2 대시보드에서 왼쪽 메뉴 모음의 **Security Groups**을 선택합니다.
1. **Create security group**을 선택합니다.
1. 설명적인 이름과 설명을 지정하고, **VPC** 드롭다운 목록에서 `gitlab-vpc`을 선택합니다.
1. 위에서 지정한 대로 인바운드 규칙을 추가합니다.
1. 완료되면 **Create security group**을 선택합니다.

대상 그룹을 생성합니다:

1. EC2 대시보드에서 왼쪽 메뉴 모음의 **Target Groups**을 선택합니다.
1. **Create target group**을 선택하여 **SSH Target Group**을 생성합니다:

   | 설정 | 값 |
   |---------|-------|
   | 대상 유형 | 인스턴스 |
   | 대상 그룹 이름 | `gitlab-nlb-ssh-target` |
   | 프로토콜 | TCP |
   | 포트 | 22 |
   | VPC | `gitlab-vpc` |
   | 상태 검사 프로토콜 | TCP |

   **다음**을 두 번 선택한 다음 **Create target group**을 선택합니다. 나중에 대상을 등록합니다.

1. **Create target group**을 다시 선택하여 **HTTP Target Group**을 생성합니다:

   | 설정 | 값 |
   |---------|-------|
   | 대상 유형 | 인스턴스 |
   | 대상 그룹 이름 | `gitlab-nlb-http-target` |
   | 프로토콜 | TCP |
   | 포트 | 80 |
   | VPC | `gitlab-vpc` |
   | 상태 검사 프로토콜 | HTTP |
   | 상태 검사 경로 | `/-/readiness` |

   > [!note]
   > [VPC IP 주소 범위(CIDR)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-security-groups.html)를 [IP 허용 목록](../../administration/monitoring/ip_allowlist.md)에 추가해야 하며, [상태 검사 엔드포인트](../../administration/monitoring/health_check.md)에 추가해야 합니다.

   **다음**을 선택하고, **Register Later**을 선택한 다음, **다음**을 두 번 선택하고 **Create target group**을 선택합니다.

Network Load Balancer를 생성합니다:

1. EC2 대시보드에서 왼쪽 네비게이션 막대의 **Load Balancers**를 찾고 **Create Load Balancer**을 선택합니다.
1. **Network Load Balancer**를 선택하고 **생성**을 선택합니다.
1. 다음 설정으로 로드 밸런서를 구성합니다:

   | 설정 | 값 |
   |---------|-------|
   | 로드 밸런서 이름 | `gitlab-nlb` |
   | 구성표 | 인터넷 연결 |
   | IP 주소 유형 | IPv4 |
   | VPC | `gitlab-vpc` |
   | 매핑 | 두 공개 서브넷 모두 선택 |
   | 보안 그룹 | `gitlab-nlb-sec-group` |

1. **Listeners and routing** 섹션에서 구성합니다:

   | 프로토콜 | 포트 | 대상 그룹 |
   |----------|------|--------------|
   | TCP | 22 | `gitlab-nlb-ssh-target` |
   | TCP | 80 | `gitlab-nlb-http-target` |
   | TLS | 443 | `gitlab-nlb-http-target` |

   포트 443의 TLS 리스너의 경우 **Security Policy** 설정 아래:
   - **정책 이름**: 드롭다운 목록에서 미리 정의된 보안 정책을 선택합니다. AWS 문서에서 [Network Load Balancer의 미리 정의된 SSL 보안 정책](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-tls-listener.html#describe-ssl-policies)을 참조하세요. GitLab 코드베이스에서 [지원되는 SSL 암호 및 프로토콜](https://gitlab.com/gitlab-org/gitlab/-/blob/9ee7ad433269b37251e0dd5b5e00a0f00d8126b4/lib/support/nginx/gitlab-ssl#L97-99)의 목록을 확인하세요.
   - **Default SSL/TLS server certificate**: ACM에서 SSL/TLS 인증서를 선택하거나 IAM에 인증서를 업로드합니다.

1. **Create load balancer**을 선택합니다.

> [!note]
> `gitlab-nlb-ssh-target`및 `gitlab-nlb-http-target` 대상 그룹의 대상은 이 가이드의 뒷부분에서 생성되는 [자동 크기 조정 그룹](#create-an-auto-scaling-group)에서 인스턴스가 시작될 때 자동으로 등록됩니다.

{{< /tab >}}

{{< tab title="Hybrid NLB->ALB 접근 방식" >}}

이 섹션에서는 Network Load Balancer가 SSH 트래픽을 처리하고 Application Load Balancer가 HTTP/HTTPS 트래픽을 처리하는 하이브리드 접근 방식을 설명합니다. NLB는 TCP 포트 22(SSH)를 Rail 노드로 직접 라우팅하고 TCP 포트 443(HTTPS)을 ALB로 라우팅하며, ALB는 SSL/TLS를 종료하고 HTTP 트래픽을 Rail 노드의 포트 80으로 라우팅합니다. 이 접근 방식은 AWS WAF 통합 및 관심 사항의 더 나은 분리를 가능하게 합니다.

이 아키텍처를 위해 세 개의 보안 그룹이 필요합니다:

1. **NLB Security Group**(`gitlab-nlb-sec-group`):
   - 인바운드: 모든 위치에서 TCP 포트 22(또는 SSH에 대한 신뢰할 수 있는 IP 범위로 제한)
   - 인바운드: 모든 위치에서 TCP 포트 443(또는 HTTPS에 대한 신뢰할 수 있는 IP 범위로 제한)
   - 아웃바운드: `gitlab-rails-sec-group`로 TCP 포트 22
   - 아웃바운드: `gitlab-alb-sec-group`로 TCP 포트 443

1. **ALB Security Group**(`gitlab-alb-sec-group`):
   - 인바운드: `gitlab-nlb-sec-group`에서 TCP 포트 443
   - 인바운드: `gitlab-rails-sec-group`에서 TCP 포트 80
   - 아웃바운드: `gitlab-rails-sec-group`로 TCP 포트 80

1. **Rails Security Group**(`gitlab-rails-sec-group`):
   - 인바운드: `gitlab-nlb-sec-group`에서 TCP 포트 22
   - 인바운드: `gitlab-alb-sec-group`에서 TCP 포트 80

이러한 보안 그룹을 생성하려면:

1. EC2 대시보드에서 왼쪽 메뉴 모음의 **Security Groups**을 선택합니다.
1. **Create security group**을 선택하여 **SSH Target Group**을 생성합니다:
1. 각각에 설명적인 이름과 설명을 지정하고, **VPC** 드롭다운 목록에서 `gitlab-vpc`을 선택합니다.
1. 위에서 지정한 대로 인바운드 규칙을 추가합니다. 소스를 선택할 때 **Security group**을 선택하고 드롭다운 목록에서 적절한 보안 그룹을 선택합니다.
1. 완료되면 **Create security group**을 선택합니다.

대상 그룹을 생성합니다:

1. EC2 대시보드에서 왼쪽 메뉴 모음의 **Target Groups**을 선택합니다.
1. 다음 설정으로 **NLB SSH Target Group**을 생성합니다:

   | 설정 | 값 |
   |---------|-------|
   | 대상 유형 | 인스턴스 |
   | 대상 그룹 이름 | `gitlab-nlb-ssh-target` |
   | 프로토콜 | TCP |
   | 포트 | 22 |
   | VPC | `gitlab-vpc` |
   | 상태 검사 프로토콜 | TCP |

   **다음**을 두 번 선택한 다음 **Create target group**을 선택합니다. 나중에 대상을 등록합니다.

1. **Create target group**을 다시 선택하여 **NLB to ALB Target Group**을 생성합니다:

   | 설정 | 값 |
   |---------|-------|
   | 대상 유형 | Application Load Balancer |
   | 대상 그룹 이름 | `gitlab-nlb-alb-target` |
   | 프로토콜 | TCP |
   | 포트 | 443 |
   | VPC | `gitlab-vpc` |
   | 상태 검사 프로토콜 | HTTPS |
   | 상태 검사 경로 | `/-/readiness` |

   **다음**을 선택하고, Application Load Balancer에 대해 **Register Later**을 선택한 다음, **다음**을 선택하고 **Create target group**을 선택합니다.

1. **Create target group**을 다시 선택하여 **ALB HTTP Target Group**을 생성합니다:

   | 설정 | 값 |
   |---------|-------|
   | 대상 유형 | 인스턴스 |
   | 대상 그룹 이름 | `gitlab-alb-http-target` |
   | 프로토콜 | HTTP |
   | 포트 | 80 |
   | VPC | `gitlab-vpc` |
   | 프로토콜 버전 | HTTP1.1 |
   | 상태 검사 프로토콜 | HTTP |
   | 상태 검사 경로 | `/-/readiness` |

   > [!note]
   > [VPC IP 주소 범위(CIDR)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-security-groups.html)를 [IP 허용 목록](../../administration/monitoring/ip_allowlist.md)에 추가해야 하며, [상태 검사 엔드포인트](../../administration/monitoring/health_check.md)에 추가해야 합니다.

   **다음**을 선택하고, **Register Later**을 선택한 다음, **다음**을 두 번 선택하고 **Create target group**을 선택합니다.

Application Load Balancer를 생성합니다:

1. EC2 대시보드에서 왼쪽 네비게이션 막대의 **Load Balancers**를 찾고 **Create Load Balancer**을 선택합니다.
1. **Application Load Balancer**를 선택하고 **생성**을 선택합니다.
1. 다음 설정으로 로드 밸런서를 구성합니다:

   | 설정 | 값 |
   |---------|-------|
   | 로드 밸런서 이름 | `gitlab-alb` |
   | 구성표 | 인터넷 연결 |
   | IP 주소 유형 | IPv4 |
   | VPC | `gitlab-vpc` |
   | 매핑 | 두 공개 서브넷 `gitlab-public-10.0.0.0`과 `gitlab-public-10.0.2.0` 모두 선택|
   | 보안 그룹 | `gitlab-alb-sec-group` |

1. **Listeners and routing** 섹션에서 구성합니다:

   | 프로토콜 | 포트 | 조치 | 대상 그룹 |
   |----------|------|--------|--------------|
   | HTTPS | 443 | 다음으로 전달 | `gitlab-alb-http-target` |

   HTTPS 리스너의 경우 ACM 인증서를 선택하고 적절한 보안 정책을 선택합니다([Application Load Balancer의 미리 정의된 SSL 보안 정책](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html) 참조).

1. **Create load balancer**을 선택합니다.

Network Load Balancer를 생성합니다:

1. EC2 대시보드에서 왼쪽 네비게이션 막대의 **Load Balancers**를 찾고 **Create Load Balancer**을 선택합니다.
1. **Network Load Balancer**를 선택하고 **생성**을 선택합니다.
1. 다음 설정으로 로드 밸런서를 구성합니다:

   | 설정 | 값 |
   |---------|-------|
   | 로드 밸런서 이름 | `gitlab-nlb` |
   | 구성표 | 인터넷 연결 |
   | IP 주소 유형 | IPv4 |
   | VPC | `gitlab-vpc` |
   | 매핑 | 두 공개 서브넷 `gitlab-public-10.0.0.0`과 `gitlab-public-10.0.2.0` 모두 선택|
   | 보안 그룹 | `gitlab-nlb-sec-group` |

1. **Listeners and routing** 섹션에서 구성합니다:

   | 프로토콜 | 포트 | 대상 그룹 |
   |----------|------|--------------|
   | TCP | 22 | `gitlab-nlb-ssh-target` |
   | TCP | 443 | `gitlab-nlb-alb-target` |

1. **Create load balancer**을 선택합니다.

ALB를 NLB의 대상으로 등록합니다:

1. EC2 대시보드에서 왼쪽 메뉴 모음의 **Target Groups**을 선택합니다.
1. `gitlab-nlb-alb-target` 대상 그룹을 선택합니다.
1. **Targets** 탭에서 **Register targets**을 선택합니다.
1. `gitlab-alb` Application Load Balancer를 선택하고 **Register pending targets**을 선택합니다.
1. **저장**을 선택합니다.

> [!note]
> `gitlab-nlb-ssh-target`및 `gitlab-alb-http-target` 대상 그룹의 대상은 이 가이드의 뒷부분에서 생성되는 [자동 크기 조정 그룹](#create-an-auto-scaling-group)에서 인스턴스가 시작될 때 자동으로 등록됩니다.

{{< /tab >}}

{{< /tabs >}}

NLB 로드 밸런서가 가동되고 실행되면 보안 그룹을 다시 방문하여 NLB를 통한 액세스만 제한하고 기타 요구 사항을 정제할 수 있습니다.

일부 속성은 로드 밸런서가 생성된 후에만 구성할 수 있습니다. 요구 사항에 따라 구성할 수 있는 몇 가지 기능은 다음과 같습니다:

- [클라이언트 IP 보존](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#client-ip-preservation)은 대상 그룹에 대해 기본적으로 활성화됩니다. 이를 통해 로드 밸런서에 연결된 클라이언트의 IP가 GitLab 애플리케이션에서 보존될 수 있습니다. 요구 사항에 따라 이를 활성화/비활성화할 수 있습니다.
- [프록시 프로토콜](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#proxy-protocol)은 대상 그룹에 대해 기본적으로 비활성화됩니다. 이를 통해 로드 밸런서가 프록시 프로토콜 헤더의 추가 정보를 보낼 수 있습니다. 이를 활성화하려면 내부 로드 밸런서, NGINX 등과 같은 기타 환경 구성 요소도 구성되어 있는지 확인합니다. 이 POC의 경우 [나중에 GitLab 노드](#proxy-protocol)에서만 활성화하면 됩니다.

### 로드 밸런서의 DNS 구성 {#configure-dns-for-load-balancer}

Route 53 대시보드에서 왼쪽 네비게이션 모음의 **Hosted zones**을 선택합니다:

1. 기존 호스팅된 영역을 선택하거나, 도메인에 대해 아직 호스팅된 영역이 없으면 **Create Hosted Zone**을 선택하고, 도메인 이름을 입력한 다음 **생성**을 선택합니다.
1. **Create record**을 선택하고 다음 값을 제공합니다:
   1. **Name (이름)**: 도메인 이름(기본값) 또는 서브도메인을 사용합니다.
   1. **유형**: **A - IPv4 address**를 선택합니다.
   1. **Alias**: **비활성화됨**으로 기본값이 설정됩니다. 이 옵션을 활성화합니다.
   1. **Route traffic to**: **Alias to Network Load Balancer**을 선택합니다.
   1. **지역**: Network Load Balancer가 있는 지역을 선택합니다.
   1. **Choose network load balancer**: 이전에 생성한 Network Load Balancer를 선택합니다.
   1. **Routing Policy**: **Simple**을 사용하지만, 사용 사례에 따라 다른 정책을 선택할 수 있습니다.
   1. **Evaluate Target Health**: 이를 **아니오**로 설정하지만, 로드 밸런서가 대상 상태에 따라 트래픽을 라우팅하도록 선택할 수 있습니다.
   1. **생성**을 선택합니다.
1. Route 53을 통해 도메인을 등록했으면 완료되었습니다. 다른 도메인 등록자를 사용했으면 도메인 등록자로 DNS 레코드를 업데이트해야 합니다. 다음을 수행해야 합니다:
   1. **Hosted zones**을 선택하고 이전에 추가한 도메인을 선택합니다.
   1. `NS` 레코드의 목록이 표시됩니다. 도메인 등록자의 관리자 패널에서 이러한 각각을 `NS` 레코드로 도메인의 DNS 레코드에 추가합니다. 이러한 단계는 도메인 등록자에 따라 다를 수 있습니다. 막히면 Google **"name of your registrar" add DNS records**를 검색하면 도메인 등록자에만 해당하는 도움말 문서를 찾을 수 있습니다.

이를 수행하는 단계는 사용하는 등록자에 따라 다르며 이 가이드의 범위를 벗어납니다.

## RDS를 사용하는 PostgreSQL {#postgresql-with-rds}

데이터베이스 서버의 경우 중복성을 위해 Multi AZ를 제공하는 PostgreSQL용 Amazon RDS를 사용합니다([Aurora는 지원되지 않습니다](https://gitlab.com/gitlab-partners-public/aws/aws-known-issues/-/issues/10)). 먼저 보안 그룹과 서브넷 그룹을 생성한 다음 실제 RDS 인스턴스를 생성합니다.

### RDS 보안 그룹 {#rds-security-group}

나중에 `gitlab-nlb-sec-group` 인스턴스에 배포할 인스턴스에서 인바운드 트래픽을 허용하는 데이터베이스용 보안 그룹이 필요합니다:

1. EC2 대시보드에서 왼쪽 메뉴 모음의 **Security Groups**을 선택합니다.
1. **Create security group**을 선택합니다.
1. 이름을 지정하고(저희는 `gitlab-rds-sec-group`을 사용), 설명을 지정한 다음, **VPC** 드롭다운 목록에서 `gitlab-vpc`을 선택합니다.
1. **Inbound rules** 섹션에서 **규칙 추가**를 선택하고 다음을 설정합니다:
   1. **유형**: **PostgreSQL** 규칙을 검색하여 선택합니다.
   1. **Source type**: "Custom"으로 설정합니다.
   1. **소스**: 로드 밸런서 접근 방식에 따라 적절한 보안 그룹을 선택합니다:
      - **NLB only**: `gitlab-nlb-sec-group`
      - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`
1. 완료되면 **Create security group**을 선택합니다.

### RDS 서브넷 그룹 {#rds-subnet-group}

1. RDS 대시보드로 이동하고 왼쪽 메뉴에서 **Subnet Groups**을 선택합니다.
1. **Create DB Subnet Group**을 선택합니다.
1. **Subnet group details** 아래에서 이름을 입력하고(저희는 `gitlab-rds-group`을 사용), 설명을 지정한 다음, VPC 드롭다운 목록에서 `gitlab-vpc`을 선택합니다.
1. **Availability Zones** 드롭다운 목록에서 구성한 서브넷을 포함하는 가용 영역을 선택합니다. 우리의 경우 `us-west-2a`과 `us-west-2b`을 추가합니다.
1. **Subnets** 드롭다운 목록에서 [서브넷 섹션](#subnets)에서 정의한 두 개의 비공개 서브넷(`10.0.1.0/24` 및 `10.0.3.0/24`)을 선택합니다.
1. 준비되면 **생성**을 선택합니다.

### 데이터베이스 생성 {#create-the-database}

> [!warning]
> 데이터베이스에 버스트 가능한 인스턴스(t 클래스 인스턴스)를 사용하지 마세요. 지속된 높은 로드 기간 동안 CPU 크레딧이 부족해지면 성능 문제가 발생할 수 있기 때문입니다.

이제 데이터베이스를 생성할 시간입니다:

1. RDS 대시보드로 이동하여 왼쪽 메뉴에서 **데이터베이스**를 선택한 다음, **데이터베이스 생성**을 선택합니다.
1. 데이터베이스 생성 방법으로 **Standard Create**을 선택합니다.
1. 데이터베이스 엔진으로 **PostgreSQL**을 선택하고 GitLab 버전에 대해 당사 [데이터베이스 요구 사항](../requirements.md#postgresql)에서 정의한 최소 PostgreSQL 버전을 선택합니다.
1. 이것이 프로덕션 서버이므로 **텝플릿** 섹션에서 **프로덕션**을 선택합니다.
1. **Availability & durability** 아래에서 **Multi-AZ DB instance**를 선택하여 다른 [가용 영역](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)에서 프로비저닝된 대기 RDS 인스턴스를 갖습니다.
1. **설정** 아래에서 다음을 사용합니다:
   - DB 인스턴스 식별자에 `gitlab-db-ha`을 사용합니다.
   - 마스터 사용자 이름으로 `gitlab`을 사용합니다.
   - 마스터 비밀번호로 매우 안전한 비밀번호를 사용합니다.

   나중에 필요하므로 이들을 기록해 두세요.

1. DB 인스턴스 크기의 경우 **Standard classes**를 선택하고 드롭다운 목록에서 요구 사항을 충족하는 인스턴스 크기를 선택합니다. 저희는 `db.m5.large` 인스턴스를 사용합니다.
1. **스토리지** 아래에서 다음을 구성합니다:
   1. 스토리지 유형 드롭다운 목록에서 **Provisioned IOPS (SSD)**를 선택합니다. 프로비저닝된 IOPS(SSD) 저장소가 이 용도에 가장 적합합니다(비용을 줄이기 위해 범용(SSD)을 선택할 수 있음). [Amazon RDS 저장소](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html)에 대해 자세히 읽어보세요.
   1. 저장소를 할당하고 프로비저닝된 IOPS를 설정합니다. 저희는 최소값 `100`과 `1000`을 사용합니다.
   1. 저장소 자동 크기 조정(선택 사항)을 활성화하고 최대 저장소 임계값을 설정합니다.
1. **Connectivity** 아래에서 다음을 구성합니다:
   1. **Virtual Private Cloud (VPC)** 드롭다운 목록에서 이전에 생성한 VPC(`gitlab-vpc`)를 선택합니다.
   1. **DB subnet group** 아래에서 이전에 생성한 서브넷 그룹(`gitlab-rds-group`)을 선택합니다.
   1. 공개 액세스를 **아니오**로 설정합니다.
   1. **VPC security group** 아래에서 **Choose existing**을 선택하고 드롭다운 목록에서 이전에 생성한 `gitlab-rds-sec-group`을 선택합니다.
   1. **추가 구성** 아래에서 데이터베이스 포트를 기본값 `5432`으로 유지합니다.
1. **Database authentication**의 경우 **Password authentication**을 선택합니다.
1. **추가 구성** 섹션을 확장하고 다음을 완료합니다:
   1. 초기 데이터베이스 이름입니다. 저희는 `gitlabhq_production`을 사용합니다.
   1. 선호하는 백업 설정을 구성합니다.
   1. 여기에서 유일한 다른 변경은 **Maintenance**에서 자동 부 버전 업데이트를 비활성화하는 것입니다.
   1. 다른 모든 설정을 그대로 두거나 필요에 따라 조정하세요.
   1. 만족하면 **데이터베이스 생성**을 선택합니다.

이제 데이터베이스가 생성되었으므로 ElastiCache로 Redis 설정으로 이동합니다.

## ElastiCache를 사용하는 Redis {#redis-with-elasticache}

ElastiCache는 메모리 내 호스팅 캐싱 솔루션입니다. Redis는 자체 지속성을 유지하며 GitLab 애플리케이션의 세션 데이터, 임시 캐시 정보 및 백그라운드 작업 큐를 저장하는 데 사용됩니다.

### Redis 보안 그룹 생성 {#create-a-redis-security-group}

1. EC2 대시보드로 이동합니다.
1. 왼쪽 메뉴에서 **Security Groups**을 선택합니다.
1. **Create security group**을 선택하고 세부 사항을 입력합니다. 이름을 지정하고(저희는 `gitlab-redis-sec-group`을 사용), 설명을 추가하고, 이전에 생성한 VPC(`gitlab-vpc`)를 선택합니다.
1. **Inbound rules** 섹션에서 **규칙 추가**를 선택하고 **Custom TCP** 규칙을 추가한 다음, 포트 `6379`을 설정하고, 로드 밸런서 접근 방식에 따라 "Custom" 소스를 설정합니다:
   - **NLB only**: `gitlab-nlb-sec-group`
   - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`
1. 완료되면 **Create security group**을 선택합니다.

### Redis 서브넷 그룹 {#redis-subnet-group}

1. AWS 콘솔에서 ElastiCache 대시보드로 이동합니다.
1. 왼쪽 메뉴의 **Subnet Groups**으로 이동하고 새 서브넷 그룹을 생성합니다(저희는 `gitlab-redis-group`로 이름을 지정함). 이전에 생성한 VPC(`gitlab-vpc`)를 선택하고 선택된 서브넷 테이블에 [비공개 서브넷](#subnets)만 포함되는지 확인합니다.
1. 준비되면 **생성**을 선택합니다.

   ![GitLab Redis 그룹을 위한 서브넷 그룹을 생성합니다.](img/ec_subnet_v17_0.png)

### Redis 클러스터 생성 {#create-the-redis-cluster}

1. ElastiCache 대시보드로 돌아갑니다.
1. 왼쪽 메뉴에서 **Redis caches**를 선택하고 **Create Redis cache**을 선택하여 새 Redis 클러스터를 생성합니다.
1. **Deployment option** 아래에서 **Design your own cache**를 선택합니다.
1. **Creation method** 아래에서 **Cluster cache**를 선택합니다.
1. **Cluster mode** 아래에서 **비활성화됨**을 선택합니다. [지원되지 않기](../../administration/redis/replication_and_failover_external.md#requirements) 때문입니다. 클러스터 모드가 없어도 여전히 여러 가용 영역에서 Redis를 배포할 수 있습니다.
1. **Cluster info** 아래에서 클러스터의 이름(`gitlab-redis`)과 설명을 지정합니다.
1. **위치** 아래에서 **AWS Cloud**를 선택하고 **Multi-AZ** 옵션을 활성화합니다.
1. 클러스터 설정 섹션:
   1. 엔진 버전의 경우 당사 [Redis 요구 사항](../requirements.md#redis-or-valkey)에서 GitLab 버전에 대해 정의한 Redis 버전을 선택합니다.
   1. 포트를 Redis 보안 그룹에서 이전에 사용한 포트인 `6379`으로 유지합니다.
   1. 노드 유형을 선택합니다(최소 `cache.t3.medium`, 필요에 따라 조정) 및 복제본 수를 선택합니다.
1. 연결성 설정 섹션:
   1. **Network type**: IPv4
   1. **Subnet groups**: **Choose existing subnet group**을 선택하고 이전에 생성한 `gitlab-redis-group`을 선택합니다.
1. 가용 영역 배치 섹션에서:
   1. 선호하는 가용 영역을 수동으로 선택하고 "Replica 2"에서 다른 영역을 선택합니다.

      ![Redis 그룹의 가용 영역을 선택합니다.](img/ec_az_v17_0.png)

1. **다음**을 선택합니다.
1. 보안 설정에서 보안 그룹을 편집하고 이전에 생성한 `gitlab-redis-sec-group`을 선택합니다. **다음**을 선택합니다.
1. 나머지 설정을 기본값으로 두거나 원하는 대로 편집합니다.
1. 완료하면 **생성**을 선택합니다.

## Bastion 호스트 설정 {#setting-up-bastion-hosts}

GitLab 인스턴스가 프라이빗 서브넷에 있으므로 구성 변경 및 업그레이드를 포함한 작업에 대해 SSH를 사용하여 이러한 인스턴스에 연결할 수 있는 방법이 필요합니다. 이를 수행하는 한 가지 방법은 [bastion 호스트](https://en.wikipedia.org/wiki/Bastion_host)를 사용하는 것이며, 이를 jump box라고도 합니다.

> [!note]
> bastion 호스트를 유지 관리하고 싶지 않으면 [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)를 설정하여 인스턴스에 액세스할 수 있습니다. 이는 이 문서의 범위를 벗어납니다.

### Bastion 호스트 A 생성 {#create-bastion-host-a}

1. EC2 대시보드로 이동하고 **Launch instance**을 선택합니다.
1. **Name and tags** 섹션에서 **이름**을 `Bastion Host A`으로 설정합니다.
1. 최신 **Ubuntu Server LTS (HVM)** AMI를 선택합니다. [지원되는 최신 OS 버전](../package/_index.md)에 대한 GitLab 문서를 확인합니다.
1. 인스턴스 유형을 선택합니다. bastion 호스트를 사용하여 다른 인스턴스로만 SSH를 수행하므로 `t2.micro`을 사용합니다.
1. **Key pair** 섹션에서 **Create new key pair**을 선택합니다.
   1. 키 페어에 이름을 지정하고(저희는 `bastion-host-a`을 사용함) `bastion-host-a.pem` 파일을 나중에 사용할 수 있도록 저장합니다.
1. 네트워크 설정 섹션을 편집합니다:
   1. **VPC**에서 드롭다운 목록의 `gitlab-vpc`을 선택합니다.
   1. **Subnet**에서 이전에 생성한 퍼블릭 서브넷(`gitlab-public-10.0.0.0`)을 선택합니다.
   1. **Auto-assign Public IP** 아래에서 **비활성화됨**이 선택되어 있는지 확인합니다. [Elastic IP 주소](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)는 [다음 섹션](#assign-elastic-ip-to-the-bastion-host-a)에서 나중에 호스트에 할당됩니다.
   1. **Firewall**에서 **Create security group**을 선택하고, **Security group name**을 입력하고(저희는 `bastion-sec-group`을 사용함) 설명을 추가합니다.
   1. SSH 액세스를 어디서나 활성화합니다(`0.0.0.0/0`). 더 엄격한 보안을 원하면 단일 IP 주소 또는 CIDR 표기법의 IP 주소 범위를 지정합니다.
1. 스토리지의 경우 모든 기본값을 유지하고 8GB 루트 볼륨만 추가합니다. 이 인스턴스에는 아무것도 저장하지 않습니다.
1. 모든 설정을 검토하고 만족하면 **Launch Instance**을 선택합니다.

#### Bastion 호스트 A에 Elastic IP 할당 {#assign-elastic-ip-to-the-bastion-host-a}

1. EC2 대시보드로 이동하고 **Network & Security**을 선택합니다.
1. **Elastic IPs**를 선택하고 `Network border group`을 `us-west-2`으로 설정합니다.
1. **Allocate**을 선택합니다.
1. 생성된 Elastic IP 주소를 선택합니다.
1. **조치**를 선택하고 **Associate Elastic IP address**을 선택합니다.
1. **Resource Type**에서 **인스턴스**를 선택하고 **인스턴스** 드롭다운 목록에서 `Bastion Host A` 호스트를 선택합니다.
1. **Associate**을 선택합니다.

#### 인스턴스에 SSH로 연결할 수 있는지 확인 {#confirm-that-you-can-ssh-into-the-instance}

1. EC2 대시보드에서 왼쪽 메뉴의 **인스턴스**를 선택합니다.
1. 인스턴스 목록에서 **Bastion Host A**를 선택합니다.
1. **연결**을 선택하고 연결 지시를 따릅니다.
1. 성공적으로 연결할 수 있으면 중복성을 위해 두 번째 bastion 호스트 설정으로 진행합니다.

### Bastion 호스트 B 생성 {#create-bastion-host-b}

1. 이전에 사용한 동일한 단계를 따르되 다음과 같이 변경하여 EC2 인스턴스를 생성합니다:
   1. **Subnet**에서 이전에 생성한 두 번째 퍼블릭 서브넷(`gitlab-public-10.0.2.0`)을 선택합니다.
   1. **Add Tags** 섹션에서 `Key: Name`과 `Value: Bastion Host B`을 설정하여 두 인스턴스를 식별할 수 있습니다.
   1. 보안 그룹의 경우 이전에 생성한 기존 `bastion-sec-group`을 선택합니다.

### SSH 에이전트 포워딩 사용 {#use-ssh-agent-forwarding}

Linux를 실행하는 EC2 인스턴스는 SSH 인증을 위해 프라이빗 키 파일을 사용합니다. SSH 클라이언트와 클라이언트에 저장된 프라이빗 키 파일을 사용하여 bastion 호스트에 연결합니다. 프라이빗 키 파일이 bastion 호스트에 없으므로 프라이빗 서브넷의 인스턴스에 연결할 수 없습니다.

bastion 호스트에 프라이빗 키 파일을 저장하는 것은 좋은 아이디어가 아닙니다. 이를 해결하려면 클라이언트에서 SSH 에이전트 포워딩을 사용하세요.

예를 들어 명령줄 `ssh` 클라이언트는 `-A` 스위치로 에이전트 포워딩을 사용하며, 다음과 같습니다:

```shell
ssh -A user@<bastion-public-IP-address>
```

다른 클라이언트에 대해 SSH 에이전트 포워딩을 사용하는 방법에 대한 단계별 가이드는 [프라이빗 Amazon VPC에서 Linux 인스턴스에 안전하게 연결](https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/)을 참조하세요.

## GitLab 설치 및 사용자 지정 AMI 생성 {#install-gitlab-and-create-custom-ami}

나중에 시작 구성에 사용할 사전 구성된 사용자 지정 GitLab AMI가 필요합니다. 시작점으로 공식 GitLab AMI를 사용하여 GitLab 인스턴스를 생성합니다. 그런 다음 PostgreSQL, Redis 및 Gitaly에 대한 사용자 지정 구성을 추가합니다. 공식 GitLab AMI를 사용하는 대신 선택한 EC2 인스턴스를 시작하고 [GitLab을 수동으로 설치](https://about.gitlab.com/install/)할 수도 있습니다.

### GitLab 설치 {#install-gitlab}

EC2 대시보드에서:

1. [AWS에서 공식 GitLab 생성 AMI ID 찾기](#find-official-gitlab-created-ami-ids-on-aws)라는 다음 섹션을 사용하여 올바른 AMI를 찾고 **Launch**을 선택합니다.
1. **Name and tags** 섹션에서 **이름**을 `GitLab`으로 설정합니다.
1. **Instance type** 드롭다운 목록에서 워크로드를 기반으로 인스턴스 유형을 선택합니다. [하드웨어 요구 사항](../requirements.md)을 확인하여 요구 사항에 맞는 인스턴스를 선택하세요(최소 `c5.2xlarge`, 100명의 사용자를 수용하기에 충분함).
1. **Key pair** 섹션에서 **Create new key pair**을 선택합니다.
   1. 키 페어에 이름을 지정하고(저희는 `gitlab`을 사용함) `gitlab.pem` 파일을 나중에 사용할 수 있도록 저장합니다.
1. **Network settings** 섹션에서:
   1. **VPC**: `gitlab-vpc`을 선택합니다. 이것은 이전에 생성한 VPC입니다.
   1. **Subnet**: 이전에 생성한 서브넷 목록에서 `gitlab-private-10.0.1.0`을 선택합니다.
   1. **Auto-assign Public IP**: `Disable`을 선택합니다.
   1. **Firewall**: **Select existing security group**을 선택하고 로드 밸런서 방식에 따라 적절한 보안 그룹을 선택합니다:
      - **NLB only**: `gitlab-nlb-sec-group`과 `bastion-sec-group`
      - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`과 `bastion-sec-group`

      `bastion-sec-group`은 [SSH 에이전트 포워딩](#use-ssh-agent-forwarding)을 사용하여 bastion 호스트에서 관리 및 구성 작업을 위한 SSH 액세스를 허용합니다.
1. 스토리지의 경우 루트 볼륨은 기본적으로 8GiB이며 아무 데이터도 저장하지 않으므로 충분해야 합니다.
1. 모든 설정을 검토하고 만족하면 **Launch Instance**을 선택합니다.

### 사용자 지정 구성 추가 {#add-custom-configuration}

**Bastion Host A**를 통해 [SSH 에이전트 포워딩](#use-ssh-agent-forwarding)을 사용하여 GitLab 인스턴스에 연결합니다. 연결되면 다음 사용자 지정 구성을 추가합니다:

#### Let's Encrypt 비활성화 {#disable-lets-encrypt}

로드 밸런서에서 SSL 인증서를 추가하므로 Let's Encrypt에 대한 GitLab 기본 제공 지원이 필요하지 않습니다. Let's Encrypt는 `https` 도메인을 사용할 때 [기본적으로 활성화](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration)되므로 명시적으로 비활성화해야 합니다:

1. `/etc/gitlab/gitlab.rb`을 열고 비활성화합니다:

   ```ruby
   letsencrypt['enable'] = false
   ```

1. 파일을 저장하고 변경 사항을 적용하도록 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

#### PostgreSQL에 필요한 확장 설치 {#install-the-required-extensions-for-postgresql}

> [!note]
> `gitlab` 사용자가 [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles) 역할을 가지고 있으면 GitLab이 필요한 확장을 자동으로 설치할 수 있습니다. 그 경우 아래의 수동 단계는 필요하지 않습니다.

GitLab 인스턴스에서 RDS 인스턴스에 연결하여 액세스를 확인하고 [필수 PostgreSQL 확장](../../administration/postgresql/extensions.md)을 설치합니다.

호스트 또는 엔드포인트를 찾으려면 **Amazon RDS** > **데이터베이스**로 이동하여 이전에 생성한 데이터베이스를 선택합니다. **Connectivity & security** 탭에서 엔드포인트를 찾습니다.

`-h`의 경우 RDS 엔드포인트 호스트명만 사용합니다. 뒤의 콜론과 포트 번호는 생략하세요:

```shell
sudo /opt/gitlab/embedded/bin/psql -U gitlab -h <rds-endpoint> -d gitlabhq_production
```

그런 다음 `CREATE EXTENSION`을 사용하여 각 [필수 확장](../../administration/postgresql/extensions.md)을 설치합니다:

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS ...;
```

`\dx`로 설치된 확장을 확인합니다.

#### PostgreSQL 및 Redis에 연결하도록 GitLab 구성 {#configure-gitlab-to-connect-to-postgresql-and-redis}

1. `/etc/gitlab/gitlab.rb`을 편집하고 `external_url 'http://<domain>'` 옵션을 찾아 사용 중인 `https` 도메인으로 변경합니다.

1. GitLab 데이터베이스 설정을 찾아 필요에 따라 주석을 제거합니다. 현재의 경우 데이터베이스 어댑터, 인코딩, 호스트, 이름, 사용자 이름 및 암호를 지정합니다:

   ```ruby
   # Disable the built-in Postgres
    postgresql['enable'] = false

   # Fill in the connection details
   gitlab_rails['db_adapter'] = "postgresql"
   gitlab_rails['db_encoding'] = "unicode"
   gitlab_rails['db_database'] = "gitlabhq_production"
   gitlab_rails['db_username'] = "gitlab"
   gitlab_rails['db_password'] = "mypassword"
   gitlab_rails['db_host'] = "<rds-endpoint>"
   ```

1. 다음으로 호스트를 추가하고 포트의 주석을 제거하여 Redis 섹션을 구성해야 합니다:

   ```ruby
   # Disable the built-in Redis
   redis['enable'] = false

   # Fill in the connection details
   gitlab_rails['redis_host'] = "<redis-endpoint>"
   gitlab_rails['redis_port'] = 6379

   # Adjust based on your Redis setting
   gitlab_rails['redis_ssl'] = true
   ```

1. 마지막으로 변경 사항을 적용하도록 GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 확인을 실행하고 서비스 상태를 확인하여 모든 것이 올바르게 설정되었는지 확인할 수도 있습니다:

   ```shell
   sudo gitlab-rake gitlab:check
   sudo gitlab-ctl status
   ```

#### Gitaly 설정 {#set-up-gitaly}

> [!warning]
> 이 아키텍처에서는 단일 Gitaly 서버가 단일 장애점을 만듭니다. 이 제한을 제거하려면 [Gitaly Cluster (Praefect)](../../administration/gitaly/praefect/_index.md)를 사용하세요.

Gitaly는 Git 리포지토리에 대한 높은 수준의 RPC 액세스를 제공하는 서비스입니다. 이전에 구성한 [프라이빗 서브넷](#subnets) 중 하나의 별도 EC2 인스턴스에서 활성화하고 구성해야 합니다.

Gitaly를 설치할 EC2 인스턴스를 생성하겠습니다:

1. EC2 대시보드에서 **Launch instance**을 선택합니다.
1. **Name and tags** 섹션에서 **이름**을 `Gitaly`으로 설정합니다.
1. AMI를 선택합니다. 이 예에서는 최신 **Ubuntu Server LTS (HVM), SSD Volume Type**을 선택합니다. [지원되는 최신 OS 버전](../package/_index.md)에 대한 GitLab 문서를 확인합니다.
1. 인스턴스 유형을 선택합니다. `m5.xlarge`을 선택합니다.
1. **Key pair** 섹션에서 **Create new key pair**을 선택합니다.
   1. 키 페어에 이름을 지정하고(저희는 `gitaly`을 사용함) `gitaly.pem` 파일을 나중에 사용할 수 있도록 저장합니다.
1. 네트워크 설정 섹션에서:
   1. **VPC**에서 드롭다운 목록의 `gitlab-vpc`을 선택합니다.
   1. **Subnet**에서 이전에 생성한 프라이빗 서브넷(`gitlab-private-10.0.1.0`)을 선택합니다.
   1. **Auto-assign Public IP** 아래에서 **사용 안 함**이 선택되어 있는지 확인합니다.
   1. **Firewall**에서 **Create security group**을 선택하고, **Security group name**을 입력하고(저희는 `gitlab-gitaly-sec-group`을 사용함) 설명을 추가합니다.
      1. **Custom TCP** 규칙을 생성하고 `8075`을 **Port Range**에 추가합니다. **소스**의 경우 로드 밸런서 방식에 따라 적절한 보안 그룹을 선택합니다:
         - **NLB only**: `gitlab-nlb-sec-group`
         - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`
      1. 또한 `bastion-sec-group`에서 SSH에 대한 인바운드 규칙을 추가하여 Bastion 호스트에서 [SSH 에이전트 포워딩](#use-ssh-agent-forwarding)을 사용하여 연결할 수 있도록 합니다.
1. 루트 볼륨 크기를 `20 GiB`로 늘리고 **Volume Type**을 `Provisioned IOPS SSD (io1)`으로 변경합니다. (볼륨 크기는 임의의 값입니다. 리포지토리 스토리지 요구 사항에 충분한 볼륨을 생성합니다.)
   1. **IOPS**에 `1000`를 설정합니다(20GiB x 50 IOPS). GiB당 최대 50 IOPS까지 프로비저닝할 수 있습니다. 더 큰 볼륨을 선택하면 IOPS를 그에 따라 늘립니다. `git`과 같은 직렬화된 방식으로 많은 작은 파일이 기록되는 워크로드에는 성능 있는 스토리지가 필요하므로 `Provisioned IOPS SSD (io1)`을 선택합니다.
1. 모든 설정을 검토하고 만족하면 **Launch Instance**을 선택합니다.

> [!note]
> 루트 볼륨에 구성 및 리포지토리 데이터를 저장하는 대신 리포지토리 스토리지를 위해 추가 EBS 볼륨을 추가하도록 선택할 수도 있습니다. 이전에 언급한 동일한 지침을 따릅니다. [Amazon EBS 가격 책정 페이지](https://aws.amazon.com/ebs/pricing/)를 참조하세요.

EC2 인스턴스가 준비되었으므로 [GitLab을 설치하고 자체 서버에서 Gitaly를 설정하는 설명서](../../administration/gitaly/configure_gitaly.md#run-gitaly-on-its-own-server)를 따릅니다. 해당 문서의 클라이언트 설정 단계를 이전에 생성한 [GitLab 인스턴스](#install-gitlab)에서 수행합니다.

##### Elastic File System (EFS) {#elastic-file-system-efs}

> [!warning]
> EFS 사용을 권장하지 않습니다. GitLab의 성능에 부정적인 영향을 미칠 수 있기 때문입니다. 자세한 내용은 [클라우드 기반 파일 시스템 피하기에 대한 설명서](../../administration/nfs.md#avoid-using-cloud-based-file-systems)를 참조하세요.

EFS를 사용하기로 결정한 경우 [PosixUser](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-accesspoint.html#cfn-efs-accesspoint-posixuser) 속성이 생략되거나 Gitaly가 설치된 시스템의 `git` 사용자의 UID 및 GID로 올바르게 지정되는지 확인합니다. UID와 GID는 다음 명령으로 검색할 수 있습니다:

```shell
# UID
id -u git

# GID
id -g git
```

또한 여러 [액세스 포인트](https://docs.aws.amazon.com/efs/latest/ug/efs-access-points.html)를 구성해서는 안 됩니다. 특히 다른 자격 증명을 지정하는 경우에는 더욱 그렇습니다. Gitaly 이외의 애플리케이션은 Gitaly가 올바르게 작동하는 것을 방지하는 방식으로 Gitaly 스토리지 디렉토리의 권한을 조작할 수 있습니다. 이 이슈의 예는 [`omnibus-gitlab` 이슈 8893](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8893)을 참조하세요.

#### 프록시된 SSL에 대한 지원 추가 {#add-support-for-proxied-ssl}

[로드 밸런서](#load-balancer)에서 SSL을 종료하므로 [프록시된 SSL 지원](https://docs.gitlab.com/omnibus/settings/ssl/#configure-a-reverse-proxy-or-load-balancer-ssl-termination)의 단계를 따라 `/etc/gitlab/gitlab.rb`에서 이를 구성합니다.

`sudo gitlab-ctl reconfigure`을 실행한 후 `gitlab.rb` 파일에 대한 변경 사항을 저장하는 것을 잊지 마세요.

#### 인증된 SSH 키의 빠른 조회 {#fast-lookup-of-authorized-ssh-keys}

GitLab에 액세스할 수 있는 사용자의 공개 SSH 키는 `/var/opt/gitlab/.ssh/authorized_keys`에 저장됩니다. 일반적으로 공유 스토리지를 사용하여 모든 인스턴스가 사용자가 SSH를 통해 Git 작업을 수행할 때 이 파일에 액세스할 수 있도록 합니다. 설정에 공유 스토리지가 없으므로 구성을 업데이트하여 GitLab 데이터베이스의 인덱싱된 조회를 통해 SSH 사용자를 인증합니다.

[빠른 SSH 키 조회 설정](../../administration/operations/fast_ssh_key_lookup.md#set-up-fast-lookup)의 지침을 따라 `authorized_keys` 파일 사용에서 데이터베이스로 전환합니다.

빠른 조회를 구성하지 않으면 SSH를 통한 Git 작업 시 다음 오류가 발생합니다:

```shell
Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

#### 호스트 키 구성 {#configure-host-keys}

일반적으로 기본 애플리케이션 서버의 `/etc/ssh/`의 내용(기본 및 공개 키)을 모든 보조 서버의 `/etc/ssh`에 수동으로 복사합니다. 이는 로드 밸런서 뒤의 클러스터에서 서버에 액세스할 때 거짓 중간자 공격 경고를 방지합니다.

사용자 지정 AMI의 일부로 정적 호스트 키를 생성하여 이를 자동화합니다. 이러한 호스트 키는 EC2 인스턴스가 부팅될 때마다 회전하므로 사용자 지정 AMI에 "하드 코딩"하는 것이 해결책으로 사용됩니다.

GitLab 인스턴스에서 다음을 실행합니다:

```shell
sudo mkdir /etc/ssh_static
sudo cp -R /etc/ssh/* /etc/ssh_static
```

`/etc/ssh/sshd_config`에서 다음을 업데이트합니다:

```shell
# HostKeys for protocol version 2
HostKey /etc/ssh_static/ssh_host_rsa_key
HostKey /etc/ssh_static/ssh_host_dsa_key
HostKey /etc/ssh_static/ssh_host_ecdsa_key
HostKey /etc/ssh_static/ssh_host_ed25519_key
```

#### Amazon S3 오브젝트 스토리지 {#amazon-s3-object-storage}

공유 스토리지에 NFS를 사용하지 않으므로 [Amazon S3](https://aws.amazon.com/s3/) 버킷을 사용하여 백업, 아티팩트, LFS 객체, 업로드, 머지 리퀘스트 diff, 컨테이너 레지스트리 이미지 등을 저장합니다. 당사 설명서에는 이러한 각 데이터 유형에 대한 [오브젝트 스토리지 구성 방법에 대한 지침](../../administration/object_storage.md)과 GitLab에서 오브젝트 스토리지 사용에 대한 기타 정보가 포함되어 있습니다.

> [!note]
> 이전에 생성한 [AWS IAM 프로필](#create-an-iam-role)을 사용하고 있으므로 오브젝트 스토리지를 구성할 때 AWS 액세스 키 및 비밀 액세스 키/값 쌍을 생략해야 합니다. 대신 구성에서 `'use_iam_profile' => true`을 사용하세요. 이는 이전에 연결된 오브젝트 스토리지 설명서에 표시되어 있습니다.
>
> S3 액세스에 IAM 역할을 사용할 때 GitLab은 IMDSv1과 IMDSv2를 모두 지원하며 사용 가능할 때 자동으로 IMDSv2를 사용합니다.

`sudo gitlab-ctl reconfigure`을 실행한 후 `gitlab.rb` 파일에 대한 변경 사항을 저장하는 것을 잊지 마세요.

---

이로써 GitLab 인스턴스의 구성 변경이 완료되었습니다. 다음으로 이 인스턴스를 기반으로 사용자 지정 AMI를 생성하여 시작 구성 및 자동 크기 조정 그룹에 사용합니다.

### IP 허용 목록 {#ip-allowlist}

이전에 생성한 `gitlab-vpc`의 [VPC IP 주소 범위(CIDR)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-security-groups.html)를 [IP 허용 목록](../../administration/monitoring/ip_allowlist.md)에 추가하여 [상태 확인 엔드포인트](../../administration/monitoring/health_check.md)에 추가해야 합니다

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '10.0.0.0/16']
   ```

1. GitLab을 재구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 프록시 프로토콜 {#proxy-protocol}

이전에 생성한 [로드 밸런서](#load-balancer)에서 프록시 프로토콜이 활성화된 경우 `gitlab.rb` 파일에서 이를 [활성화](https://docs.gitlab.com/omnibus/settings/nginx/#configuring-the-proxy-protocol)해야 합니다.

1. `/etc/gitlab/gitlab.rb`을 편집합니다.

   ```ruby
   nginx['proxy_protocol'] = true
   nginx['real_ip_trusted_addresses'] = [ "127.0.0.0/8", "IP_OF_THE_PROXY/32"]
   ```

1. GitLab을 재구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 처음으로 로그인 {#sign-in-for-the-first-time}

[로드 밸런서에 대한 DNS 구성](#configure-dns-for-load-balancer)할 때 사용한 도메인 이름을 사용하면 이제 브라우저에서 GitLab을 방문할 수 있어야 합니다.

GitLab을 설치한 방법과 다른 방법으로 암호를 변경하지 않은 경우 기본 암호는 다음 중 하나입니다:

- 공식 GitLab AMI를 사용한 경우 인스턴스 ID입니다.
- `/etc/gitlab/initial_root_password`에 24시간 동안 저장된 임의로 생성된 암호입니다.

기본 암호를 변경하려면 `root` 사용자로 기본 암호로 로그인하고 [사용자 프로필에서 변경](../../user/profile/user_passwords.md#change-your-password)합니다.

[자동 크기 조정 그룹](#create-an-auto-scaling-group)이 새 인스턴스를 시작할 때 사용자 이름 `root`과 새로 생성된 암호로 로그인할 수 있습니다.

### 사용자 지정 AMI 생성 {#create-custom-ami}

EC2 대시보드에서:

1. [이전에 생성한](#install-gitlab) `GitLab` 인스턴스를 선택합니다.
1. **조치**를 선택하고 **Image and templates**으로 스크롤하여 **Create image**을 선택합니다.
1. 이미지에 이름과 설명을 지정합니다(저희는 둘 다 `GitLab-Source`을 사용함).
1. 다른 모든 것을 기본값으로 두고 **Create Image**을 선택합니다

이제 시작 구성을 만들 때 사용할 사용자 지정 AMI가 있습니다.

## 자동 크기 조정 그룹 내에서 GitLab 배포 {#deploy-gitlab-inside-an-auto-scaling-group}

### 시작 템플릿 생성 {#create-a-launch-template}

EC2 대시보드에서:

1. 왼쪽 메뉴에서 **Launch Templates**을 선택하고 **create launch template**을 선택합니다.
1. 시작 템플릿의 이름을 입력합니다(저희는 `gitlab-launch-template`을 사용함).
1. **Launch template contents**을 선택하고 **My AMIs** 탭을 선택합니다/
1. **내가 소유자**를 선택하고 이전에 생성한 `GitLab-Source` 사용자 지정 AMI를 선택합니다.
1. 요구 사항에 가장 적합한 인스턴스 유형을 선택합니다(최소 `c5.2xlarge`).
1. **Key pair** 섹션에서 **Create new key pair**을 선택합니다.
   1. 키 페어에 이름을 지정하고(저희는 `gitlab-launch-template`을 사용함) `gitlab-launch-template.pem` 파일을 나중에 사용할 수 있도록 저장합니다.
1. 루트 볼륨은 기본적으로 8GiB이며 아무 데이터도 저장하지 않으므로 충분해야 합니다. **Configure Security Group**을 선택합니다.
1. **Select existing security group**을 선택하고 로드 밸런서 방식에 따라 적절한 보안 그룹을 선택합니다:
   - **NLB only**: `gitlab-nlb-sec-group`과 `bastion-sec-group`
   - **Hybrid NLB->ALB**: `gitlab-rails-sec-group`과 `bastion-sec-group`

   `bastion-sec-group`은 [SSH 에이전트 포워딩](#use-ssh-agent-forwarding)을 사용하여 bastion 호스트에서 관리 및 구성 작업을 위한 SSH 액세스를 허용합니다.
1. **Advanced details** 섹션에서:
   1. **IAM instance profile**: [이전에 생성한](#create-an-iam-role) `GitLabS3Access` 역할을 선택합니다.
1. 모든 설정을 검토하고 만족하면 **Create launch template**을 선택합니다.

### 자동 크기 조정 그룹 생성 {#create-an-auto-scaling-group}

EC2 대시보드에서:

1. 왼쪽 메뉴에서 **Auto scaling groups**을 선택하고 **Create Auto Scaling group**을 선택합니다.
1. **그룹 이름**을 입력합니다(저희는 `gitlab-auto-scaling-group`을 사용함).
1. **Launch template**에서 이전에 생성한 시작 템플릿을 선택합니다. **다음**을 선택합니다
1. 네트워크 설정 섹션에서:
   1. **VPC**에서 드롭다운 목록의 `gitlab-vpc`을 선택합니다.
   1. **Availability Zones and subnets**에서 프라이빗 [이전에 생성한 서브넷](#subnets)(`gitlab-private-10.0.1.0`과 `gitlab-private-10.0.3.0`)을 선택합니다.
   1. **다음**을 선택합니다.
1. 로드 밸런싱 설정 섹션에서:
   1. **Attach to an existing load balancer**을 선택합니다.
   1. **Existing load balancer target groups** 드롭다운 목록에서 로드 밸런서 방식에 따라 적절한 대상 그룹을 선택합니다:
      - **NLB only**: `gitlab-nlb-ssh-target`과 `gitlab-nlb-http-target`을 선택합니다
      - **Hybrid NLB->ALB**: `gitlab-nlb-ssh-target`과 `gitlab-alb-http-target`을 선택합니다. 자동 크기 조정 그룹이 시작된 모든 인스턴스를 이러한 대상 그룹에 자동으로 등록합니다.
   1. **Health Check Type**의 경우 **Turn on Elastic Load Balancing health checks** 옵션을 선택합니다. **Health Check Grace Period**을 기본값 `300` 초로 둡니다.
   1. **다음**을 선택합니다.
1. **Group size**의 경우 **Desired capacity**을 `2`으로 설정합니다.
1. 크기 조정 설정 섹션에서:
   1. **No scaling policies**을 선택합니다. 정책은 나중에 구성됩니다.
   1. **Min desired capacity**: `2`으로 설정합니다.
   1. **Max desired capacity**: `4`으로 설정합니다.
   1. **다음**을 선택합니다.
1. 마지막으로 알림 및 태그를 원하는 대로 구성하고, 변경 사항을 검토한 후 자동 크기 조정 그룹을 생성합니다.
1. 자동 크기 조정 그룹이 생성된 후 [Cloudwatch](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html)에서 크기 조정 정책을 만들고 할당해야 합니다.
   1. 이전에 생성한 **EC2** 인스턴스의 메트릭에 대해 `CPUUtilization`**By Auto Scaling Group**에 대한 경보를 생성합니다.
   1. 다음 조건을 사용하여 [확장 정책](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#step-scaling-create-scale-out-policy)을 생성합니다:
      1. `CPUUtilization`이 60% 이상일 때 `1` 용량 단위를 **추가**합니다.
      1. **Scaling policy name**을 `Scale Up Policy`으로 설정합니다.

   ![확장 정책을 구성합니다.](img/scale_up_policy_v17_0.png)

   1. 다음 조건을 사용하여 [축소 정책](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-simple-step.html#step-scaling-create-scale-in-policy)을 생성합니다:
      1. `CPUUtilization`이 45% 이하일 때 `1` 용량 단위를 **삭제**합니다.
      1. **Scaling policy name**을 `Scale Down Policy`으로 설정합니다.

   ![축소 정책을 구성합니다.](img/scale_down_policy_v17_0.png)

   1. 이전에 생성한 자동 크기 조정 그룹에 새 동적 크기 조정 정책을 할당합니다.

자동 크기 조정 그룹이 생성되면 EC2 대시보드에서 새 인스턴스가 시작되는 것을 볼 수 있습니다. 로드 밸런서에 추가되는 새 인스턴스도 볼 수 있습니다. 인스턴스가 헬스 체크를 통과하면 로드 밸런서에서 트래픽을 수신할 준비가 됩니다.

인스턴스가 자동 크기 조정 그룹에서 생성되므로 인스턴스로 돌아가서 [이전에 수동으로 생성한 인스턴스](#install-gitlab)를 종료합니다. 사용자 지정 AMI를 생성하려면 이 인스턴스만 필요했습니다.

## Prometheus를 사용한 상태 확인 및 모니터링 {#health-check-and-monitoring-with-prometheus}

다양한 서비스에서 활성화할 수 있는 Amazon CloudWatch 외에도 GitLab은 Prometheus를 기반으로 자체 통합 모니터링 솔루션을 제공합니다. 설정 방법에 대한 자세한 내용은 [GitLab Prometheus](../../administration/monitoring/prometheus/_index.md)를 참조하세요.

GitLab에는 ping을 할 수 있는 다양한 [상태 확인 엔드포인트](../../administration/monitoring/health_check.md)가 있고 보고서를 얻을 수 있습니다.

## 러너 {#gitlab-runner}

[GitLab CI/CD](../../ci/_index.md)를 활용하려면 최소한 하나의 [러너](https://docs.gitlab.com/runner/)를 설정해야 합니다.

[AWS에서 GitLab 러너 자동 크기 조정 구성](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/)에 대해 자세히 알아보세요.

## 백업 및 복원 {#backup-and-restore}

GitLab은 [백업](../../administration/backup_restore/_index.md) 도구를 제공하며 Git 데이터, 데이터베이스, 첨부 파일, LFS 객체 등을 복원할 수 있습니다.

알아야 할 몇 가지 중요한 사항:

- 백업/복원 도구는 secrets와 같은 일부 구성 파일을 저장하지 않습니다. [이를 직접 구성](../../administration/backup_restore/backup_gitlab.md#storing-configuration-files)해야 합니다.
- 기본적으로 백업 파일은 로컬에 저장되지만 [S3를 사용하여 GitLab을 백업](../../administration/backup_restore/backup_gitlab.md#using-amazon-s3)할 수 있습니다.
- [백업에서 특정 디렉토리를 제외](../../administration/backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)할 수 있습니다.

### GitLab 백업 {#backing-up-gitlab}

GitLab을 백업하려면:

1. 인스턴스로 SSH를 연결합니다.
1. 백업을 수행합니다:

   ```shell
   sudo gitlab-backup create
   ```

### 백업에서 GitLab 복원 {#restoring-gitlab-from-a-backup}

GitLab을 복원하려면 먼저 [복원 설명서](../../administration/backup_restore/_index.md#restore-gitlab)를 검토하고 복원 필수 조건을 검토합니다. 그런 다음 [Linux 패키지 설치 섹션](../../administration/backup_restore/restore_gitlab.md#restore-for-linux-package-installations)의 단계를 따릅니다.

## GitLab 업데이트 {#updating-gitlab}

GitLab은 [릴리스 날짜](https://about.gitlab.com/releases/)에 매달 새 버전을 출시합니다. 새 버전이 릴리스될 때마다 GitLab 인스턴스를 업데이트할 수 있습니다:

1. 인스턴스로 SSH를 연결합니다
1. 백업을 수행합니다:

   ```shell
   sudo gitlab-backup create
   ```

1. 리포지토리를 업데이트하고 GitLab을 설치합니다:

   ```shell
   sudo apt update
   sudo apt install gitlab-ee
   ```

몇 분 후 새 버전이 실행 중이어야 합니다.

## AWS에서 공식 GitLab 생성 AMI ID 찾기 {#find-official-gitlab-created-ami-ids-on-aws}

[GitLab 릴리스를 AMI로 사용](../../solutions/cloud/aws/gitlab_single_box_on_aws.md#official-gitlab-releases-as-amis)하는 방법에 대해 자세히 알아보세요.

## 결론 {#conclusion}

이 가이드에서는 주로 확장 및 일부 중복성 옵션을 다루었으며, 경험은 다를 수 있습니다.

모든 솔루션은 비용/복잡성과 가동 시간 간의 트레이드오프를 수반한다는 점을 기억하세요. 더 많은 가동 시간을 원할수록 솔루션이 더 복잡해집니다. 솔루션이 복잡할수록 설정 및 유지 관리에 더 많은 작업이 필요합니다.

다음의 다른 리소스를 읽고 추가 자료를 요청하려면 자유롭게 [이슈를 열](https://gitlab.com/gitlab-org/gitlab/-/issues/new)어주세요:

- [GitLab 확장](../../administration/reference_architectures/_index.md): GitLab은 여러 가지 유형의 클러스터링을 지원합니다.
- [Geo 복제](../../administration/geo/_index.md): Geo는 광범위하게 분산된 개발 팀을 위한 솔루션입니다.
- [Linux 패키지](https://docs.gitlab.com/omnibus/) \- GitLab 인스턴스 관리에 대해 알아야 할 모든 것입니다.
- [라이선스 추가](../../administration/license.md): 라이선스를 사용하여 모든 GitLab Enterprise Edition 기능을 활성화합니다.
- [가격](https://about.gitlab.com/pricing/): 다양한 티어의 가격 정보입니다.

## 문제 해결 {#troubleshooting}

### 인스턴스가 상태 확인에 실패 중 {#instances-are-failing-health-checks}

인스턴스가 로드 밸런서의 상태 확인에 실패하는 경우 이전에 구성한 상태 확인 엔드포인트에서 상태 `200`을 반환하는지 확인합니다. 상태 `302`와 같은 리디렉션을 포함한 다른 상태는 상태 확인이 실패하게 합니다.

상태 확인이 통과하기 전에 자동 리디렉션을 방지하려면 `root` 사용자에 대한 암호를 설정해야 할 수도 있습니다.

### 메시지: `The change you requested was rejected (422)` {#message-the-change-you-requested-was-rejected-422}

웹 인터페이스를 통해 암호를 설정하려고 할 때 이 페이지가 표시되면 `external_url`이(가) `gitlab.rb`과(와) 일치하는 도메인에서 요청하고 있는지 확인하고, 변경한 후에 `sudo gitlab-ctl reconfigure`을(를) 실행합니다.

### 일부 작업 로그가 오브젝트 스토리지에 업로드되지 않음 {#some-job-logs-are-not-uploaded-to-object-storage}

GitLab 배포가 여러 노드로 확장될 때 일부 작업 로그가 [오브젝트 스토리지](../../administration/object_storage.md)에 제대로 업로드되지 않을 수 있습니다. CI가 오브젝트 스토리지를 사용하려면 [증분 로깅이 필요](../../administration/object_storage.md#alternatives-to-file-system-storage)합니다.

아직 활성화되지 않았으면 [증분 로깅](../../administration/cicd/job_logs.md#incremental-logging)을 활성화합니다.
