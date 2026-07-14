---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 릴리스 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 프로젝트의 [릴리스](../../user/project/releases/_index.md)와 상호 작용합니다.

> [!note]
> 그룹의 릴리스와 상호 작용하려면 [그룹 릴리스 API](../group_releases.md)를 참조하세요.
>
> 릴리스 자산으로 링크와 상호 작용하려면 [릴리스 링크 API](links.md)를 참조하세요.

## 인증 {#authentication}

인증을 위해 Releases API는 다음 중 하나를 허용합니다:

- [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)을(를) `PRIVATE-TOKEN` 헤더를 사용하여 전달합니다.
- [GitLab CI/CD 작업 토큰](../../ci/jobs/ci_job_token.md) `$CI_JOB_TOKEN`을(를) `JOB-TOKEN` 헤더를 사용하여 전달합니다.

## 릴리스 나열 {#list-releases}

`released_at`로 정렬된 릴리스의 페이징된 목록을 반환합니다.

```plaintext
GET /projects/:id/releases
```

| 속성     | 유형           | 필수 | 설명                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `order_by`    | 문자열         | 아니오       | 순서로 사용할 필드입니다. `released_at` (기본값) 또는 `created_at` 중 하나입니다. |
| `sort`        | 문자열         | 아니오       | 순서의 방향입니다. 내림차순의 경우 `desc` (기본값) 또는 오름차순의 경우 `asc` 중 하나입니다. |
| `include_html_description` | 부울        | 아니오       | `true`인 경우 응답에 릴리스 설명의 HTML로 렌더링된 마크다운이 포함됩니다.   |

