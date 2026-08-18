---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Organizations API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  실험적 기능

{{< /details >}}

이 API를 사용하여 GitLab 조직과 상호 작용합니다. 자세한 정보는 [조직](../user/organization/_index.md)을 참조하세요.

## 조직 생성 {#create-an-organization}

{{< history >}}

- GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/470613)되었으며 `allow_organization_creation`이라는 [기능 플래그](../administration/feature_flags/_index.md)를 포함합니다. 기본적으로 비활성화됨. 이 기능은 [실험](../policy/development_stages_support.md) 단계입니다.
- GitLab 18.4에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/549062)되었습니다. `allow_organization_creation` 기능 플래그가 통합되고 `organization_switching`으로 이름이 변경되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

조직을 생성합니다.

이 끝점은 [실험](../policy/development_stages_support.md) 단계이며 예고 없이 변경되거나 제거될 수 있습니다.

```plaintext
POST /organizations
```

매개변수:

| 속성     | 유형   | 필수 | 설명                           |
|---------------|--------|----------|---------------------------------------|
| `name`        | 문자열 | 예      | 조직의 이름          |
| `path`        | 문자열 | 예      | 조직의 경로          |
| `description` | 문자열 | 아니요       | 조직의 설명   |
| `avatar`      | 파일   | 아니요       | 조직의 아바타 이미지 |

요청 예시:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--form "name=New Organization" \
--form "path=new-org" \
--form "description=A new organization" \
--form "avatar=@/path/to/avatar.png" \
"https://gitlab.example.com/api/v4/organizations"
```

응답 예시:

```json
{
  "id": 42,
  "name": "New Organization",
  "path": "new-org",
  "description": "A new organization",
  "created_at": "2024-09-18T02:35:15.371Z",
  "updated_at": "2024-09-18T02:35:15.371Z",
  "web_url": "https://gitlab.example.com/o/new-org/-/overview",
  "avatar_url": "https://gitlab.example.com/uploads/-/system/organizations/organization_detail/avatar/42/avatar.png"
}
```
