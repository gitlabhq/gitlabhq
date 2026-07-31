---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Paramètres et commandes de l'extension GitLab pour VS Code."
title: "Paramètres et commandes de l'extension GitLab pour VS Code"
---

L'extension GitLab pour VS Code s'intègre à la palette de commandes de VS Code, étend les intégrations existantes de VS Code avec Git et fournit des options de configuration.

## Commandes de la palette de commandes {#command-palette-commands}

Cette extension fournit plusieurs ensembles de commandes que vous pouvez déclencher dans la [palette de commandes](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette) :

### Gérer les projets et le code {#manage-projects-and-code}

- `GitLab: Authenticate`
- [`GitLab: Compare Current Branch with Default Branch`](projects.md#compare-with-default-branch) : Comparez votre branche avec la branche par défaut du dépôt et affichez les modifications sur GitLab.
- `GitLab: Open Current Project on GitLab`
- [`GitLab: Open Remote Repository`](remote_urls.md) : Parcourez un dépôt GitLab distant.
- `GitLab: Pipeline Actions - View, Create, Retry, or Cancel`
- `GitLab: Remove Account from VS Code`
- `GitLab: Validate GitLab Accounts`

### Gérer les tickets et les merge requests {#manage-issues-and-merge-requests}

- [`GitLab: Advanced Search (Issues, Merge Requests, Commits, Comments...)`](projects.md#search-issues-and-merge-requests)
- `GitLab: Copy Link to Active File on GitLab`
- `GitLab: Create New Issue on Current Project`
- `GitLab: Create New Merge Request on Current Project` : Ouvrez la page de merge request pour créer une merge request.
- [`GitLab: Open Active File on GitLab`](projects.md#open-current-file-in-gitlab-ui) : Affichez le fichier actif sur GitLab en mettant en surbrillance le numéro de ligne actif et le bloc de texte sélectionné.
- `GitLab: Open Merge Request for Current Branch`
- [`GitLab: Search Project Issues (Supports Filters)`](projects.md#search-issues-and-merge-requests).
- [`GitLab: Search Project Merge Requests (Supports Filters)`](projects.md#search-issues-and-merge-requests).
- `GitLab: Show Issues Assigned to Me` : Ouvrez les tickets qui vous sont assignés sur GitLab.
- `GitLab: Show Merge Requests Assigned to Me` : Ouvrez les merge requests qui vous sont assignées sur GitLab.

### Gérer les pipelines CI/CD {#manage-cicd-pipelines}

- [`GitLab: Show Merged GitLab CI/CD Configuration`](cicd.md#show-merged-configuration-file) : Affichez un aperçu du fichier de configuration pipeline CI/CD GitLab `.gitlab-ci.yml` avec tous les includes résolus.
- [`GitLab: Validate GitLab CI/CD Configuration`](cicd.md#test-gitlab-cicd-configuration) : Testez le fichier de configuration pipeline CI/CD GitLab `.gitlab-ci.yml`.

### Fonctionnalités assistées par l'IA {#ai-assisted-features}

- `GitLab: Restart GitLab Language Server`
- `GitLab: Show Duo Workflow`
- `GitLab: Toggle Code Suggestions`
- `GitLab: Toggle Code Suggestions for current language`

### Autres fonctionnalités {#other-features}

- `GitLab: Apply Snippet Patch`
- `GitLab: Clone Wiki`
- [`GitLab: Create Snippet`](projects.md#create-a-snippet) : Créez un extrait de code public, interne ou privé à partir d'un fichier entier ou d'une sélection.
- [`GitLab: Create Snippet Patch`](projects.md#create-a-patch-file) : Créez un fichier `.patch` à partir du fichier entier ou d'une sélection.
- [`GitLab: Insert Snippet`](projects.md#insert-a-snippet) : Insérez un extrait de code de projet à fichier unique ou à plusieurs fichiers.
- `GitLab: Publish Workspace to GitLab`
- `GitLab: Refresh Sidebar`
- `GitLab: Show Extension Logs`
- `GitLab: View Security Finding Details`
- `GitLab: Focus on For current branch View`
- `GitLab: Focus on Issues and Merge Requests View`
- `GitLab: Diagnostics` : Ouvrez une page de paramètres détaillée pour l'extension GitLab pour VS Code.

## Intégrations de commandes {#command-integrations}

Cette extension s'intègre également à certaines commandes fournies par VS Code :

- `Git: Clone` : Recherchez et clonez des projets pour chaque instance GitLab que vous configurez. Pour plus d'informations, consultez :
  - [Cloner des projets GitLab](remote_urls.md#clone-a-git-project) dans la documentation de l'extension.
  - [Cloner un dépôt](https://code.visualstudio.com/docs/sourcecontrol/overview#_cloning-a-repository) dans la documentation de VS Code.
- `Git: Add Remote...` : Ajoutez des projets existants en tant que remotes depuis chaque instance GitLab que vous configurez.

## Paramètres de l'extension {#extension-settings}

Pour savoir comment modifier les paramètres dans VS Code, consultez la documentation VS Code pour les [paramètres utilisateur et workspace](https://code.visualstudio.com/docs/configure/settings).

Si vous utilisez des certificats auto-signés pour vous connecter à votre instance GitLab, consultez [configurer l'extension pour les autorités de certification personnalisées](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/docs/user/custom-certificates.md).

| Paramètre | Valeur par défaut | Informations |
| ------- | ------- | ----------- |
| `gitlab.customQueries` | Sans objet | Définit les requêtes de recherche qui récupèrent les éléments affichés dans le panneau GitLab. Pour plus d'informations, consultez la [documentation sur les requêtes personnalisées](custom_queries.md). |
| `gitlab.authentication.oauthClientIds` | Sans objet | L'ID client OAuth à utiliser (par URL d'instance GitLab) lors de la [configuration](setup.md#authenticate-with-gitlab). |
| `gitlab.debug` | false | Lorsque `true`, active le mode de débogage. Le mode de débogage améliore les traces de pile d'erreurs car l'extension utilise des source maps pour comprendre le code minifié. Le mode de débogage affiche également les messages du journal de débogage dans les [journaux de l'extension](troubleshooting.md#view-debug-logs). |
| `gitlab.duo.enabledWithoutGitlabProject` | true | Lorsque `true`, maintient les fonctionnalités GitLab Duo activées si l'extension ne peut pas récupérer le paramètre `duoFeaturesEnabledForProject` du projet. Lorsque `false`, désactive toutes les fonctionnalités GitLab Duo si l'extension ne peut pas récupérer le paramètre `duoFeaturesEnabledForProject` du projet. Voir le [paramètre `duoFeaturesEnabledForProject`](#duofeaturesenabledforproject). |
| `gitlab.duoAgentPlatform.defaultNamespace` | Sans objet | Le chemin de groupe ou d'espace de nommage par défaut pour la plateforme d'agents GitLab Duo lorsque l'extension ne peut pas obtenir les détails du projet GitLab. |
| `gitlab.duoCodeSuggestions.additionalLanguages` | Sans objet | (Expérimental.) Pour développer la liste des langages officiellement pris en charge pour GitLab Duo Code Suggestions, fournissez un tableau des [identifiants de langage](https://code.visualstudio.com/docs/languages/identifiers#_known-language-identifiers). La qualité de Code Suggestions pour les langages ajoutés peut ne pas être optimale. |
| `gitlab.duoCodeSuggestions.enabled` | true | Lorsque `true`, active Code Suggestions pour les suggestions assistées par l'IA. |
| `gitlab.duoCodeSuggestions.enabledSupportedLanguages` | Sans objet | Les langages pris en charge pour lesquels activer Code Suggestions. Par défaut, tous les langages pris en charge sont activés. |
| `gitlab.duoCodeSuggestions.openTabsContext` | true | Lorsque `true`, active l'envoi du contexte des onglets ouverts pour améliorer Code Suggestions. |
| `gitlab.keybindingHints.enabled` | true | Active les raccourcis clavier pour GitLab Duo. |
| `gitlab.pipelineGitRemoteName` | null | Le nom du remote Git correspondant au dépôt GitLab contenant vos pipelines. Lorsque `null` ou vide, l'extension utilise le même remote que pour les fonctionnalités hors pipeline. |
| `gitlab.showPipelineUpdateNotifications` | false | Lorsque `true`, affiche une alerte quand un pipeline se termine. |

### `duoFeaturesEnabledForProject` {#duofeaturesenabledforproject}

Le paramètre `duoFeaturesEnabledForProject` est indisponible si :

- Le projet n'est pas configuré dans l'extension.
- Le projet se trouve sur une instance GitLab différente de votre compte actuel.
- Le fichier ou dossier sur lequel vous travaillez ne fait partie d'aucun projet GitLab auquel vous avez accès.
