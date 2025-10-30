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

GitLabパッケージレジストリを使用すると、さまざまな[サポートされているパッケージマネージャー](supported_functionality.md)のプライベートレジストリまたはパブリックレジストリとしてGitLabを使用できます。パッケージを公開して共有すると、ダウンストリームプロジェクトで依存関係として使用できます。

## パッケージのワークフロー {#package-workflows}

GitLabパッケージレジストリを使用して、独自のカスタムパッケージワークフローをビルドする方法を説明します:

- すべてのパッケージを単一のプロジェクトに公開するには、[プロジェクトをパッケージレジストリとして使用](../workflows/project_registry.md)します。

- 単一の[モノレポプロジェクト](../workflows/working_with_monorepos.md)から複数の別々のパッケージを公開できます。

## パッケージを表示する {#view-packages}

プロジェクトまたはグループのパッケージを表示できます:

1. プロジェクトまたはグループに移動します。
1. **デプロイ** > **パッケージレジストリ**に移動します。

このページで、パッケージを検索、ソート、フィルタリングできます。ブラウザからURLをコピーして貼り付けると、検索結果を共有できます。

パッケージマネージャーを設定したり、特定のパッケージをインストールしたりするのに役に立つコードスニペットも提供されています。

グループ内のパッケージを表示する場合:

- グループとグループのプロジェクトに公開されているすべてのパッケージが表示されます。
- 表示されるのは、アクセスできるプロジェクトのみです。
- プロジェクトが非公開の場合、またはプロジェクトのメンバーでない場合、プロジェクトのパッケージは表示されません。

パッケージを作成してアップロードする方法については、[パッケージのタイプ](supported_functionality.md)の手順に従ってください。

## GitLab CI/CDを使用する {#use-gitlab-cicd}

[GitLab CI/CD](../../../ci/_index.md)を使用して、パッケージをビルドしたり、パッケージレジストリにインポートしたりできます。

### パッケージをビルドするには {#to-build-packages}

`CI_JOB_TOKEN`を使用してGitLabで認証できます。

開始するには、利用可能な[CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)を使用できます。

GitLabパッケージレジストリでのCI/CDの使用の詳細については、以下を参照してください:

