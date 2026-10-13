---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Remplacez l'image Docker par défaut par une image personnalisée, renforcée ou hors ligne pour exécuter des flows GitLab Duo Agent Platform dans CI/CD."
title: "Configurer les images pour l'exécution des flows"
---

{{< details >}}

- Édition : [Gratuite](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les flows qui s'exécutent avec CI/CD s'exécutent dans une image Docker. Par défaut, GitLab fournit une image qui inclut les outils et la protection réseau dont les flows ont besoin. Vous pouvez remplacer l'image par défaut par une image personnalisée ou renforcée pour ajouter des dépendances de projet, respecter des exigences de conformité ou exécuter des flows dans un environnement hors ligne.

## Changer l'image Docker par défaut {#change-the-default-docker-image}

Tous les flows exécutés avec CI/CD utilisent une image Docker fournie par GitLab. Cette image Docker utilise [Anthropic Sandbox Runtime (`srt`)](https://github.com/anthropic-experimental/sandbox-runtime) pour inclure automatiquement la protection réseau.

Vous pouvez modifier l'image Docker si vous avez un projet complexe avec des dépendances ou des outils spécifiques.

Pour changer l'image Docker par défaut, dans le fichier `agent-config.yml`, ajoutez la configuration suivante :

```yaml
image: YOUR_DOCKER_IMAGE
```

Par exemple :

{{< tabs >}}

{{< tab title="Projet Python" >}}

```yaml
image: python:3.11-slim
```

{{< /tab >}}

{{< tab title="Projet Node.js" >}}

```yaml
image: node:20-alpine
```

{{< /tab >}}

{{< /tabs >}}

### Ajouter une protection réseau {#add-network-protection}

Pour utiliser la protection réseau dans votre image, ajoutez `srt` à votre image Docker avec votre version préférée :

```Docker
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.63
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version
```

Pour plus d'informations sur SRT et comment l'installer sur une image personnalisée, voir [le sandbox de l'environnement d'exécution à distance](../../environment_sandbox.md).

## Utiliser une image personnalisée {#use-a-custom-image}

Si vous utilisez une image Docker personnalisée, assurez-vous que les commandes suivantes sont disponibles pour que l'agent fonctionne correctement :

- `git`
- `curl`, qui télécharge le binaire GitLab Duo CLI au démarrage du flow.

La plupart des images de base incluent ces commandes par défaut. Cependant, les images minimales (comme les variantes `alpine`) peuvent nécessiter que vous les installiez explicitement. Si nécessaire, vous pouvez installer les commandes manquantes dans la [configuration du script de configuration](_index.md#configure-setup-scripts).

> [!note]
> Dans GitLab 18.9 et les versions antérieures, il existe [un problème connu (ticket 587996)](https://gitlab.com/gitlab-org/gitlab/-/work_items/587996) où les flows peuvent échouer avec les versions plus récentes de `git` dans les images personnalisées. Ce problème est résolu dans `@gitlab/duo-cli` version 8.71.0.
>
> Si vous utilisez `@gitlab/duo-cli` version 8.71.0 ou une version antérieure, pour éviter que les flows échouent avec les versions Git plus récentes, vous pouvez effectuer l'une des actions suivantes :
>
> - Utiliser la version Git `2.43.7` ou antérieure dans votre image personnalisée
> - Utiliser `@gitlab/duo-cli` version 8.71.0.

De plus, selon les appels d'outils effectués par les agents lors de l'exécution des flows, d'autres utilitaires courants peuvent être nécessaires.

Par exemple, si vous utilisez une image basée sur Alpine :

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --update git curl
```

### Sécurité et performances {#security-and-performance}

Lorsque vous utilisez une image Docker personnalisée, le [sandbox d'environnement](../../environment_sandbox.md) n'est appliqué que si Anthropic Sandbox Runtime (SRT) est inclus dans votre image personnalisée. Si SRT n'est pas inclus, votre flow peut accéder à n'importe quel domaine accessible depuis le runner et à l'ensemble du système de fichiers.

Si vous avez besoin d'une isolation réseau avec des images personnalisées, [installez SRT sur votre image](../../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image) et [configurez une politique réseau](../../environment_sandbox.md#configure-a-network-policy), ou configurez des contrôles au niveau du réseau sur votre runner (par exemple, des règles de pare-feu ou des politiques réseau).

Pour réduire le temps de démarrage du job d'environ 15 à 20 secondes, incluez le binaire GitLab Duo CLI et le CLI `glab` dans votre image personnalisée. L'image renforcée préinstalle les deux outils.

## Utiliser une image personnalisée dans un environnement hors ligne {#use-a-custom-image-in-an-offline-environment}

Dans les environnements hors ligne où les runners ne peuvent pas accéder aux registres externes, vous pouvez prégénérer une image d'exécuteur personnalisée qui inclut le GitLab Duo CLI. Lorsque le GitLab Duo CLI est déjà dans l'image, le démarrage du flow ignore l'étape de téléchargement.

Prérequis :

- Disposer d'un accès administrateur.
- GitLab 18.9 ou version ultérieure.
- Accès à une machine en ligne pour construire l'image et télécharger les artefacts.

Pour configurer les flows pour un environnement hors ligne :

1. Sur une machine connectée, téléchargez le binaire GitLab Duo CLI depuis le [registre de paquets GitLab](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/packages) :

   ```shell
   curl --location "https://gitlab.com/api/v4/projects/46519181/packages/generic/duo-cli/9.8.0/duo-linux-x64" \
     --output duo-linux-x64
   ```

1. Créez une image personnalisée qui inclut le binaire :

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   COPY duo-linux-x64 /usr/bin/duo
   RUN chmod +x /usr/bin/duo
   ```

1. Transférez l'image vers votre environnement hors ligne. Par exemple, avec Docker, exécutez les commandes suivantes :

   ```shell
   # On an online machine
   docker save my-duo-executor:latest -o duo-executor.tar

   # Transfer `duo-executor.tar` to the offline environment

   # On an offline machine
   docker load -i duo-executor.tar
   ```

1. Poussez l'image vers votre registre de conteneurs interne.
1. Définissez le registre d'images personnalisé :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
   1. Sélectionnez **Modifier la configuration**.
   1. Dans le champ de texte **Registre d'images**, saisissez l'URL de votre registre interne (par exemple, `registry.internal.example.com`).
1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Pour utiliser l'image personnalisée, mettez à jour le fichier `agent-config.yml` :

   ```yaml
   image: registry.internal.example.com/duo-executor:latest
   ```

## Utiliser une image Red Hat Universal Base Image 9 Minimal {#use-a-red-hat-universal-base-image-9-minimal}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/merge_requests/12) dans GitLab 19.0.

{{< /history >}}

GitLab fournit une variante d'image minimale et renforcée basée sur Red Hat Universal Base Image (UBI) 9 Minimal.

Utilisez l'image renforcée lorsque votre environnement requiert :

- Une image de base Red Hat UBI. Par exemple, pour la conformité FedRAMP ou d'entreprise.
- L'exécution de conteneurs non root par défaut.
- Une surface d'attaque minimale sans runtimes de langage au-delà de ce dont Agent Platform a besoin.
- Aucun accès internet sortant au moment de l'exécution du flow (toutes les dépendances de l'Agent Platform sont préinstallées)

L'image renforcée est publiée à l'adresse `registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened`

Elle est construite pour `linux/amd64` et `linux/arm64`, et utilise le schéma de tags suivant :

- `:<short-sha>` pour chaque build
- `:<git-tag>` pour chaque release

Prérequis :

- GitLab 18.10 ou version ultérieure

Pour utiliser l'image renforcée, définissez-la dans votre `agent-config.yml` :

```yaml
image: registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>
```

### Contenu de l'image {#image-contents}

Pour la liste exhaustive et à jour de tous les composants et versions épinglées, consultez l'inventaire d'exécution dans le `default-docker-image` [README](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/blob/main/README.md#runtime-inventory).

Le tableau suivant liste les versions épinglées actuelles :

| Composant                             | Version ou source                                        |
|---------------------------------------|----------------------------------------------------------|
| Image de base                            | Red Hat UBI 9 Minimal (`ubi9-minimal:9.7-1776833838`)    |
| `git`                                 | 2.47.x (stock UBI 9)                                     |
| `git-lfs`                             | UBI 9 stock                                              |
| Node.js                               | 20 (flux de module UBI 9 `nodejs:20`)                     |
| `npm`                                 | Inclus avec Node.js 20                                  |
| `@gitlab/duo-cli`                     | 9.21.0                                                   |
| `glab` (GitLab CLI)                   | 1.107.0                                                  |
| `@anthropic-ai/sandbox-runtime` (SRT) | 0.0.63 (via npm)                                         |
| `bwrap` (bubblewrap)                  | AlmaLinux 9 EPEL (binaire simple, sandboxing basé sur userns) |
| `socat`                               | AlmaLinux 9 EPEL                                         |
| `rg` (ripgrep)                        | AlmaLinux 9 EPEL                                         |
| `unshare`                             | UBI 9 (`util-linux-core`)                                |
| Utilisateur d'exécution                          | Non root, UID 1001 (`duo-runner`)                        |

L'image inclut le GitLab Duo CLI et `glab`. L'accès sortant vers `registry.npmjs.org` ou `registry.gitlab.com` n'est pas nécessaire au moment de l'exécution du flow.

Node.js et `npm` restent dans l'image uniquement pour installer l'Anthropic Sandbox Runtime (SRT). Le GitLab Duo CLI lui-même est un binaire précompilé et n'en a pas besoin. Lorsque SRT sera également distribué en tant que binaire précompilé, une version ultérieure de l'image renforcée supprimera entièrement Node.js et `npm`.

### Ajouter des paquets supplémentaires {#add-additional-packages}

L'image renforcée s'exécute en tant qu'UID 1001 (`duo-runner`). Le `setup_script` dans votre `agent-config.yml` s'exécute également en tant que cet utilisateur non root et ne peut donc pas installer de paquets système avec `microdnf`.

Pour ajouter des runtimes de langage ou des paquets système :

1. Étendez l'image avec votre propre couche `FROM` :

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>

   USER root
   RUN microdnf install -y python3.12 python3.12-pip && microdnf clean all
   USER 1001
   ```

1. Utilisez `setup_script` pour les dépendances de projet qui ne nécessitent pas d'accès root. Par exemple, `pip install --user` ou `npm install`.
