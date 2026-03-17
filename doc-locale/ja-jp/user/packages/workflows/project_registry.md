---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 専用のタイプ固有レジストリでパッケージを管理します
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

トップレベルのアーティファクト管理グループ内の専用プロジェクトで、タイプごとにパッケージを整理します。このアプローチにより、明確な所有権とタイプ固有のポリシーが実現します。

このアプローチは、次のような場合に使用します:

- 専用のポリシーと設定を使用して、タイプごとにパッケージを整理する。
- 組織のすべてのパッケージに対して、単一の消費エンドポイントを提供する。
- サードパーティのレジストリから構造化されたGitLabの設定にパッケージを移行する。
- パッケージ管理の懸念をアプリケーションのソースコードから分離する。
- 異なるパッケージタイプに異なるガバナンスポリシーを適用する。
- 組織全体のアクセスを有効にしながら、明確な所有権を維持する。

## 例：チュートリアル {#example-walkthrough}

このアプローチでパッケージを効果的に整理および管理するには、次の手順を実行する必要があります:

- パッケージタイプ別に編成されたプロジェクトを含む、アーティファクト管理専用のトップレベルグループを作成します。
- パッケージの消費時にパフォーマンスを向上させるために、トップレベルグループをアーティファクトを含むプロジェクトのみに制限します。

### 推奨される構造 {#recommended-structure}

次の例は、トップレベルグループとプロジェクトをどのように構成する必要があるかの概要を示しています:

```plaintext
company_namespace/artifact_management/ # top-level group
├── java-packages/           # Maven packages
├── node-packages/           # npm packages
├── python-packages/         # PyPI packages
├── docker-images/           # Container registry
├── terraform-modules/       # Terraform modules
├── nuget-packages/          # NuGet packages
└── generic-packages/        # Generic file packages
```

> [!note]一部の組織では、パッケージのライフサイクルまたは安定性に基づいて、さらに分離することを推奨しています。たとえば、`java-releases/`と`java-snapshots/`に対して別個のプロジェクトを作成できます。このようにして、安定したパッケージと開発パッケージに異なるクリーンアップポリシー、アクセス制御、または承認ワークフローを適用できます。

### グループとプロジェクトを作成する {#create-the-group-and-projects}

アーティファクト管理用の新しいトップレベルグループを作成します:

1. 上部のバーで、**新規作成**（{{< icon name="plus" >}}）と**新規グループ**を選択します。
1. **グループを作成**を選択します。
1. **グループ名**テキストボックスに、`Artifact Management`などを入力します。
1. **グループURL**では、生成されたパスをそのまま使用します。
1. グループの[**表示レベル**](../../public_access.md)を選択します。
1. **グループを作成**を選択します。

必要なパッケージタイプごとにプロジェクトを作成します:

1. 上部のバーで、**検索または移動先**を選択し、アーティファクト管理グループを検索します。
1. 左側のサイドバーで、**新規作成**（{{< icon name="plus" >}}）と**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. 目的のパッケージタイプに対して、**プロジェクト名**を入力します。例: `java-packages`、`node-packages`。
1. 適切な表示レベルを設定します。
1. **プロジェクトを作成**を選択します。

組織が最も使用するパッケージタイプから開始し、追加のパッケージ形式を採用するにつれて構造を展開します。このアプローチは、セキュリティと使いやすさを維持しながら、自然にスケールします。

グループの設定を構成します:

1. アーティファクト管理グループで、左側のサイドバーで、**設定** > **パッケージとレジストリ**を選択します。
1. 必要なグループポリシー（**パッケージの重複**や**パッケージ転送**など）を構成します。
1. 必要に応じて、グループのアクセス制御をセットアップします。

## 認証とアクセスを設定する {#configure-authentication-and-access}

