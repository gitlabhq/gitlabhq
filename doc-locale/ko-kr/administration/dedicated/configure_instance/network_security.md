---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Dedicated를 위해 사용자 정의 도메인, 인증 기관, 개인 네트워크 연결, IP 허용 목록 및 NAT 게이트웨이 IP를 구성합니다."
title: GitLab Dedicated 네트워크 액세스 및 보안
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

이 설정을 사용하여 GitLab Dedicated 인스턴스가 인터넷 및 개인 인프라에 연결되는 방식을 제어합니다. 사용자 정의 도메인을 구성하고, 외부 서비스에 대한 인증 기관을 관리하고, AWS PrivateLink를 사용하여 개인 네트워크 연결을 설정하고, IP 허용 목록으로 액세스를 제한하고, 인스턴스가 사용하는 아웃바운드 IP를 볼 수 있습니다.

## 사용자 정의 도메인 {#custom-domains}

기본값 `your-tenant.gitlab-dedicated.com` 대신 사용자 정의 도메인을 사용하여 GitLab Dedicated 인스턴스에 액세스할 수 있습니다.

사용자 정의 도메인을 추가할 때:

- 도메인이 인스턴스에 액세스하기 위한 외부 URL에 포함됩니다.
- 기본값 `tenant.gitlab-dedicated.com` 도메인을 사용하는 인스턴스에 대한 모든 연결을 더 이상 사용할 수 없습니다.

