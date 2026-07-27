---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Bonnes pratiques d'authentification et d'autorisation"
description: "Recommandations de sécurité et bonnes pratiques en matière d'authentification, d'autorisation et de gestion des accès."
---

Suivez ces bonnes pratiques de sécurité pour protéger votre instance GitLab et maintenir des contrôles d'accès appropriés. Ces recommandations vous aident à maintenir un accès sécurisé sans limiter la productivité au sein de votre organisation.

## Principes de sécurité {#security-principles}

Établissez des principes de sécurité fondamentaux qui constituent la base de votre stratégie de contrôle d'accès.

### Principe du moindre privilège {#principle-of-least-privilege}

Ce principe réduit les risques de sécurité en limitant les dommages potentiels causés par des comptes compromis ou des menaces internes.

- Accordez aux utilisateurs les autorisations minimales nécessaires à l'accomplissement de leur travail.
- Attribuez des rôles minimum (accès minimum ou Guest) au niveau du groupe principal, puis accordez des autorisations plus élevées uniquement dans les sous-groupes et projets spécifiques où cela est nécessaire.
- Réduisez le nombre de propriétaires et de mainteneurs en implémentant des rôles personnalisés qui restreignent l'accès aux paramètres sensibles.
- Lors de la création de jetons, utilisez la portée la plus limitée possible ou créez plusieurs jetons avec des portées différentes à des fins spécifiques.

### Gestion hiérarchique des autorisations {#hierarchical-permission-management}

Organisez les autorisations de manière à correspondre à votre structure organisationnelle et à réduire la charge administrative.

- Appliquez des autorisations au niveau de l'appartenance à un groupe plutôt qu'au niveau de l'appartenance à un projet, lorsque cela est possible, afin de réduire la charge administrative.
- Créez un groupe principal unique pour votre organisation afin de permettre un contrôle d'accès et un reporting centralisés.
- Organisez votre hiérarchie de groupes de manière à correspondre à votre structure organisationnelle avec des limites de propriété claires.

### Défense en profondeur {#defense-in-depth}

Superposez plusieurs contrôles de sécurité pour vous protéger contre différents types d'attaques et de défaillances. Si un contrôle est défaillant, les autres assurent une protection de secours.

- Configurez des [branches protégées](../user/project/repository/branches/protected.md) pour les applications critiques afin de prévenir les modifications non autorisées.
- Configurez des [environnements protégés](../ci/environments/protected_environments.md) pour restreindre les déploiements à des rôles ou utilisateurs spécifiques.
- Utilisez des [conteneurs protégés](../user/packages/container_registry/container_repository_protection_rules.md) pour renforcer la sécurité des artefacts sensibles.

## Authentification et identifiants {#authentication-and-credentials}

Implémentez des méthodes d'authentification robustes pour prévenir tout accès non autorisé à votre instance GitLab.

### Sécurité des mots de passe {#password-security}

Les mots de passe demeurent une méthode d'authentification principale malgré leurs limites. Des politiques de mots de passe strictes réduisent le risque d'attaques basées sur les identifiants en imposant des mots de passe forts conformes aux normes de sécurité de votre organisation.

