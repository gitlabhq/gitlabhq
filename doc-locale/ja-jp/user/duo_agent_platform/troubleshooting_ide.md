---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: IDEでのAgent Platformのトラブルシューティング
---

IDEでGitLab Duo Agent Platformを使用している場合、次の問題が発生する可能性があります。

## 一般的なガイダンス {#general-guidance}

まず、GitLab Duoがオンになっていること、IDEがGitLabに適切に接続されていることを確認します。

- [前提条件](_index.md#prerequisites)を満たしていることを確認してください。
- 作業対象のブランチがチェックアウトされていることを確認してください。
- IDEで必要な設定がオンになっていることを確認してください。
- [管理者モードが無効になっている](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session)ことを確認してください。

### グループネームスペースに属していないプロジェクト {#project-not-in-a-group-namespace}

GitLab Duo Agent Platformでは、プロジェクトがグループネームスペースに属している必要があります。

プロジェクトが属しているネームスペースを特定するには、[URLを確認](../namespace/_index.md#determine-which-type-of-namespace-youre-in)します。

必要に応じて、[プロジェクトをグループネームスペースに転送](../../tutorials/move_personal_project_to_group/_index.md#move-your-project-to-a-group)することができます。

### IDE別のトラブルシューティング {#ide-specific-troubleshooting}

さらにサポートが必要な場合は、拡張機能のトラブルシューティングページを参照してください:

- [GitLab for VS Code](../../editor_extensions/visual_studio_code/troubleshooting.md)
- [JetBrains IDE用GitLab Duoプラグイン](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md)
- [Visual Studio向けGitLab](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)

## まだ問題が発生していますか？ {#still-having-issues}

サポートが必要な場合は、GitLab管理者にお問い合わせください。
