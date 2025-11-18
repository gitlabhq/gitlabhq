---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: デプロイの安全性
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[デプロイジョブ](../jobs/_index.md#deployment-jobs)は、特定の種類のCI/CDジョブです。これらはパイプライン内の他のジョブよりも機密性が高い場合があり、特別な注意を払って取り扱う必要があるかもしれません。GitLabには、デプロイのセキュリティと安定性を維持するのに役立つ機能がいくつかあります。

次のことが可能です。

- プロジェクトに適切なロールを設定します。GitLabがサポートするさまざまなユーザーロールと、それぞれの権限については、[プロジェクトメンバーの権限](../../user/permissions.md#project-members-permissions)を参照してください。
- [重要な環境への書き込みアクセスを制限する](#restrict-write-access-to-a-critical-environment)
- [デプロイフリーズ期間中のデプロイを防止する](#prevent-deployments-during-deploy-freeze-windows)
- [本番環境のシークレットを保護する](#protect-production-secrets)
- [デプロイ用にプロジェクトを分離する](#separate-project-for-deployments)

継続的デプロイワークフローを使用しており、同じ環境への同時実行デプロイが発生しないようにする場合は、次のオプションを有効にする必要があります。

- [一度に1つのデプロイジョブのみが実行されるようにする](#ensure-only-one-deployment-job-runs-at-a-time)
- [古いデプロイジョブを防止する](#prevent-outdated-deployment-jobs)

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[CDパイプライン/ワークフローを保護する方法](https://www.youtube.com/watch?v=Mq3C1KveDc0)を参照してください。

## 重要な環境への書き込みアクセスを制限する {#restrict-write-access-to-a-critical-environment}

デフォルトでは、環境は、少なくともデベロッパーロールを持つすべてのチームメンバーが変更できます。重要な環境（たとえば、`production`環境）への書き込みアクセスを制限する場合は、[保護された環境](protected_environments.md)を設定できます。

## 一度に1つのデプロイジョブのみが実行されるようにする {#ensure-only-one-deployment-job-runs-at-a-time}

GitLab CI/CDのパイプラインジョブは並行して実行されるため、2つの異なるパイプライン内の2つのデプロイジョブが、同じ環境に同時にデプロイしようとする可能性があります。デプロイは順番に行われる必要があるため、これは望ましくない動作です。

`.gitlab-ci.yml`の[`resource_group`キーワード](../yaml/_index.md#resource_group)を使用して、一度に1つのデプロイジョブのみが実行されるようにすることができます。

次に例を示します。

```yaml
deploy:
 script: deploy-to-prod
 resource_group: prod
```

リソースグループを使用する**前**の問題のあるパイプラインフローの例:

1. パイプラインAの`deploy`ジョブが実行を開始します。
1. パイプラインBの`deploy`ジョブが実行を開始します。*これは同時デプロイであり、予期しない結果を引き起こす可能性があります。*
1. パイプラインAの`deploy`ジョブが完了しました。
1. パイプラインBの`deploy`ジョブが完了しました。

リソースグループを使用する**後**の、改善されたパイプラインフロー： 

1. パイプラインAの`deploy`ジョブが実行を開始します。
1. パイプラインBの`deploy`ジョブが開始を試みますが、最初の`deploy`ジョブが完了するのを待ちます。
1. パイプラインAの`deploy`ジョブが完了しました。
1. パイプラインBの`deploy`ジョブが実行を開始します。

詳細については、[リソースグループのドキュメント](../resource_groups/_index.md)を参照してください。

## 古いデプロイジョブを防止する {#prevent-outdated-deployment-jobs}

{{< history >}}

- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/363328)GitLab 15.5で、古くなったジョブの実行を防ぐために行われました。

{{< /history >}}

パイプラインジョブの有効な実行順序は実行ごとに異なる可能性があり、望ましくない動作を引き起こす可能性があります。たとえば、新しいパイプライン内の[デプロイジョブ](../jobs/_index.md#deployment-jobs)が、古いパイプライン内のデプロイジョブよりも先に完了する可能性があります。これにより、古いデプロイが後で完了し、「新しい」デプロイを上書きする競合状態が発生します。

新しいデプロイジョブが開始されたときに、古いデプロイジョブが実行されないようにするには、[古くなったデプロイジョブを防止](../pipelines/settings.md#prevent-outdated-deployment-jobs)機能を有効にします。

古いデプロイジョブが開始されると、失敗して、次のラベルが付けられます。

- パイプラインビューの`failed outdated deployment job`。
- 完了したジョブを表示するときの`The deployment job is older than the latest deployment, and therefore failed.`。

古いデプロイジョブが手動の場合、**実行**（{{< icon name="play" >}}）ボタンはメッセージ`This deployment job does not run automatically and must be started manually, but it's older than the latest deployment, and therefore can't run.`で無効になります。

ジョブの経過時間は、コミット時間ではなく、ジョブの開始時間によって決まるため、状況によっては新しいコミットが阻止される可能性があります。

### ロールバックデプロイのジョブの再試行 {#job-retries-for-rollback-deployments}

{{< history >}}

- ジョブの再試行によるロールバック[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378359) GitLab 15.6。
- ロールバックデプロイチェックボックスのジョブの再試行[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/410427) GitLab 16.3。

{{< /history >}}

安定した古いデプロイにすばやくロールバックする必要があるかもしれません。デフォルトでは、[デプロイのロールバック](deployments.md#deployment-rollback)のパイプラインジョブの再試行が有効になっています。

パイプラインの再試行を無効にするには、**ロールバックデプロイのジョブの再試行を許可する**チェックボックスをオフにします。機密性の高いプロジェクトでは、パイプラインの再試行を無効にする必要があります。

ロールバックが必要な場合は、以前のコミットで新しいパイプラインを実行する必要があります。

### 例 {#example}

古くなったデプロイジョブを防止を有効にする**以前**の、問題のあるパイプラインフローの例： 

1. パイプラインAは、デフォルトブランチ上に作成されます。
1. 以後、パイプラインBがデフォルトブランチ上に作成されます（新しいコミットSHAを使用）。
1. パイプラインBの`deploy`ジョブが最初に完了し、新しいコードをデプロイします。
1. パイプラインAの`deploy`ジョブが後で完了し、古いコードをデプロイし、新しい（最新の）デプロイを**上書き**します。

古くなったデプロイジョブを防止を有効にする**後**の、改善されたパイプラインフロー： 

1. パイプラインAは、デフォルトブランチ上に作成されます。
1. 以後、パイプラインBがデフォルトブランチ上に作成されます（新しいSHAを使用）。
1. パイプラインBの`deploy`ジョブが最初に完了し、新しいコードをデプロイします。
1. パイプラインAの`deploy`ジョブが失敗するため、新しいパイプラインからのデプロイは上書きされません。

## デプロイフリーズ期間中のデプロイを防止する {#prevent-deployments-during-deploy-freeze-windows}

特定の期間、たとえば、ほとんどの従業員が不在の計画された休暇期間中にデプロイを防止する場合は、[デプロイフリーズ](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze)を設定できます。デプロイフリーズ期間中は、デプロイを実行できません。これは、デプロイが予期せず発生しないようにするのに役立ちます。

次に設定されたデプロイフリーズが、[環境デプロイリスト](_index.md#view-environments-and-deployments)ページの上部に表示されます。

## 本番環境のシークレットを保護する {#protect-production-secrets}

正常にデプロイするには、本番環境のシークレットが必要です。たとえば、クラウドにデプロイする場合、クラウドプロバイダーは、これらのシークレットをサービスに接続するために必要とします。プロジェクト設定で、これらのシークレットのCI/CD変数を定義して保護できます。[保護された変数](../variables/_index.md#protect-a-cicd-variable)は、[保護ブランチ](../../user/project/repository/branches/protected.md)または[保護されたタグ](../../user/project/protected_tags.md)で実行されているパイプラインにのみ渡されます。他のパイプラインは、保護された変数を取得しません。[変数のスコープを特定の環境に設定する](../variables/where_variables_can_be_used.md#variables-with-an-environment-scope)こともできます。シークレットが意図せずに公開されないようにするために、保護された環境で保護された変数を使用することをお勧めします。[Runner側](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)で本番環境のシークレットを定義することもできます。これにより、メンテナーロールを持つ他のユーザーがシークレットを読み取ることを防ぎ、Runnerが保護されたブランチでのみ実行されるようにします。

詳細については、[パイプラインセキュリティ](../pipelines/_index.md#pipeline-security-on-protected-branches)を参照してください。

## デプロイ用にプロジェクトを分離する {#separate-project-for-deployments}

プロジェクトのメンテナーロールを持つすべてのユーザーが、本番環境のシークレットにアクセスできます。本番環境にデプロイできるユーザーの数を制限する必要がある場合は、別のプロジェクトを作成し、元のプロジェクトからCD権限を分離し、プロジェクトのメンテナーロールを持つ元のユーザーが本番環境のシークレットとCD設定にアクセスできないようにする、新しい権限モデルを構成できます。[複数プロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)を使用して、CDプロジェクトを開発プロジェクトに接続できます。

## 変更から`.gitlab-ci.yml`を保護する {#protect-gitlab-ciyml-from-change}

`.gitlab-ci.yml`には、アプリケーションを本番環境サーバーにデプロイするためのルールが含まれている場合があります。通常、このデプロイは、マージリクエストをプッシュした後に自動的に実行されます。デベロッパーが`.gitlab-ci.yml`を変更するのを防ぐために、別のリポジトリで定義できます。この設定は、まったく異なる権限のセットを持つ別のプロジェクト内のファイルを参照できます（[デプロイ用にプロジェクトを分離する](#separate-project-for-deployments)と同様）。このシナリオでは、`.gitlab-ci.yml`は公開されていますが、他のプロジェクトで適切な権限を持つユーザーのみが編集できます。

詳細については、[カスタムCI/CD設定パス](../pipelines/settings.md#specify-a-custom-cicd-configuration-file)を参照してください。

## デプロイする前に承認を要求する {#require-an-approval-before-deploying}

デプロイを本番環境環境にプロモートする前に、専任のテストグループでクロス検証することは、安全性を確保するための効果的な方法です。詳細については、[デプロイの承認](deployment_approvals.md)を参照してください。
