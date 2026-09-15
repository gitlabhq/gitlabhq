---
stage: Release Notes
group: Monthly Release
date: 2025-07-17
title: "Notes de release de GitLab 18.2"
description: "GitLab 18.2 publié avec la Duo Agent Platform dans l'IDE (version bêta)"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 17 juillet 2025, GitLab 18.2 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Markus Siebert {#this-months-notable-contributor-markus-siebert}

[Markus Siebert](https://gitlab.com/m-s-db), ingénieur de plateforme chez DB Systel GmbH, dirige l'effort communautaire visant à intégrer la prise en charge native d'AWS Secrets Manager dans GitLab CI/CD, répondant ainsi à un besoin critique des entreprises en matière de gestion sécurisée des secrets dans les pipelines. Fort de 172 activités documentées en seulement 6 semaines, Markus a travaillé sans relâche à la mise en œuvre de la prise en charge d'AWS Secrets Manager et d'AWS Systems Manager Parameter Store à travers plusieurs merge requests, notamment [Add functionality to retrieve secrest from AWS Secrets Manager](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5587), [Add GitLab CI config entry for AWS SSM ParameterStore](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191803) et [Documentation for AWS Secrets Manager](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192378).

« Le travail de Markus permet directement aux utilisateurs de GitLab dans les environnements AWS de gérer leurs secrets CI/CD de manière sécurisée sans recourir à des outils tiers ou à des scripts personnalisés. Cela est particulièrement précieux pour les utilisateurs en entreprise qui ont standardisé leurs services sur AWS », déclare [Aditya Tiwari](https://gitlab.com/atiwari71), ingénieur backend senior, Secure chez GitLab, qui a proposé la candidature de Markus.

L'engagement de Markus à mener cette fonctionnalité à bien — de la mise en œuvre initiale jusqu'à la documentation — tout en assurant activement la maintenance et l'amélioration des merge requests sur la base des retours reçus, illustre le meilleur de la contribution communautaire et démontre la puissance du développement participatif pour améliorer GitLab pour les utilisateurs AWS.

Cette contribution a été réalisée dans le cadre du [programme GitLab Co-Create](https://about.gitlab.com/community/co-create/).

Merci à Markus pour ses précieuses contributions à GitLab !

## Fonctionnalités principales {#primary-features}

### Duo Agent Platform dans l'IDE (version bêta) {#duo-agent-platform-in-the-ide-beta}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Core, Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/duo_agent_platform/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/556038)

{{< /details >}}

La Duo Agent Platform intègre le chat agentique et les flows d'agents directement dans VS Code et les IDE JetBrains, permettant une interaction conversationnelle naturelle avec votre base de code et vos projets GitLab.

Le chat agentique est conçu pour les tâches rapides et conversationnelles, comme la création et la modification de fichiers, la recherche dans votre base de code avec la correspondance de patterns et grep, et l'obtention de réponses immédiates sur votre code. Les flows d'agents gèrent les implémentations plus importantes et la planification globale, transformant des idées de haut niveau en architecture tout en accédant aux ressources GitLab, notamment les tickets, les merge requests, les commits, les pipelines CI/CD et les vulnérabilités de sécurité. Les deux offrent des capacités de recherche intelligente pour la documentation, les patterns de code et la découverte de projets, afin de vous aider à accomplir tout, des modifications rapides aux analyses de projets complexes.

La plateforme prend également en charge le Model Context Protocol (MCP) pour la connexion à des sources de données et des outils externes, permettant aux fonctionnalités d'IA d'exploiter un contexte au-delà de GitLab.

Pour en savoir plus, consultez notre blog [GitLab Duo Agent Platform Public Beta : Next-gen AI orchestration and more](https://about.gitlab.com/blog/gitlab-duo-agent-platform-public-beta/).

Pour commencer, consultez la [documentation de la Duo Agent Platform](../../user/duo_agent_platform/_index.md), le [guide de configuration VS Code](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-vs-code) et le [guide de configuration JetBrains](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-jetbrains-ides).

### Statuts de workflow personnalisés pour les tickets et les tâches {#custom-workflow-statuses-for-issues-and-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/work_items/status.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14794)

{{< /details >}}

Dépassez le système basique ouvert/fermé grâce à des statuts configurables qui vous permettent de suivre les éléments de travail à travers les étapes réelles du workflow de votre équipe.

Au lieu de vous appuyer sur des labels, vous pouvez désormais définir des statuts personnalisés qui reflètent précisément votre processus. Avec les statuts configurables, vous pouvez :

- **Define custom workflows** qui correspondent au processus réel de votre équipe.
- **Replace workflow labels** par des statuts appropriés, plus faciles à trouver, à mettre à jour et à rapporter.
- **Clarify completion outcomes** au-delà de la fermeture d'un ticket en utilisant « Terminé » ou « Annulé ».
- **Filter and report accurately** sur le statut des éléments de travail pour de meilleures informations sur le projet.
- **Use status in issue boards** avec des mises à jour automatiques lorsque les tickets se déplacent entre les colonnes.
- **Bulk update status** sur plusieurs éléments de travail pour une gestion efficace du workflow.
- **Track dependencies** avec la visibilité des statuts pour les éléments de travail liés.

Les statuts de workflow personnalisés prennent également en charge les **quick actions in comments** et se synchronisent automatiquement avec le système ouvert/fermé de GitLab.

Aidez-nous à améliorer cette fonctionnalité en partageant vos idées et suggestions dans notre [ticket de feedback](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235).

### Nouvelle page d'accueil des merge requests {#new-merge-request-homepage}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/merge_requests/homepage.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13448)

{{< /details >}}

La gestion des revues de code sur plusieurs projets peut s'avérer difficile lorsque vous jonglез avec des dizaines de merge requests en tant qu'auteur et relecteur.

La nouvelle page d'accueil des merge requests transforme la façon dont vous naviguez dans votre charge de travail de revue en priorisant intelligemment ce qui nécessite votre attention immédiate, avec deux modes d'affichage puissants :

- **Workflow view** organise les merge requests par état de revue, en regroupant le travail selon son étape dans le workflow de revue de code.
- **Role view** regroupe vos merge requests selon que vous êtes l'auteur ou le relecteur, vous offrant une séparation claire des responsabilités.

L'onglet **Actif** affiche les merge requests nécessitant une attention, **Fusionnées** affiche les travaux récemment terminés et **Rechercher** fournit des capacités de filtrage complètes.

La nouvelle page d'accueil élargit également votre visibilité en combinant les merge requests rédigées et assignées, vous assurant de ne jamais manquer un travail qui vous a été délégué.

### Améliorer la sécurité avec les tags de conteneurs immuables (version bêta) {#improve-security-with-immutable-container-tags-beta}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../user/packages/container_registry/immutable_container_tags.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15139)

{{< /details >}}

Les registres de conteneurs sont une infrastructure critique pour les équipes DevSecOps modernes. Cependant, même avec des tags de conteneurs protégés, les organisations font toujours face à un défi : une fois qu'un tag est créé, les utilisateurs disposant des permissions suffisantes peuvent le modifier. Cela crée des risques pour les équipes qui s'appuient sur des versions spécifiques taguées des images de conteneurs pour la stabilité en production. Toute modification — même par des utilisateurs autorisés — peut introduire des changements non intentionnels ou compromettre l'intégrité du déploiement.

Avec les tags de conteneurs immuables, vous pouvez protéger les images de conteneurs contre les modifications non intentionnelles. Une fois qu'un tag correspondant à une règle d'immuabilité est créé, personne ne peut modifier l'image de conteneur. Vous pouvez désormais :

- Créer jusqu'à 5 règles de protection au total par projet (combinant les règles protégées et immuables) en utilisant des patterns regex RE2.
- Protéger les tags critiques tels que latest, les versions sémantiques (par exemple, v1.0.0) ou les release candidates contre toute modification.
- S'assurer que les tags immuables sont automatiquement exclus des politiques de nettoyage.

Les tags de conteneurs immuables nécessitent le registre de conteneurs de nouvelle génération, qui est activé par défaut sur GitLab.com. Pour les instances GitLab Self-Managed, vous devez activer la [base de données de métadonnées](../../administration/packages/container_registry_metadata_database.md) pour utiliser les tags de conteneurs immuables.

### Contrôles de groupe et de projet pour Premium et Ultimate avec GitLab Duo {#group-and-project-controls-for-premium-and-ultimate-with-gitlab-duo}

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/gitlab_duo/turn_on_off.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/551895)

{{< /details >}}

Les utilisateurs de GitLab Premium et Ultimate peuvent désormais modifier la disponibilité de Code Suggestions et de GitLab Duo Chat dans l'IDE pour les groupes et les projets. Auparavant, vous pouviez uniquement modifier la disponibilité pour l'instance ou le groupe principal.

### Nouveau tableau de bord de conformité de la vue d'ensemble du groupe {#new-group-overview-compliance-dashboard}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_overview_dashboard.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13909)

{{< /details >}}

Le centre de conformité est l'emplacement central permettant aux équipes de conformité de gérer leurs rapports de statut de conformité, leurs rapports de violations et leurs cadres de conformité pour leur groupe.

Le nouveau tableau de bord de conformité de la vue d'ensemble du groupe fournit aux responsables de la conformité une vue agrégée des informations de conformité pour tous les projets d'un groupe. Cette première itération affiche les informations suivantes :

- % de projets couverts par un certain cadre de conformité.
- % d'exigences échouées pour tous les projets d'un groupe.
- % de contrôles échoués pour tous les projets d'un groupe.
- Les cadres spécifiques qui nécessitent une « attention ».

Avec cette nouvelle vue d'ensemble du groupe, les responsables de la conformité disposent désormais d'une vue unifiée unique qui leur offre une image claire de haut niveau de leur posture de conformité.

### Mapper les agents Kubernetes de workspace pour l'instance {#map-workspace-kubernetes-agents-for-the-instance}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../user/workspace/gitlab_agent_configuration.md#allow-a-cluster-agent-for-workspaces-on-the-instance) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16485)

{{< /details >}}

Les administrateurs GitLab peuvent désormais mapper les agents Kubernetes de workspace activés pour l'instance. Les utilisateurs peuvent ensuite créer des workspaces depuis n'importe quel groupe ou projet de cette instance.

Cela augmente considérablement l'évolutivité des workspaces en permettant aux organisations de provisionner les agents Kubernetes de workspace une seule fois et de rendre ces agents accessibles à tous les projets actuels et futurs de l'ensemble de l'instance.

### Télécharger un export PDF des rapports de sécurité {#download-a-pdf-export-of-security-reports}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/security_dashboard/_index.md#export-as-pdf) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16989)

{{< /details >}}

Pour communiquer l'état et la progression de vos efforts de gestion des vulnérabilités aux autres parties prenantes, vous pouvez désormais exporter le tableau de bord de sécurité de chaque projet ou groupe sous forme de document PDF.

### Gestion centralisée des politiques de sécurité (version bêta) {#centralized-security-policy-management-beta}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md#set-up-centralized-security-policy-management) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17392)

{{< /details >}}

Dans les grandes organisations où la conformité est critique, les équipes peinent souvent à gérer des politiques fragmentées dispersées dans plusieurs projets et groupes. Sans visibilité centralisée, assurer une application cohérente devient un défi chronophage qui augmente le risque de non-conformité.

La gestion centralisée des politiques de sécurité introduit une approche unifiée pour créer, gérer et appliquer les politiques de sécurité dans toute votre organisation GitLab via un groupe de conformité et de politique de sécurité (CSP) désigné. Cela permet aux équipes de sécurité de :

- **Define policies once and apply everywhere** : créer des politiques de sécurité à l'échelle de l'instance une seule fois via le CSP et les appliquer automatiquement à tous les groupes et projets.
- **Configure business unit policies** : les groupes principaux peuvent configurer leur propre ensemble distinct de politiques tout en héritant des politiques organisationnelles du groupe CSP.
- **Ensure adherence to principle of least privilege** : établir une couche centrale de gestion des politiques appliquée pour l'instance.

Cette version bêta établit le cadre fondateur pour la gestion centralisée des politiques, avec la prise en charge de tous les types de politiques de sécurité existants, configurables pour les groupes, les projets ou l'instance.

## Agentic Core {#agentic-core}

### Mistral Small désormais disponible pour GitLab Duo Self-Hosted {#mistral-small-now-available-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18202)

{{< /details >}}

Vous pouvez désormais utiliser Mistral Small sur GitLab Duo Self-Hosted. Ce modèle est disponible sur les instances GitLab Self-Managed et constitue le premier modèle open source entièrement compatible avec GitLab Duo Chat et Code Suggestions sur GitLab Duo Self-Hosted.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Les administrateurs peuvent réassigner des contributions sans confirmation de l'utilisateur {#administrators-can-reassign-contributions-without-user-confirmation}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/523259)

{{< /details >}}

Les administrateurs peuvent désormais réassigner des contributions d'utilisateurs fictifs à des utilisateurs actifs sans confirmation de l'utilisateur. Cette fonctionnalité répond à un défi majeur pour les grandes organisations, où le processus était bloqué lorsque les utilisateurs ne consultaient pas leurs e-mails pour approuver les réassignations.

Sur les instances GitLab où l'usurpation d'identité des utilisateurs est activée, les administrateurs peuvent maintenir l'intégrité des données tout en rationalisant les workflows de gestion des utilisateurs. Les utilisateurs reçoivent toujours des e-mails de notification une fois la réassignation terminée, assurant la transparence tout au long du processus.

### Réassigner depuis des utilisateurs fictifs vers des utilisateurs inactifs {#reassign-from-placeholder-users-to-inactive-users}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/523260)

{{< /details >}}

Auparavant, les administrateurs pouvaient uniquement réassigner des contributions et des appartenances d'utilisateurs fictifs à des utilisateurs actifs.

Sur GitLab Self-Managed, les administrateurs peuvent désormais également réassigner des contributions et des appartenances d'utilisateurs fictifs à des utilisateurs inactifs. Cette fonctionnalité vous permet de préserver l'historique des contributions et les informations d'appartenance des utilisateurs bloqués, bannis ou désactivés sur votre instance GitLab.

Les administrateurs doivent d'abord activer ce paramètre et, une fois activé, ce paramètre rationalise la gestion des utilisateurs en ignorant la confirmation de l'utilisateur lors de la réassignation tout en maintenant un contrôle d'accès sécurisé.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Prise en charge du Container Scanning pour les images de conteneurs multi-architecture {#container-scanning-support-for-multi-architecture-container-images}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/container_scanning/_index.md#available-cicd-variables) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/543144)

{{< /details >}}

Le Container Scanning inclut désormais des variantes d'images de conteneurs Linux Arm64. Lors d'une exécution sur un runner Linux Arm64, l'analyseur n'a plus besoin d'émulation, ce qui se traduit par une analyse plus rapide. De plus, vous pouvez désormais scanner des images multi-architecture en définissant la variable d'environnement `TRIVY_PLATFORM` sur la plateforme que vous souhaitez analyser.

### Amélioration de la prise en charge des fichiers d'archive pour le Container Scanning {#improved-archive-file-support-for-container-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/container_scanning/_index.md#scanning-archive-formats) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/501077)

{{< /details >}}

GitLab 18.2 apporte une prise en charge améliorée du scan des fichiers d'archive au Container Scanning. Si une vulnérabilité dans un package particulier est détectée dans plusieurs images, vous voyez désormais une vulnérabilité attribuée à chaque image scannée.

### Prise en charge de la portée statique pour JavaScript {#static-reachability-support-for-javascript}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dependency_scanning/static_reachability.md#supported-languages-and-package-managers) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/502334)

{{< /details >}}

Composition Analysis prend désormais en charge la portée statique (Static Reachability) pour les bibliothèques JavaScript. Vous pouvez utiliser les données produites par l'accessibilité statique dans votre processus de triage et de remédiation. Les données de portée statique peuvent également être utilisées avec les scores EPSS, KEV et CVSS pour fournir une vue plus ciblée de vos vulnérabilités.

### Amélioration de la prise en charge de la vérification de la connexion DAST réussie {#improved-support-for-verifying-successful-dast-login}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dast/browser/configuration/variables.md#authentication) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/435942)

{{< /details >}}

Auparavant, la variable `DAST_AUTH_SUCCESS_IF_AT_URL` nécessitait une correspondance exacte de l'URL pour vérifier l'authentification réussie. Cela fonctionnait bien pour les applications avec des pages de destination statiques, mais posait des difficultés pour les applications où les URL post-connexion contiennent des éléments dynamiques pour chaque connexion.

Désormais, vous pouvez utiliser des patterns génériques dans la variable `DAST_AUTH_SUCCESS_IF_AT_URL` pour correspondre aux patterns d'URL dynamiques. Cette amélioration offre la flexibilité nécessaire pour vérifier le succès de l'authentification, même lorsque l'URL exacte change entre les sessions.

### Prise en charge DAST pour l'authentification multifacteur par mot de passe à usage unique basé sur le temps {#dast-support-for-time-based-one-time-password-mfa}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dast/browser/configuration/authentication.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13633)

{{< /details >}}

L'analyse dynamique prend désormais en charge l'authentification multifacteur (MFA) par mot de passe à usage unique basé sur le temps (TOTP).

Vous pouvez exécuter des scans DAST sur des projets avec le MFA TOTP activé pour garantir des tests de sécurité complets. Cette amélioration fournit des résultats de scan plus précis en testant les applications dans des configurations qui reproduisent les environnements de production où le MFA est déployé.

### Désactiver le streaming vers une destination de streaming d'audit {#deactivate-streaming-to-an-audit-streaming-destination}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../administration/compliance/audit_event_streaming.md#activate-or-deactivate-streaming-destinations) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/537096)

{{< /details >}}

Auparavant, il n'existait aucun moyen de désactiver temporairement le streaming vers une destination de streaming d'audit. Vous pourriez avoir besoin de le faire pour plusieurs raisons, notamment pour résoudre des problèmes de connectivité du flux ou pour apporter des modifications à la configuration sans supprimer la configuration et recommencer.

Avec GitLab 18.2, nous avons ajouté la possibilité de basculer un flux d'audit entre l'état actif et inactif. Lorsque le flux d'audit est inactif, les événements d'audit ne sont plus diffusés vers la destination choisie. Lorsqu'il est réactivé, les événements d'audit sont à nouveau diffusés vers la destination choisie.

### Fonctionnalité de filtrage pour toutes les destinations de streaming d'audit {#filter-functionality-for-all-audit-streaming-destinations}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/audit_event_streaming.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/524939)

{{< /details >}}

Auparavant, certaines destinations de streaming d'audit ne disposaient pas de toutes les capacités de filtrage disponibles.

Nous prenons désormais en charge la fonctionnalité de filtrage pour toutes les destinations via l'interface utilisateur, notamment la possibilité de filtrer :

- Par type d'événement d'audit.
- Par groupes ou projets.

Ce changement signifie également que les destinations d'événements d'audit telles qu'AWS et GCP peuvent désormais filtrer les événements d'audit.

### Configurer les préférences d'affichage des epics {#configure-epic-display-preferences}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/group/epics/manage_epics.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/393559)

{{< /details >}}

Vous avez désormais un contrôle total sur les métadonnées qui apparaissent lorsque vous consultez votre liste d'éléments de travail, ce qui facilite la concentration sur les informations qui vous importent le plus.

Auparavant, tous les champs de métadonnées étaient toujours visibles, ce qui pouvait rendre la consultation des éléments de travail fastidieuse. Vous pouvez désormais personnaliser votre vue en activant ou désactivant des champs spécifiques tels que les personnes assignées, les labels, les dates et les jalons.

### Ouvrir les epics dans un panneau latéral ou en pleine page sur la page Epics {#open-epics-in-a-drawer-or-the-full-page-on-the-epics-page}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/group/epics/manage_epics.md#open-epics-in-a-drawer) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/536620)

{{< /details >}}

Vous pouvez désormais choisir comment les epics s'ouvrent depuis la page de liste grâce à un nouveau bouton bascule qui alterne entre la vue en panneau latéral et la navigation en pleine page.

Utilisez le panneau latéral pour consulter rapidement les détails d'un epic tout en conservant le contexte de votre liste d'epics, ou ouvrez la pleine page lorsque vous avez besoin de plus d'espace écran pour une édition détaillée et une navigation complète.

### Assigner des [jalons](../../user/project/milestones/_index.md) aux epics pour une planification à long terme améliorée {#assign-milestones-to-epics-for-enhanced-long-term-planning}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/milestones/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/329)

{{< /details >}}

Vous pouvez désormais assigner des [jalons](../../user/project/milestones/_index.md) directement aux epics, créant une cascade de planification naturelle des initiatives stratégiques jusqu'à l'exécution. Cette amélioration vous aide à aligner les cadences de planification à plus long terme, comme la planification trimestrielle ou les incréments de programme SAFe, avec les epics. Dans le même temps, vous pouvez maintenir les itérations axées sur les sprints de développement.

Avec cette hiérarchie claire en place, vous pouvez réduire la charge administrative et obtenir une meilleure visibilité sur la progression de vos initiatives stratégiques par rapport aux calendriers organisationnels.

### Assigner des epics aux membres de l'équipe {#assign-epics-to-team-members}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/group/epics/manage_epics.md#assignees) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/4231)

{{< /details >}}

Vous pouvez désormais assigner des epics à des individus, clarifiant ainsi qui est responsable de la supervision des initiatives stratégiques. Les assignés d'epics vous aident à identifier la propriété au niveau du portefeuille, permettant une prise de décision plus rapide et une responsabilité plus claire pour les objectifs à long terme. Les équipes peuvent rapidement identifier qui contacter concernant la progression des epics, les dépendances ou les changements de portée.

### Tri et pagination pour les vues GLQL {#sorting-and-pagination-for-glql-views}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/glql/_index.md#presentation-syntax) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/502701)

{{< /details >}}

Cette release introduit un tri et une pagination améliorés pour les vues GLQL, facilitant le travail avec de grands ensembles de données.

Vous pouvez désormais trier par champs clés, notamment les dates d'échéance, l'état de santé et la popularité, pour trouver rapidement les éléments les plus pertinents. Le nouveau système de pagination « Charger plus » offre un meilleur contrôle sur le chargement des données, remplaçant les résultats en pleine page difficiles à gérer par des blocs gérables qui se chargent à la demande.

Ces améliorations aident les équipes à naviguer efficacement dans les données de projets complexes et à se concentrer sur ce qui importe le plus à un moment donné.

### Références d'éléments de travail et améliorations de l'éditeur pour GitLab Flavored Markdown {#work-item-references-and-editor-improvements-for-gitlab-flavored-markdown}

<!-- categories: Markdown -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/markdown.md#gitlab-specific-references) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/7654)

{{< /details >}}

Vous pouvez désormais référencer des tickets, des epics et des éléments de travail en utilisant une syntaxe unifiée `[work_item:123]` dans GitLab Flavored Markdown. Cette nouvelle syntaxe fonctionne en parallèle avec les formats de référence existants tels que `#123` pour les tickets et `&123` pour les epics, et prend en charge les références inter-projets avec `[work_item:namespace/project/123]`.

L'éditeur de texte brut inclut également une nouvelle [préférence pour maintenir l'indentation du curseur](../../user/profile/preferences.md#maintain-cursor-indentation) lorsque vous appuyez sur Entrée, facilitant la rédaction de contenu structuré comme les listes imbriquées et les blocs de code.

### L'ID de vulnérabilité ajouté à l'export CSV du rapport de vulnérabilités {#vulnerability-id-added-to-vulnerability-report-csv-export}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#exporting) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18033)

{{< /details >}}

Auparavant, l'export CSV du rapport de vulnérabilités n'incluait pas les ID de vulnérabilités. Vous pouvez désormais trouver l'ID de chaque vulnérabilité listée dans l'export CSV.

### Filtre de portée dans le rapport de vulnérabilités {#reachability-filter-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/543346)

{{< /details >}}

Les utilisateurs peuvent désormais filtrer les données dans le rapport de vulnérabilités pour n'inclure que les vulnérabilités accessibles. Les vulnérabilités accessibles représentent des vulnérabilités qui sont à la fois :

- Sur la liste des vulnérabilités et expositions communes (CVE).
- Faisant partie d'une bibliothèque explicitement importée.

### L'API GraphQL de vulnérabilités renvoie des informations supplémentaires {#vulnerability-graphql-api-returns-additional-information}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../api/graphql/reference/_index.md#vulnerability) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/468913)

{{< /details >}}

Vous pouvez désormais utiliser l'API GraphQL pour déterminer le pipeline lors duquel la vulnérabilité a été introduite et quand elle a été détectée pour la dernière fois. L'API GraphQL de vulnérabilités inclut désormais :

- `initialDetectedPipeline` : permet de récupérer des informations supplémentaires sur le commit concernant le moment où la vulnérabilité a été introduite, comme le nom d'utilisateur de l'auteur.
- `latestDetectedPipeline` : permet de récupérer des informations supplémentaires sur le commit concernant le moment où la vulnérabilité a été supprimée, comme le SHA du commit.

### Exceptions de patterns de branche source pour les politiques d'approbation {#source-branch-pattern-exceptions-for-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#source-branch-exceptions) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18113)

{{< /details >}}

Auparavant, les équipes utilisant GitFlow se heurtaient souvent à des blocages d'approbation lors de la fusion des branches `release/*` vers `main`, car la plupart des contributeurs avaient déjà participé au développement de la release et ne pouvaient donc pas servir d'approbateurs.

Les exceptions de patterns de branches dans les politiques d'approbation des merge requests résolvent ce problème en contournant automatiquement les exigences d'approbation pour des combinaisons spécifiques de branches source-cible. Configurez des approbations strictes pour les fusions feature-vers-main tout en permettant des workflows release-vers-main simplifiés.

**Key capabilities:**

- **Pattern-based configuration:** Définissez des patterns de branches source tels que `release/*` ou `hotfix/*` qui contournent les exigences d'approbation
- **Seamless integration:** Les exceptions de branches s'intègrent directement dans les politiques d'approbation des merge requests existantes et sont configurables via l'interface utilisateur ou le fichier `policy.yml`.

Cela élimine le besoin de solutions de contournement complexes tout en préservant les avantages en matière de sécurité des politiques d'approbation des merge requests pour les workflows de développement standard.

### Afficher les chemins de dépendances {#display-dependency-paths}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md#dependency-paths) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16815)

{{< /details >}}

Auparavant, il était difficile de déterminer si une dépendance était une dépendance directe ou une dépendance transitive importée par un descendant de la dépendance.

Vous pouvez désormais déterminer si une bibliothèque est importée directement ou transitivement grâce à la nouvelle fonctionnalité de chemins de dépendances. Vous pouvez trouver les chemins de dépendances dans la liste des dépendances du projet et du groupe, ainsi que dans les détails des vulnérabilités. Cette fonctionnalité permet aux développeurs de déterminer le chemin le plus efficace vers un correctif en fonction de la façon dont la bibliothèque est importée.

### L'inventaire des informations d'identification inclut désormais les jetons de comptes de service {#credentials-inventory-now-includes-service-account-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../administration/credentials_inventory.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/421954)

{{< /details >}}

GitLab prend désormais en charge les jetons de comptes de service dans l'inventaire des informations d'identification, vous offrant une meilleure visibilité et un meilleur contrôle sur les différentes méthodes d'authentification utilisées dans l'ensemble de votre chaîne d'approvisionnement logicielle. L'inventaire des informations d'identification fournit une image complète des informations d'identification utilisées dans toute votre organisation.

### Inventaire de sécurité pour une visibilité complète des actifs, désormais en version bêta {#security-inventory-for-comprehensive-asset-visibility-now-in-beta}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/security_inventory/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16484)

{{< /details >}}

Les équipes AppSec ont besoin d'une visibilité complète sur la posture de sécurité de leur organisation pour tous les actifs. Auparavant, les workflows de sécurité de GitLab se concentraient principalement sur la configuration du scanner au niveau du projet et les vulnérabilités au niveau du projet, ce qui rendait difficile la compréhension des lacunes de couverture et la prise de décisions de priorisation efficaces basées sur les risques.

L'inventaire de sécurité fournit une vue centralisée de la posture de sécurité sur l'ensemble de votre instance GitLab, permettant aux équipes AppSec de :

- Obtenir une visibilité complète sur la couverture de sécurité dans les projets et les groupes
- Identifier les actifs qui manquent de scans de sécurité ou présentent des lacunes de configuration
- Prendre des décisions éclairées basées sur les risques concernant où concentrer les efforts de sécurité
- Suivre les améliorations de la posture de sécurité au fil du temps

Cette fonctionnalité aide à combler le fossé entre la sécurité des projets individuels et la stratégie de sécurité à l'échelle de l'organisation, vous fournissant la base d'inventaire des actifs nécessaire pour une gestion efficace des programmes de sécurité.

### Rôle d'administrateur personnalisé en version bêta {#custom-admin-role-in-beta}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

Le rôle d'administrateur personnalisé apporte des permissions granulaires à l'Admin Area pour les instances GitLab Self-Managed et GitLab Dedicated. Au lieu d'accorder un accès complet, les administrateurs peuvent désormais créer des rôles spécialisés qui n'accèdent qu'aux fonctions spécifiques nécessaires aux utilisateurs. Cette fonctionnalité aide les organisations à appliquer le principe du moindre privilège pour les fonctions administratives, à réduire les risques de sécurité liés aux accès surprivilégiés et à améliorer l'efficacité opérationnelle.

Nous recherchons activement des retours de la communauté sur cette fonctionnalité. Si vous avez des questions, souhaitez partager votre expérience d'implémentation ou souhaitez vous engager directement avec notre équipe sur des améliorations potentielles, veuillez consulter notre [ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/issues/509376).

### Les jobs déclencheurs peuvent reproduire le statut du pipeline downstream {#trigger-jobs-can-mirror-the-downstream-pipeline-status}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../ci/yaml/_index.md#triggerstrategy) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/431882)

{{< /details >}}

Auparavant, les jobs déclencheurs utilisant `strategy:depend` présentaient des limitations lors du traitement d'états de pipeline complexes tels que les jobs manuels, les pipelines bloqués ou les pipelines relancés avec des statuts changeants pendant l'exécution. Cela pouvait donner l'impression que le pipeline downstream était en cours d'exécution, alors qu'il était en réalité bloqué sur un job manuel.

Le nouveau mot-clé `strategy:mirror` fournit un rapport de statut plus nuancé en reproduisant le statut exact en temps réel du pipeline downstream. Les statuts incluent des états intermédiaires tels que `running`, `manual`, `blocked` et `canceled` . Cela offre aux équipes une visibilité complète sur l'état actuel de leur pipeline downstream sans perturber le workflow existant.

### GitLab Runner 18.2 {#gitlab-runner-182}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 18.2 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Corrections de bugs {#bug-fixes}

- [Les runners échouent en mode FIPS après la mise à niveau vers GitLab Runner 18.1.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38890)
- [Impossible de démarrer les pods de jobs avec `FF_USE_DUMB_INIT_WITH_KUBERNETES_EXECUTOR`](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/241)
- [L'image `ubi-fips` n'est pas la variante d'image d'aide par défaut pour GitLab Runner FIPS](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38273)
- [Les runners restent hors ligne pendant une période prolongée après la désactivation du mode de maintenance de GitLab](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29181)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.2)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
