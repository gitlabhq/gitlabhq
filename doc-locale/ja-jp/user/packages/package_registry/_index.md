---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.3で、GitLab PremiumからGitLab Freeに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/221259)しました。

{{< /history >}}

GitLabパッケージレジストリを使用すると、GitLabをさまざまな[サポート対象パッケージマネージャー](supported_package_managers.md)のプライベートまたはパブリックレジストリとして使用できます。パッケージを公開および共有して、ダウンストリームプロジェクトで依存関係として使用できます。

## パッケージのワークフロー

GitLabパッケージレジストリを使用して、独自のカスタムパッケージワークフローをビルドする方法を説明します。

- すべてのパッケージを1つのプロジェクトに公開するには、[プロジェクトをパッケージレジストリとして使用](../workflows/project_registry.md)します。

- 1つの[モノレポプロジェクト](../workflows/working_with_monorepos.md)から複数の異なるパッケージを公開します。

## パッケージを表示する

プロジェクトまたはグループのパッケージを表示できます。

1. プロジェクトまたはグループに移動します。
1. **デプロイ>パッケージレジストリ**に移動します。

このページで、パッケージを検索、並べ替え、フィルタリングできます。ブラウザからURLをコピーして貼り付けることで、検索結果を共有できます。

パッケージマネージャーの設定や特定のパッケージのインストールに役立つコードスニペットも見つけることができます。

グループ内のパッケージを表示する場合:

- グループとそのプロジェクトに公開されているすべてのパッケージが表示されます。
- アクセスできるプロジェクトのみが表示されます。
- プロジェクトが非公開の場合、またはプロジェクトのメンバーでない場合、そのプロジェクトのパッケージは表示されません。

パッケージの作成方法とアップロード方法については、[パッケージタイプ](supported_package_managers.md)の手順に従ってください。

## レジストリで認証する

