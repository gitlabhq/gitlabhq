---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Répondre aux incidents de sécurité
---

Lorsqu'un incident de sécurité survient, vous devez en premier lieu suivre les processus définis par votre organisation. L'équipe GitLab Security Operations a créé ce guide :

- Pour les administrateurs et les mainteneurs d'instances GitLab Self-Managed et de groupes sur GitLab.com.
- Pour fournir des informations supplémentaires et des bonnes pratiques sur la manière de répondre à différents incidents de sécurité liés aux services GitLab.
- En complément des processus définis par votre organisation pour gérer les incidents de sécurité. Il ne s'agit **pas d’un remplacement**.

Grâce à ce guide, vous devriez vous sentir en confiance pour gérer les incidents de sécurité liés à GitLab. Le cas échéant, le guide renvoie vers d'autres parties de la documentation GitLab.

> [!warning]
> Utilisez les suggestions et recommandations mentionnées dans ce guide à vos propres risques.

## Scénarios courants d'incidents de sécurité {#common-security-incident-scenarios}

### Exposition de credentials sur l'Internet public {#credential-exposure-to-public-internet}

Ce scénario désigne les événements de sécurité au cours desquels des informations sensibles d'authentification ou d'autorisation ont été exposées sur Internet en raison de mauvaises configurations ou d'erreurs humaines. Ces informations peuvent inclure :

- Mots de passe
- Jetons d'accès personnels
- Jetons d'accès de groupe/projet
- Jetons de runner
- Jetons de déclenchement de pipeline
- Clés SSH

Ce scénario peut également inclure l'exposition d'informations sensibles sur des credentials tiers via les services GitLab. L'exposition peut survenir, par exemple, par des commits accidentels dans des projets GitLab publics, ou par une mauvaise configuration des paramètres CI/CD. Pour plus d'informations, consultez :

