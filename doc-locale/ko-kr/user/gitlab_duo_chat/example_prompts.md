---
stage: AI Clients
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo Chat 프롬프트 예시
---

GitLab Duo 에이전틱 Chat은 여러 파일이나 GitLab 리소스의 정보가 필요한 질문에 답변하는 데 도움이 됩니다. 코드베이스에 대한 질문에 답변할 수 있으며, 정확한 파일 경로를 지정할 필요가 없습니다. 이슈 또는 머지 리퀘스트의 상태를 파악하고 파일을 생성 및 편집할 수도 있습니다.

## 프로젝트에 대해 더 알아보기 {#learn-more-about-your-projects}

GitLab Duo Chat은 자연 언어 질문으로 가장 잘 작동합니다. 프로젝트의 모든 측면에 대해, 일반적인 것부터 구체적인 것까지 질문하세요.

- `Read the project structure and explain it to me` 또는 `Explain the project`.
- `Find the API endpoints that handle user authentication in this codebase`.
- `Please explain the authorization flow for <application name>`.
- `How do I add a GraphQL mutation in this repository?`
- `Show me how error handling is implemented across our application`.
- `Component <component name> has methods for <x> and <y>. Could you split it into two components?`
- `Do merge request <MR URL> and merge request <MR URL> fully address this issue <issue URL>?`

## Chat이 작업을 대신하도록 하세요 {#have-chat-do-the-work-for-you}

원하는 작업을 이미 알고 있다면 Chat이 작업을 대신할 수 있습니다.

- `Add a GraphQL mutation that lets users query my application.`
- `Implement error handling for my application`.
- `Component <component name> has methods for <x> and <y>. Split it into two components.`
- `Add inline documentation for all Java files in <directory>.`
- `Create a merge request to address this issue: <issue URL>.`

## Chat을 사용하여 보안 취약성을 해결하세요 {#use-chat-to-address-security-vulnerabilities}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Dedicated

{{< /details >}}

Chat을 사용하여 자연 언어 명령어를 통해 취약성을 분류, 관리 및 해결합니다.

취약성 정보 및 분석의 경우:

- `List all vulnerabilities in a project with filtering by severity and report types.`
- `Get detailed vulnerability information including CVE data, EPSS scores, and reachability analysis.`
- `Show me all critical vulnerabilities in my project.`
- `List vulnerabilities with EPSS scores above 0.7 that are reachable.`

취약성 관리의 경우:

- `Mark this vulnerability as a genuine security issue.`
- `Revert vulnerability status back to detected for re-assessment.`
- `Dismiss all dependency scanning vulnerabilities marked as false positives with unreachable code.`
- `Show me vulnerabilities dismissed in the past week with their reasoning.`
- `Confirm all container scanning vulnerabilities with known exploits.`
- `Link vulnerability 123 to issue 456 for tracking remediation.`

이슈 관리 통합의 경우:

- `Create issues for all confirmed high-severity SAST vulnerabilities and assign them to recent committers.`
- `Update severity to HIGH for all vulnerabilities that cross trust boundaries.`

보안 기능에 대한 자세한 내용은 [에픽 19639](https://gitlab.com/groups/gitlab-org/-/epics/19639)를 참조하세요.
