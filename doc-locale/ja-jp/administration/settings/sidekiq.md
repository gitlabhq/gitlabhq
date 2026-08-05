---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sidekiqバックグラウンドジョブ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Sidekiqジョブサイズの制限と、cronジョブのスケジュール評価に使用するタイムゾーンを設定します。

前提条件: 

- 管理者アクセス権。

これらの設定にアクセスするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **設定**を選択します。
1. **Sidekiq Background Jobs**を展開します。

## ジョブサイズの制限 {#job-size-limits}

[Sidekiq](../sidekiq/_index.md)はRedisにジョブを保存します。過剰なRedisメモリ使用量を避けるため、GitLabは次の対応を行います:

- Redisに保存する前に、ジョブの引数を圧縮します。
- 圧縮後に指定されたしきい値制限を超えるジョブは拒否されます。

圧縮のしきい値またはサイズ制限を調整するには、値を更新します。圧縮を無効にするには、**Track**モードを選択します。

### 利用可能な設定 {#available-settings}

| 設定                                   | デフォルト          | 説明                                                                                                                                                                   |
|-------------------------------------------|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 制限モード                             | 圧縮         | このモードは、指定されたしきい値でジョブを圧縮し、圧縮後に指定された制限を超えた場合はジョブを拒否します。                                               |
| Sidekiqジョブ圧縮しきい値（バイト） | 100,000（100 KB） | 引数のサイズがこのしきい値を超えると、Redisに保存される前に圧縮されます。                                                                          |
| Sidekiqジョブサイズ制限（バイト）            | 0                | 圧縮後にこのサイズを超えるジョブは拒否されます。これにより、Redisでの過剰なメモリ使用が回避され、不安定になることを防ぎます。0に設定すると、ジョブの拒否が無効になります。     |

これらの値を変更したら、[Sidekiqを再起動](../restart_gitlab.md)します。

## Cronジョブのタイムゾーン {#cron-jobs-time-zone}

デフォルトでは、GitLabは、cronジョブのスケジュールをインスタンスのタイムゾーン（特に設定されていない場合はUTC）で評価します。異なるタイムゾーンでcronジョブを実行するには、タイムゾーンのオーバーライドを設定します。

タイムゾーンを設定するには:

1. **Cron jobs time zone**ドロップダウンリストからタイムゾーンを選択するか、**System default**を選択してインスタンスのタイムゾーンを使用します。

この値を変更したら、[Sidekiqを再起動](../restart_gitlab.md)します。
