---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Docker 컨테이너에서 실행 중인 GitLab 백업
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

다음 명령으로 GitLab 백업을 생성할 수 있습니다:

```shell
docker exec -t <container name> gitlab-backup create
```

자세한 내용은 [GitLab 백업 및 복원](../../administration/backup_restore/_index.md)을 참조하세요.

GitLab 구성이 `GITLAB_OMNIBUS_CONFIG` 환경 변수를 사용하여 완전히 제공되는 경우(["Docker 컨테이너 사전 구성"](configuration.md#pre-configure-docker-container) 단계 사용), 구성 설정이 `gitlab.rb` 파일에 저장되지 않으므로 `gitlab.rb` 파일을 백업할 필요가 없습니다.

> [!warning]
> 백업에서 GitLab을 복구할 때 [복잡한 단계](../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)를 피하려면 [GitLab 비밀 파일 백업](../../administration/backup_restore/backup_gitlab.md#storing-configuration-files)의 지침도 따라야 합니다. 비밀 파일은 컨테이너 내의 `/etc/gitlab/gitlab-secrets.json` 파일 또는 [컨테이너 호스트](installation.md#create-a-directory-for-the-volumes)의 `$GITLAB_HOME/config/gitlab-secrets.json` 파일에 저장됩니다.

## 데이터베이스 백업 생성 {#create-a-database-backup}

GitLab을 업그레이드하기 전에 데이터베이스 전용 백업을 생성합니다. GitLab 업그레이드 중에 이슈가 발생하면 데이터베이스 백업을 복원하여 업그레이드를 롤백할 수 있습니다. 데이터베이스 백업을 생성하려면 다음 명령을 실행하세요:

```shell
docker exec -t <container name> gitlab-backup create SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state
```

백업이 `/var/opt/gitlab/backups`에 기록되며, 이는 [Docker로 마운트된 볼륨](installation.md#create-a-directory-for-the-volumes)에 있어야 합니다.

업그레이드를 롤백하는 데 백업을 사용하는 방법에 대한 자세한 내용은 [Docker 인스턴스 롤백](../../update/package/downgrade.md#roll-back-a-docker-instance)을 참조하세요.
