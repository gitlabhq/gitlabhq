---
stage: Release Notes
group: Monthly Release
date: 2026-01-15
title: "Notes de release de GitLab 18.8"
description: "GitLab 18.8 est disponible avec la plateforme GitLab Duo Agent Platform désormais en disponibilité générale"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 15 janvier 2026, GitLab 18.8 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Wesley Yarde {#this-months-notable-contributor-wesley-yarde}

Le contributeur notable de ce mois-ci est [Wesley Yarde](https://gitlab.com/WYarde), pour avoir développé une nouvelle fonctionnalité fondamentale permettant aux organisations de désactiver les clés SSH pour leurs utilisateurs enterprise.

La contribution de Wesley se distingue pour plusieurs raisons :

- **Sécurité et conformité** : cette fonctionnalité permet aux organisations d'appliquer des exigences relatives aux clés SSH et de renforcer la sécurité à l'échelle de leur enterprise.
- **Foundational work** : sans implémentation existante sur laquelle s'appuyer, Wesley a dû collaborer de manière approfondie avec l'équipe GitLab pour définir les exigences et l'architecture depuis le départ.
- **First contribution** : fait remarquable, il s'agissait de la première contribution de Wesley à GitLab, démontrant une capacité exceptionnelle à naviguer dans une base de code complexe et à relever un défi fonctionnel ambitieux.
- **Enables future development** : ce travail pose les bases pour des fonctionnalités similaires, comme la désactivation des clés SSH au niveau de l'instance et les contrôles des comptes de service.

L'implémentation a couvert plusieurs merge requests ([!205020](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205020), [!210482](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210482)) avec des cycles de révision approfondis. Malgré la complexité, Wesley a fait preuve d'une collaboration et d'une patience exemplaires tout au long du processus.

« Ce fut un plaisir de collaborer avec Wesley sur cette demande de fonctionnalité ! Bien que le contributeur et les relecteurs aient pu trouver le processus de révision éprouvant, les deux parties ont fait preuve de compréhension et d'une excellente collaboration pour s'assurer que l'implémentation est solide et complète. » — [Bogdan Denkovych](https://gitlab.com/bdenkovych), qui a nommé Wesley pour cette distinction.

Félicitations Wesley, et merci pour cette précieuse contribution à GitLab !

## Fonctionnalités principales {#primary-features}

### GitLab Duo Agent Platform désormais en disponibilité générale {#gitlab-duo-agent-platform-now-generally-available}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/duo_agent_platform/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/585273)

{{< /details >}}

GitLab Duo Agent Platform est désormais en disponibilité générale, introduisant l'orchestration d'IA agentique sur l'ensemble de votre cycle de vie du développement logiciel. Contrairement aux outils d'IA qui accélèrent les tâches individuelles de manière isolée, l'Agent Platform aide les équipes à coordonner les agents d'IA à travers la planification, la construction, la sécurisation et la livraison de logiciels, comblant ainsi l'écart entre la rapidité individuelle et la réalité collaborative et multi-étapes de la livraison logicielle.

La plateforme fournit un catalogue d'IA central où les équipes peuvent découvrir, gérer et partager des agents et des flows au sein de leur organisation. Les agents par défaut intégrés tels que Planner, Security Analyst et Data Analyst prennent en charge les tâches structurées aux points de décision clés, tandis que les flows personnalisés automatisent les agents et les tâches en plusieurs étapes dans les workflows de développement, du ticket à la merge request, en passant par la migration CI/CD, la résolution des problèmes de pipeline et les revues de code.

Grâce aux contrôles de gouvernance, à la visibilité sur l'utilisation et aux options de déploiement flexibles, notamment les modèles auto-hébergés pour les environnements hors ligne, les organisations peuvent adopter l'IA à grande échelle avec la transparence et le contrôle dont elles ont besoin.

Les utilisateurs de GitLab Premium et de GitLab Ultimate peuvent dès aujourd'hui commencer à utiliser l'Agent Platform sur GitLab.com et sur les instances GitLab Self-Managed avec des GitLab Credits promotionnels [GitLab Credits](../../subscriptions/gitlab_credits.md).

### GitLab Duo Planner Agent désormais en disponibilité générale {#gitlab-duo-planner-agent-now-generally-available}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/planner.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008)

{{< /details >}}

L'agent Planner est désormais en disponibilité générale ! L'agent Planner est un agent par défaut conçu pour accompagner directement les product managers dans GitLab.

Utilisez l'agent Planner pour créer, modifier et analyser des éléments de travail GitLab. Au lieu de suivre manuellement les mises à jour, de prioriser le travail ou de résumer les données de planification, l'agent Planner vous aide à analyser les backlogs, à appliquer des frameworks tels que RICE ou MoSCoW, et à identifier ce qui nécessite vraiment votre attention. C'est comme avoir un coéquipier proactif qui comprend votre workflow de planification et travaille avec vous pour prendre de meilleures décisions, plus efficacement.

Veuillez partager vos retours dans le ticket [583008](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008).

### GitLab Duo Security Analyst Agent désormais en disponibilité générale {#gitlab-duo-security-analyst-agent-now-generally-available}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

L'agent Security Analyst de GitLab Duo, [introduit en version bêta dans GitLab 18.5](https://about.gitlab.com/releases/2025/10/16/gitlab-18-5-released/#gitlab-security-analyst-agent-for-duo-agent-catalog-beta), est désormais en disponibilité générale dans GitLab 18.8.

L'agent Security Analyst permet aux ingénieurs de gérer les vulnérabilités via des commandes en langage naturel dans GitLab Duo Agentic Chat. Au lieu de naviguer manuellement dans les tableaux de bord de vulnérabilités ou d'écrire des scripts personnalisés pour les opérations en masse, les équipes de sécurité peuvent désormais trier, évaluer et fournir des recommandations pour les vulnérabilités dans les conversations Chat.

En tant qu'agent par défaut, l'agent Security Analyst est disponible par défaut dans GitLab Duo Agentic Chat, sans configuration manuelle requise.

### Ignorer automatiquement les vulnérabilités non pertinentes avec les politiques de gestion des vulnérabilités {#auto-dismiss-irrelevant-vulnerabilities-with-vulnerability-management-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/policies/vulnerability_management_policy.md#auto-dismiss-policies) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10894)

{{< /details >}}

Les équipes de sécurité peuvent désormais ignorer automatiquement les vulnérabilités qui ne s'appliquent pas à leur organisation à l'aide des politiques de gestion des vulnérabilités. Ignorer les vulnérabilités non pertinentes pour votre organisation réduit le bruit et aide les équipes de développement à se concentrer sur les vulnérabilités qui représentent un risque réel.

Vous pouvez créer des politiques pour ignorer automatiquement les vulnérabilités selon les critères suivants :

- Chemin de fichier
- Répertoire
- Identifiant (CVE, CWE ou OWASP)

Les vulnérabilités ignorées automatiquement apparaissent dans le widget de sécurité de la merge request avec un label **Auto-dismissed** et sont suivies dans l'activité du rapport de vulnérabilités avec une raison de rejet à des fins d'audit.

## Agentic Core {#agentic-core}

### Activer ou désactiver GitLab Duo Agent Platform {#turn-the-gitlab-duo-agent-platform-on-or-off}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/583980)

{{< /details >}}

Vous pouvez désormais activer ou désactiver GitLab Duo Agent Platform, y compris GitLab Duo Chat (Agentic), les agents et les flows pour un groupe principal ou l'ensemble de l'instance. Lorsque ce paramètre est désactivé, ces fonctionnalités ne sont pas disponibles.

### Contrôle d'accès de groupe pour les fonctionnalités GitLab Duo {#group-access-control-for-gitlab-duo-features}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../administration/gitlab_duo/configure/access_control.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/585355)

{{< /details >}}

Vous pouvez désormais définir des règles d'accès de groupe pour contrôler qui peut utiliser les fonctionnalités GitLab Duo, permettant ainsi des stratégies d'adoption flexibles, qu'il s'agisse d'un accès immédiat à l'ensemble de l'organisation ou de déploiements progressifs.

Cette fonctionnalité offre un contrôle de gouvernance granulaire pour que vous puissiez adapter l'adoption à votre rythme tout en maintenant la sécurité et la conformité.

### GitLab Duo Agent Platform pour GitLab Duo Self-Hosted (licence hors ligne) désormais en disponibilité générale {#gitlab-duo-agent-platform-for-gitlab-duo-self-hosted-offline-licensing-now-generally-available}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/19125)

{{< /details >}}

GitLab Duo Agent Platform est désormais en disponibilité générale pour Duo Self-Hosted. Cette fonctionnalité est disponible pour les clients GitLab Self-Managed disposant d'une licence hors ligne, et utilise une tarification basée sur les sièges.

Les administrateurs Self-Managed peuvent configurer des [modèles compatibles](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) pour une utilisation avec GitLab Duo Agent Platform. Les administrateurs utilisant AWS Bedrock ou Azure OpenAI peuvent également configurer des modèles Anthropic Claude ou OpenAI GPT.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Prise en charge du C/C++ dans Advanced SAST désormais en disponibilité générale {#cc-support-in-advanced-sast-now-generally-available}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/sast/advanced_sast_cpp.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/18369)

{{< /details >}}

La prise en charge de l'analyse inter-fichiers et inter-fonctions pour le C/C++ est désormais en disponibilité générale dans GitLab Advanced SAST.

### Analyse de conteneurs multiple {#multiple-container-scanning}

<!-- categories: Container Scanning -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](../../user/application_security/container_scanning/multi_container_scanning.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/work_items/3139)

{{< /details >}}

Dans GitLab 18.8, nous avons publié l'analyse multi-conteneurs en version bêta.

Les utilisateurs peuvent désormais passer un tableau d'images à analyser dans le cadre de nombreux jobs d'analyse de conteneurs.

### API centralisée de gestion des identifiants pour les propriétaires de groupes {#centralized-credential-management-api-for-group-owners}

<!-- categories: System Access -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../api/groups.md#credentials-inventory-management) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16343)

{{< /details >}}

L'API Credentials Inventory est désormais disponible pour les utilisateurs Enterprise sur GitLab.com. Cela ajoute des fonctionnalités de gestion des identifiants précédemment disponibles uniquement sur les instances auto-hébergées, et permet aux organisations de mieux gérer et sécuriser leurs jetons d'authentification et leurs clés.

L'API Credentials Inventory fournit un accès programmatique pour consulter les identifiants de votre organisation, notamment :

- Jetons d'accès personnels (PAT)
- Jetons d'accès de groupe (GrATs)
- Jetons d'accès au projet (PrATs)
- Clés SSH
- Clés GPG

Cette API complète l'interface utilisateur Credentials Inventory existante, permettant aux administrateurs enterprise d'automatiser les tâches de gestion des identifiants qui nécessitaient auparavant une intervention manuelle. Avec l'API Credentials Inventory, vous pouvez :

- Automatiser les workflows de sécurité : créer des processus automatisés pour surveiller, auditer et révoquer les identifiants.
- Appliquer des politiques d'identifiants : identifier et révoquer les jetons inutilisés ou expirés.
- Améliorer la posture de sécurité : réduire le risque de mauvaise utilisation des identifiants grâce à des audits réguliers.
- Rationaliser les opérations : intégrer la gestion des identifiants dans vos outils et workflows de sécurité existants.

### Les propriétaires de groupes peuvent désactiver les clés SSH pour les utilisateurs enterprise {#group-owners-can-disable-ssh-keys-for-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/ssh_advanced.md#disable-ssh-keys-for-enterprise-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/30343)

{{< /details >}}

Les propriétaires de groupes peuvent désormais désactiver les clés SSH pour tous les utilisateurs enterprise de leur groupe. Lorsqu'elles sont désactivées, les utilisateurs ne peuvent pas ajouter de nouvelles clés SSH et leurs clés existantes sont désactivées. Cela s'applique à tous les utilisateurs enterprise du groupe, y compris ceux disposant du rôle Owner.

Merci à [Wesley Yarde](https://gitlab.com/WYarde) pour sa contribution à la création de cette fonctionnalité !

### GitLab Runner 18.8 {#gitlab-runner-188}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 18.8 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Amélioration des messages d'erreur pour les erreurs d'interpolation des entrées de job](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39163)

#### Corrections de bugs {#bug-fixes}

- [`WaitForServicesTimeout` ne prend plus en charge `-1` pour désactiver le délai d'expiration](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39172)
- [Une URL personnalisée interrompt l'authentification des sous-modules avec les règles `insteadOf`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39170)
- [Le jeton court personnalisé du runner sur Windows 2025 utilise 9 caractères au lieu de 8](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39122)
- [L'image d'assistance PowerShell par défaut est manquante pour l'exécuteur Docker dans GitLab Runner 17.8.3](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38669)
- [GitLab Runner avec Docker Autoscaler ne réutilise pas les volumes de cache disponibles](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37906)
- [VirtualBox laisse une VM orpheline lorsqu'un job est annulé](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37344)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.8)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
