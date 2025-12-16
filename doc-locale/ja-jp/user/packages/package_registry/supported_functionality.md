---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: サポートされているパッケージパッケージマネージャーと機能
---

GitLabパッケージレジストリは、パッケージの種類ごとに異なる機能をサポートしています。このサポートには、パッケージの公開とプル、リクエストの転送、重複の管理、認証が含まれます。

## サポートされているパッケージマネージャー {#supported-package-managers}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

すべてのパッケージマネージャー形式が本番環境での使用に対応しているわけではありません。

{{< /alert >}}

パッケージレジストリは、次のパッケージマネージャーの種類をサポートしています:

| パッケージの種類                                      | ステータス |
|---------------------------------------------------|--------|
| [Composer](../composer_repository/_index.md)      | [ベータ](https://gitlab.com/groups/gitlab-org/-/epics/6817) |
| [Conan 1](../conan_1_repository/_index.md)            | [実験的機能](https://gitlab.com/groups/gitlab-org/-/epics/6816) |
| [Conan 2](../conan_2_repository/_index.md)            | [実験的機能](https://gitlab.com/groups/gitlab-org/-/epics/8258) |
| [Debian](../debian_repository/_index.md)          | [実験的機能](https://gitlab.com/groups/gitlab-org/-/epics/6057) |
| [汎用パッケージ](../generic_packages/_index.md) | 一般提供     |
| [Go](../go_proxy/_index.md)                       | [実験的機能](https://gitlab.com/groups/gitlab-org/-/epics/3043) |
| [Helm](../helm_repository/_index.md)              | [ベータ](https://gitlab.com/groups/gitlab-org/-/epics/6366) |
| [Maven](../maven_repository/_index.md)            | 一般提供      |
| [npm](../npm_registry/_index.md)                  | 一般提供      |
| [NuGet](../nuget_repository/_index.md)            | 一般提供      |
| [PyPI](../pypi_repository/_index.md)              | 一般提供      |
| [Ruby gem](../rubygems_registry/_index.md)       | [実験的機能](https://gitlab.com/groups/gitlab-org/-/epics/3200) |

[各ステータスの意味を表示](../../../policy/development_stages_support.md)。

[API](../../../api/packages.md)を使用してパッケージレジストリを管理することもできます。

## パッケージの公開 {#publishing-packages}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パッケージは、プロジェクト、グループ、またはインスタンスに公開できます。

| パッケージの種類                                           | プロジェクト | グループ | インスタンス |
|--------------------------------------------------------|---------|-------|----------|
| [Maven (`mvn`を使用)](../maven_repository/_index.md)    | 可       | 不可     | 不可        |
| [Maven (`gradle`を使用)](../maven_repository/_index.md) | 可       | 不可     | 不可        |
| [Maven (`sbt`を使用)](../maven_repository/_index.md)    | 不可       | 不可     | 不可        |
| [npm](../npm_registry/_index.md)                       | 可       | 不可     | 不可        |
| [NuGet](../nuget_repository/_index.md)                 | 可       | 不可     | 不可        |
| [PyPI](../pypi_repository/_index.md)                   | 可       | 不可     | 不可        |
| [汎用パッケージ](../generic_packages/_index.md)      | 可       | 不可     | 不可        |
| [Terraform](../terraform_module_registry/_index.md)    | 可       | 不可     | 不可        |
| [Composer](../composer_repository/_index.md)           | 不可       | 可     | 不可        |
| [Conan 1](../conan_1_repository/_index.md)             | 可       | 不可     | 可        |
| [Conan 2](../conan_2_repository/_index.md)             | 可       | 不可     | 不可        |
| [Helm](../helm_repository/_index.md)                   | 可       | 不可     | 不可        |
| [Debian](../debian_repository/_index.md)               | 可       | 不可     | 不可        |
| [Go](../go_proxy/_index.md)                            | 可       | 不可     | 不可        |
| [Ruby gem](../rubygems_registry/_index.md)            | 可       | 不可     | 不可        |

## パッケージのプル {#pulling-packages}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パッケージは、プロジェクト、グループ、またはインスタンスからプルできます。

| パッケージの種類                                           | プロジェクト | グループ | インスタンス |
|--------------------------------------------------------|---------|-------|----------|
| [Maven (`mvn`を使用)](../maven_repository/_index.md)    | 可       | 可     | 可        |
| [Maven (`gradle`を使用)](../maven_repository/_index.md) | 可       | 可     | 可        |
| [Maven (`sbt`を使用)](../maven_repository/_index.md)    | 可       | 可     | 可        |
| [npm](../npm_registry/_index.md)                       | 可       | 可     | 可        |
| [NuGet](../nuget_repository/_index.md)                 | 可       | 可     | 不可        |
| [PyPI](../pypi_repository/_index.md)                   | 可       | 可     | 不可        |
| [汎用パッケージ](../generic_packages/_index.md)      | 可       | 不可     | 不可        |
| [Terraform](../terraform_module_registry/_index.md)    | 不可       | 可     | 不可        |
| [Composer](../composer_repository/_index.md)           | 可       | 可     | 不可        |
| [Conan 1](../conan_1_repository/_index.md)             | 可       | 不可     | 可        |
| [Conan 2](../conan_2_repository/_index.md)             | 可       | 不可     | 不可        |
| [Helm](../helm_repository/_index.md)                   | 可       | 不可     | 不可        |
| [Debian](../debian_repository/_index.md)               | 可       | 不可     | 不可        |
| [Go](../go_proxy/_index.md)                            | 可       | 不可     | 可        |
| [Ruby gem](../rubygems_registry/_index.md)            | 可       | 不可     | 不可        |

## リクエストの転送 {#forwarding-requests}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトのパッケージレジストリにパッケージが見つからない場合、GitLabはリクエストを対応するパブリックレジストリに転送できます。たとえば、Maven Central、npmjs、またはPyPiなどです。

デフォルトの転送動作はパッケージの種類によって異なり、[依存関係の混乱](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610)が発生する脆弱性を引き起こす可能性があります。

関連するセキュリティリスクを軽減するには、次の手順に従います:

- パッケージがアクティブに使用されていないことを確認します。
- リクエストの転送を無効にします:
  - インスタンス管理者は、**管理者**エリアの[**Continuous Integration**（継続的インテグレーション）セクション](../../../administration/settings/continuous_integration.md#control-package-forwarding)で転送を無効にできます。
  - グループオーナーは、グループ設定の**Packages and Registries**（パッケージとレジストリ）セクションで転送を無効にできます。
- Gitのようなバージョン管理されたツールを実装して、パッケージへの変更を追跡します。

| パッケージの種類                                           | リクエストの転送をサポート | セキュリティに関する考慮事項 |
|--------------------------------------------------------|-----------------------------|------------------------|
| [Maven (`mvn`を使用)](../maven_repository/_index.md)    | [はい（デフォルトで無効）](../../../administration/settings/continuous_integration.md#control-package-forwarding) | セキュリティのために明示的なオプトインが必要です。 |
| [Maven (`gradle`を使用)](../maven_repository/_index.md) | [はい（デフォルトで無効）](../../../administration/settings/continuous_integration.md#control-package-forwarding) | セキュリティのために明示的なオプトインが必要です。 |
| [Maven (`sbt`を使用)](../maven_repository/_index.md)    | [はい（デフォルトで無効）](../../../administration/settings/continuous_integration.md#control-package-forwarding) | セキュリティのために明示的なオプトインが必要です。 |
| [npm](../npm_registry/_index.md)                       | [はい](../../../administration/settings/continuous_integration.md#control-package-forwarding) | プライベートパッケージの場合は無効にすることを検討してください。 |
| [NuGet](../nuget_repository/_index.md)                 | 不可                           | 不可 |
| [PyPI](../pypi_repository/_index.md)                   | [はい](../../../administration/settings/continuous_integration.md#control-package-forwarding) | プライベートパッケージの場合は無効にすることを検討してください。 |
| [汎用パッケージ](../generic_packages/_index.md)      | 不可                           | 不可 |
| [Terraform](../terraform_module_registry/_index.md)    | 不可                           | 不可 |
| [Composer](../composer_repository/_index.md)           | 不可                           | 不可 |
| [Conan 1](../conan_1_repository/_index.md)               | 不可                           | 不可 |
| [Conan 2](../conan_2_repository/_index.md)               | 不可                           | 不可 |
| [Helm](../helm_repository/_index.md)                   | 不可                           | 不可 |
| [Debian](../debian_repository/_index.md)               | 不可                           | 不可 |
| [Go](../go_proxy/_index.md)                            | 不可                           | 不可 |
| [Ruby gem](../rubygems_registry/_index.md)            | 不可                           | 不可 |

## パッケージの削除 {#deleting-packages}

パッケージのリクエストがパブリックレジストリに転送される場合、パッケージを削除すると、[依存関係の混乱](https://medium.com/@alex.birsan/dependency-confusion-4a5d60fec610)の脆弱性になる可能性があります。

システムが削除されたパッケージをプルしようとすると、リクエストがパブリックレジストリに転送されます。パブリックレジストリに同じ名前とバージョンのパッケージが見つかった場合、代わりにそのパッケージがプルされます。レジストリからプルされたパッケージが予想されるものではない可能性があり、悪意のあるものである可能性さえあります。

関連するセキュリティリスクを軽減するために、パッケージを削除する前に、次のことを行います:

- パッケージがアクティブに使用されていないことを確認します。
- リクエストの転送を無効にします:
  - インスタンス管理者は、**管理者**エリアの[**Continuous Integration**（継続的インテグレーション）セクション](../../../administration/settings/continuous_integration.md#control-package-forwarding)で転送を無効にできます。
  - グループオーナーは、グループ設定の**Packages and Registries**（パッケージとレジストリ）セクションで転送を無効にできます。

## 他のリポジトリからのパッケージのインポート {#importing-packages-from-other-repositories}

GitLabパイプラインを使用して、Maven CentralやArtifactoryなどの他のリポジトリから、[package importer tool](https://gitlab.com/gitlab-org/ci-cd/package-stage/pkgs_importer)でパッケージをインポートできます。

| パッケージの種類                                           | インポーターは利用可能ですか？ |
|--------------------------------------------------------|---------------------|
| [Maven (`mvn`を使用)](../maven_repository/_index.md)    | 可                   |
| [Maven (`gradle`を使用)](../maven_repository/_index.md) | 可                   |
| [Maven (`sbt`を使用)](../maven_repository/_index.md)    | 可                   |
| [npm](../npm_registry/_index.md)                       | 可                   |
| [NuGet](../nuget_repository/_index.md)                 | 可                   |
| [PyPI](../pypi_repository/_index.md)                   | 可                   |
| [汎用パッケージ](../generic_packages/_index.md)      | 不可                   |
| [Terraform](../terraform_module_registry/_index.md)    | 不可                   |
| [Composer](../composer_repository/_index.md)           | 不可                   |
| [Conan 1](../conan_1_repository/_index.md)             | 不可                   |
| [Conan 2](../conan_2_repository/_index.md)             | 不可                   |
| [Helm](../helm_repository/_index.md)                   | 不可                   |
| [Debian](../debian_repository/_index.md)               | 不可                   |
| [Go](../go_proxy/_index.md)                            | 不可                   |
| [Ruby gem](../rubygems_registry/_index.md)            | 不可                   |

## 重複の許可または防止 {#allow-or-prevent-duplicates}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デフォルトでは、GitLabのパッケージレジストリは、特定のパッケージマネージャー形式のデフォルトに基づいて、重複を許可または防止します。

| パッケージの種類                                           | 重複は許可されますか？ |
|--------------------------------------------------------|---------------------|
| [Maven (`mvn`を使用)](../maven_repository/_index.md)    | Y（構成可能）    |
| [Maven (`gradle`を使用)](../maven_repository/_index.md) | Y（構成可能）    |
| [Maven (`sbt`を使用)](../maven_repository/_index.md)    | Y（構成可能）    |
| [npm](../npm_registry/_index.md)                       | 不可                   |
| [NuGet](../nuget_repository/_index.md)                 | 可                   |
| [PyPI](../pypi_repository/_index.md)                   | 不可                   |
| [汎用パッケージ](../generic_packages/_index.md)      | Y（構成可能）    |
| [Terraform](../terraform_module_registry/_index.md)    | 不可                   |
| [Composer](../composer_repository/_index.md)           | 不可                   |
| [Conan 1](../conan_1_repository/_index.md)             | 不可                   |
| [Conan 2](../conan_2_repository/_index.md)             | 不可                   |
| [Helm](../helm_repository/_index.md)                   | 可                   |
| [Debian](../debian_repository/_index.md)               | 可                   |
| [Go](../go_proxy/_index.md)                            | 不可                   |
| [Ruby gem](../rubygems_registry/_index.md)            | 可                   |

## レジストリで認証 {#authenticate-with-the-registry}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

認証は、使用しているパッケージマネージャーによって異なります。特定のパッケージタイプでサポートされている認証プロトコルについては、「[認証プロトコル](#authentication-protocols)」を参照してください。

ほとんどのパッケージの種類では、次の認証トークンが有効です:

- [パーソナルアクセストークン](../../profile/personal_access_tokens.md)
- [プロジェクトデプロイトークン](../../project/deploy_tokens/_index.md)
- [グループデプロイトークン](../../project/deploy_tokens/_index.md)
- [CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)

次の表に、特定のパッケージマネージャーでサポートされている認証トークンを示します:

| パッケージの種類                                           | サポートされているトークン                                                       |
|--------------------------------------------------------|------------------------------------------------------------------------|
| [Maven (`mvn`を使用)](../maven_repository/_index.md)    | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）、プロジェクトアクセス |
| [Maven (`gradle`を使用)](../maven_repository/_index.md) | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）、プロジェクトアクセス |
| [Maven (`sbt`を使用)](../maven_repository/_index.md)    | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）、プロジェクトアクセス |
| [npm](../npm_registry/_index.md)                       | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）、プロジェクトアクセス |
| [NuGet](../nuget_repository/_index.md)                 | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）、プロジェクトアクセス |
| [PyPI](../pypi_repository/_index.md)                   | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）、プロジェクトアクセス |
| [汎用パッケージ](../generic_packages/_index.md)      | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）、プロジェクトアクセス |
| [Terraform](../terraform_module_registry/_index.md)    | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）、プロジェクトアクセス |
| [Composer](../composer_repository/_index.md)           | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）、プロジェクトアクセス |
| [Conan 1](../conan_1_repository/_index.md)                 | 個人アクセスのトークン、ジョブトークン、プロジェクトアクセス                            |
| [Conan 2](../conan_2_repository/_index.md)                 | 個人アクセスのトークン、ジョブトークン、プロジェクトアクセス                            |
| [Helm](../helm_repository/_index.md)                   | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）                 |
| [Debian](../debian_repository/_index.md)               | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）                 |
| [Go](../go_proxy/_index.md)                            | 個人アクセスのトークン、ジョブトークン、プロジェクトアクセス                            |
| [Ruby gem](../rubygems_registry/_index.md)            | 個人アクセスのトークン、ジョブトークン、デプロイ（プロジェクトまたはグループ）                 |

{{< alert type="note" >}}

パッケージレジストリへの認証を構成する場合:

- **パッケージレジストリ**プロジェクトの設定が[オフに指定](_index.md#turn-off-the-package-registry)されている場合、オーナーロールが付与されていても、パッケージレジストリを操作すると`403 Forbidden`エラーが発生します。
- [外部認証](../../../administration/settings/external_authorization.md)がオンになっている場合、デプロイトークンではパッケージレジストリにアクセスできません。
- 組織が2要素認証（2FA）を使用している場合、スコープが`api`に設定されたパーソナルアクセストークンを使用する必要があります。
- CI/CDパイプラインを使用してパッケージを公開する場合は、CI/CDジョブトークンを使用する必要があります。

{{< /alert >}}

### 認証プロトコル {#authentication-protocols}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- Mavenパッケージの基本認証は、GitLab 16.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/212854)。

{{< /history >}}

次の認証プロトコルがサポートされています:

| パッケージの種類                                           | サポートされているAuthNプロトコル                                    |
|--------------------------------------------------------|-------------------------------------------------------------|
| [Maven (`mvn`を使用)](../maven_repository/_index.md)    | ヘッダー、基本認証                                         |
| [Maven (`gradle`を使用)](../maven_repository/_index.md) | ヘッダー、基本認証                                         |
| [Maven (`sbt`を使用)](../maven_repository/_index.md)    | 基本認証（[プル](#pulling-packages)のみ）          |
| [npm](../npm_registry/_index.md)                       | OAuth                                                       |
| [NuGet](../nuget_repository/_index.md)                 | 基本認証                                                  |
| [PyPI](../pypi_repository/_index.md)                   | 基本認証                                                  |
| [汎用パッケージ](../generic_packages/_index.md)      | 基本認証                                                  |
| [Terraform](../terraform_module_registry/_index.md)    | トークン                                                       |
| [Composer](../composer_repository/_index.md)           | OAuth                                                       |
| [Conan 1](../conan_1_repository/_index.md)                 | OAuth、基本認証                                           |
| [Conan 2](../conan_2_repository/_index.md)                 | OAuth、基本認証                                           |
| [Helm](../helm_repository/_index.md)                   | 基本認証                                                  |
| [Debian](../debian_repository/_index.md)               | 基本認証                                                  |
| [Go](../go_proxy/_index.md)                            | 基本認証                                                  |
| [Ruby gem](../rubygems_registry/_index.md)            | トークン                                                       |

## サポートされているハッシュの種類 {#supported-hash-types}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ハッシュ値は、正しいパッケージを使用していることを確認するために使用されます。これらの値は、ユーザーインターフェースまたは[API](../../../api/packages.md)で表示できます。

パッケージレジストリは、次のハッシュの種類をサポートしています:

| パッケージの種類                                           | サポートされているハッシュ                 |
|--------------------------------------------------------|----------------------------------|
| [Maven (`mvn`を使用)](../maven_repository/_index.md)    | MD5、SHA1                        |
| [Maven (`gradle`を使用)](../maven_repository/_index.md) | MD5、SHA1                        |
| [Maven (`sbt`を使用)](../maven_repository/_index.md)    | MD5、SHA1                        |
| [npm](../npm_registry/_index.md)                       | SHA1                             |
| [NuGet](../nuget_repository/_index.md)                 | 該当なし                   |
| [PyPI](../pypi_repository/_index.md)                   | MD5、SHA256                      |
| [汎用パッケージ](../generic_packages/_index.md)      | SHA256                           |
| [Composer](../composer_repository/_index.md)           | 該当なし                   |
| [Conan 1](../conan_1_repository/_index.md)             | MD5、SHA1                        |
| [Conan 2](../conan_2_repository/_index.md)             | MD5、SHA1                        |
| [Helm](../helm_repository/_index.md)                   | 該当なし                   |
| [Debian](../debian_repository/_index.md)               | MD5、SHA1、SHA256                |
| [Go](../go_proxy/_index.md)                            | MD5、SHA1、SHA256                |
| [Ruby gem](../rubygems_registry/_index.md)            | MD5、SHA1、SHA256（gemspecのみ） |
