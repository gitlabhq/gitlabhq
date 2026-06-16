---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 업로드 마이그레이션 Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다양한 스토리지 유형 간에 업로드를 마이그레이션하기 위한 Rake 작업이 있습니다.

- [`gitlab:uploads:migrate:all`](#all-in-one-rake-task)를 사용하여 모든 업로드를 마이그레이션하거나
- 특정 업로드 유형만 마이그레이션하려면 [`gitlab:uploads:migrate`](#individual-rake-tasks)를 사용합니다.

## 객체 스토리지로 마이그레이션 {#migrate-to-object-storage}

GitLab으로의 업로드를 위해 [객체 스토리지를 구성한](../../uploads.md#using-object-storage) 후, 이 작업을 사용하여 로컬 스토리지에서 원격 스토리지로 기존 업로드를 마이그레이션합니다.

모든 처리는 백그라운드 워커에서 수행되며 **no downtime**.

[GitLab에서 객체 스토리지 사용](../../object_storage.md)에 대해 자세히 알아봅니다.

### 올인원 Rake 작업 {#all-in-one-rake-task}

GitLab은 업로드된 모든 파일(예: 아바타, 로고, 첨부 파일 및 파비콘)을 한 단계에서 객체 스토리지로 마이그레이션하는 래퍼 Rake 작업을 제공합니다. 래퍼 작업은 개별 Rake 작업을 호출하여 이러한 각 범주에 해당하는 파일을 하나씩 마이그레이션합니다.

이러한 [개별 Rake 작업](#individual-rake-tasks)은 다음 섹션에서 설명합니다.

로컬 스토리지에서 객체 스토리지로 모든 업로드를 마이그레이션하려면 다음을 실행합니다:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
gitlab-rake "gitlab:uploads:migrate:all"
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate:all
```

{{< /tab >}}

{{< /tabs >}}

선택적으로 [PostgreSQL 콘솔](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database)을 사용하여 진행 상황을 추적하고 모든 업로드가 성공적으로 마이그레이션되었는지 확인할 수 있습니다:

- Linux 패키지 설치의 경우 `sudo gitlab-rails dbconsole --database main`입니다.
- 자체 컴파일 설치의 경우 `sudo -u git -H psql -d gitlabhq_production`입니다.

아래의 `objectstg`(여기서 `store=2`)를 확인하여 모든 아티팩트의 개수를 확인합니다:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when store = '1' then 1 else 0 end) AS filesystem, sum(case when store = '2' then 1 else 0 end) AS objectstg FROM uploads;

total | filesystem | objectstg
------+------------+-----------
   2409 |          0 |      2409
```

`uploads` 폴더의 디스크에 파일이 없는지 확인합니다:

```shell
sudo find /var/opt/gitlab/gitlab-rails/uploads -type f | grep -v tmp | wc -l
```

### 개별 Rake 작업 {#individual-rake-tasks}

이미 [올인원 Rake 작업](#all-in-one-rake-task)을 실행했다면, 이러한 개별 작업을 실행할 필요가 없습니다.

Rake 작업은 마이그레이션할 업로드를 찾기 위해 3개의 매개 변수를 사용합니다:

| 매개 변수        | 유형          | 설명                                            |
|:-----------------|:--------------|:-------------------------------------------------------|
| `uploader_class` | 문자열        | 마이그레이션할 업로더의 유형입니다.                  |
| `model_class`    | 문자열        | 마이그레이션할 모델의 유형입니다.                     |
| `mount_point`    | 문자열/심볼 | 업로더가 마운트된 모델 열의 이름입니다. |

> [!note]
> 이러한 매개 변수는 주로 GitLab의 구조에 내부적이며, 대신 아래의 작업 목록을 참조하고 싶을 수 있습니다. 이러한 개별 작업을 실행한 후, [올인원 Rake 작업](#all-in-one-rake-task)을 실행하여 나열된 유형에 포함되지 않은 업로드를 마이그레이션하는 것을 권장합니다.

이 작업은 기본 배치 크기를 재정의하는 데 사용할 수 있는 환경 변수도 허용합니다:

| 변수 | 유형    | 설명                                       |
|:---------|:--------|:--------------------------------------------------|
| `BATCH`  | 정수 | 배치의 크기를 지정합니다. 기본값은 200입니다. |

다음은 `gitlab:uploads:migrate`을 개별 업로드 유형에 대해 실행하는 방법을 보여줍니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
# gitlab-rake gitlab:uploads:migrate[uploader_class, model_class, mount_point]

# Avatars
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
gitlab-rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

# Attachments
gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
gitlab-rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

# Favicon
gitlab-rake "gitlab:uploads:migrate[FaviconUploader, Appearance, :favicon]"

# Markdown
gitlab-rake "gitlab:uploads:migrate[FileUploader, Project]"
gitlab-rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
gitlab-rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
gitlab-rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"

# Design Management design thumbnails
gitlab-rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action, :image_v432x230]"
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

모든 작업에 `RAILS_ENV=production`을 사용합니다.

```shell
# sudo -u git -H bundle exec rake gitlab:uploads:migrate

# Avatars
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Project, :avatar]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, Group, :avatar]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AvatarUploader, User, :avatar]"

# Attachments
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :logo]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[AttachmentUploader, Appearance, :header_logo]"

# Favicon
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FaviconUploader, Appearance, :favicon]"

# Markdown
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, Project]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[PersonalFileUploader, Snippet]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[NamespaceFileUploader, Snippet]"
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[FileUploader, MergeRequest]"

# Design Management design thumbnails
sudo -u git -H bundle exec rake "gitlab:uploads:migrate[DesignManagement::DesignV432x230Uploader, DesignManagement::Action]"
```

{{< /tab >}}

{{< /tabs >}}

## 로컬 스토리지로 마이그레이션 {#migrate-to-local-storage}

어떤 이유로든 [객체 스토리지](../../object_storage.md)를 비활성화해야 하는 경우, 먼저 객체 스토리지에서 데이터를 마이그레이션한 후 로컬 스토리지로 다시 마이그레이션해야 합니다.

> [!warning]
> **Extended downtime is required**하므로 마이그레이션 중에 객체 스토리지에서 새 파일이 생성되지 않습니다. 객체 스토리지에서 로컬 파일로 마이그레이션할 때 구성 변경을 위한 짧은 다운타임만 있으면 되는 구성 설정은 [이 문제](https://gitlab.com/gitlab-org/gitlab/-/issues/30979)에서 추적됩니다.
>
> **Additionally,** Cloud Native GitLab에서는 로컬 스토리지가 임시적이고 모든 GitLab Rails 애플리케이션 컨테이너에서 공유되지 않기 때문에 로컬 스토리지로 데이터를 마이그레이션하는 것이 일반적으로 안전하지 않습니다.

### 올인원 Rake 작업 {#all-in-one-rake-task-1}

GitLab은 업로드된 모든 파일(예: 아바타, 로고, 첨부 파일 및 파비콘)을 한 단계에서 로컬 스토리지로 마이그레이션하는 래퍼 Rake 작업을 제공합니다. 래퍼 작업은 개별 Rake 작업을 호출하여 이러한 각 범주에 해당하는 파일을 하나씩 마이그레이션합니다.

이러한 Rake 작업에 대한 자세한 내용은 [개별 Rake 작업](#individual-rake-tasks)을 참조합니다. 이 경우 작업 이름은 `gitlab:uploads:migrate_to_local`입니다.

객체 스토리지에서 로컬 스토리지로 업로드를 마이그레이션하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
gitlab-rake "gitlab:uploads:migrate_to_local:all"
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:migrate_to_local:all
```

{{< /tab >}}

{{< /tabs >}}

Rake 작업을 실행한 후, [객체 스토리지 구성](../../uploads.md#using-object-storage)의 지침에 설명된 변경 사항을 취소하여 객체 스토리지를 비활성화할 수 있습니다.
