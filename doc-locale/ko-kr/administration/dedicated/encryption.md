---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab-관리형 키 또는 자신의 암호화 키를 사용하여 GitLab Dedicated의 암호화를 구성합니다.
title: GitLab Dedicated 암호화
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated는 AWS Key Management Service(KMS)를 사용하여 Advanced Encryption Standard(AES) 256비트 암호화로 모든 저장 데이터와 전송 데이터를 암호화합니다.

## 저장 데이터 암호화 {#encryption-at-rest}

저장된 모든 데이터는 엔벨로프 암호화를 사용하며, 데이터는 여러 암호화 키 계층으로 보호됩니다.

각 서비스는 암호화를 다르게 구현합니다:

| 서비스                 | 암호화 방법 |
| ----------------------- | ----------------- |
| Amazon S3(SSE-S3)      | 각 객체가 자신의 고유 키로 암호화되고 AWS 관리형 루트 키로 암호화되는 객체 단위 암호화를 사용합니다. |
| Amazon EBS              | KMS에서 생성한 데이터 암호화 키(DEK)를 사용한 볼륨 수준 암호화를 사용합니다. |
| Amazon RDS(PostgreSQL) | KMS에서 생성한 DEK를 사용한 스토리지 수준 암호화를 사용합니다. |
| KMS                     | AWS 관리형 키 계층에서 암호화 키를 관리하며, 하드웨어 보안 모듈(HSM)로 보호됩니다. |

이 엔벨로프 암호화 시스템에서:

- 데이터는 데이터 암호화 키로 암호화됩니다.
- 데이터 암호화 키 자체는 암호화 키로 암호화됩니다.
- 암호화된 데이터 암호화 키는 암호화된 데이터와 함께 저장됩니다.
- 암호화 키는 Key Management Service에 유지되며 암호화되지 않은 형태로 노출되지 않습니다.
- 모든 암호화 키는 하드웨어 보안 모듈로 보호됩니다.

이 엔벨로프 암호화 프로세스는 KMS가 각 암호화 작업에 대해 데이터 암호화 키를 생성하도록 함으로써 작동합니다. 데이터 암호화 키(DEK)는 데이터를 직접 암호화하는 한편, DEK 자체는 암호화 키로 암호화되어 데이터 주변에 보안 엔벨로프를 만듭니다.

## 전송 중 암호화 {#encryption-in-transit}

전송 중인 모든 데이터는 전송 계층 보안(TLS)을 사용하며, 서비스 간 및 네트워크 연결을 통해 이동할 때 데이터를 보호하는 강력한 암호 그룹을 사용합니다.

각 서비스는 TLS를 사용합니다:

| 서비스                 | 암호화 방법 |
| ----------------------- | ----------------- |
| 웹 애플리케이션         | 클라이언트-서버 통신을 위한 TLS 1.2/1.3 |
| Amazon S3               | HTTPS 액세스를 위한 TLS 1.2/1.3 |
| Amazon EBS              | AWS 데이터 센터 간 데이터 복제를 위한 TLS |
| Amazon RDS(PostgreSQL) | 데이터베이스 연결을 위한 Secure Sockets Layer(SSL)/TLS(최소 TLS 1.2) |
| AWS KMS                 | API 요청을 위한 TLS |

