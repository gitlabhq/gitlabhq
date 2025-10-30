---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリ内のNuGetパッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトのパッケージレジストリにNuGetパッケージを公開します。すると、依存関係として使用する必要がある場合に、いつでもパッケージをインストールできるようになります。

パッケージレジストリは以下と連携します:

- [NuGet CLI](https://learn.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference)
- [.NET Core CLI](https://learn.microsoft.com/en-us/dotnet/core/tools/)
- [Visual Studio](https://visualstudio.microsoft.com/vs/)

これらのクライアントが使用する特定のAPIエンドポイントの詳細については、[NuGet APIリファレンス](../../../api/packages/nuget.md)を参照してください。

[NuGetをインストール](../workflows/build_packages.md#nuget)する方法を説明します。

## パッケージレジストリに対して認証する {#authenticate-to-the-package-registry}

GitLabパッケージレジストリにアクセスするには、認証トークンが必要です。実現しようとしていることに応じて、さまざまなトークンを利用できます。詳細については、[トークンに関するガイダンス](../package_registry/supported_functionality.md#authenticate-with-the-registry)参照してください。

- 組織で2要素認証（2FA）を使用している場合、スコープが`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)を使用する必要があります。
- CI/CDパイプラインでパッケージを公開する場合は、プライベートRunnerで[CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)を使用できます。インスタンスRunnerの[変数を登録](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)することもできます。

## GitLabエンドポイントをNuGetパッケージに使用する {#use-the-gitlab-endpoint-for-nuget-packages}

GitLabパッケージレジストリとやり取りするには、プロジェクトエンドポイントまたはグループエンドポイントを使用できます:

- プロジェクトエンドポイント: 同じグループにないNuGetパッケージが少数しかない場合に使用します。
- グループエンドポイント: 同じグループ内の異なるプロジェクトに多数のNuGetパッケージがある場合に使用します。

パッケージのプッシュなど、一部のアクションはプロジェクトエンドポイントでのみ使用できます。

NuGetが認証情報を処理する方法により、パッケージレジストリはパブリックグループへの匿名リクエストを拒否します。

## NuGetパッケージのソースとしてパッケージレジストリを追加する {#add-the-package-registry-as-a-source-for-nuget-packages}

パッケージをパッケージレジストリに公開およびインストールするには、パッケージのソースとしてパッケージレジストリを追加する必要があります。

前提要件: 

- あなたのGitLabのユーザー名
- 認証トークン（次のセクションではパーソナルアクセストークンを想定しています）
- ソースの名前
- プロジェクトまたはグループID

### プロジェクトエンドポイントを使用 {#with-the-project-endpoint}

{{< tabs >}}

{{< tab title="NuGet CLI" >}}

パッケージレジストリをNuGet CLIでソースとして追加するには、次のコマンドを実行します:

```shell
nuget source Add -Name <source_name> -Source "https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json" -UserName <gitlab_username> -Password <personal_access_token>
```

以下の値を置き換えます:

- `<source_name>`をソース名に置き換えます
- `<project_id>`を[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)にあるプロジェクトIDに置き換えます。
- `<gitlab_username>` GitLabのユーザー名
- `<personal_access_token>`をパーソナルアクセストークンに置き換えます

次に例を示します: 

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" -UserName carol -Password <your_access_token>
```

{{< /tab >}}

{{< tab title=".NET CLI" >}}

パッケージレジストリを .NET CLIでソースとして追加するには、次のコマンドを実行します:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json" --name <source_name> --username <gitlab_username> --password <personal_access_token>
```

以下の値を置き換えます:

- `<source_name>`をソース名に置き換えます
- `<project_id>`を[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)にあるプロジェクトIDに置き換えます。
- `<gitlab_username>` GitLabのユーザー名
- `<personal_access_token>`をパーソナルアクセストークンに置き換えます

オペレーティングシステムによっては、`--store-password-in-clear-text`をコマンドに追加する必要がある場合があります。

次に例を示します: 

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/projects/10/packages/nuget/index.json" --name gitlab --username carol --password <your_access_token> --store-password-in-clear-text
```

{{< /tab >}}

{{< tab title="Chocolatey CLI" >}}

パッケージレジストリをChocolatey CLIのソースフィードとして追加できます。Chocolatey CLI v1.xを使用している場合は、NuGet v2のソースフィードのみを追加できます。

パッケージレジストリをChocolateyのソースとして追加するには、次のコマンドを実行します:

```shell
choco source add -n=<source_name> -s "'https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/v2'" -u=<gitlab_username> -p=<personal_access_token>
```

以下の値を置き換えます:

- `<source_name>`をソース名に置き換えます
- `<project_id>`を[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)にあるプロジェクトIDに置き換えます。
- `<gitlab_username>` GitLabのユーザー名
- `<personal_access_token>`をパーソナルアクセストークンに置き換えます

次に例を示します: 

```shell
choco source add -n=gitlab -s "'https://gitlab.example.com/api/v4/projects/10/packages/nuget/v2'" -u=carol -p=<your_access_token>
```

{{< /tab >}}

{{< tab title="Visual Studio" >}}

Visual Studioでパッケージレジストリをソースとして追加するには:

1. [Visual Studio](https://visualstudio.microsoft.com/vs/)を開きます。
1. Windowsの場合は、**ツール** > **オプション**を選択します。macOSの場合は、**Visual Studio** > **設定**を選択します。
1. **NuGet**セクションで、**Sources**を選択して、すべてのNuGetソースのリストを表示します。
1. **追加**を選択します。
1. 次のフィールドに入力します:

   - **名前**: ソースの名前。
   - **ソース**: `https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json`。ここでは、`<project_id>`はプロジェクトID、`gitlab.example.com`はドメイン名です。

1. **保存**を選択します。
1. パッケージにアクセスするときは、**ユーザー名**と**パスワード**を次のように入力する必要があります:

   - **ユーザー名**: GitLabのユーザー名。
   - **パスワード**: パーソナルアクセストークン。

ソースがリストに表示されます。

警告が表示された場合は、**ソース**、**ユーザー名**、**パスワード**が正しいことを確認してください。

{{< /tab >}}

{{< tab title="設定ファイル" >}}

パッケージレジストリを .NET設定ファイルでソースとして追加するには:

1. プロジェクトのルートで、`nuget.config`という名前のファイルを作成します。
1. 次の設定を追加します:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
    <packageSources>
        <clear />
        <add key="gitlab" value="https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <gitlab>
            <add key="Username" value="%GITLAB_PACKAGE_REGISTRY_USERNAME%" />
            <add key="ClearTextPassword" value="%GITLAB_PACKAGE_REGISTRY_PASSWORD%" />
        </gitlab>
    </packageSourceCredentials>
   </configuration>
   ```

1. 必要な環境変数を設定します:

   ```shell
   export GITLAB_PACKAGE_REGISTRY_USERNAME=<gitlab_username>
   export GITLAB_PACKAGE_REGISTRY_PASSWORD=<personal_access_token>
   ```

{{< /tab >}}

{{< /tabs >}}

{{< alert type="note" >}}

前のユースケースのコマンドでは、`gitlab`という名前のソースを追加します。後続のコマンド例は、ソースURLではなく、ソース名（`gitlab`）を参照しています。

{{< /alert >}}

### グループエンドポイントを使用 {#with-the-group-endpoint}

{{< tabs >}}

{{< tab title="NuGet CLI" >}}

NuGet CLIを使用してパッケージレジストリをソースとして追加するには、次の手順を実行します:

```shell
nuget source Add -Name <source_name> -Source "https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/index.json" -UserName <gitlab_username> -Password <personal_access_token>
```

以下の値を置き換えます:

- `<source_name>`をソース名に置き換えます
- `<group_id>`を、[グループの概要ページ](../../group/_index.md#find-the-group-id)にあるグループIDに置き換えます
- `<gitlab_username>` GitLabのユーザー名
- `<personal_access_token>`をパーソナルアクセストークンに置き換えます

次に例を示します: 

```shell
nuget source Add -Name "GitLab" -Source "https://gitlab.example.com/api/v4/groups/23/-/packages/nuget/index.json" -UserName carol -Password <your_access_token>
```

{{< /tab >}}

{{< tab title=".NET CLI" >}}

.NET CLIを使用してパッケージレジストリをソースとして追加するには、次の手順を実行します:

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/index.json" --name <source_name> --username <gitlab_username> --password <personal_access_token>
```

以下の値を置き換えます:

- `<source_name>`をソース名に置き換えます
- `<group_id>`を、[グループの概要ページ](../../group/_index.md#find-the-group-id)にあるグループIDに置き換えます
- `<gitlab_username>` GitLabのユーザー名
- `<personal_access_token>`をパーソナルアクセストークンに置き換えます

オペレーティングシステムによっては、`--store-password-in-clear-text`フラグが必要になる場合があります。

次に例を示します: 

```shell
dotnet nuget add source "https://gitlab.example.com/api/v4/groups/23/-/packages/nuget/index.json" --name gitlab --username carol --password <your_access_token> --store-password-in-clear-text
```

{{< /tab >}}

{{< tab title="Chocolatey CLI" >}}

Chocolatey CLIは、[プロジェクトエンドポイント](#with-the-project-endpoint)とのみ互換性があります。

{{< /tab >}}

{{< tab title="Visual Studio" >}}

Visual Studioでパッケージレジストリをソースとして追加するには:

1. [Visual Studio](https://visualstudio.microsoft.com/vs/)を開きます。
1. Windowsの場合は、**ツール** > **オプション**を選択します。macOSの場合は、**Visual Studio** > **設定**を選択します。
1. **NuGet**セクションで、**Sources**を選択して、すべてのNuGetソースのリストを表示します。
1. **追加**を選択します。
1. 次のフィールドに入力します:

   - **名前**: ソースの名前。
   - **ソース**: `https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/index.json`。ここでは、`<group_id>`はグループID、`gitlab.example.com`はドメイン名です。

1. **保存**を選択します。
1. パッケージにアクセスするときは、**ユーザー名**と**パスワード**を次のように入力する必要があります。

   - **ユーザー名**: GitLabのユーザー名。
   - **パスワード**: パーソナルアクセストークン。

ソースがリストに表示されます。

警告が表示された場合は、**ソース**、**ユーザー名**、**パスワード**が正しいことを確認してください。

{{< /tab >}}

{{< tab title="設定ファイル" >}}

パッケージレジストリを .NET設定ファイルでソースとして追加するには:

1. プロジェクトのルートで、`nuget.config`という名前のファイルを作成します。
1. 次の設定を追加します:

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <configuration>
    <packageSources>
        <clear />
        <add key="gitlab" value="https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <gitlab>
            <add key="Username" value="%GITLAB_PACKAGE_REGISTRY_USERNAME%" />
            <add key="ClearTextPassword" value="%GITLAB_PACKAGE_REGISTRY_PASSWORD%" />
        </gitlab>
    </packageSourceCredentials>
   </configuration>
   ```

1. 必要な環境変数を設定します:

   ```shell
   export GITLAB_PACKAGE_REGISTRY_USERNAME=<gitlab_username>
   export GITLAB_PACKAGE_REGISTRY_PASSWORD=<personal_access_token>
   ```

{{< /tab >}}

{{< /tabs >}}

{{< alert type="note" >}}

前のユースケースのコマンドでは、`gitlab`という名前のソースを追加します。後続のコマンド例は、ソースURLではなく、ソース名（`gitlab`）を参照しています。

{{< /alert >}}

## パッケージを公開する {#publish-a-package}

前提要件: 

- パッケージレジストリを[ソース](#add-the-package-registry-as-a-source-for-nuget-packages)としてセットアップします。
- [NuGetパッケージ用のGitLabプロジェクトエンドポイント](#with-the-project-endpoint)を設定します。

パッケージを公開する場合、:

- GitLabインスタンスの最大ファイルサイズ制限を確認してください:
  - [GitLab.comインスタンスのパッケージレジストリ制限](../../gitlab_com/_index.md#package-registry-limits)は、ファイル形式によって異なり、設定できません。
  - [GitLab Self-Managedインスタンスのパッケージレジストリ制限](../../../administration/instance_limits.md#file-size-limits)はファイル形式によって異なり、設定可能です。
- 重複が許可されている場合、同じパッケージを同じバージョンで複数回プッシュすると、連続する各アップロードは個別のファイルとして保存されます。パッケージをインストールすると、GitLabは最新のファイルを提供します。
- ほとんどのアップロードされたパッケージは、**パッケージレジストリ**ページにすぐに表示されます。バックグラウンドで処理する必要がある場合、一部のパッケージが表示されるまでに最大10分かかる場合があります。パッケージ。

### NuGet CLIを使用 {#with-nuget-cli}

前提要件: 

- [NuGet CLIで作成されたNuGetパッケージ](https://learn.microsoft.com/en-us/nuget/create-packages/creating-a-package)。

パッケージをプッシュするには、次のコマンドを実行します:

```shell
nuget push <package_file> -Source <source_name>
```

以下の値を置き換えます:

- `<package_file>`はパッケージのファイル名で、`.nupkg`で終わります。
- `<source_name>`をソースの名前に置き換えます。

次に例を示します: 

```shell
nuget push MyPackage.1.0.0.nupkg -Source gitlab
```

### .NET CLIを使用 {#with-net-cli}

{{< history >}}

- [導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/214674) `--api-key`を使用したパッケージのプッシュをGitLab 16.1で実行します。

{{< /history >}}

前提要件:

- [.NET CLIで作成されたNuGetパッケージ](https://learn.microsoft.com/en-us/nuget/create-packages/creating-a-package-dotnet-cli)。

パッケージをプッシュするには、次のコマンドを実行します:

```shell
dotnet nuget push <package_file> --source <source_name>
```

以下の値を置き換えます:

- `<package_file>`はパッケージのファイル名で、`.nupkg`で終わります。
- `<source_name>`をソースの名前に置き換えます。

次に例を示します: 

```shell
dotnet nuget push MyPackage.1.0.0.nupkg --source gitlab
```

`username`と`password`の代わりに、`--api-key`オプションを使用してパッケージを公開することもできます:

```shell
dotnet nuget push <package_file> --source <source_url> --api-key <personal_access_token>
```

以下の値を置き換えます:

- `<package_file>`はパッケージのファイル名で、`.nupkg`で終わります。
- `<source_url>`はNuGetパッケージレジストリのURLです。

次に例を示します: 

```shell
dotnet nuget push MyPackage.1.0.0.nupkg --source https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/index.json --api-key <personal_access_token>
```

### Chocolatey CLIを使用 {#with-chocolatey-cli}

{{< history >}}

- [導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/416404) GitLab 16.2でのNuGet v2とChocolatey CLIのサポート。

{{< /history >}}

前提要件:

- [プロジェクトエンドポイント](#with-the-project-endpoint)を使用するソース。

Chocolatey CLIでパッケージをプッシュするには、次のコマンドを実行します:

```shell
choco push <package_file> --source <source_url> --api-key <gitlab_personal_access_token, deploy_token or job token>
```

以下の値を置き換えます:

- `<package_file>`はパッケージのファイル名で、`.nupkg`で終わります。
- `<source_url>`はNuGet v2フィードパッケージレジストリのURLです。

次に例を示します: 

```shell
choco push MyPackage.1.0.0.nupkg --source "https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/v2" --api-key <personal_access_token>
```

### CI/CDパイプラインを使用 {#with-a-cicd-pipeline}

GitLab CI/CDでNuGetパッケージをプッシュする場合は、パーソナルアクセストークンまたはデプロイトークンの代わりに、[`CI_JOB_TOKEN`定義済み変数](../../../ci/jobs/ci_job_token.md)を使用できます。ジョブトークンは、パイプラインを生成するユーザーまたはメンバーの権限を継承します。

次のセクションの例では、CI/CDパイプラインを使用する場合の一般的なNuGetプッシュのワークフローについて説明します。

#### デフォルトブランチがアップデートされたときにパッケージをプッシュする {#publish-packages-when-the-default-branch-is-updated}

`main`ブランチがアップデートされるたびに新しいパッケージをプッシュするには:

1. プロジェクトの`.gitlab-ci.yml`ファイルに、次の`deploy`ジョブを追加します:

   ```yaml
   default:
     # Updated to a more current SDK version
     image: mcr.microsoft.com/dotnet/sdk:7.0

   stages:
     - deploy

   deploy:
     stage: deploy
     script:
       # Build the package in Release configuration
       - dotnet pack -c Release
       # Configure GitLab package registry as a NuGet source
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       # Push the package to the project's package registry
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # Only run on the main branch
     environment: production
   ```

1. 変更をコミットしてGitLabリポジトリにプッシュし、新しいCI/CDビルドをトリガーします。

#### Gitタグを使用してバージョニングされたパッケージをプッシュする {#publish-versioned-packages-with-git-tags}

[Gitタグ](../../project/repository/tags/_index.md)でバージョニングされたNuGetパッケージをプッシュするには:

1. プロジェクトの`.gitlab-ci.yml`ファイルに、次の`deploy`ジョブを追加します:

   ```yaml
   publish-tagged-version:
     stage: deploy
     script:
       # Use the Git tag as the package version
       - dotnet pack -c Release /p:Version=${CI_COMMIT_TAG} /p:PackageVersion=${CI_COMMIT_TAG}
       # Configure GitLab package registry as a NuGet source
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       # Push the package to the project's package registry
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
       - if: $CI_COMMIT_TAG  # Only run when a tag is pushed
   ```

1. 変更をコミットしてGitLabリポジトリにプッシュします。
1. 新しいCI/CDビルドをトリガーするためにGitタグをプッシュします。

#### さまざまな環境に対して条件付きでプッシュする {#publish-conditionally-for-different-environments}

ユースケースに応じて、さまざまな環境にNuGetパッケージを条件付きでプッシュするようにCI/CDパイプラインを設定できます。

`development`および`production`環境に対して条件付きでNuGetパッケージをプッシュするには:

1. プロジェクトの`.gitlab-ci.yml`ファイルに、次の`deploy`ジョブを追加します:

   ```yaml
     # Publish development/preview packages
   publish-dev:
     stage: deploy
     script:
       # Create a development version with pipeline ID for uniqueness
       - VERSION="0.0.1-dev.${CI_PIPELINE_IID}"
       - dotnet pack -c Release /p:Version=$VERSION /p:PackageVersion=$VERSION
       # Configure GitLab package registry as a NuGet source
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       # Push the package to the project's package registry
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
       - if: $CI_COMMIT_BRANCH == "develop"
     environment: development

     # Publish stable release packages
   publish-release:
     stage: deploy
     script:
       - dotnet pack -c Release
       # Configure GitLab package registry as a NuGet source
       - dotnet nuget add source "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/nuget/index.json" --name gitlab --username gitlab-ci-token --password $CI_JOB_TOKEN --store-password-in-clear-text
       # Push the package to the project's package registry
       - dotnet nuget push "bin/Release/*.nupkg" --source gitlab
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
     environment: production
   ```

1. 変更をコミットしてGitLabリポジトリにプッシュします。

   このCI/CD設定:

   - `develop`ブランチにNuGetパッケージをプッシュすると、`development`環境のパッケージレジストリにパッケージがプッシュされます。
   - `main`ブランチにNuGetパッケージをプッシュすると、`production`環境のパッケージレジストリにNuGetパッケージがプッシュされます。

### 重複するNuGetパッケージを無効にする {#turn-off-duplicate-nuget-packages}

{{< history >}}

- GitLab 16.3で`nuget_duplicates_option`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/293748)されました。デフォルトでは無効になっています。
- GitLab 16.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/419078)になりました。機能フラグ`nuget_duplicates_option`は削除されました。
- GitLab 17.0で、必要なロールがメンテナーからオーナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)されました。

{{< /history >}}

同じ名前とバージョンで複数のパッケージをプッシュできます。

グループメンバーとユーザーが重複するNuGetパッケージをプッシュできないようにするには、**重複を許可**設定をオフにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **パッケージの重複**テーブルの**NuGet**行で、**重複を許可**の切替をオフにします。
1. オプション。**例外**テキストボックスに、許可するパッケージの名前とバージョンに一致する正規表現を入力します。

[GraphQL API](../../../api/graphql/reference/_index.md#packagesettings)の`nuget_duplicates_allowed`設定を使用して、重複するNuGetパッケージをオフにすることもできます。

{{< alert type="warning" >}}

`.nuspec`ファイルがパッケージのルートまたはアーカイブの先頭にない場合、パッケージはすぐに重複として認識されない可能性があります。必然的に重複として認識されると、**Package manager**（パッケージマネージャー）ページにエラーが表示されます。

{{< /alert >}}

## パッケージをインストールする {#install-a-package}

GitLabパッケージレジストリには、同じ名前とバージョンの複数のパッケージを含めることができます。重複するパッケージをインストールすると、最後にプッシュされたパッケージが取得されます。

前提要件:

- パッケージレジストリを[ソース](#add-the-package-registry-as-a-source-for-nuget-packages)としてセットアップします。
- [NuGetパッケージにGitLabエンドポイント](#use-the-gitlab-endpoint-for-nuget-packages)を使用する

### コマンドラインから {#from-the-command-line}

{{< tabs >}}

{{< tab title="NuGet CLI" >}}

次のコマンドを実行して、パッケージの最新バージョンをインストールします:

```shell
nuget install <package_id> -OutputDirectory <output_directory> \
  -Version <package_version> \
  -Source <source_name>
```

- `<package_id>`: はパッケージIDです。
- `<output_directory>`: は、パッケージがインストールされる出力ディレクトリです。
- `<package_version>`: オプション。はパッケージのバージョンです。
- `<source_name>`: オプション。はソース名です。
  - `nuget`は、最初にリクエストされたパッケージの`nuget.org`を確認します。`nuget.org`のパッケージと同じ名前のNuGetパッケージがパッケージレジストリにある場合は、正しいパッケージをインストールするためにソース名を指定する必要があります。

{{< /tab >}}

{{< tab title=".NET CLI" >}}

{{< alert type="note" >}}

パッケージレジストリに、別のソースのパッケージと同じ名前のパッケージがある場合、インストール中に`dotnet`がソースをチェックする順序を確認するようにしてください。この動作は`nuget.config`ファイルで定義されています。

{{< /alert >}}

次のコマンドを実行して、パッケージの最新バージョンをインストールします:

```shell
dotnet add package <package_id> \
       -v <package_version>
```

- `<package_id>`: はパッケージIDです。
- `<package_version>`: オプション。はパッケージのバージョンです。

{{< /tab >}}

{{< /tabs >}}

### NuGet v2フィードを使用 {#with-nuget-v2-feed}

{{< history >}}

- [導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/416404) GitLab 16.5でのNuGet v2インストールエンドポイントのサポート。

{{< /history >}}

前提要件:

- Chocolateyの[v2フィードソース](#with-the-project-endpoint)。
- NuGet v2フィードを使用してパッケージをインストールまたはアップグレードする場合は、バージョンを指定する必要があります。

Chocolatey CLIでパッケージをインストールするには、次の手順を実行します:

```shell
choco install <package_id> -Source <source_url> -Version <package_version>
```

- `<package_id>`: はパッケージIDです。
- `<source_url>`: は、NuGet v2フィードパッケージレジストリのURLまたは名前です。
- `<package_version>`: はパッケージのバージョンです。

次に例を示します: 

```shell
choco install MyPackage -Source gitlab -Version 1.0.2

# or

choco install MyPackage -Source "https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/v2" -u <username> -p <personal_access_token> -Version 1.0.2
```

Chocolatey CLIでパッケージをアップグレードするには、次の手順を実行します:

```shell
choco upgrade <package_id> -Source <source_url> -Version <package_version>
```

- `<package_id>`: はパッケージIDです。
- `<source_url>`: は、NuGet v2フィードパッケージレジストリのURLまたは名前です。
- `<package_version>`: はパッケージのバージョンです。

次に例を示します: 

```shell
choco upgrade MyPackage -Source gitlab -Version 1.0.3
```

## パッケージを削除する {#delete-a-package}

{{< history >}}

- [導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/38275) GitLab 16.5でのNuGetパッケージの削除のサポート。

{{< /history >}}

{{< alert type="warning" >}}

パッケージの削除は、元に戻すことができない永続的な操作です。

{{< /alert >}}

前提要件:

- プロジェクトで[メンテナー](../../permissions.md#project-members-permissions)以上のロールを持っている必要があります。
- パッケージ名とバージョンの両方を持っている必要があります。

NuGet CLIでパッケージを削除するには、次を実行します:

```shell
nuget delete <package_id> <package_version> -Source <source_name> -ApiKey <personal_access_token>
```

- `<package_id>`: はパッケージIDです。
- `<package_version>`: はパッケージのバージョンです。
- `<source_name>`: はソース名です。

次に例を示します: 

```shell
nuget delete MyPackage 1.0.0 -Source gitlab -ApiKey <personal_access_token>
```

## シンボルパッケージ {#symbol-packages}

GitLabは、NuGetパッケージレジストリからシンボルファイルを消費できます。GitLabパッケージレジストリをシンボルサーバーとして使用して、NuGetパッケージをデバッグできます。

NuGetパッケージファイル（`.nupkg`）をプッシュするたびに、シンボルパッケージファイル（`.snupkg`）がNuGetパッケージレジストリに自動的にアップロードされます。

次のように手動でプッシュすることもできます:

```shell
nuget push My.Package.snupkg -Source <source_name>
```

### シンボルファイルにGitLabエンドポイントを使用 {#use-the-gitlab-endpoint-for-symbol-files}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416178)されました。

{{< /history >}}

GitLabパッケージレジストリは、プロジェクトエンドポイントまたはグループエンドポイントで設定できる特別な`symbolfiles`エンドポイントを提供します:

- プロジェクトエンドポイント:

  ```plaintext
  https://gitlab.example.com/api/v4/projects/<project_id>/packages/nuget/symbolfiles
  ```

  - `<project_id>`をプロジェクトIDに置き換えます。

- グループエンドポイント:

  ```plaintext
  https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/nuget/symbolfiles
  ```

  - `<group_id>`をグループIDに置き換えます。

`symbolfiles`エンドポイントは、設定されたデバッガがシンボルファイルをプッシュできるソースです。

### シンボルサーバーとしてパッケージレジストリを使用する {#use-the-package-registry-as-a-symbol-server}

シンボルサーバーを使用するには、次の手順に従います:

1. [GraphiQL](../../../api/graphql/reference/_index.md#packagesettings)で`nuget_symbol_server_enabled`ネームスペース設定nuget_symbol_server_enabledを有効にします。
1. シンボルサーバーを使用するようにデバッガーを設定します。

たとえば、Visual Studioをデバッガとして設定するには:

1. **ツール** > **設定**を選択します。
1. **Debugger**（デバッガ） > **Symbol sources**（シンボルソース）を選択します。
1. **追加**を選択します。
1. シンボルサーバーのURLを入力します。
1. **Add Source**（Add Source）を選択します。

デバッガーを設定したら、通常どおりにアプリケーションをデバッグできます。デバッガは、シンボルPDBファイルが利用可能であれば、パッケージレジストリから自動的にダウンロードします。

#### シンボルパッケージを消費する {#consume-symbol-packages}

シンボルパッケージを消費するようにデバッガが設定されている場合、デバッガはリクエストで次の情報を送信します:

- `Symbolchecksum`ヘッダー: シンボルファイルのSHA-256チェックサム。
- `file_name`リクエストパラメータ: シンボルファイルの名前。たとえば、`mypackage.pdb`などです。
- `signature`リクエストパラメータ: PDBファイルのGUIDと経過時間。

GitLabサーバーはこの情報をシンボルファイルと照合して返します。

次の点に注意してください:

- ポータブルPDBファイルのみがサポートされています。
- デバッガは認証トークンを提供できないため、シンボルサーバーエンドポイントは通常の認証方法をサポートしていません。GitLabサーバーは、正しいシンボルファイルを返すために`signature`と`Symbolchecksum`を必要とします。

## サポートされているCLIコマンド {#supported-cli-commands}

{{< history >}}

- `nuget delete`および`dotnet nuget delete`コマンドは、GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/38275)されました。

{{< /history >}}

GitLab NuGetリポジトリは、NuGet CLI(`nuget`)および.NET CLI(`dotnet`)に対して、次のコマンドをサポートしています:

| NuGet | .NET | 説明 |
|-----------|----------|-------------|
| `nuget push` | `dotnet nuget push` | パッケージをレジストリにアップロードします。 |
| `nuget install` | `dotnet add` | レジストリからパッケージをインストールします。 |
| `nuget delete` | `dotnet nuget delete` | レジストリからパッケージを削除します。 |

## トラブルシューティング {#troubleshooting}

NuGetパッケージを操作する場合、次のイシューが発生する可能性があります。

### NuGetキャッシュをクリアする {#clear-the-nuget-cache}

パフォーマンスを向上させるために、NuGetはパッケージファイルをキャッシュします。ストレージの問題が発生した場合は、次のコマンドでキャッシュをクリアします:

```shell
nuget locals all -clear
```

### DockerベースのGitLabインストールでNuGetパッケージを公開しようとしたときのエラー {#errors-when-publishing-nuget-packages-in-a-docker-based-gitlab-installation}

NuGetパッケージをプッシュするときに、次のエラーメッセージが表示される場合があります:

- `Error publishing`
- `Invalid Package: Failed metadata extraction error`

ローカルネットワークアドレスへのWebhookリクエストは、内部Webサービスの悪用を防ぐためにブロックされます。

これらのエラーを解決するには、ローカルネットワークへのWebhookおよびインテグレーションのリクエストを[許可](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations)するようにネットワーク設定を変更します。
