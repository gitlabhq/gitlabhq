---
stage: Release Notes
group: Monthly Release
date: 2024-01-18
title: "Notes de release de GitLab 16.8"
description: "GitLab 16.8 publié avec les résultats d'analyse statique dans la vue des modifications de la merge request"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 18 janvier 2024, GitLab 16.8 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

Ted a apporté des contributions significatives en [supprimant du code ancien et inutilisé](https://gitlab.com/gitlab-org/gitlab/-/issues/420057) de nos fichiers d'aide et en prenant en charge d'autres tâches de maintenance. Il a été nommé par [Kerri Miller](https://gitlab.com/kerrizor), ingénieure principale chez GitLab, qui a déclaré : « Ce n'est pas toujours un travail glamour, mais c'est un travail important ».

Ted est un ingénieur logiciel indépendant, grimpeur passionné et félin enthousiaste basé dans le comté d'Orange.

Martin a été nommé par [Viktor Nagy](https://gitlab.com/nagyv-gitlab), chef de produit chez GitLab, qui a déclaré : « Il a ajouté de nombreux tests manquants au modèle de jobs Auto Deploy et a amélioré la [documentation du chart Helm agentk](../../user/clusters/agent/install/_index.md#customize-the-helm-installation) ».

[Lee Tickett](https://gitlab.com/leetickett-gitlab), ingénieur chez GitLab, a ajouté qu'il « a participé aux sessions de pair-programming communautaires sur [Discord](https://discord.gg/gitlab) et a collaboré étroitement avec les membres de l'équipe pour contribuer à une [amélioration de la recherche](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) très demandée pour les merge requests ».

Martin est architecte IT chez Deutsche Telekom MMS GmbH, basé à Dresde, en Allemagne.

Helio a été nommé par [Hannah Sutor](https://gitlab.com/hsutor), responsable principale de produit chez GitLab, qui a déclaré : « il a fait avancer toute notre équipe en proposant la [possibilité de se connecter à l'aide de clés d'accès](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135324). La merge request d'Helio a été fermée, mais sa contribution était approfondie, stimulante, et ses questions et sa discussion ouverte amélioreront notre implémentation sans mot de passe ».

Helio est un ingénieur logiciel passionné par Ruby et l'OSS.

Merci Ted, Martin et Helio ! 🙌

## Fonctionnalités principales {#primary-features}

### Résultats d'analyse statique dans la vue des modifications de la merge request {#static-analysis-findings-in-merge-request-changes-view}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/_index.md#merge-request-changes-view) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10959)

{{< /details >}}

L'analyse statique prend désormais en charge l'affichage des résultats dans la vue des modifications de la merge request. Inutile de naviguer ailleurs – tout est regroupé en un seul endroit. L'interface utilisateur est affinée pour une expérience plus simple. Pour plus de détails, il vous suffit d'ouvrir le panneau latéral. Pour en savoir plus, consultez la documentation liée, la vidéo de démonstration et le ticket de déploiement.

### Prise en charge de Google Cloud Secret Manager {#google-cloud-secret-manager-support}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/secrets/gcp_secret_manager.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11739)

{{< /details >}}

Les secrets stockés dans Google Cloud Secret Manager peuvent désormais être facilement récupérés et utilisés dans les jobs CI/CD. Notre nouvelle intégration simplifie le processus d'interaction avec Google Cloud Secret Manager via GitLab CI/CD, vous aidant à rationaliser vos processus de build et de déploiement ! Ce n'est qu'une des nombreuses façons dont [GitLab et Google Cloud sont meilleurs ensemble](https://about.gitlab.com/blog/gitlab-google-partnership-s3c/) !

### Les workspaces sont désormais disponibles en version générale {#workspaces-are-now-generally-available}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/_index.md)

{{< /details >}}

Nous sommes ravis d'annoncer que les workspaces sont désormais disponibles en version générale et prêts à améliorer l'efficacité de vos équipes de développement !

En créant des environnements de développement à distance sécurisés et à la demande, vous pouvez réduire le temps consacré à la gestion des dépendances et à l'intégration des nouveaux développeurs, et vous concentrer sur la livraison de valeur plus rapidement. Grâce à notre approche agnostique en matière de plateforme, vous pouvez utiliser votre infrastructure cloud existante pour héberger vos workspaces et garder vos données privées et sécurisées.

Depuis leur introduction dans GitLab 16.0, les workspaces ont bénéficié d'améliorations en matière de gestion des erreurs et de réconciliation, de prise en charge des projets privés et des connexions SSH, d'options de configuration supplémentaires, ainsi que d'une nouvelle interface administrateur. Ces améliorations signifient que les workspaces sont désormais plus flexibles, plus résilients et plus facilement gérables à grande échelle.

### Appliquer la 2FA pour les administrateurs GitLab {#enforce-2fa-for-gitlab-administrators}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../security/two_factor_authentication.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/427549)

{{< /details >}}

Vous pouvez désormais imposer aux administrateurs GitLab l'utilisation de l'authentification à deux facteurs (2FA) dans leur instance auto-gérée. Il est recommandé, du point de vue de la sécurité, d'utiliser la 2FA pour tous les comptes, en particulier pour les comptes privilégiés tels que les administrateurs. Si ce paramètre est appliqué et qu'un administrateur n'utilise pas encore la 2FA, il devra configurer la 2FA lors de sa prochaine connexion.

### Accélérez vos builds avec le proxy de dépendances Maven {#speed-up-your-builds-with-the-maven-dependency-proxy}

<!-- categories: Dependency Management, Package Registry -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/package_registry/dependency_proxy/_index.md)

{{< /details >}}

Un projet logiciel standard repose sur un ensemble de dépendances, que nous appelons des packages. Les packages peuvent être construits et maintenus en interne, ou provenir d'un dépôt public. D'après nos recherches utilisateurs, nous avons appris que la plupart des projets utilisent un mélange 50/50 de packages publics et privés. L'ordre d'installation des packages est très important, car l'utilisation d'une version de package incorrecte peut introduire des modifications incompatibles et des vulnérabilités de sécurité dans vos pipelines.

Vous pouvez désormais ajouter un dépôt Java externe à votre projet GitLab. Après l'avoir ajouté, lorsque vous installez un package à l'aide du proxy de dépendances, GitLab vérifie d'abord si le package est présent dans le projet. S'il n'est pas trouvé, GitLab tente alors de récupérer le package depuis le dépôt externe.

Lorsqu'un package est extrait du dépôt externe, il est importé dans le projet GitLab. La prochaine fois que ce package particulier est extrait, il l'est depuis GitLab et non depuis le dépôt externe. Même si le dépôt externe rencontre des problèmes de connectivité et que le package est présent dans le proxy de dépendances, l'extraction du package fonctionne toujours, ce qui rend vos pipelines plus rapides et plus fiables.

Si le package change dans le dépôt externe (par exemple, un utilisateur supprime une version et en publie une nouvelle avec des fichiers différents), le proxy de dépendances le détecte. Il invalide le package, de sorte que GitLab extrait le plus récent. Cela garantit que les packages corrects sont téléchargés et contribue à réduire les vulnérabilités de sécurité.

### Informations plus approfondies sur la vélocité dans le rapport Analytique des tickets {#deeper-insights-into-velocity-in-the-issue-analytics-report}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/issues_analytics/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/233905)

{{< /details >}}

Le rapport **Analytique des tickets** contient désormais des informations sur le nombre de tickets fermés par mois afin de permettre une analyse détaillée de la vélocité. Grâce à cet ajout précieux, les utilisateurs de GitLab peuvent désormais obtenir des informations sur les tendances associées à leurs projets et améliorer le délai global de traitement et la valeur livrée à leurs clients. La visualisation **Analytique des tickets** contient un graphique à barres avec le nombre de tickets pour chaque mois, avec une plage temporelle par défaut de 13 mois. Vous pouvez accéder à ce graphique depuis l'exploration dans le [Value Streams Dashboard](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports).

### Nouvelle vue DevOps au niveau de l'organisation avec des benchmarks sectoriels basés sur DORA {#new-organization-level-devops-view-with-dora-based-industry-benchmarks}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/426516)

{{< /details >}}

Nous avons ajouté un nouveau panneau **DORA Performers score** au [Value Streams Dashboard](https://www.youtube.com/watch?v=EA9Sbks27g4) pour visualiser le statut des performances DevOps de l'organisation dans différents projets. Cette nouvelle visualisation affiche une répartition du score DORA (élevé, moyen ou faible) afin que les dirigeants puissent comprendre l'état de santé DevOps de l'organisation de bout en bout.

Les [quatre métriques DORA](https://about.gitlab.com/solutions/value-stream-management/dora/#overview) sont disponibles en standard dans GitLab, et désormais avec les nouveaux scores DORA, les organisations peuvent comparer leurs performances DevOps par rapport aux [benchmarks sectoriels](https://dora.dev/) ou à leurs pairs. Ce benchmarking aide les dirigeants à comprendre leur position par rapport aux autres et à identifier les meilleures pratiques ou les domaines dans lesquels ils pourraient être en retard.

Pour nous aider à améliorer le Value Streams Dashboard, veuillez partager vos commentaires sur votre expérience dans cette [enquête](https://gitlab.fra1.qualtrics.com/jfe/form/SV_50guMGNU2HhLeT4).

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

Depuis GitLab 16.8, vous pouvez spécifier des commandes pour générer des configurations pour les services suivants dans le fichier `gitlab.rb` afin que les mots de passe en texte clair ne soient pas exposés :

- GitLab Kubernetes Agent Server
- GitLab Workhorse
- GitLab Exporter

Cela signifie que les mots de passe en texte clair pour Redis n'ont plus besoin d'être stockés dans `gitlab.rb`.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Réinitialisations d'approbation plus intelligentes avec la prise en charge de `patch-id` {#smarter-approval-resets-with-patch-id-support}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch)

{{< /details >}}

Pour s'assurer que toutes les modifications sont examinées et approuvées, il est courant de supprimer toutes les approbations lorsque de nouveaux commits sont ajoutés à une merge request. Cependant, les rebases invalidaient aussi inutilement les approbations existantes, même si le rebase n'introduisait aucune nouvelle modification, obligeant les auteurs à demander une nouvelle approbation.

Les approbations de merge request s'alignent désormais sur un [`git-patch-id`](https://git-scm.com/docs/git-patch-id). Il s'agit d'un identifiant raisonnablement stable et raisonnablement unique qui permet de prendre des décisions plus intelligentes concernant la réinitialisation des approbations. En comparant le `patch-id` avant et après le rebase, nous pouvons déterminer si de nouvelles modifications ont été introduites et si elles doivent réinitialiser les approbations et nécessiter une révision.

Si vous avez des commentaires sur vos expériences avec les réinitialisations, faites-le nous savoir dans le [ticket #435870](https://gitlab.com/gitlab-org/gitlab/-/issues/435870).

### Afficher les informations de blame directement sur la page du fichier {#view-blame-information-directly-in-the-file-page}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/files/git_blame.md#view-blame-for-a-file)

{{< /details >}}

Dans les versions précédentes de GitLab, l'affichage du blame d'un fichier nécessitait d'accéder à une autre page. Vous pouvez désormais afficher les informations de blame du fichier directement depuis la page du fichier.

### Définir l'utilisation du processeur et de la mémoire par workspace {#set-cpu-and-memory-usage-per-workspace}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

L'amélioration de l'expérience des développeurs, l'intégration et la sécurité orientent davantage le développement vers les IDE cloud et les environnements de développement à distance à la demande. Cependant, ces environnements peuvent contribuer à l'augmentation des coûts d'infrastructure. Vous pouvez déjà configurer l'utilisation du processeur et de la mémoire par projet dans votre [devfile](../../user/workspace/_index.md#devfile).

Vous pouvez désormais également définir l'utilisation du processeur et de la mémoire par workspace. En configurant les requêtes et les limites au niveau de l'agent GitLab, vous pouvez empêcher des développeurs individuels d'utiliser une quantité excessive de ressources cloud.

### Prise en charge de Kubernetes 1.28 {#kubernetes-128-support}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/432070)

{{< /details >}}

Cette release ajoute une prise en charge complète de Kubernetes version 1.28, publiée en août 2023. Si vous déployez vos applications sur Kubernetes, vous pouvez désormais mettre à niveau vos clusters connectés vers la version la plus récente et profiter de toutes ses fonctionnalités.

Vous pouvez en savoir plus sur notre politique de prise en charge de Kubernetes et les autres versions de Kubernetes prises en charge.

### Nouvelles autorisations personnalisables {#new-customizable-permissions}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

Cinq nouvelles capacités sont disponibles pour créer des rôles personnalisés :

- Gérer les jetons d'accès au projet.
- Gérer les jetons d'accès au groupe.
- Gérer les membres du groupe.
- Capacité d'archiver un projet.
- Capacité de supprimer un projet.

Ajoutez ces capacités, ainsi que d'autres capacités personnalisées préexistantes, à n'importe quel rôle par défaut pour créer un rôle personnalisé. Les rôles personnalisés vous permettent de définir des rôles granulaires qui ne donnent à un utilisateur que les capacités dont il a besoin pour effectuer ses jobs, et réduisent l'escalade de privilèges inutile.

### Attribuer un rôle personnalisé avec SAML SSO {#assign-a-custom-role-with-saml-sso}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/saml_sso/_index.md#configure-gitlab) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/417285)

{{< /details >}}

Les utilisateurs peuvent se voir attribuer un rôle personnalisé comme rôle par défaut lors de leur provisionnement avec SAML SSO. Auparavant, seuls des rôles statiques pouvaient être choisis comme rôle par défaut. Cela permet aux utilisateurs provisionnés automatiquement de se voir attribuer un rôle qui s'aligne au mieux sur le principe du moindre privilège.

### Filtrer les événements d'audit en streaming par sous-groupe/projet au niveau du groupe {#filter-streaming-audit-events-by-sub-groupproject-at-group-level}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11384)

{{< /details >}}

Les événements d'audit en streaming ont été étendus pour prendre en charge le filtrage par sous-groupe ou projet au niveau du groupe, en plus de la prise en charge existante du filtrage par type d'événement.

Ce filtre supplémentaire vous permettra de séparer les événements dans vos flux pour les envoyer vers différentes destinations, ou d'exclure les sous-groupes/projets non pertinents, en vous assurant de disposer des événements les plus exploitables à surveiller pour votre équipe.

### Améliorations de la gestion des cadres de conformité {#compliance-framework-management-improvements}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_frameworks/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11240)

{{< /details >}}

Notre centre de conformité devient la destination centrale pour comprendre la posture de conformité et gérer les cadres de conformité. Nous déplaçons la gestion des cadres dans un nouvel onglet du centre de conformité, et nous ajoutons également des fonctionnalités plus intéressantes :

- Affichez les cadres dans une vue liste dans l'onglet **Cadres**.
- Recherchez et filtrez pour trouver des cadres spécifiques.
- Utilisez le nouveau panneau latéral de cadre de conformité pour explorer plus de détails pour chaque cadre.
- Modifiez votre cadre pour afficher tous les paramètres, notamment la gestion du nom, de la description, des projets liés, et plus encore.
- Créez un rapport rapide de vos cadres avec une exportation en CSV.

### Streaming d'événements d'audit au niveau de l'instance vers AWS S3 {#instance-level-audit-event-streaming-to-aws-s3}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Auparavant, vous ne pouviez configurer que le streaming des événements d'audit du groupe principal pour AWS S3.

Avec GitLab 16.8, nous avons étendu la prise en charge d'AWS S3 aux destinations de streaming au niveau de l'instance.

### Appliquer une politique pour empêcher la suppression ou la déprotection des branches {#enforce-policy-to-prevent-branches-being-deleted-or-unprotected}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9705)

{{< /details >}}

L'un des plusieurs nouveaux paramètres ajoutés aux politiques de résultats de scan pour faciliter l'[application de la conformité des politiques de sécurité](https://gitlab.com/groups/gitlab-org/-/epics/9704), les contrôles de modification des branches limiteront la possibilité de contourner les politiques en modifiant les paramètres au niveau du projet.

Pour chaque politique de résultats de scan existante ou nouvelle, vous pouvez activer `Prevent branch modification` pour qu'elle prenne effet sur les branches définies dans la politique afin d'empêcher les utilisateurs de supprimer ou de déprotéger ces branches.

### Synchronisation des groupes SAML pour les rôles personnalisés {#saml-group-sync-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/saml_sso/group_sync.md#configure-saml-group-links) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)

{{< /details >}}

Vous pouvez désormais utiliser la synchronisation des groupes SAML pour associer des rôles personnalisés à des groupes d'utilisateurs. Auparavant, vous ne pouviez associer des groupes SAML qu'aux rôles statiques de GitLab. Cela offre plus de flexibilité aux clients qui utilisent les liens de groupes SAML pour gérer l'appartenance aux groupes et les rôles des membres.

### Authentification SAML SSO pour l'approbation des merge requests {#saml-sso-authentication-for-merge-request-approval}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11084)

{{< /details >}}

Pour ceux qui utilisent SAML SSO et SCIM pour la gestion des comptes utilisateurs dans GitLab, vous pouvez désormais utiliser SSO pour satisfaire aux exigences d'authentification des merge requests au lieu de l'authentification par mot de passe pour approuver les merge requests.

Cette méthode garantit que seuls les utilisateurs authentifiés peuvent approuver une merge request à des fins de sécurité et de conformité, sans avoir à utiliser une solution distincte basée sur un mot de passe.

### Présentation d'une page d'accueil au niveau du groupe pour les tableaux de bord Analytics {#introduce-group-level-landing-page-for-analytics-dashboards}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/433420)

{{< /details >}}

Nous introduisons une nouvelle page d'accueil pour le tableau de bord d'analyse au niveau du groupe. Cette amélioration garantit une expérience de navigation plus cohérente et plus conviviale. Dans la première phase, cette page inclut le [Value Streams Dashboard](https://www.youtube.com/watch?v=8pLEucNUlWI), mais elle pose également les bases des fonctionnalités futures, vous permettant de personnaliser vos tableaux de bord. Ces améliorations visent à rationaliser votre expérience et à offrir plus de flexibilité dans la gestion et l'interprétation de vos données.

### Afficher tous les éléments ancêtres d'une tâche ou d'un OKR {#view-all-ancestor-items-of-a-task-or-okr}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/tasks.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11197)

{{< /details >}}

Avec cette release, vous pouvez désormais afficher l'ensemble de la hiérarchie d'un élément de travail au lieu de simplement son parent immédiat.

Les éléments de travail comprennent :

- Les tâches, dans toutes les éditions.
- [Objectifs et résultats clés](../../user/okrs.md), dans l'édition Ultimate et derrière un feature flag.

### Tableau de bord de la flotte de runners : export CSV des minutes de calcul utilisées par les runners d'instance {#runner-fleet-dashboard-csv-export-of-compute-minutes-used-by-instance-runners}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/runners/runner_fleet_dashboard.md#export-compute-minutes-used-by-instance-runners) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/425853)

{{< /details >}}

Vous pourriez avoir besoin d'exécuter un rapport sur les minutes de calcul CI/CD utilisées par les projets sur les runners d'instance pour diverses raisons. Cependant, il n'existait pas de mécanisme simple à utiliser dans GitLab pour générer un rapport d'utilisation des minutes de calcul CI/CD. Avec cette fonctionnalité, vous pouvez exporter un rapport des minutes de calcul CI/CD utilisées par chaque projet sur les runners partagés sous forme de fichier CSV.

### GitLab Runner 16.8 {#gitlab-runner-168}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.8 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et renvoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Réécriture des spécifications des pods Kubernetes générées - version bêta](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29659)

#### Corrections de bugs {#bug-fixes}

- [Le jeton d'authentification GitLab Runner est exposé dans le fichier journal du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37224)
- [L'enregistrement de plusieurs runners avec mise à l'échelle automatique génère un fichier config.toml partiel](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37197)
- [L'interruption de la tâche d'assistance restore_cache corrompt le cache](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36988)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-8-stable/CHANGELOG.md) de GitLab Runner.

### Variables prédéfinies pour la description de la merge request {#predefined-variables-for-merge-request-description}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/432846)

{{< /details >}}

Si vous utilisez l'automatisation pour travailler avec les merge requests dans les pipelines CI/CD, vous avez peut-être souhaité un moyen plus simple de récupérer la description d'une merge request sans appel API. Dans GitLab 16.7, nous avons introduit la variable prédéfinie `CI_MERGE_REQUEST_DESCRIPTION`, rendant la description facilement accessible dans tous les jobs. Dans GitLab 16.8, nous avons ajusté le comportement pour tronquer `CI_MERGE_REQUEST_DESCRIPTION` à 2 700 caractères, car les descriptions très longues peuvent provoquer des erreurs dans les runners. Vous pouvez vérifier si la description a été tronquée avec la variable prédéfinie `CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED` nouvellement introduite, qui est définie sur `true` lorsque la description a été tronquée.

### Prise en charge de Windows 2022 pour les runners SaaS sur Windows {#windows-2022-support-for-saas-runners-on-windows}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/windows.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438554)

{{< /details >}}

Les équipes peuvent désormais créer, tester et déployer des applications sur Windows Server 2022.

Les runners SaaS sur Windows vous permettent d'augmenter la vélocité de vos équipes de développement dans la création et le déploiement d'applications nécessitant Windows dans un environnement de build GitLab Runner sécurisé et à la demande, intégré à GitLab CI/CD.

Essayez-le dès aujourd'hui en utilisant `saas-windows-medium-amd64` comme tag dans votre fichier .GitLab-ci.yml.

### Section du catalogue CI/CD pour vos composants CI/CD internes {#cicd-components-catalog-section-for-your-internal-components}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/components/_index.md#cicd-catalog) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/437768)

{{< /details >}}

À mesure que le nombre d'éléments dans le catalogue CI/CD continue de croître, il devient de plus en plus difficile de localiser les composants CI/CD publiés par vos équipes et disponibles pour vous. Dans cette release, nous introduisons un onglet dédié **Vos groupes**, vous permettant de filtrer et d'identifier facilement les composants associés à votre organisation. Ce processus de recherche simplifié améliore l'efficacité, car vous pouvez trouver et utiliser plus rapidement les composants CI/CD publiés.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.8)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.8)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=16.8)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
