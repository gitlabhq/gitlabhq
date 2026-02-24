---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Moa expression language
---

Moa is an expression language for dynamically constructing values during job execution.
Expressions are enclosed in `${{ }}` delimiters and are used in GitLab Functions and Job inputs.

Moa supports string manipulation, arithmetic, comparisons,
logical operations, property access, and function calls.

## Differences from CI/CD expressions

GitLab has three expression syntaxes that serve different purposes at different
stages of the pipeline lifecycle.

- [Rules](../yaml/_index.md#rules) use their own expression syntax inside `rules:` keywords
  to control job inclusion. They are evaluated during pipeline creation and support
  comparisons and pattern matching against CI/CD variables, but cannot perform arithmetic
  or access runtime state.
- CI/CD expressions use the `$[[ ]]` syntax and are evaluated during pipeline creation,
  before any jobs run. These expressions perform value substitution for
  [CI/CD inputs](../inputs/_index.md), [matrix values](../yaml/matrix_expressions.md), and
  [component inputs](../components/_index.md). They cannot perform
  arithmetic, comparisons, or logic, and have no access to runtime state.
  For more information, see [CI/CD expressions](../yaml/expressions.md).
- Moa uses the `${{ }}` syntax and is evaluated during job execution
  by the runner. Moa is a full expression language with operators, data structures,
  and function calls.

All three syntaxes can coexist in the same pipeline. A CI/CD component that contains
GitLab Functions might use all three:

```yaml
spec:
  inputs:
    echo_version:
      type: string
---

hi-job:
  # rules expression - evaluated when the pipeline is created
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  run:
    - name: say_hi
      # $[[ ]] - resolved when the pipeline is created
      step: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo@$[[ inputs.echo_version ]]
      inputs:
        # ${{ }} - resolved when the job runs
        message: "Hello, ${{ vars.CI_PROJECT_NAME }}"
```

Moa exists as a separate language because GitLab Functions need
capabilities that are unavailable at pipeline creation time:

- Runtime evaluation: Step outputs do not exist until the function runs. Expressions like
  `${{ steps.build.outputs.image_ref }}` can be evaluated only during execution.
- Typed values: Moa preserves native types (numbers, booleans, arrays, and objects)
  and passes them between functions without converting to a string.
- Operators and logic: GitLab Functions need arithmetic (`major_version + 1`), comparisons
  (`vulnerabilities == 0`), and short-circuit logic (`inputs.tag || "latest"`) to
  construct step inputs from variables and outputs.
- Sensitive value tracking: Moa propagates sensitive values through operations.
  If you concatenate a sensitive value into a string or pass it through a function call,
  the result is also treated as sensitive. This prevents the accidental disclosure
  of secrets in logs and outputs.

## Context reference

The values available in expressions depend on where the expression is used.

| Context       | Available in                                                                                             | Type   | Evaluated                        | Description                                                                                                                             |
|---------------|----------------------------------------------------------------------------------------------------------|--------|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `job.inputs`  | Job configuration: `script`, `before_script`, `after_script`, `artifacts`, `cache`, `image`, `services`  | Object | When the Runner receives the job | Input values defined for the job. Access individual variables with `job.inputs.<name>`.                                                 |
| `env`         | GitLab Functions                                                                                         | Object | Before the function runs         | Environment variables available to the function. Access individual variables with `env.<name>`.                                         |
| `inputs`      | GitLab Functions                                                                                         | Object | Before the function runs         | Input values passed to the function. Access individual inputs with `inputs.<name>`.                                                     |
| `vars`        | GitLab Functions                                                                                         | Object | Before the function runs         | Job variables passed from the CI job. Access individual variables with `vars.<name>`.                                                   |
| `steps`       | GitLab Functions                                                                                         | Object | Before the function runs         | Results from previously executed steps in the current function. Access a step's outputs with `steps.<step_name>.outputs.<output_name>`. |
| `export_file` | GitLab Functions                                                                                         | String | Before the function runs         | Path to the file where the function can write environment variables to export to subsequent steps.                                      |
| `output_file` | GitLab Functions                                                                                         | String | Before the function runs         | Path to the file where the function writes its output values.                                                                           |
| `func_dir`    | GitLab Functions                                                                                         | String | Before the function runs         | Path to the directory containing the function's definition file. Use to reference files bundled with the function.                      |
| `work_dir`    | GitLab Functions                                                                                         | String | Before the function runs         | Path to the working directory for the current execution.                                                                                |

## Template syntax

### Interpolation

Wrap expressions in `${{ }}` to evaluate them:

```yaml
script:
  - echo "Hello, ${{ job.inputs.name }}"
```

When text surrounds the expression, the result is always converted to a string.
Multiple expressions can appear in a single value:

```yaml
script:
  - echo "${{ job.inputs.greeting }}, ${{ job.inputs.name }}!"
```

### Native type passthrough

When `${{ expression }}` is the entire value with no surrounding text, the expression
returns its native type. Use native type expressions to pass non-string values like numbers,
booleans, arrays, and objects between steps without converting them to strings.

```yaml
inputs:
  count: ${{ steps.previous.outputs.total }}
```

In this example, if `total` is a number, `count` receives a number, not the string
representation.

### Escape Moa expressions

To include a literal `${{` in your text without triggering interpolation, escape it
with a backslash:

```yaml
script:
  - echo "Use \${{ to start an expression"
```

This command outputs the text `Use ${{ to start an expression` without evaluation.

## Literals

### Null

The keyword `null` represents the absence of a value.

```yaml
${{ null }}
```

### Booleans

The keywords `true` and `false` represent boolean values.

```yaml
${{ true }}
${{ false }}
```

### Numbers

Numbers are IEEE 754 double-precision floating point values with 53 bits of significand
precision. Integers, decimals, and scientific notation are supported.

```yaml
${{ 42 }}
${{ 3.14 }}
${{ 1.5e3 }}
${{ 2E-4 }}
```

### Strings

Enclose strings in double quotes or single quotes. The two quote types
handle escape sequences and template expressions differently.

Double-quoted strings support template expressions and a full set of escape sequences:

| Sequence  | Meaning                                 |
|-----------|-----------------------------------------|
| `\\`      | Backslash                               |
| `\"`      | Double quote                            |
| `\n`      | Newline                                 |
| `\r`      | Carriage return                         |
| `\t`      | Tab                                     |
| `\a`      | Alert (bell)                            |
| `\b`      | Backspace                               |
| `\f`      | Form feed                               |
| `\v`      | Vertical tab                            |
| `\/`      | Forward slash                           |
| `\uXXXX`  | Unicode code point                      |
| `\${{`    | Literal `${{` (prevents interpolation)  |

Template expressions (`${{ }}`) inside double-quoted strings are evaluated and
interpolated into the string.

Single-quoted strings are raw string literals with minimal interpretation.
Template expressions inside single-quoted strings are not evaluated. Only two
escape sequences are supported:

| Sequence | Meaning      |
|----------|--------------|
| `\\`     | Backslash    |
| `\'`     | Single quote |

```yaml
${{ "Hello\nWorld" }}
${{ 'It\'s a string' }}
${{ 'Literal ${{ not evaluated }}' }}
```

## Identifiers

Identifiers reference values from the expression context. An identifier starts with a
letter or underscore and can contain letters, digits, and underscores. Identifiers are
case-sensitive: `foo`, `Foo`, and `FOO` are three different identifiers.

```yaml
${{ env }}
${{ my_variable }}
```

Identifiers are resolved against the available context. For
the values available in each context, see [context reference](#context-reference).

When an identifier refers to a context object, the entire object is returned. For example, `${{ vars }}`
returns all job variables as an object.

## Operators

### Arithmetic operators

Arithmetic operators work on numbers. The `+` operator also concatenates strings.
Operators do not perform implicit type conversion, so `"hello" + 42` results in an error.

| Operator | Description                 | Example             | Result     |
|----------|-----------------------------|---------------------|------------|
| `+`      | Addition                    | `${{ 2 + 3 }}`      | `5`        |
| `+`      | Concatenation               | `${{ "a" + "b" }}`  | `"ab"`     |
| `-`      | Subtraction                 | `${{ 10 - 4 }}`     | `6`        |
| `*`      | Multiplication              | `${{ 3 * 4 }}`      | `12`       |
| `/`      | Division                    | `${{ 10 / 3 }}`     | `3.333...` |
| `%`      | Modulo (truncated division) | `${{ 10 % 3 }}`     | `1`        |

Division by zero results in an error.

### Comparison operators

Comparison operators return a boolean value.

| Operator | Description           | Example            | Result  |
|----------|-----------------------|--------------------|---------|
| `==`     | Equal                 | `${{ 1 == 1 }}`    | `true`  |
| `!=`     | Not equal             | `${{ 1 != 2 }}`    | `true`  |
| `<`      | Less than             | `${{ 1 < 2 }}`     | `true`  |
| `<=`     | Less than or equal    | `${{ 2 <= 2 }}`    | `true`  |
| `>`      | Greater than          | `${{ 3 > 2 }}`     | `true`  |
| `>=`     | Greater than or equal | `${{ 3 >= 3 }}`    | `true`  |

Values of different types are compared by type, so `1 == "1"` evaluates to `false`.
Values of the same type follow these comparison rules:

- Numbers: Numeric comparison.
- Strings: Lexicographic comparison (UTF-8 byte order).
- Booleans: `false` is less than `true`.
- Arrays: Element-by-element comparison.
- Objects: Compared by length, then keys, then values. Key order does not matter.
- Null: `null` is equal to `null`.

### Logical operators

Logical operators use short-circuit evaluation and return one of their operands,
not necessarily a boolean. This behavior is similar to the JavaScript `&&` and `||` operators.

| Operator   | Description | Behavior                                                                                      |
|------------|-------------|-----------------------------------------------------------------------------------------------|
| `\|\|`     | Logical OR  | Returns the left operand if it is truthy, otherwise evaluates and returns the right operand.  |
| `&&`       | Logical AND | Returns the left operand if it is falsy, otherwise evaluates and returns the right operand.   |
| `!`        | Logical NOT | Returns `true` if the operand is falsy, `false` if truthy.                                    |

The `||` operator is used to provide default values:

```yaml
${{ inputs.name || "default" }}
```

If `inputs.name` is a non-empty string, it is returned as-is. If it is empty or null,
`"default"` is returned.

### Unary operators

| Operator | Description    | Example          | Result  |
|----------|----------------|------------------|---------|
| `+`      | Unary plus     | `${{ +5 }}`      | `5`     |
| `-`      | Unary negation | `${{ -5 }}`      | `-5`    |
| `!`      | Logical NOT    | `${{ !true }}`   | `false` |

### Operator precedence

Operators are listed from highest precedence to lowest. Operators on the same row
have equal precedence. All binary operators are left-associative.

| Precedence  | Operators                        |
|-------------|----------------------------------|
| 7 (highest) | `.`, `[]`, `()`                  |
| 6           | `+`, `-`, `!`                    |
| 5           | `*`, `/`, `%`                    |
| 4           | `+`, `-`                         |
| 3           | `==`, `!=`, `<`, `<=`, `>`, `>=` |
| 2           | `&&`                             |
| 1 (lowest)  | `\|\|`                           |

Use parentheses to override precedence:

```yaml
${{ (1 + 2) * 3 }}
```

## Data structures

### Arrays

Create arrays with bracket notation. Elements can be of any type and you can mix
types. You can use trailing commas.

```yaml
${{ [1, 2, 3] }}
${{ ["a", 1, true, null] }}
${{ [] }}
```

### Objects

Create objects with brace notation. Keys must evaluate to strings. Values can be
any type. Trailing commas are allowed.

```yaml
${{ {name: "runner", version: 1} }}
${{ {"string-key": true} }}
${{ {} }}
```

Bare identifiers used as object keys are treated as string literals, not as variable
references. To use a variable as a key, wrap it in parentheses:

```yaml
${{ {name: "Alice"} }}           # "name" is the string "name", not a variable reference
${{ {(obj.prop): "value"} }}     # key is the value of obj.prop, which must be a string
```

## Property access

### Dot notation

Access object properties with dot notation:

```yaml
${{ env.HOME }}
${{ steps.build.outputs.artifact_path }}
```

### Bracket notation

Access array elements by index, or object properties by string key:

```yaml
${{ my_array[0] }}
${{ my_object["property-name"] }}
```

Bracket notation is required when a property name contains special characters
like hyphens.

### Chaining

Chain property access and function calls:

```yaml
${{ steps.build.outputs.items[0] }}
```

## Function calls

Call functions by name with parentheses:

```yaml
${{ str(42) }}
${{ num("3.14") }}
```

## Truthiness

Logical operators and the `!` operator use the following truthiness rules:

| Type    | Truthy when             | Falsy when        |
|---------|-------------------------|-------------------|
| Boolean | `true`                  | `false`           |
| String  | Length greater than `0` | Empty string `""` |
| Number  | Not `0`                 | `0`               |
| Array   | Length greater than `0` | Empty array `[]`  |
| Object  | Length greater than `0` | Empty object `{}` |
| Null    | Never                   | Always            |

## Built-in functions

### `str(value)`

Converts any value to its string representation.

```yaml
${{ str(42) }}       # "42"
${{ str(true) }}     # "true"
${{ str(null) }}     # "<null>"
```

### `num(value)`

Converts a string to a number. The string must be a valid numeric representation.

```yaml
${{ num("42") }}     # 42
${{ num("3.14") }}   # 3.14
```

### `bool(value)`

Converts any value to a boolean based on its [truthiness](#truthiness).

```yaml
${{ bool("hello") }}  # true
${{ bool("") }}       # false
${{ bool(0) }}        # false
${{ bool(1) }}        # true
```

## Reserved words

The following words are reserved and cannot be used as identifiers. They are reserved
for potential future language features.

`array`, `as`, `break`, `case`, `const`, `continue`, `default`, `else`,
`fallthrough`, `float`, `for`, `func`, `function`, `goto`, `if`, `import`,
`in`, `int`, `let`, `loop`, `map`, `namespace`, `number`, `object`, `package`,
`range`, `return`, `string`, `struct`, `switch`, `type`, `var`, `void`, `while`

The keywords `null`, `true`, and `false` are also reserved as literal values.

## Examples

### Deploy with strategy selection

```yaml
deploy job:
  when: manual
  inputs:
    environment:
      default: staging
      options: [staging, production]
      description: Target deployment environment
    strategy:
      default: rolling
      options: [rolling, blue-green, canary]
      description: Deployment strategy
    replicas:
      type: number
      default: 3
      description: Number of replicas to deploy
  image: ${{ job.inputs.environment == "production" && "deploy-tools:stable" || "deploy-tools:latest" }}
  script:
    - 'echo "Deploying to ${{ job.inputs.environment }} using ${{ job.inputs.strategy }}"'
    - deploy
        --env ${{ job.inputs.environment }}
        --strategy ${{ job.inputs.strategy }}
        --replicas ${{ str(job.inputs.replicas) }}
```

### Conditional flags from boolean job inputs

```yaml
test_job:
  inputs:
    coverage:
      type: boolean
      default: false
    verbose:
      type: boolean
      default: false
  script:
    - pytest ${{ job.inputs.verbose && "-v" || "" }} ${{ job.inputs.coverage && "--cov=src" || "" }}
```

### Building an image reference from job variables

```yaml
build_job:
  run:
    - name: build
      func: ./docker-build
      inputs:
        image: ${{ vars.CI_REGISTRY + "/" + vars.CI_PROJECT_PATH + ":" + vars.CI_PIPELINE_IID }}
```

### Continue gate

```yaml
security_scan_job:
  run:
    - name: scan
      func: ./security-scan
    - name: gate
      func: ./quality-gate
      inputs:
        should_proceed: ${{ steps.scan.outputs.critical == 0 && steps.scan.outputs.high < 5 }}
```

### Version management

```yaml
increment_version_job:
  run:
    - name: current
      func: ./find-version
    - name: bump
      func: ./bump-version
      inputs:
        new_version: ${{ str(steps.current.outputs.major + 1) + ".0.0" }}
```

### Environment-specific configuration

```yaml
deploy_job:
  run:
    - name: deploy
      func: ./deploy
      inputs:
        registry: ${{ (vars.CI_COMMIT_REF_NAME == "main" && "prod.registry.com") || "staging.registry.com" }}
        replicas: ${{ (vars.CI_COMMIT_REF_NAME == "main" && 5) || 2 }}
```

### Configure A/B testing

```yaml
configure_job:
  run:
    - name: configure_ab
      func: ./traffic-split
      inputs:
        variants: |
          ${{ [
            {name: "control", use_new_feature: false, weight: 90},
            {name: "experiment", use_new_feature: true, weight: 10}
          ] }}
```
