---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Terraform 상태 관리
description: Terraform 상태 스토리지를 관리합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab을 [Terraform](../user/infrastructure/_index.md) 상태 파일의 백엔드로 사용할 수 있습니다. 파일은 저장하기 전에 암호화됩니다. 이 기능은 기본적으로 활성화됩니다.

이 파일들의 스토리지 위치는 기본적으로 다음과 같습니다:

- `/var/opt/gitlab/gitlab-rails/shared/terraform_state` - Linux 패키지 설치의 경우입니다.
- `/home/git/gitlab/shared/terraform_state` - 자체 컴파일 설치의 경우입니다.

이 위치는 아래에 설명된 옵션을 사용하여 구성할 수 있습니다.

[외부 객체 스토리지](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files) 구성을 [GitLab Helm 차트](https://docs.gitlab.com/charts/) 설치에 사용합니다.

## Terraform 상태 비활성화 {#disabling-terraform-state}

전체 인스턴스에서 Terraform 상태를 비활성화할 수 있습니다. 디스크 공간을 줄이거나 인스턴스가 Terraform을 사용하지 않기 때문에 Terraform을 비활성화하려는 경우가 있을 수 있습니다.

Terraform 상태 관리가 비활성화되면:

- 왼쪽 사이드바에서 **운영** > **Terraform 상태**를 선택할 수 없습니다.
- Terraform 상태에 액세스하는 모든 CI/CD 작업이 이 오류로 실패합니다:

  ```shell
  Error refreshing state: HTTP remote state endpoint invalid auth
  ```

Terraform 관리를 비활성화하려면 설치 방식에 따라 아래 단계를 따릅니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

Linux 패키지 설치의 경우:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['terraform_state_enabled'] = false
   ```

1. 파일을 저장하고 [GitLab 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)을(를) 수행하여 변경 사항을 적용합니다.

자체 컴파일 설치의 경우:

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   terraform_state:
     enabled: false
   ```

1. 파일을 저장하고 [GitLab 재시작](restart_gitlab.md#self-compiled-installations)을(를) 수행하여 변경 사항을 적용합니다.

## 로컬 스토리지 사용 {#using-local-storage}

기본 구성은 로컬 스토리지를 사용합니다. Terraform 상태 파일을 로컬로 저장하는 위치를 변경하려면 아래 단계를 따릅니다.

Linux 패키지 설치의 경우:

1. 스토리지 경로를 예를 들어 `/mnt/storage/terraform_state`(으)로 변경하려면 `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['terraform_state_storage_path'] = "/mnt/storage/terraform_state"
   ```

1. 파일을 저장하고 [GitLab 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)을(를) 수행하여 변경 사항을 적용합니다.

자체 컴파일 설치의 경우:

1. 스토리지 경로를 예를 들어 `/mnt/storage/terraform_state`(으)로 변경하려면 `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   terraform_state:
     enabled: true
     storage_path: /mnt/storage/terraform_state
   ```

1. 파일을 저장하고 [GitLab 재시작](restart_gitlab.md#self-compiled-installations)을(를) 수행하여 변경 사항을 적용합니다.

## 객체 스토리지 사용 {#using-object-storage}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

Terraform 상태 파일을 디스크에 저장하는 대신 [지원되는 객체 스토리지 옵션 중 하나](object_storage.md#object-storage-provider-support)를 사용하는 것을 권장합니다. 이 구성은 이미 구성된 유효한 자격 증명에 따라 달라집니다.

[GitLab에서 객체 스토리지 사용에 대해 자세히 알아보기](object_storage.md)입니다.

### 객체 스토리지 설정 {#object-storage-settings}

다음 설정은:

- `terraform_state_object_store_`으로 시작합니다(Linux 패키지 설치의 경우).
- `terraform_state:` 아래에 중첩되며 그 다음 `object_store:`(자체 컴파일 설치의 경우)입니다.

| 설정 | 설명 | 기본값 |
|---------|-------------|---------|
| `enabled` | 객체 스토리지 활성화/비활성화 | `false` |
| `remote_directory` | Terraform 상태 파일이 저장되는 버킷 이름 | |
| `connection` | 아래에 설명된 다양한 연결 옵션 | |

### 객체 스토리지로 마이그레이션 {#migrate-to-object-storage}

> [!warning]
> Terraform 상태 파일을 객체 스토리지에서 로컬 스토리지로 다시 마이그레이션하는 것은 불가능하므로 주의하여 진행합니다. [이 동작을 변경하기 위한 이슈가 있습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/350187).

Terraform 상태 파일을 객체 스토리지로 마이그레이션하려면:

- Linux 패키지 설치의 경우:

  ```shell
  gitlab-rake gitlab:terraform_states:migrate
  ```

- 자체 컴파일 설치의 경우:

  ```shell
  sudo -u git -H bundle exec rake gitlab:terraform_states:migrate RAILS_ENV=production
  ```

[PostgreSQL 콘솔](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database)을(를) 사용하여 진행 상황을 추적하고 모든 Terraform 상태 파일이 성공적으로 마이그레이션되었는지 확인할 수 있습니다:

- `sudo gitlab-rails dbconsole --database main` - Linux 패키지 설치의 경우입니다.
- `sudo -u git -H psql -d gitlabhq_production` - 자체 컴파일 설치의 경우입니다.

`objectstg` 아래에서 확인합니다(`file_store=2`인 경우). 모든 상태의 개수를 확인합니다:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM terraform_state_versions;

total | filesystem | objectstg
------+------------+-----------
   15 |          0 |      15
```

`terraform_state` 폴더의 디스크에 파일이 없는지 확인합니다:

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/terraform_state -type f | grep -v tmp | wc -l
```

### S3 호환 연결 설정 {#s3-compatible-connection-settings}

[통합 객체 스토리지 설정](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을(를) 사용해야 합니다. 이 섹션에서는 이전 구성 형식을 설명합니다.

[다른 공급자를 위한 사용 가능한 연결 설정](object_storage.md#configure-the-connection-settings)을(를) 참조합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가합니다(원하는 값으로 바꾈):

   ```ruby
   gitlab_rails['terraform_state_object_store_enabled'] = true
   gitlab_rails['terraform_state_object_store_remote_directory'] = "terraform"
   gitlab_rails['terraform_state_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   > [!note]
   > AWS IAM 프로필을 사용하는 경우 AWS 액세스 키와 보안 액세스 키/값 쌍을 생략해야 합니다.

   ```ruby
   gitlab_rails['terraform_state_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](restart_gitlab.md#reconfigure-a-linux-package-installation)을(를) 수행하여 변경 사항을 적용합니다.
1. [기존 로컬 상태를 객체 스토리지로 마이그레이션](#migrate-to-object-storage)

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 다음 줄을 추가하거나 수정합니다:

   ```yaml
   terraform_state:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "terraform" # The bucket name
       connection:
         provider: AWS # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. 파일을 저장하고 [GitLab 재시작](restart_gitlab.md#self-compiled-installations)을(를) 수행하여 변경 사항을 적용합니다.
1. [기존 로컬 상태를 객체 스토리지로 마이그레이션](#migrate-to-object-storage)

{{< /tab >}}

{{< /tabs >}}

### Terraform 상태 파일 경로 찾기 {#find-a-terraform-state-file-path}

Terraform 상태 파일은 관련 프로젝트의 해시된 디렉터리 경로에 저장됩니다.

경로의 형식은 `/var/opt/gitlab/gitlab-rails/shared/terraform_state/<path>/<to>/<projectHashDirectory>/<UUID>/0.tfstate`이며, 여기서 [UUID](https://gitlab.com/gitlab-org/gitlab/-/blob/dcc47a95c7e1664cb15bef9a70f2a4eefa9bd99a/app/models/terraform/state.rb#L33)는 무작위로 정의됩니다.

상태 파일 경로를 찾으려면:

1. `get-terraform-path`을(를) 셸에 추가합니다:

   ```shell
   get-terraform-path() {
       PROJECT_HASH=$(echo -n $1 | openssl dgst -sha256 | sed 's/^.* //')
       echo "${PROJECT_HASH:0:2}/${PROJECT_HASH:2:2}/${PROJECT_HASH}"
   }
   ```

1. `get-terraform-path <project_id>`을(를) 실행합니다.

   ```shell
   $ get-terraform-path 650
   20/99/2099a9b5f777e242d1f9e19d27e232cc71e2fa7964fc988a319fce5671ca7f73
   ```

상대 경로가 표시됩니다.

## 백업에서 Terraform 상태 파일 복원 {#restoring-terraform-state-files-from-backups}

백업에서 Terraform 상태 파일을 복원하려면 암호화된 상태 파일과 GitLab 데이터베이스에 액세스할 수 있어야 합니다.

### 데이터베이스 테이블 {#database-tables}

다음 데이터베이스 테이블은 S3 경로를 특정 프로젝트로 다시 추적하는 데 도움이 됩니다:

- `terraform_states`:  각 상태에 대해 보편적으로 고유한 ID(UUID)를 포함한 기본 상태 정보를 포함합니다.

### 파일 구조 및 경로 구성 {#file-structure-and-path-composition}

상태 파일은 특정 디렉터리 구조에 저장되며, 여기서:

- 경로의 처음 세 세그먼트는 프로젝트 ID의 SHA-256 해시 값에서 파생됩니다.
- 각 상태는 경로의 일부를 형성하는 `terraform_states` 데이터베이스 테이블에 저장된 UUID를 갖습니다.

예를 들어, 다음과 같은 프로젝트의 경우:

- 프로젝트 ID는 `12345`입니다.
- 상태 UUID는 `example-uuid`입니다.

`12345`의 SHA-256 해시 값이 `5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5`인 경우 폴더 구조는 다음과 같습니다:

```plaintext
terraform/                                                                 <- configured Terraform storage directory
├─ 59/                                                                     <- first and second character of project ID hash
|  ├─ 94/                                                                  <- third and fourth character of project ID hash
|  |  ├─ 5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5/ <- full project ID hash
|  |  |  ├─ example-uuid/                                                  <- state UUID
|  |  |  |  ├─ 1.tf                                                        <- individual state versions
|  |  |  |  ├─ 2.tf
|  |  |  |  ├─ 3.tf
```

### 복호화 프로세스 {#decryption-process}

상태 파일은 Lockbox를 사용하여 암호화되며 복호화를 위해 다음 정보가 필요합니다:

- `db_key_base` 애플리케이션 보안 암호
- 프로젝트 ID

암호화 키는 `db_key_base`과(와) 프로젝트 ID 모두에서 파생됩니다. `db_key_base`에 액세스할 수 없는 경우 복호화가 불가능합니다.

파일을 수동으로 복호화하는 방법을 알아보려면 [Lockbox](https://github.com/ankane/lockbox)의 설명서를 참조합니다.

암호화 키 생성 프로세스를 보려면 [상태 업로더 코드](https://gitlab.com/gitlab-org/gitlab/-/blob/e0137111fbbd28316f38da30075aba641e702b98/app/uploaders/terraform/state_uploader.rb#L43)를 참조합니다.
