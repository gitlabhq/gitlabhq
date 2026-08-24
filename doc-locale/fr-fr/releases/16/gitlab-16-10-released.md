---
stage: Release Notes
group: Monthly Release
date: 2024-03-21
title: "Notes de release de GitLab 16.10"
description: "GitLab 16.10 publié avec la gestion sémantique de version dans le catalogue CI/CD"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 21 mars 2024, GitLab 16.10 a été publié avec les fonctionnalités suivantes.

Nous tenons également à remercier tous nos contributeurs, dont le contributeur notable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

[Lennard Sprong](https://gitlab.com/X_Sheep) a précédemment remporté le prix GitLab MVP dans la version 15.4 et avait également été nominé dans la version 16.9. Il continue de contribuer à GitLab Workflow pour VS Code, en fusionnant 8 contributions au cours des deux derniers mois. Parmi ses contributions passées, on peut citer la possibilité de [surveiller la trace des jobs CI en cours d'exécution](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/674), de [visualiser les pipelines downstream](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1336) et de [comparer des images dans les merge requests](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1319). Lennard est également activement impliqué dans les tickets du projet [GitLab-vscode-extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension).

[Erran Carey](https://gitlab.com/erran), Staff Fullstack Engineer chez GitLab, a nominé Lennard et a noté que « Lennard a résolu un [problème de visualisation des pipelines](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1000) affectant les utilisateurs de GitLab Community Edition. Il a orienté les utilisateurs concernés vers la solution de contournement existante avant de [créer une merge request](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1417) pour résoudre le problème. »

[Tomas Vik](https://gitlab.com/viktomas), Staff Fullstack Engineer chez GitLab, a également soutenu Lennard et mis en avant une contribution visant à [ajouter la prise en charge du diff d'images](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1319), qui permet aux utilisateurs de visualiser les modifications d'images lors de la revue de merge requests.

[Marco Zille](https://gitlab.com/zillemarco) remporte également son deuxième prix GitLab MVP, après l'avoir remporté pour la première fois dans la version 15.3. Marco a été reconnu non seulement pour ses contributions au code dans cette release, mais aussi pour ses efforts continus en soutien à la communauté élargie des contributeurs de GitLab, en animant des sessions de pair programming communautaires, en collaborant avec les membres de l'équipe GitLab et en révisant des merge requests.

Marco a ajouté la possibilité d'[annuler un pipeline immédiatement après l'échec d'un job](https://gitlab.com/gitlab-org/gitlab/-/issues/23605). La fonctionnalité est activée et disponible sur GitLab.com, mais reste encore derrière un feature flag pour les instances auto-hébergées. Elle sera mise à disposition de tous dans la version 16.11.

[Allison Browne](https://gitlab.com/allison.browne), Senior Backend Engineer chez GitLab, a nominé Marco pour avoir pris en charge cette demande de fonctionnalité très ancienne et très demandée dans l'exécution des pipelines. [Fabio Pitino](https://gitlab.com/fabiopitino), Principal Engineer chez GitLab, a ajouté que « Marco n'a pas seulement implémenté le correctif, mais a également joué un rôle clé dans la conception de la fonctionnalité, en apportant des cas d'utilisation et en les discutant avec les clients intéressés par cette fonctionnalité. »

[Peter Leitzen](https://gitlab.com/splattael) a également soutenu la nomination de Marco en soulignant la façon dont Marco a contribué à [réviser puis finaliser un correctif](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112813#note_1737719869) pour le chargement de la trace de pile depuis Sentry.

Nous sommes très reconnaissants du soutien continu de Lennard et Marco pour améliorer GitLab et soutenir notre communauté open source ! 🙌

## Fonctionnalités principales {#primary-features}

### Gestion sémantique de version dans le catalogue CI/CD {#semantic-versioning-in-the-cicd-catalog}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/components/_index.md#component-versions) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/442238)

{{< /details >}}

Afin d'imposer un comportement cohérent entre les composants publiés, GitLab 16.10 appliquera la gestion sémantique de version pour les composants publiés dans le catalogue CI/CD. Lors de la publication d'un composant, le tag doit respecter le standard de gestion sémantique de version à 3 chiffres (par exemple `1.0.0`).

Lorsque vous utilisez un composant avec la syntaxe `include: component`, vous devez utiliser la version sémantique publiée. L'utilisation de `~latest` reste prise en charge, mais cette option retournera toujours la dernière version publiée ; vous devez donc l'utiliser avec précaution, car elle pourrait inclure des modifications incompatibles. La syntaxe abrégée n'est pas prise en charge, mais elle le sera dans un prochain jalon.

### Contrôle de gouvernance d'accès à GitLab Duo {#gitlab-duo-access-governance-control}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/gitlab_duo/turn_on_off.md)

{{< /details >}}

L'IA générative révolutionne les processus de travail, et vous pouvez désormais faciliter l'adoption de ces technologies sans compromettre la confidentialité, la conformité ni les protections de la propriété intellectuelle (PI).

Vous pouvez désormais désactiver les fonctionnalités d'IA GitLab Duo pour un projet, un groupe ou une instance en utilisant l'API. Vous pouvez ensuite activer GitLab Duo pour des projets ou des groupes spécifiques lorsque vous êtes prêt. Ces modifications font partie d'un ensemble de travaux prévus pour rendre le contrôle des fonctionnalités d'IA plus granulaire.

### Modèles Wiki {#wiki-templates}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/wiki/_index.md#wiki-page-templates) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/16608)

{{< /details >}}

Cette version de GitLab introduit de tout nouveaux modèles dans le Wiki. Vous pouvez désormais créer des modèles pour simplifier la création de nouvelles pages ou la modification de pages existantes. Les modèles sont des pages wiki stockées dans le répertoire de modèles du dépôt wiki.

Grâce à cette amélioration, vous pouvez rendre la mise en page de vos pages wiki plus cohérente, créer ou restructurer des pages plus rapidement, et garantir que les informations sont présentées de manière claire et cohérente dans votre base de connaissances.

### Nouvelle intégration ClickHouse pour l'analytique DevOps haute performance {#new-clickhouse-integration-for-high-performance-devops-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/group/contribution_analytics/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/428260)

{{< /details >}}

Le [rapport Contribution Analytics](../../user/group/contribution_analytics/_index.md) est désormais plus performant et repose sur une base de données analytique avancée utilisant ClickHouse sur GitLab.com. Cette mise à niveau a posé les bases de nouvelles fonctionnalités d'analytique et de reporting étendues, nous permettant de proposer des agrégations analytiques haute performance, ainsi que des fonctionnalités de filtrage et de segmentation sur plusieurs dimensions. La prise en charge permettant aux clients auto-hébergés d'exploiter cette fonctionnalité est proposée dans [le ticket 441626](https://gitlab.com/gitlab-org/gitlab/-/issues/441626).

Bien que ClickHouse améliore les capacités analytiques de GitLab, il n'est pas destiné à remplacer PostgreSQL ou Redis, et les fonctionnalités existantes restent inchangées.

### GitLab Pages et la recherche avancée disponibles sur GitLab Dedicated {#gitlab-pages-and-advanced-search-available-on-gitlab-dedicated}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- Édition : Gold
- Liens : [Documentation](../../subscriptions/gitlab_dedicated/_index.md#available-features) \| [Ticket associé](https://about.gitlab.com/dedicated/)

{{< /details >}}

[GitLab Pages](../../user/project/pages/_index.md) et la [recherche avancée](../../user/search/advanced_search.md) ont été activés pour toutes les [instances GitLab Dedicated](https://about.gitlab.com/dedicated/). Ces fonctionnalités sont incluses dans votre abonnement GitLab Dedicated.

La recherche avancée permet une recherche plus rapide et plus efficace sur l'ensemble de votre instance GitLab Dedicated. Toutes les fonctionnalités de la recherche avancée peuvent être utilisées avec les instances GitLab Dedicated.

Avec GitLab Pages, vous pouvez publier des sites web statiques directement depuis un dépôt dans GitLab Dedicated. Certaines fonctionnalités de Pages ne sont [pas encore disponibles](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages) pour les instances GitLab Dedicated.

### Décharger le trafic CI vers les sites secondaires Geo {#offload-ci-traffic-to-geo-secondaries}

<!-- categories: Geo Replication -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/geo/secondary_proxy/runners.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9779)

{{< /details >}}

Vous pouvez désormais décharger le trafic des runners CI vers les sites Geo secondaires. Localisez les flottes de runners là où leur exploitation et leur gestion sont les plus pratiques et économiques, tout en réduisant le trafic inter-région. Distribuez la charge sur plusieurs sites Geo secondaires. Réduisez la charge sur le site principal, en réservant des ressources pour le trafic des équipes de développement. Une fois cette configuration effectuée, l'expérience des équipes de développement est transparente et fluide. Les workflows des équipes de développement pour la configuration et le paramétrage des jobs restent inchangés.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations du chart GitLab {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

Dans GitLab 16.10, nous avons supprimé la prise en charge de l'installation de GitLab sur Kubernetes 1.24 et versions antérieures. La prise en charge de la maintenance de Kubernetes 1.24 a pris fin en juillet 2023.

GitLab 16.10 inclut la prise en charge de l'installation de GitLab sur Kubernetes 1.27. Pour plus d'informations, consultez notre nouvelle [politique de prise en charge des versions de Kubernetes](https://handbook.gitlab.com/handbook/engineering/careers/matrix/infrastructure/core-platform/distribution/). Notre objectif est de prendre en charge les versions plus récentes de Kubernetes au plus près de leur release officielle.

### Améliorations d'Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 16.10 introduit une nouvelle version majeure de Patroni, la version 3.0.1. Cette mise à niveau de version nécessitera une interruption de service. Pour plus d'informations et les instructions, consultez la [section 16.10 de notre page des modifications de GitLab 16](../../update/versions/gitlab_16_changes.md#16100).

GitLab 16.10 inclut également une nouvelle version d'Alertmanager, à savoir la version 0.27. Plus particulièrement, cette version inclut la suppression de l'API v1. Pour plus d'informations sur cette release, consultez le [changelog d'Alertmanager](https://github.com/prometheus/alertmanager/blob/v0.27.0/CHANGELOG.md#0270--2024-02-28).

GitLab 16.10 inclut également [Mattermost 9.5](https://docs.mattermost.com/deploy/mattermost-changelog.html#release-v9-5-extended-support-release). Mattermost 9.5 inclut diverses mises à jour de sécurité et la dépréciation de la prise en charge de MySQL 5.7. Les utilisateurs de cette version de MySQL doivent effectuer une mise à jour.

### Filtrer les membres par utilisateurs Enterprise avec l'API GraphQL {#filter-members-by-enterprise-users-with-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../api/graphql/reference/_index.md#groupgroupmembers) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/356062)

{{< /details >}}

Avec l'API GraphQL, vous pouvez désormais filtrer les membres d'un groupe par utilisateurs Enterprise.

### Les utilisateurs bloqués sont exclus de la liste des abonnés {#blocked-users-are-excluded-from-the-followers-list}

<!-- categories: User Profile -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/_index.md#follow-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/441774)

{{< /details >}}

Précédemment, lorsqu'un utilisateur qui vous suivait était bloqué, il apparaissait toujours dans la liste des abonnés de votre profil utilisateur. À partir de GitLab 16.10, les utilisateurs bloqués sont masqués dans la liste des abonnés. Si l'utilisateur est débloqué, il réapparaîtra dans la liste des abonnés.

Merci à @SethFalco pour cette contribution communautaire !

### Filtrer les groupes par visibilité dans l'API REST {#filter-groups-by-visibility-in-the-rest-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/groups.md#list-groups) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/429314)

{{< /details >}}

Vous pouvez désormais filtrer les groupes par visibilité dans l'[API Groups](../../api/groups.md). Vous pouvez utiliser le filtrage pour vous concentrer sur les groupes ayant un niveau de visibilité spécifique, ce qui facilite l'audit des implémentations GitLab.

Merci à @imskr pour cette contribution communautaire !

### Mise à jour de la fonctionnalité de suppression de projet {#updated-project-deletion-functionality}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/working_with_projects.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/443682)

{{< /details >}}

Il est désormais plus facile d'identifier les projets supprimés dans les listes de projets. À partir de GitLab 16.10, les projets supprimés affichent un badge `Pending deletion` à côté du titre du projet sur la page de présentation du projet. Un message d'alerte précise que les projets supprimés sont en lecture seule. Ce message est visible sur toutes les pages du projet pour garantir que ce contexte n'est pas perdu, même lorsque vous travaillez sur des sous-pages du projet supprimé.

### Notifications en fils de discussion prises en charge dans Google Chat {#threaded-notifications-supported-in-google-chat}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/hangouts_chat.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438452)

{{< /details >}}

Précédemment, les notifications envoyées depuis GitLab vers un espace dans Google Chat ne pouvaient pas être créées comme réponses à des fils de discussion spécifiques. Avec cette release, les notifications en fils de discussion sont activées par défaut dans Google Chat pour le même objet GitLab (par exemple, un ticket ou une merge request).

Merci à [Robbie Demuth](https://gitlab.com/robbie-demuth) pour [cette contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145187) !

### Modèle de payload personnalisé pour les webhooks {#custom-payload-template-for-webhooks}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhooks.md#custom-webhook-template) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/362504)

{{< /details >}}

Précédemment, les webhooks GitLab ne pouvaient envoyer que des payloads JSON spécifiques, ce qui signifiait que les endpoints récepteurs devaient comprendre le format du webhook. Pour utiliser ces webhooks, vous deviez soit utiliser une application qui prend spécifiquement en charge GitLab, soit écrire votre propre endpoint.

Avec cette release, vous pouvez définir un modèle de payload personnalisé dans la configuration du webhook. Le corps de la requête est rendu à partir du modèle avec les données de l'événement actuel.

Merci à [Niklas](https://gitlab.com/Taucher2003) pour [cette contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142738) !

### Créer des tickets Service Desk depuis l'interface utilisateur et l'API {#create-service-desk-tickets-from-the-ui-and-api}

<!-- categories: Service Desk -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/service_desk/using_service_desk.md#create-a-service-desk-ticket-in-gitlab-ui) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)

{{< /details >}}

Vous pouvez désormais créer des tickets Service Desk depuis l'interface utilisateur et l'API en utilisant l'action rapide `/convert_to_ticket user@example.com` sur un ticket ordinaire.

Créez un ticket ordinaire et ajoutez un commentaire avec l'action rapide `/convert_to_ticket user@example.com`. L'adresse e-mail fournie devient l'auteur externe du ticket. GitLab n'envoie pas l'[e-mail de remerciement par défaut](../../user/project/service_desk/configure.md). Vous pouvez ajouter un commentaire public sur le ticket pour informer le participant externe que le ticket a été créé.

L'ajout d'un ticket Service Desk via l'API suit le même concept : créez un ticket en utilisant l'[API Issues](../../api/issues.md) et utilisez `issue_iid` pour ajouter une note avec l'action rapide en utilisant l'[API Notes](../../api/notes.md).

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Réduire automatiquement les fichiers générés dans les merge requests {#automatically-collapse-generated-files-in-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/changes.md#collapse-generated-files)

{{< /details >}}

Les merge requests peuvent contenir des modifications provenant d'utilisateurs, de processus automatisés ou de compilateurs. Les fichiers tels que `package-lock.json`, `Gopkg.lock`, et les fichiers `js` et `css` minifiés augmentent le nombre de fichiers affichés dans une revue de merge request et distraient les relecteurs des modifications générées par les humains. Les merge requests affichent désormais ces fichiers réduits par défaut, afin de :

- Concentrer l'attention des relecteurs sur les modifications importantes, tout en permettant une revue complète si souhaité.
- Réduire la quantité de données nécessaires au chargement de la merge request, ce qui peut améliorer les performances des merge requests plus volumineuses.

Pour des exemples de types de fichiers réduits par défaut, consultez la [documentation](../../user/project/merge_requests/changes.md#collapse-generated-files). Pour réduire davantage de fichiers et de types de fichiers dans la merge request, spécifiez-les en tant que `gitlab-generated` dans le fichier `.gitattributes` de votre projet.

Vous pouvez laisser vos commentaires sur cette modification dans le [ticket 438727](https://gitlab.com/gitlab-org/gitlab/-/issues/438727).

### Vérifications étendues dans le widget de fusion {#expanded-checks-in-merge-widget}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/auto_merge.md)

{{< /details >}}

Le widget de fusion indique clairement si votre merge request ne peut pas être fusionnée, et pour quelle raison. Précédemment, un seul bloqueur de fusion était affiché à la fois. Cela augmentait les cycles de revue et vous forçait à résoudre les problèmes individuellement, sans savoir si d'autres bloqueurs subsistaient.

Lorsque vous consultez une merge request, le widget de fusion vous offre désormais une vue complète des problèmes, qu'ils soient résolus ou non. Vous pouvez désormais identifier d'un coup d'œil si plusieurs bloqueurs existent, les corriger tous en une seule itération et accroître votre confiance dans le fait qu'aucun bloqueur caché n'a été manqué.

### Actualiser manuellement le tableau de bord pour Kubernetes {#manually-refresh-the-dashboard-for-kubernetes}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/429531)

{{< /details >}}

GitLab 16.10 ajoute une fonctionnalité d'actualisation dédiée au tableau de bord pour Kubernetes. Vous pouvez désormais récupérer manuellement les données des ressources Kubernetes et vous assurer d'avoir accès aux informations les plus récentes sur vos clusters.

### Page de détails des environnements améliorée {#improved-environment-details-page}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/431746)

{{< /details >}}

La page de détails des environnements a été améliorée dans GitLab 16.10. Lorsque vous sélectionnez un environnement dans la liste des environnements, vous pouvez consulter des informations à jour sur vos déploiements et les clusters Kubernetes connectés, le tout dans une mise en page pratique.

### Message d'erreur amélioré pour la limite de débit d'authentification {#improved-error-message-for-authentication-rate-limit}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../security/rate_limits.md#failed-authentication-ban-for-git-and-container-registry) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/22787)

{{< /details >}}

Lors de l'authentification avec GitLab, il est possible d'atteindre la limite de débit des tentatives d'authentification, par exemple lors de l'utilisation d'un script. Précédemment, si vous atteigniez la limite de débit d'authentification, un message `403 Forbidden` était renvoyé, sans expliquer pourquoi vous receviez cette erreur. Nous renvoyons désormais un message d'erreur plus descriptif qui vous indique que vous avez atteint la limite de débit d'authentification.

### Attribut `scope` des événements d'audit {#audit-event-scope-attribute}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Les événements d'audit incluent désormais un attribut `scope` qui indique si l'événement est associé à une instance entière, à un groupe, à un projet ou à un utilisateur.

Ce nouvel attribut aide les utilisateurs à déterminer l'origine d'un événement dans les payloads des événements d'audit. Il permet également à notre [documentation sur les types d'événements d'audit](../../administration/compliance/audit_event_reports.md) de lister toutes les portées disponibles pour un type d'événement d'audit.

Vous pouvez utiliser ce nouvel attribut pour analyser les destinations de streaming externes ou pour mieux comprendre le contexte des événements.

### Noms personnalisés pour les comptes de service {#custom-names-for-service-accounts}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/service_accounts.md#create-a-service-account) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415973)

{{< /details >}}

Vous pouvez désormais personnaliser le nom d'utilisateur et le nom d'affichage d'un compte de service. Précédemment, ceux-ci étaient générés automatiquement par GitLab. Avec un nom personnalisé, il est plus facile de comprendre la finalité du compte de service et de le distinguer des autres comptes dans la liste des utilisateurs.

### Événement d'audit pour l'attribution d'un rôle personnalisé {#audit-event-for-assigning-a-custom-role}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/427954)

{{< /details >}}

GitLab enregistre désormais un événement d'audit lorsqu'un utilisateur se voit attribuer un rôle différent, qu'il s'agisse d'un rôle par défaut ou d'un rôle personnalisé. Cet événement est important pour identifier si des autorisations utilisateur ont été ajoutées ou modifiées en cas d'escalade de privilèges.

### Nouvelles autorisations pour les rôles personnalisés {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

Pour créer des rôles personnalisés, vous pouvez désormais choisir deux nouvelles autorisations :

- Gérer les variables CI/CD
- Possibilité de supprimer un groupe

Avec la publication de ces autorisations personnalisées, vous pouvez réduire le nombre de propriétaires nécessaires dans un groupe en créant un rôle personnalisé avec ces autorisations équivalentes à celles d'un propriétaire. Les rôles personnalisés vous permettent de définir des rôles granulaires qui ne donnent à un utilisateur que les autorisations dont il a besoin pour effectuer son travail, et réduisent les escalades de privilèges inutiles.

### Les politiques de résultats de scan sont désormais des « politiques d'approbation des merge requests » {#scan-result-policies-are-now-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9850)

{{< /details >}}

Au fur et à mesure que nous avons étendu les capacités du type de politique pour prendre en charge le remplacement des paramètres de projet et appliquer des exigences d'approbation, nous avons mis à jour le nom de la politique en « politique d'approbation des merge requests », terme plus approprié.

Les politiques d'approbation des merge requests ne remplacent pas les règles d'approbation des merge requests existantes et n'entrent pas en conflit avec elles. Elles offrent plutôt aux clients de l'édition Ultimate la possibilité de créer une application globale sur l'ensemble des projets, via des politiques gérées par des équipes centrales de sécurité et de conformité — une tâche de plus en plus complexe pour les organisations à grande échelle.

### Les webhooks prennent en charge le TLS mutuel {#webhooks-support-mutual-tls}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhooks.md#configure-webhooks-to-support-mutual-tls) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/27450)

{{< /details >}}

Vous pouvez désormais configurer des webhooks pour prendre en charge le TLS mutuel. Cette configuration établit l'authenticité de la source du webhook et renforce la sécurité. Vous configurez le certificat client au format PEM, qui est présenté au serveur lors du handshake TLS. Vous pouvez également protéger le certificat avec une phrase secrète PEM.

### Améliorations de la page de connexion {#sign-in-page-improvements}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](https://gitlab.com/gitlab-org/gitlab/-/issues/412845) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/412845)

{{< /details >}}

La page de connexion de GitLab a été actualisée avec des améliorations qui corrigent les problèmes d'espacement, les éléments défectueux et l'alignement. Une prise en charge supplémentaire du mode sombre a également été ajoutée, ainsi qu'un bouton pour gérer les préférences relatives aux cookies. L'ensemble de ces améliorations donne un aspect actualisé et une fonctionnalité améliorée à la page de connexion.

### Prise en charge des cartes à puce pour Active Directory LDAP {#smart-card-support-for-active-directory-ldap}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/auth/smartcard.md#authentication-against-an-active-directory-ldap-server) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/328074)

{{< /details >}}

L'authentification par carte à puce auprès d'un serveur LDAP prend désormais en charge Entra ID (anciennement connu sous le nom d'Azure Active Directory). Cela facilite la synchronisation des données d'identité des utilisateurs depuis Entra ID et l'authentification auprès de LDAP avec des cartes à puce.

### Utiliser le pipeline de base de fusion pour la comparaison de la politique d'approbation des merge requests {#use-merge-base-pipeline-for-merge-request-approval-policy-comparison}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#understanding-merge-request-approval-policy-approvals) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/428518)

{{< /details >}}

Cette amélioration aligne la logique d'évaluation de la politique d'approbation des merge requests avec le widget MR de sécurité, garantissant que les résultats qui enfreignent une politique d'approbation des merge requests correspondent aux résultats affichés dans le widget. En alignant la logique, les équipes de sécurité, de conformité et de développement peuvent identifier de manière plus cohérente les résultats qui enfreignent une politique et nécessitent une approbation. Plutôt que de comparer avec le dernier pipeline `HEAD` terminé de la branche cible, les politiques de résultats de scan comparent désormais avec le dernier pipeline terminé d'un ancêtre commun, la « base de fusion ».

### Prendre en charge les redirections au niveau du domaine pour GitLab Pages {#support-domain-level-redirects-for-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/redirects.md#domain-level-redirects) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/601)

{{< /details >}}

Précédemment, GitLab se concentrait sur la prise en charge de règles de redirection simples. Dans GitLab 14.3, nous avons [introduit](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/458) la prise en charge des redirections avec caractères génériques et espaces réservés.

À partir de GitLab 16.10, GitLab Pages prend en charge les redirections au niveau du domaine. Vous pouvez combiner les redirections au niveau du domaine avec les [règles splat](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/601) pour réécrire dynamiquement le chemin de l'URL. Cette amélioration permet d'éviter toute confusion et de garantir que vous pouvez toujours trouver vos informations après un changement de domaine, même si vous utilisez un ancien domaine.

### Lister les tags du dépôt avec la nouvelle API du registre de conteneurs {#list-repository-tags-with-the-new-container-registry-api}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Free, Silver, Gold
- Liens : [Documentation](../../api/container_registry.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10208)

{{< /details >}}

Précédemment, le registre de conteneurs utilisait l'[API de registre de listing des tags d'images](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/docker/v2/api.md#listing-image-tags) Docker/OCI pour afficher les tags dans GitLab. Cette API présentait d'importantes limitations en termes de performance et de découvrabilité.

Cette API fonctionnait lentement car le nombre de requêtes réseau adressées au registre augmentait proportionnellement au nombre de tags dans la liste des tags. De plus, comme l'API ne suivait pas l'heure de publication, le timestamp de publication était souvent incorrect. Il existait également des limitations lors de l'affichage d'images basées sur des listes de manifestes Docker ou des index OCI, comme pour les images multi-architecture.

Pour remédier à ces limitations, nous avons introduit une nouvelle [API de listing des tags du dépôt](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/gitlab/api.md#list-repository-tags) pour le registre. Dans GitLab 16.10, nous avons terminé la migration vers la nouvelle API. Désormais, que vous utilisiez l'interface utilisateur ou l'API REST, vous pouvez vous attendre à de meilleures performances, à des timestamps de publication précis et à une prise en charge robuste des images multi-architecture.

Cette amélioration est disponible uniquement sur GitLab.com. La prise en charge pour les instances auto-hébergées est bloquée jusqu'à ce que le registre de conteneurs de nouvelle génération soit généralement disponible. Pour en savoir plus, consultez le [ticket 423459](https://gitlab.com/gitlab-org/gitlab/-/issues/423459).

### Nouvelle métrique du nombre de contributeurs dans le tableau de bord Value Streams {#new-contributor-count-metric-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/433353)

{{< /details >}}

Pour permettre aux responsables logiciels d'obtenir des informations sur la relation entre la vélocité des équipes, la stabilité des logiciels, les expositions aux risques de sécurité et la productivité des équipes, nous avons introduit une nouvelle [métrique **Nombre de contributeurs** dans le tableau de bord Value Streams](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports). Le nombre de contributeurs représente le nombre d'utilisateurs uniques mensuels ayant effectué des contributions dans le groupe. Cette métrique est conçue pour suivre les tendances d'adoption au fil du temps et est basée sur les [événements du calendrier des contributions](../../user/profile/contributions_calendar.md#user-contribution-events).

La métrique **Nombre de contributeurs** est disponible uniquement sur GitLab.com et nécessite que le [rapport d'analytique des contributions soit configuré pour s'exécuter via ClickHouse](../../user/group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse). Le [ticket 441626](https://gitlab.com/gitlab-org/gitlab/-/issues/441626) suit les efforts visant à rendre cette fonctionnalité disponible pour les clients auto-hébergés également.

### Filtres hérités dans Value Stream Analytics pour une analyse de workflow fluide et précise {#inherited-filters-in-value-stream-analytics-for-seamless-and-accurate-workflow-analysis}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/issues_analytics/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/439615)

{{< /details >}}

[Value stream analytics](../../user/group/value_stream_analytics/_index.md) applique désormais les mêmes filtres lors de l'exploration depuis la tuile **Durée d'exécution** vers le [rapport **Analytique des tickets**](../../user/group/issues_analytics/_index.md). L'héritage des filtres vous aide à approfondir vos analyses de manière fluide lorsque vous passez d'une vue analytique à une autre.

### Ajouter un ticket à l'itération actuelle ou suivante avec une action rapide {#add-an-issue-to-the-current-or-next-iteration-with-a-quick-action}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/quick_actions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/384885)

{{< /details >}}

L'action rapide `/iteration` accepte désormais une référence de cadence avec les arguments `--current` ou `--next`. Si votre groupe possède une seule cadence d'itération, vous pouvez rapidement affecter un ticket à l'itération actuelle ou suivante en utilisant `/iteration --current|next`. Si votre groupe contient plusieurs cadences d'itération, vous pouvez spécifier la cadence souhaitée dans l'action rapide en référençant le nom ou l'identifiant de la cadence. Par exemple, `/iteration [cadence:"<cadence name>"|<cadence ID>] --next|current`.

### Continuous Vulnerability Scanning disponible par défaut pour le scan de conteneurs {#continuous-vulnerability-scanning-available-by-default-for-container-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/continuous_vulnerability_scanning/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10174)

{{< /details >}}

Le Continuous Vulnerability Scanning pour le scan de conteneurs est désormais disponible par défaut. La disponibilité par défaut supprime la nécessité de s'abonner à cette fonctionnalité via un feature flag. Pour en savoir plus sur les avantages du Continuous Vulnerability Scanning, consultez le lien vers la documentation.

### Amélioration de la prise en charge de l'analyse des dépendances pour sbt {#improved-dependency-scanning-support-for-sbt}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/390287)

{{< /details >}}

Nous avons mis à jour le mécanisme que nous utilisons pour générer la liste des dépendances pour les projets utilisant sbt. Cette modification ne s'applique qu'aux projets utilisant sbt version 1.7.2 et ultérieure. Pour exploiter pleinement l'analyse des dépendances pour les projets sbt, vous devez effectuer une mise à niveau vers sbt version 1.7.2 ou ultérieure.

### Mises à jour des performances de l'analyseur DAST {#dast-analyzer-performance-updates}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/12194)

{{< /details >}}

Au cours du jalon de release 16.10, le DAST basé sur proxy a été :

- ZAP mis à niveau vers la version 2.14.0. Pour plus d'informations, consultez le [ticket 442056](https://gitlab.com/gitlab-org/gitlab/-/issues/442056).

Nous avons également réalisé les améliorations de performance suivantes pour le crawler DAST basé sur navigateur :

- Limiter le nombre de goroutines créées lors de l'exploration. Pour plus d'informations, consultez le [ticket 440151](https://gitlab.com/gitlab-org/gitlab/-/issues/440151).
- Optimiser la recherche des éléments avec lesquels interagir. Cela a réduit le temps de scan de 6 %. Pour plus d'informations, consultez le [ticket 440295](https://gitlab.com/gitlab-org/gitlab/-/issues/440295).
- Optimiser le désérialisage JSON des messages DevTools. Cela a réduit le temps de scan de 7 %. Pour plus d'informations, consultez le [ticket 439726](https://gitlab.com/gitlab-org/gitlab/-/issues/439726).

### GitLab Runner 16.10 {#gitlab-runner-1610}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.10 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

Correctifs de bugs :

- [Fuite mémoire lorsque des jobs sont annulés dans l'exécuteur Kubernetes du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27857)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-10-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Corrections de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.10)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.10)
- [Améliorations de l'interface](https://papercuts.gitlab.com/?milestone=16.10)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
