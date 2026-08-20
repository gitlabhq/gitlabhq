---
stage: Release Notes
group: Monthly Release
date: 2025-12-18
title: "Notes de release de GitLab 18.7"
description: "GitLab 18.7 est disponible avec des vérifications de validité des secrets améliorées et en disponibilité générale"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 18 décembre 2025, GitLab 18.7 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : David Aniebo {#this-months-notable-contributor-david-aniebo}

Nous sommes ravis de reconnaître David Aniebo comme notre contributeur remarquable pour la version 18.7, pour ses contributions impactantes aux capacités de planification produit de GitLab et à la [plateforme des contributeurs](https://contributors.gitlab.com).

Le travail de David sur [l'amélioration des fonctionnalités de liste d'éléments de travail](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207549) témoigne de son expertise technique et de son engagement à améliorer l'expérience utilisateur des fonctionnalités de planification de GitLab. Cette contribution aide les équipes à mieux organiser et gérer leurs éléments de travail, rendant la planification de projet plus efficace pour des milliers d'utilisateurs de GitLab.

Au-delà des contributions au code, David a été un soutien constant de la plateforme des contributeurs, contribuant à améliorer l'expérience des contributeurs de la communauté. Son approche collaborative et sa réactivité lui ont valu les éloges de plusieurs membres de l'équipe au sein de différents groupes.

« David a accompli un travail fantastique en contribuant aux efforts du groupe Product Planning, et nous lui sommes très reconnaissants pour ses contributions », a déclaré Nick Brandt, Engineering Manager pour Product Planning.

Merci, David, pour vos précieuses contributions à GitLab et pour votre esprit de collaboration au sein de notre communauté ! Nous espérons vous voir continuer à vous impliquer.

## Fonctionnalités principales {#primary-features}

### Vérifications de validité des secrets améliorées et en disponibilité générale {#secret-validity-checks-improved-and-generally-available}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/vulnerabilities/validity_check.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16890)

{{< /details >}}

Lorsqu'un secret valide est divulgué dans l'un de vos dépôts, vous devez réagir rapidement. Pour vous aider à prioriser les menaces urgentes, les vérifications de validité déterminent automatiquement si les identifiants divulgués peuvent encore être utilisés.

Dans GitLab 18.7, nous avons amélioré :

- Intégrations fournisseurs : intégration avec Google Cloud, AWS et Postman, en plus de la prise en charge existante des jetons GitLab.
- Filtrage des rapports : filtrez le rapport de vulnérabilité par statut de validité (actif, inactif, peut-être actif) pour trier et prioriser rapidement les résultats de secrets.
- API au niveau du groupe : activez les vérifications de validité pour tous les projets d'un groupe avec un seul appel API et simplifiez le déploiement au sein de votre organisation.

Dans cette release, les vérifications de validité sont en disponibilité générale.

### Sélection de modèle distincte pour Agentic Chat et les agents {#separate-model-selection-for-agentic-chat-and-agents}

<!-- categories: Model Personalization -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/work_items/19998)

{{< /details >}}

Des modèles distincts peuvent désormais être sélectionnés pour Agentic Chat et pour tous les autres agents pour les groupes principaux ou les instances. Cela offre davantage d'options de sélection de modèles pour GitLab Duo Agent Platform.

### Tableau de bord des tendances GitLab Duo et SDLC amélioré {#improved-gitlab-duo-and-sdlc-trends-dashboard}

<!-- categories: DevOps Reports -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/analytics/duo_and_sdlc_trends.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19629)

{{< /details >}}

Le tableau de bord des tendances GitLab Duo et SDLC offre des capacités d'analyse améliorées pour mesurer l'impact de GitLab Duo sur la livraison de logiciels. Le tableau de bord fournit désormais une analyse des tendances sur 6 mois portant sur l'adoption des fonctionnalités GitLab Duo, les performances des pipelines et les métriques de développement courantes telles que la fréquence de déploiement et le délai moyen avant fusion.

