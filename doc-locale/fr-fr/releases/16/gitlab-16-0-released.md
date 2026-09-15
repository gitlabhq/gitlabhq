---
stage: Release Notes
group: Monthly Release
date: 2023-05-22
title: "Notes de release de GitLab 16.0"
description: "GitLab 16.0 est disponible avec le tableau de bord Value Streams désormais en disponibilité générale"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 22 mai 2023, GitLab 16.0 a été publié avec les fonctionnalités suivantes.

Nous tenons également à remercier tous nos contributeurs, dont le contributeur notable de ce mois-ci.

## Contributeur notable du mois : Jimmy Berry {#this-months-notable-contributor-jimmy-berry}

Jimmy [a amélioré le widget de sécurité des merge requests](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117594) en corrigeant la base de merge utilisée pour comparer les branches sur les pipelines terminés dans la merge request. Auparavant, le widget de sécurité des merge requests comparait l'analyse de sécurité la plus récente d'un pipeline terminé sur la branche principale du dépôt. Pour que les résultats de vulnérabilité dans le widget de sécurité des merge requests soient précis, nous devions ajuster la logique et comparer la branche de fonctionnalité à la branche principale au moment où la fonctionnalité a été créée depuis la branche principale. Sans cette modification, les utilisateurs pourraient voir des résultats trompeurs. Il s'agissait déjà d'un [ticket](https://gitlab.com/groups/gitlab-org/-/epics/10092) sur notre roadmap, et Jimmy a contribué et accéléré cette amélioration non seulement pour lui-même, mais pour tous les utilisateurs de GitLab.

Jimmy [a déclaré](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34100#note_1395183419) :

> J'ai contribué à divers projets open source, mais je n'ai jamais vécu un processus de revue aussi utile.

Merci Jimmy de nous avoir aidés à améliorer la logique pour les résultats de vulnérabilité et à améliorer les fonctionnalités de sécurité dans GitLab !

## Fonctionnalités principales {#primary-features}

### Le tableau de bord Value Streams est désormais en disponibilité générale {#value-streams-dashboard-is-now-generally-available}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/403304)

{{< /details >}}

Ce [nouveau tableau de bord](https://youtu.be/EA9Sbks27g4) fournit des insights stratégiques sur les métriques qui aident les décideurs à identifier les tendances et les modèles pour optimiser la livraison logicielle. La première itération du tableau de bord GitLab Value Streams est axée sur la capacité des équipes à améliorer continuellement les workflows de livraison logicielle en comparant le cycle de vie du flux de valeur ([value stream analytics](../../user/group/value_stream_analytics/_index.md), [DORA4](../../user/analytics/dora_metrics.md)) et les métriques de [vulnérabilités](../../user/application_security/vulnerability_report/_index.md).

Les organisations peuvent utiliser le [tableau de bord Value Streams](../../user/analytics/value_streams_dashboard.md) pour suivre et comparer ces métriques sur une période donnée, identifier rapidement les tendances à la baisse, comprendre l'exposition aux risques de sécurité, et explorer les projets ou métriques individuels pour prendre des mesures d'amélioration.

Cette vue complète, construite comme une application unique avec un magasin de données unifié, permet à toutes les parties prenantes, des cadres dirigeants aux contributeurs individuels, d'avoir une visibilité sur le cycle de vie du développement logiciel, sans avoir besoin d'acheter ou de maintenir un outil tiers.

### Augmentation de la taille des runners SaaS GitLab sur Linux {#upsizing-gitlab-saas-runners-on-linux}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/linux.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/388162)

{{< /details >}}

Vous avez demandé, nous avons écouté ! Dans notre effort pour être à la pointe des vitesses de build CI/CD, nous doublons les vCPU et la RAM pour tous les runners SaaS GitLab sur Linux, sans augmentation du [facteur de coût](../../ci/pipelines/compute_minutes.md).

Nous sommes ravis de voir les pipelines s'exécuter plus rapidement et d'améliorer la productivité.

### Runners SaaS avec GPU activé sur Linux {#gpu-enabled-saas-runners-on-linux}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Liens : [Documentation](../../ci/runners/hosted_runners/linux.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/358026)

{{< /details >}}

Nous visons à apporter les meilleures pratiques DevSecOps aux sciences des données en fournissant du matériel de calcul plus puissant dans le runner GitLab. Auparavant, les data scientists pouvaient avoir des charges de travail intensives en calcul et, par conséquent, les jobs pouvaient ne pas s'exécuter aussi rapidement dans GitLab.

Désormais, grâce aux runners SaaS avec GPU activé sur Linux, ces charges de travail peuvent être prises en charge de manière transparente via GitLab.com.

Alors pourquoi attendre ? Essayez le nouveau runner dès aujourd'hui et faites-nous part de vos impressions dans ce [ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/403008). Nous sommes impatients de recevoir vos retours !

### Runners SaaS GitLab sur macOS avec processeur Apple silicon (M1) - version bêta {#apple-silicon-m1-gitlab-saas-runners-on-macos---beta}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/macos.md#example-gitlab-ciyml-file) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/342848)

{{< /details >}}

Les équipes Mobile DevOps peuvent désormais exécuter l'intégralité de leurs workflows CI/CD sur Apple silicon (M1) avec les [runners SaaS GitLab sur macOS](../../ci/runners/hosted_runners/macos.md) pour créer, tester et déployer des applications pour l'écosystème Apple de façon transparente.

Avec des performances jusqu'à **three times** supérieures à celles des runners macOS hébergés x86-64, vous augmenterez la vélocité de votre équipe de développement dans la création et le déploiement d'applications nécessitant macOS dans un environnement de build GitLab Runner sécurisé et à la demande, intégré à GitLab CI/CD.

### Modèles de commentaires {#comment-templates}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/comment_templates.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/7565)

{{< /details >}}

Lorsque vous commentez dans des tickets, des epics ou des merge requests, il vous arrive de vous répéter et de devoir écrire le même commentaire encore et encore. Peut-être avez-vous toujours besoin de demander plus d'informations sur un rapport de bug. Peut-être appliquez-vous des labels via une action rapide dans le cadre d'un processus de triage. Ou peut-être aimez-vous simplement terminer toutes vos revues de code avec un gif amusant ou un emoji approprié. 🎉

Les modèles de commentaires vous permettent de créer des réponses enregistrées que vous pouvez appliquer dans les zones de commentaires de GitLab pour accélérer votre workflow. Pour créer un modèle de commentaire, accédez à **Paramètres utilisateur > Modèles de commentaires** et remplissez votre modèle. Une fois enregistré, sélectionnez l'icône **Insérer un modèle de commentaire** dans n'importe quelle zone de texte, et votre réponse enregistrée sera appliquée.

C'est un excellent moyen de standardiser vos réponses et de gagner du temps !

### Mettre à jour votre duplication depuis l'interface GitLab {#update-your-fork-from-the-gitlab-ui}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/forking_workflow.md#update-your-fork) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/330243)

{{< /details >}}

La gestion de votre duplication vient de devenir plus simple. Lorsque votre duplication est en retard, sélectionnez **Mettre à jour la duplication** dans l'interface GitLab pour la mettre à jour avec les modifications en amont. Lorsque votre duplication est en avance, sélectionnez **Créer une requête de fusion** pour contribuer votre modification au projet en amont. Ces deux opérations nécessitaient auparavant l'utilisation de la ligne de commande.

Consultez le nombre de commits dont votre duplication est en avance (ou en retard) sur la page principale de votre projet et dans **Dépôt > Fichiers**. Si des conflits de merge existent, l'interface fournit des instructions pour les résoudre à l'aide de Git depuis la ligne de commande.

### Mettre en miroir uniquement des branches spécifiques {#mirror-specific-branches-only}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/mirror/_index.md#mirror-specific-branches) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/1893)

{{< /details >}}

Avez-vous besoin de mettre en miroir un dépôt actif comportant de nombreuses branches, mais n'en nécessitez que quelques-unes ? Limitez le nombre de branches que vous mettez en miroir en créant une expression régulière qui correspond uniquement aux branches dont vous avez besoin.

Auparavant, les miroirs vous obligeaient à répliquer l'intégralité d'un dépôt, ou toutes les branches protégées. Cette nouvelle flexibilité peut réduire la quantité de données que vos miroirs envoient ou reçoivent, et garder les branches sensibles hors des miroirs publics.

### Nouvelle expérience Web IDE désormais en disponibilité générale {#new-web-ide-experience-now-generally-available}

<!-- categories: Web IDE -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/web_ide/_index.md)

{{< /details >}}

Depuis son introduction, nous avons itéré sur la convivialité, les performances et la stabilité du Web IDE, ce qui nous a permis de créer des fonctionnalités telles que les workspaces de développement à distance et les suggestions de code sur une base solide.

Nous avons reçu des retours extrêmement positifs sur la version bêta du Web IDE et, à partir de GitLab 16.0, nous en faisons l'éditeur de code multi-fichiers par défaut dans GitLab.

### Workspaces disponibles en version bêta pour les projets publics {#workspaces-available-in-beta-for-public-projects}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10122)

{{< /details >}}

Arrêtez de passer des heures, voire des jours, à résoudre les problèmes de votre environnement de développement local et à interpréter des erreurs d'installation de paquets incompréhensibles. Vous pouvez désormais définir un environnement de développement cohérent, stable et sécurisé dans le code et l'utiliser pour créer à la demande, le tout au sein des Workspaces.

Les Workspaces servent d'environnements de développement personnels et éphémères dans le cloud. En éliminant le besoin d'un environnement de développement local, vous pouvez vous concentrer davantage sur votre code et moins sur vos dépendances. Accélérez le processus d'intégration à un nouveau projet et soyez opérationnel en quelques minutes plutôt qu'en quelques jours.

Une fois l'agent GitLab pour Kubernetes configuré et [les dépendances installées](../../user/workspace/_index.md) dans votre cluster auto-hébergé ou la plateforme cloud de votre choix, vous pouvez définir votre environnement de développement dans un fichier `.devfile.yaml` et le stocker dans un projet public. Ensuite, vous et tout autre développeur ayant accès à l'agent pouvez créer un workspace basé sur le fichier `.devfile.yaml` et modifier directement dans le Web IDE intégré. Vous bénéficiez d'un accès terminal complet au conteneur, ce qui vous permet de travailler plus efficacement. Lorsque vous avez terminé, ou si quelque chose se passe mal, vous pouvez fermer le workspace et démarrer un workspace nouveau et vierge pour votre prochaine tâche de développement.

Cette courte vidéo vous guide à travers le cycle de vie d'un workspace dans la version bêta actuelle. Apprenez-en plus sur les workspaces dans la [documentation](../../user/workspace/_index.md) et faites-nous part de vos impressions dans le [ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/issues/410031).

### Formation à la sécurité avec SecureFlag {#security-training-with-secureflag}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerabilities/_index.md#enable-security-training-for-vulnerabilities) \| [Ticket associé](https://gitlab.com/gitlab-com/alliances/alliances/-/issues/297)

{{< /details >}}

À mesure que la sécurité se déplace vers la gauche, la remédiation des résultats de sécurité sans guidance peut s'avérer difficile. Les développeurs ont besoin de conseils concrets pour résoudre les vulnérabilités et continuer à développer des fonctionnalités. Une formation contextuelle pertinente pour la vulnérabilité spécifique détectée a été publiée dans GitLab 14.9.

Dans cette release, nous ajoutons une intégration avec SecureFlag basée sur le CWE de la vulnérabilité. La solution de formation de SecureFlag est unique en ce que les labs impliquent la remédiation de la vulnérabilité dans un environnement en direct, qui peut être transféré dans un environnement réel.

### API de rotation de jetons {#token-rotation-api}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../security/tokens/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/403042)

{{< /details >}}

Auparavant, pour faire pivoter les jetons, le propriétaire du jeton devait créer manuellement un nouveau jeton et remplacer le jeton existant.

Désormais, les propriétaires de jetons peuvent utiliser un endpoint d'API `:rotate` pour faire pivoter par programmation les jetons d'accès personnels, de groupe et de projet.

### Fonctionnalités de workflow alimentées par l'IA {#ai-powered-workflow-features}

<!-- categories: Code Suggestions, Duo Agent Platform, SAST -->

{{< details >}}

- Édition : Gold
- Liens : [Documentation](../../development/ai_features/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/10524)

{{< /details >}}

GitLab évolue vers une plateforme DevSecOps alimentée par l'IA. Au cours du mois écoulé, nous avons introduit 10 nouvelles versions expérimentales pour améliorer l'efficacité et la productivité dans diverses fonctionnalités GitLab, toutes tirant parti de l'IA.

Ces workflows alimentés par l'IA améliorent l'efficacité et réduisent les délais de cycle à chaque phase du cycle de vie du développement logiciel.

En savoir plus sur les [workflows alimentés par l'IA](https://about.gitlab.com/gitlab-duo-agent-platform/)

### Améliorations de Code Suggestions {#code-suggestions-improvements}

<!-- categories: Code Suggestions -->

{{< details >}}

- Édition : Gold, Silver, Free
- Liens : [Documentation](../../user/project/repository/code_suggestions/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/9814)

{{< /details >}}

Code Suggestions est désormais disponible sur GitLab.com pour tous les utilisateurs gratuitement pendant que la fonctionnalité est en version bêta. Les équipes peuvent améliorer leur efficacité grâce à l'IA générative qui suggère du code pendant que vous développez.

Nous avons étendu la prise en charge des langages de nos six langages initiaux pour en inclure désormais 13 : C/C++, C#, Go, Java, JavaScript, Python, PHP, Ruby, Rust, Scala, Kotlin et TypeScript.

Nous apportons des améliorations au modèle d'IA sous-jacent de Code Suggestions chaque semaine pour améliorer la qualité des suggestions. N'oubliez pas que l'IA est non déterministe, vous ne recevrez donc pas nécessairement la même suggestion d'une semaine à l'autre.

En savoir plus sur ces [améliorations et les prochaines étapes](https://about.gitlab.com/blog/code-suggestions-for-all-during-beta/).

### Error Tracking est désormais en disponibilité générale {#error-tracking-is-now-generally-available}

<!-- categories: Observability -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../operations/error_tracking.md)

{{< /details >}}

GitLab Error Tracking, qui permet aux développeurs de découvrir et d'afficher les erreurs générées par leur application, est désormais en disponibilité générale sur GitLab.com ! Le suivi des erreurs GitLab contribue à améliorer l'efficacité et la prise de conscience en exposant les informations d'erreur directement dans la même interface où le code est développé, créé, déployé et publié.

Dans cette release, nous prenons en charge à la fois le [suivi des erreurs intégré à GitLab](../../operations/error_tracking.md) et les backends [basés sur Sentry](../../operations/error_tracking.md).

### Flux de valeur personnalisés pour l'analyse des flux de valeur au niveau projet {#custom-value-streams-for-project-level-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/value_stream_analytics/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/382496)

{{< /details >}}

Pour améliorer la visibilité sur l'ensemble du flux de travail, nous ajoutons à l'analyse des flux de valeur (VSA) au niveau projet l'[étape Vue d'ensemble](../../user/group/value_stream_analytics/_index.md) et l'option de [créer des flux de valeur personnalisés](../../user/group/value_stream_analytics/_index.md).

Jusqu'à présent, ces fonctionnalités n'étaient disponibles qu'au niveau VSA de groupe.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Limite de débit pour les utilisateurs non authentifiés de l'API de liste de projets {#rate-limit-for-unauthenticated-users-of-the-projects-list-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/rate_limit_on_projects_api.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/388435)

{{< /details >}}

Les utilisateurs non authentifiés de l'API de liste de projets seront désormais soumis à des limites de débit.

Sur GitLab.com, la limite est fixée à 400 requêtes par 10 minutes par adresse IP unique.

Les utilisateurs des instances GitLab auto-hébergées ont la même limite de débit par défaut, mais les administrateurs peuvent modifier les limites de débit à leur convenance. Nous encourageons les utilisateurs qui ont besoin d'effectuer plus de 400 requêtes par 10 minutes vers l'API de liste de projets à [créer un compte GitLab](https://about.gitlab.com/pricing/).

### GitLab auto-hébergé utilise deux connexions à la base de données {#self-managed-gitlab-uses-two-database-connections}

<!-- categories: Cell -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/settings/database.html#configuring-multiple-database-connections) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9627)

{{< /details >}}

À partir de la version 16.0, les installations auto-hébergées de GitLab disposeront de deux connexions à la base de données par défaut, au lieu d'une seule. Cette modification permet aux versions auto-hébergées de GitLab de se comporter de manière similaire à GitLab.com et constitue une étape vers l'activation d'une [base de données distincte pour les fonctionnalités CI](https://gitlab.com/groups/gitlab-org/-/epics/7509) pour les versions auto-hébergées de GitLab.

Cette modification s'applique aux méthodes d'installation avec Omnibus GitLab, le chart Helm GitLab, GitLab Operator, les images Docker GitLab et l'installation à partir des sources.

### Option pour désactiver les abonnés {#option-to-disable-followers}

<!-- categories: System Access, User Profile -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/_index.md#disable-following-and-being-followed-by-other-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/325558)

{{< /details >}}

Nous avons reçu des retours d'utilisateurs souhaitant empêcher l'obtention d'abonnés non désirés sur leur profil utilisateur. Nous avons pris en compte vos préoccupations : désormais, dans les paramètres de votre profil utilisateur sous Préférences, vous pouvez désactiver le suivi.

Lorsque vous désactivez cette fonctionnalité, personne ne peut vous suivre et vous ne pouvez suivre personne. Toutes les relations de suivi et d'abonnés existantes sont supprimées, et le compteur est remis à zéro.

### Suppression différée des groupes et projets définie par défaut {#delayed-group-and-project-deletion-set-as-default}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/gitlab_com/_index.md#delayed-project-deletion) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/389557)

{{< /details >}}

Pour éviter la suppression accidentelle de projets et de groupes, à partir de GitLab 16.0, la fonctionnalité de suppression différée sera activée par défaut pour tous les clients GitLab Ultimate et Premium.

Les utilisateurs auto-hébergés ont toujours la possibilité de définir une période de délai de suppression comprise entre 1 et 90 jours, et les utilisateurs SaaS bénéficient d'une période de rétention par défaut non ajustable de 7 jours.

Les utilisateurs des groupes Ultimate et Premium peuvent toujours supprimer immédiatement un groupe ou un projet depuis les paramètres du groupe ou du projet via un processus de suppression en deux étapes.

Nous pensons que cette modification contribuera à un processus de suppression plus sûr et sera bénéfique pour prévenir les suppressions accidentelles. Nous aimerions recevoir vos retours dans le ticket [\#396996](https://gitlab.com/gitlab-org/gitlab/-/issues/396996).

### Améliorations du chart GitLab {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

- Les mises à jour vers GitLab 16.0 mettent également à jour cert-manager vers la version 1.11.x. Cette mise à jour de cert-manager inclut des changements importants que vous devez [lire avant de procéder à la mise à niveau](https://cert-manager.io/docs/release-notes/release-notes-1.10/#breaking-changes-you-must-read-this-before-you-upgrade). Ces modifications incluent un changement des noms de conteneurs qui était préférable d'effectuer lors d'une version majeure de GitLab. Pour voir les détails des fonctionnalités mises à jour, consultez les [notes de release de cert-manager 1.11](https://cert-manager.io/docs/release-notes/release-notes-1.11).
- PostgreSQL 12 n'est plus pris en charge. La version minimale requise est PostgreSQL 13, et la prise en charge de PostgreSQL 14 est ajoutée. Les nouvelles installations du chart GitLab incluent PostgreSQL 14 par défaut, et les mises à niveau doivent suivre les étapes de [mise à niveau de la version PostgreSQL fournie](https://docs.gitlab.com/charts/installation/database_upgrade/).
- Les mises à jour vers GitLab 16.0 incluent une mise à jour du sous-chart Redis vers la version 16.13.2, incluant Redis 6.2.7.
- Nous avons supprimé le chart Grafana fourni. Si vous utilisez le Grafana fourni, vous devez passer à la [nouvelle version du chart de Grafana Labs](https://artifacthub.io/packages/helm/grafana/grafana) ou à un opérateur Grafana d'un fournisseur de confiance.
- GitLab 16.0 inclut les [détails des services de registre pour webservice et Sidekiq](https://docs.gitlab.com/charts/charts/globals.html#configure-registry-settings) dans la configuration `global.registry.*` par souci de simplification, car les valeurs sont présentes dans les deux. Vous pouvez conserver l'ancien comportement avec un remplacement. Vous pouvez conserver l'ancien comportement avec un remplacement.
- La [version minimale de Helm prise en charge](https://docs.gitlab.com/charts/installation/tools.html#helm) est la 3.5.2.
- La version par défaut de GitLab Runner est désormais Ubuntu 22.04.

### Améliorations d'Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- PostgreSQL 12 n'est plus pris en charge. La version minimale requise est PostgreSQL 13. Les utilisateurs de PostgreSQL 12 fourni doivent [effectuer une mise à niveau de la base de données](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server) avant d'installer GitLab 16.0.
- Le nouveau système d'exploitation de base pour les images Docker Omnibus GitLab est Ubuntu 22.04.
- GitLab 16.0 désactive les anciens endpoints de télémétrie pour Consul, qui étaient dépréciés dans Consul 1.9. Cela nous permet de [mettre à jour Consul vers des versions plus récentes](https://developer.hashicorp.com/consul/docs/v1.12.x/agent/config/config-files#telemetry-parameters).
- GitLab 16.0 inclut des paquets pour Red Hat Enterprise Linux (RHEL) 9 et les distributions compatibles.
- GitLab 16.0 inclut [Mattermost 7.10](https://mattermost.com/) avec des [mises à jour de sécurité](https://mattermost.com/security-updates/). Une mise à niveau depuis les versions antérieures est recommandée.

### Fonctionnalités d'inscription supplémentaires disponibles pour les utilisateurs Free {#additional-registration-features-available-to-free-users}

<!-- categories: Product Analytics -->

{{< details >}}

- Édition : Gratuite
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/usage_statistics.md#registration-features-program) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10508)

{{< /details >}}

Les clients GitLab Free disposant d'une instance auto-hébergée exécutant GitLab Enterprise Edition peuvent désormais accéder à cinq fonctionnalités payantes supplémentaires dans le cadre du programme [Registration Features](../../administration/settings/usage_statistics.md#registration-features-program) :

- [Politique de complexité des mots de passe](../../administration/settings/sign_up_restrictions.md)
- [Historique des modifications de description](../../user/discussions/_index.md#view-description-change-history)
- [Configuration du tableau des tickets](../../user/project/issue_board.md#configurable-issue-boards)
- [Mode de maintenance](../../administration/maintenance_mode/_index.md)
- [Test de fuzzing guidé par la couverture](../../user/application_security/coverage_fuzzing/_index.md)

Pour accéder à ces fonctionnalités, inscrivez-vous auprès de GitLab et envoyez-nous des données d'activité via [Service Ping](../../administration/settings/usage_statistics.md#enable-registration-features).

### Importer des collaborateurs comme élément supplémentaire à importer {#import-collaborators-as-an-additional-item-to-import}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/import/github.md#select-additional-items-to-import) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)

{{< /details >}}

Dans GitLab 15.10, nous avons commencé à mapper les collaborateurs des dépôts GitHub en tant que membres de projet GitLab lors des importations de projets GitHub. Nous avons reçu des [retours](https://gitlab.com/gitlab-org/gitlab/-/issues/398154) indiquant que cela avait entraîné de la confusion et que certains collaborateurs GitHub avaient été ajoutés de manière inattendue et avaient consommé des sièges.

Dans GitLab 16.0, nous avons itéré et ajouté les collaborateurs des dépôts GitHub à la liste des [éléments supplémentaires à importer](../../user/project/import/github.md#select-additional-items-to-import). Cela donne aux utilisateurs la possibilité d'éviter d'importer ces utilisateurs et de comprendre les implications possibles de leur importation.

Cette option est sélectionnée par défaut. La laisser sélectionnée peut entraîner l'utilisation d'un siège dans le groupe ou l'espace de nommage par de nouveaux utilisateurs, ainsi que l'attribution d'autorisations [pouvant aller jusqu'à propriétaire de projet](../../user/project/import/github.md#collaborators-members). Seuls les collaborateurs directs sont importés. Les collaborateurs externes ne sont jamais importés.

### Filtrer les dépôts GitHub à importer {#filter-github-repositories-to-import}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/import/github.md#filter-repositories-list) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/385113)

{{< /details >}}

Si vous possédez ou collaborez sur de nombreux dépôts dans GitHub, vous pourriez avoir du mal à trouver ceux que vous souhaitez importer dans GitLab en utilisant l'option de filtrage actuelle.

Pour faciliter la recherche des bons dépôts, nous avons ajouté des filtres supplémentaires. Vous pouvez désormais lister des sous-ensembles des dépôts que vous pouvez importer à l'aide de trois onglets :

- **Propriétaire**, pour lister les dépôts que vous possédez.
- **Collaborator**, pour lister les dépôts sur lesquels vous collaborez.
- **GitHub organization**, pour lister les dépôts appartenant à des organisations GitHub.

Dans l'onglet **Organisation**, vous pouvez affiner davantage votre recherche et choisir une organisation spécifique pour n'afficher que les dépôts qui lui appartiennent.

### Marquer comme Terminés les éléments de la liste de tâches complétés par d'autres propriétaires de groupe ou de projet {#mark-to-do-items-completed-by-other-group-or-project-owners-done}

<!-- categories: Groups & Projects, User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/todos.md#actions-that-mark-a-to-do-item-as-done) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/374726)

{{< /details >}}

Lorsqu'un utilisateur soumet une demande d'accès à un groupe ou à un projet, la demande apparaît dans la liste de tâches du propriétaire du groupe ou du projet. Pour les groupes et les projets qui ont plusieurs propriétaires, la demande apparaît dans la liste de tâches de chaque propriétaire.

Grâce à cette nouvelle fonctionnalité, les éléments de la liste de tâches déjà complétés par un autre propriétaire sont marqués comme Terminés dans les listes de tâches des autres propriétaires.

### Opter pour une nouvelle expérience de navigation {#opt-in-to-a-new-navigation-experience}

<!-- categories: Navigation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../tutorials/left_sidebar/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9044)

{{< /details >}}

GitLab 16.0 propose une toute nouvelle expérience de navigation ! Pour commencer, accédez à votre avatar en haut à droite de l'interface et activez le bouton **New navigation**. La barre latérale gauche adopte un design nouveau et amélioré, basé sur les retours des utilisateurs reçus au cours de la dernière année.

Faites-nous part de votre expérience dans [ce ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/409005). En fonction des retours, nous activerons progressivement la nouvelle navigation pour l'ensemble de nos utilisateurs, la dernière étape étant la suppression de l'ancienne navigation.

### Limiter la durée de session pour les utilisateurs {#limit-session-length-for-users}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/profile/_index.md#session-duration) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/30819)

{{< /details >}}

Les administrateurs peuvent supprimer l'option « Se souvenir de moi » pour les utilisateurs lors de la connexion, afin que les sessions ne puissent pas être prolongées et que l'utilisateur soit contraint de se réauthentifier. Limiter la durée d'une session peut améliorer la sécurité de l'instance.

### S'authentifier avec des jetons d'accès personnels Jira {#authenticate-with-jira-personal-access-tokens}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/jira/configure.md#configure-the-integration) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/8222)

{{< /details >}}

Auparavant, vous ne pouviez authentifier l'[intégration des tickets Jira](../../integration/jira/configure.md) qu'avec un nom d'utilisateur et un mot de passe Jira.

Vous pouvez désormais utiliser un [jeton d'accès personnel Jira](https://confluence.atlassian.com/enterprise/using-personal-access-tokens-1026032365.html) pour vous authentifier si vous utilisez Jira Data Center et Jira Server avec Jira 8.14 et versions ultérieures. Un jeton d'accès personnel Jira est une alternative plus sûre à un nom d'utilisateur et un mot de passe.

### Espace réservé pour la description du ticket dans les réponses automatisées du Service Desk {#placeholder-for-issue-description-in-service-desk-automated-replies}

<!-- categories: Service Desk -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/service_desk/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/223751)

{{< /details >}}

Il est utile pour un demandeur du Service Desk de voir sa demande originale dans les réponses automatiques de remerciement par e-mail.

Dans cette release, nous ajoutons un espace réservé `%{ISSUE_DESCRIPTION}` afin que les administrateurs du Service Desk puissent inclure la demande originale dans l'e-mail de remerciement.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Mises à jour en temps réel des merge requests {#real-time-merge-request-updates}

<!-- categories: Web IDE -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/_index.md)

{{< /details >}}

Lorsque vous travaillez sur des merge requests, il est important de s'assurer que ce que vous voyez correspond aux dernières informations concernant les approbations, les pipelines ou d'autres informations pouvant affecter votre capacité à faire merger les modifications. Historiquement, cela impliquait d'actualiser la merge request ou d'attendre que les mises à jour de sondage arrivent.

Nous avons amélioré l'expérience du widget du bouton de merge et du widget d'approbation dans la merge request, afin qu'ils se mettent désormais à jour en temps réel dans la merge request. Il s'agit d'une excellente amélioration pour accélérer la livraison des modifications et renforcer la confiance lors de l'avancement d'une merge request en sachant que vous consultez les dernières informations.

Nous examinons d'autres domaines d'[améliorations en temps réel](https://gitlab.com/groups/gitlab-org/-/epics/1812) dans les merge requests, alors suivez les mises à jour.

### Fournir une raison lors du rejet en masse de vulnérabilités {#provide-a-reason-when-dismissing-vulnerabilities-in-bulk}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#change-status-of-vulnerabilities) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/408366)

{{< /details >}}

Lors de la sélection d'une ou plusieurs vulnérabilités dans le rapport de vulnérabilité, il est possible de modifier leur statut en masse.

Avec cette release, vous pouvez désormais sélectionner une raison de rejet lors du choix du statut de rejet, et ajouter un commentaire lors de la modification du statut d'une vulnérabilité."

### Ajouter et supprimer des frameworks de conformité sans utiliser d'actions en masse {#add-and-remove-compliance-frameworks-without-using-bulk-actions}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group)

{{< /details >}}

Dans GitLab 15.11, nous avons ajouté l'[ajout](../../user/compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group) et la [suppression](../../user/compliance/compliance_center/compliance_projects_report.md#remove-a-compliance-framework-from-projects-in-a-group) en masse de frameworks de conformité dans le rapport sur les frameworks de conformité.

Désormais, dans GitLab 16.0, vous pouvez également ajouter et supprimer des frameworks de conformité depuis des projets directement depuis la ligne du tableau de rapport.

Avant GitLab 16.0, vous deviez créer et modifier les frameworks dans les paramètres du groupe.

Désormais, dans GitLab 16.0, vous pouvez également créer ou modifier vos frameworks de conformité dans le rapport sur les frameworks de conformité. Cela simplifie le workflow de création de framework et réduit la nécessité de changer de contexte lors de la gestion de vos frameworks.

### Filtrer les violations de conformité par nom de branche cible {#filter-compliance-violations-by-target-branch-name}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md)

{{< /details >}}

Avant GitLab 16.0, le rapport sur les violations de conformité affichait toutes les violations sur toutes les branches.

Vous pouvez désormais filtrer les violations à l'aide du nouveau champ **Branche cible de recherche**, ce qui vous permet de vous concentrer sur les branches qui vous préoccupent le plus.

### Prise en charge des actions d'approbation basées sur les rôles pour les politiques de résultats d'analyse {#support-role-based-approval-action-for-scan-result-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/8018)

{{< /details >}}

Grâce aux actions d'approbation basées sur les rôles, vous pouvez configurer des politiques de résultats d'analyse pour exiger l'approbation des rôles pris en charge par GitLab, notamment les propriétaires, les mainteneurs et les développeurs.

Cela vous offre une flexibilité supplémentaire par rapport à l'exigence d'approbateurs individuels ou de groupes d'utilisateurs définis, facilitant l'application de politiques basées sur les rôles que vous utilisez déjà dans GitLab, à grande échelle, en particulier dans les grandes organisations.

### Introduction des tests de sécurité des applications hors bande via DAST basé sur le navigateur {#introducing-out-of-band-application-security-testing-through-browser-based-dast}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/_index.md)

{{< /details >}}

Auparavant, les analyseurs DAST de GitLab ne prenaient pas en charge les attaques par rappel lors de l'exécution de vérifications actives. Cela signifiait que les tests de sécurité des applications hors bande (OAST) devaient être configurés séparément de votre analyse DAST.

Désormais, vous pouvez exécuter des tests OAST en [étendant la configuration de l'analyseur DAST basé sur le navigateur](../../user/application_security/dast/browser/_index.md) pour activer les attaques par rappel.

Dans cette release, nous introduisons le modèle [BAS.latest.GitLab-ci.yml](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/BAS.latest.gitlab-ci.yml). Le modèle CI/CD Breach and Attack Simulation propose la configuration de job pour l'analyseur DAST basé sur le navigateur et active la mise en réseau conteneur à conteneur pour ajouter des analyses DAST étendues contre des conteneurs de service à votre pipeline CI/CD.

Nous itérons en permanence pour développer de nouvelles fonctionnalités de simulation de brèches et d'attaques. Nous serions ravis de [recueillir vos retours](https://gitlab.com/gitlab-org/gitlab/-/issues/404809) sur l'ajout des attaques par rappel au DAST basé sur le navigateur.

### Importer des paquets Maven/Gradle à l'aide de pipelines CI/CD {#import-mavengradle-packages-by-using-cicd-pipelines}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/package_registry/_index.md#to-import-packages) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/389338)

{{< /details >}}

Avez-vous envisagé de déplacer votre dépôt Maven ou Gradle vers GitLab, mais vous n'avez pas pu investir le temps nécessaire pour planifier la migration ? GitLab est fier d'annoncer le lancement MVC d'un importateur de paquets Maven/Gradle.

Vous pouvez désormais utiliser l'outil Packages Importer pour importer des paquets depuis n'importe quel registre compatible Maven/Gradle, comme Artifactory.

Pour utiliser l'outil, créez simplement un fichier `config.yml` contenant les détails des paquets que vous souhaitez importer dans GitLab. Ajoutez ensuite l'importateur à un fichier de configuration de pipeline `.gitlab-ci.yml`, et l'importateur s'occupe du reste. Il s'exécute dans le pipeline, générant dynamiquement un pipeline enfant avec des jobs qui importent tous les paquets dans votre registre de paquets GitLab.

### Télécharger des paquets depuis le registre Maven avec Scala {#download-packages-from-the-maven-registry-with-scala}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/maven_repository/_index.md#install-a-package) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/212854)

{{< /details >}}

Le registre de paquets GitLab prend désormais en charge le téléchargement des paquets Maven à l'aide de l'outil de build Scala (`sbt`). Auparavant, les utilisateurs Scala n'avaient aucun moyen de télécharger des paquets Maven depuis le registre, car l'authentification de base n'était pas prise en charge. Par conséquent, les utilisateurs Scala étaient soit bloqués dans l'utilisation du registre, soit devaient utiliser Maven (`mvn`) ou Gradle comme alternative.

En ajoutant la prise en charge de Scala, nous espérons vous aider à utiliser le registre de paquets avec vos projets à forte intensité de données.

Veuillez noter que la publication d'artefacts à l'aide de `sbt` n'est pas encore prise en charge, mais vous pouvez suivre le [ticket 408479](https://gitlab.com/gitlab-org/gitlab/-/issues/408479) si vous souhaitez ajouter la prise en charge de la publication.

### Ajouter ou résoudre des éléments de la liste de tâches sur les tâches, les objectifs et les résultats clés {#add-or-resolve-to-do-items-on-tasks-objectives-and-key-results}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/todos.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9750)

{{< /details >}}

Nous savons que la [liste de tâches](../../user/todos.md) GitLab est une fonctionnalité largement adoptée, mais elle n'était pas disponible pour les tâches, les objectifs et les résultats clés.

Dans cette release, nous introduisons la possibilité d'activer ou de désactiver un élément de la liste de tâches depuis un enregistrement d'élément de travail.

### Sous-domaines uniques pour GitLab Pages {#gitlab-pages-unique-subdomains}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9347)

{{< /details >}}

Dans les versions précédentes de GitLab, les cookies des différents sites GitLab Pages sous le même groupe principal étaient visibles pour les autres projets sous le même groupe principal en raison du format d'URL par défaut de GitLab Pages.

Désormais, vous pouvez sécuriser vos sites en attribuant un sous-domaine unique à chaque projet GitLab Pages.

### Ajouter des réactions emoji sur les tâches, les objectifs et les résultats clés {#add-emoji-reactions-on-tasks-objectives-and-key-results}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/emoji_reactions.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9987)

{{< /details >}}

Vous pouvez désormais contribuer aux tâches, aux objectifs et aux résultats clés grâce à l'ajout de réactions emoji pour les éléments de travail.

Avant cette release, vous ne pouviez ajouter des réactions que sur les tickets, les merge requests, les extraits de code et les epics.

### Modifier le type d'élément de travail depuis une action rapide {#change-work-item-type-from-quick-action}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/quick_actions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/385227)

{{< /details >}}

Grâce à cette action rapide supplémentaire, vous pouvez désormais convertir des résultats clés en objectifs.

### Choisir des couleurs personnalisées pour les labels {#pick-custom-colors-for-labels}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/labels.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/361846)

{{< /details >}}

Jusqu'à présent, vous ne pouviez spécifier qu'un nombre fixe de couleurs pour vos labels.

Cette release introduit un sélecteur de couleurs dans la gestion des labels, vous permettant de sélectionner n'importe quelle plage de couleurs pour vos labels.

### Réorganiser les enregistrements enfants pour les tâches, les objectifs et les résultats clés {#reorder-child-records-for-tasks-objectives-and-key-results}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/okrs.md#reorder-objective-and-key-result-children) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9548)

{{< /details >}}

Si vous utilisez des [tâches](../../user/tasks.md) ou des OKR, vous avez probablement souhaité plus d'une fois pouvoir réorganiser les enregistrements enfants dans le widget !

Grâce à cette amélioration, les utilisateurs pourront désormais réorganiser les enregistrements enfants dans les widgets d'éléments de travail, leur permettant d'indiquer la priorité relative ou de signaler ce qui vient ensuite.

### Nouveaux événements d'étape pour l'analyse personnalisée des flux de valeur {#new-stage-events-for-custom-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/value_stream_analytics/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/361983)

{{< /details >}}

Value Stream Analytics a été étendu avec deux nouveaux événements d'étape : première affectation d'un ticket et première affectation d'une merge request. Ces événements peuvent être utiles pour mesurer le temps nécessaire à la première affectation d'un élément à un utilisateur.

Pour mettre en œuvre cette fonctionnalité, GitLab a commencé à stocker l'historique des événements d'affectation dans GitLab 16.0. Cela signifie que les événements d'affectation de tickets et de merge requests antérieurs à GitLab 16.0 ne sont pas disponibles.

### Afficher un message lorsqu'un gel du déploiement est actif {#display-message-when-deploy-freeze-is-active}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/212460)

{{< /details >}}

GitLab affiche désormais un message sur la page Environnements lorsqu'un gel du déploiement est en vigueur. Cela permet de s'assurer que votre équipe est informée des moments où des gels se produisent et où les déploiements ne sont pas autorisés.

### Mises à jour de l'analyseur SAST {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/analyzers.md) \| [Ticket associé](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST comprend [de nombreux analyseurs de sécurité](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) que l'équipe d'analyse statique de GitLab maintient, met à jour et prend en charge activement. Nous avons publié les mises à jour suivantes au cours du jalon de release 16.0 :

- L'analyseur basé sur Semgrep inclut les [règles d'analyse gérées par GitLab](https://gitlab.com/gitlab-org/security-products/sast-rules) mises à jour. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v423) pour plus de détails. Nous avons mis à jour les règles pour :
  - Mettre à jour les mappages OWASP pour indiquer qu'ils sont basés sur le Top Ten OWASP 2017. Merci à [`@artem-fedorov`](https://gitlab.com/artem-fedorov) pour cette [contribution communautaire](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/196).
  - Gérer des cas supplémentaires dans la règle `PyYAML.load`. Merci à [`@stevep-arm`](https://gitlab.com/stevep-arm) pour cette [contribution communautaire](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/237).
  - Améliorer considérablement les descriptions et les conseils pour les règles C basées sur les révisions de l'équipe de recherche sur les vulnérabilités de GitLab.
  - Ajouter la prise en charge de [l'analyse du code Scala](https://docs.gitlab.com/#faster-easier-scala-scanning-in-sast).
- L'analyseur basé sur Flawfinder prend désormais en charge le [passage de l'indicateur `--neverignore`](../../user/application_security/sast/_index.md#security-scanner-configuration) pour ignorer les directives « ignore » dans les commentaires. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder/-/blob/master/CHANGELOG.md#v401) pour plus de détails.
- L'analyseur basé sur KICS est mis à jour vers la version KICS 1.7.0. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md#v401) pour plus de détails.
- L'analyseur basé sur MobSF prend désormais en charge plusieurs modules et projets, ce qui résout plusieurs rapports de bugs. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md#v401) pour plus de détails.

De plus, [comme annoncé précédemment](../../update/deprecations.md#secure-analyzers-major-version-update), nous avons incrémenté le numéro de version majeure de chaque analyseur dans le cadre de GitLab 16.0.

Si vous [incluez le modèle SAST géré par GitLab](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) et exécutez GitLab 16.0 ou version ultérieure, vous recevez automatiquement ces mises à jour. Pour rester sur une version spécifique d'un analyseur et empêcher les mises à jour automatiques, vous pouvez [épingler sa version](../../user/application_security/sast/_index.md).

Pour les modifications précédentes, consultez les [mises à jour du mois dernier](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates).

### Mises à jour de la détection des secrets {#secret-detection-updates}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/_index.md) \| [Ticket associé](../../user/application_security/_index.md)

{{< /details >}}

Nous publions régulièrement des mises à jour de l'analyseur de détection des secrets GitLab. Au cours du jalon GitLab 16.0, nous avons :

- Ajouté des [règles de détection gérées par GitLab](../../user/application_security/secret_detection/_index.md) pour :
  - Les jetons d'accès pour les API Meta, Oculus et Instagram.
  - Les jetons pour l'API publique Segment.
- Mis à jour le moteur d'analyse Gitleaks vers la version 8.16.3.
- [Corrigé un bug](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/merge_requests/212) qui empêchait l'analyse lorsqu'un dépôt ne contenait qu'un seul commit.
- Incrémenté la version majeure de l'analyseur à `5`, [comme annoncé précédemment](../../update/deprecations.md#secure-analyzers-major-version-update).

Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/CHANGELOG.md#v501) pour plus de détails.

Si vous [utilisez le modèle de détection des secrets géré par GitLab](../../user/application_security/secret_detection/_index.md) ([`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)) et exécutez GitLab 16.0 ou version ultérieure, vous recevez automatiquement ces mises à jour. Pour rester sur une version spécifique d'un analyseur et empêcher les mises à jour automatiques, vous pouvez [épingler sa version](../../user/application_security/secret_detection/_index.md).

Pour les modifications précédentes, consultez les [mises à jour du mois dernier](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates).

### Améliorations des performances du DAST basé sur le navigateur {#browser-based-dast-performance-improvements}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9945)

{{< /details >}}

Nous avons optimisé la façon dont l'analyseur DAST basé sur le navigateur effectue ses analyses. Ces améliorations ont considérablement réduit le temps nécessaire pour exécuter une analyse DAST avec l'analyseur basé sur le navigateur. Les améliorations suivantes ont été apportées :

- Ajout de statistiques récapitulatives dans les journaux pour aider à déterminer où le temps est passé lors d'une analyse. Cela peut être activé en incluant la variable d'environnement `DAST_BROWSER_LOG="stat:debug"`.
- Optimisation des vérifications passives en les exécutant en parallèle.
- Optimisation des vérifications passives en mettant en cache les expressions régulières utilisées lors de la correspondance de contenu dans les corps de réponse HTTP.
- Optimisation de la façon dont DAST détermine si une page a fini de se charger. Désormais, nous n'attendons pas les types de documents exclus ou les URL hors portée.
- Réduction du temps d'attente pour les pages dont le DOM se stabilise rapidement après le chargement.

Grâce à ces améliorations, nous avons constaté une réduction des temps d'analyse DAST basée sur le navigateur de 50 % à 80 %, selon la complexité et la taille de l'application analysée. Bien que cette réduction en pourcentage puisse ne pas être observée dans toutes les analyses, vos analyses DAST basées sur le navigateur devraient désormais prendre significativement moins de temps.

### Analyse Scala plus rapide et plus facile dans SAST {#faster-easier-scala-scanning-in-sast}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/362958)

{{< /details >}}

GitLab Static Application Security Testing (SAST) propose désormais une analyse basée sur Semgrep pour le code Scala. Ce travail s'appuie sur notre précédente introduction de l'analyse Java basée sur Semgrep [dans GitLab 14.10](https://about.gitlab.com/releases/2022/04/22/gitlab-14-10-released/#faster-easier-java-scanning-in-sast). Comme pour les autres langages vers lesquels nous avons [effectué la transition vers l'analyse basée sur Semgrep](../../user/application_security/sast/analyzers.md#transition-to-semgrep-based-scanning), la couverture d'analyse Scala utilise des règles de détection gérées par GitLab pour détecter divers problèmes de sécurité.

La nouvelle analyse basée sur Semgrep s'exécute beaucoup plus rapidement que l'analyseur existant basé sur SpotBugs. Elle n'a pas non plus besoin de compiler votre code avant l'analyse, ce qui la rend plus simple à utiliser.

Les équipes d'analyse statique et de recherche sur les vulnérabilités de GitLab ont collaboré pour traduire les règles au format Semgrep, en préservant la plupart des règles existantes. Nous avons également mis à jour, affiné et testé les règles lors de leur conversion.

Si vous utilisez [le modèle SAST géré par GitLab](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)), les analyseurs basés sur Semgrep et SpotBugs s'exécutent désormais tous les deux lorsque du code Scala est trouvé. Dans GitLab Ultimate, le tableau de bord de sécurité combine les résultats des deux analyseurs, vous n'aurez donc pas de rapports de vulnérabilités en double.

Dans une prochaine release, nous modifierons [le modèle SAST géré par GitLab](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) pour n'exécuter que l'analyseur basé sur Semgrep pour le code Scala. L'analyseur basé sur SpotBugs continuera d'analyser le code pour d'autres langages, notamment Groovy et Kotlin. Vous pouvez [désactiver SpotBugs en avance](https://gitlab.com/gitlab-org/gitlab/-/issues/412060) si vous préférez utiliser uniquement l'analyse basée sur Semgrep.

Si vous avez des questions, des retours ou des problèmes avec la nouvelle analyse Scala basée sur Semgrep, veuillez [soumettre un ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Bug&add_related_issue=362958&issue[title]=Feedback%20on%20SAST%20Semgrep%20Scala%20support&issue[description]=%2Flabel%20~%22group%3A%3Astatic%20analysis%22), nous serons ravis de vous aider.

### Créer un runner d'instance dans la zone d'administration en tant qu'utilisateur {#create-an-instance-runner-in-the-admin-area-as-a-user}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner/register/) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/383139/)

{{< /details >}}

Dans ce nouveau workflow, l'ajout d'un nouveau runner à une instance GitLab nécessite que les utilisateurs autorisés créent un runner dans l'interface GitLab et incluent les métadonnées de configuration essentielles. Avec cette méthode, le runner est désormais facilement traçable jusqu'à l'utilisateur, ce qui aidera les administrateurs à résoudre les problèmes de build ou à répondre aux incidents de sécurité.

### Le job de déclenchement reflète le statut du pipeline downstream lorsqu'il est annulé {#trigger-job-mirror-status-of-downstream-pipeline-when-cancelled}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#triggerstrategy) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/220794)

{{< /details >}}

Auparavant, un job de déclenchement configuré avec `strategy: depends` reflétait le statut du job du pipeline downstream. Si le pipeline downstream avait le statut `running`, le job de déclenchement était également marqué comme `running`. Malheureusement, si le job downstream ne s'était pas terminé et avait le statut `canceled`, le statut du job de déclenchement était incorrectement `failed`.

Dans cette release, nous avons mis à jour les jobs de déclenchement avec `strategy: depend` pour refléter avec précision le statut du pipeline downstream. Lorsqu'un pipeline downstream est annulé, le déclencheur affiche également l'état annulé.

Cette modification peut avoir un impact sur vos pipelines existants, notamment si vous avez des jobs qui dépendent du statut du job de déclenchement marqué comme échoué. Nous vous recommandons de vérifier vos configurations de pipeline et d'effectuer les ajustements nécessaires pour tenir compte de ce changement de comportement.

### Composants CI/CD {#cicd-components}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/components/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9945)

{{< /details >}}

Dans cette release, nous sommes ravis d'annoncer la disponibilité des composants CI/CD, en tant que fonctionnalité expérimentale. Un composant CI/CD est un bloc de construction réutilisable à usage unique qui peut être utilisé pour composer une partie de la configuration CI/CD d'un projet, voire un pipeline entier.

Combiné avec le mot-clé [`inputs`](../../ci/yaml/includes.md), un composant CI/CD peut être rendu beaucoup plus flexible. Vous pouvez configurer le composant selon vos besoins précis en saisissant des valeurs utilisables pour les noms de job, les variables, les identifiants, etc.

### Endpoint d'API REST pour créer un runner {#rest-api-endpoint-to-create-a-runner}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../api/users.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/390427)

{{< /details >}}

Les utilisateurs peuvent désormais utiliser le nouvel endpoint d'API REST `POST /user/runners` pour automatiser la création de runners associés à un utilisateur. Lorsqu'un runner est créé, un jeton d'authentification est généré. Ce nouvel endpoint prend en charge le workflow de la prochaine architecture de jetons GitLab Runner.

### Clés de cache de secours par cache dans les pipelines CI/CD {#per-cache-fallback-cache-keys-in-cicd-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/caching/_index.md#per-cache-fallback-keys) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/22213)

{{< /details >}}

L'utilisation d'un cache est un excellent moyen d'accélérer vos pipelines en réutilisant les dépendances déjà récupérées dans un job ou un pipeline précédent. Mais lorsqu'il n'y a pas encore de cache, les avantages de la mise en cache sont perdus car le job doit repartir de zéro en récupérant chaque dépendance.

Nous avons précédemment introduit un cache de secours unique à utiliser lorsqu'aucun cache n'est trouvé, que vous pouvez définir globalement. Cela était utile pour les projets qui utilisaient un cache similaire pour tous les jobs. Désormais, dans la version 16.0, nous avons amélioré cette fonctionnalité avec des clés de secours par cache. Vous pouvez définir jusqu'à 5 clés de secours pour le cache de chaque job, ce qui réduit considérablement le risque qu'un job s'exécute sans cache utile. Si vous disposez d'une grande variété de caches, vous pouvez désormais utiliser un cache de secours approprié selon vos besoins.

### Créer un runner de groupe en tant qu'utilisateur {#create-a-group-runner-as-a-user}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/383143/)

{{< /details >}}

Dans ce nouveau workflow, l'ajout d'un nouveau runner à un groupe GitLab nécessite que les utilisateurs autorisés créent un runner dans l'interface GitLab et incluent les métadonnées de configuration essentielles. Avec cette méthode, le runner est désormais facilement traçable jusqu'à l'utilisateur, ce qui aidera les administrateurs à résoudre les problèmes de build ou à répondre aux incidents de sécurité.

### Nombre maximum configurable de fichiers de configuration CI/CD inclus {#configurable-maximum-number-of-included-cicd-configuration-files}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/continuous_integration.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)

{{< /details >}}

Le mot-clé `include` vous permet de composer votre configuration CI/CD à partir de plusieurs fichiers. Par exemple, vous pouvez diviser un long fichier `.gitlab-ci.yml` en plusieurs fichiers pour améliorer la lisibilité, ou réutiliser un fichier de configuration CI/CD dans plusieurs projets.

Auparavant, une seule configuration CI/CD pouvait inclure jusqu'à 150 fichiers, mais dans GitLab 16.0, les administrateurs peuvent modifier cette limite à une valeur différente dans les paramètres de l'instance.

### Créer des runners de projet en tant qu'utilisateur {#create-project-runners-as-a-user}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/383144)

{{< /details >}}

Dans ce nouveau workflow, l'ajout d'un nouveau runner à un projet nécessite que les utilisateurs autorisés créent un runner dans l'interface GitLab et incluent les métadonnées de configuration essentielles.

Avec cette méthode, le runner est désormais facilement traçable jusqu'à l'utilisateur, ce qui aidera les administrateurs à résoudre les problèmes de build ou à répondre aux incidents de sécurité.

### Limite de débit de l'endpoint d'API `projects/:id/jobs` réduite {#rate-limit-for-the-projectsidjobs-api-endpoint-reduced}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../security/rate_limits.md#project-jobs-api-endpoint) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/382985)

{{< /details >}}

Auparavant, la `GET /api/:version/projects/:id/jobs` était soumise à une limite de débit de 2 000 requêtes authentifiées par minute.

Pour aligner cette limite avec d'autres limites de débit et améliorer l'efficacité et la fiabilité, nous avons abaissé la limite à 600 requêtes authentifiées par minute.

### GitLab Runner 16.0 {#gitlab-runner-160}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.0 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Plugin de mise à l'échelle automatique de GitLab Runner pour Google Compute Engine - version expérimentale](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29217)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-0-stable/CHANGELOG.md) de GitLab Runner

## Sujets connexes {#related-topics}

- [Corrections de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.0)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.0)
- [Améliorations de l'interface](https://papercuts.gitlab.com/?milestone=16.0)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
