---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PyPI API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [PyPI 패키지 관리자 클라이언트](../../user/packages/pypi_repository/_index.md)와 상호 작용합니다.

> [!warning]
> 이 API는 [PyPI 패키지 관리자 클라이언트](https://pypi.org/)에서 사용되며 일반적으로 수동으로 사용하지 않습니다.

이러한 끝점은 표준 API 인증 방법을 준수하지 않습니다. [PyPI 패키지 레지스트리 문서](../../user/packages/pypi_repository/_index.md)에서 지원하는 헤더 및 토큰 유형에 대한 세부 정보를 참조하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

> [!note]
> [Twine 3.4.2](https://twine.readthedocs.io/en/stable/changelog.html?highlight=FIPS#id28) 이상이 FIPS 모드가 활성화되었을 때 권장됩니다.

## 그룹에 대한 패키지 파일 다운로드 {#download-a-package-file-for-a-group}

그룹에 대해 지정된 PyPI 패키지 파일을 다운로드합니다. [Simple API](#retrieve-package-descriptor-for-a-group)는 일반적으로 이 URL을 제공합니다.

```plaintext
GET groups/:id/-/packages/pypi/files/:sha256/:file_identifier
```

| 속성         | 유형   | 필수 | 설명 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 문자열 | 예      | 그룹의 ID 또는 전체 경로입니다. |
| `sha256`          | 문자열 | 예      | PyPI 패키지 파일의 sha256 체크섬입니다. |
| `file_identifier` | 문자열 | 예      | PyPI 패키지 파일의 이름입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

파일에 출력을 작성하려면:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

다운로드된 파일을 `my.pypi.package-0.0.1.tar.gz`에 현재 디렉터리로 작성합니다.

## 그룹에 대한 모든 패키지 나열 {#list-all-packages-for-a-group}

지정된 그룹의 모든 패키지를 HTML 파일로 나열합니다.

```plaintext
GET groups/:id/-/packages/pypi/simple
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 문자열 | 예 | 그룹의 ID 또는 전체 경로입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple"
```

응답 예:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for Group</title>
  </head>
  <body>
    <h1>Links for Group</h1>
    <a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my-pypi-package" data-requires-python="">my.pypi.package</a><br><a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/package-2" data-requires-python="3.8">package_2</a><br>
  </body>
</html>
```

파일에 출력을 작성하려면:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple" >> simple_index.html
```

다운로드된 파일을 `simple_index.html`에 현재 디렉터리로 작성합니다.

## 그룹에 대한 패키지 설명자 검색 {#retrieve-package-descriptor-for-a-group}

그룹의 지정된 패키지에 대한 HTML 파일로 패키지 설명자를 검색합니다.

```plaintext
GET groups/:id/-/packages/pypi/simple/:package_name
```

| 속성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 문자열 | 예      | 그룹의 ID 또는 전체 경로입니다. |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my.pypi.package"
```

응답 예:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for my.pypi.package</title>
  </head>
  <body>
    <h1>Links for my.pypi.package</h1>
    <a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1-py3-none-any.whl#sha256=5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1-py3-none-any.whl</a><br><a href="https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/files/9s9w01b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2/my.pypi.package-0.0.1.tar.gz#sha256=9s9w011b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1.tar.gz</a><br>
  </body>
</html>
```

파일에 출력을 작성하려면:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/groups/1/-/packages/pypi/simple/my.pypi.package" >> simple.html
```

다운로드된 파일을 `simple.html`에 현재 디렉터리로 작성합니다.

## 프로젝트에 대한 패키지 파일 다운로드 {#download-a-package-file-for-a-project}

프로젝트에 대해 지정된 PyPI 패키지 파일을 다운로드합니다. [Simple API](#retrieve-package-descriptor-for-a-project)는 일반적으로 이 URL을 제공합니다.

```plaintext
GET projects/:id/packages/pypi/files/:sha256/:file_identifier
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`              | 문자열 | 예 | 프로젝트의 ID 또는 전체 경로입니다. |
| `sha256`          | 문자열 | 예 | PyPI 패키지 파일 sha256 체크섬입니다. |
| `file_identifier` | 문자열 | 예 | PyPI 패키지 파일 이름입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz"
```

파일에 출력을 작성하려면:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1.tar.gz" >> my.pypi.package-0.0.1.tar.gz
```

다운로드된 파일을 `my.pypi.package-0.0.1.tar.gz`에 현재 디렉터리로 작성합니다.

## 프로젝트에 대한 모든 패키지 나열 {#list-all-packages-for-a-project}

지정된 프로젝트의 모든 패키지를 HTML 파일로 나열합니다.

```plaintext
GET projects/:id/packages/pypi/simple
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 문자열 | 예 | 프로젝트의 ID 또는 전체 경로입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple"
```

응답 예:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for Project</title>
  </head>
  <body>
    <h1>Links for Project</h1>
    <a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my-pypi-package" data-requires-python="">my.pypi.package</a><br><a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/package-2" data-requires-python="3.8">package_2</a><br>
  </body>
</html>
```

파일에 출력을 작성하려면:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple" >> simple_index.html
```

다운로드된 파일을 `simple_index.html`에 현재 디렉터리로 작성합니다.

## 프로젝트에 대한 패키지 설명자 검색 {#retrieve-package-descriptor-for-a-project}

프로젝트의 지정된 패키지에 대한 HTML 파일로 패키지 설명자를 검색합니다.

```plaintext
GET projects/:id/packages/pypi/simple/:package_name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`           | 문자열 | 예 | 프로젝트의 ID 또는 전체 경로입니다. |
| `package_name` | 문자열 | 예 | 패키지의 이름입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my.pypi.package"
```

응답 예:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Links for my.pypi.package</title>
  </head>
  <body>
    <h1>Links for my.pypi.package</h1>
    <a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff/my.pypi.package-0.0.1-py3-none-any.whl#sha256=5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1-py3-none-any.whl</a><br><a href="https://gitlab.example.com/api/v4/projects/1/packages/pypi/files/9s9w01b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2/my.pypi.package-0.0.1.tar.gz#sha256=9s9w011b0bcd52b709ec052084e33a5517ffca96f7728ddd9f8866a30cdf76f2" data-requires-python="&gt;=3.6">my.pypi.package-0.0.1.tar.gz</a><br>
  </body>
</html>
```

파일에 출력을 작성하려면:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi/simple/my.pypi.package" >> simple.html
```

다운로드된 파일을 `simple.html`에 현재 디렉터리로 작성합니다.

## 패키지 업로드 {#upload-a-package}

지정된 프로젝트에 대한 PyPI 패키지를 업로드합니다.

```plaintext
POST projects/:id/packages/pypi
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 문자열 | 예 | 프로젝트의 ID 또는 전체 경로입니다. |
| `requires_python` | 문자열 | 아니요 | 필요한 PyPI 버전입니다. |
| `sha256_digest` | 문자열 | 아니요 | 패키지 파일의 SHA256 체크섬입니다. 업로드에는 필수가 아니지만 이 특성이 없으면 `pip install`은 패키지 인덱스 URL에 필요한 체크섬이 없기 때문에 실패합니다. |

```shell
curl --request POST \
     --form 'content=@path/to/my.pypi.package-0.0.1.tar.gz' \
     --form "sha256_digest=$(shasum -a 256 < path/to/my.pypi.package-0.0.1.tar.gz | cut -d' ' -f1)" \
     --form 'name=my.pypi.package' \
     --form 'version=1.3.7' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/pypi"
```
