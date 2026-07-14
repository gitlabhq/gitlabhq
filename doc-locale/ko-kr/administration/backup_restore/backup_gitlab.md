---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 백업
description: GitLab Self-Managed 인스턴스를 백업합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 백업은 데이터를 보호하고 재해 복구에 도움이 됩니다.

최적의 백업 전략은 GitLab 배포 구성, 데이터 볼륨 및 저장소 위치에 따라 달라집니다. 이러한 요소들은 사용할 백업 방법, 백업을 저장할 위치 및 백업 일정을 구성하는 방식을 결정합니다.

더 큰 GitLab 인스턴스의 경우 대체 백업 전략은 다음과 같습니다:

- 증분 백업
- 특정 리포지토리의 백업
- 여러 저장소 위치 간 백업

## 백업에 포함된 데이터 {#data-included-in-a-backup}

{{< history >}}

- [도입된](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121142) Secure Files(GitLab 16.1).
- 외부 머지 리퀘스트 diffs [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154914)(GitLab 17.1).

{{< /history >}}

GitLab은 전체 인스턴스를 백업하는 명령줄 인터페이스를 제공합니다. 기본적으로 백업은 단일 압축된 tar 파일에 아카이브를 생성합니다. 이 파일에는 다음이 포함됩니다:

- 데이터베이스 데이터 및 구성
- 계정 및 그룹 설정
- CI/CD 아티팩트 및 작업 로그
- Git 리포지토리 및 LFS 객체
- 외부 머지 리퀘스트 diffs
- 패키지 레지스트리 데이터 및 컨테이너 레지스트리 이미지
- 프로젝트 및 그룹 wikis
- 프로젝트 수준의 첨부 파일 및 업로드
- 비밀 파일
- GitLab Pages 콘텐츠
- Terraform 상태
- 스니펫

## 백업에 포함되지 않은 데이터 {#data-not-included-in-a-backup}

