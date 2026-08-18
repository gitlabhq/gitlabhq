---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Composer API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [Composer 패키지 관리자 클라이언트](../../user/packages/composer_repository/_index.md)와 상호 작용합니다.

> [!warning]
> 이 API는 [Composer 패키지 관리자 클라이언트](https://getcomposer.org/)에서 사용하며 일반적으로 수동 사용을 위해 설계되지 않았습니다.

이 엔드포인트는 표준 API 인증 방법을 따르지 않습니다. 지원되는 헤더 및 토큰 유형에 대한 자세한 내용은 [Composer 패키지 레지스트리 문서](../../user/packages/composer_repository/_index.md)를 참조하세요. 문서화되지 않은 인증 방법은 향후 제거될 수 있습니다.

## 리포지토리 URL 템플릿 검색 {#retrieve-repository-url-templates}

그룹에 대한 개별 패키지를 요청하기 위한 리포지토리 URL 템플릿을 검색합니다.

```plaintext
GET group/:id/-/packages/composer/packages
```

| 특성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 그룹의 ID 또는 전체 경로입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/packages"
```

응답 예:

```json
{
  "packages": [],
  "metadata-url": "/api/v4/group/1/-/packages/composer/p2/%package%.json",
  "provider-includes": {
    "p/%hash%.json": {
      "sha256": "082df4a5035f8725a12a4a3d2da5e6aaa966d06843d0a5c6d499313810427bd6"
    }
  },
  "providers-url": "/api/v4/group/1/-/packages/composer/%package%$%hash%.json"
}
```

이 엔드포인트는 Composer V1 및 V2에서 사용합니다. V2 전용 응답을 보려면 Composer `User-Agent` 헤더를 포함하세요. Composer V2는 V1보다 권장됩니다.

```shell
curl --user <username>:<personal_access_token> \
     --header "User-Agent: Composer/2" \
     --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/packages"
```

응답 예:

```json
{
  "packages": [],
  "metadata-url": "/api/v4/group/1/-/packages/composer/p2/%package%.json"
}
```

## V1 패키지 목록 {#v1-packages-list}

V1 공급자 SHA가 주어진 그룹의 리포지토리에 있는 패키지 목록을 검색합니다. Composer V2는 V1보다 권장됩니다.

```plaintext
GET group/:id/-/packages/composer/p/:sha
```

| 특성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 문자열 | 예 | 그룹의 ID 또는 전체 경로입니다. |
| `sha`     | 문자열 | 예 | Composer [기본 요청](#retrieve-repository-url-templates)에서 제공하는 공급자 SHA입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/p/082df4a5035f8725a12a4a3d2da5e6aaa966d06843d0a5c6d499313810427bd6"
```

응답 예:

```json
{
  "providers": {
    "my-org/my-composer-package": {
      "sha256": "5c873497cdaa82eda35af5de24b789be92dfb6510baf117c42f03899c166b6e7"
    }
  }
}
```

## V1 패키지 메타데이터 검색 {#retrieve-v1-package-metadata}

그룹의 지정된 패키지에 대한 버전 및 메타데이터 목록을 검색합니다. Composer V2는 V1보다 권장됩니다.

```plaintext
GET group/:id/-/packages/composer/:package_name$:sha
```

URL의 `$` 기호를 참고하세요. 요청할 때 기호의 URL 인코딩된 버전 `%24`이(가) 필요할 수 있습니다. 표 다음의 예를 참조하세요:

| 특성      | 유형   | 필수 | 설명                                                                           |
|----------------|--------|----------|---------------------------------------------------------------------------------------|
| `id`           | 문자열 | 예      | 그룹의 ID 또는 전체 경로입니다.                                                     |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다.                                                              |
| `sha`          | 문자열 | 예      | [V1 패키지 목록](#v1-packages-list)에서 제공하는 패키지의 SHA 다이제스트입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/my-org/my-composer-package%245c873497cdaa82eda35af5de24b789be92dfb6510baf117c42f03899c166b6e7"
```

응답 예:

```json
{
  "packages": {
    "my-org/my-composer-package": {
      "1.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "1.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      },
      "2.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "2.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      }
    }
  }
}
```

## V2 패키지 메타데이터 검색 {#retrieve-v2-package-metadata}

그룹의 지정된 패키지에 대한 버전 및 메타데이터 목록을 검색합니다.

```plaintext
GET group/:id/-/packages/composer/p2/:package_name
```

| 특성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 문자열 | 예      | 그룹의 ID 또는 전체 경로입니다. |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/p2/my-org/my-composer-package"
```

응답 예:

```json
{
  "packages": {
    "my-org/my-composer-package": {
      "1.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "1.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      },
      "2.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "2.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      }
    }
  }
}
```

## 패키지 생성 {#create-a-package}

프로젝트에 대해 지정된 Git 태그 또는 브랜치에서 Composer 패키지를 만듭니다.

```plaintext
POST projects/:id/packages/composer
```

| 특성 | 유형   | 필수 | 설명 |
| --------- | ------ | -------- | ----------- |
| `id`      | 문자열 | 예      | 그룹의 ID 또는 전체 경로입니다. |
| `tag`     | 문자열 | 아니요       | 패키지를 대상으로 할 태그의 이름입니다. |
| `branch`  | 문자열 | 아니요       | 패키지를 대상으로 할 브랜치의 이름입니다. |

```shell
curl --request POST --user <username>:<personal_access_token> \
     --data tag=v1.0.0 \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/composer"
```

응답 예:

```json
{
  "message": "201 Created"
}
```

## 패키지 아카이브 다운로드 {#download-a-package-archive}

프로젝트에 대해 지정된 Composer 패키지 아카이브를 다운로드합니다. 이 URL은 [v1](#retrieve-v1-package-metadata) 또는 [v2 패키지 메타데이터](#retrieve-v2-package-metadata) 응답에서 제공됩니다. `.zip` 파일 확장명이 요청에 포함되어야 합니다.

```plaintext
GET projects/:id/packages/composer/archives/:package_name
```

| 특성      | 유형   | 필수 | 설명 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 문자열 | 예      | 그룹의 ID 또는 전체 경로입니다. |
| `package_name` | 문자열 | 예      | 패키지의 이름입니다. |
| `sha`          | 문자열 | 예      | 요청된 패키지 버전의 대상 SHA입니다. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
```

파일에 출력을 작성합니다:

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab" >> package.zip
```

이렇게 하면 다운로드한 파일이 현재 디렉터리의 `package.zip`에 기록됩니다.