認証は、ユースケースによって異なります。以下の提案を参照してください。認証の詳細については、[レジストリで認証する](../../packages/package_registry/supported_functionality.md#authenticate-with-the-registry)を参照してください

ローカル開発の場合（デベロッパー）:

- 個々のデベロッパー向けのパーソナルアクセストークン
- 共有チーム認証情報用のグループアクセストークン

CI/CDパイプラインの場合:

- CI/CDジョブトークン（推奨） - 自動認証
- 特別なケースのプロジェクトアクセストークン

外部システムの場合:

- 読み取り専用消費のデプロイトークン
- より詳細な制御を行うためのプロジェクトアクセストークンとグループアクセストークン

### トップレベルグループアクセスのセットアップ {#set-up-top-level-group-access}

組織全体のパッケージ消費のためにグループデプロイトークンを作成します:

1. アーティファクト管理グループで、左側のサイドバーで、**設定** > **リポジトリ**を選択します。
1. **デプロイトークン**を展開します。
1. **トークンの追加**を選択し、フィールドに入力します:
   - **名前**には、`package-consumption`を入力します。
   - **スコープ**には、`read_package_registry`を選択します。
1. **デプロイトークンを作成**を選択します。

トークンを安全に保存します。

パブリッシュにCI/CDジョブトークンを使用する場合は、ジョブトークンの許可リストを構成します:

1. パッケージ固有の各プロジェクトで、左側のサイドバーで**設定** > **CI/CD**を選択します。
1. **Token Access**を展開します。
1. このパッケージレジストリへのパッケージのパブリッシュを許可するプロジェクトを追加します。

### プロジェクトの設定を構成する {#configure-project-settings}

パッケージタイププロジェクトごとに、以下を構成します:

- そのパッケージタイプに適した**Lifecycle policies**
- 必要に応じて、**保護されたパッケージ**ルール
- 必要に応じて、**Protected container tag**ルール
- 特定のユースケースの**プロジェクトのアクセストークン**

## パッケージのパブリッシュ {#publish-packages}

チームは、適切なタイプ固有のプロジェクトレジストリにパッケージをパブリッシュする必要があります。サポートされているパッケージ形式ごとに、次の例を参照してください。

{{< tabs >}}

{{< tab title="Maven" >}}

`pom.xml`を構成して、`java-packages`プロジェクトにパブリッシュします:

```xml
<distributionManagement>
    <repository>
        <id>gitlab-maven</id>
        <url>${CI_API_V4_URL}/projects/JAVA_PACKAGES_PROJECT_ID/packages/maven</url>
    </repository>
    <snapshotRepository>
        <id>gitlab-maven</id>
        <url>${CI_API_V4_URL}/projects/JAVA_PACKAGES_PROJECT_ID/packages/maven</url>
    </snapshotRepository>
</distributionManagement>
```

`settings.xml`で認証を構成します:

```xml
<servers>
    <server>
        <id>gitlab-maven</id>
        <configuration>
            <httpHeaders>
                <property>
                    <name>Job-Token</name>
                    <value>${CI_JOB_TOKEN}</value>
                </property>
            </httpHeaders>
        </configuration>
    </server>
</servers>
```

以下を使用してパブリッシュします:

```shell
mvn deploy

{{< /tab >}}

{{< tab title="npm" >}}

Configure your project's `package.json`:

```json
{
  "name": "@company/my-package",
  "publishConfig": {
    "registry": "${CI_API_V4_URL}/projects/NODE_PACKAGES_PROJECT_ID/packages/npm/"
  }
}
```

CI/CDパブリッシュの場合、ジョブトークンが自動的に使用されます:

```yaml
publish:
  script:
    - npm publish
```

ローカルでのパブリッシュの場合は、認証を構成します:

```shell
npm config set @company:registry https://gitlab.example.com/api/v4/projects/NODE_PACKAGES_PROJECT_ID/packages/npm/
npm config set //gitlab.example.com/api/v4/projects/NODE_PACKAGES_PROJECT_ID/packages/npm/:_authToken ${PERSONAL_ACCESS_TOKEN}

{{< /tab >}}

{{< tab title="PyPI" >}}

Configure publishing in your CI/CD pipeline:

```yaml
publish:
  script:
    - pip install build twine
    - python -m build
    - TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token twine upload --repository-url ${CI_API_V4_URL}/projects/PYTHON_PACKAGES_PROJECT_ID/packages/pypi dist/*
```

ローカルでパブリッシュする場合:

```shell
twine upload --repository-url https://gitlab.example.com/api/v4/projects/PYTHON_PACKAGES_PROJECT_ID/packages/pypi --username __token__ --password ${PERSONAL_ACCESS_TOKEN} dist/*

{{< /tab >}}

{{< tab title="Container registry" >}}

Build and push Docker images:

```yaml
build-image:
  script:
    - docker build -t $CI_REGISTRY/artifact-management/docker-images/my-app:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY/artifact-management/docker-images/my-app:$CI_COMMIT_SHA
```

ローカル開発の場合:

```shell
docker login gitlab.example.com -u ${USERNAME} -p ${PERSONAL_ACCESS_TOKEN}
docker push gitlab.example.com/artifact-management/docker-images/my-app:latest

{{< /tab >}}

{{< tab title="Terraform" >}}

Publish Terraform modules:

```yaml
publish-module:
  script:
    - tar -czf module.tar.gz *.tf
    - 'curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file module.tar.gz "${CI_API_V4_URL}/projects/TERRAFORM_PACKAGES_PROJECT_ID/packages/terraform/modules/my-module/my-provider/1.0.0/file"'
```

{{< /tab >}}

{{< tab title="NuGet" >}}

プロジェクトファイルまたはCI/CDパイプラインでパブリッシュを構成します:

```yaml
publish:
  script:
    - dotnet pack
    - dotnet nuget push "bin/Release/*.nupkg" --source ${CI_API_V4_URL}/projects/NUGET_PACKAGES_PROJECT_ID/packages/nuget/index.json --api-key ${CI_JOB_TOKEN}
```

ローカルでパブリッシュする場合:

```shell
dotnet nuget push package.nupkg --source https://gitlab.example.com/api/v4/projects/NUGET_PACKAGES_PROJECT_ID/packages/nuget/index.json --api-key ${PERSONAL_ACCESS_TOKEN}

{{< /tab >}}

{{< tab title="Generic" >}}

Upload generic packages:

```yaml
upload-package:
  script:
    - 'curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file my-package.zip "${CI_API_V4_URL}/projects/GENERIC_PACKAGES_PROJECT_ID/packages/generic/my-package/1.0.0/my-package.zip"'
```

{{< /tab >}}

{{< /tabs >}}

## パッケージの利用 {#consume-packages}

パッケージを消費するには、次のいずれかを実行します:

- Maven仮想レジストリを使用します。
- トップレベルグループエンドポイントを使用します。

### Maven仮想レジストリの使用（ベータ） {#using-the-maven-virtual-registry-beta}

Maven仮想レジストリは、複数のソースからパッケージを集約することにより、アーティファクト管理設定を強化できます。次のことができます: 

- Mavenのトップレベルグループエンドポイントをアップストリームとして使用して、内部パッケージを追加します（例：`https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/maven`）。
- Maven Centralやプライベートレジストリなど、外部のアップストリームレジストリを追加します。
- 他のGitLabプロジェクトまたはグループを追加します。

このアプローチは、インテリジェントなキャッシュとアップストリームの優先順位を使用して、内部および外部の依存関係を組み合わせる単一のエンドポイントを提供します。

Maven仮想レジストリは、次の場合に使用します:

- 外部アップストリームレジストリを使用して内部GitLabパッケージを集約する必要がある
- 信頼性を向上させるために外部の依存関係をキャッシュしたい
- パブリックのものよりもプライベートレジストリを優先する必要がある
- 内部および外部の依存関係を処理する単一のエンドポイントが必要

パブリッシュは、Maven仮想レジストリではサポートされていません。

詳細については、[Maven仮想レジストリ](../virtual_registry/maven/_index.md)を参照してください。

#### トップレベルのアーティファクト管理グループ内でMaven仮想レジストリを構成する {#configure-the-maven-virtual-registry-within-a-top-level-artifact-management-group}

1. トップレベルグループにバーチャルレジストリを作成します:
   - `artifact-management`グループで、**デプロイ** > **バーチャルレジストリ**に移動します。
   - Maven仮想レジストリを作成します（たとえば、「Company Maven Registry」）。
1. アップストリームレジストリを構成します:
   - 内部`java-packages`プロジェクトをアップストリームとして追加します。
   - Maven Centralやプライベートリポジトリなどの外部レジストリを追加します。
   - プライベートレジストリを最初に、パブリックレジストリを最後に、アップストリームを注文します。
1. バーチャルレジストリを使用するようにMavenクライアントを構成します:

```xml
   <mirrors>
     <mirror>
       <id>central-proxy</id>
       <name>GitLab virtual registry</name>
       <url>https://gitlab.example.com/api/v4/virtual_registries/packages/maven/<registry_id></url>
       <mirrorOf>central</mirrorOf>
     </mirror>
   </mirrors>
```

バーチャルレジストリは、パーソナルアクセストークン、グループデプロイトークン、グループアクセストークン、CI/CDジョブトークンなど、複数のトークンタイプをサポートしています。各トークンタイプは、異なるHTTPヘッダー名を使用します。詳細については、[仮想レジストリへの認証](../virtual_registry/_index.md#authenticate-to-the-virtual-registry)を参照してください。

次の例は、パーソナルアクセストークンを実装しています:

```xml
   <servers>
     <server>
       <id>gitlab-maven</id>
       <configuration>
         <httpHeaders>
           <property>
             <name>Private-Token</name>
             <value>${PERSONAL_ACCESS_TOKEN}</value>
           </property>
         </httpHeaders>
       </configuration>
     </server>
   </servers>
```

### トップレベルグループエンドポイントを構成する {#configure-a-top-level-group-endpoint}

トップレベルグループエンドポイントからパッケージを消費するようにプロジェクトを構成します。このアプローチは、単一の構成を介してすべてのパッケージタイプへのアクセスを提供します:

{{< tabs >}}

{{< tab title="Maven" >}}

グループレジストリから消費するように`pom.xml`を構成します:

```xml
<repositories>
    <repository>
        <id>gitlab-maven</id>
        <url>https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/maven</url>
    </repository>
</repositories>
```

`settings.xml`で認証を構成します:

```xml
<settings>
    <servers>
        <server>
            <id>gitlab-maven</id>
            <username>deploy-token-username</username>
            <password>deploy-token-password</password>
        </server>
    </servers>
</settings>
```

{{< /tab >}}

{{< tab title="NPM" >}}

`.npmrc`ファイルを構成します:

```ini
@company:registry=https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/npm/
//gitlab.example.com/api/v4/groups/artifact-management/-/packages/npm/:_authToken=${DEPLOY_TOKEN}
```

{{< /tab >}}

{{< tab title="PyPi" >}}

グループレジストリを使用するように`pip`を構成します:

```ini
# pip.conf or ~/.pip/pip.conf
[global]
extra-index-url = https://deploy-token-username:deploy-token-password@gitlab.example.com/api/v4/groups/artifact-management/-/packages/pypi/simple/
```

または、環境変数を使用します:

```shell
pip install --index-url https://deploy-token-username:deploy-token-password@gitlab.example.com/api/v4/groups/artifact-management/-/packages/pypi/simple/ --no-index my-package

{{< /tab >}}

{{< tab title="Container Registry" >}}

Pull images from the group registry:

```shell
docker login gitlab.example.com -u deploy-token-username -p deploy-token-password
docker pull gitlab.example.com/artifact-management/docker-images/my-app:latest

{{< /tab >}}

{{< tab title="Terraform" >}}

Configure Terraform to use GitLab credentials with environment variables:

```shell
export TF_TOKEN_gitlab_example_com="deploy-token-password"

Then reference modules in your Terraform configuration:

```hcl
module "example" {
  source = "gitlab.example.com/artifact-management/terraform-modules//my-module"
  version = "1.0.0"
}
```

または、プロジェクト固有のURLを使用します:

```hcl
module "example" {
  source = "https://gitlab.example.com/api/v4/projects/TERRAFORM_PACKAGES_PROJECT_ID/packages/terraform/modules/my-module/my-provider/1.0.0"
}
```

{{< /tab >}}

{{< tab title="NuGet" >}}

グループレジストリを使用するようにNuGetを構成します:

```xml
<!-- nuget.config -->
<configuration>
  <packageSources>
    <add key="GitLab" value="https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/nuget/index.json" />
  </packageSources>
  <packageSourceCredentials>
    <GitLab>
      <add key="Username" value="deploy-token-username" />
      <add key="ClearTextPassword" value="deploy-token-password" />
    </GitLab>
  </packageSourceCredentials>
</configuration>

{{< /tab >}}

{{< tab title="Generic" >}}

Download generic packages:

```shell
curl --header "DEPLOY-TOKEN: ${DEPLOY_TOKEN}" "https://gitlab.example.com/api/v4/groups/artifact-management/-/packages/generic/my-package/1.0.0/my-package.zip" --output my-package.zip

{{< /tab >}}

{{< /tabs >}}

## Example CI/CD configuration

The following example shows you how a project
might consume packages from multiple package types:

```yaml
stages:
  - build
  - test

variables:
  MAVEN_OPTS: "-Dmaven.repo.local=${CI_PROJECT_DIR}/.m2/repository"

before_script:
  # Configure npm registry
  - echo "@company:registry=${CI_API_V4_URL}/groups/artifact-management/-/packages/npm/" >> .npmrc
  - echo "//${CI_SERVER_HOST}/api/v4/groups/artifact-management/-/packages/npm/:_authToken=${CI_JOB_TOKEN}" >> .npmrc

build:
  stage: build
  script:
    # Install npm dependencies from group registry
    - npm install
    # Build with Maven dependencies from group registry
    - mvn compile
  cache:
    paths:
      - .m2/repository/
      - node_modules/
```

## ソースコードと一緒に公開 {#publish-alongside-source-code}

一部の組織では、[エンタープライズスケールチュートリアル](../package_registry/enterprise_structure_tutorial.md)で説明されているように、アプリケーションソースコードと一緒にパッケージを公開することを推奨しています。このアプローチは、次の場合にうまく機能します:

- パッケージが特定のアプリケーションに密接に結合されている。
- パッケージの所有権をソースコードの所有権と一致させたい。
- チームが、コードとパッケージの両方をまとめて管理する。

アーティファクト管理アプローチは、次の場合にうまく機能します:

- パッケージのガバナンスを合理化したい。
- パッケージが複数のプロジェクト間で共有されている。
- タイプ固有のポリシーと制御が必要である。
- 従来のアーティファクトリポジトリから移行している。

組織が最も使用するパッケージタイプから開始し、追加のパッケージ形式を採用するにつれて構造を展開します。このアプローチは、セキュリティと使いやすさを維持しながら、自然にスケールします。
