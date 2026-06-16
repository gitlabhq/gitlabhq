---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Rake 작업 정리
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 GitLab 인스턴스를 정리하기 위한 Rake 작업을 제공합니다.

## 참조되지 않은 LFS 파일 제거 {#remove-unreferenced-lfs-files}

> [!warning]
> GitLab 업그레이드 후 12시간 이내에 이 작업을 실행하지 마세요. 이는 모든 백그라운드 마이그레이션이 완료되도록 하기 위함이며, 그렇지 않으면 데이터 손실이 발생할 수 있습니다.

리포지토리의 기록에서 LFS 파일을 제거하면 고아 파일이 되어 계속 디스크 공간을 차지합니다. 이 Rake 작업을 사용하면 데이터베이스에서 잘못된 참조를 제거하여 LFS 파일의 가비지 수집을 허용할 수 있습니다. 예를 들어:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:orphan_lfs_file_references PROJECT_PATH="gitlab-org/gitlab-foss"
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
bundle exec rake gitlab:cleanup:orphan_lfs_file_references RAILS_ENV=production PROJECT_PATH="gitlab-org/gitlab-foss"
```

{{< /tab >}}

{{< /tabs >}}

`PROJECT_ID` 대신 `PROJECT_PATH`를 사용하여 프로젝트를 지정할 수도 있습니다.

예를 들어:

```shell
$ sudo gitlab-rake gitlab:cleanup:orphan_lfs_file_references PROJECT_ID="13083"

