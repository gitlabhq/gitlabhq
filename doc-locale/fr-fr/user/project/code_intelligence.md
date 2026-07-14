---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Intelligence du code
description: "Configurez l'intelligence de code à l'aide d'indexeurs LSIF ou SCIP pour activer les fonctionnalités de navigation dans le code."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'intelligence de code ajoute des fonctionnalités de navigation dans le code communes aux environnements de développement interactifs (IDE), notamment :

- Signatures de types et documentation des symboles.
- Aller à la définition.

L'intelligence de code est intégrée à GitLab et repose sur [LSIF](https://lsif.dev/) (Language Server Index Format), un format de fichier pour les données d'intelligence de code précalculées. GitLab traite un seul fichier LSIF par projet, et l'intelligence de code ne prend pas en charge différents fichiers LSIF par branche.

[SCIP](https://github.com/sourcegraph/scip/) représente la prochaine évolution des outils d'indexation du code source. Vous pouvez l'utiliser pour alimenter les fonctionnalités de navigation dans le code, telles que :

- Aller à la définition
- Trouver des références

GitLab ne prend pas nativement en charge SCIP pour l'intelligence de code. Cependant, vous pouvez utiliser le [SCIP CLI](https://github.com/sourcegraph/scip/blob/main/docs/CLI.md) pour convertir les index générés avec les outils SCIP en un fichier compatible LSIF. Pour les discussions sur la prise en charge native de SCIP, consultez [l'issue 412981](https://gitlab.com/gitlab-org/gitlab/-/issues/412981).

Pour suivre l'avancement des améliorations à venir de l'intelligence de code, consultez l'[epic 4212](https://gitlab.com/groups/gitlab-org/-/epics/4212).

## Configurer l'intelligence de code {#configure-code-intelligence}

Prérequis :

- Vous avez vérifié qu'il existe un indexeur compatible pour les langages de votre projet :
  - [Indexeurs LSIF](https://lsif.dev/#implementations-server)
  - [Indexeurs SCIP](https://github.com/sourcegraph/scip/#tools-using-scip)

Pour savoir comment votre langage est le mieux pris en charge, consultez les [indexeurs recommandés par Sourcegraph](https://sourcegraph.com/docs/code-search/code-navigation/writing_an_indexer#sourcegraph-recommended-indexers).

### Avec le composant CI/CD {#with-the-cicd-component}

{{< history >}}

- La prise en charge de Python a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/301111) dans GitLab 17.9.
- La prise en charge de .Net/C# a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/372243) dans GitLab 18.0.

{{< /history >}}

GitLab fournit un [composant CI/CD](../../ci/components/_index.md) pour configurer l'intelligence de code dans votre fichier `.gitlab-ci.yml`. Le composant prend en charge les langages suivants :

- Go version 1.21 ou ultérieure.
- TypeScript ou JavaScript.
- Java 8, 11, 17 et 21.
- Python
- .Net/C#

Pour contribuer d'autres langages au composant, ouvrez une merge request dans le [projet du composant d'intelligence de code](https://gitlab.com/components/code-intelligence).

1. Ajoutez un composant CI/CD GitLab à votre fichier `.gitlab-ci.yml` du projet. Par exemple, ce job génère l'artefact LSIF pour Go :

   ```yaml
   include:
     - component: ${CI_SERVER_FQDN}/components/code-intelligence/golang-code-intel@v0.0.3
       inputs:
         golang_version: ${GO_VERSION}
   ```

1. Pour obtenir les instructions de configuration du [composant d'intelligence de code](https://gitlab.com/components/code-intelligence), consultez le `README` pour chaque langage pris en charge.
1. Pour plus d'informations, consultez [utiliser un composant](../../ci/components/_index.md#use-a-component).

### Ajouter des jobs CI/CD pour l'intelligence de code {#add-cicd-jobs-for-code-intelligence}

Pour activer l'intelligence de code pour un projet, ajoutez des jobs GitLab CI/CD à votre fichier `.gitlab-ci.yml` du projet.

{{< tabs >}}

{{< tab title="Avec un indexeur SCIP" >}}

1. Ajoutez un job à votre configuration `.gitlab-ci.yml`. Ce job génère l'index SCIP et le convertit en LSIF pour utilisation dans GitLab :

   ```yaml
   "code_navigation":
      rules:
      - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH # the job only needs to run against the default branch
      image: node:latest
      stage: test
      allow_failure: true # recommended
      script:
         - npm install -g @sourcegraph/scip-typescript
         - npm install
         - scip-typescript index
         - |
            env \
            TAG="v0.4.0" \
            OS="$(uname -s | tr '[:upper:]' '[:lower:]')" \
            ARCH="$(uname -m | sed -e 's/x86_64/amd64/')" \
            bash -c 'curl --location "https://github.com/sourcegraph/scip/releases/download/$TAG/scip-$OS-$ARCH.tar.gz"' \
            | tar xzf - scip
         - chmod +x scip
         - ./scip convert --from index.scip --to dump.lsif
      artifacts:
         reports:
            lsif: dump.lsif
   ```

1. Selon votre configuration CI/CD, vous pourriez avoir besoin d'exécuter le job manuellement, ou d'attendre qu'il s'exécute dans le cadre d'un pipeline existant.

{{< /tab >}}

{{< tab title="Avec un indexeur LSIF" >}}

1. Ajoutez un job (`code_navigation`) à votre configuration `.gitlab-ci.yml` pour générer l'index :

   ```yaml
   code_navigation:
      rules:
      - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH # the job only needs to run against the default branch
     image: sourcegraph/lsif-go:v1
     allow_failure: true # recommended
     script:
       - lsif-go
     artifacts:
       reports:
         lsif: dump.lsif
   ```

1. Selon votre configuration CI/CD, vous pourriez avoir besoin d'exécuter le job manuellement, ou d'attendre qu'il s'exécute dans le cadre d'un pipeline existant.

{{< /tab >}}

{{< /tabs >}}

> [!note]
> GitLab limite l'artefact produit par les jobs de génération de code à 200 Mo via la limite d'application d'artefact [(`ci_max_artifact_size_lsif`)](../../administration/cicd/limits.md#maximum-file-size-per-type-of-artifact). Sur les instances GitLab Self-Managed, un administrateur d'instance peut modifier cette valeur.

## Afficher les résultats de l'intelligence de code {#view-code-intelligence-results}

Une fois le job terminé avec succès, parcourez votre dépôt pour consulter les informations d'intelligence de code :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Dépôt**.
1. Accédez au fichier dans votre dépôt. Si vous connaissez le nom du fichier, effectuez l'une des actions suivantes :
   - Saisissez le raccourci clavier `/~` pour ouvrir le sélecteur de fichiers, puis saisissez le nom du fichier.
   - En haut à droite, sélectionnez **Rechercher un fichier**.
1. Pointez sur les lignes de code. Les éléments de cette ligne disposant d'informations issues de l'intelligence de code affichent une ligne pointillée en dessous :

   ![Intelligence du code](img/code_intelligence_v17_0.png)

1. Sélectionnez l'élément pour en savoir plus à son sujet.

## Trouver des références {#find-references}

Utilisez l'intelligence de code pour voir toutes les utilisations d'un objet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Dépôt**.
1. Accédez au fichier dans votre dépôt. Si vous connaissez le nom du fichier, effectuez l'une des actions suivantes :
   - Saisissez le raccourci clavier `/~` pour ouvrir le sélecteur de fichiers, puis saisissez le nom du fichier.
   - En haut à droite, sélectionnez **Rechercher un fichier**.
1. Pointez sur l'objet, puis sélectionnez-le.
1. Dans la boîte de dialogue, sélectionnez :
   - **Définition** pour voir une définition de cet objet.
   - **Références** pour afficher la liste des fichiers qui utilisent cet objet.

   ![Cette variable est référencée deux fois dans ce projet.](img/code_intelligence_refs_v17_6.png)
