---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Ruby gem 
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

これは[Ruby gem](../../user/packages/rubygems_registry/_index.md)のドキュメントです。

{{< alert type="warning" >}}

このは、[Ruby gemとBundlerパッケージマネージャークライアント](https://maven.apache.org/)で使用され、通常、手動での消費を意図したものではありません。このは開発中であり、機能が制限されているため、本番環境での使用には適していません。

{{< /alert >}}

GitLabパッケージレジストリからgemをアップロードおよびインストールする方法については、[Ruby gemレジストリドキュメント](../../user/packages/rubygems_registry/_index.md)を参照してください。

{{< alert type="note" >}}

これらのエンドポイントは、標準のAPI認証方式に準拠していません。どのヘッダーとトークンタイプがサポートされているかの詳細については、[Ruby gemレジストリドキュメント](../../user/packages/rubygems_registry/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

{{< /alert >}}

## Ruby gemを有効にする {#enable-the-ruby-gems-api}

GitLabのRuby gemは、デフォルトで無効になっている機能フラグの背後にあります。GitLab Railsコンソールへのアクセス権を持つGitLabの管理者は、インスタンスのこのを有効にできます。

有効にするには、次の手順に従います:

```ruby
Feature.enable(:rubygem_packages)
```

無効にするには、次の手順に従います: 

```ruby
Feature.disable(:rubygem_packages)
```

特定のプロジェクトに対して有効または無効にするには:

```ruby
Feature.enable(:rubygem_packages, Project.find(1))
Feature.disable(:rubygem_packages, Project.find(2))
```

## gemファイルをダウンロード {#download-a-gem-file}

gemをダウンロード:

```plaintext
GET projects/:id/packages/rubygems/gems/:file_name
```

| 属性    | 型   | 必須 | 説明 |
| ------------ | ------ | -------- | ----------- |
| `id`         | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |
| `file_name`  | 文字列 | はい      | `.gem`ファイルの名前。 |

```shell
curl --header "Authorization:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/gems/my_gem-1.0.0.gem"
```

出力をファイルに書き込み:

```shell
curl --header "Authorization:<personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/gems/my_gem-1.0.0.gem" >> my_gem-1.0.0.gem
```

これにより、ダウンロードされたファイルが現在のディレクトリの`my_gem-1.0.0.gem`に書き込まれます。

## 依存のリストをフェッチする {#fetch-a-list-of-dependencies}

gemのリストの依存のリストをフェッチします:

```plaintext
GET projects/:id/packages/rubygems/api/v1/dependencies
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |
| `gems`    | 文字列 | いいえ       | 依存をフェッチするためのgemのコンマ区切りリスト。 |

```shell
curl --header "Authorization:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/dependencies?gems=my_gem,foo"
```

このエンドポイントは、リクエストされたgemのすべてのバージョンのハッシュのハッシュの配列を返します。レスポンスはマーシャルされるため、ファイルに保存できます。Rubyがインストールされている場合は、次のRubyコマンドを使用してレスポンスを読み取りできます。これを機能させるには、[`~/.gem/credentials`で認証情報を設定する](../../user/packages/rubygems_registry/_index.md#authenticate-to-the-package-registry)必要があります:

```shell
$ ruby -ropen-uri -rpp -e \
  'pp Marshal.load(open("https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/dependencies?gems=my_gem,rails,foo"))'

[{:name=>"my_gem", :number=>"0.0.1", :platform=>"ruby", :dependencies=>[]},
 {:name=>"my_gem",
  :number=>"0.0.3",
  :platform=>"ruby",
  :dependencies=>
   [["dependency_1", "~> 1.2.3"],
    ["dependency_2", "= 3.0.0"],
    ["dependency_3", ">= 1.0.0"],
    ["dependency_4", ">= 0"]]},
 {:name=>"my_gem",
  :number=>"0.0.2",
  :platform=>"ruby",
  :dependencies=>
   [["dependency_1", "~> 1.2.3"],
    ["dependency_2", "= 3.0.0"],
    ["dependency_3", ">= 1.0.0"],
    ["dependency_4", ">= 0"]]},
 {:name=>"foo",
  :number=>"0.0.2",
  :platform=>"ruby",
  :dependencies=>
    ["dependency_2", "= 3.0.0"],
    ["dependency_4", ">= 0"]]}]
```

これにより、ダウンロードされたファイルが現在のディレクトリの`mypkg-1.0-SNAPSHOT.jar`に書き込まれます。

## gemをアップロード {#upload-a-gem}

gemをアップロード:

```plaintext
POST projects/:id/packages/rubygems/api/v1/gems
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | プロジェクトのIDまたはフルパス。 |

```shell
curl --request POST \
     --upload-file path/to/my_gem_file.gem \
     --header "Authorization:<personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/gems"
```
