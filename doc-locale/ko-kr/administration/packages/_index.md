---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 패키지 레지스트리 관리
description: 패키지 레지스트리를 관리합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab을 다양한 일반적인 패키지 관리자의 개인 리포지토리로 사용하려면 패키지 레지스트리를 사용합니다. 패키지를 빌드하고 게시할 수 있으며, 이를 다운스트림 프로젝트의 종속성으로 사용할 수 있습니다.

## 지원되는 형식 {#supported-formats}

패키지 레지스트리에서 지원하는 형식은 다음과 같습니다:

| 패키지 유형                                                       | GitLab 버전 |
|--------------------------------------------------------------------|----------------|
| [Composer](../../user/packages/composer_repository/_index.md)      | 13.2+          |
| [Conan 1](../../user/packages/conan_1_repository/_index.md)        | 12.6+          |
| [Conan 2](../../user/packages/conan_2_repository/_index.md)        | 18.1+          |
| [Go](../../user/packages/go_proxy/_index.md)                       | 13.1+          |
| [Maven](../../user/packages/maven_repository/_index.md)            | 11.3+          |
| [npm](../../user/packages/npm_registry/_index.md)                  | 11.7+          |
| [NuGet](../../user/packages/nuget_repository/_index.md)            | 12.8+          |
| [PyPI](../../user/packages/pypi_repository/_index.md)              | 12.10+         |
| [일반 패키지](../../user/packages/generic_packages/_index.md) | 13.5+          |
| [Helm Charts](../../user/packages/helm_repository/_index.md)       | 14.1+          |

패키지 레지스트리는 [모델 레지스트리 데이터](../../user/project/ml/model_registry/_index.md)를 저장하는 데도 사용됩니다.

## 기여도 수용 {#accepting-contributions}

다음 표는 지원되지 않는 패키지 형식을 나열합니다. 이러한 형식에 대한 지원을 추가하기 위해 GitLab에 기여하는 것을 고려해 보세요.

<!-- vale gitlab_base.Spelling = NO -->

