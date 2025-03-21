---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Python style guide
---

## Testing

### Overview

Testing at GitLab, including in Python codebases is a core priority rather than an afterthought. It is therefore important to consider test design quality alongside feature design from the start.

Use [Pytest](https://docs.pytest.org/en/stable/) for Python testing.

### Recommended reading

- [Five Factor Testing](https://madeintandem.com/blog/five-factor-testing/): Why do we need tests?
- [Principles of Automated Testing](https://www.lihaoyi.com/post/PrinciplesofAutomatedTesting.html): Levels of testing. Prioritize tests. Cost of tests.

### Testing levels

Before writing tests, understand the different testing levels and determine the appropriate level for your changes.

[Learn more about the different testing levels](../testing_guide/testing_levels.md), and how to decide at what level your changes should be tested.

### Recommendations

#### Name test files the same as the files they are testing

For unit tests, naming the test file with `test_{file_being_tested}.py` and placing it in the same directory structure
helps with later discoverability of tests. This also avoids confusion between files that have the same name, but
different modules.

```shell
File: /foo/bar/cool_feature.py

# Bad

Test file: /tests/my_cool_feature.py

# Good

Test file: /tests/foo/bar/test_cool_feature.py
```

#### Mocking

- Use `unittest.mock` library.
- Mock at the right level, for example, at method call boundaries.
- Mock external services and APIs.
