---
stage: Application Security Testing
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Rapports SARIF
description: Ajoutez des résultats provenant de scanners SARIF tiers dans la gestion des vulnérabilités GitLab.
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/452042) dans GitLab 18.11 [avec un indicateur](../../../administration/feature_flags/_index.md) nommé `sarif_ingestion`. Désactivée par défaut.
- Activé par défaut dans GitLab 19.1.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/602748) dans GitLab 19.2. L'indicateur de fonctionnalité `sarif_ingestion` a été supprimé.

{{< /history >}}

Utilisez des rapports SARIF tiers pour ajouter des résultats provenant de n'importe quel scanner [SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html) dans la gestion des vulnérabilités GitLab. Un job CI/CD exécute un scanner produisant du SARIF et ajoute un artefact SARIF. GitLab analyse, valide et ajoute les artefacts en tant que résultats de sécurité.

Une fois le rapport ajouté, les résultats apparaissent aux côtés des résultats des scanners GitLab natifs dans les pages suivantes :

- L'onglet **Sécurité** du pipeline
- Le rapport de vulnérabilités du projet
- Le tableau de bord de sécurité
- Le widget de sécurité de la merge request
- Politiques de sécurité

Les rapports SARIF tiers complètent les scanners intégrés proposés par GitLab. Utilisez-les pour intégrer un scanner tiers que GitLab ne fournit pas nativement, ou pour consolider les résultats d'un outil que vous utilisez déjà.

## Ajouter des rapports SARIF {#add-sarif-reports}

Pour ajouter des résultats SARIF dans GitLab :

Prérequis :

- Le rôle Chargé de maintenance ou Propriétaire pour le projet.
- Un job CI/CD qui produit un fichier SARIF 2.1.0.

1. Dans votre fichier `.gitlab-ci.yml`, définissez un job qui exécute le scanner et enregistre sa sortie SARIF en tant qu'artefact `artifacts:reports:sarif`. Exemple :

   ```yaml
   sarif_scan:
     image: <scanner-image>
     script:
       - <scanner-command> --output sarif.json
     artifacts:
       reports:
         sarif: sarif.json
   ```

1. Committez et poussez la modification. GitLab analyse le fichier SARIF à la fin du job.
1. Consultez les résultats ajoutés dans l'onglet **Sécurité** du pipeline.

