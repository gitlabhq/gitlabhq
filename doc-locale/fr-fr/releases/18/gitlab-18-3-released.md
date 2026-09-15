---
stage: Release Notes
group: Monthly Release
date: 2025-08-21
title: "Notes de release de GitLab 18.3"
description: "GitLab 18.3 disponible avec la Duo Agent Platform dans Visual Studio (version bêta)"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 21 août 2025, GitLab 18.3 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Ahmed Kashkoush {#this-months-notable-contributor-ahmed-kashkoush}

Pour la version 18.3, nous sommes ravis de désigner [Ahmed Kashkoush](https://gitlab.com/ahmad-kashkoush) comme notre Contributeur notable !

Ahmed s'est distingué en tant que contributeur au [GitLab Web IDE](https://gitlab.com/gitlab-org/gitlab-web-ide) grâce à sa [participation au Google Summer of Code](https://gitlab.com/ahmad-kashkoush/gsoc-2025-final-report) cet été. Il a constamment livré des opérations Git essentielles, répondant directement aux demandes de longue date de la communauté. Ses cinq merge requests substantielles incluent les [fonctionnalités de commit et de force push](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/497), le [message de confirmation de mise à jour](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/540), la [fonctionnalité d'amendement de commit](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/507), les [opérations de création de branche](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/534) et les [fonctionnalités de suppression de branche](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/539).

Au-delà de l'implémentation de nouvelles fonctionnalités, Ahmed a résolu une demande de fonctionnalité vieille de plus de 5 ans concernant l'amendement de commits existants depuis le Web IDE, une fonctionnalité ayant reçu 24 pouces levés de la communauté. Son implémentation complète de la gestion des branches rapproche le Web IDE d'une parité fonctionnelle avec les environnements de développement locaux, éliminant ainsi le besoin pour les utilisateurs de basculer entre les interfaces pour les opérations Git de base. Le travail d'Ahmed soutient directement [la mission de GitLab](https://handbook.gitlab.com/handbook/company/mission/) selon laquelle « tout le monde peut contribuer », en rendant le Web IDE plus accessible aux développeurs.

Ahmed a été nommé par [Enrique Alcántara](https://gitlab.com/ealcantara), ingénieur frontend principal chez GitLab, qui a été son mentor tout au long du programme Google Summer of Code. « Ahmed fait preuve d'un engagement à résoudre les véritables points de friction des utilisateurs », déclare Enrique. « Son travail démontre l'impact qu'un contributeur ciblé peut avoir sur l'amélioration des fonctionnalités essentielles de GitLab. »

Les contributions d'Ahmed illustrent la puissance du mentorat et de la collaboration communautaire dans le développement open source et rendent GitLab plus accessible aux développeurs, quelle que soit leur configuration locale.

Merci, Ahmed, pour vos contributions exceptionnelles au Web IDE de GitLab !

## Fonctionnalités principales {#primary-features}

### Duo Agent Platform dans Visual Studio (version bêta) {#duo-agent-platform-in-visual-studio-beta}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/duo_agent_platform/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/179)

{{< /details >}}

Nous sommes ravis d'annoncer la version bêta publique de la Duo Agent Platform pour Visual Studio ! Avec cette release, les utilisateurs de Visual Studio peuvent désormais accéder aux capacités avancées basées sur l'IA de la Duo Agent Platform directement dans leur IDE.

La Duo Agent Platform apporte deux puissantes fonctionnalités à votre flux de travail :

- **Chat agentique** : accomplissez rapidement des tâches conversationnelles telles que la création et la modification de fichiers, la recherche dans votre base de code avec la correspondance de motifs et grep, et obtenez des réponses instantanées sur votre code, sans jamais quitter Visual Studio.
- **Agent flows** : traitez des tâches plus importantes et plus complexes avec une planification complète et un support d'implémentation. Les flows d'agents vous aident à transformer des idées de haut niveau en architecture et en code, en exploitant les ressources GitLab telles que les tickets, les merge requests, les commits, les pipelines CI/CD et les vulnérabilités de sécurité.

Les deux fonctionnalités offrent une recherche intelligente dans la documentation, les modèles de code et les informations du projet, vous permettant de passer en toute fluidité des modifications rapides à l'analyse approfondie du projet.

Essayez dès aujourd'hui la version bêta de la Duo Agent Platform dans Visual Studio et découvrez un nouveau niveau de productivité et d'assistance par IA dans votre flux de travail de développement.

### Vues intégrées (propulsées par GLQL) {#embedded-views-powered-by-glql}

<!-- categories: Markdown, Wiki, Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/glql/_index.md#embedded-views) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

Cette release introduit les vues intégrées, propulsées par GLQL, en disponibilité générale. Créez et intégrez des vues dynamiques et interrogeables des données GitLab directement là où se trouve votre travail : dans les pages wiki, les descriptions d'epics, les commentaires de tickets et les merge requests.

Les vues intégrées offrent une base stable aux équipes pour suivre l'avancement du travail sans naviguer entre plusieurs emplacements. Interrogez les tickets, les merge requests, les epics et d'autres éléments de travail à l'aide d'une syntaxe familière, puis affichez les résultats sous forme de tableaux ou de listes avec des champs personnalisables et des options de filtrage.

Les vues intégrées transforment la documentation statique en tableaux de bord vivants qui restent à jour avec les données de votre projet, aidant les équipes à maintenir le contexte et à améliorer la collaboration dans leurs flux de travail.

Nous accueillons vos commentaires au fur et à mesure que nous continuons à améliorer les vues intégrées. Partagez vos idées et suggestions dans notre [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/509792).

### Migration par transfert direct {#migration-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/group/import/direct_transfer_migrations.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11398)

{{< /details >}}

La migration par transfert direct est désormais en disponibilité générale. Pour migrer des groupes et des projets GitLab entre des instances GitLab par transfert direct, vous pouvez utiliser l'interface utilisateur de GitLab ou l'[API REST](../../api/bulk_imports.md).

Par rapport à la [migration par chargement d'un fichier d'exportation](../../user/project/settings/import_export.md#migrate-projects-by-uploading-an-export-file), le transfert direct :

- Fonctionne de manière plus fiable avec les grands projets.
- Prend en charge les migrations avec un écart de version plus important entre les instances source et de destination.
- Offre de meilleures informations sur le processus de migration et ses résultats.

Sur GitLab.com, la migration par transfert direct est activée par défaut. Sur GitLab Self-Managed et GitLab Dedicated, un administrateur doit [activer la fonctionnalité](../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer).

### Permissions affinées pour les jetons de job CI/CD {#fine-grained-permissions-for-cicd-job-tokens}

<!-- categories: Permissions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../ci/jobs/fine_grained_permissions.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15258)

{{< /details >}}

La sécurité des pipelines vient de gagner en flexibilité. Les jetons de job sont des identifiants éphémères qui fournissent un accès aux ressources dans les pipelines. Jusqu'à présent, ces jetons héritaient des autorisations complètes de l'utilisateur, entraînant souvent des capacités d'accès inutilement larges.

Grâce à notre nouvelle fonctionnalité de permissions affinées pour les jetons de job, vous pouvez désormais contrôler précisément les ressources spécifiques auxquelles un jeton de job peut accéder dans vos projets. Cela vous permet d'appliquer le principe du moindre privilège dans vos flux de travail CI/CD, en accordant uniquement l'accès minimum nécessaire pour que les jobs accomplissent leurs tâches lors de l'accès à vos projets avec le jeton de job CI/CD.

Nous travaillons activement à l'ajout de [permissions affinées supplémentaires](https://gitlab.com/groups/gitlab-org/-/epics/6310) pour réduire la dépendance aux jetons de longue durée dans les pipelines.

### Revue de code disponible sur GitLab Duo Self-Hosted (version bêta) {#code-review-available-on-gitlab-duo-self-hosted-beta}

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/524929)

{{< /details >}}

Vous pouvez désormais utiliser la revue de code GitLab Duo sur GitLab Duo Self-Hosted. Cette fonctionnalité est en version bêta sur GitLab Duo Self-Hosted, avec la prise en charge des familles de modèles Mistral, Meta Llama, Anthropic Claude et OpenAI GPT.

Utilisez Code Review sur GitLab Duo Self-Hosted pour accélérer votre processus de développement sans compromettre la souveraineté des données. Lorsque Code Review examine vos merge requests, il identifie les bugs potentiels et suggère des améliorations que vous pouvez appliquer directement. Utilisez Code Review pour itérer et améliorer vos modifications avant de demander à un humain de les examiner.

Donnez votre avis sur Code Review dans le [ticket 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Personnaliser les instructions pour GitLab Duo Code Review {#customize-instructions-for-gitlab-duo-code-review}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/545136)

{{< /details >}}

Assurez des standards de revue de code cohérents dans vos projets grâce aux instructions personnalisées pour GitLab Duo Code Review. Définissez des critères de revue spécifiques pour différents types de fichiers à l'aide de motifs glob, garantissant l'application des conventions propres à chaque langage là où elles importent le plus.

Avec les instructions personnalisées, vous pouvez :

- Décrire les standards de revue de code de votre équipe
- Utiliser des motifs glob pour définir des instructions spécifiques aux fichiers
- Observer des retours clairement étiquetés qui font référence à vos instructions personnalisées

Créez simplement un fichier `.GitLab/duo/mr-review-instructions.YAML` dans votre dépôt avec vos instructions personnalisées. GitLab Duo intégrera automatiquement ces instructions dans ses revues, en citant le groupe d'instructions spécifique lors de la fourniture de retours.

Aidez-nous à améliorer cette fonctionnalité en partageant vos idées et suggestions dans notre [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Apportez vos propres modèles à GitLab Duo Self-Hosted (version bêta) {#bring-your-own-models-to-gitlab-duo-self-hosted-beta}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/517581)

{{< /details >}}

GitLab Duo Self-Hosted vous permet désormais d'apporter votre propre modèle à utiliser avec les fonctionnalités de GitLab Duo. Cette fonctionnalité est en version bêta et disponible pour tous les clients GitLab Self-Managed avec GitLab Duo Enterprise. Les administrateurs d'instance peuvent configurer tout modèle compatible pour l'utiliser avec une fonctionnalité GitLab Duo prise en charge.

Cette fonctionnalité rend GitLab Duo Self-Hosted plus flexible, mais GitLab ne peut pas garantir que toutes les fonctionnalités de GitLab Duo fonctionneront avec chaque modèle compatible. Les administrateurs d'instance sont responsables de la validation de la compatibilité et des performances du modèle choisi. GitLab ne fournit pas d'assistance technique pour les problèmes spécifiques au modèle ou à la plateforme que vous avez choisi.

### Sélection de modèle hybride sur GitLab Duo Self-Hosted (version bêta) {#hybrid-model-selection-on-gitlab-duo-self-hosted-beta}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17192)

{{< /details >}}

Vous pouvez désormais utiliser un mélange de modèles de fournisseurs d'IA GitLab et de modèles auto-hébergés configurés de manière privée sur GitLab Duo Self-Hosted. Cette fonctionnalité est en version bêta et disponible sur GitLab Self-Managed pour tous les clients GitLab Duo Enterprise.

Avec les modèles hybrides sur GitLab Duo Self-Hosted, les administrateurs d'instance GitLab Self-Managed peuvent désormais choisir entre un modèle auto-hébergé et une passerelle IA auto-hébergée, ou un modèle de fournisseur IA GitLab et la passerelle IA hébergée par GitLab, fonctionnalité par fonctionnalité. Cela permet aux administrateurs d'équilibrer leurs exigences de sécurité et d'évolutivité. Pour donner votre avis sur la sélection de modèle hybride, consultez le [ticket 561048](https://gitlab.com/gitlab-org/gitlab/-/issues/561048).

### Mise en évidence des violations des contrôles de cadre de conformité (version bêta) {#surfacing-violations-of-compliance-framework-controls-beta}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

Auparavant, le rapport sur les violations de conformité offrait une vue d'ensemble de l'activité des merge requests pour tous les projets d'un groupe. Les violations de conformité disponibles concernaient la séparation des fonctions, par exemple :

- Détecter quand un auteur d'une merge request a approuvé sa propre merge request.
- Quand une merge request a été fusionnée avec moins de deux approbations.

Cependant, les retours des utilisateurs ont révélé que les classifications des violations leur semblaient confuses et difficiles à comprendre, car elles ne correspondaient pas bien aux cas d'utilisation réels en matière de conformité.

GitLab 18.3 améliore considérablement le rapport sur les violations en allant au-delà de la séparation des fonctions pour inclure les violations des contrôles et exigences de conformité dans les cadres de conformité. Chaque contrôle de cadre de conformité personnalisé est associé à un événement d'audit qui fournit un contexte détaillé sur les violations : qui a commis la violation, quand elle s'est produite et comment la corriger. Cela inclut le nom et l'adresse IP de l'utilisateur, ainsi que des suggestions de remédiation exploitables.

Ces améliorations donnent aux responsables de la conformité un contexte plus puissant et pertinent pour s'assurer que leur organisation adhère à des cadres de conformité spécifiques, tout en offrant la garantie que la non-conformité peut être efficacement identifiée, rectifiée et prévenue.

### Nouvelles opérations de contrôle de source dans le Web IDE {#new-web-ide-source-control-operations}

<!-- categories: Web IDE -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/web_ide/_index.md#use-source-control)

{{< /details >}}

Nous sommes ravis d'annoncer des fonctionnalités de contrôle de source supplémentaires dans le Web IDE. Vous pouvez gérer votre flux de travail Git plus efficacement sans quitter votre navigateur. Dans le panneau **Source Control**, vous pouvez désormais :

- Créer et supprimer des branches.
- Créer une branche à partir de n'importe quelle branche existante comme base.
- Amender votre dernier commit pour des correctifs rapides.
- Forcer le push de modifications directement depuis l'interface.

Ces améliorations mettent les opérations Git directement à portée de main. Pour plus d'informations sur les fonctionnalités disponibles, consultez [Utiliser le contrôle de source](../../user/project/web_ide/_index.md#use-source-control).

### Prise en charge d'AWS Secrets Manager pour GitLab CI/CD {#aws-secrets-manager-support-for-gitlab-cicd}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../ci/secrets/aws_secrets_manager.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17822)

{{< /details >}}

Les secrets stockés dans AWS Secrets Manager peuvent désormais être facilement récupérés et utilisés dans les jobs CI/CD. Notre nouvelle intégration avec AWS simplifie le processus d'interaction avec AWS Secrets Manager via GitLab CI/CD, aidant nos clients AWS à rationaliser leurs processus de build et de déploiement !

Merci à [Markus Siebert](https://gitlab.com/m-s-db) et [Henry Sachs](https://gitlab.com/DerAstronaut) qui ont contribué à la création de cette fonctionnalité via le [programme Co-Create de GitLab](https://about.gitlab.com/community/co-create/) !

### Rôle d'administrateur personnalisé {#custom-admin-role}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

Le rôle d'administrateur personnalisé apporte des permissions granulaires à la zone Admin pour les instances GitLab Self-Managed et GitLab Dedicated. Au lieu d'accorder un accès complet, les administrateurs peuvent désormais créer des rôles spécialisés qui n'accèdent qu'aux fonctions spécifiques nécessaires aux utilisateurs. Cette fonctionnalité aide les organisations à appliquer le principe du moindre privilège pour les fonctions administratives, à réduire les risques de sécurité liés aux accès surprivilégiés et à améliorer l'efficacité opérationnelle.

Si vous avez des questions, souhaitez partager votre expérience d'implémentation ou souhaitez vous engager directement avec notre équipe sur des améliorations potentielles, consultez le [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/509376).

## Agentic Core {#agentic-core}

### Plus de modèles disponibles pour GitLab Duo Self-Hosted {#more-models-available-for-use-with-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/560016)

{{< /details >}}

Les clients GitLab Self-Managed avec GitLab Duo Enterprise peuvent désormais utiliser Anthropic Claude 4 avec GitLab Duo Self-Hosted. Claude 4 est pris en charge sur AWS Bedrock. Les modèles open source OpenAI GPT OSS 20B et 120B ont été ajoutés comme modèles expérimentaux et sont disponibles sur vLLM, Azure OpenAI et AWS Bedrock. Pour laisser un retour sur l'utilisation de ces modèles avec GitLab Duo Self-Hosted, consultez le [ticket 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918).

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Nouvelle expérience de navigation pour les groupes dans Votre travail {#new-navigation-experience-for-groups-in-your-work}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/group/_index.md#group-visibility) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/502487)

{{< /details >}}

Nous sommes ravis d'annoncer des améliorations significatives de la vue d'ensemble des groupes dans **Votre travail**, conçues pour simplifier la façon dont vous découvrez et accédez à vos groupes. La nouvelle interface à onglets comprend un onglet **Membre**, qui offre une vue complète des groupes accessibles, et un onglet **Inactif** pour suivre les groupes en attente de suppression. Nous avons également simplifié la gestion des groupes en ajoutant les actions **Éditer** et **Supprimer** à la vue liste pour les utilisateurs disposant des permissions appropriées. Nous espérons que ces améliorations facilitent la recherche et la gestion des groupes qui vous importent le plus.

Nous apprécions vos commentaires sur cette mise à jour ! Participez à la discussion dans l'[epic 18401](https://gitlab.com/groups/gitlab-org/-/epics/18401) pour partager votre expérience avec le nouveau système de navigation.

### Liste de projets améliorée de la zone **Admin** {#enhanced-admin-area-projects-list}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/admin_area.md#administering-projects) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17782)

{{< /details >}}

Nous avons mis à niveau la liste de projets de la zone **Admin** pour offrir une expérience plus cohérente aux administrateurs GitLab :

- Protection contre la suppression différée : les suppressions de projets suivent désormais le même flux de suppression sécurisé utilisé dans tout GitLab, empêchant la perte accidentelle de données.
- Interactions plus rapides : filtrez, triez et paginez les projets sans rechargement de page pour une expérience plus réactive.
- Interface cohérente : la liste de projets correspond désormais à l'apparence et au comportement des autres listes de projets dans GitLab.

Cette mise à jour aligne l'expérience administrateur sur les standards de conception de GitLab et ajoute d'importantes fonctionnalités de sécurité pour protéger vos données. Les futures améliorations de la gestion de projets apparaîtront automatiquement dans toutes les listes de projets sur la plateforme.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Informations améliorées sur l'emplacement des fichiers pour l'analyseur de détection des dépendances {#improved-file-location-information-for-dependency-scanning-analyzer}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#customizing-behavior-with-the-cicd-template) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/537716)

{{< /details >}}

Pouvoir retracer une dépendance jusqu'à sa source est important, notamment pour la remédiation des vulnérabilités. Auparavant, l'analyseur de détection des dépendances renvoyait parfois vers des artefacts de job qui avaient été supprimés à leur expiration. Cela rendait difficile le traçage jusqu'à la source de la dépendance. L'analyseur de détection des dépendances peut désormais renvoyer vers le fichier du projet qui a introduit la dépendance. Lorsque cette option est activée, les liens dans la liste des dépendances et le rapport de vulnérabilité sont fiables. Les utilisateurs peuvent activer cette fonctionnalité en définissant `DS_FF_LINK_COMPONENTS_TO_GIT_FILES=true` pour le job de détection des dépendances.

### Source définie par l'utilisateur pour les informations de licence {#user-defined-source-for-license-information}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#use-cyclonedx-report-as-a-source-of-license-information) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/501662)

{{< /details >}}

Les utilisateurs peuvent désormais choisir quelle source d'informations de licence est prioritaire : la base de données de licences GitLab ou un rapport SBOM CycloneDX. Cela offre aux utilisateurs plus de flexibilité dans l'obtention des informations de licence pour leurs dépendances open source. Les utilisateurs souhaitant définir la source des informations de licence peuvent utiliser l'[interface utilisateur de configuration de sécurité](../../user/application_security/detect/security_configuration.md#with-the-ui) pour effectuer une sélection. Par défaut, nous utilisons les données SBOM comme source d'informations de licence.

### Sortie de job DAST concise {#concise-dast-job-output}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/dast/browser/troubleshooting.md#what-is-dast-doing) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18342)

{{< /details >}}

GitLab 18.3 introduit plusieurs améliorations dans la sortie du job de test dynamique de sécurité des applications.

Cette sortie de job améliorée fournit des informations claires et structurées qui vous aident à comprendre les résultats de scan et à résoudre les échecs.

Chaque section de la sortie du job est concise et intuitive, avec un lien vers notre documentation de dépannage en bas de la sortie. Pour désactiver la sortie de job concise, définissez `DAST_FF_DIAGNOSTIC_JOB_OUTPUT: "true"` dans votre configuration DAST.

### Gestion de la conformité et des politiques au niveau de l'instance (version bêta) {#instance-level-compliance-and-policy-management-beta}

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)

{{< /details >}}

Les utilisateurs d'entreprise souhaitent gérer leurs cadres de conformité et leurs politiques de sécurité sur plusieurs groupes principaux. C'est souvent le cas lorsque tous les groupes d'une instance :

- Partagent les mêmes cadres de conformité. Par exemple, lorsque tous les projets d'un groupe doivent adhérer à la norme ISO 27001.
- Appliquent des politiques similaires. Par exemple, lorsque tous les groupes partagent la même politique d'exécution de pipeline.

Avec GitLab 18.3, la gestion de la conformité et des politiques de sécurité est désormais disponible en version bêta pour les instances GitLab Self-Managed. Vous pouvez désormais créer, configurer et allouer des cadres de conformité et des politiques de sécurité à partir d'un seul groupe principal et les appliquer à tous les autres groupes principaux de votre instance GitLab Self-Managed.

Lorsque vous utilisez un groupe principal de conformité et de politiques de sécurité, vous disposez d'une source de vérité unique où vous pouvez gérer et modifier vos cadres de conformité et vos politiques de sécurité. Les administrateurs de groupe peuvent ensuite appliquer ces cadres de conformité et politiques de sécurité à tous les projets au sein de ces groupes.

Lorsque vous gérez les cadres et politiques clés à partir du groupe principal de conformité et de politiques de sécurité choisi, il est plus facile de gérer et d'appliquer les exigences clés de conformité et de sécurité sur votre instance GitLab Self-Managed. Cependant, les groupes conservent toujours la capacité de créer leurs propres cadres de conformité et politiques de sécurité pour répondre à des situations ou des flux de travail spécifiques pouvant survenir dans ces groupes.

Cette fonctionnalité est destinée aux clients GitLab Self-Managed car les clients GitLab.com et GitLab Dedicated peuvent déjà gérer les politiques de manière centralisée au sein d'un seul groupe principal ou espace de nommage.

### Démarrage plus rapide des workspaces grâce au clonage superficiel {#faster-workspace-startup-with-shallow-cloning}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/workspace/_index.md#shallow-cloning)

{{< /details >}}

Les workspaces utilisent désormais le clonage superficiel pour réduire le temps de démarrage. Lors de l'initialisation, GitLab télécharge uniquement le dernier historique de commits au lieu de l'historique Git complet. Une fois le workspace démarré, Git convertit le clone superficiel en clone complet en arrière-plan.

Cette fonctionnalité s'applique automatiquement à tous les nouveaux workspaces, aucune configuration n'est requise et elle n'affecte pas votre flux de travail de développement.

### Nouvelles commandes CLI pour les états OpenTofu et Terraform gérés par GitLab {#new-cli-commands-for-gitlab-managed-opentofu-and-terraform-states}

<!-- categories: GitLab CLI, Infrastructure as Code -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/infrastructure/iac/terraform_state.md) \| [Ticket associé](https://gitlab.com/gitlab-org/cli/-/issues/7954)

{{< /details >}}

L'interface CLI GitLab (`glab`) inclut désormais une nouvelle commande de niveau supérieur, `opentofu`. La commande `opentofu` est associée aux commandes `terraform` et `tf` pour faciliter la gestion des états OpenTofu et Terraform gérés par GitLab.

Les commandes suivantes ont été ajoutées :

- `glab opentofu init` : initialiser le backend d'état localement.
- `glab opentofu state list` : lister tous les états d'un projet.
- `glab opentofu state download` : télécharger le dernier état ou une version spécifique.
- `glab opentofu state delete` : supprimer l'état entier ou une version spécifique.
- `glab opentofu state lock` : verrouiller un état.
- `glab opentofu state unlock` : déverrouiller un état

Pour gérer l'état avec la commande `opentofu`, vous devez disposer au minimum de `glab` 1.66 ou version ultérieure.

### Prise en charge de Kubernetes 1.33 {#kubernetes-133-support}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/538906)

{{< /details >}}

GitLab prend désormais entièrement en charge Kubernetes version 1.33. Si vous déployez vos applications sur Kubernetes, vous pouvez mettre à niveau vos clusters connectés vers la version la plus récente et profiter de toutes ses fonctionnalités.

Pour plus d'informations, consultez les [versions Kubernetes prises en charge pour les fonctionnalités GitLab](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### Les applications OAuth prennent en charge l'authentification SSO {#oauth-apps-support-sso-authentication}

<!-- categories: Pages, System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../api/oauth2.md#authorization-code-flow)

{{< /details >}}

Les applications OAuth peuvent désormais s'intégrer de manière transparente aux exigences d'authentification unique de votre organisation. Auparavant, les utilisateurs devaient s'authentifier deux fois : d'abord avec GitLab, puis avec SSO, créant une friction et une complexité inutiles.

Désormais, les applications OAuth peuvent spécifier un paramètre dans leurs requêtes d'autorisation pour déclencher automatiquement l'authentification SSO lorsque cela est requis. Cela fournit :

- Une expérience d'authentification unifiée pour les utilisateurs
- La conformité automatique aux politiques SSO de votre organisation
- Une sécurité cohérente sur toutes les intégrations GitLab
- Une implémentation simple pour les développeurs avec l'ajout d'un seul paramètre

Vos intégrations OAuth respectent désormais automatiquement les politiques SSO, éliminant les flux d'authentification confus tout en maintenant la sécurité.

### Contrôler le domaine unique par défaut pour les sites GitLab Pages {#control-unique-domains-default-for-gitlab-pages-sites}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../administration/pages/_index.md#disable-unique-domains-by-default)

{{< /details >}}

Les administrateurs peuvent désormais définir le comportement par défaut des domaines uniques pour les nouveaux sites GitLab Pages. Par défaut, les nouveaux sites Pages utilisent des URL de domaine unique (comme `my-project-1a2b3c.example.com`) pour empêcher le partage de cookies entre les sites.

Avec ce nouveau paramètre pour l'instance, vous pouvez configurer les nouveaux sites Pages pour utiliser des URL basées sur le chemin (comme `my-namespace.example.com/my-project`) par défaut. Cela aide les organisations à aligner le comportement de GitLab Pages avec leurs flux de travail et leurs exigences de sécurité.

Les utilisateurs peuvent toujours remplacer ce paramètre pour des projets individuels, et les sites Pages existants ne sont pas affectés.

### Améliorations de la fonctionnalité wiki {#enhancements-to-wiki-functionality}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/discussions/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16403)

{{< /details >}}

Cette release introduit une expérience wiki améliorée avec trois améliorations clés : vous pouvez désormais vous abonner aux pages wiki, consulter les commentaires wiki lors de la modification d'une page et trier les commentaires des pages wiki.

Ces améliorations aident les équipes à collaborer plus efficacement sur la documentation en vous permettant de :

- Discuter du contenu directement en contexte.
- Suggérer des améliorations et des corrections.
- Maintenir la documentation exacte et à jour.
- Partager les connaissances et l'expertise.

Grâce à ces mises à jour, votre wiki GitLab devient une documentation vivante qui évolue aux côtés de vos projets grâce aux retours directs et aux discussions.

### Modification en masse des responsables, jalons et autres attributs des epics {#bulk-edit-epic-assignees-milestones-and-more}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/group/epics/manage_epics.md#bulk-edit-epics) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11901)

{{< /details >}}

Vous pouvez désormais modifier en masse davantage d'attributs d'epic dans un groupe. En plus des labels, vous pouvez maintenant mettre à jour le responsable, le statut de santé, l'abonnement, la confidentialité et le jalon pour plusieurs epics à la fois.

Cette amélioration accélère la gestion d'un grand nombre d'epics en vous permettant d'appliquer les mêmes modifications sur plusieurs epics simultanément.

### Accorder l'accès aux configurations CI/CD aux politiques d'exécution de pipeline via l'API {#grant-pipeline-execution-policies-access-to-cicd-configurations-via-api}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../api/projects.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/524124)

{{< /details >}}

Utilisez l'API REST Projects pour activer ou désactiver par programmation le paramètre **Politique d'exécution de pipeline** dans les projets de politiques de sécurité avec le nouveau champ `spp_repository_pipeline_access`. Auparavant, ce paramètre ne pouvait être géré que via l'interface utilisateur de GitLab. Grâce à cette amélioration, vous pouvez désormais :

- `GET` le statut actuel de la **Politique d'exécution de pipeline**.
- `PUT` pour activer ou désactiver le paramètre par programmation.

Cette amélioration permet de meilleurs flux de travail d'automatisation et d'intégration pour les équipes gérant des politiques de sécurité à grande échelle.

### Grouper par OWASP 2021 dans le rapport de vulnérabilité {#group-by-owasp-2021-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

Dans le rapport de vulnérabilité pour les projets et les groupes, vous pouvez désormais regrouper les vulnérabilités par catégorie OWASP Top 10 2021. Disponible uniquement pour les instances GitLab.com et GitLab Dedicated.

### Modèles de politique d'exécution de scan {#scan-execution-policy-templates}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/policies/scan_execution_policies.md#scan-execution-policy-editor) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11919)

{{< /details >}}

Les modèles de politique d'exécution de scan vous aident à créer rapidement des politiques d'exécution de scan basées sur des cas d'utilisation courants. Choisissez parmi trois modèles :

- Sécurité des merge requests
- Scan planifié
- Sécurité des releases

Une fois que vous avez sélectionné un modèle, choisissez les scans de sécurité GitLab à activer avec ce modèle pour démarrer immédiatement. Si vous avez des cas d'utilisation plus avancés, vous pouvez passer à la configuration personnalisée pour étendre la politique avec des modèles de branches spécifiques, des sources de pipeline et bien plus encore.

### Événements d'audit des politiques de sécurité {#security-policy-audit-events}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/audit_event_streaming.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15869)

{{< /details >}}

GitLab Ultimate fournit désormais des événements d'audit complets pour la gestion des politiques de sécurité, avec des événements organisés et centralisés au sein de chaque projet de politique de sécurité.

Les équipes de sécurité peuvent désormais :

- Suivre toutes les modifications de politique avec des métadonnées détaillées.
- Surveiller les échecs d'application, y compris les échecs d'exécution de scan et de pipeline.
- Surveiller les pipelines d'exécution de scan et de pipeline ignorés.
- Détecter les violations de politique au sein de chaque projet, y compris les MR fusionnées avec des violations de politique.
- Recevoir des alertes lorsque les limites sont dépassées.
- Détecter les erreurs de configuration de politique.
- Utiliser des options de streaming uniquement pour les scénarios à volume élevé.

Les nouveaux événements d'audit incluent :

- [security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_create.yml).yml)
- [security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_delete.yml).yml)
- [security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_update.yml).yml)
- [security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_merge_request_merged_with_policy_violations.yml).yml)
- [security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml).yml)
- [security_policies_limit_exceeded](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml)
- [security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_violations_detected.yml).yml) (streaming uniquement)
- [security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_failed.yml).yml) (streaming uniquement)
- [security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_skipped.yml).yml) (streaming uniquement)
- [merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/[merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/merge_request_branch_bypassed_by_security_policy.yml).yml)

Cette amélioration renforce votre posture de sécurité en vous garantissant l'accès aux changements de politique, aux erreurs de configuration et aux lacunes d'application, permettant ainsi une réponse aux incidents plus rapide et des capacités d'audit approfondies.

### Exceptions de compte de service et de jeton d'accès pour les politiques d'approbation {#service-account-and-access-token-exceptions-for-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#access-token-and-service-account-exceptions) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/18112)

{{< /details >}}

La nouvelle fonctionnalité **Service Account & Access Token Exceptions** vous permet de désigner des comptes de service et des jetons d'accès pouvant contourner les politiques d'approbation des merge requests lorsque cela est nécessaire. Cela élimine les frictions pour les automatisations connues, tout en préservant les contrôles de sécurité.

**Les principales fonctionnalités incluent :**

- Support des flux de travail automatisés : configurez des comptes de service spécifiques, des utilisateurs bots, des jetons d'accès de groupe et des jetons d'accès au projet pour contourner les exigences d'approbation pour les pipelines CI/CD, la mise en miroir par pull et les mises à jour de version automatisées. Les comptes de service peuvent effectuer un push directement vers des branches protégées à l'aide de jetons approuvés, tout en maintenant les restrictions pour les utilisateurs humains.
- Accès d'urgence et audit : activez les scénarios de break-glass pour les incidents critiques avec des pistes d'audit complètes. Tous les événements de contournement génèrent des journaux d'audit détaillés avec contexte et justification, prenant en charge les exigences de conformité tout en permettant une réponse rapide lors de pannes ou de correctifs de sécurité.
- Intégration GitOps : débloquez les défis d'automatisation courants, notamment la mise en miroir de dépôt, les systèmes CI externes (Jenkins, CloudBees), la génération automatisée de journaux de modifications et les processus de release GitFlow. Les comptes de service reçoivent les permissions minimales requises avec un accès basé sur des jetons limité à des projets et des branches spécifiques.

Cette amélioration maintient des politiques de sécurité strictes avec la flexibilité nécessaire aux besoins modernes d'automatisation DevOps, éliminant les contournements personnalisés tout en préservant les contrôles de gouvernance.

### Prise en charge SSO SAML pour l'attribut de délai d'expiration de session {#saml-sso-support-for-session-timeout-attribute}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/group/saml_sso/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/262074)

{{< /details >}}

GitLab détecte et respecte désormais automatiquement l'attribut `SessionNotOnOrAfter` dans les assertions SAML de votre fournisseur d'identité (IdP). Lorsque cet attribut est présent, GitLab configure les sessions utilisateur pour qu'elles expirent à l'heure spécifiée par votre IdP, garantissant une gestion cohérente des sessions dans toute votre organisation. Cette fonctionnalité ne nécessite aucune modification de configuration : si votre IdP fournit l'attribut, GitLab respecte automatiquement le délai d'expiration spécifié.

### Options supplémentaires de configuration des e-mails de compte de service {#additional-service-account-email-configuration-options}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/profile/service_accounts.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/537976)

{{< /details >}}

Par défaut, GitLab génère automatiquement une adresse e-mail pour les nouveaux comptes de service. Les organisations peuvent désormais attribuer une adresse e-mail personnalisée pour les comptes de service via l'interface utilisateur. Auparavant, la configuration d'e-mail personnalisée n'était possible que via l'API Service Accounts. Ce changement permet aux organisations de mieux acheminer les notifications vers des adresses e-mail désignées.

### Améliorations pour les utilisateurs d'entreprise {#enterprise-user-enhancements}

<!-- categories: System Access -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/enterprise_user/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9262)

