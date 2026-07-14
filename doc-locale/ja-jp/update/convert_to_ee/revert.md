---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: エンタープライズ版からコミュニティ版に戻す
---

EEインスタンスをCEに戻すことができますが、まず以下のことを行う必要があります:

1. EE専用の認証メカニズムを無効にする。
1. EE専用のインテグレーションをデータベースから削除する。
1. 環境スコープを使用する設定を調整する。

## EE専用の認証メカニズムを無効にする {#turn-off-ee-only-authentication-mechanisms}

KerberosはEEインスタンスでのみ利用可能です。これを行うには、次の手順に従います。

- 元に戻す前にこれらのメカニズムをオフにしてください。
- ユーザーに別の認証方法を提供してください。

## データベースからEE専用のインテグレーションを削除する {#remove-ee-only-integrations-from-the-database}

これらのインテグレーションはEEコードベースでのみ利用可能です:

- [GitHub](../../user/project/integrations/github.md)
- [Git Guardian](../../user/project/integrations/git_guardian.md)
- [Google Artifact Management](../../user/project/integrations/google_artifact_management.md)
- [Google Cloud IAM](../../integration/google_cloud_iam.md)

CEへダウングレードすると、次のようなエラーが発生する可能性があります:

```plaintext
Completed 500 Internal Server Error in 497ms (ActiveRecord: 32.2ms)

ActionView::Template::Error (The single-table inheritance mechanism failed to locate the subclass: 'Integrations::Github'. This
error is raised because the column 'type_new' is reserved for storing the class in case of inheritance. Please rename this
column if you didn't intend it to be used for storing the inheritance class or overwrite Integration.inheritance_column to
use another column for that information.)
```

エラーメッセージ内の`subclass`は、以下のいずれかです:

- `Integrations::Github`
- `Integrations::GitGuardian`
- `Integrations::GoogleCloudPlatform::ArtifactRegistry`
- `Integrations::GoogleCloudPlatform::WorkloadIdentityFederation`

すべてのインテグレーションは、すべてのプロジェクトで自動的に作成されます。このエラーを回避するには、EE専用のインテグレーションレコードをすべてデータベースから削除する必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::Github']).delete_all"
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::GitGuardian']).delete_all"
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::ArtifactRegistry']).delete_all"
sudo gitlab-rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::WorkloadIdentityFederation']).delete_all"
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rails runner "Integration.where(type_new: ['Integrations::Github']).delete_all" production
bundle exec rails runner "Integration.where(type_new: ['Integrations::GitGuardian']).delete_all" production
bundle exec rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::ArtifactRegistry']).delete_all" production
bundle exec rails runner "Integration.where(type_new: ['Integrations::GoogleCloudPlatform::WorkloadIdentityFederation']).delete_all" production
```

{{< /tab >}}

{{< /tabs >}}

## 環境スコープを使用する設定を調整する {#adjust-configuration-that-uses-environment-scopes}

[environment scopes](../../user/group/clusters/_index.md#environment-scopes)を使用している場合、特に設定変数が同じキーを共有しているが、異なるスコープを持つ場合は、設定を調整する必要があるかもしれません。環境スコープは、CEでは完全に無視されます。

同じキーを共有しているが異なるスコープを持つ設定変数を使用している場合、特定の環境で予期しない変数を誤って取得してしまう可能性があります。この場合は、適切な変数があることを確認してください。

移行中にデータは完全に保持されるため、EEに戻して動作を復元することができます。

## CEに戻す {#revert-to-ce}

必要な手順を実行した後、GitLabインスタンスをCEに戻すことができます。

すべての依存関係が最新であることを確認するために、正しい[update guides](../_index.md)に従ってください。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

[installation instructions for your distribution](../../install/package/_index.md#supported-platforms)に従って、コミュニティ版パッケージをインストールします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. GitLabインストールの現在のGitリモートを、CEのGitリモートに置き換えます。
1. 最新の変更をフェッチし、最新の安定したブランチをチェックアウトする。例: 

   ```shell
   git remote set-url origin git@gitlab.com:gitlab-org/gitlab-foss.git
   git fetch --all
   git checkout 17-8-stable
   ```

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

このセクションには、発生する可能性のある問題に対する解決策が含まれています。

### エラー: `Cookbook gitlab-ee not found` {#error-cookbook-gitlab-ee-not-found}

GitLab EEインスタンスにGitLab CE用のLinuxパッケージをインストールする際に、`Cookbook gitlab-ee not found`エラーが発生する可能性があります。この問題を解決するには、次の手順に従います:

1. `gitlab-ee`Cookbookを削除します:

   ```shell
   sudo rm -rf /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab-ee
   ```

1. GitLab CEを再インストールします。
1. すべてのサービスが稼働していることを確認してください:

   ```shell
   sudo gitlab-ctl status
   ```

   そうでない場合は、GitLabを再起動してください:

   ```shell
   sudo gitlab-ctl restart
   ```
