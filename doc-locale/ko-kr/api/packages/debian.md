---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Debian API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [기능 플래그로 배포](../../administration/feature_flags/_index.md), 기본적으로 비활성화됨.

{{< /history >}}

> [!warning]
> 이 API는 [dput](https://manpages.debian.org/stable/dput-ng/dput.1.en.html) 및 [apt-get](https://manpages.debian.org/stable/apt/apt-get.8.en.html) 등의 Debian 관련 패키지 클라이언트에서 사용되며, 일반적으로 수동 사용을 위해 제작되지 않았습니다. 이 API는 개발 중이며 기능이 제한되어 있어 프로덕션 사용에 준비되지 않았습니다.

이 API를 사용하여 [Debian 패키지 관리자 클라이언트](../../user/packages/debian_repository/_index.md)와 상호작용합니다.

> [!note]
> 이러한 엔드포인트는 표준 API 인증 방법을 준수하지 않습니다. [Debian 레지스트리 설명서](../../user/packages/debian_repository/_index.md)를 참조하여 지원되는 헤더 및 토큰 유형에 대한 자세한 내용을 확인합니다. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

## Debian API 활성화 {#enable-the-debian-api}

Debian API는 기본적으로 비활성화된 기능 플래그 뒤에 있습니다. [GitLab Rails 콘솔에 액세스할 수 있는 GitLab 관리자](../../administration/feature_flags/_index.md)는 활성화를 선택할 수 있습니다. 활성화하려면 [Debian API 활성화](../../user/packages/debian_repository/_index.md#enable-the-debian-api)의 지침을 따릅니다.

## Debian 그룹 API 활성화 {#enable-the-debian-group-api}

Debian 그룹 API는 기본적으로 비활성화된 기능 플래그 뒤에 있습니다. [GitLab Rails 콘솔에 액세스할 수 있는 GitLab 관리자](../../administration/feature_flags/_index.md)는 활성화를 선택할 수 있습니다. 활성화하려면 [Debian 그룹 API 활성화](../../user/packages/debian_repository/_index.md#enable-the-debian-group-api)의 지침을 따릅니다.

### Debian 패키지 리포지토리 인증 {#authenticate-to-the-debian-package-repositories}

[Debian 패키지 리포지토리 인증](../../user/packages/debian_repository/_index.md#authenticate-to-the-debian-package-repositories)을 참조합니다.

## 패키지 파일 업로드 {#upload-a-package-file}

지정된 프로젝트에 대해 Debian 패키지 파일을 업로드합니다.

```plaintext
PUT projects/:id/packages/debian/:file_name
```

| 속성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 문자열 | 예      | 프로젝트의 ID 또는 전체 경로입니다.  |
| `file_name`    | 문자열 | 예      | Debian 패키지 파일의 이름. |
| `distribution` | 문자열 | 아니오       | 배포 코드명 또는 스위트. `component`과 함께 사용하여 명시적 배포 및 구성 요소로 업로드합니다. |
| `component`    | 문자열 | 아니오       | 패키지 파일 구성 요소. `distribution`과 함께 사용하여 명시적 배포 및 구성 요소로 업로드합니다. |

```shell
curl --request PUT \
     --user "<username>:<personal_access_token>" \
     --upload-file path/to/mypkg.deb \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/mypkg.deb"
```

명시적 배포 및 구성 요소로 업로드:

```shell
curl --request PUT \
  --user "<username>:<personal_access_token>" \
  --upload-file  /path/to/myother.deb \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/myother.deb?distribution=sid&component=main"
```

## 패키지 다운로드 {#download-a-package}

프로젝트의 지정된 패키지 파일을 다운로드합니다.

```plaintext
GET projects/:id/packages/debian/pool/:distribution/:letter/:package_name/:package_version/:file_name
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |
| `letter`          | 문자열 | 예      | Debian 분류(첫 글자 또는 lib-첫 글자). |
| `package_name`    | 문자열 | 예      | 소스 패키지 이름. |
| `package_version` | 문자열 | 예      | 소스 패키지 버전. |
| `file_name`       | 문자열 | 예      | 파일 이름. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/pool/my-distro/a/my-pkg/1.0.0/example_1.0.0~alpha2_amd64.deb" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.

## 경로 접두사 {#route-prefix}

나머지 설명된 엔드포인트는 다양한 범위로 요청을 수행하는 두 세트의 동일한 경로입니다:

- 프로젝트 수준 접두사를 사용하여 단일 프로젝트의 범위에서 요청을 만듭니다.
- 그룹 수준 접두사를 사용하여 단일 그룹의 범위에서 요청을 수행합니다.

이 문서의 예제는 모두 프로젝트 수준 접두사를 사용합니다.

### 프로젝트 수준 {#project-level}

```plaintext
/projects/:id/packages/debian
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 문자열 | 예 | 프로젝트 ID 또는 전체 프로젝트 경로입니다. |

### 그룹 수준 {#group-level}

```plaintext
/groups/:id/-/packages/debian
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 문자열 | 예 | 프로젝트 ID 또는 전체 그룹 경로. |

## 배포 Release 파일 다운로드 {#download-a-distribution-release-file}

지정된 Debian 배포 Release 파일을 다운로드합니다.

```plaintext
GET <route-prefix>/dists/*distribution/Release
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.

## 서명된 배포 Release 파일 다운로드 {#download-a-signed-distribution-release-file}

지정된 서명된 Debian 배포 Release 파일을 다운로드합니다.

```plaintext
GET <route-prefix>/dists/*distribution/InRelease
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/InRelease" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.

## 릴리스 파일 서명 다운로드 {#download-a-release-file-signature}

지정된 Debian 릴리스 파일 서명을 다운로드합니다.

```plaintext
GET <route-prefix>/dists/*distribution/Release.gpg
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/Release.gpg" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.

## 패키지 인덱스 다운로드 {#download-a-packages-index}

지정된 패키지 인덱스를 다운로드합니다.

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/Packages
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |
| `component`       | 문자열 | 예      | 배포 구성 요소 이름. |
| `architecture`    | 문자열 | 예      | 배포 아키텍처 유형. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/Packages" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.

## 해시로 패키지 인덱스 다운로드 {#download-a-packages-index-by-hash}

해시로 지정된 패키지 인덱스를 다운로드합니다.

```plaintext
GET <route-prefix>/dists/*distribution/:component/binary-:architecture/by-hash/SHA256/:file_sha256

```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |
| `component`       | 문자열 | 예      | 배포 구성 요소 이름. |
| `architecture`    | 문자열 | 예      | 배포 아키텍처 유형. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.

## Debian Installer 패키지 인덱스 다운로드 {#download-a-debian-installer-packages-index}

지정된 Debian Installer 패키지 인덱스를 다운로드합니다.

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/Packages
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |
| `component`       | 문자열 | 예      | 배포 구성 요소 이름. |
| `architecture`    | 문자열 | 예      | 배포 아키텍처 유형. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/Packages" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.

## 해시로 Debian Installer 패키지 인덱스 다운로드 {#download-a-debian-installer-packages-index-by-hash}

해시로 지정된 Debian Installer 패키지 인덱스를 다운로드합니다.

```plaintext
GET <route-prefix>/dists/*distribution/:component/debian-installer/binary-:architecture/by-hash/SHA256/:file_sha256
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |
| `component`       | 문자열 | 예      | 배포 구성 요소 이름. |
| `architecture`    | 문자열 | 예      | 배포 아키텍처 유형. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/debian-installer/binary-amd64/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.

## 소스 패키지 인덱스 다운로드 {#download-a-source-packages-index}

지정된 소스 패키지 인덱스를 다운로드합니다.

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/Sources
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |
| `component`       | 문자열 | 예      | 배포 구성 요소 이름. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/Sources" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.

## 해시로 소스 패키지 인덱스 다운로드 {#download-a-source-packages-index-by-hash}

해시로 지정된 소스 패키지 인덱스를 다운로드합니다.

```plaintext
GET <route-prefix>/dists/*distribution/:component/source/by-hash/SHA256/:file_sha256
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `distribution`    | 문자열 | 예      | Debian 배포의 코드명 또는 스위트. |
| `component`       | 문자열 | 예      | 배포 구성 요소 이름. |

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18"
```

파일에 출력을 작성합니다:

```shell
curl --header "PRIVATE-TOKEN: <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/debian/dists/my-distro/main/source/by-hash/SHA256/66a045b452102c59d840ec097d59d9467e13a3f34f6494e539ffd32c1bb35f18" \
     --remote-name
```

현재 디렉토리의 원격 파일 이름을 사용하여 다운로드한 파일을 작성합니다.
