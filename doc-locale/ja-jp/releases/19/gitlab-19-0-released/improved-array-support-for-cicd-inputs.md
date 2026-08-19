---
title: CI/CDインプットの配列サポートの強化
stage: verify
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../ci/inputs/#access-individual-array-elements"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/issues/587657"
categories: [ Pipeline Composition ]
weight: 60
---

CI/CDインプットで配列の操作がより柔軟になりました。
配列インデックス演算子 `[]` を使用することで、配列インプット内の特定の要素にアクセスできます。
この強化により、パイプライン設定におけるインプット補間の柔軟性と表現力が向上し、追加の処理ステップなしに個々の配列要素を直接参照できるようになりました。
