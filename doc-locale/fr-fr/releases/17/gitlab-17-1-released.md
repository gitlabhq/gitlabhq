---
stage: Release Notes
group: Monthly Release
date: 2024-06-20
title: "Notes de release de GitLab 17.1"
description: "GitLab 17.1 est sorti avec le registre de modèles disponible en version bêta"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 20 juin 2024, GitLab 17.1 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination ! 🙌

Shubham Kumar [a résolu 7 tickets durant la version 17.1](https://gitlab.com/dashboard/issues?sort=due_date_desc&state=closed&assignee_username%5B%5D=imskr&milestone_title=17.1) et contribue régulièrement à GitLab depuis 2021. Il a désormais atteint plus de 50 contributions fusionnées ! Shubham est un [GitLab Hero](https://contributors.gitlab.com/docs/previous-heroes) et un ancien contributeur Google Summer of Code.

Shubham a été nommé par [Christina Lohr](https://gitlab.com/lohrc), Senior Product Manager chez GitLab. « Shubham a contribué à la résolution de nombreux tickets au cours des dernières semaines et des derniers mois, notamment en comblant les lacunes de notre offre d'API », déclare Christina. « Je n'arrive pas à rédiger les articles de release assez vite pour toutes les contributions que Shubham pousse ! »

« La communauté open source est extraordinaire », déclare Shubham. « Je suis reconnaissant pour cette opportunité et cette reconnaissance, et j'espère continuer à contribuer à la plateforme GitLab. »

Joe Snyder a été nommé par [Kai Armstrong](https://gitlab.com/phikai), Principal Product Manager chez GitLab, pour avoir développé une fonctionnalité très demandée permettant de [restreindre l'inclusion des diffs dans les e-mails](https://gitlab.com/gitlab-org/gitlab/-/issues/24733). Cette contribution a nécessité plus de 10 merge requests remontant à GitLab 15.3. « Il s'agit d'une fonctionnalité massive qui a nécessité de nombreux jalons, des migrations complexes et des modifications du produit pour en permettre la prise en charge », déclare Kai. « Joe a travaillé sans relâche avec de nombreux mainteneurs et collaborateurs tout au long des jalons pour mener à bien ce travail. »

[Jocelyn Eillis](https://gitlab.com/jocelynjane), Product Manager chez GitLab, a soutenu la nomination de Joe en mettant en avant un travail supplémentaire pour corriger un bug où [les variables imbriquées dans `build:resource_group` ne sont pas développées](https://gitlab.com/gitlab-org/gitlab/-/issues/361438). « Ce bug avait 23 votes positifs, en plus de la demande documentée des clients dans le ticket lui-même », déclare Jocelyn. « La réactivité aux retours des relecteurs nous a permis d'intégrer cela dans GitLab 17.1 ! »

C'est le deuxième titre de GitLab MVP de Joe, après avoir déjà été récompensé dans [GitLab 16.6](https://about.gitlab.com/releases/2023/11/16/gitlab-16-6-released/#mvp). Joe est Senior R&D Engineer chez [Kitware](https://www.kitware.com/) et contribue à GitLab depuis 2021.

## Fonctionnalités principales {#primary-features}

### Registre de modèles disponible en version bêta {#model-registry-available-in-beta}

<!-- categories: MLOps -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/ml/model_registry/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9423)

{{< /details >}}

GitLab prend désormais officiellement en charge le registre de modèles en version bêta en tant que concept de premier ordre. Vous pouvez ajouter et modifier des modèles directement via l'interface utilisateur, ou utiliser l'intégration MLflow pour utiliser GitLab comme backend de registre de modèles.

Un registre de modèles est un hub qui aide les équipes de data science à gérer les modèles de machine learning et leurs métadonnées associées. Il sert de point central permettant aux organisations de stocker, versionner, documenter et découvrir des modèles de machine learning entraînés. Il garantit une meilleure collaboration, une meilleure reproductibilité et une meilleure gouvernance sur l'ensemble du cycle de vie du modèle.

Nous considérons le registre de modèles comme un concept fondateur qui permet aux équipes de collaborer, de déployer, de surveiller et d'entraîner continuellement des modèles, et nous sommes très intéressés par vos retours. N'hésitez pas à nous laisser un message dans notre [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/465405) et nous vous recontacterons !

### Voir plusieurs suggestions de code GitLab Duo dans VS Code {#see-multiple-gitlab-duo-code-suggestions-in-vs-code}

<!-- categories: Editor Extensions, Code Suggestions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/code_suggestions/_index.md#view-multiple-code-suggestions) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1325)

{{< /details >}}

GitLab Duo Code Suggestions dans VS Code vous indique désormais si plusieurs suggestions sont disponibles. Il suffit de survoler la suggestion et d'utiliser les flèches ou le raccourci clavier pour parcourir les suggestions.

### Secret Push Protection disponible en version bêta {#secret-push-protection-available-in-beta}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/application_security/secret_detection/secret_push_protection/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/12729)

{{< /details >}}

Si un secret, comme une clé ou un jeton d'API, est accidentellement commité dans un dépôt Git, toute personne ayant accès au dépôt peut usurper l'identité de l'utilisateur du secret à des fins malveillantes. Pour faire face à ce risque, la plupart des organisations exigent que les secrets exposés soient révoqués et remplacés, mais vous pouvez réduire le temps de remédiation et limiter les risques en empêchant les secrets d'être poussés dès le départ.

Secret Push Protection vérifie le contenu de chaque commit poussé vers GitLab. [Si des secrets sont détectés](../../user/application_security/secret_detection/secret_push_protection/_index.md#detected-secrets), le push est bloqué et affiche des informations sur le commit, notamment :

- L'ID du commit contenant le secret.
- Le nom du fichier et le numéro de ligne contenant le secret.
- Le type de secret.

Vous avez besoin de contourner Secret Push Protection pour les tests ? Lorsque vous ignorez la détection des secrets lors du push, GitLab enregistre un événement d'audit pour vous permettre d'enquêter.

Secret Push Protection est disponible sur GitLab.com et pour les clients GitLab Dedicated en tant que fonctionnalité bêta et peut être activée [par projet](../../user/application_security/secret_detection/secret_push_protection/_index.md#enable-secret-push-protection-in-a-project). Vous pouvez nous aider à améliorer Secret Push Protection en fournissant vos retours dans le [ticket 467408](https://gitlab.com/gitlab-org/gitlab/-/issues/467408).

### GitLab Runner Autoscaler est en disponibilité générale {#gitlab-runner-autoscaler-is-generally-available}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner/runner_autoscale/) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29221)

{{< /details >}}

Dans les versions antérieures de GitLab, certains clients avaient besoin d'une solution de mise à l'échelle automatique pour GitLab Runner sur des instances de machines virtuelles sur des plateformes cloud publiques. Ces clients devaient s'appuyer sur l'[exécuteur Docker Machine](https://docs.gitlab.com/runner/configuration/autoscale/) hérité ou sur des solutions personnalisées assemblées à l'aide des technologies des fournisseurs cloud.

Aujourd'hui, nous sommes heureux d'annoncer la disponibilité générale du GitLab Runner Autoscaler. Le GitLab Runner Autoscaler est composé des technologies taskscaler et [fleeting](https://docs.gitlab.com/runner/fleet_scaling/fleeting/) développées par GitLab, ainsi que du plugin de fournisseur cloud pour Google Compute Engine.

### L'application connecteur GitLab est désormais disponible sur le Snowflake Marketplace {#gitlab-connector-application-now-available-on-the-snowflake-marketplace}

<!-- categories: Audit Events, Compliance Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/snowflake.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13004)

{{< /details >}}

Les événements d'audit sont créés et stockés dans GitLab. Avant cette release, les événements d'audit n'étaient accessibles que depuis GitLab, avec des résultats consultables via l'interface utilisateur GitLab ou en définissant une destination de streaming pour recevoir tous les événements d'audit sous forme de JSON structuré.

Cependant, les clients souhaitaient également pouvoir disposer des événements d'audit dans des destinations tierces (telles que des solutions SIEM comme Snowflake) afin de faciliter :

- L'affichage, la combinaison, la manipulation et la génération de rapports sur l'ensemble des données d'événements d'audit provenant des multiples systèmes d'une organisation, y compris GitLab.
- La consultation uniquement des événements d'audit qui les intéressent afin de pouvoir répondre rapidement aux questions qu'ils se posent.
- Une vue d'ensemble complète de ce qui se passe dans GitLab, avec la possibilité de la consulter après coup.

Pour aider les clients dans ces tâches, nous avons créé une application connecteur GitLab pour le [Snowflake Marketplace](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector), qui utilise l'API des événements d'audit. Pour utiliser cette fonctionnalité, les clients doivent déployer et gérer l'application via le Snowflake Marketplace.

### Amélioration de l'expérience utilisateur du wiki {#improved-wiki-user-experience}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/wiki/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/452225)

{{< /details >}}

La fonctionnalité wiki de GitLab 17.1 offre un flux de travail plus unifié et plus efficace :

- [Un clonage plus facile et plus rapide](https://gitlab.com/gitlab-org/gitlab/-/issues/281830) grâce à un nouveau bouton de clonage du dépôt. Cela améliore la collaboration et accélère l'accès au contenu du wiki pour l'édition ou la consultation.
- [Une option de suppression plus visible](https://gitlab.com/gitlab-org/gitlab/-/issues/335169) dans un emplacement plus facilement accessible. Cela réduit le temps passé à la rechercher et minimise les erreurs ou la confusion potentielles lors de la gestion des pages du wiki.
- [La possibilité de valider des pages vides](https://gitlab.com/gitlab-org/gitlab/-/issues/221061), améliorant ainsi la flexibilité. Créez des espaces réservés vides quand vous en avez besoin. Concentrez-vous sur une meilleure planification et organisation du contenu du wiki, et remplissez les pages vides ultérieurement.

Ces améliorations facilitent l'utilisation, la découvrabilité et la gestion du contenu dans le flux de travail de votre wiki. Nous souhaitons que votre expérience du wiki soit efficace et conviviale. En rendant le clonage des dépôts plus accessible, en repositionnant les options clés pour une meilleure visibilité et en permettant la création d'espaces réservés vides, nous améliorons notre plateforme pour mieux répondre aux besoins de vos utilisateurs.

### Nouvel outil de génération de rapports Value Stream Management {#new-value-stream-management-report-generator-tool}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md#schedule-reports) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/10880)

{{< /details >}}

Avec l'ajout du nouvel outil de génération de rapports pour Value Stream Management, nous permettons aux décideurs d'être plus efficaces dans l'optimisation du cycle de vie du développement logiciel (SDLC).

Vous pouvez désormais planifier la livraison automatique et proactive de [rapports de métriques de comparaison DevSecOps](https://gitlab.com/components/vsd-reports-generator#example-for-monthly-executive-value-streams-report) ou du rapport [AI Impact analytics](https://about.gitlab.com/releases/2024/05/16/gitlab-17-0-released/#ai-impact-analytics-in-the-value-streams-dashboard), avec des informations pertinentes dans les tickets GitLab. Grâce aux rapports planifiés, les responsables peuvent se concentrer sur l'analyse des insights et la prise de décisions éclairées, plutôt que de passer du temps à rechercher manuellement le bon tableau de bord avec les données requises.

Vous pouvez accéder à l'outil de rapports planifiés via le [catalogue CI/CD](https://gitlab.com/explore/catalog).

### Images de conteneurs liées aux signatures {#container-images-linked-to-signatures}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/packages/container_registry/_index.md#container-image-signatures) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/7856)

{{< /details >}}

Le registre de conteneurs GitLab associe désormais les images de conteneurs signées à leurs signatures. Grâce à cette amélioration, les utilisateurs peuvent plus facilement :

- Identifier quelles images sont signées et lesquelles ne le sont pas.
- Trouver et valider les signatures associées à une image de conteneur.

Cette amélioration est disponible en disponibilité générale uniquement sur GitLab.com. La prise en charge des instances auto-hébergées est en version bêta et nécessite que les utilisateurs activent le [registre de conteneurs de nouvelle génération](../../administration/packages/container_registry_metadata_database.md), également en version bêta.

### Confirmation requise pour les jobs manuels {#require-confirmation-for-manual-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/job_control.md#require-confirmation-for-manual-jobs) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/18906)

{{< /details >}}

Les jobs manuels peuvent être utilisés pour déclencher des opérations hautement critiques dans votre pipeline CI/CD, comme le déploiement en production. Avec cette release, vous pouvez désormais configurer un job manuel pour exiger une confirmation avant son exécution. Utilisez `manual_confirmation` avec `when: manual` pour afficher une boîte de dialogue de confirmation dans l'interface utilisateur lorsqu'un job est exécuté manuellement. Exiger une confirmation pour les jobs manuels apporte une couche de sécurité et de contrôle supplémentaire.

Remerciements particuliers à [Phawin](https://gitlab.com/lifez) pour cette contribution communautaire !

### Tableau de bord de flotte de runners pour les groupes {#runner-fleet-dashboard-for-groups}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/runners/runner_fleet_dashboard_groups.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/424789)

{{< /details >}}

Les opérateurs de flottes de runners auto-hébergées au niveau du groupe ont besoin d'observabilité et de la capacité à répondre rapidement à des questions critiques concernant leur infrastructure de flotte de runners en un coup d'œil. Avec le tableau de bord de flotte de runners pour les groupes, vous disposez directement de l'observabilité de la flotte de runners et d'insights exploitables dans l'interface utilisateur GitLab. Vous pouvez désormais déterminer rapidement l'état de santé des runners et obtenir des insights sur les métriques d'utilisation des runners ainsi que sur les capacités de service de la file d'attente des jobs CI/CD, dans le cadre des objectifs de niveau de service cibles de votre organisation.

Les clients sur GitLab.com peuvent utiliser dès aujourd'hui toutes les métriques du tableau de bord de flotte disponibles pour les groupes. Les clients auto-hébergés peuvent utiliser la plupart des métriques du tableau de bord de flotte, mais doivent configurer la base de données analytique ClickHouse pour utiliser les métriques **Runner usage** et **Temps d'attente pour récupérer un job**.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.1 inclut des paquets pour la prise en charge d'[Ubuntu Noble 24.04](../../install/package/_index.md).

### Nouvel argument d'API GraphQL `markedForDeletionOn` pour les groupes et les projets {#new-graphql-api-argument-markedfordeletionon-for-groups-and-projects}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/graphql/reference/_index.md#querygroups) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/463809)

{{< /details >}}

Vous pouvez désormais utiliser le nouvel argument d'API GraphQL `markedForDeletionOn` pour lister les groupes ou les projets qui ont été marqués pour suppression à une date spécifique.

Merci à [@imskr](https://gitlab.com/imskr) pour cette contribution communautaire !

### Nouveaux espaces réservés pour les badges de groupe et de projet {#new-placeholders-for-group-and-project-badges}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/badges.md#placeholders) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/22278)

{{< /details >}}

Vous pouvez désormais créer des liens de badge et des URL d'image en utilisant quatre nouveaux espaces réservés :

- `%{project_namespace}` - référençant le chemin complet d'un espace de nommage de projet
- `%{group_name}` - référençant le nom du groupe
- `%{gitlab_server}` - référençant le nom du serveur du groupe ou du projet
- `%{gitlab_pages_domain}` - référençant le nom de domaine du groupe ou du projet

Merci à [@TamsilAmani](https://gitlab.com/TamsilAmani) pour cette contribution communautaire !

### Nouvel espace réservé `%{latest_tag}` pour les badges {#new-latest_tag-placeholder-for-badges}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/badges.md#placeholders) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/26420)

{{< /details >}}

Vous pouvez désormais créer des liens de badge et des URL d'image en utilisant un espace réservé `%{latest_tag}`. Cet espace réservé fait référence au dernier tag publié pour un dépôt.

Merci à [@TamsilAmani](https://gitlab.com/TamsilAmani) pour cette contribution communautaire !

### Filtrer les groupes par date `marked_for_deletion_on` avec l'API Groups {#filter-groups-by-marked_for_deletion_on-date-with-the-groups-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/groups.md#list-groups) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/429315)

{{< /details >}}

Vous pouvez désormais filtrer les réponses dans l'API Groups en utilisant l'attribut `marked_for_deletion_on`, qui renvoie les groupes qui ont été marqués pour suppression à une date spécifique.

Merci à [@imskr](https://gitlab.com/imskr) pour cette contribution communautaire !

### Lister les projets auxquels un utilisateur a contribué avec l'API GraphQL {#list-contributed-projects-of-a-user-with-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/graphql/reference/_index.md#usercontributedprojects) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/450191)

{{< /details >}}

Vous pouvez désormais utiliser le nouveau champ d'API GraphQL `User.contributedProjects` pour lister les projets auxquels un utilisateur a contribué.

Merci à [@yasuk](https://gitlab.com/yasuk) pour cette contribution communautaire !

### Ajouter des membres par nom d'utilisateur avec l'API Members {#add-members-by-username-with-the-members-api}

<!-- categories: User Management, Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/group_members.md#add-a-group-member) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/28208)

{{< /details >}}

Auparavant, lors de l'utilisation de l'API Members, vous pouviez uniquement ajouter des membres à des groupes et des projets par leur ID utilisateur. Avec cette release, vous pouvez désormais également ajouter des membres par leur nom d'utilisateur.

Merci à [@imskr](https://gitlab.com/imskr) pour cette contribution communautaire !

### Mise à jour des fonctionnalités de tri et de filtrage dans Explore {#updated-sorting-and-filtering-functionality-in-explore}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance)

{{< /details >}}

Nous avons mis à jour les fonctionnalités de tri et de filtrage des pages Explore pour les groupes et les projets. La barre de filtrage est désormais plus large pour une meilleure lisibilité.

Dans la page Explore pour les projets, vous pouvez désormais utiliser des options de tri standardisées incluant **Nom**, **Date de création**, **Date de mise à jour** et **Favori**, ainsi qu'un élément de navigation pour trier par ordre croissant ou décroissant. Le filtre de langue a été déplacé vers le menu de filtrage. Un nouvel onglet **Inactif** affiche les projets archivés pour une recherche plus ciblée. De plus, vous pouvez utiliser un filtre **Rôle** pour rechercher les projets dont vous êtes le propriétaire.

Dans la page Explore pour les groupes, nous avons standardisé les options de tri pour inclure **Nom**, **Date de création** et **Date de mise à jour**, et ajouté un élément de navigation pour trier par ordre croissant ou décroissant.

Nous accueillons vos retours sur ces modifications dans le [ticket 438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322).

### Amélioration de la sélection du niveau de visibilité {#improved-visibility-level-selection}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/public_access.md#change-group-visibility) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/455668)

{{< /details >}}

Auparavant, les paramètres généraux d'un groupe ou d'un projet n'affichaient que les niveaux de visibilité autorisés. Cette vue semait souvent la confusion chez les utilisateurs qui cherchaient à comprendre pourquoi les autres options n'étaient pas disponibles, et pouvait conduire à un affichage incorrect des informations. La nouvelle vue affiche tous les niveaux de visibilité, en grisent les options qui ne peuvent pas être sélectionnées. De plus, une fenêtre contextuelle fournit des informations supplémentaires sur la raison pour laquelle une option n'est pas disponible. Par exemple, un niveau de visibilité peut être indisponible parce qu'un administrateur l'a restreint, ou parce qu'il créerait un conflit avec le paramètre de visibilité d'un projet ou d'un groupe parent.

Nous espérons que ces modifications vous aideront à résoudre les conflits lors de la sélection de l'option de visibilité souhaitée. Merci à [@gerardo-navarro](https://gitlab.com/gerardo-navarro) pour cette contribution communautaire !

### Filtrer les projets par date `marked_for_deletion_on` avec l'API Projects {#filter-projects-by-marked_for_deletion_on-date-with-the-projects-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/projects.md#list-all-projects) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/463939)

{{< /details >}}

Vous pouvez désormais filtrer les réponses dans l'API Projects en utilisant l'attribut `marked_for_deletion_on`, qui renvoie les projets qui ont été marqués pour suppression à une date spécifique.

Merci à [@imskr](https://gitlab.com/imskr) pour cette contribution communautaire !

### Événement d'audit lors de la création d'un webhook {#audit-event-on-webhook-creation}

<!-- categories: Notifications, Audit Events -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/audit_event_types.md#webhooks) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/8068)

{{< /details >}}

Les événements d'audit enregistrent les actions importantes effectuées dans GitLab. Jusqu'à présent, aucun événement d'audit n'était créé lorsqu'un webhook système, de groupe ou de projet était ajouté par un utilisateur.

Dans cette release, nous avons ajouté un événement d'audit pour lorsqu'un utilisateur crée un webhook système, de groupe ou de projet.

### Utiliser l'API REST pour annuler une migration direct transfer en cours {#use-rest-api-to-cancel-a-running-direct-transfer-migration}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/bulk_imports.md#cancel-a-migration) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438281)

{{< /details >}}

Jusqu'à présent, l'annulation d'une migration direct transfer en cours [nécessitait l'accès à une console Rails](../../user/group/import/direct_transfer_migrations.md#cancel-a-running-migration).

Dans cette release, nous avons ajouté la possibilité pour les administrateurs d'annuler une migration en utilisant l'API REST.

### Tester les hooks de groupe avec l'API REST {#test-group-hooks-with-the-rest-api}

<!-- categories: Notifications -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/group_webhooks.md#trigger-a-test-group-hook) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/455589)

{{< /details >}}

Auparavant, vous ne pouviez tester que les hooks de projet avec l'API REST. Avec cette release, vous pouvez également déclencher des hooks de test pour des groupes spécifiques.

Cet endpoint a une limite de débit spéciale de trois requêtes par minute par hook de groupe. Pour désactiver cette limite sur GitLab auto-hébergé et GitLab Dedicated, un administrateur peut désactiver le feature flag `web_hook_test_api_endpoint_rate_limit`.

Merci à [Phawin](https://gitlab.com/lifez) pour [cette contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150486) !

### Réimporter une relation de projet choisie via l'API {#re-import-a-chosen-project-relation-by-using-the-api}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/project_import_export.md#import-project-resources) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/455889)

{{< /details >}}

Lors de l'importation de projets à partir de fichiers d'export contenant de nombreux éléments du même type (par exemple, des merge requests ou des pipelines), certains de ces éléments ne sont parfois pas importés.

Dans cette release, nous avons ajouté un endpoint d'API qui réimporte une relation nommée, en ignorant les éléments déjà importés. L'API nécessite les deux éléments suivants :

- Une archive d'export de projet.
- Un type. Issues, merge requests, pipelines ou jalons.

### Conserver la structure d'appartenance héritée lors de l'importation par direct transfer {#keep-inherited-membership-structure-when-importing-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/direct_transfer_migrations.md#user-membership-mapping) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/458834)

{{< /details >}}

Jusqu'à présent, les [appartenances héritées](../../user/project/members/_index.md#membership-types) n'étaient pas importées de manière fiable lors d'une migration par direct transfer. Cela signifiait que les membres hérités des projets étaient importés en tant que membres directs.

À partir de cette release, GitLab migre d'abord les appartenances de groupe avant de migrer les appartenances de projet. Cela réplique les appartenances héritées sur l'instance GitLab source.

### Utiliser l'API REST pour définir des en-têtes de webhook personnalisés {#use-the-rest-api-to-set-custom-webhook-headers}

<!-- categories: Source Code Management, Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/project_webhooks.md#set-a-custom-header) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/455528)

{{< /details >}}

Dans GitLab 16.11, nous avons introduit la possibilité d'[ajouter des en-têtes personnalisés lors de la création ou de la modification d'un webhook](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#custom-webhook-headers).

Avec cette release, vous pouvez désormais utiliser l'API REST GitLab pour définir des en-têtes de webhook personnalisés.

Merci à [Niklas](https://gitlab.com/Taucher2003) pour [cette contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) !

### Les sauvegardes incluent les diffs de merge requests externes stockés sur disque {#backups-include-external-merge-request-diffs-stored-on-disk}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/backup_restore/backup_gitlab.md#backup-command)

{{< /details >}}

L'outil `gitlab-backup` prend désormais en charge la sauvegarde des [diffs de merge requests externes](../../administration/merge_request_diffs.md) stockés sur le disque local. Notez que l'outil `gitlab-backup` ne sauvegarde pas les fichiers stockés sur le stockage objet. Par conséquent, si les diffs de merge requests externes sont stockés sur le stockage objet, ils devront être sauvegardés manuellement.

L'outil `backup-utility` pour les environnements Cloud Native Hybrid prenait déjà en charge la sauvegarde des diffs de merge requests externes et cette fonctionnalité reste inchangée.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Désactiver les aperçus des diffs dans les e-mails de revue de code {#disable-diff-previews-in-code-review-emails}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/group/manage.md#disable-diff-previews-in-email-notifications)

{{< /details >}}

Lorsque vous effectuez une revue de code dans une merge request et commentez une ligne de code, GitLab inclut quelques lignes du diff dans la notification par e-mail envoyée aux participants. Certaines politiques organisationnelles considèrent l'e-mail comme un système moins sécurisé, ou ne contrôlent pas leur propre infrastructure pour l'e-mail. Cela peut présenter des risques pour la propriété intellectuelle ou le contrôle d'accès au code source.

De nouveaux paramètres sont disponibles dans les groupes et les projets pour permettre aux organisations de supprimer les aperçus des diffs des e-mails de merge request. Cela peut aider à garantir que les informations sensibles ne sont pas disponibles en dehors de GitLab.

Un immense merci à [Joe Snyder](https://gitlab.com/joe-snyder) pour cette contribution !

### Les administrateurs peuvent rechercher des utilisateurs par adresse e-mail partielle {#administrators-can-search-users-by-partial-email-address}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/admin_area.md#administering-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/20381)

{{< /details >}}

Les administrateurs peuvent désormais rechercher des utilisateurs par adresse e-mail partielle dans la vue d'ensemble des utilisateurs de la zone d'administration. Par exemple, vous pouvez filtrer les utilisateurs par un domaine d'e-mail spécifique pour trouver tous les utilisateurs d'une institution particulière. Cette fonctionnalité est réservée aux administrateurs afin d'empêcher les utilisateurs non privilégiés d'accéder aux adresses e-mail d'autres comptes.

Merci à [@zzaakiirr](https://gitlab.com/zzaakiirr) pour cette contribution communautaire !

### Afficher l'icône RSS de release sur la page Releases {#show-release-rss-icon-on-releases-page}

<!-- categories: Release Orchestration -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/releases/_index.md#track-releases-with-an-rss-feed) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/30988)

{{< /details >}}

Avez-vous besoin d'être notifié lorsqu'une nouvelle release est publiée ? GitLab fournit désormais un flux RSS pour les releases. Vous pouvez vous abonner à un flux de release avec l'icône RSS sur la page de release du projet.

Merci à [Martin Schurz](https://gitlab.com/schurzi) pour cette contribution !

### Nouvelles autorisations pour les rôles personnalisés {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

Dans GitLab 17.1, vous pouvez créer des rôles personnalisés avec les nouvelles autorisations suivantes :

- [Gérer les paramètres de merge request](../../user/custom_roles/abilities.md#code-review-workflow)
- [Gérer les intégrations](../../user/custom_roles/abilities.md#integrations)
- [Gérer les jetons de déploiement](../../user/custom_roles/abilities.md#continuous-delivery)
- [Lire les contacts CRM](../../user/custom_roles/abilities.md#team-planning)

Avec les rôles personnalisés, vous pouvez réduire le nombre d'utilisateurs disposant du rôle Owner en créant des utilisateurs avec des autorisations équivalentes. Cela vous aide à définir des rôles adaptés spécifiquement aux besoins de votre groupe et à éviter toute escalade de privilèges inutile.

### Politiques d'approbation de merge request en échec ouvert/fermé (éditeur de politiques) {#merge-request-approval-policies-fail-openclosed-policy-editor}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#fallback_behavior) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13227)

{{< /details >}}

En nous appuyant sur l'[itération](https://gitlab.com/groups/gitlab-org/-/epics/10816) précédente, nous introduisons une nouvelle option dans l'éditeur de politiques permettant aux utilisateurs de basculer les politiques de sécurité en mode échec ouvert ou échec fermé. Cette amélioration étend la prise en charge YAML pour permettre une configuration plus simple dans la vue de l'éditeur de politiques.

Par exemple, une politique de merge request configurée en mode échec ouvert permet à une merge request de fusionner s'il n'y a pas suffisamment d'éléments pour évaluer les critères. L'absence de preuves peut être due au fait qu'un analyseur n'est pas activé pour le projet, ou que l'analyseur n'a pas réussi à produire des résultats que la politique peut évaluer. Cette approche permet un déploiement progressif des politiques au fur et à mesure que les équipes s'assurent d'une exécution et d'une application correctes des analyses.

### Les propriétaires de projet reçoivent des notifications d'expiration de jetons d'accès {#project-owners-receive-expiring-access-token-notifications}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../security/tokens/_index.md#project-access-tokens) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/460818)

{{< /details >}}

Les propriétaires et les Maintainers de projets avec une appartenance directe reçoivent désormais des notifications par e-mail lorsque leurs jetons d'accès au projet arrivent à expiration. Auparavant, seuls les Maintainers de projet recevaient cette notification. Cela permet de tenir davantage de personnes informées de l'expiration prochaine des jetons.

Merci à [Jacob Henner](https://gitlab.com/arcesium-henner) pour votre contribution !

### Réduire la taille des images collées lors du téléversement {#downscale-pasted-images-on-image-upload}

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/markdown.md#change-image-or-video-dimensions) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/419913)

{{< /details >}}

GitLab 17.1 améliore la gestion des images en haute résolution, permettant leur réduction lors du téléversement. Auparavant, les images s'affichaient dans leur taille d'origine, ce qui entraînait une qualité d'affichage sous-optimale. Cette amélioration garantit que les grandes images ne perturbent pas le flux visuel des pages dans lesquelles elles sont incluses.

### Médias déplaçables dans l'éditeur de texte enrichi {#draggable-media-in-the-rich-text-editor}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/rich_text_editor.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/452233)

{{< /details >}}

Auparavant, déplacer des médias dans l'éditeur de texte enrichi nécessitait de copier et coller chaque élément manuellement. Cela ralentissait souvent l'inclusion de médias dans les tickets, les epics et les wikis. Dans GitLab 17.1, vous pouvez désormais faire glisser et déposer des médias dans l'éditeur de texte enrichi, ce qui améliore considérablement l'efficacité lors de l'édition.

### Prise en charge du TLS mutuel par Pages dans les appels à l'API GitLab {#pages-support-for-mutual-tls-in-gitlab-api-calls}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/pages/_index.md#support-mutual-tls-when-calling-the-gitlab-api) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548)

{{< /details >}}

GitLab peut être configuré pour [imposer l'authentification client avec des certificats SSL](https://docs.gitlab.com/omnibus/settings/ssl/#enable-2-way-ssl-client-authentication). Cependant, le service GitLab Pages était incompatible avec cette fonctionnalité, car il ne pouvait pas être configuré pour utiliser des certificats client, et les appels à l'API interne étaient rejetés.

À partir de GitLab 17.1, vous pouvez configurer un certificat client pour GitLab Pages. Cela vous permet d'activer l'authentification client avec l'API GitLab, renforçant ainsi la sécurité de votre instance GitLab.

### Redirection des pages wiki vers la nouvelle URL lors du renommage {#redirect-wiki-pages-to-new-url-when-renamed}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/wiki/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/257892)

{{< /details >}}

GitLab 17.1 introduit une amélioration significative des redirections de pages wiki. Lorsque vous renommez une page wiki, toute personne essayant d'accéder à l'ancienne page est automatiquement redirigée vers la nouvelle page, garantissant que tous les liens existants restent fonctionnels. Cette amélioration simplifie le flux de travail de gestion des changements de noms de pages et améliore l'expérience globale de gestion des connaissances.

### Interface utilisateur Pages mise à jour {#updated-pages-ui}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153250)

{{< /details >}}

Dans GitLab 17.1, nous avons amélioré l'interface utilisateur de Pages. Les améliorations incluent une utilisation plus efficace de l'espace écran. Ces améliorations de l'interface utilisateur visent à améliorer l'expérience utilisateur et l'efficacité lors de la gestion de Pages.

### Afficher la date de dernière publication des images de conteneurs {#display-the-last-published-date-for-container-images}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Free, Silver, Gold
- Liens : [Documentation](../../user/packages/container_registry/_index.md#view-the-container-registry) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/290949)

{{< /details >}}

Auparavant, l'horodatage de publication était souvent incorrect dans l'interface utilisateur du registre de conteneurs. Cela signifiait que vous ne pouviez pas vous fier à ces données importantes pour trouver et valider vos images de conteneurs.

Dans GitLab 17.1, nous avons mis à jour l'interface utilisateur pour inclure des horodatages `last_published_at` précis. Vous pouvez trouver ces informations en naviguant vers **Déployer > Container Registry** et en sélectionnant un tag pour afficher plus de détails. La date de dernière publication est disponible en haut de la page.

Cette amélioration est disponible en disponibilité générale uniquement sur GitLab.com. La prise en charge des instances auto-hébergées est en version bêta et disponible uniquement sur les instances ayant activé le [registre de conteneurs de nouvelle génération](../../administration/packages/container_registry_metadata_database.md) en version bêta.

### Trier les tags du registre de conteneurs par date de publication {#sort-container-registry-tags-by-publish-date}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/packages/container_registry/_index.md#view-the-container-registry) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/7856)

{{< /details >}}

Vous utilisez le registre de conteneurs GitLab pour afficher, pousser et extraire des images Docker ou OCI en parallèle de votre code source ainsi que de vos pipelines. Une fois une image de conteneur construite, vous devez souvent trouver et valider qu'elle a été construite correctement. Pour de nombreux clients, trouver la bonne image de conteneur via l'interface utilisateur peut s'avérer difficile.

Vous pouvez désormais trier la liste des tags du registre de conteneurs par date de publication. Vous pouvez utiliser cette fonctionnalité pour trouver et valider rapidement l'image de conteneur la plus récemment publiée.

Cette amélioration est disponible en disponibilité générale uniquement sur GitLab.com. La prise en charge des instances auto-hébergées est en version bêta car elle nécessite le registre de conteneurs de nouvelle génération, également en version bêta. Pour en savoir plus, consultez la [documentation sur la base de données de métadonnées du registre de conteneurs](../../administration/packages/container_registry_metadata_database.md).

### Mises à jour des tableaux en temps réel pour un flux de travail plus fluide {#real-time-board-updates-for-a-smoother-workflow}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/issue_board.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/468187)

{{< /details >}}

Vous remarquerez désormais une expérience plus fluide lors de la mise à jour des tickets sur les [tableaux](../../user/project/issue_board.md) ! Les modifications que vous effectuez dans la barre latérale apparaissent instantanément sur le tableau lui-même, sans qu'il soit nécessaire de rafraîchir. Cette expérience de tableaux réactifs simplifie votre flux de travail, vous permettant d'effectuer rapidement des mises à jour tout en les voyant se refléter en temps réel.

### Suivre le temps sur les tâches {#track-time-on-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/time_tracking.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438577)

{{< /details >}}

Avec cette release, vous pouvez désormais définir des estimations de temps et enregistrer le temps passé sur des tâches avec une [action rapide](../../user/project/quick_actions.md) ou dans le widget de suivi du temps dans la barre latérale de la tâche. Le temps passé sur une tâche peut être consulté via le rapport de suivi du temps de la tâche.

### Comprendre le pourcentage de progression d'un epic {#understand-an-epics-progress-percentage}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/epics/manage_epics.md#manage-issues-assigned-to-an-epic) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/5163)

{{< /details >}}

Vous pouvez désormais voir facilement la progression globale d'un epic en fonction de la complétion du poids de ses éléments enfants. Ce nouveau récapitulatif de progression dans le widget de hiérarchie facilite la compréhension de l'étendue complète du travail d'un epic et le suivi de la progression au fur et à mesure.

### Mises à jour de l'analyseur API Security Testing {#api-security-testing-analyzer-updates}

<!-- categories: API Security -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/api_security_testing/configuration/variables.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/14170)

{{< /details >}}

GitLab 17.1 ajoute les variables de configuration suivantes pour API Security Testing :

1. `APISEC_SUCCESS_STATUS_CODES` crée une liste de codes de statut HTTP de succès séparés par des virgules qui définissent si un job d'analyse de sécurité API a réussi.
1. `APISEC_TARGET_CHECK_DISABLED` désactive l'attente que l'API cible soit disponible avant le début de l'analyse.
1. `APISEC_TARGET_CHECK_STATUS_CODE` spécifie le code de statut attendu pour la vérification de disponibilité de la cible API. S'il n'est pas fourni, tout code de statut non-500 est acceptable pour le scanner.

Ces nouvelles variables offrent une plus grande personnalisation et flexibilité pour garantir le bon déroulement des analyses.

DAST API a été renommé API Security Testing dans la version 16.10. Les noms de variables commencent désormais par le préfixe `APISEC`. Auparavant, ils commençaient par `DAST_API`. Les variables préfixées par `DAST_API` seront prises en charge jusqu'à la version 18.0 (mai 2025). Pour garantir que vos configurations fonctionnent comme prévu, vous devez mettre à jour vos noms de variables dès que possible.

### Container Scanning pour le registre {#container-scanning-for-registry}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/container_scanning/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/2340)

{{< /details >}}

GitLab Composition Analysis prend désormais en charge Container Scanning pour le registre.

Si Container Scanning pour le registre a été activé sur un projet, et qu'une image de conteneur est poussée vers le registre de conteneurs de votre projet, GitLab vérifie son tag et sa limite d'analyse.

Si le tag est `latest`, et que le nombre d'analyses est inférieur à la limite (50 analyses/jour), GitLab crée un nouveau pipeline qui exécute un job `container_scanning` sur l'image. Le pipeline est associé à l'utilisateur qui a poussé l'image vers le registre.

Le job d'analyse génère un SBOM CycloneDX qui est téléversé vers GitLab. Les fonctionnalités de Continuous Vulnerability Scanning sont activées et analysent les paquets détectés dans le SBOM.

Remarque : une analyse de vulnérabilité n'est effectuée que lorsqu'un nouvel avis est publié. Cela se produit lorsque les [métadonnées du paquet sont synchronisées](../../administration/settings/security_and_compliance.md).

Comme toujours, nous apprécions vos retours sur nos nouvelles fonctionnalités. Pour fournir vos retours, veuillez commenter ce [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/466117).

### Mises à jour de l'analyseur Fuzz Testing {#fuzz-testing-analyzer-updates}

<!-- categories: Fuzz Testing -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/api_fuzzing/configuration/variables.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)

{{< /details >}}

GitLab 17.1 ajoute les variables de configuration suivantes pour Fuzz Testing :

1. `FUZZAPI_SUCCESS_STATUS_CODES` crée une liste de codes de statut HTTP de succès séparés par des virgules qui définissent si un job Fuzz Testing a réussi.
1. `FUZZAPI_TARGET_CHECK_SKIP` désactive l'attente que l'API cible soit disponible avant le début de l'analyse.
1. `FUZZAPI_TARGET_CHECK_STATUS_CODE` spécifie le code de statut attendu pour la vérification de disponibilité de la cible API. S'il n'est pas fourni, tout code de statut non-500 est acceptable pour le scanner.

Ces nouvelles variables offrent une plus grande personnalisation et flexibilité pour garantir le bon déroulement des analyses.

### Contrôle renforcé sur les personnes autorisées à remplacer les variables définies par l'utilisateur {#enhanced-control-over-who-can-override-user-defined-variables}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/variables/_index.md#restrict-pipeline-variables) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/440338)

{{< /details >}}

Pour mieux contrôler qui peut remplacer les variables définies par l'utilisateur, nous introduisons le paramètre de projet `ci_pipeline_variables_minimum_role`. Ce nouveau paramètre offre une plus grande flexibilité que le paramètre existant [`restrict_user_defined_variables`](../../ci/variables/_index.md#restrict-pipeline-variables). Vous pouvez désormais restreindre les autorisations de remplacement à aucun utilisateur, ou uniquement aux utilisateurs disposant au moins des rôles Developer, Maintainer ou Owner.

### GitLab Runner 17.1 est sorti {#gitlab-runner-171-released}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36942)

{{< /details >}}

Aujourd'hui, nous publions GitLab Runner 17.1 ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Plugin GitLab Runner fleeting pour GCP Compute Engine](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29221)

#### Corrections de bugs {#bug-fixes}

- [Images d'aide du runner avec le point d'entrée manquant](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37689)

La liste de toutes les modifications se trouve dans le [journal des modifications](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-1-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.1)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.1)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.1)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
