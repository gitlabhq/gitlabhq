---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Niveaux de la chaîne d'approvisionnement pour les artefacts logiciels (SLSA)"
---

[Supply-chain Levels for Software Artifacts (SLSA)](https://slsa.dev/), prononcé « salsa », est un ensemble de directives adoptables de manière incrémentale pour la sécurité de la chaîne d'approvisionnement, établies par consensus industriel. La norme est définie en termes de producteurs d'artefacts, de vérificateurs, de consommateurs et de fournisseurs d'infrastructure.

GitLab, en tant que fournisseur d'infrastructure, met à la disposition des utilisateurs des outils pour produire de manière sécurisée des métadonnées associées aux conteneurs et aux artefacts. De plus, GitLab fournit des mécanismes pour vérifier et utiliser ces métadonnées en toute sécurité afin de renforcer les chaînes d'approvisionnement et de prévenir certains types d'attaques.

## Niveaux SLSA {#slsa-levels}

GitLab peut produire des attestations de provenance conformes à la spécification SLSA à différents niveaux. L'atteinte de niveaux spécifiques nécessite une auto-évaluation par rapport à des critères précis.

Pour plus d'informations, consultez la page SLSA [Build : Track Basics](https://slsa.dev/spec/v1.2/build-track-basics).

### Niveau 1 : Provenance indiquant comment le package a été construit {#level-1-provenance-showing-how-the-package-was-built}

Le niveau SLSA 1 exige une provenance générée automatiquement qui décrit comment l'artefact a été construit, notamment :

- Quelle entité a construit le package.
- Quel processus de build a été utilisé.
- Quelle était l'entrée de niveau supérieur du build.

### Niveau 2 : Provenance signée, générée par une plateforme de build hébergée {#level-2-signed-provenance-generated-by-a-hosted-build-platform}

Le niveau SLSA 2 présente les mêmes exigences que le niveau 1, mais nécessite en outre que la plateforme de build hébergée signe la provenance générée. La signature peut être effectuée par :

- Le build d'origine.
- Un build reproductible après coup.
- Un système équivalent garantissant la fiabilité de la provenance.

GitLab propose une déclaration de provenance conforme au niveau SLSA 2 qui peut être [générée automatiquement pour tous les artefacts de build produits par le GitLab Runner](../../runners/configure_runners.md#artifact-provenance-metadata). Cette déclaration de provenance est également conforme au niveau 1 et est produite par le runner lui-même.

La mise en œuvre de SLSA à ce niveau présente de nombreux avantages, notamment :

- Aider les organisations à créer un inventaire des logiciels et des plateformes de build.
- Prévenir les altérations grâce aux signatures numériques.
- Réduire la surface d'attaque aux plateformes de build spécifiques.

#### Signer et vérifier la provenance SLSA avec un composant CI/CD {#sign-and-verify-slsa-provenance-with-a-cicd-component}

Le [composant CI/CD GitLab SLSA](https://gitlab.com/explore/catalog/components/slsa) fournit des configurations pour :

- Signer les déclarations de provenance générées par le runner.
- Générer des [Verification Summary Attestations (VSA)](https://slsa.dev/spec/v1.0/verification_summary) pour les artefacts de job.

Pour plus d'informations et des exemples de configurations, consultez la [documentation du composant SLSA](https://gitlab.com/components/slsa#slsa-supply-chain-levels-for-software-artifacts).

### Niveau 3, plateforme de build renforcée {#level-3-hardened-build-platform}

Le niveau SLSA 3 met en œuvre toutes les exigences des niveaux 1 et 2, et empêche également toute altération de la provenance. Par exemple, en empêchant une altération par un attaquant ayant compromis le processus de build lui-même.

Cette résistance accrue aux altérations provient de :

- Une isolation renforcée du runner.
- S'assurer que le matériel secret n'est pas accessible à l'environnement exécutant les étapes de build définies par l'utilisateur.
- S'assurer que chaque champ de la provenance est généré ou vérifié par la plateforme de build dans un plan de contrôle de confiance.

Pour plus d'informations, consultez la [page du niveau SLSA 3](level_3/_index.md) et la [spécification de provenance SLSA](level_3/provenance_v1.md).
