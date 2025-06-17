---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: デプロイトークン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デプロイトークンを使用すると、個々のユーザーアカウントに権限を関連付けなくても、GitLabリソースへの安全なアクセスを提供できます。Git操作、コンテナレジストリ、パッケージレジストリで使用すると、デプロイの自動化に必要なものだけにアクセスできます。

デプロイトークンを使用すると、以下を実現できます。

- 自動化システムから個人の認証情報を削除することで、デプロイの安全性を向上
- トークンごとに特定の権限を付与して、きめ細かいアクセス制御を実現
- 組み込みの認証変数を使用して、CI/CDパイプラインを簡素化
- チームメンバーが変更された場合でも中断されない信頼性の高いデプロイメントプロセスを実現
- 専用のトークンIDでデプロイを追跡することで、監査証跡を改善
- 外部ビルドシステムおよびデプロイメントツールとシームレスに統合

デプロイトークンは、次の値のペアです。

- **username**: HTTP認証フレームワークの`username`。デフォルトのユーザー名の形式は`gitlab+deploy-token-{n}`です。デプロイトークンの作成時に、カスタムユーザー名を指定できます。
- **token**: HTTP認証フレームワークの`password`。

デプロイトークンは、[SSH認証](../../ssh.md)をサポートしていません。

次のエンドポイントへの[HTTP認証](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)にデプロイトークンを使用できます。

