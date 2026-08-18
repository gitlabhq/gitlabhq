---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 배포 키 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [배포 키](../user/project/deploy_keys/_index.md)와 상호 작용합니다.

## 배포 키 지문 {#deploy-key-fingerprints}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91302) `fingerprint_sha256` 속성이 GitLab 15.2에 추가되었습니다.

{{< /history >}}

일부 엔드포인트는 응답의 일부로 공개 키 지문을 반환합니다. 이러한 지문을 사용하여 배포 키를 생성한 사용자를 식별할 수 있습니다. 자세한 내용은 [배포 키 지문으로 사용자 가져오기](keys.md#retrieve-user-by-deploy-key-fingerprint)를 참조하세요.

다음 속성에 배포 키 지문이 포함됩니다:

- `fingerprint`:  MD5 해시를 사용합니다. FIPS 활성화 시스템에서는 사용할 수 없습니다.
- `fingerprint_sha256`:  SHA256 해시를 사용합니다.

## 모든 배포 키 나열 {#list-all-deploy-keys}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `projects_with_readonly_access` [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119147) GitLab 16.0에서

{{< /history >}}

GitLab 인스턴스의 모든 프로젝트에서 모든 배포 키의 목록을 가져옵니다. 이 엔드포인트는 관리자 액세스가 필요하며 GitLab.com에서는 사용할 수 없습니다.

```plaintext
GET /deploy_keys
```

지원되는 속성:

| 속성   | 유형     | 필수 | 설명           |
|:------------|:---------|:---------|:----------------------|
| `public` | 부울 | 아니요 | 공개 배포 키만 반환합니다. `false`로 기본값이 설정됩니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/deploy_keys?public=true"
```

응답 예시:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
    "created_at": "2013-10-02T10:12:29Z",
    "expires_at": null,
    "projects_with_write_access": [
      {
        "id": 73,
        "description": null,
        "name": "project2",
        "name_with_namespace": "Sidney Jones / project2",
        "path": "project2",
        "path_with_namespace": "sidney_jones/project2",
        "created_at": "2021-10-25T18:33:17.550Z"
      },
      {
        "id": 74,
        "description": null,
        "name": "project3",
        "name_with_namespace": "Sidney Jones / project3",
        "path": "project3",
        "path_with_namespace": "sidney_jones/project3",
        "created_at": "2021-10-25T18:33:17.666Z"
      }
    ],
    "projects_with_readonly_access": []
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDIJFwIL6YNcCgVBLTHgM6hzmoL5vf0ThDKQMWT3HrwCjUCGPwR63vBwn6+/Gx+kx+VTo9FuojzR0O4XfwD3LrYA+oT3ETbn9U4e/VS4AH/G4SDMzgSLwu0YuPe517FfGWhWGQhjiXphkaQ+6bXPmcASWb0RCO5+pYlGIfxv4eFGQ==",
    "fingerprint": "0b:cf:58:40:b9:23:96:c7:ba:44:df:0e:9e:87:5e:75",
    "": "SHA256:lGI/Ys/Wx7PfMhUO1iuBH92JQKYN+3mhJZvWO4Q5ims",
    "created_at": "2013-10-02T11:12:29Z",
    "expires_at": null,
    "projects_with_write_access": [],
    "projects_with_readonly_access": [
      {
        "id": 74,
        "description": null,
        "name": "project3",
        "name_with_namespace": "Sidney Jones / project3",
        "path": "project3",
        "path_with_namespace": "sidney_jones/project3",
        "created_at": "2021-10-25T18:33:17.666Z"
      }
    ]
  }
]
```

## 배포 키 추가 {#add-deploy-key}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/478476) GitLab 17.5에서

{{< /history >}}

GitLab 인스턴스에 배포 키를 생성합니다. 이 엔드포인트는 관리자 액세스가 필요합니다.

```plaintext
POST /deploy_keys
```

지원되는 속성:

| 속성     | 유형     | 필수 | 설명                                                                                                                       |
|:--------------|:---------|:---------|:----------------------------------------------------------------------------------------------------------------------------------|
| `key`         | 문자열   | 예      | 새 배포 키                                                                                                                    |
| `title`       | 문자열   | 예      | 새 배포 키의 제목                                                                                                            |
| `expires_at`  | 날짜/시간 | 아니요       | 배포 키의 만료 날짜입니다. 값이 제공되지 않으면 만료되지 않습니다. ISO 8601 형식으로 예상됩니다(`2024-12-31T08:00:00Z`) |

요청 예시:

```shell
curl --request POST \ --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data "{"title": "My deploy key", "key": "ssh-rsa AAAA...", "expired_at": "2024-12-31T08:00:00Z"}" \
     --url "https://gitlab.example.com/api/v4/deploy_keys/"
```

응답 예시:

```json
{
  "id": 5,
  "title": "My deploy key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
  "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
  "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
  "usage_type": "auth_and_signing",
  "created_at": "2024-10-03T01:32:21.992Z",
  "expires_at": "2024-12-31T08:00:00.000Z"
}
```

## 프로젝트의 배포 키 나열 {#list-deploy-keys-for-project}

프로젝트의 배포 키 목록을 가져옵니다.

```plaintext
GET /projects/:id/deploy_keys
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys"
```

응답 예시:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
    "created_at": "2013-10-02T10:12:29Z",
    "expires_at": null,
    "can_push": false
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDIJFwIL6YNcCgVBLTHgM6hzmoL5vf0ThDKQMWT3HrwCjUCGPwR63vBwn6+/Gx+kx+VTo9FuojzR0O4XfwD3LrYA+oT3ETbn9U4e/VS4AH/G4SDMzgSLwu0YuPe517FfGWhWGQhjiXphkaQ+6bXPmcASWb0RCO5+pYlGIfxv4eFGQ==",
    "fingerprint": "0b:cf:58:40:b9:23:96:c7:ba:44:df:0e:9e:87:5e:75",
    "": "SHA256:lGI/Ys/Wx7PfMhUO1iuBH92JQKYN+3mhJZvWO4Q5ims",
    "created_at": "2013-10-02T11:12:29Z",
    "expires_at": null,
    "can_push": false
  }
]
```

## 사용자에 대한 프로젝트 배포 키 나열 {#list-project-deploy-keys-for-user}

{{< history >}}

- GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88917)되었습니다.

{{< /history >}}

지정된 사용자(요청자)와 인증된 사용자(요청 자)의 공통 [프로젝트 배포 키](../user/project/deploy_keys/_index.md#scope) 목록을 가져옵니다. **enabled project keys from the common projects of requester and requestee**만 나열합니다.

```plaintext
GET /users/:id_or_username/project_deploy_keys
```

매개변수:

| 속성          | 유형   | 필수 | 설명                                                        |
|------------------- |--------|----------|------------------------------------------------------------------- |
| `id_or_username`   | 문자열 | 예      | 프로젝트 배포 키를 가져올 사용자의 ID 또는 사용자 이름입니다. |

```json
[
  {
    "id": 1,
    "title": "Key A",
    "created_at": "2022-05-30T12:28:27.855Z",
    "expires_at": null,
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkYXU2fVeO4/0rDCSsswP5iIX2+B6tv15YT3KObgyDl Key",
    "fingerprint": "40:8e:fa:df:70:f7:a7:06:1e:0d:6f:ae:f2:27:92:01",
    "fingerprint_sha256": "SHA256:Ojq2LZW43BFK/AMP81jBkDGn9YpPWYRNcViKBB44LPU"
  },
  {
    "id": 2,
    "title": "Key B",
    "created_at": "2022-05-30T13:34:56.219Z",
    "expires_at": null,
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU"
  }
]
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/20/project_deploy_keys"
```

응답 예시:

```json
[
  {
    "id": 1,
    "title": "Key A",
    "created_at": "2022-05-30T12:28:27.855Z",
    "expires_at": "2022-10-30T12:28:27.855Z",
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkYXU2fVeO4/0rDCSsswP5iIX2+B6tv15YT3KObgyDl Key",
    "fingerprint": "40:8e:fa:df:70:f7:a7:06:1e:0d:6f:ae:f2:27:92:01",
    "fingerprint_sha256": "SHA256:Ojq2LZW43BFK/AMP81jBkDGn9YpPWYRNcViKBB44LPU"
  }
]
```

## 배포 키 검색 {#retrieve-a-deploy-key}

지정된 배포 키를 검색합니다.

```plaintext
GET /projects/:id/deploy_keys/:key_id
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `key_id`  | 정수 | 예 | 배포 키의 ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
```

응답 예시:

```json
{
  "id": 1,
  "title": "Public key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
  "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
  "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
  "created_at": "2013-10-02T10:12:29Z",
  "expires_at": null,
  "can_push": false
}
```

## 프로젝트에 배포 키 추가 {#add-a-deploy-key-for-a-project}

지정된 프로젝트에 배포 키를 추가합니다.

배포 키가 이미 다른 프로젝트에 있으면, 원본이 동일한 사용자가 액세스할 수 있는 경우에만 현재 프로젝트에 조인됩니다.

```plaintext
POST /projects/:id/deploy_keys
```

| 속성    | 유형 | 필수 | 설명 |
| -----------  | ---- | -------- | ----------- |
| `id`         | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `key`        | 문자열   | 예 | 새 배포 키 |
| `title`      | 문자열   | 예 | 새 배포 키의 제목 |
| `can_push`   | 부울  | 아니요  | 배포 키가 프로젝트의 리포지토리에 푸시할 수 있습니다 |
| `expires_at` | 날짜/시간 | 아니요 | 배포 키의 만료 날짜입니다. 값이 제공되지 않으면 만료되지 않습니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data "{"title": "My deploy key", "key": "ssh-rsa AAAA...", "can_push": "true"}" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/"
```

