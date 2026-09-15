---
stage: Release Notes
group: Monthly Release
date: 2026-04-16
title: "Notes de release de GitLab 18.11"
description: "GitLab 18.11 est disponible avec la résolution des vulnérabilités en disponibilité générale sur GitLab Duo Agent Platform"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 16 avril 2026, GitLab 18.11 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Rinku C {#this-months-notable-contributor-rinku-c}

Nous sommes ravis de mettre à l'honneur [Rinku C](https://gitlab.com/therealrinku), un contributeur de niveau 4 avec plus de 80 améliorations fusionnées dans GitLab depuis son arrivée en septembre 2025.

Nommé par [Arianna Haradon](https://gitlab.com/aharadon), ingénieure fullstack senior dans l'équipe Developer Relations, ce prix célèbre son impact soutenu et significatif au fil du temps. Rinku a renforcé les flows sensibles à la sécurité en [imposant des portées sur les formulaires de création de jetons d'accès de projet et de groupe](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219236), et a amélioré l'expérience quotidienne de GitLab avec de nombreuses mises à jour telles que la [navigation suivant/précédent dans les job logs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217618), l'[exclusion des recherches vides des recherches récentes](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223570) et la [réduction de l'encombrement de l'arborescence de fichiers](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224628) grâce à des améliorations d'interface réfléchies qui rendent les workflows courants plus clairs et plus faciles à parcourir. Rinku s'attaque aux travaux qui restent souvent non réclamés, contribuant à maintenir la base de code saine et à créer une valeur significative et durable. Merci pour vos contributions !

## Fonctionnalités principales {#primary-features}

### Résolution des vulnérabilités en disponibilité générale sur GitLab Duo Agent Platform {#vulnerability-resolution-generally-available-on-gitlab-duo-agent-platform}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/vulnerabilities/agentic_vulnerability_resolution.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/585626)

{{< /details >}}

La résolution agentique des vulnérabilités SAST est désormais en disponibilité générale dans GitLab 18.11 sur GitLab Duo Agent Platform. Elle s'exécute dans le cadre de votre analyse SAST, après l'exécution de la détection des faux positifs SAST, ou lorsqu'elle est déclenchée manuellement pour des vulnérabilités SAST individuelles.

Résolution agentique des vulnérabilités SAST :

- Analyse de manière autonome le résultat et raisonne à partir du contexte du code environnant.
- Crée automatiquement une merge request prête à être révisée avec des corrections de code proposées pour les vulnérabilités SAST de gravité critique et élevée.
- Fournit des évaluations de qualité afin que les relecteurs puissent rapidement évaluer la confiance accordée à la remédiation proposée.
- Vous permet d'appliquer des résolutions directement depuis les pages de détails des vulnérabilités.

Nous accueillons vos commentaires dans [le ticket 585626](https://gitlab.com/gitlab-org/gitlab/-/issues/585626).

### L'agent par défaut Data Analyst de GitLab est désormais en disponibilité générale {#gitlab-data-analyst-foundational-agent-now-generally-available}

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20337)

{{< /details >}}

L'agent Data Analyst est un assistant de chat IA spécialisé qui vous aide à interroger, visualiser et mettre en évidence des données sur l'ensemble de la plateforme GitLab.

Reposant sur le [GitLab Query Language (GLQL)](../../user/glql/_index.md), l'agent Data Analyst peut récupérer et analyser des données relatives à chacune des [sources de données](../../user/glql/data_sources/_index.md) prises en charge, et fournir des informations claires et exploitables sur la santé de votre développement logiciel et l'efficacité de vos équipes.

Ces informations peuvent être visualisées directement dans la sortie de l'agent et intégrées directement dans les tickets et les epics pour une évaluation plus approfondie.

### L'agent CI Expert est lancé en version bêta {#ci-expert-agent-launches-in-beta}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/ci_expert_agent.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/587460)

{{< /details >}}

L'agent CI Expert optimisé par l'IA est désormais disponible en version bêta. Cet agent aide les équipes à passer du code GitLab à un premier pipeline fonctionnel sans partir d'un fichier `.gitlab-ci.yml` vierge.

En utilisant GitLab Duo Agent Platform, l'agent inspecte votre dépôt, pose quelques questions guidées sur votre processus de build et de test, et génère un pipeline prêt à l'emploi que vous pouvez réviser, modifier et committer.

Cela transforme la création de pipeline en une expérience conversationnelle et contextuelle, tout en vous laissant le contrôle total du YAML lorsque vous êtes prêt à faire évoluer et optimiser votre configuration.

### Substitutions automatisées de la gravité des vulnérabilités {#automated-vulnerability-severity-overrides}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/policies/vulnerability_management_policy.md#severity-override-policies) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15839)

{{< /details >}}

Les gravités de vulnérabilités par défaut ne reflètent pas toujours le risque réel de votre organisation. Un CVE critique dans un service uniquement interne ne justifie peut-être pas la même urgence que dans une application exposée au public, pourtant les équipes passent un temps considérable à trier les résultats qui ne correspondent pas à leur modèle de risque.

Les politiques de gestion des vulnérabilités peuvent désormais ajuster automatiquement la gravité des vulnérabilités en fonction de conditions telles que l'ID CVE, l'ID CWE, le chemin du fichier et le répertoire. Lorsqu'elle est appliquée, la politique met à jour la gravité de toute vulnérabilité correspondant aux critères sur la branche par défaut. Les substitutions manuelles ont toujours la priorité, et toutes les modifications sont consignées dans l'historique de la vulnérabilité et les événements d'audit.

Cela réduit le travail de triage et garantit que les développeurs se concentrent sur les résultats les plus importants pour votre activité.

### Créer un compte de service dans des sous-groupes et des projets {#create-service-account-in-subgroups-and-projects}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/profile/service_accounts.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Les équipes peuvent désormais créer des comptes de service dans des sous-groupes et des projets. Au lieu de bots de groupe principal généraux, vous pouvez associer un compte de service dédié à un seul sous-groupe ou projet et gérer son accès comme pour n'importe quel autre membre de cet espace de nommage. Les comptes de service de groupe et de sous-groupe peuvent être invités dans le groupe où ils ont été créés ou dans n'importe quel sous-groupe ou projet descendant. Les comptes de service de projet sont limités à leur propre projet.

### Comptes de service disponibles sur GitLab Free {#service-accounts-available-on-gitlab-free}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/profile/service_accounts.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20439)

{{< /details >}}

Les comptes de service sont désormais disponibles sur GitLab.com dans toutes les éditions. Précédemment limités à Premium et Ultimate, les comptes de service vous permettent d'effectuer des actions automatisées, d'accéder à des données ou d'exécuter des processus planifiés sans associer les identifiants à des membres individuels de l'équipe. Ils sont couramment utilisés dans les pipelines et les intégrations tierces où les identifiants doivent rester stables indépendamment des changements d'équipe. Sur GitLab Free, vous pouvez créer jusqu'à 100 comptes de service par groupe principal, y compris ceux créés dans des sous-groupes ou des projets.

### Permissions à granularité fine pour les jetons d'accès personnels désormais disponibles (version bêta) {#fine-grained-permissions-for-personal-access-tokens-now-available-beta}

<!-- categories: Permissions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../auth/tokens/fine_grained_access_tokens.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/18555)

{{< /details >}}

Les jetons d'accès personnels (PAT) à granularité fine sont désormais disponibles en version bêta. Contrairement aux PAT hérités, qui accordent l'accès à chaque projet et groupe auquel vous appartenez, les PAT à granularité fine vous permettent de limiter chaque jeton à des ressources et des actions spécifiques. Cela réduit l'impact potentiel d'un jeton compromis ou divulgué.

Vos PAT existants continuent de fonctionner comme avant, et vous pouvez toujours créer des PAT hérités sans permissions à granularité fine.

Cette version bêta couvre environ 75 % de l'API REST de GitLab. La couverture complète de l'API REST, l'application GraphQL et les contrôles de politique administrateur sont prévus pour la version en disponibilité générale.

Pour partager vos commentaires, consultez l'[epic 18555](https://gitlab.com/groups/gitlab-org/-/epics/18555).

### Graphique des CWE principaux dans les tableaux de bord de sécurité {#top-cwe-chart-in-security-dashboards}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/security_dashboard/_index.md#top-10-cwes) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17422)

{{< /details >}}

Le graphique des CWE principaux est désormais disponible sur les nouveaux tableaux de bord de sécurité. Identifiez les CWE les plus courants dans votre projet ou instance afin de repérer des opportunités de formation, d'amélioration ou d'optimisation du programme. Les utilisateurs peuvent regrouper les données du tableau de bord par gravité et filtrer le tableau de bord par gravité, projet et type de rapport.

### Déployer Gitaly sur Kubernetes {#deploy-gitaly-on-kubernetes}

<!-- categories: Gitaly -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../administration/gitaly/kubernetes.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/work_items/6127)

