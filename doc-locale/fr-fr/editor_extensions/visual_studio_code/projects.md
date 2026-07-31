---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'extension GitLab pour VS Code pour travailler avec des projets GitLab directement dans votre IDE."
title: Travailler avec des projets dans VS Code
---

Utilisez l'extension GitLab pour VS Code pour travailler avec des projets GitLab :

- Planifiez et suivez le travail dans les tickets.
- Utilisez GitLab Duo pour la planification et le codage natifs par IA.
- Révisez et discutez des modifications dans les merge requests.
- Comparez des branches et affichez des fichiers dans GitLab.
- Stockez et partagez du code avec des extraits de code.

Avec l'extension, vous pouvez effectuer bon nombre de ces tâches directement dans VS Code. Pour les autres, l'extension ouvre GitLab dans votre navigateur.

## Prérequis {#prerequisites}

- [Authentifiez l'extension](setup.md#connect-to-gitlab) et connectez-vous à un dépôt sur GitLab.
- Pour GitLab Duo, consultez les [prérequis de configuration](setup.md#configure-gitlab-duo).

## Utiliser GitLab Duo pendant votre travail {#use-gitlab-duo-as-you-work}

L'extension GitLab pour VS Code vous donne accès à la plateforme GitLab Duo Agent Platform et à GitLab Duo (non agentique) pendant que vous travaillez sur vos projets.

### GitLab Duo Agent Platform {#gitlab-duo-agent-platform}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour utiliser GitLab Duo Agentic Chat, les agents et les flows :

1. Dans la barre latérale gauche, sélectionnez **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Pour interagir avec Agentic Chat, sélectionnez l'onglet de discussion et saisissez votre invite.
1. Pour travailler avec des agents, sélectionnez l'onglet de discussion, puis utilisez la liste déroulante **Nouvelle discussion** ({{< icon name="duo-chat-new" >}}) pour sélectionner un agent fondationnel ou un agent personnalisé avec lequel travailler.
1. Pour utiliser le flow Software Development, sélectionnez l'onglet des flows, puis saisissez votre invite.

Pour utiliser GitLab Duo Code Suggestions :

1. Dans la barre d'état inférieure, sélectionnez **Duo** ({{< icon name="tanuki-ai" >}}) pour vérifier le statut de la fonctionnalité.
1. Révisez et acceptez les suggestions de code en ligne pendant que vous rédigez votre code.

### GitLab Duo {#gitlab-duo}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module complémentaire : GitLab Duo Pro ou Enterprise, GitLab Duo with Amazon Q
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- L'accès à GitLab Duo Non-Agentic Chat a été supprimé pour les clients GitLab Duo Core le 21 mai 2026 dans le cadre de la version GitLab 19.0, avec un feature flag nommé `no_duo_classic_for_duo_core_users`. Activé par défaut.

{{< /history >}}

Pour utiliser GitLab Duo Non-Agentic Chat :

1. Dans la barre latérale gauche, sélectionnez **GitLab Duo Chat** ({{< icon name="duo-chat" >}}).
1. Dans la zone de message, saisissez votre question et appuyez sur <kbd>Entrée</kbd> ou sélectionnez **Envoyer**.

Pour utiliser GitLab Duo Code Suggestions :

1. Dans la barre d'état inférieure, sélectionnez **Duo** ({{< icon name="tanuki-ai" >}}) pour vérifier le statut de la fonctionnalité.
1. Révisez et acceptez les suggestions de code en ligne pendant que vous rédigez votre code.

## Créer un ticket {#create-an-issue}

Pour créer un ticket dans le projet actuel :

1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Dans la palette de commandes, recherchez **GitLab : Create New Issue on Current Project** et appuyez sur <kbd>Enter</kbd>.

GitLab ouvre la page **Nouveau ticket** dans votre navigateur par défaut.

## Créer une merge request {#create-a-merge-request}

Pour créer une merge request dans le projet actuel, dans la barre d'état inférieure, sélectionnez **Create MR** ({{< icon name="merge-request-open" >}}).

Vous pouvez également utiliser la palette de commandes :

1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Dans la palette de commandes, recherchez **GitLab : Create New Merge Request on Current Project** et appuyez sur <kbd>Enter</kbd>.

GitLab ouvre la page **Nouvelle requête de fusion** dans votre navigateur par défaut.

## Afficher les tickets et les merge requests {#view-issues-and-merge-requests}

Pour afficher les tickets et les merge requests d'un projet spécifique :

1. Dans VS Code, dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}).
1. Développez la section des tickets et des merge requests.
1. Sélectionnez un projet pour le développer.
1. Sélectionnez l'une des options suivantes pour consulter la liste des éléments :
   - **Tickets qui me sont assignés**
   - **Tickets que j'ai créés**
   - **Merge requests qui me sont assignées**
   - **Merge requests que j'examine**
   - **Merge requests que j'ai créées**
   - **Toutes les merge requests du projet**
   - Vos [requêtes personnalisées](custom_queries.md)