- [Présentation des jetons GitLab](tokens/_index.md)
- [Sécurité des variables CI/CD GitLab](../ci/variables/_index.md#cicd-variable-security)

#### Réponse {#response}

Les incidents de sécurité liés à l'exposition de credentials peuvent varier en gravité, de faible à critique, selon le type de jeton et les permissions qui lui sont associées. Lorsque vous répondez à de tels incidents, vous devez :

- Déterminer le type et la portée du jeton.
- Identifier le propriétaire du jeton et l'équipe concernée sur la base des informations relatives au jeton.
  - Pour les jetons d'accès personnels, vous pouvez utiliser l'[API des jetons d'accès personnels](../api/personal_access_tokens.md#retrieve-a-personal-access-token) pour récupérer rapidement les détails du jeton.
- [Révoquer](../api/personal_access_tokens.md#revoke-a-personal-access-token) ou [faire tourner](../api/group_access_tokens.md#rotate-a-group-access-token) le jeton après en avoir évalué la portée et l'impact potentiel. La révocation d'un jeton de production implique un équilibre entre le risque de sécurité posé par le jeton exposé et le risque de disponibilité que peut entraîner la révocation d'un jeton. Ne révoquez le jeton que si vous :
  - Êtes certain de comprendre l'impact potentiel de la révocation du jeton.
  - Suivez les directives de réponse aux incidents de sécurité de votre entreprise.
- Documentez le moment de l'exposition des credentials et le moment où vous avez révoqué les credentials.
- Consultez les journaux d'audit GitLab pour identifier toute activité non autorisée associée au jeton exposé. En fonction de la portée et du type de jeton, recherchez les événements d'audit liés à :
  - Utilisateurs nouvellement créés
  - Jetons
  - Pipelines malveillants
  - Modifications du code
  - Modifications des paramètres du projet

#### Types d'événements {#event-types}

- Consultez les [événements d'audit](../administration/compliance/audit_event_reports.md) disponibles pour votre groupe ou espace de nommage.
- Les adversaires peuvent tenter de créer des jetons, des clés SSH ou des comptes utilisateurs pour maintenir leur persistance. Recherchez les [événements d'audit](../user/compliance/audit_event_types.md) liés à ces activités.
- Concentrez-vous sur les [événements d'audit](../user/compliance/audit_event_types.md#continuous-integration) liés à la CI pour identifier toute modification des variables CI/CD.
- Consultez les [job logs](../administration/cicd/job_logs.md) pour tout pipeline exécuté par un adversaire

### Compte utilisateur suspecté d'être compromis {#suspected-compromised-user-account}

#### Réponse {#response-1}

Si vous suspectez qu'un compte utilisateur ou un compte bot a été compromis, vous devez :

- [Bloquer l'utilisateur](../administration/moderate_users.md#block-a-user) pour atténuer tout risque immédiat.
- Réinitialiser tous les credentials auxquels l'utilisateur aurait pu avoir accès. Par exemple, les utilisateurs ayant le rôle Maintainer ou Owner peuvent consulter les [variables CI/CD](../ci/variables/_index.md) protégées et les [jetons d'enregistrement de runner](tokens/_index.md#runner-registration-tokens-legacy).
- [Réinitialiser les mots de passe des utilisateurs](reset_user_password.md).
- Demandez à l'utilisateur d'[activer l'authentification à deux facteurs](../user/profile/account/two_factor_authentication.md) (2FA), et envisagez d'[imposer la 2FA pour une instance ou un groupe](two_factor_authentication.md).
- Une fois l'investigation terminée et les impacts atténués, débloquez l'utilisateur.

#### Types d'événements {#event-types-1}

Consultez les [événements d'audit](../administration/compliance/audit_event_reports.md) disponibles pour identifier tout comportement de compte suspect. Par exemple :

- Événements de connexion suspects
- Création ou suppression de jetons d'accès personnels, de projet et de groupe
- Création ou suppression de clés SSH ou GPG
- Création, modification ou suppression de l'authentification à deux facteurs
- Modifications des dépôts
- Modifications des configurations de groupe ou de projet
- Ajout ou modification de runners
- Ajout ou modification de webhooks ou de hooks Git
- Ajout ou modification d'applications OAuth autorisées
- Modifications des fournisseurs d'identité SAML connectés
- Modifications des adresses e-mail ou des notifications

### Incidents de sécurité liés à la CI/CD {#cicd-related-security-incidents}

Les workflows CI/CD sont une composante essentielle du développement logiciel moderne et sont principalement utilisés par les développeurs et les SRE pour compiler, tester et déployer du code en production. Ces workflows étant liés aux environnements de production, ils nécessitent souvent l'accès à des secrets sensibles au sein des pipelines CI/CD. Les incidents de sécurité liés à la CI/CD peuvent varier selon votre configuration, mais ils peuvent être globalement classés comme suit :

- Incidents de sécurité liés à des jetons de job CI/CD GitLab exposés
- Secrets exposés par une mauvaise configuration de GitLab CI/CD

#### Réponse {#response-2}

##### Jeton de job GitLab CI/CD exposé {#exposed-gitlab-cicd-job-token}

Lorsqu'un job de pipeline est sur le point de s'exécuter, GitLab génère un jeton unique et l'injecte en tant que `CI_JOB_TOKEN` dans la [variable prédéfinie](../ci/variables/predefined_variables.md). Vous pouvez utiliser un jeton de job CI/CD GitLab pour vous authentifier auprès de points de terminaison d'API spécifiques. Ce jeton dispose des mêmes permissions d'accès à l'API que l'utilisateur ayant déclenché l'exécution du job. Le jeton n'est valide que pendant l'exécution du job du pipeline. Une fois le job terminé, le jeton expire et ne peut plus être utilisé.

Dans des circonstances normales, le `CI_JOB_TOKEN` n'est pas affiché dans les job logs. Cependant, vous pouvez exposer ces données involontairement en :

- Activant la journalisation détaillée dans un pipeline
- Exécutant des commandes qui affichent les variables d'environnement shell dans la console
- Ne pas sécuriser correctement l'infrastructure des runners peut exposer ces données involontairement

Dans de tels cas, vous devez :

- Vérifier s'il y a eu des modifications récentes du code source dans le dépôt. Vous pouvez consulter l'historique des commits du fichier modifié pour déterminer l'acteur ayant effectué les modifications. Si vous suspectez des modifications suspectes, examinez l'activité de l'utilisateur en utilisant le [guide sur les comptes utilisateurs suspectés d'être compromis](responding_to_security_incidents.md#suspected-compromised-user-account).
- Toute modification suspecte d'un code appelé par ce fichier peut entraîner des problèmes, doit faire l'objet d'une investigation et peut conduire à l'exposition de secrets.
- Envisagez de faire tourner les secrets exposés après avoir déterminé l'impact de la révocation sur la production.
- Consultez les [journaux d'audit](../administration/compliance/audit_event_reports.md) disponibles pour identifier toute modification suspecte des paramètres des utilisateurs et des projets.

##### Secrets exposés par une mauvaise configuration de GitLab CI/CD {#secrets-exposed-through-misconfigured-gitlab-cicd}

Lorsque des secrets stockés en tant que variables CI ne sont pas [masqués](../ci/variables/_index.md#mask-a-cicd-variable), ils peuvent être exposés dans les job logs. Par exemple, en affichant des variables d'environnement ou en rencontrant un message d'erreur détaillé. Selon la visibilité du projet, les job logs peuvent être accessibles au sein de votre entreprise ou sur Internet si votre projet est public. Pour atténuer ce type d'incident de sécurité, vous devez :

- Révoquer les secrets exposés en suivant le [guide sur les secrets exposés](#credential-exposure-to-public-internet).
- Envisager de masquer les variables. Cela empêchera qu'elles apparaissent directement dans les job logs. Cependant, le masquage n'est pas infaillible. Par exemple, une variable masquée peut toujours être écrite dans un fichier d'artefact ou envoyée vers un système distant.
- Envisager de protéger les variables. Cela garantit qu'elles ne sont disponibles que dans les branches protégées.
- Envisager de désactiver les pipelines publics pour empêcher l'accès public aux job logs et aux artefacts.
- Vérifier les politiques de rétention et d'expiration des artefacts.
- Suivre le [guide de sécurité des jetons de jobs](../ci/jobs/ci_job_token.md#gitlab-cicd-job-token-security) CI/CD pour plus d'informations sur les bonnes pratiques.
- Consultez les journaux d'audit des systèmes contenant des secrets exposés, tels que les journaux CloudTrail pour AWS ou les CloudAudit Logs pour GCP, afin de déterminer si des modifications suspectes ont été effectuées au moment de l'exposition.
- Consultez les journaux d'audit disponibles pour identifier toute modification suspecte des paramètres des utilisateurs et des projets.

### Instance suspectée d'être compromise {#suspected-compromised-instance}

Les clients et les administrateurs de GitLab Self-Managed sont responsables de :

- La sécurité de leur infrastructure sous-jacente
- La mise à jour régulière de leur installation GitLab

Il est important de [mettre régulièrement à jour GitLab](../policy/maintenance.md), de mettre à jour votre système d'exploitation et ses logiciels, et de renforcer la sécurité de vos hôtes conformément aux recommandations du fournisseur.

#### Réponse {#response-3}

Si vous suspectez que votre instance GitLab a été compromise, vous devez :

- Consulter les [événements d'audit](../administration/compliance/audit_event_reports.md) disponibles pour identifier tout comportement de compte suspect.
- Consulter [tous les utilisateurs](../administration/moderate_users.md) (y compris l'utilisateur root administrateur), et suivre les étapes du [guide sur les comptes utilisateurs suspectés d'être compromis](responding_to_security_incidents.md#suspected-compromised-user-account) si nécessaire.
- Consulter l'inventaire des credentials, si disponible.
- Modifier tous les credentials, variables, jetons et secrets sensibles. Par exemple, ceux situés dans la configuration de l'instance, la base de données, les pipelines CI/CD ou ailleurs.
- Mettre à jour vers la dernière version de GitLab et adopter un plan de mise à jour après chaque publication de correctif de sécurité.
- De plus, les suggestions suivantes constituent des étapes courantes dans les plans de réponse aux incidents lorsque des serveurs sont compromis par des acteurs malveillants :
  1. Sauvegarder l'état du serveur et les journaux dans un emplacement en écriture unique, pour une investigation ultérieure.
  1. Rechercher des processus en arrière-plan non reconnus.
  1. Vérifier les ports ouverts sur le système. Notre [guide des ports par défaut](../administration/package_information/defaults.md) peut servir de point de départ.
  1. Reconstruire l'hôte à partir d'une sauvegarde connue comme fiable ou depuis zéro, et appliquer tous les derniers correctifs de sécurité.
  1. Examiner les journaux réseau pour détecter tout trafic inhabituel.
  1. Mettre en place une surveillance du réseau et des contrôles au niveau réseau.
  1. Restreindre l'accès réseau entrant et sortant aux utilisateurs et serveurs autorisés uniquement.
  1. S'assurer que tous les journaux sont acheminés vers un datastore indépendant en écriture seule.

#### Types d'événements {#event-types-2}

Consultez les [événements d'audit d'accès système](../user/compliance/audit_event_types.md#system-access) pour déterminer les modifications liées aux paramètres système, aux permissions des utilisateurs et aux événements de connexion des utilisateurs.

### Paramètres de projet ou de groupe mal configurés {#misconfigured-project-or-group-settings}

Des incidents de sécurité peuvent survenir à la suite de paramètres de projet ou de groupe mal configurés, pouvant conduire à un accès non autorisé à des données sensibles ou propriétaires. Ces incidents peuvent inclure, sans s'y limiter :

- Modifications de la visibilité du projet
- Modifications des paramètres d'approbation des merge requests
- Suppressions de projets
- Ajout de webhooks suspects aux projets
- Modifications des paramètres des branches protégées

#### Réponse {#response-4}

Si vous suspectez des modifications non autorisées des paramètres du projet, envisagez de prendre les mesures suivantes :

- Commencez par consulter les [événements d'audit](../administration/compliance/audit_event_reports.md) disponibles pour identifier l'utilisateur responsable de l'action.
- Si le compte utilisateur semble suspect, suivez les étapes décrites dans le [guide sur les comptes utilisateurs suspectés d'être compromis](responding_to_security_incidents.md#suspected-compromised-user-account).
- Envisagez de rétablir les paramètres dans leur état d'origine en vous référant aux événements d'audit et en consultant les propriétaires et mainteneurs du projet pour obtenir des conseils.

#### Types d'événements {#event-types-3}

- Les journaux d'audit peuvent être filtrés selon le champ `target_type`. En fonction du contexte de l'incident de sécurité, appliquez un filtre sur ce champ pour réduire la portée.
- Recherchez des événements d'audit spécifiques relatifs à la [gestion de la conformité](../user/compliance/audit_event_types.md#compliance-management) et aux [événements d'audit des groupes et projets](../user/compliance/audit_event_types.md#groups-and-projects).

### Faire appel à GitLab pour obtenir de l'aide lors d'un incident de sécurité {#engaging-gitlab-for-assistance-with-a-security-incident}

Avant de demander de l'aide à GitLab, consultez la [documentation GitLab](https://docs.gitlab.com). Vous devriez contacter le support après avoir effectué l'investigation préliminaire de votre côté et si vous avez des questions supplémentaires ou besoin d'assistance. L'éligibilité à l'assistance du support GitLab est [déterminée par votre licence](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support#gitlab-support-service-levels).

### Bonnes pratiques de sécurité {#security-best-practices}

Consultez la [documentation GitLab Security](_index.md) pour des suggestions sur la gestion de votre environnement.

#### Recommandations de renforcement {#hardening-recommendations}

Pour plus d'informations sur l'amélioration de la posture de sécurité de votre environnement GitLab, consultez les [recommandations de renforcement](hardening.md).

Vous pouvez également envisager d'implémenter une limite de débit contre les abus, comme décrit dans [Git abuse rate limit](../user/group/reporting/git_abuse_rate_limit.md). La définition de limites de débit contre les abus peut aider à atténuer automatiquement certains types d'incidents de sécurité.

### Détections {#detections}

GitLab SIRT maintient un dépôt actif de détections dans le [projet public GitLab SIRT](https://gitlab.com/gitlab-security-oss/guard/-/tree/main/detections).

Les détections de ce dépôt sont basées sur les événements d'audit et suivent le format général des règles Sigma. Vous pouvez utiliser un convertisseur de règles Sigma pour obtenir les règles dans le format souhaité. Consultez le dépôt pour plus d'informations sur le format Sigma et les outils associés. Assurez-vous que les journaux d'audit GitLab sont ingérés dans votre SIEM. Vous devez suivre le guide de streaming des événements d'audit [pour votre instance auto-hébergée](../administration/compliance/audit_event_streaming.md) ou votre [groupe principal GitLab.com](../user/compliance/audit_event_streaming.md) pour streamer les événements d'audit vers la destination souhaitée.
