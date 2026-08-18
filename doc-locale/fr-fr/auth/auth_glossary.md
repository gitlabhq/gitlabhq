---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Glossaire d'authentification et d'autorisation"
description: "Terminologie relative à l'authentification, à l'autorisation, aux permissions, aux rôles et au contrôle d'accès."
---

Ce glossaire définit les termes relatifs à l'authentification, à l'autorisation et au contrôle d'accès dans GitLab.

## Identité et fédération {#identity-and-federation}

Fournisseurs d'identité externes et protocoles qui établissent et vérifient les identités des utilisateurs dans les systèmes. Ces termes décrivent comment GitLab s'intègre aux systèmes de gestion des identités d'entreprise pour centraliser l'authentification des utilisateurs.

Fournisseur d'identité (IdP) : Le service qui gère les identités de vos utilisateurs, tel qu'Okta ou OneLogin.

Fournisseur de services (SP) : Une application qui délègue l'authentification à un fournisseur d'identité externe. GitLab agit en tant que fournisseur de services lorsqu'il est configuré pour l'authentification SAML ou OIDC.

Authentification unique (SSO) : Une méthode d'authentification qui permet aux utilisateurs d'accéder à plusieurs applications avec un seul ensemble d'identifiants. Avec le SSO, les utilisateurs s'authentifient une seule fois via un fournisseur d'identité et accèdent à GitLab et à d'autres services connectés sans avoir à saisir à nouveau leurs identifiants.

SAML : Security Assertion Markup Language, un protocole basé sur XML permettant l'échange de données d'authentification et d'autorisation entre les fournisseurs d'identité et les fournisseurs de services. GitLab prend en charge [l'authentification SAML](../integration/saml.md) pour l'authentification unique d'entreprise.

LDAP : Lightweight Directory Access Protocol, un standard pour accéder aux services d'annuaire et les maintenir. GitLab s'intègre aux [serveurs LDAP](../administration/auth/ldap/_index.md) pour authentifier les utilisateurs et synchroniser les informations de compte.

SCIM : System for Cross-domain Identity Management, un standard permettant d'automatiser le provisionnement et le déprovisionnement des utilisateurs. GitLab prend en charge [SCIM](../user/group/saml_sso/scim_setup.md) pour synchroniser les événements du cycle de vie des utilisateurs depuis les fournisseurs d'identité.

OIDC (OpenID Connect) : Une couche d'authentification construite sur OAuth 2.0 qui fournit une vérification d'identité. GitLab prend en charge [OIDC](../administration/auth/oidc.md) pour l'authentification et agit en tant que fournisseur OIDC pour les applications externes.

OAuth : Un protocole d'autorisation permettant d'accéder aux ressources GitLab au nom des utilisateurs sans partager les mots de passe. [OAuth](../integration/oauth_provider.md) prend en charge les intégrations tierces et GitLab en tant que fournisseur d'identité.

Assertion : Une information sur une identité d'utilisateur, telle que son nom ou son rôle. Également appelée revendication ou attribut.

Revendication : Informations sur une identité d'utilisateur ou des attributs inclus dans les jetons d'authentification. Les revendications sont utilisées dans les jetons OAuth, OIDC et JWT pour transmettre des informations telles que le nom d'utilisateur, l'adresse e-mail ou l'appartenance à un groupe.

Provisionnement : Le processus automatisé de création et de configuration des comptes utilisateur et des droits d'accès. Vous pouvez utiliser SCIM ou LDAP pour synchroniser les utilisateurs depuis des systèmes d'identité externes vers GitLab.

URL du service consommateur d'assertions : Le point de terminaison sur GitLab vers lequel les utilisateurs sont redirigés après s'être authentifiés avec succès auprès du fournisseur d'identité.

Émetteur : La façon dont GitLab s'identifie auprès d'un fournisseur d'identité. Également appelé identifiant de confiance de la partie de confiance.

Empreinte du certificat : Confirme que les communications SAML sont sécurisées en vérifiant que le serveur signe les communications avec le bon certificat. Également appelée empreinte numérique du certificat.

## Authentification {#authentication}

Méthodes et identifiants qui vérifient l'identité d'un utilisateur avant d'accorder l'accès à GitLab. L'authentification confirme votre identité avant d'accorder l'accès au système. Les [méthodes d'authentification](user_authentication.md) comprennent les mots de passe, l'authentification à deux facteurs, les clés SSH, les jetons d'accès personnels et l'intégration avec des fournisseurs d'identité externes.

