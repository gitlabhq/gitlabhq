---
stage: Release Notes
group: Monthly Release
date: 2024-07-18
title: "Notes de release de GitLab 17.2"
description: "GitLab 17.2 est disponible avec la diffusion de logs pour les pods et conteneurs Kubernetes"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 18 juillet 2024, GitLab 17.2 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Phawin Khongkhasawan {#this-months-notable-contributor-phawin-khongkhasawan}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination ! 🙌

Phawin Khongkhasawan est Tech Lead chez [Jitta](https://www.jitta.com/) et a commencé à contribuer à GitLab en février 2024. En quelques mois seulement, Phawin a fusionné plus de 20 contributions, qui ont également été mises en avant dans les versions [16.11](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#test-project-hooks-with-the-rest-api), [17.0](https://about.gitlab.com/releases/2024/05/16/gitlab-17-0-released/#customize-avatars-for-users) et [17.1](https://about.gitlab.com/releases/2024/06/20/gitlab-17-1-released/#require-confirmation-for-manual-jobs).

Phawin a d'abord été nominé par [Magdalena Frankiewicz](https://gitlab.com/m_frankiewicz), Product Manager chez GitLab, pour l'amélioration des fonctionnalités liées aux webhooks, notamment la demande visant à [autoriser le déclenchement des webhooks de test de projet via l'API](https://gitlab.com/gitlab-org/gitlab/-/issues/455589). Les ingénieurs GitLab [Marc Shaw](https://gitlab.com/marc_shaw) et [Jose Ivan Vargas](https://gitlab.com/jivanvl), ainsi que le Product Manager GitLab [Rutvik Shah](https://gitlab.com/rutshah), ont souligné la patience de Phawin dans la collaboration et l'itération, deux des [valeurs fondamentales de GitLab](https://handbook.gitlab.com/handbook/values/).

« J'apprécie vraiment le travail, la patience et la persévérance de Phawin pour mener à bien la fonctionnalité [Add order by merged_at](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052) », déclare [Patrick Bajao](https://gitlab.com/patrickbajao), Staff Backend Engineer chez GitLab. « Il a fallu quelques jalons avant que cela soit fusionné et déployé, mais il ne s'est pas arrêté et a continué à collaborer avec nous. »

Un grand merci à Phawin pour avoir montré comment les nouveaux contributeurs peuvent avoir un impact immédiat et contribuer à co-créer GitLab.

## Fonctionnalités principales {#primary-features}

### Diffusion de logs pour les pods et conteneurs Kubernetes {#log-streaming-for-kubernetes-pods-and-containers}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13793)

{{< /details >}}

Dans GitLab 16.1, nous avons introduit la liste des pods Kubernetes et les vues de détail. Cependant, vous deviez encore utiliser des outils tiers pour analyser en profondeur vos charges de travail. GitLab propose désormais une vue de diffusion de logs pour les pods et les conteneurs, ce qui vous permet de vérifier et de résoudre rapidement les problèmes dans vos environnements sans quitter votre outil de livraison d'applications.

### GitLab Duo désactive la journalisation des entrées et sorties par défaut. {#gitlab-duo-disabling-input-and-output-logging-by-default}

<!-- categories: Duo Chat -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : GitLab Duo Pro, GitLab Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo/data_usage.md#data-retention) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13401)

{{< /details >}}

GitLab désactive désormais par défaut la journalisation des entrées et sorties de l'IA pour GitLab Duo.

Chez GitLab, nous visons à garantir que les clients disposent d'une souveraineté sur leurs données. Nous avons désormais désactivé la journalisation des entrées et sorties par défaut et ne journaliserons les entrées et sorties qu'avec le consentement explicite des clients via un ticket de support GitLab.

### Bloquer une merge request en demandant des modifications {#block-a-merge-request-by-requesting-changes}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/reviews/_index.md#prevent-merge-when-you-request-changes)

{{< /details >}}

Lorsque vous effectuez une revue, vous pouvez la finaliser en choisissant entre `approve`, `comment` ou `request changes` ([publié dans GitLab 16.9](https://about.gitlab.com/releases/2024/02/15/gitlab-16-9-released/#request-changes-on-merge-requests)). Lors de la revue, vous pouvez trouver des modifications qui devraient empêcher la fusion d'une merge request tant qu'elles ne sont pas résolues, et vous finalisez alors votre revue avec `request changes`.

Lors d'une demande de modifications, GitLab ajoute désormais une vérification de fusion qui empêche la fusion jusqu'à ce que la demande de modifications soit résolue. La demande de modifications peut être résolue lorsque l'utilisateur initial qui a demandé les modifications relit la merge request et l'approuve ensuite. Si l'utilisateur qui a initialement demandé des modifications n'est pas en mesure d'approuver, la demande de modifications peut être **Contournée** par toute personne disposant des autorisations de fusion, afin que le développement puisse continuer.

Faites-nous part de vos retours sur cette nouvelle fonctionnalité dans le [ticket 455339](https://gitlab.com/gitlab-org/gitlab/-/issues/455339).

### Explication des vulnérabilités {#vulnerability-explanation}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/application_security/analyze/duo.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10642)

{{< /details >}}

L'explication des vulnérabilités fait désormais partie de GitLab Duo Chat et est généralement disponible. Grâce à l'explication des vulnérabilités, vous pouvez ouvrir le chat depuis n'importe quelle vulnérabilité SAST pour mieux comprendre la vulnérabilité, voir comment elle pourrait être exploitée et examiner un correctif potentiel.

### Prise en charge de l'octroi d'autorisation pour les appareils OAuth 2.0 {#oauth-20-device-authorization-grant-support}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/oauth2.md#device-authorization-grant-flow) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/332682)

{{< /details >}}

GitLab prend désormais en charge le [flux d'octroi d'autorisation pour les appareils OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc8628). Ce flux permet d'authentifier en toute sécurité votre identité GitLab depuis des appareils à saisie limitée pour lesquels les interactions avec un navigateur ne sont pas envisageables. Cela rend le flux d'octroi d'autorisation pour les appareils idéal pour les utilisateurs qui tentent d'utiliser les services GitLab depuis des serveurs sans interface graphique ou d'autres appareils dont l'interface utilisateur est absente ou limitée. Merci à [John Parent](https://kitware.com/) pour votre contribution !

### Type de politique d'exécution de pipeline {#pipeline-execution-policy-type}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/pipeline_execution_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13266)

{{< /details >}}

Le type de politique d'exécution de pipeline est un nouveau type de [politique de sécurité](../../user/application_security/policies/_index.md) qui permet aux utilisateurs de prendre en charge l'application de jobs CI génériques, de scripts et d'instructions.

Le type de politique d'exécution de pipeline permet aux équipes de sécurité et de conformité d'appliquer des [modèles de scan de sécurité GitLab](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Jobs) personnalisés, des [modèles CI pris en charge par GitLab ou ses partenaires](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates), des modèles de scan de sécurité tiers, des règles de reporting personnalisées via des jobs CI, ou des scripts et règles personnalisés via GitLab CI.

La politique d'exécution de pipeline dispose de deux modes : inject et override. Le mode *inject* injecte des jobs dans le pipeline CI/CD du projet. Le mode *override* remplace la configuration du pipeline CI/CD du projet.

Comme pour toutes les politiques GitLab, l'application peut être gérée de manière centralisée par des membres désignés des équipes de sécurité et de conformité qui créent et gèrent les politiques. [Apprenez à créer votre première politique d'exécution de pipeline](../../user/application_security/policies/pipeline_execution_policies.md) !

### Prise en charge étendue des ensembles de règles personnalisés dans la détection des secrets du pipeline {#expanded-support-of-custom-rulesets-in-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/336395)

{{< /details >}}

Nous avons étendu la prise en charge des ensembles de règles personnalisés dans la détection des secrets du pipeline.

Vous pouvez utiliser deux nouveaux types de passthroughs, `git` et `url`, pour configurer des ensembles de règles distants. Cela facilite la gestion des workflows, comme le partage de configurations d'ensembles de règles entre plusieurs projets.

Vous pouvez également étendre la configuration par défaut avec un ensemble de règles distant en utilisant l'un de ces nouveaux types de passthroughs.

L'analyseur prend désormais aussi en charge :

- L'enchaînement de jusqu'à 20 passthroughs dans une seule configuration pour remplacer les règles prédéfinies.
- L'inclusion de variables d'environnement dans les passthroughs.
- La définition d'un délai d'expiration lors du chargement d'un passthrough.
- La validation de la syntaxe TOML dans la configuration de l'ensemble de règles.

### GitLab Duo Chat et Code Suggestions disponibles dans les workspaces {#gitlab-duo-chat-and-code-suggestions-available-in-workspaces}

<!-- categories: Workspaces, Duo Chat, Code Suggestions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo/_index.md)

{{< /details >}}

[GitLab Duo Chat](../../user/gitlab_duo_chat/_index.md) et [Code Suggestions](../../user/project/repository/code_suggestions/_index.md) sont désormais disponibles dans les workspaces ! Que vous recherchiez des réponses rapides ou des améliorations de code efficaces, Duo Chat et Code Suggestions sont conçus pour stimuler la productivité et optimiser votre workflow, rendant le développement à distance dans les workspaces plus efficace et plus performant que jamais.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Amélioration du tri et du filtrage dans la vue d'ensemble du groupe {#improved-sorting-and-filtering-in-group-overview}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/_index.md#view-a-group) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/437013)

{{< /details >}}

Nous avons mis à jour les fonctionnalités de tri et de filtrage de la page de vue d'ensemble du groupe. L'élément de recherche s'étend désormais sur toute la page, ce qui vous permet de mieux visualiser vos chaînes de recherche. Nous avons standardisé les options de tri sur `Name`, `Created date`, `Updated date` et `Stars`.

Nous accueillons vos retours sur ces modifications dans le [ticket 438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322).

### Répertorier les groupes auxquels un groupe a été invité avec l'API Groups {#list-groups-that-a-group-was-invited-to-using-the-groups-api}

<!-- categories: Source Code Management, Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/groups.md#list-shared-groups) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/424959)

{{< /details >}}

Nous avons ajouté un nouvel endpoint à l'API Groups pour répertorier les groupes auxquels un groupe a été invité. Cette fonctionnalité complète l'[endpoint permettant de répertorier les projets auxquels un groupe a été invité](../../api/groups.md#list-shared-projects), afin que vous puissiez obtenir une vue d'ensemble complète de tous les groupes et projets auxquels votre groupe a été ajouté. L'endpoint est limité à 60 requêtes par minute par utilisateur.

Merci à [@imskr](https://gitlab.com/imskr) pour cette contribution communautaire !

### Résoudre les éléments de la liste de tâches, une discussion à la fois {#resolve-to-do-items-one-discussion-at-a-time}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/todos.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/461111)

{{< /details >}}

Les discussions sur les tickets GitLab peuvent devenir très actives. GitLab vous aide à gérer ces conversations en créant un élément de la liste de tâches pour les commentaires qui vous concernent, et résout automatiquement l'élément lorsque vous effectuez une action sur le ticket.

Auparavant, lorsque vous effectuiez une action sur un fil de discussion dans le ticket, tous les éléments de la liste de tâches étaient résolus, même si vous étiez mentionné dans plusieurs fils de discussion différents. Désormais, GitLab résout uniquement l'élément de la liste de tâches pour le fil de discussion avec lequel vous avez interagi.

### Indiquer les éléments importés dans l'interface utilisateur {#indicate-imported-items-in-ui}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/import/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13825)

{{< /details >}}

Vous pouvez importer des projets dans GitLab depuis [d'autres solutions SCM](../../user/import/_index.md). Cependant, il était difficile de savoir si les éléments d'un projet avaient été importés ou créés sur l'instance GitLab.

Avec cette release, nous avons ajouté des indicateurs visuels aux éléments importés depuis GitHub, Gitea, Bitbucket Server et Bitbucket Cloud lorsque le créateur est identifié comme un utilisateur spécifique. Par exemple, les merge requests, les tickets et les notes.

### Les branches supprimées sont retirées du panneau de développement Jira {#deleted-branches-are-removed-from-jira-development-panel}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/jira/development_panel.md#feature-availability) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/351625)

{{< /details >}}

Auparavant, lors de l'utilisation de l'[application GitLab pour Jira Cloud](../../integration/jira/connect-app.md), si vous supprimiez une branche dans GitLab, cette branche apparaissait toujours dans le panneau de développement Jira. La sélection de cette branche provoquait une erreur `404` sur GitLab.

À compter de cette release, les branches supprimées dans GitLab sont retirées du panneau de développement Jira.

### Trouver les paramètres du projet à l'aide de la palette de commandes {#find-project-settings-by-using-the-command-palette}

<!-- categories: Settings, Global Search -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/command_palette.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/448637)

{{< /details >}}

GitLab propose de nombreux paramètres pour les projets, les groupes, l'instance et pour vous-même à titre personnel. Pour trouver le paramètre que vous recherchez, vous devez souvent passer du temps à naviguer dans de nombreuses zones différentes de l'interface utilisateur.

Avec cette release, vous pouvez désormais rechercher des paramètres de projet depuis la palette de commandes. Essayez-le en visitant un projet, en sélectionnant **Search or go to…**, en entrant en mode commande avec `>` et en tapant le nom d'une section de paramètres, comme **Étiquettes protégées**. Sélectionnez un résultat pour accéder directement au paramètre lui-même.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Génération de messages de commit de fusion désormais en disponibilité générale {#merge-commit-message-generation-now-ga}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)

{{< /details >}}

La rédaction de messages de commit est une étape importante pour s'assurer que les futurs utilisateurs comprennent ce qui a été modifié dans le code source et pourquoi. Il est difficile de trouver un message qui communique efficacement vos modifications et prend en compte tout ce que vous avez pu changer.

La génération de commits de fusion avec GitLab Duo est désormais en disponibilité générale pour garantir que chaque merge request dispose de messages de commit de qualité. Avant de fusionner, sélectionnez **Modifier le message de validation** dans le widget de fusion, puis utilisez l'option **Générer un message de validation** pour qu'un message de commit soit rédigé.

Cette nouvelle fonctionnalité de GitLab Duo est un excellent moyen de s'assurer que l'historique des commits de votre projet constitue une ressource précieuse pour les futurs développeurs.

### GitLab Duo pour la CLI désormais en disponibilité générale {#gitlab-duo-for-the-cli-now-ga}

<!-- categories: GitLab CLI -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](https://docs.gitlab.com/cli/)

{{< /details >}}

GitLab Duo pour la CLI est désormais en disponibilité générale pour tous les utilisateurs. Vous pouvez désormais utiliser `ask` GitLab Duo pour vous aider à trouver la bonne commande `git` pour vos besoins.

Utilisez `glab duo ask <git question>` pour que GitLab Duo vous fournisse des commandes `git` formatées afin d'atteindre vos objectifs. La CLI GitLab fournit ensuite des détails supplémentaires sur les commandes et ce qu'elles feront, y compris des informations sur les indicateurs transmis. Vous pouvez ensuite exécuter les commandes et obtenir leur sortie directement dans votre workflow.

La commande `ask` pour la CLI GitLab est un excellent moyen d'accélérer votre workflow avec les commandes `git` dont vous avez besoin d'un peu d'aide pour vous souvenir.

### Protocole de transfert SSH pur pour LFS {#pure-ssh-transfer-protocol-for-lfs}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/lfs/_index.md#pure-ssh-transfer-protocol) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11872)

{{< /details >}}

En septembre 2021, [`git-lfs` 3.0.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#300-24-sep-2021) a publié la prise en charge de SSH comme protocole de transfert à la place de HTTP. Avant `git-lfs` 3.0.0, HTTP était le seul protocole de transfert pris en charge, ce qui signifiait que l'utilisation de `git-lfs` sur GitLab n'était pas possible pour certains utilisateurs. Avec cette release, nous sommes très heureux de proposer la possibilité d'activer la prise en charge de SSH sur HTTP comme protocole de transfert pour `git-lfs`.

Merci à [Kyle Edwards](https://gitlab.com/KyleFromKitware) et [Joe Snyder](https://gitlab.com/joe-snyder) pour cette contribution !

### Les déploiements et les approbations vers des environnements protégés déclenchent un événement d'audit {#deployments-and-approvals-to-protected-environments-trigger-an-audit-event}

<!-- categories: Continuous Delivery -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/audit_event_types.md#continuous-delivery) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/456687)

{{< /details >}}

Un enregistrement accessible des événements de déploiement, comme les approbations de déploiement, est essentiel pour la gestion de la conformité. Jusqu'à présent, GitLab ne fournissait pas d'événements d'audit liés aux déploiements, de sorte que les responsables de la conformité devaient utiliser des outils personnalisés ou rechercher ces données directement dans GitLab. GitLab fournit désormais trois événements d'audit :

- `deployment_started` enregistre qui a démarré un job de déploiement et à quel moment.
- `deployment_approved` enregistre qui a approuvé un job de déploiement et à quel moment.
- `deployment_rejected` enregistre qui a rejeté un job de déploiement et à quel moment.

### Attribution de frameworks dans le centre de conformité des sous-groupes {#assigning-frameworks-at-subgroup-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : Ultimate, Premium
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md) \| [Epic associé](https://gitlab.com/gitlab-org/gitlab/-/issues/469004)

{{< /details >}}

Le centre de conformité est le lieu central permettant aux équipes de conformité de gérer leurs rapports de conformité aux standards, leurs rapports de violations et leurs frameworks de conformité pour leur groupe.

Auparavant, toutes les fonctionnalités associées du centre de conformité n'étaient disponibles que pour les groupes principaux. Cela signifiait que pour les sous-groupes, les propriétaires n'avaient accès à aucune des fonctionnalités fournies par le centre de conformité du groupe principal.

Pour aider à résoudre ces problèmes clés, nous avons ajouté la possibilité d'attribuer et de retirer des frameworks de conformité pour les sous-groupes. Désormais, les propriétaires de groupe peuvent visualiser leur posture de conformité au niveau du sous-groupe, en plus du tableau de bord complet du centre de conformité au niveau du groupe principal qui était déjà disponible.

### Étendre les « Scan Execution Policies » pour exécuter les modèles `latest` pour chaque analyseur GitLab {#expand-scan-execution-policies-to-run-latest-templates-for-each-gitlab-analyzer}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/scan_execution_policies.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415427)

{{< /details >}}

Les [politiques d'exécution de scan](../../user/application_security/policies/scan_execution_policies.md) ont été étendues pour vous permettre de choisir entre les modèles GitLab `default` et `latest` lors de la définition des règles de politique. Alors que `default` reflète le comportement actuel, vous pouvez mettre à jour votre politique vers `latest` pour utiliser des fonctionnalités disponibles uniquement dans le dernier modèle de l'analyseur de sécurité donné.

En utilisant le modèle `latest`, vous pouvez désormais vous assurer que les scans sont appliqués sur les pipelines de merge request, ainsi que toutes les autres règles activées dans le modèle `latest`. Auparavant, cela était limité aux pipelines de branches ou à une planification spécifiée.

Remarque : assurez-vous de vérifier toutes les modifications entre les modèles `default` et `latest` avant de modifier la politique pour vous assurer que cela correspond à vos besoins !

### Identifier les dates auxquelles plusieurs jetons d'accès expirent {#identify-dates-when-multiple-access-tokens-expire}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../security/tokens/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/467313)

{{< /details >}}

Les administrateurs peuvent désormais exécuter un script qui identifie les dates auxquelles plusieurs jetons d'accès expirent. Vous pouvez utiliser ce script en combinaison avec d'autres scripts sur la [page de dépannage des jetons](../../security/tokens/token_troubleshooting.md) pour identifier et prolonger de grands lots de jetons qui pourraient approcher de leur date d'expiration, si la rotation des jetons n'a pas encore été mise en œuvre.

### Améliorations de l'écran d'autorisation OAuth {#oauth-authorization-screen-improvements}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/oauth_provider.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/462655)

{{< /details >}}

L'écran d'autorisation OAuth décrit désormais plus clairement l'autorisation que vous accordez. Il comprend également une section « vérifié par GitLab » pour les applications fournies par GitLab. Auparavant, l'expérience utilisateur était identique, qu'une application soit fournie par GitLab ou non. Cette nouvelle fonctionnalité offre une couche de confiance supplémentaire.

### Configuration simplifiée de l'administrateur de l'instance {#streamlined-instance-administrator-setup}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/458985)

{{< /details >}}

L'expérience de configuration de l'administrateur pour une nouvelle installation de GitLab a été simplifiée et sécurisée. L'adresse e-mail root initiale de l'administrateur est désormais aléatoire, et les administrateurs sont contraints de modifier cette adresse e-mail pour un compte auquel ils peuvent accéder. Auparavant, cette étape pouvait être reportée et un administrateur pouvait oublier de modifier l'adresse e-mail.

### API utilisateur ajoutée au connecteur de données Snowflake {#user-api-added-to-the-snowflake-data-connector}

<!-- categories: Audit Events, Compliance Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../integration/snowflake.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13004)

{{< /details >}}

Dans GitLab 17.2, nous avons ajouté la prise en charge de l'[API Utilisateurs](../../api/users.md#list-all-users) au [connecteur de données GitLab](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector), disponible dans l'application Snowflake Marketplace. Vous pouvez désormais diffuser des données utilisateur depuis des instances GitLab auto-hébergées vers Snowflake à l'aide de l'API Utilisateurs.

### Configuration simplifiée pour l'intégration Google Cloud {#simplified-setup-for-google-cloud-integration}

<!-- categories: System Access -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../tutorials/set_up_gitlab_google_integration/_index.md#secure-your-usage-with-google-cloud-identity-and-access-management-iam) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/454343)

{{< /details >}}

Les commandes Google Cloud CLI sont désormais disponibles nativement lors de la configuration de la fédération d'identités de charge de travail pour l'intégration Google Cloud IAM. Auparavant, la configuration guidée utilisait un script téléchargé via des commandes cURL. De plus, un texte d'aide a été ajouté pour mieux décrire le processus de configuration. Ces améliorations aident les propriétaires de groupes à configurer l'intégration Google Cloud IAM plus rapidement.

### Champs séparés pour le titre et le chemin des pages wiki {#separate-wiki-page-title-and-path-fields}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/wiki/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)

{{< /details >}}

Dans GitLab 17.2, les titres des pages wiki sont séparés de leurs chemins. Dans les versions précédentes, si le titre d'une page changeait, le chemin changeait également, ce qui pouvait entraîner la rupture des liens vers cette page. Désormais, si le titre d'une page wiki change, le chemin reste inchangé. Même si le chemin d'une page wiki change, une redirection automatique est mise en place pour éviter les liens rompus.

### Améliorations de la barre latérale du wiki {#improvements-to-the-wiki-sidebar}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/wiki/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/281570)

{{< /details >}}

GitLab 17.2 apporte plusieurs améliorations à la façon dont les wikis affichent la barre latérale. Désormais, un wiki affiche toutes les pages dans la barre latérale (jusqu'à 5 000 pages), affiche une table des matières (TDM) et fournit une barre de recherche pour trouver rapidement des pages.

Auparavant, la barre latérale ne disposait pas de TDM, ce qui rendait difficile la navigation vers les sections d'une page. La nouvelle fonctionnalité TDM permet de visualiser clairement la structure de la page et de naviguer rapidement vers différentes sections, améliorant considérablement l'utilisabilité.

L'ajout d'une barre de recherche facilite la découverte de contenu. Et parce que la barre latérale affiche désormais toutes les pages, vous pouvez parcourir aisément l'intégralité d'un wiki.

### Documenter les modules dans le registre de modules Terraform {#document-modules-in-the-terraform-module-registry}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/packages/terraform_module_registry/_index.md#view-terraform-modules) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/451054)

{{< /details >}}

Le registre de modules Terraform affiche désormais les fichiers Readme ! Grâce à cette fonctionnalité très demandée, vous pouvez documenter de manière transparente l'objectif, la configuration et les exigences de chaque module.

Auparavant, vous deviez rechercher ces informations critiques dans d'autres sources, ce qui rendait difficile l'évaluation et l'utilisation correctes des modules. Désormais, avec la documentation du module facilement accessible, vous pouvez rapidement comprendre les capacités d'un module avant de l'utiliser. Cette accessibilité vous permet de partager et de réutiliser en toute confiance le code Terraform au sein de votre organisation.

### Ajouter un attribut de type au webhook d'événements de tickets {#add-type-attribute-to-issues-events-webhook}

<!-- categories: Team Planning, Notifications, Incident Management, Service Desk -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhook_events.md#work-item-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/467415)

{{< /details >}}

Les tickets, les tâches, les incidents, les exigences, les objectifs et les résultats clés déclenchent tous des charges utiles dans la catégorie de webhook **Issues Events**. Jusqu'à présent, il n'existait aucun moyen de déterminer rapidement le type d'objet qui a déclenché le webhook dans la charge utile de l'événement. Cette release introduit un attribut `object_attributes.type` disponible sur les charges utiles des déclencheurs **Issues events**, **Commentaires**, **Confidential issues events** et **Événements en lien avec les émojis**.

### GitLab Advanced SAST disponible en version bêta pour Go, Java et Python {#gitlab-advanced-sast-available-in-beta-for-go-java-and-python}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

GitLab Advanced SAST est désormais disponible en tant que fonctionnalité en version bêta pour les clients Ultimate. Advanced SAST utilise une analyse inter-fichiers et inter-fonctions pour produire des résultats de meilleure qualité. Il prend désormais en charge Go, Java et Python.

Durant la phase bêta, nous recommandons d'exécuter Advanced SAST dans des projets de test, sans remplacer les analyseurs SAST existants. Pour activer Advanced SAST, consultez les [instructions](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast). À compter de GitLab 17.2, Advanced SAST est inclus dans le [modèle CI/CD `SAST.latest`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml).

Cela fait partie de notre [intégration itérative de la technologie Oxeye](https://about.gitlab.com/blog/oxeye-joins-gitlab-to-advance-application-security-capabilities/). Dans les prochaines releases, nous prévoyons de faire passer Advanced SAST en disponibilité générale, d'ajouter la prise en charge d'[autres langages](https://gitlab.com/groups/gitlab-org/-/epics/14312) et d'introduire de nouveaux éléments d'interface utilisateur pour tracer le flux des vulnérabilités. Nous accueillons tous vos retours de test dans le [ticket 466322](https://gitlab.com/gitlab-org/gitlab/-/issues/466322).

### API Security Testing prend désormais en charge les requêtes d'authentification signées {#api-security-testing-now-supports-signed-authentication-requests}

<!-- categories: API Security -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/api_security_testing/configuration/variables.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/458825)

{{< /details >}}

API Security dispose déjà d'une prise en charge des « overrides » qui peuvent modifier les requêtes envoyées par le scanner. Cependant, ces overrides doivent être définis à l'avance et ne peuvent pas changer en fonction de la requête elle-même. GitLab 17.2 ajoute un « script par requête » (`APISEC_PER_REQUEST_SCRIPT`), qui permet à un utilisateur de fournir un script C# appelé avant l'envoi de chaque requête. Cela permet de « signer » la requête avec un secret comme forme d'authentification.

### Container Scanning : prise en charge des systèmes d'exploitation pour le scan continu des vulnérabilités {#container-scanning-continuous-vulnerability-scanning-os-support}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/container_scanning/continuous_container_scanning/_index.md#supported-package-types) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/10174)

{{< /details >}}

Suite au MVC du scan continu des vulnérabilités pour le Container Scanning, nous avons ajouté durant la version 17.2 la prise en charge des versions de packages de systèmes d'exploitation APK et RPM.

Cette amélioration permet à notre analyseur de prendre entièrement en charge les scans continus de vulnérabilités pour les avis de Container Scanning en comparant les versions de packages pour les types purl de systèmes d'exploitation [APK](https://gitlab.com/gitlab-org/gitlab/-/issues/428703) et [RPM](https://gitlab.com/gitlab-org/gitlab/-/issues/428941).

À noter que les versions RPM contenant un caret (`^`) ne sont pas prises en charge. Le travail de prise en charge de ces versions est suivi dans ce [ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/459969).

### Mises à jour de l'analyseur DAST {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/checks/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/13411)

{{< /details >}}

Au cours du jalon de la release 17.2, nous avons publié les mises à jour suivantes.

1. Nous avons ajouté trois nouvelles vérifications :

- La vérification 506.1 est une vérification passive qui identifie les URL de requêtes susceptibles d'être compromises par la prise de contrôle du CDN Polyfill.io.
- La vérification 384.1 est une vérification passive qui identifie les failles de fixation de session, lesquelles pourraient permettre à des acteurs malveillants de réutiliser un identifiant de session valide.
- La vérification 16.11 est une vérification active qui identifie si la méthode de débogage HTTP TRACE est activée sur un serveur de production, ce qui pourrait exposer par inadvertance des informations sensibles.

1. Nous avons traité les bugs suivants pour réduire les faux positifs :

- Les vérifications DAST 614.1 (Cookie sensible sans attribut Secure) et 1004.1 (Cookie sensible sans attribut HttpOnly) ne créent plus de résultats lorsqu'un site a effacé un cookie en définissant une date d'expiration dans le passé.
- La vérification DAST 1336.1 (Server-Side Template Injection) ne s'appuie plus sur un code de statut HTTP 500 pour déterminer le succès d'une attaque.

1. Nous avons ajouté les améliorations suivantes :

- Tous les en-têtes de réponse sont désormais présentés comme preuves dans un résultat de vulnérabilité DAST. Ce contexte supplémentaire réduit le temps consacré au tri des résultats.
- Les fichiers Sitemap.xml sont désormais explorés pour trouver des URL supplémentaires, ce qui améliore la couverture des sites web cibles.

### API Fuzz Testing prend désormais en charge les requêtes d'authentification signées {#api-fuzz-testing-now-supports-signed-authentication-requests}

<!-- categories: Fuzz Testing -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/api_fuzzing/configuration/variables.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/458825)

{{< /details >}}

API Fuzzing dispose déjà d'une prise en charge des « overrides » qui peuvent modifier les requêtes envoyées par le scanner. Cependant, ces overrides doivent être définis à l'avance et ne peuvent pas changer en fonction de la requête elle-même. GitLab 17.2 ajoute un « script par requête » (`FUZZAPI_PER_REQUEST_SCRIPT`), qui permet à un utilisateur de fournir un script C# appelé avant l'envoi de chaque requête. Cela permet de « signer » la requête avec un secret comme forme d'authentification.

### La protection contre les push de secrets désormais disponible pour les instances auto-hébergées, et des avertissements améliorés en cas de fuites potentielles {#secret-push-protection-now-available-for-self-managed-and-improved-warnings-of-potential-leaks}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13107)

{{< /details >}}

Au cours du jalon de la release 17.2, nous avons publié les mises à jour suivantes :

- La version bêta de la protection contre les push de secrets est désormais disponible pour les clients auto-hébergés. Après qu'un administrateur [active la fonctionnalité à l'échelle de l'instance](../../user/application_security/secret_detection/secret_push_protection/_index.md#allow-the-use-of-secret-push-protection-in-your-gitlab-instance), suivez notre documentation pour [activer la protection contre les push](../../user/application_security/secret_detection/secret_push_protection/_index.md#enable-secret-push-protection-in-a-project) sur vos projets.
- Les [avertissements relatifs aux fuites potentielles dans le contenu textuel](../../user/application_security/secret_detection/client/_index.md) ont été enrichis de plus de détails, facilitant la compréhension du type de secret sur le point d'être divulgué dans une description ou un commentaire dans un ticket, un epic ou une merge request.

### Options de tri pour les planifications de pipeline {#sort-options-for-pipeline-schedules}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/schedules.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/37246)

{{< /details >}}

Vous pouvez désormais trier la liste des planifications de pipeline par description, ref, prochaine exécution, date de création et date de mise à jour.

### `rules:changes:compare_to` prend désormais en charge les variables CI/CD {#ruleschangescompare_to-now-supports-cicd-variables}

<!-- categories: Pipeline Composition, Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#ruleschangescompare_to) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/369916)

{{< /details >}}

Dans GitLab 15.3, nous avons introduit le [mot-clé `compare_to`](../../ci/yaml/_index.md#ruleschangescompare_to) pour `rules:change`. Cela permettait de définir la ref exacte à comparer. À partir de GitLab 17.2, vous pouvez désormais utiliser des variables CI/CD avec ce mot-clé, ce qui facilite la définition et la réutilisation des valeurs `compare_to` dans plusieurs jobs.

### GitLab Runner 17.2 {#gitlab-runner-172}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions GitLab Runner 17.2 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Plugin fleeting de GitLab Runner pour les instances AWS EC2 (disponibilité générale)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29222)
- [Autoriser la configuration de `livenessProbe` et `readinessProbe` du Runner](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/545)
- [Possibilité d'activer et de désactiver la commande `umask 0000` pour l'exécuteur Kubernetes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28867)
- [Prise en charge de Red Hat OpenShift 4.16 pour l'opérateur GitLab Runner](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/203)

#### Corrections de bugs {#bug-fixes}

- [La mise à niveau de GitLab Runner supprime tous les volumes de cache](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30876)

Pour obtenir la liste de toutes les modifications, consultez le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-2-stable/CHANGELOG.md) de GitLab Runner.

### Nouvelle stratégie d'autorisation d'agent pour les workspaces {#new-agent-authorization-strategy-for-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

Avec cette release, nous avons mis en œuvre une nouvelle stratégie d'autorisation pour les workspaces afin de remédier aux limitations de la stratégie héritée tout en offrant aux propriétaires de groupes et aux administrateurs plus de contrôle et de flexibilité. Avec la nouvelle stratégie d'autorisation, les propriétaires de groupes et les administrateurs peuvent contrôler quels agents de cluster utiliser pour héberger les workspaces.

Pour assurer une transition en douceur, les utilisateurs ayant recours à l'ancienne stratégie d'autorisation sont migrés automatiquement vers la nouvelle stratégie. Les agents existants qui prennent en charge les workspaces sont automatiquement autorisés dans le groupe racine où ces agents sont situés. Cette migration se produit également si ces agents ont été autorisés dans différents groupes au sein d'un groupe racine.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.2)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.2)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.2)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
