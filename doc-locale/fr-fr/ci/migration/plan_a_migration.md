---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Planifier une migration d'un autre outil vers GitLab CI/CD"
description: "Migrer depuis Jenkins, GitHub Actions et autres."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Avant de commencer une migration d'un autre outil vers GitLab CI/CD, vous devez commencer par élaborer un plan de migration.

Consultez d'abord les conseils sur la [gestion des changements organisationnels](#manage-organizational-changes) pour obtenir des recommandations sur les premières étapes des migrations de grande envergure.

Les utilisateurs impliqués dans la migration elle-même doivent consulter les [questions à poser avant de commencer une migration](#technical-questions-to-ask-before-starting-a-migration), une étape technique importante pour définir les attentes. Les outils CI/CD diffèrent dans leur approche, leur structure et leurs spécificités techniques. Certains concepts se correspondent directement, tandis que d'autres nécessitent une conversion interactive.

Il est important de se concentrer sur l'état final souhaité plutôt que de traduire strictement le comportement de votre ancien outil.

## Gérer les changements organisationnels {#manage-organizational-changes}

La transition vers GitLab CI/CD implique des changements culturels et organisationnels inhérents au processus, qu'il convient de gérer avec succès.

Voici quelques éléments que les organisations ont identifiés comme étant utiles :

- Définir et communiquer une vision claire de vos objectifs de migration, afin d'aider vos utilisateurs à comprendre pourquoi cet effort en vaut la peine. La valeur est évidente une fois le travail terminé, mais les personnes concernées doivent également en être informées pendant son déroulement.
- Le soutien et l'alignement des équipes de direction concernées contribuent à atteindre le point précédent.
- Prenez le temps de former vos utilisateurs sur les différences et partagez ce guide avec eux.
- Trouver des moyens de séquencer ou de différer certaines parties de la migration peut s'avérer très utile. Il est toutefois important de ne pas laisser les choses dans un état non migré (ou partiellement migré) trop longtemps.
- Pour tirer pleinement parti de GitLab, il ne suffit pas de transférer votre configuration existante telle quelle, y compris les problèmes actuels. Tirez parti des améliorations qu'offre GitLab CI/CD et mettez à jour votre implémentation dans le cadre de la transition.

## Questions techniques à poser avant de commencer une migration {#technical-questions-to-ask-before-starting-a-migration}

Poser quelques questions techniques initiales sur vos besoins en CI/CD permet de définir rapidement les exigences de la migration :

- Combien de projets utilisent ce pipeline ?
- Quelle stratégie de branche est utilisée ? Des branches de fonctionnalités ? Une ligne principale ? Des branches de release ?
- Quels outils utilisez-vous pour générer votre code ? Par exemple, Maven, Gradle ou NPM ?
- Quels outils utilisez-vous pour tester votre code ? Par exemple JUnit, Pytest ou Jest ?
- Utilisez-vous des scanners de sécurité ?
- Où stockez-vous les packages générés ?
- Comment déployez-vous votre code ?
- Où déployez-vous votre code ?

## Sujets connexes {#related-topics}

- Comment migrer l'infrastructure CI/CD d'Atlassian Bamboo Server vers GitLab CI/CD, [première partie](https://about.gitlab.com/blog/migration-from-atlassian-bamboo-server-to-gitlab-ci/) et [deuxième partie](https://about.gitlab.com/blog/how-to-migrate-atlassians-bamboo-servers-ci-cd-infrastructure-to-gitlab-ci-part-two/)
