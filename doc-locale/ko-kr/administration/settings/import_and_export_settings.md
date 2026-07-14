---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 가져오기 및 내보내기 설정
description: "GitLab Self-Managed 인스턴스에서 가져오기 소스, 내보내기 제한, 파일 크기, 사용자 매핑 및 자리 표시자 사용자에 대한 설정을 구성합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

가져오기 및 내보내기와 관련된 기능에 대한 설정입니다.

## 허용된 가져오기 소스 구성 {#configure-allowed-import-sources}

다른 시스템에서 프로젝트를 가져오기 전에 해당 시스템의 [가져오기 소스](../../user/gitlab_com/_index.md#default-import-sources)를 활성화해야 합니다.

1. 관리자 액세스 수준을 가진 사용자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정** 섹션을 확장합니다.
1. 허용할 **소스 가져오기**를 각각 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 사용하지 않는 가져오기 소스 비활성화 {#disable-unused-import-sources}

신뢰할 수 있는 소스에서만 프로젝트를 가져옵니다. 신뢰할 수 없는 소스에서 프로젝트를 가져오면 공격자가 민감한 데이터를 도용할 수 있습니다. 예를 들어, 악의적인 `.gitlab-ci.yml` 파일이 있는 가져온 프로젝트는 공격자가 그룹 CI/CD 변수를 유출하도록 허용할 수 있습니다.

GitLab Self-Managed 관리자는 필요하지 않은 가져오기 소스를 비활성화하여 공격 표면을 줄일 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정**을 확장합니다.
1. **소스 가져오기**로 스크롤합니다.
1. 필요하지 않은 가져오기 도구의 체크박스를 선택 해제합니다.

## 프로젝트 내보내기 활성화 {#enable-project-export}

[프로젝트 및 해당 데이터](../../user/project/settings/import_export.md#export-a-project-and-its-data)의 내보내기를 활성화하려면:

1. 관리자 액세스 수준을 가진 사용자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정** 섹션을 확장합니다.
1. **프로젝트 내보내기**로 스크롤합니다.
1. **활성화** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 직접 전송을 통한 그룹 및 프로젝트 마이그레이션 활성화 {#enable-migration-of-groups-and-projects-by-direct-transfer}

{{< history >}}

- GitLab 15.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/383268)되었습니다.
- GitLab 18.3에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/461326)됩니다.

{{< /history >}}

> [!warning]
> GitLab 16.1 이상 버전에서는 [예약된 스캔 실행 정책](../../user/application_security/policies/scan_execution_policies.md)과 함께 직접 전송을 사용해서는 안 됩니다. 직접 전송을 사용하는 경우 먼저 GitLab 16.2로 업그레이드하고 적용 중인 프로젝트에서 보안 정책 봇이 활성화되어 있는지 확인합니다.

기본적으로 직접 전송을 통한 그룹 및 프로젝트 마이그레이션은 비활성화되어 있습니다. 직접 전송을 통한 그룹 및 프로젝트 마이그레이션을 활성화하려면:

1. 관리자 액세스 수준을 가진 사용자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정** 섹션을 확장합니다.
1. **직접 전송으로 GitLab 그룹 및 프로젝트 마이그레이션 허용**으로 스크롤합니다.
1. **활성화** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

API에서 동일한 설정을 [사용할 수 있습니다](../../api/settings.md#available-settings). `bulk_import_enabled` 속성으로 사용됩니다.

## 자동 관리자 내보내기 활성화 {#enable-silent-admin-exports}

{{< history >}}

- GitLab 17.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151278) 되었습니다. [플래그](../feature_flags/_index.md) `export_audit_events`(이름) 포함. 기본적으로 비활성화됩니다. 기본적으로 비활성화됨.
- GitLab 17.1에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153351)됩니다. 기능 플래그 `export_audit_events` 제거됨.
- GitLab 17.1의 파일 내보내기 다운로드에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152143)되었습니다.

{{< /history >}}

자동 관리자 내보내기를 활성화하여 인스턴스 관리자가 [감사 이벤트](../compliance/audit_event_reports.md) 를 트리거할 때 또는 내보내기 파일을 다운로드할 때 [프로젝트 또는 그룹 파일 내보내기](../../user/project/settings/import_export.md)를 방지합니다. 관리자가 아닌 사용자의 내보내기는 여전히 감사 이벤트를 생성합니다.

자동 관리자 프로젝트 및 그룹 파일 내보내기를 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택한 다음 **가져오기 및 내보내기 설정**을 확장합니다.
1. **Silent exports by admins**로 스크롤합니다.
1. **활성화** 체크박스를 선택합니다.

## 관리자에 대한 기여도 매핑 허용 {#allow-contribution-mapping-to-administrators}

{{< history >}}

- GitLab 17.5에 [플래그](../feature_flags/_index.md) `importer_user_mapping`(이름) 포함하여 도입되었습니다. 기본적으로 비활성화됨.
- GitLab 17.7에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175371)됩니다.
- GitLab 18.3에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/508944)됩니다. 기능 플래그 `importer_user_mapping` 제거됨.

