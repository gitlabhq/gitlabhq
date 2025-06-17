---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Control the job concurrency in GitLab CI/CD
title: リソースグループ
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デフォルトでは、GitLab CI/CDのパイプラインは同時に実行されます。並行処理は、マージリクエストのフィードバックループを改善するための重要な要素ですが、デプロイジョブの並行処理を制限して、一度に1つずつ実行したい場合があります。リソースグループを使用して、ジョブの並行処理を戦略的に制御し、継続的デプロイメントワークフローを安全に最適化します。

## リソースグループを追加

リソースグループに追加できるリソースは1つのみです。

次のパイプライン設定（リポジトリ内の `.gitlab-ci.yml` ファイル）があるとします。

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
```

ブランチに新しいコミットをプッシュするたびに、2つのジョブ `build` と `deploy` を持つ新しいパイプラインが実行されます。ただし、短い間隔で複数のコミットをプッシュすると、複数のパイプラインが同時に実行され始めます。次に例を示します。

- 最初のパイプラインはジョブ `build` -> `deploy` を実行します
- 2番目のパイプラインはジョブ `build` -> `deploy` を実行します

この場合、異なるパイプラインにまたがる `deploy` ジョブは、`production` 環境に対して同時に実行される可能性があります。同じインフラストラクチャに対して複数のデプロイスクリプトを実行すると、インスタンスに損害を与えたり、混乱させたりする可能性があり、最悪の場合、破損した状態になる可能性があります。

`deploy` ジョブが一度に1つずつ実行されるようにするには、並行処理の影響を受けやすいジョブに [`resource_group` キーワード](../yaml/_index.md#resource_group) を指定します。

```yaml
deploy:
  # ...
  resource_group: production
```

この設定により、デプロイメントの安全性が確保され、パイプラインの効率性を最大化するために `build` ジョブを同時に実行できます。

## 前提要件

- [GitLab CI/CD パイプライン](../pipelines/_index.md) の基本的な知識
- [GitLab環境とデプロイメント](../environments/_index.md) の基本的な知識
- CI/CDパイプラインをConfigureするには、プロジェクトのデベロッパーロール以上の権限が必要です。

## 処理モード

デプロイ設定に合わせてジョブの並行処理を戦略的に制御するために、処理モードを選択できます。次のモードがサポートされています:

- **順不同:**これは、実行中のジョブの並行処理を制限するデフォルトの処理モードです。ジョブの実行順序を気にしない場合は、これが最も簡単なオプションです。ジョブの実行準備が整うと、すぐにジョブの処理を開始します。
- **最古順:**この処理モードはジョブの並行処理を制限します。リソースが空いている場合、パイプラインIDで昇順にソートされた、リストにあるこれから実行するジョブ（`created`、`scheduled`、または `waiting_for_resource` 状態）から最初のジョブを選択します。

  このモードは、ジョブを最も古いパイプラインから実行する必要がある場合に効率的です。パイプラインの効率という点では `unordered` モードに比べて効率性は劣りますが、継続的デプロイメントにはより安全です。

- **最新順:**この処理モードはジョブの並行処理を制限します。リソースが空いている場合、パイプラインIDで降順にソートされた、リストにあるこれから実行するジョブ（`created`、`scheduled`、または `waiting_for_resource` 状態）から最初のジョブを選択します。

  このモードは、最新のパイプラインからジョブが実行されるようにし、[最新ではないデプロイジョブを防止](../environments/deployment_safety.md#prevent-outdated-deployment-jobs) 機能を使用して、古いデプロイジョブをすべて防止する場合に効率的です。これは、パイプラインの効率という点では最も効率的なオプションですが、各デプロイジョブがべき等であることを確認する必要があります。

### 処理モードの変更

リソースグループの処理モードを変更するには、APIを使用し、`process_mode` を指定して [既存のリソースグループを編集](../../api/resource_groups.md#edit-an-existing-resource-group) するリクエストを送信する必要があります。

- `unordered`
- `oldest_first`
- `newest_first`

### 処理モード間の違いの例

次の `.gitlab-ci.yml` について考えてみます。ここでは、2つのジョブ `build` と `deploy` がそれぞれ独自のステージで実行されており、`deploy` ジョブには `production` に設定されたリソースグループがあります。

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
  resource_group: production
```

3つのコミットが短い間隔でプロジェクトにプッシュされた場合、3つのパイプラインがほぼ同時に実行されることを意味します。

- 最初のパイプラインはジョブ `build` -> `deploy` を実行します。このデプロイジョブを `deploy-1` と呼びましょう。
- 2番目のパイプラインはジョブ `build` -> `deploy` を実行します。このデプロイジョブを `deploy-2` と呼びましょう。
- 3番目のパイプラインはジョブ `build` -> `deploy` を実行します。このデプロイジョブを `deploy-3` と呼びましょう。

