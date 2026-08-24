---
stage: Release Notes
group: Monthly Release
date: 2023-12-21
title: "Notes de release de GitLab 16.7"
description: "GitLab 16.7 est disponible avec GitLab Duo Code Suggestions en disponibilité générale"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 21 décembre 2023, GitLab 16.7 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

Alors que nous continuons à nous concentrer sur le développement de notre communauté élargie, nous sommes incroyablement heureux de voir les deux MVP nommés par des membres de [l'équipe Core](https://about.gitlab.com/community/core-team/).

Muhammed a été nommé pour avoir ajouté la prise en charge de [la spécification de la plateforme lors de l'utilisation d'images Docker avec GitLab Runner](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112907). Cette contribution a nécessité 9 mois de collaboration et a témoigné de l'engagement et de la persévérance de Muhammed lorsqu'un bug a nécessité un [suivi](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137100). Cela a résolu un [ticket](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919) populaire vieux de deux ans. « Bravo à l'équipe GitLab Runner » a déclaré Muhammed, « pour m'avoir soutenu dans la concrétisation d'une fonctionnalité très attendue ». Muhammed est ingénieur en automatisation chez [Airtime Rewards](https://www.airtimerewards.co.uk/), travaillant principalement avec Terraform et promouvant les pratiques CI/CD et d'automatisation au sein des équipes d'ingénierie.

Niklas a été nommé pour ses contributions et son soutien continus sous de nombreuses formes différentes. Aujourd'hui marque exactement 1 an depuis son dernier prix MVP. Niklas s'attaque à des travaux redoutables qui s'avèrent difficiles même pour les membres de l'équipe GitLab et joue un rôle majeur dans le maintien de nos contributeurs de la communauté élargie. En savoir plus dans le [ticket de nomination](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34762#note_1681021745).

Merci Muhammed et Niklas ! 🙌

## Fonctionnalités principales {#primary-features}

### GitLab Duo Code Suggestions est en disponibilité générale {#gitlab-duo-code-suggestions-is-generally-available}

<!-- categories: Code Suggestions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/code_suggestions/_index.md)

{{< /details >}}

[GitLab Duo Code Suggestions](https://about.gitlab.com/solutions/code-suggestions/) est désormais en disponibilité générale !

GitLab Duo Code Suggestions aide les équipes à créer des logiciels plus rapidement et plus efficacement, en complétant les lignes de code et en définissant et générant la logique des fonctions.

Code Suggestions a été conçu avec la confidentialité comme fondement essentiel. Le code client privé et non public stocké dans GitLab n'est pas utilisé comme données d'entraînement. Découvrez l'[utilisation des données](../../user/gitlab_duo/data_usage.md) lors de l'utilisation de Code Suggestions.

Dans la release générale, nous avons rendu [Code Suggestions disponible dans plusieurs IDE](../../user/project/repository/code_suggestions/_index.md). Code Suggestions est également plus intuitif et réactif.

GitLab Duo Code Suggestions est [gratuit à l'essai](../../user/project/repository/code_suggestions/_index.md) sous réserve de l'[accord de test GitLab](https://handbook.gitlab.com/handbook/legal/testing-agreement/) jusqu'au 15 février 2024. À partir d'aujourd'hui, vous pouvez acheter Code Suggestions en tant que module complémentaire aux abonnements GitLab pour un prix de lancement de 9 USD par utilisateur/par mois. Veuillez [nous contacter](https://about.gitlab.com/sales/) pour démarrer avec Code Suggestions.

### Utiliser GitLab Pages sans DNS générique {#use-gitlab-pages-without-a-wildcard-dns}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/pages/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)

{{< /details >}}

Auparavant, pour créer un projet GitLab Pages, vous aviez besoin d'un domaine formaté comme name.example.io ou name.pages.example.io. Cette exigence impliquait de configurer des enregistrements DNS génériques et des certificats SSL/TLS. Dans GitLab 16.7, vous pouvez configurer un projet GitLab Pages sans DNS générique. Cette fonctionnalité est une version expérimentale.

La suppression de l'exigence de certificats génériques réduit la charge administrative associée à GitLab Pages. Certains clients ne peuvent pas utiliser GitLab Pages en raison de restrictions organisationnelles sur les enregistrements DNS génériques ou les certificats.

Nous accueillons les commentaires liés à cette fonctionnalité dans le [ticket 434372](https://gitlab.com/gitlab-org/gitlab/-/issues/434372).

### Nouvelle vue d'exploration depuis les graphiques du rapport Insights {#new-drill-down-view-from-insights-report-charts}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/insights/_index.md#drill-down-on-charts) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/372215)

{{< /details >}}

Avec le [rapport Insights](https://www.youtube.com/watch?v=OMTfPsLa98I), vous pouvez analyser les tendances dans le temps à l'aide de graphiques personnalisables. La nouvelle fonctionnalité d'exploration ajoutée aux rapports Insights « Bugs créés par priorité » et « Bugs créés par gravité » vous permet d'explorer le rapport [Analyse des tickets](../../user/group/issues_analytics/_index.md) pour une analyse plus approfondie.

Nous prévoyons d'inclure cette fonctionnalité dans les autres rapports Insights en tant qu'option personnalisée dans une version ultérieure.

### Résultats SAST dans la vue des modifications de la merge request {#sast-results-in-mr-changes-view}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/application_security/sast/_index.md#merge-request-changes-view) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10959) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/432704)

{{< /details >}}

Les résultats SAST apparaissent désormais dans la vue Modifications de la merge request. Cela facilite la détection, la compréhension et la correction des faiblesses potentielles lors du processus de revue de code.

Les lignes contenant des problèmes SAST sont marquées par un symbole à côté de la gouttière. Sélectionnez le symbole pour afficher la liste des problèmes, puis sélectionnez un problème pour en afficher les détails.

Nous avons activé cette fonctionnalité sur GitLab.com. Nous prévoyons d'activer le [feature flag](https://gitlab.com/gitlab-org/gitlab/-/issues/410191) par défaut pour les instances Self-Managed dans GitLab 16.8.

### Catalogue CI/CD - version bêta {#cicd-catalog---beta-release}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/components/_index.md#cicd-catalog)

{{< /details >}}

GitLab 16.7 marque la version bêta du catalogue CI/CD ! Le catalogue est l'endroit où vous pouvez rechercher des [composants CI/CD](../../ci/components/_index.md) gérés par vous, votre organisation ou la communauté publique. C'est le lieu où les ingénieurs DevOps se réunissent pour créer, contribuer et partager des configurations de pipeline réutilisables.

Contrairement aux autres méthodes de réutilisation de la configuration CI/CD, les composants CI/CD publiés dans le catalogue offrent une expérience améliorée et s'ajoutent facilement à votre pipeline. Nous vous invitons à commencer à tester cette nouvelle fonctionnalité passionnante ! Vous pouvez essayer des composants que d'autres ont créés et partagés dans le catalogue, ou créer vos propres composants et les partager avec tout le monde.

Bien qu'il s'agisse de notre première version bêta de la fonctionnalité, nous continuons à travailler pour améliorer encore l'expérience. Notre objectif est de faire du catalogue CI/CD une partie fondamentale de l'expérience GitLab CI/CD.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Ajouter un identifiant Mastodon à votre profil utilisateur {#add-a-mastodon-handle-to-your-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/_index.md#add-external-accounts-to-your-user-profile-page) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/428442)

{{< /details >}}

Vous pouvez désormais afficher votre identifiant Mastodon sur le profil utilisateur. Grâce à cette amélioration, nous prenons désormais en charge un réseau social fediverse, ce qui contribuera à faire avancer [ActivityPub pour GitLab](https://gitlab.com/groups/gitlab-org/-/epics/11247).

### Descriptions de groupe étendues à 500 caractères {#group-descriptions-extended-to-500-characters}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/416146)

{{< /details >}}

Les descriptions de groupe peuvent désormais contenir jusqu'à 500 caractères. Si vous essayez d'enregistrer une description de groupe comportant plus de 500 caractères, un message d'avertissement s'affiche indiquant que la description est trop longue. Merci à @freznicek pour cette contribution communautaire !

### Barre de recherche plus visible sur la page des résultats de recherche {#search-bar-more-prominent-on-the-search-results-page}

<!-- categories: Global Search -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/424619)

{{< /details >}}

La barre de recherche est désormais plus visible sur la page des résultats de recherche. Pour améliorer la visibilité de la barre de recherche, les filtres de groupe et de projet ont été déplacés vers la barre latérale gauche.

### Tickets avec du code plus facilement découvrables dans la recherche avancée {#issues-with-code-more-discoverable-in-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/advanced_search.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/421012)

{{< /details >}}

Dans GitLab 16.7, les tickets contenant du code sont devenus plus faciles à découvrir. Avec la recherche avancée, vous pouvez désormais trouver des tickets contenant des extraits de code et des journaux dans leurs descriptions.

### Personnaliser le format d'affichage de l'heure {#customize-time-format-for-display}

<!-- categories: User Profile -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/preferences.md#customize-time-format) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/15206)

{{< /details >}}

Jusqu'à présent, GitLab affichait uniquement l'heure au format 12 heures, qui ne pouvait pas être modifié.

À partir de cette release, grâce à la contribution de la communauté, vous pouvez personnaliser le format utilisé pour afficher l'heure dans des endroits tels que les listes de tickets, les pages de présentation ou lors de la définition de votre statut. Vous pouvez afficher les heures sous les formats suivants :

- Format 12 heures, par exemple `2:34 PM`.
- Format 24 heures, par exemple `14:34`.

Merci à [Thorben Westerhuys](https://gitlab.com/n0rdlicht) pour cette [contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130789) !

Dans le jalon suivant, nous allons [auditer tous les horodatages](https://gitlab.com/groups/gitlab-org/-/epics/12215) affichés dans le produit GitLab pour les faire respecter ce paramètre.

### Accéder à la zone d'administration depuis la barre latérale gauche {#access-the-admin-area-from-the-left-sidebar}

<!-- categories: Navigation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/admin_area.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415854)

{{< /details >}}

Les administrateurs peuvent désormais accéder à la zone d'administration en une seule étape, en utilisant un lien au bas de la barre latérale gauche. Auparavant, vous deviez sélectionner **Rechercher ou accéder à** puis sélectionner **Admin Area**. Cette modification devrait vous faire gagner du temps lors de l'accès à la zone d'administration.

### Supprimer la limite de temps codée en dur pour l'achèvement des migrations {#remove-hardcoded-time-limit-for-migrations-to-complete}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/_index.md#limits) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/429867)

{{< /details >}}

Les migrations de groupes et de projets GitLab effectuées par transfert direct peuvent se bloquer pour diverses raisons. Par le passé, pour éviter de laisser ces migrations dans un état incomplet indéfiniment, GitLab exécutait périodiquement un worker pour identifier les migrations qui ne s'étaient pas terminées dans les 8 heures. GitLab marquait ces migrations comme ayant expiré.

Pour les grandes organisations, le processus de migration peut prendre plus de 8 heures, ce délai n'était donc pas toujours suffisant pour déterminer correctement si une migration était bloquée. Par conséquent, ce worker pourrait avoir incorrectement marqué une migration comme bloquée.

Dans ce jalon, au lieu d'utiliser une limite de temps de 8 heures, GitLab ne marque désormais la migration comme bloquée que si les workers enfants cessent de fonctionner pendant 24 heures.

### Résultats complets des importations par transfert direct {#comprehensive-results-of-imports-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/394727)

{{< /details >}}

Sachant combien il est crucial pour nos utilisateurs de comprendre les résultats du processus d'importation, nous avons encore amélioré dans ce jalon les informations présentées pour les importations par transfert direct. Nous affichons désormais des badges de statut d'importation à côté des groupes et projets GitLab sur :

- La [page où vous pouvez sélectionner les groupes et projets à importer](../../user/group/import/_index.md).
- La [page listant les groupes et projets importés](../../user/group/import/_index.md).

Les badges de statut d'importation sont :

- **Non commencée**
- **En attente**
- **Importation en cours**
- **Échec**
- **Délai d'attente**
- **Annulé**
- **Terminé**
- **Terminé partiellement**

Le badge **Partially completed badge** a été ajouté dans cette release et identifie un processus d'importation terminé qui contient des éléments (tels que des merge requests ou des tickets) non importés.

Les groupes pour lesquels un processus d'importation a été démarré disposent d'un lien **Afficher les détails** qui affiche les sous-groupes et projets importés pour ce groupe particulier. À partir de là, vous pouvez voir la liste des éléments qui n'ont pas pu être importés (le cas échéant) en cliquant sur un lien **See failures**. **See failures** a été [publié dans la dernière release](https://about.gitlab.com/releases/2023/11/16/gitlab-16-6-released/#comprehensive-list-of-items-that-failed-to-be-imported).

Dans ce jalon, nous avons également amélioré la navigation avec les fils d'Ariane entre ces pages.

### Rouvrir les tickets Service Desk lorsqu'un participant externe commente {#reopen-service-desk-issues-when-an-external-participant-comments}

<!-- categories: Service Desk -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/service_desk/configure.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/8549)

{{< /details >}}

Vous pouvez désormais configurer GitLab pour rouvrir les tickets fermés lorsqu'un participant externe ajoute un nouveau commentaire sur un ticket par e-mail. Cela vous donne une visibilité complète sur les conversations en cours, même après qu'un ticket a été résolu.

Un commentaire interne mentionnant les personnes assignées au ticket est également ajouté, créant des éléments de la liste de tâches pour elles. Ainsi, vous ne manquerez plus jamais un e-mail de suivi.

### Les sauvegardes prennent en charge des bibliothèques de compression alternatives {#backups-supports-alternate-compression-libraries}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/backup_restore/backup_gitlab.md#backup-compression)

{{< /details >}}

Vous pouvez désormais remplacer la bibliothèque de compression gzip monothread par défaut par une bibliothèque de compression alternative de votre choix pour les sauvegardes, à l'aide des commandes `COMPRESS_CMD` et `DECOMPRESS_CMD`. Cela vous permet de tirer parti de bibliothèques de compression parallèles pour accélérer l'étape de compression de la sauvegarde en utilisant la puissance des processeurs modernes multicœurs. Les commandes incluent la prise en charge du passage d'options à la bibliothèque de compression, vous permettant d'ajuster des paramètres tels que les niveaux de compression et la vitesse.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Définir une politique réseau avec des règles de sortie {#define-a-network-policy-with-egress-rules}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

Dans GitLab 16.7, vous pouvez désormais définir une politique réseau avec des règles de sortie lorsque vous configurez l'agent GitLab pour Kubernetes afin de prendre en charge les workspaces. Utilisez cette fonctionnalité pour votre installation auto-hébergée où l'instance GitLab résout vers une IP privée ou lorsqu'un workspace doit accéder à une ressource cloud sur une plage d'IP privée.

### Ajouter des emoji personnalisés aux groupes {#add-custom-emoji-to-groups}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/emoji_reactions.md)

{{< /details >}}

Qui n'aime pas un bon emoji pour vraiment s'exprimer ? Lorsque vous commentez des éléments dans GitLab, vous avez utilisé notre ensemble d'emoji par défaut pour ajouter des réactions, mais parfois ces emoji ne suffisaient pas à exprimer vos émotions. Les groupes peuvent désormais ajouter des emoji personnalisés à utiliser dans leurs projets. Les emoji personnalisés vous permettent d'exprimer vos véritables sentiments et de communiquer plus clairement avec le reste de votre équipe. Nous avons hâte de voir comment vous allez réagir.

### Les chaînes de dépendances complexes de merge requests sont désormais prises en charge {#complex-merge-request-dependency-chains-now-supported}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/dependencies.md#nested-dependencies)

{{< /details >}}

Les dépendances de merge requests GitLab sont un excellent moyen de garantir que les modifications de code qui dépendent d'autres modifications ne soient pas fusionnées d'une manière qui pourrait endommager la base de code. Auparavant, GitLab n'autorisait pas les chaînes de dépendances complexes, ce qui pouvait entraîner des références circulaires ou des imbrications profondes.

Les limitations concernant la hiérarchie des dépendances et les éléments de la chaîne ont été supprimées. Les dépendances de merge requests peuvent désormais être plus complexes : une seule merge request peut être bloquée par jusqu'à 10 merge requests et, à son tour, en bloquer jusqu'à 10 autres. Des chaînes de dépendances plus profondes permettent de représenter des workflows plus complexes via des dépendances. Nous sommes impatients de voir comment vous continuez à développer votre utilisation de cette fonctionnalité.

### Me notifier lorsqu'une merge request nécessite une approbation {#notify-me-when-any-merge-request-needs-approval}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/profile/notifications.md#edit-notification-settings)

{{< /details >}}

Lorsque votre approbation est requise pour une merge request, vous devez être notifié pour agir. Certains utilisateurs ne souhaitent des notifications que lorsque leur approbation est requise, ce qui se fait généralement en ajoutant un utilisateur par son nom pour réviser les modifications. Cependant, certains utilisateurs souhaitent recevoir une notification pour toute merge request qu'ils sont éligibles à approuver, *même s'ils ne sont pas ajoutés par leur nom en tant que relecteurs.*

Activez le niveau de notification personnalisé **Added as approver** pour déclencher un e-mail et un élément de la liste de tâches pour chaque merge request que vous êtes éligible à approuver. Cela vous aide à prendre connaissance des merge requests plus tôt dans le processus et à agir pour que la proposition soit fusionnée.

### Prise en charge bêta d'OpenTofu {#beta-support-for-opentofu}

<!-- categories: Infrastructure as Code -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/infrastructure/iac/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/terraform-images/-/issues/114)

{{< /details >}}

Si vous passez de Terraform à OpenTofu, cette release de GitLab ajoute une prise en charge préliminaire d'OpenTofu. Comme OpenTofu est un fork de Terraform, l'intégration du widget MR, le registre de modules et l'état Terraform géré par GitLab fonctionnent par défaut. Nous avons ajouté la prise en charge d'OpenTofu dans l'image d'assistance `gitlab-terraform` pour simplifier l'utilisation de l'offre GitLab IaC.

GitLab continue de prendre en charge Terraform pour le widget MR, le registre de modules et l'état Terraform géré par GitLab.

### Période personnalisée pour la rotation des jetons d'accès {#custom-time-period-for-access-tokens-rotation}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/personal_access_tokens.md#rotate-a-personal-access-token) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/416795)

{{< /details >}}

Vous pouvez désormais saisir optionnellement un nouveau paramètre, `expires_at`, lors de la rotation d'un jeton d'accès. Cela vous permet de créer une date d'expiration personnalisée pour le jeton. Auparavant, chaque rotation prolongeait l'expiration d'une semaine par rapport à la date d'expiration précédente. Cette nouvelle option offre de la flexibilité dans l'intervalle de rotation.

### Utiliser l'interface utilisateur pour attribuer des utilisateurs à des rôles personnalisés {#use-the-ui-to-assign-users-to-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/393239)

{{< /details >}}

Vous pouvez désormais utiliser l'interface utilisateur pour attribuer un rôle personnalisé à un nouvel utilisateur ou modifier le rôle d'un utilisateur existant en un rôle personnalisé. Vous pouvez effectuer cette opération dans n'importe quelle partie de l'interface utilisateur où vous pouvez actuellement attribuer ou modifier le rôle d'un utilisateur. Auparavant, vous ne pouviez effectuer cette opération que via l'API.

### Appliquer des variables dans les politiques d'exécution de scan avec la priorité la plus élevée {#enforce-variables-in-scan-execution-policies-with-the-highest-precedence}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/variables/_index.md#cicd-variable-precedence) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/424028)

{{< /details >}}

La priorité des variables CI/CD a été améliorée pour prioriser en premier les variables définies dans les politiques d'exécution de scan.

Alors que les organisations s'efforcent de répondre aux exigences de conformité, un besoin courant est de s'assurer que les scanners de sécurité sont activés dans les applications critiques pour l'entreprise.

Les politiques d'exécution de scan permettent aux équipes d'appliquer des scanners et de définir des variables CI/CD par défaut et personnalisées. Grâce à cette amélioration de la priorité des variables CI/CD, les équipes peuvent être certaines que, quelle que soit la manière dont les pipelines sont déclenchés, les variables définies dans une optique de conformité restent intactes.

### Les instructions d'attributs SAML prennent en charge le format d'attribut SAML Microsoft {#saml-attribute-statements-support-microsoft-saml-attribute-format}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/saml.md#configure-assertions) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/420766)

{{< /details >}}

Les instructions d'attributs SAML prennent désormais en charge le format d'attribut SAML Microsoft, qui est sous forme d'URL. Auparavant, les administrateurs d'instances auto-gérées devaient configurer manuellement les instructions d'attributs, et les propriétaires de groupes GitLab.com devaient ajouter des attributs personnalisés à leurs réponses SAML. Cette modification permet à GitLab auto-géré et à GitLab.com de fonctionner avec Microsoft sans aucune configuration manuelle.

### Améliorations de l'éditeur de texte enrichi {#improvements-to-rich-text-editor}

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/rich_text_editor.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136437)

{{< /details >}}

Dans GitLab 16.2, nous avons publié l'éditeur de texte enrichi comme alternative à l'expérience d'édition Markdown existante. L'éditeur de texte enrichi offre une expérience d'édition « ce que vous voyez est ce que vous obtenez » et une base extensible sur laquelle nous pouvons construire des interfaces d'édition personnalisées pour des éléments tels que les diagrammes, les incorporations de contenu, la gestion des médias, et plus encore.

Avec GitLab 16.7, nous avons modifié l'éditeur de texte enrichi pour correspondre au comportement de notre expérience d'édition Markdown et corriger les bugs signalés. Nous avons [modifié l'ordre de tri dans la modale de saisie automatique des labels pour qu'il soit cohérent entre l'éditeur Markdown et l'éditeur de texte enrichi](https://gitlab.com/gitlab-org/gitlab/-/issues/419097), [corrigé un bug dans les options renvoyées par l'action rapide de désassignation dans l'éditeur de texte enrichi](https://gitlab.com/gitlab-org/gitlab/-/issues/420344), [ajouté la prise en charge des emoji personnalisés](https://gitlab.com/gitlab-org/gitlab/-/issues/422958) et [mis à jour l'apparence du menu déroulant de sélection des actions rapides pour qu'il soit cohérent dans les deux expériences d'édition](https://gitlab.com/gitlab-org/gitlab/-/issues/406714), entre autres améliorations.

### Lister les tags du dépôt avec la nouvelle API du registre de conteneurs {#list-repository-tags-with-new-container-registry-api}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../api/container_registry.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/411387)

{{< /details >}}

Auparavant, le registre de conteneurs s'appuyait sur l'[API de registre de listing des tags d'images](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/docker/v2/api.md#listing-image-tags) Docker/OCI pour lister et afficher les tags dans GitLab. Cette API présentait des limitations importantes en termes de performances et de découvrabilité.

Cette API était lente car le nombre de requêtes réseau vers le registre augmentait proportionnellement au nombre de tags dans la liste des tags. De plus, comme l'API ne suivait pas l'heure de publication, l'horodatage de publication était souvent incorrect. Il y avait également des limitations lors de l'affichage des images basées sur des listes de manifestes Docker ou des index OCI, par exemple pour les images multi-architecture.

Pour remédier à ces limitations, nous avons introduit une nouvelle [API de listing des tags du dépôt](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/gitlab/api.md#list-repository-tags) pour le registre. En mettant à jour l'interface utilisateur pour utiliser la nouvelle API, le nombre de requêtes vers le registre de conteneurs est réduit à une seule. Les horodatages de publication sont également précis, et la prise en charge des images multi-architecture est plus robuste.

Cette fonctionnalité est disponible uniquement sur GitLab.com. La prise en charge pour les instances auto-gérées est bloquée jusqu'à ce que le registre de conteneurs de nouvelle génération soit en disponibilité générale. Pour en savoir plus, consultez le [ticket 423459](https://gitlab.com/gitlab-org/gitlab/-/issues/423459).

### Renommer des projets avec des images de conteneur dans le registre de conteneurs sur GitLab.com {#rename-projects-with-container-images-in-the-container-registry-on-gitlabcom}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Free, Silver, Gold
- Liens : [Documentation](../../user/project/working_with_projects.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10433)

{{< /details >}}

Avant cette release, vous ne pouviez pas renommer un projet disposant d'un dépôt de conteneurs avec au moins un tag sans avoir d'abord supprimé toutes les images de conteneur associées à ce projet.

C'était un vrai problème qui obligeait les utilisateurs à recourir à des scripts personnalisés pour supprimer/déplacer manuellement tous les tags avant de pouvoir utiliser un nom de projet différent, mais vous pouvez désormais renommer des projets sur GitLab.com, même s'ils contiennent des images de conteneur dans le registre !

### Filtrer par plages de dates prédéfinies dans Value Stream Analytics {#filter-by-predefined-date-ranges-in-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/value_stream_analytics/_index.md#data-filters) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/408656)

{{< /details >}}

Le rapport d'analyse de la chaîne de valeur dispose désormais d'un ensemble d'options de filtre pour les données des 30, 60, 90 ou 180 derniers jours. Ces nouvelles options de filtre simplifient le processus de sélection des dates, rendant plus efficace et plus conviviale la compréhension de [où le temps est passé pendant le cycle de vie du développement](https://about.gitlab.com/blog/value-stream-total-time-chart/).

### Prise en charge de la détection continue des vulnérabilités pour l'analyse des dépendances {#support-for-continuous-vulnerability-scanning-for-dependency-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/continuous_vulnerability_scanning/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11474)

{{< /details >}}

La détection continue des vulnérabilités est désormais en disponibilité générale. Avec CVS activé, vos projets sont automatiquement analysés lorsque des avis sont ajoutés à la base de données de conseils de sécurité GitLab. Si de nouvelles vulnérabilités liées aux dépendances sont identifiées, des vulnérabilités sont créées automatiquement.

### Mises à jour des vérifications de vulnérabilités DAST {#dast-vulnerability-check-updates}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/checks/_index.md#active-checks)

{{< /details >}}

Durant le jalon de la release 16.7, nous avons activé par défaut les vérifications actives suivantes pour DAST basé sur le navigateur :

- La vérification 89.1 remplace les vérifications ZAP 40018, 40019, 40020, 40021, 40022, 40024, 40027, 40033 et 90018 et identifie les injections SQL.
- La vérification 918.1 remplace la vérification ZAP 40046 et identifie les requêtes côté serveur falsifiées (Server Side Request Forgery).
- La vérification 98.1 remplace la vérification ZAP 7 et identifie l'inclusion de fichiers distants PHP.
- La vérification 917.1 remplace la vérification ZAP 90025 et identifie l'injection de langage d'expression.
- La vérification 1336.1 remplace la vérification ZAP 90035 et identifie l'injection de templates côté serveur.

### L'authentification DAST prend désormais en charge les formulaires de connexion multi-étapes {#dast-authentication-now-supports-multi-step-login-forms}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/configuration/authentication.md#configuration-for-a-multi-step-login-form) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11585)

{{< /details >}}

La nouvelle variable `DAST_AFTER_LOGIN_ACTIONS` vous permet de fournir une liste d'actions à exécuter après la connexion. Cela permet des interactions de connexion multi-étapes, par exemple le workflow « Keep Me Signed In » d'Azure AD.

### Mise à jour des règles SAST pour réduire les faux positifs {#updated-sast-rules-to-reduce-false-positive-results}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/rules.md#important-rule-changes) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/8170)

{{< /details >}}

Nous avons mis à jour l'ensemble de règles par défaut utilisé dans GitLab SAST pour fournir des résultats de meilleure qualité. Nous avons analysé chaque règle précédemment incluse par défaut, puis supprimé les règles qui n'apportaient pas suffisamment de valeur dans la plupart des bases de code.

Les modifications de règles sont incluses dans les versions mises à jour de l'[analyseur](../../user/application_security/sast/analyzers.md) GitLab SAST basé sur Semgrep. Cette mise à jour est automatiquement appliquée sur GitLab 16.0 ou version ultérieure, sauf si vous avez [épinglé les analyseurs SAST à une version spécifique](../../user/application_security/sast/_index.md).

Les résultats d'analyse existants des règles supprimées sont [automatiquement résolus](../../user/application_security/sast/_index.md#automatic-vulnerability-resolution) après que votre pipeline exécute une analyse avec l'analyseur mis à jour.

Nous travaillons sur d'autres améliorations des règles SAST dans l'[epic 10907](https://gitlab.com/groups/gitlab-org/-/epics/10907).

### Le mot-clé CI/CD `artifacts:public` est désormais en disponibilité générale {#artifactspublic-cicd-keyword-now-generally-available}

<!-- categories: Job Artifacts -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#artifactspublic) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11667)

{{< /details >}}

Auparavant, le mot-clé `artifacts:public` n'était disponible qu'en tant que fonctionnalité désactivée par défaut pour les instances auto-gérées. Désormais, dans GitLab 16.7, nous avons rendu le mot-clé `artifacts:public` généralement disponible pour tous les utilisateurs. Vous pouvez désormais utiliser le mot-clé `artifacts:public` dans les fichiers de configuration CI/CD pour contrôler si les artefacts de job doivent être accessibles publiquement.

### Amélioration de la capacité à conserver les derniers artefacts de job {#improved-ability-to-keep-the-latest-job-artifacts}

<!-- categories: Job Artifacts -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/428408)

{{< /details >}}

Dans GitLab 13.0, nous avons introduit la possibilité de conserver les artefacts de job du pipeline réussi le plus récent. Malheureusement, la fonctionnalité marquait également tous les pipelines ayant [échoué](https://gitlab.com/gitlab-org/gitlab/-/issues/266958) et [bloqués](https://gitlab.com/gitlab-org/gitlab/-/issues/387087) comme le dernier pipeline, que ce soient les plus récents ou non. Cela a entraîné une accumulation d'artefacts dans le stockage qui devaient être supprimés manuellement.

Dans GitLab 16.7, les bugs à l'origine de ce comportement non intentionnel sont résolus. Les artefacts de job provenant de pipelines ayant échoué ou bloqués ne sont conservés que s'ils proviennent du pipeline le plus récent, sinon ils suivront la configuration `expire_in`. Les clients GitLab.com concernés devraient voir les artefacts qui avaient été conservés par inadvertance désormais déverrouillés et supprimés après une nouvelle exécution de pipeline.

Le paramètre **Conserver les artéfacts des jobs réussis les plus récents** remplace la configuration `artifacts: expire_in` du job et peut entraîner un grand nombre d'artefacts stockés sans expiration. Si vos pipelines créent de nombreux artefacts volumineux, ils peuvent rapidement remplir votre quota de stockage de projet. Nous recommandons de désactiver ce paramètre si cette fonctionnalité n'est pas requise.

### GitLab Runner 16.7 {#gitlab-runner-167}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.7 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et renvoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Implémenter un arrêt gracieux pour l'exécuteur Docker](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6359)
- [Créer dynamiquement des volumes PVC avec des classes de stockage pour Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27835)

#### Corrections de bugs {#bug-fixes}

- [allow_failure:exit codes inutilisables avec l'exécuteur personnalisé car le code de sortie est toujours 1](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28658)
- [Améliorer la gestion des signaux dans le helper runner et le conteneur de build pour l'exécuteur Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36996)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-7-stable/CHANGELOG.md) de GitLab Runner.

### GitLab Runner prend en charge la déclaration SLSA v1.0 {#gitlab-runner-supports-slsa-v10-statement}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/runners/configure_runners.md#artifact-provenance-metadata) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36869)

{{< /details >}}

Les runners peuvent désormais générer des métadonnées de provenance avec une déclaration conforme à [SLSA 1.0](https://slsa.dev/spec/v1.0/). Pour activer SLSA 1.0, définissez la variable `SLSA_PROVENANCE_SCHEMA_VERSION=v1` dans le fichier `.gitlab-ci.yml`. La déclaration SLSA version 1.0 est prévue pour devenir la version par défaut dans GitLab 17.0.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.7)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.7)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=16.7)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