- [汎用](../generic_packages/_index.md#publish-a-package)
- [Maven](../maven_repository/_index.md#create-maven-packages-with-gitlab-cicd)
- [NPM](../npm_registry/_index.md#publish-a-package-with-a-cicd-pipeline)
- [NuGet](../nuget_repository/_index.md#with-a-cicd-pipeline)
- [PyPI](../pypi_repository/_index.md#authenticate-with-the-gitlab-package-registry)
- [Terraform](../terraform_module_registry/_index.md#authenticate-to-the-terraform-module-registry)

CI/CDを使用してパッケージをビルドする場合、パッケージの詳細を表示すると、拡張されたアクティビティー情報が表示されます:

![パッケージCI/CDアクティビティー](img/package_activity_v12_10.png)

パッケージを公開したパイプライン、これをトリガーしたコミットとユーザーを表示できます。ただし、特定のパッケージについての履歴は、5件の更新に制限されています。

### パッケージをインポートするには {#to-import-packages}

別のレジストリにビルドされたパッケージがすでにある場合は、[パッケージインポーター](https://gitlab.com/gitlab-org/ci-cd/package-stage/pkgs_importer)を使用してGitLabパッケージレジストリにパッケージをインポートできます。

サポートされているパッケージのリストについては、[他のリポジトリからパッケージをインポートする](supported_functionality.md#importing-packages-from-other-repositories)を参照してください。

## ストレージ使用量を削減する {#reduce-storage-usage}

パッケージレジストリのストレージ使用率を削減する方法については、[パッケージレジストリのストレージ使用率を削減する](reduce_package_registry_storage.md)を参照してください。

## パッケージレジストリを無効にする {#turn-off-the-package-registry}

パッケージレジストリは自動的に有効になります。

GitLab Self-Managedインスタンスの場合、管理者はGitLabサイドバーから**パッケージとレジストリ**メニュー項目を削除できます。詳細については、[GitLabパッケージレジストリの管理](../../../administration/packages/_index.md)を参照してください。

プロジェクトのパッケージレジストリを削除することもできます。具体的には以下を実行します:

1. プロジェクトで、**設定** > **一般**に移動します。
1. **可視性、プロジェクトの機能、権限**セクションを展開して、**パッケージ**機能を無効にします。
1. **変更を保存**を選択します。

**デプロイ** > **パッケージレジストリ**エントリがサイドバーから削除されます。

## パッケージレジストリの表示レベル権限 {#package-registry-visibility-permissions}

[プロジェクト権限](../../permissions.md)を使用すると、パッケージをダウンロード、プッシュ、または削除できるメンバーとユーザーを指定できます。

パッケージレジストリの表示レベルはリポジトリには依存しておらず、プロジェクト設定から制御できます。たとえば、公開プロジェクトの場合、リポジトリの表示レベルを**プロジェクトメンバーのみ**に設定すると、パッケージレジストリは公開されます。**パッケージレジストリ**の切替をオフにすると、すべてのパッケージレジストリ操作がオフになります。

| プロジェクトの表示レベル | アクション                | 最低限必要な[ロール](../../permissions.md#roles)     |
|--------------------|-----------------------|---------------------------------------------------------|
| 公開             | パッケージレジストリを表示する | 該当なし。インターネット上のすべてのユーザーがこのアクションを実行できる。    |
| 公開             | パッケージを公開する     | デベロッパー                                               |
| 公開             | パッケージをプルする        | 該当なし。インターネット上のすべてのユーザーがこのアクションを実行できる。    |
| 内部           | パッケージレジストリを表示する | ゲスト                                                   |
| 内部           | パッケージを公開する     | デベロッパー                                               |
| 内部           | パッケージをプルする        | ゲスト（1）                                               |
| プライベート            | パッケージレジストリを表示する | レポーター                                                |
| プライベート            | パッケージを公開する     | デベロッパー                                               |
| プライベート            | パッケージをプルする        | レポーター（1）                                            |

### すべてのユーザーにパッケージレジストリからのプルを許可する {#allow-anyone-to-pull-from-package-registry}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/385994)されました。
- GitLab 17.4で、NuGetグループエンドポイントをサポートするように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/468058)されました。
- GitLab 17.5で、Mavenグループエンドポイントをサポートするように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/468059)されました。
- GitLab 17.5で、Terraformモジュールのネームスペースエンドポイントをサポートするように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/468062)されました。

{{< /history >}}

プロジェクトの表示レベルを問わず、パッケージレジストリからのプルをすべてのユーザーに許可するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プライベートまたは内部プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **Allow anyone to pull from package registry**（パッケージレジストリからだれでもプルできるようにする）切替をオンにします。
1. **変更を保存**をクリックします。

インターネット上のすべてのユーザーが、このプロジェクトのパッケージレジストリにアクセスできるようになります。

#### すべてのユーザーがプルできるようにする許可を無効にする {#disable-allowing-anyone-to-pull}

前提要件:

- 管理者である必要があります。

**Allow anyone to pull from package registry**（パッケージレジストリからだれでもプルできるようにする）切替をグローバルに非表示にするには:

- [アプリケーション設定を更新](../../../api/settings.md#update-application-settings)して、`package_registry_allow_anyone_to_pull_option`を`false`にします。

**Allow anyone to pull from Package Registry**（パッケージレジストリからだれでもプルできるようにする）切替をオンにしたプロジェクトでも、匿名ダウンロードはオフになります。

すべてのユーザーにパッケージレジストリからのプルを許可する場合、既知の問題が以下のとおりいくつかあります:

- プロジェクトのエンドポイントはサポートされています。
- グループのNuGetレジストリエンドポイントはサポートされています。ただし、NuGetクライアントが認証情報を送信する方法のため、匿名ダウンロードは許可されません。この設定がオンになっていても、パッケージレジストリからプルできるのはGitLabユーザーのみです。
- グループのMavenレジストリエンドポイントはサポートされています。
- ネームスペースのTerraformモジュールレジストリエンドポイントはサポートされています。
- 他のグループやインスタンスのエンドポイントは完全にはサポートされていません。グループエンドポイントのサポートは、[エピック14234](https://gitlab.com/groups/gitlab-org/-/epics/14234)で提案されています。
- Composerにはグループエンドポイントしかないため、[Composer](../composer_repository/_index.md#install-a-composer-package)では機能しません。
- Conanでは機能します。ただし、[`conan search`](../conan_1_repository/_index.md#search-for-conan-packages-in-the-package-registry)を使用する場合は機能しません。

## 監査イベント {#audit-events}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.10で`package_registry_audit_events`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/329588)されました。デフォルトでは無効になっています。
- GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554817)になりました。機能フラグ`package_registry_audit_events`は削除されました。

{{< /history >}}

パッケージが公開または削除されると、監査イベントが作成されます。ネームスペースのオーナーは、[GraphQL API](../../../api/graphql/reference/_index.md#packagesettings)を介して`audit_events_enabled`設定を有効にできます。

以下のとおり監査イベントを表示できます:

- パッケージのプロジェクトがグループ内にある場合は、[**グループ監査イベント**](../../compliance/audit_events.md#group-audit-events)ページに表示されます。
- パッケージのプロジェクトがユーザーネームスペースにある場合は、[**プロジェクト監査イベント**](../../compliance/audit_events.md#project-audit-events)ページに表示されます。

## コントリビュートを受け入れる {#accepting-contributions}

次の表に、サポートされていないパッケージ形式を示します。これらの形式のサポートを追加するために、GitLabにコントリビュートすることを検討してください。

<!-- vale gitlab_base.Spelling = NO -->

| 形式    | 状態                                                        |
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
