---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Outil d'interface de ligne de commande qui apporte la plateforme GitLab Duo Agent à votre terminal."
title: ILC GitLab Duo (`duo`)
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](../duo_agent_platform/model_selection.md#default-models)
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduction en tant que [version expérimentale](../../policy/development_stages_support.md#experiment) dans GitLab 18.9.
- [Ajouté](https://gitlab.com/gitlab-org/cli/-/merge_requests/2838) à l'ILC GitLab en tant que version expérimentale dans `glab` 1.87.0, lors de la release GitLab 18.9.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.68.0) de l'option de sélection de modèle et de la variable d'environnement dans GitLab Duo CLI 8.68.0, lors de la release GitLab 18.10.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.76.0) de la commande slash de sélection de modèle dans GitLab Duo CLI 8.76.0, lors de la release GitLab 18.10.
- [Passage](https://gitlab.com/groups/gitlab-org/-/work_items/19716) de la version expérimentale à la version bêta dans GitLab 18.11.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0) de la variable d'environnement et de l'option pour activer les Agent Skills au niveau utilisateur dans GitLab Duo CLI 8.83.0 en tant que [version expérimentale](../../policy/development_stages_support.md#experiment), lors de la release GitLab 19.0.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2129) de l'option Approuver des outils pour une session dans GitLab 19.0.
  - Introduction dans [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.88.0) de la commande slash `/exit` dans GitLab Duo CLI 8.88.0, lors de la release GitLab 19.0.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.94.0) de la commande slash `/doctor` dans GitLab Duo CLI 8.94.0, lors de la release GitLab 19.0.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.81.0) de la commande slash `/skills` dans GitLab Duo CLI 8.81.0, lors de la release GitLab 19.0.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) de la commande slash `/mcp` dans GitLab Duo CLI 8.95.0, lors de la release GitLab 19.0.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.90.0) du panneau de paramètres dans GitLab Duo CLI 8.90.0, lors de la release GitLab 19.0.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) de la variable d'environnement `AI_AGENT` dans GitLab Duo CLI 8.95.0, lors de la release GitLab 19.0.
- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/21850) de l'approbation d'outil basée sur des modèles dans GitLab 19.1.
  - Introduction dans [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.101.0) 8.101.0.
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.105.0) des notifications système dans GitLab Duo CLI 8.105.0, lors de la release GitLab 19.1.
- [Disponibilité générale](https://gitlab.com/groups/gitlab-org/-/work_items/19717) en tant qu'ILC GitLab Duo 9.0.0 dans GitLab 19.2.
- L'approbation d'outil basée sur des modèles [supprimée](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3699) le 10 juillet 2026.
  - Supprimé dans [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.3.0) 9.3.0.

{{< /history >}}

GitLab Duo CLI est un outil d'interface en ligne de commande qui vous permet d'utiliser [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md) depuis votre terminal. Compatible avec tous les systèmes d'exploitation et éditeurs, utilisez l'ILC pour poser des questions complexes sur votre base de code et effectuer des actions de manière autonome en votre nom.

L'ILC GitLab Duo peut vous aider à :

- Comprendre la structure de votre base de code, les fonctionnalités inter-fichiers et les extraits de code individuels.
- Créer, modifier, refactoriser et moderniser du code.
- Résoudre des erreurs et corriger des problèmes dans le code.
- Automatiser la configuration CI/CD, résoudre les erreurs de pipeline et optimiser les pipelines.
- Effectuer de manière autonome des tâches de développement en plusieurs étapes.

> [!note]
> L'ILC GitLab Duo est désormais en disponibilité générale. Mettez à jour vers l'ILC GitLab Duo 9.0.0 ou une version ultérieure pour bénéficier de l'expérience de disponibilité générale complète.

L'ILC GitLab Duo propose deux modes :

- Mode interactif : offre une expérience de chat similaire à GitLab Duo Chat dans l'interface GitLab ou dans les extensions d'éditeur. Prend en charge les modes build et plan.
- Mode headless : permet une utilisation non interactive dans les runners, les scripts et autres workflows automatisés.

Il prend également en charge les [instructions personnalisées](../duo_agent_platform/customize/_index.md) définies pour la plateforme GitLab Duo Agent, notamment les fichiers `chat-rules.md`, `AGENTS.md` et `SKILL.md`.

## Prérequis {#prerequisites}

- GitLab 19.2 ou version ultérieure.
- Les [prérequis pour la plateforme GitLab Duo Agent](../duo_agent_platform/_index.md#prerequisites).

> [!note]
> Si vous utilisez GitLab 18.11 à 19.1, vous pouvez utiliser la dernière version de l'ILC GitLab Duo en activant les [fonctionnalités bêta et expérimentales](../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features).

## Activer ou désactiver l'accès à l'ILC GitLab Duo {#turn-gitlab-duo-cli-access-on-or-off}

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242250) dans GitLab 19.2.

{{< /history >}}

Par défaut, l'accès à l'ILC GitLab Duo est activé.

Sur GitLab Self-Managed et GitLab Dedicated, vous pouvez activer ou désactiver l'accès à l'ILC GitLab Duo pour une instance.

Prérequis :

- Être administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **ILC GitLab Duo**, cochez ou décochez la case **Activer l'accès à l'ILC GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

## Configurer l'ILC GitLab Duo {#set-up-the-gitlab-duo-cli}

Vous pouvez utiliser l'ILC GitLab Duo via l'[ILC GitLab](https://docs.gitlab.com/cli/) (`glab`). Avec l'ILC GitLab, vous accédez aux autres fonctionnalités de GitLab et vous n'avez besoin de vous authentifier qu'une seule fois, à l'aide d'OAuth ou d'un jeton d'accès personnel.

Vous pouvez également installer et utiliser l'ILC GitLab Duo (`duo`) en tant qu'outil IA autonome, en vous authentifiant séparément avec un jeton d'accès personnel.

Les deux configurations prennent en charge les modes interactif et headless, ainsi que toutes les options, commandes et fonctionnalités de l'ILC GitLab Duo.

### Avec l'ILC GitLab {#with-the-gitlab-cli}

Prérequis :

- [ILC GitLab](https://docs.gitlab.com/cli/) 1.107.0 ou version ultérieure.
- L'ILC GitLab est [authentifiée](https://docs.gitlab.com/cli/#authenticate-with-gitlab).

Pour configurer l'ILC GitLab Duo pour une utilisation via l'ILC GitLab :

1. Exécutez la commande `glab` pour l'ILC GitLab Duo :

   ```shell
   glab duo cli
   ```

1. Suivez les instructions pour installer le binaire de l'ILC GitLab Duo.

L'ILC GitLab gère automatiquement l'authentification, vous pouvez donc commencer à utiliser l'ILC GitLab Duo immédiatement.

### Sans l'ILC GitLab {#without-the-gitlab-cli}

Pour utiliser l'ILC GitLab Duo en tant qu'outil autonome, installez-le puis authentifiez-vous.

#### Installation {#install}

Pour installer l'ILC GitLab Duo en tant que binaire compilé, téléchargez et exécutez le script d'installation.

Sur macOS et Linux :

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

Sur Windows :

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

#### Authentification {#authenticate}

> [!note]
> Si `glab` est déjà installé et authentifié sur votre système lors de la première exécution de `duo`, `duo` utilise automatiquement `glab` comme assistant d'identification. Vous n'avez pas besoin de vous authentifier séparément. Cela nécessite `glab` 1.85.2 ou version ultérieure et `duo` 8.68.0 ou version ultérieure.
>
> Si vous avez authentifié `duo` avant que cette fonctionnalité soit disponible et que vous souhaitez utiliser `glab` comme assistant d'identification à la place, supprimez vos paramètres d'authentification de `~/.gitlab/storage.json`.

Prérequis :

- Un [jeton d'accès personnel](../profile/personal_access_tokens.md) avec les autorisations `api`.

Pour vous authentifier :

1. Exécutez `duo` dans votre terminal. La première fois que vous exécutez l'ILC GitLab Duo, un écran de configuration s'affiche.
1. Saisissez une **GitLab Instance URL** puis appuyez sur <kbd>Entrée</kbd> :
   - Pour GitLab.com, saisissez `https://gitlab.com`.
   - Pour GitLab Self-Managed ou GitLab Dedicated, saisissez l'URL de votre instance.
1. Pour **GitLab Token**, saisissez votre jeton d'accès personnel.
1. Pour enregistrer et quitter l'ILC, appuyez sur <kbd>Entrée</kbd>.
1. Pour redémarrer l'ILC, exécutez `duo` dans votre terminal.

Pour modifier la configuration après la configuration initiale, utilisez `duo config edit`.

#### Authentification avec des variables d'environnement {#authenticate-with-environment-variables}

Prérequis :

- Un [jeton d'accès personnel](../profile/personal_access_tokens.md) avec les autorisations `api`.

Pour vous authentifier avec des variables d'environnement :

1. Définissez `GITLAB_TOKEN` ou `GITLAB_OAUTH_TOKEN` sur votre jeton d'accès personnel.

   ```shell
   export GITLAB_TOKEN="<your-personal-access-token>"
   ```

1. Facultatif. Définissez `GITLAB_BASE_URL` ou `GITLAB_URL` sur l'URL de votre instance GitLab personnalisée, par exemple `https://gitlab.example.com`. La valeur par défaut est `https://gitlab.com`.

   ```shell
   export GITLAB_BASE_URL="<your-instance-url>"
   ```

Cette méthode est utile pour le mode headless, les pipelines CI/CD et les workflows scriptés où l'authentification interactive n'est pas possible.

## Utiliser l'ILC GitLab Duo {#use-the-gitlab-duo-cli}

Prérequis :

- Un [espace de nommage GitLab Duo par défaut](../profile/preferences.md#namespace-resolution-in-your-local-environment) défini, ou un projet ouvert disposant de l'accès à GitLab Duo.

### Mode interactif {#interactive-mode}

Pour utiliser l'ILC GitLab Duo en mode interactif :

1. En fonction de votre configuration, saisissez la commande pour démarrer le mode interactif :

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. L'invite `>` s'affiche dans votre fenêtre de terminal. Après l'invite, saisissez votre question ou votre demande, puis appuyez sur <kbd>Entrée</kbd>.

   Par exemple :

   ```plaintext
   What is this repository about?

   Which issues need my attention?

   Help me implement issue 15.

   The pipelines in MR 23 are failing. Please help me fix them.
   ```

Pour annuler une réponse pendant que l'ILC GitLab Duo travaille, appuyez sur <kbd>Échap</kbd>. L'ILC GitLab Duo arrête l'opération en cours et revient à l'invite.

Utilisez la touche <kbd>↑</kbd> pour afficher l'historique de vos invites, ou <kbd>Ctrl</kbd>+<kbd>R</kbd> pour y effectuer une recherche.

#### Basculer entre les modes build et plan {#switch-between-build-and-plan-modes}

En mode interactif, vous pouvez basculer l'ILC GitLab Duo entre deux modes pendant votre travail :

| Mode                 | Autorisations | Fonctionnement                                                                  |
|----------------------|-------------|-------------------------------------------------------------------------------|
| Mode build (par défaut) | Lecture-écriture  | GitLab Duo peut exécuter des tâches et apporter des modifications à votre projet.               |
| Mode plan            | Lecture seule   | GitLab Duo peut analyser votre projet et créer des plans sans apporter de modifications. |

Par exemple, commencez par discuter d'un problème avec GitLab Duo en mode plan. Lorsque vous êtes prêt, passez en mode build et demandez à GitLab Duo d'implémenter le plan.

L'ILC GitLab Duo affiche le mode actuel sous l'invite `>`. Pour basculer entre les modes, appuyez sur <kbd>Tab</kbd>.

#### Commandes slash {#slash-commands}

En mode interactif, utilisez les commandes slash pour configurer l'ILC GitLab Duo et effectuer des actions. Saisissez une commande slash à l'invite et appuyez sur <kbd>Entrée</kbd>.

Les commandes slash suivantes sont disponibles :

| Commande     | Description                                          |
|-------------|------------------------------------------------------|
| `/copy`     | Copier la dernière réponse de GitLab Duo dans le presse-papiers.  |
| `/doctor`   | Afficher les diagnostics de l'environnement de l'ILC GitLab Duo. |
| `/exit`     | Quitter l'ILC GitLab Duo.                             |
| `/feedback` | Soumettre un rapport de bug ou une demande de fonctionnalité.              |
| `/help`     | Afficher la liste des commandes slash disponibles.          |
| `/mcp`      | Afficher les serveurs MCP configurés et leur statut.        |
| `/model`    | Changer le modèle d'IA pour la session en cours.         |
| `/new`      | Démarrer une nouvelle session de chat.                            |
| `/sessions` | Parcourir, rechercher et changer de session.                 |
| `/settings` | Ouvrir le panneau de paramètres.                             |
| `/skills`   | Lister les Agent Skills disponibles dans le projet actuel.  |

Vous pouvez également créer vos propres commandes slash. Pour plus d'informations, voir [commandes slash personnalisées](#custom-slash-commands).

#### Paramètres {#settings}

Pour modifier un paramètre :

1. En mode interactif, saisissez `/settings` et appuyez sur <kbd>Entrée</kbd>.
1. Utilisez les touches fléchées pour naviguer dans la liste des paramètres.
1. Pour modifier le paramètre sélectionné, appuyez sur <kbd>Entrée</kbd> ou <kbd>Espace</kbd>.
1. Pour fermer le panneau, appuyez sur <kbd>Échap</kbd>.

Les modifications persistent d'une session à l'autre.

Les paramètres suivants sont disponibles :

| Paramètre                  | Description                                                                                       |
|--------------------------|---------------------------------------------------------------------------------------------------|
| **Telemetry**            | Envoyer des données d'utilisation anonymes pour améliorer GitLab Duo.                                                  |
| **Enable global skills** | (Expérimental) Découvrir les [Agent Skills au niveau utilisateur](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills) depuis `~/.agents/skills/` et `~/.gitlab/duo/skills/`. Un redémarrage est requis pour que les modifications prennent effet. |
| **Notifications**        | Contrôler les [notifications système](#system-notifications) (`auto` ou `disabled`).                     |

#### Notifications système {#system-notifications}

L'ILC GitLab Duo peut envoyer une notification système lorsqu'une session nécessite votre attention (par exemple, lorsqu'elle termine une tâche ou nécessite l'approbation d'un outil) pendant que la fenêtre du terminal n'est pas au premier plan.

Les notifications sont contrôlées par le paramètre **Notifications** dans le [panneau de paramètres](#settings) :

- `auto` (par défaut) : envoyer une notification système lorsque le terminal n'est pas au premier plan.
- `disabled` : ne jamais envoyer de notifications système.

#### Approbations d'outils {#tool-approvals}

Lorsque GitLab Duo a besoin d'utiliser un outil, il vous invite à l'approuver avant de commencer. Par exemple, lorsqu'il a besoin de lire un fichier ou d'exécuter une commande.

Vos options sont :

- **Approuver** : GitLab Duo peut utiliser l'outil une seule fois.
- **Approuver pour la session** : GitLab Duo peut utiliser l'outil avec ces arguments pour le reste de la session. Des arguments différents nécessitent une approbation supplémentaire.
- **Refuser** : GitLab Duo ne peut pas utiliser l'outil.

> [!note]
> Pour utiliser l'option **Approuver pour la session**, votre administrateur doit l'activer pour votre groupe ou votre instance. Pour plus d'informations, voir les [approbations d'outils](../gitlab_duo_chat/agentic_chat.md#tool-approvals).

### Mode headless {#headless-mode}

> [!caution]
> Utilisez le mode headless avec prudence et dans un [environnement sandbox](../../editor_extensions/security_considerations.md#use-development-containers-for-isolation) contrôlé.

Pour exécuter un workflow en mode non interactif, utilisez la commande correspondant à votre configuration :

{{< tabs >}}

{{< tab title="glab" >}}

Utilisez `glab duo cli run` :

```shell
glab duo cli run --goal "Your goal or prompt here"
```

Par exemple, vous pouvez exécuter une commande ESLint et rediriger les erreurs vers l'ILC GitLab Duo pour les résoudre :

 ```shell
glab duo cli run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< tab title="duo" >}}

Utilisez `duo run` :

```shell
duo run --goal "Your goal or prompt here"
```

Par exemple, vous pouvez exécuter une commande ESLint et rediriger les erreurs vers l'ILC GitLab Duo pour les résoudre :

 ```shell
duo run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< /tabs >}}

Lorsque vous utilisez le mode headless, l'ILC GitLab Duo :

- Contourne les approbations manuelles des outils et approuve automatiquement tous les outils pour utilisation.
- Ne maintient pas le contexte des conversations précédentes. Un nouveau workflow démarre à chaque fois que vous exécutez la commande `run`.

## Sélectionner un modèle {#select-a-model}

Vous pouvez sélectionner un modèle pour le mode interactif ou le mode headless.

### Pour le mode interactif {#for-interactive-mode}

Le modèle que vous sélectionnez persiste d'une session à l'autre, et vous pouvez changer de modèle en cours de conversation sans perdre le contexte.

Prérequis :

- ILC GitLab Duo 8.76.0 ou version ultérieure.

Pour sélectionner un modèle en mode interactif :

1. En mode interactif, saisissez `/model` et appuyez sur <kbd>Entrée</kbd>.
1. Utilisez les touches fléchées pour faire défiler la liste des modèles disponibles, ou saisissez un nom de modèle pour filtrer la liste.
1. Sélectionnez un modèle et appuyez sur <kbd>Entrée</kbd> pour y basculer.

### Pour le mode headless {#for-headless-mode}

Le modèle que vous sélectionnez ne persiste pas d'une session à l'autre.

Prérequis :

- ILC GitLab Duo 8.68.0 ou version ultérieure.

Pour sélectionner un modèle en mode headless :

1. Trouvez le [`gitlab_identifier` pour le modèle](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml).
1. Lorsque vous exécutez l'ILC GitLab Duo, définissez l'option `--model` ou la variable d'environnement `GITLAB_DUO_MODEL` sur la valeur `gitlab_identifier`.

   {{< tabs >}}

   {{< tab title="glab" >}}

   Utilisez l'option `--model` :

   ```shell
   glab duo cli --model <gitlab_identifier_for_the_model>
   ```

   Utilisez la variable d'environnement `GITLAB_DUO_MODEL` :

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> glab duo cli
   ```

   Par exemple, pour utiliser [`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448) :

   ```shell
   glab duo cli --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex glab duo cli
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   Utilisez l'option `--model` :

   ```shell
   duo --model <gitlab_identifier_for_the_model>
   ```

   Utilisez la variable d'environnement `GITLAB_DUO_MODEL` :

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> duo
   ```

   Par exemple, pour utiliser [`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448) :

   ```shell
   duo --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

## Changer de session {#switch-sessions}

Les sessions GitLab Duo Chat stockent l'historique de vos conversations et les données de workflow, et sont partagées entre l'ILC GitLab Duo, l'interface GitLab et les extensions d'éditeur.

Par exemple, vous pouvez démarrer une conversation dans votre navigateur et la poursuivre dans votre terminal.

Pour parcourir et passer à une session :

1. En mode interactif, saisissez `/sessions` et appuyez sur <kbd>Entrée</kbd>.
1. Utilisez les touches fléchées pour faire défiler la liste des sessions disponibles, ou saisissez du texte pour filtrer la liste.
1. Sélectionnez une session et appuyez sur <kbd>Entrée</kbd>.

Pour passer à une session en mode headless, utilisez l'option `--existing-session-id`.

## Connexions Model Context Protocol (MCP) {#model-context-protocol-mcp-connections}

Pour connecter l'ILC GitLab Duo à des serveurs MCP locaux ou distants, utilisez la même configuration MCP que les extensions GitLab IDE. Pour obtenir des instructions, voir [configurer les serveurs MCP](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-mcp-servers).

## Hooks {#hooks}

{{< details >}}

- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2209) en tant que [version expérimentale](../../policy/development_stages_support.md#experiment) dans GitLab Duo CLI 8.95.0, lors de la release GitLab 19.1.

{{< /history >}}

Utilisez des hooks pour exécuter des commandes personnalisées à des points spécifiques du cycle de vie de l'ILC GitLab Duo.

Par exemple, vous pouvez injecter du contexte supplémentaire dans chaque nouvelle session de chat en exécutant un script qui collecte des informations sur votre environnement.

L'ILC GitLab Duo prend en charge les hooks à deux niveaux :

- Niveau utilisateur (global) : s'applique à tous vos projets.
- Niveau projet : s'applique uniquement à un projet spécifique. Les hooks au niveau projet sont désactivés par défaut pour empêcher l'exécution de code arbitraire provenant de dépôts extraits.

Lorsque des fichiers `hooks.json` existent à la fois au niveau utilisateur et au niveau projet, l'ILC fusionne les hooks et exécute en premier ceux du niveau utilisateur.

> [!note]
> Pour des raisons de sécurité, les variables d'environnement sensibles (`GITLAB_TOKEN`, `GITLAB_OAUTH_TOKEN`, `CI_JOB_TOKEN`) sont exclues des processus de hook.

### Exécution des hooks {#hook-execution}

Lorsqu'un hook s'exécute, l'ILC GitLab Duo :

1. Envoie un objet JSON à l'entrée standard de la commande avec les métadonnées de session :

   ```json
   {
     "session_id": "abc-123",
     "cwd": "/path/to/project",
     "transcript_path": "",
     "hook_event_name": "SessionStart",
     "source": "startup"
   }
   ```

1. Définit les variables d'environnement `DUO_SESSION_ID` et `DUO_PROJECT_DIR` pour le processus de hook.
1. Collecte la sortie standard de la commande comme contexte supplémentaire pour la session.

Le hook peut renvoyer du texte brut sur la sortie standard, ou un objet JSON :

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Your context string here"
  }
}
```

Si le hook se termine avec un statut non nul ou expire, il est enregistré comme avertissement mais ne bloque pas le démarrage de la session.

### Créer des hooks {#create-hooks}

L'ILC GitLab Duo prend en charge l'événement `SessionStart`, qui s'exécute lorsqu'une nouvelle session démarre ou qu'une session existante reprend.

Pour créer un hook :

1. Créez un fichier `hooks.json` :
   - Pour un hook au niveau utilisateur :
     - Sur Linux ou macOS, créez le fichier à `~/.gitlab/duo/hooks.json`.
     - Sur Windows, créez le fichier à `%APPDATA%\GitLab\duo\hooks.json`.
   - Pour un hook au niveau projet, créez le fichier à la racine de votre projet : `<project>/.gitlab/duo/hooks.json`.
1. Définissez vos hooks dans le fichier.
   - Créez un groupe de correspondance pour chaque source d'événement `SessionStart` devant déclencher le hook (`startup` ou `resume`).
   - Chaque groupe de correspondance a une valeur regex `matcher` facultative et un tableau de hooks de commande :

     | Champ | Description |
     |-------|-------------|
     | `matcher` | Facultatif. Regex testée par rapport à la source d'événement (`startup` ou `resume` pour `SessionStart`). Omettez pour correspondre à tous. |
     | `hooks[].type` | Doit être `"command"`. |
     | `hooks[].command` | Une commande shell à exécuter. |
     | `hooks[].timeout` | Facultatif. Délai d'expiration en secondes. Par défaut : 30\. |

   - Par exemple :

     ```json
     {
       "hooks": {
         "SessionStart": [
           {
             "matcher": "startup",
             "hooks": [
               {
                 "type": "command",
                 "command": "cat ~/.my-coding-preferences.md",
                 "timeout": 10
               }
             ]
          }
         ]
       }
     }
     ```

1. Si vous avez des hooks au niveau projet, activez-les lorsque vous démarrez l'ILC GitLab Duo :

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli --enable-project-hooks
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo --enable-project-hooks
   ```

   {{< /tab >}}

   {{< /tabs >}}

   Vous pouvez également définir la variable d'environnement :

   ```shell
   export GITLAB_ENABLE_PROJECT_HOOKS=true
   ```

## Commandes slash personnalisées {#custom-slash-commands}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3617) dans GitLab Duo CLI 9.2.0, lors de la release GitLab 19.2.

{{< /history >}}

Créez des commandes slash personnalisées pour les invites que vous utilisez fréquemment.

L'ILC GitLab Duo prend en charge les commandes slash personnalisées à deux niveaux :

- Niveau utilisateur : s'applique à tous vos projets.
- Niveau projet : s'applique uniquement à un projet spécifique.

Si une commande au niveau utilisateur et une commande au niveau projet partagent le même nom, la commande au niveau projet est prioritaire. Les commandes slash personnalisées ne peuvent pas remplacer les commandes slash intégrées ni les [commandes slash d'Agent Skills](../duo_agent_platform/customize/agent_skills.md#expose-skills-as-slash-commands).

### Créer une commande slash personnalisée {#create-a-custom-slash-command}

Pour créer une commande slash personnalisée, vous créez un fichier Markdown.

Le nom du fichier est le nom de la commande, et le contenu du fichier est l'invite.

Par exemple, un fichier nommé `daily.md` crée la commande `/daily` :

1. Créez un répertoire `commands` :
   - Pour une commande au niveau projet, créez le répertoire à la racine de votre projet : `<project>/.agents/commands/`.
   - Pour une commande au niveau utilisateur, utilisez l'un des emplacements suivants :
     - Pour conserver vos commandes avec vos autres fichiers de personnalisation GitLab Duo :
       - Sur Linux ou macOS, créez le répertoire à `~/.gitlab/duo/commands/`.
       - Sur Windows, créez le répertoire à `%APPDATA%\GitLab\duo\commands\`.
       - Si vous avez défini `GLAB_CONFIG_DIR` ou `XDG_CONFIG_HOME`, utilisez `$GLAB_CONFIG_DIR/commands/` ou `$XDG_CONFIG_HOME/gitlab/duo/commands/`. Si les deux sont définis, `GLAB_CONFIG_DIR` est prioritaire.
     - Pour partager des commandes avec d'autres outils d'IA :
       - Sur Linux ou macOS, créez le répertoire à `~/.agents/commands/`.
       - Sur Windows, créez le répertoire à `%USERPROFILE%\.agents\commands\`.
1. Dans le répertoire, créez un fichier Markdown. Utilisez le nom de la commande comme nom de fichier. Les noms de commande doivent commencer par une lettre ou un chiffre, et ne peuvent contenir que des lettres, des chiffres, des tirets et des underscores.
1. Ajoutez l'invite dans le fichier.
1. Facultatif. Ajoutez un champ `description` dans le front matter YAML en haut du fichier. La description s'affiche à côté de la commande dans le menu des commandes slash.

   Par exemple, une commande `/daily` définie dans `daily.md` :

   ```markdown
   ---
   description: Prepare a daily report
   ---

   Use `glab todo list` to fetch my open TODO items. Give me a concise morning report ranked by priority.
   ```

1. Redémarrez l'ILC GitLab Duo. L'ILC détecte les commandes slash personnalisées au démarrage.

### Utiliser une commande slash personnalisée {#use-a-custom-slash-command}

En mode interactif, saisissez la commande slash à l'invite et appuyez sur <kbd>Entrée</kbd>. L'ILC GitLab Duo envoie le contenu du fichier comme invite.

Tout texte que vous saisissez après le nom de la commande est ajouté à la fin de l'invite.

Utilisez ceci pour personnaliser ce que fait la commande slash personnalisée.

Par exemple, `/daily prioritize my milestone deliverables`.

## Référence {#reference}

Utilisez ces options, commandes et variables d'environnement lorsque vous démarrez ou exécutez l'ILC GitLab Duo.

Pour plus de détails et la liste la plus à jour, consultez la [référence de l'ILC GitLab Duo](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md).

### Options {#options}

L'ILC GitLab Duo prend en charge les options suivantes :

- `-C, --cwd <path>` : modifier le répertoire de travail.
- `-h, --help` : afficher l'aide pour l'ILC GitLab Duo ou une commande spécifique. Par exemple, `duo --help` ou `duo run --help`.
- `--log-level <level>` : définir le niveau de journalisation (`debug`, `info`, `warn`, `error`).
- `-v`, `--version` : afficher les informations de version.
- `--enable-global-skills` : (Expérimental) Activer les [Agent Skills au niveau utilisateur](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills).
- `--enable-project-hooks` : (Expérimental) Activer le chargement des [hooks](#hooks) au niveau projet.
- `--model <model>` : sélectionner le modèle d'IA à utiliser pour la session.

Options supplémentaires pour le mode headless :

- `--ai-context-items <contextItems>` : tableau JSON encodé d'éléments de contexte supplémentaires pour référence.
- `--existing-session-id <sessionId>` : identifiant d'une session existante à reprendre.
- `--gitlab-auth-token <token>` : jeton d'authentification pour une instance GitLab.
- `--gitlab-base-url <url>` : URL de base d'une instance GitLab (par défaut : `https://gitlab.com`).

### Commandes {#commands}

Les commandes suivantes sont disponibles pour chaque configuration :

{{< tabs >}}

{{< tab title="glab" >}}

- `glab duo cli` : démarrer le mode interactif.
- `glab duo cli log` : afficher et gérer les journaux.
  - `glab duo cli log last` : ouvrir le dernier fichier journal.
  - `glab duo cli log list` : lister tous les fichiers journaux.
  - `glab duo cli log tail <args...>` : afficher la fin du dernier fichier journal. Prend en charge les arguments tail standard.
  - `glab duo cli log clear` : supprimer tous les fichiers journaux existants.
- `glab duo cli run` : démarrer le mode headless.

{{< /tab >}}

{{< tab title="duo" >}}

- `duo` : démarrer le mode interactif.
- `duo config` : gérer la configuration et les paramètres d'authentification.
- `duo log` : afficher et gérer les journaux.
  - `duo log last` : ouvrir le dernier fichier journal.
  - `duo log list` : lister tous les fichiers journaux.
  - `duo log tail <args...>` : afficher la fin du dernier fichier journal. Prend en charge les arguments tail standard.
  - `duo log clear` : supprimer tous les fichiers journaux existants.
- `duo run` : démarrer le mode headless.

{{< /tab >}}

{{< /tabs >}}

### Variables d'environnement {#environment-variables}

Vous pouvez configurer l'ILC GitLab Duo à l'aide de variables d'environnement :

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD` : mot de passe d'authentification HTTP Git.
- `DUO_WORKFLOW_GIT_HTTP_USER` : nom d'utilisateur d'authentification HTTP Git.
- `GITLAB_BASE_URL` ou `GITLAB_URL` : URL de l'instance GitLab.
- `GITLAB_DUO_MODEL` : modèle d'IA à utiliser pour la session.
- `GITLAB_ENABLE_GLOBAL_SKILLS` : (Expérimental) Activer les [Agent Skills au niveau utilisateur](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills).
- `GITLAB_ENABLE_PROJECT_HOOKS` : (Expérimental) Activer le chargement des [hooks](#hooks) au niveau projet.
- `GITLAB_OAUTH_TOKEN` ou `GITLAB_TOKEN` : jeton d'authentification.
- `LOG_LEVEL` : niveau de journalisation.

Lorsque l'ILC GitLab Duo exécute une commande en votre nom, il définit la variable d'environnement `AI_AGENT` dans ce processus. Les scripts et outils peuvent lire `AI_AGENT` pour détecter qu'ils s'exécutent dans un contexte d'exécution piloté par l'IA.

## Configuration du proxy et des certificats personnalisés {#proxy-and-custom-certificate-configuration}

Si votre réseau utilise un proxy interceptant HTTPS ou nécessite des certificats SSL personnalisés, vous pourriez avoir besoin d'une configuration supplémentaire.

### Configuration du proxy {#proxy-configuration}

L'ILC GitLab Duo respecte les variables d'environnement proxy standard :

- `HTTP_PROXY` ou `http_proxy` : URL du proxy pour les requêtes HTTP.
- `HTTPS_PROXY` ou `https_proxy` : URL du proxy pour les requêtes HTTPS.
- `NO_PROXY` ou `no_proxy` : liste d'hôtes séparés par des virgules à exclure du proxying.

### Certificats SSL personnalisés {#custom-ssl-certificates}

Si votre organisation utilise une autorité de certification (CA) personnalisée, pour un proxy interceptant HTTPS ou similaire, vous pourriez rencontrer des erreurs de certificat.

```plaintext
Error: unable to verify the first certificate
Error: self-signed certificate in certificate chain
```

Pour résoudre les erreurs de certificat, utilisez l'une des méthodes suivantes :

- Utiliser le magasin de certificats système (recommandé) :
  - Si votre certificat CA est installé dans le magasin de certificats de votre système d'exploitation, configurez Node.js pour l'utiliser. Nécessite Node.js 22.15.0, 23.9.0 ou 24.0.0 et versions ultérieures.
  - Si vous exécutez l'ILC GitLab Duo dans un conteneur, installez le certificat CA dans le magasin système du conteneur, et non dans le magasin système hôte.

  ```shell
  export NODE_OPTIONS="--use-system-ca"
  ```

- Spécifier un fichier de certificat CA :
  - Pour les versions plus anciennes de Node.js, ou lorsque le certificat CA n'est pas dans le magasin système, indiquez directement à Node.js le chemin du fichier de certificat. Le fichier doit être au format PEM.
  - Si vous exécutez l'ILC GitLab Duo dans un conteneur, définissez le chemin vers un emplacement dans le conteneur. Utilisez un montage de volume pour fournir le fichier de certificat.

  ```shell
  export NODE_EXTRA_CA_CERTS=/path/to/custom-ca.pem
  ```

### Ignorer les erreurs de certificat {#ignore-certificate-errors}

Si vous rencontrez encore des erreurs de certificat, vous pouvez désactiver la vérification des certificats.

> [!warning]
> La désactivation de la vérification des certificats est un risque de sécurité. Vous ne devez pas désactiver la vérification dans les environnements de production.

Les erreurs de certificat vous alertent sur des failles de sécurité potentielles ; vous ne devez donc désactiver la vérification des certificats que lorsque vous êtes certain que cela est sécurisé.

Prérequis :

- Vous avez vérifié la chaîne de certificats dans votre navigateur, ou votre administrateur a confirmé que cette erreur peut être ignorée sans risque.

Pour désactiver la vérification des certificats :

```shell
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

## Mettre à jour l'ILC GitLab Duo {#update-the-gitlab-duo-cli}

Pour mettre à jour manuellement l'ILC GitLab Duo vers la dernière version, exécutez la commande correspondant à votre configuration :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo cli --update
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
npm install --global @gitlab/duo-cli@latest
```

{{< /tab >}}

{{< /tabs >}}

## Contribuer à l'ILC GitLab Duo {#contribute-to-the-gitlab-duo-cli}

Pour obtenir des informations sur la contribution à l'ILC GitLab Duo, consultez le [guide de développement](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/development.md).

## Sujets connexes {#related-topics}

- [Considérations de sécurité pour les extensions d'éditeur](../../editor_extensions/security_considerations.md)
- [Référence de l'ILC GitLab Duo](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [ILC GitLab](https://docs.gitlab.com/cli/)
- [Personnaliser la plateforme GitLab Duo Agent](../duo_agent_platform/customize/_index.md)
- [Sessions de la plateforme GitLab Duo Agent](../duo_agent_platform/sessions/_index.md)
