---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Analyze security vulnerabilities and prioritize fixes based on business impact.
title: Analyze security vulnerabilities and prioritize fixes
---

Follow these guidelines when you need to evaluate multiple security vulnerabilities
and determine which ones require immediate attention.

- Time estimate: 15-25 minutes
- Level: Intermediate
- Prerequisites: GitLab Duo Enterprise add-on, vulnerabilities available in the vulnerability report

## The challenge

Security scans often generate numerous vulnerability alerts, making it difficult
to identify false positives and determine which issues pose the greatest business risk.

## The approach

Analyze vulnerabilities, assess business impact, and create prioritized remediation plans
by using GitLab Duo Chat, Vulnerability Explanation, and Vulnerability Resolution.

### Step 1: Explain vulnerabilities

Go to the vulnerability report for your project.
For each high or critical vulnerability, use Vulnerability Explanation to explain the issue. Then, use GitLab Duo Chat to ask follow-up questions.

```plaintext
Based on the earlier vulnerability explanation:

1. What specific security risk does this pose?
2. How could this be exploited in our [application_type]?
3. What data or systems could be compromised?
4. Is this a true positive or likely false positive?
5. What is the realistic business impact?

Consider our application stack: [technology_stack] and deployment environment: [environment_details].
```

Expected outcome: Clear explanation of each vulnerability's real-world impact and how it could be exploited.

### Step 2: Prioritize risks

Use GitLab Duo Chat to analyze multiple vulnerabilities together and create a priority matrix.

```plaintext
Based on these vulnerability explanations, help me prioritize fixes:

[paste_vulnerability_summaries]

Create a priority matrix considering:
1. Exploitability (how easy to exploit)
2. Business impact (what gets compromised)
3. Exposure level (public-facing vs internal)
4. Fix complexity (simple patch vs major changes)

Rank as Critical/High/Medium/Low priority with justification.
```

Expected outcome: Prioritized vulnerability list with business-focused risk assessment.

### Step 3: Generate fix plans

For high-priority vulnerabilities, use Vulnerability Resolution or Chat to get specific remediation guidance.

```plaintext
Provide a detailed remediation plan for this [vulnerability_type]:

1. Immediate steps to reduce risk
2. Code changes needed (with examples)
3. Configuration updates required
4. Testing approach to verify the fix
5. Timeline estimate for implementation

Focus on [security_framework] compliance and our [coding_standards].
```

Expected outcome: Actionable remediation plans with specific implementation steps.

## Tips

- Start with Critical and High severity vulnerabilities first.
- Use Vulnerability Explanation to understand the context before diving into fixes.
- Consider your specific application architecture when assessing business impact.
- Ask GitLab Duo Chat to explain technical terms or attack vectors you're unfamiliar with.
- Group similar vulnerabilities together for batch analysis and consistent fixes.
- Use the Security Dashboard to track progress on remediation efforts.

## Verify

Ensure that:

- Priority rankings reflect actual business risk, not just CVSS scores.
- Remediation plans include specific code examples and testing steps.
- False positives are clearly identified and documented.
- Critical vulnerabilities have immediate mitigation strategies identified.
- Fix timelines are realistic and account for testing and deployment processes.
