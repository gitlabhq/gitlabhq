---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 라이선스 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 라이선스 엔드포인트와 상호작용합니다. 자세한 내용은 [라이선스 파일 또는 키로 GitLab EE 활성화](../administration/license_file.md)를 참조하세요.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

## 라이선스 정보 검색 {#retrieve-license-information}

현재 라이선스에 대한 정보를 검색합니다.

```plaintext
GET /license
```

```json
{
  "id": 2,
  "plan": "ultimate",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 300,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

## 모든 라이선스 나열 {#list-all-licenses}

모든 라이선스에 대한 정보를 나열합니다.

```plaintext
GET /licenses
```

```json
[
  {
    "id": 1,
    "plan": "premium",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "John Doe1",
      "Email": "johndoe1@gitlab.com",
      "Company": "GitLab"
    },
    "add_ons": {
      "GitLab_FileLocks": 1,
      "GitLab_Auditor_User": 1
    }
  },
  {
    "id": 2,
    "plan": "ultimate",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "Doe John",
      "Email": "doejohn@gitlab.com",
      "Company": "GitLab"
    },
    "add_ons": {
      "GitLab_FileLocks": 1
    }
  }
]
```

초과분은 청구 가능한 사용자 수와 라이선스된 사용자 수의 차이입니다. 이는 라이선스의 만료 여부에 따라 다르게 계산됩니다.

- 라이선스가 만료된 경우 최대 청구 가능한 사용자 수 히스토리(`historical_max`)를 사용합니다.
- 라이선스가 만료되지 않은 경우 현재 청구 가능한 사용자 수를 사용합니다.

반환값:

- `200 OK` - JSON 형식의 라이선스가 포함된 응답입니다. 라이선스가 없으면 빈 JSON 배열입니다.
- 현재 사용자가 라이선스를 읽을 수 없는 경우 `403 Forbidden`입니다.

## 라이선스 검색 {#retrieve-a-license}

지정된 라이선스에 대한 정보를 검색합니다.

```plaintext
GET /license/:id
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명               |
|-----------|---------|----------|---------------------------|
| `id`      | 정수 | 예      | GitLab 라이선스의 ID입니다. |

다음 상태 코드를 반환합니다:

- `200 OK`:  JSON 형식의 라이선스가 포함된 응답입니다.
- `404 Not Found`:  요청한 라이선스가 존재하지 않습니다.
- `403 Forbidden`:  현재 사용자가 라이선스를 읽을 수 없습니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license/:id"
```

응답 예시:

```json
{
  "id": 1,
  "plan": "premium",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 50,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

## 라이선스 생성 {#create-a-license}

새 라이선스를 생성합니다.

```plaintext
POST /license
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `license` | 문자열 | 예 | 라이선스 문자열 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license?license=eyJkYXRhIjoiMHM5Q...S01Udz09XG4ifQ=="
```

응답 예시:

```json
{
  "id": 1,
  "plan": "ultimate",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 300,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

반환값:

- 라이선스가 성공적으로 추가된 경우 `201 Created`입니다.
- 라이선스를 추가할 수 없는 경우 `400 Bad Request` - 이유를 설명하는 오류 메시지와 함께 반환됩니다.

## 라이선스 삭제 {#delete-a-license}

지정된 라이선스를 삭제합니다.

```plaintext
DELETE /license/:id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | GitLab 라이선스의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license/:id"
```

반환값:

- 라이선스가 성공적으로 삭제된 경우 `204 No Content`입니다.
- 현재 사용자가 라이선스를 삭제할 수 없는 경우 `403 Forbidden`입니다.
- 삭제할 라이선스를 찾을 수 없는 경우 `404 Not Found`입니다.

## 청구 가능한 사용자 재계산 트리거 {#trigger-recalculation-of-billable-users}

지정된 라이선스에 대한 청구 가능한 사용자 재계산을 트리거합니다.

```plaintext
PUT /license/:id/refresh_billable_users
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | GitLab 라이선스의 ID입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license/:id/refresh_billable_users"
```

응답 예시:

```json
{
  "success": true
}
```

반환값:

- 청구 가능한 사용자 새로 고침 요청이 성공적으로 시작된 경우 `202 Accepted`입니다.
- 현재 사용자가 라이선스에 대한 청구 가능한 사용자를 새로 고칠 수 없는 경우 `403 Forbidden`입니다.
- 라이선스를 찾을 수 없는 경우 `404 Not Found`입니다.

| 속성                    | 유형          | 설명                               |
|:-----------------------------|:--------------|:------------------------------------------|
| `success`                    | 부울       | 요청이 성공했는지 여부입니다.     |

## 라이선스 사용 정보 검색 {#retrieve-license-usage-information}

현재 라이선스에 대한 사용 정보를 검색하고 CSV 형식으로 내보냅니다.

```plaintext
GET /license/usage_export.csv
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license/usage_export.csv"
```

응답 예시:

```plaintext
License Key,"eyJkYXRhIjoib1EwRWZXU3RobDY2Yl=
"
Email,user@example.com
License Start Date,2023-02-22
License End Date,2024-02-22
Company,Example Corp.
Generated At,2023-09-05 06:56:23
"",""
Date,Billable User Count
2023-07-11 12:00:05,21
2023-07-13 12:00:06,21
2023-08-16 12:00:02,21
2023-09-04 12:00:12,21
```

반환값:

- `200 OK`:  CSV 형식의 라이선스 사용 정보가 포함된 응답입니다.
- 현재 사용자가 라이선스 사용을 볼 수 없는 경우 `403 Forbidden`입니다.
