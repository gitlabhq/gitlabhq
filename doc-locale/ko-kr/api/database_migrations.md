---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 데이터베이스 마이그레이션 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [GitLab 16.2에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123408)

{{< /history >}}

이 API를 사용하여 GitLab 데이터베이스 마이그레이션을 관리합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

## 마이그레이션을 성공으로 표시 {#mark-a-migration-as-successful}

보류 중인 마이그레이션을 성공적으로 실행된 것으로 표시하여 `db:migrate` 작업에서 실행되지 않도록 합니다. 이 API를 사용하여 안전하다고 판단한 후 실패한 마이그레이션을 건너뜁니다.

```plaintext
POST /api/v4/admin/migrations/:version/mark
```

| 속성       | 유형           | 필수 | 설명                                                                                                                                                                                      |
|-----------------|----------------|----------|----------------------------------------------------------------------------------|
| `version`       | 정수        | 예      | 건너뛸 마이그레이션의 버전 타임스탬프                                 |
| `database`      | 문자열         | 아니요       | 마이그레이션이 건너뛰어지는 데이터베이스 이름입니다. `main`로 기본값이 설정됩니다.        |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/admin/migrations/:version/mark"
```

## 보류 중인 마이그레이션 나열 {#list-pending-migrations}

지정된 데이터베이스에 대한 모든 보류 중인(아직 실행되지 않은) 마이그레이션의 목록을 반환합니다.

```plaintext
GET /api/v4/admin/migrations/pending
```

| 속성       | 유형           | 필수 | 설명                                                                      |
|-----------------|----------------|----------|-----------------------------------------------------------------------------------|
| `database`      | 문자열         | 아니요       | 쿼리할 데이터베이스 이름입니다. `main`로 기본값이 설정됩니다.                                  |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/admin/migrations/pending?database=main"
```

응답 예시:

```json
{
  "pending_migrations": [
    {
      "version": 20240101120000,
      "name": "create_users_table",
      "filename": "20240101120000_create_users_table.rb",
      "status": "pending"
    },
    {
      "version": 20240102150000,
      "name": "add_email_to_users",
      "filename": "20240102150000_add_email_to_users.rb",
      "status": "pending"
    }
  ],
  "database": "main",
  "total_pending": 2
}
```
