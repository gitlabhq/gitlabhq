---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: Marketplace 구독 또는 공식 GitLab AMI를 사용하여 AWS에서 단일 GitLab 인스턴스를 프로비저닝하는 방법 가이드입니다. CE/EE 에디션 및 라이센싱 고려 사항을 포함합니다.
title: AWS에서 단일 EC2 인스턴스에 GitLab 프로비저닝
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

AWS에서 단일 GitLab 인스턴스를 프로비저닝하려는 경우 두 가지 옵션이 있습니다:

- Marketplace 구독
- 공식 GitLab AMI

## 마켓플레이스 구독 {#marketplace-subscription}

GitLab은 AWS 마켓플레이스 구독으로 5명 사용자 구독을 제공하여 모든 규모의 팀이 Ultimate 라이선스 인스턴스를 기록적인 시간 내에 시작하도록 지원합니다. 마켓플레이스 구독은 AWS 마켓플레이스 비공개 제안을 통해 GitLab 라이선싱으로 업그레이드할 수 있으며, AWS 결제를 계속 이용하는 편의성이 있습니다. GitLab에서 더 큰 비시간 기반 라이선스를 얻기 위해 마이그레이션이 필요하지 않습니다. 비공개 제안을 수락하면 분 단위 라이선싱이 자동으로 제거됩니다.

마켓플레이스 구독을 통해 GitLab 인스턴스를 프로비저닝하는 자습서를 보려면 [이 자습서를 사용](https://gitlab.awsworkshop.io/040_partner_setup.html)하세요. 이 자습서는 [GitLab Ultimate 마켓플레이스 목록](https://aws.amazon.com/marketplace/pp/prodview-g6ktjmpuc33zk)으로 연결되지만, [GitLab Premium 마켓플레이스 목록](https://aws.amazon.com/marketplace/pp/prodview-amk6tacbois2k)을 사용하여 인스턴스를 프로비저닝할 수도 있습니다.

## 공식 GitLab 릴리스를 AMI로 {#official-gitlab-releases-as-amis}

GitLab은 정기적인 릴리스 프로세스 중에 Amazon 머신 이미지(AMI)를 생성합니다. AMI는 단일 인스턴스 GitLab 설치에 사용되거나, `/etc/gitlab/gitlab.rb`을 구성하여 특정 GitLab 서비스 역할(예: Gitaly 서버)로 특화될 수 있습니다. 이전 릴리스는 계속 사용 가능하며 이전 GitLab 서버를 AWS로 마이그레이션하는 데 사용할 수 있습니다.

초기 라이선싱은 Free Enterprise License(EE) 또는 오픈 소스 Community Edition(CE)입니다. Enterprise Edition은 필요에 따라 라이선스 버전으로 가는 가장 쉬운 경로를 제공합니다.

현재 Amazon AMI는 Amazon에서 준비한 Ubuntu AMI(x86 및 ARM 사용 가능)를 시작점으로 사용합니다.

> [!note]
> 공식 AMI를 사용하여 GitLab 인스턴스를 배포할 때, 인스턴스의 루트 비밀번호는 EC2 **인스턴스** ID입니다(AMI ID가 아님). 이러한 루트 계정 비밀번호 설정 방식은 GitLab에서 공식으로 게시한 AMI에만 적용됩니다.

Community Edition(CE)에서 실행 중인 인스턴스는 GitLab Premium 또는 Ultimate 플랜을 구독하려면 Enterprise Edition(EE)로 마이그레이션해야 합니다. 구독을 원하는 경우, Enterprise Edition의 Free-forever 플랜을 사용하는 것이 가장 덜 방해적인 방법입니다.

> [!note]
> 지정된 GitLab 업그레이드는 데이터 디스크 업데이트 또는 데이터베이스 스키마 업그레이드를 포함할 수 있으므로, AMI를 교체하는 것만으로는 업그레이드를 수행하기에 충분하지 않습니다.

1. AWS 웹 콘솔에 로그인하면 다음 단계의 링크를 선택할 때 직접 AMI 목록으로 이동합니다.
1. 원하는 버전을 선택하세요:

   - [GitLab Enterprise Edition](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20EE;sort=desc:name): 엔터프라이즈 기능을 활용하려면 라이선스가 필요합니다.
   - [GitLab Community Edition](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;owner=782774275127;search=GitLab%20CE;sort=desc:name): GitLab의 오픈 소스 버전입니다.
   - [GitLab Premium 또는 Ultimate 마켓플레이스(사전 라이선스)](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Images:visibility=public-images;source=Marketplace;search=GitLab%20EE;sort=desc:name): 분 단위 청구에 포함된 5명 사용자 라이선스입니다.

1. AMI ID는 지역마다 고유합니다. 이러한 버전 중 하나를 로드한 후 오른쪽 상단 모서리에서 적절한 AMI를 보려면 원하는 대상 지역을 선택합니다.
1. 콘솔이 로드된 후 검색 범위를 좀 더 좁히기 위해 추가 검색 조건을 추가할 수 있습니다. 예를 들어, `13.`을 입력하여 13.x 버전만 찾습니다.
1. 나열된 AMI 중 하나로 EC2 머신을 시작하려면 관련 행의 시작 부분에 있는 상자를 선택하고 페이지의 왼쪽 위 근처에서 **Launch**를 선택합니다.