Vous pouvez désormais suivre les volumes de génération de code et les tendances par IDE ou par langage pour GitLab Duo Code Suggestions, et observer l'adoption des nouveaux flows GitLab Duo Agent Platform par vos équipes. Des métriques utilisateur améliorées permettent aux équipes d'obtenir une vision plus approfondie des fonctionnalités Duo clés apportant une valeur continue.

Un nouveau [point de terminaison pour l'utilisation de l'IA au niveau de l'instance](../../api/graphql/reference/_index.md#aiinstanceusagedata) est désormais disponible pour les administrateurs d'instance afin d'extraire toutes les données Duo depuis Postgres (rétention de 3 mois) ou ClickHouse.

Propulsé par l'[intégration ClickHouse](../../integration/clickhouse.md), ce tableau de bord offre des performances de requête inférieures à la seconde sur des millions de points de données. Pour les instances self-managed, consultez les recommandations améliorées et les conseils de configuration pour l'[intégration ClickHouse](../../integration/clickhouse.md).

### Fonctionnalités supplémentaires de l'agent Planner disponibles en version bêta {#additional-planner-agent-features-available-in-beta}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/planner.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

L'agent Planner inclut désormais des fonctionnalités de création et de modification en version bêta ! L'agent Planner est un agent par défaut conçu pour accompagner directement les product managers dans GitLab. Utilisez l'agent Planner pour créer, modifier et analyser des éléments de travail GitLab.

Au lieu de suivre manuellement les mises à jour, de prioriser le travail ou de résumer les données de planification, l'agent Planner vous aide à analyser les backlogs, à appliquer des frameworks tels que RICE ou MoSCoW, et à identifier ce qui nécessite vraiment votre attention. C'est comme avoir un coéquipier proactif qui comprend votre workflow de planification et travaille avec vous pour prendre de meilleures décisions, plus efficacement.

Faites-nous part de vos retours dans le [ticket 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622).

### Options d'entrée dynamiques dans les pipelines CI/CD {#dynamic-input-options-in-cicd-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/inputs/_index.md#define-conditional-input-options-with-specinputsrules) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18546)

{{< /details >}}

Vous pouvez configurer vos pipelines CI/CD pour utiliser la sélection d'entrée CI/CD dynamique lors de la création de nouveaux pipelines via l'interface web intuitive.

Désormais, grâce aux options d'entrée dynamiques, vous pouvez configurer vos pipelines de sorte que les options de sélection d'entrée se mettent à jour dynamiquement en fonction des sélections précédentes. Par exemple, lorsque vous sélectionnez une entrée dans une liste déroulante, elle remplit automatiquement une liste d'options d'entrée associées dans une seconde liste déroulante.

Avec les entrées CI/CD, vous pouvez :

- Déclencher des pipelines avec des entrées préconfigurées, réduisant ainsi les erreurs et simplifiant les déploiements.
- Permettre à vos utilisateurs de sélectionner des entrées différentes des valeurs par défaut dans les menus déroulants.
- Disposer désormais de listes déroulantes en cascade dont les options se mettent à jour dynamiquement en fonction des sélections précédentes.

Cette capacité dynamique vous permet de créer des configurations d'entrée plus intelligentes et contextuelles qui vous guident tout au long du processus de création de pipeline, réduisant les erreurs et garantissant que seules des combinaisons d'entrées valides sont sélectionnées.

### Détection des faux positifs SAST par l'IA (bêta) {#sast-false-positive-detection-with-ai-beta}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/application_security/vulnerabilities/false_positive_detection.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18977)

{{< /details >}}

Les équipes de sécurité consacrent souvent un temps considérable à l'examen des résultats SAST qui s'avèrent être des faux positifs, détournant ainsi l'attention des véritables risques de sécurité.

Dans GitLab 18.7, nous introduisons la détection des faux positifs SAST par l'IA pour aider les équipes à se concentrer sur les vulnérabilités qui comptent. Lors de l'exécution d'un scan de sécurité, GitLab Duo analyse automatiquement chaque vulnérabilité SAST de gravité Critique et Élevée pour déterminer la probabilité qu'il s'agisse d'un faux positif.

L'évaluation par l'IA apparaît directement dans le rapport de vulnérabilité, offrant aux ingénieurs en sécurité un contexte immédiat pour prendre des décisions de triage plus rapides et plus fiables.

Les principales fonctionnalités incluent :

- Analyse automatique : la détection des faux positifs s'exécute automatiquement après chaque scan de sécurité, sans déclenchement manuel requis.
- Option de déclenchement manuel : les utilisateurs peuvent déclencher manuellement la détection des faux positifs pour des vulnérabilités individuelles sur la page de détails de la vulnérabilité pour une analyse à la demande.
- Centré sur les résultats à fort impact : limité aux vulnérabilités de gravité Critique et Élevée pour maximiser l'amélioration du rapport signal/bruit.
- Raisonnement contextuel de l'IA : chaque évaluation inclut une explication des raisons pour lesquelles le résultat peut ou non être un vrai positif, basée sur le contexte du code et les caractéristiques de la vulnérabilité.
- Intégration fluide au workflow : les résultats apparaissent directement dans le rapport de vulnérabilité aux côtés des informations existantes sur la gravité, le statut et la remédiation.

Cette fonctionnalité est disponible en version bêta gratuite pour les clients Ultimate et doit être activée dans les paramètres de votre groupe ou projet. Nous vous invitons à nous faire part de vos retours dans le [ticket 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697).

### Nouveaux tableaux de bord de sécurité activés par défaut {#new-security-dashboards-enabled-by-default}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/security_dashboard/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/20213)

{{< /details >}}

Les nouveaux tableaux de bord de sécurité ont été mis à jour et modernisés. Les tableaux de bord étaient précédemment disponibles sur GitLab.com, et sont désormais activés par défaut sur GitLab Dedicated et GitLab Self-Managed.

Les nouvelles fonctionnalités incluent :

- Un graphique des vulnérabilités dans le temps qui prend en charge :
  - Le filtrage par projet ou par type de rapport.
  - Le regroupement par type de rapport et par gravité.
  - Des liens directs vers les vulnérabilités dans le rapport de vulnérabilité.
- Un module de score de risque qui calcule le risque estimé pour un groupe ou un projet selon un algorithme GitLab.

Veuillez noter que l'utilisation du nouveau tableau de bord nécessite Elasticsearch.

### Paramètre d'instance pour contrôler la publication de composants CI/CD dans le catalogue CI/CD {#instance-setting-to-control-publishing-of-components-to-the-cicd-catalog}

<!-- categories: Pipeline Composition, Component Catalog -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../administration/settings/continuous_integration.md#restrict-cicd-catalog-publishing) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/582044)

{{< /details >}}

Les administrateurs de GitLab Self-Managed et GitLab Dedicated peuvent désormais restreindre les projets autorisés à publier des composants CI/CD dans le catalogue CI/CD. Ce nouveau paramètre permet aux organisations de maintenir un catalogue CI/CD organisé et fiable en contrôlant quels composants CI/CD peuvent être publiés.

Les administrateurs peuvent désormais spécifier une liste d'autorisation de projets habilités à publier des composants CI/CD. Lorsque la liste d'autorisation est renseignée avec des projets, seuls ces projets peuvent publier des composants CI/CD. Cela empêche les composants CI/CD non autorisés ou non approuvés d'encombrer la liste des composants CI/CD publiés et garantit que tous les composants CI/CD respectent les normes organisationnelles et les exigences de sécurité.

Cela répond à un défi clé de gouvernance pour les clients entreprise qui souhaitent maintenir le contrôle sur leur écosystème de composants CI/CD tout en permettant à leurs équipes de découvrir et de réutiliser les composants CI/CD approuvés.

## Agentic Core {#agentic-core}

### Recherche avancée disponible pour les descriptions et les commentaires des merge requests {#advanced-search-available-for-both-merge-request-descriptions-and-comments}

<!-- categories: Global Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/search/advanced_search.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/572590)

