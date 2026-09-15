---
stage: Release Notes
group: Monthly Release
date: 2024-05-16
title: "Notes de release de GitLab 17.0"
description: "GitLab 17.0 est disponible avec le catalogue CI/CD avec des composants CI/CD et des inputs désormais en disponibilité générale"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 16 mai 2024, GitLab 17.0 a été lancé avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination 🙌

Niklas van Schrick réalise désormais le hat-trick avec trois titres de MVP et est devenu l'un des contributeurs les plus réguliers de GitLab, avec au moins une merge request par jalon depuis GitLab 14.3.

Niklas a été nominé par [Magdalena Frankiewicz](https://gitlab.com/m_frankiewicz), Product Manager chez GitLab, pour avoir contribué à une fonctionnalité permettant de créer des modèles de payload de webhook personnalisés, puis l'avoir complétée avec la [possibilité de spécifier des en-têtes de webhook personnalisés](https://gitlab.com/gitlab-org/gitlab/-/issues/17290). « Cela a résolu une demande de fonctionnalité très demandée depuis 7 ans et ayant 65 votes positifs », déclare Magdalena. « Les utilisateurs peuvent désormais concevoir entièrement des webhooks personnalisés ! »

Niklas est membre de la [GitLab Core Team](https://about.gitlab.com/community/core-team/) et aide la communauté au sens large ainsi que GitLab à accomplir notre mission de permettre à tous de contribuer.

« Au cours de mon parcours, j'ai interagi avec de nombreux relecteurs, mainteneurs, designers, rédacteurs techniques, product managers, et probablement d'autres encore », dit Niklas. « Tout le monde était serviable et faisait de son mieux pour aider à faire avancer les tickets et les merge requests. »

Gerardo Navarro contribue à GitLab depuis plus d'un an et remporte un deuxième prix GitLab MVP.

Gerardo a été nominé pour ses contributions continues à une fonctionnalité permettant d'[afficher les paquets protégés dans la liste du registre de paquets](https://gitlab.com/gitlab-org/gitlab/-/issues/437926). Cette fonctionnalité fait partie d'une série de contributions liées à l'[epic des paquets protégés](https://gitlab.com/groups/gitlab-org/-/epics/5574) qui vise à renforcer la sécurité en permettant des autorisations granulaires pour créer, mettre à jour et supprimer des paquets du registre de paquets.

Merci à Gerardo Navarro et au reste de l'équipe de Siemens pour leur contribution à la co-création de GitLab.

« Merci beaucoup d'apprécier notre travail avec un prix aussi prestigieux », dit Gerardo. « Je me sens honoré. J'apprends encore beaucoup à chaque contribution. »

## Fonctionnalités principales {#primary-features}

### Le catalogue CI/CD avec les composants CI/CD et les inputs est désormais en disponibilité générale {#cicd-catalog-with-components-and-inputs-now-generally-available}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/components/_index.md#cicd-catalog)

{{< /details >}}

Le catalogue CI/CD est désormais en disponibilité générale. Dans le cadre de cette release, nous mettons également en disponibilité générale les [composants CI/CD](../../ci/components/_index.md) et les [inputs](../../ci/yaml/_index.md#inputs).

Avec le catalogue CI/CD, vous avez accès à une vaste gamme de composants CI/CD créés par la communauté et des experts du secteur. Que vous recherchiez des solutions pour l'intégration continue, les pipelines de déploiement ou les tâches d'automatisation, vous trouverez une sélection diversifiée de composants CI/CD adaptés à vos besoins. Vous pouvez en savoir plus sur le catalogue et ses fonctionnalités dans le [billet de blog](https://about.gitlab.com/blog/ci-cd-catalog-goes-ga-no-more-building-pipelines-from-scratch/) suivant.

Vous êtes invité à contribuer des composants CI/CD au catalogue et à aider à développer cette nouvelle partie en pleine croissance de GitLab.com !

### Analyses d'impact de l'IA dans le Value Streams Dashboard {#ai-impact-analytics-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/duo_and_sdlc_trends.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/12978)

{{< /details >}}

AI Impact est un tableau de bord disponible dans le Value Streams Dashboard qui aide les organisations à comprendre l'[impact de GitLab Duo sur leur productivité](https://about.gitlab.com/blog/measuring-ai-effectiveness-beyond-developer-productivity-metrics/). Cette nouvelle vue des métriques mois par mois compare les tendances d'utilisation de l'IA avec les métriques SDLC telles que le lead time, le cycle time, DORA et les vulnérabilités. Les responsables logiciels peuvent utiliser le tableau de bord AI Impact pour mesurer le temps économisé dans leur flux de travail de bout en bout, tout en restant concentrés sur les résultats commerciaux plutôt que sur l'activité des développeurs.

Dans cette première release, l'utilisation de l'IA est mesurée comme le taux d'utilisation mensuel des [suggestions de code](../../user/project/repository/code_suggestions/_index.md), et est calculée comme le nombre d'utilisateurs mensuels uniques des suggestions de code divisé par le nombre total de [contributeurs](../../user/group/contribution_analytics/_index.md) mensuels uniques.

Le tableau de bord AI Impact est disponible pour les utilisateurs de l'édition Ultimate pour une durée limitée. Ensuite, une licence GitLab Duo Enterprise sera requise pour utiliser le tableau de bord.

### Présentation des runners hébergés sur Linux Arm {#introducing-hosted-runners-on-linux-arm}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/linux.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/365300)

{{< /details >}}

Nous sommes ravis de vous présenter les runners hébergés sur Linux Arm pour GitLab.com. Les types de machines Arm `medium` et `large` désormais disponibles, équipés respectivement de 4 et 8 vCPU, et pleinement intégrés à GitLab CI/CD, vous permettront de créer et de tester votre application plus rapidement et de manière plus rentable que jamais.

Nous sommes déterminés à offrir la vitesse de build CI/CD la plus rapide du secteur et nous réjouissons de voir les équipes atteindre des cycles de feedback encore plus courts et, en définitive, livrer des logiciels plus rapidement.

### Présentation des pages de détails de déploiement {#introducing-deployment-detail-pages}

<!-- categories: Release Orchestration, Environment Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/deployment_approvals.md#approve-or-reject-a-deployment) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/374538)

{{< /details >}}

Vous pouvez désormais créer un lien direct vers un déploiement dans GitLab. Auparavant, si vous collaboriez sur un déploiement, vous deviez rechercher le déploiement dans la liste des déploiements. En raison du nombre de déploiements répertoriés, trouver le bon déploiement était difficile et sujet aux erreurs.

À partir de la version 17.0, GitLab propose une vue des détails de déploiement vers laquelle vous pouvez créer un lien direct. Dans cette première version, la page de détails du déploiement offre une vue d'ensemble du job de déploiement et la possibilité d'approuver, de rejeter ou de commenter un déploiement dans un contexte de livraison continue. Nous explorons d'autres pistes pour améliorer la page de détails du déploiement, notamment en y ajoutant un lien depuis le job de pipeline associé. Nous serions ravis de recueillir vos retours dans le [ticket 450700](https://gitlab.com/gitlab-org/gitlab/-/issues/450700).

### GitLab Duo Chat utilise désormais Anthropic Claude 3 Sonnet {#gitlab-duo-chat-now-uses-anthropic-claude-3-sonnet}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/gitlab_duo_chat/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13297)

{{< /details >}}

GitLab Duo Chat vient de s'améliorer considérablement. Il utilise désormais Anthropic Claude 3 Sonnet comme modèle de base, remplaçant Claude 2.1 pour répondre à la plupart des questions.

Chez GitLab, nous appliquons une approche basée sur les tests pour choisir le meilleur modèle pour un ensemble de tâches et pour élaborer des prompts performants. Grâce aux ajustements récents apportés aux prompts du chat, nous avons obtenu des améliorations significatives en termes d'exactitude, d'exhaustivité et de lisibilité des réponses du chat basées sur Claude 3 Sonnet par rapport à la version précédente du chat basée sur Claude 2.1. C'est pourquoi nous avons désormais adopté cette nouvelle version du modèle.

### Les questions pratiques dans GitLab Duo Chat sont désormais prises en charge dans les déploiements self-managed {#how-to-questions-in-gitlab-duo-chat-supported-on-self-managed-deployments}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/gitlab_duo_chat/examples.md#ask-about-gitlab) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/451215)

{{< /details >}}

L'une des fonctionnalités populaires de GitLab Duo Chat est de répondre aux questions sur l'utilisation de GitLab. Bien que Chat offre diverses autres fonctionnalités, cette fonctionnalité particulière n'était auparavant disponible que sur GitLab.com. Avec cette release, nous la rendons accessible aux déploiements GitLab self-managed, conformément à notre engagement de fournir une expérience agréable dans tous les types de déploiements.

Que vous soyez novice ou expert, vous pouvez demander de l'aide à Chat avec des questions comme « Comment changer mon mot de passe dans GitLab ? » ou « Comment connecter un cluster Kubernetes à GitLab ? ». Chat vise à fournir des informations utiles pour résoudre vos problèmes plus efficacement.

### Nouveau panneau d'aperçu de l'utilisation dans le Value Streams Dashboard {#new-usage-overview-panel-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md#overview) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438256)

{{< /details >}}

Nous avons amélioré le Value Streams Dashboard avec un panneau d'aperçu. Cette nouvelle visualisation répond au besoin d'informations de niveau exécutif sur les performances de livraison logicielle, et donne une image claire de l'utilisation de GitLab dans le contexte du cycle de vie du développement logiciel (SDLC).

Le panneau d'aperçu affiche des métriques au niveau du groupe, telles que le nombre de (sous-)groupes, projets, utilisateurs, tickets, merge requests et pipelines.

### Ajouter un groupe à la liste d'autorisation des jetons de job CI/CD {#add-a-group-to-the-cicd-job-token-allowlist}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)

{{< /details >}}

Introduite dans GitLab 15.9, la liste d'autorisation des jetons de job CI/CD empêche tout accès non autorisé d'autres projets à votre projet. Auparavant, vous pouviez autoriser l'accès au niveau du projet uniquement à partir d'autres projets spécifiques, avec une limite maximale de 200 projets au total.

Dans GitLab 17.0, vous pouvez désormais ajouter des groupes à la liste d'autorisation des jetons de job CI/CD d'un projet. La limite maximale de 200 s'applique désormais à la fois aux projets et aux groupes, ce qui signifie qu'une liste d'autorisation de projet peut désormais comporter jusqu'à 200 projets et groupes autorisés à accéder. Cette amélioration facilite l'ajout d'un grand nombre de projets associés à un groupe.

### Contrôle de contexte amélioré avec le mot-clé CI/CD `rules:exists` {#enhanced-context-control-with-the-rulesexists-cicd-keyword}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#rulesexistsproject) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)

{{< /details >}}

Le mot-clé CI/CD `rules:exists` a des comportements par défaut qui varient en fonction de l'endroit où le mot-clé est défini, ce qui peut rendre son utilisation plus difficile avec des pipelines plus complexes. Lorsqu'il est défini dans un job, `rules:exists` recherche les fichiers spécifiés dans le projet exécutant le pipeline. Cependant, lorsqu'il est défini dans une section `include`, `rules:exists` recherche les fichiers spécifiés dans le projet hébergeant le fichier de configuration contenant la section `include`. Si la configuration est répartie sur plusieurs fichiers et projets, il peut être difficile de savoir quel projet exact sera utilisé pour rechercher les fichiers définis.

Dans cette release, nous avons introduit les sous-clés `project` et `ref` dans `rules:exists`, vous offrant un moyen de contrôler explicitement le contexte de recherche pour ce mot-clé. Ces nouvelles sous-clés vous aident à garantir une évaluation précise des règles en spécifiant exactement le contexte de recherche, en atténuant les incohérences et en améliorant la clarté dans vos définitions de règles de pipeline.

### Journal des modifications pour les changements de configuration effectués via Switchboard {#change-log-for-configuration-changes-made-using-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/dedicated/configure_instance/_index.md#view-the-change-log) \| [Ticket associé](https://about.gitlab.com/dedicated/)

{{< /details >}}

Vous pouvez désormais afficher le statut des modifications de configuration apportées à votre infrastructure d'instance GitLab Dedicated via la [page de configuration](../../administration/dedicated/configure_instance/_index.md#configure-your-instance-using-switchboard) de Switchboard.

Tous les utilisateurs ayant accès à l'affichage ou à la modification de votre tenant dans Switchboard pourront consulter les modifications dans le journal des changements de configuration et suivre leur progression au fur et à mesure qu'elles sont appliquées à votre instance.

Actuellement, la page de configuration de Switchboard et le journal des modifications sont disponibles pour des modifications telles que la gestion de l'accès à votre instance en ajoutant une [adresse IP à la liste d'autorisation](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist) ou la configuration des [paramètres SAML](../../administration/dedicated/configure_instance/authentication/saml.md) de votre instance.

Nous étendrons cette fonctionnalité pour permettre des mises à jour en libre-service pour des configurations supplémentaires dans les [prochains trimestres](https://about.gitlab.com/releases/whats-new/#whats-coming).

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations du chart GitLab {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

L'[opérateur GitLab](https://docs.gitlab.com/operator/) est désormais disponible pour une utilisation en production pour les installations hybrides cloud-native. Consultez la [documentation d'installation](https://docs.gitlab.com/operator/installation/) avant d'adopter l'opérateur GitLab.

La prise en charge du repli sur les images BusyBox lorsque vous spécifiez des valeurs BusyBox personnalisées (`global.busybox`) est supprimée. La prise en charge des conteneurs d'initialisation basés sur BusyBox a été dépréciée dans GitLab 16.2 (chart Helm 7.2) au profit d'une image d'initialisation commune basée sur GitLab.

La prise en charge de `gitlab.kas.privateApi.tls.enabled` et de `gitlab.kas.privateApi.tls.secretName` est également supprimée. Vous devez utiliser `global.kas.tls.enabled` et `global.kas.tls.secretName` à la place.

Les options de sélecteur de file d'attente et de négation dépréciées sont supprimées du chart Sidekiq.

### Améliorations du paquet Linux {#linux-package-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

CentOS Linux 7 atteindra sa [fin de vie](https://www.redhat.com/en/topics/linux/centos-linux-eol) le 30 juin 2024. Cela fait de GitLab 17.6 la dernière version de GitLab pour laquelle nous pourrons fournir des paquets pour CentOS 7.

### Le mode deux bases de données est disponible en version bêta {#two-database-mode-is-available-in-beta}

<!-- categories: Cell -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/postgresql/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/432391)

{{< /details >}}

Actuellement, la plupart des clients self-managed n'utilisent qu'une seule base de données. Afin de garantir que la configuration entre GitLab.com et le self-managed est identique, nous demandons aux clients self-managed de migrer et d'exécuter deux bases de données par défaut. Dans la version 16.0, les deux connexions de base de données sont devenues le paramètre par défaut pour les installations self-managed. Dans la version 17.0, nous [publions le mode deux bases de données en version bêta limitée](../../administration/postgresql/_index.md), avec pour objectif de rendre l'exécution décomposée généralement disponible d'ici la version 19.0. La migration vers deux bases de données reste optionnelle dans la version 17.0, mais doit être effectuée avant la mise à niveau vers la version 19.0.

La migration nécessite une interruption de service. Les clients self-managed peuvent utiliser un [outil](https://gitlab.com/gitlab-org/gitlab/-/issues/368729) qui exécute cette migration avec une certaine interruption de service. Nous avons introduit une nouvelle commande `gitlab-ctl` qui vous permet de mettre à niveau vos instances GitLab à base de données unique vers une configuration décomposée. Cette configuration contient des commandes compatibles avec notre paquet Linux. La [migration réelle](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135585) (copie de la base de données) fait partie d'une tâche rake dans le projet GitLab.

### Les membres de groupes partagés privés sont répertoriés dans l'onglet Membres pour tous les membres {#private-shared-group-members-are-listed-on-members-tab-for-all-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/members/sharing_projects_groups.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/418888)

{{< /details >}}

Auparavant, lorsqu'un groupe ou un projet public invitait un groupe privé, le groupe privé n'était répertorié que dans l'onglet Groupes de la page Membres, et les membres privés n'étaient pas visibles pour les membres du groupe public. Pour favoriser une meilleure collaboration entre les membres de ces groupes, nous répertorions désormais tous les membres du groupe invité dans l'onglet Membres, y compris les membres des groupes privés invités. La source d'appartenance sera masquée pour les membres qui n'ont pas accès au groupe privé. Cependant, la source d'appartenance sera visible pour les utilisateurs qui ont au moins le rôle Maintainer dans le projet ou le rôle Owner dans le groupe, afin qu'ils puissent gérer les membres de leur projet ou groupe. Si l'utilisateur consultant l'onglet Membres n'est pas authentifié ou n'est pas membre du groupe ou du projet, il ne verra pas les membres du groupe privé. Nous espérons que ce changement permettra aux membres de groupes et de projets de comprendre en un coup d'œil qui a accès à un groupe ou à un projet.

### La page Membres affiche les membres des groupes invités {#members-page-displays-members-from-invited-groups}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/members/_index.md#share-a-project-with-a-group) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)

{{< /details >}}

Auparavant, les membres des groupes invités à un groupe ou un projet n'étaient visibles que dans l'onglet Groupes de la page Membres. Cela signifiait que les utilisateurs devaient consulter à la fois les onglets Groupes et Membres pour comprendre qui a accès à un groupe ou un projet donné. Désormais, les membres partagés sont également répertoriés dans l'onglet Membres, offrant une vue d'ensemble complète de tous les membres faisant partie d'un groupe ou d'un projet en un coup d'œil.

### Importer depuis Bitbucket Cloud via l'API REST {#import-from-bitbucket-cloud-by-using-rest-api}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/import.md#import-repository-from-bitbucket-cloud) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/215036)

{{< /details >}}

Dans ce jalon, nous avons ajouté la possibilité d'importer des projets Bitbucket Cloud via l'API REST.

Cela peut être une meilleure solution pour importer un grand nombre de projets que l'importation via l'interface utilisateur.

### Réimporter une relation de projet choisie via l'API {#re-import-a-chosen-project-relation-by-using-the-api}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/project_import_export.md#import-project-resources) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/425798)

{{< /details >}}

Lors de l'importation de projets depuis des fichiers d'export contenant de nombreux éléments du même type (par exemple, des merge requests ou des pipelines), certains de ces éléments n'étaient parfois pas importés.

Dans cette release, nous avons ajouté un endpoint d'API qui réimporte une relation nommée, en ignorant les éléments déjà importés. L'API nécessite les deux éléments suivants :

- Une archive d'export de projet.
- Un type (tickets, merge requests, pipelines ou jalons).

### Afficher les tickets de plusieurs projets Jira dans GitLab {#view-issues-from-multiple-jira-projects-in-gitlab}

<!-- categories: Settings -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/jira/configure.md#view-jira-issues) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/12609)

{{< /details >}}

Pour les dépôts de grande taille, vous pouvez désormais afficher les tickets de plusieurs projets Jira dans GitLab lorsque vous configurez l'intégration des tickets Jira. Avec cette release, vous pouvez :

- Saisir jusqu'à 100 clés de projet Jira séparées par des virgules.
- Laisser **Clés de projet Jira** vide pour inclure toutes les clés disponibles.

Lorsque vous consultez les tickets Jira dans GitLab, vous pouvez [filtrer les tickets](../../integration/jira/configure.md#filter-jira-issues) par projet.

Pour [créer des tickets Jira pour les vulnérabilités](../../integration/jira/configure.md#create-a-jira-issue-for-a-vulnerability) dans GitLab Ultimate, vous ne pouvez spécifier qu'un seul projet Jira.

### Activer l'affichage des tickets Jira dans GitLab avec l'API REST {#enable-viewing-jira-issues-in-gitlab-with-the-rest-api}

<!-- categories: Source Code Management, Settings -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/project_integrations.md#jira-issues) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/267015)

{{< /details >}}

Avec cette release, vous pouvez utiliser l'API REST pour activer l'[affichage des tickets Jira](../../integration/jira/configure.md#view-jira-issues) dans GitLab. Vous pouvez également spécifier un ou plusieurs projets Jira à partir desquels afficher les tickets.

Merci à [Ivan](https://gitlab.com/ivantedja) pour [cette contribution à la communauté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150209) !

### Plusieurs participants externes pour le Service Desk {#multiple-external-participants-for-service-desk}

<!-- categories: Service Desk -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/service_desk/external_participants.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/3758)

{{< /details >}}

Il arrive que plusieurs personnes soient impliquées dans la résolution d'un ticket de support ou que le demandeur souhaite tenir ses collègues informés de l'état du ticket.

Vous pouvez désormais avoir un maximum de 10 participants externes sans compte GitLab sur un ticket Service Desk et des tickets ordinaires.

Les participants externes reçoivent des e-mails de notification du Service Desk pour chaque commentaire public sur le ticket, et leurs réponses apparaîtront sous forme de commentaires dans l'interface GitLab.

Utilisez simplement les actions rapides [`/add_email`](../../user/project/service_desk/external_participants.md#add-an-external-participant) et [`remove_email`](../../user/project/service_desk/external_participants.md#add-an-external-participant) pour ajouter ou supprimer des participants externes en quelques frappes.

Vous pouvez également configurer GitLab pour [ajouter toutes les adresses e-mail de l'en-tête `Cc`](../../user/project/service_desk/external_participants.md#add-external-participants-from-the-cc-header) de l'e-mail initial au ticket Service Desk.

Vous pouvez [personnaliser tous les modèles d'e-mails du Service Desk à votre convenance](../../user/project/service_desk/configure.md#customize-emails-sent-to-external-participants), en utilisant Markdown, HTML et des espaces réservés dynamiques. Un [espace réservé pour le lien de désinscription](../../user/project/service_desk/external_participants.md#add-an-external-participant) est disponible pour permettre aux participants externes de se désabonner facilement d'une conversation.

### Indiquer que les éléments ont été importés via le transfert direct {#indicate-that-items-were-imported-using-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/direct_transfer_migrations.md#review-results-of-the-import) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/443492)

{{< /details >}}

Vous pouvez migrer des groupes et des projets GitLab entre des instances GitLab [en utilisant le transfert direct](../../user/group/import/_index.md).

Jusqu'à présent, les éléments importés n'étaient pas facilement identifiables. Avec cette release, nous avons ajouté des indicateurs visuels aux éléments importés via le transfert direct, où le créateur est identifié comme un utilisateur spécifique :

- Notes (notes système et commentaires d'utilisateurs)
- Tickets
- Merge requests
- Epics
- Designs
- les snippets ;
- Activité du profil utilisateur

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Intégration des secrets 1Password dans le plugin GitLab Duo pour les IDE JetBrains {#1password-secrets-integration-in-gitlab-duo-plugin-for-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../editor_extensions/jetbrains_ide/_index.md#integrate-with-1password-cli) \| [Ticket associé](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291)

{{< /details >}}

Vous pouvez désormais intégrer la gestion des secrets 1Password au plugin GitLab Duo pour JetBrains.

Les développeurs peuvent remplacer leurs jetons d'accès personnel dans leurs paramètres d'IDE JetBrains par des références aux secrets 1Password. Cela simplifie la gestion des secrets et permet une rotation transparente des secrets sans mise à jour manuelle des jetons.

### Accédez à GitLab Duo Chat plus rapidement grâce à des raccourcis personnalisables {#access-gitlab-duo-chat-faster-with-customizable-shortcuts}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../editor_extensions/jetbrains_ide/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/332)

{{< /details >}}

Ouvrir Duo Chat directement depuis votre éditeur dans JetBrains est désormais encore plus facile.

Utilisez le raccourci clavier Alt+D par défaut (ou définissez le vôtre) pour ouvrir Duo Chat rapidement et saisir votre question. Utilisez le même raccourci clavier pour fermer la fenêtre.

### Modèles de commentaires de projet {#project-comment-templates}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/comment_templates.md#for-a-project) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/440818)

{{< /details >}}

Suite à la release des [modèles de commentaires de groupe dans GitLab 16.11](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#group-comment-templates), nous les apportons aux projets dans GitLab 17.0.

Au sein d'une organisation, il peut être utile d'avoir la même réponse modélisée dans les tickets, les epics et les merge requests. Ces réponses peuvent inclure des questions standard auxquelles il faut répondre, des réponses à des problèmes courants ou une bonne structure pour les commentaires de revue de code des merge requests. Les modèles de commentaires au niveau du projet vous offrent une façon supplémentaire de définir la portée de la disponibilité des modèles, offrant aux organisations plus de contrôle et de flexibilité dans leur partage entre les utilisateurs.

Pour créer un modèle de commentaire, accédez à n'importe quelle zone de commentaire sur GitLab et sélectionnez **Insérer un modèle de commentaire > Manage project comment templates**. Une fois que vous avez créé un modèle de commentaire, il est disponible pour tous les membres du projet. Sélectionnez l'icône **Insérer un modèle de commentaire** lors d'un commentaire, et votre réponse enregistrée sera appliquée.

Nous sommes vraiment enthousiastes à propos de cette itération des modèles de commentaires et si vous avez des retours, veuillez les laisser dans le [ticket 451520](https://gitlab.com/gitlab-org/gitlab/-/issues/451520).

### Signature des commits pour les commits via l'interface GitLab {#commit-signing-for-gitlab-ui-commits}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits) \| [Ticket associé](https://gitlab.com/gitlab-org/gitaly/-/issues/5361)

{{< /details >}}

Auparavant, les commits web et les commits automatisés effectués par GitLab ne pouvaient pas être signés. Vous pouvez désormais configurer votre instance self-managed avec une clé de signature, un nom de committeur et une adresse e-mail pour signer les commits web et automatisés.

### Augmentation de la limite d'autorisation de l'agent Kubernetes {#increase-kubernetes-agent-authorization-limit}

<!-- categories: Continuous Delivery -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/431133)

{{< /details >}}

Avec l'agent GitLab pour Kubernetes, vous pouvez partager une seule connexion d'agent avec un groupe. Nous visons à prendre en charge un agent unique sur un grand cluster multi-tenant. Cependant, vous avez peut-être rencontré une limitation sur le nombre de partages de connexion. Jusqu'à présent, un agent ne pouvait être partagé qu'avec 100 projets et groupes utilisant [CI/CD](../../user/clusters/agent/ci_cd_workflow.md), et 100 projets et groupes utilisant le mot-clé [`user_access`](../../user/clusters/agent/user_access.md). Dans GitLab 17.0, le nombre de projets et de groupes avec lesquels vous pouvez partager est porté à 500.

Si vous avez besoin d'exécuter plusieurs agents dans un cluster, nous aimerions recueillir vos retours dans le [ticket 454110](https://gitlab.com/gitlab-org/gitlab/-/issues/454110).

### Prise en charge de l'agent GitLab pour Kubernetes en mode FIPS {#support-for-gitlab-agent-for-kubernetes-in-fips-mode}

<!-- categories: Continuous Delivery -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/clusters/kas.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/375327)

{{< /details >}}

À partir de GitLab 17.0, vous pouvez installer GitLab en mode FIPS avec les composants de l'agent pour Kubernetes activés. Désormais, les utilisateurs conformes FIPS peuvent bénéficier de toutes les [intégrations Kubernetes avec GitLab](../../user/clusters/agent/_index.md).

### Suivre les merge requests en avance rapide dans les déploiements {#track-fast-forward-merge-requests-in-deployments}

<!-- categories: Continuous Delivery -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/deployments.md#track-newly-included-merge-requests-per-deployment) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/384104)

{{< /details >}}

Dans les releases précédentes, les merge requests n'étaient suivies dans un déploiement que si la méthode de fusion du projet était **Validation de fusion** ou **Validation de fusion avec un historique semi-linéaire**. À partir de GitLab 17.0, les merge requests sont suivies dans les déploiements, y compris dans les projets utilisant la méthode de fusion **Fusion en avance rapide**.

### Identifier les sessions initiées par le mode Admin {#identify-sessions-initiated-by-admin-mode}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/sign_in_restrictions.md#check-if-your-session-has-admin-mode-enabled) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438674)

{{< /details >}}

En tant qu'administrateur d'instance, lorsque vous utilisez plusieurs navigateurs ou différents ordinateurs, il est difficile de savoir quelles sessions sont en mode Admin et lesquelles ne le sont pas. Désormais, les administrateurs peuvent accéder à **Paramètres de l'utilisateur > Active Sessions** pour identifier les sessions utilisant le mode Admin.

Merci à [Roger Meier](https://gitlab.com/bufferoverflow) pour votre contribution !

### Personnaliser les avatars des utilisateurs {#customize-avatars-for-users}

<!-- categories: User Management -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../api/users.md#upload-an-avatar-for-yourself) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/356868)

{{< /details >}}

Vous pouvez désormais utiliser l'API pour télécharger un avatar personnalisé pour tout type d'utilisateur, y compris les utilisateurs bot. Cela peut être particulièrement utile pour distinguer visuellement les utilisateurs bot, tels que les jetons d'accès de groupe et de projet ou les comptes de service, des utilisateurs humains dans l'interface utilisateur. Merci à [Phawin](https://gitlab.com/lifez) pour votre contribution !

### Modifier un rôle personnalisé et ses autorisations {#edit-a-custom-role-and-its-permissions}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md#edit-a-custom-role) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/437590)

{{< /details >}}

Auparavant, vous ne pouviez pas modifier un rôle personnalisé existant et ses autorisations. Désormais, vous pouvez modifier un rôle personnalisé et ses autorisations sans avoir à recréer le rôle pour effectuer une modification.

### Nouvelles autorisations pour les rôles personnalisés {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

De nouvelles autorisations sont disponibles pour créer des rôles personnalisés :

- [Attribuer des liens de politique de sécurité](../../user/custom_roles/abilities.md#security-policy-management)
- [Gérer et attribuer des cadres de conformité](../../user/custom_roles/abilities.md#compliance-management)
- [Gérer les webhooks](../../user/custom_roles/abilities.md#webhooks)
- [Gérer les règles push](../../user/custom_roles/abilities.md#source-code-management)

Avec la publication de ces autorisations personnalisées, vous pouvez réduire le nombre de propriétaires nécessaires dans un groupe en créant un rôle personnalisé avec ces autorisations équivalentes à celles du propriétaire. Les rôles personnalisés vous permettent de définir des rôles granulaires qui accordent à un utilisateur uniquement les autorisations dont il a besoin pour effectuer son travail, et de réduire l'escalade de privilèges inutile.

### Gérer les rôles personnalisés au niveau de l'instance self-managed {#manage-custom-roles-at-self-managed-instance-level}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11851)

{{< /details >}}

Avant cette release, sur GitLab self-managed, les rôles personnalisés devaient être créés au niveau du groupe. Cela signifiait que les administrateurs ne pouvaient pas gérer de manière centralisée les rôles personnalisés pour l'instance, ce qui entraînait des doublons de rôles dans l'instance. Désormais, les rôles personnalisés sont gérés au niveau de l'instance self-managed. Seuls les administrateurs peuvent créer des rôles personnalisés, mais les administrateurs et les propriétaires de groupes peuvent attribuer ces rôles personnalisés.

Pour plus d'informations sur la migration des rôles personnalisés existants, les endpoints d'API et les workflows, consultez l'[epic 11851](https://gitlab.com/groups/gitlab-org/-/epics/11851).

Cette mise à jour n'a pas d'impact sur les workflows de rôles personnalisés sur GitLab.com.

### Améliorations UX des rôles personnalisés {#ux-improvements-to-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/11947)

{{< /details >}}

Une série d'améliorations ont été apportées à l'expérience utilisateur des rôles personnalisés, notamment :

- [Une nouvelle page s'ouvre lors de la création d'un nouveau rôle personnalisé](https://gitlab.com/gitlab-org/gitlab/-/issues/393238).
- [Conception améliorée pour le tableau des rôles personnalisés](https://gitlab.com/gitlab-org/gitlab/-/issues/437592).
- [Conception améliorée pour la boîte de dialogue de suppression des rôles personnalisés](https://gitlab.com/gitlab-org/gitlab/-/issues/434431).
- [Vérification préalable des autorisations du rôle par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/430915).

### Amélioration des paramètres de protection des branches pour les administrateurs et les groupes {#improved-branch-protection-settings-for-administrators-and-for-groups}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/branches/default.md#for-all-projects-in-an-instance)

{{< /details >}}

Auparavant, la configuration des options de protection de branche par défaut ne permettait pas le même niveau de configuration que les paramètres des branches protégées.

Dans cette release, nous avons mis à jour les paramètres de protection de branche par défaut pour offrir la même expérience que celle des branches protégées. Cela offre plus de flexibilité pour protéger votre branche par défaut et simplifie le processus pour correspondre à ce qui existe déjà dans les paramètres des branches protégées.

### Configuration optionnelle pour le commentaire du bot de politique {#optional-configuration-for-policy-bot-comment}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/scan_execution_policies.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438272)

{{< /details >}}

Le bot de politique de sécurité publie un commentaire sur les merge requests lorsqu'elles violent une politique, afin d'aider les utilisateurs à comprendre quand les politiques sont appliquées à leur projet, quand l'évaluation est terminée, et s'il y a des violations bloquant une merge request, avec des conseils pour les résoudre. Ces commentaires sont désormais optionnels et peuvent être activés ou désactivés dans chaque politique. Cela offre aux organisations la flexibilité et le contrôle nécessaires pour déterminer comment elles souhaitent communiquer sur ces politiques à leurs utilisateurs.

### Filtrage mis à jour dans le rapport de vulnérabilités {#updated-filtering-on-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13339)

{{< /details >}}

L'ancienne implémentation des filtres du rapport de vulnérabilités n'était pas évolutive. Nous étions limités par l'espace horizontal disponible sur la page. Vous pouvez désormais utiliser le composant de recherche filtrée pour filtrer le rapport de vulnérabilités selon n'importe quelle combinaison de statut, gravité, outil ou activité. Ce changement nous permet d'ajouter de nouveaux filtres, comme ce [filtre par identifiant](https://gitlab.com/groups/gitlab-org/-/epics/13340) proposé.

### Basculer les politiques d'approbation des merge requests en mode échec ouvert ou échec fermé {#toggle-merge-request-approval-policies-to-fail-open-or-fail-closed}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10816)

{{< /details >}}

La conformité fonctionne sur une échelle progressive pour de nombreuses organisations qui trouvent un équilibre entre le respect des exigences et le maintien de la vélocité des développeurs. Les politiques d'approbation des merge requests aident à opérationnaliser la sécurité et la conformité au cœur du workflow DevSecOps - la merge request. Nous introduisons une nouvelle option `fail open` pour les politiques d'approbation des merge requests afin d'offrir de la flexibilité aux équipes qui souhaitent faciliter la transition vers l'application des politiques lors du déploiement des contrôles dans leur organisation.

Lorsqu'une politique d'approbation des merge requests est configurée en mode échec ouvert, les merge requests ne seront désormais bloquées que si une règle de politique est violée **et** si ce projet dispose d'un analyseur de sécurité correctement configuré. Si un analyseur n'est pas activé pour un projet ou si l'analyseur ne produit pas de résultats avec succès, la politique ne considérera plus cela comme une violation pour la règle et l'analyseur concernés. Cette approche permet un déploiement progressif des politiques au fur et à mesure que les équipes s'assurent d'une exécution et d'une application correctes des analyses.

### Suppression automatique des adresses e-mail secondaires non vérifiées {#automatic-deletion-of-unverified-secondary-email-addresses}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/_index.md#delete-email-addresses-from-your-user-profile) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/367823)

{{< /details >}}

Si vous ajoutez une adresse e-mail secondaire à votre profil utilisateur et ne la vérifiez pas, cette adresse e-mail est désormais automatiquement supprimée après trois jours. Auparavant, ces adresses e-mail étaient dans un état réservé et ne pouvaient pas être libérées sans intervention manuelle. Cette suppression automatique réduit la charge de travail des administrateurs et empêche les utilisateurs de réserver des adresses e-mail dont ils ne sont pas propriétaires.

### Filtrer l'interface du registre de paquets pour les paquets contenant des erreurs {#filter-package-registry-ui-for-packages-with-errors}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/package_registry/_index.md#view-packages) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/451054)

{{< /details >}}

Vous pouvez utiliser le registre de paquets GitLab pour publier et télécharger des paquets. Parfois, des paquets échouent au téléchargement en raison d'une erreur. Auparavant, il n'existait aucun moyen de visualiser rapidement les paquets dont le téléchargement avait échoué. Cela rendait difficile l'obtention d'une vue d'ensemble du registre de paquets de votre organisation.

Vous pouvez désormais filtrer l'interface du registre de paquets pour les paquets dont le téléchargement a échoué. Cette amélioration facilite l'investigation et la résolution des problèmes rencontrés.

### Nouvelle métrique de délai médian de fusion dans le Value Streams Dashboard {#new-median-time-to-merge-metric-in-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/435451)

{{< /details >}}

Nous avons ajouté une nouvelle métrique au Value Streams Dashboard : le délai médian de fusion. Dans GitLab, cette métrique représente le délai médian entre la création d'une merge request et sa fusion. Cette nouvelle métrique mesure la santé DevOps en identifiant l'efficacité et la productivité de vos processus de merge request et de revue de code.

En analysant l'évolution de cette métrique dans le [contexte des autres métriques SDLC](https://www.youtube.com/watch?v=yNZRac7gyYo), les équipes peuvent identifier les mois de faible ou forte productivité, comprendre l'impact des nouvelles pratiques DevOps sur la vitesse de développement et le processus de livraison, réduire leur lead time global et augmenter la vélocité de leur livraison logicielle.

### Les fonctionnalités de gestion des designs étendues aux équipes produit {#design-management-features-extended-to-product-teams}

<!-- categories: Design Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/issues/design_management.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/438829)

{{< /details >}}

GitLab élargit la collaboration en mettant à jour ses autorisations. Désormais, les utilisateurs ayant le rôle Reporter peuvent accéder aux fonctionnalités de gestion des designs, permettant aux équipes produit de s'impliquer plus directement dans le processus de design. Ce changement simplifie les workflows et accélère l'innovation en invitant une participation plus large de l'ensemble de votre organisation.

### Protection améliorée contre la suppression des epics {#enhanced-epic-deletion-protection}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/epics/manage_epics.md#delete-an-epic) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/452189)

{{< /details >}}

Nous avons mis à jour ce qui se passe lorsque vous supprimez un epic pour mieux protéger la structure et les données de votre projet. Il s'agit de vous donner plus de contrôle et de tranquillité d'esprit lors de la gestion de vos projets.

Désormais, lorsque vous supprimez un epic parent, au lieu de supprimer automatiquement tous ses enregistrements enfants, nous les préservons en détachant d'abord la relation parent. Ce changement vous offre un moyen plus sûr de gérer vos epics, en veillant à ce que les suppressions accidentelles n'entraînent pas la perte d'informations précieuses.

### Trier le roadmap par date de création, date de dernière mise à jour et titre {#sort-the-roadmap-by-created-date-last-updated-date-and-title}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/roadmap/_index.md#sort-and-filter-the-roadmap) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/460492)

{{< /details >}}

Nous avons étendu les options de tri des epics disponibles dans la vue Roadmap, vous offrant plus de flexibilité dans l'organisation et la priorisation de vos projets. Vous pouvez désormais trier les epics par **created date**, **last updated date** et **title**. Cette amélioration pose les bases de capacités de tri encore plus avancées à l'avenir pour vous aider à gérer les epics de manière plus dynamique.

### Schéma de fichier de configuration simplifié pour le Value Streams Dashboard {#simplified-configuration-file-schema-for-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md#customize-dashboard-panels) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/432185)

{{< /details >}}

Vous pouvez désormais personnaliser les panneaux du Value Streams Dashboard en utilisant un framework d'interface utilisateur personnalisable simplifié piloté par un schéma. Dans le nouveau format, les champs offrent plus de flexibilité pour afficher les données et organiser les panneaux du tableau de bord. Avec le nouveau framework, les administrateurs peuvent suivre les modifications apportées au tableau de bord au fil du temps. Cet historique de versions peut vous aider à revenir à des versions précédentes et à comparer les modifications entre les versions du tableau de bord.

Grâce à cette personnalisation, les décideurs peuvent se concentrer sur les informations les plus pertinentes pour leur activité, tandis que les équipes peuvent mieux organiser et afficher les métriques DevSecOps clés.

### Les invités des groupes peuvent lier des tickets {#guests-in-groups-can-link-issues}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/permissions.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10267)

{{< /details >}}

Nous avons réduit le rôle minimum requis pour relier des tickets et des tâches de Reporter à Invité, vous offrant plus de flexibilité pour organiser le travail dans votre instance GitLab tout en maintenant les [autorisations](../../user/permissions.md).

### Les jalons et les itérations sont visibles dans les tableaux des tickets {#milestones-and-iterations-visible-on-issue-boards}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/issue_board.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/25758)

{{< /details >}}

Nous avons amélioré les tableaux des tickets pour vous offrir des informations plus claires sur le calendrier et les phases de votre projet. Désormais, avec les détails des jalons et des itérations directement visibles sur les cartes de tickets, vous pouvez facilement suivre la progression et ajuster la charge de travail de votre équipe à la volée. Cette amélioration est conçue pour rendre votre planification et votre exécution plus efficaces, en vous tenant informé et en avance sur le planning.

### Mises à jour de l'analyseur API Security Testing {#api-security-testing-analyzer-updates}

<!-- categories: API Security -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/api_security_testing/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/13644)

{{< /details >}}

Nous avons publié les mises à jour suivantes de l'analyseur de tests de sécurité des API lors du jalon de release 17.0 :

- Les variables d'environnement système sont désormais transmises depuis le runner CI aux scripts Python personnalisés utilisés pour certains scénarios avancés (comme la signature de requêtes). Cela facilitera la mise en œuvre de ces scénarios. Voir le [ticket 457795](https://gitlab.com/gitlab-org/gitlab/-/issues/457795) pour plus de détails.
- Les conteneurs API Security s'exécutent désormais en tant qu'utilisateur non root, ce qui améliore la flexibilité et la conformité. Voir le [ticket 287702](https://gitlab.com/gitlab-org/gitlab/-/issues/287702) pour plus de détails.
- Prise en charge des serveurs qui ne proposent que des chiffrements TLSv1.3, ce qui permet à davantage de clients d'adopter les tests de sécurité des API. Voir le [ticket 441470](https://gitlab.com/gitlab-org/gitlab/-/issues/441470) pour plus de détails.
- Mise à niveau vers Alpine 3.19, qui corrige des vulnérabilités de sécurité. Voir le [ticket 456572](https://gitlab.com/gitlab-org/gitlab/-/issues/456572) pour plus de détails.

Comme [annoncé précédemment](../../update/deprecations.md#secure-analyzers-major-version-update), [nous avons augmenté le numéro de version majeur des tests de sécurité des API à la version 5](https://gitlab.com/gitlab-org/gitlab/-/issues/456874) dans GitLab 17.0.

### Prise en charge de l'analyse des dépendances pour Android {#dependency-scanning-support-for-android}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#use-cicd-components) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/12968)

{{< /details >}}

Les utilisateurs de l'analyse des dépendances peuvent désormais analyser les projets Android. Pour configurer l'analyse Android, utilisez le [composant CI/CD du catalogue CI/CD](https://gitlab.com/explore/catalog/components/android-dependency-scanning). L'analyse Android est également prise en charge pour les utilisateurs du [modèle CI/CD](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#edit-the-gitlab-ciyml-file-manually).

### Image Python par défaut pour l'analyse des dépendances {#dependency-scanning-default-python-image}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/441491)

{{< /details >}}

Suite à la dépréciation de Python 3.9 comme image Python par défaut, Python 3.11 est désormais l'image par défaut.

Comme indiqué dans l'[avis de dépréciation](../../update/deprecations.md#deprecate-python-39-in-dependency-scanning-and-license-scanning), la cible pour la nouvelle version Python par défaut était 3.10. Le passage direct à Python 3.11 était nécessaire pour garantir la conformité FIPS.

### DAST prend désormais en charge les architectures arm64 et amd64 par défaut {#dast-now-supports-both-arm64-and-amd64-architectures-by-default}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/13757)

{{< /details >}}

DAST 5 prend en charge les architectures arm64 et amd64 par défaut. Cela permet aux clients de choisir l'architecture de l'hôte du runner et d'optimiser les économies de coûts.

### Couverture de l'analyseur SAST rationalisée pour davantage de langages {#streamlined-sast-analyzer-coverage-for-more-languages}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/412060)

{{< /details >}}

GitLab SAST (test statique de sécurité des applications) analyse désormais les mêmes [langages](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) avec moins d'[analyseurs](../../user/application_security/sast/analyzers.md), offrant une expérience d'analyse plus simple et plus personnalisable.

Dans GitLab 17.0, nous avons remplacé les analyseurs spécifiques aux langages par des [règles gérées par GitLab](../../user/application_security/sast/rules.md) dans l'[analyseur basé sur Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) pour les langages suivants :

- Android
- C et C++
- iOS
- Kotlin
- Node.js
- PHP
- Ruby

Comme [annoncé](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170), nous avons mis à jour le [modèle CI/CD SAST](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) pour refléter la nouvelle couverture d'analyse et supprimer les jobs d'analyseur spécifiques aux langages qui ne sont plus utilisés.

### La détection des secrets prend désormais en charge les ensembles de règles distants lors du remplacement ou de la désactivation de règles {#secret-detection-now-supports-remote-rulesets-when-overriding-or-disabling-rules}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/pipeline/configure.md#with-a-remote-ruleset) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/425251)

{{< /details >}}

Nous avons résolu un bug de détection des secrets qui affectait les ensembles de règles distants. Il est désormais possible de remplacer ou de désactiver des règles via des ensembles de règles distants. Les ensembles de règles distants offrent un moyen évolutif de configurer des règles en un seul endroit, qui peut être appliqué à plusieurs projets.

### Présentation du suivi avancé des vulnérabilités pour la détection des secrets {#introducing-advanced-vulnerability-tracking-for-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/pipeline/_index.md#duplicate-vulnerability-tracking) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/434096)

{{< /details >}}

La détection des secrets utilise désormais un algorithme avancé de suivi des vulnérabilités pour identifier plus précisément quand le même secret a été déplacé dans un fichier suite à une refactorisation ou à des modifications sans rapport. Une nouvelle occurrence n'est plus créée si :

- Une fuite se déplace dans un fichier.
- Une nouvelle fuite de la même valeur apparaît dans le même fichier.

Sinon, le workflow existant (widget de merge request, rapport de pipeline et rapport de vulnérabilités) traitera les occurrences de la même manière qu'auparavant. En s'assurant que les vulnérabilités dupliquées ne sont pas signalées lorsque les secrets changent d'emplacement, les équipes peuvent gérer plus facilement les secrets exposés.

### Plages de versions sémantiques pour les composants CI/CD publiés {#semantic-version-ranges-for-published-cicd-components}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/components/_index.md#semantic-versioning) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/450835)

{{< /details >}}

Lors de l'utilisation d'un composant CI/CD du catalogue CI/CD, vous pouvez souhaiter qu'il utilise automatiquement la dernière version. Par exemple, vous ne souhaitez pas avoir à surveiller manuellement tous les composants que vous utilisez et à passer manuellement à la version suivante à chaque mise à jour mineure ou correctif de sécurité. Mais utiliser `~latest` est également un peu risqué car les mises à jour de version mineure pourraient entraîner des changements de comportement indésirables, et les mises à jour de version majeure présentent un risque plus élevé de changements incompatibles.

Avec cette release, vous pouvez choisir d'utiliser la dernière version majeure ou mineure d'un composant CI/CD. Par exemple, spécifiez `2` pour la version du composant, et vous obtiendrez toutes les mises à jour de cette version majeure, comme `2.1.1`, `2.1.2`, `2.2.0`, mais pas `3.0.0`. Spécifiez `2.1` et vous n'obtiendrez que les mises à jour de correctifs pour cette version mineure, comme `2.1.1`, `2.1.2`, mais pas `2.2.0`.

### Processus de publication standardisé des composants CI/CD du catalogue CI/CD {#standardized-cicd-catalog-component-publishing-process}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/components/_index.md#publish-a-new-release) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/442066)

{{< /details >}}

Nous avons travaillé intensément sur les composants CI/CD, notamment pour rendre le processus de publication des composants dans le catalogue CI/CD une expérience cohérente. Dans le cadre de ce travail, nous avons fait de la publication de versions depuis un job CI/CD avec le [mot-clé `release`](../../ci/yaml/_index.md#release) et l'image `release-cli` la seule méthode. Toutes les améliorations apportées au processus de release s'appliqueront uniquement à cette méthode. Pour éviter les changements incompatibles introduits par cette restriction, assurez-vous de toujours utiliser la dernière version de l'image (`release-cli:latest`) ou au moins une version supérieure à `v0.17`. L'[option **Release** dans l'interface utilisateur](../../user/project/releases/_index.md#create-a-release-in-the-releases-page) est désormais désactivée pour les projets de composants CI/CD.

### Toujours exécuter les commandes `after_script` pour les jobs annulés {#always-run-after_script-commands-for-canceled-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/script.md#set-a-default-before_script-or-after_script-for-all-jobs) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10158)

{{< /details >}}

Le mot-clé CI/CD [`after_script`](../../ci/yaml/_index.md#after_script) est utilisé pour exécuter des commandes supplémentaires après la section principale `script` d'un job. Il est souvent utilisé pour nettoyer les environnements ou d'autres ressources utilisées par le job. Cependant, les commandes `after_script` ne s'exécutaient pas si un job était annulé.

À partir de GitLab 17.0, les commandes `after_script` s'exécuteront toujours lorsqu'un job est annulé. Pour désactiver ce comportement, consultez la [documentation](../../ci/yaml/script.md#skip-after_script-commands-if-a-job-is-canceled).

### GitLab Runner 17.0 {#gitlab-runner-170}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 17.0 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et renvoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Documentation pour l'installation du Runner Operator dans des environnements réseau déconnectés](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/123)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-0-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.0)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.0)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.0)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
