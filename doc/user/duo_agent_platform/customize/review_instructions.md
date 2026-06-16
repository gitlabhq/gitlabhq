---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Customize instructions for AI to use in merge request reviews.
title: Customize review instructions for the Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/545136) in GitLab 18.2 as a [beta](../../../policy/development_stages_support.md#beta) [with a flag](../../../administration/feature_flags/_index.md) named `duo_code_review_custom_instructions`. Disabled by default.
- Feature flag `duo_code_review_custom_instructions` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199802) in GitLab 18.3.
- Feature flag `duo_code_review_custom_instructions` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202262) in GitLab 18.4.
- Union patterns (for example, `{rb,ts}`) in `fileFilters` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237952) in GitLab 19.1.

{{< /history >}}

Create custom review instructions to provide standards for GitLab Duo to reference when reviewing merge requests.

For example, you can guide GitLab Duo to focus on Ruby style conventions for Ruby files, and Go style
conventions for Go files.

> [!note]
> Custom review instructions are guidance for the AI reviewer, not enforced policies.
> GitLab Duo uses them as context to shape its review, but cannot guarantee every instruction
> is applied in every case. Do not rely on custom instructions for security controls,
> compliance obligations, or other requirements where consistent enforcement is needed.

GitLab Duo appends your custom review instructions to its standard review criteria,
instead of replacing them.

Code Review Flow supports custom review instructions set for a specific project or for all projects within a group.

## Configure custom review instructions for a project

To configure custom merge request review instructions:

