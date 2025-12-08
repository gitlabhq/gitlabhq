---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab CI/CDでジョブの並行処理を制御する
title: リソースグループ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デフォルトでは、GitLab CI/CDのパイプラインは複数同時に実行されます。並行処理は、マージリクエストのフィードバックループを改善するうえで重要な要素ですが、デプロイメントジョブの並行処理を制限して、一度に1つずつ実行したい場合があります。リソースグループを使用すると、ジョブの並行処理を戦略的に制御し、継続的デプロイメントワークフローを安全に最適化できます。

## リソースグループを追加する {#add-a-resource-group}

リソースグループに追加できるリソースは1つのみです。

次のようなパイプライン設定（リポジトリ内の`.gitlab-ci.yml`ファイル）があるとします:

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
```

ブランチに新しいコミットをプッシュするたびに、2つのジョブ`build`と`deploy`を持つ新しいパイプラインが実行されます。ただし、短い間隔で複数のコミットをプッシュすると、複数のパイプラインが同時に実行を開始します。次に例を示します:

- 最初のパイプラインはジョブ`build` -> `deploy`を実行します。
- 2番目のパイプラインはジョブ`build` -> `deploy`を実行します。

この場合、異なるパイプラインにまたがる`deploy`ジョブが`production`環境で同時に実行されるおそれがあります。同じインフラストラクチャで複数のデプロイスクリプトを実行すると、インスタンスに悪影響や混乱をもたらし、最悪の場合、破損状態に陥る可能性があります。

`deploy`ジョブを一度に1つずつ実行するには、並行処理の影響を受けやすいジョブに[`resource_group`キーワード](../yaml/_index.md#resource_group)を指定します:

```yaml
deploy:
  # ...
  resource_group: production
