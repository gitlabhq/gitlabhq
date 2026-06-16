---
stage: Release Notes
group: Monthly Release
date: 2026-05-21
title: GitLab 19.0
description: GitLab 19.0 publié avec des instructions de revue personnalisées au niveau du groupe pour GitLab Duo
---

Le 21 mai 2026, GitLab 19.0 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également annoncer le [Contributeur notable](https://contributors.gitlab.com/notable-contributors) de ce mois-ci :  Norman Debald !

Nous sommes ravis de saluer [Norman](https://gitlab.com/Modjo85), un contributeur de niveau 3 avec plus de 40 améliorations fusionnées dans GitLab depuis son arrivée en mai 2022.

<!-- Copy this template, and paste it into the doc section where it belongs:

Primary feature, Agentic Core, Scale and Deployments, or Unified DevOps and Security.

Update all the information as needed.

### Feature explanation here

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Now write 125 words or fewer to explain the value of this improvement.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."

Use present tense, and speak about "you" instead of "the user."
-->

## Fonctionnalités principales {#primary-features}

### Instructions de revue personnalisées au niveau du groupe pour GitLab Duo {#group-level-custom-review-instructions-for-gitlab-duo}

<!-- categories: Duo Code Review -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires :  GitLab Duo Enterprise
- Liens :  [Documentation](../../user/gitlab_duo/customize_duo/review_instructions.md#configure-custom-review-instructions-for-a-group), [Ticket associé](https://gitlab.com/groups/gitlab-org/-/work_items/21504)

{{< /details >}}

Dans les versions précédentes de GitLab, vous ne pouviez définir des instructions de revue personnalisées pour GitLab Duo qu'au niveau du projet. Les équipes travaillant sur de nombreux projets dans le même groupe devaient dupliquer les mêmes instructions dans chaque projet.

Vous pouvez désormais configurer des instructions de revue personnalisées partagées pour un groupe entier et ses sous-groupes.

Sélectionnez un projet dans votre groupe à utiliser comme modèle. Lorsque GitLab Duo effectue une revue de code, il combine le fichier `.gitlab/duo/mr-review-instructions.yaml` au niveau du groupe avec toutes les instructions définies dans le projet individuel.

Le flow Code Review et GitLab Duo Code Review prennent tous deux en charge les instructions personnalisées au niveau du groupe.

### Configurer les types d'éléments de travail {#configure-work-item-types}

<!-- categories: Team Planning -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../user/work_items/configurable_work_item_types.md), [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/9365)

{{< /details >}}

Auparavant, les types d'éléments de travail pouvaient être soit un **Ticket**, soit une **Tâche**. Vous pouvez désormais configurer des types d'éléments de travail personnalisés dans un projet pour correspondre à la façon dont votre équipe planifie et suit le travail.

Vous pouvez créer ou renommer des types en **User Story**, **Bug** ou **Maintenance**. Chaque élément de travail s'affiche avec son nom de type et une icône unique. Les nouveaux types prennent en charge les champs personnalisés et les cycles de vie de statut, et apparaissent dans vos vues enregistrées et vos tableaux des tickets. La configuration des types dans le groupe principal (GitLab.com) ou l'organisation (GitLab Self-Managed) se propage à tous les projets.

Vous pouvez également contrôler les types disponibles pour chaque projet. Activez ou désactivez un type sur tous les projets à la fois, ou laissez les projets individuels gérer leur propre visibilité de type. Lorsque vous désactivez un type dans un projet, les éléments de travail existants ne sont pas affectés.

### GitLab Secrets Manager désormais disponible en bêta ouverte {#gitlab-secrets-manager-now-available-in-open-beta}

<!-- categories: Secrets Management -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed
- Liens :  [Documentation](../../ci/secrets/secrets_manager/_index.md), [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/21731)

{{< /details >}}

Dans les versions précédentes de GitLab, le GitLab Secrets Manager n'était disponible que pour un groupe fermé de bêta-testeurs. La plupart des équipes s'appuyaient sur des services externes tels que HashiCorp Vault ou AWS Secrets Manager.

Le GitLab Secrets Manager est désormais disponible en bêta ouverte pour les clients Premium et Ultimate sur GitLab.com et GitLab Self-Managed. Lorsque le GitLab Secrets Manager est activé, les propriétaires de projets et de groupes peuvent stocker, récupérer et référencer des secrets CI/CD dans GitLab. Les secrets sont limités à un projet ou un groupe et ne sont accessibles qu'aux jobs de pipeline qui les demandent explicitement.

Pendant la bêta ouverte, le GitLab Secrets Manager suit la [politique de support bêta](../../policy/development_stages_support.md#beta) et peut ne pas être prêt pour une utilisation en production.

Pour partager vos commentaires, consultez le [ticket 598100](https://gitlab.com/gitlab-org/gitlab/-/issues/598100).

### Améliorations de GitLab Duo Developer pour les workflows de merge request {#gitlab-duo-developer-enhancements-for-merge-request-workflows}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../user/duo_agent_platform/flows/foundational_flows/developer.md), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817)

{{< /details >}}

GitLab Duo Developer prend désormais en charge plusieurs méthodes de déclenchement : assignez-le à un ticket, sélectionnez **Generate MR**, ou utilisez `@mention` dans n'importe quel fil de discussion de ticket ou de merge request pour transformer les retours, les éléments de la liste de tâches et les questions de conception en modifications de code, merge requests de suivi ou résumés de recherche.

Avec `AGENTS.md` et `agent-config.yml` configurés, GitLab Duo Developer exécute vos tests et vérifications avant de faire un commit. Après qu'un administrateur de groupe principal ou d'instance active le flow Developer, GitLab ajoute automatiquement des déclencheurs de mention et d'assignation aux projets éligibles.

### Analyse des dépendances par SBOM disponible en disponibilité générale {#dependency-scanning-by-using-sbom-generally-available}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md), [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20456)

{{< /details >}}

L'analyseur de dépendances basé sur SBOM de GitLab est désormais disponible en disponibilité générale. Les projets Maven, Gradle et Python disposent désormais d'une visibilité complète sur les vulnérabilités dans l'ensemble de leur arbre de dépendances, y compris les packages vulnérables introduits de manière transitive, et pas seulement ceux déclarés directement.

L'analyseur inclut désormais la résolution automatique des dépendances pour les projets Maven, Gradle et Python. Lorsqu'un fichier de verrouillage ou un graphe de dépendances résolu n'est pas présent, l'analyseur invoque automatiquement des outils pour résoudre le graphe de dépendances transitif complet avant l'analyse. La résolution des dépendances est activée par défaut et nécessite peu ou pas de configuration supplémentaire au-delà de l'inclusion du modèle Dependency Scanning v2.

Pour les projets où la résolution des dépendances n'est pas possible, l'analyseur bascule vers l'analyse de manifeste. Il analyse `pom.xml`, `requirements.txt`, `build.gradle` et `build.gradle.kts` pour identifier les dépendances directes. L'analyse de manifeste garantit que les équipes disposent toujours d'un point de départ pour la couverture des vulnérabilités, même pour les projets sans fichiers de verrouillage ou de build.

L'analyse de manifeste est activée par défaut et renvoie uniquement les dépendances directes. Pour une couverture transitive complète, activez la résolution des dépendances ou fournissez manuellement un fichier de verrouillage de dépendances ou un export de graphe.

## Agentic Core {#agentic-core}

### GitLab Duo Core passe à la facturation basée sur l'usage {#gitlab-duo-core-moves-to-usage-based-billing}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../subscriptions/subscription-add-ons.md#gitlab-duo-core), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/600144)

{{< /details >}}

À partir de GitLab 19.0, GitLab Duo Core passe à la facturation basée sur l'usage. Les suggestions de code dans le Web IDE et les IDE de bureau consomment désormais des [GitLab Credits](../../subscriptions/gitlab_credits.md).

GitLab Duo Chat évolue également. Pour les utilisateurs de GitLab Duo Core, Chat est désormais agentique et fonctionne sur GitLab Duo Agent Platform. Pour utiliser GitLab Duo Chat dans l'interface GitLab ou les IDE de bureau, activez GitLab Duo Agent Platform pour votre instance ou votre groupe principal.

### Filtrer les résultats de recherche de code exacte par dépôt {#filter-exact-code-search-results-by-repository}

<!-- categories: Global Search -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed
- Liens :  [Documentation](../../user/search/exact_code_search.md#syntax), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/488467)

{{< /details >}}

Vous pouvez désormais filtrer les résultats de recherche de code exacte par dépôt. Avec la syntaxe `repo:`, vous pouvez définir directement la portée de votre requête de recherche sur des dépôts ou des modèles de dépôts spécifiques sans avoir à accéder aux projets individuels.

Par exemple, rechercher `def authenticate repo:my-group/my-project` renvoie des résultats uniquement depuis ce dépôt. Vous pouvez également utiliser des chemins partiels ou des modèles pour correspondre à plusieurs dépôts.

### Déclencheur d'événement « merge request prête » {#merge-request-ready-event-trigger}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed
- Liens :  [Documentation](../../user/duo_agent_platform/triggers/_index.md), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454)

{{< /details >}}

Vous pouvez désormais configurer des flows et des agents externes pour s'exécuter sur l'événement **Merge request ready**.

Lorsqu'une merge request en brouillon est marquée comme prête pour la revue, GitLab Duo exécute automatiquement le flow ou l'agent externe.

Pour configurer un déclencheur, accédez à **IA** > **Déclencheurs** dans votre projet.

Cette fonctionnalité est protégée par le feature flag `merge_request_ready_flow_trigger`, désactivé par défaut.

### Claude Opus 4.7 désormais disponible dans GitLab Duo Agent Platform {#claude-opus-47-now-available-in-gitlab-duo-agent-platform}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../user/duo_agent_platform/model_selection.md#supported-models), [Ticket associé](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2177)

{{< /details >}}

Claude Opus 4.7 est désormais disponible dans GitLab Duo Agent Platform. Opus 4.7 apporte des améliorations significatives pour les tâches complexes à plusieurs étapes qui nécessitent un raisonnement soutenu, le suivi précis des instructions et une auto-vérification avant de présenter les résultats. Cela inclut les flows prenant en charge les pipelines CI/CD, la revue de code, la résolution de vulnérabilités, et plus encore.

### Prise en charge des modèles Gemini auto-hébergés {#support-for-self-hosted-gemini-models}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models), [Ticket associé](https://gitlab.com/groups/gitlab-org/-/work_items/21186)

{{< /details >}}

GitLab Duo Agent Platform Self-Hosted est désormais compatible avec les modèles Gemini. Les modèles Gemini prennent en charge plusieurs flows, notamment le flow Code Review, le flow SAST Vulnerability Resolution, le flow Fix CI/CD Pipeline, et plus encore.

### Prise en charge élargie des modèles open source dans GitLab Duo Agent Platform {#expanded-open-source-model-support-in-gitlab-duo-agent-platform}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models), [Ticket associé](https://gitlab.com/groups/gitlab-org/-/work_items/21186)

{{< /details >}}

GitLab Duo Agent Platform prend désormais en charge des modèles open source supplémentaires pour les déploiements auto-hébergés, notamment Devstral 2 123B, GLM-5.1-FP8 et d'autres. Cela permet aux clients d'alimenter des workflows agentiques dans divers environnements, y compris les déploiements hors ligne et à accès réseau restreint.

### Approbations d'outils par session avec contrôles d'administration {#per-session-tool-approvals-with-admin-controls}

<!-- categories: Duo Agent Platform, Duo Chat -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/596366)

{{< /details >}}

Avant que GitLab Duo Agentic Chat puisse utiliser un outil en votre nom, votre approbation est requise. Chaque invocation d'outil nécessite une approbation distincte.

Désormais, vous pouvez approuver un outil de confiance une seule fois pour toute une session et simplifier vos workflows.

Les administrateurs contrôlent si l'approbation d'outil pour les sessions est disponible. Les paramètres suivants se propagent de l'instance au groupe, puis au projet :

- **Activé(e) par défaut**
- **Désactivé(e) par défaut**
- **Toujours désactivée**

Les groupes et sous-groupes peuvent modifier le paramètre, sauf si un administrateur le définit sur **Toujours désactivée**.

Le paramètre par défaut est **Désactivé(e) par défaut**, ce qui garantit que chaque invocation d'outil nécessite une approbation explicite, à moins qu'un administrateur ne le modifie.

### Résoudre les conflits de merge avec GitLab Duo (Bêta) {#resolve-merge-conflicts-with-gitlab-duo-beta}

<!-- categories: Duo Agent Platform, Code Review Workflow -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../user/project/merge_requests/conflicts.md#resolve-conflicts-with-gitlab-duo), [Ticket associé](https://gitlab.com/groups/gitlab-org/-/work_items/20688)

{{< /details >}}

Dans les versions précédentes de GitLab, vous deviez résoudre les conflits de merge manuellement dans l'interface GitLab ou depuis la ligne de commande, même pour les cas simples.

Désormais, GitLab Duo peut analyser de manière autonome les conflits de merge, modifier les fichiers en conflit, créer un commit et pousser vers la branche source. Déclenchez la résolution des conflits depuis la page **Résoudre les conflits** ou directement depuis le widget de merge request. Une fois terminé, GitLab Duo publie un commentaire de résumé afin que les relecteurs puissent voir ce qui a changé.

GitLab Duo respecte les règles de protection des branches et n'effectue pas de push forcé vers les branches protégées.

Cette fonctionnalité est en bêta et est protégée par le feature flag `mr_ai_resolve_conflicts`, désactivé par défaut.

### Restreindre le catalogue d'IA à une hiérarchie de groupes {#restrict-the-ai-catalog-to-a-group-hierarchy}

<!-- categories: AI Catalog -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../user/duo_agent_platform/ai_catalog.md#restrict-the-ai-catalog-to-a-group-hierarchy), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/594617)

{{< /details >}}

Les propriétaires de groupe principal peuvent désormais restreindre le catalogue d'IA pour n'afficher que les agents et flows appartenant aux projets de leur hiérarchie de groupes. Cela empêche les agents, les agents externes ou les flows qui ne font pas partie de cette hiérarchie d'être visibles ou activés par un utilisateur de ce groupe.

### Acheter des crédits avec le niveau Free sur GitLab Self-Managed {#purchase-credits-on-the-free-tier-on-gitlab-self-managed}

<!-- categories: Subscription Management -->

{{< details >}}

- Niveau :  Free
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](../../subscriptions/gitlab_credits.md#buy-gitlab-credits), [Ticket associé](https://gitlab.com/groups/gitlab-org/-/work_items/20165)

{{< /details >}}

Les utilisateurs du niveau Free sur GitLab Self-Managed peuvent désormais accéder à toute la puissance de GitLab Duo Agent Platform, sans abonnement Premium ou Ultimate requis. Choisissez votre montant de crédits mensuel, engagez-vous sur une durée annuelle et obtenez un accès instantané aux outils de développement alimentés par l'IA. Les crédits se renouvellent automatiquement chaque mois, afin que votre équipe dispose toujours de ce dont elle a besoin pour développer plus rapidement et plus intelligemment.

### Contrôles d'accès réseau définis par l'administrateur pour les flows distants d'Agent Platform {#admin-defined-network-access-controls-for-agent-platform-remote-flows}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../user/duo_agent_platform/environment_sandbox.md#configure-a-network-policy), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/593149)

{{< /details >}}

Les administrateurs peuvent désormais définir des politiques réseau centralisées pour les flows distants de GitLab Duo Agent Platform directement dans les paramètres. Les administrateurs de groupe principal sur GitLab.com, et les administrateurs d'instance sur GitLab Self-Managed et Dedicated, peuvent configurer des listes de blocage et des listes d'autorisation de domaines à l'échelle de l'organisation que les projets héritent automatiquement. Un paramètre supplémentaire contrôle si les projets peuvent étendre la liste des domaines approuvés avec des entrées personnalisées. Les politiques sont appliquées au moment de l'exécution sur tous les flows distants, offrant aux équipes de sécurité et de plateforme une couche de gouvernance cohérente pour les sorties réseau des agents.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Exigence minimale de PostgreSQL 17 {#postgresql-17-minimum-requirement}

<!-- categories: Omnibus Package -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](../../administration/package_information/postgresql_versions.md), [Ticket associé](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9792)

{{< /details >}}

La version minimale prise en charge de PostgreSQL est désormais la version 17. Si vous utilisez PostgreSQL 16 inclus dans le package, [mettez à niveau le serveur PostgreSQL inclus](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server) avant d'installer GitLab 19.0.

### Prise en charge du package Linux pour Ubuntu 20.04 abandonnée {#linux-package-support-for-ubuntu-2004-discontinued}

<!-- categories: Omnibus Package -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](../../install/package/_index.md#supported-platforms), [Ticket associé](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8915)

{{< /details >}}

Ubuntu 20.04 a atteint la fin du support standard en mai 2025. À partir de GitLab 19.0, les packages Linux ne sont plus fournis pour Ubuntu 20.04. GitLab 18.11 est la dernière release avec des packages pour cette distribution. Avant de mettre à niveau vers GitLab 19.0, migrez vers Ubuntu 22.04 ou un autre [système d'exploitation pris en charge](../../install/package/_index.md#supported-platforms).

### Prise en charge de Redis 6 supprimée {#redis-6-support-removed}

<!-- categories: Omnibus Package -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](../../install/requirements.md), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839)

{{< /details >}}

La prise en charge de Redis 6 est supprimée dans GitLab 19.0. Si vous utilisez un déploiement Redis 6 externe, migrez vers Redis 7.2 ou Valkey 7.2 avant la mise à niveau. Le Redis inclus dans le package Linux utilise Redis 7 depuis GitLab 16.2 et n'est pas affecté.

### Mattermost supprimé du package Linux {#mattermost-removed-from-the-linux-package}

<!-- categories: Omnibus Package -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/590798)

