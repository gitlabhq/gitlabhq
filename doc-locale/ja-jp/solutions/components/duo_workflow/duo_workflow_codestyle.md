---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: GitLab Duoワークフローを使用して、Javaコーディングスタイルガイドラインをプロジェクトに自動的に適用するための設定、実行、およびサンプルユースケースを説明するガイドラインです。
title: コーディングスタイルを適用するためのDuo Workflowのユースケース
---

{{< details >}}

- プラン: UltimateとGitLab Duoワークフロー
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

## はじめに {#getting-started}

### ソリューションコンポーネントをダウンロード {#download-the-solution-component}

1. アカウントチームから招待コードを入手してください。
1. 招待コードを使用して、[ソリューションコンポーネントのウェブストア](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントをダウンロードしてください。

## Duo Workflowユースケース: スタイルガイドでJavaアプリケーションを改善する {#duo-workflow-use-case-improve-java-application-with-style-guide}

このドキュメントでは、GitLab Duo Workflow Solutionのプロンプトとコンテキストライブラリについて説明します。このソリューションの目的は、定義されたスタイルに基づいてアプリケーションのコーディングを改善することです。

このソリューションは、GitLabイシューをプロンプトとして、スタイルガイドをコンテキストとして提供し、GitLab Duo Workflowを使用して、Javaスタイルガイドラインをコードベースに自動適用するように設計されています。プロンプトとコンテキストライブラリにより、Duo Workflowは次のことが可能になります:

1. Gitリポジトリに保存されている集中型スタイルガイドコンテンツにアクセスし、
1. ドメイン固有のコーディング標準を理解し、
1. 機能を維持しながら、Javaコードに一貫した書式設定を適用します。

GitLab Duo Workflowの詳細については、[こちらのドキュメント](../../../user/duo_agent_platform/_index.md)をご覧ください。

### 主な利点 {#key-benefits}

- すべてのJavaコードベースで**Enforces consistent style**
- 手動での作業なしで**Automates style application**
- 可読性を向上させながらコードの機能を**Maintains code functionality**
- シームレスな実装のためにGitLab for VS Codeと**Integrates with GitLab for VS Code**
- スタイルイシューへの対応にかかるコードレビュー時間を**Reduces code review time**
- デベロッパーがスタイルガイドラインを理解するための**Serves as a learning tool**

### サンプル結果 {#sample-result}

適切に設定すると、プロンプトは、この差分に示されている変換と同様に、コードをエンタープライズ標準に一致するように変換します:

![手順、タスク分析、解決ステップを表示するDuo Workflowビュー](img/duoworkflow-style_output_v17_10.png)

![Duo Workflowによるスタイルガイド変換後の書式設定が統一された更新コードスニペット](img/duoworkflow_style_code_transform_v17_10.png)

## ソリューションプロンプトとコンテキストライブラリを設定する {#configure-the-solution-prompt-and-context-library}

### 基本設定 {#basic-setup}

エージェント型ワークフローを実行して、アプリケーションのスタイルをレビューし適用するには、このユースケースプロンプトとコンテキストライブラリを設定する必要があります。

1. `Enterprise Code Quality Standards`プロジェクトをクローンして**Set up the prompt and context library**
1. ライブラリファイル`.gitlab/workflows/java-style-workflow.md`のプロンプトコンテンツを使用して**Create a GitLab issue** `Review and Apply Style`
1. **In the issue** `Review and Apply Style`で、[設定](#configuration-guide)セクションに詳述されているように、ワークフロー変数を設定します。
1. `Enterprise Code Quality Standards`プロジェクトで**In your VS code**を使用し、シンプルな[ワークフロープロンプト](#example-duo-workflow-prompt)でDuoワークフローを開始します。
1. 提案された計画と自動タスクをレビューして**Work with the Duo Workflow**し、必要に応じてワークフローにさらなる入力を追加します。
1. スタイルが適用されたコード変更を**Review and commit**してリポジトリに反映します。

### Duoワークフロープロンプトの例 {#example-duo-workflow-prompt}

```yaml
Follow the instructions in issue <issue_reference_id> for the file <path/file_name.java>. Make sure to access any issues or GitLab projects mentioned in the issue to retrieve all necessary information.
```

このシンプルなプロンプトは、Duo Workflowに次のことを指示するため強力です:

1. 特定のイシューIDの詳細な要件を読み取ります。
1. 参照されているスタイルガイドリポジトリにアクセスします。
1. 指定されたファイルにガイドラインを適用します。
1. イシュー内のすべての指示に従います。

## 設定ガイドライン {#configuration-guide}

プロンプトは、ソリューションパッケージ内の`.gitlab/workflows/java-style-workflow.md`ファイルで定義されています。このファイルは、ワークフローエージェントに、アプリケーションでのスタイルガイドレビューを自動化し変更を適用するための計画をビルドするよう指示するGitLabイシューを作成するためのテンプレートとして機能します。

`.gitlab/workflows/java-style-workflow.md`の最初のセクションでは、プロンプト用に設定する必要がある変数を定義しています。

### 変数の定義 {#variable-definition}

変数は`.gitlab/workflows/java-style-workflow.md`ファイルに直接定義されています。このファイルは、AIアシスタントに指示するGitLabイシューを作成するためのテンプレートとして機能します。このファイル内の変数を修正してから、その内容で新しいイシューを作成します。

#### 1. コンテキストとしてのスタイルガイドリポジトリ {#1-style-guide-repository-as-the-context}

プロンプトは、組織のスタイルガイドリポジトリを指すように設定する必要があります。`java-style-prompt.md`ファイルで、次の変数を置き換えます:

- `{{GITLAB_INSTANCE}}`: GitLabインスタンスのURL（例: `https://gitlab.example.com`）
- `{{STYLE_GUIDE_PROJECT_ID}}`: Javaスタイルガイドを含むGitLabプロジェクトID
- `{{STYLE_GUIDE_PROJECT_NAME}}`: スタイルガイドプロジェクトの表示名
- `{{STYLE_GUIDE_BRANCH}}`: 最新のスタイルガイドを含むブランチ（デフォルト: main）
- `{{STYLE_GUIDE_PATH}}`: リポジトリ内のスタイルガイドドキュメントへのパス

例: 

```yaml
GITLAB_INSTANCE=https://gitlab.example.com
STYLE_GUIDE_PROJECT_ID=gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards
STYLE_GUIDE_PROJECT_NAME=Enterprise Java Standards
STYLE_GUIDE_BRANCH=main
STYLE_GUIDE_PATH=coding-style/java/guidelines/java-coding-standards.md
```

#### 2. スタイル改善を適用するターゲットリポジトリ {#2-target-repository-to-apply-style-improvement}

同じ`java-style-prompt.md`ファイルで、スタイルガイドを適用するファイルを設定します:

- `{{TARGET_PROJECT_ID}}`: JavaプロジェクトのGitLabID
- `{{TARGET_FILES}}`: ターゲットとする特定のファイルまたはパターン（例: 「src/main/java/\*\*/*.java」）

例: 

```yaml
TARGET_PROJECT_ID=royal-reserve-bank
TARGET_FILES=asset-management-api/src/main/java/com/royal/reserve/bank/asset/management/api/service/AssetManagementService.java
```

### AIが生成したコードに関する重要な注意事項 {#important-notes-about-ai-generated-code}

**⚠️ Important Disclaimer**:

GitLab for VS Codeは、非決定性であるエージェント型AIを使用しています。つまり:

- 同じ入力であっても、実行ごとに結果が異なる場合があります。
- AIアシスタントのスタイルガイドラインの理解と適用は、毎回わずかに異なる場合があります。
- このドキュメントで提供されている例は説明のためのものであり、実際の環境では結果が異なる場合があります。

AIが生成したコードの変更を操作するための**Best Practices for Working with AI-Generated Code Changes**:

1. **Always review generated code**: 生成されたコードを常にレビューする: 徹底的な人間のレビューなしにAI生成された変更をマージすることは避けてください。
1. **Follow proper merge request processes**: 適切なマージリクエストプロセスに従う: 標準のコードレビュー手順を使用してください。
1. **Run all tests**: すべてのテストを実行する: マージする前に、すべての単体テストとインテグレーションテストが合格することを確認してください。
1. **Verify style compliance**: スタイルコンプライアンスを検証する: 変更がスタイルガイドの期待値と一致していることを確認します。
1. **Incremental application**: 段階的な適用: 最初は、より小さなファイルセットにスタイル変更を適用することを検討してください。

このツールは、デベロッパーを支援するためのものであり、コードレビュープロセスにおける人間の判断を置き換えるものではないことを覚えておいてください。

## 段階的な実装 {#step-by-step-implementation}

1. **Create a Style Guide Issue** (スタイルガイドイシューを作成)

   - プロジェクトで新しいイシューを作成します（例: イシュー #3）。
   - 適用するスタイルガイドラインに関する詳細情報を含めます。
   - 該当する場合は、外部スタイルガイドリポジトリを参照します。
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

1. **Configure the Prompt** (プロンプトを設定する)

   - `java-style-prompt.md`からテンプレートをコピーします。
   - すべての設定変数を入力します。
   - プロジェクト固有の例外または要件を追加します。

1. **Execute via GitLab for VS Code** (実行)

   - 設定されたプロンプトをDuoワークフローに送信します。
   - Duoワークフローは、サンプルワークフロー実行に示されているように、多段階プロセスを実行します:

     - 特定のツール（`run_read_only_git_command`、`read_file`、`find_files`、`edit_file`）でタスクを計画します。
     - 参照されているイシューにアクセスします。
     - エンタープライズJavaスタイルガイドを取得する。
     - 現在のコード構造を分析します。
     - 指定されたファイルにスタイルガイドラインを適用します。
     - 変更が機能を維持していることを検証します。
     - 行われた変更の詳細なレポートを提供します。

1. **Review and Implement** (レビューと実装)

   - 提案された変更をレビューします。
   - コードベースに変更を実装します。
   - 機能を維持するためにテストを実行します。
   - GitLab for VS Codeインターフェースを介してタスクの進行状況を監視します。

## サンプルワークフロー実行 {#sample-workflow-execution}

適切に設定すると、GitLab for VS Code拡張機能は、スタイルガイドラインを適用するための詳細な計画を実行します。ワークフローの実行例を以下に示します:

### サンプルワークフロー計画 {#sample-workflow-plan}

AIアシスタントは、まず特定のツールを使用して実行計画を作成します:

1. `https://gitlab.com/gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards.git`上で`coding-style/java/guidelines/java-coding-standards.md`ファイルに`run_read_only_git_command`を使用してEnterprise Java Standardsプロジェクトからコンテンツを取得することで、Javaスタイルガイドラインにアクセスします。`run_read_only_git_command`によってサポートされています。
1. `AssetManagementService.java`の現在のコンテンツを`read_file`ツールを使用して読み取り、その構造を理解し、スタイル更新が必要な領域を特定します。`read_file`によってサポートされています。
1. プロジェクト内で類似するファイルをfind_filesを使用して検索し、関連するサービスクラス全体で一貫したスタイル適用を確保します。`find_files`によってサポートされています。
1. edit_fileツールを使用してAssetManagementService.javaを編集し、スタイルガイドラインを適用します。特に次の点に焦点を当てます:

   - パッケージとインポートの整理
   - クラスとメソッドのドキュメント
   - コードのインデントとスペース
   - アノテーションの配置
   - メソッドパラメータの書式設定。`edit_file`によってサポートされています。

1. grep_filesを使用して、すべてのLombokアノテーション（@Service、@RequiredArgsConstructor、@Slf4j）がスタイルガイドに従って適切に書式設定されていることをコードベース全体のアノテーションパターンをチェックすることで確認します。`grep_files`によってサポートされています。

### サンプル分析出力 {#sample-analysis-output}

AIアシスタントは、ファイルと要件を分析します:

イシュー #3と`AssetManagementService.java`ファイルを分析しました。以下に調査結果を示します:

1. イシュー #3は、エンタープライズ標準JavaスタイルガイドラインをRoyal Bankingコードベースに適用することに関するものです。
1. `AssetManagementService.java`ファイルは、`asset-management-api`モジュール内にあります。
1. スタイルガイドラインは、`gl-demo-ultimate-zhenderson/sandbox/enterprise-java-standards`の別のGitLabプロジェクトに保存されています。
1. 現在の`AssetManagementService.java`ファイルには以下が含まれます:

   1. パッケージおよびインポートステートメント
   1. Springアノテーションを持つサービスクラス
   1. アセットの可用性をチェックするための1つのpublicメソッド
   1. Lombokアノテーション
   1. Javadocコメント

このイシューでは次のことが求められています:

1. エンタープライズ標準Javaスタイルガイドラインに準拠した書式設定
1. 自動スタイルチェックの実装
1. 既存の機能の維持
1. スタイル更新後にすべてのテストが合格することの確認

実装を進めるには、次の作業が必要です:

1. Enterprise Java StandardsプロジェクトからJavaスタイルガイドラインにアクセスします。
1. AssetManagementService.javaにスタイルガイドラインを適用します。
1. 変更が機能に影響しないことを検証します。
1. 更新後にすべてのテストが合格することを確認します。

### サンプル実装結果 {#sample-implementation-result}

実行後、AIアシスタントは、行われた変更の説明とともに変換されたコードを提供します:

1. 適用されたスタイルガイドラインの概要
1. 適切に書式設定された変換済みコード
1. 主要なスタイル変更の説明
1. 自動スタイル適用に関する推奨事項

変更には通常、以下が含まれます:

- 標準化されたインポート順序
- 演算子の周りの一貫したスペース
- 適切なJavadoc書式設定
- 標準化されたメソッドパラメータの配置
- 一貫したブレースの配置

これはすべて、コードが元の機能を維持するようにしながら行われます。

## サンプルチュートリアルユースケース: Royal Reserve Bank Javaプロジェクト {#sample-tutorial-use-case-royal-reserve-bank-java-project}

このリポジトリには、スタイルガイドアプリケーションが現実世界のシナリオでどのように機能するかを示す銀行チュートリアルの例が含まれています。Royal Reserve Bankプロジェクトは、複数のJavaサービスを含むマイクロサービスアーキテクチャに従います:

- アカウントAPI
- アセット管理API
- トランザクションAPI
- 通知API
- API Gateway
- 設定サーバー
- Discovery Server

サンプルでは、`AssetManagementService.java`クラスにエンタープライズスタイルガイドラインを適用し、次の適切な書式設定を示しています:

1. インポートの整理
1. Javadoc標準
1. メソッドパラメータの配置
1. 変数命名規則
1. 例外処理パターン

## 組織に合わせてカスタマイズする {#customizing-for-your-organization}

組織のニーズに合わせてこのプロンプトを調整するには、次の手順を実行します:

1. **Style Guide Replacement** (スタイルガイドの置き換え)

   - 組織のスタイルガイドリポジトリを指定します。
   - 特定のスタイルガイドドキュメントを参照します。

1. **Target File Selection** (ターゲットファイルの選択)

   - スタイルガイドを適用する特定のファイルまたはパターンを選択します。
   - 最初の実装では、表示レベルの高いコードファイルを優先します。

1. **Additional Validation** (追加の検証)

   - カスタム検証要件を追加します。
   - 標準スタイルルールに対する例外を指定します。

1. **Integration with CI/CD** (CI/CDとのインテグレーション)

   - プロンプトがCI/CDパイプラインの一部として実行されるように設定します。
   - 継続的なコンプライアンスを確保するために自動スタイルチェックを設定します。

## トラブルシューティング {#troubleshooting}

よくあるイシューとその解決策:

- **アクセスが拒否されました**: AIエージェントが両方のリポジトリにアクセスするための適切な権限を持っていることを確認してください。
- **Missing Style Guide**: スタイルガイドのパスとブランチが正しいことを確認します。
- **Functionality Changes**: 機能性を検証するために、スタイル変更の適用後にすべてのテストを実行します。

## コントリビュート {#contributing}

このプロンプトは、次の方法で自由に機能強化できます:

- より多くのスタイルルールの説明を追加します。
- さまざまなJavaプロジェクトタイプ向けの例を作成します。
- 検証ワークフローを改善します。
- 追加の静的解析ツールとのインテグレーションを追加します。
