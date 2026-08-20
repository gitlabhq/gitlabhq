---
stage: Release Notes
group: Monthly Release
date: 2024-10-17
title: "Notes de release de GitLab 17.5"
description: "GitLab 17.5 publiée avec l'introduction de Duo Quick Chat"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 17 octobre 2024, GitLab 17.5 a été publiée avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Jim Ender {#this-months-notable-contributor-jim-ender}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination ! 🙌

Jim a été reconnu pour avoir mené un effort visant à [clôturer près de 100 tickets en attente](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=updated_desc&state=closed&assignee_username%5B%5D=Jimender2&first_page_size=100) sur GitLab. Il participe activement à de nombreuses sessions hebdomadaires de pairing communautaire qui donnent lieu à des discussions intéressantes. Jim soutient également les personnes sur le [Discord de la communauté GitLab](https://discord.gg/gitlab), en résolvant les demandes d'assistance GitLab et en guidant les nouveaux contributeurs. Jim travaille pour une entreprise de technologie industrielle, où il développe des logiciels pour les infrastructures critiques et les systèmes ERP.

« Même les petites contributions s'accumulent pour améliorer les projets », dit Jim. « Quelque chose d'aussi modeste que des contributions à la documentation aide les autres. Il n'est pas nécessaire de porter une toute nouvelle fonctionnalité. »

Jim a été nommé par [Lee Tickett](https://gitlab.com/leetickett-gitlab), Staff FullStack Engineer, Contributor Success chez GitLab. « Le triage et la gestion des tickets figurent en tête de ma liste pour impliquer davantage la communauté, et Jim ouvre la voie », dit Lee.

[Daniel Murphy](https://gitlab.com/daniel-murphy), Senior Program Manager, Contributor Success chez GitLab, a ajouté à la nomination. « Le soutien exceptionnel de Jim envers les nouveaux contributeurs et ses conseils pour les aider à démarrer nous permettent de grandir en tant que communauté pour co-créer GitLab. »

« Travail impressionnant sur la [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163849) que j'ai relue ! » dit [Vanessa Otto](https://gitlab.com/vanessaotto), Senior Frontend Engineer chez GitLab. « Jim a répondu rapidement, a compris les suggestions immédiatement et les a mises en œuvre de façon transparente. Il était formidable de voir une telle efficacité et une telle clarté dans l'approche de Jim. »

Nous sommes très reconnaissants envers Jim et toute notre communauté open source pour leurs contributions à GitLab !

## Fonctionnalités principales {#primary-features}

### Présentation de Duo Quick Chat {#introducing-duo-quick-chat}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/_index.md#in-an-editor-window) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15218)

{{< /details >}}

Voici Duo Quick Chat, un chat alimenté par l'IA conçu pour fonctionner exactement là où vous vous trouvez dans votre code. Duo Quick Chat opère directement sur les lignes que vous éditez, offrant une assistance en temps réel sans jamais vous éloigner de votre code. Que vous refactorisiez, corrigiez des bugs ou rédigiez des tests, Duo Quick Chat fournit des suggestions et des explications sur le vif, vous permettant de rester pleinement concentré sans changer de contexte.

### Utiliser un modèle auto-hébergé pour GitLab Duo Code Suggestions {#use-self-hosted-model-for-gitlab-duo-code-suggestions}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/498114)

{{< /details >}}

Vous pouvez désormais héberger les grands modèles de langage (LLM) sélectionnés dans votre propre infrastructure et configurer ces modèles comme source pour Code Suggestions. Cette fonctionnalité est en version bêta et disponible avec un abonnement Ultimate et Duo Enterprise sur les environnements GitLab Self-Managed.

Avec les modèles auto-hébergés, vous pouvez utiliser des modèles hébergés sur site ou dans un cloud privé pour activer GitLab Duo Code Suggestions. Nous prenons actuellement en charge les modèles Mistral open source sur vLLM ou AWS Bedrock. En activant les modèles auto-hébergés, vous pouvez tirer parti de la puissance de l'IA générative tout en maintenant une souveraineté et une confidentialité complètes des données.

Veuillez laisser vos commentaires dans [le ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/498376).

### Exporter les événements d'utilisation des suggestions de code {#export-code-suggestion-usage-events}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../api/graphql/reference/_index.md#codesuggestionevent) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/477231)

{{< /details >}}

Précédemment, les analyses d'impact IA n'étaient disponibles que sur GitLab.com pour les clients GitLab Duo Enterprise, et sur GitLab Self-Managed avec une intégration ClickHouse. De plus, les métriques par défaut étaient agrégées.

Désormais, vous pouvez exporter les événements bruts de suggestions de code depuis l'API GraphQL. Vous pouvez ainsi importer les données dans votre outil d'analyse de données pour obtenir des informations plus approfondies sur les taux d'acceptation selon davantage de dimensions, telles que la taille de la suggestion, le langage et l'utilisateur. Les événements bruts ne sont pas stockés dans ClickHouse, de sorte que certaines métriques d'AI Impact Analytics deviennent disponibles pour tous les déploiements GitLab, y compris GitLab Dedicated et self-managed.

### Avoir une conversation avec GitLab Duo Chat à propos de votre merge request {#have-a-conversation-with-gitlab-duo-chat-about-your-merge-request}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/examples.md#ask-about-a-specific-merge-request) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/464587)

{{< /details >}}

En réponse à vos retours, GitLab Duo Chat est désormais capable de traiter les merge requests. Que vous soyez relecteur ou auteur, vous pouvez désormais converser avec Chat à propos d'une merge request pour l'analyser rapidement ou savoir quoi faire ensuite. Ouvrez simplement votre merge request, puis Duo Chat, et commencez la conversation.

Cette nouvelle fonctionnalité complète notre fonctionnalité existante, qui vous permet de remplir rapidement la description d'une merge request en demandant à GitLab Duo de [résumer les modifications du code](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes), afin que les relecteurs puissent avoir une compréhension générale de l'objet de la merge request.

### Fonctionnalités améliorées d'édition des règles de branche {#enhanced-branch-rules-editing-capabilities}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/branches/branch_rules.md#create-a-branch-rule)

{{< /details >}}

Dans GitLab 15.10, nous avons introduit une [vue consolidée des paramètres et règles liés aux branches](https://about.gitlab.com/releases/2023/03/22/gitlab-15-10-released/#see-all-branch-related-settings-together). Cette vue vous offrait un moyen simple de comprendre la configuration de votre projet à travers plusieurs paramètres.

En s'appuyant sur cette fonctionnalité, vous pouvez désormais modifier directement des règles de branche spécifiques dans cette vue, notamment les protections de branche, les règles d'approbation et les configurations de vérification de statut externe. Ces nouvelles fonctionnalités posent les bases pour des [améliorations continues](https://gitlab.com/groups/gitlab-org/-/epics/12546) de la configuration des branches qui permettront une plus grande flexibilité à l'avenir.

Nous vous encourageons à explorer ces nouvelles fonctionnalités et à nous faire part de vos retours. Vous pouvez le faire en contribuant à notre [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/486050) dédié.

### Vue d'ensemble des locataires GitLab Dedicated dans Switchboard {#gitlab-dedicated-tenant-overview-in-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/dedicated/tenant_overview.md)

{{< /details >}}

La nouvelle vue d'ensemble des locataires de Switchboard offre désormais un espace unique pour accéder rapidement aux informations essentielles sur votre instance GitLab Dedicated.

Avec cette première release, vous pouvez désormais afficher votre version GitLab actuelle, l'URL de l'instance, ainsi que la date et l'heure de vos fenêtres de maintenance à venir et passées, le tout sur la page Vue d'ensemble des locataires.

### Secret Push Protection est en disponibilité générale {#secret-push-protection-is-generally-available}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/secret_push_protection/_index.md)

{{< /details >}}

Nous sommes ravis d'annoncer que Secret Push Protection est désormais en disponibilité générale pour tous les clients GitLab Ultimate.

Si un secret, comme une clé ou un token d'API, est accidentellement commité dans un dépôt Git, toute personne ayant accès au dépôt peut usurper l'identité de l'utilisateur du secret à des fins malveillantes. Un secret divulgué coûte du temps et de l'argent, et peut potentiellement nuire à la réputation d'une entreprise. Secret Push Protection aide à réduire le temps de remédiation et à diminuer les risques en empêchant dès le départ la transmission des secrets.

Secret Push Protection a été améliorée depuis la version bêta. Lorsque des commits sont transmis via le CLI Git, seules les modifications (diff) sont désormais analysées pour détecter des secrets. Nous avons également ajouté une prise en charge expérimentale pour l'exclusion de chemins, de règles ou de valeurs spécifiques afin d'éviter les faux positifs.

Pour en savoir plus, consultez [le blog](https://about.gitlab.com/blog/prevent-secret-leaks-in-source-code-with-gitlab-secret-push-protection/).

### L'inventaire des informations d'identification disponible sur GitLab.com {#credentials-inventory-available-on-gitlabcom}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gold
- Offre : GitLab.com
- Liens : [Documentation](../../administration/credentials_inventory.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/297441)

{{< /details >}}

L'inventaire des informations d'identification est désormais disponible pour les propriétaires de groupes principaux sur GitLab.com. Dans l'inventaire des informations d'identification, vous pouvez consulter les [jetons d'accès personnels](../../user/enterprise_user/_index.md) et les clés SSH de vos utilisateurs d'entreprise dans votre groupe. Vous pouvez également révoquer, supprimer et consulter des informations supplémentaires sur les informations d'identification. Auparavant, cette fonctionnalité n'était disponible que pour les administrateurs sur GitLab Self-Managed.

Les propriétaires de groupes peuvent utiliser l'inventaire des informations d'identification pour comprendre les informations d'identification relevant de leur périmètre, et bénéficier d'une visibilité et d'un contrôle accrus.

### Filtre de composants dans la liste des dépendances {#component-filter-on-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md#filter-dependency-list) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/12652)

{{< /details >}}

Désormais, dans GitLab, vous pouvez filtrer rapidement des composants de dépendances spécifiques pour identifier s'ils sont utilisés ou non dans votre groupe ou projet. Parcourir manuellement toute la liste uniquement pour vérifier si un paquet et une version particuliers sont présents est chronophage et peu pratique. Grâce au nouveau **filter by component** sur la liste des dépendances, vous isolez les dépendances vulnérables afin d'évaluer les risques ouverts dans votre application.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations du chart GitLab {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

GitLab 17.5 inclut une mise à jour de notre version du contrôleur NGINX Ingress. L'image de conteneur `nginx-controller` est désormais en version 1.11.2. Veuillez noter que cela inclut de nouvelles exigences RBAC, car le nouveau contrôleur utilise désormais les endpointslices et nécessite une règle RBAC pour y accéder.

### Améliorations Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.5 inclut la prise en charge de la mise à niveau de PostgreSQL de la version 14.x vers la version 16.x pour les installations à nœud unique. Les mises à niveau automatiques ne sont pas activées ; les mises à niveau de PostgreSQL doivent donc être déclenchées manuellement.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Améliorez votre codage : Duo Chat désormais dans Visual Studio pour Windows {#elevate-your-coding-duo-chat-now-in-visual-studio-for-windows}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-visual-studio-for-windows) \| [Epic associé](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/77)

{{< /details >}}

Optimisez votre workflow de développement avec Duo Chat, désormais intégré de façon transparente dans Visual Studio pour Windows. Duo Chat améliore votre expérience de codage en offrant des fonctionnalités alimentées par l'IA pour expliquer, affiner, déboguer du code ou écrire des tests, le tout en temps réel. Cette intégration vous permet de tirer parti des outils d'IA avancés de Duo Chat directement dans votre environnement de développement habituel, améliorant ainsi la productivité et permettant une résolution de problèmes plus rapide et plus efficace.

### Configurer les paramètres d'agent et d'environnement GitOps avec l'API REST {#configure-agent-and-gitops-environment-settings-with-the-rest-api}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/environments.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/412677)

{{< /details >}}

Vous pouvez vérifier l'état de vos pods et la réconciliation Flux depuis l'interface des environnements GitLab. Cependant, cette approche est difficile à faire évoluer, car les paramètres requis ne sont exposés que via GraphQL ou l'interface. Désormais, GitLab intègre la prise en charge de l'API REST pour configurer un agent pour Kubernetes, ainsi que pour définir l'espace de nommage et la ressource Flux par environnement. Pour améliorer davantage la prise en charge des environnements dynamiques, le [ticket 467912](https://gitlab.com/gitlab-org/gitlab/-/issues/467912) propose d'ajouter la prise en charge de la configuration de ces paramètres dans les pipelines CI/CD.

### Démarrage simplifié de l'intégration GitLab Kubernetes {#easy-bootstrapping-of-gitlab-kubernetes-integration}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/install/_index.md#bootstrap-the-agent-with-flux-support-recommended) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/473987)

{{< /details >}}

GitLab offre un support GitOps flexible, fiable et sécurisé avec l'[agent pour Kubernetes](../../user/clusters/agent/_index.md) et son [intégration Flux](../../user/clusters/agent/gitops.md). Cependant, le démarrage de Flux avec GitLab et la configuration de l'agent pour Kubernetes nécessitaient auparavant beaucoup de lecture de documentation et des allers-retours entre l'interface GitLab et le terminal. Le CLI GitLab propose désormais [la commande `glab cluster agent bootstrap`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/cluster/agent/bootstrap.md) pour simplifier l'installation de l'agent par-dessus une installation Flux existante. Désormais, vous pouvez configurer Flux et l'agent avec seulement deux commandes simples.

### Prise en charge de l'intégration Kubernetes pour les installations GitLab protégées par un pare-feu {#kubernetes-integration-support-for-firewalled-gitlab-installations}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/_index.md#receptive-agents) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/437014)

{{< /details >}}

Jusqu'à présent, l'agent pour Kubernetes ne pouvait être utilisé que si le cluster Kubernetes pouvait se connecter à l'instance GitLab. Ce problème signifiait que certains clients ne pouvaient pas utiliser l'agent si, par exemple, ils exécutaient GitLab sur un réseau privé ou derrière un pare-feu. À partir de GitLab 17.5, vous pouvez initier la connexion cluster-GitLab depuis GitLab, en supposant qu'une instance `agentk` correctement configurée attend déjà une initialisation de connexion.

Une fois la connexion initiale établie, toutes les fonctionnalités de l'agent sont disponibles. L'initialisation depuis un cluster n'est pas modifiée par ce développement.

### Diffuser les événements de ressources Kubernetes {#stream-kubernetes-resource-events}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/470042)

{{< /details >}}

GitLab fournit une vue en temps réel de vos pods, ainsi que la diffusion des journaux de pods, le tout via le tableau de bord pour Kubernetes. Dans GitLab 17.4, nous avons proposé un listing statique des informations d'événements spécifiques aux ressources depuis l'interface. Cette release améliore encore le tableau de bord pour Kubernetes en vous permettant de diffuser les événements entrants au fur et à mesure qu'ils apparaissent dans le cluster.

### Suspendre ou reprendre la réconciliation GitOps depuis l'interface GitLab {#suspend-or-resume-gitops-reconciliation-from-the-gitlab-ui}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md#suspend-or-resume-flux-reconciliation) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/478380)

{{< /details >}}

En tant qu'utilisateur Flux, avez-vous déjà eu besoin d'arrêter rapidement une réconciliation automatique ou une remédiation de dérive ? Avez-vous voulu déclencher un `HelmRelease` pour synchroniser des ressources supprimées manuellement ? Ces actions sont mieux réalisées avec les fonctions de suspension et de reprise de Flux. Jusqu'à présent, votre meilleure option était d'utiliser le CLI Flux, ce qui nécessitait un changement de contexte et plusieurs commandes pour s'assurer que la bonne ressource était concernée. Dans GitLab 17.5, vous pouvez suspendre ou reprendre une réconciliation depuis le tableau de bord intégré pour Kubernetes.

### Résumé amélioré de la gestion des utilisateurs {#improved-user-management-summary}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/profile/account/create_accounts.md#create-a-user-in-the-admin-area) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/456332)

{{< /details >}}

Les administrateurs disposent désormais d'une vue résumée et améliorée des informations critiques suivantes concernant les utilisateurs de leur instance :

- Approbation en attente.
- Sans authentification à deux facteurs.
- Administrateurs.

Cela améliore l'efficacité de la gestion des utilisateurs, car les administrateurs peuvent rapidement voir combien d'utilisateurs se trouvent dans ces états depuis la vue résumée, et les filtrer.

### Ajouter des groupes à la portée des politiques de sécurité {#add-groups-to-security-policy-scope}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14149)

{{< /details >}}

Vous pouvez désormais cibler des groupes/sous-groupes dans les portées des politiques de sécurité. Cela étend les options existantes vous permettant de cibler tous les projets dans un groupe/sous-groupe, les projets basés sur une liste de projets définie, et les projets correspondant à une liste de labels de framework de conformité.

Cela vous offre une flexibilité supplémentaire pour activer des politiques dans vos groupes, tout en permettant d'appliquer des exceptions pour exclure des projets de l'application des politiques si nécessaire.

Cette amélioration précède également un certain nombre d'[améliorations](https://gitlab.com/groups/gitlab-org/-/epics/5446) qui simplifieront le processus de liaison des projets de politiques de sécurité et la définition granulaire de la portée d'application des politiques.

### Désactiver l'authentification par mot de passe pour les utilisateurs d'entreprise {#disable-password-authentication-for-enterprise-users}

<!-- categories: User Management -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/group/saml_sso/_index.md#disable-password-and-passkey-authentication-for-enterprise-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/373718)

{{< /details >}}

Les utilisateurs d'entreprise peuvent s'authentifier à l'aide d'un compte local avec un nom d'utilisateur et un mot de passe. Désormais, les propriétaires de groupes peuvent désactiver l'authentification par mot de passe pour les utilisateurs d'entreprise du groupe. Si l'authentification par mot de passe est désactivée, les utilisateurs d'entreprise peuvent utiliser soit le fournisseur d'identité SAML du groupe pour s'authentifier auprès de l'interface web GitLab, soit un jeton d'accès personnel pour s'authentifier auprès de l'API GitLab et de Git via HTTP Basic Authentication.

### Accéder au centre de conformité sur les projets {#access-compliance-center-on-projects}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/441350)

{{< /details >}}

Précédemment, le centre de conformité n'était disponible que pour les groupes principaux et les sous-groupes.

Avec cette release, nous avons ajouté le centre de conformité aux projets. À ce niveau, le centre de conformité fournit des fonctionnalités en lecture seule pour les vérifications et les violations liées à un projet particulier.

Pour ajouter ou modifier un framework, vous devez accéder au centre de conformité sur les groupes principaux.

### Processus de migration des pipelines de conformité vers les politiques de sécurité {#migration-process-for-compliance-pipelines-to-security-policies}

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_pipelines.md#pipeline-execution-policies-migration) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11275)

{{< /details >}}

Dans GitLab 17.3, nous avons annoncé la dépréciation des pipelines de conformité et leur suppression éventuelle lors de la release 18.0. À la place des pipelines de conformité, vous devez utiliser le type de politique d'exécution de pipeline, publié dans GitLab 17.2.

Pour vous aider à migrer vos pipelines de conformité existants vers le type de politique d'exécution de pipeline, cette release inclut une bannière d'avertissement qui :

- Informe les utilisateurs de la dépréciation des pipelines de conformité.
- Fournit un workflow guidé et accompagné pour migrer les pipelines de conformité existants vers le type de politique d'exécution de pipeline.

### Afficher les associations de tokens à l'aide de l'API {#view-token-associations-using-api}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/personal_access_tokens.md#list-all-token-associations) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/466046)

{{< /details >}}

Vous pouvez désormais voir à quels groupes, sous-groupes et projets un token est associé. Cela facilite la détermination de l'impact des expirations ou révocations de tokens, et la compréhension des endroits où un token peut être utilisé.

### Application sélective de l'authentification unique SAML {#selective-saml-single-sign-on-enforcement}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/sign_in_restrictions.md#disable-password-and-passkey-authentication-for-users-with-an-sso-identity) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/382917)

{{< /details >}}

Précédemment, lorsque SSO SAML était activé, les groupes pouvaient choisir d'appliquer le SSO, ce qui obligeait tous les membres à utiliser l'authentification SSO pour accéder au groupe. Cependant, certains groupes souhaitent bénéficier de la sécurité de l'application du SSO pour les employés ou les membres du groupe, tout en permettant aux collaborateurs externes ou aux prestataires d'accéder à leurs groupes sans SSO.

Désormais, les groupes avec SSO SAML activé ont le SSO automatiquement appliqué pour tous les membres disposant d'une identité SAML. Les membres du groupe sans identité SAML ne sont pas tenus d'utiliser le SSO, sauf si l'application du SSO est explicitement activée.

Un membre a une identité SAML si l'une ou les deux conditions suivantes sont remplies :

- Il s'est connecté à GitLab en utilisant l'URL d'authentification unique de son groupe GitLab.
- Il a été provisionné par SCIM.

Pour garantir le bon fonctionnement de la fonctionnalité d'application sélective du SSO, assurez-vous que votre configuration SAML fonctionne correctement avant de cocher la case **Activer l'authentification SAML pour ce groupe**.

### Améliorer les performances de l'API lors de l'utilisation des tags du registre de conteneurs {#enhance-api-performance-when-working-with-container-registry-tags}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../api/container_registry.md#list-all-registry-repository-tags) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/482399)

{{< /details >}}

Nous sommes ravis d'annoncer une amélioration significative de notre API de registre de conteneurs pour les instances GitLab Self-Managed. Avec la release de GitLab 17.5, nous avons implémenté la pagination par jeu de clés pour le point de terminaison `:id/registry/repositories/:repository_id/tags`, l'alignant sur les fonctionnalités déjà disponibles sur GitLab.com. Cette amélioration s'inscrit dans nos efforts continus pour améliorer les performances de l'API et offrir une expérience cohérente sur tous les déploiements GitLab.

La pagination par jeu de clés offre une méthode plus efficace pour gérer les grands ensembles de données, ce qui se traduit par de meilleures performances et une meilleure expérience utilisateur. Cette mise à jour est particulièrement utile pour la gestion de grands registres de conteneurs, car elle permet une navigation plus fluide dans les tags de dépôt. Pour utiliser cette fonctionnalité, les instances self-managed doivent mettre à niveau vers le [registre de conteneurs de nouvelle génération](../../administration/packages/container_registry_metadata_database.md).

### Protégez vos dépendances avec des paquets protégés {#safeguard-your-dependencies-with-protected-packages}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/packages/package_registry/package_protection_rules.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/472655)

{{< /details >}}

Nous sommes ravis d'introduire la prise en charge des paquets npm protégés, une nouvelle fonctionnalité conçue pour renforcer la sécurité et la stabilité de votre registre de paquets GitLab. Dans le monde du développement logiciel en constante évolution, la modification ou la suppression accidentelle de paquets peut perturber l'ensemble des processus de développement. Les paquets protégés résolvent ce problème en vous permettant de protéger vos dépendances les plus importantes contre des modifications involontaires.

À partir de GitLab 17.5, vous pouvez protéger des paquets npm en créant des règles de protection. Si un paquet correspond à une règle de protection, seuls les utilisateurs et utilisatrices spécifiés peuvent mettre à jour ou supprimer le paquet. Avec cette fonctionnalité, vous pouvez prévenir les modifications accidentelles, améliorer la conformité aux exigences réglementaires et rationaliser vos workflows en réduisant le besoin de supervision manuelle.

### Prise en charge de Ruby et mises à jour des règles pour Advanced SAST {#ruby-support-and-rule-updates-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

Nous avons ajouté la prise en charge de Ruby à GitLab Advanced SAST. Pour utiliser cette nouvelle prise en charge de l'analyse inter-fichiers et inter-fonctions, [activez Advanced SAST](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast). Si vous avez déjà activé Advanced SAST, la prise en charge de Ruby est automatiquement activée.

Au cours du dernier mois, nous avons également publié des mises à jour pour améliorer les règles de détection pour [les autres langages pris en charge par Advanced SAST](../../user/application_security/sast/gitlab_advanced_sast.md#supported-languages) en :

- Détectant des vulnérabilités supplémentaires de traversée de chemin Java, d'injection de commande Java et de traversée de chemin JavaScript.
- Mettant à jour les mappages CWE pour identifier les types de vulnérabilités de manière plus spécifique et cohérente.
- Augmentant la gravité des vulnérabilités de traversée de chemin.

Pour voir quels types de vulnérabilités Advanced SAST détecte dans chaque langage, consultez la nouvelle [page de couverture d'Advanced SAST](../../user/application_security/sast/advanced_sast_coverage.md).

Pour en savoir plus sur Advanced SAST, consultez [le blog d'annonce du mois dernier](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/).

### GitLab Runner 17.5 {#gitlab-runner-175}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 17.5 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Prise en charge des chargements multipart AWS S3 avec des informations d'identification temporaires délimitées](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26921)

#### Corrections de bugs {#bug-fixes}

- [Les jobs avec des services supplémentaires ne se terminent pas si l'un des conteneurs de service n'est pas en cours d'exécution](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38035)
- [Le paquet `gitlab-runner-fips-17.4.0-1` échoue à s'exécuter sur Amazon Linux 2 et retourne une erreur glibc](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38034)
- [Le cache ne fonctionne pas avec Amazon S3 lors de l'utilisation des points de terminaison S3 Express One Zone](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37394)
- [Les jobs ne peuvent pas récupérer les images de base si la variable `DOCKER_AUTH_CONFIG` contient plusieurs registres](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28073)

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.5)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.5)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.5)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