GitLab은 [Let's Encrypt](https://letsencrypt.org/)를 사용하여 사용자 정의 도메인에 대한 SSL/TLS 인증서를 자동으로 관리합니다. Let's Encrypt는 [HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)를 사용하여 도메인 소유권을 확인하며, 다음이 필요합니다:

- CNAME 레코드가 DNS를 통해 공개적으로 확인 가능해야 합니다.
- 90일마다 자동 인증서 갱신을 위한 동일한 공개 유효성 검사 프로세스입니다.

AWS PrivateLink 같은 개인 네트워킹으로 구성된 인스턴스의 경우, 공개 DNS 해석을 통해 인증서 관리가 제대로 작동하며, 다른 모든 액세스가 개인 네트워크로 제한되어 있어도 괜찮습니다.

GitLab Dedicated는 두 가지 구성 방법을 통해 사용자 정의 도메인을 지원합니다:

- 표준 구성:  CNAME 레코드 및 Let's Encrypt 인증서를 사용합니다. 자신의 DNS 레코드를 구성하고 지원을 통해 도메인 활성화를 요청합니다.
- Cloudflare 보안 구성:  NS 레코드 및 Let's Encrypt 인증서를 사용합니다. GitLab은 DNS 구성 세부 정보를 제공하고 사용자는 지원과 함께 이를 구현합니다.

Customer Success Manager에 연락하여 인스턴스에 적용되는 구성 방법을 확인합니다.

### 사용자 정의 도메인 세부 정보 보기 {#view-your-custom-domain-details}

**Custom domains** 섹션은 GitLab Dedicated 인스턴스의 활성 도메인 구성을 표시하며, 다음을 포함합니다:

- **GitLab instance domain**:  GitLab 인스턴스의 사용자 정의 도메인입니다.
- **Registry domain**:  컨테이너 레지스트리의 사용자 정의 도메인입니다.
- **KAS domain**:  Kubernetes용 GitLab 에이전트 서버(KAS)의 사용자 정의 도메인입니다.

이 정보를 사용하여 다음을 수행합니다:

- 현재 사용자 정의 도메인 구성을 확인합니다.
- 외부 통합을 위한 참조 도메인입니다.
- DNS 관리를 위한 구성 세부 정보를 복사합니다.

사용자 정의 도메인 세부 정보를 보려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. **구성** 탭을 선택합니다.
1. **Custom domains**을 확장합니다.

#### DNSSEC 세부 정보 {#dnssec-details}

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated for Government

{{< /details >}}

사용자 정의 도메인이 Cloudflare WAF(Web Application Firewall)로 구성된 경우, Switchboard는 Cloudflare 네임서버 및 FedRAMP 준수를 위한 DNSSEC 매개변수를 포함한 추가 구성 세부 정보를 표시합니다.

추가 세부 정보는 다음을 포함합니다:

- Cloudflare 네임서버:  Cloudflare에서 관리하는 도메인의 DNS 네임서버입니다.
- 키 태그:  DNSSEC 키의 숫자 식별자입니다.
- 알고리즘:  사용되는 암호화 알고리즘입니다(일반적으로 SHA-256 기반 ECDSA P-256의 경우 13).
- Digest 유형:  사용되는 해시 알고리즘입니다(일반적으로 SHA-256의 경우 2).
- Digest:  공개 키의 암호화 해시입니다.

이 값을 사용하여 DNS 공급자로 DNS 위임 및 DNSSEC 유효성 검사를 구성합니다.

### 표준 구성 {#standard-configuration}

이 구성을 사용하면 도메인이 CNAME 레코드를 사용하여 GitLab 인스턴스에 직접 연결됩니다. 자신의 DNS 레코드를 구성하고 지원을 통해 도메인 활성화를 요청합니다.

> [!note]
> 사용자 정의 도메인은 개인 네트워크를 통해 인스턴스에 액세스하더라도 SSL 인증서 관리를 위해 공개 인터넷에서 액세스할 수 있어야 합니다.

#### DNS 레코드 구성 {#configure-dns-records}

전제 조건:

- 도메인 호스트의 DNS 설정에 대한 액세스입니다.

DNS 레코드를 구성하려면:

1. 도메인 호스트의 웹사이트에 로그인합니다.
1. DNS 설정으로 이동합니다.
1. 사용자 정의 도메인을 GitLab Dedicated 인스턴스로 가리키는 `CNAME` 레코드를 추가합니다. 예를 들어:

   ```plaintext
   gitlab.my-company.com.  CNAME  my-tenant.gitlab-dedicated.com
   ```

1. 선택사항. 도메인에 기존 `CAA` 레코드가 있는 경우, Let's Encrypt를 유효한 인증 기관으로 포함하도록 업데이트합니다. 예를 들어:

   ```plaintext
   gitlab.my-company.com.  IN  CAA 0 issue "pki.goog"
   gitlab.my-company.com.  IN  CAA 0 issue "letsencrypt.org"
   ```

   `CAA` 레코드는 도메인의 인증서를 발급할 수 있는 인증 기관을 정의합니다.

1. 변경 사항을 저장하고 DNS 변경 사항이 적용될 때까지 기다립니다.

사용자 정의 도메인을 사용하는 동안 DNS 레코드를 유지합니다.

#### 사용자 정의 도메인 활성화 {#enable-a-custom-domain}

전제 조건:

- DNS 레코드를 구성했습니다.

사용자 정의 도메인을 활성화하려면:

1. [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 제출합니다.
1. 지원 티켓에서 다음을 지정합니다:
   - 사용자 정의 도메인 이름입니다. 예를 들어, `gitlab.company.com`.
   - 컨테이너 레지스트리 및 Kubernetes용 GitLab 에이전트 서버의 사용자 정의 도메인이 필요한 경우, 사용할 도메인 이름을 포함합니다. 예를 들어 `registry.company.com` 및 `kas.company.com`입니다.

### Cloudflare 보안 구성 {#cloudflare-security-configuration}

이 구성을 사용하면 도메인을 NS 레코드를 사용하여 GitLab으로 위임해야 하므로, 트래픽이 Cloudflare WAF(Web Application Firewall)를 통해 라우팅될 수 있습니다. Cloudflare는 도메인의 모든 DNS 설정을 관리하고 향상된 보안 기능을 제공합니다.

> [!note]
> 이 방식은 Customer Success Manager와의 조정이 필요합니다. 구성은 인스턴스의 유지 보수 기간 동안 적용됩니다.

#### 사용자 정의 도메인 요청 {#request-a-custom-domain}

사용자 정의 도메인을 요청하려면:

1. [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 제출합니다.
1. 지원 티켓에서 다음을 지정합니다:
   - 사용자 정의 도메인 이름입니다. 예를 들어, `gitlab.company.com`.
   - 컨테이너 레지스트리 및 Kubernetes용 GitLab 에이전트 서버의 사용자 정의 도메인이 필요한 경우, 사용할 도메인 이름을 포함합니다. 예를 들어 `registry.company.com` 및 `kas.company.com`입니다.
   - 규정 준수 요구 사항입니다. 예를 들어 FedRAMP입니다.

GitLab은 도메인을 Cloudflare에서 구성하고 다음을 제공합니다:

- 예를 들어 `name1.ns.cloudflare.com` 및 `name2.ns.cloudflare.com`와 같은 두 개의 Cloudflare 네임서버입니다.
- DNSSEC 매개변수(FedRAMP 고객만 해당), 다음 포함:
  - 키 태그:  숫자 식별자(GitLab에서 제공)
  - 알고리즘:  일반적으로 13(SHA-256 기반 ECDSA P-256) 또는 8(RSA/SHA-256)
  - Digest 유형:  일반적으로 2(SHA-256)
  - Digest:  공개 키의 암호화 해시(GitLab에서 제공)

#### DNS 레코드 구성 {#configure-dns-records-1}

DNS 공급자에서 NS 레코드를 구성하여 하위 도메인을 Cloudflare로 위임합니다.

전제 조건:

- 도메인 호스트의 DNS 설정에 대한 액세스입니다.
- GitLab이 네임서버 및 DNSSEC 매개변수(해당하는 경우)를 제공했습니다.

DNS 레코드를 구성하려면:

1. 도메인 호스트의 웹사이트에 로그인합니다.
1. DNS 설정으로 이동합니다.
1. GitLab이 제공한 네임서버를 사용하여 NS 레코드를 만듭니다. 예를 들어:

   ```plaintext
   gitlab.company.com.     NS    name1.ns.cloudflare.com.
   gitlab.company.com.     NS    name2.ns.cloudflare.com.
   ```

1. 동일한 하위 도메인의 충돌하는 A, AAAA 또는 CNAME 레코드를 제거합니다.
1. FedRAMP 고객만 해당입니다. GitLab이 제공한 값을 사용하여 DS 레코드를 추가합니다:

   ```plaintext
   gitlab.company.com.     DS    [Key Tag] [Algorithm] [Digest Type] [Digest]
   ```

   예를 들어:

   ```plaintext
   gitlab.company.com.     DS    12345 13 2 A1B2C3D4E5F6...
   ```

1. 변경 사항을 저장합니다. DNS 변경 사항이 적용되는 데 최대 48시간이 걸릴 수 있습니다.
1. 구성을 확인합니다:

   ```shell
   # Verify nameserver delegation
   dig +short NS gitlab.company.com

   # Verify DNS resolution
   dig gitlab.company.com

   # Verify DNSSEC (if configured)
   dig +dnssec gitlab.company.com
   ```

1. DNS 구성이 완료되었음을 지원 티켓을 통해 GitLab에 알립니다.

GitLab은 다음을 수행합니다:

- DNS 위임을 확인합니다.
- SSL/TLS 인증서를 구성합니다.
- 사용자 정의 도메인이 활성일 때를 확인합니다.

## 컨테이너 레지스트리 네트워크 액세스 {#container-registry-network-access}

컨테이너 레지스트리 FQDN(Fully Qualified Domain Name)은 인스턴스의 컨테이너 레지스트리 데이터를 저장하는 S3 버킷을 식별합니다.

### 컨테이너 레지스트리 FQDN 보기 {#view-your-container-registry-fqdn}

FQDN을 사용하여 컨테이너 레지스트리 저장 위치를 참조하는 방화벽 규칙 및 네트워크 정책을 구성합니다. S3 버킷의 IP 주소는 시간이 지남에 따라 변경될 수 있습니다.

컨테이너 레지스트리 FQDN을 보려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. **구성** 탭을 선택합니다.
1. **Resource access**를 확장합니다.
1. **컨테이너 레지스트리** 아래에서 **클립보드에 복사**({{< icon name="copy-to-clipboard" >}})를 선택합니다.

## 외부 서비스에 대한 사용자 정의 인증 기관 {#custom-certificate-authorities-for-external-services}

GitLab Dedicated는 HTTPS를 통해 외부 서비스에 연결할 때 인증서를 검증합니다. 기본적으로 GitLab Dedicated는 공개적으로 인정받은 인증 기관만 신뢰하며 신뢰할 수 없는 인증 기관의 인증서를 가진 서비스에 대한 연결을 거부합니다.

외부 서비스가 개인 또는 내부 인증 기관의 인증서를 사용하는 경우, 해당 인증 기관을 GitLab Dedicated 인스턴스에 추가해야 합니다.

다음을 위해 사용자 정의 인증 기관이 필요할 수 있습니다:

- 내부 웹후크 끝점에 연결합니다.
- 개인 컨테이너 레지스트리에서 이미지를 가져옵니다.
- 회사 공개 키 인프라 뒤의 온프레미스 서비스와 통합합니다.

### 사용자 정의 인증서 추가 {#add-a-custom-certificate}

인증서 체인 블록(단일 텍스트 블록의 여러 인증서)은 지원되지 않습니다. 체인에 여러 인증서가 있는 경우, 각 인증서를 별도로 추가합니다.

사용자 정의 인증서를 추가하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **Custom certificate authorities**을 확장합니다.
1. **\+ Add Certificate**를 선택합니다.
1. 단일 인증서를 텍스트 상자에 붙여넣습니다. `-----BEGIN CERTIFICATE-----` 및 `-----END CERTIFICATE-----` 줄을 포함합니다.
1. **저장**을 선택합니다.
1. 체인의 각 추가 인증서에 대해 4-6단계를 반복합니다.
1. 페이지 맨 위로 스크롤하고 변경 사항을 즉시 적용할지 또는 다음 유지 보수 기간 동안 적용할지 선택합니다.

Switchboard를 사용하여 사용자 정의 인증서를 추가할 수 없는 경우, [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 열고 각 사용자 정의 인증서를 별도 파일로 첨부합니다.

## AWS PrivateLink 연결 {#aws-privatelink-connectivity}

AWS PrivateLink는 AWS 인프라와 GitLab Dedicated 인스턴스 간의 개인 네트워크 연결을 가능하게 하며, 공개 인터넷을 통해 트래픽을 라우팅하지 않습니다. 모든 트래픽은 AWS 네트워크 내에 유지되므로, 외부 위협에 대한 노출이 줄어들고 개인 네트워킹에 대한 규정 준수 요구 사항을 충족하는 데 도움이 될 수 있습니다.

GitLab Dedicated는 두 가지 유형의 PrivateLink 연결을 지원합니다:

- 인바운드 PrivateLink 연결:  VPC의 사용자 및 애플리케이션이 GitLab Dedicated 인스턴스에 비공개로 연결합니다. 인스턴스에 공개 인터넷을 통해 도달할 수 없도록 액세스를 제한하려는 경우 이를 사용합니다.
- 아웃바운드 PrivateLink 연결:  GitLab Dedicated 인스턴스 및 호스팅된 러너가 VPC에서 실행되는 서비스에 비공개로 연결합니다. 웹후크, 프로젝트 미러링, 비밀 관리자 또는 인프라로의 배포에 이를 사용합니다.

PrivateLink 연결은 GitLab Dedicated 인스턴스와 동일한 AWS 영역에 있어야 하며, 기본 및 보조 AWS 영역에서만 엔드포인트 서비스를 만들 수 있습니다.

AWS PrivateLink에 대한 자세한 내용은 [AWS PrivateLink란?](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)을(를) 참조하세요.

### 인바운드 PrivateLink 연결 {#inbound-privatelink-connections}

인바운드 PrivateLink 연결을 통해 VPC의 사용자 및 애플리케이션이 GitLab Dedicated 인스턴스에 비공개로 연결할 수 있습니다.

엔드포인트 서비스를 생성할 때 액세스를 제어하는 IAM 주체를 지정합니다. 사용자가 지정한 IAM 주체만 VPC 엔드포인트를 생성하여 인스턴스에 연결할 수 있습니다.

엔드포인트 서비스는 온보딩 중에 선택하거나 무작위로 선택된 두 개의 가용 영역에서 사용할 수 있습니다.

#### 인바운드 PrivateLink 연결 생성 {#create-an-inbound-privatelink-connection}

전제 조건:

- VPC는 GitLab Dedicated 인스턴스와 동일한 영역에 있어야 합니다.
- IAM 주체는 GitLab에서 제공한 엔드포인트 서비스를 검색하고, 인터페이스 VPC 엔드포인트를 생성하고, 개인 DNS가 활성화된 경우 Route 53 개인 호스팅 영역과 연결할 수 있는 권한이 있어야 합니다.
- 역할 이름만 있는 IAM 주체를 사용합니다. 역할 경로를 포함하지 마십시오.
  - 유효함: `arn:aws:iam::AWS_ACCOUNT_ID:role/RoleName`
  - 잘못됨: `arn:aws:iam::AWS_ACCOUNT_ID:role/somepath/AnotherRoleName`

인바운드 PrivateLink 연결을 생성하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **Inbound private connections**을 확장합니다.
1. **Add endpoint service**를 선택합니다. 사용 가능한 모든 영역에 이미 엔드포인트 서비스가 있는 경우 이 버튼을 사용할 수 없습니다.
1. 영역을 선택합니다.
1. VPC 엔드포인트를 설정하고 있는 AWS 조직의 AWS 사용자 또는 역할에 대한 IAM 주체를 추가합니다. IAM 주체는 [IAM 역할 주체](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-roles) 또는 [IAM 사용자 주체](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#principal-users)여야 합니다. VPC 엔드포인트를 생성하는 역할 또는 사용자에 다음 권한이 있는 정책을 첨부합니다:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "GitLabDedicatedInboundPrivateLink",
         "Effect": "Allow",
         "Action": [
           "ec2:CreateVpcEndpoint",
           "ec2:DescribeVpcEndpointServices",
           "ec2:DescribeVpcEndpoints",
           "ec2:DescribeVpcs",
           "route53:AssociateVPCWithHostedZone"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

1. **저장**을 선택합니다. GitLab은 엔드포인트 서비스를 생성하고 개인 DNS에 대한 도메인 확인을 처리합니다. 서비스 엔드포인트 이름은 **구성** 페이지에서 사용 가능해집니다.
1. AWS 계정에서 VPC에 [엔드포인트 인터페이스](https://docs.aws.amazon.com/vpc/latest/privatelink/create-interface-endpoint.html)를 생성합니다.
1. 엔드포인트 인터페이스를 다음 설정으로 구성합니다:
   - **Service endpoint name**:  Switchboard의 **구성** 페이지에서 이름을 사용합니다.
   - **Private DNS names enabled**:  **예**를 선택합니다.
   - **Subnets**:  일치하는 모든 서브넷을 선택합니다.
1. 온보딩 중에 제공된 인스턴스 URL을 사용하여 VPC에서 GitLab Dedicated 인스턴스에 연결합니다.

[`terraform-inbound-privatelink`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-inbound-privatelink) Terraform 모듈을 사용하여 AWS VPC 엔드포인트 설정을 자동화하고 DNS를 전환할 때 필요한 Route 53 레코드를 출력할 수 있습니다.

#### KAS 및 레지스트리를 위한 DNS 구성 {#configure-dns-for-kas-and-registry}

개인 네트워크를 통해 KAS(Kubernetes용 GitLab 에이전트) 및 컨테이너 레지스트리에 액세스하기 위해 VPC에서 추가 DNS 구성을 생성합니다.

전제 조건:

- 인바운드 PrivateLink 연결을 구성했습니다.
- AWS 계정에서 Route 53 개인 호스팅 영역을 생성할 수 있는 권한이 있습니다.

KAS 및 레지스트리를 위한 DNS를 구성하려면:

1. AWS 콘솔에서 `gitlab-dedicated.com`에 대한 개인 호스팅 영역을 생성하고 인바운드 PrivateLink 연결이 포함된 VPC와 연결합니다.
1. 개인 호스팅 영역을 생성한 후 다음 DNS 레코드를 추가합니다(`example`을 인스턴스 이름으로 바꿈):

   1. GitLab Dedicated 인스턴스에 대한 `A` 레코드를 생성합니다:
      - 전체 인스턴스 도메인(예: `example.gitlab-dedicated.com`)을 VPC 엔드포인트로 확인되는 별칭으로 구성합니다.
      - 가용 영역 참조를 포함하지 않는 VPC 엔드포인트를 선택합니다.

        ![AZ 참조 없이 강조 표시된 올바른 엔드포인트를 보여주는 VPC 엔드포인트 드롭다운 목록입니다.](../img/vpc_endpoint_dns_v18_3.png)

   1. GitLab Dedicated 인스턴스 도메인(`example.gitlab-dedicated.com`)로 해석되도록 KAS와 레지스트리 모두에 대한 `CNAME` 레코드를 생성합니다:
      - `kas.example.gitlab-dedicated.com`
      - `registry.example.gitlab-dedicated.com`

1. VPC의 리소스에서 다음 명령을 실행하여 연결을 확인합니다:

   ```shell
   nslookup kas.example.gitlab-dedicated.com
   nslookup registry.example.gitlab-dedicated.com
   nslookup example.gitlab-dedicated.com
   ```

   모든 명령은 VPC 내의 개인 IP 주소로 확인되어야 합니다.

이 구성은 특정 IP 주소 대신 VPC 엔드포인트 인터페이스를 사용하므로, IP 주소가 변경되어도 안정적으로 유지됩니다.

##### GitLab Pages를 위한 DNS 구성 {#configure-dns-for-gitlab-pages}

개인 네트워크를 통해 GitLab Pages에 액세스하려면 VPC에서 추가 DNS 구성을 생성합니다.

GitLab Pages를 위한 DNS를 구성하려면:

1. AWS 콘솔에서 `<tenant_name>.gitlab-dedicated.site`에 대한 개인 호스팅 영역을 생성하고 인바운드 PrivateLink 연결이 포함된 VPC와 연결합니다.
1. 개인 호스팅 영역을 생성한 후 다음 DNS 레코드를 추가합니다:
   1. VPC 엔드포인트에 대한 꼭짓점 `A` 별칭 레코드를 생성합니다.
   1. `*.<tenant_name>.gitlab-dedicated.site`에 대한 와일드카드 `CNAME`를 생성하며, 이는 `<tenant_name>.gitlab-dedicated.site`을 가리킵니다.

### 아웃바운드 PrivateLink 연결 {#outbound-privatelink-connections}

아웃바운드 PrivateLink 연결을 통해 GitLab Dedicated 인스턴스 및 호스팅된 러너가 VPC에서 실행되는 서비스와 비공개로 통신할 수 있으므로, 공개 인터넷에 트래픽이 노출되지 않습니다.

아웃바운드 PrivateLink 연결을 사용하여 웹후크를 보내고, 프로젝트 및 리포지토리를 가져오거나 미러링하고, 호스팅된 러너에 인프라의 사용자 정의 비밀 관리자, 아티팩트, 작업 이미지 및 배포에 대한 액세스를 제공합니다.

영역당 최대 10개의 아웃바운드 PrivateLink 연결을 만들 수 있습니다. 10개 이상의 백엔드 서비스를 단일 연결 뒤에 통합하려면 [`terraform-outbound-proxy`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-outbound-proxy) Terraform 모듈을 사용하여 TLS 통과, HTTP 라우팅 및 SMTP 포워딩을 통해 고가용성 NGINX 역방향 프록시를 배포할 수 있습니다.

#### 아웃바운드 PrivateLink 연결 추가 {#add-an-outbound-privatelink-connection}

전제 조건:

- 내부 서비스에 대한 [엔드포인트 서비스 생성](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html)을 수행하고 서비스 이름과 개인 DNS의 활성화 여부를 기록합니다.
- 인스턴스가 배포된 가용 영역(AZ)에서 NLB(Network Load Balancer)를 구성합니다. 구성된 AZ(Switchboard의 **개요** 페이지에 표시됨)를 사용하거나 영역의 모든 AZ에서 NLB를 활성화합니다.
- 권장됩니다. **Acceptance required**를 **아니오**로 설정합니다. **예**로 설정된 경우, 연결이 시작된 후 수동으로 승인해야 하며, 상태는 다음 유지 보수 기간까지 Switchboard에서 **대기중**으로 표시됩니다.

> [!note]
> **Acceptance required**를 **예**로 설정한 경우, Switchboard에서 링크가 승인되는 시기를 정확하게 확인할 수 없습니다. 수동으로 링크를 승인한 후, 상태는 다음 예약된 유지 보수까지 **대기중** 대신 **활성**으로 표시됩니다. 유지 보수 후 링크 상태가 새로 고쳐지고 연결된 것으로 표시됩니다.

Switchboard를 사용하여 아웃바운드 PrivateLink 연결을 추가하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **Outbound private connections**을 확장합니다.
1. **Outbound private link IAM principal**에서 ARN을 복사하고 엔드포인트 서비스의 **Allowed Principals** 목록에 추가합니다. 자세한 내용은 [권한 관리](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions)를 참조하세요.
1. 필드를 완성하세요.
1. 엔드포인트 서비스를 추가하려면 **Add endpoint service**를 선택합니다. 각 영역에 대해 최대 10개의 엔드포인트 서비스를 추가할 수 있습니다. 영역을 저장하려면 최소 하나의 엔드포인트 서비스가 필요합니다.
1. **저장**을 선택합니다.
1. 선택사항. 두 번째 영역에 대한 아웃바운드 PrivateLink 연결을 추가하려면 **Add outbound connection**를 선택한 다음 이전 단계를 반복합니다.

지원 요청으로 아웃바운드 PrivateLink 연결을 추가하려면:

1. [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 열고 서비스 엔드포인트 이름을 제공합니다. GitLab은 엔드포인트 서비스에 대한 연결을 시작하는 IAM 역할의 ARN을 제공합니다. 이 ARN을 엔드포인트 서비스의 **Allowed Principals** 목록에 추가합니다. 이는 [AWS 설명서](https://docs.aws.amazon.com/vpc/latest/privatelink/configure-endpoint-service.html#add-remove-permissions)에 설명되어 있습니다.
1. 엔드포인트를 사용하는 서비스에 연결하려면 GitLab Dedicated에 DNS 이름이 필요합니다. PrivateLink는 자동으로 내부 이름을 생성하지만, 기계가 생성한 것이므로 대부분의 목적에 유용하지 않습니다. 다음 옵션 중 하나를 선택합니다:
   - 엔드포인트 서비스에서 [개인 DNS 이름](https://docs.aws.amazon.com/vpc/latest/privatelink/manage-dns-names.html)을 활성화하고, 필요한 유효성 검사를 수행하고, 이 옵션을 사용 중임을 지원 티켓에서 GitLab에 알립니다. **Acceptance required**가 **예**로 설정된 경우, 지원 티켓에 이를 기록하여 GitLab이 개인 DNS 없이 연결을 시작하고 확인을 기다린 후 연결을 업데이트하여 개인 DNS를 활성화할 수 있도록 합니다.
   - GitLab Dedicated는 Dedicated AWS 계정 내에서 개인 호스팅 영역(PHZ)을 관리하고 DNS 이름을 엔드포인트에 별칭으로 지정할 수 있습니다. 자세한 내용은 [개인 호스팅 영역](#private-hosted-zones)을 참조하세요.

GitLab은 인스턴스를 구성하여 제공한 서비스 이름을 기반으로 필요한 엔드포인트 인터페이스를 생성합니다. PrivateLink는 일치하는 아웃바운드 연결을 VPC로 지정합니다.

#### 아웃바운드 PrivateLink 연결 삭제 {#delete-an-outbound-privatelink-connection}

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **Outbound private connections**을 확장합니다.
1. 삭제할 아웃바운드 PrivateLink 연결로 이동한 다음 **삭제**({{< icon name="remove" >}})를 선택합니다.
1. **삭제**를 선택합니다.
1. 선택사항. 영역의 모든 링크를 삭제하려면 영역 헤더에서 **삭제**({{< icon name="remove" >}})를 선택합니다. 이는 또한 영역 구성을 삭제합니다.

## 개인 호스팅 영역 {#private-hosted-zones}

개인 호스팅 영역(PHZ)은 GitLab Dedicated 인스턴스의 네트워크에서 확인되는 사용자 정의 DNS 레코드(예: A, CNAME 또는 다른 레코드 유형)를 생성합니다.

다음을 원할 때 PHZ를 사용합니다:

- 단일 엔드포인트를 사용하는 여러 DNS 레코드(예: A 또는 CNAME 레코드)를 생성합니다. 예를 들어 여러 서비스에 연결하기 위해 역방향 프록시를 실행할 때입니다.
- 공개 DNS로 유효성을 검사할 수 없는 개인 도메인을 사용합니다.

PHZ는 일반적으로 역방향 PrivateLink와 함께 사용되어 AWS에서 생성한 엔드포인트 이름 대신 읽을 수 있는 도메인 이름을 생성합니다. 예를 들어 `alpha.beta.tenant.gitlab-dedicated.com` 대신 `vpce-0987654321fedcba0-k99y1abc.vpce-svc-0a123bcd4e5f678gh.eu-west-1.vpce.amazonaws.com`를 사용할 수 있습니다.

경우에 따라 PHZ를 사용하여 공개적으로 액세스 가능한 DNS 이름으로 해석되는 DNS 레코드를 만들 수도 있습니다. 예를 들어 내부 시스템이 개인 이름을 통해 서비스에 액세스해야 할 때 공개 엔드포인트로 해석되는 내부 DNS 이름을 만들 수 있습니다.

> [!note]
> 개인 호스팅 영역에 대한 변경 사항은 최대 5분 동안 이러한 레코드를 사용하는 서비스를 방해할 수 있습니다.

### PHZ 도메인 구조 {#phz-domain-structure}

PHZ 레코드는 다양한 유형의 대상을 가리킬 수 있습니다. 가장 일반적이고 권장되는 방식은 AWS VPC 엔드포인트의 DNS 이름을 가리키는 것입니다.

GitLab Dedicated 인스턴스의 도메인을 VPC 엔드포인트의 별칭 부분으로 사용할 때 메인 도메인 앞에 최소 하나의 하위 도메인을 포함해야 합니다. 예를 들어:

- 유효한 PHZ 항목: `subdomain1.<your-tenant-id>.gitlab-dedicated.com`.
- 유효하지 않은 PHZ 항목: `<your-tenant-id>.gitlab-dedicated.com`.

사용자 정의 도메인의 경우, `phz-entry.phz-name.com` 형식의 PHZ 이름 및 PHZ 항목을 제공해야 합니다.

PHZ 레코드가 VPC 엔드포인트가 아닌 DNS 이름을 가리키는 경우, 메인 도메인 앞에 최소 두 개의 하위 도메인을 포함해야 합니다. 예: `subdomain1.subdomain2.tenant.gitlab-dedicated.com`.

### Switchboard를 사용하여 개인 호스팅 영역 추가 {#add-a-private-hosted-zone-with-switchboard}

개인 호스팅 영역을 추가하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **Private hosted zones**을 확장합니다.
1. **Add private hosted zone entry**를 선택합니다.
1. 필드를 완성하세요.
   - **호스트 이름** 필드에 개인 호스팅 영역(PHZ) 항목을 입력합니다.
   - **Link type**의 경우 다음 중 하나를 선택합니다:
     - 아웃바운드 PrivateLink 연결 PHZ 항목의 경우 드롭다운 목록에서 엔드포인트 서비스를 선택합니다. `Available` 또는 `Pending Acceptance` 상태의 연결만 표시됩니다.
     - 다른 PHZ 항목의 경우 DNS 별칭 목록을 제공합니다.
1. **저장**을 선택합니다. PHZ 항목 및 모든 별칭이 목록에 나타납니다.
1. 페이지 맨 위로 스크롤하고 변경 사항을 즉시 적용할지 또는 다음 유지 보수 기간 동안 적용할지 선택합니다.

### 지원 요청으로 개인 호스팅 영역 추가 {#add-a-private-hosted-zone-with-a-support-request}

Switchboard를 사용하여 개인 호스팅 영역을 추가할 수 없는 경우, [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 열고 아웃바운드 PrivateLink 연결의 엔드포인트 서비스로 확인되어야 하는 DNS 이름 목록을 제공합니다. 필요에 따라 목록을 업데이트할 수 있습니다.

## IP 허용 목록 {#ip-allowlist}

IP 허용 목록으로 인스턴스에 액세스할 수 있는 IP 주소를 제어합니다. IP 허용 목록을 활성화하면 허용 목록에 없는 IP 주소가 차단되고 인스턴스에 액세스하려고 할 때 `HTTP 403 Forbidden` 응답을 받습니다.

Switchboard를 사용하여 IP 허용 목록을 구성 및 관리하거나, Switchboard를 사용할 수 없는 경우 지원 요청을 제출합니다.

### Switchboard를 사용하여 허용 목록에 IP 주소 추가 {#add-ip-addresses-to-the-allowlist-with-switchboard}

허용 목록에 IP 주소를 추가하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **IP allowlist**을 확장한 다음 **IP allowlist**을 선택하여 IP 허용 목록 페이지로 이동합니다.
1. IP 허용 목록을 활성화하려면 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 다음 **활성화**를 선택합니다.
1. 다음 중 하나를 수행합니다:

   - 단일 IP 주소를 추가하려면:

   1. **Add IP address**를 선택합니다.
   1. **IP 주소** 텍스트 상자에서 다음 중 하나를 입력합니다:
      - 단일 IPv4 주소(예: `192.168.1.1`).
      - CIDR 표기법의 IPv4 주소 범위(예: `192.168.1.0/24`).
   1. **설명** 텍스트 상자에서 설명을 입력합니다.
   1. **추가**를 선택합니다.

   - 여러 IP 주소를 가져오려면:

   1. **가져오기**를 선택합니다.
   1. CSV 파일을 업로드하거나 IP 주소 목록을 붙여넣습니다.
   1. **계속**를 선택합니다.
   1. 잘못되었거나 중복된 항목을 수정한 다음 **계속**을 선택합니다.
   1. 변경 사항을 검토한 다음 **가져오기**를 선택합니다.

1. 페이지 맨 위에서 변경 사항을 즉시 적용할지 또는 다음 유지 보수 기간 동안 적용할지 선택합니다.

### Switchboard를 사용하여 허용 목록에서 IP 주소 삭제 {#delete-ip-addresses-from-the-allowlist-with-switchboard}

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **IP allowlist**을 확장한 다음 **IP allowlist**을 선택하여 IP 허용 목록 페이지로 이동합니다.
1. 다음 중 하나를 수행합니다:

   - 단일 IP 주소를 삭제하려면:

   1. 제거할 IP 주소 옆에서 휴지통 아이콘({{< icon name="remove" >}})을 선택합니다.
   1. **Delete IP address**를 선택합니다.

   - 여러 IP 주소를 삭제하려면:

   1. 삭제할 IP 주소의 확인란을 선택합니다.
   1. 현재 페이지의 모든 IP 주소를 선택하려면 헤더 행의 확인란을 선택합니다.
   1. IP 주소 테이블 위에서 **삭제**를 선택합니다.
   1. **삭제**를 선택하여 확인합니다.

1. 페이지 맨 위에서 변경 사항을 즉시 적용할지 또는 다음 유지 보수 기간 동안 적용할지 선택합니다.

### 지원 요청으로 허용 목록에 IP 추가 {#add-an-ip-to-the-allowlist-with-a-support-request}

Switchboard를 사용하여 IP 허용 목록을 업데이트할 수 없는 경우, [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 열고 인스턴스에 액세스할 수 있는 IP 주소의 쉼표로 구분된 목록을 지정합니다.

### IP 허용 목록에 대해 OpenID Connect 활성화 {#enable-openid-connect-for-your-ip-allowlist}

[OpenID Connect ID 공급자로 GitLab 사용](../../../integration/openid_connect_provider.md)하려면 OpenID Connect 확인 엔드포인트에 대한 인터넷 액세스가 필요합니다.

IP 허용 목록을 유지 관리하면서 OpenID Connect 엔드포인트에 대한 액세스를 활성화하려면:

- [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)에서 OpenID Connect 엔드포인트에 대한 액세스를 허용하도록 요청합니다.

구성은 다음 유지 보수 기간 동안 적용됩니다.

### IP 허용 목록에 대해 SCIM 프로비저닝 활성화 {#enable-scim-provisioning-for-your-ip-allowlist}

외부 ID 공급자와 함께 SCIM을 사용하여 사용자를 자동으로 프로비저닝 및 관리할 수 있습니다. SCIM을 사용하려면 ID 공급자가 인스턴스 SCIM API 끝점에 액세스할 수 있어야 합니다. 기본적으로 IP 허용 목록은 이 끝점으로의 통신을 차단합니다.

IP 허용 목록을 유지 관리하면서 SCIM을 활성화하려면:

- [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)에서 SCIM 끝점을 인터넷으로 활성화하도록 요청합니다.

구성은 다음 유지 보수 기간 동안 적용됩니다.

## NAT 게이트웨이 IP 주소 {#nat-gateway-ip-addresses}

NAT 게이트웨이 IP 주소는 외부 서비스에 대한 연결을 수행할 때 인스턴스가 사용하는 아웃바운드 IP입니다. 이 IP는 일반적으로 일관되지만 GitLab이 재해 복구 중에 인스턴스를 다시 빌드하는 경우 변경될 수 있습니다.

이 IP 주소를 사용하여 웹후크 수신자를 구성하고 인스턴스에서 연결을 허용하도록 외부 서비스에 대한 허용 목록을 설정합니다.

NAT 게이트웨이 IP 주소를 보려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. **구성** 탭을 선택합니다.
1. **Resource access**를 확장합니다.
1. **NAT gateways** 아래에서 **클립보드에 복사**({{< icon name="copy-to-clipboard" >}})를 선택합니다.

## AWS PrivateLink 연결 문제 해결 {#troubleshooting-aws-privatelink-connectivity}

AWS PrivateLink 연결로 작업할 때 다음 이슈가 발생할 수 있습니다.

### 오류: `Service name could not be verified` {#error-service-name-could-not-be-verified}

인바운드 PrivateLink 연결에 대한 VPC 엔드포인트를 생성할 때 `Service name could not be verified`을(를) 나타내는 오류가 발생할 수 있습니다.

이 이슈는 지원 티켓에서 제공된 사용자 정의 IAM 역할이 AWS 계정에 구성된 필수 권한 또는 신뢰 정책을 갖지 않을 때 발생합니다.

이 이슈를 해결하려면:

1. 지원 티켓에서 GitLab에 제공된 사용자 정의 IAM 역할을 가정할 수 있는지 확인합니다.
1. 사용자 지정 역할이 이를 가정할 수 있는 신뢰 정책을 가지고 있는지 확인합니다. 예를 들어:

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "Statement1",
               "Effect": "Allow",
               "Principal": {
                   "AWS": "arn:aws:iam::CONSUMER_ACCOUNT_ID:user/user-name"
               },
               "Action": "sts:AssumeRole"
           }
       ]
   }
   ```

1. 사용자 지정 역할이 VPC 엔드포인트 및 EC2 작업을 허용하는 권한 정책을 가지고 있는지 확인합니다. 예를 들어:

   ```json
   {
      "Version": "2012-10-17",
      "Statement": [
         {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "vpce:*",
            "Resource": "*"
         },
         {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                  "ec2:CreateVpcEndpoint",
                  "ec2:DescribeVpcEndpointServices",
                  "ec2:DescribeVpcEndpoints"
            ],
            "Resource": "*"
         }
      ]
   }
   ```

1. 사용자 지정 역할을 사용하여 AWS 콘솔 또는 CLI에서 VPC 엔드포인트 생성을 다시 시도합니다.

### 아웃바운드 PrivateLink 연결 실패 {#outbound-privatelink-connection-fails}

아웃바운드 PrivateLink 연결이 작동하지 않으면 다음을 확인하십시오:

- NLB(Network Load Balancer)에서 교차 영역 로드 밸런싱이 켜져 있는지 확인합니다.
- 해당 보안 그룹의 인바운드 규칙 섹션이 올바른 IP 범위의 트래픽을 허용하는지 확인합니다.
- 인바운드 트래픽이 엔드포인트 서비스의 올바른 포트에 매핑되는지 확인합니다.
- Switchboard에서 **Outbound private connections**을 확장하고 세부 정보가 예상대로 표시되는지 확인합니다.
- [웹후크 및 통합에서 로컬 네트워크에 대한 요청을 허용](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations)했는지 확인합니다.