{{< /details >}}

La recherche avancée retourne désormais des résultats correspondants à la fois dans les descriptions et les commentaires des merge requests. Auparavant, les utilisateurs devaient effectuer des recherches séparées dans les descriptions et les commentaires des merge requests.

Cette amélioration offre un workflow de recherche plus fluide et plus complet pour les merge requests GitLab.

### Prise en charge de `AGENTS.md` avec GitLab Duo Chat (Agentic) dans les IDE {#support-for-agentsmd-with-gitlab-duo-chat-agentic-in-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/duo_agent_platform/customize/agents_md.md)

{{< /details >}}

GitLab Duo Chat prend désormais en charge la spécification `AGENTS.md`, une norme émergente pour fournir du contexte et des instructions aux assistants de codage IA.

Contrairement aux règles personnalisées qui ne sont disponibles que pour GitLab Duo, les fichiers `AGENTS.md` sont également disponibles pour d'autres outils de codage IA. Vos commandes de build, instructions de test, directives de style de code et contexte spécifique au projet sont ainsi accessibles à tout outil IA prenant en charge la spécification.

GitLab Duo Chat dans votre IDE applique automatiquement les instructions disponibles dans les fichiers `AGENTS.md` de votre dépôt, définies au niveau utilisateur ou workspace. Pour les monodépôts, vous pouvez placer des fichiers `AGENTS.md` dans des sous-répertoires afin de fournir des instructions adaptées à différents composants.

