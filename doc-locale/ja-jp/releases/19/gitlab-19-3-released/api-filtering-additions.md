---
title: APIによるフィルタリングと管理の機能拡張
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: foundations
co_create: true
documentation_link: "../../../api/rest/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/244359
categories: [ System Access ]
level: secondary
---

RESTおよびGraphQL APIにわたって、6つの改善が利用可能になりました。

- グループクエリで`visibilityLevel`と`includeSubgroups`が使用できるようになり、`aimed_for_deletion`を使用して削除予定のグループをフィルタリングできます。
- マージリクエストREST APIで`merged_after`と`merged_before`が使用できるようになりました。
- アチーブメントの授与メッセージを、授与時だけでなく、授与後に編集できるようになりました。
- 管理者は、管理者トークンAPIを通じてSCIMトークンをリセットできます。
- `CI_JOB_TOKEN`でリポジトリアーカイブをフェッチできるようになり、ソースフォールバックが非推奨になった際に動作しなくなっていたプライベートComposerパッケージのダウンロードが解消されました。

これらのコントリビュートをいただいた以下のユーザーの皆様に感謝いたします。

- [Colin Jacob Boby](https://gitlab.com/jcb960) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249258))
- [nagraj raikar](https://gitlab.com/nraj0408) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/244359) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245378))
- [Niklas van Schrick](https://gitlab.com/Taucher2003) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246614))
- [Nicholas Wittstruck](https://gitlab.com/nwittstruck) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243804))
- [Alessandro Lai](https://gitlab.com/Alessandro.Lai) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246159))
