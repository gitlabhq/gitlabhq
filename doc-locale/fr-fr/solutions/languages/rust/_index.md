---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Index des solutions pour le langage Rust et son écosystème
---

Cette page tente de répertorier les façons dont GitLab prend en charge Rust. Elle le fait que l'intégration résulte de la configuration de fonctionnalités générales, qu'elle soit intégrée à Rust ou à GitLab, ou qu'elle soit fournie en tant que solution.

Sauf indication contraire, tout ce contenu s'applique à la fois aux instances GitLab.com et GitLab Self-Managed.

| Balise de texte                 | Configuration / Intégré / Solution                             | Support/Maintenance                                          |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `[Rust Configuration]`    | Intégration réalisée en configurant les fonctionnalités Rust existantes       | Rust                                                          |
| `[GitLab Configuration]` | Intégration réalisée en configurant les fonctionnalités GitLab existantes    | GitLab                                                       |
| `[Rust Partner Built]`         | Intégré à GitLab par l'équipe produit pour prendre en charge l'intégration Rust | GitLab                                                       |
| `[Rust Partner Solution]`         | Construit comme exemple de solution par Rust ou ses partenaires             | Communauté/Exemple                                            |
| `[GitLab Solution]`      | Construit comme exemple de solution par GitLab ou ses partenaires       | Communauté/Exemple                                            |
| `[CI Solution]`          | Construit à l'aide de GitLab CI et donc <br />davantage personnalisable par le client. | Les éléments balisés `[CI Solution]` comporteront également <br />l'une des autres balises <br />qui indiquent le statut de maintenance. |

## Rust SCM {#rust-scm}

- GitLab Duo Code Suggestions `[GitLab Built]`

## Rust CI {#rust-ci}

- [Résultats des tests unitaires](../../../ci/testing/unit_test_report_examples.md#rust) `[GitLab Built]`
- [Composant CI/CD GitLab pour Rust](https://gitlab.com/explore/catalog/components/rust) `[GitLab Built]`
  - [Utilisation du composant CI/CD Rust](../../../ci/components/examples.md#example-test-a-rust-language-cicd-component) `[GitLab Built]`

## Rust CD {#rust-cd}

- Prise en charge du registre de paquets GitLab pour Cargo - [Ouvert aux contributions](https://gitlab.com/gitlab-org/gitlab/-/issues/33060)
- [Composant CI/CD GitLab pour Rust (actuellement en prépublication)](https://gitlab.com/explore/catalog/components/rust) `[GitLab Built]`
  - [Comment utiliser le composant CI/CD Rust](../../../ci/components/examples.md#example-test-a-rust-language-cicd-component) `[GitLab Built]`

## Rust – Sécurité et SBOM {#rust-security-and-sbom}

- [Test de couverture du code](../../../ci/testing/code_coverage/coverage_reporting.md#coverage-regex-patterns) `[GitLab Built]`
- [Analyse SAST GitLab](../../../user/application_security/sast/_index.md#supported-languages-and-frameworks) `[GitLab Built]`- nécessite la création d'un ensemble de règles personnalisé.
- [Analyse des licences Rust (actuellement en prépublication)](https://gitlab.com/groups/gitlab-org/-/epics/13093) `[GitLab Built]`
- [CodeSecure CodeSonar Embedded C Deep SAST Scanner en tant que composant CI/CD GitLab](https://gitlab.com/explore/catalog/codesonar/components/codesonar-ci) `[Rust Partner Built]` `[CI Solution]` \- prend en charge l'analyse approfondie par exécution abstraite en observant les compilations. Prend en charge le JSON SAST de GitLab, ce qui permet d'intégrer les résultats dans l'ensemble des fonctionnalités de sécurité de GitLab Ultimate. Comprend la prise en charge de MISRA et une prise en charge directe de nombreux compilateurs pour systèmes embarqués.
