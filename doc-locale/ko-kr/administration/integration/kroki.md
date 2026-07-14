---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Kroki
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Kroki](https://kroki.io) 통합을 사용하면 AsciiDoc, Markdown, reStructuredText, Textile 내에서 다이어그램으로 코드를 작성할 수 있습니다.

## GitLab에서 Kroki 활성화 {#enable-kroki-in-gitlab}

**운영자** 영역의 설정에서 Kroki 통합을 활성화해야 합니다. 이를 위해 관리자 계정으로 로그인하고 다음 단계를 따릅니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. **설정** > **일반**으로 이동합니다.
1. **Kroki** 섹션을 확장합니다.
1. **Kroki 활성화** 확인란을 선택합니다.
1. **Kroki URL**을 입력합니다. 예를 들어 `https://kroki.io`입니다.

브라우저가 외부 Kroki 서비스로 다이어그램 콘텐츠를 전송하지 않도록 하려면 [다이어그램 프록시](diagram_proxy.md)를 사용합니다.

## Kroki 서버 {#kroki-server}

Kroki를 활성화하면 GitLab은 다이어그램을 Kroki 인스턴스로 전송하여 이미지로 표시합니다. 무료 공개 클라우드 인스턴스 `https://kroki.io`를 사용하거나 자신의 인프라에 [Kroki를 설치](https://docs.kroki.io/kroki/setup/install/)할 수 있습니다. Kroki를 설치한 후에는 설정에서 **Kroki URL**을 업데이트하여 자신의 인스턴스를 가리키도록 합니다.

> [!note]
> Kroki 다이어그램은 GitLab에 저장되지 않으므로 표준 GitLab 액세스 제어 및 기타 사용자 권한 제한이 적용되지 않습니다.

### Docker {#docker}

Docker를 사용하여 다음과 같이 컨테이너를 실행합니다:

```shell
docker run -d --name kroki -p 8080:8000 yuzutech/kroki
```

**Kroki URL**은 컨테이너를 실행하는 서버의 호스트 이름입니다.

[`yuzutech/kroki`](https://hub.docker.com/r/yuzutech/kroki) Docker 이미지는 기본적으로 대부분의 다이어그램 유형을 지원합니다. 전체 목록은 [Kroki 설치 문서](https://docs.kroki.io/kroki/setup/install/#_the_kroki_container)를 참조합니다.

지원되는 다이어그램 유형은 다음과 같습니다:

<!-- vale gitlab_base.Spelling = NO -->

- [Bytefield](https://bytefield-svg.deepsymmetry.org/bytefield-svg/intro.html)
- [D2](https://d2lang.com/tour/intro/)
- [DBML](https://dbml.dbdiagram.io/home/)
- [Ditaa](https://ditaa.sourceforge.net)
- [Erd](https://github.com/BurntSushi/erd)
- [GraphViz](https://www.graphviz.org/)
- [Nomnoml](https://github.com/skanaar/nomnoml)
- [PlantUML](https://github.com/plantuml/plantuml)
  - [C4 모델](https://github.com/RicardoNiepel/C4-PlantUML) (PlantUML 포함)
- [Structurizr](https://structurizr.com/) (C4 모델 다이어그램에 유용)
- [Svgbob](https://github.com/ivanceras/svgbob)
- [UMlet](https://github.com/umlet/umlet)
- [Vega](https://github.com/vega/vega)
- [Vega-Lite](https://github.com/vega/vega-lite)
- [WaveDrom](https://wavedrom.com/)

<!-- vale gitlab_base.Spelling = YES -->

추가 다이어그램 라이브러리를 사용하려면 [Kroki 설치](https://docs.kroki.io/kroki/setup/install/#_images)를 읽어 Kroki 컴팬언 컨테이너를 시작하는 방법을 알아봅니다.

## 다이어그램 만들기 {#create-diagrams}

Kroki 통합을 활성화하고 구성한 후에는 구분된 블록을 사용하여 AsciiDoc 또는 Markdown 문서에 다이어그램을 추가할 수 있습니다:

- **마크다운**

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

구분된 블록은 Kroki 인스턴스를 가리키는 소스를 포함하는 HTML 이미지 태그로 변환됩니다. Kroki 서버가 올바르게 구성되면 블록 대신 멋진 다이어그램이 렌더링됩니다:

![예제 코드에서 렌더링된 PlantUML 다이어그램입니다.](img/kroki_plantuml_diagram_v13_7.png)

Kroki는 다양한 다이어그램 라이브러리를 지원합니다. AsciiDoc의 몇 가지 예시를 다음과 같습니다:

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

![예제 코드에서 생성된 GraphViz 다이어그램입니다.](img/kroki_graphviz_diagram_v13_7.png)

**C4 (based on PlantUML)**

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

![예제 코드에서 생성된 C4 PlantUML 다이어그램입니다.](img/kroki_c4_diagram_v13_7.png)

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

![예제 코드에서 생성된 Nomnoml 다이어그램입니다.](img/kroki_nomnoml_diagram_v13_7.png)
