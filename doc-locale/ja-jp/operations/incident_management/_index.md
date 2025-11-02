---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: インシデント管理
description: アラートの処理、対応の調整、エスカレーション手順。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

この機能は活発な開発は行われていませんが、[コミュニティのコントリビュート](https://about.gitlab.com/community/contribute/)を歓迎します。詳細については、[イシュー468607](https://gitlab.com/gitlab-org/gitlab/-/issues/468607#note_1967939452)を参照してください。この機能がニーズに合っているかどうかを判断するには、[未解決のバグイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=updated_desc&state=opened&label_name%5B%5D=Category%3AIncident%20Management&label_name%5B%5D=type%3A%3Abug&first_page_size=20)を参照してください。

{{< /alert >}}

インシデント管理により、デベロッパーは、アプリケーションによって生成されたアラートとインシデントを簡単にトリアージして表示できます。が開発されている場所にアラートとインシデントを表示することで、効率性と認識を高めることができます。詳細については、以下のセクションをチェックアウトしてください:

- [モニタリングツールを統合する](integrations.md)。
- [オンコールスケジュール](oncall_schedules.md)を管理し、トリガーされたアラートの[通知](paging.md)を受信します。
- [アラート](alerts.md)と[インシデント](incidents.md)をトリアージします。
- [ステータスページ](status_page.md)で関係者に通知します。
