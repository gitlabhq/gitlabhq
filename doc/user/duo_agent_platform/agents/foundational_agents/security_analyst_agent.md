---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Security Analyst Agent
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19659) in GitLab 18.6.

{{< /history >}}

The GitLab Security Analyst Agent is a specialized AI assistant that helps with vulnerability management
and security analysis workflows in GitLab. It combines security expertise with deep knowledge of GitLab
security features, vulnerability reports, security dashboards, and compliance tools to help you
efficiently triage, assess, and remediate security findings.

Use the GitLab Security Analyst Agent when you need assistance with:

- Vulnerability triage: Analyze and prioritize security findings across different scan types.
- Risk assessment: Evaluate the severity, exploitability, and business impact of vulnerabilities.
- False positive identification: Distinguish genuine threats from benign findings.
- Compliance management: Understand regulatory requirements and remediation timelines.
- Security reporting: Generate summaries of security posture and remediation progress.
- Remediation planning: Create actionable plans to address security vulnerabilities.
- Security workflow automation: Streamline repetitive security assessment tasks.

The GitLab Security Analyst Agent understands GitLab-specific security implementations, including
vulnerability states, severity levels, and security scanner outputs. It can interpret EPSS scores,
CVE data, and reachability analysis to provide contextual security guidance.

### Access the GitLab Security Analyst Agent

Prerequisites:

- You must be working in a GitLab project with security scanning enabled.

1. On the left sidebar, select **Search or go to** and find your project.

   If you've [turned the new navigation on](../../../interface_redesign.md#turn-new-navigation-on-or-off),
   this field is on the top bar.

1. Open GitLab Duo Chat:

   {{< tabs >}}

   {{< tab title="New navigation" >}}

   On the GitLab Duo sidebar, select either **Current GitLab Duo Chat** ({{< icon name="comment" >}})
   or **New GitLab Duo Chat** ({{< icon name="plus" >}}).

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your screen.

   {{< /tab >}}

   {{< tab title="Classic navigation" >}}

   In the upper-right corner, select **Open GitLab Duo Chat** ({{< icon name="duo-chat" >}}).
   A drawer opens on the right side of your screen.

   {{< /tab >}}

   {{< /tabs >}}

1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select **Security Analyst Agent**.
1. Enter your security-related question or request. To get the best results from your request:

   - Provide context about your security requirements and risk tolerance.
   - Specify which types of vulnerabilities or scan results you're focusing on.
   - Include relevant project or component details when asking for analysis.
   - Ask for clarification if the Security Analyst Agent's recommendations don't align with your security policies.
   - Use specific vulnerability IDs or URLs when discussing particular findings.

### Example prompts

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
