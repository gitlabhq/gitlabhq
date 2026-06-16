---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly 클러스터(Praefect) 문제 해결
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Gitaly 클러스터(Praefect) 문제를 해결할 때 아래 정보를 참조하세요. Gitaly 문제 해결에 대한 정보는 [Gitaly 문제 해결](../troubleshooting.md)을 참조하세요.

## 필수 요구 사항 {#prerequisites}

관리자 액세스 권한이 있어야 합니다.

## 클러스터 상태 확인 {#check-cluster-health}

`check` Praefect 서브 명령어는 Gitaly 클러스터(Praefect)의 상태를 확인하기 위해 일련의 검사를 실행합니다.

```shell
gitlab-ctl praefect check
```

Praefect 차트를 사용하여 Praefect가 배포된 경우 바이너리를 직접 실행하세요.

```shell
/usr/local/bin/praefect check
```

다음 섹션에서는 실행되는 검사에 대해 설명합니다.

### Praefect 마이그레이션 {#praefect-migrations}

Praefect가 올바르게 작동하려면 데이터베이스 마이그레이션이 최신 상태여야 하므로 Praefect 마이그레이션이 최신 상태인지 확인합니다.

이 검사가 실패하면:

1. 데이터베이스에서 `schema_migrations` 테이블을 확인하여 실행된 마이그레이션을 확인하세요.
1. `praefect sql-migrate`을 실행하여 마이그레이션을 최신 상태로 유지하세요.

### 노드 연결성 및 디스크 액세스 {#node-connectivity-and-disk-access}

Praefect가 모든 Gitaly 노드에 연결할 수 있는지, 그리고 각 Gitaly 노드가 모든 저장소에 읽기 및 쓰기 액세스를 가지고 있는지 확인합니다.

이 검사가 실패하면:

1. 네트워크 주소와 토큰이 올바르게 설정되었는지 확인하세요:
   - Praefect 구성에서.
   - 각 Gitaly 노드의 구성에서.
1. Gitaly 노드에서 `gitaly` 프로세스가 `git`으로 실행되고 있는지 확인하세요. Gitaly가 저장소 디렉터리에 액세스하는 것을 방지하는 권한 문제가 있을 수 있습니다.
1. Praefect를 Gitaly 노드에 연결하는 네트워크에 문제가 없는지 확인하세요.

### 데이터베이스 읽기 및 쓰기 액세스 {#database-read-and-write-access}

Praefect가 데이터베이스에서 읽고 쓸 수 있는지 확인합니다.

이 검사가 실패하면:

1. Praefect 데이터베이스가 복구 모드인지 확인하세요. 복구 모드에서는 테이블이 읽기 전용일 수 있습니다. 확인하려면 다음을 실행하세요:

   ```sql
   select pg_is_in_recovery()
   ```

1. Praefect가 PostgreSQL에 연결하는 데 사용하는 사용자가 데이터베이스에 읽기 및 쓰기 액세스를 가지고 있는지 확인하세요.
1. 데이터베이스가 읽기 전용 모드로 설정되었는지 확인하세요. 확인하려면 다음을 실행하세요:

   ```sql
   show default_transaction_read_only
   ```

### 액세스할 수 없는 리포지토리 {#inaccessible-repositories}

기본 할당이 누락되었거나 기본이 사용할 수 없어서 액세스할 수 없는 리포지토리의 개수를 확인합니다.

이 검사가 실패하면:

1. Gitaly 노드가 다운되었는지 확인하세요. `praefect ping-nodes`을 실행하여 확인하세요.
1. Praefect 데이터베이스에 높은 부하가 있는지 확인하세요. Praefect 데이터베이스의 응답이 느리면 상태 검사가 데이터베이스에 유지되지 못하여 Praefect가 노드를 건강하지 않은 것으로 생각할 수 있습니다.

## 로그의 Praefect 오류 {#praefect-errors-in-logs}

오류가 발생하면 `/var/log/gitlab/gitlab-rails/production.log`을 확인하세요.

일반적인 오류 및 잠재적 원인은 다음과 같습니다:

