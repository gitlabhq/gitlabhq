---
stage: Plan
group: Planner Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Éditeur en texte enrichi
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- L'éditeur de texte enrichi [défini comme éditeur par défaut pour les nouveaux utilisateurs](https://gitlab.com/gitlab-org/gitlab/-/issues/536611) dans GitLab 18.2.

{{< /history >}}

L'éditeur de texte enrichi est l'éditeur de texte par défaut pour les nouveaux utilisateurs dans GitLab.

Vous pouvez utiliser l'éditeur de texte enrichi dans :

- [les wikis.](project/wiki/_index.md)
- Les tickets
- Les epics
- Les merge requests
- [Designs](project/issues/design_management.md)

Les fonctionnalités de l'éditeur incluent :

- Mettre en forme du texte, notamment en gras, en italique, en citation, en titre et en code en ligne.
- Mettre en forme des listes ordonnées, des listes non ordonnées et des listes de contrôle.
- Insérer des liens, des pièces jointes, des images, des vidéos et des fichiers audio.
- Créer et modifier la structure d'un tableau.
- Insérer et mettre en forme des blocs de code avec coloration syntaxique.
- Prévisualiser les diagrammes Mermaid, PlantUML et Kroki en temps réel.

Pour suivre les travaux d'ajout de l'éditeur de texte enrichi à davantage d'endroits dans GitLab, voir [l'epic 7098](https://gitlab.com/groups/gitlab-org/-/epics/7098).

## Passer à l'éditeur de texte enrichi {#switch-to-the-rich-text-editor}

Utilisez l'éditeur de texte enrichi pour modifier des descriptions, des pages wiki et ajouter des commentaires.

Pour passer à l'éditeur de texte enrichi : dans une zone de texte, dans le coin inférieur gauche, sélectionnez **Passer à l'édition en texte enrichi**.

## Passer à l'éditeur de texte brut {#switch-to-the-plain-text-editor}

Si vous souhaitez saisir du code source Markdown dans la zone de texte, revenez à l'éditeur de texte brut.

Pour passer à l'éditeur de texte brut : dans une zone de texte, dans le coin inférieur gauche, sélectionnez **Passer à l'édition en texte brut**.

![Un éditeur de texte en mode d'édition de texte enrichi avec la zone de texte « Passer à l'édition en texte brut » dans le coin inférieur gauche](img/rich_text_editor_01_v16_2.png)

## Compatibilité avec GitLab Flavored Markdown {#compatibility-with-gitlab-flavored-markdown}

L'éditeur de texte enrichi est entièrement compatible avec [GitLab Flavored Markdown](markdown.md). Cela signifie que vous pouvez basculer entre les modes texte brut et texte enrichi sans perdre de données.

### Règles de saisie {#input-rules}

L'éditeur de texte enrichi prend également en charge des règles de saisie qui vous permettent de travailler avec du contenu enrichi comme si vous tapiez du Markdown.

Règles de saisie prises en charge :

| Syntaxe de règle de saisie                                         | Contenu inséré     |
| --------------------------------------------------------- | -------------------- |
| `# Heading 1` à `###### Heading 6`                  | Titres 1 à 6 |
| `**bold**` ou `__bold__`                                  | Texte en gras            |
| `_italics_` ou `*italics*`                                | Texte en italique      |
| `~~strike~~`                                              | Texte barré        |
| `[link](https://example.com)`                             | Hyperlien            |
| `code`                                                    | Code en ligne          |
| ` ```rb ` + <kbd>Enter</kbd> <br> ` ```js ` + <kbd>Enter</kbd> | Bloc de code      |
| `* List item`, ou<br> `- List item`, ou<br> `+ List item` | Liste non ordonnée       |
| `1. List item`                                            | Liste numérotée        |
| `<details>`                                               | Section réductible  |

## Tableaux {#tables}

Contrairement au Markdown brut, vous pouvez utiliser l'éditeur de texte enrichi pour insérer des paragraphes de contenu en bloc, des éléments de liste, des diagrammes (ou même un autre tableau !) dans les cellules d'un tableau.

### Insérer un tableau {#insert-a-table}

Pour insérer un tableau :

1. Sélectionnez **Insérer un tableau** {{< icon name="table" >}}.
1. Dans la liste déroulante, sélectionnez les dimensions du nouveau tableau.

![Un sélecteur de taille de tableau avec 3 lignes et 3 colonnes.](img/rich_text_editor_02_v16_2.png)

### Modifier un tableau {#edit-a-table}

Dans une cellule de tableau, vous pouvez utiliser un menu pour insérer ou supprimer des lignes ou des colonnes.

Pour ouvrir le menu : dans le coin supérieur droit d'une cellule, sélectionnez le chevron {{< icon name="chevron-down" >}}.

![Un menu chevron actif affichant les actions du tableau.](img/rich_text_editor_03_v16_2.png)

### Opérations sur plusieurs cellules {#operations-on-multiple-cells}

Sélectionnez plusieurs cellules et fusionnez-les ou divisez-les.

Pour fusionner les cellules sélectionnées en une seule :

1. Sélectionnez plusieurs cellules : sélectionnez-en une et faites glisser votre curseur.
1. Dans le coin supérieur droit d'une cellule, sélectionnez le chevron {{< icon name="chevron-down" >}} > **Fusionner N cellules**.

Pour diviser les cellules fusionnées : dans le coin supérieur droit d'une cellule, sélectionnez le chevron {{< icon name="chevron-down" >}} > **Diviser la cellule**.

### Coller dans une cellule de tableau {#paste-into-a-table-cell}

{{< history >}}

- Les actions de collage dans le menu du tableau ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/work_items/627112) dans GitLab 19.4.
- Le raccourci clavier pour coller dans une cellule de tableau a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/627699) dans GitLab 19.4.

