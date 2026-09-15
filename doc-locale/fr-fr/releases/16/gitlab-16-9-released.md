---
stage: Release Notes
group: Monthly Release
date: 2024-02-15
title: "Notes de release de GitLab 16.9"
description: "GitLab 16.9 est disponible avec GitLab Duo Chat en version bêta maintenant accessible dans Premium"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 15 février 2024, GitLab 16.9 a été publié avec les fonctionnalités suivantes.

Nous tenons également à remercier tous nos contributeurs, dont le contributeur notable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

Ravi travaille activement avec le groupe de recherche sur les vulnérabilités de GitLab pour traiter les résultats faux-positifs élevés dans [GitLab SAST.](https://gitlab.com/gitlab-org/security-products/sast-rules)

Ravi a été nominé par [Rohan Shah](https://gitlab.com/rmsrohan), Customer Success Manager chez GitLab, qui a souligné les améliorations significatives apportées par Ravi aux [règles de détection](../../user/application_security/sast/rules.md) utilisées dans GitLab SAST. [Dinesh Bolkensteyn](https://gitlab.com/dbolkensteyn), Senior Vulnerability Researcher chez GitLab, a ajouté : « Les retours de Ravi sont parfaitement ciblés, directement exploitables et nous ont permis d'améliorer bon nombre de nos règles SAST. »

Ravi Dharmawan, alias ravidhr, travaille au GoTo Group en tant qu'architecte en sécurité de l'information. Il travaille principalement sur la revue de conception sécurisée, la revue de code source et les tests de pénétration. Ravi est certifié OSCP + eWPTXv2.

Ian est le premier MVP GitLab reconnu pour son travail [d'assistance aux utilisateurs sur le Forum GitLab.](https://forum.gitlab.com/u/iwalker/activity) [Michael Friedrich](https://gitlab.com/dnsmichi), Senior Developer Advocate chez GitLab, et [Fatima Sarah Khalid](https://gitlab.com/sugaroverflow), Developer Advocate chez GitLab, ont tous deux nominé Ian pour ses efforts continus visant à faire de notre forum un meilleur endroit pour la communauté, en répondant aux questions des utilisateurs qui configurent et utilisent GitLab.

Ian travaille chez UpWare Sp. z o.o. en tant que consultant en systèmes et sécurité, principalement sur Red Hat OpenShift et tout ce qui est lié à Linux. Il est certifié Red Hat RHCSA + RHCE et gère, maintient et assure le support de sa propre installation GitLab auto-hébergée depuis 2017. Ian est régulièrement actif sur les forums GitLab depuis plus de 3 ans, avec plus de 2 600 réponses utiles, 480 signalements de modération communautaire et 240 solutions.

Merci Ravi et Ian ! 🙌

## Fonctionnalités principales {#primary-features}

### GitLab Duo Chat en version bêta maintenant disponible dans Premium {#gitlab-duo-chat-beta-now-available-in-premium}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/gitlab_duo_chat/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11251)

{{< /details >}}

Dans la version 16.8, nous avons rendu GitLab Duo Chat disponible pour les instances auto-hébergées. Dans la version 16.9, nous rendons Chat disponible pour les clients Premium alors qu'il est encore en version bêta.

GitLab Duo Chat peut :

- Expliquer ou résumer des tickets, des epics et du code.
- Répondre à des questions spécifiques sur ces artefacts, comme « Rassemblez tous les arguments soulevés dans les commentaires concernant la solution proposée dans ce ticket. »
- Générer du code ou du contenu basé sur les informations contenues dans ces artefacts. Par exemple : « Pouvez-vous écrire de la documentation pour ce code ? »
- Vous aider à démarrer un processus. Par exemple : « Créez un fichier de configuration .GitLab-ci.yml pour tester et construire une application Ruby on Rails dans un pipeline CI/CD. »
- Répondre à toutes vos questions relatives au DevSecOps, que vous soyez débutant ou expert. Par exemple : « Comment puis-je configurer le DAST pour une API REST ? »
- Répondre aux questions de suivi afin que vous puissiez travailler de manière itérative sur tous les scénarios précédents.

GitLab Duo Chat est disponible en tant que fonctionnalité en version bêta. Il est également intégré à notre IDE Web et à l'extension GitLab Workflow pour VS Code en tant que fonctionnalités expérimentales. Dans ces IDE, vous pouvez également utiliser des [commandes de chat prédéfinies qui vous aident à effectuer les tâches standard plus rapidement](../../user/gitlab_duo_chat/examples.md), comme l'écriture de tests.

Vous pouvez nous aider à faire mûrir ces fonctionnalités en nous faisant part de vos expériences avec GitLab Duo Chat, que ce soit dans le produit ou via notre [ticket de retour d'information](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).

### Demander des modifications sur les merge requests {#request-changes-on-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/reviews/_index.md#submit-a-review)

{{< /details >}}

La dernière étape de la revue d'une merge request consiste à communiquer le résultat. Si l'approbation était sans ambiguïté, laisser des commentaires ne l'était pas. L'auteur devait lire vos commentaires, puis déterminer si ceux-ci étaient purement informatifs ou décrivaient des modifications nécessaires. Désormais, lorsque vous terminez votre revue, vous pouvez choisir parmi trois options :

- **Commentaire** : soumettre un retour général sans approuver explicitement.
- **Approuver** : soumettre un retour et approuver les modifications.
- **Demander des modifications** : soumettre un retour qui devrait être pris en compte avant la fusion.

La barre latérale affiche désormais le résultat de votre revue à côté de votre nom. Actuellement, terminer votre revue avec **Demander des modifications** ne bloque pas la fusion de la merge request, mais cela fournit un contexte supplémentaire aux autres participants de la merge request.

Vous pouvez laisser un retour sur la fonctionnalité **Demander des modifications** dans notre [ticket de retour d'information](https://gitlab.com/gitlab-org/gitlab/-/issues/438573).

### Améliorations de l'interface utilisateur des variables CI/CD {#improvements-to-the-cicd-variables-user-interface}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/variables/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)

{{< /details >}}

Dans GitLab 16.9, nous avons publié une série d'améliorations de l'expérience utilisateur des variables CI/CD. Nous avons amélioré le flux de création des variables grâce à des modifications incluant :

- [Validation améliorée lorsque les valeurs des variables ne satisfont pas aux exigences](https://gitlab.com/gitlab-org/gitlab/-/issues/365934).
- [Texte d'aide lors de la création de variables](https://gitlab.com/gitlab-org/gitlab/-/issues/410220).
- [Permettre le redimensionnement du champ de valeur dans le formulaire des variables](https://gitlab.com/gitlab-org/gitlab/-/issues/434667).

D'autres améliorations incluent un nouveau [champ de description optionnel pour les variables de groupe et de projet](https://gitlab.com/gitlab-org/gitlab/-/issues/378938) afin de faciliter la gestion des variables. Nous avons également facilité l'[ajout ou la modification de plusieurs variables](https://gitlab.com/gitlab-org/gitlab/-/issues/434666), réduisant ainsi les frictions dans le workflow de développement logiciel et permettant aux développeurs d'effectuer leur travail plus efficacement.

Votre [retour sur ces modifications](https://gitlab.com/gitlab-org/gitlab/-/issues/441177) est toujours apprécié et valorisé.

### Options étendues pour l'annulation automatique des pipelines {#expanded-options-for-auto-canceling-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#workflowauto_cancelon_new_commit) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/412473)

{{< /details >}}

Actuellement, pour utiliser la [fonctionnalité d'annulation automatique des pipelines redondants](../../ci/pipelines/settings.md#auto-cancel-redundant-pipelines), vous devez définir les jobs pouvant être annulés comme [`interruptible: true`](../../ci/yaml/_index.md#interruptible) afin de déterminer si un pipeline peut être annulé ou non. Mais cela s'applique uniquement aux jobs en cours d'exécution au moment où GitLab tente d'annuler le pipeline. Les jobs qui n'ont pas encore démarré (avec le statut « pending ») sont également considérés comme pouvant être annulés en toute sécurité, quelle que soit leur configuration `interruptible`.

Ce manque de flexibilité nuit aux utilisateurs qui souhaitent avoir plus de contrôle sur les jobs exacts pouvant être annulés par la fonctionnalité d'annulation automatique des pipelines. Pour remédier à cette limitation, nous avons le plaisir d'annoncer l'introduction des mots-clés `auto_cancel:on_new_commit` offrant un contrôle plus granulaire sur l'annulation des jobs. Si l'ancien comportement ne vous convenait pas, vous avez désormais la possibilité de configurer le pipeline pour n'annuler que les jobs explicitement définis avec `interruptible: true`, même s'ils n'ont pas encore démarré. Vous pouvez également configurer des jobs pour qu'ils ne soient jamais annulés automatiquement.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Limiter les jobs d'indexation de code simultanés pour la recherche avancée {#limit-concurrent-code-indexing-jobs-for-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../integration/advanced_search/elasticsearch.md#advanced-search-configuration) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/435402)

{{< /details >}}

En tant qu'administrateur GitLab, vous pouvez désormais définir le nombre maximum de jobs d'indexation de code Elasticsearch en arrière-plan pouvant s'exécuter simultanément. Auparavant, vous ne pouviez limiter le nombre de jobs simultanés qu'en créant des processus Sidekiq dédiés.

### Directives personnalisées pour la gestion des membres de groupes et de projets {#custom-guidelines-for-managing-group-and-project-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/appearance.md#member-guidelines) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/433093)

{{< /details >}}

Les administrateurs peuvent désormais ajouter des directives textuelles visibles par les utilisateurs disposant des autorisations de gestion des membres sur la page **Membres** d'un groupe ou d'un projet. Les administrateurs peuvent accéder à ces directives dans la section **Apparence** des paramètres de la **Admin Area**.

Les directives sont utiles pour les équipes qui utilisent des outils externes pour gérer les membres de groupes ou de projets. Par exemple, la directive peut renvoyer vers des groupes prédéfinis que les utilisateurs devraient utiliser plutôt que de gérer l'appartenance pour des membres individuels.

Merci @bufferoverflow pour cette contribution communautaire !

### Afficher les statistiques d'importation pour le transfert direct {#show-import-stats-for-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/437874)

{{< /details >}}

Les migrations terminées de groupes et projets GitLab par transfert direct ont affiché des badges (**Terminé**, **Terminé partiellement** et **Échec**) pour informer les utilisateurs du résultat général de la migration. Les utilisateurs pouvaient également accéder à une liste des éléments non importés en cliquant sur le lien **See failures**.

Cependant, pour un projet partiellement importé, il n'existait pas de moyen rapide de comprendre combien d'éléments de chaque type avaient été importés avec succès et combien ne l'avaient pas été.

Dans cette release, nous avons ajouté des statistiques de résultats d'importation pour les groupes et les projets. Pour accéder aux statistiques, sélectionnez le lien **Détails** sur la page d'historique des transferts directs.

### Activer les tickets Jira au niveau du groupe {#enable-jira-issues-at-the-group-level}

<!-- categories: Settings -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/jira/configure.md#view-jira-issues) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/325715)

{{< /details >}}

Avec cette release, vous pouvez activer les tickets Jira pour tous les projets d'un groupe GitLab. Auparavant, vous ne pouviez activer les tickets Jira que pour chaque projet GitLab individuellement.

### Prise en charge de l'API REST pour l'application GitLab for Slack {#rest-api-support-for-the-gitlab-for-slack-app}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/group_integrations.md#gitlab-for-slack-app) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/364440)

{{< /details >}}

Avec cette release, nous avons ajouté la prise en charge de l'API REST pour l'application GitLab for Slack.

Vous ne pouvez pas créer une application GitLab for Slack depuis l'API. Vous devez plutôt [installer l'application](../../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app) depuis l'interface utilisateur GitLab. Vous pouvez ensuite récupérer les paramètres d'intégration et mettre à jour ou désactiver l'application pour un projet.

### Accéder aux données d'utilisation de GitLab via l'API REST {#access-gitlab-usage-data-through-the-rest-api}

<!-- categories: Application Instrumentation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../api/usage_data.md#export-service-ping-data) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/12251)

{{< /details >}}

Les utilisateurs auto-hébergés peuvent désormais accéder facilement aux données Service Ping via une connexion API REST, facilitant l'intégration directe avec les systèmes en aval. Cela représente une amélioration significative par rapport à la méthode précédente de téléchargement de fichiers. La nouvelle approche offre aux utilisateurs auto-hébergés un moyen plus efficace et en temps réel d'effectuer des analyses personnalisées et d'obtenir des informations spécifiques à partir de leurs données d'utilisation GitLab.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### S'authentifier et signer des commits avec des certificats SSH {#authenticate-and-sign-commits-with-ssh-certificates}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Silver, Gold
- Liens : [Documentation](../../user/group/ssh_certificates.md)

{{< /details >}}

Auparavant, les options de contrôle d'accès Git sur GitLab.com reposaient sur des identifiants configurés dans le compte utilisateur. Vous pouvez désormais configurer un processus permettant l'accès Git en utilisant uniquement des certificats SSH. Vous pouvez également utiliser ces certificats pour signer des commits.

### Limiter les workspaces par utilisateur sur l'agent GitLab {#limit-workspaces-per-user-on-the-gitlab-agent}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

Dans GitLab 16.8, nous avons introduit des paramètres pour l'agent GitLab pour Kubernetes afin de limiter l'utilisation du CPU et de la mémoire par workspace.

Dans la version 16.9, vous pouvez également limiter le nombre de workspaces par utilisateur. Grâce à ce nouveau paramètre, vous avez encore plus de contrôle sur vos ressources cloud et pouvez empêcher les développeurs individuels d'augmenter les dépenses cloud.

### Permettre aux utilisateurs de nettoyer les ressources partielles des déploiements échoués {#allow-users-to-cleanup-partial-resources-from-failed-deployments}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/_index.md#run-a-pipeline-job-when-environment-is-stopped) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/435128)

{{< /details >}}

La fonctionnalité [`auto_stop_in`](../../ci/yaml/_index.md#environmentauto_stop_in) de l'environnement a été mise à jour pour exécuter le job à partir du dernier pipeline terminé, au lieu du dernier pipeline réussi. Cela évite les cas limites où le job d'arrêt automatique ne peut pas s'exécuter en raison de l'absence de pipelines réussis.

Ce comportement pourrait être considéré comme un changement de rupture dans certaines situations. Le nouveau comportement est actuellement derrière un feature flag, et deviendra le comportement par défaut dans la version 17.0\. Dans le même temps, nous allons déprécier l'ancien comportement qui sera supprimé de GitLab dans la version 18.0. Nous recommandons à tous de commencer la transition ou de configurer le feature flag immédiatement afin de minimiser les risques liés au changement de rupture lors de la première mise à niveau vers 17.x.

### Prise en charge de Kubernetes 1.29 {#kubernetes-129-support}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/435293)

{{< /details >}}

Cette release ajoute la prise en charge complète de Kubernetes version 1.29, publiée en décembre 2023. Si vous déployez vos applications sur Kubernetes, vous pouvez désormais mettre à niveau vos clusters connectés vers la version la plus récente et profiter de toutes ses fonctionnalités.

Vous pouvez en savoir plus sur notre politique de prise en charge de Kubernetes et les autres versions de Kubernetes prises en charge.

### Adresse e-mail des utilisateurs entreprise accessible via l'interface utilisateur et l'API {#enterprise-user-email-address-accessible-through-ui-and-api}

<!-- categories: User Management -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/enterprise_user/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/391453)

{{< /details >}}

Les propriétaires de groupes disposant d'[utilisateurs entreprise](../../user/enterprise_user/_index.md) peuvent désormais utiliser à la fois l'interface de gestion des utilisateurs et l'[API des membres de groupe et de projet](../../api/group_members.md) pour voir les adresses e-mail de ces utilisateurs. Auparavant, seules les adresses e-mail des utilisateurs provisionnés étaient retournées.

### Ajouter ou supprimer des comptes de service dans des groupes avec la synchronisation de groupe LDAP {#add-or-remove-service-accounts-from-groups-with-ldap-group-sync}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/group/access_and_permissions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/425947)

{{< /details >}}

Auparavant, si un groupe avait la synchronisation LDAP activée, les administrateurs n'étaient pas en mesure d'inviter ou de supprimer des utilisateurs de ce groupe. Désormais, les administrateurs peuvent utiliser l'API des membres de groupe et de projet pour inviter des comptes de service dans un groupe avec synchronisation LDAP ou les en supprimer. Les administrateurs ne peuvent toujours pas inviter des utilisateurs humains dans un groupe avec synchronisation LDAP ni les en supprimer. Cela garantit que la synchronisation de groupe LDAP est la source unique de vérité pour l'appartenance des comptes utilisateurs humains, tout en permettant la flexibilité d'utiliser des comptes de service pour ajouter des automatisations aux groupes synchronisés via LDAP.

### Événement d'audit pour la mise à jour ou la suppression d'un rôle personnalisé {#audit-event-for-updating-or-deleting-a-custom-role}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/437672)

{{< /details >}}

GitLab enregistre désormais un événement d'audit lorsqu'un rôle personnalisé est mis à jour ou supprimé. Cet événement est important pour identifier si des autorisations ont été ajoutées ou modifiées en cas d'escalade de privilèges.

### Amélioration de l'expérience utilisateur pour les sessions SAML SSO expirées {#improved-ux-for-expired-saml-sso-sessions}

<!-- categories: System Access -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/group/saml_sso/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/414475)

{{< /details >}}

Si vous appartenez à un groupe qui exige une authentification SAML SSO, mais que vous ne disposez pas d'une session valide pour ce groupe, une bannière s'affiche pour vous inviter à actualiser votre session. Auparavant, les tickets et les merge requests n'étaient pas affichés lorsqu'une session avait expiré, mais cela n'était pas clair pour l'utilisateur. Désormais, les utilisateurs savent clairement quand ils doivent se réauthentifier pour voir l'ensemble de leurs éléments de travail.

### Améliorations du rapport de conformité aux standards {#standards-adherence-report-improvements}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11053)

{{< /details >}}

Le [rapport de conformité aux standards](../../user/compliance/compliance_center/_index.md), au sein du [centre de conformité](../../user/compliance/compliance_center/_index.md), est le point de référence pour les équipes de conformité afin de surveiller leur posture de conformité.

Dans GitLab 16.5, nous avons introduit le rapport avec le Standard GitLab — un ensemble d'exigences de conformité communes que toutes les équipes de conformité devraient surveiller. Le standard vous aide à comprendre quels projets satisfont à ces exigences, lesquels ne les satisfont pas, et comment les mettre en conformité. Au fil du temps, nous introduirons davantage de standards dans les rapports.

Dans ce jalon, nous avons apporté des améliorations qui rendront les rapports plus robustes et exploitables. Celles-ci comprennent :

- Regroupement des résultats par vérification
- Filtrage par projet, vérification et standard
- Export au format CSV (livré par e-mail)
- Pagination améliorée

### Disponibilité élargie de l'éditeur de texte enrichi {#rich-text-editor-broader-availability}

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/rich_text_editor.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/7098)

{{< /details >}}

Dans GitLab 16.2, [nous avons publié](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/) l'éditeur de texte enrichi comme alternative à l'éditeur de texte brut. L'éditeur de texte enrichi offre une interface d'édition « ce que vous voyez est ce que vous obtenez » et une base extensible pour des développements supplémentaires. Jusqu'à cette release, cependant, l'éditeur de texte enrichi n'était disponible que dans les tickets, les epics et les merge requests.

Avec GitLab 16.9, l'éditeur de texte enrichi est désormais disponible dans :

- [Descriptions des exigences](https://gitlab.com/gitlab-org/gitlab/-/issues/407493)
- [Résultats de vulnérabilités](https://gitlab.com/gitlab-org/gitlab/-/issues/407491)
- [Descriptions des releases](https://gitlab.com/gitlab-org/gitlab/-/issues/407494)
- [Notes de conception](https://gitlab.com/gitlab-org/gitlab/-/issues/407505)

Grâce à un accès amélioré à l'éditeur de texte enrichi, vous pouvez collaborer plus efficacement sans expérience préalable de Markdown.

### Autoriser les modules Terraform en double {#allow-duplicate-terraform-modules}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/terraform_module_registry/_index.md#allow-duplicate-terraform-modules) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/368040)

{{< /details >}}

Vous pouvez utiliser le registre de paquets GitLab pour publier et télécharger des modules Terraform. Par défaut, vous ne pouvez pas publier le même nom de module et la même version plus d'une fois par projet.

Cependant, vous pourriez vouloir autoriser les téléchargements en double, en particulier pour les releases. Dans cette release, GitLab étend le paramètre de groupe pour le registre de paquets afin que vous puissiez autoriser ou refuser les modules en double.

### Valider les modules Terraform depuis votre groupe ou sous-groupe {#validate-terraform-modules-from-your-group-or-subgroup}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/package_registry/_index.md#view-packages) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/352041)

{{< /details >}}

Lors de l'utilisation du registre Terraform GitLab, il est important d'avoir une vue inter-projets de tous vos modules. Jusqu'à récemment, l'interface utilisateur n'était disponible qu'au niveau du projet. Si votre groupe avait une structure complexe, vous pouviez avoir des difficultés à trouver et à valider vos modules.

Depuis GitLab 16.9, vous pouvez visualiser tous les modules de votre groupe et sous-groupe dans GitLab. La visibilité accrue permet une meilleure compréhension de votre registre et réduit la probabilité de collisions de noms.

### Ligne de travail en cours sur les tableaux {#boards-work-in-progress-line}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/issue_board.md#work-in-progress-limits) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/440540)

{{< /details >}}

Vous pouvez désormais visualiser vos limites de travail en cours dans une liste de tableau. Lorsqu'une limite est dépassée, une ligne indicatrice apparaît dans la liste pour vous aider à identifier les éléments qui dépassent la limite et à gérer la liste en conséquence.

### Nouveaux événements d'étape pour l'analyse personnalisée des flux de valeur {#new-stage-events-for-custom-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/431934)

{{< /details >}}

Pour améliorer le [suivi des workflows de développement dans GitLab](https://about.gitlab.com/blog/value-stream-total-time-chart/), le Value Stream Analytics a été enrichi avec un nouvel événement d'étape : `Issue first added to iteration`. Vous pouvez utiliser cet événement pour détecter les problèmes causés par un manque d'agilité des équipes planifiant trop à l'avance, ou des difficultés d'exécution dans les équipes où les tickets sont reportés d'une itération à l'autre. Par exemple, vous pouvez désormais ajouter une étape « Planifié » qui commence avec `Issue first added to iteration` et se termine avec `Issue first assigned`.

### Améliorations de l'analyse opérationnelle des conteneurs {#improvements-to-operational-container-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/vulnerabilities.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11968)

{{< /details >}}

Nous avons apporté des améliorations en matière de reporting et de stabilité à l'analyse opérationnelle des conteneurs (OCS). Notamment, la limite de taille du rapport Trivy a été augmentée, ce qui offre une expérience plus stable aux utilisateurs. L'augmentation de la taille du rapport Trivy de 10 Mo à 100 Mo permet aux clients qui étaient limités par la taille du rapport de tirer parti d'OCS pour sécuriser les images de conteneurs dans leur cluster.

Avec cette modification d'OCS, les utilisateurs qui exécutent `gitlab-agent` en mode FIPS ne peuvent pas exécuter l'analyse opérationnelle des conteneurs. Pour plus de détails à ce sujet, consultez notre documentation et veuillez fournir vos commentaires dans le ticket [\#440849](https://gitlab.com/gitlab-org/gitlab/-/issues/440849).

### Mises à jour de l'analyseur DAST {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/12685)

{{< /details >}}

Nous avons résolu les bugs suivants durant le jalon de la release 16.9 :

- Erreurs DAST basées sur le navigateur lors de la tentative d'obtention du corps de réponse pour les ressources mises en cache lorsque le navigateur a transitionné vers une nouvelle page. [Voir le ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/435175) pour plus de détails.
- Les tâches de crawl DAST basées sur le navigateur ne s'exécutent pas en parallèle, entraînant une dégradation des performances. [Voir le ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/435325) pour plus de détails.

### Règles SAST mises à jour pour des résultats de meilleure qualité {#updated-sast-rules-for-higher-quality-results}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/rules.md#important-rule-changes) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10971)

{{< /details >}}

Nous avons mis à jour plus de 40 règles SAST GitLab par défaut pour :

- Augmenter les résultats vrais-positifs (vulnérabilités correctement identifiées) et réduire les résultats faux-négatifs (vulnérabilités incorrectement identifiées) en mettant à jour les règles de logique de détection pour C#, Go, Java, JavaScript et Python.
- Ajouter des [mappings OWASP](https://gitlab.com/gitlab-org/gitlab/-/issues/438561) pour les règles C#, Go, Java et Python.

Les modifications de règles sont incluses dans les versions mises à jour de l'[analyseur](../../user/application_security/sast/analyzers.md) GitLab SAST basé sur Semgrep. Cette mise à jour est automatiquement appliquée sur GitLab 16.0 ou version ultérieure, sauf si vous avez [épinglé les analyseurs SAST à une version spécifique](../../user/application_security/sast/_index.md). Nous travaillons sur d'autres améliorations des règles SAST dans l'epic [10907](https://gitlab.com/groups/gitlab-org/-/epics/10907).

### Résultats de sécurité plus détaillés dans VS Code {#more-detailed-security-findings-in-vs-code}

<!-- categories: Editor Extensions, API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis, Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../editor_extensions/visual_studio_code/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10996)

{{< /details >}}

Nous avons amélioré la façon dont les résultats de sécurité sont affichés dans l'[extension GitLab Workflow](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#security-findings) pour Visual Studio Code (VS Code). Vous pouvez désormais voir plus de détails sur vos résultats de sécurité qui n'étaient pas affichés auparavant, notamment :

- Descriptions complètes, avec mise en forme en texte enrichi.
- La solution à la vulnérabilité, si elle est disponible.
- Un lien vers l'emplacement où le problème se produit dans votre code source.
- Des liens vers plus d'informations sur le type de vulnérabilité découvert.

Nous avons également :

- Amélioré la façon dont l'extension affiche le statut des analyses de sécurité avant que les résultats ne soient prêts.
- Apporté d'autres améliorations en matière d'ergonomie.

### Contrôler les rôles pouvant annuler des pipelines ou des jobs {#control-which-roles-can-cancel-pipelines-or-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/410634)

{{< /details >}}

Les organisations peuvent souhaiter contrôler quels rôles utilisateur sont en mesure d'annuler un pipeline. Auparavant, toute personne pouvant exécuter un pipeline pouvait également l'annuler. Désormais, un Maintainer de projet peut mettre à jour un paramètre qui restreint l'annulation des pipelines et des jobs à des rôles spécifiques, voire empêche complètement toute annulation !

### Fleet Dashboard : carte métrique des minutes de calcul utilisées sur les runners d'instance par projet {#fleet-dashboard-compute-minutes-used-on-instance-runners-per-project-metric-card}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/runners/runner_fleet_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/421457)

{{< /details >}}

Lors de la gestion d'une flotte de runners GitLab à grande échelle, vous nous avez indiqué que savoir quels projets utilisent le plus de minutes de calcul sur les runners est essentiel. Pour vous, cette information est indispensable pour aider les équipes à optimiser les pipelines CI/CD et pour prendre les bonnes décisions en matière d'optimisation des coûts de la flotte.

Désormais, la carte métrique d'utilisation du calcul par runner et par projet, complément de la fonctionnalité d'export des minutes de calcul CI/CD au format CSV précédemment publiée, est disponible dans le Runner Fleet Dashboard. Vous pouvez voir les principaux projets qui consomment des minutes de runner d'instance, ainsi que les runners d'instance les plus utilisés dans votre environnement GitLab.

### GitLab Runner 16.9 {#gitlab-runner-169}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.9 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Rendre les nouvelles tentatives de l'API Kubernetes configurables](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37349)

#### Corrections de bugs {#bug-fixes}

- [Avertissement aléatoire : échec de la suppression de \*\*\* : répertoire non vide](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3185)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-9-stable/CHANGELOG.md) de GitLab Runner.

### Afficher le lien de la MR pour les pipelines basés sur des branches {#show-mr-link-for-branch-based-pipelines}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/_index.md#view-pipelines) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/416134)

{{< /details >}}

Si vous utilisez des pipelines de branche, vous pouvez désormais rapidement visualiser et accéder aux merge requests associées depuis la page de détails du pipeline.

## Sujets connexes {#related-topics}

- [Corrections de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.9)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.9)
- [Améliorations de l'interface](https://papercuts.gitlab.com/?milestone=16.9)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