{{< /history >}}

가져온 사용자 기여도를 관리자에게 매핑하도록 허용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택한 다음 **가져오기 및 내보내기 설정**을 확장합니다.
1. **Allow contribution mapping to administrators**으로 스크롤합니다.
1. **활성화** 체크박스를 선택합니다.

## 관리자가 자리 표시자 사용자를 다시 할당할 때 확인 건너뛰기 {#skip-confirmation-when-administrators-reassign-placeholder-users}

{{< history >}}

- GitLab 18.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/534330) 되었습니다. [플래그](../feature_flags/_index.md) `importer_user_mapping_allow_bypass_of_confirmation`(이름) 포함. 기본적으로 비활성화됩니다. 기본적으로 비활성화됨.
- GitLab 18.6에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/541373)됩니다. 기능 플래그 `importer_user_mapping_allow_bypass_of_confirmation` 제거됨.

{{< /history >}}

전제 조건:

- GitLab 인스턴스에서 [사용자 가장이 비활성화되지 않은](../../api/rest/authentication.md#disable-impersonation) 상태인지 확인합니다.

관리자가 자리 표시자 사용자를 다시 할당할 때 확인을 건너뛰려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정**을 확장합니다.
1. **Skip confirmation when administrators reassign placeholder users** 아래에서 **활성화** 체크박스를 선택합니다.

이 설정이 활성화되면 관리자는 다음 상태 중 하나를 가진 봇이 아닌 사용자에게 기여도 및 멤버십을 다시 할당할 수 있습니다:

- `active`
- `banned`
- `blocked`
- `blocked_pending_approval`
- `deactivated`
- `ldap_blocked`

## 최대 내보내기 크기 {#max-export-size}

{{< history >}}

- GitLab 15.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86124)되었습니다.

{{< /history >}}

GitLab에서 내보내기의 최대 파일 크기를 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택한 다음 **가져오기 및 내보내기 설정**을 확장합니다.
1. **최대 내보내기 크기 (MiB)**의 값을 변경하여 증가하거나 감소합니다.

## 최대 가져오기 크기 {#max-import-size}

GitLab에서 가져오기의 최대 파일 크기를 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정**을 확장합니다.
1. **최대 가져오기 크기 (MiB)**의 값을 변경하여 증가하거나 감소합니다.

이 설정은 [GitLab 내보내기 파일에서 가져온](../../user/project/settings/import_export.md#import-a-project-and-its-data) 리포지토리에만 적용됩니다.

웹 서버에 대해 구성된 값보다 큰 크기를 선택하면 오류가 발생할 수 있습니다. 자세한 내용은 [문제 해결 섹션](account_and_limit_settings.md#troubleshooting)을 참조하세요.

GitLab.com 리포지토리 크기 제한에 대해서는 [계정 및 제한 설정](../../user/gitlab_com/_index.md#account-and-limit-settings)을 읽으세요.

## 가져오기의 최대 원격 파일 크기 {#maximum-remote-file-size-for-imports}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)되었습니다.

{{< /history >}}

기본적으로 외부 객체 저장소(예: AWS)에서 가져오기의 최대 원격 파일 크기는 10GiB입니다.

이 설정을 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정**을 확장합니다.
1. **가져오기 리모트 파일 최대 크기(MiB)**에서 값을 입력합니다. `0`로 설정하면 파일 크기 제한이 없습니다.

## 직접 전송을 통한 가져오기의 최대 다운로드 파일 크기 {#maximum-download-file-size-for-imports-by-direct-transfer}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)되었습니다.

{{< /history >}}

기본적으로 직접 전송을 통한 가져오기의 최대 다운로드 파일 크기는 5GiB입니다.

이 설정을 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정**을 확장합니다.
1. **최대 다운로드 파일 크기 (MiB)**에서 값을 입력합니다. `0`로 설정하면 파일 크기 제한이 없습니다.

## 가져온 아카이브의 최대 압축 해제 파일 크기 {#maximum-decompressed-file-size-for-imported-archives}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128218)되었습니다.
- **Maximum decompressed file size for archives from imports** 필드는 GitLab 16.4에서 **Maximum decompressed size**에서 [이름이 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130081)되었습니다.

{{< /history >}}

[파일 내보내기](../../user/project/settings/import_export.md) 또는 [직접 전송](../../user/group/import/_index.md)을 사용하여 프로젝트를 가져올 때 가져온 아카이브의 최대 압축 해제 파일 크기를 지정할 수 있습니다. 기본값은 25GiB입니다.

압축된 파일을 가져올 때 압축 해제된 크기는 최대 압축 해제 파일 크기 제한을 초과할 수 없습니다. 압축 해제된 크기가 구성된 제한을 초과하면 다음 오류가 반환됩니다:

```plaintext
Decompressed archive size validation failed.
```

이 설정을 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정**을 확장합니다.
1. **가져온 아카이브의 최대 압축 해제 파일 크기(MiB)**에 대해 다른 값을 설정합니다.

## 아카이빙 파일 압축 풀기 최대 시간 {#timeout-for-decompressing-archived-files}

{{< history >}}

- GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128218)되었습니다.

{{< /history >}}

[프로젝트를 가져올](../../user/project/settings/import_export.md) 때 가져온 아카이브를 압축 풀기 위한 최대 시간 초과를 지정할 수 있습니다. 기본값은 210초입니다.

GitLab에서 가져오기의 최대 압축 해제 파일 크기를 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정**을 확장합니다.
1. **아카이빙 파일 압축 풀기 최대 시간 (초)**에 대해 다른 값을 설정합니다.

## 동시 가져오기 작업의 최대 개수 {#maximum-number-of-simultaneous-import-jobs}

{{< history >}}

- GitLab 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)되었습니다.

{{< /history >}}

다음에 대해 동시에 실행되는 가져오기 작업의 최대 개수를 지정할 수 있습니다:

- [GitHub 가져오기 도구](../../user/project/import/github.md)
- [Bitbucket Cloud 가져오기 도구](../../user/import/bitbucket_cloud.md)
- [Bitbucket Server 가져오기 도구](../../user/import/bitbucket_server.md)

작업 제한은 서버 과부하를 방지하기 위해 머지 리퀘스트에 대한 하드 코딩된 제한이 있기 때문에 머지 리퀘스트를 가져올 때는 적용되지 않습니다.

기본 작업 제한:

- GitHub 가져오기 도구의 경우 1000입니다.
- Bitbucket Cloud 및 Bitbucket Server 가져오기 도구의 경우 100입니다. Bitbucket 가져오기 도구는 아직 좋은 기본 제한을 결정하지 못했기 때문에 낮은 기본 제한을 가지고 있습니다. 인스턴스 관리자는 더 높은 제한으로 실험해야 합니다.

이 설정을 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **가져오기 및 내보내기 설정**을 확장합니다.
1. 원하는 가져오기 도구에 대해 **Maximum number of simultaneous import jobs**에 대해 다른 값을 설정합니다.

## 동시 배치 내보내기 작업의 최대 개수 {#maximum-number-of-simultaneous-batch-export-jobs}

{{< history >}}

- GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169122)되었습니다.

