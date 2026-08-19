---
title: パイプラインインプットで複数の値を選択
stage: verify
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../ci/inputs/#array-inputs-with-options"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/566155"
categories: [ Pipeline Composition ]
weight: 70
---

これまで、UIでインプットオプションを選択する際は1つの値しか選択できず、
より複雑なオプションを持つパイプラインでの柔軟性が制限されていました。

UIからインプット付きのパイプラインを実行する際に、ドロップダウンリストから複数の値を選択できるようになりました。
選択した値は `["option1","option2"]` のように配列にまとめられます。
これにより、複数のインスタンスでのサービス再起動、複数のDockerイメージのビルド、
複数のタグの組み合わせによるテスト実行、または複数のターゲットにまたがる任意の操作を
1回のパイプライン実行でまとめて行えるようになります。
