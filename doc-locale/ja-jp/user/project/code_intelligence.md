---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: プロジェクト内のオブジェクトのすべての用途を見つけるには、コードインテリジェンスを使用します。
title: コードインテリジェンス
description: 型シグネチャ、シンボルのドキュメント、定義への移動。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コードインテリジェンスは、インタラクティブな開発環境（IDE）に共通するコードナビゲーション機能を追加します。以下を含みます:

- 型の署名とシンボルのドキュメント。
- 定義へ移動。

コードインテリジェンスは、GitLabに組み込まれており、事前に計算されたコードインテリジェンスデータ用のファイル形式である[LSIF](https://lsif.dev/)（Language Server Index Format）を利用しています。GitLabはプロジェクトごとに1つのLSIFファイルを処理し、コードインテリジェンスはブランチごとに異なるLSIFファイルをサポートしていません。

[SCIP](https://github.com/sourcegraph/scip/)は、ソースコードのインデックス作成を行うツールの次世代版です。これを使用して、次のようなコードナビゲーション機能を強化できます:

- 定義へ移動
- 参照を検索

GitLabは、コードインテリジェンス用のSCIPをネイティブにサポートしていません。ただし、[SCIPコマンドラインインターフェース](https://github.com/sourcegraph/scip/blob/main/docs/CLI.md)を使用して、SCIPツールで生成されたインデックスをLSIF互換ファイルに変換できます。ネイティブSCIPサポートに関するディスカッションについては、[issue 412981](https://gitlab.com/gitlab-org/gitlab/-/issues/412981)を参照してください。

今後のコードインテリジェンスの機能強化の進捗状況については、[エピック4212](https://gitlab.com/groups/gitlab-org/-/epics/4212)を参照してください。

## コードインテリジェンスの設定 {#configure-code-intelligence}

前提要件: 

- プロジェクトの言語に互換性のあるインデクサーがあることを確認済みです:
  - [LSIFインデクサー](https://lsif.dev/#implementations-server)
  - [SCIPインデクサー](https://github.com/sourcegraph/scip/#tools-using-scip)

お使いの言語がどのように最適にサポートされているかを確認するには、[Sourcegraphが推奨するインデクサー](https://sourcegraph.com/docs/code-search/code-navigation/writing_an_indexer#sourcegraph-recommended-indexers)を確認してください。

### CI/CDコンポーネントを使用する {#with-the-cicd-component}

{{< history >}}

- Go言語のサポートは、GitLab 17.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/301111)。
- .Net/C#のサポートは、GitLab 18.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/372243)。

{{< /history >}}

GitLabは、`.gitlab-ci.yml`ファイルでコードインテリジェンスを設定するための[CI/CDコンポーネント](../../ci/components/_index.md)を提供します。このコンポーネントは、次の言語をサポートしています:

- Go言語バージョン1.21以降。
- TypeScriptまたはJavaScript。
- Java 8、11、17、および21。
- Python
- .Net/C#

コンポーネントに言語をコントリビュートするには、[コードインテリジェンスコンポーネントプロジェクト](https://gitlab.com/components/code-intelligence)でマージリクエストを開いてください。

1. GitLab CI/CDコンポーネントをプロジェクトの`.gitlab-ci.yml`に追加します。たとえば、このジョブは`golang`のLSIFアーティファクトを生成します:

   ```yaml
   include:
     - component: ${CI_SERVER_FQDN}/components/code-intelligence/golang-code-intel@v0.0.3
       inputs:
         golang_version: ${GO_VERSION}
   ```

1. [コードインテリジェンスコンポーネント](https://gitlab.com/components/code-intelligence)の設定手順については、サポートされている各言語の`README`を確認してください。
1. 詳細な設定については、[コンポーネントの使用](../../ci/components/_index.md#use-a-component)を参照してください。

### コードインテリジェンスのCI/CDジョブを追加する {#add-cicd-jobs-for-code-intelligence}

プロジェクトのコードインテリジェンスを有効にするには、GitLab CI/CDジョブをプロジェクトの`.gitlab-ci.yml`に追加します。

{{< tabs >}}

{{< tab title="SCIPインデクサーを使用する" >}}

1. ジョブを`.gitlab-ci.yml`設定に追加します。このジョブは、SCIPインデックスを生成し、GitLabで使用するためにLSIFに変換します:

   ```yaml
   "code_navigation":
      rules:
      - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH # the job only needs to run against the default branch
      image: node:latest
      stage: test
      allow_failure: true # recommended
      script:
         - npm install -g @sourcegraph/scip-typescript
         - npm install
         - scip-typescript index
         - |
            env \
            TAG="v0.4.0" \
            OS="$(uname -s | tr '[:upper:]' '[:lower:]')" \
            ARCH="$(uname -m | sed -e 's/x86_64/amd64/')" \
            bash -c 'curl --location "https://github.com/sourcegraph/scip/releases/download/$TAG/scip-$OS-$ARCH.tar.gz"' \
            | tar xzf - scip
         - chmod +x scip
         - ./scip convert --from index.scip --to dump.lsif
      artifacts:
         reports:
            lsif: dump.lsif
   ```

1. CI/CDの設定によっては、ジョブを手動で実行するか、既存のパイプラインの一部として実行されるまで待つ必要がある場合があります。

{{< /tab >}}

{{< tab title="LSIFインデクサーを使用する" >}}

1. インデックスを生成するには、ジョブ（`code_navigation`）を`.gitlab-ci.yml`設定に追加します:

   ```yaml
   code_navigation:
      rules:
      - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH # the job only needs to run against the default branch
     image: sourcegraph/lsif-go:v1
     allow_failure: true # recommended
     script:
       - lsif-go
     artifacts:
       reports:
         lsif: dump.lsif
   ```

1. CI/CDの設定によっては、ジョブを手動で実行するか、既存のパイプラインの一部として実行されるまで待つ必要がある場合があります。

{{< /tab >}}

{{< /tabs >}}

{{< alert type="note" >}}

GitLabは、[（`ci_max_artifact_size_lsif`）](../../administration/instance_limits.md#maximum-file-size-per-type-of-artifact)アーティファクトアプリケーションの制限により、コード生成ジョブによって生成されるアーティファクトを200 MBに制限します。GitLab Self-Managedインスタンスでは、インスタンス管理者はこの値を変更できます。

{{< /alert >}}

## コードインテリジェンスの結果を表示する {#view-code-intelligence-results}

ジョブが成功したら、リポジトリを参照してコードインテリジェンス情報を確認します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで**コード** > **リポジトリ**を選択します。
1. リポジトリ内のファイルに移動します。ファイル名がわかっている場合は、次のいずれかの操作を行います:
   - `/~`キーボードショートカットを入力してファイルファインダーを開き、ファイル名を入力します。
   - 右上にある**ファイルを検索**を選択します。
1. コード行をポイントします。コードインテリジェンスからの情報が記載された行の項目には、その下に点線が表示されます:

   ![コードインテリジェンス](img/code_intelligence_v17_0.png)

1. 項目を選択して、詳細情報を確認します。

## 参照を検索 {#find-references}

コードインテリジェンスを使用して、オブジェクトのすべての用途を表示します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで**コード** > **リポジトリ**を選択します。
1. リポジトリ内のファイルに移動します。ファイル名がわかっている場合は、次のいずれかの操作を行います:
   - `/~`キーボードショートカットを入力してファイルファインダーを開き、ファイル名を入力します。
   - 右上にある**ファイルを検索**を選択します。
1. オブジェクトをポイントし、それを選択します。
1. ダイアログで、次を選択します:
   - **定義**: このオブジェクトの定義を表示します。
   - **参照**: このオブジェクトを使用するファイルのリストを表示します。

   ![この変数は、このプロジェクトで2回参照されています。](img/code_intelligence_refs_v17_6.png)
