---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Wiki設定
description: Wikiの設定を構成します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

お使いのGitLabインスタンスのWiki設定を調整します。

## Wikiページコンテンツサイズ制限 {#wiki-page-content-size-limit}

Wikiページの最大コンテンツサイズ制限を設定できます。この制限は、機能の悪用を防ぐことができます。デフォルト値は**5242880 Bytes** (5 MB) です。

### コンテンツサイズ制限の動作 {#content-size-limit-behavior}

GitLabは、GitLabのUIまたはAPIを介してWikiページを作成または更新する際に、コンテンツサイズ制限を適用します。Gitでプッシュされたローカルな変更は検証されません。

既存のWikiページを壊す場合、Wikiページが再度編集され、コンテンツが変更されるまで、制限は適用されません。

### Wikiページコンテンツサイズ制限設定 {#wiki-page-content-size-limit-configuration}

この設定は、[**管理者**エリア設定](../settings/_index.md)からは利用できません。この設定を設定するには、Railsコンソールまたは[アプリケーション設定API](../../api/settings.md)のいずれかを使用します。

> [!note]
> 制限の値はバイト単位である必要があります。最小値は1024バイトです。

#### Railsコンソールを介して {#through-the-rails-console}

この設定をRailsコンソールを介して設定するには:

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

現在の値を取得するには、Railsコンソールを起動して実行します:

  ```ruby
  Gitlab::CurrentSettings.wiki_page_max_content_bytes
  ```

#### APIを介して {#through-the-api}

アプリケーション設定APIを介してWikiページサイズ制限を設定するには、[他の設定を更新する](../../api/settings.md#update-application-settings)のと同様にコマンドを使用します:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?wiki_page_max_content_bytes=5242880"
```

APIを使用して、[現在の値を取得する](../../api/settings.md#retrieve-details-on-current-application-settings)こともできます:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings"
```

### Wikiリポジトリサイズの削減 {#reduce-wiki-repository-size}

Wikiは[ネームスペースストレージサイズ](../settings/account_and_limit_settings.md)の一部としてカウントされるため、Wikiリポジトリは可能な限りコンパクトに保つ必要があります。

リポジトリを圧縮するためのツールに関する詳細は、[リポジトリサイズの削減](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)に関するドキュメントをお読みください。

## AsciiDocでURIインクルードを許可する {#allow-uri-includes-for-asciidoc}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/348687)されました。

{{< /history >}}

インクルードディレクティブは、個別のページまたは外部URLからコンテンツをインポートし、現在のドキュメントのコンテンツの一部として表示します。AsciiDocインクルードを有効にするには、RailsコンソールまたはAPIを介して機能を有効にします。

### Railsコンソールを介して {#through-the-rails-console-1}

この設定をRailsコンソールを介して設定するには:

1. Railsコンソールを起動します:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. AsciiDocのURIインクルードを許可するようにWikiを更新します:

   ```ruby
   ApplicationSetting.first.update!(wiki_asciidoc_allow_uri_includes: true)
   ```

インクルードが有効になっているか確認するには、Railsコンソールを起動して実行します:

  ```ruby
  Gitlab::CurrentSettings.wiki_asciidoc_allow_uri_includes
  ```

### APIを介して {#through-the-api-1}

[アプリケーション設定API](../../api/settings.md#update-application-settings)を介して、AsciiDocのURIインクルードを許可するようにWikiを設定するには、`curl`コマンドを使用します:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/application/settings?wiki_asciidoc_allow_uri_includes=true"
```

## 関連トピック {#related-topics}

- [Wikiのユーザードキュメント](../../user/project/wiki/_index.md)
- [プロジェクトWiki API](../../api/wikis.md)
- [グループWiki API](../../api/group_wikis.md)
