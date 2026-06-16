---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Security Review Agent
description: Identify business logic vulnerabilities in merge requests with an AI agent.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/600301) in GitLab 19.1. This feature is in [beta](../../../../policy/development_stages_support.md#beta).

{{< /history >}}

Security Review Agent is an AI agent that detects business logic vulnerabilities in merge requests.
Unlike static analysis tools that scan for known patterns, Security Review Agent reasons about
the intent of your code. It identifies vulnerabilities that emerge from incorrect assumptions
about authorization, data exposure, and control flow.

Security Review Agent is a [foundational agent](_index.md) built on the GitLab Duo Agent Platform. It works
alongside [GitLab Duo Code Review](../../../gitlab_duo/code_review.md) and posts findings as threaded diff
comments, each with a CWE classification, severity rating, explanation, and where possible, an inline
suggested fix you can apply with one action.

Use Security Review Agent when you need help with:

- Access control review: Identify missing or misconfigured authorization checks on state-changing operations.
- Authorization gap detection: Surface broken object-level and function-level authorization issues (OWASP API #1 and #3).
- Business logic analysis: Detect flaws in application workflows that could be exploited, such as race conditions in financial or stateful operations.
- Information disclosure: Identify code paths that can leak sensitive data to unauthorized callers.
- Mass assignment risk: Flag endpoints or models that can expose unintended fields to user input.

## Prerequisites

To use Security Review Agent:

- Have the Developer, Maintainer, or Owner role for the project.
- [Turn on](../../flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off) Foundational flows
  and **Security Review** for the top-level group.
- [Turn on GitLab Duo](../../../gitlab_duo/turn_on_off.md) for the group or instance.
- If you do not have GitLab Duo Pro or Enterprise,
  [turn on GitLab Duo Core](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)
  for the top-level group or instance.
- For GitLab Self-Managed, [configure GitLab Duo](../../../../administration/gitlab_duo/configure/gitlab_self_managed.md)
  for the instance.
- In GitLab 18.8 and later, [turn on Agent Platform](../../turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)
  for the top-level group. In GitLab 18.7 and earlier,
  [turn on beta and experimental features](../../turn_on_off.md#turn-on-beta-and-experimental-features).

## Cost

Security Review Agent uses [GitLab Credits](../../../../subscriptions/gitlab_credits.md) each time it performs
a review. Credit consumption scales with the complexity of the merge request diff.

These rough estimates can help you assess typical credit usage:

| Review complexity | Approximate LLM calls | Estimated credits |
|-------------------|-----------------------|-------------------|
| Basic             | ~6                    | TBD               |
| Medium            | ~16                   | TBD               |
| Complex           | ~30                   | TBD               |

During the beta release, reviews are always initiated manually. This lets you assess typical
credit usage in your codebase before broader adoption.

## Use Security Review Agent

### Request a review

You can request a review at any time after a merge request is created. When you request a review, the agent
analyzes the merge request diff and its surrounding context.

To request a review:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Merge requests** and open your merge request.
1. In the **Reviewers** section of the right sidebar, select **Edit**.
1. Search for and select `duo-security-reviewer`. This service account is
   automatically created when the Security Review flow is turned on for your group.

When the review is complete, the agent posts an internal comment that summarizes any findings and a brief
description of the review scope. For each finding, the agent opens a diff thread at the relevant line. If you
reply to a thread (for example, to accept the risk or disagree with the assessment), the agent reads your reply
and responds accordingly.

On public projects, findings are posted in the internal summary note only, with no inline diff comments.
This avoids exposing security details publicly.

The agent sets the reviewer state based on the severity of findings:

| Severity             | Reviewer state |
| -------------------- | -------------- |
| `critical` or `high` | **Request changes** |
| `medium` or `low`    | **Comment**    |
| None                 | **Approve**    |

### Respond to a finding

Mention the agent in a thread to ask clarifying questions about a finding, discuss remediation approaches, or
flag a finding as a false positive. The agent does not perform a full re-review when mentioned.

To respond to a finding:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Merge requests** and open your merge request.
1. In any comment thread, type `@duo-security-reviewer` followed by your message, then submit.

Security Review Agent reads the thread context and replies directly.

### Review a finding

Security Review Agent focuses on logic-level vulnerabilities frequently missed by static analyzers.
Each finding is posted as a diff thread on the changed code. Each thread includes:

- The vulnerability type (CWE) with a link to the MITRE definition.
- A severity rating: `critical`, `high`, `medium`, or `low`.
- A tier classification: Tier 1 (Exploitable), Tier 2 (Logic Flaw), or Tier 3 (Design Issue).
- An explanation of the logic flaw.
- A suggested fix, where possible.

> [!note]
> Findings are not tracked in the [Vulnerability Report](../../../application_security/vulnerability_report/_index.md)
> and do not count toward [merge request approval policies](../../../application_security/policies/merge_request_approval_policies.md).
> They complement, but do not replace, static analysis (SAST) findings.

The following CWE classifications can appear in findings:

| CWE | Description |
|-----|-------------|
| [CWE-639](https://cwe.mitre.org/data/definitions/639.html) | Authorization bypass through user-controlled key (BOLA / IDOR) |
| [CWE-862](https://cwe.mitre.org/data/definitions/862.html) | Missing authorization |
| [CWE-284](https://cwe.mitre.org/data/definitions/284.html) | Improper access control |
| [CWE-200](https://cwe.mitre.org/data/definitions/200.html) | Exposure of sensitive information |
| [CWE-840](https://cwe.mitre.org/data/definitions/840.html) | Business logic errors |
| [CWE-915](https://cwe.mitre.org/data/definitions/915.html) | Improperly controlled modification of dynamically-determined object attributes (mass assignment) |
| [CWE-362](https://cwe.mitre.org/data/definitions/362.html) | Race conditions and time-of-check / time-of-use (TOCTOU) |

### Resolve a finding

To resolve a finding:

- To apply the fix, select **Apply suggestion**. To commit the suggestion to a new
  branch instead, select the dropdown next to **Apply suggestion**.
- To dismiss the finding, select **Resolve thread** if you have reviewed it and
  determined it is a false positive or accepted risk.
- To track the vulnerability for future remediation, use the standard GitLab
  [thread actions](../../../../user/project/merge_requests/_index.md#move-open-threads-to-an-issue)
  to create an issue from the finding.
- To rate the finding's usefulness, select **thumbs up** or **thumbs down**. This
  feedback helps improve the model. You can also share detailed feedback in
  [the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/600304).

After you resolve the findings, to request another review, reassign the agent as a reviewer. The agent analyzes
the updated diff and performs an action depending on the state of the finding:

- Resolved findings: The agent confirms the fix and resolves the original thread.
- Incorrect or incomplete fixes: The agent identifies any additional required changes in the original thread.
- Unaddressed findings: The original thread remains open with no additional comment.
- New findings: The agent detects any new vulnerabilities introduced by the fix and creates new comment threads
  for them.

## Troubleshooting

When you use Security Review Agent, you might encounter the following issues.

### The agent is not available to assign

The `duo-security-reviewer` service account is automatically created when the flow is turned on for your group.
Confirm the status of the Security Review flow.

### The agent does not provide findings

Confirm you meet all [prerequisites](#prerequisites), then check that the agent was correctly assigned.

- Verify that you mentioned `@duo-security-reviewer` exactly, with no spaces or capital letters.
- Verify [**Allow foundational flows**](../../flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)
  and [**Code Review**](../../flows/foundational_flows/code_review.md) settings are turned on for the top-level group.
- For GitLab Self-Managed, verify your instance is
  [configured for GitLab Duo](../../../../administration/gitlab_duo/configure/gitlab_self_managed.md).

### The agent does not review every merge request

Small merge requests without any changes to code logic might produce no findings. For example, this can
happen with documentation-only changes.

### Suggested changes do not apply cleanly

Suggestions are generated against the diff at review time. If you pushed new commits after
the review, line numbers might have shifted. Request a new review to get updated suggestions
against the current diff.

### I received an error about GitLab Credits

Your instance or group might have exhausted the [GitLab Credits](../../../../subscriptions/gitlab_credits.md)
for the current billing period. Contact your administrator to purchase additional credits, or wait for the
credits to reset at the start of the next billing period.