{{< /details >}}

Vous pouvez désormais déployer Gitaly sur Kubernetes en tant que méthode de déploiement entièrement prise en charge. Cela vous offre une plus grande flexibilité dans la gestion de votre infrastructure GitLab en utilisant les capacités d'orchestration de Kubernetes pour la mise à l'échelle, la haute disponibilité et la gestion des ressources. Auparavant, les déploiements Kubernetes nécessitaient des configurations personnalisées et n'étaient pas officiellement pris en charge, ce qui rendait difficile la maintenance de déploiements Gitaly fiables dans des environnements conteneurisés.

### Reconfigurer les entrées CI/CD lors de l'exécution manuelle des pipelines de MR {#reconfigure-inputs-when-manually-running-mr-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../ci/pipelines/merge_request_pipelines.md#run-a-merge-request-pipeline-with-custom-inputs) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/547861)

{{< /details >}}

Un aspect puissant des entrées CI/CD est que vous pouvez exécuter manuellement de nouveaux pipelines avec de nouvelles valeurs pour la personnalisation à l'exécution. Cette fonctionnalité n'était pas disponible dans les pipelines de merge request (MR) auparavant, mais dans cette version, vous pouvez désormais personnaliser les entrées CI/CD dans les pipelines de MR également.

Après avoir configuré les entrées CI/CD pour les pipelines de MR, vous pouvez éventuellement modifier ces entrées et changer le comportement du pipeline à chaque fois que vous exécutez un nouveau pipeline pour une merge request.

