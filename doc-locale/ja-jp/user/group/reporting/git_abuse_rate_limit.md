---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Git乱用レート制限
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.2で`limit_unique_project_downloads_per_namespace_user`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/8066)されました。デフォルトでは無効になっています。
- GitLab 15.6の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/365724)で有効になりました。
- GitLab 18.0[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183101)になりました。機能フラグ`limit_unique_project_downloads_per_namespace_user`は削除されました。

{{< /history >}}

これはグループレベルのドキュメントです。GitLab Self-Managedインスタンスについては、[管理ドキュメント](../../../administration/reporting/git_abuse_rate_limit.md)を参照してください。

Git乱用レートの制限は、特定の時間枠内で、グループの指定された数よりも多くのリポジトリをダウンロード、クローン、プル、フェッチ、またはフォークするユーザーを自動的にBANする機能です。BANされたユーザーは、HTTPまたはSSHを介して、トップレベルグループまたはその非公開のサブグループにアクセスできません。このレート制限は、[個人](../../profile/personal_access_tokens.md)または[グループアクセストークン](../settings/group_access_tokens.md) 、および[CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)で認証するユーザーにも適用されます。関係のないグループへのアクセスは影響を受けません。

Git乱用レートの制限は、トップレベルグループのオーナー、[デプロイトークン](../../project/deploy_tokens/_index.md) 、または[デプロイキー](../../project/deploy_keys/_index.md)には適用されません。

GitLabがユーザーのレート制限をどのように決定するかは、開発中です。GitLabチームのメンバーは、この機密性の高いエピック（`https://gitlab.com/groups/gitlab-org/modelops/anti-abuse/-/epics/14`）で詳細を確認できます。

## 自動BANの通知 {#automatic-ban-notifications}

選択されたユーザーは、ユーザーがBANされるとメールの通知を受信します。

自動BANが無効になっている場合、ユーザーが制限を超えても自動的にBANされません。ただし、通知は引き続き送信されます。この設定を使用すると、自動BANを有効にする前に、レート制限の設定の正しい値を判断できます。

自動BANが有効になっている場合、ユーザーがBANされようとするとメールの通知が送信され、ユーザーはグループとそのサブグループから自動的にBANされます。

## Git乱用レートの制限を構成する {#configure-git-abuse-rate-limiting}

1. 左側のサイドバーで、**設定** > **レポート**を選択します。
1. Git乱用レートの制限の設定を更新します:
   1. **リポジトリの数**フィールドに、`0`以上、`10,000`以下の数値を入力します。この数値は、ユーザーがBANされるまでに、指定された期間内にダウンロードできる一意のリポジトリの最大量を指定します。`0`に設定すると、Git乱用レートの制限が無効になります。
   1. **レポート期間 (秒)**フィールドに、`0`以上、`86,400` (10日) 以下の数値を入力します。この数値は、ユーザーがBANされる前にリポジトリの最大量をダウンロードできる時間 (秒) を指定します。`0`に設定すると、Git乱用レートの制限が無効になります。
   1. オプション。**除外ユーザー**フィールドに追加して、最大`100`人のユーザーを除外します。除外されたユーザーは自動的にBANされません。
   1. **通知を送信**フィールドに最大`100`人のユーザーを追加します。少なくとも1人のユーザーを選択する必要があります。Mainグループのオーナーロールを持つすべてのユーザーは、デフォルトで選択されています。
   1. オプション。**Automatically ban users from this namespace when they exceed the specified limits**（指定された制限を超えた場合に、このネームスペースからユーザーを自動的にBANする） 切替をオンにして、自動BANを有効にします。
1. **変更を保存**を選択します。

## 関連トピック {#related-topics}

- [Banおよびアンバンユーザー](../moderate_users.md)。
