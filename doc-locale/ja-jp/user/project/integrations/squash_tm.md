---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Squash TM
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/337855)されました。

{{< /history >}}

[Squash TM](https://www.squashtest.com/en/squash-gitlab-platform)インテグレーションをGitLabで有効にして構成すると、GitLabで作成されたイシュー（通常はユーザーストーリー）はSquash TMの要件として同期され、テストの進捗状況がGitLabイシューでレポートされます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Squash TMとGitLabのインテグレーションによりDevSecOpsのワークフローを最適化する概要については、[SDLCで要件とテスト管理を活用する](https://www.youtube.com/watch?v=XAiNUmBiqm4)を参照してください。
<!-- Video published on 2024-05-15 -->

## Squash TMの構成 {#configure-squash-tm}

1. オプション。システム管理者に[プロパティファイルでトークンを構成](https://tm-en.doc.squashtest.com/latest/redirect/gitlab-integration-token.html)するように依頼します。
1. [Squash TMドキュメント](https://tm-en.doc.squashtest.com/latest/redirect/gitlab-integration-configuration.html)に従って以下を行います:
   1. GitLabサーバーを作成します。
   1. `Xsquash4GitLab`プラグインを有効にします
   1. 同期を構成します。
   1. **Real-time synchronization**（リアルタイム同期）パネルから、次のフィールドをコピーして後でGitLabで使用します:

      - **WebhookのURL**。
      - Squash TMシステム管理者がステップ1でシークレットを構成した場合の**シークレットトークン**。

## GitLabを設定する {#configure-gitlab}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Squash TM**を選択します。
1. **有効**トグルが有効になっていることを確認します。
1. **トリガー**セクションで、リアルタイム同期の対象となるイシューの種類を示します。
1. フィールドに入力します:

   - **Squash TM Webhook URL**を入力します。
   - Squash TMシステム管理者が以前に構成した場合は、**secret token**（シークレットトークン）を入力します。
