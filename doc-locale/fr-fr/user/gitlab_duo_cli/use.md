---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utiliser le CLI GitLab Duo en modes interactif et headless.
title: Utiliser le CLI GitLab Duo
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Un [espace de nommage GitLab Duo par défaut](../profile/preferences.md#namespace-resolution-in-your-local-environment) défini, ou un projet ouvert disposant de l'accès à GitLab Duo

Vous pouvez utiliser le CLI GitLab Duo dans deux modes :

- Mode interactif : offre une expérience de chat similaire à GitLab Duo Chat dans l'interface GitLab ou dans les extensions d'éditeur. Prend en charge les modes build et plan.
- Mode sans interface : permet une utilisation non interactive dans les runners, les scripts et autres workflows automatisés.

## Mode interactif {#interactive-mode}

Pour utiliser GitLab Duo CLI en mode interactif :

1. En fonction de votre configuration, saisissez la commande pour démarrer le mode interactif :

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

Pour annuler une réponse pendant que GitLab Duo CLI travaille, appuyez sur <kbd>Échap</kbd>. GitLab Duo CLI arrête l'opération en cours et revient à l'invite.

Utilisez la touche <kbd>↑</kbd> pour afficher l'historique de vos invites, ou <kbd>Ctrl</kbd>+<kbd>R</kbd> pour y effectuer une recherche.

### Basculer entre les modes build et plan {#switch-between-build-and-plan-modes}

En mode interactif, vous pouvez basculer GitLab Duo CLI entre deux modes pendant votre travail :

| Mode                 | Autorisations | Fonctionnement                                                                  |
|----------------------|-------------|-------------------------------------------------------------------------------|
| Mode build (par défaut) | Lecture-écriture  | GitLab Duo peut exécuter des tâches et apporter des modifications à votre projet.               |
| Mode plan            | Lecture seule   | GitLab Duo peut analyser votre projet et créer des plans sans apporter de modifications. |

Par exemple, commencez par discuter d'un problème avec GitLab Duo en mode plan. Lorsque vous êtes prêt, passez en mode build et demandez à GitLab Duo d'implémenter le plan.

GitLab Duo CLI affiche le mode actuel sous l'invite `>`. Pour basculer entre les modes, appuyez sur <kbd>Tab</kbd>.

### Commandes slash {#slash-commands}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.88.0) de la commande slash `/exit` dans GitLab Duo CLI 8.88.0, lors de la release GitLab 19.0
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.94.0) de la commande slash `/doctor` dans GitLab Duo CLI 8.94.0, lors de la release GitLab 19.0
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.81.0) de la commande slash `/skills` dans GitLab Duo CLI 8.81.0, lors de la release GitLab 19.0
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) de la commande slash `/mcp` dans GitLab Duo CLI 8.95.0, lors de la release GitLab 19.0

{{< /history >}}

En mode interactif, utilisez les commandes slash pour configurer GitLab Duo CLI et effectuer des actions. Saisissez une commande slash à l'invite et appuyez sur <kbd>Entrée</kbd>.

Les commandes slash suivantes sont disponibles :

| Commande     | Description                                          |
|-------------|------------------------------------------------------|
| `/copy`     | Copier la dernière réponse de GitLab Duo dans le presse-papiers.  |
| `/doctor`   | Afficher les diagnostics de l'environnement de GitLab Duo CLI. |
| `/exit`     | Quitter GitLab Duo CLI.                             |
| `/feedback` | Soumettre un rapport de bug ou une demande de fonctionnalité.              |
| `/help`     | Afficher la liste des commandes slash disponibles.          |
| `/mcp`      | Afficher les serveurs MCP configurés et leur statut.        |
| `/model`    | Changer le modèle d'IA pour la session en cours.         |
| `/new`      | Démarrer une nouvelle session de chat.                            |
| `/sessions` | Parcourir, rechercher et changer de session.                 |
| `/settings` | Ouvrir le panneau de paramètres.                             |
| `/skills`   | Lister les Agent Skills disponibles dans le projet actuel.  |

Vous pouvez également créer vos propres commandes slash. Pour plus d'informations, voir [commandes slash personnalisées](customize.md#custom-slash-commands).

### Paramètres {#settings}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.90.0) du panneau de paramètres dans GitLab Duo CLI 8.90.0, lors de la release GitLab 19.0

{{< /history >}}

Pour modifier un paramètre :

1. En mode interactif, saisissez `/settings` et appuyez sur <kbd>Entrée</kbd>.
1. Utilisez les touches fléchées pour naviguer dans la liste des paramètres.
1. Pour modifier le paramètre sélectionné, appuyez sur <kbd>Entrée</kbd> ou <kbd>Espace</kbd>.
1. Pour fermer le panneau, appuyez sur <kbd>Échap</kbd>.

Les modifications persistent d'une session à l'autre.

Les paramètres suivants sont disponibles :

