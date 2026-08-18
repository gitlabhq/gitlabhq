---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: 리포지토리 저장소
description: GitLab이 리포지토리 데이터를 저장하는 방식입니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 [리포지토리](../user/project/repository/_index.md)를 리포지토리 스토리지에 저장합니다. 리포지토리 스토리지는 다음 중 하나입니다:

- 물리 스토리지는 `gitaly_address`로 구성되어 [Gitaly 노드](gitaly/_index.md)를 가리킵니다.
- [가상 스토리지](gitaly/praefect/_index.md#virtual-storage)는 Gitaly 클러스터(Praefect)에 리포지토리를 저장합니다.

> [!warning]
> 리포지토리 스토리지는 `path`로 구성될 수 있으며 리포지토리가 저장된 디렉터리를 직접 가리킵니다. GitLab이 리포지토리를 포함하는 디렉터리에 직접 액세스하는 것은 더 이상 지원되지 않습니다. GitLab을 물리 또는 가상 스토리지를 통해 리포지토리에 액세스하도록 구성해야 합니다.

자세한 정보:

- Gitaly 구성 방법은 [Gitaly 구성](gitaly/configure_gitaly.md)을 참조하세요.
- Gitaly 클러스터(Praefect) 구성 방법은 [Gitaly 클러스터(Praefect) 구성](gitaly/praefect/configure.md)을 참조하세요.

## 해시된 스토리지 {#hashed-storage}

해시된 스토리지는 프로젝트의 ID 해시를 기반으로 한 위치에 디스크에 프로젝트를 저장합니다. 이렇게 하면 폴더 구조를 변경할 수 없으며 URL에서 디스크 구조로 상태를 동기화할 필요가 없습니다. 이는 그룹, 사용자 또는 프로젝트의 이름을 바꾸는 경우:

- 데이터베이스 트랜잭션만 비용이 발생합니다.
- 즉시 적용됩니다.

해시는 또한 리포지토리를 디스크에 더 균등하게 분산시키는 데 도움이 됩니다. 최상위 디렉터리는 최상위 네임스페이스의 총 개수보다 적은 폴더를 포함합니다.

해시 형식은 `SHA256(project.id)`로 계산된 SHA256의 16진수 표현을 기반으로 합니다. 최상위 폴더는 처음 두 문자를 사용하고 그 다음에는 다음 두 문자가 있는 다른 폴더가 뒤따릅니다. 이 둘 다 특별한 `@hashed` 폴더에 저장되므로 기존 레거시 스토리지 프로젝트와 함께 존재할 수 있습니다. 예를 들어:

```ruby
# Project's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"

# Wiki's repository:
"@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

### 해시된 스토리지 경로 변환 {#translate-hashed-storage-paths}

Git 리포지토리의 문제를 해결하고, 훅을 추가하고, 다른 작업을 수행하려면 사람이 읽을 수 있는 프로젝트 이름과 해시된 스토리지 경로 사이를 변환해야 합니다. 다음을 변환할 수 있습니다:

- [프로젝트 이름에서 해시된 경로로](#from-project-name-to-hashed-path)
- [해시된 경로에서 프로젝트 이름으로](#from-hashed-path-to-project-name)

#### 프로젝트 이름에서 해시된 경로로 {#from-project-name-to-hashed-path}

{{< history >}}

- **Relative path** 필드가 GitLab 16.3에서 **Gitaly relative path**에서 [이름이 바뀌었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128416).

{{< /history >}}

관리자는 이름 또는 ID를 사용하여 프로젝트의 해시된 경로를 조회할 수 있습니다:

- [**운영자** 영역](admin_area.md#administering-projects)
- Rails 콘솔

**운영자** 영역에서 프로젝트의 해시 경로를 조회하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **프로젝트**를 선택하고 프로젝트를 선택합니다.
1. **Relative path** 필드를 찾습니다. 값은 다음과 유사합니다:

   ```plaintext
   "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
   ```

Rails 콘솔을 사용하여 프로젝트의 해시 경로를 조회하려면:

1. [Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 시작합니다.
1. 이 예제와 유사한 명령을 실행합니다(프로젝트의 ID 또는 이름을 사용):

   ```ruby
   Project.find(16).disk_path
   Project.find_by_full_path('group/project').disk_path
   ```

#### 해시된 경로에서 프로젝트 이름으로 {#from-hashed-path-to-project-name}

관리자는 해시된 상대 경로에서 프로젝트 이름을 조회할 수 있습니다:

- Rails 콘솔
- `config` 파일을 `*.git` 디렉터리에 넣습니다.

Rails 콘솔을 사용하여 프로젝트 이름을 조회하려면:

1. [Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 시작합니다.
1. 이 예제와 유사한 명령을 실행합니다:

   ```ruby
   ProjectRepository.find_by(disk_path: '@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9').project
   ```

해당 명령의 따옴표로 묶인 문자열은 GitLab 서버에서 찾을 수 있는 디렉터리 트리입니다. 예를 들어 기본 Linux 패키지 설치에서는 `/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`이고 디렉터리 이름 끝에서 `.git`를 제거합니다.

출력에는 프로젝트 ID와 프로젝트 이름이 포함됩니다. 예를 들어:

```plaintext
=> #<Project id:16 it/supportteam/ticketsystem>
```

#### 해시된 경로에서 프로젝트의 전체 경로로 {#from-hashed-path-to-full-path-of-a-project}

Rails 콘솔을 사용하여 프로젝트의 전체 경로를 조회하려면:

1. [Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 시작합니다.
1. 이 예제와 유사한 명령을 실행합니다:

   ```ruby
   ProjectRepository.find_by(disk_path: '@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9').project.full_path
   ```

   예제에서 해당 명령의 따옴표로 묶인 문자열은 GitLab 서버의 디렉터리 트리입니다. 예를 들어 기본 Linux 패키지 설치에서는 이 문자열이 `/var/opt/gitlab/git-data/repositories/@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`이고 디렉터리 이름 끝에서 `.git`를 제거합니다.

출력에는 프로젝트의 전체 경로가 포함됩니다. 예를 들어:

```plaintext
=> "it/supportteam/ticketsystem"
```

### 해시된 객체 풀 {#hashed-object-pools}

객체 풀은 [공개 및 내부 프로젝트의 포크](../user/project/repository/forking_workflow.md)를 중복 제거하는 데 사용되는 리포지토리이며 소스 프로젝트의 객체를 포함합니다. `objects/info/alternates`를 사용하면 소스 프로젝트와 포크는 공유 객체에 대해 객체 풀을 사용합니다. 자세한 정보는 GitLab 개발 문서의 Git 객체 중복 제거 정보를 참조하세요.

소스 프로젝트에서 작업이 실행될 때 객체가 소스 프로젝트에서 객체 풀로 이동됩니다. 객체 풀 리포지토리는 `@pools` 디렉터리에서 정규 리포지토리와 유사하게 저장되며 `@hashed` 대신입니다

```ruby
# object pool paths
"@pools/#{hash[0..1]}/#{hash[2..3]}/#{hash}.git"
```

> [!warning]
> `git prune` 또는 `git gc`을(를) 객체 풀 리포지토리에서 실행하지 마세요. 이들은 `@pools` 디렉터리에 저장됩니다. 이로 인해 객체 풀에 종속된 정규 리포지토리에서 데이터 손실이 발생할 수 있습니다.

### 해시된 객체 풀 스토리지 경로 변환 {#translate-hashed-object-pool-storage-paths}

Rails 콘솔을 사용하여 프로젝트의 객체 풀을 조회하려면:

1. [Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 시작합니다.
1. 다음 예제와 유사한 명령을 실행합니다:

   ```ruby
   project_id = 1
   pool_repository = Project.find(project_id).pool_repository
   pool_repository = Project.find_by_full_path('group/project').pool_repository

   # Get more details about the pool repository
   pool_repository.source_project
   pool_repository.member_projects
   pool_repository.shard
   pool_repository.disk_path
   ```

### 그룹 위키 스토리지 {#group-wiki-storage}

`@hashed` 디렉터리에 저장된 프로젝트 위키와 달리 그룹 위키는 `@groups` 디렉터리에 저장됩니다. 프로젝트 위키와 마찬가지로 그룹 위키는 해시된 스토리지 폴더 규칙을 따르지만 프로젝트 ID 대신 그룹 ID의 해시를 사용합니다.

예를 들어:

```ruby
# group wiki paths
"@groups/#{hash[0..1]}/#{hash[2..3]}/#{hash}.wiki.git"
```

### Gitaly 클러스터(Praefect) 스토리지 {#gitaly-cluster-praefect-storage}

Gitaly 클러스터(Praefect)를 사용하는 경우 Praefect는 스토리지 위치를 관리합니다. Praefect에서 리포지토리에 사용하는 내부 경로는 해시된 경로와 다릅니다. 자세한 정보는 [Praefect 생성 복제 경로](gitaly/praefect/_index.md#praefect-generated-replica-paths)를 참조하세요.

### 리포지토리 파일 아카이브 캐시 {#repository-file-archive-cache}

사용자는 `.zip` 또는 `.tar.gz`와 같은 형식의 리포지토리 아카이브를 다음 중 하나를 사용하여 다운로드할 수 있습니다:

- GitLab UI.
- [리포지토리 API](../api/repositories.md#retrieve-file-archive-from-a-repository)

GitLab은 이 아카이브를 GitLab 서버의 디렉터리에 있는 캐시에 저장합니다.

캐시의 위치는 설치 방법에 따라 다릅니다:

- Linux 패키지 인스턴스의 경우 파일 아카이브 캐시의 기본 디렉터리는 `/var/opt/gitlab/gitlab-rails/shared/cache/archive`입니다. `/etc/gitlab/gitlab.rb`의 `gitlab_rails['gitlab_repository_downloads_path']` 설정으로 이를 구성할 수 있습니다.
- Helm 차트 인스턴스의 경우 캐시는 `/srv/gitlab/shared/cache/archive`에 저장됩니다. 디렉터리를 구성할 수 없습니다.

Sidekiq에서 실행되는 백그라운드 작업은 이 디렉터리에서 오래된 아카이브를 주기적으로 정리합니다. 이러한 이유로 이 디렉터리는 모든 Sidekiq 및 GitLab Workhorse 노드에서 액세스할 수 있어야 합니다. Sidekiq이 GitLab Workhorse에서 사용하는 동일한 디렉터리에 액세스할 수 없으면 [디스크에 디렉터리가 채워집니다](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6005).

Sidekiq 및 GitLab Workhorse에 공유 마운트를 사용하고 싶지 않으면 이 디렉터리에서 파일을 삭제하도록 별도의 `cron` 작업을 구성할 수 있습니다.

또는 캐시를 완전히 비활성화할 수 있습니다:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

캐시를 비활성화하려면:

1. Puma를 실행하는 모든 노드에서 `WORKHORSE_ARCHIVE_CACHE_DISABLED` 환경 변수를 설정합니다:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_rails['env'] = { 'WORKHORSE_ARCHIVE_CACHE_DISABLED' => '1' }
   ```

1. 변경 사항을 적용하려면 업데이트된 노드를 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

캐시를 비활성화하려면 `--set gitlab.webservice.extraEnv.WORKHORSE_ARCHIVE_CACHE_DISABLED="1"`을(를) 사용하거나 값 파일에서 다음을 지정할 수 있습니다:

```yaml
gitlab:
  webservice:
    extraEnv:
      WORKHORSE_ARCHIVE_CACHE_DISABLED: "1"
```

{{< /tab >}}

{{< /tabs >}}

### 객체 스토리지 지원 {#object-storage-support}

이 표는 각 스토리지 유형에서 저장 가능한 객체를 보여줍니다:

| 저장 가능한 객체  | 해시된 스토리지 | S3 호환 |
|:-----------------|:---------------|:--------------|
| 리포지토리       | 예            | -             |
| 첨부 파일      | 예            | -             |
| 아바타          | 아니요             | -             |
| 페이지            | 아니요             | -             |
| Docker 레지스트리  | 아니요             | -             |
| CI/CD 작업 로그   | 아니요             | -             |
| CI/CD 작업 아티팩트  | 아니요             | 예           |
| CI/CD 캐시      | 아니요             | 예           |
| LFS 객체      | 유사        | 예           |
| 리포지토리 풀 | 예            | -             |

S3 호환 엔드포인트에 저장된 파일은 [해시된 스토리지](#hashed-storage)와 동일한 이점을 가질 수 있습니다. 단, `#{namespace}/#{project_name}`로 접두사가 있으면 안 됩니다. 이는 CI/CD 캐시 및 LFS 객체에 해당합니다.

#### 아바타 {#avatars}

각 파일은 데이터베이스에서 할당된 `id`과(와) 일치하는 디렉터리에 저장됩니다. 파일 이름은 항상 사용자 아바타의 경우 `avatar.png`입니다. 아바타를 바꾸면 `Upload` 모델이 파괴되고 다른 `id`로 새로운 모델이 대신합니다.

#### CI/CD 작업 아티팩트 {#cicd-artifacts}

CI/CD 작업 아티팩트는 S3 호환입니다.

#### LFS 객체 {#lfs-objects}

[GitLab의 LFS 객체](../topics/git/lfs/_index.md)는 Git 구현을 따르면서 두 개의 문자와 두 수준의 폴더를 사용하는 유사한 스토리지 패턴을 구현합니다:

```ruby
"shared/lfs-objects/#{oid[0..1}/#{oid[2..3]}/#{oid[4..-1]}"

# Based on object `oid`: `8909029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c`, path will be:
"shared/lfs-objects/89/09/029eb962194cfb326259411b22ae3f4a814b5be4f80651735aeef9f3229c"
```

LFS 객체도 [S3 호환](lfs/_index.md#storing-lfs-objects-in-remote-object-storage)입니다.

## 새 리포지토리가 저장되는 위치 구성 {#configure-where-new-repositories-are-stored}

[여러 리포지토리 스토리지를 구성](https://docs.gitlab.com/omnibus/settings/configuration/#store-git-data-in-an-alternative-directory)한 후 새 리포지토리가 저장되는 위치를 선택할 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포지토리**를 선택하세요.
1. **리포지토리 스토리지**를 확장합니다.
1. **새 리포지토리의 스토리지 노드** 필드에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

각 리포지토리 스토리지 경로에는 0-100의 가중치를 할당할 수 있습니다. 새 프로젝트를 만들 때 이러한 가중치는 리포지토리가 생성되는 스토리지 위치를 결정하는 데 사용됩니다.

주어진 리포지토리 스토리지 경로의 가중치가 다른 리포지토리 스토리지 경로에 상대적으로 높을수록 더 자주 선택됩니다(`(storage weight) / (sum of all weights) * 100 = chance %`).

기본적으로 리포지토리 가중치를 이전에 구성하지 않은 경우:

- `default`은(는) `100`의 가중치를 가집니다.
- 다른 모든 스토리지는 `0`의 가중치를 가집니다.

> [!note]
> 모든 스토리지 가중치가 `0`인 경우(예를 들어 `default`이(가) 없는 경우) GitLab은 구성에 관계없이 또는 `default`이(가) 있는지 여부에 관계없이 `default`에 새 리포지토리를 만들려고 시도합니다. 자세한 정보는 [추적 문제](https://gitlab.com/gitlab-org/gitlab/-/issues/36175)를 참조하세요.

## 리포지토리 이동 {#move-repositories}

리포지토리를 다른 리포지토리 스토리지로 이동하려면(예: `default`에서 `storage2`로) [Gitaly 클러스터(Praefect)로 마이그레이션](gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect)하는 것과 동일한 프로세스를 사용합니다.