{{< /details >}}

Mattermost inclus est supprimé du package Linux dans GitLab 19.0. Si vous utilisez actuellement Mattermost inclus, consultez [Migration du package Linux vers Mattermost Standalone](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html) pour obtenir des instructions de migration. Les clients n'utilisant pas Mattermost inclus ne sont pas impactés.

### Prise en charge du package Linux pour les distributions SUSE abandonnée {#linux-package-support-for-suse-distributions-discontinued}

<!-- categories: Omnibus Package -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](../../install/docker/installation.md), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/590801)

{{< /details >}}

La prise en charge du package Linux pour les distributions SUSE prend fin dans GitLab 19.0, ce qui affecte openSUSE Leap 15.6, SUSE Linux Enterprise Server 12.5 et SUSE Linux Enterprise Server 15.6. GitLab 18.11 est la dernière version avec des packages Linux pour ces distributions. Pour continuer à utiliser les distributions SUSE, migrez vers un [déploiement Docker de GitLab](../../install/docker/installation.md).

### Spamcheck supprimé du package Linux et du chart Helm GitLab {#spamcheck-removed-from-linux-package-and-gitlab-helm-chart}

<!-- categories: Omnibus Package, Cloud Native Installation -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](../../administration/reporting/spamcheck.md), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/590796)

