---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AWS Route53によるロケーション対応GitリモートURL
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

[GitLab Geoは、Web UIとAPIトラフィックを含むロケーション対応DNSをサポートしています。](../secondary_proxy/_index.md#configure-location-aware-dns)この設定は、このドキュメントで説明されているロケーション対応GitリモートURLよりも推奨されます。

{{< /alert >}}

GitLabユーザーに、最も近いGeoサイトを自動的に使用する単一のリモートURLを提供できます。これは、ユーザーが移動時に近い方のGeoサイトを利用するために、Git設定を更新する必要がないことを意味します。

これは、Gitプッシュリクエストが**セカンダリ**サイトから**プライマリ**サイトに自動的にリダイレクト（HTTP）またはプロキシ（SSH）できるためです。

これらの手順では[AWS Route53](https://aws.amazon.com/route53/)を使用していますが、[Cloudflare](https://www.cloudflare.com/)などの他のサービスも同様に使用できます。

## 前提要件 {#prerequisites}

この例では、以下がすでに設定されていることを前提としています:

- `primary.example.com`がGeoの**プライマリ**サイトとして設定されている。
- `secondary.example.com`がGeoの**セカンダリ**サイトとして設定されている。

`git.example.com`サブドメインを作成し、リクエストを自動的に転送します:

- ヨーロッパからのリクエストは**セカンダリ**サイトに転送します。
- 他のすべての場所からのリクエストは**プライマリ**サイトに転送します。

いずれの場合も、以下が必要です:

- 独自のアドレスでアクセス可能な、動作中のGitLab **プライマリ**サイト。
- 動作中のGitLab **セカンダリ**サイト。
- ドメインを管理するRoute53ホストゾーン。

Geoとセカンダリサイトをまだ設定していない場合は、[Geo設定手順](../setup/_index.md)を参照してください。

## トラフィックポリシーの作成 {#create-a-traffic-policy}

Route53ホストゾーンでは、トラフィックポリシーを使用して、さまざまなルーティング設定を設定できます。

1. [Route53ダッシュボード](https://console.aws.amazon.com/route53/home)に移動し、**Traffic policies**（トラフィックポリシー）を選択します。

   ![Route53ダッシュボードのトラフィックポリシーセクション](img/single_git_traffic_policies_v12_3.png)

1. **Create traffic policy**（トラフィックポリシーを作成）を選択します。

   ![トラフィックポリシーに名前を付ける](img/single_git_name_policy_v12_3.png)

1. **Policy Name**（ポリシー名）フィールドに`Single Git Host`を入力し、**次へ**を選択します。

   ![トラフィックポリシーのDNS種類を選択](img/single_git_policy_diagram_v12_3.png)

1. **DNS type**（DNS種類）を`A: IP Address in IPv4 format`のままにします。
1. **Connect to**（接続先）を選択し、**Geolocation rule**（地理ロケーションルール）を選択します。

   ![地理ロケーションルールを追加](img/single_git_add_geolocation_rule_v12_3.png)

1. 最初の**ロケーション**では、`Default`のままにします。
1. **Connect to**（接続先）を選択し、**New endpoint**（新しいエンドポイント）を選択します。
1. **種類** `value`を選択し、`<your **primary** IP address>`を入力します。
1. 2番目の**ロケーション**で、`Europe`を選択します。
1. **Connect to**（接続先）を選択し、**New endpoint**（新しいエンドポイント）を選択します。
1. **種類** `value`を選択し、`<your **secondary** IP address>`を入力します。

   ![地理ロケーションルールへのロケーションとエンドポイントの設定](img/single_git_add_traffic_policy_endpoints_v12_3.png)

1. **Create traffic policy**（トラフィックポリシーを作成）を選択します。

   ![トラフィックポリシーでのポリシーレコードの設定](img/single_git_create_policy_records_with_traffic_policy_v12_3.png)

1. **Policy record DNS name**（ポリシーレコードDNS名）に`git`を入力します。
1. **Create policy records**（ポリシーレコードを作成）を選択します。

   ![ポリシーレコードを持つトラフィックポリシーが正常に作成されました](img/single_git_created_policy_record_v12_3.png)

たとえば、`git.example.com`などのシングルホストを正常に設定しました。これは、地理ロケーションに基づいてGeoサイトにトラフィックを分配します。

## 特別なGit URLを使用するようにGitクローンURLを設定する {#configure-git-clone-urls-to-use-the-special-git-url}

ユーザーが初めてリポジトリをクローンするとき、通常、プロジェクトページからGitリモートURLをコピーします。デフォルトでは、これらのSSHおよびHTTP URLは、現在のホストの外部URLに基づいています。例: 

- `git@secondary.example.com:group1/project1.git`
- `https://secondary.example.com/group1/project1.git`

![リポジトリのSSHおよびHTTPS URL](img/single_git_clone_panel_v12_3.png)

以下をカスタマイズできます:

- ロケーション対応の`git.example.com`を使用するためのSSHリモートURL。これを行うには、Webノードの`gitlab.rb`で`gitlab_rails['gitlab_ssh_host']`を設定して、SSHリモートURLホストを変更します。
- [HTTP（S）のカスタムGitクローンURL](../../settings/visibility_and_access_controls.md#customize-git-clone-url-for-https)に示すHTTPリモートURL。

## Gitリクエスト処理の動作例 {#example-git-request-handling-behavior}

以前に文書化された設定手順に従うと、Gitリクエストの処理はロケーション対応になります。リクエストの場合:

- ヨーロッパ以外では、すべてのリクエストは**プライマリ**サイトに転送されます。
- ヨーロッパ内では、以下を経由します:
  - HTTP:
    - `git clone http://git.example.com/foo/bar.git`は**セカンダリ**サイトに転送されます。
    - `git push`は最初に**セカンダリ**に転送され、自動的に`primary.example.com`にリダイレクトされます。
  - SSH:
    - `git clone git@git.example.com:foo/bar.git`は**セカンダリ**に転送されます。
    - `git push`は最初に**セカンダリ**に転送され、自動的に`primary.example.com`にリクエストをプロキシします。
