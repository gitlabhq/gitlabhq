---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: マージリクエストのレビューでAIが使用する指示をカスタマイズします。
title: Agent Platformに合わせてレビュー指示をカスタマイズする
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/545136)されたGitLab 18.2の[ベータ](../../../policy/development_stages_support.md#beta)版として、`duo_code_review_custom_instructions`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)が提供されています。デフォルトでは無効になっています。
- 機能フラグ`duo_code_review_custom_instructions`は、GitLab 18.3で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199802)になっています。
- 機能フラグ`duo_code_review_custom_instructions`は、GitLab 18.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202262)されました。
- GitLab 19.1で`fileFilters`の和集合パターン（例: `{rb,ts}`）が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237952)されました。

{{< /history >}}

GitLab Duoがマージリクエストをレビューする際に参照する標準を提供するための、カスタムレビュー指示を作成します。

たとえば、RubyファイルではRubyのスタイル規則を、GoファイルではGoのスタイル規則を重視するよう、GitLab Duoに指示できます。

> [!note]
> カスタムレビュー指示は、AIレビュアー向けのガイダンスであり、強制的なポリシーではありません。GitLab Duoは、レビューを形成するためのコンテキストとしてこれらを使用しますが、すべての指示がすべての場合に適用されることを保証することはできません。セキュリティ管理、コンプライアンス上の義務、または一貫した強制が必要なその他の要件のためにカスタム指示に依存しないでください。

GitLab Duoは、標準のレビュー基準を置き換えるのではなく、カスタムレビュー指示を追加する形で適用します。

コードレビューフローは、プロジェクト、グループ、またはインスタンスのカスタムレビュー指示をサポートします。

## プロジェクトのカスタムレビュー指示を設定する {#configure-custom-review-instructions-for-a-project}

カスタムマージリクエストレビュー指示を設定するには:

1. リポジトリのルートで、`.gitlab/duo`ディレクトリが存在しない場合は作成します。
1. `.gitlab/duo`ディレクトリに、`mr-review-instructions.yaml`という名前のファイルを作成します。
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

   `fileFilters`セクションはオプションです。このセクションでは、globパターンを使用して、特定のファイルを対象とする指示を定めます。`fileFilters`を省略するか、空のままにすると、GitLab Duoはマージリクエスト内のすべてのファイルに指示を適用します。

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

   指示内のファイル参照の詳細については、[指示内のファイル参照](#reference-files-in-instructions)を参照してください。

   glob構文の例については、[ファイルパターンのリファレンス](#file-pattern-reference)を参照してください。

1. オプション: `mr-review-instructions.yaml`ファイルへの変更を保護するために、[コードオーナー](../../project/codeowners/_index.md)エントリを追加します。

   ```markdown
   [GitLab Duo]
   .gitlab/duo @default-owner @tech-lead
   ```

1. 変更内容をレビューしてマージするための[マージリクエストを作成](../../project/merge_requests/creating_merge_requests.md)します:

   - ファイルパターンが一致した場合、GitLab Duoはカスタム指示を自動的に適用します。
   - 複数の指示グループを1つのファイルに適用できます。ファイルが複数のグループの`fileFilters`に一致する場合、コードレビューフローは、一致するすべてのグループからの指示を適用します。
   - カスタム指示によってトリガーされたレビューコメントについて、GitLab Duoは次の形式を使用します:

     ```plaintext
     According to custom instructions in '[instruction_name]': [feedback comments]
     ```

     `instruction_name`の値は、`.gitlab/duo/mr-review-instructions.yaml`ファイルの`name`プロパティに対応しています。標準のGitLab Duoコメントでは、この形式は使用されません。
     <br><br>
     GitLab Duoが問題を検出しない場合、レビューサマリ―コメントを残します。カスタム指示は、このサマリ―コメントには適用されません。
1. オプション: 
   - フィードバックをレビューし、必要に応じて指示を調整します。
   - パターンをテストして、意図したファイルと一致することを確認します。

## グループのカスタムレビュー指示を設定する {#configure-custom-review-instructions-for-a-group}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230090)されました。

{{< /history >}}

グループのカスタムレビュー指示は、テンプレートとして使用するプロジェクトを指定することで定義できます。テンプレートプロジェクトには、グループとそのサブグループ内のすべてのプロジェクトに適用されるレビュー指示を含む`.gitlab/duo/mr-review-instructions.yaml`ファイルが必要です。

GitLab Duoがコードレビューを実行すると、トップレベルグループの指示と、個々のプロジェクトで定義された指示が組み合わされます。

前提条件: 

- トップレベルグループのオーナーロール。
- グループ内のプロジェクトに、テンプレートとして使用するカスタムレビュー指示が含まれていること。

グループのカスタムレビュー指示を設定するには:

1. 上部のバーで**検索または移動先**を選択して、トップレベルグループを見つけます。
1. 左側のサイドバーで、**設定** > **一般** > **GitLab Duoの機能**を選択します。
1. **Customize code review**の下で、グループのレビュー指示を含む`.gitlab/duo/mr-review-instructions.yaml`ファイルを持つプロジェクトを選択します。
1. **変更を保存**を選択します。

## インスタンスのカスタムレビュー指示を設定する {#configure-custom-review-instructions-for-an-instance}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237573)されました。

{{< /history >}}

GitLab Self-ManagedおよびGitLab Dedicatedでは、テンプレートとして使用するプロジェクトを指定することで、インスタンス全体のカスタムレビュー指示を定義できます。テンプレートプロジェクトには、インスタンス上のすべてのプロジェクトに適用されるレビュー指示を含む`.gitlab/duo/mr-review-instructions.yaml`ファイルが含まれている必要があります。

GitLab Duoがコードレビューを実行すると、インスタンスの指示とグループおよびプロジェクトの指示が結合されます。

前提条件: 

- インスタンスへの管理者アクセス。
- インスタンス上のプロジェクトには、テンプレートとして使用するカスタムレビュー指示が含まれています。

インスタンスのカスタムレビュー指示を設定するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **Customize code review for all groups in this instance**の下で、レビュー指示を含む`.gitlab/duo/mr-review-instructions.yaml`ファイルを持つプロジェクトを選択します。
1. **変更を保存**を選択します。

## 指示内のファイルを参照する {#reference-files-in-instructions}

コンテンツを重複させる代わりに、カスタム指示で他のファイルを参照できます。コードレビューフローは、プレスキャンステップ中に参照されたファイルを読み込み、関連するガイダンスを抽出します。

カスタム指示は、2つのファイル参照パターンをサポートしています:

- マージリクエストと同じプロジェクト内のファイル: リポジトリ相対パス、例えば`docs/security-checklist.md`を使用します。
- 同じGitLabインスタンス上の他のプロジェクト内のファイル: GitLabの完全なblob URL、例えば`https://gitlab.example.com/group/project/-/blob/main/docs/style-guide.md`を使用します。URLはマージリクエストと同じGitLabインスタンスを指し、`/-/blob/<ref>/<path>`の形式を使用する必要があります。

例: 

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

### ファイル参照の制限 {#limitations-of-file-references}

ファイル参照の解決には、次の制約があります:

- 同じGitLabインスタンスのみ。別のGitLabインスタンス、GitLab Self-Managedからの公開GitLab、またはConfluenceや公開ドキュメントサイトのようなGitLab以外のサイトを指すURLは、フェッチされません。
- blob URLのみ。形式は`/-/blob/<ref>/<path>`です。Wikiページ、イシュー、raw URL、およびスニペットはフェッチされません。
- ベアパスの場合は同じプロジェクト。`docs/security.md`のようなベアパスは、マージリクエストと同じプロジェクトに対して解決します。別のプロジェクト内のファイルを参照するには、完全なGitLabblob URLを使用します。
- 最善を尽くしますが、保証はありません。コードレビューフローは、指示テキストに基づいてどの参照をフェッチするかを決定します。存在しないパスや解析によって拒否されたURLなど、解決に失敗した参照は、サイレントにスキップされます。
- コードレビューフローは、元のファイルではなく、要約を使用します。プレスキャンステップ中にフェッチされたコンテンツを要約し、レビュー中にその要約を使用します。同じマージリクエストの2つのレビューは、異なる要約を生成する可能性があります。

コードレビューフローにファイルの正確な内容を使用させ、要約を使用させない場合は、ファイルを参照するのではなく、`instructions:`フィールドに直接含めます。インライン指示は記述されたとおりに使用されます。

## ベストプラクティス {#best-practices}

カスタムレビュー指示を作成する場合、次の点に留意してください:

- 具体的かつ実行可能な指示を作成する。コードレビューフローは、各ルールを差分と照合して確認します。例えば、「パブリックメソッドにYARDドキュメントがあることを検証する」のような具体的なルールは有用なコメントを生成しますが、「コードを適切にドキュメントする」のような抽象的なガイダンスはそうではありません。
- わかりやすくするために、指示に番号を付ける。
- 最も重要な標準に焦点を当てる。すべてのルールのテキストは、レビュープロンプトの一部となるため、価値の低いルールの長いリストは、シグナルを追加することなくプロンプトを膨らませます。
- 有用な場合は、「理由」を説明する。
- 簡単な指示から始め、必要に応じてより複雑な指示を追加する。
- コードレビューフローがデフォルトでは適用しない、プロジェクト固有の標準に焦点を当てます。カスタム指示は、標準レビュー基準を置き換えるのではなく、追加します。「エラー処理を追加する」や「意味のある名前を使用する」といった一般的なアドバイスは、通常すでにカバーされています。内部API、アーキテクチャ規則、ドメイン固有のパターンなど、プロジェクトだけが知っていることのためにカスタム指示を使用します。
- 指示はガイダンスとして記述し、命令として記述しないでください。指示は、レビューの振る舞いを形作るヒントであり、GitLab Duoが従うべきポリシーではありません。「常にフラグを立てる」や「決して許可しない」といった表現は避けてください。この表現は、共同作業者をその動作が保証されていると誤解させる可能性があります。
- ファイルパターンは、ルールの実際のスコープを反映するようにしてください。コードレビューフローは、各指示を各`fileFilters`参照と共に読み込み、それらのパターンに一致するファイルにのみルールを適用します。例えば、`**/*.rb`にスコープされた「Railsコントローラー」のルールは、gem、スクリプト、テストに適用され、コントローラーだけではありません。代わりに`app/controllers/**/*.rb`を使用してください。
- 正確な表現が重要ではない指示に対してのみ外部ファイル参照を使用し、そうでない場合は詳細をルールとして`instructions:`フィールドに直接含めます。コードレビューフローは、参照されたファイルの要約を生成して使用しますが、`instructions`で定義された正確な表現を使用します。

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
| `**/*.{js,jsx}` | すべてのディレクトリ内のJavaScriptファイルとJSXファイル（GitLab 19.1以降） |

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
Inspired by the reference in <https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml?ref_type=heads>
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
- [GitLabハンドブック](https://gitlab.com/gitlab-com/content-sites/handbook/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)
- [GitLab Webサイト](https://gitlab.com/gitlab-com/marketing/digital-experience/about-gitlab-com/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)
- [デベロッパーアドボカシー: Tanuki IoT Platform](https://gitlab.com/gitlab-da/use-cases/ai/gitlab-duo-agent-platform/demo-environments/tanuki-iot-platform/-/blob/main/.gitlab/duo/mr-review-instructions.yaml)

## トラブルシューティング {#troubleshooting}

`mr-review-instructions.yaml`を使用する際に、次のイシューが発生する可能性があります。

### コードレビューフローが指示をスキップするか、一般的なレビューを返す {#code-review-flow-skips-instructions-or-returns-a-generic-review}

コードレビューフローがカスタム指示をスキップしたり、一般的なレビューを返したりする場合、ファイルに構造上の問題がある可能性があります。カスタム指示のLinterを使用して、イシューを特定します。

#### カスタム指示のLinterを実行する {#run-the-custom-instructions-linter}

カスタム指示のLinterは、`mr-review-instructions.yaml`ファイルを検証するのに役立ちます。

Linterは以下をチェックします:

- 無効なYAML構文。
- 見つからないか、予期しないトップレベルのキー。
- 必須フィールド（`name`, `instructions`）の欠落または空白。
- 指示エントリ内の不明なキー（`instructions`の代わりに`rules`など）。
- `fileFilters`の値がリストではないか、非文字列または空白のエントリが含まれている。
- `fileFilters`が見つからないか空である場合、指示がすべてのファイルに適用されます（情報）。
- 指示エントリ間で`name`の値が重複している。

> [!note]
> Linterはファイルを読み取るだけで、変更はしません。GitLabまたはRailsの依存関係はなく、Rubyがインストールされていればどこでも実行できます。

前提条件: 

- Ruby 3.0以降。

GitLabサーバーでLinterをRakeタスクとして実行するには、`<path>`を`mr-review-instructions.yaml`ファイルのパスに置き換えてください。例: 

```shell
sudo gitlab-rake "gitlab:duo:lint_review_instructions[<path>]"
```

Rubyがインストールされている任意のマシンでLinterをスタンドアロンスクリプトとして実行するには:

1. [`review_instructions_linter.rb`](https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/lib/gitlab/duo/administration/review_instructions_linter.rb)をダウンロードします。
1. Linterを実行します。`<path>`を`mr-review-instructions.yaml`ファイルのパスに置き換えてください。

   ```shell
   ruby -r ./review_instructions_linter.rb -e '
     linter = Gitlab::Duo::Administration::ReviewInstructionsLinter.new(ARGV[0]).run
     linter.issues.each { |issue| puts issue }
     exit(linter.valid? ? 0 : 1)
   ' <path>
   ```

パスを省略すると、Linterは作業ディレクトリ内の`.gitlab/duo/mr-review-instructions.yaml`をデフォルトとして使用します。エラーが見つからない場合、Linterはステータス`0`で終了し、それ以外の場合は`1`で終了します。警告および情報メッセージは、ゼロ以外の終了を引き起こしません。

例えば、この無効なファイルは`instructions`の代わりに`rules`を使用し、`fileFilters`を省略しています:

```yaml
instructions:
  - name: "General"
    rules: "Do something"
```

Linterは次のようにレポートします:

```plaintext
[ERROR E009] Field 'instructions' must be a non-empty string at instructions[0]
[WARNING W003] Unknown keys: "rules"; expected name, instructions, fileFilters at instructions[0]
[INFO I001] Missing 'fileFilters'; the instruction applies to every file at instructions[0]
```

報告されたエラーを修正し、エラーがレポートされなくなるまでLinterを再実行します。

#### Linterメッセージコード {#linter-message-codes}

各メッセージには、ヘルプを求めるときに参照できる安定したコードが含まれています。`E`で始まるコードはエラー、`W`で始まるコードは警告、`I`で始まるコードは有効であるが知っておくべき動作に関する情報メモです。

| コード | 説明 |
| ---- | ----------- |
| `E001` | 指定されたパスにファイルが存在しません。 |
| `E003` | ファイルに無効なYAML構文が含まれています。 |
| `E004` | トップレベルのYAML値はマッピングではありません。 |
| `E005` | トップレベルの`instructions`キーがありません。 |
| `E006` | `instructions`の値がリストではありません。 |
| `E007` | `instructions`の下のエントリがマッピングではありません。 |
| `E008` | エントリの`name`フィールドが欠落しているか、空白であるか、または文字列ではありません。 |
| `E009` | エントリの`instructions`フィールドが欠落しているか、空白であるか、または文字列ではありません。 |
| `E011` | エントリの`fileFilters`の値がリストではありません。 |
| `E013` | エントリの`fileFilters`に、数値などの非文字列値が含まれています。 |
| `E014` | エントリの`fileFilters`に空白文字列が含まれています。 |
| `W001` | ファイルに不明なトップレベルのキーが含まれています。 |
| `W002` | `instructions`リストは空なので、指示は適用されません。 |
| `W003` | エントリには、`name`、`instructions`、および`fileFilters`以外のキーが含まれています。 |
| `W004` | 2つ以上のエントリが同じ`name`を共有しています。 |
| `W007` | ファイルが空なので、指示は適用されません。 |
| `I001` | エントリに`fileFilters`フィールドが欠落しているため、指示はすべてのファイルに適用されます。 |
| `I002` | エントリの`fileFilters`リストが空であるため、指示はすべてのファイルに適用されます。 |

## 関連トピック {#related-topics}

- [マージリクエストにおけるGitLab Duo](../../project/merge_requests/duo_in_merge_requests.md)
- [コードレビューフロー](../flows/foundational_flows/code_review.md)