{{< /details >}}

[Spamcheck](../../administration/reporting/spamcheck.md) est supprimé du package Linux et du chart Helm GitLab dans GitLab 19.0. Les clients n'utilisant pas actuellement Spamcheck ne sont pas impactés. Si vous utilisez Spamcheck inclus, vous pouvez le déployer séparément en utilisant [Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck). Aucune migration de données n'est requise.

### NGINX Ingress remplacé par Gateway API avec Envoy Gateway {#nginx-ingress-replaced-by-gateway-api-with-envoy-gateway}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](https://docs.gitlab.com/charts/), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/590800)

{{< /details >}}

Gateway API avec Envoy Gateway devient la configuration réseau par défaut dans le chart Helm GitLab dans GitLab 19.0, remplaçant NGINX Ingress qui a atteint sa fin de vie en mars 2026. Si la migration vers Envoy Gateway n'est pas immédiatement réalisable, vous pouvez réactiver explicitement le NGINX Ingress inclus, qui reste disponible jusqu'à sa suppression prévue dans GitLab 20.0. Cette modification n'affecte pas le NGINX utilisé dans le package Linux, ni les instances de chart Helm utilisant un Ingress géré en externe ou un contrôleur Gateway API.

### PostgreSQL, Redis et MinIO inclus supprimés du chart Helm GitLab {#bundled-postgresql-redis-and-minio-removed-from-gitlab-helm-chart}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed
- Liens :  [Documentation](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/590797)