| Paramètre                  | Description                                                                                       |
|--------------------------|---------------------------------------------------------------------------------------------------|
| **Télémétrie**            | Envoyer des données d'utilisation anonymes pour améliorer GitLab Duo.                                                  |
| **Activer les skills globaux** | (Expérimental) Découvrir les [Agent Skills au niveau utilisateur](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills) depuis `~/.agents/skills/` et `~/.gitlab/duo/skills/`. Un redémarrage est requis pour que les modifications prennent effet. |
| **Notifications**        | Contrôler les [notifications système](#system-notifications) (`auto` ou `disabled`).                     |

### Notifications système {#system-notifications}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.105.0) des notifications système dans GitLab Duo CLI 8.105.0, lors de la release GitLab 19.1

{{< /history >}}

GitLab Duo CLI peut envoyer une notification système lorsqu'une session nécessite votre attention (par exemple, lorsqu'elle termine une tâche ou nécessite l'approbation d'un outil) pendant que la fenêtre du terminal n'est pas au premier plan.

Les notifications sont contrôlées par le paramètre **Notifications** dans le [panneau de paramètres](#settings) :

- `auto` (par défaut) : envoyer une notification système lorsque le terminal n'est pas au premier plan.
- `disabled` : ne jamais envoyer de notifications système.

### Approbations d'outils {#tool-approvals}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2129) de l'option Approuver des outils pour une session dans GitLab 19.0
  - Introduction dans [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0
- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/21850) de l'approbation d'outil basée sur des modèles dans GitLab 19.1
  - Introduction dans [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.101.0) 8.101.0
- [Suppression](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3699) de l'approbation d'outil basée sur des modèles le 10 juillet 2026
  - Suppression dans [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.3.0) 9.3.0

{{< /history >}}

Lorsque GitLab Duo a besoin d'utiliser un outil, il vous invite à l'approuver avant de commencer. Par exemple, lorsqu'il a besoin de lire un fichier ou d'exécuter une commande.

Vos options sont :

- **Approuver** : GitLab Duo peut utiliser l'outil une seule fois.
- **Approuver pour la session** : GitLab Duo peut utiliser l'outil avec ces arguments pour le reste de la session. Des arguments différents nécessitent une approbation supplémentaire.
- **Refuser** : GitLab Duo ne peut pas utiliser l'outil.

> [!note]
> Pour utiliser l'option **Approuver pour la session**, votre administrateur doit l'activer pour votre groupe ou votre instance. Pour plus d'informations, voir les [approbations d'outils](../gitlab_duo_chat/agentic_chat.md#tool-approvals).

## Mode sans interface {#headless-mode}

> [!caution]
> Utilisez le mode sans interface avec prudence et dans un [environnement sandbox](../../editor_extensions/security_considerations.md#use-development-containers-for-isolation) contrôlé.

Pour exécuter un workflow en mode non interactif, utilisez la commande correspondant à votre configuration :

{{< tabs >}}

{{< tab title="glab" >}}

Utilisez `glab duo cli run` :

```shell
glab duo cli run --goal "Your goal or prompt here"
```

Par exemple, vous pouvez exécuter une commande ESLint et rediriger les erreurs vers GitLab Duo CLI pour les résoudre :

```shell
glab duo cli run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< tab title="duo" >}}

Utilisez `duo run` :

```shell
duo run --goal "Your goal or prompt here"
```

Par exemple, vous pouvez exécuter une commande ESLint et rediriger les erreurs vers GitLab Duo CLI pour les résoudre :

```shell
duo run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< /tabs >}}

Lorsque vous utilisez le mode sans interface, GitLab Duo CLI :

- Contourne les approbations manuelles des outils et approuve automatiquement tous les outils pour utilisation.
- Ne maintient pas le contexte des conversations précédentes. Un nouveau workflow démarre à chaque fois que vous exécutez la commande `run`.

## Sélectionner un modèle {#select-a-model}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.68.0) de l'option de sélection de modèle et de la variable d'environnement dans GitLab Duo CLI 8.68.0, lors de la release GitLab 18.10
- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.76.0) de la commande slash de sélection de modèle dans GitLab Duo CLI 8.76.0, lors de la release GitLab 18.10

{{< /history >}}

Vous pouvez sélectionner un modèle pour le mode interactif ou le mode sans interface.

### Pour le mode interactif {#for-interactive-mode}

Le modèle que vous sélectionnez persiste d'une session à l'autre, et vous pouvez changer de modèle en cours de conversation sans perdre le contexte.

Prérequis :

- GitLab Duo CLI 8.76.0 ou version ultérieure

Pour sélectionner un modèle en mode interactif :

1. En mode interactif, saisissez `/model` et appuyez sur <kbd>Entrée</kbd>.
1. Utilisez les touches fléchées pour faire défiler la liste des modèles disponibles, ou saisissez un nom de modèle pour filtrer la liste.
1. Sélectionnez un modèle et appuyez sur <kbd>Entrée</kbd> pour y basculer.

### Pour le mode sans interface {#for-headless-mode}

Le modèle que vous sélectionnez ne persiste pas d'une session à l'autre.

Prérequis :

- GitLab Duo CLI 8.68.0 ou version ultérieure