## Agentic Core {#agentic-core}

### Modèle par défaut de GitLab Duo Agentic Chat mis à jour de Haiku 4.5 à Sonnet 4.6 {#default-model-for-gitlab-duo-agentic-chat-updated-from-haiku-45-to-sonnet-46}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/duo_agent_platform/model_selection.md#default-models) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/595042)

{{< /details >}}

Nous avons effectué une mise à jour pour améliorer votre expérience d'Agentic Chat dans GitLab. Le modèle par défaut d'Agentic Chat a été mis à niveau de Claude Haiku 4.5 à Claude Sonnet 4.6, hébergé sur Vertex AI. Claude Sonnet 4.6 offre un raisonnement et une qualité de réponse améliorés, mais utilise un multiplicateur de GitLab Credits plus élevé que Haiku 4.5.

Vous pouvez sélectionner un modèle alternatif, y compris Haiku, en utilisant le paramètre de [sélection de modèle](../../user/duo_agent_platform/model_selection.md#select-a-model-for-a-feature). Si vous avez déjà sélectionné un modèle spécifique, votre choix est conservé. Cette mise à jour n'affecte que la valeur par défaut et ne remplacera aucune sélection existante. Pour obtenir des informations sur les multiplicateurs de crédits par modèle, consultez la [documentation sur les GitLab Credits](../../subscriptions/gitlab_credits.md).

### Configurer des outils dans les définitions de flow personnalisé {#configure-tools-in-custom-flow-definitions}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/duo_agent_platform/flows/custom.md#create-a-flow) \| [Ticket associé](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2147)

{{< /details >}}

Vous pouvez désormais configurer les options des outils et les valeurs des paramètres directement dans vos définitions de flow personnalisé pour remplacer les valeurs par défaut du LLM. Cela vous offre un contrôle plus précis et cohérent sur le comportement des outils au sein d'un flow personnalisé, facilitant l'application de garde-fous et de valeurs de paramètres spécifiques dans ce flow.

### Mistral AI désormais pris en charge en tant que modèle auto-hébergé dans GitLab Duo Agent Platform {#mistral-ai-now-supported-as-a-self-hosted-model-in-gitlab-duo-agent-platform}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#cloud-hosted-model-deployments) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/587872)

{{< /details >}}

GitLab Duo Agent Platform prend désormais en charge Mistral AI comme plateforme LLM pour les déploiements de modèles auto-hébergés. Les clients de GitLab Self-Managed peuvent configurer Mistral AI aux côtés des plateformes prises en charge existantes, notamment AWS Bedrock, Google Vertex AI, Azure OpenAI, Anthropic et OpenAI. Cela offre aux équipes plus de choix dans la façon dont elles exécutent les fonctionnalités optimisées par l'IA.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Consulter les mois historiques dans le tableau de bord des GitLab Credits {#view-historical-months-in-gitlab-credits-dashboard}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) \| [Ticket associé](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15910)

{{< /details >}}

Le tableau de bord des GitLab Credits dans le portail clients prend désormais en charge la navigation dans les mois historiques. Les gestionnaires de facturation peuvent parcourir les mois de facturation passés pour examiner les tendances d'utilisation quotidienne, comparer les modèles de consommation sur différentes périodes et rapprocher l'utilisation avec les factures. Auparavant, le tableau de bord n'affichait que le mois de facturation en cours. Grâce à cette amélioration, les administrateurs peuvent prendre des décisions plus éclairées concernant l'allocation des crédits et prévoir les besoins futurs sur la base de données historiques.

### Définir un plafond d'utilisation au niveau de l'abonnement pour les GitLab Credits {#set-subscription-level-usage-cap-for-gitlab-credits}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

Les administrateurs peuvent désormais définir un plafond d'utilisation mensuel pour les crédits à la demande au niveau de l'abonnement. Lorsque la consommation totale de crédits à la demande atteint le plafond configuré, l'accès à GitLab Duo Agent Platform est automatiquement suspendu pour tous les utilisateurs de cet abonnement jusqu'au début de la prochaine période de facturation ou jusqu'à ce que l'administrateur ajuste le plafond. Ce paramètre offre aux organisations un garde-fou strict contre les factures de dépassement imprévues, supprimant un obstacle majeur au déploiement plus large d'Agent Platform. Les plafonds se réinitialisent automatiquement à chaque période de facturation, et les administrateurs reçoivent une notification par e-mail lorsque le plafond est atteint.

### Définir un plafond de GitLab Credits par utilisateur {#set-per-user-gitlab-credits-cap}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

Les administrateurs peuvent désormais définir un plafond d'utilisation optionnel par utilisateur pour les GitLab Credits par période de facturation. Lorsque la consommation totale de crédits d'un utilisateur individuel atteint la limite configurée, l'accès à GitLab Duo Agent Platform est suspendu uniquement pour cet utilisateur, tandis que les autres utilisateurs continuent sans être affectés. Cela empêche tout utilisateur unique de consommer une part disproportionnée du pool de crédits de l'organisation et donne aux administrateurs un contrôle à granularité fine sur la distribution de l'utilisation. Les plafonds d'utilisation par utilisateur fonctionnent conjointement avec les plafonds d'utilisation au niveau de l'abonnement, en appliquant le plafond qui est atteint en premier.

### Améliorations du paquet Linux {#linux-package-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server) \| [Ticket associé](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9734)

{{< /details >}}

Dans GitLab 19.0, la version minimale prise en charge de PostgreSQL sera la version 17. Pour préparer ce changement, sur les instances qui n'utilisent pas le [cluster PostgreSQL](../../administration/postgresql/replication_and_failover.md), les mises à niveau vers GitLab 18.11 tenteront de mettre à niveau automatiquement PostgreSQL vers la version 17.

Si vous utilisez le [cluster PostgreSQL](../../administration/postgresql/replication_and_failover.md) ou si vous [refusez cette mise à niveau automatisée](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades), vous devez [mettre à niveau manuellement vers PostgreSQL 17](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server) pour pouvoir mettre à niveau vers GitLab 19.0.

### Prise en charge de la sauvegarde et de la restauration pour la base de données de métadonnées du registre de conteneurs {#backup-and-restore-support-for-container-registry-metadata-database}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/backup_restore/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-com/gl-infra/data-access/durability/-/work_items/45)

{{< /details >}}

La tâche Rake GitLab `backup` pour les installations de paquets Linux et l'outil `[backup-utility](https://docs.gitlab.com/charts/backup-restore/)` pour les installations Cloud Native (Helm) prennent désormais en charge la [base de données de métadonnées du registre de conteneurs](../../administration/packages/container_registry_metadata_database.md). Vous pouvez désormais sauvegarder les références aux blobs, aux manifestes, aux tags et à d'autres données stockées dans la base de données de métadonnées, permettant ainsi la récupération en cas de corruption malveillante ou accidentelle des données.

### Nouvelle expérience de navigation pour les groupes dans Explorer {#new-navigation-experience-for-groups-in-explore}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/group/_index.md#explore-groups) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/13791)

{{< /details >}}

Nous sommes ravis d'annoncer des améliorations de la liste de groupes dans **Explorer**, facilitant la découverte de groupes dans votre instance GitLab. L'interface repensée introduit une disposition par onglets avec deux vues :

- Onglet **Actif** : parcourez tous les groupes accessibles, vous aidant à découvrir les communautés et projets pertinents.
- Onglet **Inactif** : consultez les groupes archivés et les groupes en attente de suppression pour avoir une visibilité sur le statut du cycle de vie des groupes.

Ces changements rationalisent la découverte de groupes et offrent une visibilité plus claire sur les groupes disponibles pour rejoindre.

### Transfert asynchrone de projets {#asynchronous-transfer-of-projects}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/group/manage.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20521)

{{< /details >}}

Dans les versions précédentes de GitLab, les transferts de grands groupes et projets pouvaient expirer. À mesure que nous faisons évoluer les groupes et projets vers un modèle d'état unifié pour des opérations telles que le transfert, l'archivage et la suppression, vous bénéficiez d'un comportement plus cohérent, d'une meilleure visibilité sur l'historique des états et les détails d'audit, et de moins d'expirations, notamment pour les opérations de transfert longues via un traitement asynchrone.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### ClickHouse est en disponibilité générale pour les déploiements Self-Managed {#clickhouse-is-generally-available-for-self-managed-deployments}

<!-- categories: DevOps Reports -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../integration/clickhouse.md#set-up-clickhouse) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/work_items/51)

{{< /details >}}

Pour les instances GitLab Self-Managed, nous disposons désormais de recommandations améliorées et d'une aide à la configuration pour l'[intégration ClickHouse](../../integration/clickhouse.md) de GitLab. Les clients ont la possibilité d'apporter leur propre cluster ou d'utiliser l'option de configuration ClickHouse Cloud (recommandée). Cette intégration alimente plusieurs tableaux de bord et déverrouille l'accès à divers points de terminaison d'API dans l'espace analytique.

Cette base de données performante et évolutive fait partie des améliorations architecturales plus larges prévues pour l'infrastructure analytique de GitLab.

### Analytique améliorée de GitLab Duo Agent Platform dans le tableau de bord des tendances Duo et SDLC {#enhanced-gitlab-duo-agent-platform-analytics-on-duo-and-sdlc-trends-dashboard}

<!-- categories: DevOps Reports -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/analytics/duo_and_sdlc_trends.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20540)

