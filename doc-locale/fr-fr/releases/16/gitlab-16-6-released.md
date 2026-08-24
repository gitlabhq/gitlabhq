---
stage: Release Notes
group: Monthly Release
date: 2023-11-16
title: "Notes de release de GitLab 16.6"
description: "GitLab 16.6 publié avec GitLab Duo Chat disponible en version bêta"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 16 novembre 2023, GitLab 16.6 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Joe Snyder {#this-months-notable-contributor-joe-snyder}

Joe Snyder a reçu le titre de MVP GitLab 16.6 pour ses contributions régulières à GitLab, notamment ses récentes merge requests pour [permettre aux administrateurs de filtrer les runners par version](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135025).

Joe a été nominé par [Miguel Rincon](https://gitlab.com/mrincon), Staff Frontend Engineer chez GitLab. Miguel a salué les efforts de Joe à travers plusieurs réécritures nécessaires dues à l'évolution de l'architecture de GitLab, et a commenté la « réflexion approfondie de Joe sur la performance et l'ergonomie ».

[Pedro Pombeiro](https://gitlab.com/pedropombeiro), Sr. Backend Engineer chez GitLab, a ajouté que « Joe Snyder a conduit ce changement jusqu'à son terme après avoir pris le relais d'un ancien collègue, ce qui a nécessité d'acquérir tout le contexte autour du problème. Il s'est également montré très réactif et patient face à nos retours lors des révisions successives. »

« Travailler avec Joe a été un réel plaisir », a déclaré [Terri Chu](https://gitlab.com/terrichu), Staff Backend Engineer chez GitLab. Terri a mis en avant le travail continu de Joe sur les [modifications `emails_enabled`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899) au cours du dernier jalon (et des précédents).

Joe Snyder est Senior R&D Engineer chez [Kitware](https://www.kitware.com/) et contribue à GitLab depuis 2021. Nous remercions chaleureusement Joe pour ses contributions continues à l'amélioration de GitLab !

## Fonctionnalités principales {#primary-features}

### GitLab Duo Chat disponible en version bêta {#gitlab-duo-chat-available-in-beta}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/gitlab_duo_chat/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10550)

{{< /details >}}

Toutes les personnes impliquées dans le processus de développement logiciel peuvent passer un temps considérable à se familiariser avec le code, les epics, les tickets et les longs fils de discussion. Vous pouvez souvent vous retrouver ralenti par des tâches routinières comme la rédaction de résumés, de documentation, de tests ou même de code. Disposer d'un expert à vos côtés capable de répondre à vos questions DevSecOps sans jugement et de traiter les questions de suivi pourrait vous aider à accélérer le processus de développement logiciel.

GitLab Duo Chat vise à répondre activement à ces problèmes et à accélérer vos workflows. Ses capacités comprennent :

- Expliquer ou résumer des tickets, des epics et du code.
- Répondre à des questions spécifiques sur ces artefacts, comme « Collectez tous les arguments soulevés dans les commentaires concernant la solution proposée dans ce ticket ».
- Générer du code ou du contenu à partir des informations contenues dans ces artefacts. Par exemple, « Pouvez-vous rédiger la documentation pour ce code ? »
- Ou simplement vous aider à démarrer de zéro, comme « Créez un fichier de configuration .GitLab-ci.yml pour tester et construire une application Ruby on Rails dans un pipeline CI/CD GitLab. »
- Répondre à toutes vos questions liées à DevSecOps, que vous soyez débutant ou expert. Par exemple, « Comment puis-je configurer le test dynamique de sécurité des applications pour une API REST ? »
- Répondre aux questions de suivi afin que vous puissiez travailler de manière itérative sur tous les scénarios ci-dessus.

GitLab Duo Chat est disponible sur GitLab.com en tant que fonctionnalité en version bêta. Il est également intégré à notre Web IDE et à l'extension GitLab Workflow pour VS Code en tant que fonctionnalités expérimentales.

Vous pouvez également nous aider à faire mûrir ces fonctionnalités en nous faisant part de vos expériences avec Duo Chat, que ce soit au sein du produit ou via notre [ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).

### Revendication automatique des utilisateurs d'entreprise {#automatic-claims-of-enterprise-users}

<!-- categories: User Management -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/enterprise_user/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9675)

{{< /details >}}

Lorsque l'adresse e-mail principale d'un utilisateur GitLab.com correspond à un domaine vérifié existant, l'utilisateur est automatiquement revendiqué en tant qu'utilisateur d'entreprise. Cela donne au Owner du groupe davantage de contrôles de gestion des utilisateurs et une meilleure visibilité sur le compte de l'utilisateur. Lorsqu'un utilisateur devient un utilisateur d'entreprise, il ne peut changer son adresse e-mail principale qu'en faveur d'une adresse e-mail appartenant à son organisation, conformément à ses domaines vérifiés.

### Duplication minimale - inclure uniquement la branche par défaut {#minimal-forking---only-include-the-default-branch}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/forking_workflow.md#create-a-fork)

{{< /details >}}

Dans les versions précédentes de GitLab, lors de la duplication d'un dépôt, la duplication incluait toujours toutes les branches du dépôt. Vous pouvez désormais créer une duplication avec uniquement la branche par défaut, ce qui réduit la complexité et l'espace de stockage. Créez des duplications minimales si vous n'avez pas besoin des modifications en cours dans d'autres branches.

La méthode de duplication par défaut ne changera pas et continuera à inclure toutes les branches du dépôt. La nouvelle option indique quelle branche est la branche par défaut, afin que vous sachiez exactement quelle branche sera incluse dans la nouvelle duplication.

### Permettre aux utilisateurs d'appliquer les approbations de merge request comme politique de conformité {#allow-users-to-enforce-mr-approvals-as-a-compliance-policy}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#any_merge_request-rule-type) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9696)

{{< /details >}}

Le contrôle des modifications de code susceptibles d'affecter les applications en production et d'exposer les entreprises à des risques de conformité et à des vulnérabilités de sécurité est de plus en plus strict. Grâce aux politiques de résultats de scan, vous pouvez garantir qu'aucune modification unilatérale ne peut être effectuée en imposant une approbation par deux personnes sur toutes les merge requests.

Les politiques de résultats de scan disposent d'une nouvelle option pour cibler `Any merge request`, qui peut être associée à la définition d'[approbateurs basés sur les rôles](../../user/application_security/policies/merge_request_approval_policies.md#require_approval-action-type) afin de s'assurer que chaque merge request pour les branches définies requiert l'approbation de deux (ou plusieurs) utilisateurs avec un rôle donné (Owner, Maintainer ou Developer).

Disponible dans SaaS à partir de la version 16.6. Disponible pour les instances Self-managed derrière le feature flag `scan_result_any_merge_request` et sera activé par défaut dans la version 16.7.

### Le portail Switchboard pour GitLab Dedicated est désormais en disponibilité générale {#switchboard-portal-for-gitlab-dedicated-is-now-generally-available}

<!-- categories: Switchboard, GitLab Dedicated -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/dedicated/_index.md) \| [Ticket associé](https://about.gitlab.com/dedicated/)

{{< /details >}}

Switchboard, un nouveau portail en libre-service, est désormais disponible pour que les clients et les membres de l'équipe puissent intégrer, configurer et maintenir leurs instances [GitLab Dedicated](https://about.gitlab.com/dedicated/).

Grâce à Switchboard, vous pouvez désormais effectuer certaines [modifications de configuration](../../administration/dedicated/_index.md) sur votre instance GitLab Dedicated. Cette fonctionnalité sera étendue dans les prochaines releases.

### Release bêta des composants CI/CD {#cicd-components-beta-release}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/components/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/9897)

{{< /details >}}

Dans GitLab 16.1, nous avons [annoncé](https://about.gitlab.com/blog/introducing-ci-components/) la publication d'une fonctionnalité expérimentale passionnante appelée composants CI/CD. Le composant est un élément constitutif du pipeline qui peut être répertorié dans le futur catalogue CI/CD.

Nous sommes ravis d'annoncer aujourd'hui la disponibilité en version bêta des composants CI/CD. Avec cette release, nous avons également amélioré la structure des dossiers des composants par rapport à la version expérimentale initiale. Si vous testez déjà la version expérimentale des composants CI/CD, il est indispensable de migrer vers la [nouvelle structure de dossiers](../../ci/components/_index.md#directory-structure). Vous pouvez consulter quelques exemples [ici](https://gitlab.com/gitlab-components/). L'ancienne structure de dossiers est dépréciée et nous prévoyons de la supprimer dans les prochaines releases.

Si vous essayez les composants CI/CD, vous êtes également invité à tester le nouveau catalogue CI/CD, actuellement disponible en tant que fonctionnalité expérimentale. Vous pouvez rechercher dans le [catalogue CI/CD global](../../ci/components/_index.md) des composants créés et publiés par d'autres utilisateurs pour un usage public. De plus, si vous créez vos propres composants, vous pouvez choisir de les publier également dans le catalogue !

### Interface améliorée pour la gestion des variables CI/CD {#improved-ui-for-cicd-variable-management}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/418005)

{{< /details >}}

Les variables CI/CD sont un élément fondamental de GitLab CI/CD, et nous avons estimé que nous pouvions offrir une meilleure expérience pour travailler avec les variables depuis l'interface des paramètres. Dans cette release, nous avons donc mis à jour l'interface pour utiliser un nouveau panneau latéral qui améliore le flux d'ajout et de modification des variables CI/CD.

Par exemple, la validation du masquage n'intervenait auparavant que lorsque vous tentiez d'enregistrer la variable CI/CD, et en cas d'échec, vous deviez tout recommencer depuis le début. Mais désormais, avec le nouveau panneau latéral, vous bénéficiez d'une validation en temps réel qui vous permet d'effectuer des ajustements à la volée sans avoir à tout refaire !

Vos [retours sur ce changement](https://gitlab.com/gitlab-org/gitlab/-/issues/428807) sont toujours appréciés et valorisés.

### Tableau de bord de la flotte de runners - Métriques de démarrage (version bêta) {#runner-fleet-dashboard---starter-metrics-beta}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/runners/runner_fleet_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/424495)

{{< /details >}}

Les opérateurs de flottes de runners Self-managed ont besoin d'observabilité et de la capacité à répondre rapidement aux questions critiques concernant l'infrastructure de leur flotte de runners d'un seul coup d'œil. Désormais, avec le tableau de bord de la flotte de runners - Vue administrateur (version bêta), vous disposez d'informations exploitables pour répondre rapidement aux questions critiques de gestion de la flotte et d'expérience des développeurs, en commençant par les runners d'instance. Ces informations comprennent les réponses à des questions telles que : quels runners présentent des erreurs, les performances des files d'attente des runners pour l'exécution des jobs CI, et quels runners sont les plus utilisés. Les clients GitLab Ultimate peuvent activer cette fonctionnalité de manière indépendante, mais sont encouragés à participer au [programme des premiers adoptants](https://gitlab.com/groups/gitlab-org/-/epics/11180).

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Masquer les projets archivés dans les résultats de recherche par défaut {#hide-archived-projects-in-search-results-by-default}

<!-- categories: Global Search -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/_index.md#include-archived-projects-in-search-results) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10957)

{{< /details >}}

Auparavant, les utilisateurs voyaient de nombreux projets archivés dans leurs résultats de recherche de projets. Cela posait problème, notamment lorsque les projets archivés occupaient la plupart des premiers résultats. Nous filtrons désormais les projets archivés par défaut, et les utilisateurs peuvent sélectionner **Inclure les éléments archivés** pour voir tous les projets.

### Les noms des groupes privés sont masqués pour les utilisateurs non autorisés {#private-group-names-are-hidden-from-unauthorized-users}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/manage.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415165)

{{< /details >}}

Auparavant, les noms des groupes privés étaient visibles par tous les utilisateurs lors de l'accès à l'onglet **Groupes** de la page des membres d'un projet ou d'un groupe. Pour renforcer la sécurité, nous masquons désormais le nom et la source des groupes privés pour les utilisateurs qui ne sont pas membres du groupe partagé, du projet partagé ou du groupe invité. Ces informations seront désormais affichées comme **Privé**.

### Liste exhaustive des éléments dont l'importation a échoué {#comprehensive-list-of-items-that-failed-to-be-imported}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/386138)

{{< /details >}}

Auparavant, lorsque la migration de projets et de groupes GitLab par transfert direct était terminée et que certains éléments (tels que des merge requests ou des tickets) n'avaient pas été importés avec succès, vous pouviez sélectionner le bouton **Détails** sur la [page listant les groupes et projets importés](../../user/group/import/_index.md) et consulter les erreurs associées.

Cependant, une liste d'erreurs ne permet pas de comprendre combien d'éléments au total, ni lesquels en particulier, n'ont pas été importés. Disposer de ces informations est essentiel pour comprendre les résultats du processus d'importation.

Dans cette release, nous avons remplacé le bouton **Détails** par un lien **See failures**. En sélectionnant le lien **See failures**, vous accédez à une nouvelle page répertoriant tous les éléments dont l'importation a échoué pour un groupe ou un projet donné. Pour chaque élément qui n'a pas été importé, vous pouvez voir :

- Le type de l'élément. Par exemple, une merge request ou un ticket.
- Le type d'erreur survenue.
- L'ID de corrélation, utile à des fins de débogage.
- L'URL de l'élément sur l'instance source, si disponible (éléments avec `iid`).
- Le titre de l'élément sur l'instance source, s'il est disponible. Par exemple, le titre de la merge request ou le titre du ticket.

### Expérience de navigation cohérente pour tous les utilisateurs {#consistent-navigation-experience-for-all-users}

<!-- categories: Navigation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

La release 16.0 a introduit une nouvelle expérience de navigation, qui est devenue la valeur par défaut pour tous les utilisateurs le 2 juin 2023. Au cours des jalons suivants, de nombreuses améliorations ont été apportées sur la base d'une abondance de retours utilisateurs. La possibilité de revenir à l'ancienne navigation a désormais été supprimée. D'autres changements passionnants sont prévus pour la navigation, mais pour l'instant, tous les utilisateurs bénéficient d'une expérience de navigation cohérente.

Pour récapituler, avec la nouvelle navigation GitLab, vous pouvez :

- Épingler des éléments de menu pour enregistrer vos éléments de projet ou de groupe les plus utilisés en haut
- Masquer la navigation et l'afficher en « aperçu » pour disposer d'un écran plus large
- Rechercher facilement des éléments de menu à l'aide de raccourcis clavier
- Continuer à utiliser tous les thèmes disponibles avec la navigation précédente
- Utiliser des sections mieux organisées qui s'alignent sur un workflow DevOps

### Mode silencieux GitLab {#gitlab-silent-mode}

<!-- categories: Disaster Recovery -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/silent_mode/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9826)

{{< /details >}}

Lorsque le mode silencieux GitLab est activé, il bloque tout le trafic sortant majeur, notamment les e-mails de notification, les intégrations, les webhooks et la mise en miroir depuis une instance GitLab. Cela vous permet d'effectuer des tests sur un site GitLab sans générer de trafic vers les utilisateurs et d'autres intégrations. Vous pouvez utiliser le mode silencieux pour tester une sauvegarde restaurée ou un site Geo DR promu sans impacter votre site GitLab principal ni vos utilisateurs finaux.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Mises à jour du statut Kubernetes en temps réel dans l'interface GitLab {#real-time-kubernetes-status-updates-in-the-gitlab-ui}

<!-- categories: Deployment Management, Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/422945)

{{< /details >}}

Dans GitLab 16.6, vous pouvez utiliser l'intégration de l'interface du cluster sur votre page d'environnement pour déterminer le statut des applications en cours d'exécution sans quitter GitLab. Auparavant, le statut était mis à jour par une requête unique au chargement de l'interface, ce qui rendait le suivi de la progression du déploiement difficile à gérer. La version actuelle de GitLab améliore la connexion sous-jacente pour utiliser l'API Kubernetes watch pour la réconciliation Flux et les statuts des pods, et fournit des mises à jour quasi en temps réel de l'état du cluster dans l'interface GitLab.

### Connexion aux clusters Kubernetes avec la CLI GitLab {#connect-to-kubernetes-clusters-with-the-gitlab-cli}

<!-- categories: GitLab CLI, Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/user_access.md#access-a-cluster-with-the-kubernetes-api) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11455)

{{< /details >}}

À partir de GitLab version 16.4, vous pouvez vous connecter à un cluster Kubernetes depuis un terminal local en utilisant l'agent pour Kubernetes et un jeton d'accès personnel. Dans la version initiale, la configuration du cluster local nécessitait plusieurs commandes et un jeton d'accès à longue durée de vie. Au cours du mois écoulé, nous avons travaillé à rationaliser et à améliorer la sécurité du processus de configuration en étendant la CLI GitLab.

La CLI GitLab peut désormais lister les connexions d'agents disponibles depuis un répertoire de checkout d'un projet GitLab ou depuis le projet spécifié. Vous pouvez configurer la connexion via un agent sélectionné avec une commande dédiée. Lorsque `kubectl` ou tout autre outil doit s'authentifier auprès du cluster, la CLI GitLab génère un jeton temporaire et restreint pour l'utilisateur connecté.

### Permettre aux équipes de conformité d'empêcher les push et les push forcés vers les branches protégées {#allow-compliance-teams-to-prevent-pushing-and-force-pushing-into-protected-branches}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9706)

{{< /details >}}

L'un des plusieurs nouveaux paramètres ajoutés aux politiques de résultats de scan pour faciliter l'[application des politiques de sécurité en matière de conformité](https://gitlab.com/groups/gitlab-org/-/epics/9704), ce contrôle limitera la capacité à exploiter les paramètres au niveau du projet pour contourner les politiques.

Pour chaque politique de résultats de scan existante ou nouvelle, vous pouvez activer `Prevent pushing and force pushing` pour qu'elle prenne effet sur les branches définies dans la politique afin d'empêcher les utilisateurs de contourner le flux de merge request pour pousser des modifications directement vers une branche.

Disponible dans SaaS à partir de la version 16.6. Disponible pour les instances Self-managed derrière le feature flag `scan_result_policies_block_force_push` et sera activé par défaut dans la version 16.7.

### Streaming d'événements d'audit au niveau du groupe vers AWS S3 {#group-level-audit-event-streaming-to-aws-s3}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

En nous appuyant sur nos intégrations avec des outils de journalisation externes ou d'agrégation de données, vous pouvez désormais sélectionner AWS S3 comme destination pour les flux d'événements d'audit des groupes principaux. Cette fonctionnalité fournit des informations pertinentes pour une intégration plus facile et sans accroc.

Auparavant, vous deviez utiliser des en-têtes HTTP personnalisés pour tenter de créer une requête qu'AWS S3 accepterait. Cette méthode était sujette aux erreurs et pouvait être difficile à déboguer.

### Amélioration de la gestion des vérifications de statut externes non réactives {#improved-handling-of-unresponsive-external-status-checks}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/status_checks.md#status-checks-widget)

{{< /details >}}

Auparavant, les vérifications de statut externes sur les merge requests continuaient à interroger l'URL externe jusqu'à recevoir une réponse de succès ou d'échec. Cela pouvait entraîner un blocage apparent de certaines vérifications de statut dans un état non réactif.

Désormais, un délai d'expiration de 2 minutes a été intégré afin que vous puissiez relancer manuellement la vérification de statut après 2 minutes si vous n'obtenez aucune réponse du système externe.

### Modifications du filtre Outil du rapport de vulnérabilités {#changes-to-the-vulnerability-reports-tool-filter}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11237)

{{< /details >}}

Auparavant, le rapport de vulnérabilités vous permettait de filtrer par une liste statique de types d'outils pris en charge par GitLab, suivie d'une liste dynamique de scanners personnalisés. Avec cette release, vous pouvez désormais sélectionner le type d'outil regroupé par analyseur.

### Les comptes de service ont des dates d'expiration facultatives {#service-accounts-have-optional-expiry-dates}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/personal_access_tokens.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/421420)

{{< /details >}}

Les administrateurs GitLab et les Owners de groupe peuvent choisir s'ils souhaitent imposer une date d'expiration pour les comptes de service. Auparavant, les jetons de compte de service devaient expirer dans un délai d'un an, conformément aux limites d'expiration des jetons d'accès personnels, de projet et de groupe. Cela permet aux administrateurs et aux Owners de groupe de choisir l'équilibre entre sécurité et facilité d'utilisation qui correspond le mieux à leurs objectifs.

### Empêcher les paquets NuGet en double {#prevent-duplicate-nuget-packages}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/nuget_repository/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/293748)

{{< /details >}}

Vous pouvez utiliser le registre de paquets GitLab pour publier et télécharger les paquets NuGet de votre projet. Par défaut, vous pouvez publier le même nom et la même version de paquet plusieurs fois.

Cependant, vous pourriez vouloir empêcher les téléchargements en double, notamment pour les releases. Dans cette release, GitLab a étendu le paramètre de groupe pour le registre de paquets afin de vous permettre d'autoriser ou de refuser les téléchargements de paquets en double.

Vous pouvez ajuster ce paramètre avec l'[API GitLab](../../api/graphql/reference/_index.md#packagesettings) ou depuis l'interface.

### Charger des paquets dans le dépôt Maven avec l'authentification HTTP de base {#upload-packages-to-the-maven-repository-with-basic-http-authentication}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/packages/maven_repository/_index.md#basic-http-authentication) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/277385)

{{< /details >}}

Le registre de paquets GitLab prend désormais en charge le chargement de paquets Maven avec l'authentification HTTP de base. Auparavant, vous pouviez utiliser l'authentification HTTP de base uniquement pour télécharger des paquets Maven. Cette incohérence rendait difficile pour les développeurs la configuration et la maintenance de l'authentification pour leur projet.

La publication d'artefacts avec `sbt` n'est pas prise en charge, mais le [ticket 408479](https://gitlab.com/gitlab-org/gitlab/-/issues/408479) propose l'ajout de cette fonctionnalité.

### Container Scanning : exclure les résultats qui ne seront pas corrigés {#container-scanning-exclude-findings-which-wont-be-fixed}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/container_scanning/_index.md#available-cicd-variables) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/6846)

{{< /details >}}

Les résultats du scan de conteneurs peuvent inclure des findings que le fournisseur a évalués et décidé de ne pas corriger. Pour vous permettre de vous concentrer sur les findings exploitables, vous pouvez désormais exclure ces findings. Pour les options de configuration, veuillez consulter la documentation GitLab.

### Inclure les vecteurs CVSS dans l'export du rapport de vulnérabilités {#include-cvss-vectors-in-the-vulnerability-report-export}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11213)

{{< /details >}}

Lorsque vous exportez des informations depuis le rapport de vulnérabilités, les informations sur les vecteurs CVSS sont désormais incluses. Ces données supplémentaires vous aident à analyser et à trier les vulnérabilités en dehors de GitLab.

### Ajout de la prise en charge des projets SBT utilisant Java 21 {#added-support-for-sbt-projects-using-java-21}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/421174)

{{< /details >}}

L'analyse des dépendances et le scan de licences prennent désormais en charge les projets SBT utilisant Java 21.

### Mises à jour de l'analyseur DAST {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/checks/_index.md#active-checks)

{{< /details >}}

Au cours du jalon de release 16.6, nous avons activé par défaut les vérifications actives suivantes pour le DAST basé sur le navigateur :

- La vérification 94.1 remplace la vérification ZAP 90019 et identifie l'injection de code côté serveur (PHP).
- La vérification 94.2 remplace la vérification ZAP 90019 et identifie l'injection de code côté serveur (Ruby).
- La vérification 94.3 remplace la vérification ZAP 90019 et identifie l'injection de code côté serveur (Python).
- La vérification 943.1 remplace la vérification ZAP 40033 et identifie la neutralisation incorrecte d'éléments spéciaux dans la logique des requêtes de données.
- La vérification 74.1 remplace la vérification ZAP 90017 et identifie l'injection XSLT.

### Prise en charge de macOS 14 (Sonoma) et des images Xcode 15 {#macos-14-sonoma-and-xcode-15-image-support}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/macos.md#supported-macos-images) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/431424)

{{< /details >}}

Les équipes peuvent désormais créer, tester et déployer facilement des applications pour l'écosystème Apple sur macOS 14 et Xcode 15.

Les runners SaaS sur macOS vous permettent d'accroître la vélocité de vos équipes de développement dans la création et le déploiement d'applications nécessitant macOS, dans un environnement de build GitLab Runner sécurisé et à la demande, intégré à GitLab CI/CD.

Essayez-le dès aujourd'hui en utilisant `macos-14-xcode-15` comme image dans votre fichier .GitLab-ci.yml.

### GitLab Runner 16.6 {#gitlab-runner-166}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.6 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et renvoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Plugin Fleeting de GitLab Runner pour GCP Compute Engine - version bêta](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29409)
- [Implémenter un arrêt gracieux pour l'exécuteur Docker](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6359)
- [Créer dynamiquement des volumes PVC avec des classes de stockage pour Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27835)
- [Remplacer le point d'entrée du conteneur via `image.entrypoint` dans l'exécuteur Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30713)

#### Corrections de bugs {#bug-fixes}

- [Les pods continuent de redémarrer avec une erreur d'échec de la sonde de vivacité après la mise à niveau vers GitLab Runner 16.5.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36959)
- [Terminal de débogage - la variable contient le contenu du fichier au lieu du chemin du fichier](https://gitlab.com/gitlab-org/gitlab/-/issues/399770)
- [Les pods d'exécution de jobs dans Kubernetes ne gèrent pas les signaux](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28162)
- [Les services dans l'exécuteur Docker de GitLab Runner utilisant Podman ne démarrent pas](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29480)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-6-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.6)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.6)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=16.6)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
