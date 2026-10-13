---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Niveaux de gravité des vulnérabilités
description: "Classification, impact, priorisation et évaluation des risques."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les analyseurs de vulnérabilités GitLab tentent de retourner des valeurs de niveau de gravité des vulnérabilités dans la mesure du possible. Voici la liste des niveaux de gravité des vulnérabilités GitLab disponibles, classés du plus grave au moins grave :

- Critique
- Élevé
- Moyen
- Faible
- Info
- Inconnu

Les analyseurs GitLab s'efforcent de correspondre aux descriptions de gravité ci-dessous, mais ils peuvent ne pas toujours être corrects. Les analyseurs et scanners fournis par des éditeurs tiers peuvent ne pas suivre la même classification.

## Gravité critique {#critical-severity}

Les vulnérabilités identifiées au niveau de gravité critique doivent faire l'objet d'une investigation immédiate. Les vulnérabilités à ce niveau supposent que l'exploitation de la faille pourrait mener à une compromission totale du système ou des données. Les exemples de failles de gravité critique sont l'injection de commandes/code et l'injection SQL. En général, ces failles sont évaluées avec un score CVSS 4.0 compris entre 9,0 et 10,0.

## Gravité élevée {#high-severity}

Les vulnérabilités de gravité élevée peuvent être caractérisées comme des failles pouvant permettre à un attaquant d'accéder aux ressources d'une application ou d'exposer des données de manière non intentionnelle. Les exemples de failles de gravité élevée sont l'injection d'entité XML externe (XXE), la falsification de requête côté serveur (SSRF), l'inclusion de fichier local, la traversée de répertoire et certaines formes de scripts intersites (XSS). En général, ces failles sont évaluées avec un score CVSS 4.0 compris entre 7,0 et 8,9.

## Gravité moyenne {#medium-severity}

Les vulnérabilités de gravité moyenne sont généralement dues à une mauvaise configuration des systèmes ou à un manque de contrôles de sécurité. L'exploitation de ces vulnérabilités peut mener à l'accès à une quantité limitée de données ou peut être utilisée conjointement avec d'autres failles pour obtenir un accès non intentionnel aux systèmes ou aux ressources. Les exemples de failles de gravité moyenne sont les XSS réfléchis, la gestion incorrecte des sessions HTTP et les contrôles de sécurité manquants. En général, ces failles sont évaluées avec un score CVSS 4.0 compris entre 4,0 et 6,9.

## Gravité faible {#low-severity}

Les vulnérabilités de gravité faible contiennent des failles qui peuvent ne pas être directement exploitables, mais qui introduisent des faiblesses inutiles dans une application ou un système. Ces failles sont généralement dues à des contrôles de sécurité manquants ou à la divulgation inutile d'informations sur l'environnement de l'application. Les exemples de vulnérabilités de gravité faible sont les directives de sécurité des cookies manquantes et les messages d'erreur ou d'exception trop verbeux. En général, ces failles sont évaluées avec un score CVSS 4.0 compris entre 0,1 et 3,9.

## Gravité Info {#info-severity}

Les vulnérabilités de niveau de gravité Info contiennent des informations pouvant avoir de la valeur, mais qui ne sont pas nécessairement associées à une faille ou une faiblesse particulière. En général, ces tickets ne disposent pas d'une évaluation CVSS.

## Gravité inconnue {#unknown-severity}

Les tickets identifiés à ce niveau ne disposent pas d'un contexte suffisant pour démontrer clairement leur gravité.

Les analyseurs de vulnérabilités GitLab incluent des outils de scan open source populaires. Chaque outil de scan open source fournit sa propre valeur native de niveau de gravité des vulnérabilités. Ces valeurs peuvent être l'une des suivantes :

