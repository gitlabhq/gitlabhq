---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 저장소 서브모듈 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [Git 서브모듈](https://git-scm.com/book/en/v2/Git-Tools-Submodules)을 업데이트합니다.

## 서브모듈 참조 업데이트 {#update-a-submodule-reference}

서브모듈의 참조를 업데이트합니다. 이를 사용하는 다른 프로젝트를 최신 상태로 유지하기 위해 특히 자동화된 워크플로우 등 일부 워크플로우에 사용됩니다.

```plaintext
PUT /projects/:id/repository/submodules/:submodule
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `submodule` | 문자열 | 예 | 서브모듈의 URL 인코딩된 전체 경로입니다. 예를 들어, `lib%2Fclass%2Erb` |
| `branch` | 문자열 | 예 | 커밋할 브랜치의 이름 |
| `commit_sha` | 문자열 | 예 | 서브모듈을 업데이트할 전체 커밋 SHA |
| `commit_message` | 문자열 | 아니요 | 커밋 메시지. 메시지가 제공되지 않으면 기본값이 설정됩니다 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/submodules/lib%2Fmodules%2Fexample" \
  --data "branch=main" \
  --data "commit_sha=3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88" \
  --data "commit_message=Update submodule reference"
```

응답 예시:

```json
{
  "id": "ed899a2f4b50b4370feeea94676502b42383c746",
  "short_id": "ed899a2f4b5",
  "title": "Updated submodule example_submodule with oid 3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88",
  "author_name": "Dmitriy Zaporozhets",
  "author_email": "dzaporozhets@sphereconsultinginc.com",
  "committer_name": "Dmitriy Zaporozhets",
  "committer_email": "dzaporozhets@sphereconsultinginc.com",
  "created_at": "2018-09-20T09:26:24.000-07:00",
  "message": "Updated submodule example_submodule with oid 3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "committed_date": "2018-09-20T09:26:24.000-07:00",
  "authored_date": "2018-09-20T09:26:24.000-07:00",
  "status": null
}
```
