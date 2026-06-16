---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: X.509 서명 Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[X.509로 커밋에 서명](../../user/project/repository/signed_commits/x509.md)할 때 신뢰 앵커가 변경될 수 있으며 데이터베이스에 저장된 서명을 업데이트해야 합니다.

## 모든 X.509 서명 업데이트 {#update-all-x509-signatures}

이 작업은:

- 모든 X.509 서명된 커밋을 반복합니다.
- 현재 인증서 저장소를 기반으로 검증 상태를 업데이트합니다.
- 서명에 대한 데이터베이스 항목만 수정합니다.
- 커밋은 변경되지 않습니다.

모든 X.509 서명을 업데이트하려면 다음을 실행합니다:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:x509:update_signatures
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## 문제 해결 {#troubleshooting}

X.509 인증서로 작업할 때 다음 문제가 발생할 수 있습니다.

### 오류: 서명 업데이트 중 `GRPC::DeadlineExceeded` {#error-grpcdeadlineexceeded-during-signature-updates}

X.509 서명을 업데이트할 때 `GRPC::DeadlineExceeded` 오류가 나타날 수 있습니다.

이 문제는 네트워크 시간 초과 또는 연결 문제로 인해 작업이 완료되지 않을 때 발생합니다.

이 문제를 해결하려면 작업이 기본적으로 각 서명에 대해 최대 5번까지 자동으로 재시도합니다. `GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT` 환경 변수를 설정하여 재시도 제한을 사용자 지정할 수 있습니다:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT=2 sudo gitlab-rake gitlab:x509:update_signatures
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT=2 sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}
