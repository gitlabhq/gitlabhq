---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ファイルフック
description: "カスタムファイルフックを作成して、codeコードを修正することなく、GitLabのSelf-Managedインスタンスを外部サービスと統合します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

カスタムファイルフックを使用して、GitLabのソースcodeコードを修正することなく、カスタムインテグレーションを導入します。

ファイルフックはイベントごとに実行されます。ファイルフックのcodeコードでイベントまたはプロジェクトをフィルタリングし、必要に応じて多くのファイルフックを作成できます。各ファイルフックは、イベント発生時にGitLabによって非同期にトリガーされます。イベントのリストについては、[システムフック](system_hooks.md)および[Webhook](../user/project/integrations/webhook_events.md)のドキュメントを参照してください。

> [!note]
> ファイルフックは、GitLabサーバーのファイルシステムで設定する必要があります。GitLabサーバーの管理者のみが、これらのタスクを完了できます。ファイルシステムへのアクセス権がない場合は、オプションとして[システムフック](system_hooks.md)または[Webhook](../user/project/integrations/webhooks.md)を調査してください。

独自のファイルフックを作成してサポートする代わりに、GitLabのソースcodeコードに直接変更を加え、アップストリームにコントリビュートすることもできます。このようにして、バージョン間で機能が維持され、テストによってカバーされることを保証できます。

## カスタムファイルフックを設定する {#set-up-a-custom-file-hook}

ファイルフックは`file_hooks`ディレクトリにある必要があります。サブディレクトリは無視されます。[`file_hooks`下の`example`ディレクトリ](https://gitlab.com/gitlab-org/gitlab/-/tree/master/file_hooks/examples)に例があります。

カスタムフックを設定するには:

1. Sidekiqコンポーネントを実行しているGitLabサーバーで、プラグインディレクトリを見つけます。自己コンパイルによるインストールの場合、パスは通常`/home/git/gitlab/file_hooks/`です。Linuxパッケージインストールの場合、パスは通常`/opt/gitlab/embedded/service/gitlab-rails/file_hooks`です。

   [複数のサーバーを持つ設定](reference_architectures/_index.md)の場合、フックファイルは各GitLabアプリケーション (Rails) およびSidekiqサーバーに存在する必要があります。

1. `file_hooks`ディレクトリ内に、スペースや特殊文字を含まない任意の名前のファイルを作成します。
1. フックファイルを実行可能にし、Gitユーザーが所有していることを確認します。
1. ファイルフックが期待どおりに機能するようにcodeコードを記述します。それはどの言語でも構いません。上部にあるシバンが言語タイプを適切に反映していることを確認してください。たとえば、スクリプトがRubyの場合、シバンは`#!/usr/bin/env ruby`になるでしょう。
1. ファイルフックへのデータは、`STDIN`上でJSONとして提供されます。それは[システムフック](system_hooks.md)とまったく同じです。

ファイルフックのcodeコードが適切に実装されていれば、フックは適切に発火します。ファイルフックのファイルリストは、各イベントで更新されます。新しいファイルフックを適用するためにGitLabを再起動する必要はありません。

ファイルフックがゼロ以外の終了codeコードで実行されるか、実行に失敗した場合、メッセージは以下に記録されます:

- 自己コンパイルによるインストールの場合: `log/file_hook.log`。
- Linuxパッケージインストールの場合: `gitlab-rails/file_hook.log`。

このファイルは、ファイルフックがゼロ以外の終了codeコードで終了した場合にのみ作成されます。ファイルフックが実行されると、開始された各`FileHookWorker`のSidekiqログ`gitlab/sidekiq/current`にエントリが追加されます。このエントリには、イベントと実行されたスクリプトの詳細が含まれています。

## ファイルフックの例 {#file-hook-example}

この例はイベント`project_create`のみで応答し、GitLabインスタンスは新しいプロジェクトが作成されたことを管理者に通知します。

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

独自のファイルフックを記述するのは難しい場合がありますが、システムを変更せずに確認できると簡単になります。Rakeタスクが提供されており、ステージング環境でファイルフックを本番環境で使用する前にテストできます。Rakeタスクはサンプルデータを使用し、各ファイルフックを実行します。出力は、システムがファイルフックを認識しているかどうか、およびエラーなしで実行されたかどうかを判断するのに十分であるはずです。

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
