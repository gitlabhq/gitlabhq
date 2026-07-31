---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'extension GitLab pour VS Code pour effectuer des tâches GitLab courantes directement dans VS Code."
title: "Installer et configurer l'extension GitLab pour VS Code"
---

Pour utiliser l'extension GitLab pour VS Code, installez l'extension, connectez-vous à GitLab, puis configurez-la selon vos besoins.

## Installer l'extension {#install-the-extension}

Choisissez la méthode d'installation qui correspond à vos besoins :

- Pour VS Code standard, effectuez l'installation depuis le [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).
- Pour les versions non officielles de VS Code, effectuez l'installation depuis l'[Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow).
- Pour le développement local sécurisé, effectuez l'installation dans un Visual Studio Code Dev Container.

### Installer dans un Visual Studio Code Dev Container {#install-in-a-visual-studio-code-dev-container}

Pour une sécurité renforcée, configurez l'extension et utilisez GitLab Duo dans un environnement de développement conteneurisé à l'aide des [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers).

Prérequis :

- [Docker](https://www.docker.com/products/docker-desktop/) est installé et en cours d'exécution.
- L'extension Visual Studio Code [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) est installée dans VS Code.

Pour installer l'extension dans un VS Code Dev Container :

1. Exécutez la commande **Dev Containers : Add Dev Container Configuration Files** depuis la palette de commandes.
1. Ajoutez l'extension GitLab au fichier de configuration :

   ```json
   // .devcontainer/devcontainer.json
   {
   "name": "My Project",
   "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
   "customizations": {
      "vscode": {
         "extensions": [
         "GitLab.gitlab-workflow"
         ]
      }
   }
   }
   ```

1. Exécutez la commande **Dev Containers : Open Folder in Container** pour ouvrir votre projet dans un VS Code Dev Container. VS Code installe automatiquement l'extension dans le conteneur.

## Se connecter à GitLab {#connect-to-gitlab}

Après avoir installé l'extension, authentifiez-vous, puis connectez votre projet à un dépôt sur GitLab.

### S'authentifier avec GitLab {#authenticate-with-gitlab}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CHANGELOG.md#release--6470-2025-09-26) de l'authentification OAuth pour GitLab Self-Managed et GitLab Dedicated dans GitLab pour VS Code 6.47.0, lors de la release de GitLab 18.3.

{{< /history >}}

{{< tabs >}}

{{< tab title="GitLab.com" >}}

Prérequis :

- Pour l'authentification à l'aide d'un PAT, un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) avec la portée `api`.

Pour s'authentifier avec GitLab :

1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Saisissez `GitLab: Authenticate` et appuyez sur <kbd>Enter</kbd>.
1. Sélectionnez l'URL de votre instance GitLab dans les options ou saisissez-en une manuellement.
   - Si vous en saisissez une manuellement, dans **URL to GitLab instance**, collez l'URL complète, y compris `http://` ou `https://`. Appuyez sur <kbd>Enter</kbd> pour confirmer.
1. Sélectionnez une méthode d'authentification, **OAuth** ou **PAT**.
   - Pour OAuth, suivez les instructions pour vous connecter et vous authentifier.
   - Pour PAT, suivez les invites pour créer un jeton ou en saisir un existant afin de vous authentifier.

{{< /tab >}}

{{< tab title="GitLab Self-Managed et GitLab Dedicated" >}}

Prérequis :

- Pour l'authentification par OAuth, l'ID d'application pour une [application OAuth pour VS Code](../../administration/settings/editor_extensions.md#vs-code).
- Pour l'authentification à l'aide d'un PAT, un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) avec la portée `api`.

Pour utiliser OAuth, configurez d'abord la connexion de l'application OAuth :

1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Saisissez `Preferences: Open User Settings` et appuyez sur <kbd>Enter</kbd>.
1. Sélectionnez **Paramètres** > **Extensions** > **GitLab** > **Authentification**.
1. Sous **OAuth Client IDs**, sélectionnez **Add Item**.
1. Sélectionnez **Clé** et saisissez l'URL de l'instance GitLab.
1. Sélectionnez **Valeur** et saisissez l'ID de l'application OAuth.

Pour s'authentifier avec GitLab :

1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Saisissez `GitLab: Authenticate` et appuyez sur <kbd>Enter</kbd>.
1. Sélectionnez l'URL de votre instance GitLab dans les options ou saisissez-en une manuellement.
   - Si vous en saisissez une manuellement, dans **URL to GitLab instance**, collez l'URL complète, y compris `http://` ou `https://`. Appuyez sur <kbd>Enter</kbd> pour confirmer.
1. Sélectionnez une méthode d'authentification, **OAuth** ou **PAT**.
   - Pour OAuth, suivez les instructions pour vous connecter et vous authentifier.
   - Pour PAT, suivez les invites pour créer un jeton ou en saisir un existant afin de vous authentifier.

{{< /tab >}}

{{< /tabs >}}

L'extension associe l'URL distante de votre dépôt Git à l'URL de l'instance GitLab que vous avez spécifiée pour votre jeton. Si vous avez plusieurs comptes ou projets, vous pouvez choisir celui que vous souhaitez utiliser.

> [!note]
> Si votre instance GitLab ou votre réseau utilise une configuration SSL personnalisée, vous pouvez configurer l'extension pour prendre en charge les certificats auto-signés. Pour plus d'informations, consultez [utiliser l'extension avec des certificats auto-signés](ssl.md).

### Se connecter à votre dépôt {#connect-to-your-repository}

Pour vous connecter à votre dépôt GitLab depuis VS Code :

1. Dans VS Code, dans le menu supérieur, sélectionnez **Terminal** > **New Terminal**.
1. Clonez votre dépôt : `git clone <repository>`.
1. Accédez au répertoire dans lequel votre dépôt a été cloné et extrayez votre branche : `git checkout <branch_name>`.
1. Assurez-vous que votre projet est sélectionné :
   1. Dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}).
   1. Sélectionnez le nom du projet. Si vous avez plusieurs projets, sélectionnez celui avec lequel vous souhaitez travailler.