{{< /history >}}

Lorsque vous appuyez sur <kbd>Control</kbd>+<kbd>V</kbd> (ou <kbd>Command</kbd>+<kbd>V</kbd> sur macOS), GitLab fusionne par défaut les cellules copiées dans le tableau.

Pour choisir comment le contenu est collé :

1. Dans le coin supérieur droit de la cellule cible, sélectionnez le chevron {{< icon name="chevron-down" >}}.
1. Sélectionnez l'une des options suivantes :
   - **Coller dans la cellule** : insère le contenu copié à l'emplacement du curseur. Un tableau copié devient un tableau imbriqué dans la cellule.
   - **Coller et fusionner dans le tableau** : distribue les cellules copiées dans le tableau (comportement par défaut).

Chaque option affiche également son raccourci clavier à côté de son libellé. Pour coller un tableau copié en tant que tableau imbriqué sans ouvrir le menu, placez votre curseur dans une cellule du tableau. Appuyez ensuite sur <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd> (ou <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>V</kbd> sur macOS).

La première fois que vous utilisez l'une ou l'autre option, votre navigateur peut demander l'autorisation de lire votre presse-papiers.

> [!note]
> Sur GitLab Self-Managed, les options de collage et le raccourci clavier ne sont pas disponibles si votre instance est servie via HTTP simple. Ces fonctionnalités nécessitent que le navigateur accède au presse-papiers, et les navigateurs n'autorisent cet accès que sur les pages servies via HTTPS ou depuis `localhost`.

## Insérer des diagrammes {#insert-diagrams}

Insérez des diagrammes [Mermaid](https://mermaidjs.github.io/) et [PlantUML](https://plantuml.com/) et prévisualisez-les en direct au fur et à mesure que vous saisissez le code du diagramme.

Pour insérer un diagramme :

1. Dans la barre supérieure d'une zone de texte, sélectionnez {{< icon name="plus" >}} **Plus d'options**, puis **Diagramme Mermaid** ou **Diagramme PlantUML**.
1. Saisissez le code de votre diagramme. La prévisualisation du diagramme apparaît dans la zone de texte.

![Prévisualisation d'un diagramme Mermaid dans l'éditeur de texte enrichi avec la syntaxe LR créant un organigramme de gauche à droite](img/rich_text_editor_04_v16_2.png)

## Sujets connexes {#related-topics}

- [Définir l'éditeur de texte par défaut](profile/preferences.md#set-the-default-text-editor)
- [Raccourcis clavier](shortcuts.md#rich-text-editor) pour l'éditeur de texte enrichi
- [Markdown GitLab Flavored](markdown.md)
