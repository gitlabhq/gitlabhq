---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Diagram proxy
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223314) in GitLab 18.10.

{{< /history >}}

Use the diagram proxy to prevent browsers from sending diagram content to external services
like Kroki or PlantUML. GitLab fetches diagrams on the user's behalf and serves
them through a one-time URL that expires after use.

## Turn on the diagram proxy

Turn on the diagram proxy separately for the [Kroki](kroki.md) and
[PlantUML](plantuml.md) integrations. You can turn on the diagram proxy for Kroki, PlantUML, or both.

Prerequisites:

- Administrator access.

To turn on the diagram proxy:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Kroki** or **PlantUML**.
1. Select the **Proxy Kroki diagrams through GitLab** or
   **Proxy PlantUML diagrams through GitLab** checkbox.
1. Select **Save changes**.
