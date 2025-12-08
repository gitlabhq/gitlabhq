---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: スパムログを確認する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabはユーザーアクティビティーを追跡し、潜在的なスパムとして特定の動作にフラグを立てます。

**管理者**エリアでは、GitLabの管理者がスパムログを表示し、解決することができます。

## スパムログの管理 {#manage-spam-logs}

{{< history >}}

- **ユーザーを信頼する**がGitLab 16.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131812)。

{{< /history >}}

スパムログを表示し、解決して、インスタンス内のユーザーアクティビティーを管理します。

スパムログを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。[新しいナビゲーションをオン](../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合は、右上隅でアバターを選択し、**管理者**を選択します。
1. **スパムログ**を選択します。
1. オプション。スパムログを解決するには、**追加のアクション** ({{< icon name="ellipsis_v" >}}) を選択し、**ユーザーを削除**、**ユーザーをブロック**、**ログを削除**、または**ユーザーを信頼する**を選択します。

### スパムログの解決 {#resolving-spam-logs}

次のいずれかの効果でスパムログを解決できます:

| オプション | 説明 |
|---------|-------------|
| **ユーザーを削除** | ユーザーはインスタンスから[削除](../user/profile/account/delete_account.md)されます。 |
| **ユーザーをブロック** | ユーザーはインスタンスからブロックされます。スパムログはリストに残ります。 |
| **ログを削除** | スパムログがリストから削除されます。 |
| **ユーザーを信頼する** | ユーザーは信頼され、スパムとしてブロックされずにイシュー、注釈、スニペット、マージリクエストを作成できます。信頼されたユーザーに対してスパムログは作成されません。 |

## 関連トピック {#related-topics}

- [ユーザーのモデレート（管理者）](moderate_users.md)
- [不正行為の報告を確認する](review_abuse_reports.md)
