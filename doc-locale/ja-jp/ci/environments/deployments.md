---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: デプロイ
description: デプロイ、ロールバック、安全性、および承認。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コードのバージョンを環境にデプロイすると、デプロイが作成されます。通常、環境ごとにアクティブなデプロイは1つのみです。

GitLab:

- 各環境へのデプロイの完全な履歴を提供します。
- デプロイを追跡するため、サーバーに何がデプロイされているかを常に把握できます。

プロジェクトに関連付けられている[Kubernetes](../../user/infrastructure/clusters/_index.md)のようなデプロイサービスがある場合は、それを使用してデプロイを支援できます。

デプロイが作成されたら、ユーザーにロールバックできます。

## 手動デプロイの構成 {#configure-manual-deployments}

誰かが手動でデプロイを開始する必要があるジョブを作成できます。例: 

```yaml
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
```

`when: manual`アクション:

- GitLab UIで、そのジョブに**実行**（{{< icon name="play" >}}）ボタンが表示され、**`<environment>`に手動でデプロイできます**というテキストが表示されます。
- `deploy_prod`ジョブを手動でトリガーする必要があることを意味します。

**実行**（{{< icon name="play" >}}）は、パイプライン、環境、デプロイ、ジョブの各ビューで利用できます。

## デプロイごとに新しく含まれるマージリクエストを追跡する {#track-newly-included-merge-requests-per-deployment}

GitLabは、デプロイごとに新しく含まれるマージリクエストを追跡できます。デプロイが成功すると、システムは最新のデプロイと前のデプロイの間のコミットの差分を計算します。[デプロイAPI](../../api/deployments.md#list-all-merge-requests-associated-with-a-deployment)を使用して追跡情報をフェッチしたり、[マージリクエストページ](../../user/project/merge_requests/_index.md)のマージ後のパイプラインで表示したりできます。

追跡を有効にするには、次のいずれかの方法で環境を構成します:

- [環境名](../yaml/_index.md#environmentname)は、`/`（長期またはトップレベルの環境）を含むフォルダーを使用しません。
- [環境層](_index.md#deployment-tier-of-environments)は、`production`または`staging`のいずれかです。

  `.gitlab-ci.yml`で[`environment`キーワード](../yaml/_index.md#environment)を使用する構成例を次に示します:

  ```yaml
  # Trackable
  environment: production
  environment: production/aws
  environment: development

  # Non Trackable
  environment: review/$CI_COMMIT_REF_SLUG
  environment: testing/aws
  ```

構成の変更は、新しいデプロイにのみ適用されます。既存のデプロイレコードには、リンクされた、またはリンク解除されたマージリクエストはありません。

## デプロイをローカルにチェックアウトする {#check-out-deployments-locally}

各デプロイに対してGitリポジトリ内の参照が保存されるため、現在の環境の状態を知ることは`git fetch`だけですぐにわかります。

Git構成で、`[remote "<your-remote>"]`ブロックにフェッチ行を追加します:

```plaintext
fetch = +refs/environments/*:refs/remotes/origin/environments/*
```

## 古いデプロイをアーカイブする {#archive-old-deployments}

プロジェクトで新しいデプロイが発生すると、GitLabは[deploymentへの特別なGit-参照](#check-out-deployments-locally)を作成します。これらのGit-参照はリモートのGitLabリポジトリから入力されたため、プロジェクト内のデプロイの数が増加すると、`git-fetch`や`git-pull`などの一部のGit操作が遅くなる可能性があります。

Git操作の効率性を維持するために、GitLabは最新のデプロイ参照（最大50,000）のみを保持し、残りの古いデプロイ参照を削除します。アーカイブされたデプロイは、監査目的で、UIまたはAPIを使用して引き続き使用できます。また、アーカイブ後でも、コミットSHA（たとえば、`git checkout <deployment-sha>`）を指定して、リポジトリからデプロイされたコミットをフェッチできます。

> [!note] GitLabは、[`keep-around`参照](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)としてすべてのコミットを保持するため、デプロイ参照によって参照されていなくても、デプロイされたコミットがガベージコレクションされることはありません。

## デプロイメントのロールバック {#deployment-rollback}

特定のコミットでデプロイをロールバックすると、新しいデプロイが作成されます。このデプロイには、独自のジョブIDがあります。これは、ロールバック先のコミットを指します。

ロールバックを成功させるには、デプロイプロセスがジョブの`script`で定義されている必要があります。

実行されるのは[デプロイメントジョブ](../jobs/_index.md#deployment-jobs)のみです。前のジョブがデプロイ時に再生成する必要があるアーティファクトを生成する場合、パイプラインページから必要なジョブを手動で実行する必要があります。たとえば、Terraformを使用し、`plan`コマンドと`apply`コマンドが複数のジョブに分割されている場合は、デプロイまたはロールバックするためにジョブを手動で実行する必要があります。

### デプロイを再試行またはロールバックする {#retry-or-roll-back-a-deployment}

デプロイに問題がある場合は、再試行するか、ロールバックできます。

デプロイを再試行またはロールバックするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **環境**を選択します。
1. 環境を選択します。
1. デプロイ名の右側:
   - デプロイを再試行するには、**環境に再デプロイ**を選択します。
   - デプロイにロールバックするには、以前に成功したデプロイの横にある**環境のロールバック**を選択します。

> [!note]プロジェクトで[古くなったデプロイメントジョブを防止](deployment_safety.md#prevent-outdated-deployment-jobs)している場合、ロールバックボタンが非表示または無効になっている可能性があります。この場合は、[ロールバックデプロイのジョブ再試行](deployment_safety.md#job-retries-for-rollback-deployments)を参照してください。

## 関連トピック {#related-topics}

- [環境](_index.md)
- [デプロイメントのダウンストリームパイプライン](../pipelines/downstream_pipelines.md#downstream-pipelines-for-deployments)
- [GitLab CI/CDを使用して複数の環境にデプロイする（ブログ投稿）](https://about.gitlab.com/blog/2021/02/05/ci-deployment-and-environments/)
- [レビューアプリ](../review_apps/_index.md)
- [外部デプロイツールのデプロイを追跡する](external_deployment_tools.md)

## トラブルシューティング {#troubleshooting}

デプロイを操作するときに、次の問題が発生する可能性があります。

### デプロイ参照が見つかりません {#deployment-refs-are-not-found}

GitLabは、Gitリポジトリのパフォーマンスを維持するために[古いデプロイ参照を削除します](#archive-old-deployments)。

GitLab Self-ManagedでアーカイブされたGit-参照を復元する必要がある場合は、管理者にRailsコンソールで次のコマンドを実行するように依頼してください:

```ruby
Project.find_by_full_path(<your-project-full-path>).deployments.where(archived: true).each(&:create_ref)
```

GitLabは、パフォーマンス上の懸念から、将来このサポートを削除する可能性があります。この機能の動作について話し合うには、[GitLabイシュートラッカー](https://gitlab.com/gitlab-org/gitlab/-/issues/new)でイシューをオープンしてください。