성공하면 [`200 OK`](../rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 표시합니다:

| 속성                             | 유형   | 설명                                      |
|:--------------------------------------|:-------|:-------------------------------------------------|
| `[]._links`                           | 개체 | 릴리스의 링크입니다.                            |
| `[]._links.closed_issues_url`         | 문자열 | 릴리스의 종료된 이슈의 HTTP URL입니다.         |
| `[]._links.closed_merge_requests_url` | 문자열 | 릴리스의 종료된 머지 리퀘스트의 HTTP URL입니다. |
| `[]._links.edit_url`                  | 문자열 | 릴리스의 편집 페이지의 HTTP URL입니다.             |
| `[]._links.merged_merge_requests_url` | 문자열 | 릴리스의 병합된 머지 리퀘스트의 HTTP URL입니다. |
| `[]._links.opened_issues_url`         | 문자열 | 릴리스의 개설된 이슈의 HTTP URL입니다.           |
| `[]._links.opened_merge_requests_url` | 문자열 | 릴리스의 개설된 머지 리퀘스트의 HTTP URL입니다.   |
| `[]._links.self`                      | 문자열 | 릴리스의 HTTP URL입니다.                         |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases"
```

응답 예:

```json
[
   {
      "tag_name":"v0.2",
      "description":"## CHANGELOG\r\n\r\n- Escape label and milestone titles to prevent XSS in GLFM autocomplete. !2740\r\n- Prevent private snippets from being embeddable.\r\n- Add subresources removal to member destroy service.",
      "name":"Awesome app v0.2 beta",
      "created_at":"2019-01-03T01:56:19.539Z",
      "released_at":"2019-01-03T01:56:19.539Z",
      "author":{
         "id":1,
         "name":"Administrator",
         "username":"root",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
         "web_url":"https://gitlab.example.com/root"
      },
      "commit":{
         "id":"079e90101242458910cccd35eab0e211dfc359c0",
         "short_id":"079e9010",
         "title":"Update README.md",
         "created_at":"2019-01-03T01:55:38.000Z",
         "parent_ids":[
            "f8d3d94cbd347e924aa7b715845e439d00e80ca4"
         ],
         "message":"Update README.md",
         "author_name":"Administrator",
         "author_email":"admin@example.com",
         "authored_date":"2019-01-03T01:55:38.000Z",
         "committer_name":"Administrator",
         "committer_email":"admin@example.com",
         "committed_date":"2019-01-03T01:55:38.000Z"
      },
      "milestones": [
         {
            "id":51,
            "iid":1,
            "project_id":24,
            "title":"v1.0-rc",
            "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
            "state":"closed",
            "created_at":"2019-07-12T19:45:44.256Z",
            "updated_at":"2019-07-12T19:45:44.256Z",
            "due_date":"2019-08-16",
            "start_date":"2019-07-30",
            "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
            "issue_stats": {
               "total": 98,
               "closed": 76
            }
         },
         {
            "id":52,
            "iid":2,
            "project_id":24,
            "title":"v1.0",
            "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
            "state":"closed",
            "created_at":"2019-07-16T14:00:12.256Z",
            "updated_at":"2019-07-16T14:00:12.256Z",
            "due_date":"2019-08-16",
            "start_date":"2019-07-30",
            "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
            "issue_stats": {
               "total": 24,
               "closed": 21
            }
         }
      ],
      "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
      "tag_path":"/root/awesome-app/-/tags/v0.11.1",
      "assets":{
         "count":6,
         "sources":[
            {
               "format":"zip",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.zip"
            },
            {
               "format":"tar.gz",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar.gz"
            },
            {
               "format":"tar.bz2",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar.bz2"
            },
            {
               "format":"tar",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar"
            }
         ],
         "links":[
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
         ],
         "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.2/evidence.json"
      },
      "evidences":[
        {
          "sha": "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
          "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.2/evidence.json",
          "collected_at": "2019-01-03T01:56:19.539Z"
        }
     ]
   },
   {
      "tag_name":"v0.1",
      "description":"## CHANGELOG\r\n\r\n-Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
      "name":"Awesome app v0.1 alpha",
      "created_at":"2019-01-03T01:55:18.203Z",
      "released_at":"2019-01-03T01:55:18.203Z",
      "author":{
         "id":1,
         "name":"Administrator",
         "username":"root",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
         "web_url":"https://gitlab.example.com/root"
      },
      "commit":{
         "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
         "short_id":"f8d3d94c",
         "title":"Initial commit",
         "created_at":"2019-01-03T01:53:28.000Z",
         "parent_ids":[

         ],
         "message":"Initial commit",
         "author_name":"Administrator",
         "author_email":"admin@example.com",
         "authored_date":"2019-01-03T01:53:28.000Z",
         "committer_name":"Administrator",
         "committer_email":"admin@example.com",
         "committed_date":"2019-01-03T01:53:28.000Z"
      },
      "assets":{
         "count":4,
         "sources":[
            {
               "format":"zip",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
            },
            {
               "format":"tar.gz",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
            },
            {
               "format":"tar.bz2",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
            },
            {
               "format":"tar",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
            }
         ],
         "links":[

         ],
         "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
      },
      "evidences":[
        {
          "sha": "c3ffedec13af470e760d6cdfb08790f71cf52c6cde4d",
          "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json",
          "collected_at": "2019-01-03T01:55:18.203Z"
        }
      ],
      "_links": {
         "closed_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=closed",
         "closed_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=closed",
         "edit_url": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/edit",
         "merged_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=merged",
         "opened_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=opened",
         "opened_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=opened",
         "self": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1"
      }
   }
]
```

## 태그 이름으로 릴리스 가져오기 {#get-a-release-by-a-tag-name}

지정된 태그에 대한 릴리스를 가져옵니다.

```plaintext
GET /projects/:id/releases/:tag_name
```

| 속성                  | 유형           | 필수 | 설명                                                                         |
|----------------------------| -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`                       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths).  |
| `tag_name`                 | 문자열         | 예      | 릴리스가 연결된 Git 태그입니다.                                         |
| `include_html_description` | 부울        | 아니오       | `true`인 경우 응답에 릴리스 설명의 HTML로 렌더링된 마크다운이 포함됩니다.   |

