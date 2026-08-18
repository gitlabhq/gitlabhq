---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Créez, téléchargez, parcourez et gérez les artefacts de job dans GitLab CI/CD."
title: Artefacts de job
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les jobs peuvent générer une archive de fichiers et de répertoires. Cette sortie est appelée artefact de job. Les artefacts peuvent inclure des fichiers de sortie de build ou des fichiers de rapport. Par défaut, les jobs ultérieurs récupèrent une copie de tous les artefacts des jobs des étapes précédentes.

Par exemple, un job précoce peut builder un projet et enregistrer la sortie en tant qu'artefact. Ensuite, un job ultérieur récupère l'artefact et exécute des tests sur la sortie de build enregistrée.

Pour obtenir la liste complète des configurations prises en charge pour le mot-clé `artifacts`, consultez la [référence de syntaxe YAML GitLab CI/CD](../yaml/_index.md#artifacts).

Sujets connexes :

- [API Artefacts de job](../../api/job_artifacts.md)
- [Administration des artefacts de job](../../administration/cicd/job_artifacts.md)

## Créer des artefacts de job {#create-job-artifacts}

Pour créer des artefacts de job, utilisez le mot-clé `artifacts` dans votre fichier `.gitlab-ci.yml` :

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
```

Dans cet exemple, un job nommé `pdf` appelle la commande `xelatex` pour créer un fichier PDF à partir du fichier source LaTeX `mycv.tex`.

Le mot-clé `paths` détermine les fichiers à ajouter aux artefacts de job. Tous les chemins d'accès aux fichiers et répertoires sont relatifs au dépôt dans lequel le job a été créé.

### Avec des caractères génériques {#with-wildcards}

Vous pouvez utiliser des caractères génériques pour les chemins et les répertoires. Par exemple, pour créer un artefact avec tous les fichiers dans les répertoires qui se terminent par `xyz` :

```yaml
job:
  script: echo "build xyz project"
  artifacts:
    paths:
      - path/*xyz/*
```

### Avec une expiration {#with-an-expiry}

Le mot-clé `expire_in` détermine la durée pendant laquelle GitLab conserve les artefacts définis dans `artifacts:paths`. Par exemple :

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
    expire_in: 1 week
```

Si `expire_in` n'est pas défini, le paramètre d'instance [**Expiration par défaut des artéfacts**](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration) est utilisé.

Pour empêcher l'expiration des artefacts, vous pouvez sélectionner **Garder** depuis la page de détails du job. Cette option n'est pas disponible lorsqu'un artefact n'a pas de date d'expiration définie.

Par défaut, les artefacts sont toujours conservés pour le pipeline réussi le plus récent sur chaque ref.

### Avec un nom d'artefact explicitement défini {#with-an-explicitly-defined-artifact-name}

Vous pouvez personnaliser explicitement les noms des artefacts à l'aide de la configuration `artifacts:name` :

```yaml
job:
  artifacts:
    name: "job1-artifacts-file"
    paths:
      - binaries/
```

### Sans fichiers exclus {#without-excluded-files}

Utilisez `artifacts:exclude` pour empêcher l'ajout de fichiers à une archive d'artefacts.

Par exemple, pour stocker tous les fichiers dans `binaries/`, mais pas les fichiers `*.o` situés dans les sous-répertoires de `binaries/` :

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

Contrairement à `artifacts:paths`, les chemins `exclude` ne sont pas récursifs. Pour exclure tout le contenu d'un répertoire, faites-y correspondre les éléments explicitement plutôt que de faire correspondre le répertoire lui-même.

Par exemple, pour stocker tous les fichiers dans `binaries/` mais rien situé dans le sous-répertoire `temp/` :

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/temp/**/*
```

### Avec des fichiers non suivis {#with-untracked-files}

Utilisez `artifacts:untracked` pour ajouter tous les fichiers Git non suivis en tant qu'artefacts, en plus des chemins définis dans `artifacts:paths`. Les fichiers non suivis sont ceux qui n'ont pas été ajoutés au dépôt mais qui existent dans l'extraction du dépôt.

Par exemple, pour enregistrer tous les fichiers Git non suivis et les fichiers dans `binaries` :

```yaml
artifacts:
  untracked: true
  paths:
    - binaries/
```

Par exemple, pour enregistrer tous les fichiers non suivis mais exclure les fichiers `*.txt` :

```yaml
artifacts:
  untracked: true
  exclude:
    - "*.txt"
```

### Avec l'expansion de variables {#with-variable-expansion}

L'expansion de variables est prise en charge pour `artifacts:name`, `artifacts:paths` et `artifacts:exclude`.

Au lieu d'utiliser le shell, GitLab Runner utilise son mécanisme interne d'expansion de variables. Seules les variables CI/CD sont prises en charge dans ce contexte.

Par exemple, pour créer une archive en utilisant le nom de la branche ou du tag actuel, en incluant uniquement les fichiers d'un répertoire portant le nom du projet actuel :

```yaml
job:
  artifacts:
    name: "$CI_COMMIT_REF_NAME"
    paths:
      - binaries/${CI_PROJECT_NAME}/
```

Lorsque le nom de votre branche contient des barres obliques (par exemple, `feature/my-feature`), utilisez `$CI_COMMIT_REF_SLUG` à la place de `$CI_COMMIT_REF_NAME` pour assurer un nommage correct des artefacts.

Les variables sont développées avant les globs.

## Récupération des artefacts {#fetching-artifacts}

Par défaut, les jobs récupèrent tous les artefacts des jobs définis dans les étapes précédentes. Ces artefacts sont téléchargés dans le répertoire de travail du job.

Vous pouvez contrôler les artefacts à télécharger en utilisant les mots-clés `dependencies` ou `needs:artifacts`.

Lorsque vous utilisez ces mots-clés, le comportement par défaut change et les artefacts sont récupérés uniquement depuis les jobs que vous spécifiez.

### Empêcher un job de récupérer des artefacts {#prevent-a-job-from-fetching-artifacts}

Pour empêcher un job de télécharger des artefacts, définissez `dependencies` sur un tableau vide (`[]`) :

```yaml
job:
  stage: test
  script: make build
  dependencies: []
```

## Afficher tous les artefacts de job dans un projet {#view-all-job-artifacts-in-a-project}

Vous pouvez afficher tous les artefacts stockés dans un projet depuis la page **Version** > **Artéfacts**. Cette liste affiche tous les jobs et leurs artefacts associés. Développez une entrée pour accéder à tous les artefacts associés à un job, notamment :

- Les artefacts créés avec le mot-clé `artifacts:`.
- Les artefacts de rapport.
- Les job logs et métadonnées, qui sont stockés en interne en tant qu'artefacts distincts.

Vous pouvez télécharger ou supprimer des artefacts individuels depuis cette liste.

## Télécharger des artefacts de job {#download-job-artifacts}

Vous pouvez télécharger des artefacts de job via l'interface GitLab ou l'API.

Depuis l'interface GitLab, vous pouvez télécharger des artefacts de job depuis :

- N'importe quelle liste **Pipelines**. À droite du pipeline, sélectionnez **Télécharger les artéfacts** ({{< icon name="download" >}}).
- N'importe quelle liste **Jobs**. À droite du job, sélectionnez **Télécharger les artéfacts** ({{< icon name="download" >}}).
- La page de détails d'un job. À droite de la page, sélectionnez **Télécharger**.
- La page **Vue d'ensemble** d'une merge request. À droite du dernier pipeline, sélectionnez **Artéfacts** ({{< icon name="download" >}}).
- La page **Artéfacts**. À droite du job, sélectionnez **Télécharger** ({{< icon name="download" >}}).
- Le navigateur d'artefacts. En haut de la page, sélectionnez **Télécharger l'archive des artéfacts** ({{< icon name="download" >}}).

Les [artefacts de rapport](../yaml/artifacts_reports.md) ne peuvent être téléchargés qu'à partir de la liste **Pipelines** ou de la page **Artéfacts**.

### Depuis une URL {#from-a-url}

Vous pouvez télécharger l'archive des artefacts pour un job spécifique via une URL accessible publiquement.

Par exemple, pour télécharger les derniers artefacts d'un job nommé `build` dans la branche `main` d'un projet sur GitLab.com :

```plaintext
https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/download?job=build
```

Pour télécharger un fichier spécifique depuis les artefacts :

```plaintext
https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/raw/review/index.html?job=build
```

Les fichiers renvoyés par cet endpoint ont toujours le type de contenu `plain/text`.

Dans les deux exemples, remplacez `<project-id>` par un ID de projet valide. Vous pouvez trouver l'ID du projet sur la [page de présentation du projet](../../user/project/working_with_projects.md#find-the-project-id).

Les artefacts des pipelines parent et enfant sont recherchés dans un ordre hiérarchique du parent vers l'enfant. Par exemple, si les pipelines parent et enfant ont tous deux un job avec le même nom, les artefacts de job du pipeline parent sont renvoyés.

### Avec un jeton de job CI/CD {#with-a-cicd-job-token}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser un jeton de job CI/CD pour vous authentifier auprès de l'endpoint de l'API des artefacts de job et récupérer des artefacts depuis un pipeline différent. Vous devez spécifier le job à partir duquel récupérer les artefacts, par exemple :

```yaml
build_submodule:
  stage: test
  script:
    - apt update && apt install -y unzip
    - |
      curl --location --output artifacts.zip \
        --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"
    - unzip artifacts.zip
```

Pour récupérer des artefacts d'un job dans le même pipeline, utilisez le mot-clé `needs:artifacts`.

### Contrôler qui peut télécharger les artefacts {#control-who-can-download-artifacts}

Pour restreindre qui peut télécharger les artefacts de job, utilisez le mot-clé `artifacts:access` dans votre fichier `.gitlab-ci.yml`. Par exemple :

```yaml
job:
  artifacts:
    access: maintainer
    paths:
      - build/
```

## Parcourir le contenu de l'archive des artefacts {#browse-the-contents-of-the-artifacts-archive}

Vous pouvez parcourir le contenu des artefacts depuis l'interface sans télécharger l'artefact localement, depuis :

- N'importe quelle liste **Jobs**. À droite du job, sélectionnez **Parcourir** ({{< icon name="folder-open" >}}).
- La page de détails d'un job. À droite de la page, sélectionnez **Parcourir**.
- La page **Artéfacts**. À droite du job, sélectionnez **Parcourir** ({{< icon name="folder-open" >}}).

Si GitLab Pages est activé globalement, même s'il est désactivé dans les paramètres du projet, vous pouvez prévisualiser certaines extensions de fichiers d'artefacts directement dans votre navigateur. Si le projet est interne ou privé, vous devez activer le contrôle d'accès GitLab Pages pour activer la prévisualisation.

Les extensions suivantes sont prises en charge :

| Extension de fichier | GitLab.com  | Package Linux avec NGINX intégré |
|----------------|-------------|-----------------------------------|
| `.html`        | {{< yes >}} | {{< yes >}}                       |
| `.json`        | {{< yes >}} | {{< yes >}}                       |
| `.xml`         | {{< yes >}} | {{< yes >}}                       |
| `.txt`         | {{< no >}}  | {{< yes >}}                       |
| `.log`         | {{< no >}}  | {{< yes >}}                       |

### Depuis une URL {#from-a-url-1}

Vous pouvez parcourir les artefacts de job du dernier pipeline réussi pour un job spécifique via une URL accessible publiquement.

Par exemple, pour parcourir les derniers artefacts d'un job nommé `build` dans la branche `main` d'un projet sur GitLab.com :

```plaintext
https://gitlab.com/<full-project-path>/-/jobs/artifacts/main/browse?job=build
```

Remplacez `<full-project-path>` par un chemin de projet valide ; vous pouvez le trouver dans l'URL de votre projet.

## Définir la taille maximale des artefacts {#set-the-maximum-artifacts-size}

Définissez des limites de taille pour les artefacts de job afin de contrôler l'utilisation du stockage. Chaque fichier d'artefact dans un job a une taille maximale par défaut de 100 Mo.

> [!note]
> Ce paramètre s'applique à la taille du fichier d'archive final, pas aux fichiers individuels dans un job.

Vous pouvez configurer les limites de taille des artefacts pour :

- [Une instance](../../administration/cicd/limits.md#maximum-artifacts-size) : Le paramètre de base qui s'applique à tous les projets et groupes.
- Un groupe : Remplace le paramètre d'instance pour tous les projets du groupe.
- Un projet : Remplace à la fois les paramètres d'instance et de groupe pour un projet spécifique.

Pour modifier la taille maximale des artefacts pour un groupe ou un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet ou groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Pipelines généraux**.
1. Modifiez la valeur de **Taille maximale des artéfacts** (en Mo).
1. Sélectionnez **Sauvegarder les modifications**.

## Supprimer le job log et les artefacts {#delete-job-log-and-artifacts}

> [!warning]
> La suppression du job log et des artefacts est une action destructrice qui ne peut pas être annulée. Procédez avec précaution. La suppression de certains fichiers, notamment les artefacts de rapport, les job logs et les fichiers de métadonnées, affecte les fonctionnalités GitLab qui utilisent ces fichiers comme sources de données.

Vous pouvez supprimer les artefacts et le job log d'un job.

Prérequis :

- Vous devez être le propriétaire du job ou un utilisateur disposant du rôle Maintainer ou Owner pour le projet.

Pour supprimer un job :

1. Accédez à la page de détails d'un job.
1. Dans le coin supérieur droit du job log, sélectionnez **Effacer le job log et les artéfacts** ({{< icon name="remove" >}}).

Vous pouvez également supprimer des artefacts individuels depuis la page **Artéfacts**.

### Suppression groupée des artefacts {#bulk-delete-artifacts}

Vous pouvez supprimer plusieurs artefacts en même temps :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Artéfacts**.
1. Cochez les cases en regard des artefacts que vous souhaitez supprimer. Vous pouvez sélectionner jusqu'à 100 artefacts.
1. Sélectionnez **Supprimer la sélection**.

## Lier des artefacts de job dans l'interface des merge requests {#link-to-job-artifacts-in-the-merge-request-ui}

Utilisez le mot-clé `artifacts:expose_as` pour fournir un accès direct aux artefacts depuis l'interface des merge requests.

Par exemple, pour un artefact avec un seul fichier :

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

Avec cette configuration, la section **Voir l'artéfact exposé** affiche un lien vers `file.txt` intitulé **artifact 1**.

![Widget de merge request liant les artefacts exposés.](img/mr_artifact_expose_v18_4.png)

## Conserver les artefacts des jobs réussis les plus récents {#keep-artifacts-from-most-recent-successful-jobs}

Par défaut, les artefacts sont toujours conservés pour le pipeline réussi le plus récent sur chaque ref. Toute configuration `expire_in` ne s'applique pas aux artefacts les plus récents.

Lorsqu'un nouveau pipeline sur le même ref se termine avec succès, les artefacts du pipeline précédent sont supprimés selon la configuration `expire_in`. Les artefacts du nouveau pipeline sont conservés automatiquement.

Les artefacts d'un pipeline ne sont supprimés selon la configuration `expire_in` que si un nouveau pipeline s'exécute pour le même ref et :

- Réussit.
- Cesse de s'exécuter en raison d'un blocage par un job manuel.

Conserver les derniers artefacts peut utiliser une grande quantité d'espace de stockage dans les projets comportant de nombreux jobs ou de grands artefacts. Si les derniers artefacts ne sont pas nécessaires dans un projet, vous pouvez désactiver ce comportement pour économiser de l'espace :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Artéfacts**.
1. Décochez la case **Conserver les artéfacts des jobs réussis les plus récents**.

Après avoir désactivé ce paramètre, tous les nouveaux artefacts expirent selon la configuration `expire_in`. Les artefacts des anciens pipelines continuent d'être conservés jusqu'à ce qu'un nouveau pipeline s'exécute pour le même ref. Les artefacts du pipeline antérieur pour ce ref sont alors également autorisés à expirer.

Vous pouvez désactiver ce comportement pour tous les projets sur GitLab Self-Managed avec le paramètre d'instance [**Keep artifacts from latest successful pipelines**](../../administration/settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines).

Vous pouvez désactiver ce comportement pour tous les projets sur GitLab Self-Managed dans les [paramètres CI/CD de l'instance](../../administration/settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines).

## Sujets connexes {#related-topics}

- [Transmettre des variables d'environnement entre les jobs avec les artefacts de rapport dotenv](../variables/dotenv_variables.md)
