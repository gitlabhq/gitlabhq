---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: テストコードベースを選択し、スキャンを設定し、結果を解釈し、他のセキュリティツールと機能を比較することで、GitLab SASTを評価する方法について説明します。
title: GitLab SASTを評価する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

組織でGitLab SASTを使用する前に、それを評価することを選択できます。評価を計画し実施する際は、以下のガイダンスを考慮してください。

## 重要な概念 {#important-concepts}

GitLab SASTは、チームが共同で記述するコードのセキュリティを向上させるように設計されています。コードをスキャンして結果を表示する手順は、スキャン対象のソースコードリポジトリを中心にしています。

### スキャンプロセス {#scanning-process}

GitLab SASTは、プロジェクト内で見つかったプログラミング言語に応じて、適切なスキャン技術を自動的に選択します。Groovyを除くすべての言語について、GitLab SASTはコンパイルやビルドステップを必要とせずにソースコードを直接スキャンします。これにより、さまざまなプロジェクトでスキャンを有効にすることが容易になります。詳細については、[サポートされている言語とフレームワーク](_index.md#supported-languages-and-frameworks)を参照してください。

### 脆弱性が報告されるタイミング {#when-vulnerabilities-are-reported}

GitLab SASTの[アナライザー](analyzers.md)とそれらの[ルール](rules.md)は、開発チームとセキュリティチームにとってノイズを最小限に抑えるように設計されています。

GitLab Advanced SASTアナライザーが脆弱性を報告するタイミングの詳細については、[脆弱性検出基準](gitlab_advanced_sast.md#vulnerability-detection-criteria)を参照してください。

### その他のプラットフォーム機能 {#other-platform-features}

SASTは、Ultimateの他のセキュリティおよびコンプライアンス機能と統合されています。GitLab SASTを他の製品と比較する場合、その機能の一部がSASTではなく、関連するGitLabの機能領域に含まれている場合があります:

- [IaCスキャン](../iac_scanning/_index.md)は、Infrastructure as Code (IaC) 定義のセキュリティ問題をスキャンします。
- [シークレット検出](../secret_detection/_index.md)は、コード内の流出したシークレットを検出します。
- [セキュリティポリシー](../policies/_index.md)を使用すると、スキャンの実行を強制したり、脆弱性が修正されることを要求したりできます。
- [脆弱性管理とレポート](../vulnerability_report/_index.md)は、コードベースに存在する脆弱性を管理し、イシュートラッカーと統合します。
- GitLab Duoの[脆弱性の説明](../analyze/duo.md)と[脆弱性の修正](../remediate/duo.md)は、AIを使用して脆弱性を迅速に修正するのに役立ちます。

## テスト用のコードベースを選択する {#choose-a-test-codebase}

SASTをテストするコードベースを選択する際は、以下の点に注意してください:

- 通常開発を中断することなく、CI/CD設定を安全に変更できるリポジトリでテストしてください。SASTスキャンはCI/CDパイプラインで実行されるため、CI/CD設定を少し編集して[SASTを有効にする](_index.md#configuration)必要があります。
  - テスト用に既存のリポジトリをフォークまたはコピーできます。この方法により、通常開発を中断することなく、テスト環境をセットアップできます。
- 組織の標準的な技術スタックに一致するコードベースを使用してください。
- [GitLab Advanced SASTがサポートしている](gitlab_advanced_sast.md#supported-languages)言語を使用してください。GitLab Advanced SASTは、他の[アナライザー](analyzers.md)よりも正確な結果を生成します。

テストプロジェクトにはUltimateが必要です。Ultimateのみが次の[機能](_index.md#features)を含んでいます:

- GitLab Advanced SASTによる独自のクロスファイル、クロスファンクションスキャン。
- マージリクエストウィジェット、パイプラインセキュリティレポート、デフォルト-ブランチ脆弱性レポートにより、スキャン結果が可視化され、対処可能になります。

### ベンチマークとサンプルプロジェクト {#benchmarks-and-example-projects}

ベンチマークまたは意図的に脆弱性のあるアプリケーションをテストに使用する場合、これらのアプリケーションは次の点に注意してください:

- 特定の脆弱性タイプに焦点を当てます。ベンチマークの焦点は、組織が検出と修正のために優先する脆弱性タイプとは異なる場合があります。
- 組織がソフトウェアをビルドする方法とは異なる特定の技術を特定の形で使用します。
- 特定の基準を他の基準よりも暗黙的に強調する形で結果をレポートします。たとえば、精度 (より少ない誤検出結果) を優先するかもしれませんが、ベンチマークは再現率 (より少ない偽陰性結果) に基づいてのみスコアを付けます。

[エピック15296](https://gitlab.com/groups/gitlab-org/-/epics/15296)は、テスト対象として推奨する具体的なプロジェクトの選定作業を追跡しています。

### AIが生成したテストコード {#ai-generated-test-code}

AIツールを使用して、SASTテスト用の脆弱なコードを作成しないでください。AIモデルは、実際には悪用できないコードを返すことがよくあります。

例: 

- AIツールは、実際にはユーザー入力を受け取らないにもかかわらず、パラメータを受け取ってそれを機密性の高いコンテキスト（「シンク」と呼ばれる）で使用する小さな関数を記述することがよくあります。その関数が定数のようなプログラム制御の値でのみ呼び出されるのであれば、これは安全な設計と言えます。ユーザー入力がサニタイズや検証なしにこれらのシンクに流れない限り、コードに脆弱性はありません。
- AIツールは、脆弱性の一部をコメントアウトして、誤ってコードを実行するのを防ぐ場合があります。

これらの非現実的な例で脆弱性を報告すると、実際のコードで誤検出結果が発生する可能性があります。GitLab SASTは、これらのケースで脆弱性を報告するようには設計されていません。

## テストを実施する {#conduct-the-test}

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

テストするコードベースを選択したら、テストを実施する準備が整います。次の手順に従ってください:

1. CI/CD設定にSASTを追加するマージリクエスト (MR) を作成して、[SASTを有効にします](_index.md#configuration)。
   - より正確な結果を得るために、CI/CD変数を設定して[GitLab Advanced SASTをオンにする](gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)ようにしてください。
1. MRをリポジトリのデフォルトブランチにマージする。
1. [脆弱性レポート](../vulnerability_report/_index.md)を開いて、デフォルトブランチで見つかった脆弱性を確認してください。
   - GitLab Advanced SASTを使用している場合は、[スキャナーフィルター](../vulnerability_report/_index.md#scanner-filter)を使用して、そのスキャナーからの結果のみを表示できます。
1. 脆弱性結果をレビューします。
   - GitLab Advanced SASTの脆弱性で、汚染されたユーザー入力 (SQLインジェクションやパストラバーサルなど) を含むものについては、[コードフロービュー](../vulnerabilities/_index.md#vulnerability-code-flow)を確認してください。
   - GitLab Duo Enterpriseをお持ちの場合、[脆弱性の説明](../analyze/duo.md)または[脆弱性を解決する](../remediate/duo.md)ことができます。
1. 新しいコードが開発されるにつれてスキャンがどのように機能するかを確認するには、アプリケーションコードを変更し、新しい脆弱性または弱点を追加する新しいマージリクエストを作成します。
