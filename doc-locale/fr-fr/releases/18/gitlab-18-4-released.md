---
stage: Release Notes
group: Monthly Release
date: 2025-09-18
title: "Notes de release GitLab 18.4"
description: "GitLab 18.4 est disponible avec la sélection de modèles GitLab Duo désormais en disponibilité générale"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 18 septembre 2025, GitLab 18.4 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Patrick Rice {#this-months-notable-contributor-patrick-rice}

Patrick Rice poursuit son engagement exceptionnel envers la communauté open source de GitLab en tant que contributeur, mainteneur et mentor. [Contributeur dans le top 5](https://contributors.gitlab.com/leaderboard?fromDate=2025-01-01&toDate=2025-09-18&search=&communityOnly=true) au cours de l'année écoulée, Patrick maintient les projets [GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab) et [client-go](https://gitlab.com/gitlab-org/api/client-go), en gérant les ajouts de fonctionnalités, les releases, le tri des tickets et l'intégration de la communauté. Il incarne la mission de GitLab selon laquelle tout le monde peut contribuer, ayant progressé de contributeur à mainteneur de projet.

L'impact de Patrick va au-delà des contributions de code, s'étendant à la construction de la communauté et au coaching, en aidant les nouveaux contributeurs à démarrer et à progresser dans le projet. Patrick a précédemment nominé et soutenu Heidi Berry, qui a remporté le [prix de contributeur notable 17.11](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#notable-contributor). Il a également partagé ses connaissances avec l'équipe [GitLab for Education](https://about.gitlab.com/solutions/education/) sur le travail avec des étudiants qui apprennent GitLab, afin de nous aider à former la prochaine génération de développeurs et développeuses.

« J'adorerais encourager les nouveaux contributeurs à nous rejoindre pour collaborer sur les projets Terraform Provider et client-go », dit Patrick. « Notre communauté est toujours ouverte à de nouveaux visages amicaux. »

« Patrick n'a cessé de soutenir sans relâche l'équipe GitLab et ses clients », déclare [Lee Tickett](https://gitlab.com/leetickett-gitlab), Staff Fullstack Engineer chez GitLab, qui a nominé Patrick pour le prix. [Timo Furrer](https://gitlab.com/timofurrer), Senior Backend Engineer chez GitLab, a soutenu la nomination. « En dehors de ses contributions quotidiennes au Terraform Provider et à client-go », ajoute Timo, « il aide directement les clients GitLab dans leur parcours IaC en montrant ce qui est possible avec le GitLab Terraform Provider. »

Patrick est Enterprise Architect chez Kingland et membre de la [GitLab Community Core Team](https://about.gitlab.com/community/core-team/). Cela marque son deuxième prix de contributeur notable, ayant [précédemment remporté ce prix dans GitLab 15.8](https://about.gitlab.com/releases/2023/01/22/gitlab-15-8-released/#mvp) en janvier 2023.

Merci à Patrick pour ses contributions soutenues et son dévouement à l'accompagnement des clients GitLab et au développement de notre communauté open source !

## Fonctionnalités principales {#primary-features}

### La sélection de modèles GitLab Duo est désormais en disponibilité générale {#gitlab-duo-model-selection-now-generally-available}

<!-- categories: Model Personalization -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18818)

{{< /details >}}

La sélection de modèles GitLab Duo est désormais en disponibilité générale, offrant aux organisations un meilleur contrôle sur les modèles d'IA qui alimentent leurs workflows de développement.

Les propriétaires de groupes principaux sur GitLab.com et les administrateurs sur Self-Managed et Dedicated peuvent désormais choisir un modèle spécifique parmi une variété de fournisseurs de modèles d'IA GitLab pour une utilisation avec leurs fonctionnalités GitLab Duo, accessibles via la passerelle d'IA hébergée par GitLab.

Les utilisateurs GitLab appartenant à plusieurs espaces de nommage sur GitLab.com peuvent désormais également définir un espace de nommage par défaut pour garantir des préférences de modèles d'IA cohérentes dans tous les contextes de développement. Pour en savoir plus sur la sélection de modèles GitLab Duo, [lisez le blog](https://about.gitlab.com/blog/speed-meets-governance-model-selection-comes-to-gitlab-duo/).

### Graphe de connaissances GitLab {#gitlab-knowledge-graph}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](https://gitlab-org.gitlab.io/rust/knowledge-graph/) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17514)

{{< /details >}}

Le graphe de connaissances GitLab fournit une intelligence de code enrichie dans l'ensemble de votre base de code. Les développeurs et développeuses peuvent comprendre et naviguer dans leurs projets avec un meilleur contexte, facilitant ainsi la planification des modifications, l'analyse d'impact et la collaboration avec les agents GitLab Duo pour accélérer les tâches de développement.

La plateforme d'agents GitLab Duo exploite le graphe de connaissances pour améliorer la précision des agents d'IA. En cartographiant les fichiers et les définitions dans une base de code, le graphe de connaissances fournit un contexte enrichi qui permet aux agents Duo de comprendre les relations dans l'ensemble de votre workspace local, ouvrant la voie à des réponses plus rapides et plus précises aux questions complexes.

Cette release du graphe de connaissances se concentre sur l'indexation locale du code, où le CLI transforme votre base de code en une base de données graphique en direct et intégrable pour le RAG. Vous pouvez l'installer avec un simple script en une ligne, analyser des dépôts locaux et vous connecter via MCP pour interroger votre workspace.

Notre vision pour le projet graphe de connaissances est double : construire une édition communautaire dynamique que les développeurs et développeuses peuvent exécuter localement dès aujourd'hui, qui servira de base à un futur service de graphe de connaissances pleinement intégré dans GitLab.com et les instances self-managed.

Cette fonctionnalité est en version bêta. Donnez votre avis dans le [ticket 160](https://gitlab.com/gitlab-org/rust/knowledge-graph/-/issues/160).

### La sélection de modèles par les utilisateurs finaux est désormais disponible avec GitLab Duo {#end-user-model-selection-now-available-with-gitlab-duo}

<!-- categories: Model Personalization -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19251)

{{< /details >}}

La sélection de modèles GitLab Duo pour les utilisateurs finaux est désormais en version bêta publique sur GitLab.com. Les utilisateurs peuvent désormais sélectionner leur modèle préféré pour GitLab Duo Agentic Chat directement dans l'interface GitLab, offrant aux développeurs et développeuses un contrôle personnalisé sur leur expérience d'assistance par IA.

Lorsque les propriétaires d'espaces de nommage sur GitLab.com l'autorisent, les utilisateurs finaux peuvent choisir parmi les modèles disponibles des fournisseurs d'IA GitLab pour une utilisation avec GitLab Duo Agentic Chat. Les propriétaires d'espaces de nommage peuvent continuer à définir des préférences de modèles à l'échelle de l'organisation via les paramètres d'espace de nommage, ou autoriser la sélection de modèles par les utilisateurs finaux.

Pour commencer, recherchez le menu déroulant de modèles dans GitLab Duo Agentic Chat pour sélectionner votre modèle préféré. Notez que le changement de modèle démarrera une nouvelle conversation, et vos préférences seront mémorisées pour les sessions futures.

### Les jetons de job CI/CD peuvent authentifier les requêtes Git push {#cicd-job-tokens-can-authenticate-git-push-requests}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../ci/jobs/ci_job_token.md#allow-git-push-requests-to-your-project-repository) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/389060)

{{< /details >}}

Vous pouvez désormais autoriser les jetons de job CI/CD générés dans votre projet à authentifier les requêtes Git push vers le dépôt du projet. Activez cette option avec les paramètres des autorisations de jeton de job dans l'interface, ou alternativement avec le paramètre `[ci_push_repository_for_job_token_allowed](../../api/projects.md#edit-a-project)` dans le endpoint de l'API REST du projet.

### Exclusion de contexte GitLab Duo {#gitlab-duo-context-exclusion}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo/context.md#exclude-context-from-code-review) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17124)

{{< /details >}}

L'exclusion de contexte GitLab Duo vous permet de contrôler quel contenu de projet est exclu en tant que contexte pour GitLab Duo. Cela est utile pour protéger les informations sensibles telles que les fichiers de mots de passe et les fichiers de configuration. Vous pouvez exclure des fichiers individuels, des répertoires spécifiques, des types de fichiers spécifiques, ou toute combinaison de ces éléments.

Cette fonctionnalité est actuellement en version bêta. Donnez votre avis sur l'exclusion de contexte GitLab Duo dans le [ticket 566244](https://gitlab.com/gitlab-org/gitlab/-/issues/566244).

### Prise en charge étendue des régions AWS pour GitLab Dedicated {#expanded-aws-region-support-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)

{{< /details >}}

GitLab Dedicated prend désormais en charge le déploiement dans toutes les régions AWS, vous permettant de choisir parmi une [liste étendue de régions](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions) pour votre emplacement de déploiement principal, secondaire et de sauvegarde.

Cette expansion est rendue possible par le déploiement par AWS des disques io2 dans toutes les régions, qui répondent aux normes de GitLab Dedicated en matière de haute disponibilité et de reprise après sinistre.

Toutes les nouvelles régions disponibles peuvent être sélectionnées lors du provisionnement de votre instance GitLab Dedicated dans Switchboard.

### Simulation de pipelines CI/CD sur différentes branches {#simulate-cicd-pipelines-against-different-branch}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../ci/pipeline_editor/_index.md#validate-cicd-configuration) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/482676)

{{< /details >}}

Auparavant, lors de l'utilisation de l'éditeur de pipeline et de la validation de vos modifications via l'onglet Validate, vous ne pouviez exécuter une simulation que pour la branche par défaut. Dans cette release, nous avons étendu cette fonctionnalité. Vous pouvez désormais sélectionner n'importe quelle branche pour simuler des pipelines. Cette amélioration vous offre une plus grande flexibilité dans le test et la validation de vos pipelines. Vous pouvez vous assurer qu'ils fonctionnent comme prévu dans différents cas, y compris vos branches stables ou vos branches de fonctionnalités.

## Agentic Core {#agentic-core}

### Revue de code Duo automatique pour les groupes et les applications {#automatic-duo-code-review-for-groups-and-applications}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)

{{< /details >}}

Vous pouvez désormais utiliser les paramètres de groupe ou d'application pour activer la revue de code Duo automatique pour plusieurs projets. Cela peut vous aider à activer rapidement la revue de code Duo pour tous les projets d'un groupe, plutôt que d'activer individuellement des projets spécifiques.

Cette fonctionnalité est actuellement disponible dans GitLab.com, et nous prévoyons de la rendre disponible pour GitLab Self-Managed dans une prochaine release. Donnez votre avis dans le [ticket 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Modèles supplémentaires pris en charge pour GitLab Duo Self-Hosted {#additional-supported-models-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16742)

{{< /details >}}

Les clients GitLab Self-Managed disposant de GitLab Duo Enterprise peuvent désormais utiliser des modèles supplémentaires pris en charge avec GitLab Duo. OpenAI GPT-5 est désormais pris en charge sur Azure OpenAI. Les modèles open source OpenAI GPT OSS 20B et 120B sont également désormais pris en charge sur vLLM et Azure OpenAI. Pour laisser un retour sur l'utilisation de ces modèles avec GitLab Duo Self-Hosted, consultez le [ticket 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918).

### La revue de code Duo sur GitLab Duo Self-Hosted est en disponibilité générale {#duo-code-review-on-gitlab-duo-self-hosted-is-generally-available}

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/_index.md#gitlab-duo) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/548975)

{{< /details >}}

GitLab Duo Code Review sur GitLab Duo Self-Hosted est désormais en disponibilité générale. Utilisez Code Review sur GitLab Duo Self-Hosted pour accélérer votre processus de développement sans compromettre la souveraineté des données. Lorsque Code Review examine vos merge requests, il identifie les bugs potentiels et suggère des améliorations que vous pouvez appliquer directement. Utilisez Code Review pour itérer et améliorer vos modifications avant de demander à un humain de les examiner. Cette fonctionnalité inclut la prise en charge des familles de modèles Mistral, Meta Llama, Anthropic Claude et OpenAI GPT.

Donnez votre avis sur Code Review dans le [ticket 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

## DevOps et sécurité unifiés {#unified-devops-and-security}

### La détection des secrets dans les pipelines exclut désormais certains fichiers et répertoires par défaut {#pipeline-secret-detection-now-excludes-certain-files-and-directories-by-default}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/560147)

{{< /details >}}

La détection des secrets dans les pipelines exclut désormais automatiquement [certains types de fichiers et répertoires](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items) s'ils ont une faible probabilité de contenir des secrets, améliorant ainsi les performances d'analyse. Ces modifications sont publiées dans l'analyseur [version 7.11.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.11.0).

### Améliorations de la récupération Git par l'analyseur de détection des secrets {#secret-detection-analyzer-git-fetching-improvements}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/secret_detection/pipeline/_index.md#how-the-analyzer-fetches-commits) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17315)

{{< /details >}}

La version [7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v[7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.12.0)) de l'analyseur de détection des secrets apporte des améliorations significatives à la façon dont les commits Git sont récupérés. L'analyseur analyse désormais les options `--depth` et `--since` transmises depuis `SECRET_DETECTION_LOG_OPTIONS`, afin que vous puissiez préciser davantage le nombre de commits à analyser. L'analyseur sélectionne également des stratégies de récupération appropriées en fonction du contexte, ce qui évite un problème connu où des millions de commits pouvaient être récupérés inutilement, même avec des configurations de profondeur superficielle.

Cette amélioration réduit les délais d'expiration des jobs, diminue la consommation de ressources et offre des performances d'analyse plus prévisibles. Profitez d'analyses de détection des secrets plus rapides, notamment dans les grands dépôts, avec une journalisation plus claire correspondant au comportement de récupération réel.

### Analyse SAST avancée significativement plus rapide {#significantly-faster-advanced-sast-scanning}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16561)

{{< /details >}}

Chaque minute compte lorsque vous activez des analyses de sécurité dans vos merge requests et vos pipelines. Nous livrons régulièrement des améliorations de performance pour Advanced SAST, ciblant à la fois le moteur et ses règles de détection.

Dans cette release, nous mettons en avant une amélioration spécifique qui réduit le temps d'exécution de l'analyse jusqu'à 78 % dans nos benchmarks et tests réels. Nous avons ajouté une mise en cache dans une partie sensible aux performances du processus d'analyse, ce qui conduit à des analyses significativement plus rapides dans les grands dépôts.

Cette amélioration est automatiquement activée dans la version 2.9.6 et ultérieure de l'analyseur Advanced SAST. Vous pouvez voir quelle version de l'analyseur vous utilisez en [consultant les job logs d'analyse](../../user/application_security/sast/gitlab_advanced_sast.md).

### Configuration du seuil de gravité pour l'analyse opérationnelle des conteneurs {#operational-container-scanning-severity-threshold-configuration}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/559278)

{{< /details >}}

Vous pouvez désormais configurer l'analyse opérationnelle des conteneurs (OCS) pour ne retourner que les vulnérabilités atteignant ou dépassant un certain niveau de gravité. Après avoir défini un seuil de gravité, les vulnérabilités inférieures à la gravité choisie ne sont plus retournées dans le rapport de vulnérabilités, les charges utiles de l'API et les autres mécanismes de reporting. Cela peut vous aider à vous concentrer sur les vulnérabilités que vous souhaitez corriger.

Pour activer ce filtrage, [définissez un `severity_threshold`](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter) dans votre configuration OCS.

Nous remercions chaleureusement [John Walsh](https://gitlab.com/mjohnw) pour cette contribution communautaire. Pour en savoir plus sur la contribution à GitLab, consultez le [programme de contribution communautaire](https://about.gitlab.com/community/contribute/).

### Publier des modules et des fournisseurs OpenTofu dans le registre de conteneurs GitLab avec des templates CI/CD {#publish-opentofu-modules-and-providers-to-the-gitlab-container-registry-with-cicd-templates}

<!-- categories: Infrastructure as Code -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](https://gitlab.com/components/opentofu#publish-providers-to-the-gitlab-oci-registry) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/562715)

{{< /details >}}

Le registre de conteneurs GitLab prend désormais en charge les types de médias pour héberger des modules et des fournisseurs OpenTofu.

La version [3.1.0](https://gitlab.com/components/opentofu/-/releases/[3.1.0](https://gitlab.com/components/opentofu/-/releases/3.1.0)) du [composant CI/CD OpenTofu](https://gitlab.com/components/opentofu) prend en charge un nouveau template `provider-release` pour déployer un fournisseur OpenTofu dans le registre GitLab au format OCI. Désormais, vous pouvez héberger des fournisseurs OpenTofu privés directement dans GitLab.

De plus, le template `module-release` prend désormais en charge un nouvel input `type` que vous pouvez définir sur `oci` pour déployer le module OpenTofu dans le registre GitLab au format OCI.

### Contournement de la confirmation pour les utilisateurs enterprise lors de la réaffectation des espaces réservés {#bypass-confirmation-for-enterprise-users-when-reassigning-placeholders}

<!-- categories: Importers -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/import/mapping/reassignment.md#bypass-confirmation-when-reassigning-placeholder-users) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17871)

{{< /details >}}

Les utilisateurs disposant du rôle Owner pour un groupe peuvent désormais contourner la confirmation des utilisateurs lors de la réaffectation des espaces réservés aux utilisateurs enterprise actifs de ce groupe. Ainsi, les utilisateurs enterprise n'ont plus besoin de vérifier continuellement leurs e-mails pour confirmer les réaffectations. Une fois la limite de temps du paramètre atteinte, les demandes de confirmation par e-mail sont à nouveau envoyées pour toutes les nouvelles réaffectations.

Les utilisateurs enterprise reçoivent toujours des e-mails de notification une fois la réaffectation terminée, garantissant la transparence tout au long du processus.

### Configurer la façon d'afficher les tickets depuis la page Tickets {#configure-how-to-view-issues-from-the-issues-page}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/issues/managing_issues.md#open-issues-in-a-panel) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/570776)

{{< /details >}}

Vous avez désormais un contrôle total sur votre vue de la page de liste : choisissez quelles métadonnées s'affichent et si les éléments de travail s'ouvrent dans un panneau latéral, facilitant ainsi la concentration sur les informations les plus importantes pour vous.

Auparavant, tous les champs de métadonnées étaient toujours visibles, ce qui pouvait rendre la consultation des éléments de travail fastidieuse. Vous pouvez désormais personnaliser votre vue en activant ou désactivant des champs spécifiques tels que les personnes assignées, les labels, les dates et les jalons.

Grâce au nouveau bouton de basculement entre la vue en panneau latéral et la navigation en pleine page, vous pouvez examiner rapidement les détails tout en conservant le contexte de votre liste, ou ouvrir la page complète lorsque vous avez besoin de plus d'espace pour une édition détaillée et une navigation complète.

### Filtrage parent amélioré pour les listes d'epics et de tickets {#enhanced-parent-filtering-for-epic-and-issue-lists}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/issues/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/556200)

{{< /details >}}

Nous avons remplacé le filtre « epic » sur les pages Tickets et Epics par un filtre « parent » plus flexible. Ce changement vous permet de filtrer par n'importe quel élément de travail parent, pas seulement les epics. Vous pouvez désormais trouver facilement les tâches enfants en filtrant par leur ticket parent, ou trouver des tickets en filtrant par leur epic parent, offrant ainsi une meilleure visibilité sur votre hiérarchie de travail dans les listes de tickets et d'epics.

### Les tableaux des tickets affichent désormais les hiérarchies d'epics complètes {#issue-boards-now-show-complete-epic-hierarchies}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/issue_board.md#filter-issues) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/358416)

{{< /details >}}

Vous pouvez désormais afficher tous les tickets des epics enfants lors du filtrage par un epic parent dans les tableaux des tickets, en cohérence avec le fonctionnement de la page Tickets. Cette amélioration vous aide à mieux suivre et visualiser votre hiérarchie d'epics complète sans manquer aucun ticket imbriqué dans les epics enfants, rendant ainsi votre workflow de gestion de projet plus efficace et fiable.

### Parité des barres d'outils des éditeurs de texte {#text-editors-toolbar-parity}

<!-- categories: Markdown -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/rich_text_editor.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/507377)

{{< /details >}}

L'éditeur de texte brut GitLab inclut désormais les mêmes options de formatage que l'éditeur de texte enrichi. La barre d'outils de l'éditeur de texte brut a été mise à jour avec un menu « Plus d'options » qui donne accès à des outils de formatage avancés tels que :

- Blocs de code
- Blocs Détails
- Règles horizontales
- Diagrammes Mermaid
- Diagrammes PlantUML
- Table des matières

Les deux éditeurs disposent désormais d'un placement cohérent des boutons et de séparateurs, facilitant le passage d'un mode d'édition à l'autre tout en conservant l'accès aux options de formatage habituelles.

### Les détails de la vulnérabilité affichent l'ID du pipeline de résolution automatique {#vulnerability-details-shows-the-auto-resolve-pipeline-id}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/policies/vulnerability_management_policy.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/566392)

{{< /details >}}

Lors du dépannage des vulnérabilités qui ont été automatiquement résolues, puis redétectées, il peut être utile de comparer le pipeline actuel au pipeline dans lequel la vulnérabilité a été résolue.

Si une vulnérabilité est automatiquement résolue, les notes de vulnérabilité sur la page des détails de la vulnérabilité incluent désormais l'ID du pipeline où elle s'est produite.

### Contrôles améliorés sur les personnes autorisées à télécharger les artefacts de job {#enhanced-controls-for-who-can-download-job-artifacts}

<!-- categories: Artifact Security -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../ci/yaml/_index.md#artifactsaccess) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/454398)

{{< /details >}}

Dans GitLab 16.11, nous avons ajouté le mot-clé `artifacts:access` permettant aux utilisateurs de contrôler si les artefacts peuvent être téléchargés par tous les utilisateurs ayant accès au pipeline, uniquement par les utilisateurs disposant du rôle Developer ou supérieur, ou par aucun utilisateur.

Dans cette release, vous pouvez désormais restreindre le téléchargement des artefacts aux seuls utilisateurs disposant du rôle Maintainer ou supérieur, vous offrant une option supplémentaire pour contrôler qui peut télécharger les artefacts de job.

### GitLab Runner 18.4 {#gitlab-runner-184}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 18.4 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Corrections de bugs {#bug-fixes}

- [Les runners FIPS échouent à démarrer des jobs avec GitLab Runner 18.2.1](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38963)
- [La commande `chown` pour les runners avec ConfigMap personnalisé et contraintes de contexte de sécurité (SCC) échoue après la mise à niveau vers Operator v1.37.0 sur OpenShift 4.16.27](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/246)
- [Rétablissement de `FF_RETRIEVE_POD_WARNING_EVENTS` dans les releases GitLab 17.x.x en raison d'une suppression anticipée dans la version 17.2](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38851)
- [Tous les jobs GitLab Runner échouent en raison d'erreurs de permissions sur le système de fichiers](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/214)
- [Les jobs de build échouent de façon intermittente avec une erreur d'accès refusé](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37464)
- [La mise à niveau du chart Helm GitLab Runner a corrompu les variables](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30851)
- [L'activation de `FF_USE_FASTZIP` n'active pas fastzip](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28989)
- [GitLab Runner rencontre une erreur `UnsupportedOperation` lors de la tentative d'arrêt d'instances Spot créées avec des requêtes ponctuelles](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28865)
- [Le long polling pour les runners GitLab ne fonctionne pas correctement dans les environnements déployés sur Kubernetes](https://gitlab.com/gitlab-org/gitlab/-/issues/331460)
- [Permettre aux administrateurs de remplacer la valeur image:Kubernetes:user](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38894)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.4)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
