---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Refactor legacy code in your repository.
title: Refactor legacy code
---

Follow these guidelines when you need to improve performance, readability, or maintainability of existing code.

- Time estimate: 15-30 minutes
- Level: Intermediate
- Prerequisites: Code file open in IDE, GitLab Duo Chat available

## The challenge

Transform complex, hard-to-maintain code into clean, testable components without breaking functionality.

## The approach

Analyze, plan, and implement by using GitLab Duo Chat and Code Suggestions.

### Step 1: Analyze

Use GitLab Duo Chat to understand the current state. Select the code you want to refactor, then ask:

```plaintext
Analyze the [ClassName] in [file_path]. Focus on:
1. Current methods and their complexity
2. Performance bottlenecks
3. Areas where readability can be improved
4. Potential design patterns that could be applied

Provide specific examples from the code and suggest applicable refactoring patterns.
```

Expected outcome: Detailed analysis with specific improvement suggestions.

### Step 2: Plan

Use GitLab Duo Chat to create a structured proposal.

```plaintext
Based on your analysis of [ClassName], create a refactoring plan:

1. Outline the new structure
2. Suggest new method names and their purposes
3. Identify any new classes or modules needed
4. Explain how this improves [performance/readability/maintainability]

Format as a structured plan with clear before/after comparisons.
```

Expected outcome: Step-by-step refactoring roadmap.

### Step 3: Implement

Use GitLab Duo Chat to generate the refactored code. Then apply the code and use Code Suggestions to help with syntax.

```plaintext
Implement the refactoring plan for [ClassName]:

1. Create the new [language] file following our coding standards
2. Include detailed comments explaining changes
3. Update [related_file] to use the new structure
4. Write tests for the new implementation

Follow [style_guide] and document any design decisions.
```

Expected outcome: Complete refactored code with tests.

## Tips

- Start with analysis before jumping to implementation.
- Select specific code sections when asking Chat for analysis.
- Ask Chat for specific examples from your actual code.
- Reference your existing codebase patterns for consistency.
- Use incremental prompts rather than trying to do everything at once.
- Let Code Suggestions help with syntax as you implement the recommendations from Chat.

## Verify

Ensure that:

- Generated code follows your team's style guide.
- New structure actually improves the identified issues.
- Tests cover the refactored functionality.
- No functionality was lost in the refactoring.