1. Sélectionnez un ticket ou une merge request pour l'ouvrir dans un nouvel onglet VS Code.

## Rechercher des tickets et des merge requests {#search-issues-and-merge-requests}

Utilisez la recherche filtrée ou la [recherche avancée](../../integration/advanced_search/elasticsearch.md) pour rechercher les tickets et les merge requests de votre projet directement depuis VS Code. Avec la recherche filtrée, vous utilisez des jetons prédéfinis pour affiner vos résultats de recherche. La recherche avancée offre une recherche plus rapide et plus efficace sur l'ensemble de l'instance GitLab.

Prérequis :

- Vous êtes membre d'un projet GitLab.

Pour rechercher dans votre projet :

1. Dans VS Code, ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Sélectionnez le type de recherche souhaité :
   - **GitLab : Search Project Issues (Supports Filters)**
   - **GitLab : Search Project Merge Requests (Supports Filters)**
   - **GitLab : Advanced Search (Issues, Merge Requests, Commits, Comments...)**
1. Suivez les invites pour saisir vos valeurs de recherche et affiner votre recherche.

GitLab ouvre les résultats dans un onglet de navigateur.

### Jetons pour filtrer les résultats de recherche {#tokens-to-filter-search-results}

Les recherches dans les grands projets renvoient de meilleurs résultats lorsque vous ajoutez des filtres. L'extension prend en charge ces jetons pour filtrer les merge requests et les tickets :

| Jeton     | Exemple                                                 | Description |
|-----------|---------------------------------------------------------|-------------|
| assignee  | `assignee: sjones`                                      | Nom d'utilisateur du responsable, sans `@`. |
| author    | `author: zwei`                                          | Nom d'utilisateur de l'auteur, sans `@`. |
| label     | `label: frontend` ou `label:frontend label: Discussion` | Un seul label. Utilisable plusieurs fois, et peut être utilisé dans la même requête que `labels`. |
| labels    | `labels: frontend, Discussion, performance`             | Plusieurs labels dans une liste séparée par des virgules. Peut être utilisé dans la même requête que `label`. |
| milestone | `milestone: 18.1`                                       | Titre du jalon sans `%`. |
| scope     | `scope: created-by-me`                                  | Portée du ticket ou de la merge request. Valeurs : `created-by-me` (par défaut), `assigned-to-me` ou `all`. |
| title     | `title: discussions refactor`                           | Mots à faire correspondre dans le titre ou la description. N'ajoutez pas de guillemets autour des expressions. |

Syntaxe et directives des jetons :

- Chaque nom de jeton requiert un deux-points (`:`) après lui, comme `label:`.
  - Un espace avant le deux-points (`label :`) est invalide et renvoie une erreur d'analyse.
  - Un espace après le nom du jeton est facultatif. `label: frontend` et `label:frontend` sont tous deux valides.
- Vous pouvez utiliser les jetons `label` et `labels` plusieurs fois et ensemble. Ces requêtes renvoient les mêmes résultats :
  - `labels: frontend discussion label: performance`
  - `label: frontend label: discussion label: performance`
  - `labels: frontend discussion performance` (la requête combinée résultante)

Vous pouvez combiner plusieurs jetons dans une seule requête de recherche. Par exemple :

```plaintext
title: new merge request widget author: zwei assignee: sjones labels: frontend, performance milestone: 17.5
```

Cette requête de recherche porte sur :

- Titre : `new merge request widget`
- Auteur : `zwei`
- Responsable : `sjones`
- Labels : `frontend` et `performance`
- Jalon : `17.5`

## Réviser une merge request {#review-a-merge-request}

Pour réviser, commenter et approuver des merge requests dans VS Code :

1. Dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}).
1. Développez la section des tickets et des merge requests, puis sélectionnez votre projet.
1. Sélectionnez la merge request que vous souhaitez réviser.
1. Sous le numéro et le titre de la merge request, sélectionnez **Vue d'ensemble** pour en savoir plus sur la merge request.
1. Pour réviser les modifications proposées à un fichier, sélectionnez le fichier dans la liste pour l'afficher dans un onglet VS Code. GitLab affiche les commentaires de diff en ligne dans l'onglet. Dans la liste, les fichiers supprimés sont marqués en rouge :

   ![Une liste alphabétique des fichiers modifiés dans cette merge request, incluant les types de modifications.](img/vscode_view_changed_file_v17_6.png)

Utilisez le diff pour :

- Réviser et créer des discussions.
- Résoudre et rouvrir ces discussions.
- Supprimer et modifier des commentaires individuels.

## Utiliser les actions rapides {#use-quick-actions}

Pour utiliser les [actions rapides GitLab](../../user/project/quick_actions.md) dans les tickets et les merge requests :

