---
stage: Data Access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sidekiqジョブのサイズ制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Sidekiq](../sidekiq/_index.md)ジョブはRedisに保存されます。Redisのメモリ使用量が過剰になるのを防ぐため、以下のことを行います:

- Redisに保存する前に、ジョブの引数を圧縮します。
- 圧縮後、指定されたしきい値制限を超えるジョブを拒否します。

Sidekiqジョブサイズの制限にアクセスするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Sidekiqジョブサイズの制限**を展開します。
1. 圧縮のしきい値またはサイズ制限を調整します。**Track**モードを選択すると、圧縮を無効にできます。

## 使用可能な設定 {#available-settings}

| 設定                                   | デフォルト          | 説明                                                                                                                                                                   |
|-------------------------------------------|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 制限モード                             | 圧縮         | このモードでは、指定されたしきい値でジョブを圧縮し、圧縮後に指定された制限を超えるとそれらを拒否します。                                               |
| Sidekiqジョブ圧縮のしきい値（バイト） | 100 000（100 KB） | 引数のサイズがこのしきい値を超えると、Redisに保存される前に圧縮されます。                                                                          |
| Sidekiqジョブサイズ制限（バイト）            | 0                | 圧縮後、このサイズを超えるジョブは拒否されます。これにより、Redisでの過剰なメモリ使用量が回避され、不安定になるのを防ぎます。0に設定すると、ジョブの拒否を防ぎます。     |

これらの値を変更したら、[Sidekiqを再起動](../restart_gitlab.md)します。
