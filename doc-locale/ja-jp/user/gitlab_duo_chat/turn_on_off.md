---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chatの可用性を制御する
---

GitLab Duo Chatは、オン/オフ切り替えと可用性の変更が可能です。

## GitLab.comの場合 {#for-gitlabcom}

GitLab 16.11以降、GitLab Duo Chatは:

- 一般提供されています。
- GitLab Duoシートが割り当てられたすべてのユーザーが利用できます。

[GitLab Duoのオン/オフを切り替える](../gitlab_duo/turn_on_off.md)と、Duo Chatも同時にオン/オフが切り替わります。

## GitLab Self-Managedの場合 {#for-gitlab-self-managed}

Self-ManagedインスタンスのGitLabでGitLab Duo Chatを使用するには、次のいずれかを実行します:

- GitLab AIベンダーモデルとGitLabがホストするクラウドベースのAIゲートウェイを使用する（デフォルトオプション）。
- [GitLab Duo Self-Hostedを使用して、サポートされているセルフホストLLMでAIゲートウェイをセルフホストする](../../administration/gitlab_duo_self_hosted/_index.md#set-up-a-gitlab-duo-self-hosted-infrastructure)。

前提要件: 

- GitLab Duoで最適なユーザーエクスペリエンスと結果を得るには、GitLab 17.2以降が必要です。それ以前のバージョンでも動作する可能性はありますが、エクスペリエンスが低下するおそれがあります。
- サブスクリプションについて:
  - GitLab AIベンダーモデルとクラウドベースのAIゲートウェイを使用している場合は、[GitLabと同期された](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/)PremiumまたはUltimateのサブスクリプションが必要です。GitLab Duo Chatがすぐに動作するように、管理者は[手動でサブスクリプションを同期](#manually-synchronize-your-subscription)できます。
  - GitLab Duo Self-Hostedを使用している場合は、GitLab Ultimateサブスクリプションに加えてDuo Enterpriseアドオンが必要です。
- [ネットワーキング接続を有効にする](../gitlab_duo/setup.md)必要があります。
- [サイレントモード](../../administration/silent_mode/_index.md)がオンになっていないこと。
- お使いのインスタンスのすべてのユーザーが、最新バージョンのIDE拡張機能を使用している必要があります。

その後、お使いのGitLabのバージョンに応じて、GitLab Duo Chatを有効にできます。

### GitLab 16.11以降 {#in-gitlab-1611-and-later}

GitLab 16.11以降、GitLab Duo Chatは:

- 一般提供されています。
- GitLab Duoシートが割り当てられたすべてのユーザーが利用できます。

### それ以前のGitLabバージョン {#in-earlier-gitlab-versions}

GitLab 16.8、16.9、16.10では、GitLab Duo Chatはベータ版で利用できます。GitLab Self-ManagedでGitLab Duo Chatを有効にするには、管理者が実験的機能とベータ機能を有効にする必要があります:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. 左側のサイドバーの下部にある**AIネイティブ機能**を展開し、**実験的機能とベータ版のAIネイティブ機能を有効にする**を選択します。
1. **変更を保存**を選択します。
1. GitLab Duo Chatがすぐに動作するように、[手動でサブスクリプションを同期](#manually-synchronize-your-subscription)する必要があります。

{{< alert type="note" >}}

GitLab Duo Chatベータ版の使用には、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)が適用されます。[GitLab Duo Chat使用時のデータの使用状況](../gitlab_duo/data_usage.md)を参照してください。

{{< /alert >}}

### 手動でサブスクリプションを同期する {#manually-synchronize-your-subscription}

次のいずれかに該当する場合は、[手動でサブスクリプションを同期](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)できます:

- PremiumまたはUltimateのサブスクリプションを購入したばかりの場合、またはGitLab Duo Proのシートを最近割り当てて、GitLab 16.8にアップグレードした場合。
- PremiumまたはUltimateのサブスクリプションを既にお持ちの場合、またはGitLab Duo Proのシートを最近割り当てて、GitLab 16.8にアップグレードした場合。

手動同期を行わない場合、インスタンスでGitLab Duo Chatがアクティブになるまでに最大24時間かかる場合があります。

## GitLab Dedicatedの場合 {#for-gitlab-dedicated}

GitLab 16.11以降のGitLab Dedicatedでは、GitLab Duo Chatは一般提供されており、GitLab Duo ProまたはEnterpriseをお持ちの場合は自動的に有効になります。

GitLab 16.8、16.9、16.10のGitLab Dedicatedでは、GitLab Duo Chatはベータ版で利用できます。

## GitLab Duo Chatをオフにする {#turn-off-gitlab-duo-chat}

GitLab Duo Chatがアクセスできるデータを制限するには、[GitLab Duo機能をオフにする](../gitlab_duo/turn_on_off.md)ための手順に従ってください。

## VS Codeでチャットをオフにする {#turn-off-chat-in-vs-code}

VS CodeでGitLab Duo Chatをオフにするには:

1. **Settings** > **Extensions** > **GitLab Workflow**に移動します。
1. **Enable GitLab Duo Chat assistant**チェックボックスをオフにします。