{{< /details >}}

Le tableau de bord des tendances GitLab Duo et SDLC offre des capacités d'analyse améliorées pour mesurer l'impact de GitLab Duo sur la livraison de logiciels. Le tableau de bord inclut désormais de nouveaux panneaux de statistiques uniques pour les utilisateurs mensuels uniques d'Agent Platform et les sessions Agentic Chat. De plus, les métriques précédemment affichées en pourcentage d'utilisation par rapport aux attributions de sièges ont été mises à jour pour rapporter strictement les nombres d'utilisation. Ce changement résout le [ticket](https://gitlab.com/gitlab-org/gitlab/-/work_items/590326) où les comptages ne prenaient pas en compte l'utilisation d'Agent Platform contrôlée par le nouveau modèle de facturation à l'utilisation.

### GLQL a désormais accès aux sources de données des projets, pipelines et jobs {#glql-now-has-access-to-projects-pipelines-and-jobs-data-sources}

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/glql/data_sources/_index.md)

{{< /details >}}

Le [GitLab Query Language (GLQL)](../../user/glql/_index.md) a désormais accès à trois nouvelles sources de données : les projets, les pipelines et les jobs. Ces nouvelles sources de données sont également disponibles sous forme de vues intégrées, permettant aux équipes de faire apparaître les résultats de pipeline, les statuts de job et les aperçus de projets directement dans les wikis, les descriptions de tickets et de merge requests, et les fichiers Markdown du dépôt. GLQL alimente également l'[agent Data Analyst](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md).

