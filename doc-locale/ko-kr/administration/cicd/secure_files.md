---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보안 파일 관리
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/350748)하며 기능 플래그 `ci_secure_files`이(가) GitLab 15.7에서 제거되었습니다.

{{< /history >}}

CI/CD 파이프라인에서 사용하기 위해 최대 100개의 파일을 보안 파일로 안전하게 저장할 수 있습니다. 이 파일들은 프로젝트의 리포지토리 외부에 안전하게 저장되며 버전 제어되지 않습니다. 이 파일에 민감한 정보를 저장해도 안전합니다. 보안 파일은 일반 텍스트 및 바이너리 파일 형식을 모두 지원하며 5 MB 이하여야 합니다.

이 파일들의 저장 위치는 아래에 설명된 옵션을 사용하여 구성할 수 있지만, 기본 위치는 다음과 같습니다:

- `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files`은 Linux 패키지를 사용한 설치의 경우입니다.
- `/home/git/gitlab/shared/ci_secure_files`은 자체 컴파일 설치의 경우입니다.

[외부 오브젝트 저장소](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files) 구성을 [GitLab Helm 차트](https://docs.gitlab.com/charts/) 설치에 사용합니다.

## 보안 파일 비활성화 {#disabling-secure-files}

전체 GitLab 인스턴스에서 보안 파일을 비활성화할 수 있습니다. 디스크 공간을 줄이거나 기능에 대한 액세스를 제거하기 위해 보안 파일을 비활성화할 수 있습니다.

보안 파일을 비활성화하려면 설치에 따라 아래 단계를 따르세요.

전제 조건:

- 관리자여야 합니다.

**For Linux package installations**

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가하세요:

   ```ruby
   gitlab_rails['ci_secure_files_enabled'] = false
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

**For self-compiled installations**

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정하세요:

   ```yaml
   ci_secure_files:
     enabled: false
   ```

1. 파일을 저장하고 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

## 로컬 스토리지 사용 {#using-local-storage}

기본 구성은 로컬 저장소를 사용합니다. 보안 파일이 로컬에 저장되는 위치를 변경하려면 아래 단계를 따르세요.

**For Linux package installations**

1. 저장소 경로를 예를 들어 `/mnt/storage/ci_secure_files`로 변경하려면 `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가하세요:

   ```ruby
   gitlab_rails['ci_secure_files_storage_path'] = "/mnt/storage/ci_secure_files"
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

**For self-compiled installations**

1. 저장소 경로를 예를 들어 `/mnt/storage/ci_secure_files`로 변경하려면 `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정하세요:

   ```yaml
   ci_secure_files:
     enabled: true
     storage_path: /mnt/storage/ci_secure_files
   ```

1. 파일을 저장하고 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

## object storage 사용 {#using-object-storage}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

보안 파일을 디스크에 저장하는 대신 [지원되는 오브젝트 저장소 옵션 중 하나](../object_storage.md#object-storage-provider-support)를 사용해야 합니다. 이 구성은 이미 구성된 유효한 자격 증명에 의존합니다.

### 통합 오브젝트 저장소 {#consolidated-object-storage}

{{< history >}}

- 통합 오브젝트 저장소에 대한 지원이 GitLab 17.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149873)되었습니다.

{{< /history >}}

오브젝트 저장소의 [통합 형식](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을 사용하는 것이 좋습니다.

### 저장소별 오브젝트 저장소 {#storage-specific-object-storage}

다음 설정들은:

- `ci_secure_files:` 아래에 중첩되고 자체 컴파일 설치의 경우 `object_store:` 아래에 중첩됩니다.
- Linux 패키지 설치의 경우 `ci_secure_files_object_store_`이(가) 접두사로 붙습니다.

| 설정 | 설명 | 기본값 |
|---------|-------------|---------|
| `enabled` | 오브젝트 저장소 활성화/비활성화 | `false` |
| `remote_directory` | 보안 파일이 저장되는 버킷 이름 | |
| `connection` | 아래에서 설명하는 다양한 연결 옵션 | |

### S3 호환 연결 설정 {#s3-compatible-connection-settings}

[다양한 공급자의 사용 가능한 연결 설정](../object_storage.md#configure-the-connection-settings)을 참조하세요.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가하되 원하는 값을 사용하세요:

   ```ruby
   gitlab_rails['ci_secure_files_object_store_enabled'] = true
   gitlab_rails['ci_secure_files_object_store_remote_directory'] = "ci_secure_files"
   gitlab_rails['ci_secure_files_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   > [!note]
   > AWS IAM 프로필을 사용하는 경우 AWS 액세스 키와 비밀 액세스 키/값 쌍을 생략해야 합니다:

   ```ruby
   gitlab_rails['ci_secure_files_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. [기존 로컬 상태를 오브젝트 저장소로 마이그레이션](#migrate-to-object-storage)합니다.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정하세요:

   ```yaml
   ci_secure_files:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "ci_secure_files"  # The bucket name
       connection:
         provider: AWS  # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

1. [기존 로컬 상태를 오브젝트 저장소로 마이그레이션](#migrate-to-object-storage)합니다.

{{< /tab >}}

{{< /tabs >}}

### 오브젝트 저장소로 마이그레이션 {#migrate-to-object-storage}

{{< history >}}

- GitLab 16.1에서 [도입](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/125)되었습니다.

{{< /history >}}

> [!warning]
> 보안 파일을 오브젝트 저장소에서 로컬 저장소로 다시 마이그레이션할 수 없으므로 주의하여 진행하세요.

보안 파일을 오브젝트 저장소로 마이그레이션하려면 아래 지침을 따르세요.

- Linux 패키지 설치의 경우:

  ```shell
  sudo gitlab-rake gitlab:ci_secure_files:migrate
  ```

- 자체 컴파일된 설치의 경우:

  ```shell
  sudo -u git -H bundle exec rake gitlab:ci_secure_files:migrate RAILS_ENV=production
  ```