{{< /details >}}

GitLab 18.3 introduit des améliorations pour les utilisateurs d'entreprise qui donnent aux organisations un plus grand contrôle sur la confidentialité des utilisateurs et la gestion du cycle de vie.

Les propriétaires de groupe peuvent désormais supprimer des utilisateurs d'entreprise dans leur espace de nommage avec l'API Users. Cette action destructrice dissocie les contributions des utilisateurs et les associe à un utilisateur Ghost à l'échelle du système. Cette option est particulièrement utile pour nettoyer les utilisateurs créés par erreur lors d'imports SCIM automatisés ou pour gérer des environnements fédérés où les noms d'utilisateur et les e-mails doivent être réutilisés.

De plus, les organisations peuvent désormais masquer les e-mails des utilisateurs d'entreprise sur leurs profils, offrant une application plus large de la confidentialité des e-mails pour tous les utilisateurs d'entreprise.

### Avertissements de sécurité pour les clés SSH {#ssh-key-security-warnings}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/ssh.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/432624)

{{< /details >}}

GitLab affiche désormais un avertissement de sécurité dans l'interface utilisateur lorsqu'un utilisateur charge une clé SSH faible. Cet avertissement s'affiche pour les types de clés plus anciens ou les clés avec une longueur de bits insuffisante (moins de 2048 bits). Ce changement aide à informer les utilisateurs sur les meilleures pratiques de sécurité des clés SSH et encourage l'utilisation de clés cryptographiques plus robustes.