| Type de niveau de gravité de vulnérabilité natif                                                                                          | Exemples                                       |
|-----------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| Chaîne                                                                                                                            | `WARNING`, `ERROR`, `Critical`, `Negligible`   |
| Entier                                                                                                                           | `1`, `2`, `5`                                  |
| [Évaluation CVSS v2.0](https://nvd.nist.gov/vuln-metrics/cvss)                                                                        | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`                 |
| [Évaluation qualitative de la gravité CVSS v3.1](https://www.first.org/cvss/v3.1/specification-document#Qualitative-Severity-Rating-Scale) | `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` |
| [Évaluation qualitative de la gravité CVSS v4.0](https://www.first.org/cvss/v4.0/specification-document#Qualitative-Severity-Rating-Scale) | `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N` |

Pour fournir des valeurs de niveau de gravité des vulnérabilités cohérentes, les analyseurs de vulnérabilités GitLab convertissent les valeurs précédentes en un niveau de gravité de vulnérabilité GitLab standardisé, comme indiqué dans les tableaux suivants :

## Scan de conteneurs {#container-scanning}

| Analyseur GitLab                                                        | Génère des niveaux de gravité ? | Type de niveau de gravité natif | Exemple de niveau de gravité natif                                |
|------------------------------------------------------------------------|--------------------------|----------------------------|--------------------------------------------------------------|
| [`container-scanning`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)| {{< yes >}} | Chaîne | `Unknown`, `Low`, `Medium`, `High`, `Critical` |

Lorsqu'il est disponible, le niveau de gravité du fournisseur est prioritaire et utilisé par l'analyseur. S'il n'est pas disponible, l'évaluation CVSS v4.0 est utilisée par défaut. Si celle-ci n'est pas non plus disponible, l'évaluation CVSS v3.1 est utilisée. Si celle-ci n'est pas non plus disponible, l'évaluation CVSS v2.0 est utilisée à la place.

## Test dynamique de sécurité des applications (DAST) {#dynamic-application-security-testing-dast}

| Analyseur GitLab                                                                          | Génère des niveaux de gravité ?     | Type de niveau de gravité natif | Exemple de niveau de gravité natif       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`Browser-based DAST`](../dast/browser/_index.md)         | {{< yes >}}       | Chaîne | `HIGH`, `MEDIUM`, `LOW`, `INFO` |

## Test de sécurité des API {#api-security-testing}

| Analyseur GitLab                                                                          | Génère des niveaux de gravité ?     | Type de niveau de gravité natif | Exemple de niveau de gravité natif       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`API security testing`](../api_security_testing/_index.md)         | {{< yes >}}       | Chaîne | `HIGH`, `MEDIUM`, `LOW` |

## Analyse des dépendances {#dependency-scanning}

| Analyseur GitLab                                                                          | Génère des niveaux de gravité ?     | Type de niveau de gravité natif | Exemple de niveau de gravité natif       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`gemnasium`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)         | {{< yes >}}       | Évaluation CVSS v2.0, évaluation qualitative de la gravité CVSS v3.1 <sup>1</sup> et évaluation qualitative de la gravité CVSS v4.0 <sup>1</sup> | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`, `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H`, `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N` |

L'évaluation CVSS v4.0 est utilisée pour calculer le niveau de gravité. Si elle n'est pas disponible, l'évaluation CVSS v3.1 est utilisée. Si celle-ci n'est pas non plus disponible, l'évaluation CVSS v2.0 est utilisée à la place.

## Test de fuzzing {#fuzz-testing}

Tous les résultats de tests de fuzzing sont signalés avec une gravité inconnue. Ils doivent être examinés et triés manuellement pour identifier les failles exploitables à prioriser pour la correction.

## Test statique de sécurité des applications (SAST) {#static-application-security-testing-sast}

|  Analyseur GitLab                                                                 | Génère des niveaux de gravité ? | Type de niveau de gravité natif | Exemple de niveau de gravité natif |
|----------------------------------------------------------------------------------|--------------------------|----------------------------|-------------------------|
| [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec)   | {{< yes >}}   | Chaîne                     | `CriticalSeverity`, `InfoSeverity` |
| [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex) | {{< yes >}}   | Entier                    | `1`, `2`, `3`, `4`, `5`            |
| [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)   | {{< yes >}}   | Chaîne                     | `error`, `warning`, `note`, `none` |
| [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)   | {{< yes >}}   | Non applicable             | Définit tous les niveaux de gravité en dur sur `Unknown` |
| [`SpotBugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) | {{< yes >}}   | Entier                    | `1`, `2`, `3`, `11`, `12`, `18`    |

## Scan d'Infrastructure as Code (IaC) {#infrastructure-as-code-iac-scanning}

|  Analyseur GitLab                                                                                         | Génère des niveaux de gravité ? | Type de niveau de gravité natif | Exemple de niveau de gravité natif      |
|----------------------------------------------------------------------------------------------------------|--------------------------|----------------------------|------------------------------------|
| [`kics`](https://gitlab.com/gitlab-org/security-products/analyzers/kics)                                 | {{< yes >}}   | Chaîne                     | `error`, `warning`, `note`, `none` (mappé sur `info` dans la [version 3.7.0 et ultérieure de l'analyseur](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/releases/v3.7.0)) |

### Correspondance des niveaux de gravité de Keeping Infrastructure as Code Secure (KICS) {#keeping-infrastructure-as-code-secure-kics-severity-mapping}

L'analyseur KICS mappe sa sortie sur les niveaux de gravité du format SARIF (Static Analysis Results Interchange Format), qui sont eux-mêmes mappés sur les niveaux de gravité GitLab. Utilisez le tableau ci-dessous pour voir le niveau de gravité correspondant dans le rapport de vulnérabilités GitLab.

| Gravité KICS | Gravité KICS SARIF | Gravité GitLab |
|---------------|---------------------|-----------------|
| CRITICAL      | error               | Critique        |
| HIGH          | error               | Critique        |
| MEDIUM        | warning             | Moyen          |
| LOW           | note                | Info            |
| INFO          | none                | Info            |
| invalid       | none                | Info            |

Bien que KICS et GitLab définissent tous deux la gravité élevée, SARIF ne le fait pas ; ainsi, les vulnérabilités de gravité élevée dans KICS sont mappées sur la gravité critique dans GitLab.

[Code source du mapping GitLab](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/902c7dcb5f3a0e551223167931ebf39588a0193a/sarif/sarif.go#L279-315).

## Détection des secrets {#secret-detection}

L'analyseur GitLab [`secrets`](https://gitlab.com/gitlab-org/security-products/analyzers/secrets) définit tous les niveaux de gravité en dur sur critique. Des évaluations de gravité plus granulaires sont proposées dans l'[epic 10320](https://gitlab.com/groups/gitlab-org/-/epics/10320).