リソースグループの処理モードに応じて、次のようになります。

- 処理モードが `unordered` に設定されている場合:
  - `deploy-1`、`deploy-2`、および `deploy-3` は同時に実行されません。
  - ジョブの実行順序は保証されていません。たとえば、`deploy-1` は `deploy-3` の実行前または実行後に実行される可能性があります。
- 処理モードが `oldest_first` の場合:
  - `deploy-1`、`deploy-2`、および `deploy-3` は同時に実行されません。
  - `deploy-1` が最初に実行され、`deploy-2` が2番目に実行され、`deploy-3` が最後に実行されます。
- 処理モードが `newest_first` の場合:
  - `deploy-1`、`deploy-2`、および `deploy-3` は同時に実行されません。
  - `deploy-3` が最初に実行され、`deploy-2` が2番目に実行され、`deploy-1` が最後に実行されます。

## クロスプロジェクト/親子パイプラインによるパイプラインレベルの並行処理制御

並行処理に影響されやすいダウンストリームパイプラインに対して `resource_group` を定義できます。[`trigger` キーワード](../yaml/_index.md#trigger) はダウンストリームパイプラインをトリガーでき、[`resource_group` キーワード](../yaml/_index.md#resource_group) はそれと共存できます。`resource_group` はデプロイメントパイプラインの並行処理を制御するのに効率的ですが、他のジョブは引き続き同時に実行できます。

次の例では、プロジェクトに2つのパイプライン設定があります。パイプラインの実行が開始されると、影響を受けやすいジョブ以外のジョブが最初に実行され、他のパイプラインでの並行処理の影響を受けません。ただし、GitLabは、デプロイメント（子）パイプラインをトリガーする前に、他のデプロイメントパイプラインが実行されていないことを確認します。他のデプロイメントパイプラインが実行されている場合、GitLabはこれらのパイプラインが完了するまで待機してから、別のパイプラインを実行します。

```yaml
# .gitlab-ci.yml (parent pipeline)

build:
  stage: build
  script: echo "Building..."

test:
  stage: test
  script: echo "Testing..."

deploy:
  stage: deploy
  trigger:
    include: deploy.gitlab-ci.yml
    strategy: depend
  resource_group: AWS-production
```

```yaml
# deploy.gitlab-ci.yml (child pipeline)

stages:
  - provision
  - deploy

provision:
  stage: provision
  script: echo "Provisioning..."

deployment:
  stage: deploy
  script: echo "Deploying..."
  environment: production
```

`trigger` キーワードで [`strategy: depend`](../yaml/_index.md#triggerstrategy) を定義する必要があります。これにより、ダウンストリームパイプラインが完了するまでロックがリリースされないようになります。

## 関連トピック

- [APIドキュメント](../../api/resource_groups.md)
- [logドキュメント](../../administration/logs/_index.md#ci_resource_groups_jsonlog)
- [安全なデプロイメントのためのGitLab](../environments/deployment_safety.md)

## トラブルシューティング

### パイプライン設定でデッドロックを回避する

[`oldest_first` 処理モード](#process-modes) では、ジョブがパイプライン順に実行されるため、他のCI機能とうまく連携しない場合があります。

たとえば、親パイプラインと同じリソースグループを必要とする[子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)を実行すると、デッドロックが発生する可能性があります。以下は _悪い_ 設定の例です。

```yaml
# BAD
test:
  stage: test
  trigger:
    include: child-pipeline-requires-production-resource-group.yml
    strategy: depend

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

親パイプラインでは、`test` ジョブを実行して子パイプラインを後続で実行し、[`strategy: depend` オプション](../yaml/_index.md#triggerstrategy) は、`test` ジョブが子パイプラインの完了まで待機するようにします。親パイプラインは、`production` リソースグループのリソースを必要とする次のステージで `deploy` ジョブを実行します。処理モードが `oldest_first` の場合、最も古いパイプラインからジョブが実行されます。つまり、`deploy` ジョブが次に実行されます。

ただし、子パイプラインも `production` リソースグループのリソースを必要とします。子パイプラインは親パイプラインよりも新しいため、`deploy` ジョブが完了するまで子パイプラインは待機します。これは決して起こりません。

この場合、代わりに親パイプライン設定で `resource_group` キーワードを指定する必要があります。

```yaml
# GOOD
test:
  stage: test
  trigger:
    include: child-pipeline.yml
    strategy: depend
  resource_group: production # Specify the resource group in the parent pipeline

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

### ジョブが「リソース待機中」でスタックする

ジョブが `Waiting for resource: <resource_group>` というメッセージでハングすることがあります。解決するには、まずリソースグループが正しく機能していることを確認します。

1. ジョブの詳細ページに移動します。
1. リソースがジョブに割り当てられている場合は、**現在リソースを使用しているジョブを表示** を選択し、ジョブの状態を確認します。

   - 状態が `running` または `pending` の場合、機能は正しく動作しています。ジョブが完了してリソースをリリースするまで待ちます。
   - 状態が `created` であり、[処理モード](#process-modes) が **最古順** または **最新順** のいずれかである場合、機能は正しく動作しています。ジョブのパイプラインページにアクセスし、どのアップストリームステージまたはジョブが実行をブロックしているかを確認します。
   - 上記の条件のいずれも満たされていない場合、機能が正しく動作していない可能性があります。[GitLabにイシューを報告](#report-an-issue) します。

1. **現在リソースを使用しているジョブを表示** が利用できない場合、リソースはジョブに割り当てられていません。代わりに、リソースの今後のジョブを確認してください。

   1. [REST API](../../api/resource_groups.md#list-upcoming-jobs-for-a-specific-resource-group) でリソースの今後のジョブを取得します。
   1. リソースグループの[処理モード](#process-modes)が**最古順**であることを検証します。
   1. 今後のジョブのリストで最初のジョブを見つけ、[GraphQLで](#get-job-details-through-graphql)ジョブの詳細を取得します。
   1. 最初のジョブのパイプラインが古いパイプラインの場合は、パイプラインまたはジョブ自体をキャンセルしてみてください。
   1. 任意。次の今後のジョブがまだ実行されなくなった古いパイプラインにある場合は、このプロセスを繰り返します。
   1. イシューが解決しない場合は、[GitLabに問題を報告](#report-an-issue) します。

#### 複雑またはビジーなパイプラインでの競合状態

上記の方法でイシューを解決できない場合は、既知の競合状態の問題が発生している可能性があります。競合状態は、複雑またはビジーなパイプラインで発生します。たとえば、次のような場合に競合状態が発生する可能性があります。

- 複数の子パイプラインを持つパイプライン。
- 複数のパイプラインが同時に実行されている単一のプロジェクト。

このイシューが発生していると思われる場合は、[GitLabに問題を報告](#report-an-issue) し、新しい問題へのリンクを付けて [イシュー 436988](https://gitlab.com/gitlab-org/gitlab/-/issues/436988) にコメントを残してください。問題を確認するために、GitLabは完全なパイプライン設定などの追加の詳細を求める場合があります。

一時的な回避策として、次のことができます。

- 新しいパイプラインを開始します。
- スタックしたジョブと同じリソースグループを持つ完了したジョブを再実行します。

  たとえば、同じリソースグループを持つ `setup_job` と `deploy_job` がある場合、`deploy_job` が「リソース待機中」でスタックしている間、`setup_job` が完了する可能性があります。`setup_job` を再起動してプロセス全体を再開し、`deploy_job` が完了できるようにします。

#### GraphQLを介してジョブの詳細を取得

GraphQL APIからジョブ情報を取得できます。[クロスプロジェクト/親子パイプラインによるパイプラインレベルの並行処理制御](#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines) を使用する場合は、トリガージョブがUIからアクセスできないため、GraphQL APIを使用する必要があります。

GraphQL APIからジョブ情報を取得するには:

1. パイプラインの詳細ページに移動します。
1. **ジョブ** タブを選択し、スタックしたジョブのIDを見つけます。
1. [インタラクティブGraphQLエクスプローラー](../../api/graphql/_index.md#interactive-graphql-explorer) に移動します。
1. 次のクエリを実行します:

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       name
       job(id: "gid://gitlab/Ci::Build/<job-id>") {
         name
         status
         detailedStatus {
           action {
             path
             buttonTitle
           }
         }
       }
     }
   }
   ```

    `job.detailedStatus.action.path` フィールドには、リソースを使用しているジョブIDが含まれています。

1. 次のクエリを実行し、上記の基準に従って `job.status` フィールドを確認します。`pipeline.path` フィールドからパイプラインページにアクセスすることもできます。

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       name
       job(id: "gid://gitlab/Ci::Build/<job-id-currently-using-the-resource>") {
         name
         status
         pipeline {
           path
         }
       }
     }
   }
   ```

### イシューを報告

次の情報で[新しいイシューをオープン](https://gitlab.com/gitlab-org/gitlab/-/issues/new) します:

- 影響を受けるジョブのID。
- ジョブの状態。
- 問題の発生頻度。
- 問題を再現する手順。

  詳細な支援が必要な場合、または開発チームに連絡を取りたい場合は、[サポートに連絡](https://about.gitlab.com/support/#contact-support) することもできます。
