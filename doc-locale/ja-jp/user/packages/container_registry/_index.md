---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabコンテナレジストリ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

統合されたコンテナレジストリを使用して、各GitLabプロジェクトのコンテナイメージを保存できます。

GitLabインスタンスのコンテナレジストリを有効にするには、[管理者ドキュメント](../../../administration/packages/container_registry.md)を参照してください。

{{< alert type="note" >}}

Docker Hubからコンテナイメージをプルする場合は、[GitLab依存プロキシ](../dependency_proxy/_index.md#use-the-dependency-proxy-for-docker-images)を使用すると、レート制限を回避してパイプラインを高速化できます。

{{< /alert >}}

## コンテナレジストリを表示する

プロジェクトまたはグループのコンテナレジストリを表示できます。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトまたはグループを検索します。
1. **デプロイ>コンテナレジストリ**の順に選択します。

コンテナイメージは、検索、並べ替え、フィルタリング、[削除](delete_container_registry_images.md#use-the-gitlab-ui)できます。ブラウザからURLをコピーすると、フィルタリングしたビューを共有できます。

### コンテナレジストリ内の特定のコンテナイメージのタグを表示する

コンテナレジストリの**タグの詳細**ページを使用して、特定のコンテナイメージに関連付けられているタグのリストを表示できます。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトまたはグループを検索します。
1. **デプロイ>コンテナレジストリ**の順に選択します。
1. コンテナイメージを選択します。

公開日時、使用ストレージ量、マニフェスト、設定のダイジェストなどの各タグに関する詳細を表示できます。

このページで、タグを検索、並べ替え（タグ名順）、[削除](delete_container_registry_images.md#use-the-gitlab-ui)できます。ブラウザからURLをコピーすると、フィルタリングしたビューを共有できます。

### ストレージ使用量

コンテナレジストリのストレージ使用量を表示して、プロジェクトおよびグループ全体にわたってコンテナリポジトリのサイズを追跡して管理できます。

詳細については、「[コンテナレジストリの使用状況を表示する](../../../user/packages/container_registry/reduce_container_registry_storage.md#view-container-registry-usage)」を参照してください。

## コンテナレジストリからコンテナイメージを使用する

コンテナレジストリでホストされているコンテナイメージをダウンロードして実行するには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトまたはグループを検索します。
1. **デプロイ>コンテナレジストリ**の順に選択します。
1. 作業対象のコンテナイメージを検索して、**イメージパスをコピー**（{{< icon name="copy-to-clipboard" >}}）を選択します。

1. コピーしたリンクを使用して`docker run`を実行します。

   ```shell
   docker run [options] registry.example.com/group/project/image [arguments]
   ```

{{< alert type="note" >}}

プライベートリポジトリからコンテナイメージをダウンロードするには、[コンテナレジストリで認証](authenticate_with_container_registry.md)を行う必要があります。

{{< /alert >}}

コンテナイメージの実行の詳細については、[Dockerのドキュメント](https://docs.docker.com/get-started/)を参照してください。

## コンテナイメージの命名規則

コンテナイメージは、次の命名規則に準拠する必要があります。

```plaintext
<registry server>/<namespace>/<project>[/<optional path>]
```

たとえば、プロジェクトが`gitlab.example.com/mynamespace/myproject`の場合、コンテナイメージの名前は`gitlab.example.com/mynamespace/myproject`にする必要があります。

コンテナイメージ名の最後に、最大2レベルの深さまで追加の名前を付加できます。

たとえば、以下はすべて`myproject`という名前のプロジェクト内のコンテナイメージに有効な名前です。

```plaintext
registry.example.com/mynamespace/myproject:some-tag
```

```plaintext
registry.example.com/mynamespace/myproject/image:latest
```

```plaintext
registry.example.com/mynamespace/myproject/my/image:rc1
```

## コンテナレジストリのリポジトリを移動または名前変更する

コンテナリポジトリのパスは、関連するプロジェクトのリポジトリパスと常に一致するため、コンテナレジストリのみを名前変更または移動することはできません。代わりに、プロジェクト全体を[名前変更](../../project/working_with_projects.md#rename-a-repository)または[移動](../../project/settings/migrate_projects.md)できます。

入力済みのコンテナリポジトリがあるプロジェクトの名前変更は、GitLab.comでのみサポートされています。

GitLab Self-Managedインスタンスでは、グループまたはプロジェクトを移動または名前を変更する前に、すべてのコンテナイメージを削除できます。別の方法として、[イシュー18383](https://gitlab.com/gitlab-org/gitlab/-/issues/18383#possible-workaround)では、この制限を回避するためのコミュニティからの提案が説明されています。[エピック9459](https://gitlab.com/groups/gitlab-org/-/epics/9459)では、コンテナリポジトリがあるプロジェクトとグループをGitLab Self-Managedに移動するためのサポートを追加することが提案されています。

## プロジェクトのコンテナレジストリを無効にする

コンテナレジストリはデフォルトで有効になっています。

ただし、次の手順でプロジェクトのコンテナレジストリを削除できます。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **設定>一般**を選択します。
1. **可視性、プロジェクトの機能、権限**セクションを展開し、**コンテナレジストリ**を無効にします。
1. **変更の保存**を選択します。

**デプロイ>コンテナレジストリ**エントリがプロジェクトのサイドバーから削除されます。

## コンテナレジストリの表示レベルを変更する

デフォルトでは、コンテナレジストリはプロジェクトへのアクセス権を持つすべてのユーザーに表示されます。ただし、プロジェクトのコンテナレジストリの表示レベルは変更できます。

この設定がユーザーに付与する権限の詳細については、[コンテナレジストリの表示レベル権限](#container-registry-visibility-permissions)を参照してください。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **設定>一般**を選択します。
1. **可視性、プロジェクトの機能、権限**セクションを展開します。
1. **コンテナレジストリ**で、次のようにドロップダウンリストからオプションを選択します。

   - **アクセスできる人すべて**（デフォルト）: コンテナレジストリは、プロジェクトへのアクセス権を持つすべてのユーザーに表示されます。プロジェクトがパブリックの場合、コンテナレジストリもパブリックになります。プロジェクトが内部またはプライベートの場合、コンテナレジストリも内部またはプライベートになります。

   - **プロジェクトメンバーのみ**: コンテナレジストリは、少なくともレポーターロールを持つプロジェクトメンバーにのみ表示されます。この表示レベルは、コンテナレジストリの表示レベルが**アクセスできる人すべて**に設定されているプライベートプロジェクトの動作に似ています。

1. **変更の保存**を選択します。

## コンテナレジストリの表示レベル権限

コンテナレジストリの表示機能とコンテナイメージのプル機能は、コンテナレジストリの表示レベル権限によって制御されます。表示レベルは、[UIの表示レベル設定](#change-visibility-of-the-container-registry)または[API](../../../api/container_registry.md#change-the-visibility-of-the-container-registry)で変更できます。コンテナレジストリの更新、コンテナイメージのプッシュまたは削除などの[その他の権限](../../permissions.md)は、この設定の影響を受けません。ただし、コンテナレジストリを無効にすると、すべてのコンテナレジストリ操作が無効になります。

|                                                                                                                   |                                               | 匿名<br/>（インターネット上のすべてのユーザー） | ゲスト | レポーター、デベロッパー、メンテナー、オーナー |
|-------------------------------------------------------------------------------------------------------------------|-----------------------------------------------|--------------------------------------|-------|----------------------------------------|
| コンテナレジストリの表示レベルがあるパブリックプロジェクト <br/> **アクセスできる人すべて**（UI）または`enabled`（API）に設定する   | コンテナレジストリを表示する <br/> イメージをプルする | 可                                  | 可   | 可                                    |
| コンテナレジストリの表示レベルがあるパブリックプロジェクト <br/> **プロジェクトメンバーのみ**（UI）または`private`（API）に設定する   | コンテナレジストリを表示する <br/> イメージをプルする | 不可                                   | 不可    | 可                                    |
| コンテナレジストリの表示レベルがある内部プロジェクト <br/> **アクセスできる人すべて**（UI）または`enabled`（API）に設定する | コンテナレジストリを表示する <br/> イメージをプルする | 不可                                   | 可   | 可                                    |
| コンテナレジストリの表示レベルがある内部プロジェクト <br/> **プロジェクトメンバーのみ**（UI）または`private`（API）に設定する | コンテナレジストリを表示する <br/> イメージをプルする | 不可                                   | 不可    | 可                                    |
| コンテナレジストリの表示レベルがあるプライベートプロジェクト <br/> **アクセスできる人すべて**（UI）または`enabled`（API）に設定する  | コンテナレジストリを表示する <br/> イメージをプルする | 不可                                   | 不可    | 可                                    |
| コンテナレジストリの表示レベルがあるプライベートプロジェクト <br/> **プロジェクトメンバーのみ**（UI）または`private`（API）に設定する  | コンテナレジストリを表示する <br/> イメージをプルする | 不可                                   | 不可    | 可                                    |
| コンテナレジストリが`disabled`のすべてのプロジェクト                                                                    | コンテナレジストリに対するすべての操作          | 不可                                   | 不可    | 不可                                     |

## サポートされているイメージタイプ

{{< history >}}

- GitLab 16.6で、OCI仕様が[導入](https://gitlab.com/groups/gitlab-org/-/epics/10345)されました。

{{< /history >}}

コンテナレジストリは、[Docker V2](https://distribution.github.io/distribution/spec/manifest-v2-2/)と[Open Container Initiative（OCI）](https://github.com/opencontainers/image-spec/blob/main/spec.md)のイメージ形式をサポートしています。さらに、コンテナレジストリは[OCI配布仕様に準拠](https://conformance.opencontainers.org/#gitlab-container-registry)しています。

OCIサポートとは、[Helm 3以降のチャートパッケージ](https://helm.sh/docs/topics/registries/)など、OCIベースのイメージ形式をレジストリでホストできることを意味します。GitLab [API](../../../api/container_registry.md)とUIでのイメージ形式に差異はありません。[イシュー38047](https://gitlab.com/gitlab-org/gitlab/-/issues/38047)では、Helmから始め、この区別について説明しています。

## コンテナイメージの署名

{{< history >}}

- GitLab 17.1で、コンテナイメージの署名の表示が[導入](https://gitlab.com/groups/gitlab-org/-/epics/7856)されました。

{{< /history >}}

GitLabコンテナレジストリでは、[OCI 1.1マニフェストの`subject`フィールド](https://github.com/opencontainers/image-spec/blob/v1.1.0/manifest.md)を使用して、コンテナイメージを[Cosign署名](../../../ci/yaml/signing_examples.md)に関連付けることができます。これにより、該当する署名のタグを検索する必要なく、署名情報は関連付けられたコンテナイメージとともに表示されるようになります。

[コンテナイメージのタグを表示する](#view-the-tags-of-a-specific-container-image-in-the-container-registry)際、関連付けられた署名がある各タグの横にアイコンが表示されます。署名の詳細を表示するには、アイコンをクリックします。

前提要件:

- コンテナイメージに署名するには、Cosign v2.0以降が必要です。
- GitLab Self-Managedの場合、署名を表示するには、[メタデータデータベースで設定されたGitLabコンテナレジストリ](../../../administration/packages/container_registry_metadata_database.md)が必要です。

### OCIリファラーデータを使用してコンテナイメージに署名する

Cosignを使用して署名にリファラーデータを追加するには、次の操作を行う必要があります。

- `COSIGN_EXPERIMENTAL`環境変数を`1`に設定します。
- `--registry-referrers-mode oci-1-1`を署名コマンドに追加します。

次に例を示します。

```shell
COSIGN_EXPERIMENTAL=1 cosign sign --registry-referrers-mode oci-1-1 <container image>
```

{{< alert type="note" >}}

GitLabコンテナレジストリはOCI 1.1マニフェストの`subject`フィールドをサポートしていますが、[OCI 1.1 Referrers API](https://github.com/opencontainers/distribution-spec/blob/v1.1.0/spec.md#listing-referrers)を完全に実装しているわけではありません。

{{< /alert >}}
