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

#### Using NamedTuples to define parametrized test cases

[Pytest parametrized tests](https://docs.pytest.org/en/stable/how-to/parametrize.html) effectively reduce code
repetition, but they rely on tuples for test case definition, unlike Ruby's more readable syntax. As your parameters or
test cases increase, these tuple-based tests become harder to understand and maintain.

By using Python [NamedTuples](https://docs.python.org/3/library/typing.html#typing.NamedTuple) instead, you can:

- Enforce clearer organization with named fields.
- Make tests more self-documenting.
- Easily define default values for parameters.
- Improve readability in complex test scenarios.

```python
# Good: Short examples, with small numbers of arguments. Easy to map what each value maps to each argument

@pytest.mark.parametrize(
    (
        "argument1",
        "argument2",
        "expected_result",
    ),
    [
        # description of case 1,
        ("value1", "value2", 200),
        # description of case 2,
        ...,
    ],
)
def test_get_product_price(argument1, argument2, expected_result):
    assert get_product_price(value1, value2) == expected_cost

# Bad: difficult to map a value to an argument, and to add or remove arguments when updating test cases

@pytest.mark.parametrize(
    (
        "argument1",
        "argument2",
        "argument3",
        "expected_response",
    ),
    [
      # Test case 1: 
      (
        "value1",
        {
          ...
        },
        ...
      ),
      # Test case 2:
      ...
    ]
)

def test_my_function(argument1, argument2, argument3, expected_response):
   ...

# Good: NamedTuples improve readibility for larger test scenarios.

from typing import NamedTuple

class TestMyFunction:
  class Case(NamedTuple):
      argument1: str
      argument2: int = 3
      argument3: dict
      expected_response: int

  TEST_CASE_1 = Case(
      argument1="my argument",
      argument3={
          "key": "value"
      },
      expected_response=2
  )

  TEST_CASE_2 = Case(
      ...
  )
  @pytest.mark.parametrize(
      "test_case", [TEST_CASE_1, TEST_CASE_2]
  )
  def test_my_function(test_case):
      assert my_function(case.argument1, case.argument2, case.argument3) == case.expected_response
```

#### Mocking

- Use `unittest.mock` library.
- Mock at the right level, for example, at method call boundaries.
- Mock external services and APIs.
