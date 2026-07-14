---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Fichiers sécurisés au niveau du projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/350748) et feature flag `ci_secure_files` supprimé dans GitLab 15.7.

{{< /history >}}

Cette fonctionnalité fait partie de [Mobile DevOps](../mobile_devops/_index.md). La fonctionnalité est encore en cours de développement, mais vous pouvez :

- [Demander une fonctionnalité](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?description_template=feature_request).
- [Signaler un bug](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?description_template=report_bug).
- [Partager des commentaires](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?description_template=general_feedback).

Vous pouvez stocker en toute sécurité jusqu'à 100 fichiers à utiliser dans des pipelines CI/CD en tant que fichiers sécurisés. Ces fichiers sont stockés en toute sécurité en dehors du dépôt de votre projet et ne sont pas soumis au contrôle de version. Il est sûr de stocker des informations sensibles dans ces fichiers. Les fichiers sécurisés prennent en charge les types de fichiers texte brut et binaire, mais doivent faire 5 Mo ou moins.

Vous pouvez gérer les fichiers sécurisés dans les paramètres du projet, ou avec l'[API des fichiers sécurisés](../../api/secure_files.md).

Les fichiers sécurisés peuvent être [téléchargés et utilisés par des jobs CI/CD](#use-secure-files-in-cicd-jobs) en utilisant la commande [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile).

## Ajouter un fichier sécurisé à un projet {#add-a-secure-file-to-a-project}

Pour ajouter un fichier sécurisé à un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez la section **Fichiers sécurisés**.
1. Sélectionnez **Téléverser un Fichier**.
1. Trouvez le fichier à téléverser, sélectionnez **Ouvrir**, et le téléversement du fichier commence immédiatement. Le fichier apparaît dans la liste lorsque le téléversement est terminé.

## Utiliser des fichiers sécurisés dans des jobs CI/CD {#use-secure-files-in-cicd-jobs}

> [!warning]
> Le contenu des fichiers sécurisés n'est pas [masqué](../variables/_index.md#mask-a-cicd-variable) dans la sortie du job log. Veillez à éviter d'afficher le contenu des fichiers sécurisés dans le job log, en particulier lorsque la sortie de journalisation pourrait contenir des informations sensibles.

### Avec l'outil `glab` {#with-the-glab-tool}

Pour télécharger un ou plusieurs fichiers sécurisés avec [`glab`](https://gitlab.com/gitlab-org/cli/), vous pouvez utiliser l'image Docker `cli` dans le job CI/CD.

#### Télécharger tous les fichiers d'un projet {#download-all-the-files-in-a-project}

Pour télécharger tous les fichiers sécurisés d'un projet :

```yaml
test:
  image: registry.gitlab.com/gitlab-org/cli:latest
  script:
    - glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL
    - glab -R $CI_PROJECT_PATH securefile download --all --output-dir="where/to/save"
```

Dans cet exemple, toutes les variables sont des [variables prédéfinies](../variables/predefined_variables.md) automatiquement disponibles.

#### Télécharger un seul fichier d'un projet {#download-a-single-file-in-a-project}

```yaml
test:
  image: registry.gitlab.com/gitlab-org/cli:latest
  script:
    - glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL
    - glab -R $CI_PROJECT_PATH securefile download $SECURE_FILE_ID --path="where/to/save/file.txt"
```

La variable CI/CD `SECURE_FILE_ID` doit être transmise explicitement au job, par exemple dans les [paramètres CI/CD](../variables/_index.md#define-a-cicd-variable-in-the-ui) ou lors de l'[exécution manuelle d'un pipeline](../pipelines/_index.md#run-a-pipeline-manually). Toute autre variable est une [variable prédéfinie](../variables/predefined_variables.md) automatiquement disponible.

Vous pouvez également, au lieu d'utiliser l'image Docker, [télécharger le binaire](https://gitlab.com/gitlab-org/cli/-/releases) et l'utiliser dans votre job CI/CD.

### Avec l'outil `download-secure-files` (déprécié) {#with-the-download-secure-files-tool-deprecated}

{{< history >}}

- [Déprécié](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/issues/45) dans GitLab 18.6.

{{< /history >}}

> [!warning]
> Cette méthode est dépréciée.

Pour utiliser vos fichiers sécurisés dans un job CI/CD, vous pouvez utiliser l'outil [`download-secure-files`](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files) pour télécharger les fichiers dans le job. Une fois téléchargés, vous pouvez les utiliser avec vos autres commandes de script.

Ajoutez une commande dans la section `script` de votre job pour télécharger l'outil `download-secure-files` et l'exécuter. Les fichiers sont téléchargés dans un répertoire `.secure_files` à la racine du projet. Pour modifier l'emplacement de téléchargement des fichiers sécurisés, définissez le chemin dans la [variable CI/CD](../variables/_index.md) `SECURE_FILES_DOWNLOAD_PATH`.

Par exemple :

```yaml
test:
  variables:
    SECURE_FILES_DOWNLOAD_PATH: './where/files/should/go/'
  script:
    - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
```

## Détails de sécurité {#security-details}

Les fichiers sécurisés au niveau du projet sont chiffrés lors du téléversement à l'aide du gem Ruby [Lockbox](https://github.com/ankane/lockbox) via l'interface [`Ci::SecureFileUploader`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/uploaders/ci/secure_file_uploader.rb). Cette interface génère une somme de contrôle SHA256 du fichier source lors du téléversement, qui est persistée avec l'enregistrement dans la base de données afin de pouvoir être utilisée pour vérifier le contenu du fichier lors du téléchargement.

Une [clé de chiffrement unique](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb#L27) est générée pour chaque fichier lors de sa création et persistée dans la base de données. Les fichiers téléversés chiffrés sont stockés soit dans un stockage local, soit dans un stockage d'objets selon la [configuration de l'instance GitLab](../../administration/cicd/secure_files.md).

Les fichiers individuels peuvent être récupérés via l'[API de téléchargement des fichiers sécurisés](../../api/secure_files.md#download-a-secure-file). Les métadonnées peuvent être récupérées via les endpoints API [list](../../api/secure_files.md#list-all-secure-files-for-a-project) ou [show](../../api/secure_files.md#retrieve-details-of-a-secure-file). Les fichiers peuvent également être récupérés avec la commande [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile). Cette commande vérifie automatiquement la somme de contrôle de chaque fichier lors de son téléchargement.

Tout membre du projet disposant du rôle Developer, Maintainer ou Owner peut accéder aux fichiers sécurisés au niveau du projet. Les interactions avec les fichiers sécurisés au niveau du projet ne sont pas incluses dans les événements d'audit, mais le [ticket 117](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/117) propose d'ajouter cette fonctionnalité.
