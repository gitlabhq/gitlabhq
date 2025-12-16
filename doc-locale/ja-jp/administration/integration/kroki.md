---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Kroki
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[Kroki](https://kroki.io)インテグレーションを使用すると、AsciiDoc、Markdown、reStructuredText、Textile内でdiagrams-as-コードを作成できます。

## GitLabでKrokiを有効にする {#enable-kroki-in-gitlab}

**管理者**の設定からKrokiインテグレーションを有効にする必要があります。これを行うには、管理者アカウントでサインインし、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**に移動します。
1. **Kroki**セクションを展開します。
1. **Krokiを有効にする**チェックボックスを選択します。
1. **Kroki URL**を入力します（例: `https://kroki.io`）。

## Krokiサーバー {#kroki-server}

Krokiを有効にすると、GitLabは図をKrokiのインスタンスに送信し、画像として表示します。無料のパブリッククラウドインスタンス`https://kroki.io`を使用するか、独自のインフラストラクチャに[Krokiをインストールする](https://docs.kroki.io/kroki/setup/install/)ことができます。Krokiをインストールしたら、設定で**Kroki URL**を更新して、インスタンスを指すようにしてください。

{{< alert type="note" >}}

Krokiの図はGitLabに保存されないため、標準のGitLabアクセス制御およびその他のユーザー権限の制限は適用されません。

{{< /alert >}}

### Docker {#docker}

Dockerで、次のようなコンテナを実行します:

```shell
docker run -d --name kroki -p 8080:8000 yuzutech/kroki
```

**Kroki URL**は、コンテナを実行しているサーバーのホスト名です。

[`yuzutech/kroki`](https://hub.docker.com/r/yuzutech/kroki) Dockerイメージは、ほとんどの図のタイプをすぐにサポートしています。完全なリストについては、[Krokiインストールドキュメント](https://docs.kroki.io/kroki/setup/install/#_the_kroki_container)を参照してください。

サポートされている図のタイプは次のとおりです:

<!-- vale gitlab_base.Spelling = NO -->

- [Bytefield](https://bytefield-svg.deepsymmetry.org/bytefield-svg/intro.html)
- [D2](https://d2lang.com/tour/intro/)
- [DBML](https://dbml.dbdiagram.io/home/)
- [Ditaa](https://ditaa.sourceforge.net)
- [Erd](https://github.com/BurntSushi/erd)
- [GraphViz](https://www.graphviz.org/)
- [Nomnoml](https://github.com/skanaar/nomnoml)
- [PlantUML](https://github.com/plantuml/plantuml)
  - [C4モデル](https://github.com/RicardoNiepel/C4-PlantUML)（PlantUMLを使用）
- [Structurizr](https://structurizr.com/)（C4 モデルのダイアグラムに最適）
- [Svgbob](https://github.com/ivanceras/svgbob)
- [UMlet](https://github.com/umlet/umlet)
- [Vega](https://github.com/vega/vega)
- [Vega-Lite](https://github.com/vega/vega-lite)
- [WaveDrom](https://wavedrom.com/)

<!-- vale gitlab_base.Spelling = YES -->

追加の図書ライブラリを使用する場合は、Krokiコンパニオンコンテナを開始する方法について、[Krokiのインストール](https://docs.kroki.io/kroki/setup/install/#_images)をお読みください。

## 図を作成する {#create-diagrams}

Krokiインテグレーションが有効になり、設定されると、区切りブロックを使用してAsciiDocまたはMarkdownドキュメントに図を追加できます:

- **Markdown**

  ````markdown
  ```plantuml
  Bob -> Alice : hello
  Alice -> Bob : hi
  ```
  ````

- **AsciiDoc**

  ```plaintext
  [plantuml]
  ....
  Bob->Alice : hello
  Alice -> Bob : hi
  ....
  ```

- **reStructuredText**

  ```plaintext
  .. code-block:: plantuml

    Bob->Alice : hello
    Alice -> Bob : hi
  ```

- **Textile**

  ```plaintext
  bc[plantuml]. Bob->Alice : hello
  Alice -> Bob : hi
  ```

区切られたブロックは、ソースがKrokiインスタンスを指すHTMLイメージタグに変換されます。Krokiサーバーが正しく設定されている場合、ブロックの代わりに、優れた図がレンダリングされます:

![サンプルコードからレンダリングされたPlantUML図](img/kroki_plantuml_diagram_v13_7.png)

Krokiは、ダース以上の図書ライブラリをサポートしています。AsciiDocのいくつかの例を次に示します:

**GraphViz**

```plaintext
[graphviz]
....
digraph finite_state_machine {
  rankdir=LR;
  node [shape = doublecircle]; LR_0 LR_3 LR_4 LR_8;
  node [shape = circle];
  LR_0 -> LR_2 [ label = "SS(B)" ];
  LR_0 -> LR_1 [ label = "SS(S)" ];
  LR_1 -> LR_3 [ label = "S($end)" ];
  LR_2 -> LR_6 [ label = "SS(b)" ];
  LR_2 -> LR_5 [ label = "SS(a)" ];
  LR_2 -> LR_4 [ label = "S(A)" ];
  LR_5 -> LR_7 [ label = "S(b)" ];
  LR_5 -> LR_5 [ label = "S(a)" ];
  LR_6 -> LR_6 [ label = "S(b)" ];
  LR_6 -> LR_5 [ label = "S(a)" ];
  LR_7 -> LR_8 [ label = "S(b)" ];
  LR_7 -> LR_5 [ label = "S(a)" ];
  LR_8 -> LR_6 [ label = "S(b)" ];
  LR_8 -> LR_5 [ label = "S(a)" ];
}
....
```

![サンプルコードから生成されたGraphViz図](img/kroki_graphviz_diagram_v13_7.png)

**C4（PlantUMLに基づく）**

```plaintext
[c4plantuml]
....
@startuml
!include C4_Context.puml

title System Context diagram for Internet Banking System

Person(customer, "Banking Customer", "A customer of the bank, with personal bank accounts.")
System(banking_system, "Internet Banking System", "Allows customers to check their accounts.")

System_Ext(mail_system, "E-mail system", "The internal Microsoft Exchange e-mail system.")
System_Ext(mainframe, "Mainframe Banking System", "Stores all of the core banking information.")

Rel(customer, banking_system, "Uses")
Rel_Back(customer, mail_system, "Sends e-mails to")
Rel_Neighbor(banking_system, mail_system, "Sends e-mails", "SMTP")
Rel(banking_system, mainframe, "Uses")
@enduml
....
```

![サンプルコードから生成されたC4 PlantUML図](img/kroki_c4_diagram_v13_7.png)

<!-- vale gitlab_base.Spelling = NO -->

**Nomnoml**

<!-- vale gitlab_base.Spelling = YES -->

```plaintext
[nomnoml]
....
[Pirate|eyeCount: Int|raid();pillage()|
  [beard]--[parrot]
  [beard]-:>[foul mouth]
]

[<abstract>Marauder]<:--[Pirate]
[Pirate]- 0..7[mischief]
[jollyness]->[Pirate]
[jollyness]->[rum]
[jollyness]->[singing]
[Pirate]-> *[rum|tastiness: Int|swig()]
[Pirate]->[singing]
[singing]<->[rum]
....
```

![サンプルコードから生成されたNomnoml図](img/kroki_nomnoml_diagram_v13_7.png)
