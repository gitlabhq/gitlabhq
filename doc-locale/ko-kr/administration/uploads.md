---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 업로드 관리
description: 업로드 저장소를 관리합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

업로드는 GitLab으로 단일 파일로 전송될 수 있는 모든 사용자 데이터를 나타냅니다. 예를 들어 아바타 및 메모 첨부 파일이 업로드입니다. 업로드는 GitLab 기능에 필수적이므로 비활성화할 수 없습니다.

> [!note]
> 주석 또는 설명에 추가된 첨부 파일은 상위 프로젝트 또는 그룹이 삭제될 때 **only** 삭제됩니다. 첨부 파일은 주석 또는 리소스(이슈, 머지 리퀘스트, 에픽)가 삭제되어도 파일 저장소에 남아 있습니다.

## 로컬 저장소 사용 {#using-local-storage}

이것이 기본 설정입니다. 업로드를 로컬로 저장하는 위치를 변경하려면 설치 방법에 따라 이 섹션의 단계를 사용합니다:

> [!note]
> 역사적 이유로 인해 전체 인스턴스에 대한 업로드(예: [파비콘](appearance.md#customize-the-favicon))는 기본적으로 `uploads/-/system`인 기본 디렉토리에 저장됩니다. 기존 GitLab 설치에서 기본 디렉토리를 변경하는 것은 강력히 권장하지 않습니다.

Linux 패키지 설치의 경우:

_업로드는 기본적으로 `/var/opt/gitlab/gitlab-rails/uploads`에 저장됩니다._

1. 저장소 경로를 변경하려면(예: `/mnt/storage/uploads`) `/etc/gitlab/gitlab.rb`를 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['uploads_directory'] = "/mnt/storage/uploads"
   ```

   이 설정은 `gitlab_rails['uploads_storage_path']` 디렉토리를 변경하지 않은 경우에만 적용됩니다.

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab을 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

직접 컴파일된 설치의 경우:

_업로드는 기본적으로 `/home/git/gitlab/public/uploads`에 저장됩니다._

1. 저장소 경로를 변경하려면(예: `/mnt/storage/uploads`) `/home/git/gitlab/config/gitlab.yml`를 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   uploads:
     storage_path: /mnt/storage
     base_dir: uploads
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab을 다시 시작](restart_gitlab.md#self-compiled-installations)합니다.

## 객체 저장소 사용 {#using-object-storage}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab이 설치된 로컬 디스크를 사용하여 업로드를 저장하지 않으려면 대신 AWS S3과 같은 객체 저장소 공급자를 사용할 수 있습니다. 이 설정은 유효한 AWS 자격 증명이 이미 구성되어 있어야 합니다.

[GitLab으로 객체 저장소 사용에 대해 자세히 알아보기](object_storage.md).

### 객체 저장소 설정 {#object-storage-settings}

이 섹션에서는 저장소 관련 설정 형식을 설명합니다. 대신 [통합 객체 저장소 설정](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을 사용해야 합니다.

직접 컴파일된 설치의 경우 다음 설정은 `uploads:` 아래에 중첩되고 `object_store:`도 그렇습니다. Linux 패키지 설치에서는 `uploads_object_store_`로 접두사가 붙습니다.

| 설정 | 설명 | 기본값 |
|---------|-------------|---------|
| `enabled` | 객체 저장소 활성화/비활성화 | `false` |
| `remote_directory` | 업로드가 저장되는 버킷 이름| |
| `proxy_download` | `true`로 설정하여 제공되는 모든 파일의 프록시를 활성화합니다. 이 옵션을 사용하면 클라이언트가 모든 데이터를 프록시하는 대신 원격 저장소에서 직접 다운로드할 수 있으므로 송신 트래픽을 줄일 수 있습니다 | `false` |
| `connection` | 아래에 설명된 다양한 연결 옵션 | |

#### 연결 설정 {#connection-settings}

[다양한 공급자를 위한 사용 가능한 연결 설정](object_storage.md#configure-the-connection-settings)을 참조하세요.

Linux 패키지 설치의 경우:

_업로드는 기본적으로 `/var/opt/gitlab/gitlab-rails/uploads`에 저장됩니다._

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 원하는 값으로 바꾼 후 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['uploads_object_store_enabled'] = true
   gitlab_rails['uploads_object_store_remote_directory'] = "uploads"
   gitlab_rails['uploads_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   AWS IAM 프로필을 사용하는 경우 AWS 액세스 키 및 비밀 액세스 키/값 쌍을 생략해야 합니다.

   ```ruby
   gitlab_rails['uploads_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab을 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
1. [`gitlab:uploads:migrate:all` Rake 작업](raketasks/uploads/migrate.md)으로 기존 로컬 업로드를 객체 저장소로 마이그레이션합니다.

직접 컴파일된 설치의 경우:

_업로드는 기본적으로 `/home/git/gitlab/public/uploads`에 저장됩니다._

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정합니다. [공급자에 적합한 것](object_storage.md#configure-the-connection-settings)을(를) 사용해야 합니다:

   ```yaml
   uploads:
     object_store:
       enabled: true
       remote_directory: "uploads" # The bucket name
       connection: # The lines in this block depend on your provider
         provider: AWS
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab을 다시 시작](restart_gitlab.md#self-compiled-installations)합니다.
1. [`gitlab:uploads:migrate:all` Rake 작업](raketasks/uploads/migrate.md)으로 기존 로컬 업로드를 객체 저장소로 마이그레이션합니다.