I, [2019-12-13T16:35:31.764962 #82356]  INFO -- :  Looking for orphan LFS files for project GitLab Org / GitLab Foss
I, [2019-12-13T16:35:31.923659 #82356]  INFO -- :  Removed invalid references: 12
```

기본적으로 이 작업은 아무것도 삭제하지 않고 삭제할 수 있는 파일 참조의 개수만 표시합니다. 실제로 참조를 삭제하려면 `DRY_RUN=false`를 사용하여 명령을 실행하세요. `LIMIT={number}` 매개변수를 사용하여 삭제된 참조의 개수를 제한할 수도 있습니다.

이 Rake 작업은 LFS 파일에 대한 참조만 제거합니다. 참조되지 않은 LFS 파일은 나중에 가비지 수집됩니다(하루에 한 번). 즉시 가비지 수집이 필요한 경우 아래에서 설명한 `rake gitlab:cleanup:orphan_lfs_files`를 실행하세요.

### 참조되지 않은 LFS 파일을 즉시 제거 {#remove-unreferenced-lfs-files-immediately}

참조되지 않은 LFS 파일은 매일 제거되지만 필요한 경우 즉시 제거할 수 있습니다. 참조되지 않은 LFS 파일을 즉시 제거하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:orphan_lfs_files
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
bundle exec rake gitlab:cleanup:orphan_lfs_files
```

{{< /tab >}}

{{< /tabs >}}

출력 예:

```shell
$ sudo gitlab-rake gitlab:cleanup:orphan_lfs_files
I, [2020-01-08T20:51:17.148765 #43765]  INFO -- : Removed unreferenced LFS files: 12
```

## 프로젝트 업로드 파일 정리 {#clean-up-project-upload-files}

GitLab 데이터베이스에 존재하지 않는 프로젝트 업로드 파일을 정리합니다.

### 파일 시스템에서 프로젝트 업로드 파일 정리 {#clean-up-project-upload-files-from-file-system}

GitLab 데이터베이스에 존재하지 않는 로컬 프로젝트 업로드 파일을 정리합니다. 이 작업은 파일을 찾을 수 있는 경우 수정을 시도하고, 그렇지 않으면 파일을 분실 디렉토리로 이동합니다. 파일 시스템에서 프로젝트 업로드 파일을 정리하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:project_uploads
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
bundle exec rake gitlab:cleanup:project_uploads RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

출력 예:

```shell
$ sudo gitlab-rake gitlab:cleanup:project_uploads

I, [2018-07-27T12:08:27.671559 #89817]  INFO -- : Looking for orphaned project uploads to clean up. Dry run...
D, [2018-07-27T12:08:28.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:28.689869 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:28.755624 #89817]  INFO -- : Can fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:28.760257 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
I, [2018-07-27T12:08:28.764470 #89817]  INFO -- : To cleanup these files run this command with DRY_RUN=false

$ sudo gitlab-rake gitlab:cleanup:project_uploads DRY_RUN=false
I, [2018-07-27T12:08:32.944414 #89936]  INFO -- : Looking for orphaned project uploads to clean up...
D, [2018-07-27T12:08:33.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:33.689869 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:33.755624 #89817]  INFO -- : Did fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:33.760257 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
```

객체 스토리지를 사용하는 경우 [올인원 Rake 작업](uploads/migrate.md#all-in-one-rake-task)을 실행하여 모든 업로드가 객체 스토리지로 마이그레이션되었는지 확인하고 업로드 폴더의 디스크에 파일이 없는지 확인합니다.

### 객체 스토리지에서 프로젝트 업로드 파일 정리 {#clean-up-project-upload-files-from-object-storage}

GitLab 데이터베이스에 존재하지 않는 경우 객체 스토어 업로드 파일을 분실 디렉토리로 이동합니다. 객체 스토리지에서 프로젝트 업로드 파일을 정리하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:remote_upload_files
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

출력 예:

```shell
$ sudo gitlab-rake gitlab:cleanup:remote_upload_files

I, [2018-08-02T10:26:13.995978 #45011]  INFO -- : Looking for orphaned remote uploads to remove. Dry run...
I, [2018-08-02T10:26:14.120400 #45011]  INFO -- : Can be moved to lost and found: @hashed/6b/DSC_6152.JPG
I, [2018-08-02T10:26:14.120482 #45011]  INFO -- : Can be moved to lost and found: @hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg
I, [2018-08-02T10:26:14.120634 #45011]  INFO -- : To cleanup these files run this command with DRY_RUN=false
```

```shell
$ sudo gitlab-rake gitlab:cleanup:remote_upload_files DRY_RUN=false

I, [2018-08-02T10:26:47.598424 #45087]  INFO -- : Looking for orphaned remote uploads to remove...
I, [2018-08-02T10:26:47.753131 #45087]  INFO -- : Moved to lost and found: @hashed/6b/DSC_6152.JPG -> lost_and_found/@hashed/6b/DSC_6152.JPG
I, [2018-08-02T10:26:47.764356 #45087]  INFO -- : Moved to lost and found: @hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg -> lost_and_found/@hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg
```

## 고아 아티팩트 파일 제거 {#remove-orphan-artifact-files}

> [!note]
> 이러한 명령은 [객체 스토리지](../object_storage.md)에 저장된 작업 아티팩트에 대해 작동하지 않습니다.

디스크에 예상보다 많은 작업 아티팩트 파일 및/또는 디렉토리가 있는 것을 발견하면 다음을 실행할 수 있습니다:

```shell
sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files
```

이 명령:

- 전체 아티팩트 폴더를 스캔합니다.
- 데이터베이스에 기록이 있는 파일을 확인합니다.
- 데이터베이스 기록을 찾을 수 없으면 파일 및 디렉토리가 디스크에서 삭제됩니다.

기본적으로 이 작업은 아무것도 삭제하지 않고 삭제할 수 있는 것만 표시합니다. 실제로 파일을 삭제하려면 `DRY_RUN=false`를 사용하여 명령을 실행하세요:

```shell
sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files DRY_RUN=false
```

`LIMIT`를 사용하여 삭제할 파일 개수를 제한할 수도 있습니다(기본값 `100`):

```shell
sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files LIMIT=100
```

이는 디스크에서 최대 100개의 파일만 삭제합니다. 이를 사용하여 테스트 목적으로 작은 집합을 삭제할 수 있습니다.

`DEBUG=1`를 제공하면 고아로 감지되는 모든 파일의 전체 경로가 표시됩니다.

`ionice`이 설치되어 있으면 이 작업은 이를 사용하여 명령이 디스크에 너무 많은 부하를 주지 않도록 합니다. `NICENESS`를 사용하여 친절함 수준을 구성할 수 있습니다. 아래는 유효한 수준이지만 확인하려면 `man 1 ionice`를 참조하세요.

- `0` 또는 `None`
- `1` 또는 `Realtime`
- `2` 또는 `Best-effort`(기본값)
- `3` 또는 `Idle`

## 만료된 ActiveSession 조회 키 제거 {#remove-expired-activesession-lookup-keys}

만료된 ActiveSession 조회 키를 제거하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:sessions:active_sessions_lookup_keys
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
bundle exec rake gitlab:cleanup:sessions:active_sessions_lookup_keys RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## 컨테이너 레지스트리 가비지 수집 {#container-registry-garbage-collection}

컨테이너 레지스트리는 상당한 양의 디스크 공간을 사용할 수 있습니다. 사용되지 않는 레이어를 정리하려면 레지스트리에는 [가비지 수집 명령](../packages/container_registry.md#container-registry-garbage-collection)이 포함됩니다.