Avec ces nouveaux types, l'agent peut inspecter les résultats des jobs CI/CD, déboguer les échecs et fournir des aperçus détaillés de l'exécution du pipeline, ainsi qu'un aperçu précis des projets dans un espace de nommage.

### Résolution des dépendances pour l'analyse SAST SBOM de Maven et Python {#dependency-resolution-for-maven-and-python-sbom-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#dependency-resolution) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20461)

{{< /details >}}

L'analyse des dépendances GitLab utilisant SBOM prend désormais en charge la génération automatique d'un graphe de dépendances pour les projets Maven et Python. Auparavant, l'analyse des dépendances nécessitait que les utilisateurs fournissent un fichier de verrouillage ou un fichier graphe pour obtenir une analyse précise des dépendances. Désormais, lorsqu'un fichier de verrouillage ou un fichier graphe n'est pas disponible, l'analyseur tente automatiquement d'en générer un. Cette amélioration facilite l'activation de l'analyse des dépendances pour les projets Maven et Python sans nécessiter de fichier de verrouillage.

### Analyse incrémentielle pour Advanced SAST {#incremental-scanning-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#incremental-scanning) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/20508)

{{< /details >}}

Vous pouvez désormais effectuer des analyses incrémentielles qui analysent uniquement les parties modifiées de la base de code avec GitLab Advanced SAST, réduisant considérablement les temps d'analyse par rapport aux analyses complètes du dépôt. Cette fonctionnalité est une itération supplémentaire de l'analyse basée sur les différences, car elle produit des résultats complets pour les bases de code.

En analysant uniquement le code qui a changé plutôt que l'ensemble de la base de code, vos équipes peuvent intégrer les tests de sécurité de manière plus transparente dans leur workflow de développement sans sacrifier la vitesse ni ajouter de friction.

### Vulnérabilités non vérifiées (version bêta) {#unverified-vulnerabilities-beta}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#report-unverified-vulnerabilities) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/15649)

