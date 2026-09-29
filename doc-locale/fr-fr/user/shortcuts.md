---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Raccourcis clavier GitLab
description: "Raccourcis globaux, navigation et accès rapide."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab propose plusieurs raccourcis clavier que vous pouvez utiliser pour accéder à ses différentes fonctionnalités.

Pour afficher une fenêtre dans GitLab listant ses raccourcis clavier, utilisez l'une des méthodes suivantes :

- Appuyez sur <kbd>?</kbd>.
- Dans le coin inférieur gauche de l'application, sélectionnez **Aide**, puis **Raccourcis clavier**.

Bien que les [raccourcis globaux](#global-shortcuts) fonctionnent depuis n'importe quelle zone de GitLab, vous devez vous trouver sur des pages spécifiques pour que les autres raccourcis soient disponibles, comme expliqué dans chaque section.

## Raccourcis globaux {#global-shortcuts}

Ces raccourcis sont disponibles dans la plupart des zones de GitLab :

| Raccourci clavier                  | Description |
|------------------------------------|-------------|
| <kbd>?</kbd>                       | Afficher ou masquer la fiche de référence des raccourcis. |
| <kbd>Shift</kbd>+<kbd>h</kbd>      | Aller à la page d'accueil. |
| <kbd>Shift</kbd>+<kbd>p</kbd>      | Accéder à votre page **Projets**. |
| <kbd>Shift</kbd>+<kbd>g</kbd>      | Accéder à votre page **Groupes**. |
| <kbd>Shift</kbd>+<kbd>a</kbd>      | Accéder à votre page **Activité**. |
| <kbd>Shift</kbd>+<kbd>l</kbd>      | Accéder à votre page **Jalons**. |
| <kbd>Shift</kbd>+<kbd>s</kbd>      | Accéder à votre page **Extraits de code**. |
| <kbd>s</kbd> / <kbd>/</kbd>        | Placer le curseur dans la barre de recherche. |
| <kbd>f</kbd>                       | Mettre le focus sur la barre de filtre |
| <kbd>Shift</kbd>+<kbd>i</kbd>      | Accéder à votre page **Tickets**. |
| <kbd>Shift</kbd>+<kbd>m</kbd>      | Accéder à votre page **Requêtes de fusion**. |
| <kbd>Shift</kbd>+<kbd>r</kbd>      | Accéder à votre page **Demandes de révision**. |
| <kbd>Shift</kbd>+<kbd>t</kbd>      | Accéder à votre page **Liste des pense-bêtes**. |
| <kbd>p</kbd>, puis <kbd>b</kbd>    | Afficher ou masquer la barre de performance. |
| <kbd>Escape</kbd>                  | Masquer les info-bulles ou les popovers. |
| <kbd>g</kbd>, puis <kbd>x</kbd>    | Basculer entre [GitLab](https://gitlab.com/) et [GitLab Next](https://next.gitlab.com/) (GitLab.com uniquement). |
| <kbd>.</kbd>                       | Ouvrir le [Web IDE](project/web_ide/_index.md). |
| <kbd>d</kbd>                       | Ouvrir GitLab Duo Chat |

En outre, les raccourcis suivants sont disponibles lors de l'édition de texte dans des champs de texte (par exemple, les commentaires, les réponses, les descriptions de tickets et les descriptions de merge requests) :

| Raccourci macOS                                       | Raccourci Windows                                   | Description |
|------------------------------------------------------|----------------------------------------------------|-------------|
| <kbd>↑</kbd>                                         | <kbd>↑</kbd>                                       | Modifier votre dernier commentaire. Vous devez vous trouver dans un champ de texte vide sous un fil de discussion et avoir déjà au moins un commentaire dans ce fil. |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>p</kbd>     | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>p</kbd>   | Activer ou désactiver l'aperçu Markdown lors de l'édition de texte dans un champ de texte doté des onglets **Écrire** et **Aperçu** en haut. |
| <kbd>Command</kbd>+<kbd>b</kbd>                      | <kbd>Control</kbd>+<kbd>b</kbd>                    | Mettre le texte sélectionné en gras (l'entourer de `**`). |
| <kbd>Command</kbd>+<kbd>i</kbd>                      | <kbd>Control</kbd>+<kbd>i</kbd>                    | Mettre le texte sélectionné en italique (l'entourer de `_`). |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>     | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>   | Barrer le texte sélectionné (l'entourer de `~~`). |
| <kbd>Command</kbd>+<kbd>k</kbd>                      | <kbd>Control</kbd>+<kbd>k</kbd>                    | Ajouter un lien (entourer le texte sélectionné de `[]()`). |
| <kbd>Command</kbd>+<kbd>[</kbd>                      | <kbd>Control</kbd>+<kbd>[</kbd>                    | Désindenter le texte. |
| <kbd>Command</kbd>+<kbd>]</kbd>                      | <kbd>Control</kbd>+<kbd>]</kbd>                    | Indenter le texte. |
| <kbd>Command</kbd>+<kbd>Enter</kbd>                  | <kbd>Control</kbd>+<kbd>Enter</kbd>                | Soumettre ou enregistrer les modifications |

Les raccourcis pour l'édition dans les champs de texte sont toujours activés, même si les autres raccourcis clavier sont désactivés.

## Projet {#project}

Ces raccourcis sont disponibles depuis n'importe quelle page d'un projet. Vous devez les saisir assez rapidement pour qu'ils fonctionnent, et ils vous redirigent vers une autre page du projet.

| Raccourci clavier           | Description |
|-----------------------------|-------------|
| <kbd>g</kbd>+<kbd>o</kbd>   | Accéder à la page **Vue d'ensemble du projet**. |
| <kbd>g</kbd>+<kbd>v</kbd>   | Accéder à la page **Activité** du projet (**Gérer** > **Activité**). |
| <kbd>g</kbd>+<kbd>r</kbd>   | Accéder à la page **Release** du projet (**Déployer** > **Release**). |
| <kbd>g</kbd>+<kbd>f</kbd>   | Accéder aux [fichiers du projet](#project-files) (**Code** > **Dépôt**). |
| <kbd>t</kbd>                | Ouvrir la boîte de dialogue de recherche de fichiers du projet. (**Code** > **Dépôt**, sélectionnez **Rechercher un fichier**). |
| <kbd>g</kbd>+<kbd>c</kbd>   | Accéder à la page **Validation** du projet (**Code** > **Validation**). |
| <kbd>g</kbd>+<kbd>n</kbd>   | Accéder à la page [**Graphe du dépôt**](#repository-graph) (**Code** > **Graphe du dépôt**). |
| <kbd>g</kbd>+<kbd>d</kbd>   | Accéder aux graphiques de la page **Données d'analyse du dépôt** (**Analyse** > **Données d'analyse du dépôt**). |
| <kbd>g</kbd>+<kbd>i</kbd>   | Accéder à la page **Éléments de travail** du projet (**Forfait** > **Éléments de travail**). |
| <kbd>i</kbd>                | Accéder à la page **Nouveau ticket** (**Forfait** > **Éléments de travail**, sélectionnez **Nouvel élément** ). |
| <kbd>g</kbd>+<kbd>b</kbd>   | Accéder à la page **Tableaux des tickets** du projet (**Forfait** > **Tableaux des tickets**). |
| <kbd>g</kbd>+<kbd>m</kbd>   | Accéder à la page **Requêtes de fusion** du projet (**Code** > **Requêtes de fusion**). |
| <kbd>g</kbd>+<kbd>p</kbd>   | Accéder à la page **Pipelines** CI/CD (**Version** > **Pipelines**). |
| <kbd>g</kbd>+<kbd>j</kbd>   | Accéder à la page **Jobs** CI/CD (**Version** > **Jobs**). |
| <kbd>g</kbd>+<kbd>e</kbd>   | Accéder à la page **Environnements** du projet (**Opération** > **Environnements**). |
| <kbd>g</kbd>+<kbd>k</kbd>   | Accéder à la page d'intégration **Clusters Kubernetes** du projet (**Opération** > **Clusters Kubernetes**). Vous devez disposer au minimum des [autorisations `maintainer`](permissions.md) pour accéder à cette page. |
| <kbd>g</kbd>+<kbd>s</kbd>   | Accéder à la page **Extraits de code** du projet (**Code** > **Extraits de code**). |
| <kbd>g</kbd>+<kbd>w</kbd>   | Accéder au wiki du projet (**Forfait** > **Wiki**), si activé. |
| <kbd>.</kbd>                | Ouvrir le Web IDE. |

### Tickets {#issues}

Ces raccourcis sont disponibles lors de la consultation des tickets :

| Raccourci clavier           | Description |
|-----------------------------|-------------|
| <kbd>e</kbd>                | Modifier la description. |
| <kbd>a</kbd>                | Changer le responsable. |
| <kbd>m</kbd>                | Changer le jalon. |
| <kbd>l</kbd>                | Changer le label. |
| <kbd>c</kbd>+<kbd>r</kbd>   | Copier la référence du ticket. |
| <kbd>r</kbd>                | Commencer à rédiger un commentaire. Le texte présélectionné est cité dans le commentaire. |
| <kbd>→</kbd>                | Aller au design suivant. |
| <kbd>←</kbd>                | Aller au design précédent. |
| <kbd>Escape</kbd>           | Fermer le design. |

### Merge requests {#merge-requests}

Ces raccourcis sont disponibles lors de la consultation des [merge requests](project/merge_requests/_index.md) :

| Raccourci macOS                    | Raccourci Windows                  | Description |
|-----------------------------------|-----------------------------------|-------------|
| <kbd>]</kbd> ou <kbd>j</kbd>      |                                   | Passer au fichier suivant. |
| <kbd>[</kbd> ou <kbd>k</kbd>  |                                   | Passer au fichier précédent. |
| <kbd>Command</kbd>+<kbd>p</kbd>   | <kbd>Control</kbd>+<kbd>p</kbd>   | Rechercher un fichier et accéder directement à celui-ci pour le réviser. |
| <kbd>n</kbd>                      |                                   | Passer au fil de discussion ouvert suivant. |
| <kbd>p</kbd>                      |                                   | Passer au fil de discussion ouvert précédent. |
| <kbd>b</kbd>                      |                                   | Copier le nom de la branche source. |
| <kbd>c</kbd>+<kbd>r</kbd>         |                                   | Copier la référence de la merge request. |
| <kbd>r</kbd>                      |                                   | Commencer à rédiger un commentaire. Le texte présélectionné est cité dans le commentaire. |
| <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>Enter</kbd> | <kbd>Shift</kbd>+<kbd>Control</kbd>+<kbd>Enter</kbd> | Publier votre commentaire immédiatement. |
| <kbd>Command</kbd>+<kbd>Enter</kbd> | <kbd>Control</kbd>+<kbd>Enter</kbd> | Ajouter votre commentaire en attente, dans le cadre d'une révision. |
| <kbd>c</kbd>                      |                                   | Passer au commit suivant. |
| <kbd>x</kbd>                      |                                   | Passer au commit précédent. |
| <kbd>Shift</kbd>+<kbd>f</kbd>     |                                   | Activer ou désactiver l'explorateur de fichiers. |
| <kbd>v</kbd>                      |                                   | Marquer le fichier comme consulté ou non consulté. |
| <kbd>;</kbd>                      |                                   | Développer tous les fichiers. |
| <kbd>Shift</kbd>+<kbd>;</kbd>     |                                   | Réduire tous les fichiers. |
| <kbd>Shift</kbd>+<kbd>d</kbd>     |                                   | Basculer entre la vue diff en ligne et la vue diff côte à côte. |

### Fichiers du projet {#project-files}

Ces raccourcis sont disponibles lors de la navigation dans les fichiers d'un projet (accédez à **Code** > **Dépôt**) :

| Raccourci clavier | Description |
|-------------------|-------------|
| <kbd>↑</kbd>      | Déplacer la sélection vers le haut (uniquement lors de la recherche de fichiers, **Code** > **Dépôt**, puis sélectionnez **Rechercher un fichier**). |
| <kbd>↓</kbd>      | Déplacer la sélection vers le bas (uniquement lors de la recherche de fichiers, **Code** > **Dépôt**, puis sélectionnez **Rechercher un fichier**). |
| <kbd>Enter</kbd>  | Ouvrir la sélection (uniquement lors de la recherche de fichiers, **Code** > **Dépôt**, puis sélectionnez **Rechercher un fichier**). |
| <kbd>Escape</kbd> | Revenir à l'écran **Rechercher un fichier** (uniquement lors de la recherche de fichiers, **Code** > **Dépôt**, puis sélectionnez **Rechercher un fichier**). |
| <kbd>y</kbd>      | Accéder au lien permanent du fichier (uniquement lors de la consultation d'un fichier). |
| <kbd>.</kbd>      | Ouvrir le Web IDE. |
| <kbd>Shift</kbd>+<kbd>f</kbd> | Afficher ou masquer le [navigateur d'arborescence de fichiers](project/repository/files/file_tree_browser.md). |
| <kbd>f</kbd>      | Ouvrir le panneau de recherche (uniquement lorsque le navigateur d'arborescence de fichiers est ouvert). |

### Graphe du dépôt {#repository-graph}

Ces raccourcis sont disponibles lors de la consultation de la page [graphe du dépôt](project/repository/_index.md#repository-history-graph) du projet (accédez à **Code** > **Graphe du dépôt**) :

| Raccourci clavier                                                  | Description |
|--------------------------------------------------------------------|-------------|
| <kbd>←</kbd> ou <kbd>h</kbd>                                       | Faire défiler vers la gauche. |
| <kbd>→</kbd> ou <kbd>l</kbd>                                       | Faire défiler vers la droite. |
| <kbd>↑</kbd> ou <kbd>k</kbd>                                       | Faire défiler vers le haut. |
| <kbd>↓</kbd> ou <kbd>j</kbd>                                       | Faire défiler vers le bas. |
| <kbd>Shift</kbd>+<kbd>↑</kbd> ou <kbd>Shift</kbd>+<kbd>k</kbd>     | Faire défiler jusqu'en haut. |
| <kbd>Shift</kbd>+<kbd>↓</kbd> ou <kbd>Shift</kbd>+<kbd>j</kbd>     | Faire défiler jusqu'en bas. |

### Incidents {#incidents}

Ces raccourcis sont disponibles lors de la consultation des incidents :

| Raccourci clavier             | Description |
|-------------------------------|-------------|
| <kbd>c</kbd>+<kbd>r</kbd>     | Copier la référence de l'incident. |

### Pages wiki {#wiki-pages}

Ce raccourci est disponible lors de la consultation d'une [page wiki](project/wiki/_index.md) :

| Raccourci clavier | Description     |
|-------------------|-----------------|
| <kbd>e</kbd>      | Modifier la page wiki. |

### Éditeur en texte enrichi {#rich-text-editor}

Ces raccourcis sont disponibles lors de la modification d'un fichier avec l'[éditeur de texte enrichi](rich_text_editor.md) :

| Raccourci macOS | Raccourci Windows | Description |
|----------------|------------------|-------------|
| <kbd>Command</kbd>+<kbd>c</kbd> | <kbd>Control</kbd>+<kbd>c</kbd> | Copier |
| <kbd>Command</kbd>+<kbd>x</kbd> | <kbd>Control</kbd>+<kbd>x</kbd> | Couper |
| <kbd>Command</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>v</kbd> | Coller |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | Coller sans mise en forme |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>v</kbd> | Dans une cellule de tableau, coller un tableau copié en tant que tableau imbriqué dans la cellule |
| <kbd>Command</kbd>+<kbd>z</kbd> | <kbd>Control</kbd>+<kbd>z</kbd> | Annuler |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>v</kbd> | Rétablir |
| <kbd>Shift</kbd>+<kbd>Enter</kbd> | <kbd>Shift</kbd>+<kbd>Enter</kbd> | Ajouter un saut de ligne |

#### Mise en forme {#formatting}

| Raccourci macOS | Raccourci Windows/Linux | Description |
|----------------|------------------------|-------------|
| <kbd>Command</kbd>+<kbd>b</kbd> | <kbd>Control</kbd>+<kbd>b</kbd>  | Gras |
| <kbd>Command</kbd>+<kbd>i</kbd> | <kbd>Control</kbd>+<kbd>i</kbd>   | Italique |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>x</kbd>   | Texte barré |
| <kbd>Command</kbd>+<kbd>k</kbd> | <kbd>Control</kbd>+<kbd>k</kbd>   | Insérer un lien |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>0</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>0</kbd> | Appliquer le style de texte normal |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>1</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>1</kbd> | Appliquer le style de titre 1 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>2</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>2</kbd> | Appliquer le style de titre 2 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>3</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>3</kbd> | Appliquer le style de titre 3 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>4</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>4</kbd> | Appliquer le style de titre 4 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>5</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>5</kbd> | Appliquer le style de titre 5 |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>6</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>6</kbd> | Appliquer le style de titre 6 |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>7</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>7</kbd> | Liste ordonnée |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>8</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>8</kbd> | Liste non ordonnée |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>9</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>9</kbd> | Liste de tâches |
| <kbd>Command</kbd>+<kbd>Option</kbd>+<kbd>c</kbd> | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>c</kbd> | Bloc de code |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>h</kbd>  | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>h</kbd> | Surligner |
| <kbd>Command</kbd>+<kbd>,</kbd> | <kbd>Control</kbd>+<kbd>,</kbd> | Indice |
| <kbd>Command</kbd>+<kbd>.</kbd> | <kbd>Control</kbd>+<kbd>.</kbd> | Exposant |
| <kbd>Tab</kbd> | <kbd>Tab</kbd> | Indenter la liste |
| <kbd>Shift</kbd>+<kbd>Tab</kbd> | <kbd>Shift</kbd>+<kbd>Tab</kbd> | Désindenter la liste |

#### Sélection de texte {#text-selection}

| Raccourci macOS                    | Raccourci Windows                  | Description |
|-----------------------------------|-----------------------------------|-------------|
| <kbd>Command</kbd>+<kbd>a</kbd>   | <kbd>Control</kbd>+<kbd>a</kbd>   | Tout sélectionner |
| <kbd>Shift</kbd>+<kbd>←</kbd>     | <kbd>Shift</kbd>+<kbd>←</kbd>     | Étendre la sélection d'un caractère vers la gauche |
| <kbd>Shift</kbd>+<kbd>→</kbd>     | <kbd>Shift</kbd>+<kbd>→</kbd>     | Étendre la sélection d'un caractère vers la droite |
| <kbd>Shift</kbd>+<kbd>↑</kbd>     | <kbd>Shift</kbd>+<kbd>↑</kbd>     | Étendre la sélection d'une ligne vers le haut |
| <kbd>Shift</kbd>+<kbd>↓</kbd>     | <kbd>Shift</kbd>+<kbd>↓</kbd>     | Étendre la sélection d'une ligne vers le bas |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>↑</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>↑</kbd> | Étendre la sélection jusqu'au début du document |
| <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>↓</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>↓</kbd> | Étendre la sélection jusqu'à la fin du document |

### GitLab Duo Chat {#gitlab-duo-chat}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module d'extension : GitLab Duo Core, Pro ou Enterprise, GitLab Duo with Amazon Q
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduction dans GitLab 18.7.

{{< /history >}}

Les raccourcis suivants sont disponibles lors de l'utilisation de [GitLab Duo Non-Agentic Chat](gitlab_duo_chat/_index.md) avec un IDE pris en charge.

| Raccourci macOS                    | Raccourci Windows                  | Description | VS Code | JetBrains IDEs | Visual Studio |
|-----------------------------------|-----------------------------------|-------------|---|---|---|
| <kbd>Option</kbd>+<kbd>d</kbd>    | <kbd>Alt</kbd>+<kbd>d</kbd> | Ouvrir ou fermer le Chat, ou basculer le focus vers le Chat s'il est déjà ouvert| {{< yes >}} | {{< yes >}} | {{< no >}} |
| <kbd>Option</kbd>+<kbd>n</kbd>    | <kbd>Alt</kbd>+<kbd>n</kbd> | Dans le Chat, démarrer une nouvelle conversation. | {{< yes >}} | {{< no >}} | {{< no >}} |
| <kbd>Option</kbd>+<kbd>r</kbd>    | <kbd>Alt</kbd>+<kbd>r</kbd> | [Refactoriser le code](gitlab_duo_chat/examples.md#refactor-code-in-the-ide)| {{< yes >}} | {{< no >}} | {{< no >}} |
| <kbd>Option</kbd>+<kbd>t</kbd>    | <kbd>Alt</kbd>+<kbd>t</kbd> | [Écrire des tests](gitlab_duo_chat/examples.md#write-tests-in-the-ide)| {{< yes >}} | {{< no >}} | {{< no >}} |

Vous pouvez personnaliser ces raccourcis dans votre IDE.

#### Personnaliser dans VS Code {#customize-in-vs-code}

1. Dans VS Code, accédez à **Paramètres** > **Raccourcis clavier**.
1. Dans la zone de texte de recherche, saisissez <kbd>GitLab</kbd> pour trouver tous les raccourcis GitLab.
1. Pour le raccourci que vous souhaitez personnaliser, sélectionnez **Modifier le raccourci clavier (Entrée)** {{< icon name="pencil" >}}.
1. Appuyez sur la nouvelle combinaison de touches de raccourci, puis appuyez sur <kbd>Enter</kbd>.

#### Personnaliser dans JetBrains IDEs {#customize-in-jetbrains-ides}

1. Dans votre IDE JetBrains, accédez à **Paramètres** > **Keymap**, ou aux paramètres de mappage clavier équivalents pour votre IDE.
1. Trouvez tous les raccourcis GitLab.
1. Personnalisez le raccourci approprié et enregistrez.

#### Personnaliser dans Visual Studio {#customize-in-visual-studio}

1. Dans Visual Studio, accédez à **Outils** > **Options**.
1. Accédez à **Environnement** > **Clavier**.
1. Dans la zone de texte **Afficher les commandes contenant :**, saisissez <kbd>GitLab</kbd> pour trouver tous les raccourcis GitLab.
1. Sous **Appuyer sur les touches de raccourci**, sélectionnez la combinaison de touches de raccourci actuelle.
1. Appuyez sur la nouvelle combinaison de touches de raccourci, puis sélectionnez **Assigner**.
1. Sélectionnez **OK**.

## Epics {#epics}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ces raccourcis sont disponibles lors de la consultation des [epics](group/epics/_index.md) :

| Raccourci clavier            | Description       |
|------------------------------|-------------------|
| <kbd>e</kbd>                 | Modifier la description. |
| <kbd>l</kbd>                 | Changer le label.     |
| <kbd>c</kbd>+<kbd>r</kbd>    | Copier la référence de l'epic. |

## Désactiver les raccourcis clavier {#disable-keyboard-shortcuts}

Pour désactiver les raccourcis clavier :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Préférences**.
1. Dans la section **Comportement**, décochez la case **Activer les raccourcis clavier**.
1. Sélectionnez **Enregistrer les modifications**.

## Activer les raccourcis clavier {#enable-keyboard-shortcuts}

Pour activer les raccourcis clavier :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Préférences**.
1. Dans la section **Comportement**, cochez la case **Activer les raccourcis clavier**.
1. Sélectionnez **Enregistrer les modifications**.

## Dépannage {#troubleshooting}

### Raccourcis Linux {#linux-shortcuts}

Les utilisateurs Linux peuvent rencontrer des raccourcis clavier GitLab qui sont remplacés par ceux de leur système d'exploitation ou de leur navigateur.
