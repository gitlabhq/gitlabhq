---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Options, commandes et variables d'environnement pour le CLI GitLab Duo."
title: Référence de GitLab Duo CLI
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez ces options, commandes et variables d'environnement lorsque vous démarrez ou exécutez GitLab Duo CLI.

Cette liste n'est pas exhaustive. Pour une référence complète, consultez la [référence complète du CLI GitLab Duo](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md).

## Options {#options}

GitLab Duo CLI prend en charge les options suivantes :

- `-C, --cwd <path>` : modifier le répertoire de travail.
- `-h, --help` : afficher l'aide pour GitLab Duo CLI ou une commande spécifique. Par exemple, `duo --help` ou `duo run --help`.
- `-v`, `--version` : afficher les informations de version.
- `--model <model>` : sélectionner le modèle d'IA à utiliser pour la session.

Pour une liste complète des options, consultez la référence complète du CLI GitLab Duo.

## Commandes {#commands}

Les commandes suivantes sont disponibles pour chaque configuration :

{{< tabs >}}

{{< tab title="glab" >}}

- `glab duo cli` : démarrer le mode interactif.
- `glab duo cli log` : afficher et gérer les fichiers journaux.
- `glab duo cli run` : démarrer le mode sans interface.

{{< /tab >}}

{{< tab title="duo" >}}

- `duo` : démarrer le mode interactif.
- `duo config` : gérer la configuration et les paramètres d'authentification.
- `duo log` : afficher et gérer les fichiers journaux.
- `duo run` : démarrer le mode sans interface.

{{< /tab >}}

{{< /tabs >}}

Pour une liste complète des commandes, consultez la référence complète du CLI GitLab Duo.

## Variables d'environnement {#environment-variables}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) de la variable d'environnement `AI_AGENT` dans GitLab Duo CLI 8.95.0, lors de la release GitLab 19.0

{{< /history >}}

Vous pouvez configurer GitLab Duo CLI à l'aide de variables d'environnement :

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD` : mot de passe d'authentification HTTP Git
- `DUO_WORKFLOW_GIT_HTTP_USER` : nom d'utilisateur d'authentification HTTP Git
- `GITLAB_BASE_URL` ou `GITLAB_URL` : URL de l'instance GitLab
- `GITLAB_DUO_MODEL` : modèle d'IA à utiliser pour la session
- `GITLAB_OAUTH_TOKEN` ou `GITLAB_TOKEN` : jeton d'authentification

Lorsque GitLab Duo CLI exécute une commande en votre nom, il définit la variable d'environnement `AI_AGENT` dans ce processus. Les scripts et outils peuvent lire `AI_AGENT` pour détecter qu'ils s'exécutent dans un contexte d'exécution piloté par l'IA.

Pour une liste complète des variables d'environnement, consultez la référence complète du CLI GitLab Duo.