```

この設定により、デプロイの安全性を確保しつつ、パイプラインの効率性を最大化するために複数の`build`ジョブを同時に実行できます。

## 前提要件 {#prerequisites}

- [GitLab CI/CDパイプライン](../pipelines/_index.md)に関する知識
- [GitLab環境とデプロイ](../environments/_index.md)に関する知識
- CI/CDパイプラインを設定するには、プロジェクトのデベロッパーロール以上が必要です。

## 処理モード {#process-modes}

デプロイ設定に合わせてジョブの並行処理を制御するために、処理モードを選択できます。次のモードがサポートされています:

| 処理モード | 説明 | 使用するケース  |
|---------------|-------------|-------------|
| `unordered` | デフォルトの処理モードです。ジョブの実行準備が整うと、すぐにジョブを処理します。 | ジョブの実行順序が重要でない場合。最も使いやすいオプションです。 |
| `oldest_first` | リソースが空くと、パイプラインIDを昇順に並べた実行待ちジョブのリストから、最初のジョブを選択します。 | 最も古いパイプラインのジョブから順に実行したい場合。`unordered`モードよりも効率は下がりますが、継続的デプロイではより安全です。 |
| `newest_first` | リソースが空くと、パイプラインIDを降順に並べた実行待ちジョブのリストから、最初のジョブを選択します。 | 最新のパイプラインのジョブを実行し、[古いデプロイメントジョブの実行を防ぎたい](../environments/deployment_safety.md#prevent-outdated-deployment-jobs)場合。各ジョブがべき等（同じ操作を繰り返し実行しても結果が同じ）でなければなりません。 |
| `newest_ready_first` | リソースが空くと、このリソースでの実行待ちジョブのリストから、最初のジョブを選択します。ジョブは、パイプラインIDの降順でソートされています。 | `newest_first`が現在のパイプラインをデプロイする前に新しいパイプラインを優先するのを防ぎたい場合。`newest_first`よりも高速です。各ジョブがべき等（同じ操作を繰り返し実行しても結果が同じ）でなければなりません。 |

### 処理モードを変更する {#change-the-process-mode}

リソースグループの処理モードを変更するには、APIを使用して`process_mode`を指定し、[既存のリソースグループを編集](../../api/resource_groups.md#edit-an-existing-resource-group)するリクエストを送信する必要があります:

- `unordered`
- `oldest_first`
- `newest_first`
- `newest_ready_first`

### 処理モード間の違いの例 {#an-example-of-difference-between-the-process-modes}

次の`.gitlab-ci.yml`について考えてみましょう。これには、`build`ジョブと`deploy`ジョブがあります。各ジョブは独自のステージで実行され、`deploy`ジョブには、`production`に設定されたリソースグループがあります:

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

3つのコミットが短い間隔でプロジェクトにプッシュされると、3つのパイプラインがほぼ同時に実行されることになります:

- 最初のパイプラインはジョブ`build` -> `deploy`を実行します。このデプロイメントジョブを`deploy-1`とします。
- 2番目のパイプラインはジョブ`build` -> `deploy`を実行します。このデプロイメントジョブを`deploy-2`とします。
- 3番目のパイプラインはジョブ`build` -> `deploy`を実行します。このデプロイメントジョブを`deploy-3`とします。

リソースグループの処理モードに応じて、次のように動作します:

- 処理モードが`unordered`の場合:
  - `deploy-1`、`deploy-2`、`deploy-3`は同時には実行されません。
  - ジョブの実行順序は保証されません。たとえば、`deploy-1`が`deploy-3`より先に実行される場合も、後に実行される場合もあります。
- 処理モードが`oldest_first`の場合:
  - `deploy-1`、`deploy-2`、`deploy-3`は同時には実行されません。
  - `deploy-1`が最初に実行され、次に`deploy-2`、最後に`deploy-3`が実行されます。
- 処理モードが`newest_first`の場合:
  - `deploy-1`、`deploy-2`、`deploy-3`は同時には実行されません。
  - `deploy-3`が最初に実行され、次に`deploy-2`、最後に`deploy-1`が実行されます。

## クロスプロジェクト/親子パイプラインによるパイプラインレベルの並行処理制御 {#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines}

並行処理に影響されやすいダウンストリームパイプラインに対して`resource_group`を定義できます。[`trigger`キーワード](../yaml/_index.md#trigger)はダウンストリームパイプラインをトリガーでき、[`resource_group`キーワード](../yaml/_index.md#resource_group)はそれと併用できます。`resource_group`はデプロイメントパイプラインの並行処理を制御するのに効率的であり、他のジョブは引き続き同時に実行できます。

次の例では、1つのプロジェクトに2つのパイプライン設定があります。パイプラインの実行が開始されると、並行処理の影響を受けにくいジョブが最初に実行され、他のパイプラインの並行処理の影響を受けません。ただし、GitLabは、他のデプロイメントパイプラインが実行中でないことを確認してから、デプロイメント（子）パイプラインをトリガーします。他のデプロイメントパイプラインが実行中であれば、GitLabはこれらのパイプラインが完了するまで待機してから、別のパイプラインを実行します。

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
    strategy: mirror
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

[`trigger:strategy`](../yaml/_index.md#triggerstrategy)を定義して、ダウンストリームパイプラインが完了するまでロックが解除されないようにする必要があります。

## 関連トピック {#related-topics}

- [APIドキュメント](../../api/resource_groups.md)
- [ログのドキュメント](../../administration/logs/_index.md#ci_resource_groups_jsonlog)
- [安全なデプロイのためのGitLab](../environments/deployment_safety.md)

## トラブルシューティング {#troubleshooting}

### パイプライン設定でデッドロックを回避する {#avoid-dead-locks-in-pipeline-configurations}

[`oldest_first`処理モード](#process-modes)では、ジョブをパイプライン順に強制的に実行するため、他のCI機能とうまく連携しない場合があります。

たとえば、親パイプラインと同じリソースグループを必要とする[子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)を実行すると、デッドロックが発生する可能性があります。以下は不適切な設定の例です:

```yaml
# BAD
test:
  stage: test
  trigger:
    include: child-pipeline-requires-production-resource-group.yml
    strategy: mirror

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

