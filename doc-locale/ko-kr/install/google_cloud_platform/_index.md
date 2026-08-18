---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Google Cloud Platform에서 가상 머신에 GitLab 인스턴스를 설치합니다.
title: Google Cloud Platform에 GitLab 설치
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

공식 Linux 패키지를 사용하여 [Google Cloud Platform(GCP)](https://cloud.google.com/)에 GitLab을 설치할 수 있습니다. 필요에 맞게 사용자 지정해야 합니다.

> [!note]
> Google Kubernetes Engine에 프로덕션 준비 GitLab을 배포하려면 Google Cloud Platform의 [`Click to Deploy` 단계](https://github.com/GoogleCloudPlatform/click-to-deploy/blob/master/k8s/gitlab/README.md)를 따를 수 있습니다. GCP VM 사용 대신 대체 방법이며 [Cloud Native GitLab Helm 차트](https://docs.gitlab.com/charts/)를 사용합니다.

## 전제 조건 {#prerequisites}

GCP에 GitLab을 설치하기 위한 두 가지 필수 요건이 있습니다:

1. Google 계정이 있어야 합니다.
1. GCP 프로그램에 가입해야 합니다. 처음인 경우 Google에서 [무료로 $300 크레딧](https://console.cloud.google.com/freetrial)을 제공하며 60일 동안 사용할 수 있습니다.

이 두 단계를 완료한 후 [VM을 생성](#creating-the-vm)할 수 있습니다.

## VM 생성 {#creating-the-vm}

GCP에 GitLab을 배포하려면 가상 머신을 생성해야 합니다:

1. <https://console.cloud.google.com/compute/instances>로 이동하여 Google 자격 증명으로 로그인합니다.
1. **생성**을 선택합니다

   !["생성"을 선택하여 인스턴스를 생성합니다.](img/launch_vm_v10_6.png)

1. 다음 페이지에서 VM의 유형과 예상 비용을 선택할 수 있습니다. 인스턴스 이름, 원하는 데이터 센터 및 머신 유형을 제공합니다. 다양한 사용자 기반 크기에 대한 [하드웨어 요구 사항](../requirements.md)을 참고합니다.

   ![인스턴스를 구성합니다.](img/vm_details_v13_1.png)

1. 크기, 유형 및 원하는 [운영 체제](../package/_index.md)를 선택하려면 `Boot disk` 아래의 **Change**을 선택합니다. 완료되면 **선택**을 선택합니다.

1. 유료 라이선스의 경우 필수입니다. **라벨** 아래에서 GitLab 라이선스를 구매한 방법에 따라 리소스 라벨을 추가합니다:
   - Google Cloud Marketplace 구매의 경우 다음을 추가합니다:
     - 키: `goog-partner-solution`
     - 값: `isol_plb32_0014m00001h35gdqaq_i4j66u754ivftu3n2bb3vyv7fek76fjo`
   - 마켓플레이스가 아닌 구매의 경우 다음을 추가합니다:
     - 키: `goog-partner-solution`
     - 값: `isol_psn_0014m00001h35gdqaq_gitlab`

   이러한 라벨은 파트너십 계약에 따라 필요한 Google Cloud의 GitLab 설치와 관련된 리소스로 태깅합니다. 리소스 라벨에 대한 자세한 내용은 [Google Cloud 리소스 라벨 지정 설명서](https://cloud.google.com/compute/docs/labeling-resources#create_resources_with_labels)를 참고합니다.

   > [!note]
   > Terraform을 사용하여 적절한 라벨로 인프라 생성을 자동화할 수 있습니다. 참고용으로 [Google Cloud Terraform 코드의 GitLab 설치](https://gitlab.com/gitlab-partners-public/google-cloud/source-code/gitlab-installation-on-google-cloud)를 참고합니다.

1. HTTP 및 HTTPS 트래픽을 허용한 다음 **생성**을 선택합니다. 프로세스가 몇 초 안에 완료됩니다.

## GitLab 설치 {#installing-gitlab}

몇 초 후 인스턴스가 생성되고 로그인할 수 있습니다. 다음 단계는 인스턴스에 GitLab을 설치하는 것입니다.

![인스턴스가 성공적으로 생성되었습니다.](img/vm_created_v10_6.png)

1. 인스턴스의 외부 IP 주소를 기록해 두십시오. 나중 단계에서 필요합니다. <!-- using future tense is okay here -->
1. 연결 열에서 **SSH**를 선택하여 인스턴스에 연결합니다.
1. 새 창이 나타나면 인스턴스에 로그인됩니다.

   ![인스턴스의 명령줄 인터페이스](img/ssh_terminal_v10_6.png)

1. 다음으로 <https://about.gitlab.com/install/>에서 선택한 운영 체제에 대한 GitLab 설치 지침을 따릅니다. 이전에 기록한 외부 IP 주소를 호스트 이름으로 사용할 수 있습니다.
1. 축하합니다! GitLab이 이제 설치되었으며 브라우저를 통해 액세스할 수 있습니다. 설치를 완료하려면 브라우저에서 URL을 열고 초기 관리자 암호를 제공합니다. 이 계정의 사용자 이름은 `root`입니다.

   ![설치 후 GitLab 첫 로그인.](img/first_signin_v10_6.png)

## 다음 단계 {#next-steps}

GitLab을 처음 설치한 후 수행해야 할 가장 중요한 다음 단계는 다음과 같습니다.

### 정적 IP 할당 {#assigning-a-static-ip}

기본적으로 Google은 인스턴스에 임시 IP를 할당합니다. 프로덕션 환경에서 도메인 이름으로 GitLab을 사용하는 경우 정적 IP를 할당해야 합니다.

자세한 내용은 [임시 외부 IP 주소 승격](https://cloud.google.com/vpc/docs/reserve-static-external-ip-address#promote_ephemeral_ip)을 참고합니다.

### 도메인 이름 사용 {#using-a-domain-name}

도메인 이름을 소유하고 있으며 DNS를 이전 단계에서 구성한 정적 IP를 가리키도록 올바르게 설정한 경우, GitLab이 변경을 인식하도록 구성하는 방법은 다음과 같습니다:

1. VM에 SSH로 연결합니다. Google 콘솔에서 **SSH**를 선택하면 새 창이 표시됩니다.

   ![인스턴스 세부 정보와 SSH 버튼으로 로그인합니다.](img/vm_created_v10_6.png)

   향후 [SSH 키를 사용한 연결](https://docs.cloud.google.com/compute/docs/connect/standard-ssh)을 설정할 수도 있습니다.

1. 선호하는 텍스트 편집기를 사용하여 Linux 패키지의 구성 파일을 편집합니다:

   ```shell
   sudo vim /etc/gitlab/gitlab.rb
   ```

1. `external_url` 값을 GitLab이 가져야 할 도메인 이름으로 설정하되 **without** `https`:

   ```ruby
   external_url 'http://gitlab.example.com'
   ```

   다음 단계에서 HTTPS를 설정하므로 지금은 이 작업을 수행할 필요가 없습니다. <!-- using future tense is okay here -->

1. 변경 사항을 적용하도록 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 이제 도메인 이름을 사용하여 GitLab을 방문할 수 있습니다.

### 도메인 이름으로 HTTPS 구성 {#configuring-https-with-the-domain-name}

필수는 아니지만 [TLS 인증서](https://docs.gitlab.com/omnibus/settings/ssl/)로 GitLab을 보호하는 것을 강력히 권장합니다.

### 이메일 SMTP 설정 구성 {#configuring-the-email-smtp-settings}

이메일 SMTP 설정을 올바르게 구성해야 합니다. 그렇지 않으면 GitLab이 댓글, 암호 변경 등과 같은 알림 이메일을 보낼 수 없습니다. 방법을 확인하려면 [Linux 패키지 설명서](https://docs.gitlab.com/omnibus/settings/smtp/#smtp-settings)를 참고합니다.

## 추가 정보 {#further-reading}

GitLab은 LDAP, SAML 및 Kerberos와 같은 다른 OAuth 공급자를 사용하여 인증하도록 구성할 수 있습니다. 다음은 읽을 관심이 있을 만한 일부 문서입니다:

- [Linux 패키지 설명서](https://docs.gitlab.com/omnibus/)
- [통합 설명서](../../integration/_index.md)
- [GitLab Pages 구성](../../administration/pages/_index.md)
- [GitLab 컨테이너 레지스트리 구성](../../administration/packages/container_registry.md)