{{< /details >}}

Advanced SAST peut désormais faire apparaître des vulnérabilités non vérifiées (résultats qui ne peuvent pas être entièrement tracés de la source au récepteur) directement dans le rapport de vulnérabilités. Activez cette fonctionnalité si vous avez une tolérance plus élevée pour les faux positifs que pour les faux négatifs.

Cette fonctionnalité est en version bêta. Donnez votre avis dans le [ticket 596512](https://gitlab.com/gitlab-org/gitlab/-/work_items/596512).

### Prise en charge de Kubernetes 1.35 {#kubernetes-135-support}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/584225)

{{< /details >}}

GitLab prend désormais entièrement en charge Kubernetes version 1.35. Si vous souhaitez déployer vos applications sur Kubernetes et accéder à toutes les fonctionnalités, mettez à niveau vos clusters connectés vers la version la plus récente. Pour plus d'informations, consultez [les versions de Kubernetes prises en charge pour les fonctionnalités de GitLab](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### Mode prefer pour la base de données de métadonnées du registre de conteneurs {#prefer-mode-for-the-container-registry-metadata-database}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/packages/container_registry_metadata_database.md#prefer-mode) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/595480)

{{< /details >}}

Vous pouvez désormais définir la base de données de métadonnées du registre de conteneurs en mode `prefer`, une nouvelle option de configuration aux côtés des valeurs existantes `true` et `false`. En mode prefer, le registre détecte automatiquement s'il doit utiliser la base de données de métadonnées ou revenir au stockage hérité en fonction de l'état actuel de votre installation.

Si votre registre dispose de métadonnées de système de fichiers existantes qui n'ont pas été importées dans la base de données, le registre continue d'utiliser le stockage hérité jusqu'à ce que vous terminiez une importation de métadonnées. Si la base de données est déjà utilisée, ou lors d'une nouvelle installation, le registre utilise directement la base de données.

Dans une version ultérieure, le mode `prefer` deviendra la valeur par défaut pour les nouvelles installations de paquets Linux. Les installations existantes ne seront pas affectées. Pour plus d'informations, consultez le [ticket 595480](https://gitlab.com/gitlab-org/gitlab/-/work_items/595480).

### Les règles de protection des paquets prennent désormais en charge les modules Terraform {#package-protection-rules-now-support-terraform-modules}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/packages/package_registry/package_protection_rules.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/592761)

{{< /details >}}

Les équipes qui publient des modules Terraform via le registre de paquets de modules Terraform intégré à GitLab n'avaient aucun moyen de restreindre les personnes pouvant pousser de nouvelles versions de module. Les règles de protection des paquets prenaient en charge plusieurs formats de paquets, mais n'incluaient pas `terraform_module`, laissant les équipes d'infrastructure sans contrôle de push au niveau du projet.

Vous pouvez désormais créer des règles de protection de paquets limitées à `terraform_module`, en restreignant l'accès au push en fonction du rôle minimum. La prise en charge est disponible dans le menu déroulant de type de paquet de l'interface utilisateur, l'API REST, l'API GraphQL et la ressource du fournisseur Terraform GitLab.

### La preuve de release inclut désormais les paquets {#release-evidence-now-includes-packages}

<!-- categories: Package Registry, Release Evidence -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/releases/release_evidence.md#include-packages-as-release-evidence) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/283995)

{{< /details >}}

Lors de la création d'une release GitLab, les paquets publiés dans le registre de paquets n'étaient pas automatiquement associés à celle-ci. Les équipes devaient construire manuellement les URL des paquets et les joindre en tant que liens de release via l'API ou des scripts de pipeline, ajoutant ainsi des frictions et un risque d'enregistrements de release incomplets.

GitLab inclut désormais automatiquement les paquets dans la preuve de release lorsque la version du paquet correspond au tag de release. Cela crée un lien vérifiable et auditable entre votre release et ses paquets associés sans aucune étape manuelle, gardant le code source, les artefacts et les paquets ensemble dans un instantané de release complet.

### Basculement de la barre latérale du wiki repositionné pour un accès plus facile {#wiki-sidebar-toggle-repositioned-for-easier-access}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/wiki/_index.md#sidebar) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/580569)

{{< /details >}}

Le bouton de basculement de la barre latérale du wiki est désormais positionné sur le côté gauche, directement à côté de la barre latérale qu'il contrôle.

Lorsque la barre latérale est réduite, le bouton de basculement reste visible en tant que contrôle flottant afin que vous puissiez la rouvrir sans avoir à revenir en haut de la page.

### Barre d'actions fixe sur les pages wiki {#sticky-action-bar-on-wiki-pages}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/project/wiki/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/590255)

{{< /details >}}

La barre d'actions sur les pages wiki est désormais fixe, elle reste donc visible lorsque vous faites défiler une page. Auparavant, vous deviez faire défiler jusqu'en haut pour accéder aux actions telles que la modification, la consultation de l'historique de la page ou la gestion des modèles. Désormais, le titre de la page et les actions clés, notamment Modifier, Nouvelle page, Modèles, Historique de la page, et plus encore, restent à portée de main quelle que soit votre position dans la page.

### Poids des epics {#epic-weights}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/work_items/weight.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/12273)

{{< /details >}}

Les epics prennent désormais en charge les poids, facilitant l'estimation et la priorisation des initiatives à grande échelle lors de la planification.

Avant de décomposer un epic en tickets enfants, vous pouvez attribuer un poids préliminaire pour représenter votre estimation initiale. Au fur et à mesure que vous décomposez l'epic, le poids se met automatiquement à jour pour refléter le total cumulé de tous les tickets enfants. Cela est cohérent avec le fonctionnement du cumul de poids pour les tickets et les tâches.

Sur la page de détail de l'epic, vous pouvez voir à la fois le poids préliminaire et le poids cumulé des tickets enfants, vous donnant les informations nécessaires pour affiner les estimations au fil du temps.

### Bloquer les merge requests présentant un risque d'exploitabilité élevé {#block-merge-requests-with-high-exploitability-risk}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#vulnerability_attributes-object) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16311)

{{< /details >}}

Auparavant, les politiques d'approbation des merge requests (MR) pouvaient bloquer les MR en fonction de la gravité des vulnérabilités, mais toutes les vulnérabilités ne présentent pas le même risque. La gravité CVSS seule ne vous indique pas si un CVE est exploité ou quelle est la probabilité d'exploitation. Cela entraîne des politiques d'approbation bruyantes et une perte de temps pour les développeurs et les équipes de sécurité.

Vous pouvez désormais configurer des politiques d'approbation de MR en utilisant les données Known Exploited Vulnerability (KEV) et Exploit Prediction Scoring System (EPSS). Bloquez ou exigez une approbation lorsqu'un résultat figure dans le catalogue KEV (activement exploité dans la nature), ou lorsque son score EPSS dépasse un seuil. Les violations de politique dans la MR incluent le contexte KEV et EPSS afin que les développeurs comprennent pourquoi la passerelle de sécurité a été déclenchée.

Cela donne aux équipes de sécurité un contrôle précis sur les résultats qui bloquent ou avertissent, réduit la fatigue des alertes et maintient l'application alignée sur le paysage des menaces actuel.

### Attribuer des scores CVSS 4.0 aux vulnérabilités {#assign-cvss-40-scores-to-vulnerabilities}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/vulnerabilities/severities.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18697)

{{< /details >}}

CVSS 4.0 est la dernière version de la norme industrielle utilisée pour évaluer et noter la gravité d'une vulnérabilité. Vous pouvez désormais consulter et accéder au score CVSS 4.0 dans l'interface utilisateur, notamment sur la page de détails de la vulnérabilité et dans le rapport de vulnérabilités. Vous pouvez également interroger le score à l'aide de l'API.

### Interaction de ligne améliorée dans le rapport de vulnérabilités {#improved-row-interaction-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/561414)

{{< /details >}}

Auparavant, vous deviez sélectionner la description de la ligne pour accéder à une page de détails de vulnérabilité depuis le rapport de vulnérabilités.

Vous pouvez désormais sélectionner n'importe où dans la ligne pour accéder directement à ses détails. Le style de lien pour la description de la vulnérabilité et l'emplacement du fichier n'apparaît que lorsque vous survolez chaque lien, et la navigation au clavier a été améliorée.

Ces changements rendent le rapport de vulnérabilités plus intuitif et accessible.

### Exporter un tableau de bord de sécurité au format PDF {#export-a-security-dashboard-as-a-pdf}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/security_dashboard/_index.md#export-as-pdf) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18203)

{{< /details >}}

Vous pouvez exporter le tableau de bord de sécurité au format PDF pour l'utiliser dans des rapports et des présentations. L'export capture l'état actuel de tous les graphiques et panneaux du tableau de bord, y compris les filtres actifs.

### Analyse SAST dans les profils de configuration de sécurité {#sast-scanning-in-security-configuration-profiles}

<!-- categories: Security Testing Configuration -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/configuration/security_configuration_profiles.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/19951)

