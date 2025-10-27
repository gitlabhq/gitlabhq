---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バッジ
description: パイプラインの状態、グループ、プロジェクト、カスタムバッジ。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

バッジは、プロジェクトに関する凝縮された情報を表示するための統一された方法です。バッジは、小さな画像と、その画像が指すURLで構成されます。GitLabでは、バッジはプロジェクトの概要ページで、プロジェクトの説明の下に表示されます。バッジは、[プロジェクト](#project-badges)レベルと[グループ](#group-badges)レベルで使用できます。

## 利用可能なバッジ {#available-badges}

GitLabは、次のパイプラインバッジを提供します:

- [パイプラインステータスバッジ](#pipeline-status-badges)
- [テストカバレッジレポートバッジ](#test-coverage-report-badges)
- [最新リリースバッジ](#latest-release-badges)

GitLabは[カスタムバッジ](#customize-badges)もサポートしています。

## パイプラインステータスバッジ {#pipeline-status-badges}

パイプライン状態バッジは、プロジェクト内の最新のパイプラインの状態を示します。パイプラインの状態に応じて、バッジは次のいずれかの値を持ちます:

- `pending`
- `running`
- `passed`
- `failed`
- `skipped`
- `manual`
- `canceled`
- `unknown`

次のリンクを使用して、パイプライン状態バッジ画像にアクセスできます:

```plaintext
https://gitlab.example.com/<namespace>/<project>/badges/<branch>/pipeline.svg
```

### スキップされていない状態のみを表示 {#display-only-non-skipped-status}

パイプラインステータスバッジに最後にスキップされなかった状態のみを表示するには、`?ignore_skipped=true`クエリパラメータを使用します:

```plaintext
https://gitlab.example.com/<namespace>/<project>/badges/<branch>/pipeline.svg?ignore_skipped=true
```

## テストカバレッジレポートバッジ {#test-coverage-report-badges}

テストカバレッジレポートバッジは、プロジェクトでTestされているコードの割合を示します。値は、最後に成功したパイプラインに基づいて計算されます。

次のリンクを使用して、テストカバレッジレポートバッジ画像にアクセスできます:

```plaintext
https://gitlab.example.com/<namespace>/<project>/badges/<branch>/coverage.svg
```

各ジョブログと照合される[コードカバレッジ](../../ci/testing/code_coverage/_index.md#configure-coverage-reporting)の正規表現を定義できます。これは、パイプライン内の各ジョブに、定義されたテストカバレッジの割合の値を持たせることができることを意味します。

特定のジョブからカバレッジレポートを取得するには、URLに`job=coverage_job_name`パラメータを追加します。たとえば、次のコードと同様のコードを使用して、`coverage`ジョブのテストカバレッジレポートバッジをMarkdownファイルに追加できます:

```markdown
![coverage](https://gitlab.example.com/<namespace>/<project>/badges/<branch>/coverage.svg?job=coverage)
```

### テストカバレッジの制限とバッジの色 {#test-coverage-limits-and-badge-colors}

次の表に、デフォルトのテストカバレッジの制限とバッジの色を示します:

| テストカバレッジ | パーセンテージ制限           | バッジの色 |
|---------------|-----------------------------|-------------|
| 良好          | 95～100％ | <span style="color: #4c1">■</span> `#4c1` |
| 許容可能    | 90～95％                | <span style="color:#a3c51c"> ■</span> `#a3c51c` |
| 中程度        | 75～90％                | <span style="color: #dfb317">■</span> `#dfb317` |
| 低           | 0～75％                 | <span style="color: #e05d44">■</span> `#e05d44` |
| 不明       | カバレッジなし                 | <span style="color: #9f9f9f">■</span> `#9f9f9f` |

{{< alert type="note" >}}

*～*は上限を含まない上限までを意味します。

{{< /alert >}}

### デフォルトの制限を変更 {#change-the-default-limits}

カバレッジレポートバッジURLに次のクエリパラメータを渡すことで、デフォルトの制限を上書きできます:

| クエリパラメータ  | 許容値                            | デフォルト |
|------------------|----------------------------------------------|---------|
| `min_good`       | `3`から`100`の間の任意の値              | `95`    |
| `min_acceptable` | `2`から`min_good`-1の間の任意の値       | `90`    |
| `min_medium`     | `1`から`min_acceptable`-1の間の任意の値 | `75`    |

次に例を示します:

```plaintext
https://gitlab.example.com/<namespace>/<project>/badges/<branch>/coverage.svg?min_good=98&min_acceptable=75
```

無効な境界を設定すると、GitLabは自動的に有効になるように調整します。たとえば、`min_good`を`80`に、`min_acceptable`を`85`に設定すると、最小許容値は最小良好値より高くならないため、GitLabは`min_acceptable`を`79`（`min_good - 1`）に設定します。

## 最新リリースバッジ {#latest-release-badges}

最新リリースバッジは、プロジェクトの最新リリースタグ名を示します。リリースがない場合は、`none`と表示されます。

次のリンクを使用して、最新リリースバッジ画像にアクセスできます:

```plaintext
https://gitlab.example.com/<namespace>/<project>/-/badges/release.svg
```

デフォルトでは、バッジは[`released_at`](../../api/releases/_index.md#create-a-release)時間を使用してソートされたリリースを、`?order_by`クエリパラメータでフェッチします。

```plaintext
https://gitlab.example.com/<namespace>/<project>/-/badges/release.svg?order_by=release_at
```

`value_width`パラメータを使用して、リリース名フィールドの幅を変更できます（GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113615)）。値は1～200の間でなければならず、デフォルト値は54です。範囲外の値を設定すると、GitLabは自動的にデフォルト値に調整します。

## プロジェクトバッジ {#project-badges}

バッジはメンテナーまたはオーナーがプロジェクトに追加でき、プロジェクトの**概要**ページに表示されます。同じバッジを複数のプロジェクトに追加する必要がある場合は、[グループレベル](#group-badges)で追加することをお勧めします。

### プロジェクトバッジの例: パイプラインステータス {#example-project-badge-pipeline-status}

一般的なプロジェクトバッジは、GitLab CIパイプラインの状態を示します。

このバッジをプロジェクトに追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **バッジ**を展開します。
1. **名前**に、_パイプライン状態_と入力します。
1. **リンク**に、次のURLを入力します: `https://gitlab.com/%{project_path}/-/commits/%{default_branch}`
1. **バッジ画像のURL**に、次のURLを入力します: `https://gitlab.com/%{project_path}/badges/%{default_branch}/pipeline.svg`
1. **バッジを追加**を選択します。

## グループバッジ {#group-badges}

バッジはオーナーがグループに追加でき、グループに属するすべてのプロジェクトの**概要**ページに表示されます。バッジをグループに追加することにより、グループ内のすべてのプロジェクトに対してプロジェクトレベルのバッジを追加および適用します。

{{< alert type="note" >}}

これらのバッジはコードベースでプロジェクトレベルのバッジとして表示されますが、プロジェクトレベルで編集または削除することはできません。

{{< /alert >}}

各プロジェクトに個別のバッジが必要な場合は、次のいずれかの操作を行います:

- [プロジェクトレベル](#project-badges)でバッジを追加します。
- [プレースホルダー](#placeholders)を使用します。

## バッジの表示 {#view-badges}

プロジェクトまたはグループで利用可能なバッジを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **一般**を選択します。
1. **バッジ**を展開します。

## バッジの追加 {#add-a-badge}

プロジェクトまたはグループに新しいバッジを追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **一般**を選択します。
1. **バッジ**を展開します。
1. **バッジを追加**を選択します。
1. **名前**テキストボックスに、バッジの名前を入力します。
1. **リンク**テキストボックスに、バッジが指すURLを入力します。
1. **バッジ画像のURL**テキストボックスに、バッジに表示する画像のURLを入力します。
1. **バッジを追加**を選択します。

## パイプラインバッジのURLを表示 {#view-the-url-of-pipeline-badges}

バッジの正確なリンクを表示できます。次に、リンクを使用して、バッジをHTMLまたはMarkdownページに埋め込むことができます。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **CI/CD**を選択します。
1. **一般パイプライン**を展開します。
1. **Pipeline status**（パイプライン状態）、**Coverage report**（カバレッジレポート）、または**Latest release**（最新リリース）セクションで、画像のURLを表示します。

{{< alert type="note" >}}

パイプライン状態バッジは、特定のGitリビジョン（ブランチ）に基づいています。正しいパイプライン状態を表示するには、適切なブランチを選択してください。

{{< /alert >}}

## バッジのカスタマイズ {#customize-badges}

バッジの次の側面をカスタマイズできます:

- スタイル
- テキスト
- 幅
- 画像

### バッジのスタイルのカスタマイズ {#customize-badge-style}

URLに`style=style_name`パラメータを追加すると、パイプラインバッジを異なるスタイルでレンダリングできます。2つのスタイルが利用可能です:

- フラット（デフォルト）:

  ```plaintext
  https://gitlab.example.com/<namespace>/<project>/badges/<branch>/coverage.svg?style=flat
  ```

  ![バッジフラットスタイル](img/badge_flat.svg)

- フラットスクエア:

  ```plaintext
  https://gitlab.example.com/<namespace>/<project>/badges/<branch>/coverage.svg?style=flat-square
  ```

  ![バッジフラットスクエアスタイル](img/badge_flat_square.svg)

### バッジテキストのカスタマイズ {#customize-badge-text}

バッジのテキストをカスタマイズして、同じパイプラインで実行される複数のカバレッジジョブを区別できます。`key_text=custom_text`および`key_width=custom_key_width`パラメータをURLに追加して、バッジのテキストと幅をカスタマイズします:

```plaintext
https://gitlab.com/gitlab-org/gitlab/badges/main/coverage.svg?job=karma&key_text=Frontend+Coverage&key_width=130
```

![カスタムテキストと幅のバッジ](img/badge_custom_text.svg)

### バッジ画像のカスタマイズ {#customize-badge-image}

デフォルト以外のバッジを使用する場合は、プロジェクトまたはグループでカスタムバッジ画像を使用します。

前提要件:

- バッジに必要な画像に直接ポイントする有効なURL。画像がGitLabリポジトリにある場合は、画像へのrawリンクを使用します。

プレースホルダーを使用して、リポジトリのルートにあるraw画像を参照するバッジ画像URLの例を次に示します:

```plaintext
https://gitlab.example.com/<project_path>/-/raw/<default_branch>/my-image.svg
```

カスタムイメージを使用して新しいバッジをグループまたはプロジェクトに追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **一般**を選択します。
1. **バッジ**を展開します。
1. **名前**に、バッジの名前を入力します。
1. **リンク**に、バッジが指すURLを入力します。
1. **バッジ画像のURL**に、表示するカスタム画像に直接ポイントするURLを入力します。
1. **バッジを追加**を選択します。

パイプラインを介して生成されたカスタムイメージの使用方法については、[URLで最新のジョブアーティファクトにアクセスする](../../ci/jobs/job_artifacts.md#from-a-url)に関するドキュメントを参照してください。

## バッジの編集 {#edit-a-badge}

プロジェクトまたはグループでバッジを編集するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **一般**を選択します。
1. **バッジ**を展開します。
1. 編集するバッジの横にある**編集**（{{< icon name="pencil" >}}）を選択します。
1. **名前**、**リンク**、または**バッジ画像のURL**を編集します。
1. **変更を保存**を選択します。

## バッジの削除 {#delete-a-badge}

プロジェクトまたはグループでバッジを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **一般**を選択します。
1. **バッジ**を展開します。
1. 削除するバッジの横にある**削除**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**バッジを削除します**を選択します。

{{< alert type="note" >}}

グループに関連付けられたバッジは、[グループレベル](#group-badges)でのみ編集または削除できます。

{{< /alert >}}

## プレースホルダー {#placeholders}

バッジが指すURLとイメージURLの両方にプレースホルダーを含めることができ、バッジを表示するときに評価されます。次のプレースホルダーを使用できます:

- `%{project_path}`: 親グループを含むプロジェクトのパス
- `%{project_title}`: プロジェクトのタイトル
- `%{project_name}`: プロジェクトの名前
- `%{project_id}`: プロジェクトに関連付けられたデータベースID
- `%{project_namespace}`: プロジェクトのプロジェクトネームスペース
- `%{group_name}`: プロジェクトのグループ
- `%{gitlab_server}`: プロジェクトのサーバー
- `%{gitlab_pages_domain}`: GitLab Pagesをホストするドメイン
- `%{default_branch}`: プロジェクトのリポジトリ用に設定されたデフォルトのブランチ名
- `%{commit_sha}`: プロジェクトのリポジトリのデフォルトブランチへの最新のコミットのID
- `%{latest_tag}`: プロジェクトのリポジトリに追加された最新のタグ

{{< alert type="note" >}}

プレースホルダーを使用すると、プロジェクトがプライベートリポジトリを持つように設定されている場合に、バッジがデフォルトブランチやコミットSHAなどの通常は非公開の情報を公開できます。バッジは公開で使用されることを目的としているため、この動作は意図的です。情報が機密の場合は、これらのプレースホルダーの使用を避けてください。

{{< /alert >}}