### Gestion des versions des agents d'IA et des flows {#ai-agent-and-flow-versioning}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/duo_agent_platform/ai_catalog.md#agent-and-flow-versions) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/20022)

{{< /details >}}

Lorsque vous activez un agent d'IA ou un flow depuis le catalogue d'IA dans votre projet, GitLab le fixe désormais à une version spécifique.

Cela signifie que vos workflows IA restent stables et prévisibles, même lorsque les éléments du catalogue évoluent, afin que vous puissiez tester et valider les nouvelles versions avant de mettre à niveau.

### Paramètre de délai d'expiration de la passerelle IA {#ai-gateway-timeout-setting}

<!-- categories: Model Personalization -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-timeout-for-the-ai-gateway) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/579183)

{{< /details >}}

Pour GitLab Duo Self-Hosted, vous pouvez désormais configurer une valeur de délai d'expiration pour les requêtes adressées aux modèles auto-hébergés.

Cette valeur peut être comprise entre 60 et 600 secondes.

### Signaler des agents et des flows aux administrateurs {#report-agents-and-flows-to-administrators}

<!-- categories: AI Catalog -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/report_abuse.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/578591)

{{< /details >}}

Vous pouvez désormais signaler des agents et des flows aux administrateurs d'instance lorsque vous rencontrez du contenu problématique. Soumettez un rapport d'abus incluant vos retours, et un administrateur peut choisir de masquer ou de supprimer l'élément nuisible.

Utilisez cette fonctionnalité pour assurer la sécurité de vos agents et flows au sein de toute votre organisation.

### Configurer la disponibilité des agents par défaut {#configure-foundational-agent-availability}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/583815)

{{< /details >}}

Vous pouvez désormais contrôler quels agents par défaut sont disponibles dans votre groupe principal ou votre instance.

Activez ou désactivez tous les agents par défaut par défaut, ou activez/désactivez des agents individuels pour les aligner sur les politiques de sécurité et de gouvernance de votre organisation.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Expérience d'essai active améliorée pour Self-Managed {#enhanced-active-trial-experience-for-self-managed}

<!-- categories: Acquisition -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../subscriptions/free_trials.md#view-remaining-trial-period-days)

{{< /details >}}

Les utilisateurs de GitLab Self-Managed disposant d'un essai Ultimate peuvent désormais accéder au statut de leur essai actif, aux jours restants, aux fonctionnalités accessibles et aux notifications d'expiration depuis la barre latérale gauche.

Ces améliorations permettent d'éliminer la confusion quant à la durée de l'essai et facilitent l'évaluation des fonctionnalités payantes avant l'achat.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Gestion avancée des vulnérabilités disponible dans les environnements Self-Managed et Dedicated {#advanced-vulnerability-management-available-in-self-managed-and-dedicated-environments}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

La gestion avancée des vulnérabilités est disponible pour tous les clients Ultimate et inclut les fonctionnalités suivantes :

- Regroupement des données par catégories OWASP 2021 dans le rapport de vulnérabilité pour un projet ou un groupe.
- Filtrage basé sur un identifiant de vulnérabilité dans le rapport de vulnérabilité pour un projet ou un groupe.
- Filtrage basé sur la valeur d'accessibilité dans le rapport de vulnérabilité pour un projet ou un groupe.
- Filtrage par motif de contournement de violation de politique.

### Agent Data Analyst, agent par défaut propulsé par GLQL (bêta) {#data-analyst-foundational-agent-powered-by-glql-beta}

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md)