응답 예시:

```json
{
  "key": "ssh-rsa AAAA...",
  "id": 12,
  "title": "My deploy key",
  "can_push": true,
  "created_at": "2015-08-29T12:44:31.550Z",
  "expires_at": null
}
```

## 배포 키 업데이트 {#update-a-deploy-key}

프로젝트의 배포 키를 업데이트합니다.

```plaintext
PUT /projects/:id/deploy_keys/:key_id
```

| 속성  | 유형 | 필수 | 설명 |
| ---------  | ---- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `can_push` | 부울 | 아니요  | 배포 키가 프로젝트의 리포지토리에 푸시할 수 있습니다 |
| `title`    | 문자열  | 아니요 | 새 배포 키의 제목 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data "{"title": "New deploy key", "can_push": true}" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
```

응답 예시:

```json
{
  "id": 11,
  "title": "New deploy key",
  "key": "ssh-rsa AAAA...",
  "created_at": "2015-08-29T12:44:31.550Z",
  "expires_at": null,
  "can_push": true
}
```

## 배포 키 삭제 {#delete-a-deploy-key}

프로젝트에서 배포 키를 제거합니다. 배포 키가 이 프로젝트에만 사용되면 시스템에서 삭제됩니다.

```plaintext
DELETE /projects/:id/deploy_keys/:key_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `key_id`  | 정수 | 예 | 배포 키의 ID |

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/13"
```

## 배포 키 활성화 {#enable-a-deploy-key}

프로젝트의 배포 키를 활성화하여 사용할 수 있도록 합니다. 성공하면 활성화된 키를 반환하고 상태 코드 201을 반환합니다.

```plaintext
POST /projects/:id/deploy_keys/:key_id/enable
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `key_id`  | 정수 | 예 | 배포 키의 ID |

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/deploy_keys/12/enable"
```

응답 예시:

```json
{
  "key": "ssh-rsa AAAA...",
  "id": 12,
  "title": "My deploy key",
  "created_at": "2015-08-29T12:44:31.550Z",
  "expires_at": null
}
```

## 여러 프로젝트에 배포 키 추가 {#add-deploy-keys-to-multiple-projects}

동일한 그룹의 여러 프로젝트에 동일한 배포 키를 추가하려면 API를 사용하여 이를 수행할 수 있습니다.

먼저 관심 있는 프로젝트의 ID를 찾으세요. 모든 프로젝트를 나열하여:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects"
```

또는 그룹의 ID를 찾습니다:

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups"
```

그런 다음 해당 그룹의 모든 프로젝트를 나열합니다(예: 그룹 1234):

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/1234"
```

이러한 ID를 사용하여 모든 ID에 동일한 배포 키를 추가합니다:

```shell
for project_id in 321 456 987; do
    curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
         --header "Content-Type: application/json" \
         --data "{"title": "my key", "key": "ssh-rsa AAAA..."}" \
         "https://gitlab.example.com/api/v4/projects/${project_id}/deploy_keys"
done
```
