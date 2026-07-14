---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Switchboard 온보딩 프로세스를 완료하여 GitLab Dedicated 인스턴스를 생성하고 액세스합니다.
title: GitLab Dedicated 인스턴스 생성
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated 관리 포털인 Switchboard를 사용하여 GitLab Dedicated 인스턴스를 생성합니다.

이 프로세스는 다음 단계를 포함합니다:

- Switchboard에 액세스합니다.
- 인스턴스를 생성합니다.
- 새 인스턴스에 액세스합니다.

## Switchboard에 액세스 {#get-access-to-switchboard}

Switchboard에 액세스하려면:

1. 계정 팀에 다음을 제공합니다:

   - 예상 사용자 수
   - [구매한 총 스토리지](storage_types.md#total-purchased-storage)
   - 리포지토리의 초기 스토리지 크기(GiB)
   - GitLab Dedicated 인스턴스를 생성하기 위해 Switchboard 액세스가 필요한 사용자의 이메일 주소
   - Geo 마이그레이션을 사용할지 여부
   - GitLab에서 암호화를 관리하도록 하는 대신 자신의 암호화 키를 사용하여 데이터를 보호할지 여부

   자신의 암호화 키를 사용하려면 GitLab이 키 구성을 위한 AWS 계정 ID를 제공합니다.

1. 임시 Switchboard 자격 증명이 포함된 초대 이메일을 확인합니다.

   > [!note]
   > Switchboard 자격 증명은 기존 GitLab.com 또는 GitLab Self-Managed 자격 증명과 별개입니다.

1. 임시 자격 증명을 사용하여 Switchboard에 로그인합니다.
1. 비밀번호를 업데이트하고 다중 인증(MFA)을 설정합니다.

## 인스턴스 생성 {#create-your-instance}

GitLab Dedicated 인스턴스를 생성하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. **Account details** 페이지에서 구독 설정을 검토하고 확인합니다:

   - **Reference architecture**:  예상 부하 및 사용 패턴을 기반으로 인스턴스의 인프라 크기 조정 계층입니다. 최대 권장 사용자 수로 명명됩니다(예: "최대 3,000명의 사용자"). 계약 요구사항을 기반으로 계정 팀에서 결정합니다. 자세한 내용은 [expected load](../../reference_architectures/_index.md#expected-load)를 참조하세요.
   - **구매한 총 스토리지**:  계약에 따라 구매한 총 스토리지 공간(리포지토리 및 object storage)입니다. 계정 팀에서 미리 결정합니다.
   - **리포지토리 스토리지**:  모든 리포지토리에 사용 가능한 총 스토리지 공간(예: 16 GiB)입니다. [Evaluate tool](https://gitlab.com/gitlab-org/professional-services-automation/tools/utilities/evaluate)을 사용한 초기 용량 계획 논의를 기반으로 합니다. 프로비저닝 후 증가할 수는 있지만 감소할 수는 없습니다.

   이러한 설정은 계약 및 계정 팀 논의에서 미리 결정합니다.

1. **구성** 페이지에서 필드를 완료합니다:

   - **Tenant name**:  인스턴스 URL(`<tenant_name>.gitlab-dedicated.com`)의 이름을 입력합니다. 사용자 지정 도메인을 구성하지 않는 한 프로비저닝 후 변경할 수 없습니다.
   - **Primary region**:  작업 및 데이터 스토리지를 위한 AWS 리전을 선택합니다. 모든 인프라(컴퓨팅, 스토리지, 데이터베이스)가 이 리전에서 프로비저닝되기 때문에 프로비저닝 후 변경할 수 없습니다.
   - **Primary region Availability Zone IDs (AZ IDs)**:  GitLab에서 가용성 영역을 선택하는 방법을 선택합니다:
     - **Default AZ IDs**(권장):  GitLab이 인스턴스의 가용성 영역을 선택합니다.
     - **Custom AZ IDs**:  기존 AWS 인프라와 일치하는 두 AZ ID를 선택합니다. PrivateLink 연결을 포함하여 기존 AWS 인프라를 특정 가용성 영역 내의 GitLab Dedicated 인스턴스에 연결하는 데 필요합니다. 프로비저닝 후 변경할 수 없습니다.
   - **Secondary region**:  선택사항. Geo 기반 재해 복구를 위한 AWS 리전을 선택합니다. 프로비저닝 후 변경할 수 없습니다. Geo 마이그레이션 방법을 사용하는 경우 필요하지 않습니다.
   - **Secondary region Availability Zone IDs (AZ IDs)**:  보조 리전을 구성하는 경우에만 사용할 수 있습니다. GitLab에서 가용성 영역을 선택하는 방법을 선택합니다:
     - **Default AZ IDs**(권장):  GitLab이 인스턴스의 가용성 영역을 선택합니다.
     - **Custom AZ IDs**:  기존 AWS 인프라와 일치하는 두 AZ ID를 선택합니다. 프로비저닝 후 변경할 수 없습니다.
   - **Backup region**:  백업 복제를 위한 AWS 리전을 선택합니다. 주 리전 및 보조 리전과 동일하거나 중복성을 높이기 위해 다를 수 있습니다. 백업 자격 증명 모음 및 복제가 프로비저닝 중에 구성되므로 프로비저닝 후 변경할 수 없습니다.
   - **Maintenance window**:  업데이트 및 [maintenance](../maintenance.md)를 위해 원하는 주간 4시간 창을 선택합니다. 옵션은 시간대(APAC, EU, US)와 일치합니다. 자세한 내용은 [GitLab Dedicated info portal](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/dedicated-info-portal/)을 참조하세요.

1. **보안** 페이지에서 인스턴스의 암호화를 구성합니다.

   GitLab이 자동으로 암호화 키를 관리하거나(권장) 규정 준수 요구사항을 위해 자신의 키를 관리할 수 있습니다.

   > [!warning]
   > 고객이 관리하는 암호화 키는 자신의 AWS 계정에서 추가 설정 및 지속적인 관리가 필요합니다. 인스턴스를 프로비저닝하기 전에 AWS KMS 키를 생성하고 구성해야 합니다. 구성되면 이러한 설정은 프로비저닝 후 변경할 수 없습니다.

   GitLab 관리 암호화(권장)의 경우:

   - 모든 AWS Key Management Service(KMS) 필드를 비워 둡니다. GitLab이 모든 서비스(백업, EBS 디스크, RDS 데이터베이스, S3 object storage, 고급 검색)에서 자동으로 암호화를 구성합니다.

   고객이 관리하는 암호화의 경우:

   1. [Create encryption keys](../encryption.md#create-encryption-keys).
   1. 선택사항. 보조 리전을 Geo 기반 재해 복구용으로 선택한 경우에만 [replica keys](../encryption.md#create-replica-keys)를 생성합니다.
   1. 각 키 또는 복제 키의 Amazon Resource Name(ARN)을 수집합니다. ARN 형식은 `arn:aws:kms:<REGION>:<ACCOUNT-ID>:key/<KEY-ID>`입니다.

      예: `arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012`

   1. 선택한 각 AWS 리전(주, 보조, 백업)에 대해 이 매핑을 사용하여 키 필드를 완료합니다:

      - **Primary region Default**:  주 리전의 키 ARN을 사용합니다.
      - **Secondary region Default**:  복제 키 ARN을 사용합니다(Geo용 보조 리전을 구성한 경우에만).
      - **Backup region Default**:  백업 리전의 키 ARN을 사용합니다. 백업 리전이 주 리전과 동일한 경우 동일한 키 ARN을 사용합니다.

   1. 각 서비스(**Backup**, **EBS (disks)**, **RDS (database)**, **S3 (object storage)**, **고급 검색**)의 경우:  해당 리전의 기본 키를 사용하거나 해당 서비스의 특정 KMS 키 ARN을 입력하거나 비워 둡니다. 서비스별 키는 해당 기본 키와 동일한 AWS 리전에서 가져야 합니다.
   1. 사용하지 않는 리전의 필드를 비워 둡니다. 예를 들어 주 리전만 있는 경우 보조 및 백업 리전 필드를 비워 둡니다.
   1. 계속하기 전에 모든 ARN이 올바른지 확인합니다.

1. 선택사항. **Geo migration secrets** 페이지에서 GitLab Self-Managed 인스턴스의 암호화된 비밀을 수집하고 업로드합니다:

   > [!note]
   > 이 단계는 계정 설정 중에 Geo 마이그레이션을 선택한 경우에만 필요합니다.

   1. 설치 유형에 대한 스크립트를 다운로드하고 GitLab Self-Managed 인스턴스에서 실행합니다.
   1. `migration_secrets.json.age` 파일을 업로드합니다.
   1. 선택사항. `ssh_host_keys.json.age` 파일을 업로드합니다(사용자 지정 도메인을 사용하려는 경우 권장).

   자세한 내용과 문제 해결 방법은 [migrate to GitLab Dedicated with Geo](../geo_migration.md)를 참조하세요.

1. **Tenant summary** 페이지에서 모든 구성 세부사항을 검토합니다.

   > [!warning]
   > 프로비저닝 후 이러한 설정을 변경할 수 없습니다:
   > - AWS KMS 키(BYOK) 구성
   > - AWS 리전(주, 보조, 백업 리전)
   > - AWS 가용성 영역 ID(주 및 보조 리전)
   > - 리포지토리 용량(증가만 가능)
   > - 테넌트 이름 및 URL

1. **Create tenant**를 선택합니다.

인스턴스를 프로비저닝하는 데 최대 3시간이 소요됩니다. 설정이 완료되면 확인 이메일을 받습니다.

## 인스턴스 액세스 {#access-your-instance}

GitLab Dedicated 인스턴스에 액세스하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. **Access your GitLab Dedicated instance** 배너에서 **자격 증명 보기**를 선택합니다.
1. 테넌트 URL 및 임시 루트 자격 증명을 복사합니다.

   > [!note]
   > 임시 루트 자격 증명은 한 번만 검색할 수 있습니다. Switchboard를 떠나기 전에 안전하게 저장합니다.

1. 테넌트 URL로 이동하여 임시 루트 자격 증명으로 로그인합니다.
1. [Change your temporary root password](../../../user/profile/user_passwords.md#change-your-password).
1. **운영자** 영역에서 [add the license key](../../license_file.md#add-license-in-the-admin-area).
1. Switchboard로 돌아가 필요에 따라 [add users](../configure_instance/users_notifications.md#add-switchboard-users)합니다.

## 다음 단계 {#next-steps}

업그레이드 및 유지보수를 위해 [release rollout schedule](../releases.md#release-rollout-schedule)을 검토합니다.

다음 기능이 필요한 경우 미리 계획하세요:

- [Inbound PrivateLink connections](../configure_instance/network_security.md#inbound-privatelink-connections)
- [Outbound PrivateLink connections](../configure_instance/network_security.md#outbound-privatelink-connections)
- [SAML SSO](../configure_instance/authentication/saml.md)
- [Custom domains](../configure_instance/network_security.md#custom-domains)

모든 구성 옵션은 [configure your GitLab Dedicated instance](../configure_instance/_index.md)를 참조하세요.

> [!note]
> GitLab Dedicated 인스턴스는 GitLab Self-Managed 인스턴스와 동일한 기본 설정을 사용합니다.
>
> GitLab 18.0부터 [GitLab Duo Core](../../../subscriptions/subscription-add-ons.md#gitlab-duo-core) 기능이 새 인스턴스에 기본적으로 켜집니다. 데이터 거주 요구사항 또는 AI 사용 정책을 준수하려면 [turn off GitLab Duo Core](../../../user/gitlab_duo/turn_on_off.md#for-an-instance)할 수 있습니다.
