---
stage: Release Notes
group: Monthly Release
date: 2023-10-22
title: "Notes de release de GitLab 16.5"
description: "GitLab 16.5 est disponible avec le rapport de conformité aux standards"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 22 octobre 2023, GitLab 16.5 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Thorben Westerhuys {#this-months-notable-contributor-thorben-westerhuys}

Thorben a été reconnu pour son travail continu sur sa merge request visant à [ajouter une préférence utilisateur pour afficher les heures au format 24 heures](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130789). Cette fonctionnalité est prévue pour la version 16.6 et donnera aux utilisateurs le choix entre les formats d'heure 12 heures et 24 heures.

Magdalena Frankiewicz, Product Manager chez GitLab, a nommé Thorben et a souligné que le ticket relatif à cette fonctionnalité est ouvert depuis 7 ans avec plus de 190 votes positifs. Peter Leitzen, Staff Backend Engineer chez GitLab, a également mis en avant le travail de Thorben visant à [refactoriser le code backend lié au format d'heure](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130794).

Thorben est CTO de LUUCY, une plateforme web 3D qui rassemble des données géographiques haute résolution. Il est ancien CTO de cividi, un cabinet de conseil en données géospatiales spécialisé dans les sujets liés à l'urbanisme.

Merci à Thorben et au reste de la communauté GitLab pour leurs contributions 🙌

## Fonctionnalités principales {#primary-features}

### Rapport de conformité aux standards {#compliance-standards-adherence-report}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

Le Compliance Center inclut désormais un nouvel onglet pour le rapport de conformité aux standards. Ce rapport inclut initialement un standard de bonnes pratiques GitLab, indiquant quand les projets de votre groupe ne satisfont pas aux exigences des vérifications incluses dans le standard. Les trois vérifications affichées initialement sont :

- Une règle d'approbation existe pour exiger au moins 2 approbateurs sur les MR
- Une règle d'approbation existe pour interdire à l'auteur de la MR de fusionner
- Une règle d'approbation existe pour interdire aux contributeurs de la MR de fusionner

Le rapport contient des détails sur le statut de chaque vérification par projet. Il indique également la dernière date d'exécution de la vérification, le standard auquel elle s'applique, et comment corriger les échecs ou problèmes éventuellement signalés dans le rapport. Les itérations futures ajouteront davantage de vérifications et élargiront la portée pour inclure davantage de réglementations et de standards. De plus, nous ajouterons des améliorations pour regrouper et filtrer le rapport, afin que vous puissiez vous concentrer sur les projets ou les standards les plus importants pour votre organisation.

### Créer des règles pour définir les branches cibles des merge requests {#create-rules-to-set-target-branches-for-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/branches/_index.md#configure-workflows-for-target-branches)

{{< /details >}}

Certains projets utilisent plusieurs branches à long terme pour le développement, comme `develop` et `qa`. Dans ces projets, vous souhaiterez peut-être conserver `main` comme branche par défaut, car elle représente l'état de production du projet. Cependant, le travail de développement s'attend à ce que les merge requests ciblent `develop` ou `qa`. Les règles de branche cible permettent de s'assurer que les merge requests ciblent la branche appropriée pour votre projet et votre workflow de développement.

Lorsque vous créez une merge request, la règle vérifie le nom de la branche. Si le nom de la branche correspond à la règle, la merge request présélectionne la branche que vous avez spécifiée dans la règle comme cible. Si le nom de la branche ne correspond pas, la merge request cible la branche par défaut du projet.

### Résoudre un fil de discussion d'un ticket {#resolve-an-issue-thread}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/discussions/_index.md#resolve-a-thread) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)

{{< /details >}}

Les tickets de longue durée comportant de nombreux fils de discussion peuvent être difficiles à lire et à suivre. Vous pouvez désormais résoudre un fil de discussion sur un ticket lorsque le sujet de discussion est clos.

### Merge trains fast-forward avec historique semi-linéaire {#fast-forward-merge-trains-with-semi-linear-history}

<!-- categories: Merge Trains -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/merge_trains.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/26996)

{{< /details >}}

Dans la version 16.4, nous avons publié les [merge trains fast-forward](https://about.gitlab.com/releases/2023/09/22/gitlab-16-4-released/#fast-forward-merge-support-for-merge-trains) et, dans la continuité, nous souhaitons nous assurer de prendre en charge toutes les [méthodes de fusion](../../user/project/merge_requests/methods/_index.md). Désormais, si vous souhaitez vous assurer que votre historique de commits semi-linéaire est maintenu, vous pouvez utiliser les merge trains fast-forward semi-linéaires.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Trouver des epics avec la recherche avancée {#find-epics-with-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/250699)

{{< /details >}}

La popularité des epics dans GitLab continue de croître. Auparavant, trouver des epics était un peu plus difficile que pour les autres types de contenu. Avec cette release, vous pouvez désormais rechercher et afficher des résultats pour les epics lorsque vous utilisez la recherche avancée.

### Améliorations Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- Les paquets Linux `.deb` de GitLab 16.5 ont [basculé de la compression gzip vers xz](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8197), ce qui réduit la taille des paquets. Ce changement peut entraîner des temps de décompression plus longs lors de l'installation.
- GitLab 16.5 inclut [Mattermost 9.0](https://docs.mattermost.com/install/self-managed-changelog.html#release-v9-0-major-release). Cette version supprime la fonctionnalité Insights dépréciée, et [Mattermost Boards ainsi que divers plugins sont passés sous support communautaire](https://forum.mattermost.com/t/upcoming-product-changes-to-boards-and-various-plugins/16669).
- GitLab 16.5 [déplace le module de politique SELinux GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/7165) de `/opt/gitlab/embedded/selinux/rhel/7/` vers `/opt/gitlab/embedded/selinux` pour refléter que le module n'est pas uniquement destiné à RHEL 7.

### Informations sur les relecteurs pour les merge requests dans le panneau de développement Jira {#reviewer-information-for-merge-requests-in-the-jira-development-panel}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/jira/development_panel.md#information-displayed-in-the-development-panel) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/364273)

{{< /details >}}

Avec l'[application GitLab pour Jira Cloud](../../integration/jira/connect-app.md), vous pouvez connecter GitLab et Jira Cloud pour synchroniser les informations de développement en temps réel. Vous pouvez consulter ces informations dans le panneau de développement Jira. Auparavant, lorsqu'un relecteur était assigné à une merge request, les informations le concernant n'étaient pas affichées dans le panneau de développement Jira. Avec cette release, le nom du relecteur, son adresse e-mail et son statut d'approbation sont affichés dans le panneau de développement Jira lorsque vous utilisez l'application GitLab pour Jira Cloud.

### Changer de contexte est désormais plus simple {#changing-context-just-got-easier}

<!-- categories: Navigation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

Nous avons pris note de vos retours indiquant qu'il peut être difficile de trouver le bouton de recherche dans la barre latérale gauche et de basculer entre des éléments tels que les projets et les préférences. Dans cette release, nous avons rendu le bouton plus visible. Cela facilite la découverte et rationalise les workflows en un seul point d'accès.

Vous pouvez l'essayer en sélectionnant le bouton **Search or go to…** ou avec un raccourci clavier en tapant / ou s.

### Le webhook est désormais déclenché lors de la suppression d'une release {#webhook-now-triggered-when-a-release-is-deleted}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhook_events.md#release-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/418113)

{{< /details >}}

Vous pouvez utiliser les événements de release pour surveiller les objets de release et réagir aux modifications. Auparavant, un webhook n'était déclenché que lors de la création ou de la mise à jour d'une release. Dans les secteurs fortement réglementés, la suppression de releases est un événement crucial qui doit être surveillé et suivi. Avec GitLab 16.5, un webhook est désormais également déclenché lors de la suppression d'une release.

### Liste des tickets du Service Desk repensée {#redesigned-service-desk-issues-list}

<!-- categories: Service Desk -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/service_desk/using_service_desk.md)

{{< /details >}}

Nous avons repensé la liste des tickets du Service Desk pour qu'elle se charge plus rapidement et de manière plus fluide. Elle correspond désormais plus étroitement à la liste de tickets standard. Les fonctionnalités disponibles incluent :

- Les mêmes options de tri et d'organisation que dans la liste de tickets.
- Les mêmes filtres, y compris l'opérateur OU et le filtrage par identifiant de ticket.

### Geo ajoute des boutons de resynchronisation et de revérification en masse pour tous les composants {#geo-adds-bulk-resync-and-reverify-buttons-for-all-components}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/geo/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/8212)

{{< /details >}}

Vous pouvez désormais déclencher une resynchronisation ou une revérification en masse pour n'importe quel composant de données géré par Geo, via des boutons dans l'interface d'administration Geo. La sélection du bouton applique l'opération à tous les éléments de données liés au composant concerné. Auparavant, cela n'était possible qu'en se connectant à la console Rails. Ces actions sont désormais plus accessibles, et l'expérience de dépannage et d'application de modifications à grande échelle nécessitant une resynchronisation ou une revérification complète de composants spécifiques, comme le déplacement d'emplacements de stockage, est améliorée.

### Sauvegarder et restaurer les données du dépôt dans le cloud {#back-up-and-restore-repository-data-in-the-cloud}

<!-- categories: Gitaly, Backup/Restore of GitLab instances -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/backup_restore/backup_gitlab.md#create-server-side-repository-backups) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10826)

{{< /details >}}

La fonctionnalité de sauvegarde et de restauration de GitLab prend désormais en charge le stockage des données de dépôt dans un stockage objet. Cette mise à jour améliore les performances en éliminant les étapes intermédiaires utilisées pour créer une archive tar volumineuse, qui doit être stockée manuellement à un emplacement approprié.

Avec cette mise à jour, les sauvegardes de dépôt sont stockées dans un emplacement de stockage objet de votre choix (Amazon S3, Google Cloud Storage, Azure Cloud Data Storage, MinIO, etc.). Ce changement élimine la nécessité de déplacer manuellement les données depuis votre instance Gitaly.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Intégrer l'approbation des déploiements et les modifications des règles d'approbation dans les événements d'audit {#integrate-deployment-approval-and-approval-rule-changes-into-audit-events}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/audit_event_types.md#environment-management) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415603)

{{< /details >}}

Les déploiements dans les secteurs réglementés sont un sujet central de conformité. Dans les releases précédentes, les approbations de déploiement ne faisaient pas partie des événements audités, ce qui rendait difficile de déterminer quand et comment les règles d'approbation avaient changé.

GitLab intègre désormais un nouvel ensemble d'événements d'audit pour l'approbation des déploiements et les modifications des règles d'approbation. Ces événements se déclenchent lorsque les règles d'approbation de déploiement changent, ou lorsque les règles d'approbation pour les environnements protégés changent.

### Utiliser l'API pour supprimer les identités SAML et SCIM d'un utilisateur {#use-the-api-to-delete-a-users-saml-and-scim-identities}

<!-- categories: User Management -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../api/scim.md#delete-a-single-scim-identity) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/423592)

{{< /details >}}

Auparavant, les propriétaires de groupe n'avaient aucun moyen de supprimer par programmation des identités SAML ou SCIM. Cela rendait difficile le dépannage des problèmes liés aux processus de provisionnement des utilisateurs et de connexion. Désormais, les propriétaires de groupe peuvent utiliser de nouveaux endpoints pour supprimer ces identités.

Merci à [jgao1025](https://gitlab.com/jgao1025) pour sa contribution !

### Exporter le rapport de violations de conformité {#export-the-compliance-violations-report}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

Le rapport de violations de conformité peut contenir beaucoup d'informations. Auparavant, vous pouviez uniquement consulter les informations dans l'interface de GitLab. Cela convenait pour les tickets individuels, mais pouvait s'avérer complexe si vous deviez, par exemple :

- Créer un artefact du statut de conformité actuel pour une release. Par exemple, prouver à un auditeur qu'il y avait 0 violation.
- Agréger les données avec un autre ensemble de données ou les traiter dans un autre outil.

Dans GitLab 16.5, vous pouvez désormais exporter une liste des éléments inclus dans le rapport de violations de conformité au format CSV.

### Nouvelles autorisations personnalisables {#new-customizable-permissions}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/17364)

{{< /details >}}

Les autorisations permettant de gérer les membres du groupe et les jetons d'accès au projet ont été ajoutées au framework des rôles personnalisés. Vous pouvez ajouter ces autorisations personnalisées à n'importe quel rôle par défaut pour créer un rôle personnalisé. En créant des rôles personnalisés avec uniquement les autorisations nécessaires pour accomplir un ensemble particulier de tâches, vous n'avez pas à attribuer inutilement des rôles hautement privilégiés tels que Maintainer et Owner aux utilisateurs.

### Streaming des événements d'audit au niveau de l'instance vers Google Cloud Logging {#instance-level-audit-event-streaming-to-google-cloud-logging}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11061)

{{< /details >}}

Auparavant, vous pouviez configurer uniquement le streaming des événements d'audit pour les groupes principaux vers Google Cloud Logging.

Avec GitLab 16.5, nous avons étendu la prise en charge de Google Cloud Logging aux destinations de streaming au niveau de l'instance.

### Politique de verrouillage des utilisateurs configurable {#configurable-locked-user-policy}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../security/unlock_user.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/27048)

{{< /details >}}

Les administrateurs peuvent désormais configurer une politique de verrouillage des utilisateurs pour leur instance en choisissant le nombre de tentatives de connexion infructueuses et la durée de verrouillage de l'utilisateur. Par exemple, cinq tentatives de connexion infructueuses entraîneraient le verrouillage d'un utilisateur pendant 60 minutes. Cela permet aux administrateurs de définir une politique de verrouillage des utilisateurs qui répond à leurs besoins en matière de sécurité et de conformité. Auparavant, le nombre de tentatives de connexion et la durée de verrouillage des utilisateurs n'étaient pas configurables.

### Activer et désactiver les en-têtes pour le streaming des événements d'audit {#activate-and-deactivate-headers-for-streaming-audit-events}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11109)

{{< /details >}}

Auparavant, vous deviez supprimer les en-têtes HTTP ajoutés aux destinations de streaming des événements d'audit, même si vous souhaitiez seulement les désactiver temporairement.

Avec GitLab 16.5, vous pouvez utiliser la case à cocher **Actif** dans l'interface de GitLab pour activer ou désactiver individuellement chaque en-tête. Vous pouvez l'utiliser pour :

- Tester différents en-têtes.
- Désactiver temporairement un en-tête.
- Basculer entre deux versions du même en-tête.

### API pour créer un jeton d'accès personnel pour l'utilisateur actuellement authentifié {#api-to-create-pat-for-currently-authenticated-user}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../api/users.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/425171)

{{< /details >}}

Vous pouvez désormais utiliser un nouvel endpoint d'API REST à `user/personal_access_tokens` pour créer un nouveau jeton d'accès personnel pour l'utilisateur actuellement authentifié. La portée de ce jeton est limitée à `k8s_proxy` pour des raisons de sécurité, vous pouvez donc l'utiliser uniquement pour effectuer des appels à l'API Kubernetes via l'agent pour Kubernetes. Auparavant, seuls les administrateurs d'instance pouvaient [créer des jetons d'accès personnels via l'API](../../api/users.md).

### Regroupement du rapport de vulnérabilités par statut et gravité {#vulnerability-report-grouping-by-status-and-severity}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#group-vulnerabilities) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10164)

{{< /details >}}

En tant qu'utilisateur, vous avez besoin de pouvoir regrouper les vulnérabilités afin de les trier plus efficacement. Avec cette release, vous pouvez regrouper par gravité ou par statut. Cela vous aidera à mieux répondre à des questions telles que le nombre de vulnérabilités confirmées dans un groupe ou un projet, ou le nombre de vulnérabilités qui doivent encore être triées.

### Exporter des pages wiki individuelles en PDF {#export-individual-wiki-pages-as-pdf}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/wiki/_index.md#export-a-wiki-page) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/414691)

{{< /details >}}

Depuis GitLab 16.5, vous pouvez exporter des pages wiki individuelles en fichiers PDF. Désormais, le partage des connaissances de l'équipe est encore plus fluide. L'exportation d'un wiki en PDF peut être utilisée pour diverses situations. Par exemple, pour fournir une copie de la documentation technique conservée dans un wiki ou partager des informations d'un wiki avec l'état d'avancement d'un projet. Il n'est plus nécessaire de recourir à des outils alternatifs pour convertir des fichiers Markdown en PDF, car dans certaines organisations, l'utilisation de ces outils est interdite, ce qui constitue un défi supplémentaire. Merci à JiHu pour sa contribution à cette fonctionnalité !

### Ajouter un élément enfant (tâche, objectif ou résultat clé) avec une action rapide {#add-a-child-task-objective-or-key-result-with-a-quick-action}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/quick_actions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/420797)

{{< /details >}}

Vous pouvez désormais ajouter un élément enfant pour une tâche, un objectif ou un résultat clé en utilisant l'action rapide `/add_child`.

### Widget des éléments liés dans les tâches, les objectifs et les résultats clés {#linked-items-widget-in-tasks-objectives-and-key-results}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/okrs.md#linked-items-in-okrs) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/416558)

{{< /details >}}

Avec cette release, vous pouvez lier des [tâches](../../user/tasks.md#linked-items-in-tasks) et des [OKRs](../../user/okrs.md#linked-items-in-okrs) comme « liés », « bloqués par » ou « bloquants » pour assurer la traçabilité entre les éléments de travail dépendants et connexes.

Lorsque nous migrerons les [epics](https://gitlab.com/groups/gitlab-org/-/epics/9290) et les [tickets](https://gitlab.com/groups/gitlab-org/-/epics/9584) vers le framework des éléments de travail, vous pourrez créer des liens entre tous ces types.

### Définir un parent pour une tâche, un objectif ou un résultat clé avec une action rapide {#set-a-parent-for-a-task-objective-or-key-result-with-a-quick-action}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/quick_actions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/420798)

{{< /details >}}

Vous pouvez désormais définir un élément parent pour une tâche, un objectif ou un résultat clé en utilisant l'action rapide `/set_parent`.

### Mises à jour de l'analyseur DAST {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/checks/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11426)

{{< /details >}}

Durant le jalon de la release 16.5, nous avons activé par défaut les vérifications actives suivantes pour le DAST basé sur navigateur :

- La vérification 78.1 remplace la vérification ZAP 90020 et identifie l'injection de commandes, qui peut être exploitée en exécutant des commandes OS arbitraires sur le serveur d'application cible. Il s'agit d'une vulnérabilité critique pouvant conduire à une compromission totale du système.
- La vérification 611.1 remplace la vérification ZAP 90023 et identifie l'injection d'entités XML externes (XXE), qui peut être exploitée en forçant le parseur XML d'une application à inclure des ressources externes.
- La vérification 94.4 remplace la vérification ZAP 90019 et identifie l'« injection de code côté serveur (NodeJS) », qui peut être exploitée en injectant du code JavaScript arbitraire pour être exécuté sur le serveur.
- La vérification 113.1 remplace la vérification ZAP 40003 et identifie la « neutralisation incorrecte des séquences CRLF dans les en-têtes HTTP (séparation des réponses HTTP) », qui peut être exploitée en insérant des caractères de retour chariot / saut de ligne (CRLF) pour injecter des données arbitraires dans les réponses HTTP.

### Rendre configurable la limite de débit de l'endpoint API des jobs {#make-jobs-api-endpoint-rate-limit-configurable}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/user_and_ip_rate_limits.md#maximum-authenticated-requests-to-projectidjobs-per-minute) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/395702)

{{< /details >}}

Une limite de débit pour l'endpoint d'API REST `project/:id/jobs` a été ajoutée récemment, avec une valeur par défaut de 600 requêtes par minute par utilisateur. Dans le cadre d'une itération de suivi, nous rendons cette limite configurable, permettant aux administrateurs d'instance de définir la limite qui correspond le mieux à leurs besoins.

### GitLab Runner 16.5 {#gitlab-runner-165}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.5 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et renvoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Plugin fleeting de GitLab Runner pour les instances AWS EC2 - version bêta](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29404)

#### Corrections de bugs {#bug-fixes}

- [La terminaison d'un pod k8s du gestionnaire de runner entraîne des pods worker orphelins](https://gitlab.com/gitlab-org/gitlab/-/issues/390645)
- [GitLab Runner 15.8.0 ne peut pas extraire les branches contenant des caractères spéciaux](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29606)
- [GitLab Runner extrait une image d'aide x86-64 au lieu de l'image d'aide arm64 sur un hôte de calcul arm64](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27768)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-5-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.5)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.5)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=16.5)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