Clé d'accès : Une méthode d'authentification sans mot de passe utilisant des identifiants cryptographiques stockés sur des appareils. Les [clés d'accès](passkeys.md) offrent une authentification résistante au phishing grâce à la biométrie ou aux codes PIN des appareils.

Authentification à deux facteurs (2FA) : Une couche de sécurité supplémentaire qui exige des utilisateurs qu'ils fournissent une deuxième forme d'authentification au-delà de leur mot de passe. GitLab prend en charge diverses [méthodes de 2FA](../user/profile/account/two_factor_authentication.md), notamment les applications d'authentification et les codes de récupération.

Session : Un état authentifié temporaire qui persiste après qu'un utilisateur s'est connecté à GitLab. Les sessions persistent entre les requêtes jusqu'à l'expiration ou la fermeture de la session.

Clés SSH : Des clés cryptographiques utilisées pour une authentification sécurisée lors de l'accès aux dépôts Git. Les [clés SSH](../user/ssh.md) constituent une alternative sécurisée à l'authentification par mot de passe pour les opérations Git.

Jeton d'accès personnel : Un jeton qui sert d'alternative aux mots de passe pour l'authentification lors de l'utilisation de l'API GitLab ou de Git via HTTPS. Les [jetons d'accès personnels](../user/profile/personal_access_tokens.md) disposent de portées définies qui limitent les actions qu'ils peuvent effectuer.

Jeton d'accès de groupe : Un jeton dont la portée est limitée à un groupe spécifique pour les tâches automatisées dans ce groupe et dans ses sous-groupes. Les [jetons d'accès de groupe](../user/group/settings/group_access_tokens.md) héritent des permissions du groupe et prennent en charge l'accès à l'API et les opérations Git.

Jeton d'accès au projet : Un jeton dont la portée est limitée à un projet spécifique pour les tâches automatisées dans ce projet. Les [jetons d'accès au projet](../user/project/settings/project_access_tokens.md) sont couramment utilisés pour les pipelines CI/CD et les intégrations nécessitant un accès spécifique au projet.

Jeton de déploiement : Un jeton avec des portées limitées pour l'automatisation des déploiements. Les [jetons de déploiement](../user/project/deploy_tokens/_index.md) fournissent un accès en lecture seule ou en écriture aux dépôts et aux registres de paquets sans nécessiter de compte utilisateur.

JWT (JSON Web Token) : Un format de jeton compact permettant de transmettre des informations de manière sécurisée entre des parties. GitLab utilise les JWT pour l'authentification des jobs CI/CD, les flux OAuth et la communication entre services.

