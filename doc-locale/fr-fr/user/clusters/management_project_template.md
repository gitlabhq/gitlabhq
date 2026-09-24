---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gérer les applications de cluster
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab fournit un modèle de projet de gestion de cluster que vous utilisez pour créer un projet. Le projet inclut des applications de cluster qui s'intègrent à GitLab et étendent ses fonctionnalités. Vous pouvez utiliser le modèle présenté dans le projet pour étendre vos applications de cluster personnalisées.

> [!note]
> Le modèle de projet fonctionne sur GitLab.com sans modification. Si vous utilisez une instance GitLab Self-Managed, vous devez modifier le fichier `.gitlab-ci.yml`.

## Utiliser un seul projet pour l'agent et vos manifestes {#use-one-project-for-the-agent-and-your-manifests}

Si vous n'avez pas encore utilisé l'agent pour connecter votre cluster à GitLab :

1. [Créez un projet à partir du modèle de projet de gestion de cluster](#create-a-project-based-on-the-cluster-management-project-template).
1. [Configurez le projet pour l'agent](agent/install/_index.md).
1. Dans les paramètres de votre projet, créez une [variable d'environnement](../../ci/variables/_index.md#for-a-project) nommée `$KUBE_CONTEXT` et définissez la valeur sur `path/to/agent-configuration-project:your-agent-name`.
1. [Configurez les fichiers](#configure-the-project) selon vos besoins.

## Utiliser des projets séparés pour l'agent et vos manifestes {#use-separate-projects-for-the-agent-and-your-manifests}

Si vous avez déjà configuré l'agent et connecté un cluster à GitLab :

1. [Créez un projet à partir du modèle de projet de gestion de cluster](#create-a-project-based-on-the-cluster-management-project-template).
1. Dans le projet où vous avez configuré votre agent, [accordez à l'agent l'accès au nouveau projet](agent/ci_cd_workflow.md#authorize-agent-access).
1. Dans le nouveau projet, créez une [variable d'environnement](../../ci/variables/_index.md#for-a-project) nommée `$KUBE_CONTEXT` et définissez la valeur sur `path/to/agent-configuration-project:your-agent-name`.
1. Dans le nouveau projet, [configurez les fichiers](#configure-the-project) selon vos besoins.

## Créer un projet basé sur le modèle de projet de gestion de cluster {#create-a-project-based-on-the-cluster-management-project-template}

Pour créer un projet à partir du modèle de projet de gestion de cluster :

1. Dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Nouveau projet/dépôt**.
1. Sélectionnez **Créer à partir d'un modèle**.
1. Dans la liste des modèles, en regard de **Gestion de cluster avec GitLab**, sélectionnez **Utiliser un modèle**.
1. Saisissez les détails du projet.
1. Sélectionnez **Créer le projet**.
1. Dans le nouveau projet, [configurez les fichiers](#configure-the-project) selon vos besoins.

## Configurer le projet {#configure-the-project}

Après avoir utilisé le modèle de gestion de cluster pour créer un projet, vous pouvez configurer :

- [Le fichier `.gitlab-ci.yml`](#the-gitlab-ciyml-file).
- [Le fichier principal `helmfile.yml`](#the-main-helmfileyml-file).
- [Le répertoire contenant les applications intégrées](#built-in-applications).

### Le fichier `.gitlab-ci.yml` {#the-gitlab-ciyml-file}

Le fichier `.gitlab-ci.yml` :

- Vérifie que vous utilisez Helm version 3.
- Déploie les applications activées depuis le projet.

Vous pouvez modifier et étendre les définitions de pipeline.

L'image de base utilisée dans le pipeline est générée par le projet [cluster-applications](https://gitlab.com/gitlab-org/cluster-integration/cluster-applications). Cette image contient un ensemble de scripts utilitaires Bash pour prendre en charge les [releases Helm v3](https://helm.sh/docs/intro/using_helm/#three-big-concepts).

Si vous utilisez une instance GitLab Self-Managed, vous devez modifier le fichier `.gitlab-ci.yml`. Plus précisément, la section qui commence par le commentaire `Automatic package upgrades` ne fonctionne pas sur une instance GitLab Self-Managed, car `include` fait référence à un projet GitLab.com. Si vous supprimez tout ce qui se trouve en dessous de ce commentaire, le pipeline réussit.

### Le fichier principal `helmfile.yml` {#the-main-helmfileyml-file}

Le modèle contient un [Helmfile](https://github.com/helmfile/helmfile) que vous pouvez utiliser pour gérer les applications de cluster avec [Helm v3](https://helm.sh/).

Ce fichier contient une liste de chemins vers d'autres fichiers Helm pour chaque application. Tous ces chemins sont commentés par défaut ; vous devez donc décommenter ceux correspondant aux applications que vous souhaitez utiliser dans votre cluster.

Par défaut, chaque `helmfile.yaml` dans ces sous-chemins possède l'attribut `installed: true`. Cela signifie que, selon l'état de votre cluster et des releases Helm, Helmfile tente d'installer ou de mettre à jour les applications à chaque exécution du pipeline. Si vous définissez cet attribut sur `installed: false`, Helmfile tente de désinstaller cette application de votre cluster. [En savoir plus](https://helmfile.readthedocs.io/en/latest/) sur le fonctionnement de Helmfile.

### Applications intégrées {#built-in-applications}

Le modèle contient un répertoire `applications` avec un fichier `helmfile.yaml` configuré pour chaque application du modèle.

Les [applications intégrées prises en charge](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/tree/main/applications) sont :

- [Cert-manager](../infrastructure/clusters/manage/management_project_applications/certmanager.md)
- [GitLab Runner](../infrastructure/clusters/manage/management_project_applications/runner.md)
- [Ingress](../infrastructure/clusters/manage/management_project_applications/ingress.md)
- [Vault](../infrastructure/clusters/manage/management_project_applications/vault.md)

Chaque application possède un fichier `applications/{app}/values.yaml`. Pour GitLab Runner, le fichier est `applications/{app}/values.yaml.gotmpl`.

Dans ce fichier, vous pouvez définir les valeurs par défaut pour le chart Helm de votre application. Certaines applications ont déjà des valeurs par défaut définies.