- 500 응답 코드
  - `ActionView::Template::Error (7:permission denied)`
    - `praefect['configuration'][:auth][:token]`과 `gitlab_rails['gitaly_token']`이 GitLab 서버에서 일치하지 않습니다.
    - `gitlab_rails['repositories_storages']` 저장소 구성이 Sidekiq 서버에서 누락되었습니다.
  - `Unable to save project. Error: 7:permission denied`
    - GitLab 서버의 `praefect['configuration'][:virtual_storage]`의 비밀 토큰이 하나 이상의 Gitaly 서버의 `gitaly['auth_token']`의 값과 일치하지 않습니다.
- 503 응답 코드
  - `GRPC::Unavailable (14:failed to connect to all addresses)`
    - GitLab이 Praefect에 연결할 수 없었습니다.
  - `GRPC::Unavailable (14:all SubCons are in TransientFailure...)`
    - Praefect가 하나 이상의 자식 Gitaly 노드에 연결할 수 없습니다. Praefect 연결 검사기를 실행하여 진단하세요.

## 높은 CPU 부하를 경험하는 Praefect 데이터베이스 {#praefect-database-experiencing-high-cpu-load}

Praefect 데이터베이스에서 CPU 사용량이 증가하는 몇 가지 일반적인 이유는 다음과 같습니다:

- Prometheus 메트릭 스크래핑 [비용이 많이 드는 쿼리 실행](https://gitlab.com/gitlab-org/gitaly/-/issues/3796). `praefect['configuration'][:prometheus_exclude_database_from_default_metrics] = true`을 `gitlab.rb`에 설정하세요.
- [읽기 분포 캐싱](configure.md#reads-distribution-caching)이 비활성화되어 사용자 트래픽이 높을 때 데이터베이스에 대한 쿼리 수가 증가합니다. 읽기 분포 캐싱이 활성화되어 있는지 확인하세요.

## 기본 Gitaly 노드 결정 {#determine-primary-gitaly-node}

리포지토리의 기본 노드를 결정하려면 [`praefect metadata`](#view-repository-metadata) 서브 명령어를 사용하세요.

## 리포지토리 메타데이터 보기 {#view-repository-metadata}

Gitaly 클러스터(Praefect)는 클러스터에 저장된 리포지토리에 대한 정보를 포함하는 [메타데이터 데이터베이스](_index.md#components)를 유지관리합니다. `praefect metadata` 서브 명령어를 사용하여 문제 해결을 위해 메타데이터를 검사하세요.

다음 중 하나의 방법으로 리포지토리의 메타데이터를 검색할 수 있습니다:

- 가상 저장소 및 [상대 경로](../../repository_storage_paths.md#from-project-name-to-hashed-path).
- [Praefect에서 할당한 리포지토리 ID](_index.md#praefect-generated-replica-paths).

{{< tabs >}}

{{< tab title="가상 저장소 및 상대 경로" >}}

가상 저장소 및 상대 경로별로 리포지토리의 메타데이터를 검색하려면:

1. 우측 상단 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **개요** > **프로젝트**를 선택하고 프로젝트를 선택하세요.
1. 프로젝트의 **Storage name**과 **Relative path** 값을 적어두세요.
1. 이 값으로 다음 명령어를 실행하세요:

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage <virtual-storage> -relative-path <relative-path>
   ```

{{< /tab >}}

{{< tab title="Praefect에서 할당한 리포지토리 ID" >}}

> [!note]
> 리포지토리 ID는 프로젝트 ID와 동일하지 않습니다.

Praefect에서 할당한 리포지토리 ID로 리포지토리의 메타데이터를 검색하려면:

1. 리포지토리의 복제본 경로의 마지막 구성 요소를 적어두세요. 예를 들어 `@cluster/repositories/6f/96/54771`의 경우 리포지토리 ID는 `54771`입니다.
1. 이 값으로 다음 명령어를 실행하세요:

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id <repository-id>
   ```

{{< /tab >}}

{{< /tabs >}}

### 예제 {#examples}

가상 저장소 `default`과 상대 경로 `@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`를 사용하여 리포지토리의 메타데이터를 검색하려면:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage default -relative-path @hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git
```

Praefect에서 할당한 리포지토리 ID가 1인 리포지토리의 메타데이터를 검색하려면:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id 1
```

이러한 예제 중 하나는 예제 리포지토리에 대한 다음 메타데이터를 검색합니다:

```plaintext
Repository ID: 54771
Virtual Storage: "default"
Relative Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Replica Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Primary: "gitaly-1"
Generation: 1
Replicas:
- Storage: "gitaly-1"
  Assigned: true
  Generation: 1, fully up to date
  Healthy: true
  Valid Primary: true
  Verified At: 2021-04-01 10:04:20 +0000 UTC
- Storage: "gitaly-2"
  Assigned: true
  Generation: 0, behind by 1 changes
  Healthy: true
  Valid Primary: false
  Verified At: unverified
- Storage: "gitaly-3"
  Assigned: true
  Generation: replica not yet created
  Healthy: false
  Valid Primary: false
  Verified At: unverified
```

### 사용 가능한 메타데이터 {#available-metadata}

`praefect metadata`에서 검색한 메타데이터는 다음 표의 필드를 포함합니다.

| 필드             | 설명                                                                                                        |
|:------------------|:-------------------------------------------------------------------------------------------------------------------|
| `Repository ID`   | Praefect에서 리포지토리에 할당한 영구적인 고유 ID입니다. GitLab이 리포지토리에 사용하는 ID와는 다릅니다.      |
| `Virtual Storage` | 리포지토리가 저장된 가상 저장소의 이름입니다.                                                           |
| `Relative Path`   | 가상 저장소의 리포지토리 경로입니다.                                                                          |
| `Replica Path`    | Gitaly 노드의 디스크에 리포지토리의 복제본이 저장되는 위치입니다.                                                |
| `Primary`         | 리포지토리의 현재 기본 저장소입니다.                                                                                 |
| `Generation`      | Praefect가 리포지토리 변경을 추적하는 데 사용됩니다. 리포지토리의 각 쓰기 작업은 리포지토리의 세대를 증가시킵니다. |
| `Replicas`        | 존재하거나 존재할 것으로 예상되는 복제본의 목록입니다.                                                            |

각 복제본에 대해 다음 메타데이터를 사용할 수 있습니다:

| `Replicas` 필드 | 설명                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|:-----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Storage`        | 복제본을 포함하는 Gitaly 저장소의 이름입니다.                                                                                                                                                                                                                                                                                                                                                                                                  |
| `Assigned`       | 복제본이 저장소에 존재할 것으로 예상되는지 여부를 나타냅니다. Gitaly 노드가 클러스터에서 제거되거나 리포지토리의 복제 계수가 감소한 후 저장소에 추가 복사본이 포함되어 있는 경우 `false`일 수 있습니다.                                                                                                                                                                                                                       |
| `Generation`     | 복제본의 최신 확인된 세대입니다. 나타내는 바:<br><br>\- 세대가 리포지토리의 세대와 일치하면 복제본은 완전히 최신 상태입니다.<br>\- 복제본의 세대가 리포지토리의 세대보다 작으면 복제본은 오래되었습니다.<br>\- 복제본이 저장소에 아직 존재하지 않으면 `replica not yet created`입니다.                                                                                                          |
| `Healthy`        | 이 복제본을 호스팅하는 Gitaly 노드가 Praefect 노드의 합의에 의해 건강한 것으로 간주되는지 여부를 나타냅니다.                                                                                                                                                                                                                                                                                                                               |
| `Valid Primary`  | 복제본이 기본 노드로 작동할 적합한지 여부를 나타냅니다. 리포지토리의 기본이 유효한 기본이 아닌 경우 유효한 기본인 다른 복제본이 있으면 다음 쓰기에서 리포지토리로의 장애 조치가 발생합니다. 복제본이 유효한 기본인 경우:<br><br>\- 건강한 Gitaly 노드에 저장됩니다.<br>\- 완전히 최신 상태입니다.<br>\- 복제 계수 감소로 인한 보류 중인 삭제 작업의 대상이 아닙니다.<br>\- 할당됩니다. |
| `Verified At` | [검증 워커](configure.md#repository-verification)에 의한 복제본의 최신 성공적인 검증을 나타냅니다. 복제본이 아직 검증되지 않은 경우 마지막 성공적인 검증 시간 대신 `unverified`가 표시됩니다. |

### 명령어가 '리포지토리를 찾을 수 없음'으로 실패 {#command-fails-with-repository-not-found}

`-virtual-storage`의 제공된 값이 올바르지 않으면 명령어는 다음 오류를 반환합니다:

```plaintext
get metadata: rpc error: code = NotFound desc = repository not found
```

문서화된 예제는 `-virtual-storage default`을 지정합니다. Praefect 서버 설정 `praefect['configuration'][:virtual_storage]`을 `/etc/gitlab/gitlab.rb`에서 확인하세요.

## 리포지토리가 동기화되었는지 확인 {#check-that-repositories-are-in-sync}

[경우에 따라](_index.md#known-issues) Praefect 데이터베이스가 기본 Gitaly 노드와 동기화되지 않을 수 있습니다. 주어진 리포지토리가 모든 노드에서 완전히 동기화되었는지 확인하려면 Rails 노드에서 [`gitlab:praefect:replicas` Rake 작업](../../raketasks/praefect.md#replica-checksums)을 실행하세요. 이 Rake 작업은 모든 Gitaly 노드에서 리포지토리의 체크섬을 계산합니다.

[Praefect `dataloss`](recovery.md#check-for-data-loss) 명령어는 Praefect 데이터베이스의 리포지토리 상태만 확인하며 이 시나리오에서 동기화 문제를 감지하는 데 사용할 수 없습니다.

### `dataloss` 명령어가 `@failed-geo-sync` 리포지토리를 동기화되지 않음으로 표시 {#dataloss-command-shows-failed-geo-sync-repositories-as-out-of-sync}

`@failed-geo-sync`은 GitLab 16.1 이전에 Geo에서 프로젝트 동기화가 실패했을 때 사용했던 레거시 경로이며 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/375640).

GitLab 16.2 이상에서는 이 경로를 안전하게 삭제할 수 있습니다. `@failed-geo-sync` 디렉터리는 Gitaly 노드의 [리포지토리 경로](../../repository_storage_paths.md) 아래에 위치합니다.

## 관계가 존재하지 않는 오류 {#relation-does-not-exist-errors}

기본적으로 Praefect 데이터베이스 테이블은 `gitlab-ctl reconfigure` 작업에 의해 자동으로 생성됩니다.

그러나 Praefect 데이터베이스 테이블은 초기 재구성에서 생성되지 않으며 다음 중 하나인 경우 관계가 존재하지 않는다는 오류를 발생시킬 수 있습니다:

- `gitlab-ctl reconfigure` 명령어가 실행되지 않습니다.
- 실행 중 오류가 발생합니다.

예를 들어:

- `ERROR:  relation "node_status" does not exist at character 13`
- `ERROR:  relation "replication_queue_lock" does not exist at character 40`
- 이 오류:

  ```json
  {"level":"error","msg":"Error updating node: pq: relation \"node_status\" does not exist","pid":210882,"praefectName":"gitlab1x4m:0.0.0.0:2305","time":"2021-04-01T19:26:19.473Z","virtual_storage":"praefect-cluster-1"}
  ```

이를 해결하려면 `sql-migrate` `praefect` 명령어의 서브 명령어를 사용하여 데이터베이스 스키마 마이그레이션을 수행할 수 있습니다:

```shell
$ sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml sql-migrate
praefect sql-migrate: OK (applied 21 migrations)
```

## '리포지토리 범위: 유효하지 않은 리포지토리' 오류로 인해 요청 실패 {#requests-fail-with-repository-scoped-invalid-repository-errors}

이는 [Praefect 구성](configure.md#praefect) 에서 사용된 가상 저장소 이름이 GitLab의 [`gitaly['configuration'][:storage][<index>][:name]` 설정](configure.md#gitaly)에서 사용된 저장소 이름과 일치하지 않음을 나타냅니다.

Praefect 및 GitLab 구성에서 사용된 가상 저장소 이름을 일치시켜 이를 해결하세요.

## 클라우드 플랫폼의 Gitaly 클러스터(Praefect) 성능 문제 {#gitaly-cluster-praefect-performance-issues-on-cloud-platforms}

Praefect는 많은 CPU나 메모리를 필요로 하지 않으며 소규모 가상 머신에서 실행할 수 있습니다. 클라우드 서비스는 디스크 IO 및 네트워크 트래픽과 같이 소규모 VM이 사용할 수 있는 리소스에 대한 다른 제한을 할 수 있습니다.

Praefect 노드는 많은 네트워크 트래픽을 생성합니다. 네트워크 대역폭이 클라우드 서비스로 제한된 경우 다음 증상이 관찰될 수 있습니다:

- Git 작업의 성능 저하.
- 높은 네트워크 지연 시간.
- Praefect의 높은 메모리 사용량.

가능한 해결책:

- 더 큰 네트워크 트래픽 할당량에 액세스하기 위해 더 큰 VM을 프로비저닝하세요.
- 클라우드 서비스의 모니터링 및 로깅을 사용하여 Praefect 노드가 트래픽 할당량을 소진하지 않는지 확인하세요.

## `gitlab-ctl reconfigure`이 Praefect 구성 오류로 실패 {#gitlab-ctl-reconfigure-fails-with-a-praefect-configuration-error}

`gitlab-ctl reconfigure`이 실패하면 다음 오류가 표시될 수 있습니다:

```plaintext
STDOUT: praefect: configuration error: error reading config file: toml: cannot store TOML string into a Go int
```

이 오류는 `praefect['database_port']` 또는 `praefect['database_direct_port']`이 정수 대신 문자열로 구성되어 있을 때 발생합니다.

## 일반적인 복제 오류 {#common-replication-errors}

다음은 몇 가지 일반적인 복제 오류와 가능한 해결책입니다.

### 잠금 파일이 존재 {#lock-file-exists}

잠금 파일은 동일한 참조에 대한 여러 업데이트를 방지하는 데 사용됩니다. 때때로 잠금 파일이 오래되면 복제가 오류 `error: cannot lock ref`로 실패합니다.

오래된 `*.lock` 파일을 제거하려면 [Rails 콘솔](../../operations/rails_console.md)에서 `OptimizeRepositoryRequest`을 트리거할 수 있습니다:

```ruby
p = Project.find <Project ID>
client = Gitlab::GitalyClient::RepositoryService.new(p.repository)
client.optimize_repository
```

`OptimizeRepositoryRequest`을 트리거하는 것이 작동하지 않으면 파일을 수동으로 검사하여 생성 날짜를 확인하고 `*.lock` 파일을 수동으로 제거할 수 있는지 결정하세요. 24시간 이상 전에 생성된 잠금 파일은 안전하게 제거할 수 있습니다.

### Git `fsck` 오류 {#git-fsck-errors}

유효하지 않은 개체가 있는 Gitaly 리포지토리는 Gitaly 로그에 다음과 같은 오류가 있는 복제 실패로 이어질 수 있습니다:

- `exit status 128, stderr: "fatal: git upload-pack: not our ref"`.
- `"fatal: bad object 58....e0f... ssh://gitaly/internal.git did not send all necessary objects`.

Gitaly 노드 중 하나가 여전히 리포지토리의 정상적인 복사본을 가지고 있는 한 이러한 문제는 다음과 같이 해결할 수 있습니다:

1. [Praefect 데이터베이스에서 리포지토리 제거](recovery.md#manually-remove-repositories).
1. [Praefect `track-repository` 서브 명령어](recovery.md#manually-add-a-single-repository-to-the-tracking-database)를 사용하여 다시 추적합니다.

이는 권한 있는 Gitaly 노드에서 리포지토리의 복사본을 사용하여 다른 모든 Gitaly 노드의 복사본을 덮어씁니다. 이러한 명령어를 실행하기 전에 리포지토리의 최근 백업을 만들었는지 확인하세요.

1. 잘못된 리포지토리를 제거하십시오:

   ```shell
   run `mv <REPOSITORY_PATH> <REPOSITORY_PATH>.backup`
   ```

   예를 들어:

   ```shell
   mv /var/opt/gitlab/git-data/repositories/@cluster/repositories/de/74/2335 /var/opt/gitlab/git-data/repositories/@cluster/repositories/de/74/2335.backup
   ```

1. Praefect 명령어를 실행하여 복제를 트리거합니다:

   ```shell
   # Validate you have the correct repository.
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage gitaly -relative-path '<relative_path>' -db-only

   # Run again with '--apply' flag to remove repository from the Praefect tracking database
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage gitaly -relative-path '<relative_path>' -db-only --apply

   # Re-track the repository, overwriting the secondary nodes
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repository -virtual-storage gitaly -authoritative-storage '<healthy_gitaly>' -relative-path '<relative_path>' -replica-path '<replica_path>'-replicate-immediately
   ```

### 복제가 자동으로 실패 {#replication-fails-silently}

[Praefect `dataloss`](recovery.md#check-for-data-loss) 가 [부분적으로 사용할 수 없는 리포지토리](recovery.md#unavailable-replicas-of-available-repositories) 를 표시하고 [`accept-dataloss` 명령어](recovery.md#accept-data-loss)가 로그에 오류 없이 리포지토리를 동기화하지 못하면 이는 Praefect 데이터베이스의 `repository_id` 필드의 `storage_repositories` 테이블에서 불일치로 인한 것일 수 있습니다. 불일치를 확인하려면:

1. Praefect 데이터베이스에 연결하세요.
1. 다음 쿼리를 실행하세요:

   ```sql
   select * from storage_repositories where relative_path = '<relative-path>';
   ```

   `<relative-path>`을 [`@hashed`로 시작하는](../../repository_storage_paths.md#hashed-storage) 리포지토리 경로로 바꾸세요.

### 대체 디렉터리가 존재하지 않음 {#alternate-directory-does-not-exists}

GitLab은 중복 제거를 위해 Git alternates 메커니즘을 사용합니다. `alternates`은 `@pool` 리포지토리의 `objects` 디렉터리를 가리키는 텍스트 파일입니다. 이 파일이 유효하지 않은 경로를 가리키면 복제가 다음 오류 중 하나로 실패할 수 있습니다:

- `"error":"no alternates directory exists", "warning","msg":"alternates file does not point to valid git repository"`
- `"error":"unexpected alternates content:`
- `remote: error: unable to normalize alternate object path`

이 오류의 원인을 조사하려면:

1. [Rails 콘솔](../../operations/rails_console.md)을 사용하여 프로젝트가 풀의 일부인지 확인하세요:

   ```ruby
   project = Project.find_by_id(<project id>)
   project.pool_repository
   ```

1. 풀 리포지토리 경로가 디스크에 존재하는지, 그리고 `alternates` 파일 내용과 일치하는지 확인하세요.
1. `alternates` 파일의 경로가 프로젝트의 `objects` 디렉터리에서 도달 가능한지 확인하세요.

이러한 검사를 수행한 후 수집한 정보와 함께 GitLab Support에 문의하세요.

### 실패한 리포지토리 저장소 이동 후 프로젝트가 읽기 전용 상태로 고정 {#projects-are-stuck-in-read-only-state-after-failed-repository-storage-moves}

Horizontal Pod Autoscaler(HPA)를 Sidekiq 파드와 함께 사용할 때, 작업 실행 중 파드 스케일링으로 인해 리포지토리 저장소 이동이 자동으로 실패할 수 있습니다. 이 문제로 인해 리포지토리 저장소 이동이 실패한 경우 실패한 프로젝트는 읽기 전용 상태로 고정될 수 있습니다.

영향을 받은 리포지토리를 복구하려면:

1. [영향을 받은 프로젝트를 읽기/쓰기 상태로 재설정](../../read_only_gitlab.md#make-the-repositories-read-only).
1. [Sidekiq 포드에 대한 HPA 비활성화](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/#disable-hpa-scaling)
1. 개별 프로젝트에 대해 [REST API를 사용하여 저장소 이동 다시 실행](../../operations/moving_repositories.md).
1. 마이그레이션이 완료된 후 HPA 구성을 복원합니다.
