---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 保護パッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.5で`packages_protected_packages`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416395)されました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- 保護ルールの設定**Push protected up to access level**が[変更され](https://gitlab.com/gitlab-org/gitlab/-/issues/416382)、GitLab 17.1で**プッシュに必要な最小アクセスレベル**になりました。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/472655)になりました。機能フラグ`packages_protected_packages`は削除されました。
- Conanの保護されたパッケージは、GitLab 17.6で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/323975) 、[フラグ](../../../administration/feature_flags/_index.md)`packages_protected_packages_conan`という名前が付けられました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- Mavenの保護されたパッケージは、GitLab 17.9で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/323969) 、[フラグ](../../../administration/feature_flags/_index.md)`packages_protected_packages_maven`という名前が付けられました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- GitLab 17.10で`packages_protected_packages_delete`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/516215)されました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- Mavenの保護されたパッケージは、GitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/497082)されました。機能フラグ`packages_protected_packages_maven`は削除されました。
- Conanの保護されたパッケージは、GitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/497811)されました。機能フラグ`packages_protected_packages_conan`は削除されました。
- NuGetの保護されたパッケージは、GitLab 18.0で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/323972) 、[フラグ](../../../administration/feature_flags/_index.md)`packages_protected_packages_nuget`という名前が付けられました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- 保護されたHelmチャートは、GitLab 18.1で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/323973) 、[フラグ](../../../administration/feature_flags/_index.md)`packages_protected_packages_helm`という名前が付けられました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- 汎用保護されたパッケージは、GitLab 18.1で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/323973) 、[フラグ](../../../administration/feature_flags/_index.md)`packages_protected_packages_generic`という名前が付けられました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- 汎用保護されたパッケージは、GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/537971)されました。機能フラグ`packages_protected_packages_generic`は削除されました。
- NuGetの保護されたパッケージは、GitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/524145)されました。機能フラグ`packages_protected_packages_nuget`は削除されました。
- Helmの保護されたパッケージは、GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/538375)されました。機能フラグ`packages_protected_packages_helm`は削除されました。

{{< /history >}}

デフォルトでは、デベロッパー、メンテナー、またはオーナーロールを持つすべてのユーザーが、パッケージを作成、編集、削除できます。どのユーザーがパッケージを変更できるかを制限するには、パッケージ保護ルールを追加します。

GitLabは、npm、PyPI、Maven、およびConanのパッケージの保護をサポートしていますが、[エピック5574](https://gitlab.com/groups/gitlab-org/-/epics/5574)では追加の機能とパッケージ形式の追加が提案されています。

パッケージが保護されている場合、デフォルトの動作では、次の制限がパッケージに適用されます:

| アクション                                 | 最小ロールまたはトークン                                                                     |
|:---------------------------------------|:----------------------------------------------------------------------------------|
| パッケージを保護する                      | メンテナーまたはオーナーのロール。                                                     |
| 新しいパッケージをプッシュする                     | [**プッシュに必要な最小アクセスレベル**](#protect-a-package)で設定されたロール以上。 |
| デプロイトークンで新しいパッケージをプッシュする | プッシュされたパッケージが保護ルールと一致しない場合に限り、有効なデプロイトークン。保護されたパッケージは、デプロイトークンでプッシュすることはできません。 |
| パッケージを削除する                       | [**削除に必要な最小アクセスレベル**](#protect-a-package)で設定されたロール以上。 |

## パッケージを保護する {#protect-a-package}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140473)されました。

{{< /history >}}

前提条件: 

- メンテナーまたはオーナーのロールを持っている必要があります。

パッケージを保護するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **パッケージレジストリ**を展開します。
1. **保護されたパッケージ**で、**保護ルールを追加する**を選択します。
1. フィールドに入力します:
   - **名前パターン**は、保護したいパッケージの名前パターンです。パターンにはワイルドカード (`*`) を含めることができます。
   - **パッケージタイプ**は、保護するパッケージのタイプです。
   - **プッシュに必要な最小アクセスレベル**は、名前パターンに一致するパッケージをプッシュするために必要な最小限のロールです。
   - **削除に必要な最小アクセスレベル**は、名前パターンに一致するパッケージを削除するために必要な最小限のロールです。
1. **保護**を選択します。

パッケージ保護ルールが作成され、設定に表示されます。

### 複数のパッケージを保護する {#protecting-multiple-packages}

ワイルドカードを使用して、同じパッケージ保護ルールで複数のパッケージを保護できます。たとえば、CI/CDパイプライン中にビルドされたすべての一時的なパッケージを保護できます。

次の表に、複数のパッケージに一致するパッケージ保護ルールの例を示します:

| ワイルドカードを含むパッケージ名パターン | 一致するパッケージ                                                           |
|------------------------------------|-----------------------------------------------------------------------------|
| `@group/package-*`                 | `@group/package-prod`、`@group/package-prod-sha123456789`                   |
| `@group/*package`                  | `@group/package`、`@group/prod-package`、`@group/prod-sha123456789-package` |
| `@group/*package*`                 | `@group/package`、`@group/prod-sha123456789-package-v1`                     |

同じパッケージに複数の保護ルールを適用することができます。少なくとも1つの保護ルールがパッケージに適用される場合、そのパッケージは保護されます。

## パッケージ保護ルールを削除し、パッケージの保護を解除する {#delete-a-package-protection-rule-and-unprotect-a-package}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140483)されました。

{{< /history >}}

前提条件: 

- メンテナーまたはオーナーのロールを持っている必要があります。

パッケージの保護を解除するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **パッケージレジストリ**を展開します。
1. **保護されたパッケージ**の下で、削除したい保護ルールの横にある**削除** ({{< icon name="remove" >}}) を選択します。
1. 確認ダイアログで、**削除**を選択します。

パッケージ保護ルールは削除され、設定には表示されません。
