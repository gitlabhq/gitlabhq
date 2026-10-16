---
title: インターフェースへのその他の追加
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
co_create: true
documentation_link: "../../../user/project/merge_requests/approvals/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/258534
categories: [ Code Review Workflow ]
level: secondary
weight: 90
---

このリリースでは、インターフェースに以下の追加が行われました。

- マージリクエストの設定で**必要な承認数**を変更すると、成功時にはトーストが表示され、失敗時にはアラートが表示されます。
- 要件にすでに5つのコントロールが設定されているコンプライアンスフレームワークを再度編集できるようになりました。
- 保護環境の更新に失敗した場合、APIメッセージが表示されます。
- **ブランチを作成**ダイアログで、ブランチ名が検証されるまで送信ボタンが無効のままになります。
- アーカイブ済みのラベルは、イシューおよびマージリクエストの一覧で**アーカイブ済み**ツールチップが表示され、新たに割り当てることはできません。
- グループのSAMLプロバイダーが無効になっている間は、SCIMトークンを生成できません。
- `.4dm`ファイルの構文がハイライト表示されます。
- 右揃えのMarkdownテーブル列では、固定幅の数字が使用されます。

承認ルール、コンプライアンスフレームワーク、および保護環境にはPremiumまたはUltimateが必要です。

これらのコントリビュートをいただいた以下のユーザーの皆様に感謝いたします。

- [Sahil Bhatt](https://gitlab.com/Sahil8383) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/258534) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/258009))
- [Jeston Singh](https://gitlab.com/sjestonsingh) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255147))
- [Vladislav Petrov](https://gitlab.com/plus3x) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256907))
- [Nicholas Wittstruck](https://gitlab.com/nwittstruck) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251069))
- [ryo-whaletech](https://gitlab.com/ryo-whaletech) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255219))
- [Sergey Pechenko](https://gitlab.com/tnt4brain) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249242))
- [Logan Swartzendruber](https://gitlab.com/loganswartz) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/257688))
- [Steve Mokris](https://gitlab.com/smokris) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254031))