> [!warning]
> 설정 파일을 [별도로 백업](#storing-configuration-files)하려면 반드시 읽어보시기 바랍니다.

- [Mattermost 데이터](../../integration/mattermost/_index.md#back-up-gitlab-mattermost)
- Redis(따라서 Sidekiq 작업)
- Linux 패키지(Omnibus) / Docker / Self-compiled 설치의 [Object Storage](#object-storage)
- [Global server hooks](../server_hooks.md#create-global-server-hooks-for-all-repositories)
- [File hooks](../file_hooks.md)
- GitLab 구성 파일(`/etc/gitlab`)
- TLS 및 SSH 관련 키 및 인증서
- 기타 시스템 파일

## 간단한 백업 절차 {#simple-backup-procedure}

대략적인 가이드로, 1k 참조 아키텍처를 사용하고 100GB 미만의 데이터가 있는 경우 다음 단계를 따릅니다:

1. 백업 명령을 실행합니다.
1. 해당되는 경우 Object Storage를 백업합니다.
1. 시스템 구성 파일을 수동으로 백업합니다.

참고 항목:

- [1k 참조 아키텍처](../reference_architectures/1k_users.md)
- [백업 명령 세부정보](#backup-command)
- [Object Storage 구성](#object-storage)
- [구성 파일 가이드](#storing-configuration-files)

## 백업 확장 {#scaling-backups}

GitLab 데이터의 양이 증가하면 백업 명령을 실행하는 데 더 오래 걸립니다. Git 리포지토리를 동시에 백업하고 증분 리포지토리 백업과 같은 백업 옵션은 실행 시간을 줄이는 데 도움이 될 수 있습니다. 어느 시점에서는 백업 명령이 자체적으로는 실용적이지 않게 됩니다. 예를 들어 24시간 이상이 소요될 수 있습니다.

GitLab 18.0부터 많은 수의 참조(브랜치, 태그)가 있는 리포지토리에 대한 리포지토리 백업 성능이 크게 향상되었습니다. 이 개선 사항은 영향을 받는 리포지토리의 백업 시간을 시간에서 분 단위로 줄일 수 있습니다. 이 개선 사항을 활용하기 위해 구성 변경이 필요하지 않습니다.

경우에 따라 백업을 확장할 수 있도록 아키텍처 변경이 필요할 수 있습니다.

추가 정보:

- [증분 리포지토리 백업](#incremental-repository-backups).
- [Git 리포지토리를 동시에 백업](#back-up-git-repositories-concurrently).
- [대규모 참조 아키텍처 백업 및 복원](backup_large_reference_architectures.md).
- [대체 백업 전략](#alternative-backup-strategies).
- [GitLab 리포지토리 백업 시간 단축에 관한 블로그 게시물](https://about.gitlab.com/blog/how-we-decreased-gitlab-repo-backup-times-from-48-hours-to-41-minutes/).

## 백업해야 할 데이터 {#what-data-needs-to-be-backed-up}

다음 데이터를 백업해야 합니다.

### PostgreSQL 데이터베이스 {#postgresql-databases}

가장 간단한 경우 GitLab은 다른 모든 GitLab 서비스와 동일한 VM의 하나의 PostgreSQL 서버에 하나의 PostgreSQL 데이터베이스가 있습니다. 하지만 구성에 따라 GitLab은 여러 PostgreSQL 서버에서 여러 PostgreSQL 데이터베이스를 사용할 수 있습니다.

일반적으로 이 데이터는 웹 인터페이스의 대부분의 사용자 생성 콘텐츠(예: 이슈 및 머지 리퀘스트 콘텐츠, 댓글, 권한 및 자격증명)의 단일 정보 소스입니다.

PostgreSQL은 또한 HTML로 렌더링된 Markdown, 그리고 기본적으로 머지 리퀘스트 diffs와 같은 캐시된 데이터를 보유합니다. 그러나 머지 리퀘스트 diffs는 [파일 시스템 또는 Object Storage로 오프로드](#blobs)되도록 구성할 수도 있습니다.

Gitaly Cluster(Praefect)는 Gitaly 노드를 관리하기 위한 단일 정보 소스로 PostgreSQL 데이터베이스를 사용합니다.

일반적인 PostgreSQL 유틸리티인 [`pg_dump`](https://www.postgresql.org/docs/16/app-pgdump.html)는 PostgreSQL 데이터베이스를 복원하는 데 사용할 수 있는 백업 파일을 생성합니다. [백업 명령](#backup-command)은 내부적으로 이 유틸리티를 사용합니다.

안타깝게도 데이터베이스가 클수록 `pg_dump`을 실행하는 데 더 오래 걸립니다. 상황에 따라 특정 시점에서 기간이 비현실적이 됩니다(예: 며칠). 데이터베이스가 100GB를 초과하면 `pg_dump` 및 [백업 명령](#backup-command)은 사용하기 어려울 가능성이 높습니다. 자세한 내용은 [대체 백업 전략](#alternative-backup-strategies)을 참조하세요.

### Git 리포지토리 {#git-repositories}

GitLab 인스턴스는 하나 이상의 리포지토리 샤드를 가질 수 있습니다. 각 샤드는 로컬에 저장된 Git 리포지토리에 대한 액세스 및 작업을 허용하는 역할을 하는 Gitaly 인스턴스 또는 Gitaly Cluster(Praefect)입니다. Gitaly는 다음과 같은 머신에서 실행될 수 있습니다:

- 단일 디스크 포함.
- 단일 mount-point(RAID 배열 같은)로 마운트된 여러 디스크 포함.
- LVM 사용.

각 프로젝트는 최대 3개의 서로 다른 리포지토리를 가질 수 있습니다:

- 소스 코드가 저장되는 프로젝트 리포지토리.
- wiki 콘텐츠가 저장되는 wiki 리포지토리.
- 설계 아티팩트가 인덱싱되는 설계 리포지토리(자산은 실제로 LFS에 있음).

모두 동일한 샤드에 있고 Wiki 및 Design 리포지토리 경우에 `-wiki` 및 `-design` 접미사로 동일한 기본 이름을 공유합니다.

개인 및 프로젝트 스니펫, 그룹 wiki 콘텐츠는 Git 리포지토리에 저장됩니다.

프로젝트 포크는 GitLab 사이트의 풀 리포지토리를 사용하여 중복 제거됩니다.

백업 명령은 각 리포지토리에 대해 Git 번들을 생성하고 모두 tar합니다. 이것은 풀 리포지토리 데이터를 모든 포크로 복제합니다. 테스트에서 100GB의 Git 리포지토리를 백업하고 S3에 업로드하는 데 2시간 이상이 걸렸습니다. 약 400GB의 Git 데이터에서 백업 명령은 정규적인 백업에 실용적이지 않을 가능성이 높습니다. 자세한 내용은 [대체 백업 전략](#alternative-backup-strategies)을 참조하세요.

### Blobs {#blobs}

GitLab은 이슈 첨부 파일 또는 LFS 객체와 같은 blobs(또는 파일)를 다음 중 하나로 저장합니다:

- 특정 위치의 파일 시스템입니다.
- [Object Storage](../object_storage.md) 솔루션. Object Storage 솔루션은 다음과 같을 수 있습니다:
  - Amazon S3 및 Google Cloud Storage 같은 클라우드 기반입니다.
  - Self-hosted S3 호환 Object Storage.
  - Object Storage 호환 API를 노출하는 저장소 어플라이언스.

#### Object Storage {#object-storage}

백업 명령은 파일 시스템에 저장되지 않은 blobs을 백업하지 않습니다. Object Storage를 사용하는 경우 Object Storage 제공자와 함께 백업을 활성화해야 합니다.

제공자 특정 백업 가이드:

- [Amazon S3 백업](https://docs.aws.amazon.com/aws-backup/latest/devguide/s3-backups.html)
- [Google Cloud Storage Transfer Service](https://cloud.google.com/storage-transfer-service)
- [Google Cloud Storage Object Versioning](https://cloud.google.com/storage/docs/object-versioning)

참고 항목:

- [백업 명령 세부정보](#backup-command)
- [Object Storage 구성](../object_storage.md)

### 컨테이너 레지스트리 {#container-registry}

GitLab 컨테이너 레지스트리 저장소는 다음 중 하나로 구성할 수 있습니다:

- 특정 위치의 파일 시스템입니다.
- Object Storage 솔루션. Object Storage 솔루션은 다음과 같을 수 있습니다:
  - Amazon S3 및 Google Cloud Storage 같은 클라우드 기반입니다.
  - Self-hosted S3 호환 Object Storage.
  - Object Storage 호환 API를 노출하는 저장소 어플라이언스.

백업 명령은 Object Storage에 저장된 경우 레지스트리 데이터를 백업하지 않습니다.

#### 메타데이터 데이터베이스 {#metadata-database}

[컨테이너 레지스트리 메타데이터 데이터베이스](https://docs.gitlab.com/charts/charts/registry/metadata_database)를 활성화한 경우 백업 중 레지스트리 데이터베이스에 대한 액세스를 구성해야 합니다. GitLab 설치에 필요한 자격증명을 구성하려면 지침을 따르세요:

- [Linux 패키지 지침](https://docs.gitlab.com/omnibus/settings/backups/#container-registry-metadata-database-backup-credentials)
- [GitLab Helm chart](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#registry-metadata-database-credentials)

참고 항목:

- [GitLab 컨테이너 레지스트리](../packages/container_registry.md)
- [Object Storage 구성](../object_storage.md)

### 구성 파일 저장 {#storing-configuration-files}

> [!warning]
> GitLab이 제공하는 백업 Rake 작업은 구성 파일을 저장하지 않습니다. 주된 이유는 데이터베이스에 2단계 인증 및 CI/CD 보안 변수에 대한 암호화된 정보를 포함하는 항목이 포함되어 있기 때문입니다. 암호화된 정보를 해당 키와 동일한 위치에 저장하면 처음부터 암호화를 사용하는 목적이 무의미해집니다. 예를 들어 비밀 파일은 데이터베이스 암호화 키를 포함합니다. 이를 잃으면 GitLab 응용 프로그램은 데이터베이스의 암호화된 값을 해독할 수 없습니다.
>
> 또한 업그레이드 후 비밀 파일이 변경될 수 있습니다.

구성 디렉터리를 백업해야 합니다. 최소한 다음을 백업해야 합니다:

{{< tabs >}}

{{< tab title="Linux 패키지" >}}

- `/etc/gitlab/gitlab-secrets.json`
- `/etc/gitlab/gitlab.rb`

자세한 내용은 [Linux 패키지(Omnibus) 구성 백업 및 복원](https://docs.gitlab.com/omnibus/settings/backups/#backup-and-restore-omnibus-gitlab-configuration)을 참조하세요.

{{< /tab >}}

{{< tab title="Self-compiled" >}}

- `/home/git/gitlab/config/secrets.yml`
- `/home/git/gitlab/config/gitlab.yml`

{{< /tab >}}

{{< tab title="Docker" >}}

- 구성 파일이 저장된 볼륨을 백업합니다. 문서에 따라 GitLab 컨테이너를 생성한 경우 `/srv/gitlab/config` 디렉터리에 있어야 합니다.

{{< /tab >}}

{{< tab title="GitLab Helm chart" >}}

- [비밀 백업](https://docs.gitlab.com/charts/backup-restore/backup/#back-up-the-secrets) 지침을 따르세요.

{{< /tab >}}

{{< /tabs >}}

또한 TLS 키 및 인증서(`/etc/gitlab/ssl`, `/etc/gitlab/trusted-certs`) 및 [SSH 호스트 키](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)를 백업하여 전체 시스템 복구를 수행해야 하는 경우 중간자 공격 경고를 방지할 수 있습니다.

비밀 파일이 손실된 경우 [비밀 파일이 손실되었을 때](troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)를 참조하세요.

### 기타 데이터 {#other-data}

GitLab은 Redis를 캐시 저장소로 사용하고 백그라운드 작업 시스템인 Sidekiq을 위한 영구 데이터를 보유합니다. 제공된 백업 명령은 Redis 데이터를 백업하지 않습니다. 이는 백업 명령으로 일관된 백업을 수행하려면 보류 중이거나 실행 중인 백그라운드 작업이 없어야 함을 의미합니다.

Elasticsearch는 고급 검색을 위한 선택 사항인 데이터베이스입니다. 소스 코드 수준과 이슈, 머지 리퀘스트 및 토론의 사용자 생성 콘텐츠 모두에서 검색을 개선할 수 있습니다. 백업 명령은 Elasticsearch 데이터를 백업하지 않습니다. Elasticsearch 데이터는 복원 후 PostgreSQL 데이터에서 재생성할 수 있습니다.

수동 백업 옵션:

- [Redis 백업 절차](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/#backing-up-redis-data)
- [Elasticsearch 백업 절차](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)

참고 항목: [백업 명령 세부정보](#backup-command).

### 요구사항 {#requirements}

백업 및 복원을 수행하려면 시스템에 Rsync가 설치되어 있는지 확인하세요. GitLab을 설치한 경우:

- Linux 패키지를 사용하는 경우 Rsync가 이미 설치되어 있습니다.
- Self-compiled를 사용하는 경우 `rsync`이 설치되어 있는지 확인하고 설치되지 않았으면 설치하세요.

### 백업 명령 {#backup-command}

- 백업 명령은 Linux 패키지(Omnibus) / Docker / Self-compiled 설치의 Object Storage에 있는 항목을 백업하지 않습니다.
- 백업 명령은 설치에서 PgBouncer를 사용하는 경우 성능상의 이유로 또는 Patroni 클러스터와 함께 사용할 때 추가 매개변수가 필요합니다.
- 백업을 생성된 동일한 버전 및 유형(CE/EE)의 GitLab으로만 복원할 수 있습니다.

**Important considerations:**

- [Object Storage 제한사항](#object-storage)
- [PgBouncer 구성 요구사항](#back-up-and-restore-for-installations-using-pgbouncer)

백업을 생성하려면:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup create
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

`kubectl`을 사용하여 GitLab toolbox pod에서 `backup-utility` 스크립트를 실행하여 백업 작업을 실행합니다. 자세한 내용은 [charts 백업 문서](https://docs.gitlab.com/charts/backup-restore/backup/)를 참조하세요.

{{< /tab >}}

{{< tab title="Docker" >}}

호스트에서 백업을 실행합니다.

```shell
docker exec -t <container name> gitlab-backup create
```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

GitLab 배포에 여러 노드가 있는 경우 백업 명령을 실행할 노드를 선택해야 합니다. 지정된 노드가 다음을 확인해야 합니다:

- 영구적이며 자동 크기 조정의 대상이 아닙니다.
- GitLab Rails 응용 프로그램이 이미 설치되어 있습니다. Puma 또는 Sidekiq이 실행 중이면 Rails가 설치됩니다.
- 백업 파일을 생성할 충분한 저장소 및 메모리가 있습니다.

예제 출력:

```plaintext
Dumping database tables:
- Dumping table events... [DONE]
- Dumping table issues... [DONE]
- Dumping table keys... [DONE]
- Dumping table merge_requests... [DONE]
- Dumping table milestones... [DONE]
- Dumping table namespaces... [DONE]
- Dumping table notes... [DONE]
- Dumping table projects... [DONE]
- Dumping table protected_branches... [DONE]
- Dumping table schema_migrations... [DONE]
- Dumping table services... [DONE]
- Dumping table snippets... [DONE]
- Dumping table taggings... [DONE]
- Dumping table tags... [DONE]
- Dumping table users... [DONE]
- Dumping table users_projects... [DONE]
- Dumping table web_hooks... [DONE]
- Dumping table wikis... [DONE]
Dumping repositories:
- Dumping repository abcd... [DONE]
Creating backup archive: <backup-id>_gitlab_backup.tar [DONE]
Deleting tmp directories...[DONE]
Deleting old backups... [SKIPPING]
```

백업 프로세스에 대한 자세한 내용은 [백업 아카이브 프로세스](backup_archive_process.md)를 참조하세요.

### 백업 옵션 {#backup-options}

GitLab이 제공하는 명령줄 도구는 더 많은 옵션을 수락할 수 있습니다.

#### 백업 전략 옵션 {#backup-strategy-option}

기본 백업 전략은 본질적으로 Linux 명령 `tar` 및 `gzip`를 사용하여 각 데이터 위치에서 백업으로 데이터를 스트리밍하는 것입니다. 이는 대부분의 경우 잘 작동하지만 데이터가 빠르게 변경되는 경우 문제가 발생할 수 있습니다.

`tar`이 읽는 동안 데이터가 변경되면 오류 `file changed as we read it`이 발생할 수 있으며 백업 프로세스가 실패합니다. 이 경우 `copy`라고 하는 백업 전략을 사용할 수 있습니다. 전략은 데이터 파일을 임시 위치로 복사한 후 `tar` 및 `gzip`을 호출하여 오류를 방지합니다.

부작용은 백업 프로세스가 추가 1X 디스크 공간을 차지한다는 것입니다. 프로세스는 각 스테이지에서 임시 파일을 정리하여 문제가 복합되지 않도록 최선을 다하지만 대규모 설치의 경우 상당한 변화가 될 수 있습니다.

`copy` 전략을 기본 스트리밍 전략 대신 사용하려면 Rake 작업 명령에서 `STRATEGY=copy`를 지정하세요. 예를 들어:

```shell
sudo gitlab-backup create STRATEGY=copy
```

#### 백업 파일명 {#backup-filename}

> [!warning]
> 사용자 정의 백업 파일명을 사용하는 경우 [백업의 수명 제한](#limit-backup-lifetime-for-local-files-prune-old-backups)을 할 수 없습니다.

백업 파일은 [특정 기본값](backup_archive_process.md#backup-id)에 따라 파일명으로 생성됩니다. 그러나 `<backup-id>` 부분을 `BACKUP` 환경 변수로 설정하여 재정의할 수 있습니다. 예를 들어:

```shell
sudo gitlab-backup create BACKUP=dump
```

결과 파일의 이름은 `dump_gitlab_backup.tar`입니다. 이는 rsync 및 증분 백업을 사용하는 시스템에 유용하며 훨씬 빠른 전송 속도를 제공합니다.

#### 백업 압축 {#backup-compression}

기본적으로 Gzip 빠른 압축이 다음 항목의 백업 중에 적용됩니다:

- PostgreSQL 데이터베이스 덤프.
- Blobs, 예를 들어 업로드, 작업 아티팩트, 외부 머지 리퀘스트 diffs.

참고 항목:

- [PostgreSQL 데이터베이스](#postgresql-databases)
- [Blobs](#blobs)

기본 명령은 `gzip -c -1`입니다. 이 명령을 `COMPRESS_CMD`로 재정의할 수 있습니다. 마찬가지로 압축 해제 명령을 `DECOMPRESS_CMD`으로 재정의할 수 있습니다.

주의사항:

- 압축 명령은 파이프라인에서 사용되므로 사용자 정의 명령은 `stdout`로 출력해야 합니다.
- GitLab과 함께 패키지되지 않은 명령을 지정하는 경우 직접 설치해야 합니다.
- 결과 파일 이름은 여전히 `.gz`로 끝납니다.
- 복원 중에 사용되는 기본 압축 해제 명령은 `gzip -cd`입니다. 따라서 압축 명령을 `gzip -cd`로 압축 해제할 수 없는 형식으로 재정의하는 경우 복원 중에 압축 해제 명령을 재정의해야 합니다.
- 백업 명령 뒤에 환경 변수를 배치하지 마세요. 예를 들어 `gitlab-backup create COMPRESS_CMD="pigz -c --best"`은 의도한 대로 작동하지 않습니다.

##### 기본 압축:  가장 빠른 방법을 사용하는 Gzip {#default-compression-gzip-with-fastest-method}

```shell
gitlab-backup create
```

##### 가장 느린 방법을 사용하는 Gzip {#gzip-with-slowest-method}

```shell
COMPRESS_CMD="gzip -c --best" gitlab-backup create
```

`gzip`이 백업에 사용된 경우 복원에는 옵션이 필요하지 않습니다:

```shell
gitlab-backup restore
```

##### 압축 없음 {#no-compression}

백업 대상에 기본 제공되는 자동 압축이 있는 경우 압축을 건너뛸 수 있습니다.

`tee` 명령은 `stdin`을 `stdout`으로 전달합니다.

```shell
COMPRESS_CMD=tee gitlab-backup create
```

복원:

```shell
DECOMPRESS_CMD=tee gitlab-backup restore
```

##### `pigz`을 사용한 병렬 압축 {#parallel-compression-with-pigz}

> [!warning]
> `COMPRESS_CMD` 및 `DECOMPRESS_CMD`을 사용하여 기본 Gzip 압축 라이브러리를 재정의하는 것은 지원하지만 기본 Gzip 라이브러리를 기본 옵션으로 일상적으로만 테스트합니다. 백업의 생존력을 테스트하고 검증할 책임이 있습니다. 압축 명령을 재정의하는지 여부에 관계없이 백업에 대한 일반적인 모범 사례로 이를 강력히 권장합니다. 다른 압축 라이브러리에서 이슈가 발생하면 기본값으로 되돌아가야 합니다. 대체 라이브러리의 문제 해결 및 오류 수정은 GitLab의 낮은 우선순위입니다.

`pigz`을 사용하여 백업을 압축하는 예입니다(4개 프로세스 사용):

```shell
sudo COMPRESS_CMD="pigz --stdout --fast --processes 4" gitlab-backup create
```

`pigz`은 `gzip` 형식으로 압축하므로 `pigz`을 사용하여 `pigz`로 압축된 백업을 압축 해제할 필요가 없습니다. 그러나 `gzip`보다 성능상의 이점이 있을 수 있습니다. `pigz`로 백업을 압축 해제하는 예입니다:

```shell
sudo DECOMPRESS_CMD="pigz --decompress --stdout" gitlab-backup restore
```

> [!note]
> `pigz`은 GitLab Linux 패키지에 포함되지 않습니다. 직접 설치해야 합니다.

##### `zstd`을 사용한 병렬 압축 {#parallel-compression-with-zstd}

> [!warning]
> `COMPRESS_CMD` 및 `DECOMPRESS_CMD`을 사용하여 기본 Gzip 압축 라이브러리를 재정의하는 것은 지원하지만 기본 Gzip 라이브러리를 기본 옵션으로 일상적으로만 테스트합니다. 백업의 생존력을 테스트하고 검증할 책임이 있습니다. 압축 명령을 재정의하는지 여부에 관계없이 백업에 대한 일반적인 모범 사례로 이를 강력히 권장합니다. 다른 압축 라이브러리에서 이슈가 발생하면 기본값으로 되돌아가야 합니다. 대체 라이브러리의 문제 해결 및 오류 수정은 GitLab의 낮은 우선순위입니다.

`zstd`을 사용하여 백업을 압축하는 예입니다(4개 스레드 사용):

```shell
sudo COMPRESS_CMD="zstd --compress --stdout --fast --threads=4" gitlab-backup create
```

`zstd`로 백업을 압축 해제하는 예입니다:

```shell
sudo DECOMPRESS_CMD="zstd --decompress --stdout" gitlab-backup restore
```

> [!note]
> `zstd`은 GitLab Linux 패키지에 포함되지 않습니다. 직접 설치해야 합니다.

#### 아카이브를 전송할 수 있는지 확인 {#confirm-archive-can-be-transferred}

생성된 아카이브가 rsync로 전송 가능한지 확인하려면 `GZIP_RSYNCABLE=yes` 옵션을 설정할 수 있습니다. 이는 `--rsyncable` 옵션을 `gzip`으로 설정하며, 이는 [백업 파일명 옵션 설정](#backup-filename)과 함께 사용할 때만 유용합니다.

`--rsyncable` 옵션은 `gzip`에서 모든 배포에서 사용 가능하도록 보장되지 않습니다. 배포에서 사용 가능한지 확인하려면 `gzip --help`을 실행하거나 man 페이지를 참조하세요.

```shell
sudo gitlab-backup create BACKUP=dump GZIP_RSYNCABLE=yes
```

#### 백업에서 특정 데이터 제외 {#excluding-specific-data-from-the-backup}

설치 유형에 따라 백업 생성 시 약간 다른 구성 요소를 건너뛸 수 있습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus) / Docker / Self-compiled" >}}

<!-- source: <https://gitlab.com/gitlab-org/gitlab/-/blob/d693aa7f894c7306a0d20ab6d138a7b95785f2ff/lib/backup/manager.rb#L117-133> -->

- `db` (데이터베이스)
- `repositories` (Git 리포지토리 데이터, wikis 포함)
- `uploads` (첨부 파일)
- `builds` (CI 작업 출력 로그)
- `artifacts` (CI 작업 아티팩트)
- `pages` (Pages 콘텐츠)
- `lfs` (LFS 객체)
- `terraform_state` (Terraform 상태)
- `registry` (컨테이너 레지스트리 이미지)
- `packages` (패키지)
- `ci_secure_files` (프로젝트 수준의 보안 파일)
- `external_diffs` (외부 머지 리퀘스트 diffs)

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

<!-- source: <https://gitlab.com/gitlab-org/build/CNG/-/blob/068e146db915efcd875414e04403410b71a2e70c/gitlab-toolbox/scripts/bin/backup-utility#L19> -->

- `db` (데이터베이스)
- `repositories` (Git 리포지토리 데이터, wikis 포함)
- `uploads` (첨부 파일)
- `artifacts` (CI 작업 아티팩트 및 출력 로그)
- `pages` (Pages 콘텐츠)
- `lfs` (LFS 객체)
- `terraform_state` (Terraform 상태)
- `registry` (컨테이너 레지스트리 이미지)
- `packages` (패키지 레지스트리)
- `ci_secure_files` (프로젝트 수준의 보안 파일)
- `external_diffs` (머지 리퀘스트 diffs)

{{< /tab >}}

{{< /tabs >}}

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup create SKIP=db,uploads
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

charts 백업 문서의 [구성 요소 건너뛰기](https://docs.gitlab.com/charts/backup-restore/backup/#skipping-components)를 참조하세요.

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=db,uploads RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

`SKIP=`도 다음과 같은 용도로 사용됩니다:

- [tar 파일 생성 건너뛰기](#skipping-tar-creation) (`SKIP=tar`).
- [원격 저장소로의 백업 업로드 건너뛰기](#skip-uploading-backups-to-remote-storage) (`SKIP=remote`).

#### tar 생성 건너뛰기 {#skipping-tar-creation}

> [!note]
> [Object Storage](#upload-backups-to-a-remote-cloud-storage) for backups를 사용할 때는 tar 생성을 건너뛸 수 없습니다.

백업을 생성할 때 마지막 부분은 모든 부분을 포함하는 `.tar` 파일을 생성하는 것입니다. 경우에 따라 `.tar` 파일을 생성하는 것이 낭비적이거나 직접적으로 해로울 수 있으므로 `tar`를 `SKIP` 환경 변수에 추가하여 이 단계를 건너뛸 수 있습니다. 예제 사용 사례:

- 백업이 다른 백업 소프트웨어에 의해 선택됩니다.
- 매번 백업을 추출할 필요가 없도록 증분 백업의 속도를 높입니다. (이 경우 `PREVIOUS_BACKUP` 및 `BACKUP`를 지정하지 않아야 합니다. 그렇지 않으면 지정된 백업이 추출되지만 끝에 `.tar` 파일이 생성되지 않습니다.)

`tar`를 `SKIP` 변수에 추가하면 백업을 포함하는 파일 및 디렉터리가 중간 파일에 사용되는 디렉터리에 남아 있습니다. 새 백업이 생성되면 이 파일들이 덮어쓰기되므로 시스템에 한 번에 하나의 백업만 가질 수 있으므로 다른 곳에 복사하는지 확인해야 합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup create SKIP=tar
```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=tar RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### 서버 측 리포지토리 백업 생성 {#create-server-side-repository-backups}

{{< history >}}

- [도입된](https://gitlab.com/gitlab-org/gitaly/-/issues/4941) `gitlab-backup`(GitLab 16.3).
- `gitlab-backup`에 대한 서버 측 지원을 통해 최신 백업 대신 지정된 백업을 복원합니다 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188)(GitLab 16.6).
- 증분 백업을 생성하기 위한 `gitlab-backup`에 서버 측 지원 [도입됨](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475)(GitLab 16.6).
- `backup-utility`에 서버 측 지원 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/438393)(GitLab 17.0).

{{< /history >}}

백업 아카이브에 대규모 리포지토리 백업을 저장하는 대신 각 리포지토리를 호스팅하는 Gitaly 노드가 백업을 생성하고 Object Storage로 스트리밍할 수 있도록 리포지토리 백업을 구성할 수 있습니다. 이는 백업을 생성하고 복원하는 데 필요한 네트워크 리소스를 줄이는 데 도움이 됩니다.

1. [Gitaly에서 서버 측 백업 대상 구성](../gitaly/configure_gitaly.md#configure-server-side-backups).
1. 리포지토리 서버 측 옵션을 사용하여 백업을 생성합니다. 다음 예를 참조하세요.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true
```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_SERVER_SIDE=true
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --repositories-server-side
```

[cron 기반 백업](https://docs.gitlab.com/charts/backup-restore/backup/#cron-based-backup)을 사용하는 경우 추가 인수에 `--repositories-server-side` 플래그를 추가합니다.

{{< /tab >}}

{{< /tabs >}}

#### Git 리포지토리를 동시에 백업 {#back-up-git-repositories-concurrently}

[여러 리포지토리 저장소](../repository_storage_paths.md)를 사용하는 경우 리포지토리를 동시에 백업하거나 복원하여 CPU 시간을 충분히 활용할 수 있습니다. 다음 변수는 Rake 작업의 기본 동작을 수정하는 데 사용 가능합니다:

- `GITLAB_BACKUP_MAX_CONCURRENCY`:  동시에 백업할 최대 프로젝트 수입니다. 논리적 CPU의 수로 기본 설정합니다.
- `GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY`:  각 저장소에서 동시에 백업할 최대 프로젝트 수입니다. 이를 통해 리포지토리 백업을 저장소 전체에 분산할 수 있습니다. `2`로 기본값 설정됩니다.

예를 들어 4개의 리포지토리 저장소 사용:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

```yaml
toolbox:
#...
    extra: {}
    extraEnv:
      GITLAB_BACKUP_MAX_CONCURRENCY: 4
      GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY: 1

```

{{< /tab >}}

{{< /tabs >}}

#### 증분 리포지토리 백업 {#incremental-repository-backups}

{{< history >}}

- 증분 백업을 생성하기 위한 서버 측 지원 [도입됨](https://gitlab.com/gitlab-org/gitaly/-/issues/5461)(GitLab 16.6).

{{< /history >}}

> [!note]
> 증분 백업은 리포지토리만 지원합니다. 따라서 `INCREMENTAL=yes`를 사용하면 작업은 자체 포함된 백업 tar 아카이브를 생성합니다. 이는 리포지토리를 제외한 모든 하위 작업이 여전히 전체 백업을 생성하기 때문입니다(리포지토리 기존 전체 백업을 덮어씁니다). 모든 하위 작업에 대해 증분 백업을 지원하는 기능 요청을 위해 [이슈 19256](https://gitlab.com/gitlab-org/gitlab/-/issues/19256)을 참조하세요.

증분 리포지토리 백업은 전체 리포지토리 백업보다 빠를 수 있습니다. 각 리포지토리의 마지막 백업 이후 변경 사항만 백업 번들로 압축됩니다. `gitlab-backup`로 생성된 백업 아카이브는 원본 전체 백업부터 시작하여 각 리포지토리를 복원하는 데 필요한 모든 단계를 포함하기 때문에 휴대 가능하고 자체 포함됩니다.

증분 백업을 새 GitLab 인스턴스(사전 기존 데이터 없음)로 복원하려면 전체 백업에서 증분 백업을 생성해야 합니다. 기본 백업을 생성할 때 백업 구성 요소를 건너뛰지 마세요.

서버 측 리포지토리 백업을 사용하면 증분 리포지토리 백업 파일이 Object Storage에 별도로 저장됩니다. 각 증분은 원본 전체 백업으로 돌아가는 모든 이전 단계에 따라 달라집니다.

> [!warning]
> Object Storage에서 증분 백업 파일을 삭제하지 마세요. 중간 파일이 삭제된 경우(예: Object Storage 수명 주기 정책을 통해) 백업 체인이 끊어지고 백업을 복원할 수 없습니다.

자세한 내용은 [증분 리포지토리 백업 복원](restore_gitlab.md#restoring-an-incremental-repository-backup)을 참조하세요.

`PREVIOUS_BACKUP=<backup-id>` 옵션을 사용하여 사용할 백업을 선택합니다. 기본적으로 [백업 ID](backup_archive_process.md#backup-id) 섹션에 설명된 대로 백업 파일이 생성됩니다. 파일명의 `<backup-id>` 부분은 [`BACKUP` 환경 변수](#backup-filename)를 설정하여 재정의할 수 있습니다.

증분 백업을 생성하려면 다음을 실행합니다:

```shell
sudo gitlab-backup create INCREMENTAL=yes PREVIOUS_BACKUP=<backup-id>
```

tar된 백업에서 [untarred](#skipping-tar-creation) 증분 백업을 생성하려면 `SKIP=tar`를 사용하세요:

```shell
sudo gitlab-backup create INCREMENTAL=yes SKIP=tar
```

#### 특정 리포지토리 저장소 백업 {#back-up-specific-repository-storages}

{{< history >}}

- [도입된](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86896) GitLab 15.0.

{{< /history >}}

[여러 리포지토리 저장소](../repository_storage_paths.md)를 사용하는 경우 `REPOSITORIES_STORAGES` 옵션을 사용하여 특정 리포지토리 저장소에서 리포지토리를 별도로 백업할 수 있습니다. 옵션은 저장소 이름의 쉼표로 구분된 목록을 허용합니다.

예를 들어:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup create REPOSITORIES_STORAGES=storage1,storage2
```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_STORAGES=storage1,storage2
```

{{< /tab >}}

{{< /tabs >}}

#### 특정 리포지토리 백업 {#back-up-specific-repositories}

{{< history >}}

- [도입된](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88094) GitLab 15.1.
- [건너뛰기 특정 리포지토리 추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121865) GitLab 16.1.

{{< /history >}}

`REPOSITORIES_PATHS` 옵션을 사용하여 특정 리포지토리를 백업할 수 있습니다. 마찬가지로 `SKIP_REPOSITORIES_PATHS`를 사용하여 특정 리포지토리를 건너뛸 수 있습니다. 두 옵션 모두 프로젝트 또는 그룹 경로의 쉼표로 구분된 목록을 허용합니다. 그룹 경로를 지정하면 그룹의 모든 프로젝트 및 하위 그룹의 모든 리포지토리가 사용한 옵션에 따라 포함되거나 건너뜁니다.

예를 들어 그룹 A(`group-a`)의 모든 프로젝트에 대한 모든 리포지토리를 백업하려면 그룹 B(`group-b/project-c`)의 프로젝트 C 리포지토리 및 그룹 A(`group-a/project-d`)의 프로젝트 D 건너뛰기:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup create REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

```shell
REPOSITORIES_PATHS=group-a SKIP_REPOSITORIES_PATHS=group-a/project_a2 backup-utility --skip db,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,ci_secure_files,pages
```

{{< /tab >}}

{{< /tabs >}}

#### 원격(클라우드) 저장소로 백업 업로드 {#upload-backups-to-a-remote-cloud-storage}

> [!note]
> 백업용 Object Storage를 사용할 때는 [tar 생성 건너뛰기](#skipping-tar-creation)를 할 수 없습니다.

백업 스크립트가 생성하는 `.tar` 파일을 원격 저장소로 업로드하도록 할 수 있습니다. 다음 예에서는 Amazon S3을 저장소로 사용하지만 Google Cloud Storage 및 Azure와 같은 다른 클라우드 제공자 또는 로컬 마운트된 공유를 사용할 수도 있습니다.

참고 항목:

- [Fog 라이브러리 문서](https://fog.github.io/)
- [기타 저장소 제공자](https://fog.github.io/storage/)
- [GitLab Object Storage 가이드](../object_storage.md)
- [로컬 마운트된 공유에 업로드](#upload-to-locally-mounted-shares)
- [GitLab에서 Object Storage 사용](../object_storage.md)

##### Amazon S3 사용 {#using-amazon-s3}

Linux 패키지(Omnibus):

1. `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-west-1',
     # Choose one authentication method
     # IAM Profile
     'use_iam_profile' => true
     # OR AWS Access and Secret key
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   # Consider using multipart uploads when file size reaches 100 MB. Enter a number in bytes.
   # gitlab_rails['backup_multipart_chunk_size'] = 104857600
   ```

1. IAM Profile 인증 방법을 사용하는 경우 `backup-utility`이 실행될 인스턴스가 다음 정책을 설정했는지 확인하십시오(`<backups-bucket>`을 올바른 버킷 이름으로 바꾸기):

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject"
               ],
               "Resource": "arn:aws:s3:::<backups-bucket>/*"
           }
       ]
   }
   ```

1. [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation) 변경 사항을 적용합니다

##### S3 암호화 버킷 {#s3-encrypted-buckets}

AWS는 이러한 [서버 측 암호화 모드](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html)를 지원합니다:

- Amazon S3 관리 키(SSE-S3)
- AWS Key Management Service(SSE-KMS)에 저장된 Customer Master Key(CMK)
- Customer-Provided Keys(SSE-C)

GitLab에서 선택한 모드를 사용합니다. 각 모드는 비슷하지만 약간 다른 구성 방법을 가집니다.

###### SSE-S3 {#sse-s3}

SSE-S3을 활성화하려면 백업 저장소 옵션에서 `server_side_encryption` 필드를 `AES256`로 설정합니다. 예를 들어 Linux 패키지(Omnibus):

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'AES256'
}
```

###### SSE-KMS {#sse-kms}

SSE-KMS를 활성화하려면 [`arn:aws:kms:region:acct-id:key/key-id` 형식으로 Amazon Resource Name(ARN) 통해 KMS 키](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html)가 필요합니다. `backup_upload_storage_options` 구성 설정에서 다음을 설정합니다:

- `server_side_encryption`을 `aws:kms`로 변경합니다.
- `server_side_encryption_kms_key_id` 키의 ARN.

예를 들어 Linux 패키지(Omnibus):

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'aws:kms',
  'server_side_encryption_kms_key_id' => 'arn:aws:<YOUR KMS KEY ID>:'
}
```

###### SSE-C {#sse-c}

SSE-C는 다음 암호화 옵션을 설정해야 합니다:

- `backup_encryption`:  AES256\.
- `backup_encryption_key`:  인코딩되지 않은 32바이트(256비트) 키. 정확히 32바이트가 아니면 업로드가 실패합니다.

예를 들어 Linux 패키지(Omnibus):

```ruby
gitlab_rails['backup_encryption'] = 'AES256'
gitlab_rails['backup_encryption_key'] = '<YOUR 32-BYTE KEY HERE>'
```

키에 이진 문자가 포함되어 있고 UTF-8로 인코딩될 수 없는 경우 대신 `GITLAB_BACKUP_ENCRYPTION_KEY` 환경 변수로 키를 지정합니다. 예를 들어:

```ruby
gitlab_rails['env'] = { 'GITLAB_BACKUP_ENCRYPTION_KEY' => "\xDE\xAD\xBE\xEF" * 8 }
```

##### Digital Ocean Spaces {#digital-ocean-spaces}

이 예제는 암스테르담(AMS3)의 버킷에 사용할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'ams3',
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123',
     'endpoint'              => 'https://ams3.digitaloceanspaces.com'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   ```

1. [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation) 변경 사항을 적용합니다

Digital Ocean Spaces를 사용할 때 `400 Bad Request` 오류 메시지가 표시되는 경우 원인은 백업 암호화 사용일 수 있습니다. Digital Ocean Spaces는 암호화를 지원하지 않으므로 `gitlab_rails['backup_encryption']`를 포함하는 줄을 제거하거나 주석 처리합니다.

##### 기타 S3 제공자 {#other-s3-providers}

모든 S3 제공자가 Fog 라이브러리와 완전히 호환되지는 않습니다. 예를 들어 업로드를 시도한 후 `411 Length Required` 오류 메시지가 표시되는 경우 `aws_signature_version` 값을 기본값에서 `2`로 다운그레이드해야 할 수 있습니다([이 이슈로 인해](https://github.com/fog/fog-aws/issues/428)).

자체 컴파일된 설치의 경우:

1. `home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
     backup:
       # snip
       upload:
         # Fog storage connection settings, see https://fog.github.io/storage/ .
         connection:
           provider: AWS
           region: eu-west-1
           aws_access_key_id: AKIAKIAKI
           aws_secret_access_key: 'secret123'
           # If using an IAM Profile, leave aws_access_key_id & aws_secret_access_key empty
           # ie. aws_access_key_id: ''
           # use_iam_profile: 'true'
         # The remote 'directory' to store your backups. For S3, this would be the bucket name.
         remote_directory: 'my.s3.bucket'
         # Specifies Amazon S3 storage class to use for backups, this is optional
         # storage_class: 'STANDARD'
         #
         # Turns on AWS Server-Side Encryption with Amazon Customer-Provided Encryption Keys for backups, this is optional
         #   'encryption' must be set in order for this to have any effect.
         #   'encryption_key' should be set to the 256-bit encryption key for Amazon S3 to use to encrypt or decrypt.
         #   To avoid storing the key on disk, the key can also be specified via the `GITLAB_BACKUP_ENCRYPTION_KEY` your data.
         # encryption: 'AES256'
         # encryption_key: '<key>'
         #
         #
         # Turns on AWS Server-Side Encryption with Amazon S3-Managed keys (optional)
         # https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html
         # For SSE-S3, set 'server_side_encryption' to 'AES256'.
         # For SS3-KMS, set 'server_side_encryption' to 'aws:kms'. Set
         # 'server_side_encryption_kms_key_id' to the ARN of customer master key.
         # storage_options:
         #   server_side_encryption: 'aws:kms'
         #   server_side_encryption_kms_key_id: 'arn:aws:kms:YOUR-KEY-ID-HERE'
   ```

1. [GitLab 재시작](../restart_gitlab.md#self-compiled-installations) 변경 사항을 적용합니다

##### Google Cloud Storage 사용 {#using-google-cloud-storage}

Google Cloud Storage를 사용하여 백업을 저장하려면 먼저 Google 콘솔에서 액세스 키를 생성해야 합니다:

1. [Google 저장소 설정 페이지](https://console.cloud.google.com/storage/settings)로 이동합니다.
1. **Interoperability**를 선택한 다음 액세스 키를 만듭니다.
1. **Access Key** 및 **비밀**을 기록하고 다음 구성에서 바꿉니다.
1. 버킷의 고급 설정에서 **Set object-level and bucket-level permissions** 액세스 제어 옵션을 선택되어 있는지 확인합니다.
1. 아직 버킷을 생성했는지 확인하세요.

Linux 패키지(Omnibus):

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'Google',
     'google_storage_access_key_id' => 'Access Key',
     'google_storage_secret_access_key' => 'Secret',

     ## If you have CNAME buckets (foo.example.com), you might run into SSL issues
     ## when uploading backups ("hostname foo.example.com.storage.googleapis.com
     ## does not match the server certificate"). In that case, uncomment the following
     ## setting. See: https://github.com/fog/fog/issues/2834
     #'path_style' => true
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.google.bucket'
   ```

1. [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation) 변경 사항을 적용합니다

자체 컴파일된 설치의 경우:

1. `home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
     backup:
       upload:
         connection:
           provider: 'Google'
           google_storage_access_key_id: 'Access Key'
           google_storage_secret_access_key: 'Secret'
         remote_directory: 'my.google.bucket'
   ```

1. [GitLab 재시작](../restart_gitlab.md#self-compiled-installations) 변경 사항을 적용합니다

##### Azure Blob Storage 사용 {#using-azure-blob-storage}

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
    'provider' => 'AzureRM',
    'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
    'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
    'azure_storage_domain' => 'blob.core.windows.net', # Optional
   }
   gitlab_rails['backup_upload_remote_directory'] = '<AZURE BLOB CONTAINER>'
   ```

   [관리형 ID](../object_storage.md#azure-workload-and-managed-identities)를 사용하는 경우 `azure_storage_access_key`를 생략합니다:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>' # Optional
   }
   gitlab_rails['backup_upload_remote_directory'] = '<AZURE BLOB CONTAINER>'
   ```

1. [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation) 변경 사항을 적용합니다

{{< /tab >}}

{{< tab title="Self-compiled" >}}

1. `home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
     backup:
       upload:
         connection:
           provider: 'AzureRM'
           azure_storage_account_name: '<AZURE STORAGE ACCOUNT NAME>'
           azure_storage_access_key: '<AZURE STORAGE ACCESS KEY>'
         remote_directory: '<AZURE BLOB CONTAINER>'
   ```

1. [GitLab 재시작](../restart_gitlab.md#self-compiled-installations) 변경 사항을 적용합니다

{{< /tab >}}

{{< /tabs >}}

자세한 내용은 [Azure 매개변수 테이블](../object_storage.md#azure-blob-storage)을 참조하세요.

##### 백업을 위한 사용자 정의 디렉터리 지정 {#specifying-a-custom-directory-for-backups}

이 옵션은 원격 저장소에서만 작동합니다. 백업을 그룹화하려면 `DIRECTORY` 환경 변수를 전달할 수 있습니다:

```shell
sudo gitlab-backup create DIRECTORY=daily
sudo gitlab-backup create DIRECTORY=weekly
```

#### 원격 저장소로의 백업 업로드 건너뛰기 {#skip-uploading-backups-to-remote-storage}

GitLab을 [원격 저장소로의 백업 업로드](#upload-backups-to-a-remote-cloud-storage)로 구성한 경우 `SKIP=remote` 옵션을 사용하여 백업을 원격 저장소에 업로드하는 것을 건너뛸 수 있습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup create SKIP=remote
```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=remote RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### 로컬 마운트된 공유에 업로드 {#upload-to-locally-mounted-shares}

Fog [`Local`](https://github.com/fog/fog-local#usage) 저장소 제공자를 사용하여 로컬 마운트된 공유(예: `NFS`,`CIFS` 또는 `SMB`)로 백업을 보낼 수 있습니다.

이를 수행하려면 다음 구성 키를 설정해야 합니다:

- `backup_upload_connection.local_root`: 백업이 복사되는 마운트된 디렉터리.
- `backup_upload_remote_directory`: `backup_upload_connection.local_root` 디렉터리의 서브 디렉터리. 존재하지 않으면 생성됩니다. tarballs을 마운트된 디렉터리의 루트에 복사하려면 `.`를 사용합니다.

마운트되면 `local_root` 키에 설정된 디렉터리의 소유자는 다음 중 하나여야 합니다:

- `git` 사용자. `uid=`의 `git` 사용자에 대해 `CIFS` 및 `SMB` 마운팅할 수 있습니다.
- 백업 작업을 실행하는 사용자입니다. Linux 패키지(Omnibus)의 경우 `git` 사용자입니다.

파일 시스템 성능이 전체 GitLab 성능에 영향을 미칠 수 있으므로 [클라우드 기반 파일 시스템을 저장소로 사용하지 않는 것이 좋습니다](../nfs.md#avoid-using-cloud-based-file-systems).

##### 충돌하는 구성 방지 {#avoid-conflicting-configuration}

다음 구성 키를 동일한 경로로 설정하지 마세요:

- `gitlab_rails['backup_path']` (Self-compiled 설치의 경우 `backup.path`).
- `gitlab_rails['backup_upload_connection'].local_root` (Self-compiled 설치의 경우 `backup.upload.connection.local_root`).

`backup_path` 구성 키는 백업 파일의 로컬 위치를 설정합니다. `upload` 구성 키는 백업 파일을 별도의 서버(아마도 보관 목적)에 업로드할 때 사용합니다.

이 구성 키가 동일한 위치로 설정되면 업로드 위치에 백업이 이미 있기 때문에 업로드 기능이 실패합니다. 이 실패로 인해 업로드 기능이 백업을 삭제합니다. 백업이 실패한 업로드 시도 후 남은 잔여 파일이라고 가정하기 때문입니다.

##### 로컬 마운트된 공유에 업로드 구성 {#configure-uploads-to-locally-mounted-shares}

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     :provider => 'Local',
     :local_root => '/mnt/backups'
   }

   # The directory inside the mounted folder to copy backups to
   # Use '.' to store them in the root directory
   gitlab_rails['backup_upload_remote_directory'] = 'gitlab_backups'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Self-compiled" >}}

1. `home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   backup:
     upload:
       # Fog storage connection settings, see https://fog.github.io/storage/ .
       connection:
         provider: Local
         local_root: '/mnt/backups'
       # The directory inside the mounted folder to copy backups to
       # Use '.' to store them in the root directory
       remote_directory: 'gitlab_backups'
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

#### 백업 아카이브 권한 {#backup-archive-permissions}

GitLab이 생성하는 백업 아카이브(`1393513186_2014_02_27_gitlab_backup.tar`)는 기본적으로 소유자/그룹 `git`/`git` 및 0600 권한이 있습니다. 이는 다른 시스템 사용자가 GitLab 데이터를 읽는 것을 방지하기 위한 것입니다. 백업 아카이브가 다른 권한을 가져야 하는 경우 `archive_permissions` 설정을 사용할 수 있습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['backup_archive_permissions'] = 0644 # Makes the backup archives world-readable
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Self-compiled" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   backup:
     archive_permissions: 0644 # Makes the backup archives world-readable
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

#### 일일 백업을 위해 cron 구성 {#configuring-cron-to-make-daily-backups}

> [!warning]
> 다음 cron 작업은 GitLab 구성 파일 또는 SSH 호스트 키를 백업하지 않습니다.

**Important:** 또한 백업해야 합니다:

- [GitLab 구성 파일](#storing-configuration-files)
- [SSH 호스트 키](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)

리포지토리 및 GitLab 메타데이터를 백업하는 cron 작업을 예약할 수 있습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `root` 사용자의 crontab을 편집합니다:

   ```shell
   sudo su -
   crontab -e
   ```

1. 그곳에서 매일 오전 2시에 백업을 예약하기 위해 다음 줄을 추가합니다:

   ```plaintext
   0 2 * * * /opt/gitlab/bin/gitlab-backup create CRON=1
   ```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

1. `git` 사용자의 crontab을 편집합니다:

   ```shell
   sudo -u git crontab -e
   ```

1. 맨 아래에 다음 줄을 추가합니다:

   ```plaintext
   # Create a full backup of the GitLab repositories and SQL database every day at 2am
   0 2 * * * cd /home/git/gitlab && PATH=/usr/local/bin:/usr/bin:/bin bundle exec rake gitlab:backup:create RAILS_ENV=production CRON=1
   ```

{{< /tab >}}

{{< /tabs >}}

`CRON=1` 환경 변수는 백업 스크립트에 오류가 없으면 모든 진행률 출력을 숨기도록 지시합니다. cron 스팸을 줄이기 위해 권장됩니다. 그러나 백업 문제를 해결할 때 `CRON=1`를 `--trace`로 바꾸어 자세히 기록합니다.

#### 로컬 파일의 백업 수명 제한(오래된 백업 정리) {#limit-backup-lifetime-for-local-files-prune-old-backups}

> [!warning]
> 이 섹션에 설명된 프로세스는 백업에 사용자 지정 파일 이름을 사용한 경우 작동하지 않습니다.

정기적인 백업이 디스크 공간을 모두 사용하지 않도록 하려면 백업의 수명을 제한하려고 할 수 있습니다. 다음에 백업 작업이 실행될 때 `backup_keep_time`보다 오래된 백업이 정리됩니다.

이 구성 옵션은 로컬 파일만 관리합니다. GitLab은 사용자가 파일을 나열하고 삭제할 권한이 없을 수 있으므로 타사 객체 스토리지에 저장된 오래된 파일을 정리하지 않습니다. 객체 스토리지에 대해 적절한 보관 정책을 구성하는 것이 좋습니다.

참고 항목:

- [사용자 지정 파일 이름 구성](#backup-filename)
- [원격 클라우드 스토리지에 백업 업로드](#upload-backups-to-a-remote-cloud-storage)
- [AWS S3 수명 주기 정책](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-lifecycle.html)

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Self-compiled" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   backup:
     ## Limit backup lifetime to 7 days - 604800 seconds
     keep_time: 604800
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations)을 수행하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

#### PgBouncer를 사용하는 설치에 대한 백업 및 복원 {#back-up-and-restore-for-installations-using-pgbouncer}

PgBouncer 연결을 통해 GitLab을 백업하거나 복원하지 마세요. 이 작업은 [PgBouncer를 우회하고 PostgreSQL 주 데이터베이스 노드에 직접 연결](#bypassing-pgbouncer)해야 합니다. 그렇지 않으면 GitLab 중단이 발생합니다.

PgBouncer에서 GitLab 백업 또는 복원 작업을 사용할 때 다음 오류 메시지가 표시됩니다:

```ruby
ActiveRecord::StatementInvalid: PG::UndefinedTable
```

GitLab 백업이 실행될 때마다 GitLab은 500 오류를 생성하기 시작하며 누락된 테이블에 대한 오류가 [PostgreSQL에 의해 기록](../logs/_index.md#postgresql-logs)됩니다:

```plaintext
ERROR: relation "tablename" does not exist at character 123
```

이는 작업이 `pg_dump`를 사용하기 때문입니다. 이는 null 검색 경로를 설정하고 CVE-2018-1058을 해결하기 위해 모든 SQL 쿼리에 스키마를 명시적으로 포함합니다.

PgBouncer에서 트랜잭션 풀링 모드의 연결을 재사용하므로 PostgreSQL은 기본 `public` 스키마를 검색하지 못합니다. 결과적으로 이 검색 경로 지우기로 인해 테이블과 열이 누락된 것처럼 나타납니다.

기술 참조:

- [스키마 처리 구현](https://gitlab.com/gitlab-org/gitlab/-/issues/23211)
- [CVE-2018-1058 세부사항](https://www.postgresql.org/about/news/postgresql-103-968-9512-9417-and-9322-released-1834/)

##### PgBouncer 우회 {#bypassing-pgbouncer}

이 문제를 해결하는 두 가지 방법이 있습니다:

1. [환경 변수를 사용하여 데이터베이스 설정 재정의](#environment-variable-overrides)를 백업 작업에 사용합니다.
1. 노드를 재구성하여 [PostgreSQL 주 데이터베이스 노드에 직접 연결](../postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)합니다.

###### 환경 변수 재정의 {#environment-variable-overrides}

{{< history >}}

- 다중 데이터베이스 지원이 GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133177)되었습니다.

{{< /history >}}

기본적으로 GitLab은 구성 파일(`database.yml`)에 저장된 데이터베이스 구성을 사용합니다. 그러나 `GITLAB_BACKUP_`로 접두어가 붙은 환경 변수를 설정하여 백업 및 복원 작업의 데이터베이스 설정을 재정의할 수 있습니다:

- `GITLAB_BACKUP_PGHOST`
- `GITLAB_BACKUP_PGUSER`
- `GITLAB_BACKUP_PGPORT`
- `GITLAB_BACKUP_PGPASSWORD`
- `GITLAB_BACKUP_PGSSLMODE`
- `GITLAB_BACKUP_PGSSLKEY`
- `GITLAB_BACKUP_PGSSLCERT`
- `GITLAB_BACKUP_PGSSLROOTCERT`
- `GITLAB_BACKUP_PGSSLCRL`
- `GITLAB_BACKUP_PGSSLCOMPRESSION`

예를 들어 Linux 패키지(Omnibus)에서 데이터베이스 호스트 및 포트를 192.168.1.10 및 포트 5432로 재정의하려면:

```shell
sudo GITLAB_BACKUP_PGHOST=192.168.1.10 GITLAB_BACKUP_PGPORT=5432 /opt/gitlab/bin/gitlab-backup create
```

GitLab을 [다중 데이터베이스](../postgresql/_index.md)에서 실행하는 경우 환경 변수에 데이터베이스 이름을 포함하여 데이터베이스 설정을 재정의할 수 있습니다. 예를 들어 `main` 및 `ci` 데이터베이스가 다른 데이터베이스 서버에서 호스팅되는 경우 `GITLAB_BACKUP_` 접두어 뒤에 이름을 추가하고 `PG*` 이름은 그대로 둡니다:

```shell
sudo GITLAB_BACKUP_MAIN_PGHOST=192.168.1.10 GITLAB_BACKUP_CI_PGHOST=192.168.1.12 /opt/gitlab/bin/gitlab-backup create
```

[PostgreSQL 설명서](https://www.postgresql.org/docs/16/libpq-envars.html)에서 이러한 매개변수가 수행하는 작업에 대한 자세한 내용을 참조하세요.

#### `gitaly-backup` - 리포지토리 백업 및 복원 {#gitaly-backup-for-repository-backup-and-restore}

`gitaly-backup` 바이너리는 백업 Rake 작업에서 Gitaly의 리포지토리 백업을 생성하고 복원하는 데 사용됩니다. `gitaly-backup`는 GitLab에서 Gitaly에 대해 직접 RPC를 호출하는 이전 백업 방법을 대체합니다.

백업 Rake 작업은 이 실행 파일을 찾을 수 있어야 합니다. 대부분의 경우 기본 경로 `/opt/gitlab/embedded/bin/gitaly-backup`에서 제대로 작동하므로 바이너리의 경로를 변경할 필요가 없습니다. 경로를 변경할 특정한 이유가 있는 경우 Linux 패키지(Omnibus)에서 구성할 수 있습니다:

1. `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   ```ruby
   gitlab_rails['backup_gitaly_backup_path'] = '/path/to/gitaly-backup'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

## 대체 백업 전략 {#alternative-backup-strategies}

모든 배포에 다양한 기능이 있을 수 있으므로 먼저 백업해야 할 데이터를 검토하여 활용할 수 있는 방법을 더 잘 이해해야 합니다.

예를 들어 Amazon RDS를 사용하는 경우 GitLab PostgreSQL 데이터를 처리하기 위해 기본 제공 백업 및 복원 기능을 사용하고 백업 명령을 사용할 때 PostgreSQL 데이터를 제외하도록 선택할 수 있습니다.

참고 항목:

- [어떤 데이터를 백업해야 하는가](#what-data-needs-to-be-backed-up)
- [PostgreSQL 데이터베이스](#postgresql-databases)
- [백업에서 특정 데이터 제외](#excluding-specific-data-from-the-backup)
- [백업 명령](#backup-command)

다음의 경우 백업 전략의 일부로 파일 시스템 데이터 전송 또는 스냅샷 사용을 고려합니다:

- GitLab 인스턴스에 많은 Git 리포지토리 데이터가 포함되어 있고 GitLab 백업 스크립트가 너무 느립니다.
- GitLab 인스턴스에 많은 포크 프로젝트가 있고 일반 백업 작업이 모두에 대해 Git 데이터를 복제합니다.
- GitLab 인스턴스에 문제가 있으며 일반 백업 및 가져오기 Rake 작업을 사용할 수 없습니다.

> [!warning]
> Gitaly Cluster(Praefect) [는 스냅샷 백업을 지원하지 않습니다](../gitaly/praefect/_index.md#snapshot-backup-and-recovery).

파일 시스템 데이터 전송 또는 스냅샷 사용을 고려할 때:

- 한 운영 체제에서 다른 운영 체제로 마이그레이션하기 위해 이 방법들을 사용하지 마세요. 소스 및 대상의 운영 체제는 가능한 한 유사해야 합니다. 예를 들어 이러한 방법을 사용하여 Ubuntu에서 RHEL로 마이그레이션하지 마세요.
- 데이터 일관성은 매우 중요합니다. 파일 시스템 전송(예: `rsync`)을 수행하거나 스냅샷을 만들기 전에 GitLab(`sudo gitlab-ctl stop`)을 중지해야 메모리의 모든 데이터가 디스크에 플러시됩니다. GitLab은 고유한 버퍼, 큐 및 스토리지 레이어가 있는 여러 하위 시스템(Gitaly, 데이터베이스, 파일 스토리지)으로 구성됩니다. GitLab 트랜잭션은 이러한 하위 시스템에 걸쳐 있을 수 있으므로 트랜잭션의 일부가 디스크에 다른 경로로 이동합니다. 라이브 시스템에서 파일 시스템 전송 및 스냅샷 실행은 메모리에 여전히 있는 트랜잭션의 일부를 캡처하지 못합니다.

예시:  Amazon Elastic Block Store(EBS)

- Amazon AWS에서 호스팅되는 Linux 패키지(Omnibus)를 사용하는 GitLab 서버입니다.
- ext4 파일 시스템이 포함된 EBS 드라이브가 `/var/opt/gitlab`에 마운트됩니다.
- 이 경우 EBS 스냅샷을 만들어 애플리케이션 백업을 수행할 수 있습니다.
- 백업에는 모든 리포지토리, 업로드 및 PostgreSQL 데이터가 포함됩니다.

예시:  Logical Volume Manager(LVM) 스냅샷 + rsync

- Linux 패키지(Omnibus)를 사용하는 GitLab 서버이며 LVM 논리 볼륨이 `/var/opt/gitlab`에 마운트됩니다.
- rsync를 사용하여 `/var/opt/gitlab` 디렉토리를 복제하는 것은 rsync가 실행되는 동안 너무 많은 파일이 변경되므로 안정적이지 않습니다.
- `/var/opt/gitlab`을(를) rsync하는 대신 임시 LVM 스냅샷을 만들어 `/mnt/gitlab_backup`에서 읽기 전용 파일 시스템으로 마운트합니다.
- 이제 원격 서버에 일관된 복제본을 만드는 더 오래 실행되는 rsync 작업을 수행할 수 있습니다.
- 복제본에는 모든 리포지토리, 업로드 및 PostgreSQL 데이터가 포함됩니다.

가상화된 서버에서 GitLab을 실행하는 경우 전체 GitLab 서버의 VM 스냅샷을 만들 수도 있습니다. 그러나 VM 스냅샷을 만들려면 서버를 종료해야 하는 경우가 드물지 않으므로 이 솔루션의 실용적인 사용을 제한합니다.

### 리포지토리 데이터 별도로 백업 {#back-up-repository-data-separately}

먼저 [리포지토리를 건너뛰면서](#excluding-specific-data-from-the-backup) 기존 GitLab 데이터를 백업했는지 확인합니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup create SKIP=repositories
```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=repositories RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

디스크의 Git 리포지토리 데이터를 수동으로 백업하기 위해 여러 가지 전략이 있습니다:

- Amazon EBS 드라이브 스냅샷 또는 LVM 스냅샷 + rsync의 이전 예시와 같은 스냅샷을 사용합니다.
- [GitLab Geo](../geo/_index.md)를 사용하고 Geo 보조 사이트의 리포지토리 데이터를 사용합니다.
- [쓰기를 방지하고 Git 리포지토리 데이터를 복사](#prevent-writes-and-copy-the-git-repository-data)합니다.
- [리포지토리를 읽기 전용으로 표시하여 온라인 백업 만들기(실험적)](#online-backup-through-marking-repositories-as-read-only-experimental).

#### 쓰기를 방지하고 Git 리포지토리 데이터를 복사 {#prevent-writes-and-copy-the-git-repository-data}

Git 리포지토리는 일관된 방식으로 복사되어야 합니다. 리포지토리를 동시 쓰기 작업 중에 복사하면 불일치 또는 손상 이슈가 발생할 수 있습니다. 이는 리포지토리 손상, 누락된 커밋 또는 불완전한 백업 데이터로 이어질 수 있습니다.

Git 리포지토리 데이터에 대한 쓰기를 방지하기 위해 두 가지 가능한 방법이 있습니다:

- [유지보수 모드](../maintenance_mode/_index.md)를 사용하여 GitLab을 읽기 전용 상태로 전환합니다.
- 리포지토리를 백업하기 전에 모든 Gitaly 서비스를 중지하여 명시적 가동 중지 시간을 만듭니다:

  ```shell
  sudo gitlab-ctl stop gitaly
  # execute git data copy step
  sudo gitlab-ctl start gitaly
  ```

쓰기가 복사되는 데이터에서 방지되는 한(불일치 및 손상 이슈를 방지하기 위해) 모든 방법을 사용하여 Git 리포지토리 데이터를 복사할 수 있습니다. 선호도 및 안전의 순서로 권장되는 방법은 다음과 같습니다:

1. `rsync`을(를) 아카이브 모드, 삭제 및 체크섬 옵션과 함께 사용합니다. 예를 들어:

   ```shell
   rsync -aR --delete --checksum source destination # be extra safe with the order as it will delete existing data if inverted
   ```

1. [`tar` 파이프를 사용하여 전체 리포지토리 디렉토리를 다른 서버 또는 위치로 복사](../operations/moving_repositories.md#use-a-tar-pipe-to-another-server)합니다.
1. `sftp`, `scp`, `cp` 또는 다른 복사 방법을 사용합니다.

#### 리포지토리를 읽기 전용으로 표시하여 온라인 백업(실험적) {#online-backup-through-marking-repositories-as-read-only-experimental}

인스턴스 전체 가동 중지 없이 리포지토리를 백업하는 한 가지 방법은 기본 데이터를 복사하면서 프로젝트를 읽기 전용으로 프로그래밍 방식으로 표시하는 것입니다.

이에 대한 몇 가지 가능한 단점이 있습니다:

- 리포지토리는 리포지토리 크기에 따라 확장되는 기간 동안 읽기 전용입니다.
- 각 프로젝트를 읽기 전용으로 표시하여 백업을 완료하는 데 더 오래 걸리므로 잠재적으로 불일치가 발생할 수 있습니다. 예를 들어 백업된 첫 번째 프로젝트에서 사용 가능한 마지막 데이터와 백업된 마지막 프로젝트 사이의 가능한 날짜 불일치입니다.
- 풀 리포지토리에 대한 잠재적 변경을 방지하기 위해 포크 네트워크는 내부 프로젝트가 백업되는 동안 완전히 읽기 전용이어야 합니다.

이 프로세스를 자동화하려고 시도하는 실험적 스크립트가 [Geo 팀 Runbooks 프로젝트](https://gitlab.com/gitlab-org/geo-team/runbooks/-/tree/main/experimental-online-backup-through-rsync)에 있습니다.
