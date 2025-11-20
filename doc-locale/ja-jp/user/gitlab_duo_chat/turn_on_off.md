---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoチャットの利用可否を制御
---

GitLab Duoチャットはオン/オフを切り替えたり、利用可否を変更したりできます。

## GitLab.comの場合 {#for-gitlabcom}

GitLab 16.11以降、GitLab Duoチャットは次のようになります。:

- 一般提供。
- 割り当てられたGitLab Duoシートを持つすべてのユーザーが利用できます。

[GitLab Duoをオンまたはオフにする](../gitlab_duo/turn_on_off.md)と、Duoチャットもオンまたはオフになります。

## GitLab Self-Managedの場合 {#for-gitlab-self-managed}

Self-ManagedインスタンスのGitLabでGitLab Duoチャットを使用するには、次のいずれかを実行します。:

- GitLabでホストされているGitLab AIベンダーモデルとクラウドベースのAIゲートウェイを使用します（デフォルトオプション）。
- [GitLab Duo Self-Hostedを使用してAIゲートウェイをセルフホストし、サポートされているセルフホスト大規模言語モデルを使用します](../../administration/gitlab_duo_self_hosted/_index.md#set-up-a-gitlab-duo-self-hosted-infrastructure)。

前提要件: 

- 最高のユーザーエクスペリエンスと結果を得るには、GitLab DuoでGitLab 17.2以降が必要です。以前のバージョンでも引き続き動作する可能性はありますが、エクスペリエンスが低下するおそれがあります。
- サブスクリプションについて:
  - GitLab AIベンダーモデルとクラウドベースのAIゲートウェイを使用している場合は、GitLabと[同期された](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/)PremiumまたはUltimateのサブスクリプションが必要です。GitLab Duoチャットがすぐに動作するように、管理者は[手動でサブスクリプションを同期](#manually-synchronize-your-subscription)できます。
  - GitLab Duo Self-Hostedを使用している場合は、GitLab Duo EnterpriseアドオンのUltimateサブスクリプションが必要です。
- [有効なネットワーキング接続](../gitlab_duo/setup.md)が必要です。
- [サイレントモード](../../administration/silent_mode/_index.md)をオンにしないでください。
- お使いのインスタンスのすべてのユーザーが、最新バージョンのIDE拡張機能を備えている必要があります。

次に、お使いのGitLabのバージョンに応じて、GitLab Duoチャットを有効にできます。

### GitLab 16.11以降 {#in-gitlab-1611-and-later}

GitLab 16.11以降、GitLab Duoチャットは次のようになります。:

- 一般提供。
- 割り当てられたGitLab Duoシートを持つすべてのユーザーが利用できます。

### 以前のGitLabバージョン {#in-earlier-gitlab-versions}

GitLab 16.8、16.9、および16.10では、GitLab Duoチャットはベータ版で利用できます。Self-ManagedインスタンスのGitLabでGitLab Duoチャットを有効にするには、管理者が実験的およびベータ機能を有効にする必要があります。:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. 左側のサイドバーの下部にある**AIネイティブ機能**を展開し、**Enable Experiment and Beta AI-native features**（AIネイティブ機能の実験ベータを有効にする）を選択します。
1. **変更を保存**を選択します。
1. GitLab Duoチャットがすぐに動作するように、[手動でサブスクリプションを同期](#manually-synchronize-your-subscription)する必要があります。

{{< alert type="note" >}}

GitLab Duoチャットベータ版の使用には、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)が適用されます。[GitLab Duoチャット使用時のデータの使用状況](../gitlab_duo/data_usage.md)について説明します。

{{< /alert >}}

### 手動でサブスクリプションを同期 {#manually-synchronize-your-subscription}

次のいずれかに該当する場合は、[手動でサブスクリプションを同期](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)できます。:

- PremiumまたはUltimateティアのサブスクリプションを購入したばかりの場合、またはGitLab Duo Proのシートを最近割り当てて、GitLab 16.8にアップグレードした場合。
- PremiumまたはUltimateティアのサブスクリプションを既にお持ちの場合、またはGitLab Duo Proのシートを最近割り当てて、GitLab 16.8にアップグレードした場合。

手動で同期しないと、インスタンスでGitLab Duoチャットがアクティブになるまでに最大24時間かかる場合があります。

## GitLab Dedicatedの場合 {#for-gitlab-dedicated}

GitLab 16.11以降のGitLab Dedicatedでは、GitLab Duoチャットは一般提供されており、GitLab Duo ProまたはEnterpriseをお持ちの場合は自動的に有効になります。

GitLab 16.8、16.9、および16.10のGitLab Dedicatedでは、GitLab Duoチャットはベータ版で利用できます。

## GitLab Duoチャットをオフにする {#turn-off-gitlab-duo-chat}

GitLab Duoチャットがアクセスできるデータを制限するには、[GitLab Duo機能をオフにする](../gitlab_duo/turn_on_off.md)ための手順に従ってください。

## VS Codeでチャットをオフにする {#turn-off-chat-in-vs-code}

VS CodeでGitLab Duoチャットをオフにするには:

1. **設定** > **Extensions**（拡張機能） > **GitLab Workflow**（GitLab Workflow）に移動します。
1. **Enable GitLab Duo Chat assistant**（GitLab Duo Chatアシスタントを有効にする）チェックボックスをオフにします。
