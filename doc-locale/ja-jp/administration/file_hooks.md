---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ファイルフック
description: "カスタムファイルフックを作成して、ソースコードを修正せずに、外部サービスとGitLab Self-Managedインスタンスをインテグレーションします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

カスタムファイルフックを使用して、GitLabソースコードを修正せずに、カスタムインテグレーションを導入します。

ファイルフックは各エントリで実行されます。ファイルフックのコードでエントリまたはプロジェクトをフィルタリングし、必要に応じて多数のファイルフックを作成できます。各ファイルフックは、エントリの場合、GitLabによって非同期的にトリガーされます。エントリのリストについては、[システムフック](system_hooks.md)と[Webhook](../user/project/integrations/webhook_events.md)のドキュメントを参照してください。

{{< alert type="note" >}}

ファイルフックは、GitLabサーバーのファイルシステムで設定する必要があります。これらのタスクを完了できるのは、GitLabサーバーの管理者のみです。ファイルシステムへのアクセス権がない場合は、オプションとして[システムフック](system_hooks.md)または[Webhook](../user/project/integrations/webhooks.md)を調査してください。

{{< /alert >}}

独自のファイルフックを作成してサポートする代わりに、GitLabソースコードを直接変更して、アップストリームにコントリビュートすることもできます。このようにして、機能がバージョン間で維持され、テストでカバーされるようにすることができます。

## カスタムファイルフックをセットアップする {#set-up-a-custom-file-hook}

ファイルフックは、`file_hooks`ディレクトリにある必要があります。サブディレクトリは無視されます。[`file_hooks`下の`example`ディレクトリ](https://gitlab.com/gitlab-org/gitlab/-/tree/master/file_hooks/examples)に例があります。

カスタムフックをセットアップするには:

1. Sidekiqコンポーネントを実行しているGitLabサーバーで、プラグインディレクトリを見つけます。自己コンパイルによるインストールの場合、パスは通常`/home/git/gitlab/file_hooks/`です。Linuxパッケージインストールの場合、パスは通常`/opt/gitlab/embedded/service/gitlab-rails/file_hooks`です。

   [複数のサーバーでの設定](reference_architectures/_index.md)の場合、フックファイルは各Sidekiqサーバーに存在する必要があります。

1. `file_hooks`ディレクトリ内で、スペースや特殊文字を含まない、任意の名前のファイルを作成します。
1. フックファイルを実行可能にし、Gitユーザーが所有していることを確認します。
1. 期待どおりにファイルフックが機能するようにコードを記述します。これは任意の言語で記述でき、上部の「シバン」が言語タイプを適切に反映していることを確認します。たとえば、スクリプトがRubyで記述されている場合、シバンはおそらく`#!/usr/bin/env ruby`となります。
1. ファイルフックへのデータは、`STDIN`のJSONとして提供されます。これは[システムフック](system_hooks.md)とまったく同じです。

ファイルフックコードが適切に実装されていると仮定すると、フックは適切にトリガーされます。ファイルフックファイルリストは、各エントリで更新されます。新しいファイルフックを適用するために、GitLabを再起動する必要はありません。

ファイルフックがゼロ以外の終了コードで実行されるか、実行に失敗した場合、メッセージが以下に記録されます:

- 自己コンパイルによるインストールの場合: `log/file_hook.log`。
- Linuxパッケージインストールの場合: `gitlab-rails/file_hook.log`。

このファイルは、ファイルフックがゼロ以外の状態で終了した場合にのみ作成されます。ファイルフックが実行されると、開始された各`FileHookWorker`のSidekiqログ`gitlab/sidekiq/current`にエントリが追加されます。このエントリには、エントリの詳細と、実行されたスクリプトが含まれています。

## ファイルフックの例 {#file-hook-example}

この例は、`project_create`エントリでのみ応答し、GitLabインスタンスは、新しいプロジェクトが作成されたことを管理者に通知します。

```ruby
#!/opt/gitlab/embedded/bin/ruby
# By using the embedded ruby version we eliminate the possibility that our chosen language
# would be unavailable from
require 'json'
require 'mail'

# The incoming variables are in JSON format so we need to parse it first.
ARGS = JSON.parse($stdin.read)

# We only want to trigger this file hook on the event project_create
return unless ARGS['event_name'] == 'project_create'

# We will inform our admins of our gitlab instance that a new project is created
Mail.deliver do
  from    'info@gitlab_instance.com'
  to      'admin@gitlab_instance.com'
  subject "new project " + ARGS['name']
  body    ARGS['owner_name'] + 'created project ' + ARGS['name']
end
```

## 検証の例 {#validation-example}

独自のファイルフックを作成するのは難しい場合があり、システムを変更せずに確認できると簡単になります。Rakeタスクは、本番環境で使用する前に、ステージング環境でファイルフックをテストするために使用できるように提供されています。Rakeタスクはサンプルデータを使い、各ファイルフックを実行します。出力は、システムがファイルフックを認識しているかどうか、エラーなしで実行されたかどうかを判断するのに十分なはずです。

```shell
# Omnibus installations
sudo gitlab-rake file_hooks:validate

# Installations from source
cd /home/git/gitlab
bundle exec rake file_hooks:validate RAILS_ENV=production
```

出力の例:

```plaintext
Validating file hooks from /file_hooks directory
* /home/git/gitlab/file_hooks/save_to_file.clj succeed (zero exit code)
* /home/git/gitlab/file_hooks/save_to_file.rb failure (non-zero exit code)
```

## 関連トピック {#related-topics}

- [サーバーフック](server_hooks.md)
- [システムフック](system_hooks.md)
