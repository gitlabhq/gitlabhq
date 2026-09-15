---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicated for GovernmentでGitLab Duoが正しく設定され、動作していることを確認します。
title: GitLab DuoをGitLab Dedicated for Governmentで設定します。
gitlab_dedicated: yes
---

{{< details >}}

- 提供形態: 政府機関向けGitLab Dedicated

{{< /details >}}

GitLab Dedicated for Governmentでは、GitLab Duo Self-Hostedアーキテクチャを使用する必要があります。GitLabが管理するAIゲートウェイとモデルは利用できません。

> [!note]
> GitLab Duo Agent Platformの機能は、デフォルトで無効になっている機能フラグによって制御されており、GitLab Dedicated for Governmentでは利用できません。

GitLab Duo Self-Hostedを設定するには:

1. [サイレントモードがオフになっていること](../../silent_mode/_index.md#turn-off-silent-mode)を確認してください。
1. AWS GovCloud（US-West）に[GitLab AIゲートウェイをインストール](../../../install/install_ai_gateway.md)します。最適なパフォーマンスのために、[AIゲートウェイとインスタンスを併置](../../../install/install_ai_gateway.md#co-locate-your-ai-gateway-and-instance)してください。
   - [FIPS検証済みのAIゲートウェイイメージ](../../../install/install_ai_gateway.md#fips-validated-images)を使用します。FIPS検証済みのイメージは、[コンテナレジストリ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/9518478?orderBy=PUBLISHED_AT&sort=desc&search%5B%5D=self-hosted)で公開されています。インスタンスが実行しているGitLabバージョンと同じタグが付けられた最新のイメージを選択してください。
   - [Docker](../../../install/install_ai_gateway.md#install-by-using-docker)または[GitLab Helmチャート](../../../install/install_ai_gateway.md#install-by-using-helm-chart)を使用してAIゲートウェイをデプロイできます。各デプロイ方法の詳細については、[セキュリティアップデートとイメージ検証](../../../install/install_ai_gateway.md#security-updates-and-image-verification)を参照してください。
1. AIゲートウェイをインストールした環境で、インスタンスと選択したLLMへのアクセスを有効にするために[ネットワーク設定を構成](../../../install/install_ai_gateway.md#restrict-network-access)してください。
1. ローカルAIゲートウェイへの[アクセスを設定](../../gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway)します。
1. GitLab Duo機能で使用する[セルフホストモデルを追加](../../gitlab_duo_self_hosted/configure_duo_features.md#add-a-self-hosted-model)します。
1. [サポートチケットを作成](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)して、GitLabにインスタンスからセルフホストモデルのAIゲートウェイおよび選択したLLMへのネットワーク接続を有効にするようリクエストしてください。
1. GitLab Duoがチームの生産性に与える影響を測定するために、[GitLab DuoとSDLCのトレンドを表示](../../../user/analytics/duo_and_sdlc_trends.md#view-gitlab-duo-and-sdlc-trends)します。

## 関連トピック {#related-topics}

- [サポートされているモデルとハードウェア要件](../../gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md)
- [GitLab Duo Self-Hostedのトラブルシューティング](../../gitlab_duo_self_hosted/troubleshooting.md)
- [GitLab Duoのヘルスチェックを実行する](_index.md#run-a-health-check-for-gitlab-duo)