- GitLabパッケージレジストリパブリックAPI。
- [Gitコマンド](https://git-scm.com/docs/gitcredentials#_description)。

プロジェクトまたはグループレベルでデプロイトークンを作成できます。

- **プロジェクトデプロイトークン**: 権限はプロジェクトにのみ適用されます。
- **グループデプロイトークン**: 権限はグループ内のすべてのプロジェクトに適用されます。

デフォルトでは、デプロイトークンは期限切れになりません。オプションで、作成時に有効期限を設定できます。有効期限は、その日付のUTC午前0時に切れます。

{{< alert type="warning" >}}

[外部認証](../../../administration/settings/external_authorization.md)が有効になっている場合、Git操作およびパッケージレジストリ操作に新規または既存のデプロイトークンを使用することはできません。

{{< /alert >}}

## スコープ

デプロイトークンのスコープによって、実行できるアクションが決まります。

| スコープ                    | 説明                                                                                                  |
|--------------------------|--------------------------------------------------------------------------------------------------------------|
| `read_repository`        | `git clone`を使用したリポジトリへの読み取り専用アクセス。                                                        |
| `read_registry`          | プロジェクトの[コンテナレジストリ](../../packages/container_registry/_index.md)内のイメージへの読み取り専用アクセス。 |
| `write_registry`         | プロジェクトの[コンテナレジストリ](../../packages/container_registry/_index.md)への書き込みアクセス（プッシュ）。イメージをプッシュするには、読み取りアクセスと書き込みアクセスの両方が必要です。 |
| `read_package_registry`  | プロジェクトのパッケージレジストリへの読み取り専用アクセス。                                                          |
| `write_package_registry` | プロジェクトのパッケージレジストリへの書き込みアクセス。                                                              |

## GitLabデプロイトークン

{{< history >}}

- GitLab 15.1で、`ci_variable_for_group_gitlab_deploy_token`という名前の[フラグとともに](../../../administration/feature_flags.md)グループレベルでの`gitlab-deploy-token`のサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/214014)されました。デフォルトで有効になりました。
- GitLab 15.4で、[機能フラグ`ci_variable_for_group_gitlab_deploy_token`](https://gitlab.com/gitlab-org/gitlab/-/issues/363621)が削除されました。

{{< /history >}}

GitLabデプロイトークンは、特別なタイプのデプロイトークンです。`gitlab-deploy-token`という名前のデプロイトークンを作成すると、そのデプロイトークンは自動的に次の変数としてプロジェクトCI/CDジョブに公開されます。

- `CI_DEPLOY_USER`: ユーザー名
- `CI_DEPLOY_PASSWORD`: トークン

たとえば、GitLabトークンを使用してGitLabコンテナレジストリにサインインするには、次のコマンドを実行します。

```shell
echo "$CI_DEPLOY_PASSWORD" | docker login $CI_REGISTRY -u $CI_DEPLOY_USER --password-stdin
```

{{< alert type="note" >}}

GitLab 15.0以前では、`gitlab-deploy-token`デプロイトークンに対する特別な処理はグループデプロイトークンでは機能しません。グループデプロイトークンをCI/CDジョブで使用できるようにするには、**設定> CI/CD >変数**で`CI_DEPLOY_USER`および`CI_DEPLOY_PASSWORD`のCI/CD変数をグループデプロイトークンの名前とトークンに設定します。

{{< /alert >}}

グループで`gitlab-deploy-token`が定義されている場合、`CI_DEPLOY_USER`および`CI_DEPLOY_PASSWORD`のCI/CD変数はグループ直下の子プロジェクトでのみ使用できます。

### GitLabデプロイトークンのセキュリティ

GitLabデプロイトークンは有効期間が長いため、攻撃者にとって魅力的です。

デプロイトークンの漏えいを防ぐために、[Runner](../../../ci/runners/_index.md)も安全に設定する必要があります。

- マシンが再利用される場合は、Docker `privileged`モードの使用を避ける必要があります。
- ジョブが同じマシンで実行される場合は、[`shell` executor](https://docs.gitlab.com/runner/executors/shell.html)の使用を避ける必要があります。

脆弱なGitLab Runner設定は、他のジョブからのトークンの盗難リスクを増大させます。

### GitLabパブリックAPI

デプロイトークンは、GitLabパブリックAPIでは使用できません。ただし、パッケージレジストリのエンドポイントなど、一部のエンドポイントではデプロイトークンを使用できます。URLに文字列`packages/<format>`が含まれていると、エンドポイントがパッケージレジストリに属していると判断できます。例: `https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/0.0.1/file.txt`。詳細については、「[レジストリを使用して認証する](../../packages/package_registry/_index.md#authenticate-with-the-registry)」を参照してください。

## デプロイトークンを作成する

ユーザーアカウントとは独立して実行できるデプロイタスクを自動化するためのデプロイトークンを作成します。

前提要件:

- グループデプロイトークンを作成するには、グループのオーナーロールが必要です。
- プロジェクトデプロイトークンを作成するには、プロジェクトのメンテナーロール以上が必要です。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトまたはグループを検索します。
1. **設定>リポジトリ**を選択します。
1. **デプロイトークン**を展開します。
1. **トークンの追加**を選択します。
1. フィールドに入力し、目的の[スコープ](#scope)を選択します。
1. **デプロイトークンを作成**を選択します。

デプロイトークンの値を記録します。ページを離れるか更新すると、**再度アクセスすることはできません**。

## デプロイトークンを取り消す

不要になったトークンを取り消します。

前提要件:

- グループデプロイトークンを取り消すには、グループのオーナーロールが必要です。
- プロジェクトデプロイトークンを取り消すには、プロジェクトのメンテナーロール以上が必要です。

デプロイトークンを取り消すには:

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトまたはグループを検索します。
1. **設定>リポジトリ**を選択します。
1. **デプロイトークン**を展開します。
1. **アクティブなデプロイトークン**セクションで、取り消すトークンの横にある**取り消し**を選択します。

## リポジトリのクローンを作成する

デプロイトークンを使用してリポジトリのクローンを作成できます。

前提要件:

- `read_repository`スコープを持つデプロイトークン。

デプロイトークンを使用してリポジトリのクローンを作成する例:

```shell
git clone https://<username>:<deploy_token>@gitlab.example.com/tanuki/awesome_project.git
```

## コンテナレジストリからイメージをプルする

デプロイトークンを使用して、コンテナレジストリからイメージをプルできます。

前提要件:

- `read_registry`スコープを持つデプロイトークン。

デプロイトークンを使用してコンテナレジストリからイメージをプルする例:

```shell
echo "$DEPLOY_TOKEN" | docker login -u <username> --password-stdin registry.example.com
docker pull $CONTAINER_TEST_IMAGE
```

## コンテナレジストリにイメージをプッシュする

デプロイトークンを使用して、コンテナレジストリにイメージをプッシュできます。

前提要件:

- `read_registry`および`write_registry`のスコープを持つデプロイトークン。

デプロイトークンを使用して、コンテナレジストリにイメージをプッシュする例:

```shell
echo "$DEPLOY_TOKEN" | docker login -u <username> --password-stdin registry.example.com
docker push $CONTAINER_TEST_IMAGE
```

## パッケージレジストリからパッケージをプルする

デプロイトークンを使用して、パッケージレジストリからパッケージをプルできます。

前提要件:

- `read_package_registry`スコープを持つデプロイトークン。

[選択するパッケージの種類](../../packages/package_registry/supported_functionality.md#authentication-tokens)については、デプロイトークンの認証手順に従ってください。

GitLabレジストリからNuGetパッケージをインストールする例:

```shell
nuget source Add -Name GitLab -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName <username> -Password <deploy_token>
nuget install mypkg.nupkg
```

## パッケージレジストリにパッケージをプッシュする

デプロイトークンを使用して、GitLabパッケージレジストリにパッケージをプッシュできます。

前提要件:

- `write_package_registry`スコープを持つデプロイトークン。

[選択するパッケージの種類](../../packages/package_registry/supported_functionality.md#authentication-tokens)については、デプロイトークンの認証手順に従ってください。

パッケージレジストリにNuGetパッケージを公開する例:

```shell
nuget source Add -Name GitLab -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName <username> -Password <deploy_token>
nuget push mypkg.nupkg -Source GitLab
```

## 依存プロキシからイメージをプルする

デプロイトークンを使用して、依存プロキシからイメージをプルできます。

前提要件:

- `read_registry`および`write_registry`のスコープを持つデプロイトークン。

依存プロキシの[認証手順](../../packages/dependency_proxy/_index.md)に従ってください。
