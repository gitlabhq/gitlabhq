---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: ローカルマシンにGitをインストールする方法。
title: Gitをインストールする
---

GitLabプロジェクトにコントリビュートするには、ローカルマシンにGitクライアントをダウンロード、インストール、設定する必要があります。GitLabは、SSHプロトコルを使用してGitと安全に通信します。SSHを使用すると、ユーザー名とパスワードを毎回入力しなくても、GitLabのリモートサーバーに対して認証できます。

Gitをインストールして設定したら、[SSHキーペアを生成してGitLabアカウントに追加](../../../user/ssh.md#generate-an-ssh-key-pair)します。

## Gitをインストールして更新する {#install-and-update-git}

{{< tabs >}}

{{< tab title="macOS" >}}

macOSには特定のバージョンのGitが含まれていますが、最新バージョンのGitをインストールする必要があります。Gitをインストールする一般的な方法は、[Homebrew](https://brew.sh/index.html)を使用することです。

Homebrewを使用してmacOSに最新バージョンのGitをインストールするには:

1. Homebrewをインストールしたことがない場合は、[Homebrewのインストール手順](https://brew.sh/index.html)に従ってください。
1. ターミナルで、`brew install git`を実行してGitをインストールします。
1. ローカルマシンでGitが動作することを確認します。

   ```shell
   git --version
   ```

Gitを最新の状態に保つには、次のコマンドを定期的に実行します。

```shell
brew update && brew upgrade git
```

{{< /tab >}}

{{< tab title="Ubuntu Linux" >}}

Ubuntuには特定のバージョンのGitが含まれていますが、最新バージョンのGitをインストールする必要があります。最新バージョンは、Personal Package Archive（PPA）を使用して入手できます。

PPAを使用してUbuntu Linuxに最新バージョンのGitをインストールするには:

1. ターミナルで、必要なPPAを設定し、Ubuntuパッケージのリストを更新して、`git`をインストールします。

   ```shell
   sudo apt-add-repository ppa:git-core/ppa
   sudo apt-get update
   sudo apt-get install git
   ```

1. ローカルマシンでGitが動作することを確認します。

   ```shell
   git --version
   ```

Gitを最新の状態に保つには、次のコマンドを定期的に実行します。

```shell
sudo apt-get update && sudo apt-get install git
```

{{< /tab >}}

{{< tab title="その他のオペレーティングシステム" >}}

他のオペレーティングシステムへのGitのダウンロードとインストールについては、[Git公式ウェブサイト](https://git-scm.com/downloads)を参照してください。

{{< /tab >}}

{{< /tabs >}}

## Gitを設定する {#configure-git}

ローカルマシンからGitの使用を開始するには、認証情報を入力して、自分が作業の作成者であることを識別する必要があります。

Git IDはローカルまたはグローバルに設定できます。

- ローカル: 現在のプロジェクトのみに使用します。
- グローバル: 現在および将来のすべてのプロジェクトに使用します。

{{< tabs >}}

{{< tab title="ローカル設定" >}}

現在のプロジェクトのみに使用する場合は、Git IDをローカルに設定します。

氏名とメールアドレスは、GitLabで使用するものと一致する必要があります。

1. ターミナルで、氏名を追加します。次に例を示します。

   ```shell
   git config --local user.name "Alex Smith"
   ```

1. メールアドレスを追加します。次に例を示します。

   ```shell
   git config --local user.email "your_email_address@example.com"
   ```

1. 設定を確認するには、次を実行します。

   ```shell
   git config --local --list
   ```

{{< /tab >}}

{{< tab title="グローバル設定" >}}

マシン上の現在および将来のすべてのプロジェクトで使用する場合は、Git IDをグローバルに設定します。

氏名とメールアドレスは、GitLabで使用するものと一致する必要があります。

1. ターミナルで、氏名を追加します。次に例を示します。

   ```shell
   git config --global user.name "Sidney Jones"
   ```

1. メールアドレスを追加します。次に例を示します。

   ```shell
   git config --global user.email "your_email_address@example.com"
   ```

1. 設定を確認するには、次を実行します。

   ```shell
   git config --global --list
   ```

{{< /tab >}}

{{< /tabs >}}

### Gitの設定を確認する {#check-git-configuration-settings}

設定済みのGitの設定を確認するには、次を実行します。

```shell
git config user.name && git config user.email
```

## 関連トピック {#related-topics}

- [Gitの設定のドキュメント](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
- [SSHキーを使用してGitLabと通信する](../../../user/ssh.md)
