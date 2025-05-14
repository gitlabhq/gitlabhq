---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: 変更履歴エントリ
---

このガイドでは、変更履歴エントリファイルを生成するタイミングと方法、および変更履歴プロセスに関する情報と履歴について説明します。

## 概要

[`CHANGELOG.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/CHANGELOG.md)ファイル内の各リスト項目、または**エントリ**は、Gitコミットのサブジェクト行から生成します。`Changelog` [Gitトレーラー](https://git-scm.com/docs/git-interpret-trailers)を収容できる場合には、コミットを含みます。変更履歴の生成時には、作成者とマージリクエストの詳細を自動的に追加します。

`Changelog`トレーラーは、次の値を受け入れます。

- `added`:新機能
- `fixed`:バグ修正
- `changed`:機能変更
- `deprecated`:新規非推奨
- `removed`:機能削除
- `security`:セキュリティ修正
- `performance`:パフォーマンス改善
- `other`:その他

変更履歴に含めるGitコミットの例を次に示します。

```plaintext
Update git vendor to gitlab

Now that we are using gitaly to compile git, the git version isn't known
from the manifest, instead we are getting the gitaly version. Update our
vendor field to be `gitlab` to avoid cve matching old versions.

Changelog: changed
```

マージリクエストに複数のコミットがある場合、[`Changelog`エントリを最初のコミットに追加していることを確認します](changelog.md#how-to-generate-a-changelog-entry)。こうしておくとコミットをスカッシュしたときに正しいエントリを生成します。

### 関連するマージリクエストをオーバーライドする

GitLabは、変更履歴を生成するときに、自動的にマージリクエストをコミットにリンクします。リンクするマージリクエストをオーバーライドする場合は、`MR`トレーラーを使用して代替マージリクエストを指定できます。

```plaintext
Update git vendor to gitlab

Now that we are using gitaly to compile git, the git version isn't known
from the manifest, instead we are getting the gitaly version. Update our
vendor field to be `gitlab` to avoid cve matching old versions.

Changelog: changed
MR: https://gitlab.com/foo/bar/-/merge_requests/123
```

その値は、マージリクエストのフルURLである必要があります。

### GitLab Enterpriseを変更する

変更がGitLab Enterpriseエディション専用である場合は、トレーラー`EE: true`を**追加する必要**があります。

```plaintext
Update git vendor to gitlab

Now that we are using gitaly to compile git, the git version isn't known
from the manifest, instead we are getting the gitaly version. Update our
vendor field to be `gitlab` to avoid cve matching old versions.

Changelog: changed
MR: https://gitlab.com/foo/bar/-/merge_requests/123
EE: true
```

EEとCEの両方に適用する変更については、トレーラーを追加**しない**でください。

## 変更履歴エントリが必要な場合

- データベース移行が行われる変更では、定期的な移行であれデプロイ後の移行であれデータ移行であれ、変更履歴エントリが無効な機能フラグの背後にあっても、変更履歴エントリが**必要**です。
- [セキュリティ修正](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md)には、`security`に設定された`Changelog`トレーラーを含む変更履歴エントリが**必要**です。
- ユーザーに影響する変更には、すべて変更履歴エントリが**必要**です。例:「GitLabでは、すべてのテキストにシステムフォントを使用するようになりました。」
- RESTやGraphQL APIへのクライアントに影響する変更には、すべて変更履歴エントリが**必要**です。[GraphQLの互換性を維持しない変更を構成する完全なリスト](api_graphql_styleguide.md#breaking-changes)を参照してください。
- [高度な検索移行](search/advanced_search_migration_styleguide.md#create-a-new-advanced-search-migration)を行う変更には、すべて変更履歴エントリが**必要**です。
- （月次リリースの候補版で行ったバグの修正など）同じリリースで発生してデバッグしたリグレッションの修正には、変更履歴エントリを行っては**なりません**。
- （リファクタリング、技術的負債の修正、Testスイートの変更など）デベロッパーに影響する変更には、一切変更履歴エントリを行っては**なりません**。例:「サイクル分析モデル仕様で作成したデータベースレコードを削減します。」
- コミュニティメンバーからの_なんらかの_コントリビュートはたとえ小さくても、コントリビューターが希望するなら、ガイドラインに関係なく変更履歴エントリを行っても**かまいません**。
- [実験](experiment_guide/_index.md)の変更には、変更履歴エントリを行っては**なりません**。
- ドキュメントの変更のみを含むMR（マージリクエスト）には、変更履歴エントリを行っては**なりません**。

詳細については、[機能フラグで変更履歴エントリを処理する方法](feature_flags/_index.md#changelog)を参照してください。

## 優れた変更履歴エントリを作成する

優れた変更履歴エントリは、説明的で簡潔でなければなりません。これは変更に関する_背景状況をまったく知らない_読者に、変更内容を説明するものです。簡潔さと説明性の両立が難しい場合は、説明を優先させてください。

- **悪い例: **プロジェクトの順序に移動します。
- **良い例:**「プロジェクトへ移動」ドロップダウンリストの一番上に、ユーザーのお気に入りプロジェクトを表示します。

最初の例では、変更が行われた箇所、その理由、ユーザーにどのように役立つのかといった背景状況が不明です。

- **悪い例: **（一部のテキスト）をクリップボードにコピーします。
- **良い例:**「クリップボードにコピー」ツールチップを更新して、コピーする内容を示すようにします。

これも最初の例はあいまいすぎて、背景状況が分かりません。

- **悪い例: **ミニパイプライングラフのCSSとHTMLの問題を修正し改善し、ドロップダウンリストをビルドします。
- **良い例:**ミニパイプライングラフのツールチップとホバー状態を修正し、ドロップダウンリストをビルドします。

最初の例は、実装の詳細に焦点を当てすぎています。ユーザーは、CSSやHTMLの変更は気にせず、その変更の_最終結果_を気にします。

- **悪い例: **`find_commits_by_message_with_elastic`から返されるコミットオブジェクトの配列で`nil`を取り除きます
- **良い例: **ガベージコレクションしたコミットを参照するElasticsearchの結果により、500のエラーを修正します

最初の例は、_何_を修正したのかではなく、_どのように_修正したかに焦点を当てています。書き換えられたバージョンでは、ユーザーにとっての_最終的なメリット_（500のエラーを削減）と、_いつ_（Elasticsearchでコミットを検索したとき）を明確に説明しています。

最善の判断を下し、列挙した変更履歴を読んでいる人の考え方を理解するように努めてください。このエントリは価値を追加しますか？変更を行った_場所_と_理由_についての背景状況を提供していますか？

## 変更履歴エントリの生成方法

Gitトレーラーは、変更をコミットするときに追加します。これは選択したテキストエディタで実行できます。既存のコミットにトレーラーを追加するには、（最新のコミットである場合）コミットへの修正、または`git rebase -i`によるインタラクティブなリベースが必要です。

最終のコミットを更新するには、次の命令を実行します。

```shell
git commit --amend
```

これでコミットメッセージに`Changelog`トレーラーを追加できます。以前のコミットをremoteブランチにすでにプッシュしていた場合は、以下のように新しいコミットを強制的にプッシュする必要があります。

```shell
git push -f origin your-branch-name
```

古い（または複数の）コミットを編集するには`git rebase -i HEAD~N`を使用します。ここで`N`はリベースする最終コミット数です。たとえばブランチに3つのコミットA、B、Cがあるとします。コミットBを更新する場合は、次のコマンドを実行する必要があります。

```shell
git rebase -i HEAD~2
```

これで最後の2つのコミットのインタラクティブなリベースセッションを開始します。開始すると、Gitは次の行に沿ってコンテンツを含むテキストエディタを表示します。

```plaintext
pick B Subject of commit B
pick C Subject of commit C
```

コミットBを更新するには、単語`pick`を`reword`に変更し、エディターを保存して終了します。いったん閉じると、Gitは新しいテキストエディタインスタンスを表示し、コミットBのコミットメッセージを編集できます。トレーラーを追加し、次にエディターを保存して終了します。すべてうまくいけば、コミットBが更新されます。

remoteブランチにすでに存在するコミットを変更したため、remoteブランチにプッシュするときには次のように`--force-with-lease`フラグを使用する必要があります。

```shell
git push origin your-branch-name --force-with-lease
```

インタラクティブなリベースの詳細については、[Gitドキュメント](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History)を参照してください。

---

[開発ドキュメントに戻る](_index.md)
