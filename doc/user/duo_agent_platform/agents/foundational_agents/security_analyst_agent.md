---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Security Analyst Agent
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19659) in GitLab 18.6.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.

{{< /history >}}

The Security Analyst Agent is a specialized AI assistant that helps with vulnerability management
and security analysis workflows in GitLab. It combines security expertise with deep knowledge of GitLab
security features, vulnerability reports, security dashboards, and compliance tools to help you
efficiently triage, assess, and remediate security findings.

Use the Security Analyst Agent when you need assistance with:

- Vulnerability triage: Analyze and prioritize security findings across different scan types.
- Risk assessment: Evaluate the severity, exploitability, and business impact of vulnerabilities.
- False positive identification: Distinguish genuine threats from benign findings.
- Compliance management: Understand regulatory requirements and remediation timelines.
- Security reporting: Generate summaries of security posture and remediation progress.
- Remediation planning: Create actionable plans to address security vulnerabilities.
- Security workflow automation: Streamline repetitive security assessment tasks.

The Security Analyst Agent understands GitLab-specific security implementations, including
vulnerability states, severity levels, and security scanner outputs. It can interpret EPSS scores,
CVE data, and reachability analysis to provide contextual security guidance.

## Use the Security Analyst Agent

You can use the Security Analyst Agent in the GitLab UI, VS Code, and JetBrains IDEs.

### In the GitLab UI

Prerequisites:

- Use a GitLab project with security scanning enabled.
- [Turn on](_index.md#turn-foundational-agents-on-or-off) foundational agents.

To use the Security Analyst Agent in the GitLab UI:

1. On the top bar, select **Search or go to** and find your project.

1. On the GitLab Duo sidebar, select either **New GitLab Duo Chat**
   ({{< icon name="pencil-square" >}}) or **Current GitLab Duo Chat**
   ({{< icon name="duo-chat" >}}).

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your
   screen.

1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select **Security Analyst**.
1. Enter your security-related question or request. To get the best results from your request:

   - Provide context about your security requirements and risk tolerance.
   - Specify which types of vulnerabilities or scan results you're focusing on.
   - Include relevant project or component details when asking for analysis.
   - Ask for clarification if the Security Analyst Agent's recommendations do not align with your security policies.
   - Use specific vulnerability IDs or URLs when discussing particular findings.

### In VS Code

Prerequisites:

- Use a GitLab project with security scanning enabled.
- [Turn on](_index.md#turn-foundational-agents-on-or-off) foundational agents.
- Install and configure [GitLab for VS Code](../../../../editor_extensions/visual_studio_code/setup.md)
  version 8.39.0 or later.
- Set a [default GitLab Duo namespace](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace).

To use the Security Analyst Agent in VS Code:

1. In VS Code, on the left sidebar, select **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select **Security Analyst**.
1. Enter your security-related question or request. To get the best results from your request:

   - Provide context about your security requirements and risk tolerance.
   - Specify which types of vulnerabilities or scan results you're focusing on.
   - Include relevant project or component details when asking for analysis.
   - Ask for clarification if the Security Analyst Agent's recommendations do not align with your security policies.
   - Use specific vulnerability IDs or URLs when discussing particular findings.

### In JetBrains IDEs

Prerequisites:

- Use a GitLab project with security scanning enabled.
- [Turn on](_index.md#turn-foundational-agents-on-or-off) foundational agents.
- Install and configure [GitLab plugin for JetBrains](../../../../editor_extensions/jetbrains_ide/setup.md)
  version 3.11.1 or later.
- Set a [default GitLab Duo namespace](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace).

First, enable the GitLab Duo Agent Platform:

1. In your JetBrains IDE, go to **Settings** > **Tools** > **GitLab Duo**.
1. Under **GitLab Duo Agent Platform**, select the **Enable GitLab Duo Agent Platform** checkbox.
1. Restart your IDE if prompted.

Then, to use the Security Analyst Agent:

1. In your JetBrains IDE, on the right tool window bar, select **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select **Security Analyst**.
1. Enter your security-related question or request. To get the best results from your request:

   - Provide context about your security requirements and risk tolerance.
   - Specify which types of vulnerabilities or scan results you're focusing on.
   - Include relevant project or component details when asking for analysis.
   - Ask for clarification if the Security Analyst Agent's recommendations do not align with your security policies.
   - Use specific vulnerability IDs or URLs when discussing particular findings.

## Example prompts

- Vulnerability analysis:
  - "Show me all critical vulnerabilities in my project."
  - "List vulnerabilities with EPSS scores above 0.7 that are reachable."
  - "Which SAST findings should I prioritize based on exploitability?"
  - "Analyze the security impact of vulnerabilities in (component name)."
  - "Compare vulnerability trends between this release and the previous one."
- Risk assessment:
  - "What's the business risk of these container scanning findings?"
  - "Help me assess if this dependency vulnerability affects our use case."
  - "Evaluate the severity of vulnerabilities that cross trust boundaries."
  - "Which vulnerabilities pose the highest risk to production?"
- Triage and management:
  - "Dismiss all dependency scanning vulnerabilities marked as false positives with unreachable code."
  - "Confirm all container scanning vulnerabilities with known exploit."
  - "Update severity to HIGH for all vulnerabilities that cross trust boundaries."
  - "Show me vulnerabilities dismissed in the past week, with their reasoning."
  - "Revert vulnerability status back to detected for re-assessment."
- Issue management:
  - "Create issues for all confirmed high-severity SAST vulnerabilities and assign them to recent committers"
  - "Link vulnerability (vulnerability ID) to issue (issue ID) for tracking remediation."
  - "Generate remediation tasks for critical infrastructure vulnerabilities."
  - "Create a security epic to track all authentication-related vulnerabilities."
- Reporting and compliance:
  - "Generate an executive summary of our current security posture."
  - "Draft a compliance report showing remediation progress."
  - "Summarize security findings for the security review board."
  - "Create a timeline for addressing all high-severity findings."
- Remediation guidance:
  - "Suggest remediation approaches for these SQL injection vulnerabilities."
  - "What's the recommended fix for this container base image vulnerability?"
  - "Help me prioritize security patches for the next sprint."
  - "Provide guidance on secure coding practices to prevent these issues."
