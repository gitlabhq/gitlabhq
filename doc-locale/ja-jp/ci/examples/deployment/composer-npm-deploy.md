---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Composerとnpmスクリプトをデプロイメントで実行し、SCP経由でGitLab CI/CDで実行する。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このガイドでは、[GitLab CI/CD](../../_index.md)を使用して、npmスクリプト経由でアセットをコンパイルしながら、PHPプロジェクトの依存関係をビルドする方法について説明します。

カスタムPHPおよびNode.jsのバージョンで独自のDockerイメージを作成できます。簡潔にするため、このガイドでは、PHPとNode.jsの両方がインストールされた既存の[Dockerイメージ](https://hub.docker.com/r/tetraweb/php/)を使用します。

```yaml
image: tetraweb/php
```

次のステップは、zip/unzipパッケージをインストールし、composerを使用できるようにすることです。これらを`before_script`セクションに配置します:

```yaml
before_script:
  - apt-get update
  - apt-get install zip unzip
  - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  - php composer-setup.php
  - php -r "unlink('composer-setup.php');"
```

これにより、すべての要件が確実に準備されます。次に、`composer install`を実行してすべてのPHPの依存関係をフェッチし、`npm install`を実行してNode.jsパッケージを読み込むます。次に、`npm`スクリプトを実行します。コマンドを`before_script`セクションに追加します:

```yaml
before_script:
  # ...
  - php composer.phar install
  - npm install
  - npm run deploy
```

この特定のケースでは、`npm deploy`スクリプトは、次の処理を行うGulpスクリプトです:

1. CSSとJSをコンパイル
1. スプライトを作成
1. さまざまなアセット（画像、フォント）をコピー
1. いくつかの文字列を置換

これらのすべての操作により、すべてのファイルが`build`フォルダーに配置され、ライブサーバーにデプロイする準備が整います。

## ライブサーバーにファイルを転送する方法 {#how-to-transfer-files-to-a-live-server}

rsync、SCP、SFTPなどの複数のオプションがあります。ここでは、SCPを使用します。

これを機能させるには、GitLab CI/CDCI/CD変数を (`gitlab.example/your-project-name/variables`でアクセス可能) を追加する必要があります。この変数に`STAGING_PRIVATE_KEY`という名前を付け、サーバーの**非公開** SSHキーに設定します。

### セキュリティのヒント {#security-tip}

更新が必要なフォルダーへのアクセス権を**only**（のみ）持つユーザーを作成します。

その変数を作成したら、そのキーが実行時にDockerコンテナに追加されていることを確認してください:

```yaml
before_script:
  # - ....
  - 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'
  - mkdir -p ~/.ssh
  - eval $(ssh-agent -s)
  - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config'
```

このスクリプトは、次のアクションを実行します:

1. `ssh-agent`が利用可能かどうかを確認し、利用できない場合はインストールします。
1. `~/.ssh`フォルダーを作成します。
1. スクリプトの実行環境がbashで実行されていることを確認します。
1. ホストの確認を無効にします。すべての接続は新しい実行環境で発生するため、ホストの確認を無効にすると、接続するたびにサーバーのIDを確認して受け入れるようにGitLabから求められることがなくなります。

そして、これは基本的に`before_script`セクションに必要なすべてです。

## デプロイ方法 {#how-to-deploy}

Dockerイメージからサーバーに`build`フォルダーをデプロイするには、新しいジョブを作成します:

```yaml
stage_deploy:
  artifacts:
    paths:
      - build/
  rules:
    - if: $CI_COMMIT_BRANCH == "dev"
  script:
    - ssh-add <(echo "$STAGING_PRIVATE_KEY")
    - ssh -p22 server_user@server_host "mkdir htdocs/wp-content/themes/_tmp"
    - scp -P22 -r build/* server_user@server_host:htdocs/wp-content/themes/_tmp
    - ssh -p22 server_user@server_host "mv htdocs/wp-content/themes/live htdocs/wp-content/themes/_old && mv htdocs/wp-content/themes/_tmp htdocs/wp-content/themes/live"
    - ssh -p22 server_user@server_host "rm -rf htdocs/wp-content/themes/_old"
```

内訳は次のとおりです:

1. `rules:if: $CI_COMMIT_BRANCH == "dev"`は、`dev`ブランチに何かがプッシュされた場合にのみ、このビルドが実行されることを意味します。このブロックを完全に削除して、すべてのプッシュですべてを実行させることができます（ただし、おそらくこれは不要です）。
1. `ssh-add ...`は、Web UIに追加した非公開キーをDockerコンテナに追加します。
1. `ssh`を使用して接続し、新しい`_tmp`フォルダーを作成します。
1. `scp`を使用して接続し、（`npm`スクリプトによって生成された）`build`フォルダーを、以前に作成した`_tmp`フォルダーにアップロードします。
1. `ssh`を使用して再度接続し、`live`フォルダーを`_old`フォルダーに移動してから、`_tmp`を`live`に移動します。
1. SSHに接続して、`_old`フォルダーを削除します。

`artifacts`セクションは、`build`ディレクトリを保持するようにGitLab CI/CDに指示します（後で、必要に応じてダウンロードできます）。

### この方法を選ぶ理由 {#why-do-it-this-way}

これをステージサーバーにのみ使用している場合は、次の2つのステップで実行できます:

```yaml
- ssh -p22 server_user@server_host "rm -rf htdocs/wp-content/themes/live/*"
- scp -P22 -r build/* server_user@server_host:htdocs/wp-content/themes/live
```

問題は、サーバーにアプリがない短い期間があることです。

したがって、本番環境では、追加の手順により、機能的なアプリが常に配置されるようになります。

## 次のステップ {#where-to-go-next}

これはWordPressプロジェクトであったため、実際のコードスニペットが含まれています。追求できる更なるアイデアを以下に示します:

- デフォルトのブランチに対してわずかに異なるスクリプトを使用すると、そのブランチから本番サーバーに、他のブランチからステージサーバーにデプロイできます。
- ライブにプッシュする代わりに、WordPressの公式リポジトリにプッシュできます。
- i18nテキストドメインを動的に生成できます。

---

最終的な`.gitlab-ci.yml`は次のようになります:

```yaml
stage_deploy:
  image: tetraweb/php
  artifacts:
    paths:
      - build/
  rules:
    - if: $CI_COMMIT_BRANCH == "dev"
  before_script:
    - apt-get update
    - apt-get install zip unzip
    - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    - php composer-setup.php
    - php -r "unlink('composer-setup.php');"
    - php composer.phar install
    - npm install
    - npm run deploy
    - 'which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )'
    - mkdir -p ~/.ssh
    - eval $(ssh-agent -s)
    - '[[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config'
  script:
    - ssh-add <(echo "$STAGING_PRIVATE_KEY")
    - ssh -p22 server_user@server_host "mkdir htdocs/wp-content/themes/_tmp"
    - scp -P22 -r build/* server_user@server_host:htdocs/wp-content/themes/_tmp
    - ssh -p22 server_user@server_host "mv htdocs/wp-content/themes/live htdocs/wp-content/themes/_old && mv htdocs/wp-content/themes/_tmp htdocs/wp-content/themes/live"
    - ssh -p22 server_user@server_host "rm -rf htdocs/wp-content/themes/_old"
```