| 형식 | 상태 |
| ------ | ------ |
| Chef      | [\#36889](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) |
| CocoaPods | [\#36890](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) |
| Conda     | [\#36891](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) |
| CRAN      | [\#36892](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) |
| Debian    | [초안: 머지 리퀘스트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50438) |
| Opkg      | [\#36894](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) |
| P2        | [\#36895](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) |
| Puppet    | [\#36897](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) |
| RPM       | [\#5932](https://gitlab.com/gitlab-org/gitlab/-/issues/5932) |
| RubyGems  | [\#803](https://gitlab.com/gitlab-org/gitlab/-/issues/803) |
| SBT       | [\#36898](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) |
| Terraform | [초안: 머지 리퀘스트](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834) |
| Vagrant   | [\#36899](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) |

<!-- vale gitlab_base.Spelling = YES -->

## 속도 제한 {#rate-limits}

패키지를 다운스트림 프로젝트의 종속성으로 다운로드할 때 Packages API를 통해 많은 요청이 수행됩니다. 따라서 적용된 사용자 및 IP 속도 제한에 도달할 수 있습니다. 이 문제를 해결하려면 Packages API에 대한 특정 속도 제한을 정의할 수 있습니다. 자세한 내용은 [패키지 레지스트리 속도 제한](../settings/package_registry_rate_limits.md)을 참조하세요.

## 패키지 레지스트리 활성화 또는 비활성화 {#enable-or-disable-the-package-registry}

패키지 레지스트리는 기본적으로 활성화됩니다. 비활성화하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   # Change to true to enable packages - enabled by default if not defined
   gitlab_rails['packages_enabled'] = false
   ```

1. 파일을 저장하고 GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다:

   ```yaml
   global:
     appConfig:
       packages:
         enabled: false
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['packages_enabled'] = false
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다:

   ```yaml
   production: &base
     packages:
       enabled: false
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 스토리지 경로 변경 {#change-the-storage-path}

기본적으로 패키지는 로컬에 저장되지만 기본 로컬 위치를 변경하거나 객체 저장소를 사용할 수도 있습니다.

### 로컬 스토리지 경로 변경 {#change-the-local-storage-path}

기본적으로 패키지는 GitLab 설치에 상대적인 로컬 경로에 저장됩니다:

- Linux 패키지(Omnibus): `/var/opt/gitlab/gitlab-rails/shared/packages/`
- 직접 컴파일(소스): `/home/git/gitlab/shared/packages/`

로컬 스토리지 경로를 변경하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['packages_storage_path'] = "/mnt/packages"
   ```

1. 파일을 저장하고 GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다:

   ```yaml
   production: &base
     packages:
       enabled: true
       storage_path: /mnt/packages
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

이미 이전 스토리지 경로에 패키지가 저장되어 있는 경우 기존 패키지를 액세스할 수 있도록 모든 것을 이전 위치에서 새 위치로 이동합니다:

```shell
mv /var/opt/gitlab/gitlab-rails/shared/packages/* /mnt/packages/
```

Docker 및 Kubernetes는 로컬 저장소를 사용하지 않습니다.

- Helm 차트(Kubernetes):  대신 객체 저장소를 사용합니다.
- Docker:  `/var/opt/gitlab/` 디렉터리는 이미 호스트의 디렉터리에 마운트되어 있습니다. 컨테이너 내의 로컬 스토리지 경로를 변경할 필요가 없습니다.

### 객체 저장소 사용 {#use-object-storage}

로컬 저장소에만 의존하는 대신 객체 저장소를 사용하여 패키지를 저장할 수 있습니다.

자세한 내용은 [통합 객체 저장소 설정](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을 사용하는 방법을 참조하세요.

### 객체 저장소와 로컬 저장소 간 패키지 마이그레이션 {#migrate-packages-between-object-storage-and-local-storage}

객체 저장소를 구성한 후 다음 작업을 사용하여 로컬 저장소와 원격 저장소 간에 패키지를 마이그레이션할 수 있습니다. 처리는 백그라운드 작업자에 의해 수행되며 중단 시간이 필요하지 않습니다.

#### 객체 저장소로 마이그레이션 {#migrate-to-object-storage}

마이그레이션 작업은 패키지 파일 및 메타데이터 캐시를 객체 저장소로 이동합니다: 패키지 파일 (`packages_package_files`), Helm 메타데이터 캐시 (`packages_helm_metadata_caches`), NPM 메타데이터 캐시 (`packages_npm_metadata_caches`), NuGet 기호 (`packages_nuget_symbols`). 이전에 마이그레이션을 실행했고 이러한 유형 중 하나에 대해 남은 파일이 있는 경우 작업을 다시 실행합니다. 남은 로컬 파일을 마이그레이션합니다.

1. 패키지를 객체 저장소로 마이그레이션합니다:

   {{< tabs >}} {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   sudo gitlab-rake "gitlab:packages:migrate"
   ```

   {{< /tab >}} {{< tab title="직접 컴파일(소스)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:packages:migrate
   ```

   {{< /tab >}} {{< /tabs >}}

1. PostgreSQL 콘솔을 사용하여 진행 상황을 추적하고 모든 패키지가 성공적으로 마이그레이션되었는지 확인합니다:

   {{< tabs >}} {{< tab title="Linux 패키지(Omnibus) 14.1 이하" >}}

   ```shell
   sudo gitlab-rails dbconsole
   ```

   {{< /tab >}} {{< tab title="Linux 패키지(Omnibus) 14.2 이상" >}}

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   {{< /tab >}} {{< tab title="직접 컴파일(소스)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H psql -d gitlabhq_production
   ```

   {{< /tab >}} {{< /tabs >}}

1. 다음 SQL 쿼리를 사용하여 모든 패키지가 객체 저장소로 마이그레이션되었는지 확인합니다. `objectstg` 수가 `total`과 동일해야 합니다:

   ```sql
   SELECT count(*) AS total,
          sum(case when file_store = '1' then 1 else 0 end) AS filesystem,
          sum(case when file_store = '2' then 1 else 0 end) AS objectstg
   FROM packages_package_files;
   ```

   출력 예:

   ```plaintext
   total | filesystem | objectstg
   ------+------------+-----------
    34   |          0 |        34
   ```

1. 마지막으로 `packages` 디렉터리에 파일이 없는지 확인합니다:

   {{< tabs >}} {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}} {{< tab title="직접 컴파일(소스)" >}}

   ```shell
   sudo -u git find /home/git/gitlab/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}} {{< /tabs >}}

#### 객체 저장소에서 로컬 저장소로 마이그레이션 {#migrate-from-object-storage-to-local-storage}

객체 저장소로 마이그레이션할 때와 동일한 유형이 마이그레이션됩니다(패키지 파일, Helm 메타데이터 캐시, NPM 메타데이터 캐시, NuGet 기호).

1. 패키지를 객체 저장소에서 로컬 저장소로 마이그레이션합니다:

   {{< tabs >}} {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   sudo gitlab-rake "gitlab:packages:migrate[local]"
   ```

   {{< /tab >}} {{< tab title="직접 컴파일(소스)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H bundle exec rake "gitlab:packages:migrate[local]"
   ```

   {{< /tab >}} {{< /tabs >}}

1. PostgreSQL 콘솔을 사용하여 진행 상황을 추적하고 모든 패키지가 성공적으로 마이그레이션되었는지 확인합니다:

   {{< tabs >}} {{< tab title="Linux 패키지(Omnibus) 14.1 이하" >}}

   ```shell
   sudo gitlab-rails dbconsole
   ```

   {{< /tab >}} {{< tab title="Linux 패키지(Omnibus) 14.2 이상" >}}

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   {{< /tab >}} {{< tab title="직접 컴파일(소스)" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H psql -d gitlabhq_production
   ```

   {{< /tab >}} {{< /tabs >}}

1. 다음 SQL 쿼리를 사용하여 모든 패키지가 로컬 저장소로 마이그레이션되었는지 확인합니다. `filesystem` 수가 `total`과 동일해야 합니다:

   ```sql
   SELECT count(*) AS total,
          sum(case when file_store = '1' then 1 else 0 end) AS filesystem,
          sum(case when file_store = '2' then 1 else 0 end) AS objectstg
   FROM packages_package_files;
   ```

   출력 예:

   ```plaintext
   total | filesystem | objectstg
   ------+------------+-----------
    34   |         34 |         0
   ```

1. 마지막으로 `packages` 디렉터리에 파일이 있는지 확인합니다:

   {{< tabs >}} {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}} {{< tab title="직접 컴파일(소스)" >}}

   ```shell
   sudo -u git find /home/git/gitlab/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}} {{< /tabs >}}
