---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Diagrams.netのインテグレーションをGitLabに設定します。
gitlab_dedicated: yes
title: Diagrams.net
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- オフライン環境のサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116281)されたGitLab 16.1。

{{< /history >}}

[diagrams.net](https://www.drawio.com/)インテグレーションを使用して、Wikiにスケーラブルベクターグラフィックス図を作成して埋め込みます。図エディタは、プレーンテキストエディタとリッチテキストエディタの両方で使用できます。

GitLab.comは、すべてのSaaSユーザーに対してこのインテグレーションを有効にします。追加の設定は必要ありません。

GitLabセルフマネージドおよびGitLab Dedicatedの場合、無料の[diagrams.net](https://www.drawio.com/) Webサイトとインテグレーションするか、オフライン環境で独自のdiagrams.netサイトをホストします。

インテグレーションをセットアップするには、次の手順に従います:

1. 無料のdiagrams.net Webサイトと統合するか、[diagrams.netサーバーを設定します](#configure-your-diagramsnet-server)。
1. [インテグレーションを有効にする](#enable-diagramsnet-integration)。

インテグレーションが完了すると、指定したURLでdiagrams.netエディタが開きます。

## diagrams.netサーバーを構成する {#configure-your-diagramsnet-server}

独自のdiagrams.netサーバーをセットアップして、図を生成できます。

これは、GitLabセルフマネージドのオフラインインスタンスにインストールするユーザーにとって必須の手順です。

たとえば、Dockerでdiagrams.netコンテナを実行するには、次のコマンドを実行します:

```shell
docker run -it --rm --name="draw" -p 8080:8080 -p 8443:8443 jgraph/drawio
```

インテグレーションを有効にする際にdiagrams.net URLとして使用するために、コンテナを実行しているサーバーのホスト名をメモしてください。

詳細については、[Dockerで独自のdiagrams.netサーバーを実行する](https://www.drawio.com/blog/diagrams-docker-app)を参照してください。

## Diagrams.netインテグレーションを有効にする {#enable-diagramsnet-integration}

1. [管理者](../../user/permissions.md)ユーザーとしてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **Diagrams.net**を展開する。
1. **Enable Diagrams.net**（Diagrams.netを有効にする）チェックボックスを選択します。
1. Diagrams.net URLを入力します。接続先:
   - 無料のパブリックインスタンス: `https://embed.diagrams.net`と入力します。
   - ローカルでホストされているdiagrams.netインスタンス: [以前に構成した](#configure-your-diagramsnet-server)URLを入力します。
1. **変更を保存**を選択します。
