---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: ポーリング間隔倍率
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab UIは、イシューのメモ、イシューのタイトル、パイプラインのステータスなど、さまざまなリソースの更新を、リソースに応じたスケジュールでポーリングします。

これらのスケジュールで乗算を調整して、GitLab UIが更新をポーリングする頻度を調整します。乗算を次の値に設定した場合:

- `1`より大きい値にすると、UIのポーリングが遅くなります。多数のクライアントが更新をポーリングすることによるデータベースの読み込むに関するイシューが発生した場合、乗算を大きくすると、ポーリングを完全に無効にする代わりに有効です。たとえば、値を`2`に設定すると、すべてのポーリングの間隔が2倍になります。つまり、ポーリングの頻度が半分になります。
- `0`～`1`の間の値の場合、UIのポーリングの頻度が高くなり、更新の頻度も高くなります。**Not recommended**（推奨されません）。
- `0`の場合、すべてのポーリングが無効になります。次回のポーリングで、クライアントは更新のポーリングを停止します。

デフォルト値（`1`）は、ほとんどのGitLabインストールで推奨されています。

## 設定 {#configure}

ポーリングの間隔の乗算を調整するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **ポーリング間隔倍率**を展開します。
1. ポーリングの間隔の乗算の値を設定します。この乗算は、すべてのリソースに一度に適用されます。
1. **変更を保存**を選択します。
