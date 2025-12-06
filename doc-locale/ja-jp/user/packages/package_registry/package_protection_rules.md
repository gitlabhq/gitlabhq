---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 保護パッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.5で`packages_protected_packages`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/416395)されました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- 保護ルール**Push protected up to access level**（プッシュ保護のアクセスレベル） の[名前が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/416382)され、GitLab 17.1で**プッシュに必要な最小アクセスレベル**になりました。
- GitLab 17.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/472655)になりました。機能フラグ`packages_protected_packages`は削除されました。
- Conanの保護されたパッケージはGitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/323975)され、[フラグ付き](../../../administration/feature_flags/_index.md)の名前は`packages_protected_packages_conan`です。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- Mavenの保護されたパッケージはGitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/323969)され、[フラグ付き](../../../administration/feature_flags/_index.md)の名前は`packages_protected_packages_maven`です。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- GitLab 17.10で`packages_protected_packages_delete`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/516215)されました。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- Mavenの保護されたパッケージはGitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/497082)になりました。機能フラグ`packages_protected_packages_maven`は削除されました。
- Conanの保護されたパッケージはGitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/497811)になりました。機能フラグ`packages_protected_packages_conan`は削除されました。
- NuGetの保護されたパッケージはGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/323972)され、[フラグ付き](../../../administration/feature_flags/_index.md)の名前は`packages_protected_packages_nuget`です。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- 保護されたHelmチャートはGitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/323973)され、[フラグ付き](../../../administration/feature_flags/_index.md)の名前は`packages_protected_packages_helm`です。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- 汎用的な保護されたパッケージはGitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/323973)され、[フラグ付き](../../../administration/feature_flags/_index.md)の名前は`packages_protected_packages_generic`です。デフォルトでは無効になっています。これは[実験的機能](../../../policy/development_stages_support.md)です。
- 汎用的な保護されたパッケージはGitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/537971)になりました。機能フラグ`packages_protected_packages_generic`は削除されました。
- NuGetの保護されたパッケージはGitLab 18.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/524145)になりました。機能フラグ`packages_protected_packages_nuget`は削除されました。
- Helmの保護されたチャートはGitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/538375)になりました。機能フラグ`packages_protected_packages_helm`は削除されました。

{{< /history >}}

デフォルトでは、少なくともデベロッパーロールを持つすべてのユーザーは、パッケージを作成、編集、削除できます。どのユーザーがパッケージを変更できるかを制限するには、パッケージ保護ルールを追加します。

GitLabは、NPM、PyPi、Maven、Conanパッケージのパッケージ保護をサポートしていますが、[エピック5574](https://gitlab.com/groups/gitlab-org/-/epics/5574)では、追加機能とパッケージ形式を追加することを提案しています。

パッケージが保護されている場合、デフォルトの動作では、パッケージにこれらの制限が適用されます:

| アクション                                 | 最小ロールまたはトークン                                                                     |
|:---------------------------------------|:----------------------------------------------------------------------------------|
| パッケージを保護する                      | メンテナー以上のロール。                                                     |
| 新しいパッケージをプッシュする                     | [**プッシュに必要な最小アクセスレベル**](#protect-a-package)で設定された最小ロール以上。 |
| デプロイトークンで新しいパッケージをプッシュする | 有効なデプロイトークン、プッシュされたパッケージが保護ルールと一致しない場合に限ります。保護されたパッケージは、デプロイトークンでプッシュできません。 |
| パッケージを削除する                       | [**削除に必要な最小アクセスレベル**](#protect-a-package)で設定された最小ロール以上。 |

## パッケージの保護 {#protect-a-package}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140473)されました。

{{< /history >}}

前提要件:

- メンテナーロール以上が必要です。

パッケージを保護するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **パッケージレジストリ**を展開します。
1. **保護されたパッケージ**で、**保護ルールを追加する**を選択します。
1. フィールドに入力します:
   - **名前パターン**は、保護するパッケージ名のパターンです。パターンには、ワイルドカード（`*`）を含めることができます。
   - **パッケージタイプ**は、保護するパッケージのタイプです。
   - **プッシュに必要な最小アクセスレベル**は、名前パターンに一致するパッケージをプッシュするために必要な最小ロールです。
   - **削除に必要な最小アクセスレベル**は、名前パターンに一致するパッケージを削除するために必要な最小ロールです。
1. **保護**を選択します。

パッケージ保護ルールが作成され、設定に表示されます。

### 複数のパッケージの保護 {#protecting-multiple-packages}

ワイルドカードを使用して、同じパッケージ保護ルールで複数のパッケージを保護できます。たとえば、CI/CDパイプライン中にビルドされた一時的なパッケージをすべて保護できます。

次の表に、複数のパッケージに一致するパッケージ保護ルールの例を示します:

| ワイルドカード付きのパッケージ名パターン | 一致するパッケージ                                                           |
|------------------------------------|-----------------------------------------------------------------------------|
| `@group/package-*`                 | `@group/package-prod`、`@group/package-prod-sha123456789`                   |
| `@group/*package`                  | `@group/package`、`@group/prod-package`、`@group/prod-sha123456789-package` |
| `@group/*package*`                 | `@group/package`、`@group/prod-sha123456789-package-v1`                     |

同じパッケージに複数の保護ルールを適用できます。少なくとも1つの保護ルールがパッケージに適用される場合、そのパッケージは保護されます。

## パッケージ保護ルールを削除して、パッケージの保護を解除します {#delete-a-package-protection-rule-and-unprotect-a-package}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140483)されました。

{{< /history >}}

前提要件:

- メンテナーロール以上が必要です。

パッケージの保護を解除するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **パッケージレジストリ**を展開します。
1. **保護されたパッケージ**で、削除する保護ルールの横にある**削除**（{{< icon name="remove" >}}）を選択します。
1. 確認ダイアログで、**削除**を選択します。

パッケージ保護ルールが削除され、設定に表示されなくなります。
