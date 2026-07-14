---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Markdown API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [필수 인증](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93727) 을 GitLab 15.3에서 소개했습니다. [플래그](../administration/feature_flags/_index.md)의 이름은 `authenticate_markdown_api`입니다. 기본적으로 활성화됨.

{{< /history >}}

이 API를 사용하여 [Markdown](../user/markdown.md) 콘텐츠를 HTML로 렌더링합니다.

이 API의 모든 요청은 [인증](rest/authentication.md)되어야 합니다.

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 테스트용으로 사용할 수 있지만, 프로덕션 환경에서 사용할 준비가 되지 않았습니다.

## Markdown 콘텐츠 렌더링 {#render-markdown-content}

Markdown 콘텐츠를 HTML로 렌더링합니다.

```plaintext
POST /markdown
```

| 속성 | 유형    | 필수      | 설명                                |
| --------- | ------- | ------------- | ------------------------------------------ |
| `text`    | 문자열  | 예           | 렌더링할 Markdown 텍스트                |
| `gfm`     | 부울 | 아니요            | GitLab Flavored Markdown을 사용하여 텍스트를 렌더링합니다. 기본값은 `false` |
| `project` | 문자열  | 아니요            | `project`을(를) GitLab Flavored Markdown을 사용하여 참조를 생성할 때의 컨텍스트로 사용합니다  |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type:application/json" \
  --data '{"text":"Hello world! :tada:", "gfm":true, "project":"group_example/project_example"}' "https://gitlab.example.com/api/v4/markdown"
```

응답 예:

```json
{ "html": "<p dir=\"auto\">Hello world! <gl-emoji title=\"party popper\" data-name=\"tada\" data-unicode-version=\"6.0\">🎉</gl-emoji></p>" }
```
