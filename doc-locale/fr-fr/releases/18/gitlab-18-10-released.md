---
stage: Release Notes
group: Monthly Release
date: 2026-03-19
title: "Notes de release de GitLab 18.10"
description: "GitLab 18.10 est disponible avec la détection des faux positifs SAST grâce à GitLab Duo Agent Platform"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 19 mars 2026, GitLab 18.10 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Harshith Sudar {#this-months-notable-contributor-harshith-sudar}

Harshith est actuellement un contributeur de niveau 3 qui a apporté des contributions significatives à l'amélioration des outils communautaires et des analyses, de l'automatisation du triage et de la reconnaissance des contributeurs aux insights d'utilisation de [GitLab Duo](https://about.gitlab.com/gitlab-duo-agent-platform/).

Les contributions de Harshith ont été reconnues pour la première fois par [Lee Tickett](https://gitlab.com/leetickett-gitlab), ingénieur fullstack en ingénierie DevRel chez GitLab, qui l'a nommé. Son travail a renforcé la façon dont nous soutenons les contributeurs en coulisses grâce à des améliorations apportées à notre automatisation et aux expériences destinées aux contributeurs. Par exemple, il a étendu notre automatisation du triage en [mettant à jour le processeur `IssueSummary` dans triage-ops pour travailler avec plusieurs projets](https://gitlab.com/gitlab-org/quality/triage-ops/-/merge_requests/3589), y compris [contributors.gitlab.com](https://contributors.gitlab.com), ce qui nous permet de maintenir plus facilement un résumé cohérent et une visibilité accrue pour davantage de projets communautaires. Il a également contribué à la reconnaissance des contenus créés par la communauté grâce au [nouveau bouton « Ajouter du contenu » et au flow associé](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1250), qui permet aux contributeurs d'enregistrer des articles de blog, des vidéos et d'autres contenus directement depuis leur profil et d'être récompensés.

Harshith a également contribué à nos analyses et aux insights d'utilisation de GitLab Duo. Parmi les points forts, on peut citer [le perfectionnement du calcul de l'utilisation de GitLab Duo](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207511), l'amélioration de l'exploration de l'impact de l'IA dans le temps en [supprimant la valeur par défaut de 180 jours](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218870), et [la consolidation des constantes de plage de dates des métriques DORA](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216715), ainsi que l'amélioration des analyses à grande échelle avec des améliorations comme l'ajout du [défilement infini pour le sélecteur de labels des étapes personnalisées dans Value Stream Analytics](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207796). Ensemble, ces changements aident les équipes à mieux comprendre comment GitLab est utilisé dans des projets réels.

En ses propres mots :

> « Une chose que j'ai vraiment appréciée en contribuant, c'est la façon dont les idées sont discutées avec soin au sein de la communauté. Il est encourageant de voir les suggestions explorées de manière collaborative, comme dans la discussion autour de [MR !1288](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1288), qui s'est transformée en une excellente expérience d'apprentissage. Je suis vraiment heureux de faire partie de cette communauté et j'espère pouvoir apporter encore de nombreuses contributions à l'avenir. »

Merci, Harshith, pour votre travail continu visant à améliorer la base de code GitLab et l'expérience des contributeurs !

Vous souhaitez vous connecter avec Harshith et en savoir plus sur ses contributions ? Visitez le [profil GitLab](https://gitlab.com/official.harshith1) de Harshith et son [profil LinkedIn](https://www.linkedin.com/in/harshith-s-a44169282/).

## Fonctionnalités principales {#primary-features}

### Détection des faux positifs SAST avec GitLab Duo Agent Platform {#sast-false-positive-detection-with-gitlab-duo-agent-platform}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/application_security/vulnerabilities/false_positive_detection.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/19789)

{{< /details >}}

La détection des faux positifs SAST, introduite pour la première fois en version bêta dans GitLab 18.7, est désormais généralement disponible dans GitLab 18.10.

Lorsqu'un scan de sécurité s'exécute, GitLab Duo Agent Platform analyse chaque vulnérabilité SAST de gravité critique et élevée et détermine la probabilité qu'il s'agisse d'un faux positif. L'évaluation apparaît directement dans le rapport de vulnérabilité, donnant aux équipes le contexte dont elles ont besoin pour trier avec confiance plutôt qu'avec incertitude.

Les principales fonctionnalités incluent :

- Analyse automatique : la détection des faux positifs s'exécute automatiquement après chaque scan de sécurité, sans intervention manuelle requise.
- Option manuelle : les utilisateurs peuvent exécuter manuellement la détection des faux positifs pour des vulnérabilités individuelles sur la page de détails de la vulnérabilité pour une analyse à la demande.
- Focalisation sur les résultats à fort impact : limiter l'analyse aux vulnérabilités SAST de gravité critique et élevée permet de filtrer le bruit là où cela importe le plus.
- Raisonnement contextuel de l'IA : chaque évaluation explique pourquoi un résultat peut ou non être un faux positif, en tenant compte du contexte du code, du flux de données et des caractéristiques de la vulnérabilité spécifiques à l'analyse statique.
- Intégration fluide au workflow : les résultats apparaissent directement dans le rapport de vulnérabilité aux côtés des informations existantes sur la gravité, le statut et la remédiation — aucune modification des workflows existants n'est requise.

Cette fonctionnalité est disponible pour les clients GitLab Ultimate avec GitLab Duo Agent Platform. La fonctionnalité doit être activée dans les paramètres de votre groupe ou projet. Nous vous invitons à nous faire part de vos retours dans le [ticket 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697).

### Acheter des GitLab Credits dans l'édition Gratuite sur GitLab.com {#purchase-gitlab-credits-on-the-free-tier-on-gitlabcom}

<!-- categories: Subscription Management -->

{{< details >}}

- Édition : Gratuite
- Offre : GitLab.com
- Modules complémentaires : GitLab Credits
- Liens : [Documentation](../../subscriptions/gitlab_credits.md#for-the-free-tier) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20165)

{{< /details >}}

Les propriétaires de groupes de l'édition Gratuite sur GitLab.com peuvent désormais débloquer l'IA avec des GitLab Credits. Achetez un montant mensuel de crédits, engagez-vous sur une durée annuelle et accédez aux [agents et flows de GitLab Duo Agent Platform](../../subscriptions/gitlab_credits.md#for-the-free-tier). Les crédits se renouvellent automatiquement chaque mois, afin que votre équipe dispose toujours de ce dont elle a besoin pour développer plus rapidement et plus intelligemment.

Points essentiels :

- **Usage-based pricing** : achetez un engagement mensuel de crédits sans avoir besoin d'un abonnement à un plan de base.
- **Self-service purchasing** : achetez des crédits via le flow d'achat GitLab.
- **Seamless upgrade path** : votre engagement en crédits est transféré si vous passez ultérieurement à Premium ou Ultimate.
- **Consumption tracking** : surveillez votre utilisation de crédits via le tableau de bord GitLab Credits.

Cette [option d'achat](../../subscriptions/gitlab_credits.md#buy-gitlab-credits) est actuellement disponible uniquement pour les groupes principaux GitLab.com gratuits.

### Connectez-vous en toute sécurité avec des clés d'accès {#sign-in-securely-with-passkeys}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../auth/passkeys.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/10897)

{{< /details >}}

GitLab prend désormais en charge les clés d'accès pour la connexion sans mot de passe et comme méthode d'authentification à deux facteurs (2FA) résistante au hameçonnage. Les clés d'accès utilisent la cryptographie à clé publique et l'authentification biométrique (empreinte digitale, reconnaissance faciale) ou le code PIN de votre appareil pour accéder en toute sécurité à votre compte.

Les clés d'accès offrent les avantages suivants :

- **Passwordless convenience** : connectez-vous avec les données biométriques ou le code PIN de votre appareil au lieu de mémoriser un mot de passe.
- **Multi-device support** : utilisez des clés d'accès sur les navigateurs de bureau, les appareils mobiles (iOS 16 ou version ultérieure, Android 9 ou version ultérieure) et les clés de sécurité matérielles compatibles FIDO2/WebAuthn.
- **Phishing-resistant security** : votre clé privée ne quitte jamais votre appareil. GitLab ne stocke que la clé publique, protégeant votre compte même si les serveurs GitLab sont compromis.
- **Automatic 2FA integration** : pour les comptes avec la 2FA activée, les clés d'accès deviennent disponibles comme méthode 2FA par défaut.

Pour commencer, ajoutez une clé d'accès dans les paramètres de votre compte. Nous accueillons vos questions et retours dans le ticket [366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/[366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/366758)).

### Présentation de la liste des éléments de travail et des vues enregistrées {#introducing-the-work-items-list-and-saved-views}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/work_items/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/17530)

{{< /details >}}

L'expérience de planification GitLab bénéficie d'une mise à niveau significative avec la liste des éléments de travail et les vues enregistrées, réunissant deux fonctionnalités très demandées :

- La liste des éléments de travail combine les epics, les tickets et d'autres éléments de travail dans une liste unifiée, supprimant la nécessité de naviguer entre des pages séparées pour différents types d'éléments de travail. Cela facilite la compréhension des relations entre vos objets de planification.
- Les vues enregistrées vous permettent de créer et d'enregistrer des configurations de liste personnalisées, incluant des filtres, un ordre de tri et des options d'affichage. Cela rend les vérifications de routine plus efficaces et prend en charge des façons standardisées de visualiser le travail au sein de votre équipe.

Il s'agit de la prochaine étape dans le parcours des éléments de travail GitLab, une architecture unifiée conçue pour offrir de la cohérence et débloquer de nouvelles fonctionnalités dans les outils de planification GitLab.

Partagez vos idées et retours dans le [ticket 590689](https://gitlab.com/gitlab-org/gitlab/-/work_items/590689).

### Les agents personnalisés peuvent utiliser MCP pour accéder à des données externes {#custom-agents-can-use-mcp-to-access-external-data}

<!-- categories: AI Catalog -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Liens : [Documentation](../../user/gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708)

{{< /details >}}

Vous pouvez désormais connecter des agents personnalisés dans le catalogue d'IA à des sources de données et des outils externes via le Model Context Protocol (MCP), sans quitter GitLab.

Cette fonctionnalité est une version expérimentale. Partagez vos retours dans le [ticket 593219](https://gitlab.com/gitlab-org/gitlab/-/work_items/593219).

### Appliquer des conventions de nommage aux titres de merge requests avec des expressions régulières {#enforce-merge-request-title-naming-conventions-with-regex}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/merge_requests/title_validation.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20108)

{{< /details >}}

Il est important de maintenir des titres de merge requests cohérents pour les équipes qui s'appuient sur des conventions de nommage structurées. Que ce soit en suivant le format Conventional Commits, ou en liant à un système de suivi interne. Les équipes avaient auparavant besoin d'outils externes ou de jobs de pipeline CI/CD personnalisés pour appliquer ces conventions, mais cette approche présentait une lacune critique. Si quelqu'un modifiait le titre de la merge request après l'exécution du pipeline, il n'y avait pas de revalidation, et la MR pouvait toujours être fusionnée avec un titre non conforme.

Vous pouvez désormais configurer une expression régulière de titre requise pour les merge requests dans les paramètres de votre projet. Une fois configuré, GitLab évalue le titre de la merge request par rapport au modèle lors d'une vérification de fusionnabilité — bloquant la fusion jusqu'à ce que le titre soit mis à jour pour être conforme, quelle que soit la date de la dernière modification du titre.

Pour configurer ceci, accédez aux **Paramètres > Requêtes de fusion** de votre projet et saisissez un modèle d'expression régulière dans le champ **Merge request title must match regex**.

Vos workflows de merge request existants continuent de fonctionner comme avant. Cette vérification s'applique uniquement aux projets pour lesquels vous configurez explicitement une expression régulière de titre.

### Secret false positive detection avec l'IA (version bêta) {#secret-false-positive-detection-with-ai-beta}

<!-- categories: Vulnerability Management, Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/application_security/vulnerabilities/secret_false_positive_detection.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20152)

{{< /details >}}

Les équipes de sécurité passent beaucoup de temps à examiner les résultats de détection des secrets qui s'avèrent être des faux positifs. Par exemple, des identifiants de test, des valeurs d'exemple et des jetons fictifs qui sont incorrectement signalés comme de véritables secrets. Les faux positifs créent une fatigue des alertes, érodent la confiance dans les résultats des scans et détournent l'attention des véritables risques de sécurité.

GitLab 18.10 introduit la Secret false positive detection alimentée par l'IA (version bêta) pour se concentrer sur les secrets qui importent réellement. Lorsqu'un scan de sécurité s'exécute, GitLab Duo analyse automatiquement chaque vulnérabilité de détection des secrets de gravité **Critique** et **Niveau élevé** pour déterminer s'il s'agit d'un faux positif.

L'évaluation par l'IA apparaît directement dans le rapport de vulnérabilité, donnant aux ingénieurs de sécurité un contexte immédiat pour prendre des décisions de triage plus rapides et confiantes.

Les principales fonctionnalités incluent :

- Analyse automatique : la détection des faux positifs s'exécute automatiquement après chaque scan de sécurité sans déclenchement manuel.
- Option de déclenchement manuel : vous pouvez déclencher manuellement la détection des faux positifs pour des vulnérabilités individuelles sur la page de détails de la vulnérabilité pour une analyse à la demande.
- Focalisation sur les résultats à fort impact : limitée aux vulnérabilités de gravité **Critique** et **Niveau élevé** pour maximiser l'amélioration du rapport signal/bruit.
- Raisonnement contextuel de l'IA : chaque évaluation inclut une explication des raisons pour lesquelles le résultat peut ou non être un vrai positif, basée sur le contexte du code et les caractéristiques de la vulnérabilité.
- Score de confiance : chaque détection inclut un score de confiance pour aider les équipes à prioriser la révision en fonction de la certitude du modèle.
- Intégration fluide au workflow : les résultats apparaissent directement dans le rapport de vulnérabilité aux côtés des informations existantes sur la gravité, le statut et la remédiation.

Cette fonctionnalité est disponible en version bêta gratuite pour les clients Ultimate et doit être activée dans les paramètres de votre groupe ou projet. Partagez vos retours dans le [ticket 592861](https://gitlab.com/gitlab-org/gitlab/-/work_items/592861).

### Utiliser des entrées d'exécution avec les jobs CI/CD {#use-runtime-inputs-with-cicd-jobs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/jobs/job_inputs.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17833)

{{< /details >}}

L'utilisation de variables CI/CD pour la configuration dynamique des jobs peut s'avérer difficile. Les variables suivent une hiérarchie de substitution complexe difficile à gérer, et elles ne peuvent pas être utilisées pour de nombreux cas d'utilisation.

Vous pouvez désormais utiliser `inputs` pour définir des entrées explicites et typées au niveau du job. Utilisez les entrées de job pour définir et contrôler les valeurs qu'un job accepte au moment de l'exécution. Avec les entrées de job, vous bénéficiez de :

- Sécurité de type (string, number, boolean, array).
- Des valeurs par défaut qui peuvent être statiques ou référencer des variables existantes.
- L'option de définir une liste stricte de valeurs possibles à utiliser.
- Prise en charge des expressions régulières pour la validation des valeurs d'entrée.

Les entrées de job peuvent utiliser les valeurs par défaut sans aucune interaction utilisateur, mais vous pouvez modifier les valeurs lors de la réexécution d'un job ou de l'exécution d'un job manuel.

## Agentic Core {#agentic-core}

### GitLab Blob Search pour la recherche de code dans les groupes et les instances {#gitlab-blob-search-for-group-and-instance-code-search}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/duo_agent_platform/agents/tools.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/593221)

{{< /details >}}

L'outil [`[gitlab_blob_search](../../user/duo_agent_platform/agents/tools.md)`](../../user/duo_agent_platform/agents/tools.md) permet désormais aux agents d'IA GitLab de rechercher dans votre code :

- Dans tous les projets d'un groupe.
- Dans tous les projets accessibles sur une instance.

Auparavant, la recherche de blob était limitée à un seul projet ou nécessitait de spécifier des identifiants de projet explicites. Ce changement facilite la découverte et la réutilisation du code réparti sur plusieurs projets liés par les workflows alimentés par l'IA.

### Outil de serveur MCP GitLab pour la gestion des pipelines {#gitlab-mcp-server-tool-for-pipeline-management}

<!-- categories: MCP Server -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/gitlab_duo/model_context_protocol/mcp_server_tools.md#manage_pipeline) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)

{{< /details >}}

Vous pouvez désormais gérer vos pipelines CI/CD dans un projet GitLab avec le nouvel outil `manage_pipeline`. Cet outil de serveur MCP GitLab permet aux agents d'IA de créer, annuler, réessayer, supprimer et mettre à jour les métadonnées de pipeline en un seul appel. Avec cet outil, vous n'avez plus à assembler plusieurs étapes pour automatiser vos workflows de pipeline.

Si vous souhaitez voir d'autres outils de serveur MCP GitLab, faites-le nous savoir dans le [ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/work_items/566375).

### Les Maintainers de projet peuvent activer les agents personnalisés et les flows {#project-maintainers-can-enable-custom-agents-and-flows}

<!-- categories: AI Catalog -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/duo_agent_platform/flows/custom.md#enable-a-flow) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/590573)

{{< /details >}}

Auparavant, l'activation des agents d'IA et des flows depuis le catalogue d'IA nécessitait des autorisations de groupe principal.

Désormais, lors de la navigation dans le catalogue d'IA au niveau exploration ou au niveau projet, les Maintainers de projet peuvent activer des agents et des flows directement dans leurs projets.

### Configurer le contrôle d'accès réseau pour les flows distants dans les projets {#configure-network-access-control-for-remote-flows-in-projects}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/duo_agent_platform/environment_sandbox.md#configure-a-network-policy) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/593560)

{{< /details >}}

Vous pouvez désormais configurer des [contrôles d'accès réseau](../../user/duo_agent_platform/environment_sandbox.md) pour les flows utilisant des runners GitLab dans les projets.

Cela fournit des intégrations externes sécurisées, tout en maintenant le contrôle sur les destinations réseau. Cela donne également aux mainteneurs de projet la flexibilité d'autoriser les connexions API nécessaires, les serveurs MCP et les services tiers tout en appliquant des limites de sécurité.

Configurez les [contrôles d'accès réseau](../../user/duo_agent_platform/environment_sandbox.md) dans la section `network_policy` de `agent-config.yml`. Le fichier `agent-config.yml` est protégé par des règles de protection de branche et des workflows d'approbation de merge request.

### Vertex AI auto-hébergé pour GitLab Duo Agent Platform {#self-hosted-vertex-ai-for-gitlab-duo-agent-platform}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#configure-authentication-with-gemini-enterprise-agent-platform) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/591604)

{{< /details >}}

Vertex AI est désormais une plateforme LLM prise en charge dans GitLab Duo Agent Platform Self-Hosted.

Les clients peuvent désormais configurer des modèles Anthropic hébergés sur Vertex AI pour une utilisation avec les fonctionnalités de GitLab Duo Agent Platform.

### Les utilisateurs peuvent activer les agents et les flows directement depuis les projets {#users-can-enable-agents-and-flows-directly-from-projects}

<!-- categories: AI Catalog -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/duo_agent_platform/agents/custom.md#enable-an-agent) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/588012)

{{< /details >}}

Les Maintainers et les Owners peuvent désormais activer des agents et des flows directement depuis leur projet ou la page d'exploration, sans quitter leur contexte actuel.

Les Owners de groupes principaux peuvent également sélectionner leur groupe et les projets spécifiques où ils souhaitent activer des agents et des flows, simplifiant ainsi la configuration de leur workflow.

### Prise en charge des Agent Skills dans les IDE et les pipelines CI/CD {#support-for-agent-skills-in-ides-and-cicd-pipelines}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/duo_agent_platform/customize/agent_skills.md) \| [Ticket associé](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1984)

{{< /details >}}

GitLab Duo Agent Platform prend désormais en charge la [spécification Agent Skills](https://agentskills.io/specification), un standard émergent pour donner aux agents d'IA de nouvelles capacités et expertises.

Vous pouvez définir des Agent Skills au niveau du workspace pour votre projet afin de donner aux agents des connaissances spécialisées et des workflows pour des tâches spécifiques, comme l'écriture de tests dans un framework particulier. Les agents découvrent et chargent automatiquement les compétences pertinentes lorsqu'ils rencontrent des tâches correspondantes.

Vous pouvez également déclencher des compétences manuellement par nom, chemin de fichier ou commandes slash personnalisées. Les Agent Skills sont accessibles pour les flows et le Chat agentique dans votre IDE, et pour les flows exécutés dans des pipelines CI/CD. Ils fonctionnent également avec tout autre outil d'IA qui prend en charge la spécification.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Télécharger les données d'utilisation des crédits au format CSV {#download-credit-usage-data-as-csv}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../subscriptions/gitlab_credits.md#export-usage-data) \| [Ticket associé](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/14504)

{{< /details >}}

Les gestionnaires de facturation peuvent désormais télécharger les données d'utilisation des crédits sous forme de fichier CSV directement depuis le tableau de bord GitLab Credits dans le portail clients.

L'export fournit une ventilation quotidienne par action de la consommation de crédits pour le mois de facturation en cours, incluant les crédits d'engagement, de renonciation, d'essai, à la demande et inclus utilisés.

Les équipes financières et opérationnelles peuvent utiliser ces données pour effectuer l'allocation des coûts, les rapports de refacturation et l'analyse d'utilisation dans Excel, Google Sheets ou des outils de BI sans collecte manuelle de données ni demandes d'assistance.

### Lier l'utilisation des crédits aux sessions GitLab Duo Agent Platform {#link-credit-usage-to-gitlab-duo-agent-platform-sessions}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/579139)

{{< /details >}}

Le tableau de bord GitLab Credits lie désormais la consommation de crédits directement à la session GitLab Duo Agent Platform qui l'a générée.

Dans la vue détaillée par utilisateur, la colonne **Action** pour les lignes d'utilisation d'Agent Platform (telles que **Chat agentique** ou **Foundational Agents**) est désormais un lien hypertexte cliquable qui navigue vers les détails de la session correspondante.

Ce lien fournit une piste d'audit directe de la facturation au comportement des sessions d'IA, permettant aux administrateurs d'examiner l'utilisation des crédits, les escalades d'assistance et les révisions de conformité sans corréler manuellement les horodatages entre des systèmes distincts.

### Trier les utilisateurs dans le tableau de bord GitLab Credits {#sort-users-in-the-gitlab-credits-dashboard}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) \| [Ticket associé](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15608)

{{< /details >}}

Les administrateurs d'entreprise peuvent désormais trier le tableau **Usage by User** dans le tableau de bord GitLab Credits par total de crédits utilisés ou par nom d'utilisateur.

L'ordre de tri par défaut est par total de crédits consommés (le plus élevé en premier), de sorte que les principaux consommateurs sont immédiatement visibles sans faire défiler.

Avec cette vue, les administrateurs gérant des milliers d'utilisateurs de GitLab Duo peuvent rapidement identifier les personnes à forte consommation pour l'allocation des coûts, les rapports de refacturation et les audits d'utilisation des licences.

### Nouvelle expérience de navigation pour les projets dans Explorer {#new-navigation-experience-for-projects-in-explore}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/13786)

{{< /details >}}

Nous avons simplifié la page des projets dans **Explorer** pour réduire l'encombrement et supprimer les options redondantes qui s'étaient accumulées au fil du temps. L'interface simplifiée se concentre désormais sur deux vues principales :

- Onglet **Actif** : découvrez les projets avec une activité récente et un développement en cours.
- Onglet **Inactif** : accédez aux projets archivés et à ceux planifiés pour la suppression.

Nous avons supprimé plusieurs onglets redondants :

- Les projets **Most starred** peuvent être trouvés en triant les onglets **Actif** ou **Inactif** par nombre d'étoiles.
- **Tous** les projets sont disponibles en consultant les onglets **Actif** et **Inactif**.
- L'onglet **Trending** sera entièrement supprimé dans GitLab 19.0 en raison de fonctionnalités limitées et d'une faible utilisation.

Le design plus épuré s'aligne sur les autres listes de projets pour une cohérence visuelle. Vous pouvez toujours accéder à tout le même contenu grâce à une organisation plus logique et des options de tri flexibles.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Analyse des dépendances avec prise en charge SBOM pour les fichiers de build Java Gradle {#dependency-scanning-with-sbom-support-for-java-gradle-build-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/588788)

{{< /details >}}

L'analyse des dépendances GitLab via SBOM prend désormais en charge le scan des fichiers de build Java `build.gradle` et `build.gradle.kts`.

Auparavant, l'analyse des dépendances pour les projets Java utilisant Gradle nécessitait la présence d'un fichier de verrouillage. Désormais, lorsqu'un fichier de verrouillage n'est pas disponible, l'analyseur revient automatiquement au scan des fichiers `build.gradle` et `build.gradle.kts`, en extrayant et en rapportant uniquement les dépendances directes pour l'analyse des vulnérabilités. Cette amélioration facilite l'activation de l'analyse des dépendances pour les projets Java utilisant Gradle sans nécessiter de fichier de verrouillage.

Pour activer le repli sur le manifeste, définissez la variable CI/CD `DS_ENABLE_MANIFEST_FALLBACK` sur `"true"`.

### L'analyse des dépendances basée sur SBOM étendue aux instances auto-hébergées {#dependency-scanning-sbom-based-scanning-extended-to-self-managed}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/546429)

{{< /details >}}

Dans GitLab 18.10, nous étendons le statut de disponibilité limitée aux instances auto-hébergées pour la nouvelle fonctionnalité d'analyse des dépendances basée sur SBOM.

Cette fonctionnalité a été initialement publiée dans GitLab 18.5 avec une disponibilité limitée pour GitLab.com uniquement, derrière le feature flag `dependency_scanning_sbom_scan_api` et désactivée par défaut.

Grâce à des améliorations et des corrections supplémentaires, nous avons désormais la confiance nécessaire pour utiliser de manière fiable la nouvelle API interne de scan SBOM et activer ce feature flag par défaut. Cette API interne permet à l'analyseur d'analyse des dépendances de générer un rapport d'analyse des dépendances contenant toutes les vulnérabilités des composants. Contrairement au comportement précédent (version bêta) qui traitait les rapports SBOM après la complétion du pipeline CI/CD, [ce processus amélioré](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#how-it-scans-an-application) génère les résultats du scan immédiatement pendant le job CI/CD, donnant aux utilisateurs un accès instantané aux données de vulnérabilités pour les workflows personnalisés.

Les clients auto-hébergés qui rencontrent des problèmes peuvent désactiver le feature flag `dependency_scanning_sbom_scan_api`. L'analyseur reviendra alors au comportement précédent.

Pour utiliser cette fonctionnalité, importez le modèle d'analyse des dépendances v2 `Jobs/Dependency-Scanning.v2.gitlab-ci.yml`.

Nous accueillons avec plaisir vos retours sur cette fonctionnalité. Si vous avez des questions, des commentaires ou souhaitez échanger avec notre équipe, veuillez nous contacter dans ce [ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/issues/523458).

### Prise en charge du scan de licences pour les projets Dart/Flutter utilisant le gestionnaire de paquets Pub {#license-scanning-support-for-dartflutter-projects-using-pub-package-manager}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#data-sources) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/18351)

{{< /details >}}

GitLab prend désormais en charge le scan de licences pour les projets Dart et Flutter qui utilisent le gestionnaire de paquets `pub`. Auparavant, les équipes développant avec Dart ou Flutter ne pouvaient pas identifier les licences de leurs dépendances open source directement dans GitLab, créant des angles morts de conformité pour les organisations ayant des exigences de politique de licences.

Les données de licences sont directement extraites de [pub.dev](https://pub.dev), le dépôt officiel de paquets Dart, et les résultats sont affichés aux côtés des autres écosystèmes pris en charge. L'analyse des dépendances et la détection des vulnérabilités pour Dart/Flutter étaient déjà prises en charge.

### Prise en charge du registre de paquets Conan 2.0 (version bêta) {#conan-20-package-registry-support-beta}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/packages/conan_2_repository/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/585819)

{{< /details >}}

Les équipes de développement C et C++ utilisant Conan comme gestionnaire de paquets ont longtemps demandé la prise en charge d'un registre dans GitLab. Auparavant, le registre de paquets Conan était expérimental et ne prenait en charge que les clients Conan 1.x, limitant l'adoption pour les équipes ayant migré vers la chaîne d'outils moderne Conan 2.0.

Le registre de paquets Conan prend désormais en charge Conan 2.0 et a été promu de version expérimentale à version bêta. Cette release inclut une compatibilité complète avec l'API v2, la prise en charge des révisions de recettes, des capacités de recherche améliorées et une gestion appropriée des politiques de téléchargement, y compris le flag `--force`. Les équipes peuvent publier et installer des paquets Conan 2.0 directement depuis GitLab en utilisant les workflows client Conan standard, réduisant ainsi le besoin de solutions externes de gestion des artefacts comme JFrog Artifactory.

Avec cette mise à jour, les équipes d'ingénierie de plateforme gérant les dépendances C et C++ peuvent consolider leur gestion de paquets dans GitLab aux côtés de leur code source, de leurs pipelines CI/CD et de leur scan de sécurité. Le registre Conan prend en charge les endpoints au niveau projet et au niveau instance, et fonctionne avec les jetons d'accès personnel, les jetons de déploiement et les jetons de job CI/CD pour l'authentification.

Nous accueillons vos retours pendant que nous travaillons à la disponibilité générale. Partagez votre expérience dans l'[epic](https://gitlab.com/groups/gitlab-org/-/work_items/6816).

### Gérer les registres de conteneurs virtuels avec une interface dédiée (version bêta) {#manage-container-virtual-registries-with-a-dedicated-ui-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/packages/virtual_registry/container/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/19283)

{{< /details >}}

Lorsque le registre de conteneurs virtuel a été lancé en version bêta lors du dernier jalon, les ingénieurs de plateforme pouvaient agréger plusieurs registres de conteneurs amont — Docker Hub, Harbor, Quay et autres — derrière un seul point de terminaison de tirage. Cependant, toute configuration nécessitait des appels API directs, ce qui signifiait que les équipes devaient maintenir des scripts ou des commandes curl manuelles pour créer et gérer leurs registres, configurer les sources amont et gérer les modifications au fil du temps. Cela ajoutait une surcharge opérationnelle et rendait la fonctionnalité inaccessible aux utilisateurs qui n'étaient pas à l'aise pour travailler directement avec l'API.

Les registres de conteneurs virtuels peuvent désormais être créés et gérés directement depuis l'interface GitLab. Depuis la page du registre de conteneurs au niveau groupe, vous pouvez créer de nouveaux registres virtuels, configurer des sources amont avec des identifiants d'authentification, modifier les configurations existantes et supprimer les registres dont vous n'avez plus besoin — tout cela sans quitter GitLab ni écrire un seul appel API. L'interface s'intègre parfaitement à l'expérience de registre de conteneurs existante, faisant des registres virtuels une partie intégrante du workflow de gestion des artefacts de votre groupe.

Cette fonctionnalité est en version bêta. Pour partager vos retours, veuillez commenter dans le [ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/work_items/589630).

### Le registre Helm Chart GitLab est généralement disponible {#gitlab-helm-chart-registry-generally-available}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/packages/helm_repository/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/573715)

{{< /details >}}

Les équipes utilisant Helm pour gérer les déploiements d'applications Kubernetes peuvent désormais s'appuyer sur le registre GitLab Helm Chart pour les charges de travail en production. Précédemment en version bêta, le registre est désormais généralement disponible à la suite de la résolution des principales préoccupations architecturales et de fiabilité.

Le chemin vers la disponibilité générale a inclus la résolution d'une limite stricte qui empêchait le point de terminaison `index.yaml` de renvoyer plus de 1 000 charts, la correction d'un bug d'indexation en arrière-plan qui causait l'absence des nouvelles versions de charts publiées dans l'index, la réalisation d'une révision complète de sécurité AppSec, et l'ajout de la prise en charge de la réplication Geo pour le cache de métadonnées Helm, assurant une haute disponibilité pour les clients auto-hébergés exécutant GitLab Geo.

Les équipes Platform et DevOps peuvent publier et installer des charts Helm directement depuis GitLab en utilisant les workflows client Helm standard, avec prise en charge des endpoints au niveau projet et authentification via des jetons d'accès personnel, des jetons de déploiement et des jetons de job CI/CD. Vous pouvez maintenant conserver les charts aux côtés du code source, des pipelines et du scan de sécurité qui en dépendent.

### Prise en charge des éléments de tâche dans les tableaux Markdown {#task-item-support-in-markdown-tables}

<!-- categories: Markdown -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/markdown.md#task-lists-in-tables) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/21506)

{{< /details >}}

Vous pouvez désormais utiliser la syntaxe de case à cocher d'élément de tâche directement dans les cellules de tableaux Markdown.

Auparavant, y parvenir nécessitait une combinaison de HTML brut et de Markdown, ce qui était fastidieux et difficile à maintenir.

Cette amélioration facilite le suivi de l'avancement des tâches directement dans des mises en page de tableaux structurés dans les tickets, les epics et autres contenus.

### Détection des secrets par pipeline dans les profils de configuration de sécurité {#pipeline-secret-detection-in-security-configuration-profiles}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/configuration/security_configuration_profiles.md)

{{< /details >}}

Dans GitLab 18.9, nous avons introduit des profils de configuration de sécurité avec le profil **Secret Detection - Default**, en commençant par la protection push. Vous utilisez le profil pour appliquer un scan de secrets standardisé à des centaines de projets sans toucher à un seul fichier de configuration CI/CD.

Le profil **Secret Detection - Default** couvre désormais également le scan basé sur les pipelines, fournissant une surface de contrôle unifiée pour la détection des secrets dans l'ensemble de votre workflow de développement.

Le profil active trois déclencheurs de scan :

- **Push Protection** : scanne tous les événements Git push et bloque les push où des secrets sont détectés, empêchant les secrets d'entrer dans votre base de code.
- **Pipelines de merge request** : exécute automatiquement un scan chaque fois que de nouveaux commits font l'objet d'un push vers une branche avec une merge request ouverte. Les résultats n'incluent que les nouvelles vulnérabilités introduites par la merge request.
- **Pipelines de branche (par défaut seulement)** : s'exécute automatiquement lorsque des modifications sont fusionnées ou poussées vers la branche par défaut, fournissant une vue complète de la posture de détection des secrets de votre branche par défaut.

L'application du profil ne nécessite aucune configuration YAML. Le profil peut être appliqué à un groupe pour propager la couverture à tous les projets du groupe, ou à des projets individuels pour un contrôle plus granulaire.

### Image de job macOS Tahoe 26 et Xcode 26 {#macos-tahoe-26-and-xcode-26-job-image}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/macos.md) \| [Epic associé](https://gitlab.com/groups/gitlab-com/gl-infra/-/work_items/1694)

{{< /details >}}

Vous pouvez désormais créer, tester et déployer des applications pour les dernières générations d'appareils Apple en utilisant macOS Tahoe 26 et Xcode 26.

Avec les [runners hébergés sur macOS](../../ci/runners/hosted_runners/macos.md), vos équipes de développement peuvent créer et déployer des applications macOS plus rapidement dans un environnement de build sécurisé et à la demande, intégré à GitLab CI/CD.

Essayez-le dès aujourd'hui en utilisant l'image `macos-26-xcode-26` dans votre fichier `.gitlab-ci.yml`.

### GitLab Runner 18.10 {#gitlab-runner-1810}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](https://docs.gitlab.com/runner/)

{{< /details >}}

Nous publions également GitLab Runner 18.10 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Permettre au runner k8s de définir des ressources au niveau Pod pour le pod de build](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39085)
- [Ajouter une automatisation pour mettre à jour les versions et packages Go pour tous les projets Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39192)

#### Corrections de bugs {#bug-fixes}

- [Le cache S3 avec RoleARN renvoie 403 au lieu de 404 pour un cache inexistant](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39105)
- [L'utilisation de l'image helper `gitlab-runner-helper:x86_64-v16.11.1-nanoserver21H2` entraîne une erreur `init-permissions`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37872)
- [MacOS : LaunchAgent - Le service n'a pas pu s'initialiser sur l'architecture M1](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/28136)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.10)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
