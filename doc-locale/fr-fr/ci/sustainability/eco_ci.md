---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Mesurez la consommation d'énergie et les émissions de carbone de vos pipelines CI/CD avec Eco CI."
title: Eco CI
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Eco CI est un outil tiers qui s'intègre aux pipelines CI/CD GitLab. GitLab ne maintient pas cet outil et n'en assure pas le support, et ne garantit pas que cet outil satisfait à des exigences réglementaires ou de conformité.

[Eco CI](https://www.green-coding.io/products/eco-ci/) est un outil open source qui mesure la consommation d'énergie et les émissions de carbone des pipelines CI/CD. Il s'exécute sous forme de scripts bash légers dans les jobs de votre pipeline et ne nécessite pas de serveurs ni de bases de données distincts.

Vous placez des scripts de mesure avant et après les commandes dans les jobs de votre pipeline. L'outil surveille l'utilisation du CPU pendant l'exécution des commandes et calcule la consommation d'énergie à l'aide de courbes de puissance précalculées issues de la base de données SPECpower. Il stocke tous les résultats de mesure sous forme de fichiers texte que vous pouvez enregistrer en tant qu'artefacts de job pour les télécharger et les consulter. Vous pouvez également envoyer les résultats vers un tableau de bord externe à des fins d'analyse historique.

## Ajouter Eco CI à votre pipeline {#add-eco-ci-to-your-pipeline}

Ajoutez Eco CI à votre pipeline pour mesurer la consommation d'énergie et les émissions de carbone pendant l'exécution des jobs.

Eco CI utilise la variable `ECO_CI_LABEL` pour identifier et regrouper vos mesures. Choisissez un nom descriptif représentant votre projet ou l'étape de votre pipeline. Par défaut, les données de mesure sont envoyées au tableau de bord Green Coding Solutions à des fins d'analyse, mais vous pouvez définir `ECO_CI_SEND_DATA` sur `false` pour stocker les résultats uniquement en local.

Prérequis :

- Les jobs de pipeline qui s'exécutent sur des runners avec prise en charge de bash.
- Un environnement de runner disposant des utilitaires `curl`, `jq`, `awk`, `bash`, `git` et `coreutils`.

Pour ajouter Eco CI à votre pipeline :

1. Dans votre fichier `.gitlab-ci.yml`, incluez le modèle Eco CI et configurez l'identifiant de votre projet :

   ```yaml
   variables:
     ECO_CI_LABEL: "my-project-pipeline"
     ECO_CI_SEND_DATA: "false"

   include:
     - remote: 'https://raw.githubusercontent.com/green-coding-solutions/eco-ci-energy-estimation/main/eco-ci-gitlab.yml'
   ```

1. Ajoutez des scripts de mesure à vos jobs :

   ```yaml
   build-job:
     image: node:alpine
     before_script:
       - apk add --no-cache curl jq gawk bash git coreutils
     script:
       - !reference [.start_measurement, script]
       - npm install
       - npm run build
       - npm test
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]
     artifacts:
       paths:
         - eco-ci-output.txt
         - metrics.txt
       expire_in: 1 week
   ```

1. Facultatif. Pour mesurer les commandes séparément, utilisez des scripts de mesure pour chaque commande :

   ```yaml
   build-job:
     image: node:alpine
     before_script:
       - apk add --no-cache curl jq gawk bash git coreutils
     script:
       - !reference [.start_measurement, script]
       - npm install
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]

       - !reference [.start_measurement, script]
       - npm run build
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]

       - !reference [.start_measurement, script]
       - npm test
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]
     artifacts:
       paths:
         - eco-ci-output.txt
         - metrics.txt
       expire_in: 1 week
   ```

## Afficher les résultats de mesure {#view-measurement-results}

Eco CI stocke les résultats de mesure dans des artefacts de job accessibles via l'interface GitLab. Les résultats de mesure comprennent :

- Consommation d'énergie : Affichée en joules et en watts
- Émissions de carbone : Émissions estimées en grammes d'équivalent CO₂ (gCO₂eq)
- Durée : Durée de la période mesurée en secondes
- Utilisation du CPU : Utilisation moyenne du CPU pendant la mesure
- Software Carbon Intensity (SCI) : Émissions de carbone par exécution de pipeline

Pour afficher les résultats de mesure :

1. Accédez à votre pipeline.
1. Sélectionnez le job qui inclut les mesures Eco CI.
1. Dans les détails du job, sous **Artéfacts de job**, sélectionnez **Parcourir**.
1. Ouvrez le fichier `eco-ci-output.txt`.

Exemple de sortie :

```plaintext
"build-job: Label: my-project-pipeline: Energy Used [Joules]:" 5.82
"build-job: Label: my-project-pipeline: Avg. CPU Utilization:" 22.69
"build-job: Label: my-project-pipeline: Avg. Power [Watts]:" 1.91
"build-job: Label: my-project-pipeline: Duration [seconds]:" 3.04
----------------
"build-job: Energy [Joules]:" 5.82
"build-job: Avg. CPU Utilization:" 22.69
"build-job: Avg. Power [Watts]:" 1.91
"build-job: Duration [seconds]:" 3.04
----------------
🌳 CO2 Data:
CO₂ from energy is: 0.001944 g
CO₂ from manufacturing (embodied carbon) is: 0.000442 g
Carbon Intensity for this location: 334 gCO₂eq/kWh
SCI: 0.002386 gCO₂eq / pipeline run emitted
```

## Intégration au tableau de bord {#dashboard-integration}

Si vous définissez `ECO_CI_SEND_DATA` sur `true`, les données de mesure sont automatiquement envoyées au [tableau de bord des métriques Eco CI](https://metrics.green-coding.io/ci-index.html). Le tableau de bord fournit des historiques, une analyse des tendances et une comparaison entre les exécutions de pipeline. Par défaut, les tableaux de bord sont publics et peuvent être consultés par tout le monde.

Vous pouvez consulter les tendances de consommation d'énergie au fil du temps, les patterns d'émissions de carbone, et comparer les mesures entre différentes branches, commits ou périodes. Accédez au tableau de bord avec l'identifiant `ECO_CI_LABEL` de votre projet.

### Ajouter un badge à votre projet {#add-a-badge-to-your-project}

Vous pouvez afficher un badge Eco CI dans le fichier `README.md` de votre projet pour présenter les métriques de consommation d'énergie.

Prérequis :

- `ECO_CI_SEND_DATA` doit être défini sur `true`.
- Au moins un pipeline doit avoir été exécuté avec succès avec Eco CI activé.

Pour ajouter le badge au fichier `README.md` :

1. Copiez et collez le contenu suivant dans votre fichier `README.md` :

   ```markdown
   [![Eco CI](https://api.green-coding.io/v1/ci/badge/get?repo=<namespace>/<project>&branch=<branch>&workflow=<project-id>)](https://metrics.green-coding.io/ci.html?repo=<namespace>/<project>&branch=<branch>&workflow=<project-id>)
   ```

1. Remplacez les espaces réservés :

   - `<namespace>/<project>` par le chemin de votre projet GitLab (par exemple, `mygroup/myproject`)
   - `<branch>` par le nom de votre branche (par exemple, `main`)
   - `<project-id>` par l'identifiant de votre projet GitLab (par exemple, `52215136`)

Exemple :

```markdown
[![Eco CI](https://api.green-coding.io/v1/ci/badge/get?repo=lyspin/eco-ci-demo&branch=main&workflow=52215136)](https://metrics.green-coding.io/ci.html?repo=lyspin/eco-ci-demo&branch=main&workflow=52215136)
```

## Dépannage {#troubleshooting}

Lorsque vous utilisez Eco CI, vous pouvez rencontrer ces problèmes.

### Erreur : Date has returned a timestamp that is not accurate to microseconds {#error-date-has-returned-a-timestamp-that-is-not-accurate-to-microseconds}

Vous pouvez obtenir un message d'erreur :

```shell
ERROR: Date has returned a timestamp that is not accurate to microseconds! You may need to install `coreutils`.
```

Ce problème survient lors de l'utilisation d'Alpine Linux ou d'autres distributions minimales qui n'incluent pas GNU `coreutils` par défaut.

Pour résoudre ce problème, installez `coreutils`. Par exemple, avec Alpine :

```yaml
before_script:
  - apk add --no-cache coreutils
```

### Aucune donnée de mesure n'apparaît dans les artefacts {#no-measurement-data-appears-in-artifacts}

Le fichier `eco-ci-output.txt` n'apparaît pas dans vos artefacts de job.

Ce problème peut être causé par une configuration des artefacts manquante. Vérifiez que votre job contient la configuration `artifacts` correcte :

```yaml
artifacts:
  paths:
    - eco-ci-output.txt
    - metrics.txt
```

### Les mesures affichent une consommation d'énergie nulle {#measurements-show-zero-energy-consumption}

Votre fichier `eco-ci-output.txt` affiche des valeurs telles que `Energy [Joules]: 0.00`.

Ce problème survient lorsque les scripts de mesure sont mal positionnés.

Pour résoudre ce problème, vérifiez que les scripts de mesure encadrent les commandes gourmandes en CPU :

```yaml
script:
  - !reference [.start_measurement, script]
  - npm install  # CPU-intensive command
  - npm run build  # CPU-intensive command
  - !reference [.get_measurement, script]
  - !reference [.display_results, script]
```
