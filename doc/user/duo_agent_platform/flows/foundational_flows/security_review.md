---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Security Review Flow
description: Identify business logic vulnerabilities in merge requests with AI.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/600301) in GitLab 19.1. This feature is in [beta](../../../../policy/development_stages_support.md#beta).

{{< /history >}}

Security Review Flow detects business logic vulnerabilities in merge requests.
Unlike static analysis tools that scan for known patterns, Security Review Flow reasons about
the intent of your code. It identifies vulnerabilities that emerge from incorrect assumptions
about authorization, data exposure, and control flow.

Security Review Flow is a [foundational flow](_index.md) built on the GitLab Duo Agent Platform. It works
alongside [GitLab Duo Code Review](../../../gitlab_duo/code_review.md) and posts findings as threaded diff
comments, each with a CWE classification, severity rating, explanation, and where possible, an inline
suggested fix you can apply with one action.

> [!note]
> Security Review Flow results are AI-generated and are advisory input, not an authoritative or
> complete security assessment. A review that reports no findings is not proof that a merge request
> is secure, and findings can include false positives that need human judgment. For more information,
> see [Known limitations](#known-limitations).

Use Security Review Flow when you need help with:

- Access control review: Identify missing or misconfigured authorization checks on state-changing operations.
- Authorization gap detection: Surface broken object-level and function-level authorization issues.
- Business logic analysis: Detect flaws in application workflows that could be exploited, such as race conditions in financial or stateful operations.
- Information disclosure: Identify code paths that can leak sensitive data to unauthorized callers.
- Mass assignment risk: Flag endpoints or models that can expose unintended fields to user input.

## Prerequisites

To use Security Review Flow:

- Have the Developer, Maintainer, or Owner role for the project.
- [Turn on](_index.md#turn-foundational-flows-on-or-off) Foundational flows
  and **Security Review** for the top-level group.
- [Turn on GitLab Duo](../../../gitlab_duo/turn_on_off.md) for the group or instance.
- If you do not have GitLab Duo Pro or Enterprise,
  [turn on GitLab Duo Core](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)
  for the top-level group or instance.
- For GitLab Self-Managed, [configure GitLab Duo](../../../../administration/gitlab_duo/configure/_index.md)
  for the instance.
- In GitLab 18.8 and later, [turn on Agent Platform](../../turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)
  for the top-level group. In GitLab 18.7 and earlier,
  [turn on beta and experimental features](../../turn_on_off.md#turn-on-beta-and-experimental-features).

## Cost

Security Review Flow uses [GitLab Credits](../../../../subscriptions/gitlab_credits.md) each time it
performs a review. Credit usage scales with diff complexity and the model you select.

The following estimates apply to the [default model](../../../../user/duo_agent_platform/model_selection.md#default-models):

| Review complexity                        | Approximate LLM calls | Estimated credits |
|------------------------------------------|-----------------------|-------------------|
| Small diff or a few changed files        | ~16                   | ~8                |
| Standard feature branch                  | ~28                   | ~14               |
| Large or logic-heavy multi-file change   | ~40                   | ~20               |

During the beta release, you always start reviews manually. This lets you assess typical credit
usage in your codebase before broader adoption.

## Use Security Review Flow

### Request a review

You can request a review at any time after a merge request is created. When you request a review, the flow
analyzes the merge request diff and its surrounding context.

The **Duo Security Review** service account is created for your top-level group when the Security Review flow is
turned on, and is available to all projects and subgroups within it. Each service account name includes the
associated top-level group, for example `duo-security-review-gitlab-org`.

To request a review:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Merge requests** and open your merge request.
1. In the **Reviewers** section of the right sidebar, select **Edit**.
1. In the search box, enter `Duo Security Review` and select the account from the list.

When the review is complete, the flow posts an internal note. The note summarizes any findings and
the review scope. If the review produces no findings, the flow states this in the internal note.

For each finding, the flow opens a diff thread at the relevant line. If you
reply to a thread (for example, to accept the risk or disagree with the assessment), the flow reads your reply
and responds accordingly. On public projects, findings are posted in the internal note only, with no inline
diff comments. Posting findings privately avoids exposing security details.

The flow sets the reviewer state based on the severity of findings. The flow never sets the
**Approve** state, even when it finds no issues:

| Severity             | Reviewer state |
| -------------------- | -------------- |
| `critical` or `high` | **Request changes** |
| `medium` or `low`    | **Comment**    |
| None                 | **Comment**    |

### Respond to a finding

{{< history >}}

- Delivery of replies to mentions [changed](https://gitlab.com/gitlab-org/gitlab/-/work_items/604317) in GitLab 19.2 [with a flag](../../../../administration/feature_flags/_index.md) named `ai_use_messaging_adapter_for_mentions`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> When the flag is disabled, a mention starts a full review instead of a targeted reply.
> For more information, see
> [a mention starts a full review instead of a reply](#a-mention-starts-a-full-review-instead-of-a-reply).

Mention the flow in a thread to ask clarifying questions about a finding, discuss remediation approaches, or
flag a finding as a false positive. The flow does not perform a full re-review when mentioned.

To respond to a finding:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Merge requests** and open your merge request.
1. In any comment thread, enter `@duo-security-review` and select **Duo Security Review** from the list.
1. Add your message and select **Comment**.

Security Review Flow reads the thread context and replies directly.

### Review a finding

Security Review Flow focuses on logic-level vulnerabilities frequently missed by static analyzers.
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
  branch instead, select the dropdown list next to **Apply suggestion**.
- To dismiss the finding, select **Resolve thread** if you reviewed the finding and
  determined it is a false positive or accepted risk.
- To track the vulnerability for future remediation, use the standard GitLab
  [thread actions](../../../../user/project/merge_requests/_index.md#move-open-threads-to-an-issue)
  to create an issue from the finding.
- To rate the finding's usefulness, select **thumbs up** or **thumbs down**. This
  feedback helps improve the model. You can also share detailed feedback in
  [the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/600304).

To request another review after you resolve the findings, reassign the flow as a reviewer. The flow analyzes
the updated diff and performs an action depending on the state of the finding:

- Resolved findings: The flow confirms the fix and resolves the original thread.
- Incorrect or incomplete fixes: The flow identifies any additional required changes in the original thread.
- Unaddressed findings: The original thread remains open with no additional comment.
- New findings: The flow detects any new vulnerabilities introduced by the fix and creates new comment threads
  for them.

## Known limitations

Understand the following limitations before you rely on Security Review Flow output.

- Findings are advisory, not a coverage guarantee. Security Review Flow results are AI-generated.
  The flow might not surface every vulnerability in a change: its analysis works within a bounded
  search and read budget, so very large files or diffs might not be fully reviewed. A review that
  reports no findings is not proof that the merge request is secure.
- Findings can include false positives. Treat findings as input that needs human judgment, not
  as a final verdict.
- Security Review Flow complements other tooling. It does not replace human security review or
  other GitLab security tools, such as
  [SAST](../../../application_security/sast/_index.md) and
  [GitLab Advanced SAST](../../../application_security/sast/gitlab_advanced_sast.md).

## Troubleshooting

When you use Security Review Flow, you might encounter the following issues.

### The flow is not available to assign

The **Duo Security Review** service account is created for your top-level group when the
Security Review flow is turned on. The service account name includes the top-level group
name, for example `duo-security-review-gitlab-org`.

Confirm the status of the Security Review flow.

### The flow does not provide findings

Confirm you meet all [prerequisites](#prerequisites), then check that the flow was correctly assigned.

- Verify that you mentioned the **Duo Security Review** account (its username begins with `@duo-security-review-`).
- Verify [**Allow foundational flows**](_index.md#turn-foundational-flows-on-or-off)
  and [**Code Review**](code_review.md) settings are turned on for the top-level group.
- For GitLab Self-Managed, verify your instance is
  [configured for GitLab Duo](../../../../administration/gitlab_duo/configure/_index.md).

### The flow does not review every merge request

To run this security scan, you must manually trigger the flow on a merge request. It will not run
automatically on every merge request. If you assigned the flow but received no findings, see
[The flow does not provide findings](#the-flow-does-not-provide-findings).

When the flow reviews a merge request, a report with no findings typically means:

- No security issues were detected: The code logic was analyzed, and no vulnerabilities were identified.
- No security-relevant logic: The change does not contain code that impacts security (for example,
  documentation-only updates).

Note on large changes: For large merge requests, the flow operates within a bounded search and read
budget. In these cases, the flow might report no findings or still output findings but fail to cover the full
merge request, meaning important vulnerabilities could be missed. A completed review is not a guarantee of full
coverage. For more information, see [Known limitations](#known-limitations).

### A mention starts a full review instead of a reply

The flow answers a mention with a targeted reply only when the
`ai_use_messaging_adapter_for_mentions` feature flag is enabled.
When the flag is disabled, a mention starts a full review of the merge request instead.

- On GitLab Self-Managed and GitLab Dedicated, an administrator can
  enable the feature flag named
  `ai_use_messaging_adapter_for_mentions`.
- On GitLab.com, this flag is disabled while GitLab rolls out support for replies.
  Until the rollout is complete, a mention starts a full review.
  For the rollout status, see [issue 602269](https://gitlab.com/gitlab-org/gitlab/-/issues/602269).

### Suggested changes do not apply cleanly

Suggestions are generated against the diff at review time. If you pushed new commits after
the review, line numbers might have shifted. Request a new review to get updated suggestions
against the current diff.

### I received an error about GitLab Credits

Your instance or group might have exhausted the [GitLab Credits](../../../../subscriptions/gitlab_credits.md)
for the current billing period. Contact your administrator to purchase additional credits, or wait for the
credits to reset at the start of the next billing period.
