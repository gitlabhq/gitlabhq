---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: GitLab Duoワークフローを使用して、Javaのコーディングスタイルガイドラインをプロジェクトに自動的に適用する方法、および設定、実行、サンプルユースケースについて説明します。
title: コーディングスタイルを適用するためのDuo Workflowのユースケース
---

{{< details >}}

- プラン: UltimateプランとGitLab Duoワークフロー
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

## はじめに {#getting-started}

### ソリューションコンポーネントのダウンロード {#download-the-solution-component}

1. アカウントチームから招待コードを入手してください。
1. 招待コードを使用して、[ソリューションコンポーネントウェブストア](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントをダウンロードします。

## Duoワークフローのユースケース: スタイルガイドを使用したJavaアプリケーションの改善 {#duo-workflow-use-case-improve-java-application-with-style-guide}

このドキュメントでは、プロンプトとコンテキストライブラリを使用したGitLab Duoワークフローソリューションについて説明します。このソリューションの目的は、定義されたスタイルに基づいてアプリケーションのコーディングを改善することです。

このソリューションは、プロンプトとしてGitLabイシューを提供し、コンテキストとしてスタイルガイドを提供し、GitLab Duoワークフローを使用してJavaのスタイルガイドラインをコードベースに自動化するように設計されています。プロンプトおよびコンテキストライブラリを使用すると、Duoワークフローで次のことが可能になります:

1. GitLabリポジトリに保存されている集中管理されたスタイルガイドコンテンツへのアクセス
1. ドメイン固有のコーディング標準の理解
1. 機能を維持しながら、Javaコードに一貫したフォーマットを適用します。

GitLab Duoワークフローの詳細については、[こちらのドキュメント](../../../user/duo_agent_platform/_index.md)をご覧ください。

### 主な利点 {#key-benefits}

- すべてのJavaコードベースで**Enforces consistent style**（一貫したスタイルを適用）
- 手作業なしで**Automates style application**（スタイル適用を自動化）
- 読みやすさを向上させながら**Maintains code functionality**（コードの機能を維持）
- シームレスな実装のために**Integrates with GitLab Workflow**（GitLabワークフローとインテグレーション）
- スタイルに関する問題の対応に費やす**Reduces code review time**（コードレビュー時間を削減）
- スタイルガイドラインを理解するための**Serves as a learning tool**（デベロッパー向けの学習ツールとして機能）

### サンプル結果 {#sample-result}

適切に設定すると、プロンプトはコードをエンタープライズ標準に一致するように変換します。この差分に示す変換と同様です:

![手順、タスク分析、解決策の手順を表示するDuoワークフロービュー](img/duoworkflow-style_output_v17_10.png)

![Duoワークフローによるスタイルガイド変換後の一貫したフォーマットによる更新されたコードスニペット](img/duoworkflow_style_code_transform_v17_10.png)

## ソリューションのプロンプトとコンテキストライブラリの設定 {#configure-the-solution-prompt-and-context-library}

### 基本設定 {#basic-setup}

アプリケーションのスタイルをレビューして適用するエージェント型ワークフローを実行するには、このユースケースのプロンプトとコンテキストライブラリをセットアップする必要があります。

1. `Enterprise Code Quality Standards`プロジェクトをクローンして**Set up the prompt and context library**（プロンプトとコンテキストライブラリをセットアップする）
1. ライブラリファイル`.gitlab/workflows/java-style-workflow.md`からプロンプトコンテンツを使用して**Create a GitLab issue**（GitLabイシューを作成する） `Review and Apply Style`
1. `Review and Apply Style`で、**In the issue**（イシューに）[設定セクション](#configuration-guide)で詳述されているように、ワークフロー変数を設定します
1. `Enterprise Code Quality Standards`プロジェクトで**In your VS code**（VS Code）で、簡単な[ワークフロープロンプト](#example-duo-workflow-prompt)を使用してDuoワークフローを開始します
1. 提案された計画と自動化されたタスクをレビューすることにより**Work with the Duo Workflow**（Duoワークフローを操作）し、必要に応じて、ワークフローにさらに入力を追加します
1. **Review and commit**（レビューして）スタイルが適用されたコードの変更をリポジトリにコミットします

### Duoワークフロープロンプトの例 {#example-duo-workflow-prompt}

```yaml
Follow the instructions in issue <issue_reference_id> for the file <path/file_name.java>. Make sure to access any issues or GitLab projects mentioned in the issue to retrieve all necessary information.
```

この簡単なプロンプトが強力なのは、Duoワークフローに次のことを指示するためです:

1. 特定のイシューIDで詳細な要件を読み取ります
1. 参照されているスタイルガイドリポジトリにアクセスする
1. 指定されたファイルにガイドラインを適用する
1. イシューのすべての指示に従ってください

## 設定ガイド {#configuration-guide}

プロンプトは、ソリューションパッケージの`.gitlab/workflows/java-style-workflow.md`ファイルで定義されています。このファイルは、AIアシスタントに指示するGitLabイシューを作成するためのテンプレートとして機能します。このイシューは、アプリケーションのスタイルガイドのレビューを自動化し、変更を適用するための計画をビルドするようにエージェントに指示します。

`.gitlab/workflows/java-style-workflow.md`の最初のセクションでは、プロンプトに設定する必要がある変数を定義します。

### 変数の定義 {#variable-definition}

変数は、`.gitlab/workflows/java-style-workflow.md`ファイルで直接定義されます。このファイルは、AIアシスタントに指示するGitLabイシューを作成するためのテンプレートとして機能します。このファイルで変数を変更してから、そのコンテンツを含む新しいイシューを作成します。

#### 1\.コンテキストとしてのスタイルガイドリポジトリ {#1-style-guide-repository-as-the-context}

プロンプトは、組織のスタイルガイドリポジトリを指すように設定する必要があります。`java-style-prompt.md`ファイルで、次の変数を置き換えます:

- `{{GITLAB_INSTANCE}}`: GitLabインスタンスのURL（例：`https://gitlab.example.com`）
- `{{STYLE_GUIDE_PROJECT_ID}}`: Javaスタイルガイドを含むGitLabプロジェクトID
- `{{STYLE_GUIDE_PROJECT_NAME}}`: スタイルガイドプロジェクトの表示名
- `{{STYLE_GUIDE_BRANCH}}`: 最新のスタイルガイドを含むブランチ (デフォルト: main)
- `{{STYLE_GUIDE_PATH}}`: リポジトリ内のスタイルガイドドキュメントへのパス

例: 

```yaml
GITLAB_INSTANCE=https://gitlab.example.com
STYLE_GUIDE_PROJECT_ID=gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards
STYLE_GUIDE_PROJECT_NAME=Enterprise Java Standards
STYLE_GUIDE_BRANCH=main
STYLE_GUIDE_PATH=coding-style/java/guidelines/java-coding-standards.md
```

#### 2\.スタイル改善を適用するためのターゲットリポジトリ {#2-target-repository-to-apply-style-improvement}

同じ`java-style-prompt.md`ファイルで、スタイルガイドを適用するファイルを設定します:

- `{{TARGET_PROJECT_ID}}`: JavaプロジェクトのGitLab ID
- `{{TARGET_FILES}}`: ターゲットにする特定のファイルまたはパターン（例：「src/main/java/\*\*/*.java」）

例: 

```yaml
TARGET_PROJECT_ID=royal-reserve-bank
TARGET_FILES=asset-management-api/src/main/java/com/royal/reserve/bank/asset/management/api/service/AssetManagementService.java
```

### AI生成コードに関する重要な注意事項 {#important-notes-about-ai-generated-code}

**⚠️ Important Disclaimer**（⚠️重要な免責事項）:

GitLabワークフローは非決定的なエージェント型AIを使用します。つまり:

- 同一の入力を使用しても、実行ごとに結果が異なる場合があります
- AIアシスタントのスタイルガイドの理解と適用は、毎回わずかに異なる場合があります
- このドキュメントで提供されている例は説明用であり、実際の結果は異なる場合があります

**Best Practices for Working with AI-Generated Code Changes**（AI生成コードの変更を操作するためのベストプラクティス）:

1. **Always review generated code**（生成されたコードを常にレビューする）: 綿密な人間のレビューなしに、AI生成された変更をマージしないでください
1. **Follow proper merge request processes**（適切なマージリクエストプロセスに従う）: 標準のコードレビュー手順を使用します
1. **Run all tests**（すべてのテストを実行する）: マージする前に、すべてのユニットテストとインテグレーションテストが合格していることを確認します
1. **Verify style compliance**（スタイルコンプライアンスを検証する）: 変更がスタイルガイドの期待に沿っていることを確認します
1. **Incremental application**（段階的な適用）: 最初は、より少ないファイルセットにスタイルの変更を適用することを検討してください

このツールは、コードレビュープロセスにおける人間の判断に代わるものではなく、デベロッパーを支援することを目的としていることを忘れないでください。

## ステップごとの実装 {#step-by-step-implementation}

1. **Create a Style Guide Issue**（スタイルガイドイシューを作成する）

   - プロジェクトで新しいイシューを作成します（たとえば、イシュー＃3）
   - 適用するスタイルガイドラインに関する詳細情報を含めます
   - 該当する場合は、外部スタイルガイドリポジトリを参照してください
   - 次のような要件を指定します:

     ```yaml
     Task: Code Style Update
     Description: Apply the enterprise standard Java style guidelines to the codebase.
     Reference Style Guide: Enterprise Java Style Guidelines (https://gitlab.com/gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards/-/blob/main/coding-style/java/guidelines/java-coding-standards.md)
     Constraints:
     - Adhere to Enterprise Standard Java Style Guide
     - Maintain Functionality
     - Implement automated style checks
     ```

1. **Configure the Prompt**（プロンプトを設定する）

   - `java-style-prompt.md`からテンプレートをコピーします
   - すべての設定変数を入力します
   - プロジェクト固有の例外または要件を追加します

1. **Execute via GitLab Workflow**（GitLabワークフロー経由で実行する）

   - 設定されたプロンプトをDuoワークフローに送信します
   - Duoワークフローは、サンプルワークフローの実行に見られるように、多段階プロセスで実行されます:

     - 特定のツール（`run_read_only_git_command`、`read_file`、`find_files`、`edit_file`）を使用してタスクを計画します
     - 参照されているイシューにアクセスします
     - エンタープライズJavaスタイルガイドを取得します
     - 現在のコード構造を分析します
     - 指定されたファイルにスタイルガイドラインを適用します
     - 変更が機能を維持することを確認します
     - 行われた変更の詳細なレポートを提供します

1. **Review and Implement**（レビューして実装する）

   - 提案された変更をレビューします
   - コードベースに変更を実装します
   - テストを実行して、機能が維持されていることを確認します
   - GitLabワークフローインターフェースを介してタスクの進行状況を監視します

## サンプルワークフローの実行 {#sample-workflow-execution}

適切に設定されると、GitLabワークフローは、スタイルガイドラインを適用するための詳細な計画を実行します。ワークフローの実行がどのように見えるかのサンプルを次に示します:

### サンプルワークフロー計画 {#sample-workflow-plan}

AIアシスタントは、最初に特定のツールを使用して実行計画を作成します:

1. `run_read_only_git_command`でサポートされている、ファイル`coding-style/java/guidelines/java-coding-standards.md`の`https://gitlab.com/gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards.git`で`run_read_only_git_command`を使用して、Enterprise Java Standardsプロジェクトからコンテンツを取得して、Javaスタイルガイドラインにアクセスします。
1. `read_file`によってサポートされている、`read_file`ツールを使用して`AssetManagementService.java`の現在のコンテンツを読み取り、分析して、その構造を理解し、スタイルの更新が必要な領域を特定します。
1. `find_files`でサポートされているfind_filesを使用して、プロジェクト内の同様のファイルを検索し、関連するサービスクラス全体で一貫したスタイルの適用を確保します。
1. スタイルガイドラインを適用するためにedit_fileツールを使用してAssetManagementService.javaを編集し、以下に焦点を当てます:

   - パッケージとインポートの編成
   - クラスとメソッドのドキュメント
   - コードのインデントと間隔
   - アノテーションの配置
   - `edit_file`でサポートされているメソッドパラメータのフォーマット

1. `grep_files`でサポートされている、grep_filesを使用してコードベース全体のアノテーションパターンをチェックし、すべてのLombokアノテーション（@Service、@RequiredArgsConstructor、@Slf4j）がスタイルガイドに従って適切にフォーマットされていることを確認します

### サンプル分析出力 {#sample-analysis-output}

アシスタントは、ファイルと要件を分析します:

イシュー#3と`AssetManagementService.java`ファイルを分析しました。分析結果は次のとおりです:

1. イシュー＃3は、エンタープライズ標準JavaスタイルガイドラインをRoyal Bankingコードベースに適用することです。
1. `AssetManagementService.java`ファイルは、`asset-management-api`モジュールにあります。
1. スタイルガイドラインは、`gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards`の別のGitLabプロジェクトに保存されています。
1. 現在の`AssetManagementService.java`ファイルには以下が含まれています:

   1. パッケージとインポートステートメント
   1. Springアノテーションを使用したサービスクラス
   1. 資産の可用性をチェックするための1つのパブリックメソッド
   1. Lombokアノテーション
   1. Javadocコメント

イシューに必要なものは次のとおりです:

1. エンタープライズ標準Javaスタイルガイドラインに従ってフォーマット
1. 自動化されたスタイルチェックの実装
1. 既存の機能の維持
1. スタイルの更新後にすべてのテストが合格することを確認する

実装を進めるには、次のことを行う必要があります:

1. Enterprise Java StandardsプロジェクトからJavaスタイルガイドラインにアクセスします
1. スタイルガイドラインをAssetManagementService.javaに適用します
1. 変更が機能に影響を与えないことを確認します
1. 更新後にすべてのテストが合格することを確認します

### サンプル実装結果 {#sample-implementation-result}

実行後、アシスタントは、行われた変更の説明とともに、変換されたコードを提供します。これには以下が含まれます:

1. 適用されたスタイルガイドラインの概要
1. 適切なフォーマットの変換されたコード
1. 主要なスタイル変更の説明
1. 自動化されたスタイルの実施に関する推奨事項

通常、変更には以下が含まれます:

- 標準化されたインポートの順序付け
- 演算子周辺の一貫した間隔
- 適切なJavadocフォーマット
- 標準化されたメソッドパラメータの配置
- 一貫した中括弧の配置

すべて、コードが元の機能を維持していることを確認しながら。

## サンプルチュートリアルユースケース: Royal Reserve Bank Javaプロジェクト {#sample-tutorial-use-case-royal-reserve-bank-java-project}

このリポジトリには、スタイルガイドアプリケーションが実際のシナリオでどのように機能するかを示す銀行チュートリアルの例が含まれています。Royal Reserve Bankプロジェクトは、複数のJavaサービスを備えたマイクロサービスアーキテクチャに従います:

- アカウントAPI
- 資産管理API
- トランザクションAPI
- 通知API
- APIゲートウェイ
- 設定サーバー
- ディスカバリーサーバー

サンプル例では、エンタープライズスタイルガイドラインを`AssetManagementService.java`クラスに適用し、適切なフォーマットを示します:

1. インポートの構成
1. Javadoc標準
1. メソッドパラメータの配置
1. 変数の命名規則
1. 例外処理パターン

## 組織向けにカスタマイズ {#customizing-for-your-organization}

このプロンプトを組織のニーズに合わせるには:

1. **Style Guide Replacement**（スタイルガイドの交換）

   - 組織のスタイルガイドリポジトリを指してください
   - 特定のスタイルガイドドキュメントを参照してください

1. **Target File Selection**（対象ファイルの選択）

   - スタイルガイドを適用する特定のファイルまたはパターンを選択します
   - 初期実装のために、可視性の高いコードファイルを優先します

1. **Additional Validation**（追加の検証）

   - カスタムの検証要件を追加します
   - 標準スタイルのルールに対する例外を指定します

1. **Integration with CI/CD**（CI/CDとのインテグレーション）

   - CI/CDパイプラインの一部として実行するようにプロンプトを設定します
   - 継続的なコンプライアンスを確保するために、自動化されたスタイルチェックを設定します

## トラブルシューティング {#troubleshooting}

一般的な問題とその解決策:

- **アクセスが拒否されました**: AIエージェントが、両方のリポジトリにアクセスするための適切な権限を持っていることを確認してください
- **Missing Style Guide**（スタイルガイドの欠落）: スタイルガイドのパスとブランチが正しいことを確認します
- **Functionality Changes**（機能の変更）: スタイル変更を適用した後、すべてのテストを実行して機能を確認します

## コントリビュート {#contributing}

このプロンプトは、ご自由に拡張してください:

- スタイルルールの説明をさらに追加する
- さまざまなJavaプロジェクトタイプの例を作成する
- 検証ワークフローを改善する
- 追加の静的解析ツールとのインテグレーションを追加する