1. Suivez les instructions pour afficher un ticket ou une merge request dans VS Code.
1. Faites défiler vers le bas pour trouver la section des commentaires.
1. Saisissez une action rapide dans un nouveau commentaire, puis appuyez sur <kbd>Enter</kbd>. Par exemple, pour ajouter le label `bug` à un ticket, saisissez `/label bug`.

## Comparer avec la branche par défaut {#compare-with-default-branch}

Pour comparer votre branche avec la branche par défaut de votre projet, sans créer de merge request :

1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Dans la palette de commandes, recherchez **GitLab : Compare Current Branch with Default Branch** et appuyez sur <kbd>Enter</kbd>.

L'extension ouvre un nouvel onglet de navigateur. Il affiche un diff entre le commit le plus récent sur votre branche et le commit le plus récent sur la branche par défaut de votre projet.

## Ouvrir le fichier actuel dans l'interface GitLab {#open-current-file-in-gitlab-ui}

Pour ouvrir un fichier de votre projet GitLab actuel dans l'interface GitLab, avec des lignes spécifiques mises en surbrillance :

1. Ouvrez le fichier souhaité dans VS Code.
1. Sélectionnez les lignes que vous souhaitez mettre en surbrillance.
1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Dans la palette de commandes, recherchez **GitLab : Open Active File on GitLab** et appuyez sur <kbd>Enter</kbd>.

## Créer un extrait de code {#create-a-snippet}

Créez un [extrait de code](../../user/snippets.md) pour stocker et partager des fragments de code et de texte avec d'autres utilisateurs. Les extraits de code peuvent être une sélection ou un fichier entier.

Pour créer un extrait de code dans VS Code :

1. Choisissez le contenu de votre extrait de code :
   - Pour créer un extrait de code à partir d'un fichier entier, ouvrez le fichier.
   - Pour créer un extrait de code à partir d'une sélection de fichier, ouvrez le fichier et sélectionnez les lignes que vous souhaitez inclure.
1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Dans la palette de commandes, recherchez **GitLab : Create Snippet** et appuyez sur <kbd>Enter</kbd>.
1. Sélectionnez le niveau de confidentialité de l'extrait de code :
   - Les extraits de code **Privé** ne sont visibles que par les membres du projet.
   - Les extraits de code **Public** sont visibles par tous.
1. Sélectionnez la portée de l'extrait de code :
   - **Snippet from file** utilise l'intégralité du contenu du fichier actif.
   - **Snippet from selection** utilise les lignes que vous avez sélectionnées dans le fichier actif.

GitLab ouvre la page du nouvel extrait de code dans un nouvel onglet de navigateur.

### Créer un fichier patch {#create-a-patch-file}

Lorsque vous révisez une merge request, créez un patch d'extrait de code lorsque vous souhaitez suggérer des modifications sur plusieurs fichiers.

1. Sur votre machine locale, extrayez la branche pour laquelle vous souhaitez proposer des modifications.
1. Dans VS Code, modifiez tous les fichiers que vous souhaitez changer. Ne commitez pas vos modifications.
1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Dans la palette de commandes, recherchez **GitLab : Create Snippet Patch** et appuyez sur <kbd>Enter</kbd>. Cette commande exécute une commande `git diff` et crée un extrait de code GitLab dans votre projet.
1. Saisissez un **Patch name** et appuyez sur <kbd>Enter</kbd>. GitLab utilise ce nom comme titre de l'extrait de code et le convertit en nom de fichier suivi de `.patch`.
1. Sélectionnez le niveau de confidentialité de l'extrait de code :
   - Les extraits de code **Privé** ne sont visibles que par les membres du projet.
   - Les extraits de code **Public** sont visibles par tous.

VS Code ouvre le patch d'extrait de code dans un nouvel onglet de navigateur. La description du patch d'extrait de code contient des instructions sur la façon d'appliquer le patch.

### Insérer un extrait de code {#insert-a-snippet}

Pour insérer un extrait de code existant d'un seul fichier ou [multi-fichier](../../user/snippets.md#add-or-remove-multiple-files) à partir d'un projet dont vous êtes membre :

1. Placez votre curseur là où vous souhaitez insérer l'extrait de code.
1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Recherchez **GitLab : Insert Snippet** et appuyez sur <kbd>Enter</kbd>.
1. Sélectionnez le projet contenant votre extrait de code.
1. Sélectionnez l'extrait de code à appliquer.
1. Pour un extrait de code multi-fichier, sélectionnez le fichier à appliquer.

## Sujets connexes {#related-topics}

- [Les pipelines CI/CD dans l'extension VS Code](cicd.md)
- [Sécuriser votre application dans GitLab pour VS Code](security_scanning.md)
- [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md)
- [GitLab Duo](../../user/gitlab_duo/feature_summary.md)
- [Requêtes personnalisées](custom_queries.md)
