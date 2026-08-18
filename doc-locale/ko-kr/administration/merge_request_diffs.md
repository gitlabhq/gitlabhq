---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 인스턴스에서 머지 리퀘스트 차이에 대한 외부 저장소를 구성합니다.
title: 머지 리퀘스트 차이 저장소
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

머지 리퀘스트와 관련된 차이의 크기 제한 사본입니다. 머지 리퀘스트를 볼 때 성능 최적화를 위해 가능한 한 이러한 사본에서 차이를 가져옵니다.

기본적으로 GitLab은 머지 리퀘스트 차이를 `merge_request_diff_files`라는 테이블에 데이터베이스에 저장합니다. 더 큰 설치의 경우 이 테이블이 너무 커질 수 있으며, 이 경우 외부 저장소로 전환해야 합니다.

머지 리퀘스트 차이는 다음과 같이 저장할 수 있습니다:

- 완전히 [디스크에](#using-external-storage) 저장합니다.
- 완전히 [객체 저장소에](#using-object-storage) 저장합니다.
- 데이터베이스의 현재 차이와 [객체 저장소의 오래된 차이](#alternative-in-database-storage)입니다.

## 외부 저장소 사용 {#using-external-storage}

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. 외부 차이는 `/var/opt/gitlab/gitlab-rails/shared/external-diffs`에 저장됩니다. 경로를 변경하려면, 예를 들어 `/mnt/storage/external-diffs`(으)로, `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['external_diffs_storage_path'] = "/mnt/storage/external-diffs"
   ```

1. 파일을 저장하고 [GitLab을 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다. GitLab은 기존 머지 리퀘스트 차이를 외부 저장소로 마이그레이션합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   external_diffs:
     enabled: true
   ```

1. 외부 차이는 `/home/git/gitlab/shared/external-diffs`에 저장됩니다. 경로를 변경하려면, 예를 들어 `/mnt/storage/external-diffs`(으)로, `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   external_diffs:
     enabled: true
     storage_path: /mnt/storage/external-diffs
   ```

1. 파일을 저장하고 [GitLab을 다시 시작](restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다. GitLab은 기존 머지 리퀘스트 차이를 외부 저장소로 마이그레이션합니다.

{{< /tab >}}

{{< /tabs >}}

## 객체 저장소 사용 {#using-object-storage}

> [!warning]
> 객체 저장소로의 마이그레이션은 되돌릴 수 없습니다.

디스크에 외부 차이를 저장하는 대신 AWS S3과 같은 객체 저장소를 사용해야 합니다. 이 구성은 유효하게 사전 구성된 AWS 자격 증명에 따라 달라집니다.

> [!note]
> 통합 객체 저장소 설정에서 외부 차이에 대해 객체 저장소를 구성하면 머지 리퀘스트 차이에 대한 외부 저장소가 자동으로 활성화되지 않습니다. `external_diffs_enabled`을(를) `true`(으)로 명시적으로 설정해야 합니다.

외부 차이에 대해 객체 저장소를 구성하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. [통합 객체 저장소 설정](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을(를) 구성합니다.
1. 파일을 저장하고 [GitLab을 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   external_diffs:
     enabled: true
   ```

1. [통합 객체 저장소 설정](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을(를) 구성합니다.
1. 파일을 저장하고 [GitLab을 다시 시작](restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

GitLab을 재구성하거나 다시 시작한 후 기존 머지 리퀘스트 차이가 외부 저장소로 마이그레이션됩니다.

자세한 내용은 [객체 저장소](object_storage.md)를 참조하세요.

## 대안: 데이터베이스 내 저장소 {#alternative-in-database-storage}

외부 차이를 활성화하면 별도 작업에서 머지 리퀘스트 성능이 저하될 수 있습니다. 현재 차이를 데이터베이스에 유지하면서 오래된 차이만 외부에 저장하여 타협점에 도달할 수 있습니다.

이 기능을 활성화하려면 다음 단계를 수행합니다:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['external_diffs_when'] = 'outdated'
   ```

1. 파일을 저장하고 [GitLab을 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   external_diffs:
     enabled: true
     when: outdated
   ```

1. 파일을 저장하고 [GitLab을 다시 시작](restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

이 기능이 활성화되면 차이는 초기에 외부가 아닌 데이터베이스에 저장됩니다. 다음 조건 중 하나가 참이 되면 외부 저장소로 이동됩니다:

- 머지 리퀘스트 차이의 최신 버전이 존재합니다
- 머지 리퀘스트가 7일 이상 전에 병합되었습니다
- 머지 리퀘스트가 7일 이상 전에 닫혔습니다

이러한 규칙은 자주 액세스되는 차이만 데이터베이스에 저장하여 공간과 성능 간의 균형을 유지합니다. 액세스 가능성이 낮은 차이는 대신 외부 저장소로 이동됩니다.

## 외부 저장소에서 객체 저장소로 전환 {#switching-from-external-storage-to-object-storage}

자동 마이그레이션은 데이터베이스에 저장된 차이를 이동하지만 저장소 유형 간에 차이를 이동하지 않습니다. 외부 저장소에서 객체 저장소로 전환하려면:

1. 로컬 또는 NFS 저장소에 저장된 파일을 수동으로 객체 저장소로 이동합니다.
1. 이 Rake 작업을 실행하여 데이터베이스의 위치를 변경합니다.

   Linux 패키지 설치의 경우:

   ```shell
   sudo gitlab-rake gitlab:external_diffs:force_object_storage
   ```

   자체 컴파일 설치의 경우:

   ```shell
   sudo -u git -H bundle exec rake gitlab:external_diffs:force_object_storage RAILS_ENV=production
   ```

   기본적으로 `sudo`은(는) 기존 환경 변수를 보존하지 않습니다. 접두사로 추가하지 말고 추가해야 하며, 다음과 같습니다:

   ```shell
   sudo gitlab-rake gitlab:external_diffs:force_object_storage START_ID=59946109 END_ID=59946109 UPDATE_DELAY=5
   ```

이러한 환경 변수는 Rake 작업의 동작을 수정합니다:

| 이름           | 기본값 | 목적 |
|----------------|---------------|---------|
| `ANSI`         | `true`        | ANSI 이스케이프 코드를 사용하여 출력을 더 이해하기 쉽게 만듭니다. |
| `BATCH_SIZE`   | `1000`        | 이 크기의 배치에서 테이블을 반복합니다. |
| `START_ID`     | `nil`         | 설정된 경우 이 ID에서 스캔을 시작합니다. |
| `END_ID`       | `nil`         | 설정된 경우 이 ID에서 스캔을 중지합니다. |
| `UPDATE_DELAY` | `1`           | 업데이트 사이에 절전할 초 단위입니다. |

- `START_ID`과(와) `END_ID`은(는) 테이블의 다른 부분에 다른 프로세스를 할당하여 업데이트를 병렬로 실행하는 데 사용할 수 있습니다.
- `BATCH`과(와) `UPDATE_DELAY`은(는) 마이그레이션 속도를 테이블에 대한 동시 액세스와 절충합니다.
- 터미널이 ANSI 이스케이프 코드를 지원하지 않으면 `ANSI`을(를) `false`(으)로 설정해야 합니다.

객체 저장소와 로컬 저장소 간 외부 차이의 분포를 확인하려면 다음 SQL 쿼리를 사용합니다:

```shell
gitlabhq_production=# SELECT count(*) AS total,
  SUM(CASE
    WHEN external_diff_store = '1' THEN 1
    ELSE 0
  END) AS filesystem,
  SUM(CASE
    WHEN external_diff_store = '2' THEN 1
    ELSE 0
  END) AS objectstg
FROM merge_request_diffs;
```
