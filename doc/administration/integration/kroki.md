---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Kroki diagrams **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/241744) in GitLab 13.7.
> - Support for reStructuredText and Textile documents [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/324766) in GitLab 13.12.

When [Kroki](https://kroki.io) integration is enabled and configured in
GitLab you can use it to create diagrams in AsciiDoc, Markdown, reStructuredText, and Textile documents.

## Kroki Server

When Kroki is enabled, GitLab sends diagrams to an instance of Kroki to display them as images.
You can use the free public cloud instance `https://kroki.io` or you can [install Kroki](https://docs.kroki.io/kroki/setup/install/)
on your own infrastructure.
After you've installed Kroki, make sure to update the server URL to point to your instance.

### Docker

With Docker, run a container like this:

```shell
docker run -d --name kroki -p 8080:8000 yuzutech/kroki
```

The **Kroki URL** is the hostname of the server running the container.

The [`yuzutech/kroki`](https://hub.docker.com/r/yuzutech/kroki) image contains the following diagrams libraries out-of-the-box:

<!-- vale gitlab.Spelling = NO -->

- [Bytefield](https://bytefield-svg.deepsymmetry.org/)
- [Ditaa](http://ditaa.sourceforge.net)
- [Erd](https://github.com/BurntSushi/erd)
- [GraphViz](https://www.graphviz.org/)
- [Nomnoml](https://github.com/skanaar/nomnoml)
- [PlantUML](https://github.com/plantuml/plantuml)
  - [C4 model](https://github.com/RicardoNiepel/C4-PlantUML) (with PlantUML)
- [Svgbob](https://github.com/ivanceras/svgbob)
- [UMlet](https://github.com/umlet/umlet)
- [Vega](https://github.com/vega/vega)
- [Vega-Lite](https://github.com/vega/vega-lite)
- [WaveDrom](https://wavedrom.com/)

<!-- vale gitlab.Spelling = YES -->

If you want to use additional diagram libraries,
read the [Kroki installation](https://docs.kroki.io/kroki/setup/install/#_images) to learn how to start Kroki companion containers.

## Enable Kroki in GitLab

You need to enable Kroki integration from Settings under Admin Area.
To do that, log in with an administrator account and follow these steps:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. Go to **Settings > General**.
1. Expand the **Kroki** section.
1. Select **Enable Kroki** checkbox.
1. Enter the **Kroki URL**.

## Create diagrams

With Kroki integration enabled and configured, you can start adding diagrams to
your AsciiDoc or Markdown documentation using delimited blocks:

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

The above blocks are converted to an HTML image tag with source pointing to the
Kroki instance. If the Kroki server is correctly configured, this should
render a nice diagram instead of the block:

![PlantUML diagram](../img/kroki_plantuml_diagram.png)

Kroki supports more than a dozen diagram libraries. Here's a few examples for AsciiDoc:

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

![GraphViz diagram](../img/kroki_graphviz_diagram.png)

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

![C4 PlantUML diagram](../img/kroki_c4_diagram.png)

<!-- vale gitlab.Spelling = NO -->

**Nomnoml**

<!-- vale gitlab.Spelling = YES -->

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

![Diagram](../img/kroki_nomnoml_diagram.png)