{{< /history >}}

직접 전송 내보내기는 상당한 양의 리소스를 소비할 수 있습니다. 데이터베이스 또는 Sidekiq 프로세스를 사용하지 않도록 방지하려면 관리자는 `concurrent_relation_batch_export_limit` 설정을 구성할 수 있습니다.

기본값은 `8` 작업입니다. 이는 [최대 40RPS 또는 2,000명의 사용자를 위한 참조 아키텍처](../reference_architectures/2k_users.md)에 해당합니다. `PG::QueryCanceled: ERROR: canceling statement due to statement timeout` 오류가 발생하거나 Sidekiq 메모리 제한으로 인해 작업이 중단되는 경우 이 번호를 줄이는 것이 좋습니다. 충분한 리소스가 있으면 이 번호를 증가시켜 더 많은 동시 내보내기 작업을 처리할 수 있습니다.

이 설정을 수정하려면 `/api/v4/application/settings`에 `concurrent_relation_batch_export_limit`로 API 요청을 보냅니다. 자세한 내용은 [애플리케이션 설정 API](../../api/settings.md)를 참조하세요.

### 배치 내보내기 크기 {#export-batch-size}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607)되었습니다.

{{< /history >}}

메모리 사용량 및 데이터베이스 로드를 더 관리하려면 `relation_export_batch_size` 설정을 사용하여 내보내기 작업 중 각 배치에서 처리되는 레코드 수를 제어합니다.

기본값은 배치당 `50` 레코드입니다. 이 설정을 수정하려면 `/api/v4/application/settings`에 `relation_export_batch_size`로 API 요청을 보냅니다. 자세한 내용은 [애플리케이션 설정 API](../../api/settings.md)를 참조하세요.

## 문제 해결 {#troubleshooting}

## 오류: `Help page documentation base url is blocked: execution expired` {#error-help-page-documentation-base-url-is-blocked-execution-expired}

[가져오기 소스](#configure-allowed-import-sources)와 같은 애플리케이션 설정을 활성화할 때 `Help page documentation base url is blocked: execution expired` 오류가 발생할 수 있습니다. 이 오류를 해결하려면:

1. `docs.gitlab.com` 또는 [리디렉션 도움말 설명서 페이지 URL](help_page.md#redirect-help-pages) 을 [허용 목록](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)에 추가합니다.
1. **변경 사항 저장**을 선택합니다.

## 관련 항목 {#related-topics}

- [GitLab으로 가져오기 및 마이그레이션](../../user/import/_index.md).
- [Sidekiq 구성 가져오기](../sidekiq/configuration_for_imports.md).
- [여러 Sidekiq 프로세스 실행](../sidekiq/extra_sidekiq_processes.md).
- [특정 작업 클래스 처리](../sidekiq/processing_specific_job_classes.md).