認証は、使用されているパッケージマネージャーによって異なります。特定のパッケージタイプでサポートされている認証プロトコルについては、「[認証プロトコル](supported_functionality.md#authentication-protocols)」を参照してください。

ほとんどのパッケージタイプで、次の認証情報タイプが有効になっています。

- [パーソナルアクセストークン](../../profile/personal_access_tokens.md): ユーザー権限で認証します。パッケージレジストリの個人使用およびローカル使用に適しています。
- [プロジェクトデプロイトークン](../../project/deploy_tokens/_index.md): プロジェクト内のすべてのパッケージへのアクセスを許可します。多くのユーザーへのプロジェクトアクセス権の付与と取り消しに適しています。
- [グループデプロイトークン](../../project/deploy_tokens/_index.md): グループとそのサブグループ内のすべてのパッケージへのアクセスを許可します。多数のパッケージへのアクセス権をユーザーセットに付与および取り消すのに適しています。
- [ジョブトークン](../../../ci/jobs/ci_job_token.md): パイプラインを実行しているユーザーに対して、ジョブを実行しているプロジェクト内のパッケージへのアクセスを許可します。他の外部プロジェクトへのアクセスを設定できます。
- 組織で2要素認証（2FA）を使用している場合は、スコープが`api`に設定されたパーソナルアクセストークンを使用する必要があります。
- CI/CDパイプラインを使用してパッケージを公開する場合は、CI/CDジョブトークンを使用する必要があります。

{{< alert type="note" >}}

パッケージレジストリへの認証を設定する場合:

- **パッケージレジストリ**プロジェクト設定が[オフになっている](#turn-off-the-package-registry)場合、オーナーロールを持っていても、パッケージレジストリを操作すると`403 Forbidden`エラーが発生します。
- [外部認証](../../../administration/settings/external_authorization.md)がオンになっている場合、デプロイトークンでパッケージレジストリにアクセスすることはできません。

{{< /alert >}}

## GitLab CI/CDを使用する

[GitLab CI/CD](../../../ci/_index.md)を使用して、パッケージをビルドしたり、パッケージレジストリにインポートしたりできます。

### パッケージをビルドするには

`CI_JOB_TOKEN`を使用してGitLabで認証できます。

まず、利用可能な[CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)を使用します。

CI/CDでのGitLabパッケージレジストリの使用に関する詳細は、以下を参照してください。

- [汎用](../generic_packages/_index.md#publish-a-package)
- [Maven](../maven_repository/_index.md#create-maven-packages-with-gitlab-cicd)
- [NPM](../npm_registry/_index.md#publish-a-package-with-a-cicd-pipeline)
- [NuGet](../nuget_repository/_index.md#publish-a-nuget-package-by-using-cicd)
- [PyPi](../pypi_repository/_index.md#authenticate-with-the-gitlab-package-registry)
- [Terraform](../terraform_module_registry/_index.md#authenticate-to-the-terraform-module-registry)

CI/CDを使用してパッケージをビルドする場合、パッケージの詳細を表示すると、拡張されたアクティビティー情報が表示されます。

![パッケージCI/CDアクティビティー](img/package_activity_v12_10.png)

パッケージを公開したパイプラインとそれをトリガーしたコミットおよびユーザーを表示できます。ただし、履歴は特定のパッケージの5つの更新に制限されています。

### パッケージをインポートするには

別のレジストリにビルドされたパッケージがすでにある場合は、[パッケージインポーター](https://gitlab.com/gitlab-org/ci-cd/package-stage/pkgs_importer)を使用してGitLabパッケージレジストリにパッケージをインポートできます。

サポートされているパッケージのリストについては、「[他のリポジトリからパッケージをインポートする](supported_functionality.md#importing-packages-from-other-repositories)」を参照してください。

## ストレージ使用量を削減する

パッケージレジストリのストレージ使用量を削減する方法については、「[パッケージレジストリのストレージ使用量を削減する](reduce_package_registry_storage.md)」を参照してください。

## パッケージレジストリを無効にする

パッケージレジストリは自動的に有効になっています。

GitLab Self-Managedインスタンスでは、管理者はGitLabサイドバーから**パッケージとレジストリ**メニュー項目を削除できます。詳細については、「[GitLabパッケージレジストリの管理](../../../administration/packages/_index.md)」を参照してください。

プロジェクトのパッケージレジストリを特別に削除することもできます。

1. プロジェクトで、**設定>一般**に移動します。
1. **可視性、プロジェクトの機能、権限**セクションを展開し、**パッケージ**機能を無効にします。
1. **変更の保存**を選択します。

**デプロイ>パッケージレジストリ**エントリがサイドバーから削除されます。

## パッケージレジストリの表示レベル権限

[プロジェクト権限](../../permissions.md)は、どのメンバーとユーザーがパッケージをダウンロード、プッシュ、または削除できるかを決定します。

パッケージレジストリの表示レベルはリポジトリとは無関係で、プロジェクトの設定から制御できます。たとえば、パブリックプロジェクトがあり、リポジトリの表示レベルを**プロジェクトメンバーのみ**に設定した場合、パッケージレジストリはパブリックになります。**パッケージレジストリ**の切替をオフにすると、すべてのパッケージレジストリ操作がオフになります。

| プロジェクトの表示レベル | アクション                | 最低限必要な[ロール](../../permissions.md#roles)     |
|--------------------|-----------------------|---------------------------------------------------------|
| パブリック             | パッケージレジストリを表示する | 該当なし。インターネット上の誰でもこのアクションを実行できます。    |
| パブリック             | パッケージを公開する     | デベロッパー                                               |
| パブリック             | パッケージをプルする        | 該当なし。インターネット上の誰でもこのアクションを実行できます。    |
| 内部           | パッケージレジストリを表示する | ゲスト                                                   |
| 内部           | パッケージを公開する     | デベロッパー                                               |
| 内部           | パッケージをプルする        | ゲスト（1）                                               |
| プライベート            | パッケージレジストリを表示する | レポーター                                                |
| プライベート            | パッケージを公開する     | デベロッパー                                               |
| プライベート            | パッケージをプルする        | レポーター（1）                                            |

### 誰でもパッケージレジストリからプルできるようにする

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385994)されました。
- GitLab 17.4で、NuGetグループエンドポイントをサポートするように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/468058)されました。
- GitLab 17.5で、Mavenグループエンドポイントをサポートするように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/468059)されました。
- GitLab 17.5で、Terraformモジュールネームスペースエンドポイントをサポートするように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/468062)されました。

{{< /history >}}

プロジェクトの表示レベルに関係なく、誰でもパッケージレジストリからプルできるようにするには:

1. 左側のサイドバーで、**検索または移動**を選択し、プライベートまたは内部プロジェクトを検索します。
1. **設定>一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **パッケージレジストリからだれでもプルできるようにする**切替をオンにします。
1. **変更の保存**を選択します。

インターネット上の誰でもプロジェクトのパッケージレジストリにアクセスできます。

#### 誰でもプルできる機能を無効にする

前提要件:

- 管理者である必要があります。

**パッケージレジストリからだれでもプルできるようにする**切替をグローバルに非表示にするには:

- [アプリケーション設定を更新](../../../api/settings.md#update-application-settings)して、`package_registry_allow_anyone_to_pull_option`を`false`にします。

**パッケージレジストリからだれでもプルできるようにする**切替をオンにしたプロジェクトでも、匿名ダウンロードはオフになります。

誰でもパッケージレジストリからプルできるようにすると、いくつかの既知の問題が発生します。

- プロジェクトのエンドポイントがサポートされています。
- グループのNuGetレジストリエンドポイントがサポートされています。ただし、NuGetクライアントが認証情報を送信する方法により、匿名ダウンロードは許可されていません。この設定がオンになっていても、GitLabユーザーのみパッケージレジストリからプルできます。
- グループのMavenレジストリエンドポイントがサポートされています。
- ネームスペースのTerraformモジュールレジストリエンドポイントがサポートされています。
- 他のグループおよびインスタンスのエンドポイントは完全にはサポートされていません。グループエンドポイントのサポートは、[エピック14234](https://gitlab.com/groups/gitlab-org/-/epics/14234)で提案されています。
- Composerにはグループエンドポイントしかないため、[Composer](../composer_repository/_index.md#install-a-composer-package)では機能しません。
- Conanでは機能しますが、[`conan search`](../conan_repository/_index.md#search-for-conan-packages-in-the-package-registry)を使用すると機能しません。

## 監査イベント

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.10で、`package_registry_audit_events`という名前の[フラグとともに](../../../administration/feature_flags.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/329588)されました。デフォルトでは無効になっています。

{{< /history >}}

パッケージが公開または削除されたときに、監査イベントを作成します。ネームスペースのオーナーは、[GraphQL API](../../../api/graphql/reference/_index.md#packagesettings)を介して`audit_events_enabled`設定を有効にできます。

次の場所に、監査イベントを表示できます。

- パッケージのプロジェクトがグループにある場合は、[**グループ監査イベント**](../../compliance/audit_events.md#group-audit-events)ページに表示されます。
- パッケージのプロジェクトがユーザーネームスペースにある場合は、[**プロジェクト監査イベント**](../../compliance/audit_events.md#project-audit-events)ページに表示されます。

## コントリビュートを受け入れる

次の表に、コントリビュートを受け入れているサポート対象外のパッケージマネージャー形式を示します。GitLabへのコントリビュート方法については、[開発ガイドライン](../../../development/packages/_index.md)を参照してください。

<!-- vale gitlab_base.Spelling = NO -->

| 形式    | ステータス                                                        |
| --------- | ------------------------------------------------------------- |
| Chef      | [\#36889](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) |
| CocoaPods | [\#36890](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) |
| Conda     | [\#36891](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) |
| CRAN      | [\#36892](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) |
| Opkg      | [\#36894](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) |
| P2        | [\#36895](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) |
| Puppet    | [\#36897](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) |
| RPM       | [\#5932](https://gitlab.com/groups/gitlab-org/-/epics/5128)    |
| SBT       | [\#36898](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) |
| Swift     | [\#12233](https://gitlab.com/gitlab-org/gitlab/-/issues/12233) |
| Vagrant   | [\#36899](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) |

<!-- vale gitlab_base.Spelling = YES -->
