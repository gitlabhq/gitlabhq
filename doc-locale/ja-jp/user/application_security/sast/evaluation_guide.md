---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: テストコードベースを選択し、スキャンを設定し、結果を解釈し、他のセキュリティツールと機能を比較して、GitLab SASTを評価する方法について説明します。
title: GitLab SASTの評価
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

組織で使用する前に、GitLab SASTを評価することを選択できます。評価を計画および実施する際に、次のガイダンスを考慮してください。

## 重要な概念 {#important-concepts}

GitLab SASTは、チームが共同で記述するのセキュリティを向上させるのに役立つように設計されています。コードをスキャンして結果を表示するために実行する手順は、スキャンされるソースコードリポジトリを中心にしています。

### スキャンプロセス {#scanning-process}

GitLab SASTは、プロジェクトで見つかったプログラミング言語に応じて、使用する適切なスキャンテクノロジーを自動的に選択します。Groovyを除くすべての言語について、GitLab SASTは、コンパイルまたはビルドステップを必要とせずに、ソースを直接スキャンします。これにより、さまざまなプロジェクトでスキャンを簡単に有効にできます。詳細については、[サポートされている言語とフレームワーク](_index.md#supported-languages-and-frameworks)を参照してください。

### 脆弱性が報告されるタイミング {#when-vulnerabilities-are-reported}

GitLab SAST [アナライザー](analyzers.md)とその[ルール](rules.md)は、開発チームとセキュリティチームのノイズを最小限に抑えるように設計されています。

GitLab Advanced SASTアナライザーが脆弱性をレポートするタイミングの詳細については、[脆弱性がレポートされるタイミング](gitlab_advanced_sast.md#when-vulnerabilities-are-reported)を参照してください。

### その他のプラットフォーム機能 {#other-platform-features}

SASTは、GitLab Ultimateプランの他のセキュリティおよびコンプライアンス機能と統合されています。GitLab SASTを別の製品と比較している場合、その機能の一部がSASTではなく、関連するGitLab機能領域に含まれている場合があります:

- [IaCスキャン](../iac_scanning/_index.md)は、Infrastructure as Code（IaC）定義のセキュリティ問題をスキャンします。
- [シークレット検出](../secret_detection/_index.md)は、内で流出したシークレットを見つけます。
- [セキュリティポリシー](../policies/_index.md)を使用すると、スキャンの実行を強制したり、脆弱性の修正を要求したりできます。
- [脆弱性管理とレポート](../vulnerability_report/_index.md)は、コードベースに存在する脆弱性を管理し、イシュー追跡ツールと統合します。
- GitLab Duoの[脆弱性の説明](../vulnerabilities/_index.md#vulnerability-explanation)と[脆弱性の解決](../vulnerabilities/_index.md#vulnerability-resolution)は、AIを使用して、脆弱性を迅速に修正するのに役立ちます。

## テストコードベースを選択 {#choose-a-test-codebase}

SASTをテストするためのコードベースを選択する場合は、次のことを行う必要があります:

- 通常の開発作業を妨げることなく、CI/CD設定を安全に変更できるリポジトリでテストします。SASTスキャンはCI/CDパイプラインで実行されるため、CI/CD設定を少し編集して[SASTを有効にする](_index.md#configuration)必要があります。
  - 既存のリポジトリのフォークまたはコピーを作成してテストできます。これにより、通常の開発を中断することなく、テスト環境をセットアップできます。
- 組織の一般的なテクノロジースタックに一致するコードベースを使用します。
- [GitLab Advanced SASTがサポートする](gitlab_advanced_sast.md#supported-languages)言語を使用します。GitLab Advanced SASTは、他の[アナライザー](analyzers.md)よりも正確な結果を生成します。

テストプロジェクトにはGitLab Ultimateが必要です。Ultimateプランのみに、次のような[機能](_index.md#features)が含まれています:

- GitLab高度なSASTによるクロスファイル、クロスファンクションスキャン
- マージリクエストウィジェット、パイプラインセキュリティレポート、およびスキャン結果を表示してアクションを実行できるようにするデフォルトブランチの脆弱性レポート。

### ベンチマークとサンプルプロジェクト {#benchmarks-and-example-projects}

ベンチマークまたは意図的に脆弱なアプリケーションをテストに使用する場合は、これらのアプリケーションが次の点に注意してください:

- 特定の脆弱性タイプに焦点を当てます。ベンチマークの焦点は、組織が検出と修正を優先する脆弱性タイプとは異なる場合があります。
- 組織のソフトウェアビルド方法とは異なる特定の方法で特定のテクノロジーを使用します。
- 結果をレポートする方法で、暗黙のうちに他の基準よりも特定の基準を強調する場合があります。たとえば、ベンチマークが再現率（偽陰性の結果が少ない）のみに基づいてスコアリングする場合、精度（偽陽性の結果が少ない）を優先する場合があります。

[エピック15296](https://gitlab.com/groups/gitlab-org/-/epics/15296)は、テスト用の特定のプロジェクトを推奨する作業を追跡します。

### AIによって生成されたテスト {#ai-generated-test-code}

SASTをテストするために、AIツールを使用して脆弱なを作成しないでください。AIモデルは、実際には悪用できないを返すことがよくあります。

例: 

- AIツールは、多くの場合、パラメータを受け取り、機密性の高いコンテキスト（「シンク」と呼ばれる）で使用する小さな関数を作成しますが、実際にはユーザー入力を受信しません。関数が定数などのプログラム制御された値でのみ呼び出すされる場合、これは安全な設計になる可能性があります。ユーザー入力が最初にサニタイズまたは検証されずにこれらのシンクに流れることが許可されない限り、は脆弱ではありません。
- AIツールは、誤ってを実行するのを防ぐために、脆弱性の一部をコメントアウトする場合があります。

これらの非現実的な例で脆弱性をレポートすると、実際の世界ので偽陽性の結果が発生します。GitLab SASTは、これらの場合に脆弱性をレポートするように設計されていません。

## テストの実施 {#conduct-the-test}

テストするコードベースを選択したら、テストを実施する準備が整います。次の手順に従うことができます:

1. [SASTを有効にする](_index.md#configuration)には、CI/CD設定にSASTを追加するマージリクエスト（MR）を作成します。
   - より正確な結果を得るには、CI/CD変数を設定して[GitLab Advanced SASTを有効にする](gitlab_advanced_sast.md#enable-gitlab-advanced-sast-scanning)ようにしてください。
1. MRをリポジトリのデフォルトブランチにマージします。
1. [脆弱性レポート](../vulnerability_report/_index.md)を開いて、デフォルトブランチで見つかった脆弱性を確認します。
   - GitLab Advanced SASTを使用している場合は、[スキャナーフィルター](../vulnerability_report/_index.md#scanner-filter)を使用して、そのスキャナーからの結果のみを表示できます。
1. 脆弱性の結果をレビューします。
   - SQLインジェクションやパストラバーサルなどの、汚染されたユーザー入力を含むGitLab Advanced SASTの脆弱性については、[コードフロービュー](../vulnerabilities/_index.md#vulnerability-code-flow)を確認してください。
   - GitLab Duo Enterpriseをお持ちの場合は、脆弱性を[説明](../vulnerabilities/_index.md#vulnerability-explanation)または[解決](../vulnerabilities/_index.md#vulnerability-resolution)します。
1. 新しいが開発されるにつれてスキャンがどのように機能するかを確認するには、アプリケーションを変更し、新しい脆弱性または脆弱性を追加する新しいマージリクエストを作成します。