1. Dans le terminal, vérifiez que votre dépôt est configuré avec un distant : `git remote -v`. Les résultats devraient ressembler à :

   ```plaintext
   origin  git@gitlab.com:gitlab-org/gitlab.git (fetch)
   origin  git@gitlab.com:gitlab-org/gitlab.git (push)
   ```

   Si aucun distant n'est défini, ou si vous avez plusieurs distants :

   1. Dans la barre latérale gauche, sélectionnez **Source Control** ({{< icon name="branch" >}}).
   1. Sur le label **Source Control**, faites un clic droit et sélectionnez **Dépôts**.
   1. À côté de votre dépôt, sélectionnez les points de suspension ({{< icon name=ellipsis_h >}}), puis **Distant** > **Add Remote**.
   1. Sélectionnez **Add remote from GitLab**.
   1. Choisissez un distant.

L'extension affiche des informations dans la barre d'état VS Code si les deux conditions suivantes sont remplies :

- Votre projet dispose d'un pipeline pour le dernier commit.
- Votre branche actuelle est associée à une merge request.

## Configurer l'extension {#configure-the-extension}

Pour configurer les paramètres, accédez à **Paramètres** > **Extensions** > **GitLab**.

### Configurer les comptes et les projets {#configure-accounts-and-projects}

Après vous être authentifié et connecté à votre dépôt, l'extension associe automatiquement votre compte GitLab et votre projet en fonction de la configuration de votre dépôt Git.

Dans certains environnements, une configuration supplémentaire peut être nécessaire pour conserver vos identifiants.

#### Stocker les jetons dans des variables d'environnement {#store-tokens-in-environment-variables}

