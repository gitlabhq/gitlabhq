---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicated 인스턴스의 애플리케이션 로그에 대한 액세스를 관리합니다.
title: GitLab Dedicated의 애플리케이션 로그에 액세스
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated는 자동으로 인스턴스의 애플리케이션 로그를 프라이빗 Amazon S3 버킷에 전달합니다. 이러한 로그는 모니터링, 문제 해결 및 규정 준수 목적을 위해 인프라 및 애플리케이션 데이터를 모두 포함합니다.

S3 버킷에는 다음과 같은 로그가 포함됩니다:

- GitLab이 관리하는 AWS KMS 키를 사용하여 무기한 저장되고 암호화됩니다.
- `YYYY/MM/DD/HH` 형식으로 날짜별로 정렬됩니다.
- [Amazon Kinesis Data Firehose](https://aws.amazon.com/firehose/)를 사용하여 실시간으로 스트리밍됩니다.

[자체 암호화 키](encryption.md#customer-managed-encryption)를 사용하는 경우 애플리케이션 로그는 사용자가 제공한 키가 아닌 GitLab 관리 키를 사용합니다.

## 애플리케이션 로그 액세스 보기 및 관리 {#view-and-manage-application-log-access}

애플리케이션 로그에 대한 읽기 전용 액세스 권한이 있는 AWS IAM 사용자 및 역할을 추가, 편집 또는 제거할 수 있습니다.

애플리케이션 로그에 액세스하여 다음을 수행할 수 있습니다:

- GitLab Dedicated 인스턴스를 모니터링하고 문제를 해결합니다.
- 자동화된 로그 처리 및 모니터링 시스템을 구성합니다.
- S3 버킷에서 로그를 검색하는 도구를 설정합니다.
- 규정 준수 보고를 위해 감사 추적을 유지합니다.

전제 조건:

- 액세스가 필요한 각 AWS 사용자 또는 역할의 전체 ARN 경로가 있어야 합니다.

> [!note]
> IAM 사용자 및 역할 ARN만 사용할 수 있습니다. Security Token Service(STS) ARN 및 와일드카드는 지원되지 않습니다.

로그 액세스를 관리하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **Resource access**를 확장합니다.
1. **Application logs** 아래의 **Log access ARNs** 섹션에서:

   - 액세스를 추가하려면:  **Add ARN**를 선택하고 전체 ARN 경로를 입력한 다음 **저장**을 선택합니다. 예를 들어:
     - 사용자: `arn:aws:iam::123456789012:user/username`
     - 역할: `arn:aws:iam::123456789012:role/rolename`
   - 액세스를 편집하려면:  ARN 옆에서 연필 아이콘({{< icon name="pencil" >}})을 선택하고 ARN을 업데이트한 다음 **저장**을 선택합니다.
   - 액세스를 제거하려면:  ARN 옆에서 휴지통 아이콘({{< icon name="remove" >}})을 선택한 다음 **삭제**를 선택합니다.

1. **Logs S3 bucket name**을 복사합니다. 권한이 있는 사용자 또는 역할이 이 버킷 이름을 사용하여 로그에 액세스합니다.

ARN 권한을 구성하고 버킷 이름을 사용자에게 제공한 후 사용자는 S3 버킷의 모든 객체에 액세스할 수 있습니다. 액세스를 확인하려면 [AWS CLI](https://aws.amazon.com/cli/)를 사용합니다.

AWS에서 S3 버킷에 액세스하는 방법에 대한 자세한 내용은 [Amazon S3 버킷 액세스](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-bucket-intro.html)를 참조하세요.

## S3 이벤트 알림 사용 {#enable-s3-event-notifications}

GitLab Dedicated 로깅 버킷에서 S3 이벤트 알림을 사용하도록 설정하여 보안 모니터링 시스템과 통합할 수 있습니다. 로그 파일이 생성될 때 알림이 전송됩니다.

S3 이벤트 알림은 다음으로 알림을 보낼 수 있습니다:

- Amazon Simple Queue Service(SQS) 대기열
- Amazon Simple Notification Service(SNS) 토픽

대상 리소스는 GitLab Dedicated 인스턴스와 동일한 리전에 있어야 합니다.

S3 이벤트 알림을 사용하도록 설정하려면:

1. [지원 티켓 생성](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)합니다.
1. 지원 요청에 다음을 포함합니다:

   - 기본 리전, 보조 리전 또는 둘 다에 대해 알림을 구성할지 여부.
   - 알림에 SQS 또는 SNS를 사용할지 여부.
   - SQS 대기열 또는 SNS 토픽의 ARN.

1. GitLab Support가 필요한 IAM 정책을 제공한 후 이를 SQS 대기열 또는 SNS 토픽에 연결합니다.

그러면 GitLab Support가 S3 로그 버킷에서 S3 이벤트 알림 구성을 완료합니다.