1. In the root of your repository, create a `.gitlab/duo` directory if one doesn't already exist.
1. In the `.gitlab/duo` directory, create a file named `mr-review-instructions.yaml`.
1. Add your custom instructions using the following format:

   ```yaml
   instructions:
     - name: <instruction_group_name>
       fileFilters:
         - <glob_pattern_1>
         - <glob_pattern_2>
         - !<exclude_pattern>  # Exclude files matching this pattern
       instructions: |
         <your_custom_review_instructions>
   ```

   The `fileFilters` section is optional. Use glob patterns in this section to target the instruction
   to specific files. If you omit `fileFilters` or leave it empty, GitLab Duo applies the
   instruction to every file in the merge request.

   For example:

   ```yaml
   instructions:
     - name: Ruby Style Guide
       fileFilters:
         - "*.rb"           # Ruby files in the root directory
         - "lib/**/*.rb"    # Ruby files in lib and its subdirectories
         - "!spec/**/*.rb"  # Exclude test files
       instructions: |
         1. Ensure all methods have proper documentation
         2. Follow Ruby style guide conventions
         3. Prefer symbols over strings for hash keys

     - name: TypeScript Source Files
       fileFilters:
         - "**/*.ts"        # Typescript files in any directory
         - "!**/*.test.ts"  # Exclude test files
         - "!**/*.spec.ts"  # Exclude spec files
       instructions: |
         1. Ensure proper TypeScript types (avoid 'any')
         2. Follow naming conventions
         3. Document complex functions

     - name: All Files Except Tests
       fileFilters:
         - "!**/*.test.*"   # Exclude all test files
         - "!**/*.spec.*"   # Exclude all spec files
         - "!test/**/*"     # Exclude test directories
         - "!spec/**/*"     # Exclude spec directories
       instructions: |
         1. Follow consistent code style
         2. Add meaningful comments for complex logic
         3. Ensure proper error handling

     - name: Test Coverage
       fileFilters:
         - "spec/**/*_spec.rb" # Ruby test files in spec directory
       instructions: |
         1. Test both happy paths and edge cases
         2. Include error scenarios
         3. Use shared examples to reduce duplication

     - name: Database Migrations
       fileFilters:
         - "db/migrate/**/*.rb"
         - "db/post_migrate/**/*.rb"
       instructions: |
         1. Follow the migration safety guidelines in
            https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/database/avoiding_downtime_in_migrations.md
         2. Apply the team checklist in docs/migrations-checklist.md

     - name: All Files
       fileFilters:
         - "**/*"   # All files in the repository
       instructions: |
         1. Explain the "why" behind each suggestion
   ```

   For details about referencing files in instructions, see
   [reference files in instructions](#reference-files-in-instructions).

   For glob syntax examples, see the
   [file pattern reference](#file-pattern-reference).

1. Optional: Add a [Code Owners](../../project/codeowners/_index.md) entry to
   protect changes to the `mr-review-instructions.yaml` file.

   ```markdown
   [GitLab Duo]
   .gitlab/duo @default-owner @tech-lead
   ```

1. [Create a merge request](../../project/merge_requests/creating_merge_requests.md)
   to review and merge the changes:

   - GitLab Duo automatically applies your custom instructions when the file
     patterns match.
   - Multiple instruction groups can apply to a single file. When a file
     matches the `fileFilters` of more than one group, Code Review Flow applies
     the instructions from every matching group.
   - For review comments triggered by your custom instructions, GitLab Duo uses this format:

     ```plaintext
     According to custom instructions in '[instruction_name]': [feedback comments]
     ```

     The `instruction_name` value corresponds to the `name` property from your
     `.gitlab/duo/mr-review-instructions.yaml` file. Standard GitLab Duo comments
     do not use this format.
     <br><br>
     If GitLab Duo does not find any issues, it leaves a review summary comment. Custom
     instructions do not apply to this summary comment.
1. Optional:
   - Review the feedback and refine your instructions as needed.
   - Test the patterns to ensure they match the intended files.

## Configure custom review instructions for a group

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230090) in GitLab 19.0.

{{< /history >}}

You can define custom review instructions for a group by specifying a project to use as a template.
The template project must contain a `.gitlab/duo/mr-review-instructions.yaml` file with review
instructions that apply to all projects in the group and its subgroups.

When GitLab Duo performs a code review, it combines instructions from the top-level group with instructions defined in the individual project.

Prerequisites:

- The Owner role for the top-level group.
- A project in the group contains the custom review instructions that you want to use as a template.

To configure custom review instructions for a group:

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Settings** > **General** > **GitLab Duo features**.
1. Under **Custom review instructions for groups**, select the project that contains the
   `.gitlab/duo/mr-review-instructions.yaml` file with your group's review instructions.
1. Select **Save changes**.

## Reference files in instructions

You can reference other files in custom instructions instead of duplicating content.
Code Review Flow reads the referenced files during the pre-scan step
and extracts relevant guidance.

Custom instructions support two file reference patterns:

- Files in the same project as the merge request: Use a repository-relative path,
  such as `docs/security-checklist.md`.
- Files in other projects on the same GitLab instance: Use a full
  GitLab blob URL, such as
  `https://gitlab.example.com/group/project/-/blob/main/docs/style-guide.md`.
  The URL must point to the same GitLab instance as the merge request and
  must use the `/-/blob/<ref>/<path>` format.

For example:

```yaml
instructions:
  - name: Database Migrations
    fileFilters:
      - "db/migrate/**/*.rb"
    instructions: |
      1. Follow the migration guidelines in
         https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/database/avoiding_downtime_in_migrations.md
      2. Reference the team checklist in docs/db-checklist.md
```

### Limitations of file references

File reference resolution has the following constraints:

- Same GitLab instance only. URLs that point to a different GitLab
  instance, to public GitLab from a GitLab Self-Managed instance, or to any
  non-GitLab site, such as Confluence or a public documentation site, are not
  fetched.
- Blob URLs only, formatted as `/-/blob/<ref>/<path>`. Wiki pages, issues,
  raw URLs, and snippets are not fetched.
- Same project for bare paths. A bare path such as `docs/security.md`
  resolves against the same project as the merge request. Use a full GitLab
  blob URL to reference a file in a different project.
- Best effort, not guaranteed. Code Review Flow decides which references
  to fetch based on the instruction text. A reference that fails to resolve,
  such as a path that does not exist or a URL the parser rejects, is skipped
  silently.
- Code Review Flow uses a summary, not the original file. It summarizes the
  fetched content during the pre-scan step and uses the summary during the
  review. Two reviews of the same merge request can produce different
  summaries.

If you want Code Review Flow to use the exact file contents and not a summary,
include it directly in the `instructions:` field instead of referencing the
file. Inline instructions are used as written.

## Best practices

When writing custom review instructions:

- Be specific and actionable. Code Review Flow checks each rule against the
  diff. For example, a concrete rule like "verify that public methods have YARD
  documentation" produces useful comments, but abstract guidance like
  "document your code well" does not.
- Number your instructions for clarity.
- Focus on the most important standards. Every rule's text becomes part of
  the review prompt, so long lists of low-value rules inflate the prompt
  without adding signal.
- Explain the "why" when helpful.
- Start with straightforward instructions, and add complexity as needed.
- Focus on project-specific standards that Code Review Flow wouldn't apply
  by default. Custom instructions add to the standard review criteria instead
  of replacing them. General advice like "add error handling" or "use
  meaningful names" is usually already covered. Use custom instructions for
  what only your project knows: internal APIs, architectural conventions,
  domain-specific patterns.
- Write instructions as guidance, not mandates. Instructions are hints that
  shape review behavior, not policies that GitLab Duo is required to follow. Avoid
  wording like "always flag" or "never allow". This phrasing can mislead collaborators into thinking the behavior is guaranteed.
- Make file patterns reflect the actual scope of the rule. Code Review Flow
  reads each instruction alongside each `fileFilters` reference and applies
  the rule only to files that match those patterns. For example, a rule for "Rails
  controllers" scoped to `**/*.rb` will apply to gems, scripts, and
  tests, not just controllers. Use `app/controllers/**/*.rb` instead.
- Only use external file references for instructions where exact wording
  does not matter, otherwise include the details as a rule in the
  `instructions:` field directly. Code Review Flow generates and uses
  summaries for referenced files, but uses the exact wording defined in
  `instructions`.

For example:

```yaml
instructions: |
  1. All public functions must include docstrings with parameter descriptions
  2. Use parameterized queries to prevent SQL injection
  3. Validate user input before processing (check type, length, format)
  4. Include error handling for all external API calls
  5. Avoid hardcoded credentials - use environment variables
```

For language-specific examples, see the [use case examples](#use-case-examples).

## File pattern reference

Use glob patterns in `fileFilters` to target specific files.

For example, for a project that contains Ruby files:

| Pattern | Match |
| --- | --- |
| `**/*.rb`       | All Ruby files in any directory |
| `*.rb`          | Ruby files in root directory only |
| `lib/**/*.rb`   | Ruby files in the `lib` directory and its subdirectories |
| `!**/*.test.rb` | Exclude all Ruby test files |
| `!spec/**/*.rb` | Exclude all Ruby files in the `spec` directory and its subdirectories |
| `!tests/**/*`   | Exclude all files in the `tests` directory and its subdirectories |
| `**/*.{js,jsx}` | JavaScript and JSX files in all directories (GitLab 19.1 and later) |

The following example shows the difference between `**/*.rb` and `*.rb`:

```plaintext
project/
├── app.rb              ← matched by both *.rb and **/*.rb
├── lib/
│   └── helper.rb       ← matched only by **/*.rb
└── app/
    └── models/
        └── user.rb     ← matched only by **/*.rb
```

- `*.rb` would only match app.rb
- `**/*.rb` would match all three files

For the `mr-review-instructions.yaml` file, `**/*.rb` ensures that review instructions
apply to Ruby files anywhere in the project structure, not just the root directory.

## Use case examples

<!-- 2025-11-12 Use case examples are maintained by DevRel, @dnsmichi
Inspired by the reference in <https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml?ref_type=heads>
-->

{{< tabs >}}

{{< tab title="Assembly" >}}

```yaml
instructions:
  - name: Assembly Style Guide
    fileFilters:
      - "**/*.asm"
      - "**/*.s"
      - "**/*.S"
    instructions: |
      1. Document the target architecture (x86-64, ARM, RISC-V, AVR, etc.) at the top
      2. Use meaningful labels and comment all non-obvious instructions
      3. Document register usage and calling conventions
      4. Align code sections properly for readability
      5. Include memory layout and stack usage documentation
```

{{< /tab >}}

{{< tab title="C" >}}

```yaml
instructions:
  - name: C Style Guide
    fileFilters:
      - "**/*.c"
      - "**/*.h"
    instructions: |
      1. goto is not allowed
      2. Avoid using global variables
      3. Use meaningful variable names
      4. Add comments for complex logic
```

{{< /tab >}}

{{< tab title="C++" >}}

```yaml
instructions:
  - name: C++ Style Guide
    fileFilters:
      - "**/*.cpp"
      - "**/*.{h,hpp}"
    instructions: |
      1. Ensure all methods have proper documentation
      2. Use smart pointers for dynamic memory management
      3. Avoid raw pointers
```

{{< /tab >}}

{{< tab title="C#" >}}

```yaml
instructions:
  - name: C# Style Guide
    fileFilters:
      - "**/*.cs"
    instructions: |
      1. Follow Microsoft C# coding conventions
      2. Use XML documentation comments for public APIs
      3. Prefer async/await for asynchronous operations
      4. Use nullable reference types appropriately
      5. Follow .NET naming conventions (PascalCase for public members)
```

{{< /tab >}}

{{< tab title="COBOL" >}}

```yaml
instructions:
  - name: COBOL Style Guide
    fileFilters:
      - "**/*.CBL"
      - "**/*.cbl"
      - "**/*.COB"
      - "**/*.cob"
    instructions: |
      1. Use clear and meaningful names for variables and procedures
      2. Prefer COBOL-85 syntax where possible
      3. Use proper division structure (IDENTIFICATION, ENVIRONMENT, DATA, PROCEDURE)
      4. Document all paragraphs and sections with meaningful comments
      5. Use 88-level condition names for boolean flags and status codes
      6. Avoid GO TO statements, prefer PERFORM for structured programming
      7. Use proper error handling with declaratives or status code checking
      8. Define working storage variables with appropriate PICTURE clauses
      9. Use meaningful paragraph names that describe the operation
      10. For mainframe integration, document JCL dependencies and file layouts
```

{{< /tab >}}

{{< tab title="Go" >}}

```yaml
instructions:
  - name: Go Style Guide
    fileFilters:
      - "**/*.go"
    instructions: |
      1. Use idiomatic Go practices
      2. Ensure all public functions and types have documentation
      3. Prefer standard library packages over third-party ones when possible
```

{{< /tab >}}

{{< tab title="Java" >}}

```yaml
instructions:
  - name: Java Style Guide
    fileFilters:
      - "**/*.java"
    instructions: |
      1. Do not modernize Java 8 code to Java 11+ features, unless there is a GitLab issue or task specifically requesting modernization
      2. All public classes must have Javadoc describing purpose and usage
      3. All public methods must have Javadoc with @param and @return tags
      4. Include code examples in main class Javadoc
      5. All public methods must have at least one test case
```

{{< /tab >}}

{{< tab title="JavaScript/TypeScript" >}}

```yaml
instructions:
  - name: JavaScript/TypeScript Files
    fileFilters:
      - "src/**/*.js"
      - "src/**/*.jsx"
      - "src/**/*.ts"
      - "src/**/*.tsx"
      - "!**/*.test.js"
      - "!**/*.test.ts"
      - "!**/*.spec.js"
      - "!**/*.spec.ts"
    instructions: |
      1. Use const/let instead of var
      2. Prefer async/await over promise chains
      3. Add JSDoc comments for complex functions
      4. Ensure proper error handling in async code
      5. Avoid any 'any' types in TypeScript
```

{{< /tab >}}

{{< tab title="Kotlin" >}}

```yaml
instructions:
  - name: Kotlin Style Guide
    fileFilters:
      - "**/*.kt"
      - "**/*.kts"
    instructions: |
      1. Follow Kotlin coding conventions
      2. Prefer immutability (val over var)
      3. Use coroutines for asynchronous operations
      4. Leverage Kotlin's null safety features
      5. Document public APIs with KDoc
```

{{< /tab >}}

{{< tab title="MATLAB" >}}

```yaml
instructions:
  - name: MATLAB Style Guide
    fileFilters:
      - "**/*.m"
    instructions: |
      1. Use descriptive variable and function names with camelCase convention
      2. Vectorize operations instead of using loops where possible
      3. Document functions with H1 line and help text comments
      4. Preallocate arrays before loops to improve performance
      5. Use proper error handling with try-catch blocks and error() function
```

{{< /tab >}}

{{< tab title="Perl" >}}

```yaml
instructions:
  - name: Perl Style Guide
    fileFilters:
      - "**/*.pl"
      - "**/*.pm"
    instructions: |
      1. Follow idiomatic Perl practices
      2. Ensure proper module documentation
      3. Use strict and warnings pragmas
```

{{< /tab >}}

{{< tab title="PHP" >}}

```yaml
instructions:
  - name: PHP Style Guide
    fileFilters:
      - "**/*.php"
    instructions: |
      1. Follow PSR-12 coding standard
      2. Use type declarations for function parameters and return types
      3. Ensure compatibility with PHP 8+
      4. Use proper error handling and exceptions
      5. Document classes and methods with PHPDoc
```

{{< /tab >}}

{{< tab title="Python" >}}

```yaml
instructions:
  - name: Python Source Files
    fileFilters:
      - "**/*.py"
      - "!tests/**/*.py"
      - "!test_*.py"
    instructions: |
      1. All functions must have docstrings with parameters and return types
      2. Use type hints for function signatures
      3. Follow PEP 8 style conventions
      4. Ensure proper exception handling
      5. Avoid using bare 'except' clauses

  - name: Python Tests
    fileFilters:
      - "tests/**/*.py"
      - "test_*.py"
    instructions: |
      1. Use pytest fixtures for common setup
      2. Test names should clearly describe the scenario being tested
      3. Include assertions for both expected outcomes and edge cases
      4. Mock external dependencies appropriately
```

{{< /tab >}}

{{< tab title="Ruby" >}}

```yaml
instructions:
  - name: Ruby Style Guide
    fileFilters:
      - "*.rb"
      - "lib/**/*.rb"
      - "!spec/**/*.rb"  # Exclude test files
    instructions: |
      1. Follow Ruby style guide conventions
      2. Prefer symbols over strings for hash keys
      3. Use snake_case for methods/variables, SCREAMING_SNAKE_CASE for constants, CamelCase for classes
      4. Prefer Ruby 3.0+ features (pattern matching, endless methods) where appropriate
      5. Use proper error handling - raise exceptions over returning nil for errors
      6. Write idiomatic Ruby - use blocks, enumerables, and Ruby idioms over procedural patterns
      7. Use meaningful method names - use ? for predicates, ! for dangerous methods
      8. Prefer keyword arguments for methods with multiple parameters
      9. All public methods should have corresponding RSpec/Minitest tests
      10. Manage dependencies with Gemfile and ensure version compatibility
      11. Document thread-safe code and use proper synchronization for concurrent operations
      12. Handle signals (SIGTERM, SIGINT) properly for daemon processes
```

{{< /tab >}}

{{< tab title="R" >}}

```yaml
instructions:
  - name: R Style Guide
    fileFilters:
      - "**/*.r"
      - "**/*.R"
    instructions: |
      1. Follow tidyverse style guide conventions
      2. Use snake_case for variable and function names
      3. Document functions with roxygen2 comments
      4. Prefer vectorized operations over loops
      5. Use proper error handling with tryCatch and stop()
```

{{< /tab >}}

{{< tab title="Rust" >}}

```yaml
instructions:
  - name: Rust Style Guide
    fileFilters:
      - "**/*.rs"
    instructions: |
      1. Follow Rust idioms and conventions
      2. Use proper error handling with Result and Option types
      3. Avoid unsafe code unless absolutely necessary and well-documented
      4. Ensure all public items have documentation comments
```

{{< /tab >}}

{{< tab title="Scala" >}}

```yaml
instructions:
  - name: Scala Style Guide
    fileFilters:
      - "**/*.scala"
    instructions: |
      1. Follow Scala style guide conventions
      2. Prefer immutable data structures (val over var)
      3. Use pattern matching effectively for control flow
      4. Document public APIs with ScalaDoc
      5. Use proper error handling with Try, Either, or Option types
```

{{< /tab >}}

{{< tab title="Shell" >}}

```yaml
instructions:
  - name: Shell Script Style Guide
    fileFilters:
      - "**/*.sh"
      - "**/*.bash"
      - "**/*.zsh"
      - "**/*.ksh"
    instructions: |
      1. Always quote variables to prevent word splitting ("$var" not $var)
      2. Use proper error handling with set -euo pipefail at script start
      3. Document script purpose, parameters, and exit codes in header comments
      4. Prefer [[ ]] over [ ] for conditional tests
      5. Use meaningful function names and avoid complex one-liners
```

{{< /tab >}}

{{< tab title="SQL" >}}

```yaml
instructions:
  - name: SQL Style Guide
    fileFilters:
      - "**/*.sql"
    instructions: |
      1. Use uppercase for SQL keywords (SELECT, FROM, WHERE, JOIN)
      2. Always specify column names explicitly instead of using SELECT *
      3. For PostgreSQL use SERIAL/RETURNING, for MySQL use AUTO_INCREMENT, for Oracle use SEQUENCE
      4. For NoSQL (MongoDB) use proper indexing and aggregation pipelines to avoid N+1 queries
      5. Document database-specific features and expected performance characteristics
      6. Use proper indentation for complex queries and subqueries
```

{{< /tab >}}

{{< tab title="VHDL" >}}

```yaml
instructions:
  - name: VHDL Style Guide
    fileFilters:
      - "**/*.vhd"
      - "**/*.vhdl"
    instructions: |
      1. Follow IEEE VHDL coding standards
      2. Use meaningful signal and entity names with clear prefixes
      3. Document all entities, architectures, and processes with comments
      4. Use synchronous design practices with proper clock and reset handling
      5. Avoid combinational loops and ensure proper timing constraints
```

{{< /tab >}}

{{< tab title="Configuration files" >}}

```yaml
instructions:
  - name: Configuration Files
    fileFilters:
      - "*.yaml"
      - "*.yml"
      - "*.json"
      - "config/**/*"
      - "!.gitlab/**/*"
    instructions: |
      1. Do not include sensitive data (passwords, API keys)
      2. Use environment variables for environment-specific values
      3. Document all configuration options
      4. Validate configuration schema if possible
```

{{< /tab >}}

{{< tab title="Infrastructure-as-Code" >}}

```yaml
instructions:
  - name: Ansible Style Guide
    fileFilters:
      - "*.yaml"
      - "*.yml"
      - "playbooks/**/*.yaml"
      - "roles/**/*.yaml"
    instructions: |
      1. Use meaningful play and task names that describe the action
      2. Prefer modules over shell/command tasks when possible
      3. Use variables and defaults for reusability across environments
      4. Implement idempotency - tasks should be safe to run multiple times
      5. Use handlers for service restarts and notifications
      6. Document playbook purpose, required variables, and dependencies

  - name: Dockerfile Style Guide
    fileFilters:
      - "Dockerfile"
      - "*.dockerfile"
      - "Dockerfile.*"
    instructions: |
      1. Use specific base image tags, avoid 'latest'
      2. Minimize layers by combining RUN commands with && where logical
      3. Use multi-stage builds to reduce final image size
      4. Run containers as non-root user for security
      5. Use .dockerignore to exclude unnecessary files
      6. Document exposed ports, volumes, and environment variables

  - name: GitLab CI/CD Style Guide
    fileFilters:
      - ".gitlab-ci.yml"
      - "**/.gitlab-ci.yml"
    instructions: |
      1. Use job extends instead of YAML anchors for reusability
      2. Always use rules instead of only/except for job conditions
      3. Define appropriate caching strategies for dependencies
      4. Use stages to organize pipeline workflow logically
      5. Include security scanning templates (SAST, dependency scanning, secret detection)
      6. Document job purpose, required variables, and dependencies in comments

  - name: Helm Chart Style Guide
    fileFilters:
      - "Chart.yaml"
      - "values.yaml"
      - "templates/**/*.yaml"
    instructions: |
      1. Use semantic versioning for chart versions
      2. Provide sensible defaults in values.yaml with comments
      3. Use template functions for conditional logic and loops
      4. Include NOTES.txt with post-installation instructions
      5. Validate charts with helm lint before committing
      6. Document all configurable values and their purpose

  - name: Kubernetes Style Guide
    fileFilters:
      - "*.yaml"
      - "*.yml"
      - "k8s/**/*.yaml"
      - "kubernetes/**/*.yaml"
    instructions: |
      1. Use explicit API versions and avoid deprecated APIs
      2. Always define resource limits and requests for containers
      3. Use namespaces to organize resources logically
      4. Define liveness and readiness probes for all deployments
      5. Use ConfigMaps and Secrets instead of hardcoded values
      6. Document resource purpose and dependencies in metadata annotations

  - name: Terraform/OpenTofu Style Guide
    fileFilters:
      - "*.tf"
      - "*.tfvars"
    instructions: |
      1. Use consistent naming conventions for resources (environment_service_resource)
      2. Organize code into modules for reusability
      3. Use variables with descriptions and validation rules
      4. Define outputs for important resource attributes
      5. Use remote state with locking for team collaboration
      6. Document module purpose, inputs, outputs, and provider requirements
```

{{< /tab >}}

{{< /tabs >}}

### Example projects

For more custom review instructions use cases, see the following production examples:

- [GitLab development in `gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/duo/mr-review-instructions.yaml)
- [GitLab handbook](https://gitlab.com/gitlab-com/content-sites/handbook/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)
- [GitLab website](https://gitlab.com/gitlab-com/marketing/digital-experience/about-gitlab-com/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)
- [Developer Advocacy: Tanuki IoT Platform](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)

## Troubleshooting

When working with `mr-review-instructions.yaml`, you might encounter the following issues.

### Code Review Flow skips instructions or returns a generic review

If Code Review Flow skips your custom instructions or returns a generic review,
the file might have a structural problem. Use the custom instructions linter to
identify any issues.

#### Run the custom instructions linter

The custom instructions linter helps you validate your `mr-review-instructions.yaml` file.

The linter checks for:

- Invalid YAML syntax.
- Missing or unexpected top-level keys.
- Missing or blank required fields (`name`, `instructions`).
- Unknown keys in an instruction entry, such as `rules` instead of `instructions`.
- `fileFilters` values that are not lists or contain non-string or blank entries.
- Missing or empty `fileFilters`, which causes the instruction to apply to every file (info).
- Duplicate `name` values across instruction entries.

> [!note]
> The linter reads the file only and does not modify it.
> It has no GitLab or Rails dependencies and runs anywhere with Ruby installed.

Prerequisites:

- Ruby 3.0 or later.

To run the linter as a Rake task on a GitLab server, replace `<path>` with the path to
your `mr-review-instructions.yaml` file. For example:

```shell
sudo gitlab-rake "gitlab:duo:lint_review_instructions[<path>]"
```

To run the linter as a standalone script on any machine with Ruby installed:

1. Download [`review_instructions_linter.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/review_instructions_linter.rb).
1. Run the linter. Replace `<path>` with the path to your `mr-review-instructions.yaml` file.

   ```shell
   ruby -r ./review_instructions_linter.rb -e '
     linter = Gitlab::Duo::Administration::ReviewInstructionsLinter.new(ARGV[0]).run
     linter.issues.each { |issue| puts issue }
     exit(linter.valid? ? 0 : 1)
   ' <path>
   ```

If you omit the path, the linter defaults to `.gitlab/duo/mr-review-instructions.yaml`
in the working directory. The linter exits with status `0` if no errors are found, or
`1` otherwise. Warnings and info messages do not cause a non-zero exit.

For example, this invalid file uses `rules` instead of `instructions` and omits
`fileFilters`:

```yaml
instructions:
  - name: "General"
    rules: "Do something"
```

The linter reports:

```plaintext
[ERROR E009] Field 'instructions' must be a non-empty string at instructions[0]
[WARNING W003] Unknown keys: "rules"; expected name, instructions, fileFilters at instructions[0]
[INFO I001] Missing 'fileFilters'; the instruction applies to every file at instructions[0]
```

Fix the reported errors and re-run the linter until it reports no errors.

#### Linter message codes

Each message includes a stable code that you can refer to when you ask for help.
Codes that start with `E` are errors, codes that start with `W` are warnings, and
codes that start with `I` are informational notes about valid but worth-knowing behavior.

| Code | Description |
| ---- | ----------- |
| `E001` | The file does not exist at the given path. |
| `E003` | The file contains invalid YAML syntax. |
| `E004` | The top-level YAML value is not a mapping. |
| `E005` | The top-level `instructions` key is missing. |
| `E006` | The `instructions` value is not a list. |
| `E007` | An entry under `instructions` is not a mapping. |
| `E008` | An entry's `name` field is missing, blank, or not a string. |
| `E009` | An entry's `instructions` field is missing, blank, or not a string. |
| `E011` | An entry's `fileFilters` value is not a list. |
| `E013` | An entry's `fileFilters` contains a non-string value, such as a number. |
| `E014` | An entry's `fileFilters` contains a blank string. |
| `W001` | The file contains an unknown top-level key. |
| `W002` | The `instructions` list is empty, so no instructions apply. |
| `W003` | An entry contains keys other than `name`, `instructions`, and `fileFilters`. |
| `W004` | Two or more entries share the same `name`. |
| `W007` | The file is empty, so no instructions apply. |
| `I001` | An entry is missing the `fileFilters` field, so the instruction applies to every file. |
| `I002` | An entry's `fileFilters` list is empty, so the instruction applies to every file. |

## Related topics

- [GitLab Duo in merge requests](../../project/merge_requests/duo_in_merge_requests.md)
- [Code Review Flow](../flows/foundational_flows/code_review.md)