### GitLab Runner 18.3 {#gitlab-runner-183}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 18.3 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Corrections de bugs {#bug-fixes}

- [Dans GitLab 18.2.0, les runners ne peuvent pas extraire le cache de job en utilisant le fichier de sous-répertoire comme clé de cache](https://gitlab.com/gitlab-org/gitlab/-/issues/556464)
- [L'exécuteur Docker ne parvient pas à démarrer les jobs par intermittence et renvoie un message d'erreur `incorrect username or password`.](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38707)
- [Incohérence dans l'utilisation des hooks `*_get_sources` entre les stratégies Git `none` et `empty`](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38703)
- [L'opérateur déployé avec des manifestes non-OLM suppose des images par défaut incorrectes](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/228)
- [L'opérateur crée un ConfigMap avec le mauvais nom si le CR a le label `app.kubernetes.io/instance`](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/183)
- [L'opérateur 1.10.0 sur OpenShift 4.9 ne parvient pas à créer le ConfigMap du runner et à démarrer le pod dans l'espace de nommage `gitlab-runner`](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/138)

#### Nouveautés {#whats-new}

- [GitLab Runner Operator prend désormais en charge l'annotation du pod du gestionnaire de runners](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/245)
- [GitLab Runner Operator prend désormais en charge OpenShift 4.19](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/253)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.3)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
