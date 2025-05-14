---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインエディタ
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パイプラインエディタは、リポジトリのルートにある`.gitlab-ci.yml`ファイルで GitLab CI/CD の設定を編集するための主要な場所です。エディタにアクセスするには、**ビルド > パイプラインエディタ**に移動します。

パイプラインエディタページから、次のことができます。

- 作業するブランチを選択します。
- ファイルの編集中に、設定の構文を[検証](#validate-ci-configuration)します。
- [`include`](../yaml/_index.md#include) キーワードで追加されたすべての設定で検証する、設定のより詳細な[Lint](#lint-ci-configuration)を実行します。
- [`include` キーワードで追加された CI/CD 設定のリスト](#view-included-cicd-configuration)を表示します。
- 現在の設定の[視覚化](#visualize-ci-configuration)を表示します。
- `include`から追加されたすべての設定を含む設定を表示する[完全な設定](#view-full-configuration)を表示します。
- 特定のブランチへの変更を[コミット](#commit-changes-to-ci-configuration)します。

## CI設定の検証

パイプラインの設定を編集すると、GitLab CI/CD パイプラインスキーマに対して継続的に検証されます。CI YAML設定の構文をチェックし、いくつかの基本的な論理検証も実行します。

この検証の結果は、エディタページの上部に表示されます。検証に失敗した場合、このセクションには問題を修正するためのヒントが表示されます。

## CI設定のLint

{{< alert type="note" >}}

**Lint** タブは、GitLab 15.3 で **検証する** タブに置き換えられました。Lintの結果は、成功した[パイプラインシミュレーション](#simulate-a-cicd-pipeline)に含まれています。

{{< /alert >}}

変更をコミットする前に GitLab CI/CD 設定の有効性を Test するには、CI Lint ツールを使用します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **ビルド > パイプラインエディタ**を選択します。
1. **検証する**タブを選択します。

このツールは構文エラーとロジックエラーをチェックしますが、エディタの自動[検証](#validate-ci-configuration)よりも詳細になります。

結果はリアルタイムで更新されます。設定に加えた変更はすべて、CI Lint に反映されます。既存の[CI Lintツール](../yaml/lint.md)と同じ結果が表示されます。

## CI/CDパイプラインのシミュレーション

{{< history >}}

- GitLab 15.3 で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/337282)。

{{< /history >}}

パイプラインの構文とロジックのイシューを探すには、**検証する**タブで GitLab CI/CD パイプラインの作成をシミュレートします。パイプラインシミュレーションは、正しくない`rules`および`needs`ジョブの依存関係などの問題を見つけるのに役立ち、[CI Lint ツール](../yaml/lint.md#simulate-a-pipeline)のシミュレーションに似ています。

## 含まれているCI/CD設定の表示

{{< history >}}

- GitLab 15.0 で[導入](https://gitlab.com/groups/gitlab-org/-/epics/7064) ([フラグ付き](../../administration/feature_flags.md)、名前は `pipeline_editor_file_tree`)。デフォルトでは無効になっています。
- GitLab 15.1 で[機能フラグが削除](https://gitlab.com/gitlab-org/gitlab/-/issues/357219)されました。

{{< /history >}}

パイプラインエディタで[`include`](../yaml/_index.md#include)キーワードを使用して追加された設定をレビューできます。右上隅で、ファイルツリー({{< icon name="file-tree" >}})を選択して、含まれているすべての設定ファイルのリストを表示します。選択したファイルが新しいタブで開き、レビューできます。

## CI設定の視覚化

`.gitlab-ci.yml`設定の視覚化を表示するには、プロジェクトで、**ビルド > パイプラインエディタ**に移動し、**視覚化**タブを選択します。視覚化には、すべてのステージとジョブが表示されます。任意の[`needs`](../yaml/_index.md#needs)関係は、ジョブ同士を結び付ける線として表示され、実行の階層を示します。

ジョブの上にカーソルを置くと、その`needs`関係が強調表示されます。

![ホバー時のCI/CD設定の視覚化](img/ci_config_visualization_hover_v17_9.png)

設定に`needs`関係がない場合、各ジョブは前のステージが正常に完了した場合にのみ依存するため、線は描画されません。

## 完全な設定を表示

{{< history >}}

- **YAMLのマージ表示**タブは、GitLab 16.0 で[**完全な設定**](https://gitlab.com/gitlab-org/gitlab/-/issues/377404)に名称変更されました。

{{< /history >}}

完全に展開されたCI/CD設定を1つの結合ファイルとして表示するには、パイプラインエディタの**完全な設定**タブに移動します。このタブには、展開された設定が表示されます。

- [`include`](../yaml/_index.md#include)でインポートされた設定がビューにコピーされます。
- [`extends`](../yaml/_index.md#extends)を使用するジョブは、[拡張設定がジョブにマージ](../yaml/yaml_optimization.md#merge-details)されて表示されます。
- [YAMLアンカー](../yaml/yaml_optimization.md#anchors)は、リンクされた設定に置き換えられます。
- [YAML `!reference`tag](../yaml/yaml_optimization.md#reference-tags)も、リンクされた設定に置き換えられます。

`!reference`tag を使用すると、展開されたビューの行の先頭に複数のハイフン(`-`)が表示されるネストされた設定が発生する可能性があります。この動作は予期されたものであり、余分なハイフンはジョブの実行に影響しません。たとえば、この設定と完全に展開されたバージョンはどちらも有効です。

- `.gitlab-ci.yml`ファイル:

  ```yaml
  .python-req:
    script:
      - pip install pyflakes

  .rule-01:
    rules:
      - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/
        when: manual
        allow_failure: true
      - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME

  .rule-02:
    rules:
      - if: $CI_COMMIT_BRANCH == "main"
        when: manual
        allow_failure: true

  lint-python:
    image: python:latest
    script:
      - !reference [.python-req, script]
      - pyflakes python/
    rules:
      - !reference [.rule-01, rules]
      - !reference [.rule-02, rules]
  ```

- **完全な設定**タブの展開された設定:

  ```yaml
  ".python-req":
    script:
    - pip install pyflakes
  ".rule-01":
    rules:
    - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/"
      when: manual
      allow_failure: true
    - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"
  ".rule-02":
    rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
      allow_failure: true
  lint-python:
    image: python:latest
    script:
    - - pip install pyflakes                                     # <- The extra hyphens do not affect the job's execution.
    - pyflakes python/
    rules:
    - - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/" # <- The extra hyphens do not affect the job's execution.
        when: manual
        allow_failure: true
      - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"               # <- No extra hyphen but aligned with previous rule
    - - if: $CI_COMMIT_BRANCH == "main"                          # <- The extra hyphens do not affect the job's execution.
        when: manual
        allow_failure: true
  ```

## CI設定への変更のコミット

エディタの各タブの下部にコミットフォームが表示されるため、いつでも変更をコミットできます。

変更に満足したら、記述的なコミットメッセージを追加してブランチを入力します。ブランチフィールドは、プロジェクトのデフォルトブランチにデフォルト設定されています。

新しいブランチ名を入力すると、**これらの変更で新しいマージリクエストを開始する**チェックボックスが表示されます。それを選択して、変更をコミットした後に新しいマージリクエストを開始します。

![新しいブランチを含むコミットフォーム](img/pipeline_editor_commit_v13_8.png)

## トラブルシューティング

### `Configuration validation currently not available`メッセージ

このメッセージは、パイプラインエディタで構文を検証する際に問題が発生した場合に表示されます。これは、次の場合に発生する可能性があります。

- GitLabが構文を検証するサービスと通信できないため、これらのセクションの情報が正しく表示されない場合があります。

  - **編集**タブの構文状態(有効または無効)。
  - **視覚化**タブ。
  - **Lint**タブ。
  - **完全な設定**タブ。

  CI/CD設定を引き続き操作し、イシューなく変更をコミットできます。サービスが再び利用可能になるとすぐに、構文の検証がすぐに表示されます。

- [`include`](../yaml/_index.md#include)を使用していますが、含まれている設定ファイルによって loop が作成されます。たとえば、`.gitlab-ci.yml`には`file1.yml`、それには`file2.yml`、それには`file1.yml`が含まれており、`file1.yml`と`file2.yml`の間に loop が作成されます。

  `include`行の1つを削除して、loop を排除し、イシューを解決します。
