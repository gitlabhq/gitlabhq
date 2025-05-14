---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: How to install Git on your local machine.
title: Git をインストール
---

GitLabプロジェクトにコントリビュートするには、ローカルマシンに Git クライアントをダウンロード、インストール、Configure する必要があります。GitLab は SSH プロトコルを使用して Git と Secure に通信します。SSH を使用すると、ユーザー名とパスワードを毎回入力しなくても、GitLab remote サーバーに対して認証できます。

他のオペレーティングシステムへの Git のダウンロードとインストールについては、[Git 公式ウェブサイト](https://git-scm.com/downloads)を参照してください。

Git をインストールして Configure したら、[SSH キーペアを生成して GitLab アカウントに追加](../../../user/ssh.md#generate-an-ssh-key-pair)します。

## Git をインストールして更新

{{< tabs >}}

{{< tab title="macOS" >}}

macOS には Git のバージョンが付属していますが、最新バージョンの Git をインストールする必要があります。Git をインストールする一般的な方法は、[Homebrew](https://brew.sh/index.html) を使用することです。

Homebrew を使用して macOS に最新バージョンの Git をインストールするには:

1. Homebrew をまだインストールしたことがない場合は、[Homebrew のインストール手順](https://brew.sh/index.html)に従ってください。
1. ターミナルで、`brew install git` を実行して Git をインストールします。
1. ローカルマシンで Git が動作することを確認します:

   ```shell
   git --version
   ```

Git を最新の状態に保つには、次のコマンドを定期的に実行します:

```shell
brew update && brew upgrade git
```

{{< /tab >}}

{{< tab title="Ubuntu Linux" >}}

Ubuntu には Git のバージョンが付属していますが、最新バージョンの Git をインストールする必要があります。最新バージョンは、Personal Package Archive (PPA) を使用して入手できます。

PPA を使用して Ubuntu Linux に最新バージョンの Git をインストールするには:

1. ターミナルで、必要な PPA を configure し、Ubuntu パッケージのリストを更新して、`git` をインストールします:

   ```shell
   sudo apt-add-repository ppa:git-core/ppa
   sudo apt-get update
   sudo apt-get install git
   ```

1. ローカルマシンで Git が動作することを確認します:

   ```shell
   git --version
   ```

Git を最新の状態に保つには、次のコマンドを定期的に実行します:

```shell
sudo apt-get update && sudo apt-get install git
```

{{< /tab >}}

{{< /tabs >}}

## Git を Configure する

ローカルマシンから Git の使用を開始するには、認証情報を入力して、作業の作成者として自身を識別する必要があります。

Git ID はローカルまたはグローバルに Configure できます:

- ローカル:現在のプロジェクトのみに使用します。
- グローバル:現在および将来のすべてのプロジェクトに使用します。

{{< tabs >}}

{{< tab title="ローカル設定" >}}

現在のプロジェクトのみに使用するように Git ID をローカルで Configure します。

氏名とメールアドレスは、GitLab で使用するものと一致する必要があります。

1. ターミナルで、氏名を追加します。次に例を示します:

   ```shell
   git config --local user.name "Alex Smith"
   ```

1. メールアドレスを追加します。次に例を示します:

   ```shell
   git config --local user.email "your_email_address@example.com"
   ```

1. 設定を確認するには、次を実行します:

   ```shell
   git config --local --list
   ```

{{< /tab >}}

{{< tab title="グローバル設定" >}}

マシン上の現在および将来のすべてのプロジェクトで使用するように Git ID をグローバルに Configure します。

氏名とメールアドレスは、GitLab で使用するものと一致する必要があります。

1. ターミナルで、氏名を追加します。次に例を示します:

   ```shell
   git config --global user.name "Sidney Jones"
   ```

1. メールアドレスを追加します。次に例を示します:

   ```shell
   git config --global user.email "your_email_address@example.com"
   ```

1. 設定を確認するには、次を実行します:

   ```shell
   git config --global --list
   ```

{{< /tab >}}

{{< /tabs >}}

### Git 構成設定の確認

Configure 済みの Git 設定を確認するには、次を実行します:

```shell
git config user.name && git config user.email
```

## 関連トピック

- [Git 設定ドキュメント](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
- [SSH鍵を使用して GitLab と通信する](../../../user/ssh.md)
