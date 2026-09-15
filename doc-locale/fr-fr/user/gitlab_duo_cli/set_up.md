---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Installer et authentifier le GitLab Duo CLI.
title: Configurer le GitLab Duo CLI
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser GitLab Duo CLI via [GitLab CLI](https://docs.gitlab.com/cli/) (`glab`). Avec la CLI GitLab, vous avez accès à d'autres fonctionnalités GitLab et vous n'avez besoin de vous authentifier qu'une seule fois, à l'aide d'OAuth ou d'un jeton d'accès personnel.

Vous pouvez également installer et utiliser GitLab Duo CLI (`duo`) en tant qu'outil IA autonome, en vous authentifiant séparément avec un jeton d'accès personnel.

Les deux configurations prennent en charge les modes interactif et headless, ainsi que l'ensemble des options, commandes et fonctionnalités du GitLab Duo CLI.

## Prérequis {#prerequisites}

- GitLab 19.2 ou version ultérieure.
- Les [prérequis pour GitLab Duo Agent Platform](../duo_agent_platform/_index.md#prerequisites).
- Pour GitLab Self-Managed et GitLab Dedicated, assurez-vous que l'accès au GitLab Duo CLI est [activé](_index.md#manage-gitlab-duo-cli-access).

> [!note]
> Si vous utilisez GitLab 18.11 à 19.1, vous pouvez utiliser la dernière version de GitLab Duo CLI en activant les [fonctionnalités bêta et expérimentales](../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features).

## Avec GitLab CLI {#with-the-gitlab-cli}

Prérequis :

- [GitLab CLI](https://docs.gitlab.com/cli/) 1.107.0 ou version ultérieure.
- GitLab CLI est [authentifié](https://docs.gitlab.com/cli/#authenticate-with-gitlab).

Pour configurer GitLab Duo CLI pour une utilisation via GitLab CLI :

1. Exécutez la commande `glab` pour GitLab Duo CLI :

   ```shell
   glab duo cli
   ```

1. Suivez les instructions pour installer le binaire de GitLab Duo CLI.

GitLab CLI gère automatiquement l'authentification, vous pouvez donc commencer à utiliser GitLab Duo CLI immédiatement.

## Sans GitLab CLI {#without-the-gitlab-cli}

Pour utiliser GitLab Duo CLI en tant qu'outil autonome, installez-le puis authentifiez-vous.

### Installation {#install}

Pour installer GitLab Duo CLI en tant que binaire compilé, téléchargez et exécutez le script d'installation.

Sur macOS et Linux :

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

Sur Windows :

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

### Authentification {#authenticate}

> [!note]
> Si `glab` est déjà installé et authentifié sur votre système lors de la première exécution de `duo`, `duo` utilise automatiquement `glab` comme assistant d'identification. Vous n'avez pas besoin de vous authentifier séparément. Cela nécessite `glab` 1.85.2 ou version ultérieure et `duo` 8.68.0 ou version ultérieure.
>
> Si vous avez authentifié `duo` avant que cette fonctionnalité soit disponible et que vous souhaitez utiliser `glab` comme assistant d'identification à la place, supprimez vos paramètres d'authentification de `~/.gitlab/storage.json`.

Prérequis :

- Un [jeton d'accès personnel](../profile/personal_access_tokens.md) avec les autorisations `api`

Pour vous authentifier :

1. Exécutez `duo` dans votre terminal. La première fois que vous exécutez GitLab Duo CLI, un écran de configuration s'affiche.
1. Saisissez une **URL de l'instance GitLab** puis appuyez sur <kbd>Entrée</kbd> :
   - Pour GitLab.com, saisissez `https://gitlab.com`.
   - Pour GitLab Self-Managed ou GitLab Dedicated, saisissez l'URL de votre instance.
1. Pour **le jeton GitLab**, saisissez votre jeton d'accès personnel.
1. Pour enregistrer et quitter GitLab CLI, appuyez sur <kbd>Entrée</kbd>.
1. Pour redémarrer GitLab CLI, exécutez `duo` dans votre terminal.

Pour modifier la configuration après la configuration initiale, utilisez `duo config edit`.

### Authentification avec des variables d'environnement {#authenticate-with-environment-variables}

Prérequis :

- Un [jeton d'accès personnel](../profile/personal_access_tokens.md) avec les autorisations `api`

GitLab Duo CLI respecte les variables d'environnement proxy standard :

- `HTTP_PROXY` ou `http_proxy` : URL du proxy pour les requêtes HTTP
- `HTTPS_PROXY` ou `https_proxy` : URL du proxy pour les requêtes HTTPS
- `NO_PROXY` ou `no_proxy` : liste d'hôtes séparés par des virgules à exclure du proxying

Pour vous authentifier avec des variables d'environnement :

1. Définissez `GITLAB_TOKEN` ou `GITLAB_OAUTH_TOKEN` sur votre jeton d'accès personnel.

   ```shell
   export GITLAB_TOKEN="<your-personal-access-token>"
   ```

1. Facultatif. Définissez `GITLAB_BASE_URL` ou `GITLAB_URL` sur l'URL de votre instance GitLab personnalisée, par exemple `https://gitlab.example.com`. La valeur par défaut est `https://gitlab.com`.

   ```shell
   export GITLAB_BASE_URL="<your-instance-url>"
   ```

Cette méthode est utile pour le mode sans interface, les pipelines CI/CD et les workflows scriptés où l'authentification interactive n'est pas possible.

## Sujets connexes {#related-topics}

- [Référence complète du GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [Considérations de sécurité pour les extensions d'éditeur](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
