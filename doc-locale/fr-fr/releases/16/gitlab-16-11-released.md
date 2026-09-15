---
stage: Release Notes
group: Monthly Release
date: 2024-04-18
title: "Notes de release de GitLab 16.11"
description: "GitLab 16.11 est disponible avec GitLab Duo Chat désormais en disponibilité générale"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 18 avril 2024, GitLab 16.11 a été publié avec les fonctionnalités suivantes.

Nous tenons également à remercier tous nos contributeurs, dont le contributeur notable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

[Ivan Shtyrliaiev](https://gitlab.com/bahek2462774) a apporté [une demi-douzaine de contributions](https://gitlab.com/groups/gitlab-org/-/merge_requests?scope=all&state=merged&author_username=bahek2462774) à GitLab depuis le début de l'année 2024. Il a été nominé par [Hannah Sutor](https://gitlab.com/hsutor), responsable principale de produit chez GitLab, qui a mis en avant sa contribution visant à [améliorer l'expérience de recherche et de filtrage de la liste des utilisateurs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144907).

« Il s'agit d'une amélioration considérable de l'expérience utilisateur qui nous permet de passer d'une liste d'onglets défilant horizontalement à une interface beaucoup plus élégante avec seulement 2 onglets et une zone de recherche », a déclaré Hannah. « Les utilisateurs peuvent désormais filtrer via la zone de recherche plutôt que de faire défiler les onglets horizontalement ! »

Ivan a été remarqué pour avoir pris en charge cette demande complexe, collaboré avec l'équipe UX de GitLab pour affiner la proposition et avoir été très réactif lors des révisions. [Adil Farrukh](https://gitlab.com/adil.farrukh), Engineering Manager chez GitLab, a soutenu la nomination, soulignant que cette fonctionnalité n'était pas triviale et qu'Ivan avait été très réactif aux retours. [Eduardo Sanz García](https://gitlab.com/eduardosanz), Sr. Frontend Engineer chez GitLab, a également soutenu la nomination et a salué la résilience d'Ivan.

« Je suis vraiment reconnaissant envers la révision d'Eduardo et l'équipe GitLab pour les efforts considérables déployés pour permettre ces contributions », a déclaré Ivan. « C'était très utile et je réalise combien de temps cela prend. »

Ivan est ingénieur logiciel frontend chez [Politico](https://www.politico.com/).

[Baptiste Lalanne](https://gitlab.com/BaptisteLalanne) a repris un ticket vieux de trois ans avec près de soixante-dix votes positifs pour contribuer à une [fonctionnalité très demandée](https://gitlab.com/gitlab-org/gitlab/-/issues/262674) qui ajoute `retry:exit codes` à la configuration CI/CD. Cette contribution offre à nos utilisateurs une flexibilité accrue dans la gestion des jobs de pipeline en échec et des jobs avec différents codes de sortie.

Baptiste a été nominé par [Dov Hershkovitch](https://gitlab.com/dhershkovitch), chef de produit chez GitLab. « Le travail assidu de Baptiste sur ce projet est allé bien au-delà de la simple implémentation », a déclaré Dov. « Cette réalisation constitue un exemple parfait de la force collaborative de notre communauté. Grâce aux efforts de Baptiste, GitLab a non seulement répondu à un besoin critique, mais a également renforcé son engagement envers l'ouverture et la transparence, enrichissant ainsi notre mentalité open-core. »

« C'est vraiment touchant et très apprécié », a déclaré Baptiste. « J'ai vraiment hâte de continuer à contribuer pendant mon temps libre, tant j'apprécie cela. »

Au cours de l'année écoulée, Baptiste a fusionné six merge requests dans GitLab et envisage ensuite de [contribuer à GitLab Runner](https://docs.gitlab.com/runner/development/). Baptiste est ingénieur logiciel chez [DataDog](https://www.datadoghq.com/).

Un grand merci à nos nouveaux MVPs, Ivan et Baptiste, ainsi qu'à tous les contributeurs de la communauté GitLab ! 🙌

## Fonctionnalités principales {#primary-features}

### GitLab Duo Chat désormais en disponibilité générale {#gitlab-duo-chat-now-generally-available}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/gitlab_duo_chat/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13516)

{{< /details >}}

GitLab Duo Chat est désormais en disponibilité générale. Dans le cadre de cette release, nous rendons également ces fonctionnalités généralement disponibles :

- L'explication de code aide les développeurs et les utilisateurs moins techniques à comprendre plus rapidement un code inconnu
- La refactorisation de code permet aux développeurs de simplifier et d'améliorer le code existant
- La génération de tests automatise les tâches répétitives et aide les équipes à détecter les bugs plus tôt

Les utilisateurs peuvent accéder à GitLab Duo Chat dans l'interface GitLab, dans le Web IDE, dans VS Code ou dans les IDE JetBrains.

En savoir plus sur cette release de GitLab Duo Chat dans cet [article de blog](https://about.gitlab.com/blog/gitlab-duo-chat-now-generally-available/).

Chat est actuellement librement accessible à tous les utilisateurs Ultimate et Premium. Les administrateurs d'instance, les propriétaires de groupe et les propriétaires de projet peuvent choisir de [restreindre l'accès et le traitement de leurs données par les fonctionnalités Duo](../../user/gitlab_duo/turn_on_off.md).

GitLab Duo Chat fait partie de [GitLab Duo Pro](https://about.gitlab.com/gitlab-duo/#pricing). Afin de faciliter la transition pour les utilisateurs de la version bêta de Chat qui n'ont pas encore acheté GitLab Duo Pro, Duo Chat restera disponible pour les clients Premium et Ultimate existants (sans le module complémentaire) pendant une courte période. Nous annoncerons ultérieurement la date à laquelle l'accès sera restreint aux abonnés Duo Pro.

N'hésitez pas à partager vos commentaires en cliquant sur le bouton de feedback dans le chat ou en créant un ticket et en mentionnant GitLab Duo Chat. Nous serions ravis de vous lire !

### GitLab Duo Chat disponible dans les IDE JetBrains {#gitlab-duo-chat-available-in-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../editor_extensions/jetbrains_ide/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/307)

{{< /details >}}

Nous sommes heureux d'annoncer la disponibilité de GitLab Duo Chat dans les IDE JetBrains.

Dans le cadre des offres IA de GitLab, Duo Chat améliore davantage l'expérience des développeurs en intégrant directement une fenêtre de chat interactive dans tout IDE JetBrains pris en charge, avec la possibilité d'expliquer le code, d'écrire des tests et de refactoriser le code existant.

Pour une liste complète des fonctionnalités, consultez notre [documentation Duo Chat](../../user/gitlab_duo_chat/_index.md).

### Portées des politiques de sécurité {#security-policy-scopes}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/scan_execution_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/5510)

{{< /details >}}

La définition de portée des politiques offre une gestion et une application granulaires des politiques. Applicable à la fois aux politiques d'approbation des merge requests (résultats d'analyse) et aux politiques d'exécution d'analyse, cette nouvelle fonctionnalité permet aux équipes de sécurité et de conformité de limiter l'application des politiques à un cadre de conformité ou à un ensemble de projets inclus/exclus dans un groupe.

Alors qu'aujourd'hui toutes les politiques gérées dans un projet de politiques de sécurité sont appliquées à tous les groupes, sous-groupes et projets liés, la définition de portée des politiques vous permettra d'affiner cette application politique par politique. Cela permet aux équipes de sécurité et de conformité de :

- Gérer plus facilement les politiques de manière centralisée dans leur organisation, tout en continuant à les appliquer de façon granulaire.
- Mieux comprendre comment les contrôles qu'elles mettent en œuvre et appliquent dans GitLab s'intègrent aux cadres de conformité qu'elles ont définis.
- Afficher et gérer les politiques liées à un cadre de conformité via le centre de conformité.
- Mieux organiser et comprendre leur posture en matière de sécurité et de conformité.

### Mieux comprendre vos utilisateurs grâce à Product Analytics {#understand-your-users-better-with-product-analytics}

<!-- categories: Product Analytics -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/productivity_analytics.md)

{{< /details >}}

Il est essentiel de comprendre comment vos utilisateurs interagissent avec votre application afin de prendre des décisions basées sur les données concernant les innovations et optimisations futures. Constatez-vous une augmentation de l'utilisation de vos URL les plus critiques pour votre activité, une baisse inhabituelle du nombre d'utilisateurs actifs mensuels, ou une augmentation du nombre de clients utilisant un appareil mobile Android ? En disposant des réponses à ces questions et en les rendant accessibles à vos équipes d'ingénierie depuis la plateforme GitLab, vos équipes peuvent rester synchronisées avec la façon dont leur travail de développement affecte les résultats des utilisateurs.

Avec la nouvelle fonctionnalité Product Analytics de GitLab, vous pouvez instrumenter vos applications, collecter des données clés sur l'utilisation et l'adoption par vos utilisateurs, puis les afficher dans GitLab. Vous pouvez visualiser les données dans des tableaux de bord, en générer des rapports et les filtrer de différentes manières pour trouver des informations sur vos utilisateurs. Votre équipe peut désormais identifier et répondre rapidement aux baisses ou pics inattendus dans l'utilisation par les clients qui signalent un problème, tout en célébrant le succès de leurs releases récentes.

Pour utiliser Product Analytics, vous aurez besoin d'un cluster Kubernetes pour installer ce [chart Helm](https://gitlab.com/gitlab-org/analytics-section/product-analytics/helm-charts) et instrumenter votre application pour lui envoyer du trafic. GitLab se connectera ensuite au cluster pour récupérer les données à des fins de visualisation.

### Désactiver les jetons d'accès personnels pour les utilisateurs Enterprise {#disable-personal-access-tokens-for-enterprise-users}

<!-- categories: User Management -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/profile/personal_access_tokens.md#disable-personal-access-tokens-for-enterprise-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)

{{< /details >}}

Les propriétaires de groupes GitLab.com peuvent désormais désactiver la création et l'utilisation de jetons d'accès personnels pour tous les utilisateurs Enterprise de leurs groupes. En raison des privilèges importants qui peuvent être associés aux jetons d'accès personnels, certains propriétaires peuvent souhaiter désactiver ces jetons pour des raisons de sécurité.

Ce contrôle granulaire offre des options pour équilibrer sécurité et accessibilité sur GitLab.com.

### Prise en charge de la saisie semi-automatique pour les liens vers les pages wiki {#autocomplete-support-for-links-to-wiki-pages}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/markdown.md#gitlab-specific-references) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/442229)

{{< /details >}}

Nous sommes ravis d'introduire la prise en charge de la saisie semi-automatique pour les liens vers les pages wiki dans GitLab 16.11 ! Avec cette nouvelle fonctionnalité, créer des liens vers des pages wiki depuis vos epics et tickets n'a jamais été aussi simple : il suffit de quelques frappes au clavier.

Fini les jours où vous deviez copier et coller les URL des pages wiki dans les commentaires des epics et tickets. Désormais, naviguez simplement vers n'importe quel groupe ou projet disposant de pages wiki, accédez à un epic ou un ticket, et utilisez le raccourci de saisie semi-automatique pour créer facilement des liens vers vos pages wiki depuis l'epic ou le ticket !

### Barre latérale pour les métadonnées sur la page de présentation du projet {#sidebar-for-metadata-on-the-project-overview-page}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/working_with_projects.md)

{{< /details >}}

Nous avons repensé la page de présentation du projet. Vous pouvez désormais trouver toutes les informations et tous les liens du projet dans une seule barre latérale plutôt que dans plusieurs zones.

### Notifications par e-mail pour les modifications effectuées via Switchboard {#email-notifications-for-changes-made-using-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/dedicated/configure_instance/users_notifications.md) \| [Ticket associé](https://about.gitlab.com/dedicated/)

{{< /details >}}

Les modifications de configuration apportées à votre instance GitLab Dedicated par les administrateurs locataires via Switchboard génèrent désormais des notifications par e-mail une fois terminées.

Tous les utilisateurs ayant accès à la consultation ou à la modification de votre tenant dans Switchboard recevront une notification pour chaque modification effectuée.

### Option pour annuler un pipeline immédiatement en cas d'échec d'un job {#option-to-cancel-a-pipeline-immediately-if-any-jobs-fails}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#workflowauto_cancelon_job_failure) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)

{{< /details >}}

Parfois, après avoir constaté l'échec d'un job, vous pouvez annuler manuellement le reste du pipeline pour économiser des ressources pendant que vous travaillez sur le problème à l'origine de l'échec. Avec GitLab 16.11, vous pouvez désormais configurer les pipelines pour qu'ils soient annulés automatiquement lorsqu'un job échoue. Pour les grands pipelines qui prennent beaucoup de temps à s'exécuter, notamment avec de nombreux jobs de longue durée s'exécutant en parallèle, cela peut être un moyen efficace de réduire l'utilisation des ressources et les coûts.

Vous pouvez même configurer un pipeline pour qu'il soit immédiatement [annulé si un pipeline downstream échoue](../../ci/pipelines/downstream_pipelines.md#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline), ce qui annule le pipeline parent et tous les autres pipelines downstream.

Un grand merci à [Marco](https://gitlab.com/zillemarco) pour sa contribution à cette fonctionnalité !

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations d'Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- Dans GitLab 17.0, la version minimale prise en charge de PostgreSQL sera la version 14. En préparation de ce changement, dans GitLab 16.11, nous avons modifié le paramètre `attempt_auto_pg_upgrade?` en `true`, ce qui tentera de mettre à niveau automatiquement la version de PostgreSQL vers la version 14\. Ce processus est identique à celui utilisé la dernière fois que nous avons relevé la version minimale prise en charge de PostgreSQL.

### Mise à jour de la fonctionnalité d'archivage de projets {#updated-project-archiving-functionality}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/working_with_projects.md#archive-a-project)

{{< /details >}}

Il est désormais plus facile d'identifier les projets archivés dans les listes de projets. À partir de la version 16.11, les projets archivés affichent un badge **Archivées** dans l'onglet **Archivées** de la présentation du groupe. Ce badge fait également partie du titre du projet sur la page de présentation du projet.

Un message d'alerte précise que les projets archivés sont en lecture seule. Ce message est visible sur toutes les pages du projet afin que ce contexte ne soit pas perdu, même lorsque vous travaillez sur des sous-pages du projet archivé.

De plus, lors de la suppression d'un groupe, la fenêtre de confirmation liste désormais le nombre de projets archivés afin d'éviter les suppressions accidentelles.

### En-têtes de webhook personnalisés {#custom-webhook-headers}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhooks.md#custom-headers) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/17290)

{{< /details >}}

Auparavant, les webhooks GitLab ne prenaient pas en charge les en-têtes personnalisés. Cela signifiait que vous ne pouviez pas les utiliser avec des systèmes acceptant les jetons d'authentification provenant d'en-têtes avec des noms spécifiques.

Avec cette release, vous pouvez ajouter jusqu'à 20 en-têtes personnalisés lors de la création ou de la modification d'un webhook. Vous pouvez utiliser ces en-têtes personnalisés pour l'authentification auprès de services externes.

Grâce à cette fonctionnalité et au [modèle de webhook personnalisé](../../user/project/integrations/webhooks.md#custom-webhook-template) introduit dans GitLab 16.10, vous pouvez désormais concevoir entièrement des webhooks personnalisés. Vous pouvez configurer vos webhooks pour :

- Publier des charges utiles personnalisées.
- Ajouter les en-têtes d'authentification requis.

Comme les jetons secrets et les variables d'URL, les en-têtes personnalisés sont réinitialisés lors du changement de l'URL cible.

Merci à [Niklas](https://gitlab.com/Taucher2003) pour [cette contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146702) !

### Tester les hooks de projet avec l'API REST {#test-project-hooks-with-the-rest-api}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/projects.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/25329)

{{< /details >}}

Auparavant, vous pouviez tester les hooks de projet uniquement dans l'interface GitLab. Avec cette release, vous pouvez désormais déclencher des hooks de test pour des projets spécifiés en utilisant l'API REST.

Merci à [Phawin](https://gitlab.com/lifez) pour [cette contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147656) !

### Application GitLab pour Slack configurable pour les groupes et les instances {#gitlab-for-slack-app-configurable-for-groups-and-instances}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/gitlab_slack_application.md#from-the-project-or-group-settings) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/391526)

{{< /details >}}

Auparavant, vous pouviez configurer l'application GitLab pour Slack pour un seul projet à la fois. Avec cette release, il est désormais possible de configurer l'intégration pour des groupes ou des instances et d'apporter des modifications à de nombreux projets à la fois.

Cette amélioration rapproche l'application GitLab pour Slack de la parité de fonctionnalités avec la [intégration des notifications Slack](../../user/project/integrations/slack.md) dépréciée.

### Limite configurable des jobs d'importation {#configurable-import-jobs-limit}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/import_and_export_settings.md#maximum-number-of-simultaneous-import-jobs) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/439286)

{{< /details >}}

Jusqu'à présent, le nombre maximum de jobs d'importation pour :

- L'importateur GitHub était de 1000.
- Les importateurs Bitbucket Cloud et Bitbucket Server étaient de 100.

Ces limites étaient codées en dur et ne pouvaient pas être modifiées. Ces limites pouvaient ralentir les importations, car elles pouvaient être insuffisantes pour permettre aux jobs d'importation d'être traités au même rythme qu'ils étaient mis en file d'attente.

Dans cette release, nous avons déplacé les limites codées en dur vers les paramètres de l'application. Bien que nous n'augmentions pas ces limites sur GitLab.com, les administrateurs des instances GitLab auto-hébergées peuvent désormais configurer le nombre de jobs d'importation selon leurs besoins.

### Explorez vos données Product Analytics avec GitLab Duo {#explore-your-product-analytics-data-with-gitlab-duo}

<!-- categories: Product Analytics -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/productivity_analytics.md)

{{< /details >}}

[Product Analytics est désormais en disponibilité générale](https://docs.gitlab.com/#understand-your-users-better-with-product-analytics), et cette release inclut un [concepteur de visualisation personnalisé](../../user/analytics/analytics_dashboards.md). Vous pouvez l'utiliser pour explorer les données d'événements de votre application et créer des tableaux de bord pour mieux comprendre les habitudes d'utilisation et d'adoption de vos clients.

Dans le concepteur de visualisation, vous pouvez désormais demander à GitLab Duo de créer des visualisations en saisissant des requêtes en texte libre, par exemple « Afficher le nombre d'utilisateurs actifs mensuels en 2024 » ou « Lister les principales URL de cette semaine. »

GitLab Duo dans Product Analytics est disponible en tant que fonctionnalité expérimentale.

Vous pouvez nous aider à faire mûrir cette fonctionnalité en nous faisant part de vos retours sur votre expérience avec GitLab Duo dans le concepteur de visualisation personnalisé dans ce [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/455363).

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Modèles de commentaires de groupe {#group-comment-templates}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/comment_templates.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/440817)

{{< /details >}}

À l'échelle d'une organisation, il peut être utile de disposer de la même réponse modèle dans les tickets, les epics ou les merge requests. Ces réponses peuvent inclure des questions standard auxquelles il faut répondre, des réponses aux problèmes courants, ou encore une structure pour les commentaires de révision des merge requests.

Les modèles de commentaires de groupe vous permettent de créer des réponses enregistrées que vous pouvez appliquer dans les zones de commentaires de GitLab pour accélérer votre workflow. Ce nouvel ajout aux modèles de commentaires permet aux organisations de créer et de gérer des modèles de manière centralisée, afin que tous leurs utilisateurs bénéficient des mêmes modèles.

Pour créer un modèle de commentaire, accédez à n'importe quelle zone de commentaire sur GitLab et sélectionnez **Insérer un modèle de commentaire > Manage group comment templates**. Une fois le modèle de commentaire créé, il est disponible pour tous les membres du groupe. Sélectionnez l'icône **Insérer un modèle de commentaire** lors de la rédaction d'un commentaire, et votre réponse enregistrée sera appliquée.

Nous sommes vraiment enthousiastes à propos de cette nouvelle itération des modèles de commentaires et nous ajouterons également prochainement des [modèles de commentaires au niveau du projet](https://gitlab.com/gitlab-org/gitlab/-/issues/440818). Si vous avez des commentaires, veuillez les laisser dans le [ticket 45120](https://gitlab.com/gitlab-org/gitlab/-/issues/451520).

### Mise à niveau de l'étape de build d'Auto DevOps {#build-step-of-auto-devops-upgraded}

<!-- categories: Auto DevOps -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../topics/autodevops/troubleshooting.md#builder-sunset-error) \| [Ticket associé](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image/-/issues/73)

{{< /details >}}

L'image `heroku/buildpacks:20` utilisée par le composant Auto Build d'Auto DevOps ayant été dépréciée en amont, nous passons à l'image `heroku/builder:20`.

Cette modification avec rupture de compatibilité survient en dehors d'une release majeure de GitLab pour s'adapter à une modification avec rupture de compatibilité en amont. La mise à niveau est peu susceptible de perturber vos pipelines. En guise de solution temporaire, vous pouvez également configurer manuellement l'image `heroku/builder:20` et [ignorer les erreurs de fin de vie du builder](../../topics/autodevops/troubleshooting.md#skipping-errors).

De plus, nous prévoyons une autre mise à niveau majeure de `heroku/builder:20` vers `heroku/builder:22` dans GitLab 17.0.

### Améliorations de la recherche et du filtrage de la liste des utilisateurs {#users-list-search-and-filter-improvements}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/admin_area.md#administering-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)

{{< /details >}}

La page des utilisateurs de la zone d'administration a été améliorée.

Auparavant, les onglets s'étendaient horizontalement en haut de la liste des utilisateurs, ce qui rendait difficile la navigation vers le filtre souhaité.

Désormais, les filtres ont été intégrés dans la zone de recherche, ce qui facilite grandement la recherche et le filtrage des utilisateurs.

Merci à [Ivan Shtyrliaiev](https://www.linkedin.com/in/bahek2462774/) pour votre contribution !

### Notifications webhook pour les jetons d'accès de groupe et de projet arrivant à expiration {#webhook-notifications-for-expiring-group-and-project-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhook_events.md#project-and-group-access-token-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/426147)

{{< /details >}}

Les événements webhook pour les jetons d'accès de projet et de groupe sont désormais disponibles.

Auparavant, l'e-mail était le seul moyen de recevoir des notifications concernant les jetons arrivant à expiration. Un événement webhook, s'il est déclenché, le sera sept jours avant l'expiration d'un jeton d'accès.

### Afficher les politiques de sécurité liées dans les cadres de conformité {#display-linked-security-policies-in-compliance-frameworks}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_frameworks/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11480)

{{< /details >}}

Alors que le centre de conformité devient le poste de commandement des responsables de la conformité, vous pouvez désormais gérer les cadres de conformité et obtenir une visibilité sur les contrôles créés via des politiques de sécurité et liés à un cadre de conformité.

Appliquez l'exécution d'analyseurs de sécurité dans les projets concernés par votre conformité, imposez l'approbation à deux personnes ou activez les workflows de gestion des vulnérabilités via ces contrôles étendus, puis regroupez-les dans un cadre de conformité, en vous assurant que les projets pertinents au sein du cadre sont correctement contrôlés.

### Renouveler le secret d'application via l'API {#renew-application-secret-with-api}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../api/applications.md#renew-an-application-secret) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/422420)

{{< /details >}}

Vous pouvez désormais utiliser l'API Applications pour renouveler les secrets d'application. Auparavant, vous deviez utiliser l'interface pour effectuer cette opération. Vous pouvez maintenant utiliser l'API pour faire pivoter les secrets par programmation.

Merci à [Phawin](https://gitlab.com/lifez) pour votre contribution !

### Étendre le commentaire du bot de politique avec des données de violation {#extend-policy-bot-comment-with-violation-data}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/433403)

{{< /details >}}

Le bot de politique de sécurité fournit aux utilisateurs un contexte pour comprendre quand les politiques sont appliquées à leur projet, quand l'évaluation est terminée et s'il existe des violations bloquant une merge request, avec des conseils pour les résoudre. Nous avons désormais étendu la prise en charge dans le commentaire du bot pour fournir des informations supplémentaires sur les raisons pour lesquelles une merge request peut être bloquée par une politique, avec des retours plus granulaires sur la façon de résoudre le problème. Les détails fournis par le commentaire incluent :

- Les résultats de sécurité qui bloquent spécifiquement la merge request
- Les licences hors politique
- Les erreurs de politique pouvant entraîner un comportement par défaut de type « fail closed » et bloquant
- Les détails concernant les pipelines pris en compte dans l'évaluation pour les résultats de sécurité

Grâce à ces informations supplémentaires, vous pouvez désormais comprendre plus rapidement l'état de votre merge request et résoudre vous-même les problèmes éventuels.

### S'authentifier auprès de Google Cloud avec la fédération d'identité de charge de travail {#authenticate-to-google-cloud-with-workload-identity-federation}

<!-- categories: System Access -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../integration/google_cloud_iam.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/12758)

{{< /details >}}

La fédération d'identité de charge de travail vous permet de connecter en toute sécurité des charges de travail entre GitLab et Google Cloud sans utiliser de clés de compte de service. Cela améliore la sécurité, car les clés peuvent potentiellement être des identifiants de longue durée qui exposent un vecteur d'attaque. Les clés impliquent également une charge de gestion pour la création, la sécurisation et la rotation.

La fédération d'identité de charge de travail vous permet de mapper les rôles IAM entre GitLab et Google Cloud.

Cette fonctionnalité est en version bêta et est actuellement disponible uniquement sur GitLab.com.

### Problème avec les politiques de sécurité en double résolu {#issue-with-duplicate-security-policies-resolved}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/416903)

{{< /details >}}

Dans GitLab 16.9 et versions antérieures, il était possible pour un projet d'hériter des politiques de sécurité d'un groupe parent ou d'un sous-groupe et de se lier au même projet de politiques de sécurité. Il en résultait une duplication des politiques dans la liste des politiques.

Ce problème a été résolu et il n'est plus possible de se lier à un projet de politiques de sécurité dont les politiques sont déjà héritées.

### Plus d'options de nom d'utilisateur {#more-username-options}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/_index.md#change-your-username) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/429283)

{{< /details >}}

Les noms d'utilisateur ne peuvent contenir que des lettres non accentuées, des chiffres, des tirets bas (`_`), des tirets (`-`) et des points (`.`). Les noms d'utilisateur ne doivent pas commencer par un tiret (`-`), ni se terminer par un point (`.`), `.git` ou `.atom`.

La validation des noms d'utilisateur indique désormais ces critères de manière plus précise. Cette validation améliorée vous permet d'avoir une vision plus claire de vos options lors du choix de votre nom d'utilisateur.

Merci à [Justin Zeng](https://www.linkedin.com/in/jzeng88/) pour votre contribution !

### Amélioration de la visibilité de GitLab Pages dans la barre latérale {#improved-gitlab-pages-visibility-in-sidebar}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/18027)

{{< /details >}}

Dans les releases précédentes, pour les projets disposant d'un site GitLab Pages, il était difficile de trouver l'URL du site.

À partir de GitLab 16.11, la barre latérale droite contient un lien de raccourci vers le site, vous permettant de trouver l'URL sans avoir à consulter la documentation.

### Connecter Google Artifact Registry à votre projet GitLab {#connect-google-artifact-registry-to-your-gitlab-project}

<!-- categories: Container Registry -->

{{< details >}}

- Édition : Free, Silver, Gold
- Liens : [Documentation](../../user/project/integrations/google_artifact_management.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/12365)

{{< /details >}}

Vous utilisez le registre de conteneurs GitLab pour afficher, pousser et récupérer des images Docker et OCI aux côtés de votre code source et de vos pipelines. Pour de nombreux clients GitLab, cela fonctionne très bien pour les images de conteneurs lors des phases `test` et `build`. Cependant, il est courant que les organisations publient leurs images de production auprès d'un fournisseur cloud, comme Google.

Auparavant, pour pousser des images de GitLab vers Google Artifact Registry, vous deviez créer et maintenir des scripts personnalisés pour vous connecter et déployer vers Artifact Registry. Cette approche était inefficace et sujette aux erreurs. De plus, il n'existait aucun moyen simple d'obtenir une vue globale de toutes vos images de conteneurs.

Désormais, vous pouvez tirer parti de la nouvelle fonctionnalité Google Artifact Management pour connecter facilement votre projet GitLab à un dépôt Artifact Registry. Vous pouvez ensuite utiliser des pipelines CI/CD GitLab pour publier des images dans Artifact Registry. Vous pouvez également afficher les images publiées dans Artifact Registry dans GitLab en accédant à **Déployer > Registre d'artefacts Google**. Pour afficher les détails d'une image, sélectionnez simplement une image.

Cette fonctionnalité est en version bêta et est actuellement disponible uniquement sur GitLab.com.

### Distinguer visuellement les epics à l'aide de couleurs {#visually-distinguish-epics-using-colors}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/epics/manage_epics.md#epic-color) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9033)

{{< /details >}}

Pour améliorer davantage la capacité à utiliser les fonctionnalités de gestion de portefeuille dans toute l'organisation, vous pouvez désormais distinguer les epics à l'aide de couleurs sur les [roadmaps](../../user/group/roadmap/_index.md) et les [tableaux d'epics](../../user/group/epics/epic_boards.md).

Distinguez rapidement la propriété du groupe, l'étape dans un cycle de vie, le développement vers la maturité ou un certain nombre d'autres catégorisations grâce à cette fonctionnalité légère mais polyvalente.

### Les événements de flux de valeur peuvent désormais être calculés de manière cumulative {#value-stream-events-can-now-be-calculated-cumulatively}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/value_stream_analytics/_index.md#cumulative-label-event-duration) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/12088)

{{< /details >}}

Nous avons introduit une méthode plus robuste pour calculer les durées entre les événements de label. Ce changement prend en compte les scénarios où des événements se produisent plusieurs fois, comme les changements de label dans les merge requests qui alternent entre les états de développement et de révision. Auparavant, la durée était calculée comme le temps total écoulé entre le premier et le dernier événement de label.

Désormais, la durée est calculée de manière cumulative, ce qui signifie qu'elle représente correctement uniquement le temps pendant lequel un ticket ou une merge request avait un label donné.

### Prise en charge du graphe de dépendances pour les SBOM d'analyse des dépendances {#dependency-graph-support-for-dependency-scanning-sboms}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md) \| [Epic associé](https://gitlab.com/gitlab-org/gitlab/-/issues/366168)

{{< /details >}}

Les utilisateurs peuvent accéder aux informations du graphe de dépendances dans les SBOM CycloneDX générés dans le cadre de leur rapport d'analyse des dépendances. Les informations du graphe de dépendances sont disponibles pour les gestionnaires de packages suivants :

- NuGet
- Yarn 1.x
- sbt
- Conan

### Prise en charge de l'analyse des dépendances pour Yarn v4 {#dependency-scanning-support-for-yarn-v4}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) \| [Epic associé](https://gitlab.com/gitlab-org/gitlab/-/issues/431752)

{{< /details >}}

L'analyse des dépendances prend en charge Yarn v4. Cette amélioration permet à notre analyseur de parser les fichiers de verrouillage Yarn v4.

### Mises à jour des performances de l'analyseur DAST {#dast-analyzer-performance-updates}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/12194)

{{< /details >}}

Au cours du jalon de release 16.11, nous avons réalisé les améliorations DAST suivantes :

- Raccourcissement des chemins de navigation pour améliorer les performances du crawler, ce qui a réduit le temps d'analyse de 20 % selon notre test de référence. [Voir le ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/430815) pour plus de détails.
- Optimisation du reporting DAST pour réduire l'utilisation de la mémoire, ce qui a réduit les pics de mémoire du runner lors des analyses DAST. [Voir le ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/444180) pour plus de détails.

### Automatiser la création de runners Google Compute Engine depuis GitLab - Version bêta publique {#automate-the-creation-of-google-compute-engine-runners-from-gitlab---public-beta}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/provision_runners_google_cloud.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13494)

{{< /details >}}

Auparavant, la création de runners GitLab dans Google Compute Engine nécessitait plusieurs changements de contexte entre GitLab et Google Cloud.

Désormais, vous pouvez facilement provisionner des runners GitLab dans Google Compute Engine à l'aide d'un modèle Terraform du GitLab Runner Infrastructure Toolkit et de GitLab pour déployer un runner GitLab et provisionner l'infrastructure Google Cloud, sans avoir à passer d'un système à un autre.

### Améliorer la nouvelle tentative automatique pour les jobs CI en échec avec des codes de sortie spécifiques {#improve-automatic-retry-for-failed-ci-jobs-with-specific-exit-codes}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#retry) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/262674)

{{< /details >}}

Auparavant, vous pouviez utiliser `retry:when` en plus de `retry:max` pour configurer le nombre de fois qu'un job est réessayé lorsque des échecs spécifiques se produisent, comme lorsqu'un script échoue.

Avec cette release, vous pouvez désormais utiliser [`retry:exit_codes`](../../ci/yaml/_index.md#retryexit_codes) pour configurer les nouvelles tentatives automatiques des jobs en échec en fonction de codes de sortie de script spécifiques. Vous pouvez utiliser `retry:exit_codes` avec `retry:when` et `retry:max` pour affiner le comportement de votre pipeline selon vos besoins spécifiques et améliorer l'exécution de votre pipeline.

Merci à [Baptiste Lalanne](https://gitlab.com/BaptisteLalanne) pour cette contribution communautaire !

### GitLab Runner 16.11 {#gitlab-runner-1611}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.11 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Corrections de bugs {#bug-fixes}

- [Crash : erreur fatale : lecture et écriture simultanées sur une map](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/31077)
- [Le feature flag FF_KUBERNETES_HONOR_ENTRYPOINT ne fonctionne pas](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37243)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-11-stable/CHANGELOG.md) de GitLab Runner.

### Prise en charge étendue des secrets HashiCorp Vault, incluant Artifactory et AWS {#expanded-hashicorp-vault-secrets-support-including-artifactory-and-aws}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/secrets/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)

{{< /details >}}

L'intégration GitLab avec HashiCorp Vault a été étendue pour prendre en charge davantage de types de secrets. Vous pouvez désormais sélectionner un type de moteur de secrets `generic`, introduit dans GitLab Runner 16.11. Ce moteur générique prend en charge le [plugin Artifactory Secrets](https://jfrog.com/help/r/jfrog-integrations-documentation/hashicorp-vault-artifactory-secrets-plugin) et le [moteur de secrets AWS](https://developer.hashicorp.com/vault/docs/secrets/aws) de HashiCorp Vault. Utilisez cette option pour récupérer en toute sécurité les secrets dont vous avez besoin et les utiliser dans vos pipelines CI/CD GitLab !

Un grand merci à [Ivo Ivanov](https://gitlab.com/urbanwax) pour cette excellente contribution !

### Contrôler qui peut télécharger les artefacts de job {#control-who-can-download-job-artifacts}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#artifactsaccess) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/428677)

{{< /details >}}

Par défaut, tous les artefacts générés par les jobs CI/CD dans un pipeline public sont disponibles en téléchargement pour tous les utilisateurs ayant accès au pipeline. Cependant, il existe des cas où les artefacts ne doivent jamais être téléchargés, ou uniquement être accessibles en téléchargement par les membres de l'équipe disposant d'un niveau d'accès plus élevé.

Ainsi, dans cette release, nous avons ajouté le mot-clé `artifacts:access`. Désormais, les utilisateurs peuvent contrôler si les artefacts peuvent être téléchargés par tous les utilisateurs ayant accès au pipeline, uniquement par les utilisateurs disposant du rôle Developer ou supérieur, ou par aucun utilisateur.

### Page de détails du pipeline améliorée {#improved-pipeline-details-page}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/_index.md#view-pipelines)

{{< /details >}}

Le graphe de pipeline offre une vue d'ensemble complète de vos pipelines, affichant les statuts des jobs, les mises à jour en temps réel, les pipelines multi-projets et les pipelines parent-enfant.

Aujourd'hui, nous sommes ravis d'annoncer la release du graphe de pipeline repensé avec une esthétique améliorée, une visualisation groupée des jobs, une expérience mobile améliorée et une visibilité étendue des pipelines downstream dans votre vue existante.

Nous vous serions très reconnaissants de bien vouloir l'essayer et de partager vos retours via ce [ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/450676) dédié.

## Sujets connexes {#related-topics}

- [Corrections de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.11)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.11)
- [Améliorations de l'interface](https://papercuts.gitlab.com/?milestone=16.11)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
