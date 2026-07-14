---
stage: Production Engineering
group: Networking and Incident Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: rawエンドポイントのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.10でraw blobリクエスト1分あたりのレート制限（未認証）が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/226344)。

{{< /history >}}

前提条件: 

- 管理者アクセス権。

rawエンドポイントへのアクセスを制御する2つのレート制限設定があります:

- **1分あたりのRaw blobリクエストレート制限**: 各プロジェクトおよびファイルパスのリクエストを制限します。デフォルトでは1分あたり`300`リクエストです。
- **Raw blob request rate limit per minute (unauthenticated)**: 各プロジェクトのすべてのファイルパスに対する未認証リクエストを制限します。デフォルトでは1分あたり`800`リクエストです。

これらの設定を構成するには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **ネットワーク**を選択します。
1. **パフォーマンスの最適化**を展開します。

![1分あたりのraw blobリクエストレート制限が300および800に設定されています。](img/rate_limits_on_raw_endpoints_v18_10.png)

たとえば、パスベースの制限が`300`の場合、`300`を超える1分間のリクエストが`https://gitlab.com/gitlab-org/gitlab-foss/raw/master/app/controllers/application_controller.rb`に対してブロックされます。rawファイルへのアクセスは1分後にリリースされます。

Theパスベースの制限は次のとおりです:

- 各プロジェクトおよびファイルパスに個別に適用されます。
- IPアドレスまたはユーザーによって適用されません。
- デフォルトで有効です。無効にするには、オプションを`0`に設定します。

未認証のプロジェクト全体の制限は次のとおりです:

- 各プロジェクトのすべてのファイルパスに対して、未認証のリクエストのみに適用されます。
- 認証済みユーザーには適用されません。
- IPアドレスごとには適用されません。
- デフォルトで有効です。無効にするには、オプションを`0`に設定します。

レート制限を超えるリクエストは`auth.log`にログされます。