親パイプラインでは、`test`ジョブを実行し、その後に子パイプラインを実行します。[`strategy: mirror`オプション](../yaml/_index.md#triggerstrategy)により、`test`ジョブは子パイプラインが完了するまで待機します。次のステージで、親パイプラインは`deploy`ジョブを実行しますが、このジョブは`production`リソースグループのリソースを必要とします。処理モードが`oldest_first`の場合、最も古いパイプラインからジョブが実行されます。つまり、次に実行されるのは`deploy`ジョブになります。

ところが、子パイプラインも`production`リソースグループのリソースを必要とします。子パイプラインは親パイプラインよりも新しいため、`deploy`ジョブが完了するまで待機します。しかし、このジョブが完了することはありません。

この場合、代わりに親パイプラインの設定で`resource_group`キーワードを指定する必要があります:

```yaml
# GOOD
test:
  stage: test
  trigger:
    include: child-pipeline.yml
    strategy: mirror
  resource_group: production # Specify the resource group in the parent pipeline

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

### ジョブが`Waiting for resource`で停止する {#jobs-get-stuck-in-waiting-for-resource}

ジョブが`Waiting for resource: <resource_group>`（リソース待機中）というメッセージでハングすることがあります。解決するには、まずリソースグループが正しく動作していることを確認します:

1. ジョブの詳細ページに移動します。
1. リソースがジョブに割り当てられている場合は、**現在リソースを使用しているジョブを表示**を選択し、ジョブステータスを確認します。

   - ステータスが`running`または`pending`の場合、この機能は正常に動作しています。ジョブが完了してリソースをリリースするまで待ちます。
   - ステータスが`created`であり、[処理モード](#process-modes)が**古い順**または**新しい順**のいずれかである場合、この機能は正しく動作しています。ジョブのパイプラインページにアクセスし、どのアップストリームステージまたはジョブが実行をブロックしているかを確認します。
   - 前述の条件に当てはまらない場合、この機能が正しく動作していない可能性があります。[GitLabにイシューを報告](#report-an-issue)してください。

1. **現在リソースを使用しているジョブを表示**が利用できない場合、リソースはジョブに割り当てられていません。代わりに、リソースの実行待ちジョブを確認します。

   1. [REST API](../../api/resource_groups.md#list-upcoming-jobs-for-a-specific-resource-group)でリソースの実行待ちジョブを取得します。
   1. リソースグループの[処理モード](#process-modes)が**古い順**であることを確認します。
   1. 実行待ちジョブのリストで最初のジョブを見つけ、[GraphQLで](#get-job-details-through-graphql)そのジョブの詳細を取得します。
   1. 最初のジョブのパイプラインが古いパイプラインの場合は、そのパイプラインまたはジョブ自体をキャンセルしてみてください。
   1. オプション。次の実行待ちジョブが、実行されなくなった古いパイプラインに属している場合は、このプロセスを繰り返します。
   1. 問題が解決しない場合は、[GitLabにイシューを報告](#report-an-issue)してください。

#### 複雑またはビジーなパイプラインでの競合状態 {#race-conditions-in-complex-or-busy-pipelines}

前述の方法でイシューを解決できない場合は、既知の競合状態の問題が発生している可能性があります。競合状態は、複雑またはビジーなパイプラインで発生します。たとえば、次のような場合に競合状態が発生する可能性があります:

- パイプラインに複数の子パイプラインが存在する
- 単一のプロジェクトで複数のパイプラインが同時に実行されている

このイシューが発生していると思われる場合は、[GitLabにイシューを報告](#report-an-issue)し、新しいイシューへのリンクを付けて[イシュー436988](https://gitlab.com/gitlab-org/gitlab/-/issues/436988)にコメントを残してください。問題を確認するために、GitLabからパイプライン全体の設定などの追加の詳細を求められる場合があります。

一時的な回避策として、次のことができます:

- 新しいパイプラインを開始する。
- スタックしたジョブと同じリソースグループを持つ完了したジョブを再実行する。

  たとえば、同じリソースグループに属する`setup_job`と`deploy_job`がある場合、`deploy_job`が`waiting for resource`で停滞している間に、`setup_job`が完了する可能性があります。この場合、`setup_job`を再起動してプロセス全体を再開し、`deploy_job`を完了させることができます。

#### GraphQLを介してジョブの詳細を取得する {#get-job-details-through-graphql}

GraphQL APIからジョブ情報を取得できます。[クロスプロジェクト/親子パイプラインによるパイプラインレベルの並行処理制御](#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines)を使用する場合は、UIからはトリガージョブにアクセスできないため、GraphQL APIを使用する必要があります。

GraphQL APIからジョブ情報を取得するには、次のようにします:

1. パイプラインの詳細ページに移動します。
1. **ジョブ**タブを選択し、スタックしたジョブのIDを見つけます。
1. [インタラクティブGraphQLエクスプローラー](../../api/graphql/_index.md#interactive-graphql-explorer)に移動します。
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

    `job.detailedStatus.action.path`フィールドには、リソースを使用しているジョブのIDが含まれています。

1. 次のクエリを実行し、前述の基準に従って`job.status`フィールドを確認します。`pipeline.path`フィールドからパイプラインページにアクセスすることもできます。

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

### イシューを報告する {#report-an-issue}

次の情報を含む[新しいイシューをオープン](https://gitlab.com/gitlab-org/gitlab/-/issues/new)します:

- 影響を受けたジョブのID
- ジョブステータス
- 問題の発生頻度
- 問題を再現する手順

  [サポートに連絡](https://about.gitlab.com/support/#contact-support)して、さらに支援を受けたり、開発チームとやり取りしたりすることもできます。
