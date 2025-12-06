---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Wiki設定
description: Wiki設定を構成します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabインスタンスのWiki設定を調整します。

## Wikiページのコンテンツサイズ制限 {#wiki-page-content-size-limit}

Wikiページの最大コンテンツサイズ制限を設定できます。この制限により、機能の悪用を防ぐことができます。デフォルト値は**5242880バイト**（5 MB）です。

### どのように機能しますか？ {#how-does-it-work}

コンテンツサイズの制限は、WikiページがGitLab UIまたはAPIを介して作成または更新されたときに適用されます。Git経由でプッシュされたローカルの変更は検証されません。

既存のWikiページを中断するために、Wikiページが再度編集され、コンテンツが変更されるまで、制限は有効になりません。

### Wikiページのコンテンツサイズ制限の設定 {#wiki-page-content-size-limit-configuration}

この設定は、[**管理者**エリアの設定](../settings/_index.md)からは使用できません。この設定を構成するには、Railsコンソールまたは[Application設定API](../../api/settings.md)のいずれかを使用します。

{{< alert type="note" >}}

制限の値はバイト単位である必要があります。最小値は1024バイトです。

{{< /alert >}}

#### Railsコンソールから {#through-the-rails-console}

Railsコンソールからこの設定を構成するには:

1. Railsコンソールを起動します:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. Wikiページの最大コンテンツサイズを更新します:

   ```ruby
   ApplicationSetting.first.update!(wiki_page_max_content_bytes: 5.megabytes)
   ```

現在の値を取得するには、Railsコンソールを起動して、以下を実行します:

  ```ruby
  Gitlab::CurrentSettings.wiki_page_max_content_bytes
  ```

#### APIを使用します {#through-the-api}

Application設定APIからWikiページのサイズ制限を設定するには、[他の設定を更新](../../api/settings.md#update-application-settings)するのと同じように、コマンドを使用します:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?wiki_page_max_content_bytes=5242880"
```

APIを使用して[現在の値を取得](../../api/settings.md#get-details-on-current-application-settings)することもできます:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings"
```

### Wikiリポジトリのサイズを縮小する {#reduce-wiki-repository-size}

Wikiは[ネームスペースストレージサイズ](../settings/account_and_limit_settings.md)の一部としてカウントされるため、Wikiリポジトリをできるだけコンパクトに保つ必要があります。

リポジトリをコンパクトにするツールの詳細については、[リポジトリサイズの縮小](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)に関するドキュメントを参照してください。

## AsciiDocのURIインポートを許可する {#allow-uri-includes-for-asciidoc}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348687)されました。

{{< /history >}}

インポートディレクティブは、個別のページまたは外部URIからコンテンツをインポートし、現在のドキュメントのコンテンツの一部として表示します。AsciiDocのインポートを有効にするには、RailsコンソールまたはAPIを使用して機能を有効にします。

### Railsコンソールから {#through-the-rails-console-1}

Railsコンソールからこの設定を構成するには:

1. Railsコンソールを起動します:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. AsciiDocのURIインポートを許可するようにWikiを更新します:

   ```ruby
   ApplicationSetting.first.update!(wiki_asciidoc_allow_uri_includes: true)
   ```

インポートが有効になっているかどうかを確認するには、Railsコンソールを起動して、以下を実行します:

  ```ruby
  Gitlab::CurrentSettings.wiki_asciidoc_allow_uri_includes
  ```

### APIを使用します {#through-the-api-1}

[Application設定API](../../api/settings.md#update-application-settings)を介してAsciiDocのURIインポートを許可するようにWikiを設定するには、`curl`コマンドを使用します:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/application/settings?wiki_asciidoc_allow_uri_includes=true"
```

## 関連トピック {#related-topics}

- [Wikiのユーザーインターフェースドキュメント](../../user/project/wiki/_index.md)
- [プロジェクトWiki API](../../api/wikis.md)
- [グループWiki API](../../api/group_wikis.md)
