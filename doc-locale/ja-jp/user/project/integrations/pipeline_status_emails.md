---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインステータスメール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループまたはプロジェクトでパイプラインステータスの変更に関する通知を、メールアドレスのリストに送信できます。

ブロックされたユーザーによってトリガーされたパイプラインの通知は配信されません。

## パイプラインステータスのメール通知を有効にする {#enable-pipeline-status-email-notifications}

前提要件: 

- プロジェクトのメンテナーロール、またはグループのオーナーロールが少なくとも必要です。

パイプラインステータスのメールを有効にするには、次の手順に従ってください:

1. プロジェクトまたはグループの左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **パイプラインのステータスに関するメール**を選択します。
1. **有効**チェックボックスが選択されていることを確認します。
1. **受信者**に、コンマ区切りのメールアドレスのリストを入力します。無効なメールアドレスは自動的に除外され、通知を受信しません。
1. オプション。破損したパイプラインのみの通知を受信するには、**壊れたパイプラインのみ通知**を選択します。
1. 通知を送信するブランチを選択します。
1. **変更を保存**を選択します。