- Configurez les [exigences de complexité des mots de passe](../administration/settings/sign_up_restrictions.md#modify-password-complexity-requirements) adaptées à votre organisation.
- Activez la [détection des mots de passe compromis](../user/profile/user_passwords.md) pour empêcher l'utilisation de mots de passe connus comme compromis.

### Authentification à deux facteurs {#two-factor-authentication}

L'authentification à deux facteurs (2FA) améliore considérablement la sécurité en exigeant une seconde forme de vérification. Même si des mots de passe sont compromis, la 2FA empêche tout accès non autorisé.

- Exigez l'[authentification à deux facteurs](../user/profile/account/two_factor_authentication.md) pour tous les utilisateurs, en particulier ceux disposant d'autorisations élevées.
- Fournissez une documentation claire et un accompagnement pour la configuration de la 2FA afin d'assurer son adoption par les utilisateurs.
- Mettez en place des méthodes de récupération de secours pour éviter le blocage des comptes.

### Authentification par jeton {#token-based-authentication}

Les jetons offrent un accès sécurisé et programmatique aux ressources GitLab. Les différents types de jetons ont des objectifs distincts et des implications de sécurité variables.

- Renouvelez régulièrement les [jetons d'accès personnels](../user/profile/personal_access_tokens.md) et avant leur expiration.
- Utilisez des [jetons d'accès de groupe](../user/group/settings/group_access_tokens.md) et des [jetons d'accès au projet](../user/project/settings/project_access_tokens.md) plutôt que des jetons personnels pour les processus automatisés.
- Stockez les jetons de manière sécurisée et ne les commitez jamais dans des dépôts.

### Authentification par clé SSH {#ssh-key-authentication}

Les clés SSH offrent un accès sécurisé sans mot de passe aux dépôts Git. Une gestion appropriée des clés est essentielle au maintien de la sécurité.

- Utilisez des algorithmes de clé SSH robustes (au minimum RSA 2048 bits ou Ed25519).
- Configurez les [restrictions de clés SSH](../security/ssh_keys_restrictions.md) pour appliquer les normes de sécurité.
- Auditez et renouvelez régulièrement les clés SSH, en particulier pour les comptes de service.

## Gestion des accès {#access-management}

Contrôlez qui peut accéder à quelles ressources et surveillez ces autorisations dans le temps. Une gestion efficace des accès permet d'équilibrer les exigences de sécurité et l'efficacité opérationnelle.

### Gestion des types d'utilisateurs {#user-type-management}

Les différents types d'utilisateurs nécessitent des niveaux d'accès différents en fonction de leur relation avec votre organisation et des exigences de sécurité. Une classification appropriée des utilisateurs permet d'appliquer des limites d'accès adaptées.

- Désignez les sous-traitants et les tiers comme [utilisateurs externes](../administration/external_users.md) pour restreindre automatiquement leur visibilité aux projets internes.
- Attribuez le rôle Guest aux collaborateurs externes qui ont besoin d'une interaction limitée avec les dépôts.
- Utilisez les [utilisateurs auditeurs](../administration/auditor_users.md) pour le personnel chargé de la conformité et de la sécurité qui nécessite un accès en lecture seule à l'ensemble de l'instance.

### Révisions d'accès régulières {#regular-access-reviews}

Les révisions d'accès périodiques garantissent que les autorisations des utilisateurs restent appropriées à mesure que les rôles et les responsabilités évoluent. Les révisions régulières permettent d'identifier et de corriger les accès inappropriés avant qu'ils ne constituent un risque de sécurité.

- Effectuez des révisions d'accès régulières pour valider les autorisations des utilisateurs et résoudre immédiatement les incohérences.
- Utilisez les fonctionnalités d'[export des utilisateurs](../administration/admin_area.md#user-permission-export) et d'[export des groupes](../user/group/manage.md#export-members-as-csv) pour générer des rapports d'accès complets.
- Révoquez immédiatement les accès lorsque des utilisateurs quittent l'organisation ou changent de rôle.

### Surveillance et audit des accès {#access-monitoring-and-auditing}

La surveillance continue des schémas d'accès et des modifications d'autorisations permet de détecter les incidents de sécurité et de maintenir la conformité. Les pistes d'audit offrent une visibilité sur qui a accédé à quelles ressources et à quel moment.

- Configurez le [streaming d'événements d'audit](../administration/compliance/audit_event_streaming.md) vers un outil SIEM pour une surveillance de sécurité en temps réel.
- Consultez régulièrement l'[inventaire des identifiants](../administration/credentials_inventory.md) pour identifier les jetons inutilisés ou disposant de privilèges excessifs.
- Surveillez les modifications d'accès non autorisées ou les tentatives d'escalade de privilèges.

## Mise à l'échelle organisationnelle {#organizational-scaling}

Les différentes tailles et structures organisationnelles nécessitent des approches différentes en matière de gestion des autorisations. Adaptez vos pratiques de contrôle d'accès pour rester sécurisé à mesure que vous évoluez.

### Niveau fondation (1 à 50 utilisateurs) {#foundation-level-1-50-users}

Concentrez-vous sur l'établissement de bonnes bases sans processus complexes susceptibles de nuire à la productivité.

- Commencez avec les rôles par défaut et attribuez les autorisations au niveau du groupe plutôt que par projet.
- Documentez vos décisions en matière d'autorisations et leur justification pour référence future.
- Formez votre équipe principale au modèle d'autorisations GitLab et aux pratiques de sécurité.
- Établissez une configuration CI/CD au niveau du groupe pour appliquer des pratiques de sécurité cohérentes.

### Niveau croissance (50 à 200 utilisateurs) {#growth-level-50-200-users}

Équilibrez les exigences de sécurité avec le besoin de processus évolutifs.

- Intégrez [LDAP](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap) ou [SAML](../user/group/saml_sso/group_sync.md) avec les groupes d'utilisateurs pour simplifier la gestion.
- Créez des sous-groupes distincts pour les ressources partagées et les ressources sensibles afin de contrôler les accès.
- Développez des processus formels d'intégration et de départ pour les membres de l'équipe.
- Limitez les structures de groupes profondément imbriquées (maximum 4 à 5 niveaux pour la plupart des organisations).

### Niveau entreprise (200 utilisateurs et plus) {#enterprise-level-200-users}

Implémentez des contrôles et des processus de gouvernance de niveau entreprise.

- Développez des [rôles personnalisés](../user/custom_roles/_index.md) pour des besoins d'accès spécifiques tout en réduisant le nombre d'utilisateurs disposant de privilèges élevés.
- Automatisez les opérations d'accès en masse à l'aide des API GitLab pour réduire la charge de provisionnement manuel.
- Établissez des processus de gouvernance pour les modifications d'autorisations afin de prévenir toute interruption d'activité.
- Implémentez des accès à durée limitée pour les rôles privilégiés et des cadres de conformité pour la séparation des tâches.

## Sécurité des dépôts et CI/CD {#repository-and-cicd-security}

Protégez votre code, vos déploiements et vos processus automatisés contre les modifications et accès non autorisés. Ces contrôles garantissent l'intégrité de votre pipeline de développement et de livraison logicielle.

### Sécurité des pipelines {#pipeline-security}

Les pipelines CI/CD disposent souvent de privilèges élevés pour déployer des applications et accéder à des ressources sensibles. La sécurisation de l'exécution des pipelines empêche les actions non autorisées et protège votre processus de déploiement.

- Utilisez les [autorisations de job](../ci/jobs/fine_grained_permissions.md) pour contrôler les ressources accessibles lors de l'exécution du pipeline.
- Configurez des [portes d'approbation](../ci/environments/deployment_approvals.md) pour les étapes de déploiement critiques.
- Utilisez des runners spécifiques à l'environnement ou des tags de runner pour isoler les déploiements et limiter l'accès aux ressources de production sensibles.

### Protection des dépôts {#repository-protection}

Les dépôts de code source contiennent la propriété intellectuelle de votre organisation et doivent être protégés contre les modifications non autorisées. Les contrôles de sécurité des dépôts garantissent l'intégrité du code et préviennent les modifications malveillantes.

- Implémentez des [règles de push](../user/project/repository/push_rules.md) pour appliquer des normes de commit et éviter l'exposition de données sensibles.
- Exigez une [revue de code](../user/project/merge_requests/approvals/rules.md) via des règles d'approbation avant de fusionner les modifications dans des branches protégées.
- Utilisez des [commits signés](../user/project/repository/signed_commits/_index.md) pour fournir une vérification cryptographique de l'authenticité des commits.

### Sécurité des API et de l'automatisation {#api-and-automation-security}

Les processus automatisés et les intégrations d'API utilisent souvent des identifiants à longue durée de vie avec des accès étendus. Ces schémas d'accès non humains nécessitent des considérations de sécurité particulières pour prévenir l'abus des identifiants.

- Utilisez des comptes de service avec des autorisations limitées pour les processus automatisés plutôt que des jetons personnels.
- Renouvelez régulièrement les identifiants utilisés dans les processus d'automatisation et les pipelines CI/CD.
- Surveillez les schémas d'accès automatisés pour détecter tout comportement inhabituel ou toute tentative d'escalade de privilèges.
- Utilisez les portées les plus spécifiques possible lors de la création de jetons pour l'accès aux API.
- Implémentez la gestion des erreurs et la journalisation pour les intégrations d'API.
- Appliquez des limites de débit aux requêtes d'API pour prévenir les abus et garantir la stabilité du système.