{{< /details >}}

L'agent Data Analyst est un assistant IA spécialisé qui vous aide à interroger, visualiser et exploiter les données sur l'ensemble de la plateforme GitLab. Il utilise le langage de requête GitLab (GLQL) pour récupérer et analyser les données, puis fournit des insights clairs et exploitables sur vos projets.

Vous trouverez des exemples de prompts et des cas d'usage dans la documentation.

Cet agent d'IA est actuellement en version bêta, aussi nous vous invitons à partager vos réflexions dans le [ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/issues/574028) pour nous aider à l'améliorer et à mieux comprendre vos attentes.

### Filtrer et commenter les violations de conformité {#filter-and-comment-on-compliance-violations}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

Le rapport sur les violations de conformité offre une vue centralisée de toutes les violations de conformité au sein des projets de votre organisation. Le rapport affiche des détails complets sur les violations de contrôle, les événements d'audit associés, et permet aux équipes de suivre efficacement les statuts des violations.

Dans GitLab 18.7, nous avons introduit de puissantes capacités de filtrage pour vous aider à trouver rapidement les violations les plus importantes. Vous pouvez désormais filtrer par :

- Statut
- Projet
- Contrôle

Les équipes peuvent désormais également collaborer directement sur la résolution des violations via des commentaires. Au sein même de l'enregistrement de violation, les équipes peuvent :

- Identifier des membres de l'équipe pour l'investigation
- Discuter des approches de remédiation
- Documenter les résultats — le tout au sein de l'enregistrement de violation lui-même.

Ensemble, ces fonctionnalités font évoluer le rapport sur les violations de conformité en une plateforme de collaboration dynamique, permettant aux organisations de découvrir, d'analyser et de résoudre efficacement les violations de conformité dans leurs groupes et projets.

### Les contrôles du framework de conformité affichent un statut de scan précis {#compliance-framework-controls-show-accurate-scan-status}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)

{{< /details >}}

Les contrôles de conformité GitLab peuvent être utilisés dans les frameworks de conformité. Les contrôles sont des vérifications portant sur la configuration ou le comportement des projets affectés à un framework de conformité.

Auparavant, les contrôles liés aux scanners (par exemple, vérifier si SAST est activé) exigeaient que vos projets disposent d'un pipeline réussi sur la branche par défaut avant que le centre de conformité n'affiche le statut de réussite ou d'échec de vos contrôles.

Dans GitLab 18.7, nous avons modifié ce comportement pour indiquer si vos contrôles ont réussi ou échoué en se basant uniquement sur la complétion du scan, indépendamment du statut global du pipeline. Cela permet de réduire la confusion, car le statut de conformité de vos contrôles reflète si les scans de sécurité ont été exécutés et complétés, et non si l'ensemble du pipeline a réussi.

### Améliorations de l'accessibilité pour les liens d'ancrage de titres {#accessibility-improvements-for-heading-anchor-links}

<!-- categories: Markdown -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/markdown.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/463385)

{{< /details >}}

Les liens d'ancrage de titres s'annoncent désormais avec le même texte que leur titre correspondant, améliorant ainsi l'expérience pour les utilisateurs de lecteurs d'écran. Les liens apparaissent également après le texte du titre, offrant une présentation visuelle plus claire.

Ces modifications permettent à tous les utilisateurs de mieux comprendre et naviguer vers des sections spécifiques de la documentation, des tickets et d'autres contenus.

### Mode d'avertissement dans les politiques d'approbation des merge requests {#warn-mode-in-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

Les équipes de sécurité peuvent désormais utiliser le mode d'avertissement pour tester et valider l'impact des politiques de sécurité avant d'appliquer une mise en application, ou pour déployer des portes souples afin d'accélérer votre programme de sécurité. Le mode d'avertissement contribue à réduire les frictions pour les développeurs lors du déploiement des politiques de sécurité, tout en continuant de garantir que les vulnérabilités détectées sont traitées.

