---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse de la portée statique
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/groups/gitlab-org/-/epics/14177) en tant que [version expérimentale](../../../policy/development_stages_support.md) dans GitLab 17.5
- [Passage](https://gitlab.com/groups/gitlab-org/-/epics/15781) de la version expérimentale à la version bêta dans GitLab 17.11
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/502334) de la prise en charge de JavaScript et TypeScript dans GitLab 18.2 et l'analyseur d'analyse des dépendances v0.32.0
- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/17607) de la prise en charge de Java dans GitLab 18.5 et l'analyseur d'analyse des dépendances v0.39.0
- [Passage](https://gitlab.com/groups/gitlab-org/-/epics/15780) de la version bêta à la disponibilité limitée (LA) dans GitLab 18.5
- [Passage](https://gitlab.com/groups/gitlab-org/-/epics/19692) de la prise en charge de Java de la version expérimentale à la version bêta dans GitLab 18.8
- [En disponibilité générale](https://gitlab.com/groups/gitlab-org/-/work_items/20456) dans GitLab 19.0

{{< /history >}}

L'analyse des dépendances identifie toutes les dépendances vulnérables dans votre projet. Cependant, toutes les vulnérabilités ne présentent pas le même niveau de risque. L'analyse de la portée statique vous aide à prioriser la remédiation en déterminant quels packages vulnérables sont accessibles, c'est-à-dire importés par votre application. En se concentrant sur les vulnérabilités accessibles, l'analyse de la portée statique vous permet de prioriser la remédiation en fonction de l'exposition réelle aux menaces plutôt que du risque théorique.

L'analyse de la portée statique fonctionne en analysant le code source de votre projet pour déterminer quelles dépendances de votre SBOM sont accessibles. L'analyse des dépendances génère un rapport SBOM qui identifie tous les composants et leurs dépendances transitives. L'analyse de la portée statique vérifie ensuite chaque dépendance dans le SBOM et ajoute une valeur de portée, enrichissant le rapport avec des données d'utilisation réelles. Ce SBOM enrichi est ensuite ingéré par GitLab pour compléter les résultats de vulnérabilité.

Un SBOM n'est enrichi que lorsque le fichier SBOM et les fichiers de code source appartiennent au même arbre de répertoires de projet. Lorsque plusieurs projets imbriqués existent, le système sélectionne le chemin de projet le plus proche (le plus profond) pour déterminer l'enrichissement. L'analyse de la portée statique s'appuie sur des [métadonnées](https://gitlab.com/gitlab-org/security-products/static-reachability-metadata/-/tree/v1?ref_type=heads) qui mappent les noms de packages des SBOM vers leurs chemins d'importation de code correspondants pour les packages Python et Java. Ces métadonnées sont maintenues avec des mises à jour hebdomadaires.

Partagez vos commentaires dans le [ticket 535498](https://gitlab.com/gitlab-org/gitlab/-/issues/535498).

## Activer l'analyse de la portée statique {#turn-on-static-reachability-analysis}

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- Le projet utilise des [langages et gestionnaires de packages pris en charge](#supported-languages-and-package-managers).
- [L'analyseur d'analyse des dépendances](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning) version 0.39.0 ou ultérieure (les versions antérieures peuvent prendre en charge des langages spécifiques - voir `History` ci-dessus).
- [L'analyse des dépendances par SBOM](dependency_scanning_sbom/_index.md#turn-on-dependency-scanning) est activée pour le projet. Les analyseurs [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) ne sont pas pris en charge.
- Prérequis spécifiques au langage :
  - Python :
    - Les fichiers de graphe de dépendances doivent être fournis en tant qu'artefact de job dans l'étape `build`. Consultez les instructions pour [pip](dependency_scanning_sbom/_index.md#pip) ou [pipenv](dependency_scanning_sbom/_index.md#pipenv). Pour les autres gestionnaires de packages Python pris en charge, consultez la [documentation de l'analyseur d'analyse des dépendances](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files).
  - JavaScript et TypeScript :
    - Le dépôt doit contenir des fichiers de verrouillage [pris en charge](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files) par l'analyseur d'analyse des dépendances.
  - Java :
    - Les fichiers de graphe de dépendances doivent être fournis en tant qu'artefact de job dans l'étape `build`. Consultez les instructions pour [Maven](dependency_scanning_sbom/_index.md#maven) ou [Gradle](dependency_scanning_sbom/_index.md#gradle).

> [!warning]
> L'analyse de la portée statique augmente la durée des jobs.

Pour activer l'analyse de la portée statique dans votre projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Dépôt**.
1. Sélectionnez le fichier `.gitlab-ci.yml`.
1. Sélectionnez **Édition** > **Modifier un seul fichier**.
1. Ajoutez la configuration suivante :

   ```yaml
   include:
   - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

   variables:
     DS_STATIC_REACHABILITY_ENABLED: true
   ```

1. Sélectionnez **Valider les modifications**.

Lorsque l'analyse des dépendances s'exécute et génère un SBOM, les résultats sont complétés par l'analyse de la portée statique.

## Valeurs de portée {#reachability-values}

Une dépendance peut avoir l'une des valeurs de portée suivantes. Priorisez le triage et la remédiation des dépendances marquées comme **Oui**, car leur utilisation dans votre code est confirmée.

Oui : le package lié à cette vulnérabilité est confirmé comme étant accessible dans le code. Lorsqu'une dépendance directe est marquée comme accessible, ses dépendances transitives sont également marquées comme accessibles.

Introuvable : l'analyse de la portée statique s'est exécutée avec succès, mais n'a pas détecté d'utilisation du package vulnérable.

Non disponible : l'analyse de la portée statique n'a pas été exécutée, il n'existe donc aucune donnée de portée.

Pour trouver la valeur de portée d'une dépendance vulnérable :

- Dans le rapport de vulnérabilité, survolez la valeur **Gravité**.
- Sur la page de détails d'une vulnérabilité, vérifiez la valeur **Accessible**.
- Utilisez une requête GraphQL pour lister les vulnérabilités accessibles.

### Résultats « Introuvable » {#not-found-results}

Une valeur de portée **Introuvable** ne garantit pas que la dépendance est inutilisée, car l'analyse de la portée statique ne peut pas toujours déterminer de manière définitive l'utilisation d'un package.

Les dépendances sont marquées comme introuvables lorsque :

- Elles apparaissent dans les fichiers de verrouillage mais ne sont pas importées dans le code.
- Elles se trouvent dans des répertoires exclus (par exemple, configurés avec `DS_EXCLUDED_PATHS`).
- Ce sont des outils inclus uniquement pour un usage local, comme les packages de test de couverture ou de linting.

Prenons l'exemple suivant d'un répertoire exclu. Vous avez défini la variable CI/CD `DS_EXCLUDED_PATHS="test"`. La structure du dépôt du projet est la suivante.

```plaintext
.
├── pipdeptree.json  // contains "requests" dependency
└── test/
    └── app.py       // imports "requests" dependency
```

Dans cet exemple, le fichier de graphe `pipdeptree.json` est en dehors du répertoire exclu et est analysé pour identifier les dépendances répertoriées dans le fichier. Cependant, le code source qui importe la dépendance `requests` se trouve dans un répertoire exclu, de sorte que l'analyse de la portée statique ne vérifie pas sa portée. Par conséquent, la dépendance `requests` est labelée comme **Introuvable**. En d'autres termes, cela se produit lorsque le fichier de verrouillage est en dehors du répertoire exclu, mais que le code qui importe la dépendance est à l'intérieur de celui-ci.

## Langages et gestionnaires de packages pris en charge {#supported-languages-and-package-managers}

La prise en charge varie selon la maturité du langage et inclut des gestionnaires de packages et des types de fichiers spécifiques pour chaque langage.

| Langage                          | Maturité | Gestionnaires de packages pris en charge                  | Types de fichiers pris en charge |
|-----------------------------------|----------|---------------------------------------------|----------------------|
| Python<sup>1</sup>                | version bêta     | `pip`, `pipenv`<sup>2</sup>, `poetry`, `uv` | `.py`                |
| JavaScript/TypeScript<sup>3</sup> | version bêta     | `npm`, `pnpm`, `yarn`                       | `.js`, `.ts`         |
| Java<sup>4</sup>                  | version bêta     | `maven`<sup>5</sup>, `gradle`<sup>6</sup>   | `.java`              |

**Notes de bas de page** :

1. Lors de l'utilisation de l'analyse des dépendances avec `pipdeptree`, les [dépendances facultatives](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies) sont marquées comme dépendances directes plutôt que comme dépendances transitives. L'analyse de la portée statique peut ne pas identifier ces packages comme étant utilisés. Par exemple, l'utilisation de `passlib[bcrypt]` peut entraîner que `passlib` soit marqué comme `in_use` et que `bcrypt` soit marqué comme `not_found`. Pour plus de détails, consultez [pip](dependency_scanning_sbom/_index.md#pip).
1. Pour Python `pipenv`, l'analyse de la portée statique ne prend pas en charge les fichiers `Pipfile.lock`. La prise en charge est disponible uniquement pour `pipenv.graph.json`, car ce format prend en charge un graphe de dépendances.
1. Aucune prise en charge des frameworks frontend.
1. La nature dynamique de Java entraîne les problèmes suivants, qui peuvent conduire à des taux de faux négatifs plus élevés pour les projets utilisant des frameworks modernes :
   - L'analyse de la portée statique détecte l'utilisation explicite via les imports directs, les patterns de réflexion Java et les chaînes de connexion Java Database Connectivity dans le code source. Elle ne peut pas identifier les dépendances chargées dynamiquement à l'exécution, telles que celles utilisant des frameworks d'injection de dépendances comme Spring Boot.
   - La couverture est limitée aux packages présents dans la base de données des avis de sécurité GitLab et aux packages les plus largement utilisés dans Maven Central.
1. Utilisez les fichiers `maven.graph.json` comme décrit dans les instructions [Maven](dependency_scanning_sbom/_index.md#maven).
1. Utilisez les fichiers de verrouillage de dépendances comme décrit dans les instructions [Gradle](dependency_scanning_sbom/_index.md#gradle).

## Environnement hors ligne {#offline-environment}

Pour exécuter l'analyse de la portée statique dans un [environnement hors ligne](../offline_deployments/_index.md), vous devez effectuer une configuration initiale et assurer une maintenance continue.

Configuration initiale :

- Complétez les exigences de l'environnement hors ligne pour l'[analyse des dépendances (SBOM)](dependency_scanning_sbom/_index.md#offline-environment).

Maintenance continue :

- Mettez à jour l'image locale d'analyse des dépendances (SBOM) à chaque nouvelle release.

Pour les packages Python et Java, l'analyse de la portée statique utilise des métadonnées pour mapper les noms de packages des SBOM vers leurs chemins d'importation de code correspondants. Ces métadonnées sont contenues dans l'image de l'analyseur d'analyse des dépendances. Des métadonnées obsolètes peuvent entraîner une analyse de portée incomplète ou inexacte.