{{< /details >}}

Les charts Bitnami PostgreSQL, Bitnami Redis et MinIO inclus sont supprimés du chart Helm GitLab et de l'opérateur GitLab dans GitLab 19.0 sans remplacement. Ces composants étaient destinés uniquement aux environnements de preuve de concept et de test et ne sont pas recommandés pour une utilisation en production. Si vous exécutez une instance avec l'un de ces services inclus, suivez le [guide de migration](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/) pour configurer des services externes avant de mettre à niveau vers GitLab 19.0.

### Déprovisionnement fiable des utilisateurs SCIM pour les grands groupes {#reliable-scim-user-deprovisioning-for-large-groups}

<!-- categories: User Management -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com
- Liens :  [Documentation](../../development/internal_api/_index.md#group-scim-api), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/521324)

{{< /details >}}

Pour les organisations gérant un grand nombre d'utilisateurs via SCIM, le déprovisionnement des membres du groupe pouvait expirer et renvoyer des erreurs `500`. Les requêtes SCIM `DELETE` et `PATCH` renvoient désormais immédiatement une réponse de succès. La suppression des membres est gérée de manière asynchrone, de sorte que les fournisseurs d'identité et les clients SCIM reçoivent des réponses de succès cohérentes.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Remédiation automatique pour les dépendances vulnérables (Expérience) {#auto-remediation-for-vulnerable-dependencies-experiment}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com
- Liens :  [Documentation](../../user/application_security/remediate/auto_remediation.md), [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/17403)

{{< /details >}}

La remédiation automatique pour les dépendances est désormais disponible en tant qu'expérience dans GitLab 19.0. Lorsque l'analyse des dépendances détecte une dépendance Ruby vulnérable avec un correctif connu, GitLab ouvre automatiquement une merge request pour la mettre à jour vers une version sûre sans intervention humaine. Seuls les projets Ruby sont pris en charge dans l'expérience.

Après chaque pipeline, GitLab identifie la vulnérabilité de la plus haute gravité avec un correctif ou une mise à niveau de version mineure disponible. GitLab génère la modification du fichier manifeste et ouvre une merge request via un compte de service. La merge request passe ensuite par le workflow standard de revue et d'approbation de votre projet.

Pendant l'expérience, jusqu'à trois merge requests de remédiation automatique peuvent être ouvertes par projet à la fois.

Pour partager vos commentaires ou demander à participer à l'expérience, laissez un commentaire sur [l'epic 600511](https://gitlab.com/gitlab-org/gitlab/-/work_items/600511). Pour activer l'expérience sur votre projet, un membre de l'équipe GitLab doit activer le feature flag `dependency_management_auto_remediation` pour votre projet.

### Analyse des dépendances dans les profils de configuration de sécurité {#dependency-scanning-in-security-configuration-profiles}

<!-- categories: Security Testing Configuration -->

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens :  [Documentation](../../user/application_security/configuration/security_configuration_profiles.md), [Ticket associé](https://gitlab.com/groups/gitlab-org/-/work_items/19952)

{{< /details >}}

GitLab 18.11 a introduit des profils de configuration de sécurité pour SAST et la détection des secrets. Désormais, l'analyse des dépendances est également disponible avec le profil **Dependency Scanning - Default**. Ce profil vous offre une surface de contrôle unifiée pour appliquer une couverture SCA standardisée à tous vos projets sans modifier un seul fichier de configuration CI/CD.

Le profil active deux déclencheurs d'analyse :

- **Merge Request Pipelines** :  Exécute automatiquement une analyse de dépendances à chaque fois que de nouveaux commits sont poussés vers une branche avec une merge request ouverte. Les résultats incluent uniquement les nouvelles vulnérabilités introduites par la merge request.
- **Branch Pipelines (default only)** :  S'exécute automatiquement lorsque des modifications sont fusionnées ou poussées vers la branche par défaut, offrant une vue complète de la posture des dépendances de votre branche par défaut.

### Résolution des dépendances pour l'analyse SBOM Gradle {#dependency-resolution-for-gradle-sbom-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens :  [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#dependency-resolution) | [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/590734)

{{< /details >}}

L'analyse des dépendances GitLab utilisant SBOM génère désormais automatiquement un graphe de dépendances (`gradle.graph.txt`) pour les projets Gradle. Auparavant, l'analyse des dépendances Gradle nécessitait que vous génériez manuellement un graphe de dépendances dans le cadre de votre build. Désormais, lorsqu'un fichier de graphe n'est pas disponible, l'analyseur en génère un automatiquement, supprimant cette étape manuelle pour les projets Java et Kotlin utilisant Gradle.

### Prise en charge améliorée des tableaux pour les entrées CI/CD {#improved-array-support-for-cicd-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens :  [Documentation](../../ci/inputs/_index.md#access-individual-array-elements), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/587657)

{{< /details >}}

Les entrées CI/CD disposent désormais d'une meilleure prise en charge des tableaux. Utilisez l'opérateur d'index de tableau `[]` pour accéder à des éléments spécifiques dans les entrées CI/CD de type tableau. Cette amélioration offre des capacités d'interpolation d'entrées CI/CD plus flexibles et plus puissantes dans vos configurations de pipeline, vous permettant de référencer directement des éléments individuels d'un tableau sans étapes de traitement supplémentaires.

### Sélectionner plusieurs valeurs pour les entrées CI/CD de pipeline {#select-multiple-values-for-pipeline-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens :  [Documentation](../../ci/inputs/_index.md#array-inputs-with-options), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/566155)

{{< /details >}}

Auparavant, vous ne pouviez sélectionner qu'une seule valeur lors de la sélection des options d'entrée CI/CD dans l'interface, ce qui limitait la flexibilité pour les pipelines avec des options plus complexes.

Désormais, lorsque vous exécutez un pipeline avec des entrées CI/CD depuis l'interface, vous pouvez sélectionner plusieurs valeurs dans une liste déroulante et les valeurs sélectionnées sont combinées dans un tableau, par exemple `["option1","option2"]`. Cela facilite le redémarrage de services sur plusieurs instances, la création de plusieurs images Docker, l'exécution de tests avec plusieurs combinaisons de tags ou toute opération sur plusieurs cibles dans une seule exécution de pipeline.

### Analyse détaillée de l'utilisation des composants CI/CD du catalogue CI/CD {#detailed-cicd-catalog-component-usage-analytics}

<!-- categories: Component Catalog -->

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../ci/components/_index.md#view-component-usage-details), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/579460)

{{< /details >}}

Lorsque vous gérez un composant CI/CD dans le catalogue CI/CD GitLab, les détails d'utilisation sont essentiels pour gérer les mises à niveau, appliquer la conformité et communiquer les changements non rétrocompatibles. Vous devez savoir quels projets utilisent vos composants CI/CD et quelles versions ils utilisent. Auparavant, ces informations n'étaient pas disponibles, ce qui rendait difficile la notification des bons mainteneurs, la planification des dépréciations en toute sécurité ou la garantie que les projets restent à jour avec les derniers correctifs de sécurité.

La vue des détails d'utilisation des composants CI/CD dans la page des ressources du catalogue affiche désormais exactement quels projets utilisent chaque composant CI/CD, la version qu'ils exécutent et s'ils disposent de la dernière version ou d'une version obsolète. Les projets utilisant des versions plus anciennes sont mis en avant, afin que vous puissiez prioriser la communication, encourager l'adoption des correctifs de sécurité et assurer une mise à niveau en douceur dans toute votre organisation.

### Configurer les limites de pipelines parallèles pour les merge trains {#configure-parallel-pipeline-limits-for-merge-trains}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../administration/instance_limits.md#merge-train-parallel-pipeline-limit), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/374188)

{{< /details >}}

Dans les versions précédentes de GitLab, vous ne pouviez pas modifier le maximum de 20 pipelines parallèles dans un merge train, ce qui vous forçait soit à surcharger vos runners, soit à abandonner complètement les merge trains. Vous pouvez désormais configurer la limite de pipelines parallèles par merge train pour équilibrer la charge des runners et le débit de fusion. Vous pouvez définir la limite par projet ou à l'échelle de l'instance. Définir la limite à 1 signifie que chaque merge request s'exécute une à la fois, par rapport à une branche cible propre.

Merci à [Norman Debald (@Modjo85)](https://gitlab.com/Modjo85) pour cette contribution communautaire.

### Personnaliser les titres de merge request par défaut {#customize-default-merge-request-titles}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed
- Liens :  [Documentation](../../user/project/merge_requests/title_templates.md), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/16080)

{{< /details >}}

Dans les versions précédentes de GitLab, le titre par défaut d'une nouvelle merge request provenait de la branche source ou du premier commit, et vous ne pouviez pas imposer une convention de nommage cohérente dans votre projet.

Vous pouvez désormais configurer un modèle de titre de merge request par défaut par projet. Les modèles prennent en charge des variables pour la branche source, la branche cible, le sujet du premier commit, l'identifiant du ticket lié, le titre du ticket et une version lisible par l'homme du nom de la branche source. Par exemple, le modèle `Resolve %{issue_id} "%{issue_title}"` produit des titres tels que `Resolve 123 "Fix login bug"`. Vous pouvez toujours modifier le titre avant de créer la merge request.

### Sécuriser les webhooks avec des jetons de signature HMAC {#secure-webhooks-with-hmac-signing-tokens}

<!-- categories: Importers -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens :  [Documentation](../../user/project/integrations/webhooks.md#signing-tokens), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/19367)

{{< /details >}}

L'en-tête `X-Gitlab-Token` existant envoie un secret statique en texte clair, rendant les webhooks susceptibles d'être interceptés et rejoués.

Vous pouvez désormais ajouter un jeton de signature à n'importe quel webhook. GitLab utilise le jeton de signature pour calculer une signature HMAC-SHA256 sur :

- L'identifiant unique du webhook.
- L'horodatage de la requête.
- La charge utile du webhook.

GitLab envoie ensuite le résultat dans l'en-tête `webhook-signature` avec les en-têtes `webhook-id` et `webhook-timestamp`, conformément à la spécification [Standard Webhooks](https://www.standardwebhooks.com/).

Vous pouvez recalculer la signature pour confirmer que les requêtes proviennent bien de GitLab et que la charge utile n'a pas été modifiée. En validant également l'horodatage, vous pouvez rejeter les requêtes rejouées.

Merci à [Van Anderson](https://gitlab.com/van.m.anderson) et [Norman Debald](https://gitlab.com/Modjo85) pour leurs contributions communautaires !

### Pushs entre projets utilisant des jetons de job CI/CD {#cross-project-pushes-using-cicd-job-tokens}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens :  [Documentation](../../ci/jobs/ci_job_token.md#allow-cross-project-git-push-requests-from-allowlisted-projects), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/479907)

{{< /details >}}

Dans les versions précédentes de GitLab, vous ne pouviez utiliser un jeton de job CI/CD (`CI_JOB_TOKEN`) que pour pousser vers le même dépôt où le pipeline s'exécute. Les pushs entre projets nécessitaient un jeton d'accès personnel ou un jeton de déploiement.

Vous pouvez désormais utiliser un jeton de job pour pousser vers un autre projet lorsque :

1. Le projet cible l'accepte.
1. L'utilisateur qui démarre le pipeline dispose au moins du rôle Développeur dans le projet cible.

Cette fonctionnalité est protégée par le feature flag `allow_push_to_allowlisted_projects`, désactivé par défaut dans GitLab 19.0. Demandez à votre administrateur de l'activer.

### Rendu des diagrammes Mermaid mis à niveau vers la version 11 {#mermaid-diagram-rendering-upgraded-to-version-11}

<!-- categories: Markdown -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens :  [Documentation](../../user/markdown.md#mermaid), [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/491514)

{{< /details >}}

GitLab utilise désormais [Mermaid version 11](../../user/markdown.md#mermaid) pour le rendu des diagrammes en Markdown.

Auparavant, GitLab prenait en charge Mermaid version 10. Avec cette mise à niveau, vous avez accès à tous les nouveaux types de diagrammes, améliorations de syntaxe et corrections de bugs introduits dans Mermaid 11, notamment un rendu amélioré pour les organigrammes, les diagrammes de séquence et plus encore.

### Rapid Diffs pour les revues de merge request (Bêta) {#rapid-diffs-for-merge-request-reviews-beta}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed
- Liens :  [Documentation](../../user/project/merge_requests/changes.md#rapid-diffs), [Ticket associé](https://gitlab.com/groups/gitlab-org/-/work_items/18457)

{{< /details >}}

Dans les versions précédentes de GitLab, vous deviez attendre que l'onglet **Modifications** charge tous les fichiers avant de pouvoir commencer la revue, ce qui ralentissait les grandes revues.

Vous pouvez désormais utiliser Rapid Diffs pour revoir les merge requests avec un chargement initial plus rapide, un défilement plus fluide et des interactions plus réactives entre les fichiers. Rapid Diffs utilise la même technologie qui alimente déjà la page des commits.

Rapid Diffs est en bêta. Certaines fonctionnalités de l'expérience de diff classique ne sont pas encore disponibles. Vous pouvez revenir à tout moment.

[Regardez la vidéo de présentation](https://www.youtube.com/watch?v=S-IzJnhoH6U) et partagez votre expérience dans le [ticket de retour](https://gitlab.com/gitlab-org/gitlab/-/issues/596236).

### GitLab Runner 19.0 {#gitlab-runner-190}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens :  [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 19.0 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Instrumentation du runner : Négociation de fonctionnalités, client d'export OTLP et premier span `job_execution`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39231)
- [Ajouter un délai d'expiration de l'étape de préparation configurable à la configuration du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/26583)

#### Corrections de bugs {#bug-fixes}

- [Corrections complètes pour l'implémentation du feature flag `FF_SCRIPTS_TO_STEPS`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39403)
- [Erreur `SignatureDoesNotMatch` lors du téléchargement du cache S3](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39402)
- [Erreur d'exécution lorsque GitLab Runner s'exécute dans AWS avec le cache S3](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39386)
- [Liens de téléchargement RPM S3 corrompus pour `amd64`, `arm64`, `arm` et `armhf` dans GitLab Runner 18.9.0 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39362)
- [Les codes de sortie négatifs sont signalés incorrectement sur Windows](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39292)
- [Documentation incorrecte sur le nommage des conteneurs de services de l'exécuteur Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39235)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-0-stable/CHANGELOG.md) de GitLab Runner.
