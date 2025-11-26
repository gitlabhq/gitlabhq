---
stage: Package
group: Package Registry
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'チュートリアル: エンタープライズの拡大に合わせてパッケージレジストリを構造化する'
---

組織がスケールするにつれて、パッケージ管理はますます複雑になる可能性があります。GitLabパッケージレジストリモデルは、エンタープライズパッケージ管理のための強力なソリューションを提供します。パッケージレジストリを活用する方法を理解することは、パッケージを安全、簡単、かつ大規模に扱う上で重要です。

このチュートリアルでは、GitLabパッケージレジストリモデルをエンタープライズグループ構造に組み込む方法を学びます。ここで提供する例はMavenおよびNPMパッケージに固有のものですが、このチュートリアルの概念は、GitLabパッケージレジストリでサポートされているパッケージに拡張できます。

このチュートリアルを終えると、次の方法がわかるようになります:

1. [作業を構造化するために、単一のルートグループまたはトップレベルグループを設定する](#create-an-enterprise-structure)。
1. [明確な所有権を持つパッケージを公開するためのプロジェクトを設定する](#set-up-a-top-level-group)。
1. [アクセスを簡素化するために、トップレベルグループのパッケージ消費を設定する](#publish-packages)。
1. [チームが組織のパッケージにアクセスできるようにデプロイトークンを追加する](#add-deploy-tokens)。
1. [パッケージを安全に操作できるようにCI/CDを設定する](#use-packages-with-cicd)。

## はじめる前 {#before-you-begin}

このチュートリアルを完了するには、以下が必要です:

- NPMまたはMavenパッケージ。
- GitLabパッケージレジストリに関する知識。
- テストプロジェクト。既存のプロジェクトを使用するか、このチュートリアル用にプロジェクトを新規作成できます。

## GitLabパッケージレジストリについて {#understand-the-gitlab-package-registry}

JFrog ArtifactoryやSonatype Nexusなどの従来のパッケージマネージャーは、単一の集中リポジトリを使用してパッケージを保存および更新します。GitLabでは、グループまたはプロジェクトでパッケージを直接管理します。これは、次の意味をもちます:

- チームはコードを保存するプロジェクトにパッケージを公開します。
- チームは、それらの下にあるすべてのパッケージを集約するルートグループレジストリからパッケージを消費します。
- アクセス制御は、既存のGitLab権限から継承されます。

パッケージはコードのように保存および管理されるため、既存のプロジェクトまたはグループにパッケージ管理を追加できます。このモデルには、いくつかの利点があります:

- ソースコードと並行したパッケージの明確な所有権
- 追加の設定なしで、きめ細かいアクセス制御
- 簡素化されたCI/CDインテグレーション
- チーム構造との自然な連携
- ルートグループ消費を通じて、すべての企業パッケージにアクセスするための単一のURL

## エンタープライズ構造を作成する {#create-an-enterprise-structure}

単一のトップレベルグループでコードを整理することを検討してください。例: 

```plaintext
company/ (top-level group)
├── retail-division/
│   ├── shared-libraries/    # Division-specific shared code
│   └── teams/
│       ├── checkout/        # Team publishes packages here
│       └── inventory/       # Team publishes packages here
├── banking-division/
│   ├── shared-libraries/    # Division-specific shared code
│   └── teams/
│       ├── payments/        # Team publishes packages here
│       └── fraud/           # Team publishes packages here
└── shared-platform/         # Enterprise-wide shared code
    ├── java-commons/        # Shared Java libraries
    └── ui-components/       # Shared UI components
```

この構造では、会社内のすべてのチームがコードとパッケージを独自のプロジェクトに公開し、トップレベルグループ`company/`グループの設定を継承します。

## トップレベルグループを設定する {#set-up-a-top-level-group}

オーナーロールがあり、既存のトップレベルグループがある場合は、それを使用できます。

グループがない場合は、次の手順で作成します:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規グループ**を選択します。
1. **グループ名**に、グループの名前を入力します。
1. **グループURL**に、グループのパスを入力します。これは、ネームスペースとして使用されます。
1. [表示レベル](../../public_access.md)を選択します。
1. オプション。情報を入力して、エクスペリエンスをパーソナライズします。
1. **グループを作成**を選択します。

このグループは、組織内の他のグループとプロジェクトを格納します。他のプロジェクトやグループがある場合は、管理のために[トップレベルグループに転送する](../../group/manage.md#transfer-a-group)ことができます。

続行する前に、少なくとも以下があることを確認してください:

- トップレベルグループの場合
- トップレベルグループまたはそのサブグループの1つに属するプロジェクト。

## パッケージを公開 {#publish-packages}

明確な所有権を維持するために、チームは独自のパッケージレジストリにパッケージを公開する必要があります。これにより、パッケージはソースコードとともに保持され、バージョン履歴がプロジェクトアクティビティーに関連付けられます。

{{< tabs >}}

{{< tab title="Mavenプロジェクト" >}}

Mavenパッケージを公開するには:

- プロジェクトのパッケージレジストリに公開するように`pom.xml`ファイルを設定します:

  ```xml
  <!-- checkout/pom.xml -->
  <distributionManagement>
      <repository>
          <id>gitlab-maven</id>
          <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
      </repository>
  </distributionManagement>
  ```

{{< /tab >}}

{{< tab title="NPMプロジェクト" >}}

NPMパッケージを公開するには:

- `package.json`ファイルを設定する:

  ```json
  // ui-components/package.json
  {
    "name": "@company/ui-components",
    "publishConfig": {
      "registry": "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"
    }
  }
  ```

{{< /tab >}}

{{< /tabs >}}

## パッケージを消費する {#consume-packages}

プロジェクトは単一のトップレベルグループの下に編成されているため、パッケージは組織から引き続きアクセスできます。チームがパッケージを消費するための単一のAPIエンドポイントを設定しましょう。

{{< tabs >}}

{{< tab title="Mavenプロジェクト" >}}

- トップレベルグループからパッケージにアクセスするように`pom.xml`を設定します:

  ```xml
  <!-- Any project's pom.xml -->
  <repositories>
      <repository>
          <id>gitlab-maven</id>
          <url>https://gitlab.example.com/api/v4/groups/company/-/packages/maven</url>
      </repository>
  </repositories>
  ```

{{< /tab >}}

{{< tab title="NPMプロジェクト" >}}

- `.npmrc`ファイルを設定する:

  ```shell
  # Any project's .npmrc
  @company:registry=https://gitlab.example.com/api/v4/groups/company/-/packages/npm/
  ```

{{< /tab >}}

{{< /tabs >}}

この設定により、プロジェクトベースの公開の利点を維持しながら、組織全体のすべてのパッケージへのアクセスが自動的に提供されます。

## デプロイトークンを追加 {#add-deploy-tokens}

次に、読み取り専用デプロイトークンを追加します。このトークンは、組織のサブグループとプロジェクトに保存されているパッケージへのアクセス制御を提供するため、チームは開発にそれらを使用できます。

1. トップレベルグループで、左側のサイドバーで**設定** > **リポジトリ**を選択します。
1. **デプロイトークン**を展開します。
1. **トークンの追加**を選択します。
1. フィールドに入力し、スコープを`read_repository`に設定します。
1. **デプロイトークンを作成**を選択します。

必要に応じて、トップレベルグループにデプロイトークンをいくつでも追加できます。トークンを定期的にローテーションすることを忘れないでください。トークンが漏洩した疑いがある場合は、すぐに失効して交換してください。

## CI/CDでパッケージを使用する {#use-packages-with-cicd}

CI/CDジョブがパッケージレジストリにアクセスする必要がある場合、定義済みのCI/CD変数`CI_JOB_TOKEN`で認証します。この認証は自動的に行われるため、追加の設定を行う必要はありません:

```yaml
publish:
  script:
    - mvn deploy  # For Maven packages
    # or
    - npm publish # For npm packages
  # CI_JOB_TOKEN provides automatic authentication
```

## まとめと次のステップ {#summary-and-next-steps}

GitLabプロジェクトを1つのトップレベルグループの下に編成すると、いくつかの利点があります:

- 簡素化された設定:
  - すべてのパッケージアクセスに対する1つのURL
  - チーム全体で一貫性のあるセットアップ
  - 簡単なトークンローテーション
- 明確な所有権:
  - パッケージはソースコードとともに保持されます
  - チームは公開に対するアクセス制御を維持します
  - バージョン履歴はプロジェクトアクティビティーに関連付けられています
- 自然な組織:
  - グループは会社構造と一致します
  - チームは自律性を維持しながら共同作業できます

GitLabパッケージレジストリモデルは、エンタープライズパッケージ管理のための強力なソリューションを提供します。プロジェクトベースの公開とトップレベルグループ消費を組み合わせることで、明確な所有権と簡素化されたアクセスの両方の利点が得られます。

このアプローチは、セキュリティと使いやすさを維持しながら、組織に合わせて自然にスケールします。このモデルを単一のチームまたは部門に実装することから始め、この統合されたアプローチの利点を確認したら展開します。このチュートリアルではMavenとNPMに焦点を当てていますが、同じ原則はGitLabでサポートされているすべてのパッケージタイプに適用されることを忘れないでください。
