---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリ内のNuGetパッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトのパッケージレジストリにNuGetパッケージを公開します。すると、依存関係として使用する必要がある場合に、いつでもパッケージをインストールできるようになります。

パッケージレジストリは以下と連携します。

- [NuGet CLI](https://learn.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference)
- [.NET Core CLI](https://learn.microsoft.com/en-us/dotnet/core/tools/)
- [Visual Studio](https://visualstudio.microsoft.com/vs/)

これらのクライアントが使用する特定のAPIエンドポイントのドキュメントについては、[NuGet APIドキュメント](../../../api/packages/nuget.md)を参照してください。

[NuGetをインストール](../workflows/build_packages.md#nuget)する方法を説明します。

## NuGetパッケージにGitLabエンドポイントを使用する

NuGetパッケージにGitLabエンドポイントを使用するには、次のいずれかのオプションを選択します。

- **プロジェクトレベル**: NuGetパッケージが少なく、それらが同じGitLabグループにない場合に使用します。
- **グループレベル**: 同じGitLabグループ内で、異なるプロジェクトに多数のNuGetパッケージがある場合に使用します。

パッケージの[公開](#publish-a-nuget-package)などの一部の機能は、プロジェクトレベルのエンドポイントでのみ使用できます。

指定されたNuGetパッケージ名のバージョンを要求すると、GitLabパッケージレジストリは最大300件の最新バージョンを返します。

ここに記載されている方法以外で認証を行わないようにしてください。ドキュメント化されていない認証方法は、将来削除される可能性があります。

{{< alert type="warning" >}}

NuGetの認証情報の扱いにより、パッケージレジストリはグループレベルのエンドポイントでの匿名リクエストを拒否します。この制限を回避するには、[認証](#add-the-package-registry-as-a-source-for-nuget-packages)を設定します。

{{< /alert >}}

## NuGetパッケージのソースとしてパッケージレジストリを追加する

パッケージをパッケージレジストリに公開およびインストールするには、パッケージのソースとしてパッケージレジストリを追加する必要があります。

前提要件:

- GitLabのユーザー名。
- パーソナルアクセストークンまたはデプロイトークン。リポジトリ認証の場合、
  - [パーソナルアクセストークン](../../profile/personal_access_tokens.md)を生成できます。
    - リポジトリからパッケージをインストールするには、トークンのスコープに`read_api`または`api`を含める必要があります。
    - リポジトリにパッケージを公開するには、トークンのスコープに`api`を含める必要があります。
  - [デプロイトークン](../../project/deploy_tokens/_index.md)を生成できます。
    - リポジトリからパッケージをインストールするには、トークンのスコープに`read_package_registry`を含める必要があります。
    - リポジトリにパッケージを公開するには、トークンのスコープに`write_package_registry`を含める必要があります。
- ソースの名前。
- 使用する[エンドポイントレベル](#use-the-gitlab-endpoint-for-nuget-packages)に応じて、次のいずれかになります。
  - [プロジェクトの概要ページ](../../project/working_with_projects.md#access-a-project-by-using-the-project-id)にあるプロジェクトID。
  - グループのホームページにあるグループID。

NuGetに次の新しいソースを追加できるようになりました。

- [NuGet CLI](#add-a-source-with-the-nuget-cli)
- [Visual Studio](#add-a-source-with-visual-studio)
- [.NET CLI](#add-a-source-with-the-net-cli)
- [設定ファイル](#add-a-source-with-a-configuration-file)
- [Chocolatey CLI](#add-a-source-with-chocolatey-cli)

### NuGet CLIでソースを追加する

#### プロジェクトレベルのエンドポイント

NuGetパッケージをパッケージレジストリに公開するには、プロジェクトレベルのエンドポイントが必要です。プロジェクトからNuGetパッケージをインストールする場合にも、プロジェクトレベルのエンドポイントが必要です。

[プロジェクトレベル](#use-the-gitlab-endpoint-for-nuget-packages)のNuGetエンドポイントを使用するには、次のように`nuget`でパッケージレジストリをソースとして追加します。

```shell
nuget source Add -Name <source_name> -Source "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" -UserName <gitlab_username or deploy_token_username> -Password <gitlab_personal_access_token or deploy_token>
```

- `<source_name>`は、目的のソース名です。

以下に例を示します。

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName carol -Password 12345678asdf
```

#### グループレベルのエンドポイント

グループからNuGetパッケージをインストールするには、グループレベルのエンドポイントを使用します。

[グループレベル](#use-the-gitlab-endpoint-for-nuget-packages)のNuGetエンドポイントを使用するには、次のように`nuget`でパッケージレジストリをソースとして追加します。

```shell
nuget source Add -Name <source_name> -Source "https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/index.json" -UserName <gitlab_username or deploy_token_username> -Password <gitlab_personal_access_token or deploy_token>
```

- `<source_name>`は、目的のソース名です。

以下に例を示します。

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example.com/api/v4/groups/23/-/packages/nuget/index.json" -UserName carol -Password 12345678asdf
```

### Visual Studioでソースを追加する

#### プロジェクトレベルのエンドポイント

NuGetパッケージをパッケージレジストリに公開するには、プロジェクトレベルのエンドポイントが必要です。プロジェクトからNuGetパッケージをインストールする場合にも、プロジェクトレベルのエンドポイントが必要です。

[プロジェクトレベル](#use-the-gitlab-endpoint-for-nuget-packages)のNuGetエンドポイントを使用するには、次のようにVisual Studioでパッケージレジストリをソースとして追加します。

1. [Visual Studio](https://visualstudio.microsoft.com/vs/)を開きます。
1. Windowsでは、**Tools > Options**を選択します。macOSでは、**Visual Studio > Preferences**を選択します。
1. **NuGet**セクションで、**Sources**を選択して、すべてのNuGetソースのリストを表示します。
1. **Add**を選択します。
1. 次のフィールドに入力します。

   - **Name**: ソースの名前。
   - **Source**: `https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json`。ここでは、`<your_project_id>`はプロジェクトID、`gitlab.example.com`はドメイン名です。

1. **Save**を選択します。
1. パッケージにアクセスするときは、**Username**と**Password**を次のように入力する必要があります。

   - **Username**: GitLabのユーザー名またはデプロイトークンのユーザー名。
   - **Password**: パーソナルアクセストークンまたはデプロイトークン。

ソースがリストに表示されます。

警告が表示された場合は、**Source**、**Username**、**Password**が正しいことを確認してください。

#### グループレベルのエンドポイント

グループからパッケージをインストールするには、グループレベルのエンドポイントを使用します。

[グループレベル](#use-the-gitlab-endpoint-for-nuget-packages)のNuGetエンドポイントを使用するには、次のようにVisual Studioでパッケージレジストリをソースとして追加します。

1. [Visual Studio](https://visualstudio.microsoft.com/vs/)を開きます。
1. Windowsでは、**Tools > Options**を選択します。macOSでは、**Visual Studio > Preferences**を選択します。
1. **NuGet**セクションで、**Sources**を選択して、すべてのNuGetソースのリストを表示します。
1. **Add**を選択します。
1. 次のフィールドに入力します。

   - **Name**: ソースの名前。
   - **Source**: `https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/index.json`。ここでは、`<your_group_id>`はグループ ID、`gitlab.example.com`はドメイン名です。

1. **Save**を選択します。
1. パッケージにアクセスするときは、**Username**と**Password**を次のように入力する必要があります。

   - **Username**: GitLabのユーザー名またはデプロイトークンのユーザー名。
   - **Password**: パーソナルアクセストークンまたはデプロイトークン。

ソースがリストに表示されます。

警告が表示された場合は、**Source**、**Username**、**Password**が正しいことを確認してください。

### .NET CLIでソースを追加する

#### プロジェクトレベルのエンドポイント

NuGetパッケージをパッケージレジストリに公開するには、プロジェクトレベルのエンドポイントが必要です。プロジェクトからNuGetパッケージをインストールする場合にも、プロジェクトレベルのエンドポイントが必要です。

[プロジェクトレベル](#use-the-gitlab-endpoint-for-nuget-packages)のNuGetエンドポイントを使用するには、次のように`nuget`でパッケージレジストリをソースとして追加します。

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" --name <source_name> --username <gitlab_username or deploy_token_username> --password <gitlab_personal_access_token or deploy_token>
```

- `<source_name>`は、目的のソース名です。
- オペレーティングシステムによっては、`--store-password-in-clear-text`が必要になる場合があります。

以下に例を示します。

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" --name gitlab --username carol --password 12345678asdf
```

#### グループレベルのエンドポイント

グループからNuGetパッケージをインストールするには、グループレベルのエンドポイントを使用します。

[グループレベル](#use-the-gitlab-endpoint-for-nuget-packages)のNuGetエンドポイントを使用するには、次のように`nuget`でパッケージレジストリをソースとして追加します。

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/index.json" --name <source_name> --username <gitlab_username or deploy_token_username> --password <gitlab_personal_access_token or deploy_token>
```

- `<source_name>`は、目的のソース名です。
- オペレーティングシステムによっては、`--store-password-in-clear-text`が必要になる場合があります。

以下に例を示します。

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/groups/23/-/packages/nuget/index.json" --name gitlab --username carol --password 12345678asdf
```

### 設定ファイルでソースを追加する

#### プロジェクトレベルのエンドポイント

プロジェクトレベルのエンドポイントは次の目的で必要です。

- NuGetパッケージをパッケージレジストリに公開する。
- プロジェクトからNuGetパッケージをインストールします。

.NETのソースとして[プロジェクトレベル](#use-the-gitlab-endpoint-for-nuget-packages)パッケージレジストリを使用するには、次の手順に従います。

1. プロジェクトのルートで、`nuget.config`という名前のファイルを作成します。
1. 次のコンテンツを追加します。

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
    <packageSources>
        <clear />
        <add key="gitlab" value="https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <gitlab>
            <add key="Username" value="%GITLAB_PACKAGE_REGISTRY_USERNAME%" />
            <add key="ClearTextPassword" value="%GITLAB_PACKAGE_REGISTRY_PASSWORD%" />
        </gitlab>
    </packageSourceCredentials>
   </configuration>
   ```

1. 必要な環境変数を設定します。

   ```shell
   export GITLAB_PACKAGE_REGISTRY_USERNAME=<gitlab_username or deploy_token_username>
   export GITLAB_PACKAGE_REGISTRY_PASSWORD=<gitlab_personal_access_token or deploy_token>
   ```

#### グループレベルのエンドポイント

グループからパッケージをインストールするには、グループレベルのエンドポイントを使用します。

.NETのソースとして[グループレベル](#use-the-gitlab-endpoint-for-nuget-packages)パッケージレジストリを使用するには、次の手順に従います。

1. プロジェクトのルートで、`nuget.config`という名前のファイルを作成します。
1. 次のコンテンツを追加します。

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
    <packageSources>
        <clear />
        <add key="gitlab" value="https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <gitlab>
            <add key="Username" value="%GITLAB_PACKAGE_REGISTRY_USERNAME%" />
            <add key="ClearTextPassword" value="%GITLAB_PACKAGE_REGISTRY_PASSWORD%" />
        </gitlab>
    </packageSourceCredentials>
   </configuration>
   ```

1. 必要な環境変数を設定します。

   ```shell
   export GITLAB_PACKAGE_REGISTRY_USERNAME=<gitlab_username or deploy_token_username>
   export GITLAB_PACKAGE_REGISTRY_PASSWORD=<gitlab_personal_access_token or deploy_token>
   ```

### Chocolatey CLIでソースを追加する

Chocolatey CLIを使用してソースフィードを追加できます。Chocolatey CLI v1.xを使用する場合は、NuGet v2ソースフィードのみを追加できます。

#### プロジェクトレベルのエンドポイントを設定する

NuGetパッケージをパッケージレジストリに公開するには、プロジェクトレベルのエンドポイントが必要です。

[プロジェクトレベル](#use-the-gitlab-endpoint-for-nuget-packages)のパッケージレジストリをChocolateyのソースとして使用するには、次の手順に従います。

- 次のように、`choco`でパッケージレジストリをソースとして追加します。

  ```shell
  choco source add -n=gitlab -s "'https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/v2'" -u=<gitlab_username or deploy_token_username> -p=<gitlab_personal_access_token or deploy_token>
  ```

## NuGetパッケージを公開する

前提要件:

- [ソース](#add-the-package-registry-as-a-source-for-nuget-packages)を[プロジェクトレベルのエンドポイント](#use-the-gitlab-endpoint-for-nuget-packages)で設定している。

パッケージを公開する場合、

- GitLab.comのパッケージレジストリには、最大5 GBのコンテンツを保存できます。この制限は、[GitLab Self-Managed向けに設定可能](../../../administration/instance_limits.md#package-registry-limits)です。
- 同じパッケージを同じバージョンで複数回公開すると、連続する各アップロードは個別のファイルとして保存されます。パッケージをインストールすると、GitLabは最新のファイルを提供します。
- GitLabにパッケージを公開しても、プロジェクトのパッケージユーザーインターフェースにはすぐに表示されません。パッケージの処理には最大10分かかる場合があります。

### NuGet CLIでパッケージを公開する

前提要件:

- [NuGet CLIで作成されたNuGetパッケージ](https://learn.microsoft.com/en-us/nuget/create-packages/creating-a-package)。
- [プロジェクトレベルのエンドポイント](#use-the-gitlab-endpoint-for-nuget-packages)を設定している。

次のコマンドを実行してパッケージを公開します。

```shell
nuget push <package_file> -Source <source_name>
```

- `<package_file>`はパッケージのファイル名で、`.nupkg`で終わります。
- `<source_name>`は、[セットアップ中に使用されたソース名](#add-a-source-with-the-nuget-cli)です。

### .NET CLIでパッケージを公開する

{{< history >}}

- `--api-key`を使用したパッケージの公開は、GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/214674)されました。

{{< /history >}}

前提要件:

- [.NET CLIで作成されたNuGetパッケージ](https://learn.microsoft.com/en-us/nuget/create-packages/creating-a-package-dotnet-cli)。
- [プロジェクトレベルのエンドポイント](#use-the-gitlab-endpoint-for-nuget-packages)を設定している。

次のコマンドを実行してパッケージを公開します。

```shell
dotnet nuget push <package_file> --source <source_name>
```

- `<package_file>`はパッケージのファイル名で、`.nupkg`で終わります。
- `<source_name>`は、[セットアップ中に使用されたソース名](#add-a-source-with-the-net-cli)です。

以下に例を示します。

```shell
dotnet nuget push MyPackage.1.0.0.nupkg --source gitlab
```

`username`と`password`の代わりに、`--api-key`オプションを使用してパッケージを公開することもできます。

```shell
dotnet nuget push <package_file> --source <source_url> --api-key <gitlab_personal_access_token, deploy_token or job token>
```

- `<package_file>`はパッケージのファイル名で、`.nupkg`で終わります。
- `<source_url>`はNuGetパッケージレジストリのURLです。

以下に例を示します。

```shell
dotnet nuget push MyPackage.1.0.0.nupkg --source https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/index.json --api-key <gitlab_personal_access_token, deploy_token or job token>
```

### CI/CDを使用してNuGetパッケージを公開する

NuGetをGitLab CI/CDで使用している場合は、パーソナルアクセストークンまたはデプロイトークンの代わりにCIジョブトークンを使用できます。トークンは、パイプラインを生成するユーザーの権限を継承します。

この例は、`main`ブランチが更新されるたびに新しいパッケージを作成する方法を示しています。

1. 次のように`deploy`ジョブを`.gitlab-ci.yml`ファイルに追加します。

   ```yaml
   default:
     image: mcr.microsoft.com/dotnet/core/sdk:3.1

   stages:
     - deploy

   deploy:
     stage: deploy
     script:
       - dotnet pack -c Release
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
      - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
     environment: production
   ```

1. 変更をコミットしてGitLabリポジトリにプッシュし、新しいCI/CDビルドをトリガーします。

### Chocolatey CLIでNuGetパッケージを公開する

{{< history >}}

- GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416404)されました。

{{< /history >}}

前提要件:

- プロジェクトレベルのパッケージレジストリは、Chocolateyのソースです。

Chocolatey CLIでパッケージを公開するには、次を実行します。

```shell
choco push <package_file> --source <source_url> --api-key <gitlab_personal_access_token, deploy_token or job token>
```

このコマンドでは、次の通りとなっています。

- `<package_file>`はパッケージのファイル名で、`.nupkg`で終わります。
- `<source_url>`はNuGet v2フィードパッケージレジストリのURLです。

以下に例を示します。

```shell
choco push MyPackage.1.0.0.nupkg --source "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/v2" --api-key <gitlab_personal_access_token, deploy_token or job token>
```

### 同じ名前またはバージョンのパッケージを公開する

既存のパッケージと同じ名前またはバージョンでパッケージを公開すると、既存のパッケージが上書きされます。

### 重複するNuGetパッケージを許可しない

{{< history >}}

- GitLab 16.3で、`nuget_duplicates_option`という名前の[フラグ付きで](../../../administration/feature_flags.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/293748)されました。デフォルトでは無効になっています。
- GitLab 16.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/419078)になりました。機能フラグ`nuget_duplicates_option`が削除されました。
- GitLab 17.0で必要なロールがメンテナーからオーナーに[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)。

{{< /history >}}

ユーザーが重複する NuGetパッケージを公開できないようにするには、[GraphQl API](../../../api/graphql/reference/_index.md#packagesettings)またはUIを使用します。

UIで、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択し、グループを見つけます。
1. **設定 > パッケージとレジストリ**を選択します。
1. **パッケージの重複**テーブルの**NuGet**行で、**重複を許可**の切替をオフにします。
1. （オプション）**例外**テキストボックスに、許可するパッケージの名前とバージョンに一致する正規表現を入力します。

{{< alert type="note" >}}

**重複を許可**がオンになっている場合は、**例外**テキストボックスに重複してはならないパッケージの名前とバージョンを指定できます。

{{< /alert >}}

変更は自動的に保存されます。

{{< alert type="warning" >}}

.nuspecファイルがパッケージのルートまたはアーカイブの先頭にない場合、パッケージはすぐに重複として認識されない可能性があります。ただし、後で拒否され、UIにエラーが表示されます。

{{< /alert >}}

## パッケージをインストールする

複数のパッケージの名前とバージョンが同じ場合、パッケージをインストールすると、最後に公開されたパッケージが取得されます。

パッケージレジストリからNuGetパッケージをインストールするには、まず[プロジェクトレベルまたはグループレベルのエンドポイントを追加](#add-the-package-registry-as-a-source-for-nuget-packages)する必要があります。

### NuGet CLIでパッケージをインストールする

{{< alert type="warning" >}}

デフォルトでは、`nuget`はまず`nuget.org`で公式ソースを確認します。`nuget.org`のパッケージと同じ名前のNuGetパッケージがパッケージレジストリにある場合は、正しいパッケージをインストールするためにソース名を指定する必要があります。

{{< /alert >}}

次のコマンドを実行して、パッケージの最新バージョンをインストールします。

```shell
nuget install <package_id> -OutputDirectory <output_directory> \
  -Version <package_version> \
  -Source <source_name>
```

- `<package_id>`はパッケージIDです。
- `<output_directory>`は、パッケージがインストールされる出力ディレクトリです。
- `<package_version>`はパッケージバージョンです。（オプション）
- `<source_name>`はソース名です。（オプション）

### .NET CLIでパッケージをインストールする

{{< alert type="warning" >}}

パッケージレジストリに、別のソースのパッケージと同じ名前のパッケージがある場合、インストール中に`dotnet`がソースをチェックする順序を確認するようにしてください。これは、`nuget.config`ファイルで定義されています。

{{< /alert >}}

次のコマンドを実行して、パッケージの最新バージョンをインストールします。

```shell
dotnet add package <package_id> \
       -v <package_version>
```

- `<package_id>`はパッケージIDです。
- `<package_version>`は、パッケージのバージョンです。（オプション）

### NuGet v2フィードを使用してパッケージをインストールする

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416405)されました。

{{< /history >}}

前提要件:

- プロジェクトレベルのパッケージレジストリは、Chocolatey用の[v2フィードソース](#add-a-source-with-chocolatey-cli)です。
- NuGet v2フィードを使用してパッケージをインストールまたはアップグレードする場合は、バージョンを指定する必要があります。

Chocolatey CLIでパッケージをインストールするには、次の手順を実行します。

```shell
choco install <package_id> -Source <source_url> -Version <package_version>
```

このコマンドでは、次の通りとなっています。

- `<package_id>`はパッケージIDです。
- `<source_url>`は、NuGet v2フィードパッケージレジストリのURLまたは名前です。
- `<package_version>`は、パッケージのバージョンです。

以下に例を示します。

```shell
choco install MyPackage -Source gitlab -Version 1.0.2

# or

choco install MyPackage -Source "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/v2" -u <username> -p <gitlab_personal_access_token, deploy_token or job token> -Version 1.0.2
```

Chocolatey CLIでパッケージをアップグレードするには、次の手順を実行します。

```shell
choco upgrade <package_id> -Source <source_url> -Version <package_version>
```

このコマンドでは、次の通りとなっています。

- `<package_id>`はパッケージIDです。
- `<source_url>`は、NuGet v2フィードパッケージレジストリのURLまたは名前です。
- `<package_version>`は、パッケージのバージョンです。

以下に例を示します。

```shell
choco upgrade MyPackage -Source gitlab -Version 1.0.3
```

## パッケージを削除する

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38275)されました。

{{< /history >}}

{{< alert type="warning" >}}

パッケージの削除は、元に戻すことができない永続的な操作です。

{{< /alert >}}

前提要件:

- プロジェクトで[メンテナー](../../permissions.md#project-members-permissions)以上のロールを持っている必要があります。
- パッケージ名とバージョンの両方を持っている必要があります。

NuGet CLIでパッケージを削除するには、次を実行します。

```shell
nuget delete <package_id> <package_version> -Source <source_name> -ApiKey <gitlab_personal_access_token, deploy_token or job token>
```

このコマンドでは、次の通りとなっています。

- `<package_id>`はパッケージIDです。
- `<package_version>`は、パッケージのバージョンです。
- `<source_name>`は、ソース名です。

以下に例を示します。

```shell
nuget delete MyPackage 1.0.0 -Source gitlab -ApiKey <gitlab_personal_access_token, deploy_token or job token>
```

## シンボルパッケージ

`.nupkg`をプッシュすると、`.snupkg`形式のシンボルパッケージファイルが自動的にアップロードされます。次のように手動でプッシュすることもできます。

```shell
nuget push My.Package.snupkg -Source <source_name>
```

### シンボルサーバーとしてパッケージレジストリを使用する

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416178)されました。

{{< /history >}}

GitLabはNuGetパッケージレジストリからシンボルファイルを消費できることから、パッケージレジストリをシンボルサーバーとして使用できます。

シンボルサーバーを使用するには、次の手順に従います。

1. [GraphQl API](../../../api/graphql/reference/_index.md#packagesettings)を使用して、`nuget_symbol_server_enabled`ネームスペース設定を有効にします。
1. シンボルサーバーを使用するようにデバッガーを設定します。たとえば、Visual Studioを構成するには、次の手順を実行します。

   1. **Tools > Preferences**を開きます。
   1. **Debugger > Symbol sources**を選択します。
   1. **Add**を選択します。
   1. 必要なフィールドに入力します。シンボルサーバーのURLは次のとおりです。

      ```shell
      https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/nuget/symbolfiles
      -- or --
      https://gitlab.example.com/api/v4/groups/<your_group_id>/-/packages/nuget/symbolfiles
      ```

   1. **Add Source**を選択します。

デバッガーを設定したら、通常どおりにアプリケーションをデバッグできます。デバッガーは、シンボルPDBファイルが利用可能であれば、パッケージレジストリから自動的にダウンロードします。

#### シンボルパッケージを使用する

シンボルパッケージを使用するようにデバッガーが構成されている場合、デバッガーはリクエストで以下を送信します。

- `Symbolchecksum`ヘッダー: シンボルファイルのSHA-256チェックサム。
- `file_name`リクエストパラメーター: シンボルファイルの名前。たとえば、`mypackage.pdb`などです。
- `signature`リクエストパラメーター: PDBファイルのGUIDと経過時間。

GitLabサーバーはこの情報をシンボルファイルと照合して返します。

注意:

- ポータブルPDBファイルのみがサポートされています。
- デバッガーは認証トークンを提供できないため、シンボルサーバーエンドポイントは通常認証方法をサポートしていません。GitLabサーバーは、正しいシンボルファイルを返すために`signature`と`Symbolchecksum`を必要とします。

## サポートされているCLIコマンド

{{< history >}}

- `nuget delete`および`dotnet nuget delete`コマンドは、GitLab 16.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/38275)。

{{< /history >}}

GitLab NuGetリポジトリは、NuGet CLI(`nuget`)および.NET CLI(`dotnet`)に対して、次のコマンドをサポートしています。

- `nuget push`:パッケージをレジストリにアップロードします。
- `dotnet nuget push`:パッケージをレジストリにアップロードします。
- `nuget install`:レジストリからパッケージをインストールします。
- `dotnet add`:レジストリからパッケージをインストールします。
- `nuget delete`:レジストリからパッケージを削除します。
- `dotnet nuget delete`:レジストリからパッケージを削除します。

## プロジェクトの例

例については、Guided Explorationプロジェクトの[GitVersionを使用した、完全に自動化されたソフトウェアとアーティファクトのバージョニング](https://gitlab.com/guided-explorations/devops-patterns/utterly-automated-versioning)を参照してください。このプロジェクトは、

- `msbuild`メソッドでNuGetパッケージを生成します。
- `nuget.exe`メソッドでNuGetパッケージを生成します。
- NuGetパッケージングに関連して、GitLabリリースと`release-cli`を使用します。
- 複雑なリポジトリでNuGetパッケージのバージョンを自動的に決定して増分するために、[GitVersion](https://gitversion.net/)と呼ばれるツールを使用します。

このサンプルプロジェクトを、テスト用に独自のグループまたはインスタンスにコピーできます。他にどのようなGitLab CIパターンが示されているかについて詳しくは、プロジェクトページをご覧ください。

## トラブルシューティング

### NuGetキャッシュをクリアする

パフォーマンスを向上させるため、NuGetはパッケージに関連するファイルをキャッシュします。問題が発生した場合は、次のコマンドでキャッシュをクリアしてください。

```shell
nuget locals all -clear
```

### DockerベースのGitLabインストールでNuGetパッケージを公開しようとしたときのエラー

ローカルネットワークアドレスへのWebhookリクエストは、内部Webサービスの悪用を防ぐためにブロックされます。NuGetパッケージを公開しようとしたときに`Error publishing`または`Invalid Package: Failed metadata extraction error`メッセージが表示される場合は、ネットワーク設定を変更して、[Webhookおよびインテグレーションからのローカルネットワークへのリクエストを許可](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations)します。
