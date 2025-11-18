---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Enterprise Edition（EE）からCommunity Edition（CE）への変更
---

GitLab Enterprise Edition（EE）インスタンスをCE（Community Edition）にダウングレードできますが、その前に次のことを行う必要があります:

1. EE専用の認証メカニズムを無効にします。
1. データベースからEE専用のインテグレーションを削除します。
1. スコープ環境を使用する設定を調整します。

## EE専用の認証メカニズムをオフにします {#turn-off-ee-only-authentication-mechanisms}

KerberosはEEインスタンスでのみ利用可能です。これを行うには、次の手順に従います:

- ロールバックする前に、これらのメカニズムをオフにします。
- 別の認証方法をユーザーに提供します。

## データベースからEE専用のインテグレーションを削除します {#remove-ee-only-integrations-from-the-database}

これらのインテグレーションは、EEのコードベースでのみ利用可能です:

- [GitHub](../../user/project/integrations/github.md)
- [Git Guardian](../../user/project/integrations/git_guardian.md)
- [Google Artifact Management](../../user/project/integrations/google_artifact_management.md)
- [Google Cloud IAM](../../integration/google_cloud_iam.md)

CEにダウングレードすると、次のようなエラーが発生する可能性があります:

```plaintext
Completed 500 Internal Server Error in 497ms (ActiveRecord: 32.2ms)

ActionView::Template::Error (The single-table inheritance mechanism failed to locate the subclass: 'Integrations::Github'. This
error is raised because the column 'type_new' is reserved for storing the class in case of inheritance. Please rename this
column if you didn't intend it to be used for storing the inheritance class or overwrite Integration.inheritance_column to
use another column for that information.)
```

エラーメッセージの`subclass`は、以下のいずれかになります:

- `Integrations::Github`
- `Integrations::GitGuardian`
- `Integrations::GoogleCloudPlatform::ArtifactRegistry`
- `Integrations::GoogleCloudPlatform::WorkloadIdentityFederation`

すべてのインテグレーションは、すべてのプロジェクトに対して自動的に作成されます。このエラーが発生しないようにするには、データベースからEE専用のインテグレーションレコードをすべて削除する必要があります。

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

## スコープ環境を使用する設定を調整します {#adjust-configuration-that-uses-environment-scopes}

[環境スコープ](../../user/group/clusters/_index.md#environment-scopes)を使用している場合は、設定、特に設定変数が同じキーを共有しているが、スコープが異なる場合は、調整が必要になることがあります。環境スコープはCEでは完全に無視されます。

キーは共有しているがスコープが異なる設定変数を使用すると、特定の環境で予期しない変数が誤って取得される可能性があります。この場合は、正しい変数があることを確認してください。

データは移行時に完全に保持されるため、EEに戻して動作を復元できます。

## CEにロールバック {#revert-to-ce}

必要な手順を実行したら、GitLabインスタンスをCEにロールバックできます。

すべての依存関係が最新の状態になっていることを確認するには、正しい[更新ガイド](../_index.md)に従ってください。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

[ディストリビューションのインストール手順](../../install/package/_index.md#supported-platforms)に従って、Community Editionパッケージをインストールします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. GitLabインストールの現在のGitリモートを、CE Gitリモートに置き換えます。
1. 最新の変更をフェッチし、最新の安定したブランチをチェックアウトします。次に例を示します: 

   ```shell
   git remote set-url origin git@gitlab.com:gitlab-org/gitlab-foss.git
   git fetch --all
   git checkout 17-8-stable
   ```

{{< /tab >}}

{{< /tabs >}}
