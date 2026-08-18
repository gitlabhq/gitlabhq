---
stage: Systems
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Azure Marketplace에서 GitLab을 설치합니다.
title: Microsoft Azure에 GitLab 설치
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Microsoft Azure 비즈니스 클라우드 사용자를 위해 GitLab은 [Azure Marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/)에서 사전 구성된 제공 서비스를 제공합니다. 이 자습서에서는 단일 가상 머신(VM)에 GitLab Enterprise Edition을 설치하는 방법을 설명합니다.

## 전제 조건 {#prerequisites}

- Azure 계정 다음 방법 중 하나를 사용하세요:
  - 이미 구독이 있는 계정을 보유하고 있다면 해당 계정을 사용하세요.
  - [무료 계정을 생성](https://azure.microsoft.com/en-us/free/)하면 30일 동안 Azure를 탐색할 수 있는 $200 크레딧을 받습니다. 자세한 내용은 [Azure 무료 계정](https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0044p/)을 참조하세요.
  - MSDN 구독이 있다면 Azure 구독자 혜택을 활성화하세요. MSDN 구독을 사용하면 매월 반복되는 Azure 크레딧을 받습니다.
- GitLab 인스턴스를 유지하기 위한 관리자 액세스 권한

## GitLab 배포 및 구성 {#deploy-and-configure-gitlab}

GitLab이 이미 사전 구성된 이미지에 설치되어 있으므로 새 VM을 만들기만 하면 됩니다:

1. [마켓플레이스에서 GitLab 제공 서비스 방문](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/gitlabinc1586447921813.gitlabee?tab=Overview)
1. **Get it now**를 선택하면 **Create this app in Azure** 창이 열립니다. **계속**을 선택하세요.
1. Azure 포털에서 다음 옵션 중 하나를 선택하세요:
   - **생성**을 선택하여 처음부터 VM을 만듭니다.
   - **Start with a pre-set configuration**을 선택하여 일부 사전 구성된 옵션으로 시작합니다. 이러한 구성은 언제든지 수정할 수 있습니다.

이 가이드의 목적상 처음부터 VM을 만들려고 하므로 **생성**을 선택합니다.

> [!note]
> VM이 활성 상태("할당됨"이라고 함)일 때마다 Azure가 컴퓨팅 요금을 청구한다는 점을 주의하세요. 무료 평가판 크레딧을 사용하고 있더라도 마찬가지입니다. [Azure VM을 올바르게 종료하여 비용을 절약하는 방법](https://build5nines.com/properly-shutdown-azure-vm-to-save-money/)을 참조하세요. [Azure 가격 계산기](https://azure.microsoft.com/en-us/pricing/calculator/)를 참조하여 리소스 비용이 얼마나 될 수 있는지 확인하세요.

가상 머신을 만든 후 다음 섹션의 정보를 사용하여 구성합니다.

### 기본 탭 구성 {#configure-the-basics-tab}

먼저 기본 가상 머신의 기본 설정을 구성해야 합니다:

1. 구독 모델 및 리소스 그룹을 선택합니다(없는 경우 새 그룹 생성).
1. VM의 이름을 입력합니다(예: `GitLab`).
1. 지역을 선택하세요.
1. **Availability options**에서 **Availability zone**을 선택하고 `1`으로 설정합니다. [가용성 영역](https://learn.microsoft.com/en-us/azure/virtual-machines/availability)에 대해 자세히 알아보세요.
1. 선택한 이미지가 **GitLab - Gen1**으로 설정되었는지 확인합니다.
1. [하드웨어 요구 사항](../requirements.md)을 기준으로 VM 크기를 선택합니다. 최대 500명의 사용자를 위한 GitLab 환경을 실행하기 위한 최소 시스템 요구 사항은 `D4s_v3` 크기로 충족되므로 해당 옵션을 선택합니다.
1. 인증 유형을 **SSH 공개키**로 설정합니다.
1. 사용자 이름을 입력하거나 자동으로 생성된 사용자 이름을 그대로 둡니다. 이는 Azure가 SSH를 통해 VM에 연결하는 데 사용하는 사용자입니다. 기본적으로 사용자는 루트 액세스 권한이 있습니다.
1. 자신의 SSH 키를 제공할 것인지 아니면 Azure가 키를 생성하도록 할 것인지 결정하세요. SSH 공개키를 설정하는 방법에 대한 자세한 내용은 [SSH](../../user/ssh.md)를 참조하세요.

입력한 설정을 검토한 후 디스크 탭으로 진행합니다.

### 디스크 탭 구성 {#configure-the-disks-tab}

디스크의 경우:

1. OS 디스크 유형으로 **Premium SSD**를 선택합니다.
1. 기본 암호화를 선택합니다.

[Azure가 제공하는 디스크 유형에 대해 자세히 알아보세요](https://learn.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview).

설정을 검토한 후 네트워킹 탭으로 진행합니다.

### 네트워킹 탭 구성 {#configure-the-networking-tab}

이 탭을 사용하여 네트워크 인터페이스 카드(NIC) 설정을 구성하여 가상 머신의 네트워크 연결을 정의합니다. 기본 설정으로 유지할 수 있습니다.

Azure는 기본적으로 보안 그룹을 생성하고 VM이 여기에 할당됩니다. 마켓플레이스의 GitLab 이미지는 기본적으로 다음 포트를 열어 두었습니다:

| 포트 | 설명 |
|------|-------------|
| 80   | VM이 HTTP 요청에 응답하도록 하여 공개 액세스를 허용합니다. |
| 443  | VM이 HTTPS 요청에 응답하도록 하여 공개 액세스를 허용합니다. |
| 22   | VM이 SSH 연결 요청에 응답하도록 하여 원격 터미널 세션에 대한 공개 액세스(인증 포함)를 허용합니다. |

포트를 변경하거나 규칙을 추가하려면 VM을 만든 후 VM 대시보드에 있는 동안 왼쪽 사이드바에서 네트워킹 설정을 선택하여 수행할 수 있습니다.

### 관리 탭 구성 {#configure-the-management-tab}

이 탭을 사용하여 VM의 모니터링 및 관리 옵션을 구성합니다. 기본 설정을 변경할 필요가 없습니다.

### 고급 탭 구성 {#configure-the-advanced-tab}

이 탭을 사용하여 가상 머신 확장 또는 `cloud-init`을 통해 추가 구성, 에이전트, 스크립트 또는 애플리케이션을 추가합니다. 기본 설정을 변경할 필요가 없습니다.

### 태그 탭 구성 {#configure-the-tags-tab}

이 탭을 사용하여 리소스를 분류할 수 있는 이름/값 쌍을 추가합니다. 기본 설정을 변경할 필요가 없습니다.

### VM 검토 및 생성 {#review-and-create-the-vm}

최종 탭에서는 선택한 모든 옵션을 제시하여 이전 단계에서 선택한 항목을 검토하고 수정할 수 있습니다. Azure는 백그라운드에서 유효성 검사 테스트를 실행하며, 필요한 모든 설정을 제공했다면 VM을 만들 수 있습니다.

**생성**을 선택한 후 Azure가 SSH 키 쌍을 생성하도록 선택한 경우 프롬프트가 나타나 프라이빗 SSH 키를 다운로드합니다. VM으로 SSH 연결할 때 필요하므로 키를 다운로드합니다.

키를 다운로드한 후 배포가 시작됩니다.

### 배포 완료 {#finish-deployment}

이 시점에서 Azure가 새 VM을 배포하기 시작합니다. 배포 프로세스는 완료하는 데 몇 분이 걸립니다. 완료되면 새 VM과 관련 리소스가 Azure 대시보드에 표시됩니다. **Go to resource**을 선택하여 VM의 대시보드를 방문합니다.

GitLab이 배포되었으며 사용할 준비가 되었습니다. 그러나 먼저 도메인 이름을 설정하고 GitLab이 도메인 이름을 사용하도록 구성해야 합니다.

### 도메인 이름 설정 {#set-up-a-domain-name}

VM에는 공개 IP 주소(기본적으로 정적)가 있지만 Azure를 사용하면 VM에 설명이 포함된 DNS 이름을 할당할 수 있습니다:

1. VM 대시보드에서 **DNS name** 아래의 **구성**을 선택합니다.
1. **DNS name label** 필드에 인스턴스의 설명적인 DNS 이름을 입력합니다(예: `gitlab-prod`). 이렇게 하면 `gitlab-prod.eastus.cloudapp.azure.com`에서 VM에 액세스할 수 있습니다.
1. **저장**을 선택합니다.

결국 대부분의 사용자는 자신의 도메인 이름을 사용하고 싶어 합니다. 이를 수행하려면 Azure VM의 공개 IP 주소를 가리키는 도메인 등록 기관과 함께 DNS `A` 레코드를 추가해야 합니다. [Azure DNS](https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns) 또는 [다른 등록 기관](https://docs.gitlab.com/omnibus/settings/dns/)을 사용할 수 있습니다.

### GitLab 외부 URL 변경 {#change-the-gitlab-external-url}

GitLab은 구성 파일에서 `external_url`을 사용하여 도메인 이름을 설정합니다. 이를 설정하지 않으면 Azure 친화적 이름을 방문할 때 브라우저가 공개 IP로 리디렉션됩니다.

GitLab 외부 URL을 설정하려면:

1. VM 대시보드에서 **설정** > **연결**로 이동하여 SSH를 통해 GitLab에 연결하고 지침을 따릅니다. [VM을 만들](#configure-the-basics-tab) 때 지정한 사용자 이름과 SSH 키로 로그인하는 것을 잊지 마세요. Azure VM 도메인 이름은 [이전에 설정한](#set-up-a-domain-name) 이름입니다. VM에 대한 도메인 이름을 설정하지 않은 경우 대신 IP 주소를 사용할 수 있습니다.

   예를 들어 다음과 같습니다:

   ```shell
   ssh -i <private key path> gitlab-azure@gitlab-prod.eastus.cloudapp.azure.com
   ```

   > [!note]
   > 자격 증명을 재설정해야 하는 경우 [Azure VM의 사용자에 대한 SSH 자격 증명을 재설정하는 방법](https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/linux/troubleshoot-ssh-connection#reset-ssh-credentials-for-a-user)을 읽어보세요.

1. `/etc/gitlab/gitlab.rb`을 편집기로 열어 봅니다.
1. `external_url`을 찾아 자신의 도메인 이름으로 바꿉니다. 이 예의 목적상 Azure가 설정한 기본 도메인 이름을 사용합니다. URL에서 `https`을 사용하면 [자동으로 활성화](https://docs.gitlab.com/omnibus/settings/ssl/#lets-encrypt-integration)되므로 Let's Encrypt가 활성화되고 HTTPS가 기본적으로 설정됩니다:

   ```ruby
   external_url 'https://gitlab-prod.eastus.cloudapp.azure.com'
   ```

1. 다음 설정을 찾아 주석 처리하여 GitLab이 잘못된 인증서를 선택하지 않도록 합니다:

   ```ruby
   # nginx['redirect_http_to_https'] = true
   # nginx['ssl_certificate'] = "/etc/gitlab/ssl/server.crt"
   # nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/server.key"
   ```

1. GitLab을 다시 구성하여 변경 사항을 적용합니다. `/etc/gitlab/gitlab.rb`을 변경할 때마다 다음 명령을 실행하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 도메인 이름이 [재부팅 후 재설정](https://docs.bitnami.com/aws/apps/gitlab/configuration/change-default-address/)되는 것을 방지하려면 Bitnami가 사용하는 유틸리티의 이름을 바꿉니다:

   ```shell
   sudo mv /opt/bitnami/apps/gitlab/bnconfig /opt/bitnami/apps/gitlab/bnconfig.bak
   ```

이제 브라우저에서 새 외부 URL의 GitLab을 방문할 수 있습니다.

### 처음으로 GitLab 방문 {#visit-gitlab-for-the-first-time}

이전에 설정한 도메인 이름을 사용하여 브라우저에서 새 GitLab 인스턴스를 방문합니다. 이 예에서는 `https://gitlab-prod.eastus.cloudapp.azure.com`입니다.

가장 먼저 나타나는 것은 로그인 페이지입니다. GitLab은 기본적으로 관리자 사용자를 만듭니다. 자격 증명은 다음과 같습니다:

- 사용자 이름: `root`
- 암호: 암호는 자동으로 생성되며 [두 가지 방법으로 찾을 수 있습니다](https://docs.bitnami.com/virtual-machine/faq/get-started/find-credentials/).

로그인한 후 즉시 [암호를 변경](../../user/profile/user_passwords.md#change-your-password)해야 합니다.

## GitLab 인스턴스 유지 {#maintain-your-gitlab-instance}

GitLab 환경을 최신 상태로 유지하는 것이 중요합니다. GitLab 팀은 지속적으로 개선 사항을 만들고 있으며 경우에 따라 보안상의 이유로 업데이트해야 할 수 있습니다. GitLab을 업데이트해야 할 때마다 이 섹션의 정보를 사용하세요.

### 현재 버전 확인 {#check-the-current-version}

현재 실행 중인 GitLab의 버전을 확인하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **대시보드**를 선택합니다.
1. **컴포넌트** 표에서 버전을 찾습니다.

GitLab의 최신 버전에 하나 이상의 보안 수정 사항이 포함되어 있으면 GitLab은 **Update asap** 알림 메시지를 표시하여 [업데이트](#update-gitlab)하도록 권장합니다.

### GitLab 업데이트 {#update-gitlab}

GitLab을 최신 버전으로 업데이트하려면:

1. SSH를 통해 VM에 연결합니다.
1. GitLab을 업데이트합니다:

   ```shell
   sudo apt update
   sudo apt install gitlab-ee
   ```

   이 명령은 GitLab과 관련 컴포넌트를 최신 버전으로 업데이트하며 완료하는 데 시간이 걸릴 수 있습니다. 이 동안 터미널에는 터미널에서 완료되고 있는 다양한 업데이트 작업이 표시됩니다.

   > [!note]
   > `E: The repository 'https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease' is not signed.`와 같은 오류가 발생하면 [문제 해결 섹션](#update-the-gpg-key-for-the-gitlab-repositories)을 참조하세요.

1. 업데이트 프로세스가 완료되면 다음과 같은 메시지가 나타납니다:

   ```plaintext
   Upgrade complete! If your GitLab server is misbehaving try running

      sudo gitlab-ctl restart

   before anything else.
   ```

브라우저에서 GitLab 인스턴스를 새로 고치고 **운영자** 영역으로 이동합니다. 이제 최신 버전의 GitLab 인스턴스가 있어야 합니다.

## 다음 단계 및 추가 구성 {#next-steps-and-further-configuration}

이제 기능하는 GitLab 인스턴스가 있으므로 [다음 단계](../next_steps.md)를 따라 새로운 설치로 할 수 있는 더 많은 작업을 배우세요.

## 문제 해결 {#troubleshooting}

이 섹션에서는 발생할 수 있는 일반적인 오류에 대해 설명합니다.

### GitLab 리포지토리에 대한 GPG 키 업데이트 {#update-the-gpg-key-for-the-gitlab-repositories}

> [!note]
> 이는 GitLab 이미지가 새 GPG 키로 업데이트될 때까지의 임시 수정 사항입니다.

Azure의 사전 구성된 GitLab 이미지(Bitnami에서 제공)는 [2020년 4월에 더 이상 사용되지 않는](https://about.gitlab.com/blog/gpg-key-for-gitlab-package-repositories-metadata-changing/) GPG 키를 사용합니다.

리포지토리를 업데이트하려고 하면 시스템이 다음 오류를 반환합니다:

```plaintext
[   21.023494] apt-setup[1198]: W: GPG error: https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
[   21.024033] apt-setup[1198]: E: The repository 'https://packages.gitlab.com/gitlab/gitlab-ee/debian buster InRelease' is not signed.
```

이를 수정하려면 새 GPG 키를 가져옵니다:

```shell
sudo apt install gpg-agent
sudo curl --fail --silent --show-error \
     --output /etc/apt/trusted.gpg.d/gitlab.asc \
     --url "https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab_new_gpg.key"
```

이제 [GitLab을 업데이트](#update-gitlab)할 수 있습니다. 자세한 내용은 [패키지 서명](https://docs.gitlab.com/omnibus/update/package_signatures/)에 대해 읽어보세요.
