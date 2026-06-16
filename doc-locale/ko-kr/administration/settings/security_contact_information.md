---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 공개 보안 연락처 정보 제공
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 16.7에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/433210).

{{< /history >}}

조직은 공개 연락처 정보를 제공하여 보안 이슈의 책임감 있는 공개를 용이하게 할 수 있습니다. GitLab은 이 목적으로 [`security.txt`](https://securitytxt.org/) 파일을 사용하도록 지원합니다.

관리자는 GitLab UI 또는 [REST API](../../api/settings.md#update-application-settings)를 사용하여 `security.txt` 파일을 추가할 수 있습니다. 추가된 모든 콘텐츠는 `https://gitlab.example.com/.well-known/security.txt`에서 사용할 수 있습니다. 이 파일을 보기 위해 인증이 필요하지 않습니다.

`security.txt` 파일을 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **보안 연락처 정보 추가**를 확장합니다.
1. **security.txt 내용**에서 <https://securitytxt.org/>에 문서화된 형식으로 보안 연락처 정보를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

보고서를 받은 경우 응답 방법에 대한 정보는 [보안 사건에 대응](../../security/responding_to_security_incidents.md)을 참조하세요.

## `security.txt` 파일 예제 {#example-securitytxt-file}

이 정보의 형식은 <https://securitytxt.org/>에 문서화되어 있습니다. `security.txt` 파일의 예는 다음과 같습니다:

```plaintext
Contact: mailto:security@example.com
Expires: 2024-12-31T23:59Z
```
