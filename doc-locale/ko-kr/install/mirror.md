---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Linux 패키지 리포지토리 미러링
title: Linux 패키지 리포지토리 미러링
---

GitLab과 러너 Linux 패키지는 <https://packages.gitlab.com>에서 사용 가능합니다. 이 문서에서는 이러한 리포지토리의 로컬 미러를 유지하는 방법을 설명합니다.

## APT 리포지토리 미러링 {#mirroring-apt-repositories}

`apt` 리포지토리의 로컬 미러는 `apt-mirror` 도구를 사용하여 생성할 수 있습니다.

1. `apt-mirror` 설치

   ```shell
   sudo apt install apt-mirror
   ```

1. 미러를 위한 디렉터리 생성

   ```shell
   sudo mkdir /srv/gitlab-repo-mirror
   ```

1. `apt-mirror` 설정 파일(위치: `/etc/apt/mirror.list`)에 다음 줄을 추가합니다.

   ```shell
   set base_path /srv/gitlab-repo-mirror
   ```

   미러링된 콘텐츠는 `/srv/gitlab-repo-mirror/mirror/packages.gitlab.com`에 작성됩니다.

   다른 사용 가능한 설정은 [업스트림 예제 구성 파일](https://github.com/apt-mirror/apt-mirror/blob/master/mirror.list)을 확인하세요.

1. 설정 파일의 끝에서 `apt` 소스 파일 URL 형식으로 미러링할 리포지토리를 지정합니다.

   > [!note]
   > 리포지토리 구조는 GitLab과 러너 간에 다릅니다.
   >
   > ### GitLab {#gitlab}
   >
   > GitLab은 OS 배포판 간에 패키지에 대해 동일한 버전 문자열을 사용합니다(내용은 다름). 이는 이러한 패키지가 [Debian 리포지토리 형식에 따른 중복 패키지](https://wiki.debian.org/DebianRepository/Format#Duplicate_Packages)로 간주된다는 의미입니다.
   >
   > 이를 해결하기 위해 각 OS 배포판(예: Debian Trixie 또는 Ubuntu Focal)은 해당 배포판만 호스팅하는 전용 리포지토리를 가집니다. 이로 인해 URL에 추가 배포판 구성 요소가 포함됩니다.
   >
   > ### 러너 {#gitlab-runner}
   >
   > 러너는 정적으로 링크된 Go 바이너리이며 다양한 OS 배포판에 대해 동일한 패키지를 사용합니다. OS당 단일 apt 리포지토리를 사용하며 해당 리포지토리 내에서 해당 OS의 모든 배포판을 호스팅합니다.

   {{< tabs >}}

   {{< tab title="GitLab" >}}

   ```plaintext
   deb https://packages.gitlab.com/gitlab/gitlab-ee/debian/trixie trixie main
   deb-src https://packages.gitlab.com/gitlab/gitlab-ee/debian/trixie trixie main
   ```

   {{< /tab >}}

   {{< tab title="러너" >}}

   ```plaintext
   deb https://packages.gitlab.com/runner/gitlab-runner/debian trixie main
   deb-src https://packages.gitlab.com/runner/gitlab-runner/debian trixie main
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. 미러 프로세스 시작

   ```shell
   sudo apt-mirror
   ```

## RPM 리포지토리 미러링 {#mirroring-rpm-repositories}

`rpm` 리포지토리의 로컬 미러는 `reposync`(패키지 다운로드용) 및 `createrepo`(메타데이터 생성용)을 사용하여 생성할 수 있습니다.

> [!note]
> `reposync`은 미러링하려는 리포지토리가 시스템에 설치되어 있어야 합니다. 미러링하려는 리포지토리에 대해 [설치 문서](package/_index.md#supported-platforms)를 따르세요.
>
> 리포지토리 ID를 찾으려면 다음으로 사용 가능한 리포지토리를 나열하세요:
>
> ```shell
> yum repolist
> ```

1. `createrepo` 및 `reposync` 설치

   ```shell
   sudo yum install createrepo yum-utils
   ```

1. 미러를 위한 디렉터리 생성

   ```shell
   sudo mkdir /srv/gitlab-repo-mirror
   ```

1. `reposync`를 실행합니다. 리포지토리 ID 및 출력 디렉터리를 인수로 전달합니다.

   ```shell
   reposync --repoid=gitlab_gitlab-ee --download-path=/srv/gitlab-repo-mirror
   ```

1. `createrepo`을 사용하여 리포지토리에 대한 메타데이터 생성

   ```shell
   createrepo -o /srv/gitlab-repo-mirror /srv/gitlab-repo-mirror
   ```
