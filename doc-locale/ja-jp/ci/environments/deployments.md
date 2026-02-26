---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: デプロイ
description: デプロイ、ロールバック、安全性、承認。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コードの特定のバージョンを環境にデプロイすると、デプロイが作成されます。通常、環境ごとにアクティブなデプロイは1つのみです。

GitLab:

- 各環境へのデプロイの完全な履歴を提供します。
- デプロイを追跡し、サーバーに何がデプロイされているかを常に把握できます。

[Kubernetes](../../user/infrastructure/clusters/_index.md)のようなデプロイサービスがプロジェクトに関連付けられている場合、それを使用してデプロイを支援できます。

デプロイが作成されたら、ユーザーにロールアウトできます。

## 手動デプロイを設定する {#configure-manual-deployments}

手動でデプロイを開始する必要があるジョブを作成できます。例: 

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

`when: manual`アクションの仕様は次のとおりです:

- GitLab UIで、このジョブに**実行**（{{< icon name="play" >}}）ボタンが表示され、**`<environment>`に手動でデプロイ可能**というテキストが表示されます。
- `deploy_prod`ジョブを手動でトリガーする必要があります。

**実行**（{{< icon name="play" >}}）は、パイプライン、環境、デプロイ、ジョブの各ビューに表示されます。

## デプロイごとに新たに含まれたマージリクエストを追跡する {#track-newly-included-merge-requests-per-deployment}

GitLabは、デプロイごとに新たに含まれたマージリクエストを追跡できます。デプロイが成功すると、システムは最新のデプロイと前回のデプロイの間でコミットの差分を計算します。追跡情報は、[デプロイAPI](../../api/deployments.md#list-all-merge-requests-associated-with-a-deployment)でフェッチするか、[マージリクエストページ](../../user/project/merge_requests/_index.md)のマージ後パイプラインで確認できます。

追跡を有効にするには、次のいずれかの条件を満たすように環境を設定します:

- [環境名](../yaml/_index.md#environmentname)で`/`を含むフォルダーを使用しない（長期またはトップレベルの環境）。
- [環境の階層](_index.md#deployment-tier-of-environments)が`production`または`staging`のいずれかである。

  `.gitlab-ci.yml`で[`environment`キーワード](../yaml/_index.md#environment)を使用する設定例を次に示します:

  ```yaml
  # Trackable
  environment: production
  environment: production/aws
  environment: development

  # Non Trackable
  environment: review/$CI_COMMIT_REF_SLUG
  environment: testing/aws
  ```

設定変更は新しいデプロイにのみ適用されます。既存のデプロイレコードでは、マージリクエストのリンクまたはリンク解除は行われません。

## ローカルでデプロイをチェックアウトする {#check-out-deployments-locally}

Gitリポジトリには、デプロイごとに参照が保存されます。そのため、現在の環境の状態は`git fetch`するだけで把握できます。

Gitの設定で、`[remote "<your-remote>"]`ブロックに次のフェッチ行を追加します:

```plaintext
fetch = +refs/environments/*:refs/remotes/origin/environments/*
```

## 古いデプロイをアーカイブする {#archive-old-deployments}

プロジェクトで新しいデプロイが行われると、GitLabは[そのデプロイ用の特別なGit ref](#check-out-deployments-locally)を作成します。これらのGit refsはリモートのGitLabリポジトリから取り込まれるため、プロジェクト内のデプロイ数が増えるにつれて、`git-fetch`や`git-pull`などのGit操作が遅くなることがあります。

Git操作の効率を維持するため、GitLabは最新のデプロイrefs（最大50,000）のみを保持し、それ以外の古いデプロイrefsは削除します。アーカイブされたデプロイは、監査目的でUIまたはAPIを使用して引き続き参照できます。またアーカイブ後でも、コミットSHAを指定することで、デプロイされたコミットをリポジトリから引き続きフェッチできます（例: `git checkout <deployment-sha>`）。

> [!note]
> GitLabは、[`keep-around` refs](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)としてすべてのコミットを保持するため、デプロイrefsから参照されなくなっても、デプロイされたコミットがガベージコレクションされることはありません。

## デプロイのロールバック {#deployment-rollback}

特定のコミットにデプロイをロールバックすると、新しいデプロイが作成されます。このデプロイには固有のジョブIDが割り当てられます。これは、ロールバック先のコミットを参照します。

ロールバックを成功させるには、デプロイプロセスがジョブの`script`に定義されている必要があります。

実行されるのは[デプロイジョブ](../jobs/_index.md#deployment-jobs)のみです。以前のジョブが生成したアーティファクトを、デプロイ時に再生成する必要がある場合、パイプラインページから必要なジョブを手動で実行する必要があります。たとえば、Terraformを使用しており、`plan`と`apply`のコマンドが複数のジョブに分かれている場合、デプロイまたはロールバックのためにジョブを手動で実行する必要があります。

### デプロイを再試行またはロールバックする {#retry-or-roll-back-a-deployment}

デプロイに問題がある場合は、再試行またはロールバックできます。

デプロイを再試行またはロールバックするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **操作** > **環境**を選択します。
1. 環境を選択します。
1. デプロイ名の右側で、次のいずれかを行います:
   - デプロイを再試行するには、**環境に再デプロイ**を選択します。
   - デプロイをロールバックするには、以前に成功したデプロイの横にある**環境のロールバック**を選択します。

> [!note]
> プロジェクトで[古いデプロイジョブを防止](deployment_safety.md#prevent-outdated-deployment-jobs)している場合、ロールバックボタンが非表示または無効になっている可能性があります。その場合は、[ロールバックデプロイのジョブの再試行](deployment_safety.md#job-retries-for-rollback-deployments)を参照してください。

## 関連トピック {#related-topics}

- [環境](_index.md)
- [デプロイのダウンストリームパイプライン](../pipelines/downstream_pipelines.md#downstream-pipelines-for-deployments)
- [Deploy to multiple environments with GitLab CI/CD（ブログ投稿）](https://about.gitlab.com/blog/ci-deployment-and-environments/)
- [レビューアプリ](../review_apps/_index.md)
- [外部デプロイツールのデプロイを追跡する](external_deployment_tools.md)

## トラブルシューティング {#troubleshooting}

デプロイを操作する際に、次の問題が発生する可能性があります。

### デプロイrefsが見つからない {#deployment-refs-are-not-found}

GitLabは、Gitリポジトリのパフォーマンスを維持するため、[古いデプロイrefsを削除](#archive-old-deployments)します。

GitLab Self-ManagedでアーカイブされたGit refsを復元する必要がある場合は、Railsコンソールで次のコマンドを実行するように管理者に依頼してください:

```ruby
Project.find_by_full_path(<your-project-full-path>).deployments.where(archived: true).each(&:create_ref)
```

パフォーマンス上の懸念から、GitLabは将来このサポートを廃止する可能性があります。この機能の動作について議論したい場合は、[GitLabイシュートラッカー](https://gitlab.com/gitlab-org/gitlab/-/issues/new)でイシューをオープンしてください。
