---
stage: Release Notes
group: Monthly Release
date: 2024-12-19
title: "Notes de release de GitLab 17.7"
description: "GitLab 17.7 publié avec le nouveau rôle utilisateur Planificateur"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 19 décembre 2024, GitLab 17.7 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Vedant Jain {#this-months-notable-contributor-vedant-jain}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination ! 🙌

Vedant est un contributeur communautaire exceptionnel, reconnu pour son approche proactive de la contribution, son engagement à livrer et ses compétences en matière de collaboration. Il excelle à prendre en compte les retours, à les intégrer dans son travail et à demander de l'aide lorsque nécessaire, veillant à ce que ses contributions soient non seulement menées à terme, mais qu'elles répondent également aux standards de GitLab.

Ses contributions incluent la rationalisation des processus de gestion de projets avec [Abstracted work item attributes to a single list/board](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172191), [Ordering of metadata on work items](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173033), et le développement de fonctionnalités dans [Remember the collapsed state of work item widgets](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171228). Vedant a également corrigé des liens dans l'interface vers la documentation ([1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170633), [2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170534)), aidant ainsi l'équipe de rédaction technique dans le cadre d'un effort important visant à améliorer l'expérience utilisateur sur l'ensemble du produit.

[Amanda Rueda](https://gitlab.com/amandarueda), Sr. Product Manager, Product Planning chez GitLab, a nominé Vedant et a mis en avant son état d'esprit proactif et orienté vers la communauté : « Le travail de Vedant répond non seulement aux besoins des utilisateurs, mais, grâce à ses contributions, il co-crée un environnement GitLab plus stable et plus fiable. En contribuant aux corrections de bugs, aux améliorations de l'ergonomie et aux efforts de maintenance, il a joué un rôle essentiel dans l'amélioration de la qualité globale du produit. Son approche proactive et ses contributions transversales incarnent les valeurs fondamentales de GitLab que sont l'itération, la collaboration avec les clients et l'amélioration continue, faisant de lui un contributeur remarquable dans la communauté. »

« Merci à tous ceux qui m'ont aidé à réaliser mes contributions », déclare Vedant. « Je suis très reconnaissant de pouvoir avoir un impact positif et j'espère contribuer encore davantage. »

Vedant est ingénieur frontend chez Atlan, une plateforme de métadonnées active pour les équipes de données modernes, et mentor pour Google Summer of Code 2024.

Nous sommes très reconnaissants envers Vedant pour toutes ses contributions, ainsi qu'envers l'ensemble de notre communauté open source pour ses contributions à GitLab !

## Fonctionnalités principales {#primary-features}

### Nouveau rôle utilisateur Planificateur {#new-planner-user-role}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/permissions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/482733)

{{< /details >}}

Nous avons introduit le nouveau rôle Planificateur pour vous offrir un accès adapté aux outils de planification Agile tels que les epics, les roadmaps et les tableaux Kanban, sans sur-provisionner les [permissions](../../user/permissions.md). Ce changement vous aide à collaborer plus efficacement tout en maintenant la sécurité de vos workflows et en les alignant sur le principe du moindre privilège.

### Les administrateurs d'instance peuvent contrôler les intégrations pouvant être activées {#instance-administrators-can-control-which-integrations-can-be-enabled}

<!-- categories: Settings -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/project_integration_management.md#integration-allowlist) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)

{{< /details >}}

Les administrateurs d'instance peuvent désormais configurer une liste d'autorisation pour contrôler les intégrations pouvant être activées sur une instance GitLab. Si une liste d'autorisation vide est configurée, aucune intégration n'est autorisée sur l'instance. Après la configuration d'une liste d'autorisation, les nouvelles intégrations GitLab n'y figurent pas par défaut.

Les intégrations précédemment activées qui sont ensuite bloquées par les paramètres de la liste d'autorisation sont désactivées. Si ces intégrations sont de nouveau autorisées, elles sont réactivées avec leur configuration existante.

### Nouveau mappage des contributions utilisateur et des adhésions disponible dans le transfert direct {#new-user-contribution-and-membership-mapping-available-in-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/direct_transfer_migrations.md) \| [Epic associé](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)

{{< /details >}}

La nouvelle méthode de mappage des contributions utilisateur et des adhésions est désormais disponible lorsque vous migrez entre des instances GitLab par [transfert direct](../../user/group/import/_index.md). Cette fonctionnalité offre flexibilité et contrôle, aussi bien aux utilisateurs qui gèrent le processus d'importation qu'à ceux qui reçoivent les réaffectations de contributions. Avec la nouvelle méthode, vous pouvez :

- Réaffecter les adhésions et les contributions aux utilisateurs existants sur l'instance de destination une fois l'importation terminée. Les adhésions et contributions que vous importez sont d'abord mappées à des utilisateurs temporaires. Toutes les contributions apparaissent associées à ces utilisateurs temporaires jusqu'à ce que vous les réaffectiez sur l'instance de destination.
- Mapper les adhésions et contributions pour les utilisateurs dont les adresses e-mail diffèrent entre les instances source et destination.

Lorsque vous réaffectez une contribution à un utilisateur sur l'instance de destination, celui-ci peut accepter ou refuser la réaffectation.

Pour plus d'informations, voir [rationaliser les migrations avec le mappage des contributions utilisateur et des adhésions](https://about.gitlab.com/blog/streamline-migrations-with-user-contribution-and-membership-mapping/). Pour laisser un commentaire, ajoutez un commentaire au [ticket 502565](https://gitlab.com/gitlab-org/gitlab/-/issues/502565).

### Résolution automatique des vulnérabilités non détectées lors des analyses ultérieures {#auto-resolve-vulnerabilities-when-not-found-in-subsequent-scans}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/vulnerability_management_policy.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/5708)

{{< /details >}}

Les [outils d'analyse de sécurité](../../user/application_security/_index.md) de GitLab permettent d'identifier les vulnérabilités connues et les faiblesses potentielles dans le code de votre application. L'analyse des branches de fonctionnalités fait apparaître de nouvelles faiblesses ou vulnérabilités afin qu'elles puissent être corrigées avant la fusion. Dans le cas des vulnérabilités déjà présentes dans la branche par défaut de votre projet, leur correction dans une branche de fonctionnalité marquera la vulnérabilité comme n'étant plus détectée lors de la prochaine analyse de la branche par défaut. S'il est utile de savoir quelles vulnérabilités ne sont plus détectées, chacune doit encore être marquée manuellement comme Résolue pour être clôturée. Cette opération peut être chronophage lorsqu'il y en a beaucoup à résoudre, même en utilisant le nouveau [filtre d'activité](../../user/application_security/vulnerability_report/_index.md#activity-filter) et la [modification en masse du statut](../../user/application_security/vulnerability_report/_index.md#change-status-of-vulnerabilities).

Nous introduisons un nouveau type de politique, *Vulnerability Management policy*, destiné aux utilisateurs qui souhaitent que les vulnérabilités soient automatiquement définies sur Résolues lorsqu'elles ne sont plus détectées par l'analyse automatisée. Il vous suffit de configurer une nouvelle politique avec la nouvelle option de résolution automatique et de l'appliquer aux projets appropriés. Vous pouvez même configurer la politique pour ne résoudre automatiquement que les vulnérabilités d'une certaine gravité ou provenant de scanners de sécurité spécifiques. Une fois en place, lors de la prochaine analyse de la branche par défaut du projet, toutes les vulnérabilités existantes qui ne sont plus détectées seront marquées comme Résolues. L'action met à jour l'enregistrement de la vulnérabilité avec une note d'activité, un horodatage de l'action et le pipeline dans lequel la suppression de la vulnérabilité a été déterminée.

### Rotation des jetons d'accès personnels, de projet et de groupe dans l'interface {#rotate-personal-project-and-group-access-tokens-in-the-ui}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/personal_access_tokens.md#rotate-a-personal-access-token) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/241523)

{{< /details >}}

Vous pouvez désormais utiliser l'interface pour effectuer la rotation des jetons d'accès personnels, de projet et de groupe. Auparavant, vous deviez utiliser l'API pour effectuer cette opération.

Merci [shangsuru](https://gitlab.com/shangsuru) pour votre contribution !

### Suivre l'utilisation des composants CI/CD entre les projets {#track-cicd-component-usage-across-projects}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../api/graphql/reference/_index.md#cicatalogresourcecomponentusage) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/466575)

{{< /details >}}

Les équipes DevOps centrales ont souvent besoin de suivre l'utilisation de leurs composants CI/CD dans les pipelines pour mieux les gérer et les optimiser. Sans visibilité, il est difficile d'identifier les utilisations de composants obsolètes, de comprendre les taux d'adoption ou de gérer le cycle de vie des composants.

Pour y remédier, nous avons ajouté une nouvelle requête GraphQL qui permet aux équipes DevOps de consulter la liste des projets dans lesquels un composant est utilisé dans les pipelines de leur organisation. Cette capacité permet aux équipes DevOps d'améliorer leur productivité et de prendre de meilleures décisions en fournissant des informations essentielles.

### Petit runner hébergé sur Linux Arm disponible pour toutes les éditions {#small-hosted-runner-on-linux-arm-available-to-all-tiers}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/linux.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/501423)

{{< /details >}}

Nous sommes ravis d'introduire le petit runner hébergé sur Linux Arm pour GitLab.com, disponible pour toutes les éditions. Ce runner Arm à 2 vCPU est entièrement intégré à GitLab CI/CD et vous permet de compiler et de tester des applications nativement sur l'architecture Arm.

Nous sommes déterminés à offrir la vitesse de build CI/CD la plus rapide du secteur et nous réjouissons de voir les équipes atteindre des cycles de feedback encore plus courts et, en définitive, livrer des logiciels plus rapidement.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

En raison d'un bug, les packages Linux FIPS pour GitLab 17.6 et versions antérieures n'utilisaient pas le système Libgcrypt, mais le même Libgcrypt fourni avec les packages Linux standard.

Ce problème est résolu pour tous les packages Linux FIPS de GitLab 17.7, à l'exception d'AmazonLinux 2. La version de Libgcrypt d'AmazonLinux 2 n'est pas compatible avec les versions de GPGME et GnuPG fournies avec les packages Linux FIPS.

Les packages Linux FIPS pour AmazonLinux 2 continueront d'utiliser le même Libgcrypt fourni avec les packages Linux standard, sinon nous aurions à rétrograder GPGME et GnuPG.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Amélioration de la précision de détection dans Advanced SAST {#improved-detection-accuracy-in-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14685)

{{< /details >}}

Nous avons mis à jour Advanced SAST pour détecter les classes de vulnérabilités suivantes de manière plus précise :

- C# : injection de commandes OS et injection SQL.
- Go : traversée de chemin.
- Java : injection de code, injection CRLF dans les en-têtes ou journaux, falsification de requête intersite (CSRF), validation incorrecte de certificat, désérialisation non sécurisée, réflexion non sécurisée et injection d'entité externe XML (XXE).
- JavaScript : injection de code.

Nous avons également amélioré la détection des sources d'entrées utilisateur pour C# (ASP.NET) et Java (JSF, HttpServlet) et mis à jour les niveaux de gravité par souci de cohérence.

Pour connaître les types de vulnérabilités qu'Advanced SAST détecte dans chaque langage, voir [couverture d'Advanced SAST](../../user/application_security/sast/advanced_sast_coverage.md). Pour utiliser cette analyse inter-fichiers et inter-fonctions améliorée, [activez Advanced SAST](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast). Si vous avez déjà activé Advanced SAST, les nouvelles règles sont [activées automatiquement](../../user/application_security/sast/rules.md#how-rule-updates-are-released).

### Priorisation efficace des risques avec KEV {#efficient-risk-prioritization-with-kev}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/graphql/reference/_index.md#cveenrichmenttype) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11912)

{{< /details >}}

Dans GitLab 17.7, nous avons ajouté la prise en charge du catalogue des vulnérabilités exploitées connues (KEV). Le [catalogue KEV](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) est maintenu par la CISA et recense les CVE qui ont été exploitées dans la nature. Vous pouvez utiliser KEV pour mieux prioriser les résultats d'analyse et évaluer l'impact potentiel qu'une vulnérabilité peut avoir sur votre environnement.

Ces données sont disponibles pour les utilisateurs de l'analyse de composition via GraphQL. Des [travaux sont prévus](https://gitlab.com/gitlab-org/gitlab/-/issues/427441) pour prendre en charge l'affichage de ces données dans l'interface GitLab.

### Vue Code Flow étendue pour Advanced SAST {#expanded-code-flow-view-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow)

{{< /details >}}

La [vue code flow](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow) d'Advanced SAST est désormais disponible partout où les vulnérabilités sont affichées, notamment dans :

- [Le rapport de vulnérabilités](../../user/application_security/vulnerability_report/_index.md).
- [Le widget de sécurité de la merge request](../../user/application_security/sast/_index.md).
- [Le rapport de sécurité du pipeline](../../user/application_security/detect/security_scanning_results.md).
- [La vue des modifications de la merge request](../../user/application_security/sast/_index.md#merge-request-changes-view).

Les nouvelles vues sont activées sur GitLab.com. Sur GitLab Self-Managed, les nouvelles vues sont activées par défaut à partir de GitLab 17.7 (vue des modifications de la MR) et de GitLab 17.6 (toutes les autres vues). Pour plus de détails sur les versions prises en charge et les feature flags, voir [disponibilité de la fonctionnalité code flow](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow).

Pour en savoir plus sur Advanced SAST, consultez [le blog d'annonce](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/).

### Nouvelle commande `/help` dans GitLab Duo Chat {#new-help-command-in-gitlab-duo-chat}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/462122)

{{< /details >}}

Découvrez les puissantes fonctionnalités de GitLab Duo Chat ! Saisissez simplement `/help` dans le champ du message de chat pour explorer tout ce qu'il peut faire pour vous.

Essayez-le et découvrez comment GitLab Duo Chat peut rendre votre travail plus fluide et plus efficace.

### La définition de `environment.action: access` et de `prepare` réinitialise le minuteur `auto_stop_in` {#setting-environmentaction-access-and-prepare-resets-the-auto_stop_in-timer}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#environmentauto_stop_in) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)

{{< /details >}}

Auparavant, lors de l'utilisation des jobs `action: prepare`, `action: verify` et `action: access` conjointement avec le paramètre `auto_stop_in`, le minuteur n'était pas réinitialisé. À partir de la version 18.0, `action: prepare` et `action: access` réinitialiseront le minuteur, tandis que `action: verify` le laissera inchangé.

Pour l'instant, vous pouvez passer à la nouvelle implémentation en activant le feature flag `prevent_blocking_non_deployment_jobs`.

Plusieurs changements cassants sont destinés à différencier le comportement des valeurs `environment.action: prepare | verify | access`. Le mot-clé `environment.action: access` restera le plus proche de son comportement actuel, à l'exception de la réinitialisation du minuteur.

Pour éviter de futurs problèmes de compatibilité, vous devez revoir l'utilisation de ces mots-clés. Pour en savoir plus sur ces modifications proposées, consultez les tickets suivants :

- [Ticket 437132](https://gitlab.com/gitlab-org/gitlab/-/issues/437132)
- [Ticket 437133](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)
- [Ticket 437142](https://gitlab.com/gitlab-org/gitlab/-/issues/437142)

### Prise en charge de Kubernetes 1.31 {#kubernetes-131-support}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/501390)

{{< /details >}}

Cette release ajoute la prise en charge complète de Kubernetes version 1.31, publiée en août 2024. Si vous déployez vos applications sur Kubernetes, vous pouvez désormais mettre à niveau vos clusters connectés vers la version la plus récente et profiter de toutes ses fonctionnalités.

Pour plus d'informations, consultez notre [politique de prise en charge de Kubernetes et les autres versions de Kubernetes prises en charge](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### Définir l'espace de nommage et le chemin de ressource Flux depuis un job CI/CD {#set-namespace-and-flux-resource-path-from-cicd-job}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/500164)

{{< /details >}}

Pour utiliser le tableau de bord pour Kubernetes, vous devez sélectionner un agent pour la connexion Kubernetes depuis les paramètres d'environnement, et éventuellement configurer un espace de nommage et une ressource Flux pour suivre le statut de réconciliation. Dans GitLab 17.6, nous avons ajouté la prise en charge de la sélection d'un agent avec une configuration CI/CD. Cependant, la configuration de l'espace de nommage et de la ressource Flux nécessitait encore d'utiliser l'interface ou d'effectuer un appel d'API. Dans la version 17.7, vous pouvez configurer entièrement le tableau de bord à l'aide de la syntaxe CI/CD avec les attributs `environment.kubernetes.namespace` et `environment.kubernetes.flux_resource_path`.

### Jetons d'accès de groupe et de projet dans l'inventaire des identifiants {#group-and-project-access-tokens-in-credentials-inventory}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gold
- Offre : GitLab.com
- Liens : [Documentation](../../administration/credentials_inventory.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/498333)

{{< /details >}}

Les jetons d'accès de groupe et de projet sont désormais visibles dans l'inventaire des identifiants sur GitLab.com. Auparavant, seuls les jetons d'accès personnels et les clés SSH étaient visibles. Les types de jetons supplémentaires dans l'inventaire permettent d'obtenir une image plus complète des identifiants au sein du groupe.

### Notifications d'expiration de jetons étendues {#extended-token-expiration-notifications}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../security/tokens/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)

{{< /details >}}

Auparavant, les notifications par e-mail d'expiration de jetons n'étaient envoyées que sept jours avant l'expiration. Ces notifications sont désormais également envoyées 30 et 60 jours avant l'expiration. La fréquence accrue et la plage de dates étendue des notifications permettent aux utilisateurs d'être mieux informés des jetons susceptibles d'expirer prochainement.

### Prise en charge des emoji Unicode 15.1 🦖🍋‍🟩🐦‍🔥 {#unicode-151-emoji-support-}

<!-- categories: Markdown -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](https://gitlab-org.gitlab.io/ruby/gems/tanuki_emoji/) \| [Ticket associé](https://gitlab.com/gitlab-org/ruby/gems/tanuki_emoji/-/issues/28)

{{< /details >}}

Dans les versions précédentes de GitLab, la prise en charge des emoji était limitée à une ancienne norme Unicode, ce qui signifiait que certains emoji plus récents n'étaient pas disponibles.

GitLab 17.7 introduit la prise en charge d'Unicode 15.1, apportant les derniers ajouts d'emoji. Cela inclut de nouvelles options inédites comme le t-rex 🦖, la lime 🍋‍🟩 et le phénix 🐦‍🔥, vous permettant de vous exprimer avec les symboles les plus récents.

De plus, cette mise à jour enrichit la diversité des emoji, garantissant une meilleure représentation des cultures, des langues et des identités, et permettant à chacun de se sentir inclus lors des échanges sur la plateforme.

### Définir votre éditeur de texte préféré comme éditeur par défaut {#set-your-preferred-text-editor-as-default}

<!-- categories: Text Editors -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/preferences.md#set-the-default-text-editor) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/423104)

{{< /details >}}

Dans cette version, nous introduisons la possibilité de définir un éditeur de texte par défaut pour une expérience d'édition plus personnalisée. Grâce à ce changement, vous pouvez désormais choisir entre l'éditeur de texte enrichi, l'éditeur de texte brut, ou opter pour l'absence de valeur par défaut, offrant ainsi une flexibilité dans la façon dont vous créez et modifiez du contenu.

Cette mise à jour garantit des workflows plus fluides en alignant l'interface de l'éditeur sur les préférences individuelles ou les standards de l'équipe. Grâce à cette amélioration, GitLab continue de donner la priorité à la personnalisation et à la facilité d'utilisation pour tous les utilisateurs.

### Nouveau champ de description pour les jetons d'accès {#new-description-field-for-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)

{{< /details >}}

Lors de la création d'un jeton d'accès personnel, de projet, de groupe ou d'emprunt d'identité, vous pouvez désormais saisir facultativement une description de ce jeton. Cela permet de fournir un contexte supplémentaire sur le jeton, par exemple où et comment il est utilisé.

### Activer la protection contre les push de secrets dans vos groupes via les API {#enable-secret-push-protection-in-your-groups-with-apis}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/group_security_settings.md)

{{< /details >}}

Avec cette release, vous pouvez désormais activer la protection contre les push de secrets sur tous les projets de votre groupe via l'[API REST](../../api/group_security_settings.md) et l'[API GraphQL](../../api/graphql/reference/_index.md#mutationsetgroupsecretpushprotection). Cela vous permet d'activer efficacement la protection contre les push de secrets par groupe plutôt que projet par projet. Des événements d'audit sont enregistrés chaque fois que la protection contre les push est activée ou désactivée.

### Nouveau point de terminaison d'API pour lister les utilisateurs entreprise {#new-api-endpoint-to-list-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../api/group_enterprise_users.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438366)

{{< /details >}}

Les propriétaires de groupes peuvent désormais utiliser un point de terminaison d'API dédié pour lister les utilisateurs entreprise et les attributs associés.

### Supprimer le rôle par défaut Owner des rôles personnalisés {#remove-owner-base-role-from-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md#create-a-custom-member-role) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/474273)

{{< /details >}}

Le rôle par défaut Owner n'est plus disponible lors de la création d'un rôle personnalisé, car il n'apportait aucune valeur supplémentaire du fait que les permissions sont additives. Les rôles personnalisés existants avec le rôle par défaut Owner ne sont pas affectés par ce changement.

### Améliorations de la navigation et de l'ergonomie pour le centre de conformité {#navigation-and-usability-improvements-for-the-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : Ultimate, Premium
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_frameworks_report.md)

{{< /details >}}

Nous continuons à apporter des améliorations itératives et importantes à l'expérience utilisateur du centre de conformité, aussi bien pour les groupes que pour les projets.

Avec GitLab 17.7, nous avons livré deux améliorations clés :

- Les utilisateurs peuvent désormais filtrer par groupes dans l'onglet **Projets** du centre de conformité, offrant ainsi une option supplémentaire pour appliquer, filtrer et rechercher le projet approprié, ainsi que le cadre de conformité associé à ce projet.
- Le centre de conformité d'un projet dispose désormais d'un onglet **Cadres**, qui permet aux utilisateurs de rechercher les cadres de conformité associés à ce projet particulier.

Veuillez noter que l'ajout ou la modification de cadres se fait toujours au niveau des groupes, et non des projets.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.7)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.7)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.7)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