Emprunt d'identité : Une fonctionnalité administrative permettant aux utilisateurs autorisés d'agir temporairement en tant qu'un autre utilisateur. L'[emprunt d'identité](../api/rest/authentication.md#impersonation-tokens) est parfois utilisé pour résoudre des problèmes spécifiques à un utilisateur.

## Gestion des utilisateurs et des comptes {#user-and-account-management}

Types de comptes et catégories d'utilisateurs qui définissent différents niveaux d'accès et capacités dans GitLab. Ces termes décrivent les différents types de comptes pouvant interagir avec le système.

Compte utilisateur : Un compte individuel représentant une personne accédant à GitLab. Les comptes utilisateur peuvent se voir attribuer différents rôles dans différents groupes et projets.

Types d'utilisateurs : Le type attribué à un compte utilisateur qui accorde implicitement un ensemble d'actions autorisées. Les types comprennent Regular, Auditor et Administrator. Les types sont différents des rôles et des permissions.

Utilisateurs administrateurs : Un type d'utilisateur disposant du plus haut niveau d'accès au système. Les utilisateurs disposant d'un accès administrateur peuvent configurer les paramètres à l'échelle de l'instance, gérer les autres utilisateurs et effectuer des tâches administratives dans tous les groupes et projets.

### Utilisateurs auditeurs {#auditor-users}

Un type d'utilisateur spécial disposant d'un accès en lecture seule à tous les groupes, projets et fonctions administratives. Les [utilisateurs auditeurs](../administration/auditor_users.md) ne peuvent pas apporter de modifications, mais peuvent consulter le contenu à des fins de conformité et de sécurité.

Utilisateurs externes : Utilisateurs désignés comme externes à votre organisation qui disposent d'un accès restreint aux projets et groupes internes. Les [utilisateurs externes](../administration/external_users.md) ne peuvent accéder qu'aux projets pour lesquels ils ont une appartenance directe.

Comptes de service : Des comptes utilisateur non humains conçus pour effectuer des actions automatisées, accéder aux données ou exécuter des processus planifiés. Les [comptes de service](../user/profile/service_accounts.md) sont couramment utilisés dans les pipelines ou les intégrations tierces.

## Autorisation et contrôle d'accès {#authorization-and-access-control}

Cadres et processus qui déterminent ce que les utilisateurs authentifiés peuvent faire dans GitLab. L'autorisation évalue les permissions en fonction de l'identité de l'utilisateur, des rôles et de la propriété des ressources.

Contrôle d'accès : La pratique consistant à restreindre l'accès aux ressources en fonction de l'authentification (vérification de l'identité d'un utilisateur) et de l'autorisation (détermination de ce qu'un utilisateur peut faire).

Autorisation : Le processus qui détermine les actions qu'un utilisateur authentifié peut effectuer dans GitLab. L'autorisation est basée sur les rôles utilisateur attribués, les permissions et l'appartenance aux groupes et projets.

RBAC (contrôle d'accès basé sur les rôles) : Un modèle de contrôle d'accès où les permissions sont attribuées via des rôles plutôt que directement aux utilisateurs. Dans GitLab, les utilisateurs reçoivent des permissions en fonction du rôle qui leur est attribué dans un groupe ou un projet.

Politique : Un ensemble de règles d'autorisation qui déterminent les actions que les principaux peuvent effectuer sur les ressources. GitLab applique les décisions de contrôle d'accès à l'aide du [framework Declarative Policy](../development/policies.md).

## Permissions et rôles {#permissions-and-roles}

Les éléments fondamentaux qui définissent les actions que les utilisateurs peuvent effectuer sur les ressources. Les permissions se combinent en rôles, qui sont attribués aux utilisateurs pour leur accorder des capacités spécifiques.

Permission : Les [actions spécifiques](../user/permissions.md) qu'un utilisateur peut effectuer sur les ressources GitLab, comme créer des tickets, pousser du code ou gérer les paramètres du projet.

Rôles : Des ensembles d'une ou plusieurs permissions attribuées à un utilisateur qui définissent les actions qu'il peut effectuer dans les groupes et les projets. Les rôles comprennent à la fois des rôles par défaut et des rôles personnalisés.

Rôles par défaut : Les [rôles prédéfinis](../user/permissions.md) disponibles dans chaque instance GitLab. Chaque rôle inclut un ensemble spécifique de permissions. Les rôles par défaut disponibles sont les suivants : `Minimal Access`, `Guest`, `Planner`, `Reporter`, `Security Manager`, `Developer`, `Maintainer`, `Owner`.

Rôles personnalisés : Des rôles que vous créez pour votre instance GitLab afin de répondre à vos besoins organisationnels. Chaque [rôle personnalisé](../user/custom_roles/_index.md) étend un rôle par défaut avec des permissions supplémentaires.

Portées : Les permissions disponibles pour un jeton ou une application OAuth à un niveau organisationnel spécifique. GitLab utilise les portées pour déterminer l'accès accordé aux jetons d'accès personnels, aux jetons d'accès de groupe, aux jetons d'accès au projet et aux applications OAuth.

## Structure organisationnelle {#organizational-structure}

Des conteneurs et des relations hiérarchiques qui organisent les ressources et contrôlent l'accès. Ces structures déterminent la façon dont les permissions se propagent dans les groupes, les projets et les espaces de nommage.

Espace de nommage : Un conteneur qui organise les groupes et les projets dans une structure hiérarchique. Les espaces de nommage déterminent les chemins des ressources et l'héritage des permissions. Chaque utilisateur dispose d'un espace de nommage personnel, et les groupes fournissent des espaces de nommage partagés pour les équipes.

Groupe : Un ensemble de projets et d'utilisateurs liés qui permet une organisation et une gestion des permissions efficaces. Les groupes peuvent contenir des sous-groupes et hériter des permissions des groupes parents.

Membre : Un utilisateur qui s'est vu accorder l'accès à un groupe ou à un projet spécifique. Les membres ont un rôle attribué qui détermine leurs permissions dans cette ressource.

Appartenance : L'association entre un utilisateur et un groupe ou un projet spécifique qui définit ses droits d'accès dans cette ressource. Les utilisateurs peuvent avoir différentes appartenances et différents rôles dans plusieurs groupes et projets.

Périmètres : Les niveaux organisationnels auxquels les permissions et les politiques peuvent être appliquées :

<!-- markdownlint-disable MD007 -->

  - Instance : S'applique à l'ensemble de l'instance GitLab.
  - Groupe : S'applique à un groupe spécifique, ainsi qu'à ses sous-groupes ou projets.
  - Projet : S'applique uniquement à un seul projet.
  - Utilisateur : S'applique aux actions effectuées par ou au nom d'un utilisateur spécifique.

<!-- markdownlint-disable MD007 -->

Héritage : Le flux automatique des permissions des groupes parents vers les groupes enfants et les projets. L'héritage simplifie la gestion des accès en appliquant les permissions accordées à un niveau supérieur à tous les sous-groupes et projets imbriqués.

Visibilité : Les [paramètres](../user/public_access.md) qui contrôlent qui peut afficher et accéder à votre contenu :

<!-- markdownlint-disable MD007 -->

  - Public : Visible par tous, y compris les utilisateurs sans compte GitLab.
  - Interne : Visible par tous les utilisateurs GitLab authentifiés.
  - Privé : Visible par les membres uniquement.

<!-- markdownlint-disable MD007 -->
