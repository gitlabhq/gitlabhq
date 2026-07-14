---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 다이어그램 프록시
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 18.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223314)

{{< /history >}}

다이어그램 프록시를 사용하여 브라우저가 Kroki 또는 PlantUML과 같은 외부 서비스로 다이어그램 콘텐츠를 전송하는 것을 방지합니다. GitLab은 사용자 대신 다이어그램을 가져오고 사용 후 만료되는 일회용 URL을 통해 제공합니다.

## 다이어그램 프록시 켜기 {#turn-on-the-diagram-proxy}

[Kroki](kroki.md) 와 [PlantUML](plantuml.md) 통합을 위해 다이어그램 프록시를 각각 켭니다. Kroki, PlantUML 또는 둘 모두에 대해 다이어그램 프록시를 켤 수 있습니다.

전제 조건:

- 관리자 액세스

다이어그램 프록시를 켜려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을(를) 선택합니다.
1. **Kroki** 또는 **PlantUML**을 확장합니다.
1. **GitLab을 통한 Proxy Kroki 다이어그램** 또는 **GitLab을 통한 Proxy PlantUML 다이어그램** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.