Si vous supprimez souvent votre stockage VS Code, par exemple dans des conteneurs Gitpod, stockez vos jetons d'authentification dans des [variables d'environnement VS Code](https://code.visualstudio.com/docs/editor/variables-reference#_environment-variables). Les variables d'environnement persistent lorsque vous supprimez votre stockage VS Code.

Définissez ces variables avant de démarrer VS Code :

- `GITLAB_WORKFLOW_INSTANCE_URL` : L'URL de votre instance GitLab. Par exemple, `https://gitlab.com`.
- `GITLAB_WORKFLOW_TOKEN` : Votre jeton d'accès personnel.

Si vous configurez un jeton pour la même instance GitLab dans l'extension, le jeton de l'extension remplace la variable d'environnement.

#### Changer de compte {#switch-accounts}

L'extension utilise un compte pour chaque [workspace VS Code](https://code.visualstudio.com/docs/editor/workspaces) (fenêtre). Elle sélectionne automatiquement le compte dans les cas suivants :

- Vous vous authentifiez avec un seul compte GitLab dans l'extension.
- Tous les workspaces de votre fenêtre VS Code utilisent le même compte GitLab, en fonction de la configuration `git remote`.

Si plusieurs comptes GitLab existent et que l'extension ne peut pas déterminer quel compte utiliser, elle ajoute **Multiple GitLab Accounts** ({{< icon name="question-o" >}}) à la barre d'état. Pour sélectionner un compte GitLab, sélectionnez l'élément de la barre d'état et suivez les invites.

Vous pouvez également utiliser la palette de commandes :

1. Ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Exécutez la commande `GitLab: Select Account for this Workspace`.
1. Sélectionnez un compte dans la liste.

#### Sélectionner un projet {#select-a-project}

L'extension utilise le distant de votre dépôt Git pour déterminer quel projet GitLab associer à votre workspace VS Code.

Lorsque votre dépôt Git possède plusieurs distants pointant vers différents projets GitLab, l'extension ne peut pas déterminer lequel utiliser. Par exemple :

- `origin` : `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- `personal-fork` : `git@gitlab.com:myusername/gitlab-vscode-extension.git`

Dans ces cas, l'extension ajoute un label **(multiple projects)** à la barre d'état.

Pour sélectionner un projet :

1. Dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}).
1. Développez **Tickets et requêtes de fusion**.
1. Sélectionnez la ligne contenant **(multiple projects, click to select)**.
1. Sélectionnez un projet dans la liste.

La liste **Tickets et requêtes de fusion** est mise à jour avec les informations du projet sélectionné.

#### Modifier le projet {#change-the-project}

Pour modifier la sélection de votre projet :

1. Dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}).
1. Développez **Tickets et requêtes de fusion**.
1. Sélectionnez le projet.
1. À côté du nom du projet, sélectionnez **Clear Selected Project** ({{< icon name="close-xs" >}}).

### Configurer GitLab Duo {#configure-gitlab-duo}

Les fonctionnalités GitLab Duo sont activées par défaut dans VS Code lorsque vous remplissez les prérequis :

- Pour les fonctionnalités agentiques, vous remplissez les prérequis pour la [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites).
- Vous avez [activé](../../user/gitlab_duo/turn_on_off.md) GitLab Duo.
- Pour les flows, vous avez [activé les flows par défaut](../../user/duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).
- Pour les agents, vous avez [activé les agents par défaut](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off) et [activé les agents personnalisés](../../user/duo_agent_platform/agents/custom.md#enable-an-agent), selon vos besoins.
- Votre projet se trouve dans un [espace de nommage de groupe](../../user/namespace/_index.md).
- Vous avez défini un [espace de nommage GitLab Duo par défaut](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment) ou vous avez ouvert un projet disposant d'un accès à GitLab Duo.
- Pour GitLab Duo Code Suggestions, vous [remplissez les prérequis supplémentaires](../../user/project/repository/code_suggestions/set_up.md#prerequisites).

Pour approuver les outils Agentic Chat une fois par session plutôt qu'individuellement, consultez les [approbations d'outils](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals).

#### Désactiver GitLab Duo {#turn-off-gitlab-duo}

Pour désactiver les fonctionnalités GitLab Duo dans VS Code :

1. Dans VS Code, ouvrez l'éditeur de paramètres :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
1. Sélectionnez **Extensions** > **GitLab** > **GitLab Duo**.
1. Trouvez la fonctionnalité que vous souhaitez désactiver et décochez la case.

### Configurer la télémétrie {#configure-telemetry}

GitLab pour VS Code utilise les paramètres de télémétrie de Visual Studio Code pour envoyer des informations sur l'utilisation et les erreurs à GitLab. Pour activer ou personnaliser la télémétrie dans Visual Studio Code :

1. Dans VS Code, ouvrez l'éditeur de paramètres :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
1. Sélectionnez **Application** > **Telemetry**.
1. Pour **Telemetry Level**, sélectionnez les données que vous souhaitez partager :
   - `all` : Envoie des données d'utilisation, la télémétrie d'erreurs générales et des rapports de plantage.
   - `error` : Envoie la télémétrie d'erreurs générales et des rapports de plantage.
   - `crash` : Envoie des rapports de plantage au niveau du système d'exploitation.
   - `off` : Désactive toutes les données de télémétrie dans Visual Studio Code.
1. Enregistrez vos modifications.
