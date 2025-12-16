---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan 2パッケージレジストリ内のパッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.1で`conan_package_revisions_support`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519741)されました。デフォルトでは無効になっています。
- GitLab 18.3の[GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14896)で有効になりました。機能フラグ`conan_package_revisions_support`は削除されました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="warning" >}}

GitLabのConan 2パッケージレジストリは開発中であり、機能が限られているため、本番環境での使用には適していません。この[エピック](https://gitlab.com/groups/gitlab-org/-/epics/8258)では、本番環境で使用できるようになるまでの残りの作業とタイムラインについて詳しく説明します。

{{< /alert >}}

{{< alert type="note" >}}

Conan 2レジストリはFIPSに準拠しておらず、FIPSモードが有効になっている場合は無効になります。

{{< /alert >}}

プロジェクトのパッケージパッケージレジストリにConan 2パッケージを公開します。これにより、依存関係として使用する必要がある場合に、いつでもパッケージをインストールできるようになります。

GitLabパッケージレジストリにConan 2パッケージを公開するには、パッケージレジストリをリモートとして追加し、認証します。

次に、`conan`コマンドを実行して、パッケージレジストリにパッケージを公開できます。

Conan 2パッケージマネージャークライアントが使用する特定のAPIエンドポイントのドキュメントについては、[Conan v2 API](../../../api/packages/conan_v2.md)を参照してください

[Conan 2パッケージのビルド方法](../workflows/build_packages.md#conan-2)について説明します。

## パッケージレジストリをConanリモートとして追加する {#add-the-package-registry-as-a-conan-remote}

`conan`コマンドを実行するには、プロジェクトまたはインスタンスのConanリモートとしてパッケージレジストリを追加する必要があります。次に、パッケージレジストリとの間でパッケージを公開およびインストールできます。

### プロジェクトのリモートを追加する {#add-a-remote-for-your-project}

すべてのコマンドでリモート名を指定しなくても、プロジェクト内のパッケージを操作できるように、リモートを設定します。

プロジェクトのリモートを設定する場合、パッケージ名は小文字にする必要があります。また、コマンドには、ユーザー名とチャンネルを含む完全なレシピを含める必要があります（例: `package_name/version@user/channel`）。

リモートを追加するには:

1. ターミナルで、次のコマンドを実行します:

   ```shell
   conan remote add gitlab https://gitlab.example.com/api/v4/projects/<project_id>/packages/conan
   ```

1. Conan 2コマンドの最後に`--remote=gitlab`を追加して、リモートを使用します。

   例: 

   ```shell
   conan search hello* --remote=gitlab
   ```

## パッケージレジストリに対して認証する {#authenticate-to-the-package-registry}

GitLabでは、パッケージのアップロード、およびプライベートプロジェクトと内部プロジェクトからのパッケージのインストールには、認証が必要です。（ただし、認証なしでパブリックプロジェクトからパッケージをインストールできます）。

パッケージレジストリに認証するには、次のいずれかが必要です:

- スコープが`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
- スコープが`read_package_registry`と`write_package_registry`のどちらか、または両方に設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。
- [CIジョブトークン](#publish-a-conan-2-package-by-using-cicd)。

{{< alert type="note" >}}

認証されていない場合、プライベートプロジェクトと内部プロジェクトからのパッケージは非表示になります。認証なしでプライベートプロジェクトまたは内部プロジェクトからパッケージを検索またはダウンロードしようとすると、Conan 2クライアントでエラー`unable to find the package in remote`が表示されます。

{{< /alert >}}

### GitLabリモートに認証情報を追加する {#add-your-credentials-to-the-gitlab-remote}

すべてのConan 2コマンドにトークンを明示的に追加する必要がないように、GitLabリモートにトークンを関連付けます。

前提要件: 

- 認証トークンが必要です。
- Conanリモート[が構成されている](#add-the-package-registry-as-a-conan-remote)必要があります。

ターミナルで、次のコマンドを実行します。この例では、リモート名は`gitlab`です。リモートの名前を使用します。

```shell
conan remote login -p <personal_access_token or deploy_token> gitlab <gitlab_username or deploy_token_username>
```

`--remote=gitlab`でコマンドを実行すると、リクエストにユーザー名とパスワードが含まれるようになります。

{{< alert type="note" >}}

GitLabでの認証は定期的に期限切れになるため、パーソナルアクセストークンの再入力が必要になる場合があります。

{{< /alert >}}

## Conan 2パッケージを公開する {#publish-a-conan-2-package}

GitLabパッケージレジストリにConan 2パッケージを公開して、プロジェクトにアクセスできるすべてのユーザーが依存関係としてパッケージを使用できるようにします。

前提要件: 

- Conanリモート[が構成されている](#add-the-package-registry-as-a-conan-remote)必要があります。
- パッケージレジストリでの[認証](#authenticate-to-the-package-registry)を構成する必要があります。
- ローカル[Conan 2パッケージ](../workflows/build_packages.md#conan-2)が存在する必要があります。
- [プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)に表示されるプロジェクトIDが必要です。

パッケージを公開するには、`conan upload`コマンドを使用します:

```shell
conan upload hello/0.1@mycompany/beta -r gitlab
```

## CI/CDを使用してConan 2パッケージを公開する {#publish-a-conan-2-package-by-using-cicd}

[GitLab CI/CD](../../../ci/_index.md)でConan 2コマンドを使用するには、コマンドでパーソナルアクセストークンの代わりに`CI_JOB_TOKEN`を使用できます。

`.gitlab-ci.yml`ファイル内の各Conanコマンドで`CONAN_LOGIN_USERNAME`および`CONAN_PASSWORD`を指定できます。例: 

```yaml
create_package:
  image: <conan 2 image>
  stage: deploy
  script:
    - conan remote add gitlab ${CI_API_V4_URL}/projects/$CI_PROJECT_ID/packages/conan
    - conan new <package-name>/0.1
    - conan create . --channel=stable --user=mycompany
    - CONAN_LOGIN_USERNAME=ci_user CONAN_PASSWORD=${CI_JOB_TOKEN} conan upload <package-name>/0.1@mycompany/stable --remote=gitlab
  environment: production
```

CIファイルのベースとして使用する適切なConan 2イメージを作成するには、[公式ガイド](https://docs.conan.io/2.17/examples/runners/docker/basic.html)に従ってください。

### 同じレシピでパッケージを再公開する {#re-publishing-a-package-with-the-same-recipe}

既存のパッケージと同じレシピ（`package-name/version@user/channel`）を持つパッケージを公開すると、Conanはそれらが既にサーバーにあるため、アップロードをスキップします。

## Conan 2パッケージをインストールする {#install-a-conan-2-package}

依存関係として使用できるように、パッケージレジストリからConan 2パッケージをインストールします。プロジェクトのスコープからパッケージをインストールできます。複数のパッケージが同じレシピを持つ場合、パッケージをインストールすると、最後に公開されたパッケージが取得されます。

Conan 2パッケージは、多くの場合、`conanfile.txt`ファイルを使用して依存関係としてインストールされます。

前提要件: 

- Conanリモート[が構成されている](#add-the-package-registry-as-a-conan-remote)必要があります。
- プライベートプロジェクトと内部プロジェクトの場合は、パッケージレジストリで[認証](#authenticate-to-the-package-registry)を構成する必要があります。

1. [Conan 2パッケージ](../workflows/build_packages.md#conan-2)ガイドに従って、別のパッケージを作成します。プロジェクトのルートで、`conanfile.txt`という名前のファイルを作成します。

1. Conanレシピをファイルの`[requires]`セクションに追加します:

   ```plaintext
   [requires]
   hello/0.1@mycompany/beta
   ```

1. プロジェクトのルートに`build`ディレクトリを作成し、そのディレクトリに移動します:

   ```shell
   mkdir build && cd build
   ```

1. `conanfile.txt`にリストされている依存関係をインストールします:

   ```shell
   conan install ../conanfile.txt
   ```

{{< alert type="note" >}}

このチュートリアルで作成したパッケージをインストールしようとすると、パッケージが既に存在するため、インストールコマンドは無効になります。既存のパッケージをローカルで削除してから、再試行するには、このコマンドを使用します:

```shell
conan remove hello/0.1@mycompany/beta
```

{{< /alert >}}

## Conan 2パッケージを削除する {#remove-a-conan-2-package}

GitLabパッケージレジストリからConan 2パッケージを削除するには、2つの方法があります。

- コマンドラインから、Conan 2クライアントを使用します:

  ```shell
  conan remove hello/0.1@mycompany/beta --remote=gitlab
  ```

  それ以外の場合、パッケージはお客様のローカルシステムのキャッシュからのみ削除されるため、このコマンドにはリモートを明示的に含める必要があります。

  {{< alert type="note" >}}

  このコマンドは、すべてのレシピとバイナリパッケージファイルをパッケージレジストリから削除します。

  {{< /alert >}}

- GitLabユーザーインターフェースから:

  プロジェクトの**デプロイ** > **パッケージレジストリ**に移動します。**リポジトリを削除** ({{< icon name="remove" >}})を選択して、パッケージを削除します。

## パッケージレジストリでConan 2パッケージを検索する {#search-for-conan-2-packages-in-the-package-registry}

パッケージ名の一部または全部、あるいは正確なレシピで検索するには、`conan search`コマンドを実行します。

- 特定のパッケージ名を持つすべてのパッケージを検索するには:

  ```shell
  conan search hello --remote=gitlab
  ```

- `he`で始まるすべてのパッケージのように、部分的な名前を検索するには:

  ```shell
  conan search "he*" --remote=gitlab
  ```

検索のスコープは、Conanリモート構成によって異なります。アクセス許可がある限り、検索にはターゲットプロジェクト内のすべてのパッケージが含まれます。

{{< alert type="note" >}}

検索結果の上限は500個のパッケージであり、結果は最も新しく公開されたパッケージ順にソートされます。

{{< /alert >}}

## Conan 2パッケージをダウンロードする {#download-a-conan-2-package}

`conan download`コマンドを使用する設定を使用せずに、Conan 2パッケージのレシピとバイナリをローカルキャッシュにダウンロードできます。

前提要件: 

- Conanリモート[が構成されている](#add-the-package-registry-as-a-conan-remote)必要があります。
- プライベートプロジェクトと内部プロジェクトの場合は、パッケージレジストリで[認証](#authenticate-to-the-package-registry)を構成する必要があります。

### すべてのバイナリパッケージをダウンロードする {#download-all-binary-packages}

パッケージレジストリから、レシピに関連付けられているすべてのバイナリパッケージをダウンロードできます。

すべてのバイナリパッケージをダウンロードするには、次のコマンドを実行します:

```shell
conan download hello/0.1@mycompany/beta --remote=gitlab
```

### レシピファイルをダウンロードする {#download-recipe-files}

任意のバイナリパッケージなしで、レシピファイルのみをダウンロードできます。

レシピファイルをダウンロードするには、次のコマンドを実行します:

```shell
conan download hello/0.1@mycompany/beta --remote=gitlab --only-recipe
```

### 特定のバイナリパッケージをダウンロードする {#download-a-specific-binary-package}

そのパッケージ参照（Conan 2ドキュメントでは`package_id`と呼ばれます）を参照して、単一のバイナリパッケージをダウンロードできます。

特定のバイナリパッケージをダウンロードするには、次のコマンドを実行します:

```shell
conan download Hello/0.1@foo+bar/stable:<package_reference> --remote=gitlab
```

## サポートされているCLIコマンド {#supported-cli-commands}

GitLab Conanリポジトリは、次のConan 2 CLIコマンドをサポートしています:

- `conan upload`: お客様のレシピとパッケージファイルをパッケージレジストリにアップロードします。
- `conan install`: `conanfile.txt`ファイルの使用を含め、パッケージレジストリからConan 2パッケージをインストールします。
- `conan download`: 設定を使用せずに、パッケージレシピとバイナリをローカルキャッシュにダウンロードします。
- `conan search`: パブリックパッケージ、および表示する権限があるプライベートパッケージについて、パッケージレジストリを検索します。
- `conan list`: 既存のレシピ、リビジョン、またはパッケージをリストします。
- `conan remove`: パッケージレジストリからパッケージを削除します。

## Conanリビジョン {#conan-revisions}

Conanリビジョンは、パッケージレジストリにパッケージの不変性を提供します。バージョンを変更せずにレシピまたはパッケージに変更を加えると、Conanはこれらの変更を追跡するための一意の識別子（リビジョン）を計算します。

### リビジョンの種類 {#types-of-revisions}

Conanは、次の2つの種類のリビジョンを使用します:

- **Recipe revisions (RREV)**（レシピリビジョン（RREV））: レシピがエクスポートされるときに生成されます。デフォルトでは、Conanはレシピマニフェストのチェックサムハッシュを使用してレシピリビジョンを計算します。
- **Package revisions (PREV)**（パッケージリビジョン（PREV））: パッケージのビルド時に生成されます。Conanは、パッケージコンテンツのハッシュを使用してパッケージリビジョンを計算します。

### 参照リビジョン {#reference-revisions}

次の形式でパッケージを参照できます:

| 参照 | 説明 |
| --- | --- |
| `lib/1.0@conan/stable` | `lib/1.0@conan/stable`の最新のRREV。 |
| `lib/1.0@conan/stable#RREV` | `lib/1.0@conan/stable`の特定RREV。 |
| `lib/1.0@conan/stable#RREV:PACKAGE_REFERENCE` | 特定のRREVに属するバイナリパッケージ。 |
| `lib/1.0@conan/stable#RREV:PACKAGE_REFERENCE#PREV` | 特定のRREVに属するバイナリパッケージリビジョンPREV。 |

### リビジョンをアップロードする {#upload-revisions}

すべてのリビジョンとそのバイナリをGitLabパッケージレジストリにアップロードするには:

```shell
conan upload "hello/0.1@mycompany/beta#*" --remote=gitlab
```

複数のリビジョンをアップロードすると、最も古いリビジョンから最新のリビジョンへアップロードされます。相対的な順序はレジストリに保持されます。

### リビジョンを一覧表示する {#list-revisions}

Conan 2で特定のレシピのすべてのリビジョンをリストするには:

```shell
conan list "hello/0.1@mycompany/beta#*" --remote=gitlab
```

このコマンドは、指定されたレシピで使用可能なすべてのリビジョンを、リビジョンハッシュおよび作成日とともに表示します。

特定のリビジョンの詳細情報を取得するには:

```shell
conan list "hello/0.1@mycompany/beta#revision_hash:*#*" --remote=gitlab
```

このコマンドは、特定のリビジョンで使用可能な特定のバイナリパッケージとパッケージリビジョンを示します。

### リビジョンを使用してパッケージを削除する {#delete-packages-with-revisions}

さまざまなレベルの粒度でパッケージを削除できます:

#### 特定レシピのリビジョンを削除する {#delete-a-specific-recipe-revision}

特定レシピのリビジョンとそれに関連付けられているすべてのバイナリパッケージを削除するには:

```shell
conan remove "hello/0.1@mycompany/beta#revision_hash" --remote=gitlab
```

#### 特定レシピのリビジョンのパッケージを削除する {#delete-packages-for-a-specific-recipe-revision}

特定レシピのリビジョンに関連付けられているすべてのパッケージを削除するには:

```shell
conan remove "hello/0.1@mycompany/beta#revision_hash:*" --remote=gitlab
```

#### リビジョンで特定のパッケージを削除する {#delete-a-specific-package-in-a-revision}

レシピリビジョンの特定のパッケージを削除するには、次を使用します:

```shell
conan remove "package_name/version@user/channel#revision_hash:package_id" --remote=gitlab
```

### イミュータブルなリビジョンのワークフロー {#immutable-revisions-workflow}

リビジョンはイミュータブルであるように設計されています。レシピまたはそのコードを変更する場合:

- レシピをエクスポートすると、新しいレシピリビジョンが作成されます。
- 以前のレシピリビジョンに属する既存のバイナリは含まれていません。新しいレシピリビジョンの新しいバイナリをビルドする必要があります。
- パッケージをインストールすると、リビジョンを指定しない限り、Conan 2は自動的に最新のリビジョン取得します。

パッケージバイナリの場合、レシピリビジョンおよびパッケージ参照ごとに1つのパッケージリビジョンのみを含める必要があります（Conan 2ドキュメントでは`package_id`と呼ばれます）。同じレシピリビジョンとパッケージIDの複数のパッケージリビジョンは、パッケージが不必要に再ビルドされたことを示します。
