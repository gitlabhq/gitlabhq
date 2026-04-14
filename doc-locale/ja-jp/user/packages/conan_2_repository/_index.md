---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パッケージレジストリ内のConan 2パッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.1で`conan_package_revisions_support`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519741)されました。デフォルトでは無効になっています。
- GitLab 18.3で[GitLab.comで有効化](https://gitlab.com/groups/gitlab-org/-/epics/14896)されました。機能フラグ`conan_package_revisions_support`は削除されました。

{{< /history >}}

> [!flag]
> この機能の可用性は機能フラグによって制御されます。詳細については、履歴を参照してください。

プロジェクトのパッケージレジストリにConan 2パッケージを公開します。これにより、依存関係として使用する必要がある場合に、いつでもパッケージをインストールできるようになります。

> [!warning]
> GitLab用のConan 2パッケージレジストリは開発中であり、機能が限られているため、本番環境での使用には適していません。この[エピック](https://gitlab.com/groups/gitlab-org/-/epics/8258)では、本番環境で使用できるようになるまでの残りの作業とタイムラインについて詳しく説明します。

Conan 2パッケージをパッケージレジストリに公開するには、パッケージレジストリをリモートとして追加し、それに認証する必要があります。

その後、`conan`コマンドを実行して、パッケージをパッケージレジストリに公開できます。

> [!note]
> ConanレジストリはFIPSに準拠しておらず、FIPSモードが有効になっている場合は無効になります。

Conan 2パッケージマネージャークライアントが使用する特定のAPIエンドポイントのドキュメントについては、[Conan v2 API](../../../api/packages/conan_v2.md)を参照してください。

Conan 2パッケージを[ビルドする](../workflows/build_packages.md#conan-2)方法を学びます。

## Conanリモートとしてパッケージレジストリを追加 {#add-the-package-registry-as-a-conan-remote}

`conan`コマンドを実行するには、パッケージレジストリをプロジェクトまたはインスタンス用のConanリモートとして追加する必要があります。その後、パッケージレジストリに対してパッケージを公開したり、パッケージをインストールしたりできます。

### プロジェクトのリモートを追加 {#add-a-remote-for-your-project}

リモートを設定すると、すべてのコマンドでリモート名を指定することなく、プロジェクト内のパッケージを操作できます。

プロジェクトのリモートを設定する場合、パッケージ名は小文字にする必要があります。また、コマンドには、ユーザーとチャンネルを含む完全なレシピ（例: `package_name/version@user/channel`）を含める必要があります。

リモートを追加するには:

1. お使いのターミナルで、このコマンドを実行してください:

   ```shell
   conan remote add gitlab https://gitlab.example.com/api/v4/projects/<project_id>/packages/conan
   ```

1. Conan 2コマンドの末尾に`--remote=gitlab`を追加してリモートを使用します。

   例: 

   ```shell
   conan search hello* --remote=gitlab
   ```

## パッケージレジストリに対して認証する {#authenticate-to-the-package-registry}

GitLabでは、パッケージのアップロード、およびプライベートまたは内部プロジェクトからのパッケージのインストールに認証が必要です。(ただし、公開プロジェクトからのパッケージは認証なしでインストールできます。)

パッケージレジストリに認証するには、次のいずれかが必要です:

- スコープが`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
- スコープが`read_package_registry`と`write_package_registry`のどちらか、または両方に設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。
- [CIジョブトークン](#publish-a-conan-2-package-by-using-cicd)。

> [!note]
> 認証されていない場合、プライベートおよび内部プロジェクトのパッケージは非表示になります。プライベートまたは内部プロジェクトのパッケージを認証せずに検索またはダウンロードしようとすると、Conan 2クライアントでエラー`unable to find the package in remote`が表示されます。

### GitLabリモートに認証情報を追加 {#add-your-credentials-to-the-gitlab-remote}

あなたのトークンをGitLabリモートと関連付けることで、すべてのConan 2コマンドにトークンを明示的に追加する必要がなくなります。

前提条件: 

- あなたは認証トークンを持っている必要があります。
- Conanリモートは[設定されている](#add-the-package-registry-as-a-conan-remote)必要があります。

ターミナルで、このコマンドを実行してください。この例では、リモート名は`gitlab`です。リモートの名前を使用してください。

```shell
conan remote login -p <personal_access_token or deploy_token> gitlab <gitlab_username or deploy_token_username>
```

これで、`--remote=gitlab`を使用してコマンドを実行すると、あなたのユーザー名とパスワードがリクエストに含まれるようになります。

> [!note]
> GitLabでの認証は定期的に期限切れになるため、時々パーソナルアクセストークンを再入力する必要がある場合があります。

## Conan 2パッケージを公開する {#publish-a-conan-2-package}

プロジェクトにアクセスできる誰もがパッケージを依存として使用できるように、Conan 2パッケージをパッケージレジストリに公開します。

前提条件: 

- Conanリモートは[設定されている](#add-the-package-registry-as-a-conan-remote)必要があります。
- パッケージレジストリでの[認証](#authenticate-to-the-package-registry)を設定する必要があります。
- ローカルの[Conan 2パッケージ](../workflows/build_packages.md#conan-2)が存在する必要があります。
- プロジェクトIDを持っている必要があります。これは[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)に表示されます。

パッケージを公開するには、`conan upload`コマンドを使用します:

```shell
conan upload hello/0.1@mycompany/beta -r gitlab
```

## CI/CDを使用してConan 2パッケージを公開する {#publish-a-conan-2-package-by-using-cicd}

[GitLab CI/CD](../../../ci/_index.md)でConan 2コマンドを操作するには、コマンド内でパーソナルアクセストークンの代わりに`CI_JOB_TOKEN`を使用できます。

各Conanコマンドとともに`CONAN_LOGIN_USERNAME`と`CONAN_PASSWORD`を`.gitlab-ci.yml`ファイルに指定できます。例: 

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

[公式ガイド](https://docs.conan.io/2.17/examples/runners/docker/basic.html)に従って、CIファイルのベースとして使用する適切なConan 2イメージを作成してください。

### 同じレシピのパッケージを再公開する {#re-publishing-a-package-with-the-same-recipe}

既存のパッケージと同じレシピ（`package-name/version@user/channel`）を持つパッケージを公開すると、Conanはすでにサーバーに存在するためアップロードをスキップします。

## Conan 2パッケージをインストールする {#install-a-conan-2-package}

Conan 2パッケージをパッケージレジストリからインストールすると、それを依存として使用できます。プロジェクトのスコープからパッケージをインストールできます。複数のパッケージが同じレシピを持つ場合、パッケージをインストールすると、最も最近公開されたパッケージが取得するされます。

Conan 2パッケージは、`conanfile.txt`ファイルを使用して依存としてインストールされることがよくあります。

前提条件: 

- Conanリモートは[設定されている](#add-the-package-registry-as-a-conan-remote)必要があります。
- プライベートおよび内部プロジェクトの場合、パッケージレジストリでの[認証](#authenticate-to-the-package-registry)を設定する必要があります。

1. [Conan 2パッケージ](../workflows/build_packages.md#conan-2)ガイドに従って、別のパッケージを作成してください。プロジェクトのルートに、`conanfile.txt`というファイルを作成します。

1. Conanレシピをファイルの`[requires]`セクションに追加します:

   ```plaintext
   [requires]
   hello/0.1@mycompany/beta
   ```

1. プロジェクトのルートに`build`ディレクトリを作成し、そのディレクトリに移動します:

   ```shell
   mkdir build && cd build
   ```

1. `conanfile.txt`にリストされている依存をインストールします:

   ```shell
   conan install ../conanfile.txt
   ```

> [!note]
> このチュートリアルで作成したパッケージをインストールしようとしても、そのパッケージはすでに存在するため、インストールコマンドは効果がありません。このコマンドを使用して、既存のパッケージをローカルで削除してから、もう一度試してください:
>
> ```shell
> conan remove hello/0.1@mycompany/beta
> ```

## Conan 2パッケージを削除する {#remove-a-conan-2-package}

GitLabパッケージレジストリからConan 2パッケージを削除するには、2つの方法があります。

- コマンドラインから、Conan 2クライアントを使用:

  ```shell
  conan remove hello/0.1@mycompany/beta --remote=gitlab
  ```

  このコマンドにはリモートを明示的に含める必要があります。そうしないと、パッケージはローカルシステムキャッシュからのみ削除されます。

  > [!note]
  > このコマンドは、すべてのレシピおよびバイナリパッケージファイルをパッケージレジストリから削除します。

- GitLabユーザーインターフェースから:

  プロジェクトの**デプロイ** > **パッケージレジストリ**に移動します。パッケージを、**リポジトリを削除** ({{< icon name="remove" >}}) を選択して削除します。

## パッケージレジストリでConan 2パッケージを検索する {#search-for-conan-2-packages-in-the-package-registry}

完全または部分的なパッケージ名、または正確なレシピで検索するには、`conan search`コマンドを実行します。

- 特定のパッケージ名を持つすべてのパッケージを検索するには:

  ```shell
  conan search hello --remote=gitlab
  ```

- 部分名（例: `he`で始まるすべてのパッケージ）で検索するには:

  ```shell
  conan search "he*" --remote=gitlab
  ```

検索のスコープは、Conanリモートの設定によって異なります。アクセス権限がある限り、検索にはターゲットプロジェクト内のすべてのパッケージが含まれます。

検索結果の制限は500パッケージで、結果は最も最近公開されたパッケージによってソートされます。

> [!note]
> パッケージを検索する場合、Conan v2 CLIは、Conan v2でアップロードされたパッケージの詳細のみを表示します。Conan v1でアップロードされたパッケージは検索結果に表示されますが、その詳細は表示されません。これは、Conan v2が`recipe_hash`フィールドのないパッケージ参照を期待しているためです。このフィールドはConan v1でアップロードされたパッケージには存在します。

## Conan 2パッケージをダウンロードする {#download-a-conan-2-package}

Conan 2パッケージのレシピとバイナリを、`conan download`コマンドを使用する設定なしでローカルキャッシュにダウンロードできます。

前提条件: 

- Conanリモートは[設定されている](#add-the-package-registry-as-a-conan-remote)必要があります。
- プライベートおよび内部プロジェクトの場合、パッケージレジストリでの[認証](#authenticate-to-the-package-registry)を設定する必要があります。

### すべてのバイナリパッケージをダウンロードする {#download-all-binary-packages}

パッケージレジストリから、レシピに関連付けられたすべてのバイナリパッケージをダウンロードできます。

すべてのバイナリパッケージをダウンロードするには、次のコマンドを実行してください:

```shell
conan download hello/0.1@mycompany/beta --remote=gitlab
```

### レシピファイルをダウンロードする {#download-recipe-files}

バイナリパッケージなしでレシピファイルのみをダウンロードできます。

レシピファイルをダウンロードするには、次のコマンドを実行してください:

```shell
conan download hello/0.1@mycompany/beta --remote=gitlab --only-recipe
```

### 特定のバイナリパッケージをダウンロードする {#download-a-specific-binary-package}

パッケージ参照（Conan 2のドキュメントでは`package_id`として知られています）を参照することで、単一のバイナリパッケージをダウンロードできます。

特定のバイナリパッケージをダウンロードするには、次のコマンドを実行してください:

```shell
conan download Hello/0.1@foo+bar/stable:<package_reference> --remote=gitlab
```

## サポートされているCLIコマンド {#supported-cli-commands}

GitLab Conanリポジトリは、次のConan 2 CLIコマンドをサポートしています:

- `conan upload`: レシピとパッケージファイルをパッケージレジストリにアップロードします。
- `conan install`: Conan 2パッケージをパッケージレジストリからインストールします。これには`conanfile.txt`ファイルの使用が含まれます。
- `conan download`: パッケージのレシピとバイナリを、設定を使用せずにローカルキャッシュにダウンロードします。
- `conan search`: 公開パッケージ、および表示権限のあるプライベートパッケージをパッケージレジストリで検索します。
- `conan list`: 既存のレシピ、リビジョン、またはパッケージをリスト表示します。
- `conan remove`: パッケージレジストリからパッケージを削除します。

## Conanリビジョン {#conan-revisions}

Conanリビジョンは、パッケージレジストリでパッケージの不変性を提供します。レシピまたはパッケージをバージョンを変更せずに変更すると、Conanはこれらの変更を追跡するための固有識別子（リビジョン）を計算します。

### リビジョンの種類 {#types-of-revisions}

Conanは2種類のリビジョンを使用します:

- **Recipe revisions (RREV)**: レシピがエクスポートするされるときに生成されます。デフォルトでは、Conanはレシピマニフェストのチェックサムハッシュを使用してレシピリビジョンを計算します。
- **Package revisions (PREV)**リビジョン（PREV）: パッケージがビルドするされるときに生成されます。Conanはパッケージコンテンツのハッシュを使用してパッケージリビジョンを計算します。

### 参照リビジョン {#reference-revisions}

次の形式でパッケージを参照できます:

| 参照 | 説明 |
| --- | --- |
| `lib/1.0@conan/stable` | `lib/1.0@conan/stable`の最新のRREV。 |
| `lib/1.0@conan/stable#RREV` | `lib/1.0@conan/stable`の特定のRREV。 |
| `lib/1.0@conan/stable#RREV:PACKAGE_REFERENCE` | 特定のRREVに属するバイナリパッケージ。 |
| `lib/1.0@conan/stable#RREV:PACKAGE_REFERENCE#PREV` | 特定のRREVに属するバイナリパッケージリビジョンPREV。 |

### リビジョンをアップロードする {#upload-revisions}

すべてのリビジョンとそれらのバイナリをGitLabパッケージレジストリにアップロードするには:

```shell
conan upload "hello/0.1@mycompany/beta#*" --remote=gitlab
```

複数のリビジョンをアップロードすると、古いものから新しいものへとアップロードされます。相対的な順序はレジストリで保持されます。

### リビジョンをリスト表示する {#list-revisions}

Conan 2で特定のレシピのすべてのリビジョンをリスト表示するには:

```shell
conan list "hello/0.1@mycompany/beta#*" --remote=gitlab
```

このコマンドは、指定されたレシピで使用可能なすべてのリビジョンを、リビジョンハッシュと作成日とともに表示します。

特定のリビジョンの詳細情報を取得するには:

```shell
conan list "hello/0.1@mycompany/beta#revision_hash:*#*" --remote=gitlab
```

このコマンドは、特定のバイナリパッケージと、そのリビジョンで利用可能なパッケージリビジョンを表示します。

### リビジョンを持つパッケージを削除する {#delete-packages-with-revisions}

パッケージは、異なる粒度レベルで削除できます:

#### 特定のレシピリビジョンを削除する {#delete-a-specific-recipe-revision}

特定のレシピリビジョンとそれに関連付けられたすべてのバイナリパッケージを削除するには:

```shell
conan remove "hello/0.1@mycompany/beta#revision_hash" --remote=gitlab
```

#### 特定のレシピリビジョンのパッケージを削除する {#delete-packages-for-a-specific-recipe-revision}

特定のレシピリビジョンに関連付けられたすべてのパッケージを削除するには:

```shell
conan remove "hello/0.1@mycompany/beta#revision_hash:*" --remote=gitlab
```

#### リビジョン内の特定のパッケージを削除する {#delete-a-specific-package-in-a-revision}

レシピリビジョン内の特定のパッケージを削除するには、次を使用できます:

```shell
conan remove "package_name/version@user/channel#revision_hash:package_id" --remote=gitlab
```

### イミュータブルなリビジョンワークフロー {#immutable-revisions-workflow}

リビジョンはイミュータブルであるように設計されています。レシピまたはそのソースcodeを修正する場合:

- レシピをエクスポートするすると、新しいレシピリビジョンが作成されます。
- 以前のレシピリビジョンに属する既存のバイナリは含まれません。新しいレシピリビジョン用に新しいバイナリをビルドするする必要があります。
- パッケージをインストールすると、Conan 2はリビジョンを指定しない限り、自動的に最新のリビジョンを取得するします。

パッケージのバイナリの場合、レシピリビジョンおよびパッケージ参照（Conan 2ドキュメントでは`package_id`として知られています）ごとに1つのパッケージリビジョンのみを含める必要があります。同じレシピリビジョンとパッケージIDに対して複数のパッケージリビジョンが存在する場合、そのパッケージが不必要に再ビルドするされたことを示します。
