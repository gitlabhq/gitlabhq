---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicated for GovernmentでGitLab Duoが正しく設定され、動作していることを確認します。
title: GitLab Dedicated for GovernmentでGitLab Duoを設定する
gitlab_dedicated: yes
---

{{< details >}}

- 提供形態: 政府機関向けGitLab Dedicated

{{< /details >}}

GitLab Dedicated for Governmentでは、FedRAMP承認モデルを備えたGitLab Duo Self-Hostedを使用する必要があります。クラウドベースのAIゲートウェイおよびベンダーモデルは利用できません。

> [!note]
> GitLab Duo Agent Platformの機能は、デフォルトで無効になっている機能フラグによって制御されており、GitLab Dedicated for Governmentでは利用できません。

GitLab Duo Self-Hostedを設定するには:

1. [ベータおよび実験的機能を有効にする](../../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)。
1. [サイレントモードをオフ](../../silent_mode/_index.md#turn-off-silent-mode)にしてください。
1. 送信接続をセルフホスト型AIゲートウェイに許可するには、[サポートチケットを作成](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)してAIゲートウェイURLへの開放をリクエストします。
1. [プライベートインフラストラクチャを設定する](../../gitlab_duo_self_hosted/_index.md#set-up-a-private-infrastructure)。

## 関連トピック {#related-topics}

- [サポートされているモデルとハードウェア要件](../../gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md)
- [GitLab Duo Self-Hostedのトラブルシューティング](../../gitlab_duo_self_hosted/troubleshooting.md)
- [GitLab Duoのヘルスチェックを実行する](_index.md#run-a-health-check-for-gitlab-duo)
