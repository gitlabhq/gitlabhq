---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan 1のパッケージレジストリ内のパッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< alert type="warning" >}}

GitLabのConanパッケージレジストリは開発中であり、機能が限られているため、本番環境での使用には適していません。この[エピック](https://gitlab.com/groups/gitlab-org/-/epics/6816)では、本番環境で使用できるようになるまでの残りの作業とタイムラインについて詳しく説明します。

{{< /alert >}}

{{< alert type="note" >}}

ConanレジストリはFIPSに準拠しておらず、FIPSモードが有効になっていると無効になります。

{{< /alert >}}

プロジェクトのパッケージレジストリにConanパッケージを公開します。これにより、依存関係として使用する必要がある場合に、いつでもパッケージをインストールできるようになります。

Conanパッケージをパッケージレジストリに公開するには、パッケージレジストリをリモートとして追加し、認証します。

次に、`conan`コマンドを実行して、パッケージレジストリにパッケージを公開できます。

Conanパッケージマネージャークライアントが使用する特定のAPIエンドポイントのドキュメントについては、[Conan v1 API](../../../api/packages/conan_v1.md)または[Conan v2 API](../../../api/packages/conan_v2.md)を参照してください。

[Conan 1パッケージをビルドする方法](../workflows/build_packages.md#conan-1)をご覧ください。

## パッケージレジストリをConanリモートとして追加する {#add-the-package-registry-as-a-conan-remote}

`conan`コマンドを実行するには、プロジェクトまたはインスタンスのConanリモートとしてパッケージレジストリを追加する必要があります。次に、パッケージレジストリとの間でパッケージを公開およびインストールできます。

### プロジェクトのリモートを追加する {#add-a-remote-for-your-project}

すべてのコマンドでリモート名を指定しなくても、プロジェクト内のパッケージを操作できるように、リモートを設定します。

プロジェクトのリモートを設定する場合、パッケージ名に制限はありません。ただし、コマンドには、たとえば`package_name/version@user/channel`など、ユーザーとチャンネルを含む完全なレシピを含める必要があります。

リモートを追加するには:

1. ターミナルで、次のコマンドを実行します:

   ```shell
   conan remote add gitlab https://gitlab.example.com/api/v4/projects/<project_id>/packages/conan
   ```

1. Conanコマンドの最後に`--remote=gitlab`を追加して、リモートを使用します。

   例: 

   ```shell
   conan search Hello* --remote=gitlab
   ```

### インスタンスのリモートを追加する {#add-a-remote-for-your-instance}

単一のリモートを使用して、GitLabインスタンス全体のパッケージにアクセスします。

ただし、このリモートを使用する場合は、これらの[パッケージ](#package-recipe-naming-convention-for-instance-remotes)の命名規則に従う必要があります。

リモートを追加するには:

1. ターミナルで、次のコマンドを実行します:

   ```shell
   conan remote add gitlab https://gitlab.example.com/api/v4/packages/conan
   ```

1. Conanコマンドの最後に`--remote=gitlab`を追加して、リモートを使用します。

   例: 

   ```shell
   conan search 'Hello*' --remote=gitlab
   ```

#### インスタンスリモートのパッケージレシピの命名規則 {#package-recipe-naming-convention-for-instance-remotes}

標準のConanレシピの命名規則は`package_name/version@user/channel`ですが、[インスタンスリモート](#add-a-remote-for-your-instance)を使用している場合、レシピの`user`は、プラス記号（`+`）で区切られたプロジェクトパスである必要があります。

レシピ名の例:

| プロジェクト                | パッケージ                                        | サポート対象 |
| ---------------------- | ---------------------------------------------- | --------- |
| `foo/bar`              | `my-package/1.0.0@foo+bar/stable`              | √       |
| `foo/bar-baz/buz`      | `my-package/1.0.0@foo+bar-baz+buz/stable`      | √       |
| `gitlab-org/gitlab-ce` | `my-package/1.0.0@gitlab-org+gitlab-ce/stable` | √       |
| `gitlab-org/gitlab-ce` | `my-package/1.0.0@foo/stable`                  | いいえ        |

[プロジェクトのリモート](#add-a-remote-for-your-project)には、より柔軟な命名規則があります。

## パッケージレジストリに対して認証する {#authenticate-to-the-package-registry}

GitLabでは、パッケージのアップロード、およびプライベートプロジェクトと内部プロジェクトからパッケージをインストールするには、認証が必要です。（ただし、認証なしで公開プロジェクトからパッケージをインストールできます）。

パッケージレジストリに認証するには、次のいずれかが必要です:

- スコープが`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
- スコープが`read_package_registry`と`write_package_registry`のどちらか、または両方に設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。
- [CIジョブトークン](#publish-a-conan-package-by-using-cicd)。

{{< alert type="note" >}}

認証されていない場合、プライベートプロジェクトと内部プロジェクトのパッケージは非表示になります。認証せずに、プライベートプロジェクトまたは内部プロジェクトからパッケージを検索またはダウンロードしようとすると、Conanクライアントでエラー`unable to find the package in remote`が表示されます。

{{< /alert >}}

### GitLabリモートに認証情報を追加する {#add-your-credentials-to-the-gitlab-remote}

すべてのConanコマンドにトークンを明示的に追加する必要がないように、トークンをGitLabリモートに関連付けます。

前提要件: 

- 認証トークンが必要です。
- Conanリモート[を設定する](#add-the-package-registry-as-a-conan-remote)必要があります。

ターミナルで、次のコマンドを実行します。この例では、リモート名は`gitlab`です。リモートの名前を使用します。

```shell
conan user <gitlab_username or deploy_token_username> -r gitlab -p <personal_access_token or deploy_token>
```

`--remote=gitlab`でコマンドを実行すると、ユーザー名とパスワードがリクエストに含まれるようになります。

{{< alert type="note" >}}

GitLabでの認証は定期的に期限切れになるため、パーソナルアクセストークンを再入力する必要がある場合があります。

{{< /alert >}}

### プロジェクトのデフォルトリモートを設定する（オプション） {#set-a-default-remote-for-your-project-optional}

リモートを指定せずにGitLabパッケージレジストリとやり取りする場合は、Conanにパッケージのパッケージレジストリを常に使用するように指示できます。

ターミナルで、次のコマンドを実行します:

```shell
conan remote add_ref Hello/0.1@mycompany/beta gitlab
```

{{< alert type="note" >}}

パッケージレシピにはバージョンが含まれているため、`Hello/0.1@user/channel`のデフォルトリモートは`Hello/0.2@user/channel`では機能しません。

{{< /alert >}}

デフォルトのユーザーまたはリモートを設定しない場合でも、コマンドにユーザーとリモートを含めることができます:

```shell
CONAN_LOGIN_USERNAME=<gitlab_username or deploy_token_username> CONAN_PASSWORD=<personal_access_token or deploy_token> <conan command> --remote=gitlab
```

## Conanパッケージを公開する {#publish-a-conan-package}

Conanパッケージをパッケージレジストリに公開して、プロジェクトにアクセスできるすべてのユーザーが、依存関係としてパッケージを使用できるようにします。

前提要件: 

- Conanリモート[を設定する](#add-the-package-registry-as-a-conan-remote)必要があります。
- パッケージレジストリでの[認証](#authenticate-to-the-package-registry)を設定する必要があります。
- ローカル[Conanパッケージ](https://docs.conan.io/en/latest/creating_packages/getting_started.html)が存在する必要があります。
  - インスタンスリモートの場合、パッケージは[命名規則](#package-recipe-naming-convention-for-instance-remotes)を満たしている必要があります。
- [プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)に表示されるプロジェクトIDが必要です。

パッケージを公開するには、`conan upload`コマンドを使用します:

```shell
conan upload Hello/0.1@mycompany/beta --all
```

## CI/CDを使用してConanパッケージを公開する {#publish-a-conan-package-by-using-cicd}

[GitLab CI/CD](../../../ci/_index.md)でConanコマンドを使用するには、コマンドでパーソナルアクセストークンの代わりに`CI_JOB_TOKEN`を使用できます。

`.gitlab-ci.yml`ファイル内の各Conanコマンドで、`CONAN_LOGIN_USERNAME`と`CONAN_PASSWORD`を指定できます。例: 

```yaml
create_package:
  image: conanio/gcc7
  stage: deploy
  script:
    - conan remote add gitlab ${CI_API_V4_URL}/projects/$CI_PROJECT_ID/packages/conan
    - conan new <package-name>/0.1 -t
    - conan create . <group-name>+<project-name>/stable
    - CONAN_LOGIN_USERNAME=ci_user CONAN_PASSWORD=${CI_JOB_TOKEN} conan upload <package-name>/0.1@<group-name>+<project-name>/stable --all --remote=gitlab
  environment: production
```

CIファイルの基盤として使用する追加のConanイメージは、[Conanドキュメント](https://docs.conan.io/en/latest/howtos/run_conan_in_docker.html#available-docker-images)で入手できます。

### 同じレシピでパッケージを再公開する {#re-publishing-a-package-with-the-same-recipe}

既存のパッケージと同じレシピ（`package-name/version@user/channel`）を持つパッケージを公開すると、重複ファイルが正常にアップロードされ、UIからアクセスできます。ただし、パッケージをインストールすると、最後に公開されたパッケージのみが返されます。

## Conanパッケージをインストールする {#install-a-conan-package}

パッケージレジストリからConanパッケージをインストールして、依存関係として使用できるようにします。インスタンスまたはプロジェクトのスコープからパッケージをインストールできます。複数のパッケージのレシピが同じ場合、パッケージをインストールすると、最後に公開されたパッケージが取得されます。

Conanパッケージは、多くの場合、`conanfile.txt`ファイルを使用して依存関係としてインストールされます。

前提要件: 

- Conanリモート[を設定する](#add-the-package-registry-as-a-conan-remote)必要があります。
- プライベートプロジェクトと内部プロジェクトの場合は、パッケージレジストリで[認証](#authenticate-to-the-package-registry)を設定する必要があります。

1. 依存関係としてパッケージをインストールするプロジェクトで、`conanfile.txt`を開きます。または、プロジェクトのルートで、`conanfile.txt`という名前のファイルを作成します。

1. Conanレシピをファイルの`[requires]`セクションに追加します:

   ```plaintext
   [requires]
   Hello/0.1@mycompany/beta

   [generators]
   cmake
   ```

1. プロジェクトのルートで、`build`ディレクトリを作成し、そのディレクトリに変更します:

   ```shell
   mkdir build && cd build
   ```

1. `conanfile.txt`にリストされている依存関係をインストールします:

   ```shell
   conan install .. <options>
   ```

{{< alert type="note" >}}

このチュートリアルで作成したパッケージをインストールしようとすると、パッケージが既に存在するため、インストールコマンドは無効になります。キャッシュに保存されているパッケージをクリーンアップするには、`~/.conan/data`を削除します。

{{< /alert >}}

## Conanパッケージを削除する {#remove-a-conan-package}

GitLabパッケージレジストリからConanパッケージを削除する方法は2つあります。

- コマンドラインから、Conanクライアントを使用する:

  ```shell
  conan remove Hello/0.2@user/channel --remote=gitlab
  ```

  このコマンドにはリモートを明示的に含める必要があります。そうしないと、パッケージはローカルシステムのキャッシュからのみ削除されます。

  {{< alert type="note" >}}

  このコマンドは、すべてのレシピファイルとバイナリパッケージファイルをパッケージレジストリから削除します。

  {{< /alert >}}

- GitLabのユーザーインターフェースから:

  プロジェクトの**デプロイ** > **パッケージレジストリ**に移動します。**リポジトリを削除**（{{< icon name="remove" >}}）を選択して、パッケージを削除します。

## パッケージレジストリでConanパッケージを検索する {#search-for-conan-packages-in-the-package-registry}

パッケージ名の全部または一部、あるいは正確なレシピで検索するには、`conan search`コマンドを実行します。

- 特定のパッケージ名のすべてのパッケージを検索するには:

  ```shell
  conan search Hello --remote=gitlab
  ```

- `He`で始まるすべてのパッケージなど、部分的な名前を検索するには:

  ```shell
  conan search He* --remote=gitlab
  ```

検索のスコープは、Conanリモートの設定によって異なります:

- [インスタンス](#add-a-remote-for-your-instance)用に設定されたリモートがある場合、検索には、アクセス許可を持つすべてのプロジェクトが含まれます。これには、プライベートプロジェクトとすべてのパブリックプロジェクトが含まれます。

- [プロジェクト](#add-a-remote-for-your-project)用に設定されたリモートがある場合、検索には、アクセス許可を持つ限り、ターゲットプロジェクト内のすべてのパッケージが含まれます。

{{< alert type="note" >}}

検索結果の制限は500個のパッケージであり、結果は最後に公開されたパッケージによってソートされます。

{{< /alert >}}

## パッケージレジストリからConanパッケージ情報をフェッチする {#fetch-conan-package-information-from-the-package-registry}

`conan info`コマンドは、パッケージに関する情報を返します:

```shell
conan info Hello/0.1@mycompany/beta
```

## Conanパッケージをダウンロードする {#download-a-conan-package}

{{< alert type="flag" >}}

[Conan情報のメタデータ抽出](#extract-conan-metadata)が有効になる前にアップロードされたパッケージは、`conan download` CLIコマンドでダウンロードできません。

{{< /alert >}}

`conan download`コマンドを使用する設定を使用せずに、Conanパッケージのレシピとバイナリをローカルキャッシュにダウンロードできます。

前提要件: 

- Conanリモート[を設定する](#add-the-package-registry-as-a-conan-remote)必要があります。
- プライベートプロジェクトと内部プロジェクトの場合は、パッケージレジストリで[認証](#authenticate-to-the-package-registry)を設定する必要があります。

### すべてのバイナリパッケージをダウンロードする {#download-all-binary-packages}

パッケージレジストリからレシピに関連付けられているすべてのバイナリパッケージをダウンロードできます。

すべてのバイナリパッケージをダウンロードするには、次のコマンドを実行します:

```shell
conan download Hello/0.1@foo+bar/stable --remote=gitlab
```

### レシピファイルをダウンロードする {#download-recipe-files}

任意のバイナリパッケージなしで、レシピファイルのみをダウンロードできます。

レシピファイルをダウンロードするには、次のコマンドを実行します:

```shell
conan download Hello/0.1@foo+bar/stable --remote=gitlab --recipe
```

### 特定のバイナリパッケージをダウンロードする {#download-a-specific-binary-package}

パッケージ参照（Conanドキュメントでは`package_id`として知られています）を参照することにより、単一のバイナリパッケージをダウンロードできます。

特定のバイナリパッケージをダウンロードするには、次のコマンドを実行します:

```shell
conan download Hello/0.1@foo+bar/stable:<package_reference> --remote=gitlab
```

## サポートされているCLIコマンド {#supported-cli-commands}

GitLab Conanリポジトリは、次のConan CLIコマンドをサポートしています:

- `conan upload`: レシピファイルとパッケージファイルをパッケージレジストリにアップロードします。
- `conan install`: `conanfile.txt`ファイルの使用を含む、パッケージレジストリからConanパッケージをインストールします。
- `conan download`: 設定を使用せずに、パッケージのレシピとバイナリをローカルキャッシュにダウンロードします。
- `conan search`: パッケージレジストリで、パブリックパッケージと、表示する権限のあるプライベートパッケージを検索します。
- `conan info`: パッケージレジストリから特定のパッケージに関する情報を表示します。
- `conan remove`: パッケージレジストリからパッケージを削除します。

## Conanメタデータを抽出する {#extract-conan-metadata}

{{< history >}}

- GitLab 17.10で`parse_conan_metadata_on_upload`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178728)されました。デフォルトでは無効になっています。
- GitLab 17.11[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186292)になりました。機能フラグ`parse_conan_metadata_on_upload`は削除されました。

{{< /history >}}

Conanパッケージをアップロードすると、GitLabは`conaninfo.txt`ファイルからメタデータを自動的に抽出します。このメタデータには、以下が含まれます:

- パッケージ設定（`os`、`arch`、`compiler`、`build_type`など）
- パッケージオプション
- パッケージの要件と依存関係

{{< alert type="note" >}}

この機能が有効になる前にアップロードされたパッケージ（GitLab 17.10）は、メタデータが抽出されていません。これらのパッケージでは、一部の検索機能とダウンロード機能が制限されています。

{{< /alert >}}

## Conanリバージョン {#conan-revisions}

{{< history >}}

- GitLab 18.1で`conan_package_revisions_support`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519741)されました。デフォルトでは無効になっています。
- GitLab 18.3の[GitLab.comで有効](https://gitlab.com/groups/gitlab-org/-/epics/14896)になりました。機能フラグ`conan_package_revisions_support`は削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="note" >}}

Conan 1のリビジョンは、リモートが[プロジェクト](#add-a-remote-for-your-project)に設定されている場合にのみサポートされ、[インスタンス](#add-a-remote-for-your-instance)全体ではサポートされません。

{{< /alert >}}

Conan 1のリバージョンは、パッケージレジストリでパッケージの不変性を提供します。バージョンを変更せずにレシピまたはそのコードに変更を加えると、Conanは、これらの変更を追跡するための固有識別子（リバージョン）を計算します。

### リバージョンのタイプ {#types-of-revisions}

Conanは、次の2種類のリバージョンを使用します:

- **Recipe revisions (RREV)**（レシピのリバージョン（RREV））: レシピがエクスポートされるときに生成されます。デフォルトでは、Conanはレシピのマニフェストのチェックサムハッシュを使用してレシピのリバージョンを計算します。
- **Package revisions (PREV)**（パッケージのリバージョン（PREV））: パッケージがビルドされるときに生成されます。Conanは、パッケージコンテンツのハッシュを使用してパッケージのリバージョンを計算します。

### リバージョンを有効にする {#enable-revisions}

Conan 1.xでは、リバージョンはデフォルトでは有効になっていません。リバージョンを有効にするには、次のいずれかを行う必要があります:

- `_conan.conf_`ファイルの`[general]`セクションに`revisions_enabled=1`を追加します（推奨）。
- `CONAN_REVISIONS_ENABLED=1`環境変数を設定します。

### 参照リバージョン {#reference-revisions}

次の形式でパッケージを参照できます:

| 参照                                          | 説明                                                       |
| -------------------------------------------------- | ----------------------------------------------------------------- |
| `lib/1.0@conan/stable`                             | `lib/1.0@conan/stable`の最新のRREV。                       |
| `lib/1.0@conan/stable#RREV`                        | `lib/1.0@conan/stable`の特定RREV。                     |
| `lib/1.0@conan/stable#RREV:PACKAGE_REFERENCE`      | 特定のRREVに属するバイナリパッケージ。               |
| `lib/1.0@conan/stable#RREV:PACKAGE_REFERENCE#PREV` | 特定のRREVに属するバイナリパッケージのリバージョンPREV。 |

### リバージョンをアップロードする {#upload-revisions}

すべてのリバージョンとそのバイナリをGitLabパッケージレジストリにアップロードするには:

```shell
conan upload package_name/version@user/channel#* --all --remote=gitlab
```

複数のリバージョンをアップロードすると、古いものから新しいものへとアップロードされます。相対的な順序はレジストリに保持されます。

### リバージョンを検索する {#search-for-revisions}

Conan v1で特定のレシピのすべてのリバージョンを検索するには:

```shell
conan search package_name/version@user/channel --revisions --remote=gitlab
```

このコマンドは、指定されたレシピで使用可能なすべてのリビジョンを、そのリビジョンのハッシュおよび作成日とともに表示します。

特定のリビジョンの詳細情報を取得するには:

```shell
conan search package_name/version@user/channel#revision_hash --remote=gitlab
```

このコマンドは、そのリビジョンで使用可能な特定のパッケージのバイナリを表示します。

### リビジョンを使用してパッケージを削除します {#delete-packages-with-revisions}

異なる粒度レベルでパッケージを削除できます:

#### 特定レシピリビジョンを削除します {#delete-a-specific-recipe-revision}

特定のレシピリビジョンとそれに関連するすべてのバイナリパッケージを削除するには:

```shell
conan remove package_name/version@user/channel#revision_hash --remote=gitlab
```

#### 特定レシピリビジョンのパッケージを削除します {#delete-packages-for-a-specific-recipe-revision}

特定レシピリビジョンに関連付けられているすべてのパッケージを削除するには:

```shell
conan remove package_name/version@user/channel#revision_hash --packages --remote=gitlab
```

#### リビジョンで特定のパッケージを削除します {#delete-a-specific-package-in-a-revision}

リビジョンで特定のパッケージを削除するには、次のいずれかのコマンドを使用します:

```shell
conan remove package_name/version@user/channel#revision_hash -p package_id --remote=gitlab
```

または:

```shell
conan remove package_name/version@user/channel#revision_hash:package_id --remote=gitlab
```

{{< alert type="note" >}}

リビジョンでパッケージを削除する場合は、`--remote=gitlab`フラグを含める必要があります。そうしないと、パッケージはお使いのローカルシステムのキャッシュからのみ削除されます。

{{< /alert >}}

### イミュータブルなリビジョンのワークフロー {#immutable-revisions-workflow}

リビジョンはイミュータブルになるように設計されています。レシピまたはそのコードを変更する場合:

- レシピをエクスポートすると、新しいレシピリビジョンが作成されます。
- 以前のレシピリビジョンに属する既存のバイナリは含まれません。新しいレシピリビジョンのために、新しいバイナリをビルド必要があります。
- パッケージをインストールすると、リビジョンを指定しない限り、Conanは自動的に最新のリビジョンを取得します。

パッケージのバイナリの場合、レシピリビジョンおよびパッケージ参照（Conanドキュメントでは`package_id`として知られています）ごとに1つのパッケージリビジョンのみを含める必要があります。同じレシピリビジョンとパッケージIDに対する複数のパッケージリビジョンは、パッケージが不必要にリビルドされたことを示しています。

## トラブルシューティング {#troubleshooting}

### 出力を冗長にする {#make-output-verbose}

Conanのイシューをトラブルシューティングする際に、より詳細な出力を行うには:

```shell
export CONAN_TRACE_FILE=/tmp/conan_trace.log # Or SET in windows
conan <command>
```

その他のログに関するヒントは、[Conanドキュメント](https://docs.conan.io/en/latest/mastering/logging.html)にあります。

### SSLエラー {#ssl-errors}

自己署名証明書を使用している場合、ConanでSSLエラーを管理する方法は2つあります:

- `conan remote`コマンドを使用して、SSL検証を無効にします。
- サーバーの`crt`ファイルを`cacert.pem`ファイルに追加します。

詳細については、[Conanドキュメント](https://docs.conan.io/en/latest/howtos/use_tls_certificates.html)をお読みください。