Pour la référence des artefacts CI/CD, consultez [`artifacts:reports:sarif`](../../../ci/yaml/artifacts_reports.md#artifactsreportssarif).

## Types de rapports attribués {#assigned-report-types}

GitLab attribue un type de rapport de vulnérabilité pour chaque résultat SARIF en fonction de l'emplacement et des identifiants du résultat. Le type détermine l'endroit où le résultat apparaît dans le rapport de vulnérabilité et la manière dont il interagit avec les politiques de sécurité.

GitLab évalue les règles suivantes dans l'ordre et attribue le premier type correspondant au résultat.

| Règle                                                                                         | Type de rapport attribué |
|----------------------------------------------------------------------------------------------|----------------------|
| Tout identifiant est un CVE.                                                                     | Analyse des dépendances  |
| Tout identifiant est un CWE lié aux secrets. <sup>1</sup>                                         | Détection des secrets     |
| Par défaut (aucune règle ne correspond)                                                          | SAST                 |

**Notes de bas de page :**

1. Les CWE suivants sont liés aux secrets :

   - [CWE-798 (Hard-coded credentials)](https://cwe.mitre.org/data/definitions/798.html).
   - [CWE-259 (Hard-coded password)](https://cwe.mitre.org/data/definitions/259.html).
   - [CWE-321 (Hard-coded cryptographic key)](https://cwe.mitre.org/data/definitions/321.html).
   - [CWE-522 (Insufficiently protected credentials)](https://cwe.mitre.org/data/definitions/522.html).
   - [CWE-312 (Cleartext storage of sensitive information)](https://cwe.mitre.org/data/definitions/312.html).
   - [CWE-319 (Cleartext transmission of sensitive information)](https://cwe.mitre.org/data/definitions/319.html).
   - [CWE-256 (Plaintext storage of a password)](https://cwe.mitre.org/data/definitions/256.html).
   - [CWE-257 (Storing passwords in a recoverable format)](https://cwe.mitre.org/data/definitions/257.html).
   - [CWE-540 (Inclusion of sensitive information in source code)](https://cwe.mitre.org/data/definitions/540.html).

GitLab lit les identifiants à partir de trois sources dans un résultat et sa règle, dans cet ordre :

1. `result.ruleId` lorsque l'entrée correspond au format `CVE-YYYY-N` ou `CWE-N`.
1. `rule.properties.tags[]` lorsque l'entrée correspond au format `cwe:N`, `cwe-N`, `cve:YYYY-N` ou `cve-YYYY-N`.
1. `rule.relationships[]` lorsque le `target.toolComponent.name` de la relation est `CWE`.

> [!note]
> Les résultats sans CVE ni identifiant CWE pris en charge sont attribués en tant que SAST. Pour modifier le type attribué par GitLab, configurez votre scanner afin qu'il émette un identifiant CVE ou CWE correspondant.

## Correspondance des champs SARIF {#sarif-field-mapping}

GitLab attribue les champs SARIF aux champs compatibles avec GitLab selon les règles suivantes.

| Champ GitLab          | Source SARIF                                                                          | Obligatoire    | Notes                                                                                                                                         |
|-----------------------|---------------------------------------------------------------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Gravité              | Voir [Résolution de la gravité](#severity-resolution)                                       | {{< no >}}  | Par défaut `medium` lorsqu'aucun champ de gravité n'est défini.                                                                                           |
| Identifiant principal    | `result.ruleId` est mis en correspondance avec la valeur correspondante dans `run.tool.driver.rules[].id` | {{< yes >}} | Les résultats sans `ruleId` ne sont pas ajoutés.                                                                                                    |
| Identifiants secondaires | `rule.properties.tags[]` et `rule.relationships[]`                                   | {{< no >}}  | Utilisé pour attribuer le type de rapport.                                                                                                               |
| Emplacement              | `result.locations[0].physicalLocation`                                                | {{< yes >}} | Les résultats sans emplacement physique ne sont pas ajoutés.                                                                                           |
| Nom du scanner          | `run.tool.driver.name`                                                                | {{< yes >}} | Requis pour un [SARIF valide](https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790791) |
| Éditeur du scanner        | `run.tool.driver.organization`, puis `run.tool.driver.informationUri`                 | {{< no >}}  | La première valeur non vide est utilisée                                                                                                                 |
| Version du scanner       | `run.tool.driver.version`, puis `run.tool.driver.semanticVersion`                     | {{< no >}}  | La première valeur non vide est utilisée                                                                                                                 |
| Suppression           | `result.suppressions[]`                                                               | {{< no >}}  | Les résultats supprimés sont ignorés, sauf si chaque suppression est `underReview` ou `rejected`.                                                       |

## Résolution de la gravité {#severity-resolution}

GitLab résout la gravité d'un résultat SARIF en vérifiant les champs suivants par ordre de priorité. Le premier champ ayant une valeur est utilisé.

1. `result.rank`. Un flottant de `0.0` à `100.0`.
1. `rule.properties.security-severity`. Un flottant de `0.0` à `10.0`. La valeur est multipliée par 10 avant le regroupement en plages.
1. `result.properties.security-severity`. Un flottant de `0.0` à `10.0`. La valeur est multipliée par 10 avant le regroupement en plages.
1. `result.level`.
1. `rule.defaultConfiguration.level`.
1. `medium` par défaut si aucune autre correspondance n'est trouvée.

Les scores numériques issus de `result.rank` ou `security-severity` sont attribués comme gravités selon les plages suivantes :

| Score (0-100) | Gravité |
|---------------|----------|
| `0.0`-`9.9`   | Info     |
| `10.0`-`39.9` | Faible      |
| `40.0`-`69.9` | Moyen   |
| `70.0`-`89.9` | Élevé     |
| `90.0`-`100`  | Critique |

Les valeurs `level` SARIF sont mappées comme suit :

| `level`   | Gravité |
|-----------|----------|
| `error`   | Élevé     |
| `warning` | Moyen   |
| `note`    | Faible      |
| `none`    | Info     |

> [!note]
> GitLab attribue `level: error` à élevé, et non à critique. Pour signaler un résultat critique, définissez `result.rank` à `90` ou plus, ou définissez `security-severity` à `9.0` ou plus.

## Comportement d'ingestion {#ingestion-behavior}

Lorsque le fichier SARIF est bien formé mais que certains résultats ne peuvent pas être ajoutés, GitLab utilise le pourcentage de résultats qu'il n'a pas pu traiter pour décider de la marche à suivre pour l'analyse dans son ensemble.

| Taux de rejet     | Comportement                                                | Signalé comme           |
|---------------|---------------------------------------------------------|------------------------|
| 0 %            | Tous les résultats sont ingérés.                              | Aucun message.            |
| 1 % à 50 %     | Les résultats valides sont ingérés.                        | Avertissement avec le nombre de rejets. |
| Plus de 50 % | L'analyse entière échoue. Aucun résultat du rapport n'est ingéré. | Erreur avec le nombre de rejets.   |

GitLab ne peut pas traiter un résultat dans les cas suivants :

- Le `ruleId` est manquant.
- Le `physicalLocation` est manquant.
- L'un des composants requis pour générer l'identifiant du résultat est nul.
- Un champ de type chaîne dépasse sa [limite de caractères](#limits).

Le taux de rejet est calculé sur l'ensemble de l'artefact SARIF, et non pour chaque `run` dans le fichier. Lorsque la part de résultats non traitables sur l'ensemble des exécutions dépasse le seuil, le retour d'information sur l'ingestion est appliqué à chaque rapport émis depuis l'artefact.

Les erreurs de validation du schéma et les versions SARIF non prises en charge entraînent le rejet de l'ensemble du rapport, quel que soit le taux de rejet.

## Rapports multi-outils {#multi-tool-reports}

Un fichier SARIF peut contenir plusieurs exécutions d'outils, chacune avec sa propre entrée `runs[]`. Pour chaque exécution, GitLab regroupe les résultats par type de rapport inféré et crée un enregistrement d'analyse distinct pour chaque groupe. Une exécution contenant des résultats de plus d'un type inféré produit plus d'un enregistrement d'analyse. Chaque analyse utilise le `tool.driver.name` de l'exécution comme scanner.

Utilisez des rapports multi-exécutions pour combiner la sortie de plusieurs scanners en un seul artefact. Par exemple, un job peut exécuter deux scanners et émettre un seul fichier SARIF contenant deux exécutions.

Pour la limite d'exécutions par fichier, consultez [les limites](#limits).

## Limites {#limits}

| Limite                                  | Valeur par défaut                                                       | Configurable |
|----------------------------------------|---------------------------------------------------------------|--------------|
| Taille maximale de l'artefact SARIF            | 10 Mo (`ci_max_artifact_size_sarif`)                          | {{< yes >}}  |
| Nombre maximum d'exécutions par fichier SARIF            | 20                                                            | {{< no >}}   |
| Nombre maximum de résultats par exécution                | 5 000                                                         | {{< no >}}   |
| Nombre maximum de règles par exécution                  | 25 000                                                        | {{< no >}}   |
| Nombre maximum de tags par règle                  | 10                                                            | {{< no >}}   |
| Longueur maximale de `rule.name`             | 255 caractères                                                | {{< no >}}   |
| Longueur maximale de `shortDescription.text` | 1 024 caractères                                              | {{< no >}}   |
| Longueur maximale de `fullDescription.text`  | 1 024 caractères, tronqués à 255 lorsqu'ils sont utilisés comme titre de résultat | {{< no >}}   |
| Longueur maximale de `message.text`          | 1 024 caractères, tronqués à 255 lorsqu'ils sont utilisés comme titre de résultat | {{< no >}}   |
| Longueur maximale de `helpUri`               | 2 048 caractères                                              | {{< no >}}   |
| Versions SARIF prises en charge               | 2.1.0 uniquement                                                    | {{< no >}}   |

Lorsqu'un compteur par exécution dépasse sa limite, GitLab traite les N premières entrées et enregistre un avertissement. Lorsqu'un résultat contient un champ de type chaîne dépassant sa limite de caractères, l'ensemble du résultat est ignoré et comptabilisé dans le [taux de rejet](#ingestion-behavior).

Pour les instances GitLab Self-Managed, un administrateur peut modifier les limites configurables via les [limites de l'instance](../../../administration/instance_limits.md).

## Problèmes connus {#known-issues}

- Les résultats SARIF attribués en tant que SAST, analyse des dépendances ou détection des secrets ne sont pas dédupliqués par rapport aux résultats du scanner GitLab natif équivalent. Pour plus de détails, consultez [le ticket 592410](https://gitlab.com/gitlab-org/gitlab/-/issues/592410).
- Bien que les résultats puissent être exclus via les suppressions SARIF, GitLab ne crée pas de rejets de vulnérabilités sur la base des suppressions. Pour rejeter un résultat, utilisez le rapport de vulnérabilités.

## Sujets connexes {#related-topics}

- [`artifacts:reports:sarif`](../../../ci/yaml/artifacts_reports.md#artifactsreportssarif)
- [Rapport de sécurité du pipeline](security_scanning_results.md)
- [Rapport de vulnérabilités du projet](../vulnerability_report/_index.md)
- [Politiques de sécurité](../policies/_index.md)
- [Spécification SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