Lorsque vous créez ou modifiez une [politique d'approbation des merge requests](../../user/application_security/policies/merge_request_approval_policies.md), vous pouvez désormais choisir entre les options de mise en application `warn` ou `enforce`.

Les politiques en mode d'avertissement génèrent des commentaires de bot informatifs sans bloquer les merge requests. Des approbateurs optionnels peuvent être désignés comme points de contact pour les questions relatives aux politiques. Cette approche permet aux équipes de sécurité d'évaluer l'impact des politiques et de renforcer la confiance des développeurs grâce à une adoption transparente et progressive des politiques.

Des indicateurs clairs dans les merge requests informent les utilisateurs lorsque les politiques sont en mode `warn` ou `enforce`, et les événements d'audit suivent les violations et les rejets de politiques à des fins de reporting de conformité. Les développeurs peuvent contourner les violations de politiques de résultats de scan et de licences en fournissant une justification pour le rejet de la politique, créant ainsi une boucle de retour collaborative entre les développeurs et les équipes de sécurité pour une activation des politiques plus efficace.

Lorsque des violations de politique sont détectées sur la branche par défaut d'un projet, les politiques identifient les vulnérabilités qui violent la politique dans les rapports de vulnérabilité pour les projets et les groupes. La liste des dépendances pour les projets affiche également des badges indiquant les violations de politique de conformité des licences.

De plus, vous pouvez utiliser l'API pour interroger une liste filtrée des violations de politique sur la branche par défaut d'un projet.

### Comptes de service disponibles pendant les essais sur GitLab.com {#service-accounts-available-during-trials-on-gitlabcom}

<!-- categories: System Access -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/profile/service_accounts.md)

{{< /details >}}

Les comptes de service sont désormais disponibles pendant les périodes d'essai, vous permettant de tester des workflows d'automatisation et d'intégration avant l'achat.

### GitLab Runner 18.7 {#gitlab-runner-187}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 18.7 aujourd'hui !

GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Limitation configurable de la réservation taskscaler](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39161)
- [Activer `FF_TIMESTAMPS` par défaut](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38378)

#### Corrections de bugs {#bug-fixes}

- [L'exécuteur Shell échoue sur un dépôt Git existant si un `builds_dir` relatif est spécifié](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39150)
- [Échec d'authentification dans GitLab Runner 18.6.0 lors des exécutions de pipeline suivantes (exécuteur SSH)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39140)
- [Échec d'authentification dans GitLab Runner 18.6.0 lors des exécutions de pipeline suivantes (exécuteur shell)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39123)
- [Problèmes de compatibilité avec l'API Docker 29](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39129)
- [Les variables référençant des variables de fichier ne fonctionnent plus dans GitLab Runner 18.6.0 avec l'exécuteur shell](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39124)
- [GitLab Runner prend désormais en charge Windows 11 2025 (25H2)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39050)
- [L'assistant d'identification ECR ne fonctionne pas avec l'exécuteur Docker Autoscaler](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38365)
- [Les délais d'expiration des jobs sont désormais correctement appliqués dans GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27040)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/CHANGELOG.md).md) de GitLab Runner.

### Afficher les rapports de pipeline enfant dans les merge requests {#view-child-pipeline-reports-in-merge-requests}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18311)

{{< /details >}}

Les équipes utilisant des pipelines CI/CD parent-enfant devaient auparavant parcourir plusieurs pages de pipeline pour vérifier les résultats des tests, les rapports de qualité du code et les modifications d'infrastructure, perturbant ainsi leur workflow de révision des merge requests.

Vous pouvez désormais consulter et télécharger tous les rapports dans une vue unifiée, incluant les tests unitaires, les vérifications de qualité du code, les plans Terraform et les métriques personnalisées, sans quitter la merge request.

Cela élimine les changements de contexte et accélère la vélocité des merge requests, permettant aux équipes de livrer des fonctionnalités plus rapidement sans compromettre la qualité.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.7)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