{{< /details >}}

Dans GitLab 18.9, nous avons introduit les profils de configuration de sécurité avec le profil **Secret Detection - Default**. Dans GitLab 18.11, les profils s'étendent désormais au SAST avec le profil **Static Application Security Testing (SAST) - Default**, vous offrant une surface de contrôle unifiée pour appliquer une couverture d'analyse statique standardisée à tous vos projets sans toucher à un seul fichier de configuration CI/CD.

Le profil active deux déclencheurs d'analyse :

- **Pipelines de merge request** : exécute automatiquement un scan SAST chaque fois que de nouveaux commits font l'objet d'un push vers une branche avec une merge request ouverte. Les résultats n'incluent que les nouvelles vulnérabilités introduites par la merge request.
- **Pipelines de branche (par défaut seulement)** : s'exécute automatiquement lorsque des modifications sont fusionnées ou poussées vers la branche par défaut, offrant une vue complète de la posture SAST de votre branche par défaut.

### Filtres d'attributs de sécurité dans les tableaux de bord de sécurité de groupe {#security-attribute-filters-in-group-security-dashboards}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/security_dashboard/_index.md#filter-the-entire-dashboard) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18201)

{{< /details >}}

Vous pouvez désormais filtrer les résultats dans un tableau de bord de sécurité de groupe en fonction des attributs de sécurité que vous avez appliqués aux projets de ce groupe.

