---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Identify and fix bugs in failing code or tests.
title: Debug failing code
---

Follow these guidelines when you have code that isn't working as expected or tests that are failing.

- Time estimate: 10-25 minutes
- Level: Beginner
- Prerequisites: Error messages or failing code available, GitLab Duo Chat available in IDE

## The challenge

Quickly identify the root cause of bugs or test failures and implement effective fixes without spending hours debugging manually.

## The approach

Analyze errors, identify causes, and implement fixes by using GitLab Duo Chat.

### Step 1: Analyze

Copy the error message and relevant code. Then ask GitLab Duo Chat to explain the error.

```plaintext
Explain what's causing this error and help me fix it:

Error: [paste_error_message]

Context: [brief_description_of_what_you_were_trying_to_do]

Here's the relevant code:
[paste_problematic_code]
```

Expected outcome: Clear explanation of the error cause and specific fix recommendations.

### Step 2: Implement

Ask Chat to provide the corrected code.

```plaintext
Based on your analysis, please provide the corrected version of this code:

[paste_original_code]

Make sure the fix addresses [specific_error] and follows [language/framework] best practices.
```

Expected outcome: Working code that fixes the identified issue.

### Step 3: Prevent

Ask for guidance on how to avoid similar issues.

```plaintext
How can I prevent this type of error in the future?
What are the warning signs to watch for with [error_type] in [language/framework]?
Include any best practices or common patterns I should follow.
```

Expected outcome: Preventive guidance and best practices to avoid similar bugs.

## Tips

- Include the full error message, not just a summary.
- Provide context about what you were trying to accomplish.
- Start by copying only the specific code section that's failing. Add more code from the file if Chat requires more context.
- Ask Chat to explain the fix so you understand the underlying issue.
- If the first suggestion doesn't work, tell Chat what happened when you tried it.

## Verify

Ensure that:

- The error no longer occurs when you run the code.
- The fix addresses the root cause, not just the symptoms.
- The solution follows your project's coding standards.
- You understand why the error occurred and how the fix works.