Pour sélectionner un modèle en mode sans interface :

1. Trouvez le [`gitlab_identifier` pour le modèle](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml).
1. Lorsque vous exécutez GitLab Duo CLI, définissez l'option `--model` ou la variable d'environnement `GITLAB_DUO_MODEL` sur la valeur `gitlab_identifier`.

   {{< tabs >}}

   {{< tab title="glab" >}}

   Utilisez l'option `--model` :

   ```shell
   glab duo cli --model <gitlab_identifier_for_the_model>
   ```

   Utilisez la variable d'environnement `GITLAB_DUO_MODEL` :

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> glab duo cli
   ```

   Par exemple, pour utiliser [`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448) :

   ```shell
   glab duo cli --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex glab duo cli
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   Utilisez l'option `--model` :

   ```shell
   duo --model <gitlab_identifier_for_the_model>
   ```

   Utilisez la variable d'environnement `GITLAB_DUO_MODEL` :

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> duo
   ```

   Par exemple, pour utiliser [`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448) :

   ```shell
   duo --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

## Changer de session {#switch-sessions}

Les sessions GitLab Duo Chat stockent l'historique de vos conversations et les données de workflow, et sont partagées entre GitLab Duo CLI, l'interface GitLab et les extensions d'éditeur.

Par exemple, vous pouvez démarrer une conversation dans votre navigateur et la poursuivre dans votre terminal.

Pour parcourir et passer à une session :

1. En mode interactif, saisissez `/sessions` et appuyez sur <kbd>Entrée</kbd>.
1. Utilisez les touches fléchées pour faire défiler la liste des sessions disponibles, ou saisissez du texte pour filtrer la liste.
1. Sélectionnez une session et appuyez sur <kbd>Entrée</kbd>.

Pour passer à une session en mode sans interface, utilisez l'option `--existing-session-id`.

## Connexions Model Context Protocol (MCP) {#model-context-protocol-mcp-connections}

Pour connecter GitLab Duo CLI à des serveurs MCP locaux ou distants, utilisez la même configuration MCP que les extensions GitLab IDE. Pour obtenir des instructions, voir [configurer les serveurs MCP](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-mcp-servers).

## Sujets connexes {#related-topics}

- [Référence complète du CLI GitLab Duo](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [Considérations de sécurité pour les extensions d'éditeur](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
- [Personnaliser GitLab Duo Agent Platform](../duo_agent_platform/customize/_index.md)
- [Sessions de GitLab Duo Agent Platform](../duo_agent_platform/sessions/_index.md)

## Dépannage {#troubleshooting}

Lorsque vous utilisez le CLI GitLab Duo, vous pouvez rencontrer les problèmes suivants.

### Erreurs de certificat {#certificate-errors}

Vous pouvez rencontrer des erreurs de certificat :

```plaintext
Error: unable to verify the first certificate
Error: self-signed certificate in certificate chain
```

Ces erreurs se produisent si votre organisation utilise une autorité de certification (CA) personnalisée pour un proxy d'interception HTTPS ou similaire.

Pour résoudre les erreurs de certificat, utilisez l'une des méthodes suivantes :

- Utiliser le magasin de certificats système (recommandé) :
  1. Si votre certificat CA est installé dans le magasin de certificats de votre système d'exploitation, configurez Node.js pour l'utiliser. Nécessite Node.js 22.15.0, 23.9.0 ou 24.0.0 et versions ultérieures.
  1. Si vous exécutez GitLab Duo CLI dans un conteneur, installez le certificat CA dans le magasin système du conteneur, et non dans le magasin système hôte.

     ```shell
     export NODE_OPTIONS="--use-system-ca"
     ```

- Spécifier un fichier de certificat CA :
  1. Pour les versions plus anciennes de Node.js, ou lorsque le certificat CA n'est pas dans le magasin système, indiquez directement à Node.js le chemin du fichier de certificat. Le fichier doit être au format PEM.
  1. Si vous exécutez GitLab Duo CLI dans un conteneur, définissez le chemin vers un emplacement dans le conteneur. Utilisez un montage de volume pour fournir le fichier de certificat.

     ```shell
     export NODE_EXTRA_CA_CERTS=/path/to/custom-ca.pem
     ```

### Ignorer les erreurs de certificat {#ignore-certificate-errors}

Si vous rencontrez encore des erreurs de certificat, vous pouvez désactiver la vérification des certificats.

> [!warning]
> La désactivation de la vérification des certificats est un risque de sécurité. Vous ne devez pas désactiver la vérification dans les environnements de production.

Les erreurs de certificat vous alertent sur des failles de sécurité potentielles. Vous ne devez donc désactiver la vérification des certificats que lorsque vous êtes certain que cette désactivation est sans risque.

Prérequis :

- Vous avez vérifié la chaîne de certificats dans votre navigateur, ou votre administrateur a confirmé que cette erreur peut être ignorée sans risque.

Pour désactiver la vérification des certificats :

```shell
export NODE_TLS_REJECT_UNAUTHORIZED=0
```
