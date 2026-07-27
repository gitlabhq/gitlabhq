---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Hooks serveur Git
description: Configurer les hooks serveur Git.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/issues/372991) de hooks serveur en hooks serveur Git dans GitLab 15.6.

{{< /history >}}

Les hooks serveur Git exécutent une logique personnalisée sur le serveur GitLab. Vous pouvez les utiliser pour exécuter des tâches liées à Git, telles que :

- L'application de politiques de commit spécifiques.
- L'exécution de tâches en fonction de l'état du dépôt.

Les hooks serveur Git utilisent les hooks côté serveur Git `pre-receive`, `post-receive` et `update`.

Les administrateurs GitLab configurent les hooks serveur à l'aide de la commande `gitaly`, qui permet également de :

- Lancer un serveur Gitaly.
- Fournir plusieurs sous-commandes.
- Se connecter à l'API gRPC de Gitaly.

Si vous n'avez pas accès à la commande `gitaly`, les alternatives aux hooks serveur incluent :

- [Les webhooks](../user/project/integrations/webhooks.md).
- [GitLab CI/CD](../ci/_index.md).
- [Les règles push](../user/project/repository/push_rules.md), pour une interface de hook Git configurable par l'utilisateur.

Pour les instances GitLab Helm chart, consultez les informations sur les [hooks serveur globaux dans le chart Gitaly](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#global-server-hooks).

> [!note]
> [Geo](geo/_index.md) ne réplique pas les hooks serveur sur les nœuds secondaires.

## Prérequis {#prerequisites}

- Le [nom du stockage](gitaly/configure_gitaly.md#gitlab-requires-a-default-repository-storage), le chemin vers le fichier de configuration Gitaly (par défaut `/var/opt/gitlab/gitaly/config.toml` sur les instances du package Linux), et le [chemin relatif du dépôt](repository_storage_paths.md#from-project-name-to-hashed-path) pour le dépôt.
- Tous les environnements d'exécution de langage et les utilitaires requis par les hooks doivent être installés sur chacun des serveurs exécutant Gitaly.

## Définir les hooks serveur pour un dépôt {#set-server-hooks-for-a-repository}

Pour définir des hooks serveur pour un dépôt :

1. Créer une archive tar contenant les hooks personnalisés :
   1. Écrivez le code pour que le hook serveur fonctionne comme prévu. Les hooks serveur Git peuvent être dans n'importe quel langage de programmation. Assurez-vous que le shebang en haut reflète le type de langage. Par exemple, si le script est en Ruby, le shebang est probablement `#!/usr/bin/env ruby`.

      - Pour créer un seul hook serveur, créez un fichier dont le nom correspond au type de hook. Par exemple, pour un hook serveur `pre-receive`, le nom de fichier doit être `pre-receive` sans extension.
      - Pour créer plusieurs hooks serveur, créez un répertoire pour les hooks correspondant au type de hook. Par exemple, pour un hook serveur `pre-receive`, le nom du répertoire doit être `pre-receive.d`. Placez les fichiers du hook dans ce répertoire.

   1. Assurez-vous que les fichiers de hook serveur sont exécutables et ne correspondent pas au modèle de fichier de sauvegarde (`*~`). Les hooks serveur doivent se trouver dans un répertoire `custom_hooks` à la racine de l'archive tar.
   1. Créez l'archive des hooks personnalisés avec la commande tar. Par exemple, `tar -cf custom_hooks.tar custom_hooks`.
1. Exécutez la sous-commande `hooks set` avec les options requises pour définir les hooks Git pour le dépôt. Par exemple :

   ```shell
   cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
   ```

   - Un chemin vers une configuration Gitaly valide pour le nœud est requis pour se connecter au nœud et fourni à l'option `--config`.
   - L'archive tar des hooks personnalisés doit être transmise via `stdin`. Par exemple :

     ```shell
     cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
     ```

1. Si vous utilisez Gitaly Cluster (Praefect), vous devez exécuter la sous-commande `hooks set` sur tous les nœuds Gitaly.

Si vous avez implémenté le code du hook serveur correctement, il doit s'exécuter lors du prochain déclenchement du hook Git.

### Hooks serveur sur un cluster Gitaly (Praefect) {#server-hooks-on-a-gitaly-cluster-praefect}

Si vous utilisez Gitaly Cluster (Praefect), un dépôt individuel peut être répliqué vers plusieurs stockages Gitaly dans Praefect. Par conséquent, les scripts de hook doivent être copiés sur chaque nœud Gitaly qui possède une réplique du dépôt. Pour ce faire, suivez les mêmes étapes de configuration des hooks de dépôt personnalisés pour la version applicable et répétez l'opération pour chaque stockage.

L'emplacement où copier les scripts dépend de l'endroit où les dépôts sont stockés. Les nouveaux dépôts sont créés en utilisant des chemins de réplica générés par Praefect qui ne sont pas le chemin de stockage haché. Pour identifier le chemin de réplica, [interrogez les métadonnées du dépôt Praefect](gitaly/praefect/troubleshooting.md#view-repository-metadata) en utilisant l'option `-relative-path` pour spécifier le chemin de stockage haché GitLab attendu.

## Créer des hooks serveur globaux pour tous les dépôts {#create-global-server-hooks-for-all-repositories}

Pour créer un hook Git qui s'applique à tous les dépôts, définissez un hook serveur global. Les hooks serveur globaux s'appliquent également à :

- Les dépôts wiki de projet et de groupe. Les noms de leur répertoire de stockage sont au format `<id>.wiki.git`.
- Les dépôts de gestion du design sous un projet. Les noms de leur répertoire de stockage sont au format `<id>.design.git`.

### Choisir un répertoire de hook serveur {#choose-a-server-hook-directory}

Avant de créer un hook serveur global, vous devez choisir un répertoire pour celui-ci.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Le répertoire est défini dans `gitlab.rb` sous `gitaly['configuration'][:hooks][:custom_hooks_dir]`. Vous pouvez soit :

- Utiliser la suggestion par défaut du répertoire `/var/opt/gitlab/gitaly/custom_hooks` en le décommentant.
- Ajouter votre propre paramètre.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

- Le répertoire est défini dans `gitaly/config.toml` sous la section `[hooks]`. Cependant, GitLab utilise la valeur `custom_hooks_dir` dans `gitlab-shell/config.yml` si la valeur dans `gitaly/config.toml` est vide ou inexistante.
- Le répertoire par défaut est `/home/git/gitlab-shell/hooks`.

{{< /tab >}}

{{< /tabs >}}

### Créer le hook serveur global {#create-the-global-server-hook}

Pour créer un hook serveur global pour tous les dépôts :

1. Sur le serveur GitLab, accédez au répertoire de hook serveur global configuré.
1. Dans le répertoire de hook serveur global configuré, créez un répertoire pour les hooks correspondant au type de hook. Par exemple, pour un hook serveur `pre-receive`, le nom du répertoire doit être `pre-receive.d`.
1. Dans ce nouveau répertoire, ajoutez vos hooks serveur. Les hooks serveur Git peuvent être dans n'importe quel langage de programmation. Assurez-vous que le shebang (`#!`) en haut reflète le type de langage. Par exemple, si le script est en Ruby, le shebang est probablement `#!/usr/bin/env ruby`.
1. Rendez le fichier de hook exécutable, assurez-vous qu'il appartient à l'utilisateur Git et qu'il ne correspond pas au modèle de fichier de sauvegarde (`*~`).

Si le code du hook serveur est correctement implémenté, il doit s'exécuter lors du prochain déclenchement du hook Git. Les hooks sont exécutés dans l'ordre alphabétique par nom de fichier dans les sous-répertoires de type de hook.

## Supprimer les hooks serveur pour un dépôt {#remove-server-hooks-for-a-repository}

Pour supprimer les hooks serveur, transmettez une archive tar vide à `hook set` pour indiquer que le dépôt ne doit contenir aucun hook. Par exemple :

```shell
cat empty_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
```

## Hooks serveur chaînés {#chained-server-hooks}

GitLab peut exécuter des hooks serveur en chaîne. GitLab recherche et exécute les hooks serveur dans l'ordre suivant :

- Hooks serveur GitLab intégrés. Ces hooks serveur ne sont pas personnalisables par les utilisateurs.
- `<project>.git/custom_hooks/<hook_name>` : Hooks par projet. Cet emplacement est conservé pour des raisons de compatibilité ascendante.
- `<project>.git/custom_hooks/<hook_name>.d/*` : Emplacement pour les hooks par projet.
- `<custom_hooks_dir>/<hook_name>.d/*` : Emplacement pour tous les fichiers de hook globaux exécutables, à l'exception des fichiers de sauvegarde d'éditeur.

Dans un répertoire de hooks serveur, les hooks :

- Sont exécutés dans l'ordre alphabétique.
- Cessent de s'exécuter lorsqu'un hook se termine avec une valeur non nulle.

## Variables d'environnement disponibles pour les hooks serveur {#environment-variables-available-to-server-hooks}

Vous pouvez transmettre n'importe quelle variable d'environnement aux hooks serveur, mais vous ne devez vous appuyer que sur les variables d'environnement prises en charge.

Les variables d'environnement GitLab suivantes sont prises en charge pour tous les hooks serveur :

| Variable d'environnement | Description |
|:---------------------|:------------|
| `GL_ID`              | Identifiant GitLab de l'utilisateur ou de la clé SSH qui a initié le push. Par exemple, `user-2234` ou `key-4`. |
| `GL_PROJECT_PATH`    | Chemin du projet GitLab. |
| `GL_PROTOCOL`        | Protocole utilisé pour ce changement. L'un des suivants : `http` (Git `push` via HTTP), `ssh` (Git `push` via SSH), ou `web` (toutes les autres actions). |
| `GL_REPOSITORY`      | ID du projet GitLab avec un préfixe `project-`. Par exemple, `project-1234` |
| `GL_USERNAME`        | Nom d'utilisateur GitLab de l'utilisateur qui a initié le push. |

Les variables d'environnement Git suivantes sont prises en charge pour les hooks serveur `pre-receive` et `post-receive` :

| Variable d'environnement               | Description |
|:-----------------------------------|:------------|
| `GIT_ALTERNATE_OBJECT_DIRECTORIES` | Répertoires d'objets alternatifs dans l'[environnement de quarantaine](https://git-scm.com/docs/git-receive-pack#_quarantine_environment). |
| `GIT_OBJECT_DIRECTORY`             | Chemin du projet GitLab dans l'environnement de quarantaine. |
| `GIT_PUSH_OPTION_COUNT`            | Nombre d'[options push](../topics/git/commit.md#push-options). |
| `GIT_PUSH_OPTION_<i>`              | Valeur d'une option push spécifique où `<i>` va de `0` à une valeur inférieure à celle définie dans `GIT_PUSH_OPTION_COUNT`. |

## Messages d'erreur personnalisés {#custom-error-messages}

Lorsque les hooks serveur rejettent un push, fournissez des messages d'erreur clairs pour aider les utilisateurs à comprendre pourquoi le push a été rejeté et comment résoudre le problème. Les messages d'erreur personnalisés apparaissent dans l'interface GitLab et dans le terminal de l'utilisateur lorsqu'un hook refuse un push.

Sans messages d'erreur personnalisés, les utilisateurs ne voient que des messages génériques tels que `(pre-receive hook declined)`. Des messages d'erreur clairs aident les utilisateurs à :

- Comprendre pourquoi leur push a été rejeté.
- Résoudre le problème sans contacter un administrateur.
- Réduire les demandes d'assistance.

Pour afficher un message d'erreur personnalisé, votre script doit :

- Envoyer les messages d'erreur personnalisés vers le `stdout` ou le `stderr` du script.
- Préfixer chaque message avec `GL-HOOK-ERR:` sans aucun caractère avant le préfixe.

Par exemple :

```shell
# Bad: Generic message
echo "GL-HOOK-ERR: Commit rejected.";

# Good: Specific message with action
echo "GL-HOOK-ERR: Commit rejected: Commit message must include an issue reference (for example, #1234).";
```

## Sujets connexes {#related-topics}

- [Crochets système](system_hooks.md)
- [Crochets de fichier](file_hooks.md)
- [Chemins de réplica générés par Praefect](gitaly/praefect/_index.md#praefect-generated-replica-paths)

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec des hooks serveur Git, vous pourriez rencontrer les problèmes suivants.

### Erreur : `pre-receive hook declined` {#error-pre-receive-hook-declined}

Lorsqu'un utilisateur pousse vers un dépôt GitLab, il peut recevoir un message d'erreur contenant `(pre-receive hook declined)`. Par exemple :

```plaintext
! [remote rejected] main (pre-receive hook declined)
error: failed to push some refs to 'https://gitlab.example.com/group/project'
```

Cette erreur indique qu'un hook pre-receive a rejeté le push. Les hooks pre-receive s'exécutent avant la mise à jour de toute référence dans le dépôt. Git fournit trois hooks côté serveur qui peuvent rejeter les pushs :

- `pre-receive` : S'exécute avant la mise à jour de toute référence. Peut rejeter l'ensemble du push.
- `update` : S'exécute une fois par branche mise à jour. Peut rejeter des branches individuelles.
- `post-receive` : S'exécute après la mise à jour de toutes les références. Ne peut pas rejeter les pushs, mais peut provoquer des erreurs si le hook échoue.

L'erreur `(pre-receive hook declined)` provient généralement du hook `pre-receive` ou `update`. Pour identifier le problème :

1. Vérifiez la sortie immédiatement avant le message `(pre-receive hook declined)`. La sortie contient souvent des informations sur la raison pour laquelle le push a été rejeté. Par exemple :

   ```plaintext
   remote: GitLab: The default branch of a project cannot be deleted.
   ! [remote rejected] main (pre-receive hook declined)
   ```

1. Consultez les journaux Gitaly pour plus de détails sur la raison de l'échec du hook :

   ```shell
   sudo grep PreReceiveHook /var/log/gitlab/gitaly/current | jq .
   ```

1. Si le dépôt a des hooks serveur personnalisés configurés, examinez le code du hook personnalisé pour détecter des problèmes.

Les causes courantes des échecs de hook pre-receive sont les suivantes :

- Protection de la branche par défaut : Les pushs qui suppriment ou forcent la mise à jour de la branche par défaut sont rejetés. Cela se produit avec `git push --mirror` lorsque le dépôt source a une branche par défaut différente de celle du dépôt cible.
- Règles push : Le push enfreint les règles push configurées, telles que les exigences relatives aux messages de commit, les limites de taille de fichier ou les restrictions d'adresse e-mail de l'auteur.
- Hooks serveur personnalisés : Un script de hook serveur personnalisé a rejeté le push. Examinez votre code de hook personnalisé et les messages d'erreur.
- Délai d'expiration : Le hook a mis trop de temps à s'exécuter et a été interrompu. Consultez les journaux Gitaly pour détecter les erreurs de délai d'expiration.
- Objets LFS : Les objets Git LFS requis sont manquants dans le dépôt.

Pour aider les utilisateurs à comprendre les échecs de hook, utilisez des [messages d'erreur personnalisés](#custom-error-messages) pour fournir un retour clair sur la raison pour laquelle un push a été rejeté. Les messages d'erreur personnalisés apparaissent dans l'interface GitLab et dans le terminal de l'utilisateur.
