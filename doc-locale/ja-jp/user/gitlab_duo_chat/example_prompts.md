---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chatプロンプトの例
---

GitLab Duo Chat（エージェント）は、複数のファイルまたはGitLabリソースからの情報を必要とする質問に答えるのに役立ちます。お客様のコードベースに関する質問に答えることができ、正確なファイルパスを指定する必要はありません。また、イシューやマージリクエストのステータスを把握し、ファイルを作成および編集することもできます。

## プロジェクトの詳細について {#learn-more-about-your-projects}

GitLab Duo Chatは、自然言語の質問でよく機能します。プロジェクトのあらゆる側面について、一般的なことから具体的なことまで質問してください。

- `Read the project structure and explain it to me`、または`Explain the project`。
- `Find the API endpoints that handle user authentication in this codebase`。
- `Please explain the authorization flow for <application name>`。
- `How do I add a GraphQL mutation in this repository?`
- `Show me how error handling is implemented across our application`。
- `Component <component name> has methods for <x> and <y>. Could you split it into two components?`
- `Do merge request <MR URL> and merge request <MR URL> fully address this issue <issue URL>?`

## チャットに作業を任せる {#have-chat-do-the-work-for-you}

何をしたいのかすでにわかっている場合は、チャットが作業を行うことができます。

- `Add a GraphQL mutation that lets users query my application.`
- `Implement error handling for my application`。
- `Component <component name> has methods for <x> and <y>. Split it into two components.`
- `Add inline documentation for all Java files in <directory>.`
- `Create a merge request to address this issue: <issue URL>.`

## チャットを使用してセキュリティの脆弱性に対処する {#use-chat-to-address-security-vulnerabilities}

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Dedicated

{{< /details >}}

チャットを使用して、自然言語コマンドを通じて脆弱性のトリアージ、管理、および修正を行います。

脆弱性情報と分析:

- `List all vulnerabilities in a project with filtering by severity and report types.`
- `Get detailed vulnerability information including CVE data, EPSS scores, and reachability analysis.`
- `Show me all critical vulnerabilities in my project.`
- `List vulnerabilities with EPSS scores above 0.7 that are reachable.`

脆弱性管理:

- `Mark this vulnerability as a genuine security issue.`
- `Revert vulnerability status back to detected for re-assessment.`
- `Dismiss all dependency scanning vulnerabilities marked as false positives with unreachable code.`
- `Show me vulnerabilities dismissed in the past week with their reasoning.`
- `Confirm all container scanning vulnerabilities with known exploits.`
- `Link vulnerability 123 to issue 456 for tracking remediation.`

イシュー管理インテグレーション:

- `Create issues for all confirmed high-severity SAST vulnerabilities and assign them to recent committers.`
- `Update severity to HIGH for all vulnerabilities that cross trust boundaries.`

セキュリティ機能の詳細については、[エピック19639](https://gitlab.com/groups/gitlab-org/-/epics/19639)を参照してください。
