---
stage: Production Engineering
group: Networking and Incident Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: rawエンドポイントのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

この設定は、1分あたり`300`リクエストにデフォルト設定されており、rawエンドポイントへのリクエストのレート制限をすることができます:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **ネットワーク**を選択します。
1. **パフォーマンスの最適化**を展開します。

たとえば、`https://gitlab.com/gitlab-org/gitlab-foss/raw/master/app/controllers/application_controller.rb`への1分あたり`300`を超えるリクエストはブロックされます。rawファイルのアクセスは1分後にリリースされます。

![1分あたりのraw blobリクエストのレート制限は300に設定されています。](img/rate_limits_on_raw_endpoints_v12_2.png)

この制限は次のとおりです:

- プロジェクトごと、ファイルパスごとに個別に適用されます。
- IPアドレスごとには適用されません。
- デフォルトで有効。無効にするには、オプションを`0`に設定します。

レート制限を超えたリクエストは、`auth.log`に記録されます。
