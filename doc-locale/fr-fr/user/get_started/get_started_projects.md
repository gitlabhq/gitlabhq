---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez les projets pour les adapter à votre organisation.
title: "Premiers pas dans l'organisation du travail avec les projets"
---

Les projets dans GitLab organisent toutes les données d'un projet de développement spécifique. Un projet est l'endroit où vous travaillez avec votre équipe, stockez vos fichiers et gérez vos tâches.

Utilisez les projets pour :

- Écrire et enregistrer du code
- Suivre les tickets et les tâches
- Collaborer sur les modifications de code
- Tester et déployer votre application

La création et la maintenance de projets font partie d'un flux de travail plus large :

![L'organisation du travail avec les projets fait partie de l'étape de planification dans un flux de travail de développement.](img/get_started_projects_v16_11.png)

## Étape 1 :  Créer un projet {#step-1-create-a-project}

Commencez par créer un nouveau projet dans GitLab pour contenir votre base de code, votre documentation et les ressources associées.

Un projet contient un dépôt. Un dépôt contient tous les fichiers, répertoires et données liés à votre travail.

Lorsque vous créez le projet, passez en revue et configurez les paramètres suivants pour les aligner sur votre flux de travail de développement et vos exigences de collaboration :

- Niveau de visibilité
- Approbations de merge request
- Suivi des tickets
- Pipelines CI/CD
- Modèles de description pour les entités telles que les tickets ou les merge requests

Pour plus d'informations, consultez :

- [Créer un projet](../project/_index.md)
- [Gérer les projets](../project/working_with_projects.md)
- [Visibilité des projets](../public_access.md)
- [Paramètres du projet](../project/settings/_index.md)
- [Modèles de description](../project/description_templates.md)

## Étape 2 :  Sécuriser et contrôler l'accès aux projets {#step-2-secure-and-control-access-to-projects}

Utilisez les outils suivants pour gérer l'accès sécurisé à vos projets :

- Jetons d'accès au projet :  Accordez des droits d'accès spécifiques aux outils automatisés ou aux systèmes externes pour une intégration sécurisée.
- Clés de déploiement :  Accordez un accès en lecture seule à vos dépôts pour déployer votre projet en toute sécurité vers des systèmes externes.
- Jetons de déploiement :  Accordez un accès temporaire et limité au dépôt et au registre de votre projet pour des déploiements et une automatisation sécurisés.

Pour plus d'informations, consultez :

- [Jetons d'accès au projet](../project/settings/project_access_tokens.md)
- [Clés de déploiement](../project/deploy_keys/_index.md)
- [Jetons de déploiement](../project/deploy_tokens/_index.md)

## Étape 3 :  Collaborer et partager des projets {#step-3-collaborate-and-share-projects}

Vous pouvez inviter plusieurs projets dans un groupe, parfois appelé `sharing a project with a group`. Chaque projet possède son propre dépôt, ses tickets, ses merge requests et d'autres fonctionnalités.

Avec plusieurs projets dans un groupe, les membres de l'équipe peuvent collaborer sur des projets individuels tout en ayant une vue d'ensemble de tout le travail effectué dans le groupe.

Pour affiner davantage l'accès à vos projets, vous pouvez ajouter des sous-groupes à votre groupe.

Pour plus d'informations, consultez :

- [Partager des projets](../project/members/sharing_projects_groups.md)
- [Sous-groupes](../group/subgroups/_index.md)

## Étape 4 :  Améliorer la découvrabilité et la reconnaissance des projets {#step-4-enhance-project-discoverability-and-recognition}

Utilisez la barre de recherche pour trouver rapidement des projets, des tickets, des merge requests ou des extraits de code spécifiques dans votre instance GitLab.

Pour faciliter la recherche de projets :

- Créez un schéma de nommage cohérent et reconnaissable pour vos projets avec des noms de projets et de groupes réservés.
- Ajoutez des badges au fichier `README` de votre projet. Les badges peuvent afficher des informations importantes, comme le statut de build, la santé du projet, la couverture de tests ou le numéro de version.
- Attribuez des topics au projet. Les topics sont des labels qui vous aident à organiser et à trouver des projets.

Pour plus d'informations, consultez :

- [Noms de projets et de groupes réservés](../reserved_names.md)
- [Recherche](../search/_index.md)
- [Badges](../project/badges.md)
- [Topics de projet](../project/project_topics.md)

## Étape 5 :  Améliorer l'efficacité du développement et maintenir la qualité du code {#step-5-boost-development-efficiency-and-maintain-code-quality}

Utilisez les fonctionnalités d'intelligence du code pour améliorer votre productivité et maintenir une base de code de haute qualité, telles que :

- Navigation dans le code
- Informations au survol
- Complétion automatique

L'intelligence du code est un ensemble d'outils qui vous aident à explorer, analyser et maintenir efficacement votre base de code.

Pour localiser rapidement des fichiers spécifiques dans votre projet et y accéder, utilisez le sélecteur de fichiers.

Pour plus d'informations, consultez :

- [Intelligence du code](../project/code_intelligence.md)
- [Fichiers](../project/repository/files/_index.md)

## Étape 6 :  Migrer des projets vers GitLab {#step-6-migrate-projects-into-gitlab}

Utilisez les exports de fichiers pour migrer des projets vers GitLab depuis d'autres systèmes ou instances GitLab.

Lorsque vous migrez un dépôt fréquemment utilisé vers GitLab, vous pouvez utiliser un alias de projet pour continuer à y accéder par son nom d'origine.

Sur GitLab.com, vous pouvez transférer un projet d'un espace de nommage à un autre. Un transfert déplace essentiellement un projet vers un autre groupe afin que ses membres aient accès au projet ou en soient propriétaires.

Pour plus d'informations, consultez :

- [Importer et migrer vers GitLab](../import/_index.md)
- [Alias de projet](../project/working_with_projects.md#project-aliases)
- [Transférer un projet vers un autre espace de nommage](../project/working_with_projects.md#transfer-a-project)
