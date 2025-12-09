---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部リポジトリのGitLab CI/CD
description: GitHub、Bitbucket、外部ソース、ミラーリング、クロスプラットフォーム。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab CI/CDは、[GitHub](github_integration.md) 、[Bitbucket Cloud](bitbucket_integration.md)、またはその他のGitサーバーで使用できます。いくつかの[既知の問題](#known-issues)があります。

プロジェクト全体をGitLabに移動する代わりに、外部リポジトリを接続してGitLab CI/CDの利点を得ることができます。

外部リポジトリを接続すると、[リポジトリのミラーリング](../../user/project/repository/mirror/_index.md)が設定され、イシュー、マージリクエスト、Wiki、およびスニペットが無効になっている軽量プロジェクトが作成されます。これらの機能は[後で再度有効にできます](../../user/project/settings/_index.md#configure-project-features-and-permissions)。

## 外部リポジトリに接続する {#connect-to-an-external-repository}

外部リポジトリに接続するには、次の手順に従います:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。[新しいナビゲーションをオンにした](../../user/interface_redesign.md#turn-new-navigation-on-or-off)場合、このボタンは右上隅にあります。
1. **外部リポジトリのCI/CDを実行**を選択します。
1. **GitHub**または**リポジトリのURL**を選択します。
1. フィールドに入力します。

**外部リポジトリのCI/CDを実行**オプションが利用できない場合:

- GitLabインスタンスにインポート元が設定されていない可能性があります。管理者に[インポート元の設定](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)を確認するように依頼してください。
- [プロジェクトのミラーリング](../../user/project/repository/mirror/_index.md)が無効になっている可能性があります。無効になっている場合、管理者のみが**外部リポジトリのCI/CDを実行**オプションを使用できます。管理者に[プロジェクトのミラーリングの設定](../../administration/settings/visibility_and_access_controls.md#enable-project-mirroring)を確認するように依頼してください。

## 外部プルリクエストのパイプライン {#pipelines-for-external-pull-requests}

[GitHub上の外部リポジトリ](github_integration.md)でGitLab CI/CDプルリクエストのコンテキストでパイプラインを実行できます。

GitHubのリモートブランチに変更をプッシュすると、GitLab CI/CDは、そのブランチのパイプラインを実行できます。ただし、そのブランチのプルリクエストを開くか更新するときは、次のことをお勧めします:

- 追加のジョブを実行します。
- 特定のジョブを実行しません。

例: 

```yaml
always-run:
  script: echo 'this should always run'

on-pull-requests:
  script: echo 'this should run on pull requests'
  rules:
    - if: $CI_PIPELINE_SOURCE == "external_pull_request_event"

except-pull-requests:
  script: echo 'This should not run for pull requests, but runs in other cases.'
  rules:
    - if: $CI_PIPELINE_SOURCE == "external_pull_request_event"
      when: never
    - when: on_success
```

### 外部プルリクエストのパイプライン実行 {#pipeline-execution-for-external-pull-requests}

リポジトリがGitHubからインポートされると、GitLabは`push`イベントと`pull_request`イベントのWebhookをサブスクライブします。`pull_request`イベントを受信するとすぐに、プルリクエストデータが保存され、参照として保持されます。プルリクエストが作成されたばかりの場合、GitLabはすぐに外部プルリクエストのパイプラインを作成します。

プルリクエストによって参照されるブランチに変更がプッシュされ、プルリクエストがまだ開いている場合、外部プルリクエストのパイプラインが作成されます。

GitLab CI/CDは、この場合2つのパイプラインを作成します。ブランチのプッシュ用と外部プルリクエスト用です。

プルリクエストが閉じられた後、新しい変更が同じブランチにプッシュされても、外部プルリクエストのパイプラインは作成されません。

### 追加の定義済み変数 {#additional-predefined-variables}

外部プルリクエストのパイプラインを使用することにより、GitLabは追加の[定義済み変数](../variables/predefined_variables.md)をパイプラインジョブに公開します。

変数名には、`CI_EXTERNAL_PULL_REQUEST_`というプレフィックスが付きます。

### 既知の問題 {#known-issues}

この機能は、以下をサポートしていません:

- GitHub Enterpriseに必要な[手動接続方式](github_integration.md#connect-manually)。インテグレーションが手動で接続されている場合、外部プルリクエストは[パイプラインをトリガーしません](https://gitlab.com/gitlab-org/gitlab/-/issues/323336#note_884820753)。
- フォークしたリポジトリからのプルリクエスト。[フォークしたリポジトリからのプルリクエストは無視されます](https://gitlab.com/gitlab-org/gitlab/-/issues/5667)。

GitLabは2つのパイプラインを作成するため、開いているプルリクエストを参照するリモートブランチに変更がプッシュされると、両方ともGitHubインテグレーションを介してプルリクエストのステータスにコントリビュートします。外部プルリクエストでのみパイプラインを実行し、ブランチでは実行しない場合は、ジョブの仕様に`except: [branches]`を追加できます。[詳細はこちら](https://gitlab.com/gitlab-org/gitlab/-/issues/24089#workaround)。

## トラブルシューティング {#troubleshooting}

- [プルミラーリングがパイプラインをトリガーしません](../../user/project/repository/mirror/troubleshooting.md#pull-mirroring-is-not-triggering-pipelines)。
- ミラーリング時のハード障害を[修正](../../user/project/repository/mirror/pull.md#fix-hard-failures-when-mirroring)する。
