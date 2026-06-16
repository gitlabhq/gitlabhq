---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Dependency Proxy 관리
description: 자주 액세스하는 업스트림 아티팩트(컨테이너 이미지 및 패키지 포함)를 관리하기 위한 GitLab dependency proxy 관리자 가이드입니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/7934) [GitLab Premium](https://about.gitlab.com/pricing/) 11.11
- [이동됨](https://gitlab.com/gitlab-org/gitlab/-/issues/273655) GitLab Premium에서 GitLab Free로 13.6에서

{{< /history >}}

GitLab을 자주 액세스하는 업스트림 아티팩트(컨테이너 이미지 및 패키지 포함)를 위한 dependency proxy로 사용할 수 있습니다.

이것은 관리 설명서입니다. dependency proxy를 사용하는 방법을 알아보려면 다음을 참조하세요:

- [컨테이너 이미지용 dependency proxy](../../user/packages/dependency_proxy/_index.md) 사용자 가이드
- [가상 레지스트리](../../user/packages/virtual_registry/_index.md) 사용자 가이드

GitLab Dependency Proxy:

- 기본적으로 켜져 있습니다.
- 관리자가 끌 수 있습니다.

## Dependency Proxy 끄기 {#turn-off-the-dependency-proxy}

Dependency Proxy는 기본적으로 활성화되어 있습니다. 관리자인 경우 Dependency Proxy를 끌 수 있습니다. Dependency Proxy를 끄려면 GitLab 설치에 맞는 지침을 따르세요.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = false
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

설치가 완료되면 글로벌 `appConfig`을(를) 업데이트하여 Dependency Proxy를 끕니다:

```yaml
global:
  appConfig:
    dependencyProxy:
      enabled: false
      bucket: gitlab-dependency-proxy
      connection:
        secret:
        key:
```

자세한 내용은 [차트 글로벌을 사용하여 구성](https://docs.gitlab.com/charts/charts/globals/#configure-appconfig-settings)을(를) 참조하세요.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. 설치가 완료되면 `dependency_proxy` 섹션을 `config/gitlab.yml`에서 구성하세요. `enabled`을(를) `false`(으)로 설정하여 Dependency Proxy를 끕니다:

   ```yaml
   dependency_proxy:
     enabled: false
   ```

1. [GitLab 재시작](../restart_gitlab.md#self-compiled-installations) 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

### 다중 노드 GitLab 설치 {#multi-node-gitlab-installations}

각 웹 및 Sidekiq 노드에 대한 Linux 패키지 설치 단계를 따릅니다.

## Dependency Proxy 켜기 {#turn-on-the-dependency-proxy}

Dependency Proxy는 기본적으로 켜져 있지만 관리자가 끌 수 있습니다. 수동으로 끄려면 [Dependency Proxy 끄기](#turn-off-the-dependency-proxy)의 지침을 따릅니다.

## 저장소 경로 변경 {#changing-the-storage-path}

기본적으로 Dependency Proxy 파일은 로컬로 저장되지만 기본 로컬 위치를 변경하거나 객체 저장소를 사용할 수 있습니다.

### 로컬 저장소 경로 변경 {#changing-the-local-storage-path}

Linux 패키지 설치를 위한 Dependency Proxy 파일은 `/var/opt/gitlab/gitlab-rails/shared/dependency_proxy/` 아래에 저장되고 원본 설치를 위해서는 `shared/dependency_proxy/` 아래에 저장됩니다(Git 홈 디렉터리 기준).

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['dependency_proxy_storage_path'] = "/mnt/dependency_proxy"
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `dependency_proxy` 섹션을 `config/gitlab.yml`에서 편집하세요:

   ```yaml
   dependency_proxy:
     enabled: true
     storage_path: shared/dependency_proxy
   ```

1. [GitLab 재시작](../restart_gitlab.md#self-compiled-installations) 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

### 객체 저장소 사용 {#using-object-storage}

로컬 저장소에 의존하는 대신 [통합 객체 저장소 설정](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을(를) 사용할 수 있습니다. 이 섹션은 이전 구성 형식을 설명합니다. [마이그레이션 단계는 여전히 적용됩니다](#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage).

[GitLab과 함께 객체 저장소 사용에 대해 자세히 알아보기](../object_storage.md).

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가하세요(필요한 경우 주석 처리 제거):

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = true
   gitlab_rails['dependency_proxy_storage_path'] = "/var/opt/gitlab/gitlab-rails/shared/dependency_proxy"
   gitlab_rails['dependency_proxy_object_store_enabled'] = true
   gitlab_rails['dependency_proxy_object_store_remote_directory'] = "dependency_proxy" # The bucket name.
   gitlab_rails['dependency_proxy_object_store_proxy_download'] = false        # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
   gitlab_rails['dependency_proxy_object_store_connection'] = {
     ##
     ## If the provider is AWS S3, uncomment the following
     ##
     #'provider' => 'AWS',
     #'region' => 'eu-west-1',
     #'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     #'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY',
     ##
     ## If the provider is other than AWS (an S3-compatible one), uncomment the following
     ##
     #'host' => 's3.amazonaws.com',
     #'aws_signature_version' => 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
     #'endpoint' => 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
     #'path_style' => false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   }
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `dependency_proxy` 섹션을 `config/gitlab.yml`에서 편집하세요(필요한 경우 주석 처리 제거):

   ```yaml
   dependency_proxy:
     enabled: true
     ##
     ## The location where build dependency_proxy are stored (default: shared/dependency_proxy).
     ##
     # storage_path: shared/dependency_proxy
     object_store:
       enabled: false
       remote_directory: dependency_proxy  # The bucket name.
       #  proxy_download: false     # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
       connection:
       ##
       ## If the provider is AWS S3, use the following
       ##
         provider: AWS
         region: us-east-1
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         ##
         ## If the provider is other than AWS (an S3-compatible one), comment out the previous 4 lines and use the following instead:
         ##
         #  host: 's3.amazonaws.com'             # default: s3.amazonaws.com.
         #  aws_signature_version: 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
         #  endpoint: 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
         #  path_style: false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   ```

1. [GitLab 재시작](../restart_gitlab.md#self-compiled-installations) 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

#### 로컬 Dependency Proxy Blob 및 매니페스트를 객체 저장소로 마이그레이션 {#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage}

[객체 저장소 구성](#using-object-storage) 후 다음 작업을 사용하여 기존 Dependency Proxy Blob 및 매니페스트를 로컬 저장소에서 원격 저장소로 마이그레이션합니다. 처리는 백그라운드 작업자에 의해 수행되며 중단 시간이 필요하지 않습니다.

- Linux 패키지 설치의 경우:

  ```shell
  sudo gitlab-rake "gitlab:dependency_proxy:migrate"
  ```

- 자체 컴파일 설치의 경우:

  ```shell
  RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:dependency_proxy:migrate
  ```

[PostgreSQL 콘솔](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database)을(를) 사용하여 모든 Dependency Proxy Blob 및 매니페스트가 성공적으로 마이그레이션되었는지 선택적으로 추적하고 확인할 수 있습니다:

- `sudo gitlab-rails dbconsole` Linux 패키지 설치의 경우 버전 14.1 이하에서 실행 중입니다.
- `sudo gitlab-rails dbconsole --database main` Linux 패키지 설치의 경우 버전 14.2 이상에서 실행 중입니다.
- `sudo -u git -H psql -d gitlabhq_production` 자체 컴파일 인스턴스의 경우.

`objectstg`(여기서 `file_store = '2'`) 모든 Dependency Proxy Blob 및 각 해당 쿼리에 대한 매니페스트 개수를 확인하세요:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM dependency_proxy_blobs;

total | filesystem | objectstg
------+------------+-----------
 22   |          0 |        22

gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM dependency_proxy_manifests;

total | filesystem | objectstg
------+------------+-----------
 10   |          0 |        10
```

`dependency_proxy` 폴더의 디스크에 파일이 없는지 확인하세요:

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/dependency_proxy -type f | grep -v tmp | wc -l
```

## JWT 만료 변경 {#changing-the-jwt-expiration}

Dependency Proxy는 [Docker v2 토큰 인증 흐름](https://distribution.github.io/distribution/spec/auth/token/)을(를) 따르며 클라이언트에 풀 요청에 사용할 JWT를 발급합니다. 토큰 만료 시간은 애플리케이션 설정 `container_registry_token_expire_delay`을(를) 사용하여 구성할 수 있습니다. Rails 콘솔에서 변경할 수 있습니다:

```ruby
# update the JWT expiration to 30 minutes
ApplicationSetting.update(container_registry_token_expire_delay: 30)
```

기본 만료 및 GitLab.com의 만료는 15분입니다.

## 프록시 뒤에서 dependency proxy 사용 {#using-the-dependency-proxy-behind-a-proxy}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가하세요:

   ```ruby
   gitlab_workhorse['env'] = {
     "http_proxy" => "http://USERNAME:PASSWORD@example.com:8080",
     "https_proxy" => "http://USERNAME:PASSWORD@example.com:8080"
   }
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
