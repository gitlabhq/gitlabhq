---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナイメージの依存プロキシストレージを削減する
description: クリーンアップポリシー、APIキャッシュのクリア、TTL設定を使用して、GitLab依存プロキシ内のblobストレージを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

blobの自動削除処理はありません。手動で削除しない限り、無期限に保存されます。このページでは、キャッシュから未使用のアイテムをクリアするためのいくつかのオプションについて説明します。

## 依存プロキシストレージの使用状況を確認する {#check-dependency-proxy-storage-use}

[**使用量クォータ**](../../storage_usage_quotas.md)ページには、コンテナイメージの依存プロキシのストレージ使用量が表示されます。

## APIを使用してキャッシュをクリアする {#use-the-api-to-clear-the-cache}

不要になったイメージblobで使用されているディスク領域を再利用するには、[dependency proxy API](../../../api/dependency_proxy.md)を使用して、全体のキャッシュをクリアします。キャッシュをクリアすると、次回のパイプライン実行時に、Docker Hubからイメージまたはタグをプルする必要があります。

## クリーンアップポリシー {#cleanup-policies}

{{< history >}}

- GitLab 15.0で、必要なロールがデベロッパーからメンテナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/350682)されました。
- GitLab 17.0で、必要なロールがメンテナーからオーナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)されました。

{{< /history >}}

### GitLab内からクリーンアップポリシーを有効にする {#enable-cleanup-policies-from-within-gitlab}

ユーザーインターフェースからコンテナイメージの依存プロキシに自動Time-To-Live（TTL）ポリシーを有効にできます。これを行うには、グループの**設定** > **パッケージとレジストリ** > **依存プロキシ**に移動し、90日後にキャッシュからアイテムを自動的にクリアする設定を有効にします。

### GraphQLでクリーンアップポリシーを有効にする {#enable-cleanup-policies-with-graphql}

クリーンアップポリシーは、使用されなくなったキャッシュされたイメージをクリアするために使用できるスケジュールされたジョブであり、追加のストレージ領域を解放します。このポリシーは、Time-To-Live（TTL）ロジックを使用します:

- 日数が設定されます。
- それほど日数がプルされていない、キャッシュされたすべての依存プロキシファイルが削除されます。

クリーンアップポリシーを有効化および構成するには、[GraphQL API](../../../api/graphql/reference/_index.md#mutationupdatedependencyproxyimagettlgrouppolicy)を使用します:

```graphql
mutation {
  updateDependencyProxyImageTtlGroupPolicy(input:
    {
      groupPath: "<your-full-group-path>",
      enabled: true,
      ttl: 90
    }
  ) {
    dependencyProxyImageTtlPolicy {
      enabled
      ttl
    }
    errors
  }
}
```

GraphQLクエリを作成する方法については、[GraphQLの使用を開始する](../../../api/graphql/getting_started.md)ガイドを参照してください。

ポリシーが最初に有効になったとき、デフォルトのTTL設定は90日です。有効にすると、古くなった依存プロキシファイルは、毎日削除のためにキューに入れられます。処理時間のため、削除がすぐに行われない場合があります。キャッシュされたファイルが期限切れとしてマークされた後にイメージがプルされた場合、期限切れのファイルは無視され、外部レジストリから新しいファイルがダウンロードされてキャッシュされます。
