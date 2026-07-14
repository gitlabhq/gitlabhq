---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Kroki
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Grâce à l'intégration [Kroki](https://kroki.io), vous pouvez créer des diagrammes sous forme de code dans AsciiDoc, Markdown, reStructuredText et Textile.

## Activer Kroki dans GitLab {#enable-kroki-in-gitlab}

Vous devez activer l'intégration Kroki depuis les Paramètres dans la zone **Admin**. Pour ce faire, connectez-vous avec un compte administrateur et suivez ces étapes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Accédez à **Paramètres** > **Général**.
1. Développez la section **Kroki**.
1. Cochez la case **Activer Kroki**.
1. Saisissez l'**URL Kroki**, par exemple `https://kroki.io`.

Pour empêcher les navigateurs d'envoyer le contenu des diagrammes au service Kroki externe, utilisez le [proxy de diagramme](diagram_proxy.md).

## Serveur Kroki {#kroki-server}

Lorsque vous activez Kroki, GitLab envoie les diagrammes à une instance de Kroki pour les afficher sous forme d'images. Vous pouvez utiliser l'instance cloud publique gratuite `https://kroki.io` ou vous pouvez [installer Kroki](https://docs.kroki.io/kroki/setup/install/) sur votre propre infrastructure. Après avoir installé Kroki, assurez-vous de mettre à jour l'**URL Kroki** dans les paramètres pour qu'elle pointe vers votre instance.

> [!note]
> Les diagrammes Kroki ne sont pas stockés sur GitLab, donc les contrôles d'accès standard de GitLab et les autres restrictions de permissions utilisateur ne sont pas appliqués.

### Docker {#docker}

Avec Docker, exécutez un conteneur comme ceci :

```shell
docker run -d --name kroki -p 8080:8000 yuzutech/kroki
```

L'**URL Kroki** est le nom d'hôte du serveur exécutant le conteneur.

L'image Docker [`yuzutech/kroki`](https://hub.docker.com/r/yuzutech/kroki) prend en charge la plupart des types de diagrammes nativement. Pour une liste complète, consultez la [documentation d'installation de Kroki](https://docs.kroki.io/kroki/setup/install/#_the_kroki_container).

Les types de diagrammes pris en charge incluent :

<!-- vale gitlab_base.Spelling = NO -->

- [Bytefield](https://bytefield-svg.deepsymmetry.org/bytefield-svg/intro.html)
- [D2](https://d2lang.com/tour/intro/)
- [DBML](https://dbml.dbdiagram.io/home/)
- [Ditaa](https://ditaa.sourceforge.net)
- [Erd](https://github.com/BurntSushi/erd)
- [GraphViz](https://www.graphviz.org/)
- [Nomnoml](https://github.com/skanaar/nomnoml)
- [PlantUML](https://github.com/plantuml/plantuml)
  - [Modèle C4](https://github.com/RicardoNiepel/C4-PlantUML) (avec PlantUML)
- [Structurizr](https://structurizr.com/) (idéal pour les diagrammes de modèle C4)
- [Svgbob](https://github.com/ivanceras/svgbob)
- [UMlet](https://github.com/umlet/umlet)
- [Vega](https://github.com/vega/vega)
- [Vega-Lite](https://github.com/vega/vega-lite)
- [WaveDrom](https://wavedrom.com/)

<!-- vale gitlab_base.Spelling = YES -->

Si vous souhaitez utiliser des bibliothèques de diagrammes supplémentaires, consultez l'[installation de Kroki](https://docs.kroki.io/kroki/setup/install/#_images) pour savoir comment démarrer les conteneurs compagnons Kroki.

## Créer des diagrammes {#create-diagrams}

Une fois l'intégration Kroki activée et configurée, vous pouvez commencer à ajouter des diagrammes à votre documentation AsciiDoc ou Markdown en utilisant des blocs délimités :

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

Les blocs délimités sont convertis en balise d'image HTML dont la source pointe vers l'instance Kroki. Si le serveur Kroki est correctement configuré, cela devrait afficher un beau diagramme à la place du bloc :

![Un diagramme PlantUML rendu à partir d'un exemple de code.](img/kroki_plantuml_diagram_v13_7.png)

Kroki prend en charge plus d'une douzaine de bibliothèques de diagrammes. Voici quelques exemples pour AsciiDoc :

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

![Un diagramme GraphViz généré à partir d'un exemple de code.](img/kroki_graphviz_diagram_v13_7.png)

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

![Un diagramme C4 PlantUML généré à partir d'un exemple de code.](img/kroki_c4_diagram_v13_7.png)

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

![Un diagramme Nomnoml généré à partir d'un exemple de code.](img/kroki_nomnoml_diagram_v13_7.png)
