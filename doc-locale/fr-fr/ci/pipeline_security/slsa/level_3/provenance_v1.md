---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Spécification de provenance SLSA
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com
- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/547865) dans GitLab 18.3 [avec un indicateur](../../../../administration/feature_flags/_index.md) nommé `slsa_provenance_statement`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

La [spécification de provenance SLSA](https://slsa.dev/spec/v1.1/provenance) exige que la référence `buildType` soit documentée et publiée. Cette référence est destinée à aider les consommateurs des attestations SLSA de GitLab à analyser les champs spécifiques qui sont propres aux déclarations de provenance SLSA de GitLab.

Consultez la [documentation `buildType`](https://slsa.dev/spec/v1.1/provenance#builddefinition) de SLSA pour plus de détails.

## `buildType` {#buildtype}

Cette référence officielle [SLSA Provenance](https://slsa.dev/spec/v1.1/provenance) `buildType` :

- Décrit l'exécution d'un [job CI/CD](_index.md) GitLab.
- Est hébergée et maintenue par GitLab.

### Description {#description}

Ce `buildType` décrit l'exécution d'un workflow qui génère un artefact logiciel.

> [!note]
> Les consommateurs doivent ignorer les paramètres externes non reconnus. Toute modification ne doit pas changer la sémantique des paramètres externes existants.

### Paramètres externes {#external-parameters}

Les paramètres externes :

| Champ        | Valeur |
|--------------|-------|
| `source`     | L'URL du projet. |
| `entryPoint` | Le nom du job CI/CD qui a déclenché la build. |
| `variables`  | Les noms et valeurs de toutes les variables CI/CD ou d'environnement disponibles lors de l'exécution de la commande de build. Si la variable est [masquée ou cachée](../../../variables/_index.md), la valeur de la variable est définie sur `[MASKED]`. |

### Paramètres internes {#internal-parameters}

Les paramètres internes, qui sont renseignés par défaut :

| Champ          | Valeur |
|----------------|-------|
| `name`         | Le nom du runner. |
| `executor`     | L'exécuteur du runner. |
| `architecture` | L'architecture sur laquelle le job CI/CD est exécuté. |
| `job`          | L'ID du job CI/CD qui a déclenché la build. |

### Exemple {#example}

Cet exemple illustre le format d'une déclaration de provenance générée par GitLab :

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    {
      "name": "artifacts.zip",
      "digest": {
        "sha256": "717a1ee89f0a2829cf5aad57054c83615675b04baa913bdc19999d7519edf3f2"
      }
    }
  ],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": {
    "buildDefinition": {
      "buildType": "<Link to Build Type>",
      "externalParameters": {
        "source": "http://gdk.test:3000/root/repo_name",
        "entryPoint": "build-job",
        "variables": {
          "CI_PIPELINE_ID": "576",
          "CI_PIPELINE_URL": "http://gdk.test:3000/root/repo_name/-/pipelines/576",
          "CI_JOB_ID": "412",

          [... additional environment variables ...]

          "masked_and_hidden_variable": "[MASKED]",
          "masked_variable": "[MASKED]",
          "visible_variable": "visible_variable",
        }
      },
      "internalParameters": {
        "architecture": "arm64",
        "executor": "docker",
        "job": 412,
        "name": "9-mfdkBG"
      },
      "resolvedDependencies": [
        {
          "uri": "http://gdk.test:3000/root/repo_name",
          "digest": {
            "gitCommit": "a288201509dd9a85da4141e07522bad412938dbe"
          }
        }
      ]
    },
    "runDetails": {
      "builder": {
        "id": "http://gdk.test:3000/groups/user/-/runners/33",
        "version": {
          "gitlab-runner": "4d7093e1"
        }
      },
      "metadata": {
        "invocationId": 412,
        "startedOn": "2025-06-05T01:33:18Z",
        "finishedOn": "2025-06-05T01:33:23Z"
      }
    }
  }
}
```
