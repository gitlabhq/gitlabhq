---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Generate comprehensive tests for existing functions and classes.
title: Generate tests for existing code
---

Follow these guidelines when you need to create comprehensive test coverage for existing functions or classes.

- Time estimate: 10-20 minutes
- Level: Beginner
- Prerequisites: Code file open in IDE, GitLab Duo Chat available, existing code to test

## The challenge

Create thorough test coverage for existing code without manually writing boilerplate test cases and setup code.

## The approach

Select code, generate tests, and refine coverage by using GitLab Duo Chat and Code Suggestions.

### Step 1: Generate

Select the function or class you want to test, then use GitLab Duo Chat to generate tests.

```plaintext
Generate tests for the selected [function_name/ClassName] by using [test_framework]:

1. Include test cases for normal operation
2. Add edge cases and error conditions
3. Test boundary values and invalid inputs
4. Follow [testing_conventions] for our project
5. Include setup and teardown if needed

Make the tests comprehensive but readable.
```

Expected outcome: Complete test file with multiple test cases covering different scenarios.

### Step 2: Refine

Review the generated tests and ask for specific improvements.

```plaintext
Review the generated tests and:
1. Add any missing edge cases for [specific_functionality]
2. Improve test names to be more descriptive
3. Add comments explaining complex test scenarios
4. Ensure tests follow [specific_style_guide]

Focus on making tests maintainable and clear.
```

Expected outcome: Polished test file with clear, comprehensive coverage.

### Step 3: Extend

Use Code Suggestions to add additional test cases. Type this text in your file.

```plaintext
// Test [specific_edge_case_scenario]
// Test [error_condition]
// Test [boundary_condition]
```

Expected outcome: Code Suggestions helps complete additional test cases.

## Tips

- Select specific functions or classes rather than entire files for better results.
- Be specific about your testing framework (for example, Jest, pytest, RSpec).
- Ask Chat to explain the reasoning behind test cases if you're learning.
- Use Code Suggestions to quickly add similar test patterns.
- Request both positive and negative test cases for thorough coverage.

## Verify

Ensure that:

- Tests cover the main functionality and common edge cases.
- Test names clearly describe what is being tested.
- Tests follow your project's testing conventions and style.
- All tests pass when run against the existing code.
