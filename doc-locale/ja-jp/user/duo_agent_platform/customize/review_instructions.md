---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: マージリクエストのレビューでAIが使用する指示をカスタマイズします。
title: レビュー手順をエージェントプラットフォームに合わせてカスタマイズ
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.2で`duo_code_review_custom_instructions`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[ベータ版](../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/545136)されました。デフォルトでは無効になっています。
- 機能フラグ`duo_code_review_custom_instructions`は、GitLab 18.3で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199802)になっています。
- 機能フラグ`duo_code_review_custom_instructions`は、GitLab 18.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202262)されました。

{{< /history >}}

カスタムマージリクエストレビュー指示を作成して、GitLab Duoがプロジェクト内で一貫性のある具体的なコードレビュー標準を適用するようにします。

たとえば、Rubyファイルに対してのみRubyスタイルの規則を適用し、Goファイルに対してはGoスタイルの規則を適用できます。

GitLab Duoは、標準のレビュー基準を置き換えるのではなく、カスタムレビュー指示を追加する形で適用します。

コードレビューフローは、カスタムレビュー手順をサポートしています。

## カスタムレビュー指示を設定する {#configure-custom-review-instructions}

カスタムマージリクエストレビュー指示を設定するには:

1. リポジトリのルートで、`.gitlab/duo`ディレクトリが存在しない場合は作成します。
1. `.gitlab/duo`ディレクトリに、`mr-review-instructions.yaml`という名前のファイルを作成します。
1. オプション。[GitLab Duo Chat（エージェント）](../../gitlab_duo_chat/agentic_chat.md)にコードベースとドキュメントを分析させて、カスタムレビュー指示を生成させます。

   プロンプトの例:

   ```plaintext
   I need to create custom rules for GitLab Duo Code Review. When you look at the source code,
   which languages are missing and need to be added to the mr-review-instructions.yaml
   file?
   ```

1. 次の形式を使用して、カスタム指示を追加します:

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

   `fileFilters`セクションでglobパターンを使用して、カスタムレビュールールの対象となる特定のファイルを指定します。

   例: 

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
   ```

   glob構文の例については、[ファイルパターンのリファレンス](#file-pattern-reference)を参照してください。

1. オプション: `mr-review-instructions.yaml`ファイルへの変更を保護するために、[コードオーナー](../../project/codeowners/_index.md)エントリを追加します。

   ```markdown
   [GitLab Duo]
   .gitlab/duo @default-owner @tech-lead
   ```

1. 変更内容をレビューしてマージするための[マージリクエストを作成](../../project/merge_requests/creating_merge_requests.md)します:

   - ファイルパターンが一致した場合、GitLab Duoはカスタム指示を自動的に適用します。
   - 複数の指示グループを1つのファイルに適用できます。
   - カスタム指示によってトリガーされたレビューコメントについて、GitLab Duoは次の形式を使用します:

     ```plaintext
     According to custom instructions in '[instruction_name]': [feedback comments]
     ```

     `instruction_name`の値は、`.gitlab/duo/mr-review-instructions.yaml`ファイルの`name`プロパティに対応しています。標準のGitLab Duoコメントでは、この形式は使用されません。
1. オプション: 
   - フィードバックをレビューし、必要に応じて指示を調整します。
   - パターンをテストして、意図したファイルと一致することを確認します。

## ベストプラクティス {#best-practices}

カスタムレビュー指示を作成する場合、次の点に留意してください:

- 具体的かつ実行可能な指示を作成する。
- わかりやすくするために、指示に番号を付ける。
- 最も重要な標準に焦点を当てる。
- 有用な場合は、「理由」を説明する。
- 簡単な指示から始め、必要に応じてより複雑な指示を追加する。

例: 

```yaml
instructions: |
  1. All public functions must include docstrings with parameter descriptions
  2. Use parameterized queries to prevent SQL injection
  3. Validate user input before processing (check type, length, format)
  4. Include error handling for all external API calls
  5. Avoid hardcoded credentials - use environment variables
```

言語別の例については、[ユースケースの例](#use-case-examples)を参照してください。

## ファイルパターンのリファレンス {#file-pattern-reference}

`fileFilters`のglobパターンを使用して、特定のファイルをターゲットにします。

たとえば、Rubyファイルを含むプロジェクトの場合は次のとおりです:

| パターン | マッチ |
| --- | --- |
| `**/*.rb`       | 任意のディレクトリ内のすべてのRubyファイル |
| `*.rb`          | ルートディレクトリ直下のRubyファイルのみ |
| `lib/**/*.rb`   | `lib`ディレクトリとそのサブディレクトリ内のRubyファイル |
| `!**/*.test.rb` | すべてのRubyテストファイルを除外する |
| `!spec/**/*.rb` | `spec`ディレクトリとそのサブディレクトリ内のすべてのRubyファイルを除外する |
| `!tests/**/*`   | `tests`ディレクトリとそのサブディレクトリ内のすべてのファイルを除外する |
| `**/*.{js,jsx}` | すべてのディレクトリ内のJavaScriptファイルおよびJSXファイル |

次の例は、`**/*.rb`と`*.rb`の違いを示しています:

```plaintext
project/
├── app.rb              ← matched by both *.rb and **/*.rb
├── lib/
│   └── helper.rb       ← matched only by **/*.rb
└── app/
    └── models/
        └── user.rb     ← matched only by **/*.rb
```

- `*.rb`はapp.rbのみに一致します
- `**/*.rb`は3つすべてのファイルに一致します

`mr-review-instructions.yaml`ファイルでは、`**/*.rb`を使用することで、ルートディレクトリに限らず、プロジェクト構造内のあらゆる場所にあるRubyファイルにレビュー指示を適用できます。

## ユースケースの例 {#use-case-examples}

<!-- 2025-11-12 Use case examples are maintained by DevRel, @dnsmichi
Inspired by the reference in https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml?ref_type=heads
-->

{{< tabs >}}

{{< tab title="アセンブリ" >}}

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

{{< tab title="設定ファイル" >}}

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

{{< tab title="Infrastructure as Code" >}}

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

### プロジェクトの例 {#example-projects}

カスタムレビュー指示のその他のユースケースについては、次の本番環境の例を参照してください:

- [`gitlab-org/gitlab`におけるGitLabの開発](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/duo/mr-review-instructions.yaml)
- [GitLabハンドブック](https://gitlab.com/gitlab-com/content-sites/handbook/-/blob/main/.gitlab/duo/mr-review-instructions.yml)
- [GitLab Webサイト](https://gitlab.com/gitlab-com/marketing/digital-experience/about-gitlab-com/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)
- [デベロッパーアドボカシー: Tanuki IoT Platform](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)

## 関連トピック {#related-topics}

- [マージリクエストにおけるGitLab Duo](../../project/merge_requests/duo_in_merge_requests.md)
- [コードレビューフロー](../../duo_agent_platform/flows/foundational_flows/code_review.md)