TLS 인증서는 기본적으로 생성되고 관리됩니다. 사용자 지정 TLS 인증서를 구성하여 조직의 인증서를 대신 사용할 수 있습니다. 자세한 내용은 [외부 서비스용 사용자 지정 인증 기관](configure_instance/network_security.md#custom-certificate-authorities-for-external-services)을 참고하세요.

## 암호화 옵션 {#encryption-options}

다음 암호화 옵션을 사용할 수 있습니다:

- GitLab 관리형 암호화(기본값):  GitLab은 구성이 필요 없이 모든 암호화 설정을 처리합니다.
- 고객 관리형 암호화:  키 관리 및 액세스 정책을 추가로 제어하기 위해 자신의 암호화 키를 제공하고 제어합니다.

### GitLab 관리형 암호화 {#gitlab-managed-encryption}

기본적으로 GitLab은 인스턴스의 모든 암호화 설정을 처리합니다. 설정이 필요 없으며 GitLab은 모든 서비스 전체에서 자동으로 암호화를 구성합니다.

키는 암호화 키에 대한 무단 액세스를 방지하고 데이터가 암호화 상태로 유지되도록 하는 AWS Hardware Security Module(HSM) 기반 보안 제어로 보호됩니다.

### 고객 관리형 암호화 {#customer-managed-encryption}

> [!warning]
> 고객 관리형 암호화 키는 인스턴스 온보딩 중에 구성해야 합니다. 활성화되면 프로비저닝 후에는 사용 중지하거나 변경할 수 없습니다.

고객 관리형 암호화 키는 저장 데이터를 보호하는 키에 대한 직접적인 제어를 제공합니다.

AWS KMS 키를 자신의 AWS 계정에서 생성 및 관리한 다음, [인스턴스를 생성](create_instance/_index.md)할 때 구성합니다. GitLab은 데이터 암호화에 키를 사용하지만, AWS 계정을 통해 키 액세스 정책, 로테이션 및 수명 주기 관리에 대한 완전한 제어를 유지합니다.

다양한 수준에서 키를 구성할 수 있습니다:

- 모든 리전의 모든 서비스에 대한 하나의 키:  Geo 인스턴스가 있는 각 리전에 복제본이 있는 단일 다중 리전 키를 사용합니다.
- 각 리전 내 모든 서비스에 대한 하나의 키:  Geo 인스턴스가 있는 각 리전에 대해 별도의 키를 사용합니다.
- 리전당 서비스별 키:  각 리전 내에서 다양한 서비스(백업, EBS, RDS, S3, 고급 검색)에 대해 다양한 키를 사용합니다.

#### 암호화 키 생성 {#create-encryption-keys}

키 로테이션 요구 사항으로 인해 인스턴스는 AWS가 암호화 키 자료를 생성하는 키(즉, `AWS_KMS` 원본 유형)만 지원하며, 자신의 키 자료를 가져오는 키는 지원하지 않습니다. 자세한 내용은 [다중 리전 기본 키 생성](https://docs.aws.amazon.com/kms/latest/developerguide/create-primary-keys.html)을 참고하세요.

전제 조건:

- GitLab Dedicated 계정 팀으로부터 GitLab AWS 계정 ID를 받았어야 합니다.

자신의 암호화 키를 생성하려면:

1. AWS Management Console에 로그인하고 KMS 서비스로 이동합니다.
1. 키를 생성할 리전을 선택합니다.
1. **Create key**을 선택합니다.
1. **Configure key** 섹션에서:
   - **Key type**은 **Symmetric**을 선택합니다.
   - **Key usage**은 **Encrypt and decrypt**를 선택합니다.
   - **Advanced options** 아래:
     - **Key material origin**은 **AWS_KMS**를 선택합니다.
     - **Regionality**은 **Multi-Region key**를 선택합니다.
1. 키에 대한 별칭, 설명 및 태그를 입력합니다.
1. 키를 관리할 수 있는 IAM 사용자 및 역할을 선택합니다.
1. 선택사항. **Allow key administrators to delete this key**을 선택 해제하여 실수로 인한 삭제를 방지합니다.
1. **Define key usage permissions** 페이지의 **Other AWS accounts** 섹션에서 계정 팀에서 제공한 GitLab AWS 계정 ID를 입력합니다.
1. KMS 키 정책이 다음 예제와 일치하는지 확인합니다. 플레이스홀더 값을 자신의 계정 ID 및 사용자 이름으로 바꿉니다. 이 정책을 초과하는 추가 제한은 지원되지 않습니다.

   > [!note]
   > `kms:GrantIsForAWSResource`과 같이 AWS가 자동으로 생성할 수 있는 조건이나 제한을 포함한 추가 조건이나 제한을 제거합니다.

```json
{
    "Version": "2012-10-17",
    "Id": "byok-key-policy",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:user/<CUSTOMER-USER>"
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion",
                "kms:ReplicateKey",
                "kms:UpdatePrimaryRegion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*"
        }
    ]
}
```

#### 복제본 키 생성 {#create-replica-keys}

다양한 리전의 여러 Geo 인스턴스에서 동일한 암호화 키를 사용하려면 복제본 키를 생성합니다. 자세한 내용은 [다중 리전 복제본 키 생성](https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-replicate.html)을 참고하세요.

전제 조건:

- 다중 리전 기본 키를 생성했어야 합니다.
- 다양한 AWS 리전에 추가 Geo 인스턴스가 있어야 합니다.

복제본 키를 생성하려면:

1. AWS KMS 콘솔에서 이전에 생성한 키를 선택합니다.
1. **Regionality** 탭을 선택합니다.
1. **Related multi-Region keys** 섹션에서 **Create new replica keys**을 선택합니다.
1. 추가 Geo 인스턴스가 있는 AWS 리전을 선택합니다.
1. 원본 별칭을 유지하거나 복제본 키에 대해 다른 별칭을 입력합니다.
1. 선택사항. 설명을 입력하고 태그를 추가합니다.
1. 복제본 키를 관리할 수 있는 Identity and Access Management(IAM) 사용자 및 역할을 선택합니다.
1. 선택사항. **Allow key administrators to delete this key** 체크박스를 선택하거나 선택 해제합니다.
1. **Define key usage permissions** 페이지에서 GitLab AWS 계정이 **Other AWS accounts** 아래 나열되어 있는지 확인합니다.
1. 정책 및 설정을 검토합니다.
1. **Finish**를 선택합니다.