Les attributs de sécurité disponibles sont les suivants :

- Impact sur l'activité
- Application
- Unité commerciale
- Exposition à Internet
- Emplacement

### Rôle Responsable sécurité (version bêta) {#security-manager-role-beta}

<!-- categories: Permissions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/permissions.md)

{{< /details >}}

Le rôle Responsable sécurité est désormais disponible en tant que fonctionnalité bêta, offrant un nouvel ensemble de permissions par défaut conçu spécifiquement pour les professionnels de la sécurité. Les équipes de sécurité n'ont plus besoin des rôles Developer ou Maintainer pour accéder aux fonctionnalités de sécurité, éliminant ainsi les préoccupations de sur-privilégiation tout en maintenant la séparation des tâches.

Les utilisateurs disposant du rôle Responsable sécurité ont les accès suivants :

- **Gestion des vulnérabilités** : consultez, triez et gérez les vulnérabilités dans les groupes et projets, y compris les rapports de vulnérabilités et les tableaux de bord de sécurité.
- **Inventaire de sécurité** : consultez l'inventaire de sécurité d'un groupe pour comprendre la couverture des scanners dans tous les projets.
- **Security configuration profiles** : consultez les profils de configuration de sécurité d'un groupe.
- **Compliance tools** : consultez les événements d'audit, le centre de conformité, les cadres de conformité et les listes de dépendances pour un groupe ou un projet.
- **Protection push de détection des secrets** : activez la protection push de détection des secrets pour un groupe.
- **On-demand DAST** : créez et exécutez des analyses DAST à la demande pour un groupe.

Pour commencer, accédez à un groupe et sélectionnez **Gérer** > **Membres** pour inviter et attribuer des membres au rôle Responsable sécurité.

### Popover de liste d'identifiants dans le rapport de vulnérabilités {#identifier-list-popover-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/564939)

{{< /details >}}

Le rapport de vulnérabilités affiche désormais l'identifiant CVE principal sous forme de lien cliquable dans chaque ligne. Lorsqu'il existe plusieurs identifiants, un popover `"+N more"` liste tous les identifiants. Chaque identifiant de la liste renvoie à sa référence externe (par exemple, dans les bases de données CVE, CWE ou WASC) afin que vous puissiez accéder rapidement à plus de détails sans quitter le rapport.

### GitLab Runner 18.11 {#gitlab-runner-1811}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 18.11 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Créer une image d'aide `concrete` avec des dépendances intégrées](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39286)
- [Lire le feature flag du routeur de job depuis la configuration du runner plutôt que depuis une variable d'environnement](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39280)

#### Corrections de bugs {#bug-fixes}

- [Chemin binaire du runner incorrect après refactorisation](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39329)
- [Le pipeline se bloque sur les opérations de cache](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39279)
- [Le binaire `docker-machine` dans GitLab Runner 18.9.0 fait référence à CVE-2025-68121](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39276)
- [Le runner se rabat silencieusement sur les identifiants du payload de job lorsque le binaire d'aide aux identifiants est absent de `DOCKER_AUTH_CONFIG`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39201)
- [`CONCURRENT_PROJECT_ID `n'est pas unique dans différents jobs, ce qui provoque un conflit dans le répertoire de builds](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38307)
- [L'envoi d'artefacts échoue avec un délai d'attente lors de la réception des en-têtes de réponse](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37220)
- [Le `after_script` défini par l'utilisateur s'exécute après un `pre_build_script` ayant échoué et contourne le `post_build_script`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/3116)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.11)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
