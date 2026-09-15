---
stage: Release Notes
group: Monthly Release
date: 2025-11-20
title: "Notes de release de GitLab 18.6"
description: "GitLab 18.6 publié avec la nouvelle interface GitLab : conçue pour la productivité"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 20 novembre 2025, GitLab 18.6 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Samaksh Agarwal {#this-months-notable-contributor-samaksh-agarwal}

Chaque développeur utilisant le GitLab Development Kit (GDK) bénéficie de la [contribution de Samaksh à l'amélioration de la lisibilité de `gdk status`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/5227). Bien que cette amélioration puisse sembler simple en apparence, elle témoigne d'une attention exceptionnelle portée à l'expérience développeur et d'une compréhension de la façon dont de petites améliorations peuvent avoir un impact considérable.

La lisibilité améliorée de `gdk status` fait gagner du temps à chaque développeur utilisant GDK et augmente considérablement l'accessibilité de l'un des éléments centraux de l'environnement de développement. Ce type de contribution témoigne d'une maturité dans la compréhension de la façon d'apporter des améliorations significatives au workflow de développement.

En réfléchissant à ses contributions, Samaksh partage : « Le GitLab Development Kit (ou GDK) est mon choix de contributions actives pour le moment, car j'aime personnellement travailler sur ce qui facilite et améliore l'expérience des autres contributeurs. Et c'est le genre de développeur que je veux être. Celui qui peut mettre ses compétences au service des autres pour leur simplifier la vie. »

Interrogé sur son expérience de contribution à GitLab, Samaksh note : « Je recommande GitLab à tous ceux qui souhaitent découvrir une expérience open source nouvelle et de qualité. Lorsque j'ai commencé à contribuer à GitLab, j'étais un peu dépassé, mais toute la communauté était si solidaire, serviable et accueillante que cela s'est dissipé rapidement. Je suis absolument amoureux de cette communauté et de sa façon de faire les choses. De la rédaction d'une excellente documentation au maintien d'une qualité de code optimale, en passant par la reconnaissance sincère de ses contributeurs, la communauté GitLab est absolument merveilleuse. »

## Fonctionnalités principales {#primary-features}

### La nouvelle interface GitLab : conçue pour la productivité {#the-new-gitlab-ui-designed-for-productivity}

<!-- categories: Design Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../tutorials/gitlab_navigation.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17279)

{{< /details >}}

Découvrez une interface GitLab plus intelligente et plus intuitive, qui place la productivité des développeurs au premier plan.

La nouvelle conception côte à côte utilise des panneaux contextuels pour vous maintenir dans votre workflow, réduisant les clics inutiles et aidant les équipes à travailler plus rapidement. Personnalisez votre workspace, optimisez l'espace écran et profitez d'une expérience plus épurée et plus dynamique qui s'adapte à votre workflow.

GitLab s'engage en faveur de l'amélioration continue. Partagez donc vos commentaires dans le [ticket de retour d'information](https://gitlab.com/gitlab-org/gitlab/-/issues/577554) et contribuez à façonner l'avenir de GitLab.

### Recherche exacte de code en disponibilité limitée {#exact-code-search-in-limited-availability}

<!-- categories: Global Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/exact_code_search.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17918)

{{< /details >}}

Avec cette release, la recherche exacte de code est désormais en disponibilité limitée. Vous pouvez utiliser les modes correspondance exacte et expression régulière pour rechercher du code sur l'ensemble d'une instance, dans un groupe ou dans un projet. La recherche exacte de code repose sur le moteur de recherche open source Zoekt.

Pour GitLab.com, la recherche exacte de code est activée par défaut. Pour GitLab Self-Managed, un administrateur doit [installer Zoekt](../../integration/zoekt/_index.md#install-zoekt) et [activer la recherche exacte de code](../../integration/zoekt/_index.md#enable-exact-code-search).

Cette fonctionnalité est en cours de développement actif. Nous vous invitons à nous faire part de vos commentaires dans le [ticket 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920) !

### Les composants CI/CD peuvent référencer leurs propres métadonnées {#cicd-components-can-reference-their-own-metadata}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/yaml/expressions.md#component-context) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438275)

{{< /details >}}

Auparavant, les composants CI/CD ne pouvaient pas référencer leurs propres métadonnées, telles que les numéros de version ou les SHAs de commit, dans leur configuration. Ce manque d'informations pouvait vous amener à utiliser des configurations avec des valeurs codées en dur ou des solutions de contournement complexes. Écrire la configuration de cette façon peut entraîner des incohérences de version lorsque les composants génèrent des ressources telles que des images Docker, car il n'existe aucun moyen d'étiqueter automatiquement ces ressources avec la version compatible du composant.

Dans cette release, nous avons introduit la possibilité d'accéder au contexte d'un composant grâce au mot-clé `spec:component`. Vous pouvez désormais générer et publier des ressources versionnées telles que des images Docker lors de la publication d'une version de composant, garantissant ainsi la synchronisation de l'ensemble, l'élimination de la gestion manuelle des versions et la prévention des incohérences de version.

### Prise en charge des dépendances de job dynamiques dans `needs:[parallel:matrix](../../ci/yaml.md#parallelmatrix)` {#support-dynamic-job-dependencies-in-needsparallelmatrixciyamlmdparallelmatrix}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/yaml/matrix_expressions.md#matrix-expressions-in-needsparallelmatrix) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/423553)

{{< /details >}}

[`parallel:matrix`](../../ci/yaml/_index.md#parallelmatrix) permet d'exécuter facilement plusieurs jobs en parallèle avec des exigences différentes, par exemple pour tester du code sur plusieurs plateformes en même temps. Mais si vous souhaitiez que des jobs ultérieurs utilisent `needs:parallel:matrix` pour dépendre de jobs parallèles spécifiques, la configuration était complexe et peu flexible.

Désormais, grâce à la nouvelle expression `$[[matrix.VARIABLE]]` introduite en tant que fonctionnalité version bêta, les utilisateurs peuvent créer des dépendances dynamiques 1-1, ce qui facilite considérablement la gestion des configurations `parallel:matrix` complexes. Cela peut vous aider à créer des pipelines plus rapides, avec une gestion efficace des artefacts, une meilleure évolutivité et une configuration plus claire. Cette fonctionnalité est particulièrement utile pour les builds multi-plateformes, les déploiements Terraform dans plusieurs environnements et tout workflow nécessitant un traitement parallèle sur plusieurs dimensions.

### L'agent Security Analyst de GitLab disponible en tant qu'agent par défaut {#gitlab-security-analyst-agent-available-as-a-foundational-agent}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

L'agent Security Analyst de GitLab est désormais un agent par défaut dans GitLab Duo Agentic Chat. Cela signifie que les utilisateurs n'ont plus à ajouter manuellement l'agent Security Analyst de GitLab depuis le catalogue d'IA, et que cet agent est également disponible par défaut pour GitLab Self-Managed et GitLab Dedicated. Cet assistant spécialisé fournit une gestion des vulnérabilités et une analyse de sécurité natives à l'IA, vous aidant à analyser les résultats, à trier les vulnérabilités et à gérer les exigences de conformité sans aucune configuration.

Cette fonctionnalité est en version bêta, et nous vous invitons à partager vos retours dans le [ticket 576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916).

### Sélection de modèle pour GitLab Duo Agentic Chat dans VS Code et les IDE JetBrains {#model-selection-for-gitlab-duo-agentic-chat-in-vs-code-and-jetbrains-ides}

<!-- categories: Editor Extensions, Model Personalization -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19345)

{{< /details >}}

Choisissez facilement votre modèle d'IA préféré directement dans GitLab Duo Chat, désormais disponible dans VS Code et les IDE JetBrains. Utilisez la liste déroulante dans le panneau GitLab Duo Chat pour choisir parmi Claude, GPT et d'autres modèles pris en charge. La disponibilité des modèles est gérée par les administrateurs de votre organisation, garantissant ainsi votre accès aux modèles adaptés à votre workflow.

### Mise à niveau du tableau de bord de sécurité (version bêta sur GitLab.com) {#security-dashboard-upgrade-beta-on-gitlabcom}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com
- Liens : [Documentation](../../user/application_security/security_dashboard/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18509)

{{< /details >}}

Les nouveaux tableaux de bord de sécurité ont été mis à jour et modernisés. Les fonctionnalités initiales de la version bêta comprennent :

- Un graphique des vulnérabilités dans le temps qui prend en charge :
  - Le filtrage par projet ou par type de rapport.
  - Le regroupement par type de rapport et par gravité.
  - Des liens directs vers les vulnérabilités dans le rapport de vulnérabilité.
- Un module de score de risque qui calcule le risque estimé pour un groupe ou un projet selon un algorithme GitLab.

Les nouveaux tableaux de bord de sécurité publiés dans la version 18.6 sont actuellement disponibles sur GitLab.com uniquement.

## Agentic Core {#agentic-core}

### Serveur GitLab MCP disponible en [version bêta](../../policy/development_stages_support.md#beta) {#gitlab-mcp-server-available-in-beta}

<!-- categories: MCP Server -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo/model_context_protocol/mcp_server.md)

{{< /details >}}

Le serveur GitLab MCP est disponible en [version bêta](../../policy/development_stages_support.md#beta). Grâce au serveur GitLab MCP, vous pouvez utiliser des assistants IA tels que Claude Code, Cursor et d'autres outils compatibles MCP pour interagir avec vos projets, tickets, merge requests et pipelines GitLab, sans avoir à créer d'intégrations personnalisées pour chaque outil.

Pour commencer, [activez les fonctionnalités bêta et expérimentales](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) dans vos paramètres GitLab Duo.

Le serveur GitLab MCP fournit des outils essentiels couvrant les tickets, les merge requests et les pipelines, et nous continuons à l'affiner en fonction des retours des utilisateurs. Cette fonctionnalité peut présenter des fonctionnalités incomplètes ou des bugs. Essayez-la et partagez vos commentaires dans le [ticket 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

### Recherche avancée disponible pour les descriptions et les commentaires des tickets {#advanced-search-available-for-both-issue-descriptions-and-comments}

<!-- categories: Global Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/search/advanced_search.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/513146)

{{< /details >}}

La recherche avancée renvoie désormais des résultats correspondants à la fois dans les descriptions et les commentaires des tickets. Auparavant, les utilisateurs devaient rechercher séparément dans les descriptions et les commentaires des tickets. Cette amélioration offre un workflow de recherche plus rationalisé et plus complet pour les tickets GitLab.

### Le modèle Gemini 2.5 Flash compatible avec GitLab Duo Agent Platform pour [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) {#gemini-25-flash-model-compatible-with-gitlab-duo-agent-platform-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/572353)

{{< /details >}}

Vous pouvez désormais utiliser le modèle Gemini 2.5 Flash sur GitLab Duo Agent Platform avec GitLab Duo Self-Hosted.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Limite de débit pour le listage des membres de projets et de groupes {#rate-limit-for-listing-project-and-group-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../administration/settings/rate_limit_on_projects_api.md#configure-rate-limits-on-listing-project-members) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/580116)

{{< /details >}}

Nous avons introduit une limite de débit pour les endpoints `/api/v4/projects/:id/members/all` et `/api/v4/groups/:id/members/all` afin d'améliorer la stabilité de l'API et de garantir une utilisation équitable des ressources pour tous les utilisateurs. Les endpoints `GET /api/v4/projects/:id/members/all` et `GET /api/v4/groups/:id/members/all` ont désormais une limite de débit de 200 requêtes par minute par utilisateur.

Cette modification contribue à protéger les instances GitLab contre une utilisation excessive de l'API susceptible d'affecter les performances pour tous les utilisateurs. La limite de 200 requêtes par minute offre une capacité suffisante pour les schémas d'utilisation normaux, tout en prévenant les abus potentiels ou l'épuisement involontaire des ressources. Si vos intégrations ou scripts utilisent cet endpoint, assurez-vous qu'ils gèrent correctement les réponses de limite de débit (HTTP 429) et implémentez une logique de nouvelle tentative avec délai d'attente si nécessaire. La plupart des utilisateurs ne devraient pas être affectés par cette modification dans le cadre d'une utilisation normale.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Couverture accrue des règles pour la protection contre les push de secrets et la détection des secrets dans les pipelines {#increased-rule-coverage-for-secret-push-protection-and-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/secret_detection/detected_secrets.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/576279)

{{< /details >}}

Nous avons ajouté la prise en charge de 40 nouvelles règles pour la détection des secrets dans les pipelines de GitLab. Certaines règles existantes ont également été mises à jour pour améliorer la qualité et réduire les faux positifs. Ces modifications sont publiées dans la [version 7.20.1](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.20.1) de l'analyseur de secrets.

### Les propriétaires du code prennent désormais en charge les appartenances de groupe héritées {#code-owners-now-supports-inherited-group-memberships}

<!-- categories: Code Review Workflow, Source Code Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/codeowners/advanced.md#group-inheritance-and-eligibility)

{{< /details >}}

La propriété du code est essentielle pour maintenir la qualité du code et s'assurer que les bonnes personnes passent en revue les modifications apportées aux parties sensibles de votre base de code. Cependant, la gestion des propriétaires du code dans les organisations dotées de structures de groupe complexes a toujours été difficile. Auparavant, pour référencer un groupe dans votre fichier `CODEOWNERS`, ce groupe devait être directement invité dans chaque projet spécifique, même s'il était déjà membre d'un groupe parent.

Les propriétaires du code prennent désormais en charge les groupes avec appartenances héritées en tant qu'approbateurs éligibles :

- Les groupes bénéficiant d'un accès hérité via l'appartenance à un groupe parent sont reconnus comme propriétaires du code valides lorsque les approbations des propriétaires du code sont activées.
- Plus besoin d'inviter des groupes directement dans chaque projet.
- Les fichiers `CODEOWNERS` existants continuent de fonctionner sans modification.
- Même niveau de contrôle sur les personnes pouvant approuver les modifications apportées aux chemins de code critiques.

Cette modification réduit la charge administrative tout en maintenant les exigences de sécurité et d'approbation assurées par les propriétaires du code.

### Activer ou désactiver la visibilité des brouillons de merge requests sur votre page d'accueil {#toggle-draft-merge-request-visibility-on-your-homepage}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/merge_requests/homepage.md#set-your-display-preferences) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/551475)

{{< /details >}}

Sur votre page d'accueil, les brouillons de merge requests peuvent encombrer votre vue des merge requests et vous distraire des travaux prêts à être traités. Auparavant, il n'était pas possible de les filtrer.

Vous pouvez désormais masquer les brouillons de merge requests dans la section **Vos requêtes de fusion** de votre page d'accueil grâce aux préférences d'affichage. Lorsque vous masquez les brouillons de merge requests :

- Ils sont exclus du compteur actif.
- Un pied de page affiche le nombre de brouillons de merge requests filtrés.
- Vos préférences sont enregistrées automatiquement.

Cette modification vous aide à vous concentrer sur les merge requests nécessitant une attention immédiate.

### Nouvelles fonctionnalités et améliorations de la CLI GitLab {#new-gitlab-cli-features-and-improvements}

<!-- categories: GitLab CLI -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](https://docs.gitlab.com/cli/) \| [Ticket associé](https://gitlab.com/gitlab-org/cli/-/releases)

{{< /details >}}

La CLI GitLab (glab) offre de nouvelles fonctionnalités et améliorations pour améliorer votre workflow GitLab depuis la ligne de commande :

- **Enhanced authentication** : détection automatique des URL GitLab depuis les remotes git lors de la connexion, facilitant l'authentification auprès de l'instance GitLab appropriée.
- **Flexible pipeline monitoring** : affichez n'importe quel pipeline par ID avec la commande `ci-view`.
- **GPG key management** : gérez les clés GPG directement depuis la CLI avec de nouvelles commandes.
- **Project member management** : ajoutez, supprimez et mettez à jour les membres du projet depuis la ligne de commande.
- **Improved Git integration** : plugin git-credential amélioré avec prise en charge de tous les types de jetons.
- **Modern user interface** : bibliothèque de prompts mise à jour pour de meilleures boîtes de dialogue de confirmation et un thème GitLab cohérent sur tous les composants de l'interface utilisateur.

Pour obtenir la liste complète des modifications et mises à jour, consultez les [releases CLI](https://gitlab.com/gitlab-org/cli/-/releases). Pour commencer à utiliser la CLI GitLab ou mettre à jour vers la dernière version, consultez le [guide d'installation](https://gitlab.com/gitlab-org/cli/#installation).

### Notifications webhook pour les nouvelles demandes de révision de merge requests {#webhook-notifications-for-merge-request-review-re-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/integrations/webhook_events.md#re-request-review-events)

{{< /details >}}

Les intégrations webhook sont essentielles pour automatiser les workflows et maintenir la synchronisation des systèmes externes avec les activités des merge requests GitLab. Cependant, lorsque des relecteurs étaient sollicités à nouveau pour des merge requests, les consommateurs de webhook n'avaient aucun moyen d'identifier quel relecteur spécifique était de nouveau sollicité, ce qui rendait difficile le déclenchement de notifications ou d'automatisations appropriées.

Les charges utiles des webhooks pour les merge requests incluent désormais un attribut `re_requested` dans les données des relecteurs qui indique clairement quel relecteur a été de nouveau sollicité :

- Défini sur `true` pour le relecteur spécifique faisant l'objet d'une nouvelle demande.
- Défini sur `false` pour tous les autres relecteurs.

Cette amélioration permet une automatisation plus précise autour du processus de révision des merge requests. Les consommateurs de webhook peuvent envoyer des notifications ciblées, mettre à jour des systèmes de suivi externes et déclencher des workflows appropriés lorsque des révisions sont de nouveau demandées.

### Prise en charge du Web IDE pour les environnements GitLab Self-Managed hors ligne {#web-ide-support-for-offline-gitlab-self-managed-environments}

<!-- categories: Web IDE, Editor Extensions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/web_ide.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/15146)

{{< /details >}}

Les administrateurs GitLab Self-Managed dans des environnements réseau hors ligne ou strictement contrôlés peuvent désormais configurer un domaine hôte d'extension Web IDE personnalisé, permettant ainsi le plein fonctionnement du Web IDE sans accès à Internet externe.

Auparavant, le Web IDE nécessitait une connectivité à `.cdn.web-ide.gitlab-static.net` pour charger les extensions et les fonctionnalités VS Code. Cette exigence bloquait l'adoption du Web IDE pour les organisations soucieuses de la sécurité, les clients du secteur public et gouvernemental, ainsi que les entreprises appliquant des politiques réseau strictes.

Grâce à cette mise à jour, les administrateurs peuvent configurer leur instance GitLab pour diffuser directement les ressources du Web IDE, supprimant ainsi la dépendance vis-à-vis des domaines externes. Vous pouvez désormais :

- Utiliser l'ensemble des fonctionnalités du Web IDE dans des environnements entièrement hors ligne.
- Activer l'Extension Marketplace avec un service de registre d'extensions personnalisé.
- Activer l'aperçu Markdown, l'édition de code et GitLab Duo Chat dans le Web IDE sur des réseaux isolés.

### Déclencheurs webhook pour les réinitialisations d'approbations initiées par le système {#webhook-triggers-for-system-initiated-approval-resets}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/integrations/webhook_events.md#system-initiated-merge-request-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/553070)

{{< /details >}}

L'intégration de GitLab avec des systèmes externes via des webhooks est essentielle pour les workflows automatisés et pour tenir les équipes informées des changements de statut des merge requests. Cependant, lorsque GitLab réinitialisait automatiquement les approbations (par exemple, lorsque de nouveaux commits étaient poussés vers une merge request avec l'option « Réinitialiser les approbations lors d'un push » activée), les systèmes externes ne pouvaient pas distinguer ces événements initiés par le système des actions manuelles des utilisateurs.

GitLab inclut désormais des charges utiles webhook améliorées qui identifient clairement les réinitialisations d'approbations initiées par le système. Lorsque les approbations sont automatiquement réinitialisées, les webhooks incluent désormais :

- Un champ `system` défini sur `true`.
- Un champ `system_action` qui fournit le contexte spécifique expliquant pourquoi la réinitialisation s'est produite, comme `approvals_reset_on_push` ou `code_owner_approvals_reset_on_push`.

Cela signifie que vos intégrations webhook peuvent désormais distinguer les modifications manuelles d'approbation des réinitialisations automatiques du système, permettant ainsi des workflows d'automatisation plus sophistiqués qui répondent de manière appropriée au contexte spécifique de chaque modification d'approbation.

### L'agent Planner GitLab Duo désormais disponible par défaut {#gitlab-duo-planner-agent-now-available-by-default}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/planner.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/580924)

{{< /details >}}

L'agent Planner GitLab Duo est désormais disponible par défaut dans la liste déroulante des agents de GitLab Duo Chat, ce qui supprime la nécessité de l'ajouter manuellement depuis le catalogue d'IA. Avec le contexte complet de vos éléments de travail, epics, tickets et tâches, l'agent Planner peut désormais vous assister au niveau du groupe et du projet.

Commencez avec [**[des exemples de prompts](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts)**\](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts) pour découvrir comment l'agent Planner peut vous aider à décomposer des travaux complexes, à créer des plans d'implémentation et à organiser les objectifs de votre équipe.

Cette fonctionnalité est en version bêta, et nous vous invitons à nous faire part de vos commentaires dans le [ticket 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622).

### Registre de charts Helm : plus de limite à 1 000 charts {#helm-chart-registry-no-more-1000-chart-limit}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/packages/helm_repository/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/545919)

{{< /details >}}

Le registre de charts Helm de GitLab générait auparavant des réponses de métadonnées à la volée, ce qui créait des goulots d'étranglement de performance lorsque les dépôts contenaient un grand nombre de charts. Pour maintenir la stabilité du système, nous avons appliqué une limite stricte aux 1 000 charts les plus récents. Cette limite provoquait des erreurs 404 frustrantes lorsque les équipes de plateforme tentaient d'accéder aux anciennes versions de charts.

Les ingénieurs de plateforme étaient contraints d'implémenter des solutions de contournement complexes, comme la répartition des charts dans plusieurs dépôts, la gestion manuelle des politiques de rétention des charts ou le maintien de solutions de stockage de charts distinctes. Ces solutions de contournement ajoutaient une surcharge opérationnelle et fragmentaient les workflows de déploiement, rendant plus difficile le maintien d'une gouvernance centralisée des charts.

Dans GitLab 18.6, nous avons éliminé la limitation à 1 000 charts en pré-calculant les réponses de métadonnées et en les stockant dans un stockage objet. Cette modification architecturale offre à la fois un accès illimité aux charts et des performances améliorées, car les métadonnées sont générées une seule fois dans des jobs en arrière-plan plutôt qu'à chaque requête.

### Mode d'avertissement dans les politiques d'approbation des merge requests (version bêta) {#warn-mode-in-merge-request-approval-policies-beta}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

Les équipes de sécurité peuvent désormais utiliser le mode d'avertissement pour tester et valider l'impact des politiques de sécurité avant d'appliquer leur application, réduisant ainsi les frictions pour les développeurs lors des déploiements de politiques de sécurité.

Lorsque vous créez ou modifiez une [politique d'approbation des merge requests](../../user/application_security/policies/merge_request_approval_policies.md), vous pouvez désormais choisir entre les options de mise en application `warn` ou `enforce`.

Les politiques en mode d'avertissement génèrent des commentaires de bot informatifs sans bloquer les merge requests. Des approbateurs optionnels peuvent être désignés comme points de contact pour les questions relatives aux politiques. Cette approche permet aux équipes de sécurité d'évaluer l'impact des politiques et de renforcer la confiance des développeurs grâce à une adoption transparente et progressive des politiques.

Des indicateurs clairs dans les merge requests informent les utilisateurs lorsque les politiques sont en mode `warn` ou `enforce`, et les événements d'audit suivent les violations et les rejets de politiques à des fins de reporting de conformité. Les développeurs peuvent rejeter des vulnérabilités tout en fournissant une justification pour le rejet, créant ainsi une approche collaborative de la gestion des politiques de sécurité.

### Attributs de sécurité (version bêta) {#security-attributes-beta}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/attributes/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19597)

{{< /details >}}

Les équipes de sécurité peuvent désormais appliquer un contexte métier aux projets en exploitant les attributs de sécurité.

Les attributs de sécurité sont organisés par catégories, notamment l'impact sur l'activité (avec des sélections prédéfinies structurées), l'application, l'unité métier, l'exposition à Internet et la localisation. Vous pouvez également créer vos propres catégories d'attributs et définir des labels dans ces catégories.

En appliquant ces attributs à vos projets, vous pouvez beaucoup plus rapidement rechercher, filtrer et identifier les projets dans l'inventaire de sécurité qui nécessitent une action en fonction de la posture de risque et du contexte organisationnel. Vous pouvez désormais :

- Identifier les projets critiques nécessitant une meilleure couverture des scans
- Examiner la couverture des scans par application ou unité métier
- Rechercher et filtrer en fonction des attributs appliqués à vos projets
- Localiser rapidement les projets contribuant à des applications accessibles ou exposées publiquement

### Exceptions pour contourner les politiques d'approbation des merge requests {#exceptions-to-bypass-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

Les organisations peuvent désormais désigner des utilisateurs, des groupes, des rôles ou des rôles personnalisés spécifiques qui peuvent contourner les politiques d'approbation des merge requests en cas de situations critiques. Cette capacité offre une flexibilité pour les réponses d'urgence, tout en maintenant des pistes d'audit complètes et des contrôles de gouvernance.

**Emergency bypass with accountability** : les utilisateurs désignés peuvent contourner les exigences d'approbation lors d'incidents critiques, de correctifs de sécurité ou de problèmes de production urgents. En cas d'urgence, le personnel autorisé peut fusionner ou pousser des modifications immédiatement pendant que le système capture la justification détaillée et les informations d'audit pour examen de conformité.

**Les principales fonctionnalités incluent :**

- **Documented bypass process** : lorsque des utilisateurs autorisés invoquent un contournement de politique, ils doivent fournir un raisonnement détaillé à l'aide d'une interface modale intuitive, garantissant que chaque exception est correctement documentée avec son contexte.
- **Comprehensive audit integration** : chaque contournement génère des événements d'audit détaillés incluant l'identité de l'utilisateur, le contexte de la politique, le raisonnement et les horodatages pour une visibilité complète des modèles d'utilisation des exceptions.
- **Flexible configuration** : définissez des autorisations d'exception pour les politiques à l'aide de la configuration YAML ou de l'interface utilisateur, en prenant en charge les utilisateurs individuels, les groupes GitLab, les rôles standard et les rôles personnalisés.
- **Git-based push exceptions** : les utilisateurs disposant d'exceptions de politique pré-approuvées peuvent pousser directement en invoquant l'option de contournement de push `security_policy.bypass_reason`.

Cette fonctionnalité élimine la nécessité de désactiver entièrement les politiques de sécurité lors des urgences, offrant une voie contrôlée pour les modifications urgentes tout en préservant la gouvernance organisationnelle et les exigences d'audit.

### Désigner un bénéficiaire pour la succession de compte {#designate-an-account-succession-beneficiary}

<!-- categories: System Access -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/profile/account/account_succession.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/330669)

{{< /details >}}

Vous pouvez désormais désigner un bénéficiaire de compte ayant l'autorisation de gérer votre compte GitLab si vous êtes dans l'incapacité de le faire ou indisponible. Pour accéder à votre compte, le bénéficiaire doit fournir la documentation légale appropriée. Cette fonctionnalité contribue à assurer la continuité de votre travail et de vos projets tout en prévenant les accès non autorisés.

### Les propriétaires de groupe peuvent mettre à jour les adresses e-mail principales des utilisateurs enterprise {#group-owners-can-update-primary-emails-for-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/enterprise_user/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/425837)

{{< /details >}}

Les propriétaires de groupe peuvent désormais mettre à jour l'adresse e-mail principale des utilisateurs enterprise dans leur groupe. Les mises à jour peuvent être effectuées via l'API Users. Auparavant, chaque utilisateur enterprise devait mettre à jour manuellement sa propre adresse e-mail. Cette modification facilite la gestion des utilisateurs enterprise à grande échelle.

### GitLab Runner 18.6 {#gitlab-runner-186}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 18.6 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Implémentation d'une API minimale de confirmation de job](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39013)

#### Corrections de bugs {#bug-fixes}

- [GitLab Runner ne développe pas les variables dans l'option de plateforme de l'image Docker](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38488)
- [Le conteneur sidecar d'assistance ne parvient pas à charger le cache dans un compartiment S3 depuis un autre compte](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37879)
- [Un job automatiquement annulé continue son exécution et échoue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37878)
- [L'absence du BOM UTF8 dans le script PowerShell généré permet l'exécution de code à distance en utilisant le titre de la merge request avec le caractère Ä](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36060)
- [Échecs intermittents des requêtes au serveur API Kubernetes avec l'exécuteur Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30109)
- [Lors de l'utilisation d'un exécuteur Kubernetes, les jobs avec des messages de commit volumineux échouent](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26624)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.6)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