성공하면 [`200 OK`](../rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 표시합니다:

| 속성                             | 유형   | 설명                                      |
|:--------------------------------------|:-------|:-------------------------------------------------|
| `[]._links`                           | 개체 | 릴리스의 링크입니다.                            |
| `[]._links.closed_issues_url`         | 문자열 | 릴리스의 종료된 이슈의 HTTP URL입니다.         |
| `[]._links.closed_merge_requests_url` | 문자열 | 릴리스의 종료된 머지 리퀘스트의 HTTP URL입니다. |
| `[]._links.edit_url`                  | 문자열 | 릴리스의 편집 페이지의 HTTP URL입니다.             |
| `[]._links.merged_merge_requests_url` | 문자열 | 릴리스의 병합된 머지 리퀘스트의 HTTP URL입니다. |
| `[]._links.opened_issues_url`         | 문자열 | 릴리스의 개설된 이슈의 HTTP URL입니다.           |
| `[]._links.opened_merge_requests_url` | 문자열 | 릴리스의 개설된 머지 리퀘스트의 HTTP URL입니다.   |
| `[]._links.self`                      | 문자열 | 릴리스의 HTTP URL입니다.                         |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

응답 예:

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"Awesome app v0.1 alpha",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "milestones": [
       {
         "id":51,
         "iid":1,
         "project_id":24,
         "title":"v1.0-rc",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-12T19:45:44.256Z",
         "updated_at":"2019-07-12T19:45:44.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
         "issue_stats": {
            "total": 98,
            "closed": 76
         }
       },
       {
         "id":52,
         "iid":2,
         "project_id":24,
         "title":"v1.0",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-16T14:00:12.256Z",
         "updated_at":"2019-07-16T14:00:12.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
         "issue_stats": {
            "total": 24,
            "closed": 21
         }
       }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "assets":{
      "count":5,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[
         {
            "id":3,
            "name":"hoge",
            "url":"https://gitlab.example.com/root/awesome-app/-/tags/v0.11.1/binaries/linux-amd64",
            "link_type":"other"
         }
      ]
   },
   "evidences":[
     {
       "sha": "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
       "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json",
       "collected_at": "2019-07-16T14:00:12.256Z"
     },
   "_links": {
      "closed_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=closed",
      "closed_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=closed",
      "edit_url": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/edit",
      "merged_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=merged",
      "opened_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=opened",
      "opened_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=opened",
      "self": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1"
    }
  ]
}
```

## 릴리스 자산 다운로드 {#download-a-release-asset}

{{< history >}}

- GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/358188)되었습니다.

{{< /history >}}

다음 형식으로 요청하여 릴리스 자산 파일을 다운로드합니다:

```plaintext
GET /projects/:id/releases/:tag_name/downloads/:direct_asset_path
```

| 속성                  | 유형           | 필수 | 설명                                                                         |
|----------------------------| -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`                       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths).  |
| `tag_name`                 | 문자열         | 예      | 릴리스가 연결된 Git 태그입니다.                                         |
| `direct_asset_path`        | 문자열         | 예      | 릴리스 자산 파일의 경로는 [생성](links.md#create-a-release-link) 또는 [업데이트](links.md#update-a-release-link) 시 지정됩니다. |

요청 예시:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/downloads/bin/asset.exe"
```

### 최신 릴리스 가져오기 {#get-the-latest-release}

{{< history >}}

- GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/358188)되었습니다.

{{< /history >}}

최신 릴리스 정보는 영구적인 API URL을 통해 액세스할 수 있습니다.

URL의 형식은 다음과 같습니다:

```plaintext
GET /projects/:id/releases/permalink/latest
```

릴리스 태그가 필요한 다른 GET API를 호출하려면 `permalink/latest` API 경로에 접미사를 추가합니다.

예를 들어 최신 [릴리스 증거](#collect-release-evidence)를 가져오려면 다음을 사용할 수 있습니다:

```plaintext
GET /projects/:id/releases/permalink/latest/evidence
```

또 다른 예는 최신 릴리스의 [자산 다운로드](#download-a-release-asset)이며, 다음을 사용할 수 있습니다:

```plaintext
GET /projects/:id/releases/permalink/latest/downloads/bin/asset.exe
```

#### 정렬 기본 설정 {#sorting-preferences}

기본적으로 GitLab은 `released_at` 시간을 사용하여 릴리스를 가져옵니다. 쿼리 매개변수 `?order_by=released_at`의 사용은 선택 사항이며, `?order_by=semver`에 대한 지원은 [이슈 352945](https://gitlab.com/gitlab-org/gitlab/-/issues/352945)에서 추적됩니다.

## 릴리스 생성 {#create-a-release}

릴리스를 생성합니다. 릴리스를 생성하려면 프로젝트에 대한 개발자 수준 액세스가 필요합니다.

```plaintext
POST /projects/:id/releases
```

| 속성          | 유형            | 필수                    | 설명                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | 정수 또는 문자열  | 예                         | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths).                                              |
| `name`             | 문자열          | 아니오                          | 릴리스 이름입니다.                                                                                                                |
| `tag_name`         | 문자열          | 예                         | 릴리스가 생성되는 태그입니다.                                                                                  |
| `tag_message`      | 문자열          | 아니오                          | 새 주석 태그를 생성할 때 사용할 메시지입니다.                                                                                  |
| `description`      | 문자열          | 아니오                          | 릴리스의 설명입니다. [마크다운](../../user/markdown.md)을 사용할 수 있습니다.                                                  |
| `ref`              | 문자열          | `tag_name`이 존재하지 않는 경우 예 | `tag_name`에 지정된 태그가 존재하지 않으면 릴리스는 `ref`에서 생성되고 `tag_name`로 태그됩니다. 커밋 SHA, 다른 태그 이름 또는 브랜치 이름일 수 있습니다. |
| `milestones`       | 문자열 배열 | 아니오                          | 릴리스가 연결된 각 마일스톤의 제목입니다. [GitLab Premium](https://about.gitlab.com/pricing/) 고객은 그룹 마일스톤을 지정할 수 있습니다.                                                                      |
| `assets:links`     | 해시 배열   | 아니오                          | 자산 링크의 배열입니다.                                                                                                        |
| `assets:links:name`| 문자열          | `assets:links`에 필수 | 링크의 이름입니다. 링크 이름은 릴리스 내에서 고유해야 합니다.                                                              |
| `assets:links:url` | 문자열          | `assets:links`에 필수 | 링크의 URL입니다. 링크 URL은 릴리스 내에서 고유해야 합니다.                                                                |
| `assets:links:direct_asset_path` | 문자열     | 아니오 | [직접 자산 링크](../../user/project/releases/release_fields.md#permanent-links-to-release-assets)의 선택적 경로입니다. |
| `assets:links:link_type` | 문자열     | 아니오 | 링크의 유형: `other`, `runbook`, `image`, `package`입니다. `other`을(를) 기본값으로 합니다. |
| `released_at`      | 날짜/시간        | 아니오                          | 릴리스의 날짜와 시간입니다. 현재 시간이 기본값입니다. ISO 8601 형식으로 예상됩니다 (`2019-03-15T08:00:00Z`). [예정된 릴리스](../../user/project/releases/_index.md#upcoming-releases) 또는 [과거 릴리스](../../user/project/releases/_index.md#historical-releases)를 생성하는 경우에만 이 필드를 제공합니다.  |

요청 예시:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "name": "New release", "tag_name": "v0.3", "description": "Super nice release", "milestones": ["v1.0", "v1.0-rc"], "assets": { "links": [{ "name": "hoge", "url": "https://google.com", "direct_asset_path": "/binaries/linux-amd64", "link_type":"other" }] } }' \
     --request POST "https://gitlab.example.com/api/v4/projects/24/releases"
```

응답 예:

```json
{
   "tag_name":"v0.3",
   "description":"Super nice release",
   "name":"New release",
   "created_at":"2019-01-03T02:22:45.118Z",
   "released_at":"2019-01-03T02:22:45.118Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"079e90101242458910cccd35eab0e211dfc359c0",
      "short_id":"079e9010",
      "title":"Update README.md",
      "created_at":"2019-01-03T01:55:38.000Z",
      "parent_ids":[
         "f8d3d94cbd347e924aa7b715845e439d00e80ca4"
      ],
      "message":"Update README.md",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:55:38.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:55:38.000Z"
   },
   "milestones": [
       {
         "id":51,
         "iid":1,
         "project_id":24,
         "title":"v1.0-rc",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-12T19:45:44.256Z",
         "updated_at":"2019-07-12T19:45:44.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
         "issue_stats": {
            "total": 99,
            "closed": 76
         }
       },
       {
         "id":52,
         "iid":2,
         "project_id":24,
         "title":"v1.0",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-16T14:00:12.256Z",
         "updated_at":"2019-07-16T14:00:12.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
         "issue_stats": {
            "total": 24,
            "closed": 21
         }
       }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":5,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar"
         }
      ],
      "links":[
         {
            "id":3,
            "name":"hoge",
            "url":"https://gitlab.example.com/root/awesome-app/-/tags/v0.11.1/binaries/linux-amd64",
            "link_type":"other"
         }
      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.3/evidence.json"
   }
}
```

### 그룹 마일스톤 {#group-milestones}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

프로젝트와 연결된 그룹 마일스톤은 [릴리스 생성](#create-a-release) 및 [릴리스 업데이트](#update-a-release) API 호출에 대해 `milestones` 배열에서 지정할 수 있습니다. 프로젝트의 그룹과 연결된 마일스톤만 지정할 수 있으며, 상위 그룹에 대한 마일스톤을 추가하면 오류가 발생합니다.

## 릴리스 증거 수집 {#collect-release-evidence}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

기존 릴리스에 대한 증거를 생성합니다.

```plaintext
POST /projects/:id/releases/:tag_name/evidence
```

| 속성     | 유형           | 필수 | 설명                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `tag_name`    | 문자열         | 예      | 릴리스가 연결된 Git 태그입니다.                                         |

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/evidence"
```

응답 예:

```json
200
```

## 릴리스 업데이트 {#update-a-release}

{{< history >}}

- GitLab 14.5에서 `JOB-TOKEN`를 허용하도록 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72448)되었습니다.

{{< /history >}}

릴리스를 업데이트합니다. 릴리스를 업데이트하려면 프로젝트에 대한 개발자 수준 액세스가 필요합니다.

```plaintext
PUT /projects/:id/releases/:tag_name
```

| 속성     | 유형            | 필수 | 설명                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | 정수 또는 문자열  | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths).                         |
| `tag_name`    | 문자열          | 예      | 릴리스가 연결된 Git 태그입니다.                                                                 |
| `name`        | 문자열          | 아니오       | 릴리스 이름입니다.                                                                                           |
| `description` | 문자열          | 아니오       | 릴리스의 설명입니다. [마크다운](../../user/markdown.md)을 사용할 수 있습니다.                             |
| `milestones`  | 문자열 배열 | 아니오       | 릴리스와 연결할 각 마일스톤의 제목입니다. [GitLab Premium](https://about.gitlab.com/pricing/) 고객은 그룹 마일스톤을 지정할 수 있습니다. 릴리스에서 모든 마일스톤을 제거하려면 `[]`을(를) 지정합니다. |
| `released_at` | 날짜/시간        | 아니오       | 릴리스가 준비되었거나 준비된 날짜입니다. ISO 8601 형식으로 예상됩니다 (`2019-03-15T08:00:00Z`).          |

요청 예시:

```shell
curl --header 'Content-Type: application/json' --request PUT --data '{"name": "new name", "milestones": ["v1.2"]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

응답 예:

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"new name",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "milestones": [
      {
         "id":53,
         "iid":3,
         "project_id":24,
         "title":"v1.2",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"active",
         "created_at":"2019-09-01T13:00:00.256Z",
         "updated_at":"2019-09-01T13:00:00.256Z",
         "due_date":"2019-09-20",
         "start_date":"2019-09-05",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/3",
         "issue_stats": {
            "opened": 11,
            "closed": 78
         }
      }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":4,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[

      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
   }
}
```

## 릴리스 삭제 {#delete-a-release}

{{< history >}}

- GitLab 11.7에서 [도입](https://gitlab.com/gitlab-org/gitlab-foss/-/work_items/41766)되었습니다.

{{< /history >}}

릴리스를 삭제합니다. 릴리스를 삭제해도 연결된 태그는 삭제되지 않습니다. 프로젝트에 대해 최소한 개발자 역할이 필요합니다.

```plaintext
DELETE /projects/:id/releases/:tag_name
```

| 속성     | 유형           | 필수 | 설명                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](../rest/_index.md#namespaced-paths). |
| `tag_name`    | 문자열         | 예      | 릴리스가 연결된 Git 태그입니다.                                         |

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

응답 예:

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"new name",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":4,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[

      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
   }
}
```

## 예정된 릴리스 {#upcoming-releases}

`released_at` 특성이 미래 날짜로 설정된 릴리스는 **예정된 릴리스**로 표시됩니다 [UI](../../user/project/releases/_index.md#upcoming-releases)에서.

추가로, [API에서 릴리스를 요청](#list-releases)하면 `release_at` 특성이 미래 날짜로 설정된 각 릴리스에 대해 `upcoming_release` (true로 설정) 추가 특성이 응답의 일부로 반환됩니다.

## 과거 릴리스 {#historical-releases}

{{< history >}}

- GitLab 15.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/199429)되었습니다.

{{< /history >}}

`released_at` 특성이 과거 날짜로 설정된 릴리스는 **과거 릴리스**로 표시됩니다 [UI](../../user/project/releases/_index.md#historical-releases)에서.

추가로, [API에서 릴리스를 요청](#list-releases)하면 `release_at` 특성이 과거 날짜로 설정된 각 릴리스에 대해 `historical_release` (true로 설정) 추가 특성이 응답의 일부로 반환됩니다.
