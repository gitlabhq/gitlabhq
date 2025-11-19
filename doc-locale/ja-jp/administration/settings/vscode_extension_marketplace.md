---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: VS Code拡張機能マーケットプレースをGitLab Self-Managedインスタンスの機能のために構成します。
title: VS Code Extension Marketplaceを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

VS Code拡張機能マーケットプレースを使用すると、Web IDEおよびワークスペースの機能を強化する拡張機能にアクセスできます。管理者は、インスタンス全体の拡張機能マーケットプレースへのアクセスを設定できます。

{{< alert type="note" >}}

VS Code拡張機能マーケットプレースにアクセスするには、ブラウザが`.cdn.web-ide.gitlab-static.net`アセットホストにアクセスできる必要があります。このセキュリティ要件により、サードパーティの拡張機能は分離された状態で実行され、アカウントにアクセスできなくなります。

{{< /alert >}}

## VS Code拡張機能マーケットプレース設定 {#access-vs-code-extension-marketplace-settings}

前提要件: 

- 管理者である必要があります。

VS Code拡張機能マーケットプレース設定にアクセスするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **VS Code Extension Marketplace**を展開します。

## 拡張レジストリを有効にする {#enable-the-extension-registry}

デフォルトでは、GitLabインスタンスは[Open VSX](https://open-vsx.org/)拡張機能レジストリを使用するように設定されています。このデフォルトの設定で拡張機能マーケットプレースを有効にするには、次の手順に従います:

前提要件: 

- 管理者である必要があります。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **VS Code Extension Marketplace**を展開します。
1. **拡張マーケットプレースを有効にする**をオンに切替して、GitLabインスタンス全体で拡張機能マーケットプレースを有効にします。

## 拡張レジストリを変更する {#modify-the-extension-registry}

前提要件: 

- 管理者である必要があります。

拡張レジストリを変更するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **VS Code Extension Marketplace**を展開します。
1. **レジストリ設定を表示する**を展開する。
1. **Open VSX拡張レジストリを使用する**をオフに切替します。
1. VS Code拡張レジストリの**サービスURL**、**アイテムURL**、および**リソースURLテンプレート**の完全なURLを入力します。
1. **変更を保存**を選択します。

拡張レジストリを変更した後:

- アクティブなWeb IDEまたはワークスペースセッションは、更新されるまで、以前のレジストリを引き続き使用します。
- すべてのユーザーは、拡張機能を使用する前に、[アカウントを新しいレジストリと統合する](../../user/profile/preferences.md#integrate-with-the-extension-marketplace)必要があります。
