---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab에서 관리하는 리포지토리 이동
description: "프로젝트, 스니펫, 그룹을 서버와 스토리지 간에 이동합니다."
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab에서 관리하는 모든 리포지토리를 다른 파일 시스템 또는 다른 서버로 이동합니다.

## GitLab 인스턴스에서 데이터 이동 {#move-data-in-a-gitlab-instance}

GitLab API를 사용하여 Git 리포지토리를 이동합니다:

- 서버 간 이동
- 다양한 스토리지 간 이동
- 단일 노드 Gitaly에서 Gitaly 클러스터(Praefect)로 이동

GitLab 리포지토리는 프로젝트, 그룹, 스니펫과 연결될 수 있습니다. 이러한 각 유형에는 리포지토리 이동을 위한 별도의 API가 있습니다. GitLab 인스턴스의 모든 리포지토리를 이동하려면 각 스토리지마다 각 유형의 리포지토리를 이동해야 합니다.

각 리포지토리는 이동 기간 동안 읽기 전용이 되며 이동이 완료될 때까지 쓸 수 없습니다.

리포지토리를 이동하려면:

1. 모든 [로컬 및 클러스터 스토리지](../gitaly/configure_gitaly.md#mixed-configuration)가 GitLab 인스턴스에 액세스 가능한지 확인합니다. 이 예에서 이들은 `<original_storage_name>` 및 `<cluster_storage_name>`입니다.
1. [리포지토리 스토리지 가중치 구성](../repository_storage_paths.md#configure-where-new-repositories-are-stored)을 수행하여 새 스토리지가 모든 새 프로젝트를 수신하도록 합니다. 이는 마이그레이션이 진행 중인 동안 기존 스토리지에서 새 프로젝트가 생성되는 것을 방지합니다.
1. 프로젝트, 스니펫, 그룹에 대한 리포지토리 이동을 예약합니다.
1. [Geo](../geo/_index.md) 를 사용하는 경우 [모든 리포지토리를 재동기화](../geo/replication/troubleshooting/synchronization_verification.md#resync-resources-for-the-selected-component)합니다.
1. Sidekiq 포드에서 Horizontal Pod Autoscaler를 사용하는 경우, 마이그레이션 중 스케일링을 방지하기 위해 [Sidekiq 포드에 대해 HPA 비활성화](https://docs.gitlab.com/charts/gitlab/sidekiq/#disable-hpa-scaling)합니다.

### 프로젝트 이동 {#move-projects}

모든 프로젝트 또는 개별 프로젝트를 이동할 수 있습니다.

API를 사용하여 모든 프로젝트를 이동하려면:

1. API를 사용하여 [스토리지 샤드의 모든 프로젝트에 대한 리포지토리 스토리지 이동 예약](../../api/project_repository_storage_moves.md#create-repository-storage-moves-for-all-projects-on-a-storage-shard)을 수행합니다. 예를 들어:

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/project_repository_storage_moves"
   ```

1. API를 사용하여 [가장 최근의 리포지토리 이동 쿼리](../../api/project_repository_storage_moves.md#list-all-project-repository-storage-moves)를 수행합니다. 응답은 다음 중 하나를 나타냅니다:
   - 이동이 성공적으로 완료되었습니다. `state` 필드가 `finished`입니다.
   - 이동이 진행 중입니다. 리포지토리 이동이 성공적으로 완료될 때까지 재쿼리합니다.
   - 이동이 실패했습니다. 대부분의 오류는 일시적이며 이동을 다시 예약하여 해결됩니다.

1. 이동이 완료되면 API를 사용하여 [프로젝트 쿼리](../../api/projects.md#list-all-projects)를 수행하고 모든 프로젝트가 이동되었음을 확인합니다. `repository_storage` 필드가 이전 스토리지로 설정된 프로젝트가 반환되지 않아야 합니다. 예를 들어:

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
   "https://gitlab.example.com/api/v4/projects?repository_storage=<original_storage_name>"
   ```

   또는 Rails 콘솔을 사용하여 모든 프로젝트가 이동되었는지 확인합니다:

   ```ruby
   ProjectRepository.for_repository_storage('<original_storage_name>')
   ```

1. 필요에 따라 각 스토리지에 대해 반복합니다.

모든 프로젝트를 이동하지 않으려면 [개별 프로젝트 이동](../../api/project_repository_storage_moves.md#create-a-repository-storage-move-for-a-project) 지침을 따릅니다.

### 스니펫 이동 {#move-snippets}

모든 스니펫 또는 개별 스니펫을 이동할 수 있습니다.

API를 사용하여 모든 스니펫을 이동하려면:

1. [스토리지 샤드의 모든 스니펫에 대한 리포지토리 스토리지 이동 예약](../../api/snippet_repository_storage_moves.md#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard)을 수행합니다. 예를 들어:

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
   ```

1. [가장 최근의 리포지토리 이동 쿼리](../../api/snippet_repository_storage_moves.md#list-all-snippet-repository-storage-moves)를 수행합니다. 응답은 다음 중 하나를 나타냅니다:
   - 이동이 성공적으로 완료되었습니다. `state` 필드가 `finished`입니다.
   - 이동이 진행 중입니다. 리포지토리 이동이 성공적으로 완료될 때까지 재쿼리합니다.
   - 이동이 실패했습니다. 대부분의 오류는 일시적이며 이동을 다시 예약하여 해결됩니다.

1. 이동이 완료되면 Rails 콘솔을 사용하여 모든 스니펫이 이동되었는지 확인합니다:

   ```ruby
   SnippetRepository.for_repository_storage('<original_storage_name>')
   ```

   명령이 원본 스토리지에서 스니펫을 반환하지 않아야 합니다.

1. 필요에 따라 각 스토리지에 대해 반복합니다.

모든 스니펫을 이동하지 않으려면 [개별 스니펫](../../api/snippet_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-snippet) 지침을 따릅니다.

### 그룹 이동 {#move-groups}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

모든 그룹 또는 개별 그룹을 이동할 수 있습니다.

API를 사용하여 모든 그룹을 이동하려면:

1. [스토리지 샤드의 모든 그룹에 대한 리포지토리 스토리지 이동 예약](../../api/group_repository_storage_moves.md#create-group-repository-storage-moves-for-a-storage-shard)을 수행합니다. 예를 들어:

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/group_repository_storage_moves"
   ```

1. [가장 최근의 리포지토리 이동 쿼리](../../api/group_repository_storage_moves.md#list-all-group-repository-storage-moves)를 수행합니다. 응답은 다음 중 하나를 나타냅니다:
   - 이동이 성공적으로 완료되었습니다. `state` 필드가 `finished`입니다.
   - 이동이 진행 중입니다. 리포지토리 이동이 성공적으로 완료될 때까지 재쿼리합니다.
   - 이동이 실패했습니다. 대부분의 오류는 일시적이며 이동을 다시 예약하여 해결됩니다.

1. 이동이 완료되면 Rails 콘솔을 사용하여 모든 그룹이 이동되었는지 확인합니다:

   ```ruby
   GroupWikiRepository.for_repository_storage('<original_storage_name>')
   ```

   명령이 원본 스토리지에서 그룹을 반환하지 않아야 합니다.

1. 필요에 따라 각 스토리지에 대해 반복합니다.

모든 그룹을 이동하지 않으려면 [개별 그룹](../../api/group_repository_storage_moves.md#create-a-group-repository-storage-move) 지침을 따릅니다.

## 다른 GitLab 인스턴스로 마이그레이션 {#migrate-to-another-gitlab-instance}

새 GitLab 환경으로 마이그레이션하는 경우 [API를 사용하여 데이터 이동](#move-data-in-a-gitlab-instance)을 수행할 수 없습니다. 예를 들어:

- 단일 노드 GitLab에서 확장된 아키텍처로
- 프라이빗 데이터 센터의 GitLab 인스턴스에서 클라우드 공급자로

이 경우 `/var/opt/gitlab/git-data/repositories`에서 `/mnt/gitlab/repositories`로 모든 리포지토리를 복사할 수 있는 방법이 있습니다(시나리오에 따라 다름):

- 대상 디렉터리가 비어 있습니다.
- 대상 디렉터리에 리포지토리의 오래된 복사본이 포함되어 있습니다.
- 수천 개의 리포지토리가 있는 경우

> [!warning]
> 이 방법들 각각은 대상 디렉터리 `/mnt/gitlab/repositories`의 데이터를 덮어쓸 수 있거나 덮어씁니다. 원본과 대상을 올바르게 지정해야 합니다.

### 백업 및 복원 사용(권장) {#use-backup-and-restore-recommended}

Gitaly 또는 Gitaly 클러스터(Praefect) 대상의 경우 GitLab [백업 및 복원 기능](../backup_restore/_index.md)을 사용해야 합니다. Git 리포지토리는 Gitaly에 의해 GitLab 서버에서 데이터베이스로 액세스, 관리 및 저장됩니다. `rsync`과 같은 도구를 사용하여 Gitaly 파일을 직접 액세스하고 복사하면 데이터 손실이 발생할 수 있습니다. 다음을 수행할 수 있습니다:

- [여러 리포지토리를 동시에 처리](../backup_restore/backup_gitlab.md#back-up-git-repositories-concurrently)하여 백업 성능을 향상합니다.
- [건너뛰기 기능](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)을 사용하여 리포지토리만 백업합니다.

Gitaly 클러스터(Praefect) 대상의 경우 백업 및 복원 방법을 사용해야 합니다.

### `tar` 사용 {#use-tar}

`tar` 파이프를 사용하여 리포지토리를 이동할 수 있는 경우:

- Gitaly 클러스터 대상이 아닌 Gitaly 대상을 지정합니다.
- 대상 디렉터리 `/mnt/gitlab/repositories`이(가) 비어 있습니다.

이 방법은 오버헤드가 낮고 `tar`은 일반적으로 시스템에 사전 설치되어 있습니다. 그러나 중단된 `tar` 파이프를 재개할 수 없습니다. `tar`이 중단되면 대상 디렉터리를 비우고 모든 데이터를 다시 복사해야 합니다.

`tar` 프로세스의 진행 상황을 보려면 `-xf`를 `-xvf`로 바꿉니다.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  tar -C /mnt/gitlab/repositories -xf -'
```

#### `tar` 파이프를 다른 서버로 {#use-a-tar-pipe-to-another-server}

Gitaly 대상의 경우 `tar` 파이프를 사용하여 데이터를 다른 서버로 복사할 수 있습니다. `git` 사용자가 `git@<newserver>`으로 새 서버에 대한 SSH 액세스 권한이 있으면 SSH를 통해 데이터를 파이프할 수 있습니다.

네트워크를 통해 데이터를 압축하려는 경우(CPU 사용률 증가) `ssh`을 `ssh -C`로 바꿀 수 있습니다.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  ssh git@newserver tar -C /mnt/gitlab/repositories -xf -'
```

### `rsync` 사용 {#use-rsync}

`rsync`을 사용하여 리포지토리를 이동할 수 있는 경우:

- Gitaly 클러스터 대상이 아닌 Gitaly 대상을 지정합니다.
- 대상 디렉터리에 이미 리포지토리의 부분적 또는 오래된 복사본이 포함되어 있으므로 `tar`을 사용하여 모든 데이터를 다시 복사하는 것은 비효율적입니다.

> [!warning]
> `rsync`을 사용할 때 `--delete` 옵션을 사용해야 합니다. `rsync`을 `--delete` 없이 사용하면 데이터 손실 및 리포지토리 손상이 발생할 수 있습니다. 자세한 내용은 [이슈 270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422)를 참조하세요.

다음 명령에서 `/.`은 매우 중요합니다. 그렇지 않으면 대상 디렉터리에서 잘못된 디렉터리 구조를 얻을 수 있습니다. 진행 상황을 보려면 `-a`를 `-av`으로 바꿉니다.

```shell
sudo -u git  sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  /mnt/gitlab/repositories'
```

#### `rsync`을 다른 서버로 {#use-rsync-to-another-server}

Gitaly 대상의 경우 `rsync`으로 네트워크를 통해 리포지토리를 보낼 수 있습니다(원본 시스템의 `git` 사용자가 대상 서버에 대한 SSH 액세스 권한이 있는 경우).

```shell
sudo -u git sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  git@newserver:/mnt/gitlab/repositories'
```

## 관련 항목 {#related-topics}

- [Gitaly 구성](../gitaly/configure_gitaly.md)
- [Gitaly 클러스터(Praefect)](../gitaly/praefect/_index.md)
- [프로젝트 리포지토리 스토리지 이동 API](../../api/project_repository_storage_moves.md)
- [그룹 리포지토리 스토리지 이동 API](../../api/group_repository_storage_moves.md)
- [스니펫 리포지토리 스토리지 이동 API](../../api/snippet_repository_storage_moves.md)
