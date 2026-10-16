---
title: 子パイプラインは親ジョブにオプションで依存できるようになりました
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
co_create: false
documentation_link: "../../../ci/yaml/#needspipelinejob"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/349538
categories: [ Continuous Integration (CI) ]
level: secondary
weight: 20
---

多くの開発チームは、大規模なCI/CDの設定を親パイプラインと子パイプラインに分割し、各部分を管理しやすくしています。
これまで、子パイプラインのジョブは、特定の条件下でのみ実行される親ジョブ（例えば、特定のファイルが変更された場合にのみ実行されるテストなど）に安全に依存することができませんでした。
その親ジョブがスキップされると子ジョブが失敗するため、チームはジョブの重複や脆弱なスクリプトで回避策を講じる必要がありました。

今回のリリースで、これらの依存関係をオプションとしてマークできるようになりました。親ジョブが実行された場合、子ジョブはこれまでどおりその完了を待ちます。
親ジョブが実行されない場合、子ジョブはそれを待たずに処理を進めます。回避策なしにパイプラインの速度と信頼性を維持でき、実行されたジョブで障害が発生した場合は引き続きパイプラインが停止するため、品質チェックが弱まることはありません。

この貢献をしてくださった [Jimmy Spagnola](https://gitlab.com/jspagnola) さんに感謝します！
