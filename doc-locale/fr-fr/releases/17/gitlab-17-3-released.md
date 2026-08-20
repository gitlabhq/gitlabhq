---
stage: Release Notes
group: Monthly Release
date: 2024-08-15
title: "Notes de release de GitLab 17.3"
description: "GitLab 17.3 est disponible avec la fonctionnalité Résoudre les jobs en échec avec l'analyse des causes racines"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 15 août 2024, GitLab 17.3 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Anton Kalmykov {#this-months-notable-contributor-anton-kalmykov}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination ! 🙌

Anton Kalmykov est l'un des meilleurs contributeurs de GitLab cette année avec 37 [contributions fusionnées](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&author_username=antonkalmykov) depuis février, et d'autres en cours. Anton est ingénieur Frontend Senior chez [Yolo group (Bombay Games)](https://yolo.com/).

« Contribuer à GitLab est l'une des initiatives les plus stimulantes, ambitieuses et enthousiasmantes », déclare Anton. « J'apprécie l'opportunité de participer à la création et à l'amélioration d'un produit aussi remarquable. Grâce à cette opportunité, j'ai appris beaucoup de nouvelles choses, et il me reste encore beaucoup à faire. Je suis incroyablement reconnaissant envers l'équipe GitLab, en particulier ceux qui ont examiné mes merge requests, m'ont guidé et m'ont aidé à bien faire les choses. »

Anton a été nommé par [Christina Lohr](https://gitlab.com/lohrc), Senior Product Manager chez GitLab, pour avoir aidé le groupe Tenant Scale sur plusieurs tickets frontend.

« Nous avons de nombreuses améliorations UX mineures à traiter pour nos workflows de base, et il est formidable de bénéficier de l'aide de la communauté pour mener à bien ces initiatives plus rapidement », déclare Christina. « Toutes ces améliorations contribuent à créer une expérience utilisateur plus cohérente entre les groupes et les projets. Merci Anton. »

Un grand merci à Anton et à tous les autres contributeurs open source de GitLab pour leur participation à la co-création de GitLab !

## Fonctionnalités principales {#primary-features}

### Résoudre les jobs en échec avec l'analyse des causes racines {#troubleshoot-failed-jobs-with-root-cause-analysis}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13080)

{{< /details >}}

L'analyse des causes racines est désormais généralement disponible. Grâce à l'analyse des causes racines, vous pouvez résoudre plus rapidement les jobs en échec dans les pipelines CI/CD. Cette fonctionnalité basée sur l'IA analyse le job log du job en échec, détermine rapidement la cause racine de l'échec et vous suggère un correctif.

### Vérification de l'état de GitLab Duo en version bêta {#health-check-for-gitlab-duo-in-beta}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/14518)

{{< /details >}}

Vous pouvez désormais résoudre les problèmes de configuration de GitLab Duo sur votre instance self-managed. Dans la zone **Admin**, sur la page GitLab Duo, sélectionnez **Lancer l'état des services**. Cette vérification de l'état effectue une série de validations et suggère des actions correctives appropriées pour s'assurer que GitLab Duo est opérationnel.

La vérification de l'état de GitLab Duo est disponible sur les instances self-managed et GitLab Dedicated en tant que fonctionnalité en version bêta.

### Supprimer un pod depuis l'interface GitLab {#delete-a-pod-from-the-gitlab-ui}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md#delete-a-pod) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/467653)

{{< /details >}}

Avez-vous déjà eu besoin de redémarrer ou de supprimer un pod défaillant dans Kubernetes ? Jusqu'à présent, vous deviez quitter GitLab, utiliser un autre outil pour vous connecter au cluster, arrêter le pod et attendre qu'un nouveau pod démarre. GitLab intègre désormais la prise en charge native de la suppression des pods, ce qui vous permet de résoudre facilement les problèmes de vos clusters Kubernetes.

Vous pouvez arrêter un pod depuis un [tableau de bord Kubernetes](../../ci/environments/kubernetes_dashboard.md), qui répertorie tous les pods de votre cluster ou espace de nommage.

### Se connecter facilement à un cluster depuis votre terminal local {#easily-connect-to-a-cluster-from-your-local-terminal}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/user_access.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/463769)

{{< /details >}}

Souhaitez-vous vous connecter à un cluster Kubernetes depuis votre terminal local ou en utilisant l'un des outils GUI Kubernetes pour desktop ? GitLab vous permet de vous connecter à un terminal grâce à la [fonctionnalité d'accès utilisateur de l'agent pour Kubernetes](../../user/clusters/agent/user_access.md). Auparavant, trouver des commandes nécessitait de quitter GitLab pour parcourir la documentation. Désormais, GitLab fournit la commande de connexion depuis l'interface utilisateur. GitLab peut même vous aider à configurer l'accès utilisateur !

Pour récupérer la commande de connexion, accédez à un [tableau de bord Kubernetes](../../ci/environments/kubernetes_dashboard.md) ou à la [liste des agents](../../user/clusters/agent/work_with_agent.md#view-your-agents).

### Résoudre une vulnérabilité avec l'IA {#resolve-a-vulnerability-with-ai}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10783)

{{< /details >}}

La résolution des vulnérabilités utilise l'IA pour fournir des suggestions de code spécifiques permettant aux utilisateurs de corriger les vulnérabilités. En un seul clic, vous pouvez ouvrir une merge request pour commencer à résoudre n'importe quelle vulnérabilité SAST à partir de la [liste des identifiants CWE pris en charge](../../user/application_security/vulnerabilities/_index.md#supported-vulnerabilities-for-vulnerability-resolution).

### Ajouter plusieurs référentiels de conformité à un seul projet {#add-multiple-compliance-frameworks-to-a-single-project}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/working_with_projects.md#add-a-compliance-framework-to-a-project) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13294)

{{< /details >}}

Vous pouvez créer un référentiel de conformité pour identifier que votre projet présente certaines exigences de conformité ou nécessite une supervision supplémentaire. Le référentiel de conformité peut éventuellement appliquer une configuration de pipeline de conformité aux projets sur lesquels il est appliqué.

Auparavant, les utilisateurs ne pouvaient appliquer qu'un seul référentiel de conformité à un projet, ce qui limitait le nombre d'exigences de conformité pouvant être définies sur un projet. Nous avons désormais fourni la possibilité pour un utilisateur d'appliquer plusieurs référentiels de conformité par projet. Cela permettra aux utilisateurs d'appliquer plusieurs référentiels de conformité différents à un seul projet à un moment donné. Avec cette release, vous pouvez appliquer plusieurs référentiels de conformité à un projet. Le projet est alors configuré avec les exigences de conformité de chaque référentiel.

### Analytique d'impact IA : taux d'acceptation des suggestions de code et utilisation des sièges GitLab Duo {#ai-impact-analytics-code-suggestions-acceptance-rate-and-gitlab-duo-seats-usage}

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/471168)

{{< /details >}}

Ces deux nouvelles métriques mettent en évidence l'efficacité et l'utilisation de GitLab Duo, et sont désormais incluses dans [l'analytique d'impact IA dans le tableau de bord Value Streams](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/), qui aide les organisations à comprendre l'impact de GitLab Duo sur la création de valeur métier.

La métrique **Taux d'acceptation des suggestions de code** indique la fréquence à laquelle les développeurs acceptent les suggestions de code proposées par GitLab Duo. Cette métrique reflète à la fois l'efficacité de ces suggestions et le niveau de confiance que les contributeurs accordent aux capacités de l'IA. Plus précisément, la métrique représente le pourcentage de suggestions de code fournies par GitLab Duo qui ont été acceptées par les contributeurs de code au cours des 30 derniers jours.

La métrique **GitLab Duo seats assigned and used** affiche le pourcentage de sièges sous licence consommés, aidant les organisations à planifier efficacement l'utilisation des licences, l'allocation des ressources et la compréhension des schémas d'utilisation. Cette métrique suit le ratio de sièges attribués ayant utilisé au moins une fonctionnalité IA au cours des 30 derniers jours.

Avec l'ajout de ces nouvelles métriques, nous avons également introduit de nouvelles vignettes de vue d'ensemble — une nouvelle visualisation qui fournit un résumé clair des métriques, vous aidant à évaluer rapidement l'état actuel de vos fonctionnalités IA.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.3 inclut des packages prenant en charge [Raspberry Pi OS 12](https://www.raspberrypi.com/news/bookworm-the-new-version-of-raspberry-pi-os/).

Debian 10 a atteint sa [fin de vie le 30 juin 2024](https://www.debian.org/releases/buster/). GitLab supprimera la prise en charge de Debian 10 dans GitLab 17.6.

### Amélioration du tri et du filtrage des projets et des groupes dans Your Work {#improved-sorting-and-filtering-for-projects-and-groups-in-your-work}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/25368)

{{< /details >}}

Nous avons mis à jour les fonctionnalités de tri et de filtrage de la vue d'ensemble des projets et des groupes dans **Your Work**. Auparavant, dans la page **Your Work** pour les projets, vous pouviez filtrer par nom et par langage, et utiliser un ensemble prédéfini d'options de tri. Nous avons standardisé les options de tri pour inclure **Nom**, **Date de création**, **Date de mise à jour** et **Favori**. Nous avons également ajouté un élément de navigation pour trier par ordre croissant ou décroissant, et déplacé le filtre de langage vers le menu de filtrage. Vous pouvez maintenant trouver les projets archivés dans le nouvel onglet **Inactif**. De plus, nous avons ajouté un filtre **Rôle** qui vous permet de rechercher les projets dont vous êtes le propriétaire.

Dans la page Your Work pour les groupes, nous avons standardisé les options de tri pour inclure **Nom**, **Date de création** et **Date de mise à jour**, et ajouté un élément de navigation pour trier par ordre croissant ou décroissant.

Nous accueillons vos commentaires sur ces modifications dans [\#438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322).

### Indexation de bout en bout de l'instance pour la recherche avancée {#end-to-end-instance-indexing-for-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/advanced_search/elasticsearch.md#index-the-instance) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/271532)

{{< /details >}}

Lorsque vous activez la recherche avancée dans GitLab, vous pouvez désormais sélectionner **Indexer l'instance** pour effectuer l'indexation initiale ou recréer un index de zéro. Ce paramètre atteint une parité fonctionnelle avec la tâche rake `gitlab:elastic:index` en indexant tous les types de données pris en charge dans le cluster Elasticsearch ou OpenSearch intégré.

**Indexer l'instance** remplace le paramètre d'indexation de tous les projets, qui était limité à l'indexation initiale uniquement.

### Basculer l'héritage des paramètres des intégrations via l'API {#toggle-inheriting-settings-for-integrations-by-using-the-api}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)

{{< /details >}}

Jusqu'à présent, vous ne pouviez contrôler que via l'interface utilisateur si un projet héritait des paramètres d'intégration ou utilisait ses propres paramètres.

Dans ce jalon, nous introduisons un nouveau paramètre `use_inherited_settings` dans l'API REST de toutes les intégrations. Ce paramètre vous permet d'utiliser l'API pour définir si un projet hérite ou non des paramètres d'intégration. S'il n'est pas défini, le comportement par défaut est `false` (utiliser les paramètres propres au projet).

### Lister les événements webhook d'un groupe ou d'un projet via l'API {#list-group-or-project-webhook-events-with-the-api}

<!-- categories: Notifications -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/project_webhooks.md#list-project-webhook-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/437188)

{{< /details >}}

Depuis GitLab 9.3, vous pouvez consulter l'historique des requêtes webhook de projet dans l'interface utilisateur, et depuis GitLab 15.3, vous pouvez également [consulter l'historique des requêtes webhook de groupe dans l'interface utilisateur](../../user/project/integrations/webhooks.md#view-webhook-request-history).

Dans cette release, ces données sont désormais exposées dans l'API REST, ce qui peut vous aider à automatiser les processus de détection et de réponse aux erreurs de webhook. Vous pouvez obtenir une liste d'événements pour un [hook de projet](../../api/project_webhooks.md#list-project-webhook-events) et un [hook de groupe](../../api/group_webhooks.md#list-all-group-hook-events) spécifiques au cours des 7 derniers jours.

Merci à [Phawin](https://gitlab.com/lifez) pour [cette contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048) !

### Trouver les paramètres de groupe à l'aide de la palette de commandes {#find-group-settings-by-using-the-command-palette}

<!-- categories: Settings, Global Search -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/command_palette.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/448646)

{{< /details >}}

Dans la version 17.2, nous avons ajouté la possibilité de [rechercher les paramètres de projet à l'aide de la palette de commandes](https://about.gitlab.com/releases/2024/07/18/gitlab-17-2-released/#find-project-settings-by-using-the-command-palette). Cette modification a facilité la recherche rapide des paramètres dont vous avez besoin.

Avec la version 17.3, vous pouvez désormais également rechercher des paramètres de groupe depuis la palette de commandes. Essayez-la en visitant un groupe, en sélectionnant **Rechercher ou accéder à**, en entrant en mode commande avec `>`, et en saisissant le nom d'une section de paramètres, comme **Approbations des requêtes de fusion**. Sélectionnez un résultat pour accéder directement au paramètre lui-même.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Contrôle granulaire des suggestions de code par langage dans VS Code {#granular-control-of-code-suggestions-by-language-in-vs-code}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/project/repository/code_suggestions/supported_extensions.md#manage-languages-for-code-suggestions) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1388)

{{< /details >}}

Bénéficiez d'un meilleur contrôle sur votre expérience de codage dans VS Code en activant ou désactivant les suggestions de code pour des langages de programmation spécifiques. Ce contrôle granulaire vous permet de personnaliser votre workflow, en réduisant les suggestions non pertinentes ou intrusives tout en conservant les avantages des suggestions de code pour vos langages préférés.

### Amélioration de la prise en charge TLS dans les IDE JetBrains {#improved-tls-support-in-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md#certificate-errors) \| [Ticket associé](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/371)

{{< /details >}}

Pour renforcer la sécurité dans les environnements sensibles, vous pouvez désormais configurer des options d'agent HTTP personnalisées, notamment des certificats clients et des autorités de certification, directement dans les paramètres de votre IDE JetBrains.

### Supprimer plus facilement du contenu des dépôts {#more-easily-remove-content-from-repositories}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/repository_size.md#remove-blobs)

{{< /details >}}

Actuellement, le processus de suppression de contenu d'un dépôt est complexe et vous pourriez avoir besoin d'effectuer un push forcé du projet vers GitLab. Cela est sujet aux erreurs et peut vous obliger à désactiver temporairement les protections pour permettre le push. Il peut être encore plus difficile de supprimer des fichiers qui occupent trop d'espace dans le dépôt.

Vous pouvez désormais utiliser la nouvelle option de maintenance de dépôt dans les paramètres du projet pour supprimer des blobs à partir d'une liste d'ID d'objets. Avec cette nouvelle méthode, vous pouvez supprimer sélectivement du contenu sans avoir besoin d'effectuer un push forcé d'un projet vers GitLab.

Dans le cas où des secrets ou d'autres contenus ont été poussés et doivent être supprimés d'un projet, nous introduisons également une nouvelle option pour expurger du texte. Fournissez une chaîne que GitLab remplacera par `***REMOVED***` dans les fichiers du projet. Une fois le texte expurgé, exécutez la maintenance pour supprimer les anciennes versions de la chaîne.

Cette nouvelle interface utilisateur simplifie la gestion de vos dépôts lorsque du contenu doit être supprimé.

### Événement d'audit lors de la création et de la suppression d'un agent pour Kubernetes {#audit-event-when-agent-for-kubernetes-is-created-and-deleted}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/audit_event_types.md#deployment-management) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/462749)

{{< /details >}}

Étant donné que l'agent pour Kubernetes permet un flux de données bidirectionnel entre un cluster Kubernetes et GitLab, il est important de savoir quand un composant pouvant accéder à vos systèmes est ajouté ou supprimé. Dans les versions précédentes, les équipes de conformité devaient utiliser des outils personnalisés ou rechercher ces données directement dans GitLab. GitLab fournit désormais les événements d'audit suivants :

- `cluster_agent_created` enregistre qui a enregistré un nouvel agent pour Kubernetes.
- `cluster_agent_create_failed` enregistre qui a tenté d'enregistrer un nouvel agent pour Kubernetes mais a échoué.
- `cluster_agent_deleted` enregistre qui a supprimé l'enregistrement d'un agent pour Kubernetes.
- `cluster_agent_delete_failed` enregistre qui a tenté de supprimer l'enregistrement d'un agent pour Kubernetes mais a échoué.

Ces événements d'audit étendent les événements d'audit `cluster_agent_token_created` et `cluster_agent_token_revoked` pour améliorer davantage la capacité d'audit de votre instance GitLab.

### Prise en charge de Kubernetes 1.30 {#kubernetes-130-support}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/456929)

{{< /details >}}

Cette release ajoute la prise en charge complète de Kubernetes version 1.30, publiée en avril 2024. Si vous déployez vos applications sur Kubernetes, vous pouvez désormais mettre à niveau vos clusters connectés vers la version la plus récente et profiter de toutes ses fonctionnalités.

Vous pouvez en savoir plus sur [notre politique de prise en charge Kubernetes et les autres versions Kubernetes prises en charge](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### Ajouter une authentification aux vérifications de statut externes des merge requests {#add-authentication-to-merge-request-external-status-checks}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/status_checks.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/433035)

{{< /details >}}

Les vérifications de statut externes peuvent désormais être configurées avec l'authentification HMAC (Hash-based Message Authentication Code). Cela fournira une méthode plus sécurisée pour vérifier l'authenticité des requêtes de GitLab vers les services externes.

Lorsqu'elle est activée pour votre vérification de statut, un secret partagé est utilisé pour générer une signature unique pour chaque requête. La signature est envoyée dans l'en-tête `X-Gitlab-Signature`, en utilisant SHA256 comme algorithme de hachage.

- Sécurité améliorée : l'authentification HMAC empêche la falsification des requêtes et garantit qu'elles proviennent d'une source légitime.
- Conformité : cette fonctionnalité est particulièrement utile pour les secteurs réglementés, comme la banque, où la sécurité est primordiale.
- Compatibilité ascendante : la fonctionnalité sera optionnelle et compatible avec les versions antérieures. Les utilisateurs peuvent choisir d'activer l'authentification HMAC pour les vérifications nouvelles ou existantes, mais les vérifications de statut externes existantes continueront à fonctionner sans modification.

Dans une [itération future](https://gitlab.com/gitlab-org/gitlab/-/issues/476163), GitLab prévoit d'ajouter une option pour également vérifier et bloquer les requêtes HTTP.

### Filtrer la liste des membres d'un groupe ou d'un projet par rôle {#filter-the-member-list-in-a-group-or-project-by-role}

<!-- categories: Permissions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/members/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/431397)

{{< /details >}}

Les utilisateurs peuvent désormais filtrer la page Membres par rôle. Utilisez le filtre pour trouver des membres avec un rôle spécifique.

### Afficher les détails du rôle dans le panneau latéral droit {#view-role-details-in-the-right-drawer}

<!-- categories: Permissions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/13061)

{{< /details >}}

Auparavant, si vous souhaitiez consulter les autorisations des rôles personnalisés d'un utilisateur, vous deviez disposer du rôle Propriétaire dans le groupe. Cette exigence rendait difficile le dépannage et la compréhension des actions qu'un utilisateur peut effectuer lorsqu'il se voit attribuer un rôle personnalisé. Désormais, tout utilisateur peut consulter les autorisations d'un utilisateur auquel un rôle personnalisé a été attribué dans la page Membres.

### Prise en charge des liens de groupe LDAP pour les rôles personnalisés {#ldap-group-link-support-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/435229)

{{< /details >}}

Les organisations qui utilisent des liens de groupe LDAP pour gérer les autorisations des utilisateurs pour les groupes peuvent déjà utiliser des rôles par défaut pour l'appartenance.

Dans cette release, nous étendons cette prise en charge aux [rôles personnalisés](../../user/custom_roles/_index.md). Cette configuration facilite le mappage des accès pour un grand groupe d'utilisateurs.

### Nouvelle permission pour les rôles personnalisés {#new-permission-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

Vous pouvez créer des rôles personnalisés avec la nouvelle permission suivante :

- [Read Runners](../../user/custom_roles/abilities.md#runner)

Avec les rôles personnalisés, vous pouvez réduire le nombre d'utilisateurs disposant du rôle Owner en créant des utilisateurs avec des autorisations équivalentes. Cela vous aide à définir des rôles adaptés aux besoins de votre groupe et empêche les utilisateurs de recevoir plus de privilèges qu'il n'en faut.

### Désactiver les jetons d'accès personnels via l'interface Admin {#disable-personal-access-tokens-using-admin-ui}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/profile/personal_access_tokens.md#view-token-usage-information) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/436991)

{{< /details >}}

Les administrateurs peuvent désormais désactiver ou réactiver les jetons d'accès personnels d'instance via l'interface Admin. Auparavant, les administrateurs devaient utiliser l'API des paramètres d'application ou la console GitLab Rails pour effectuer cette opération.

### Identifiant Bluesky dans le profil utilisateur {#bluesky-identifier-in-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/_index.md#add-external-accounts-to-your-user-profile-page) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/451690)

{{< /details >}}

Vous pouvez désormais ajouter votre identifiant Bluesky did:plc à votre profil GitLab.

Merci à [Dominique](https://domi.zip/) pour votre contribution !

### Cookies de sous-domaine préservés lors de la déconnexion {#subdomain-cookies-preserved-on-sign-out}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/active_sessions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/471097)

{{< /details >}}

Le processus de déconnexion de GitLab a été amélioré afin que les cookies des sous-domaines frères ne soient pas supprimés lors de la déconnexion. Auparavant, ces cookies étaient supprimés, ce qui entraînait la déconnexion des utilisateurs des autres services de sous-domaine sur le même domaine de premier niveau que GitLab. Par exemple, si un utilisateur a Kibana configuré sur `kibana.example.com` et GitLab configuré sur `gitlab.example.com`, la déconnexion de GitLab ne déconnectera plus l'utilisateur de Kibana.

Merci à [Guilherme C. Souza](https://gitlab.com/GCSBOSS) pour votre contribution !

### Analytique d'impact IA avec une visualisation améliorée des tendances par sparklines {#ai-impact-analytics-with-enhanced-sparklines-trend-visualization}

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/analytics/duo_and_sdlc_trends.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/464692)

{{< /details >}}

Nous sommes ravis d'annoncer une amélioration significative de notre [analytique d'impact IA](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/) avec l'introduction des sparklines. Ces petits graphiques simples intégrés dans les tableaux de données améliorent la lisibilité et l'accessibilité des données d'impact IA. En transformant les valeurs numériques en représentations visuelles, les nouvelles sparklines facilitent l'identification des tendances au fil du temps, vous permettant de repérer les mouvements à la hausse ou à la baisse. Cette nouvelle approche visuelle simplifie également le processus de comparaison des tendances sur plusieurs métriques, réduisant le temps et les efforts nécessaires lorsqu'on s'appuie uniquement sur des chiffres.

### Ajouter des merge requests aux tâches {#add-merge-requests-to-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/tasks.md#add-a-merge-request-and-automatically-close-tasks) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/440851)

{{< /details >}}

Les tâches sont fréquemment utilisées pour décomposer les tickets en étapes d'implémentation technique. Avant cette release, il n'existait aucun moyen de relier une merge request à la tâche qu'elle implémente. Vous pouvez désormais utiliser le même [modèle de fermeture](../../user/project/issues/managing_issues.md#closing-issues-automatically) que vous utiliseriez lors du référencement de tickets depuis la description d'une merge request pour relier une merge request à une tâche. Depuis la vue de la tâche, les merge requests connectées sont visibles depuis la barre latérale. Si votre projet a le [paramètre de fermeture automatique activé](../../user/project/issues/managing_issues.md#disable-automatic-issue-closing), la tâche se fermera automatiquement lorsque la merge request connectée sera fusionnée dans votre branche par défaut.

### Définir les éléments parents pour les OKR et les tâches {#set-parent-items-for-okrs-and-tasks}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/okrs.md#set-an-objective-as-a-parent) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11198)

{{< /details >}}

Vous pouvez désormais mettre à jour facilement les attributions parent pour les [OKR](../../user/okrs.md#set-an-objective-as-a-parent) et les [tâches](../../user/tasks.md#set-an-issue-as-a-parent), directement depuis l'enregistrement enfant, éliminant ainsi le besoin de naviguer dans les deux sens. Il s'agit d'une étape importante vers notre objectif d'[amélioration de l'efficacité de vos workflows](https://gitlab.com/groups/gitlab-org/-/epics/10501).

### Signaler des abus pour les tâches, objectifs et résultats clés {#report-abuse-for-task-objective-and-key-result-items}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/report_abuse.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)

{{< /details >}}

Vous pouvez désormais facilement signaler des abus pour des éléments de travail directement depuis le menu **Actions**, tout comme vous pouvez le faire avec les tickets existants. Cette nouvelle fonctionnalité contribue à maintenir votre workspace propre et sûr en vous permettant de signaler rapidement du contenu inapproprié, garantissant ainsi un meilleur environnement collaboratif pour votre équipe.

### Résoudre les fils de discussion dans les tâches, objectifs et résultats clés {#resolve-threads-in-tasks-objectives-and-key-results}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/discussions/_index.md#resolve-a-thread) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/458818)

{{< /details >}}

Vous pouvez désormais résoudre les fils de discussion dans les tâches, les objectifs et les résultats clés, ce qui facilite la gestion et le suivi des conversations importantes. Les fils de discussion résolus sont réduits par défaut, vous aidant à vous concentrer sur les discussions actives et à simplifier vos workflows de collaboration.

### Nouveaux événements d'étape Value Stream Analytics pour la réduction du temps de cycle {#new-value-stream-analytics-stage-events-for-cycle-time-reduction}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/466383)

{{< /details >}}

Pour améliorer le suivi du temps de révision des merge requests (MR) dans GitLab, nous avons ajouté un nouvel événement d'étape à [Value Stream Analytics](https://about.gitlab.com/solutions/value-stream-management/) : **MR first reviewer assigned**. Grâce à ce nouvel événement, les équipes peuvent identifier où se produisent les retards dans le processus de révision, trouver des opportunités d'améliorer la collaboration et encourager une culture de réactivité et de responsabilité parmi les membres de l'équipe. La réduction du temps de révision a un impact direct sur le temps de cycle global du développement, [conduisant à une livraison logicielle plus rapide](https://about.gitlab.com/blog/three-steps-to-optimize-software-value-streams/). Par exemple, vous pouvez désormais ajouter une nouvelle étape personnalisée **Review Time to Merge (RTTM)** qui commence avec **MR first reviewer assigned** et se termine avec **MR merged**.

### Prise en charge de Rust pour l'analyse des dépendances et des licences {#rust-support-for-dependency-and-license-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/13093)

{{< /details >}}

Composition Analysis a livré la prise en charge de Rust pour l'analyse des dépendances et des licences. L'analyse Rust prend en charge le type de fichier `Cargo.lock`.

Pour activer l'analyse Rust pour votre projet, utilisez le modèle `cargo` du [composant CI/CD d'analyse des dépendances](https://gitlab.com/explore/catalog/components/dependency-scanning).

### Afficher les erreurs d'ingestion SBOM dans l'interface GitLab {#display-sbom-ingestion-errors-in-gitlab-ui}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/14408)

{{< /details >}}

GitLab 15.3 a ajouté la prise en charge de [l'ingestion des SBOMs CycloneDX](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx). Bien que les rapports SBOM soient validés par rapport au schéma CycloneDX, les avertissements et les erreurs produits dans le cadre de la validation n'étaient pas affichés à l'utilisateur.

Dans GitLab 17.3, ces messages de validation apparaissent dans l'interface GitLab sur les pages Rapport de vulnérabilité et Liste des dépendances au niveau du projet.

Les utilisateurs pourront consulter les erreurs d'ingestion SBOM dans les zones suivantes de l'interface GitLab : les pages de rapport de vulnérabilité et de liste des dépendances au niveau du projet, les onglets licences et sécurité de la page de pipeline.

### Appliquer l'ensemble de règles utilisé dans SAST, l'analyse IaC et la détection des secrets {#enforce-the-ruleset-used-in-sast-iac-scanning-and-secret-detection}

<!-- categories: SAST, Secret Detection, Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/customize_rulesets.md#use-a-remote-ruleset-file)

{{< /details >}}

Vous pouvez personnaliser les règles utilisées dans [SAST](../../user/application_security/sast/customize_rulesets.md), l'[analyse IaC](../../user/application_security/iac_scanning/_index.md#optimize-iac-scanning) et la [détection des secrets](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-behavior) en créant un fichier de configuration local commité dans le dépôt ou en définissant une variable CI/CD pour appliquer une configuration partagée à plusieurs projets.

Auparavant, les analyseurs préféraient le fichier de configuration local, même si vous aviez également défini une référence d'ensemble de règles partagé. Cet ordre de priorité rendait difficile de s'assurer que les analyses utiliseraient un ensemble de règles connu et approuvé.

Désormais, nous avons ajouté une nouvelle variable CI/CD, `SECURE_ENABLE_LOCAL_CONFIGURATION`, pour contrôler si les fichiers de configuration locaux sont autorisés. Sa valeur par défaut est `true`, ce qui conserve le comportement existant : les fichiers de configuration locaux sont autorisés et sont préférés aux configurations partagées. Si vous définissez la valeur sur `false` lorsque vous [appliquez l'exécution des analyses](../../user/application_security/policies/scan_execution_policies.md), vous pouvez être sûr que les analyses utiliseront votre ensemble de règles partagé, ou l'ensemble de règles par défaut, même si les développeurs du projet ajoutent un fichier de configuration local.

### Filtrer les jobs par nom de job {#filter-jobs-by-job-name}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/387547)

{{< /details >}}

Vous pouvez désormais trouver rapidement un job spécifique en recherchant son nom.

Auparavant, vous ne pouviez filtrer la liste des jobs que par statut, ce qui nécessitait un défilement manuel pour trouver un job spécifique. Avec cette release, vous pouvez désormais saisir un nom de job pour filtrer les résultats. Les résultats n'incluront que les jobs dans les pipelines exécutés après la release de GitLab 17.3.

### Visualisation du merge train {#merge-train-visualization}

<!-- categories: Merge Trains -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/merge_trains.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13705)

{{< /details >}}

Vous pouvez désormais visualiser le merge train pour mieux comprendre le statut et l'ordre des merge requests dans le pipeline. Grâce à la visualisation du merge train, vous pouvez identifier les conflits plus tôt, agir directement sur les merge requests dans le merge train et minimiser le risque de casser la branche par défaut.

### GitLab Runner 17.3 {#gitlab-runner-173}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions GitLab Runner 17.3 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Corrections de bugs {#bug-fixes}

- [Les jobs semblent se bloquer lorsqu'ils sont annulés dans le runner Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37780)
- [Le niveau de log n'est pas mis à jour lorsqu'il n'est pas spécifié](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37490)
- [Le job log ajoute des sauts de ligne supplémentaires lors de l'utilisation de l'exécuteur Kubernetes du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27099)

Pour une liste de toutes les modifications, consultez le [changelog](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-3-stable/CHANGELOG.md) de GitLab Runner.

### Amélioration des performances des runners hébergés sur macOS {#improved-performance-for-hosted-runners-on-macos}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/macos.md) \| [Ticket associé](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/job-images/-/issues/6)

{{< /details >}}

Nous avons livré des améliorations de performances avec la récente mise à niveau vers macOS 14.5 et Xcode 15.4. Avec cette modification, les jobs de build Xcode sont nettement plus rapides par rapport aux exécutions précédentes.

### Description et type ajoutés aux détails des entrées du composant du catalogue CI/CD {#description-and-type-added-to-cicd-catalog-component-input-details}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/components/_index.md#cicd-catalog) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/426870)

{{< /details >}}

La page de détails d'un composant CI/CD dans le catalogue CI/CD fournit des informations utiles sur le composant. Dans cette release, nous avons ajouté deux nouvelles colonnes au tableau qui affiche les informations sur les entrées disponibles. Les nouvelles colonnes **Description** et **Type** facilitent grandement la compréhension de l'utilisation d'une entrée et du type de valeur attendu.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.3)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.3)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.3)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
