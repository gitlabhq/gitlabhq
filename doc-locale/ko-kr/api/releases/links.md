---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 릴리스 링크 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.1에서 [GitLab CI/CD 작업 토큰](../../ci/jobs/ci_job_token.md)으로 인증 [추가됨](https://gitlab.com/gitlab-org/gitlab/-/issues/250819).

{{< /history >}}

이 API를 사용하여 [릴리스](../../user/project/releases/_index.md)에 대한 링크와 상호 작용합니다.

GitLab은 다음 프로토콜을 지원하는 자산 링크를 지원합니다:

- `http`
- `https`
- `ftp`

> [!note]
> 프로젝트 릴리스와 직접 상호 작용하려면 [프로젝트 릴리스 API](_index.md)를 참조하세요.

## 모든 릴리스 링크 나열 {#list-all-release-links}

릴리스에서 자산으로 모든 링크를 나열합니다.

```plaintext
GET /projects/:id/releases/:tag_name/assets/links
```

| 속성     | 유형           | 필수 | 설명                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `tag_name`    | 문자열         | 예      | 릴리스와 관련된 태그. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links"
```

응답 예시:

```json
[
   {
      "id":2,
      "name":"awesome-v0.2.msi",
      "url":"http://192.168.10.15:3000/msi",
      "link_type":"other"
   },
   {
      "id":1,
      "name":"awesome-v0.2.dmg",
      "url":"http://192.168.10.15:3000",
      "link_type":"other"
   }
]
```

## 릴리스 링크 검색 {#retrieve-a-release-link}

릴리스에서 지정된 자산을 링크로 검색합니다.

```plaintext
GET /projects/:id/releases/:tag_name/assets/links/:link_id
```

| 속성     | 유형           | 필수 | 설명                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `tag_name`    | 문자열         | 예      | 릴리스와 관련된 태그. |
| `link_id`    | 정수         | 예      | 링크의 ID. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

응답 예시:

```json
{
   "id":1,
   "name":"awesome-v0.2.dmg",
   "url":"http://192.168.10.15:3000",
   "link_type":"other"
}
```

## 릴리스 링크 생성 {#create-a-release-link}

지정된 릴리스에 대한 자산 링크를 생성합니다.

```plaintext
POST /projects/:id/releases/:tag_name/assets/links
```

| 속성            | 유형           | 필수 | 설명                                                                                                               |
|----------------------|----------------|----------|---------------------------------------------------------------------------------------------------------------------------|
| `id`                 | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths).                                        |
| `tag_name`           | 문자열         | 예      | 릴리스와 관련된 태그.                                                                                      |
| `name`               | 문자열         | 예      | 링크의 이름. 링크 이름은 릴리스 내에서 고유해야 합니다.                                                           |
| `url`                | 문자열         | 예      | 링크의 URL. 링크 URL은 릴리스 내에서 고유해야 합니다.                                                             |
| `direct_asset_path`  | 문자열         | 아니오       | [직접 자산 링크](../../user/project/releases/release_fields.md#permanent-links-to-release-assets)를 위한 선택적 경로. |
| `link_type`          | 문자열         | 아니오       | 링크의 유형: `other`, `runbook`, `image`, `package`. `other`로 기본 설정됩니다.                                        |

요청 예시:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data name="hellodarwin-amd64" \
    --data url="https://gitlab.example.com/mynamespace/hello/-/jobs/688/artifacts/raw/bin/hello-darwin-amd64" \
    --data direct_asset_path="/bin/hellodarwin-amd64" \
    "https://gitlab.example.com/api/v4/projects/20/releases/v1.7.0/assets/links"
```

응답 예시:

```json
{
   "id":2,
   "name":"hellodarwin-amd64",
   "url":"https://gitlab.example.com/mynamespace/hello/-/jobs/688/artifacts/raw/bin/hello-darwin-amd64",
   "direct_asset_url":"https://gitlab.example.com/mynamespace/hello/-/releases/v1.7.0/downloads/bin/hellodarwin-amd64",
   "link_type":"other"
}
```

## 릴리스 링크 업데이트 {#update-a-release-link}

릴리스에 대해 지정된 자산 링크를 업데이트합니다.

```plaintext
PUT /projects/:id/releases/:tag_name/assets/links/:link_id
```

| 속성            | 유형           | 필수 | 설명                                                                                                               |
| -------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------- |
| `id`                 | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `tag_name`           | 문자열         | 예      | 릴리스와 관련된 태그. |
| `link_id`            | 정수        | 예      | 링크의 ID. |
| `name`               | 문자열         | 아니오       | 링크의 이름. |
| `url`                | 문자열         | 아니오       | 링크의 URL. |
| `direct_asset_path`  | 문자열         | 아니오       | [직접 자산 링크](../../user/project/releases/release_fields.md#permanent-links-to-release-assets)를 위한 선택적 경로. |
| `link_type`          | 문자열         | 아니오       | 링크의 유형: `other`, `runbook`, `image`, `package`. `other`로 기본 설정됩니다. |

> [!note]
> `name` 또는 `url` 중 최소 하나는 지정해야 합니다.

요청 예시:

```shell
curl --request PUT --data name="new name" --data link_type="runbook" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

응답 예시:

```json
{
   "id":1,
   "name":"new name",
   "url":"http://192.168.10.15:3000",
   "link_type":"runbook"
}
```

## 릴리스 링크 삭제 {#delete-a-release-link}

릴리스에서 지정된 자산 링크를 삭제합니다.

```plaintext
DELETE /projects/:id/releases/:tag_name/assets/links/:link_id
```

| 속성     | 유형           | 필수 | 설명                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `tag_name`    | 문자열         | 예      | 릴리스와 관련된 태그. |
| `link_id`    | 정수         | 예      | 링크의 ID. |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

응답 예시:

```json
{
   "id":1,
   "name":"new name",
   "url":"http://192.168.10.15:3000",
   "link_type":"other"
}
```
