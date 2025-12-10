---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chat prompt examples
---

GitLab Duo Chat (Agentic) can help you answer questions that require information from multiple files or GitLab resources.
It can answer questions about your codebase, and you don't need to specify exact file paths.
It can also understand the status of issues or merge requests, and create and edit files.

## Learn more about your projects

GitLab Duo Chat works best with natural language questions.
Ask it about any aspect of your project, from the general to the specific.

- `Read the project structure and explain it to me`, or `Explain the project`.
- `Find the API endpoints that handle user authentication in this codebase`.
- `Please explain the authorization flow for <application name>`.
- `How do I add a GraphQL mutation in this repository?`
- `Show me how error handling is implemented across our application`.
- `Component <component name> has methods for <x> and <y>. Could you split it into two components?`
- `Do merge request <MR URL> and merge request <MR URL> fully address this issue <issue URL>?`

## Have Chat do the work for you

If you already know what you want to do, Chat can do the work for you.

- `Add a GraphQL mutation that lets users query my application.`
- `Implement error handling for my application`.
- `Component <component name> has methods for <x> and <y>. Split it into two components.`
- `Add inline documentation for all Java files in <directory>.`
- `Create a merge request to address this issue: <issue URL>.`

## Use Chat to address security vulnerabilities

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Dedicated

{{< /details >}}

Use Chat to triage, manage, and remediate vulnerabilities through natural language commands.

For vulnerability information and analysis:

- `List all vulnerabilities in a project with filtering by severity and report types.`
- `Get detailed vulnerability information including CVE data, EPSS scores, and reachability analysis.`
- `Show me all critical vulnerabilities in my project.`
- `List vulnerabilities with EPSS scores above 0.7 that are reachable.`

For vulnerability management:

- `Mark this vulnerability as a genuine security issue.`
- `Revert vulnerability status back to detected for re-assessment.`
- `Dismiss all dependency scanning vulnerabilities marked as false positives with unreachable code.`
- `Show me vulnerabilities dismissed in the past week with their reasoning.`
- `Confirm all container scanning vulnerabilities with known exploits.`
- `Link vulnerability 123 to issue 456 for tracking remediation.`

For issue management integration:

- `Create issues for all confirmed high-severity SAST vulnerabilities and assign them to recent committers.`
- `Update severity to HIGH for all vulnerabilities that cross trust boundaries.`

For more information about security capabilities, see [epic 19639](https://gitlab.com/groups/gitlab-org/-/epics/19639).
