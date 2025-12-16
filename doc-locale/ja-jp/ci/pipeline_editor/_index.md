---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインエディタ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パイプラインエディタは、リポジトリのルートにある`.gitlab-ci.yml`ファイルでGitLab CI/CDの設定を編集するための主要な場所です。エディタにアクセスするには、**ビルド** > **パイプラインエディタ**に移動します。

パイプラインエディタページでは、次のことができます:

- 作業するブランチを選択する。
- ファイルの編集中に、設定の構文を[検証](#validate-cicd-syntax)する。
- 設定に対してより厳密な[検証](#validate-cicd-configuration)を実行し、[`include`](../yaml/_index.md#include)キーワードで追加されたすべての設定を検証します。
- [`include`キーワードで追加されたCI/CD設定のリスト](#view-included-cicd-configuration)を表示する。
- 現在の設定を[視覚化](#visualize-ci-configuration)して表示する。
- [完全な設定](#view-full-configuration)を表示する。これには、`include`から追加された設定もすべて含まれます。
- 特定のブランチに変更を[コミット](#commit-changes-to-ci-configuration)する。

## CI/CD検証構文 {#validate-cicd-syntax}

パイプラインエディタを使用すると、パイプラインの設定構文がGitLab CI/CDパイプラインスキーマに対して継続的に検証されます。CI/CD YAMLの構文と、いくつかの基本的な論理検証がチェックされます。

この検証の結果は、エディタページの上部に表示されます。検証に失敗した場合、このセクションに問題を修正するためのヒントが表示されます。

## CI/CD設定を検証する {#validate-cicd-configuration}

{{< history >}}

- 異なるブランチを選択するオプションがGitLab 18.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/482676)。

{{< /history >}}

コミットする前にGitLab CI/CD設定の有効性をテストするには、パイプラインエディタ検証ツールを使用します。このツールは、Gitプッシュイベントによるパイプラインの作成をシミュレートし、正しくない`rules`や`needs`ジョブの依存関係などのロジックのトラブルシューティングに役立ちます:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **ビルド** > **パイプラインエディタ**を選択します。
1. **検証**タブを選択します。
1. オプション。**パイプラインを実行するソース**ドロップダウンリストを使用して、シミュレートされたプッシュイベントに使用する別のブランチを選択します。
1. **パイプラインの検証**を選択します。

シミュレートされたパイプラインは、**編集**タブの既存のパイプライン設定を使用します。

**編集**タブにCI/CD YAMLスニペットを追加せずに検証するには、代わりに[CI Lint tool](../yaml/lint.md#simulate-a-pipeline)を使用します。

## インクルードされたCI/CD設定を表示する {#view-included-cicd-configuration}

{{< history >}}

- GitLab 15.0で`pipeline_editor_file_tree`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/7064)されました。デフォルトでは無効になっています。
- GitLab 15.1で[機能フラグは削除](https://gitlab.com/gitlab-org/gitlab/-/issues/357219)されました。

{{< /history >}}

パイプラインエディタでは、[`include`](../yaml/_index.md#include)キーワードで追加された設定を確認できます。右上隅で、ファイルツリー（{{< icon name="file-tree" >}}）を選択して、インクルードされたすべての設定ファイルのリストを表示します。選択したファイルは新しいタブで開き、確認できます。

## CI設定を視覚化する {#visualize-ci-configuration}

`.gitlab-ci.yml`設定の視覚化を表示するには、プロジェクトで、**ビルド** > **パイプラインエディタ**に移動し、**視覚化**タブを選択します。この視覚化には、すべてのステージとジョブが表示されます。[`needs`](../yaml/_index.md#needs)関係は、ジョブを結ぶ線として表示され、実行の階層を示します。

ジョブの上にカーソルを合わせると、そのジョブの`needs`関係が強調表示されます:

![ホバー時のCI/CD設定の視覚化](img/ci_config_visualization_hover_v17_9.png)

設定に`needs`関係がない場合、各ジョブは前のステージが正常に完了したことのみに依存するため、線は描画されません。

## 完全な設定を表示する {#view-full-configuration}

{{< history >}}

- **View merged YAML**（マージされたYAMLの表示）タブは、GitLab 16.0で[**完全な設定**に名前が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/377404)されました。

{{< /history >}}

完全に展開されたCI/CD設定を1つの結合ファイルとして表示するには、パイプラインエディタの**完全な設定**タブに移動します。このタブには、次のように展開された設定が表示されます:

- [`include`](../yaml/_index.md#include)でインポートされた設定がビューにコピーされる。
- [`extends`](../yaml/_index.md#extends)を使用するジョブは、[拡張された設定がジョブにマージ](../yaml/yaml_optimization.md#merge-details)された状態で表示される。
- [YAMLアンカー](../yaml/yaml_optimization.md#anchors)は、リンクされた設定に置き換えられる。
- [YAMLの`!reference`タグ](../yaml/yaml_optimization.md#reference-tags)も、リンクされた設定に置き換えられる。
- 条件付きルールは、デフォルトブランチへのプッシュイベントを前提として評価される。

`!reference`タグを使用すると、展開ビューで、ネストされた設定の行の先頭に複数のハイフン（`-`）が表示されることがあります。これは想定された動作であり、余分なハイフンがあってもジョブの実行には影響しません。たとえば、この設定と完全に展開した後の設定はどちらも有効です:

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

- **完全な設定**タブでの展開後の設定:

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

## CI設定への変更をコミットする {#commit-changes-to-ci-configuration}

エディタの各タブの下部にコミットフォームが表示されるため、いつでも変更をコミットできます。

変更に満足したら、記述的なコミットメッセージを追加してブランチを入力します。ブランチフィールドには、プロジェクトのデフォルトブランチがデフォルトで設定されています。

新しいブランチ名を入力すると、**Start a new merge request with these changes**（これらの変更で新しいマージリクエストを開始）チェックボックスが表示されます。これをオンにすると、変更をコミットした後に新しいマージリクエストを開始できます。

![新しいブランチが指定されているコミットフォーム](img/pipeline_editor_commit_v13_8.png)

## エディタのアクセシビリティオプション {#editor-accessibility-options}

パイプラインエディタは、[Monaco Editor](https://github.com/microsoft/monaco-editor)をベースにしており、[アクセシビリティ機能](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide)がいくつか用意されています:

| 機能                          | WindowsまたはLinuxでのショートカット      | macOSでのショートカット                                    | 詳細 |
|----------------------------------|-----------------------------------|------------------------------------------------------|---------|
| キーボードナビゲーションコマンドリスト | <kbd>F1</kbd>                     | <kbd>F1</kbd>                                        | エディタをマウスなしでも使いやすくする[コマンドのリスト](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide#keyboard-navigation)です。 |
| タブトラップ                     | <kbd>Control</kbd> + <kbd>m</kbd> | <kbd>Control</kbd> + <kbd>Shift</kbd> + <kbd>m</kbd> | タブ文字を挿入するのではなく、ページ上の次のフォーカス可能な要素に移動する[タブトラップ](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide#tab-trapping)を有効にします。 |

## トラブルシューティング {#troubleshooting}

### `Unable to validate CI/CD configuration.`メッセージ {#unable-to-validate-cicd-configuration-message}

このメッセージは、パイプラインエディタで構文を検証する際に問題が発生した場合に表示されます。これは、GitLabが構文を検証するサービスと通信できない場合に発生することがあります。

次のセクションの情報が正しく表示されない場合があります:

- **編集**タブの構文ステータス（有効または無効）。
- **視覚化**タブ。
- **Lint**タブ。
- **完全な設定**タブ。

CI/CD設定を引き続き操作し、問題なく変更をコミットできます。サービスが再び利用可能になると、構文の検証がすぐに表示されます。
