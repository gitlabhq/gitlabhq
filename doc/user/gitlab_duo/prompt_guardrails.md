---
stage: AI-powered
group: AI Model Validation
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo prompt guardrails
---

GitLab Duo has foundational prompt guardrails. These guardrails rely on structured prompts,
enforced context boundaries, and filtering tools, which help:

- Reduce sensitive data exposure.
- Prevent prompt injection.
- Guide the model towards safe and helpful responses.

These safeguards support compliance with common regulatory standards,
like GDPR, by helping to minimize risks associated with AI-driven workflows.

NOTE:
While these guardrails may reduce risks, they do not eliminate all vulnerabilities.
No system can guarantee complete protection against all misuse or sophisticated attacks.

## General guardrails

The prompts used by GitLab Duo aim to:

- Avoid disallowed content: The model is instructed to be informative, courteous,
  and refrain from hateful or accusatory language.
- Adhere strictly to user requests: The model is instructed to stick closely to the prompt and avoid role play,
  impersonation, or deviating into unrelated content.
- Use tags to isolate content: Tags instruct the model to focus on provided snippets,
  helping to reduce the risk of prompt injection.
- Filter secrets: Code suggestions are scanned to help avoid sending sensitive information inadvertently. Example: A customer's job logs containing sensitive configuration data are encapsulated in `<log>` tags, helping to ensure the model focuses only on the provided context without making unrelated assumptions.

## Guardrails by job role

Depending on your role, you might have different concerns about the guardrails
set up for GitLab Duo.

### For technical users

- **Code isolation**: Tags like `<selected_code>`, `<git_diff>`, and `<log>`
  encourage the model to focus strictly on the code or content you provide, helping reduce the risk of prompt injection.
- **Secrets filtering**: Tools such as Gitleaks scan code suggestions to help prevent sensitive data,
  like API keys or passwords, from being shared.
- **Focused responses**: GitLab Duo focuses on the topic to help avoid behavior that could lead to unhelpful or unexpected outputs.
- **Root Cause Analysis**: When troubleshooting, GitLab Duo aims to analyze job logs without making assumptions about anything beyond what's provided.

### For auditors and compliance teams

- **Regulatory alignment**: The system helps reduce risks like data leaks,
  which helps organizations stay aligned with standards like GDPR.
- **Transparency**: The way prompts and contexts are structured helps make
  GitLab Duo actions predictable and available for auditing. For details, see [guardrails by feature](#guardrails-for-features).
- **Content control**: For tasks like summarizing discussions or resolving vulnerabilities,
  GitLab Duo uses only the inputs provided, helping to reduce the chance of errors or unintended outputs.
- **Protection against malicious inputs**: Filters and tagging mechanisms help safeguard
  the system from harmful or poorly formatted user content.

### For decision makers

- **Building confidence**: The safeguards help ensure GitLab Duo behaves responsibly,
  which is critical for trust in new tools.
- **Informed decisions**: Clear documentation of security features gives you the
  information needed to assess the suitability of GitLab Duo for your organization.
- **Reducing risks**: By working to tackle common concerns around sensitive data and model behavior,
  GitLab Duo offers a secure, practical solution for integrating AI into your workflows.

## Guardrails for features

Individual features include specific prompt instructions to help limit exposure. The prompt instructions adhere to the following principles.

### GitLab Duo Chat

Responses should remain on-topic, constructive, and non-abusive.
Personality shifts, role play, or malicious instructions are discouraged.
Focusing on user-provided content helps reduce injection risk.

### Discussion Summary

Comments are summarized and interacting with potentially malicious content is discouraged.
The user should be warned about suspicious comments without revealing or replicating them.

### Code Explanation, Test Generation, Refactor Code, Fix Code

Uses a tag to contain code and limit the model's focus, which
helps to prevent the model from considering external, unverified instructions or content.

### GitLab Duo for CLI

Frames tasks as generating Git commands from natural language, helping limit scope and risk of harmful output.

### Merge Request Summary

Isolates the code to help prevent prompt injection.

### Code Review

Isolates the code to help prevent prompt injection.

### Merge Commit Message Generation

Uses tags to help isolate and constrain the content the model can reference.

### Root Cause Analysis

Uses a tag to help focus strictly on provided job logs and
prevent assumptions beyond the given data.

### Vulnerability Resolution

Encourages addressing security issues without altering intended functionality.
The model is instructed to focus on the provided code diff to help prevent changes to code.
