---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 侵害されたパスワードの検出
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 18.0で`notify_compromised_passwords`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188723)されました。デフォルトでは無効になっています。
- GitLab 18.1のGitLab.comで有効になりました。機能フラグ`notify_compromised_passwords`は削除されました。

{{< /history >}}

GitLabは、お客様のGitLab.comの認証情報が、他のサービスまたはプラットフォームでのデータ漏洩の一部として侵害された場合に通知することができます。GitLabの認証情報は暗号化されており、GitLab自体がそれらに直接アクセスすることはありません。

侵害された認証情報が検出されると、GitLabはセキュリティバナーを表示し、パスワードの変更方法とアカウントセキュリティの強化方法に関する指示を含むメールアラートを送信します。

[外部プロバイダーで](../administration/auth/_index.md)認証する場合、またはアカウントがすでに[ロック](unlock_user.md)されている場合、侵害されたパスワードの検出は利用できません。
