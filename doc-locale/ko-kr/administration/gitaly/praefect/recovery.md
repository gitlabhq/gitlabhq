---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly Cluster(Praefect) 복구 옵션 및 도구
---

Gitaly Cluster(Praefect)는 주 노드 장애 및 사용 불가능한 리포지토리에서 복구할 수 있습니다. Gitaly Cluster(Praefect)는 데이터 복구를 수행할 수 있으며 Praefect 추적 데이터베이스 도구를 가지고 있습니다.

## Gitaly Cluster(Praefect)에서 Gitaly 노드 관리 {#manage-gitaly-nodes-on-a-gitaly-cluster-praefect}

Gitaly Cluster(Praefect)에서 Gitaly 노드를 추가하고 교체할 수 있습니다.

### 새 Gitaly 노드 추가 {#add-new-gitaly-nodes}

새 Gitaly 노드를 추가하려면:

1. [설명서](configure.md#gitaly)를 따라 새 Gitaly 노드를 설치합니다.
1. 새 노드를 [Praefect 구성](configure.md#praefect)에 `praefect['virtual_storages']` 아래에 추가합니다.
1. 다음 명령을 실행하여 Praefect를 다시 구성하고 다시 시작합니다:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart praefect
   ```

복제 동작은 복제 계수 설정에 따라 달라집니다.

#### 사용자 지정 복제 계수 {#custom-replication-factor}

사용자 지정 복제 계수가 설정되면 Praefect는 기존 리포지토리를 새 Gitaly 노드로 자동으로 복제하지 않습니다. `set-replication-factor` Praefect 명령을 사용하여 각 리포지토리에 대해 [복제 계수](configure.md#configure-replication-factor)를 설정해야 합니다. 새 리포지토리는 [복제 계수](configure.md#configure-replication-factor)를 기반으로 복제됩니다.

#### 기본 복제 계수 {#default-replication-factor}

기본 복제 계수를 사용하면 Praefect는 복제 계수를 유지하기 위해 구성에 추가된 모든 새 Gitaly 노드로 모든 데이터를 자동으로 복제합니다.

### 기존 Gitaly 노드 교체 {#replace-an-existing-gitaly-node}

기존 Gitaly 노드를 같은 이름 또는 다른 이름의 새 노드로 교체할 수 있습니다. 이전 노드를 제거하기 전에:

- 복제 계수가 설정되어 있으면 데이터 손실을 방지하기 위해 1보다 커야 합니다.
- 복제 계수가 설정되지 않으면 리포지토리는 가상 저장소 아래의 모든 노드에 복제됩니다.

주 Gitaly 노드가 제거되면 해당 노드에서 관리하는 리포지토리는 다음 중 하나가 될 때까지 사용할 수 없습니다:

- 노드가 교체되고 복제됩니다.
- 교체된 주 노드의 데이터를 포함하는 새 교체 노드를 사용할 수 있습니다.

노드를 사용할 수 없는 동안 영향을 받는 리포지토리에 대한 읽기 요청은 `404` 오류로 실패합니다. Gitaly는 영향을 받는 리포지토리에 대한 다음 쓰기 시도에서 장애 조치를 트리거하여 새 주 노드를 설정하여 이 상황을 자동으로 해결합니다.

#### 같은 이름의 노드 {#with-a-node-with-the-same-name}

교체 노드에 동일한 이름을 사용하려면 [리포지토리 검증기](configure.md#enable-deletions)를 사용하여 저장소를 스캔하고 분리된 메타데이터 레코드를 제거합니다. 교체된 저장소의 [검증 수동 우선 순위 지정](configure.md#prioritize-verification-manually)을 통해 프로세스 속도를 높입니다.

#### 다른 이름의 노드 {#with-a-node-with-a-different-name}

Gitaly Cluster(Praefect)에서 다른 이름의 노드로 노드를 교체하는 단계는 [복제 계수](configure.md#configure-replication-factor)가 설정되어 있는지 여부에 따라 달라집니다.

사용자 지정 복제 계수가 설정되면 [`praefect set-replication-factor`](configure.md#configure-replication-factor)를 사용하여 리포지토리별 복제 계수를 다시 설정하여 새 저장소를 할당받습니다.

예를 들어 가상 저장소의 두 노드의 복제 계수가 2이고 새 노드(`gitaly-3`)가 추가되면 복제 계수를 3으로 증가시켜야 합니다:

```shell
$ sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml set-replication-factor -virtual-storage default -relative-path @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git -replication-factor 3

current assignments: gitaly-1, gitaly-2, gitaly-3
```

이렇게 하면 리포지토리가 새 노드로 복제되고 `repository_assignments` 테이블이 새 Gitaly 노드의 이름으로 업데이트됩니다.

[기본 복제 계수](configure.md#configure-replication-factor)가 설정되면 새 노드가 복제에 자동으로 포함되지 않습니다. 이전에 설명한 단계를 따라야 합니다.

[확인](#check-for-data-loss) 후 리포지토리가 새 노드로 성공적으로 복제되었습니다:

1. `gitaly-1` 노드를 [Praefect 구성](configure.md#praefect)에서 `praefect['virtual_storages']` 아래로 제거합니다.
1. Praefect를 다시 구성하고 다시 시작합니다:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart praefect
   ```

이전 Gitaly 노드를 참조하는 데이터베이스 상태는 무시할 수 있습니다.

다른 방법은 새 Gitaly 노드를 구성한 후 이전 저장소에서 새 저장소로 모든 리포지토리를 다시 할당하는 것입니다:

1. Praefect 데이터베이스에 연결:

   ```shell
   /opt/gitlab/embedded/bin/psql -h <psql host> -U <user> -d <database name>
   ```

1. `repository_assignments` 테이블을 업데이트하여 이전 Gitaly 노드 이름(예: `old-gitaly`)을 새 Gitaly 노드 이름(예: `new-gitaly`)으로 교체합니다:

   ```sql
   UPDATE repository_assignments SET storage='new-gitaly' WHERE storage='old-gitaly';
   ```

이렇게 하면 적절한 복제 작업이 트리거되어 시스템이 원하는 상태로 돌아갑니다.

## 주 노드 장애 {#primary-node-failure}

Gitaly Cluster(Praefect)는 건강한 보조 노드를 새 주 노드로 승격시켜 실패한 주 Gitaly 노드에서 복구합니다. Gitaly Cluster(Praefect):

- 리포지토리의 최신 복사본을 가진 건강한 보조 노드를 새 주 노드로 선택합니다.
- 최신 보조 노드를 사용할 수 없으면 주 노드에서 복제되지 않은 쓰기가 가장 적은 보조 노드를 새 주 노드로 선택합니다.
- 건강한 보조 노드에 최신 복사본이 없으면 리포지토리를 사용할 수 없게 됩니다. [Praefect `dataloss` 하위 명령](#check-for-data-loss)을 사용하여 탐지합니다.

### 사용 불가능한 리포지토리 {#unavailable-repositories}

리포지토리는 최신 복사본이 모두 사용할 수 없으면 사용할 수 없습니다. 사용 불가능한 리포지토리는 부실 데이터를 제공하지 않도록 Praefect를 통해 액세스할 수 없으며, 이는 자동화된 도구를 손상시킬 수 있습니다.

### 데이터 손실 확인 {#check-for-data-loss}

Praefect `dataloss` 하위 명령은 사용할 수 없는 리포지토리를 식별합니다. 이는 잠재적 데이터 손실과 최신 복사본을 모두 사용할 수 없어 더 이상 액세스할 수 없는 리포지토리를 식별하는 데 도움이 됩니다.

다음 매개변수를 사용할 수 있습니다:

- `-virtual-storage`은 확인할 가상 저장소를 지정합니다. 관리자의 개입이 필요할 수 있으므로 기본 동작은 사용 불가능한 리포지토리를 표시하는 것입니다.
- [`-partially-unavailable`](#unavailable-replicas-of-available-repositories)는 사용 가능하지만 사용할 수 없는 일부 할당된 복사본이 있는 리포지토리를 출력에 포함할지 여부를 지정합니다.

> [!note]
> `dataloss`는 여전히 [베타](../../../policy/development_stages_support.md#beta) 단계이며 출력 형식은 변경될 수 있습니다.

오래된 주 노드 또는 사용할 수 없는 리포지토리를 확인하려면 다음을 실행합니다:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>]
```

지정된 것이 없으면 모든 구성된 가상 저장소가 확인됩니다:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss
```

건강한 최신 복사본을 사용할 수 없는 리포지토리가 출력에 나열됩니다. 각 리포지토리에 대해 다음 정보가 출력됩니다:

- 리포지토리의 저장소 디렉터리에 대한 상대 경로는 각 리포지토리를 식별하고 관련 정보를 그룹화합니다.
- `(unavailable)`은 리포지토리를 사용할 수 없으면 디스크 경로 옆에 인쇄됩니다.
- 주 필드는 리포지토리의 현재 주 노드를 나열합니다. 리포지토리에 주 노드가 없으면 필드에 `No Primary`이 표시됩니다.
- 동기화된 저장소 목록은 최신 성공적인 쓰기 및 그 앞의 모든 쓰기를 복제한 복사본을 나열합니다.
- 오래된 저장소 목록은 리포지토리의 오래된 복사본을 포함하는 복사본을 나열합니다. 리포지토리의 복사본이 없지만 포함해야 하는 복사본도 여기에 나열됩니다. 복사본이 누락된 최대 변경 수는 복사본 옆에 나열됩니다. 오래된 복사본이 최신 상태일 수도 있고 나중의 변경 사항을 포함할 수도 있지만 Praefect는 이를 보장할 수 없다는 점에 유의하는 것이 중요합니다.

추가 정보에는 다음이 포함됩니다:

- 노드가 리포지토리를 호스트하도록 할당되었는지 여부는 각 노드의 상태와 함께 나열됩니다. `assigned host`은 리포지토리를 저장하도록 할당된 노드 옆에 인쇄됩니다. 리포지토리의 복사본을 포함하지만 리포지토리를 저장하도록 할당되지 않은 경우 텍스트가 생략됩니다. 이러한 복사본은 Praefect에 의해 동기화 상태로 유지되지 않지만 할당된 복사본을 최신 상태로 가져오기 위한 복제 소스로 작용할 수 있습니다.
- `unhealthy`은 건강하지 않은 Gitaly 노드에 위치한 복사본 옆에 인쇄됩니다.

출력 예:

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git (unavailable):
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-2, assigned host, unhealthy
      Outdated Storages:
        gitaly-1 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

모든 리포지토리를 사용할 수 있으면 확인 메시지가 인쇄됩니다. 예를 들어:

```shell
Virtual storage: default
  All repositories are available!
```

#### 사용 가능한 리포지토리의 사용 불가능한 복사본 {#unavailable-replicas-of-available-repositories}

사용 가능하지만 할당된 일부 노드에서 사용할 수 없는 리포지토리의 정보도 나열하려면 `-partially-unavailable` 플래그를 사용합니다.

리포지토리는 건강한 최신 복사본을 사용할 수 있으면 사용 가능합니다. 일부 할당된 보조 복사본은 최신 변경 사항을 복제하기 위해 대기하는 동안 임시로 액세스할 수 없습니다.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>] [-partially-unavailable]
```

출력 예:

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git:
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-1, assigned host
      Outdated Storages:
        gitaly-2 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

`-partially-unavailable` 플래그가 설정되면 모든 할당된 복사본이 완전히 최신이고 건강한 경우 확인 메시지가 인쇄됩니다.

예를 들어:

```shell
Virtual storage: default
  All repositories are fully available on all assigned storages!
```

### 리포지토리 체크섬 확인 {#check-repository-checksums}

모든 Gitaly 노드에서 프로젝트의 리포지토리 체크섬을 확인하려면 주 GitLab 노드에서 [복사본 Rake 작업](../../raketasks/praefect.md#replica-checksums)을 실행합니다.

### 데이터 손실 수용 {#accept-data-loss}

> [!warning]
> `accept-dataloss`는 리포지토리의 다른 버전을 덮어써서 영구적인 데이터 손실을 유발합니다. 데이터 [복구 노력](#data-recovery)은 이를 사용하기 전에 수행해야 합니다.

최신 복사본 중 하나를 다시 온라인으로 가져올 수 없으면 데이터 손실을 수용해야 할 수도 있습니다. 데이터 손실을 수용할 때 Praefect는 선택한 리포지토리 복사본을 최신 버전으로 표시하고 이를 다른 할당된 Gitaly 노드로 복제합니다. 이 프로세스는 리포지토리의 다른 버전을 덮어쓰므로 주의가 필요합니다.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss
-virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

### 쓰기 활성화 또는 데이터 손실 수용 {#enable-writes-or-accept-data-loss}

> [!warning]
> `accept-dataloss`는 리포지토리의 다른 버전을 덮어써서 영구적인 데이터 손실을 유발합니다. 데이터 [복구 노력](#data-recovery)은 이를 사용하기 전에 수행해야 합니다.

Praefect는 쓰기를 다시 활성화하거나 데이터 손실을 수용하기 위한 다음 하위 명령을 제공합니다. 최신 노드 중 하나를 다시 온라인으로 가져올 수 없으면 데이터 손실을 수용해야 할 수도 있습니다:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss -virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

데이터 손실을 수용할 때 Praefect:

1. 리포지토리의 선택한 복사본을 최신 버전으로 표시합니다.
1. 복사본을 다른 할당된 Gitaly 노드로 복제합니다.

   이 프로세스는 리포지토리의 다른 복사본을 덮어쓰므로 주의가 필요합니다.

## 데이터 복구 {#data-recovery}

Gitaly 노드가 어떤 이유로든 복제 작업에 실패하면 영향을 받는 리포지토리의 오래된 버전을 호스팅하게 됩니다. Praefect는 자동 조정을 위한 도구를 제공합니다. 이러한 도구는 오래된 리포지토리를 조정하여 다시 최신 상태로 가져옵니다.

Praefect는 최신이 아닌 리포지토리를 자동으로 조정합니다. 기본적으로 이는 5분마다 수행됩니다. 건강한 Gitaly 노드의 각 오래된 리포지토리에 대해 Praefect는 다른 건강한 Gitaly 노드에서 복제할 리포지토리의 임의의 완전히 최신 복사본을 선택합니다. 복제 작업은 대상 리포지토리에 대해 다른 복제 작업이 대기 중이 없는 경우에만 예약됩니다.

조정 빈도는 구성을 통해 변경할 수 있습니다. 값은 모든 유효한 [Go 기간 값](https://pkg.go.dev/time#ParseDuration)일 수 있습니다. 0 이하의 값은 기능을 비활성화합니다.

예:

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '5m', # the default value
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '30s', # reconcile every 30 seconds
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '0', # disable the feature
   },
}
```

### 리포지토리 수동 제거 {#manually-remove-repositories}

`remove-repository` Praefect 하위 명령은 Gitaly Cluster(Praefect)에서 리포지토리를 제거하고 지정된 리포지토리와 관련된 모든 상태를 포함합니다:

- 모든 관련 Gitaly 노드의 디스크상 리포지토리.
- Praefect에서 추적하는 모든 데이터베이스 상태.

기본적으로 명령은 드라이 런 모드에서 작동합니다. 예를 들어:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository>
```

- `<virtual-storage>`을 리포지토리를 포함하는 가상 저장소의 이름으로 바꿉니다.
- `<repository>`을 제거할 리포지토리의 상대 경로로 바꿉니다.
- `-db-only`을 추가하여 디스크상 리포지토리를 제거하지 않고 Praefect 추적 데이터베이스 항목을 제거합니다. 이 옵션을 사용하여 고아 데이터베이스 항목을 제거하고 유효한 리포지토리가 실수로 지정될 때 디스크상 리포지토리 데이터가 삭제되지 않도록 보호합니다. 데이터베이스 항목이 실수로 삭제된 경우 [`track-repository` 명령](#manually-add-a-single-repository-to-the-tracking-database)으로 리포지토리를 다시 추적합니다.
- `-apply`을 추가하여 드라이 런 모드 외부에서 명령을 실행하고 리포지토리를 제거합니다. 예를 들어:

  ```shell
  sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository> -apply
  ```

- `-virtual-storage`은 리포지토리가 위치한 가상 스토리지입니다. 가상 저장소는 `/etc/gitlab/gitlab.rb` 아래 `praefect['configuration']['virtual_storage]`에서 구성되며 다음과 같이 표시됩니다:

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  이 예제에서 지정할 가상 저장소는 `default` 또는 `storage-1`입니다.

- `-repository`은 저장소 [`@hashed`으로 시작](../../repository_storage_paths.md#hashed-storage)하는 리포지토리의 상대 경로입니다. 예를 들어:

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

`remove-repository`을 실행한 후 리포지토리의 일부가 계속 존재할 수 있습니다. 이는 다음 때문일 수 있습니다:

- 삭제 오류.
- 리포지토리를 대상으로 하는 비행 중인 RPC 호출.

이 경우 `remove-repository`을 다시 실행합니다.

## Praefect 추적 데이터베이스 유지 관리 {#praefect-tracking-database-maintenance}

Praefect 추적 데이터베이스의 일반적인 유지 관리 작업이 이 섹션에 문서화되어 있습니다.

### 추적되지 않은 리포지토리 나열 {#list-untracked-repositories}

`list-untracked-repositories` Praefect 하위 명령은 다음 두 가지 모두를 충족하는 Gitaly Cluster(Praefect)의 리포지토리를 나열합니다:

- 적어도 하나의 Gitaly 저장소에 존재합니다.
- Praefect 추적 데이터베이스에서 추적되지 않습니다.

`-older-than` 옵션을 추가하여 다음이 포함된 리포지토리를 표시하지 않습니다:

- 생성 중입니다.
- Praefect 추적 데이터베이스에 레코드가 아직 존재하지 않습니다.

`<duration>`을 시간 기간(예: `5s`, `10m`, 또는 `1h`)으로 바꿉니다. `6h`로 기본 설정됩니다.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories -older-than <duration>
```

지정된 기간 전의 생성 시간을 가진 리포지토리만 고려됩니다.

명령은 다음을 출력합니다:

- `STDOUT`에 결과 및 명령의 로그를 반환합니다.
- `STDERR`에 오류를 반환합니다.

각 항목은 끝에 줄바꿈이 있는 완전한 JSON 문자열입니다(`-delimiter` 플래그를 사용하여 구성 가능). 예를 들어:

```plaintext
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567890.git"}
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567891.git"}
```

### 추적 데이터베이스에 단일 리포지토리 수동 추가 {#manually-add-a-single-repository-to-the-tracking-database}

> [!warning]
> [알려진 문제](https://gitlab.com/gitlab-org/gitaly/-/issues/5402)로 인해 GitLab 16.0 이전 버전에서는 Praefect에서 생성한 복사본 경로(`@cluster`)를 사용하여 Praefect 추적 데이터베이스에 리포지토리를 추가할 수 없습니다. 이러한 리포지토리는 GitLab에서 사용하는 리포지토리 경로와 관련이 없으며 액세스할 수 없습니다.

`track-repository` Praefect 하위 명령은 디스크상 리포지토리를 Praefect 추적 데이터베이스에 추가하여 추적됩니다.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repository -virtual-storage <virtual-storage> -authoritative-storage <storage-name> -relative-path <repository> -replica-path <disk_path> -replicate-immediately
```

- `-virtual-storage`은 리포지토리가 위치한 가상 스토리지입니다. 가상 저장소는 `/etc/gitlab/gitlab.rb` 아래 `praefect['configuration'][:virtual_storage]`에서 구성되며 다음과 같이 표시됩니다:

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  이 예제에서 지정할 가상 저장소는 `default` 또는 `storage-1`입니다.

- `-relative-path`은 가상 저장소의 상대 경로입니다. 일반적으로 [`@hashed`으로 시작](../../repository_storage_paths.md#hashed-storage)합니다. 예를 들어:

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

- `-replica-path`은 물리적 저장소의 상대 경로입니다. [`@cluster`으로 시작하거나 `relative_path`와 일치](../../repository_storage_paths.md#gitaly-cluster-praefect-storage)할 수 있습니다.
- `-authoritative-storage`은 Praefect가 주 노드로 취급할 저장소입니다. [리포지토리별 복제](configure.md#configure-replication-factor)가 복제 전략으로 설정된 경우 필수입니다.
- `-replicate-immediately`은 명령이 리포지토리를 즉시 보조 노드로 복제하게 합니다. 그렇지 않으면 복제 작업이 데이터베이스에서 실행을 위해 예약되고 Praefect 백그라운드 프로세스에 의해 선택됩니다.

명령은 다음을 출력합니다:

- `STDOUT`에 결과 및 명령의 로그를 반환합니다.
- `STDERR`에 오류를 반환합니다.

이 명령은 다음의 경우 실패합니다:

- 리포지토리가 이미 Praefect 추적 데이터베이스에 의해 추적 중입니다.
- 리포지토리가 디스크에 존재하지 않습니다.

### 추적 데이터베이스에 많은 리포지토리 수동 추가 {#manually-add-many-repositories-to-the-tracking-database}

> [!warning]
> [알려진 문제](https://gitlab.com/gitlab-org/gitaly/-/issues/5402)로 인해 GitLab 16.0 이전 버전에서는 Praefect에서 생성한 복사본 경로(`@cluster`)를 사용하여 Praefect 추적 데이터베이스에 리포지토리를 추가할 수 없습니다. 이러한 리포지토리는 GitLab에서 사용하는 리포지토리 경로와 관련이 없으며 액세스할 수 없습니다.

API를 사용한 마이그레이션은 리포지토리를 Praefect 추적 데이터베이스에 자동으로 추가합니다.

대신 기존 인프라에서 리포지토리를 수동으로 복사하는 경우 `track-repositories` Praefect 하위 명령을 사용할 수 있습니다. 이 하위 명령은 디스크상 리포지토리의 대량을 Praefect 추적 데이터베이스에 추가합니다.

```shell
# Omnibus GitLab install
sudo gitlab-ctl praefect track-repositories --input-path /path/to/input.json

# Source install
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repositories -input-path /path/to/input.json
```

명령은 모든 항목의 유효성을 검사합니다:

- 올바르게 형식이 지정되고 필수 필드를 포함합니다.
- 디스크의 유효한 Git 리포지토리에 해당합니다.
- Praefect 추적 데이터베이스에서 추적되지 않습니다.

항목이 이러한 검사에 실패하면 명령은 리포지토리 추적을 시도하기 전에 중단됩니다.

- `input-path`은 개행 구분 JSON 개체로 형식이 지정된 리포지토리 목록을 포함하는 파일의 경로입니다. 개체는 다음 키를 포함해야 합니다:
  - `relative_path`: [`track-repository`](#manually-add-a-single-repository-to-the-tracking-database)의 `repository`과 일치합니다.
  - `authoritative-storage`: Praefect가 주 노드로 취급할 저장소.
  - `virtual-storage`: 리포지토리가 위치한 가상 저장소.

    예를 들어:

    ```json
    {"relative_path":"@hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git","replica_path":"@cluster/fe/d3/1","authoritative_storage":"gitaly-1","virtual_storage":"default"}
    {"relative_path":"@hashed/f8/9f/f89f8d0e735a91c5269ab08d72fa27670d000e7561698d6e664e7b603f5c4e40.git","replica_path":"@cluster/7b/28/2","authoritative_storage":"gitaly-2","virtual_storage":"default"}
    ```

- `-replicate-immediately`, 명령이 리포지토리를 즉시 보조 노드로 복제하게 합니다. 그렇지 않으면 복제 작업이 데이터베이스에서 실행을 위해 예약되고 Praefect 백그라운드 프로세스에 의해 선택됩니다.

### 가상 저장소 세부 정보 나열 {#list-virtual-storage-details}

`list-storages` Praefect 하위 명령은 가상 저장소 및 관련 저장소 노드를 나열합니다. 가상 저장소인 경우:

- `-virtual-storage`을 사용하여 지정하면 지정된 가상 저장소의 저장소 노드만 나열합니다.
- 지정되지 않으면 모든 가상 저장소 및 관련 저장소 노드가 표 형식으로 나열됩니다.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-storages -virtual-storage <virtual_storage_name>
```

명령은 다음을 출력합니다:

- `STDOUT`에 결과 및 명령의 로그를 반환합니다.
- `STDERR`에 오류를 반환합니다.
