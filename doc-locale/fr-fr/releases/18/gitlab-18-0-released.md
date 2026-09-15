---
stage: Release Notes
group: Monthly Release
date: 2025-05-15
title: "Notes de release de GitLab 18.0"
description: "GitLab 18.0 publié avec GitLab Premium et Ultimate with Duo"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 15 mai 2025, GitLab 18.0 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Michael Hofer {#this-months-notable-contributor-michael-hofer}

Michael Hofer défend la mission open source de GitLab en tant que contributeur de premier plan et leader de la communauté. Avec plus de [50 contributions](https://contributors.gitlab.com/users/karras?fromDate=2025-01-01&toDate=2025-05-12) cette année, ses travaux ont renforcé les fonctionnalités Geo de GitLab et le Secrets Manager, basé sur OpenBao. Il a remporté le [Hackathon d'avril](https://contributors.gitlab.com/hackathon?hackathonName=2025_04) tout en soutenant d'autres contributeurs et en dirigeant des projets communautaires.

« J'apprécie vraiment que tout le monde puisse contribuer à GitLab ! » déclare Michael. « L'équipe est formidable, c'est très amusant, et tout le monde est super serviable, surtout quand nous collaborons sur des initiatives open source comme OpenBao et SLSA. »

Michael est le CTO chez [Adfinis](https://adfinis.com/en/), un prestataire de services informatiques international spécialisé dans la planification, la création et l'exploitation de charges de travail open source critiques. Il est passionné par le développement de la collaboration et la promotion des solutions open source au sein des organisations.

Récemment, Adfinis a participé au [programme Co-Create](https://about.gitlab.com/community/co-create/) de GitLab, qui associe des organisations aux équipes produit et ingénierie de GitLab pour construire GitLab ensemble. « Nous recommandons vivement Co-Create à toutes les organisations », déclare Michael. « Cela a conduit à un certain nombre de contributions intéressantes, notamment des builds Podman sans root, la coloration syntaxique Glimmer et d'autres améliorations. »

« L'équipe Geo apprécie vraiment et prend plaisir à travailler avec Michael », déclare [Lucie Zhao](https://gitlab.com/luciezhao), Engineering Manager chez GitLab, qui a nominé Michael pour cette récompense. « Grâce à ses excellentes contributions au cours des derniers jalons, il est devenu le contributeur communautaire le plus connu au sein de notre équipe. »

Les membres de l'équipe GitLab [Lee Tickett](https://gitlab.com/leetickett-gitlab), [Chloe Fons](https://gitlab.com/c_fons) et [Alex Scheel](https://gitlab.com/cipherboy-gitlab) ont soutenu la nomination. Alex ajoute : « Le leadership de Michael au sein d'OpenBao nous a permis de collaborer efficacement pour proposer une solution de gestion des secrets à nos clients, avec la transparence qui s'aligne sur nos valeurs GitLab. »

Merci à Michael et à l'équipe Adfinis pour leur co-création de GitLab !

## Fonctionnalités principales {#primary-features}

### GitLab Premium et Ultimate with Duo {#gitlab-premium-and-ultimate-with-duo}

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)

{{< /details >}}

Nous sommes ravis d'annoncer GitLab Premium with Duo et GitLab Ultimate with Duo. GitLab Premium et Ultimate incluent désormais des fonctionnalités natives d'IA.

Les fonctionnalités natives d'IA de GitLab comprennent Code Suggestions et Chat au sein de l'IDE. Les équipes de développement peuvent utiliser ces fonctionnalités pour :

- Analyser, comprendre et expliquer le code
- Écrire du code sécurisé plus rapidement
- Générer rapidement des tests pour maintenir la qualité du code
- Refactoriser facilement le code pour améliorer les performances ou utiliser des bibliothèques spécifiques

### Repository X-Ray désormais disponible sur GitLab Duo Self-Hosted {#repository-x-ray-now-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/project/repository/code_suggestions/repository_xray.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17756)

{{< /details >}}

Vous pouvez désormais utiliser Repository X-Ray avec Code Suggestions sur GitLab Duo Self-Hosted. Cette fonctionnalité est en version bêta pour GitLab Duo Self-Hosted, et est généralement disponible sur les instances GitLab Self-Managed.

### Revues automatiques avec Duo Code Review {#automatic-reviews-with-duo-code-review}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Review fournit des informations précieuses durant le processus de revue, mais nécessite actuellement de demander manuellement des revues sur chaque merge request.

Vous pouvez désormais configurer GitLab Duo Code Review pour s'exécuter automatiquement sur les merge requests en mettant à jour les paramètres de merge request de votre projet. Lorsqu'elle est activée, Duo Code Review révise automatiquement les merge requests, sauf si :

- La merge request est marquée comme brouillon.
- La merge request ne contient aucune modification.

Les revues automatiques garantissent que tout le code de votre projet fait l'objet d'une revue, améliorant ainsi la qualité du code de manière cohérente dans toute votre base de code.

### Mise en cache des prompts de Code Suggestions {#code-suggestions-prompt-caching}

<!-- categories: Code Suggestions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/project/repository/code_suggestions/_index.md#prompt-caching) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17489)

{{< /details >}}

Code Suggestions inclut désormais la mise en cache des prompts. La mise en cache des prompts améliore considérablement la latence de complétion du code en évitant le retraitement des données de prompt et d'entrée mises en cache. Les données mises en cache ne sont jamais enregistrées dans un stockage persistant, et vous pouvez éventuellement désactiver la mise en cache des prompts dans les paramètres GitLab Duo.

### Contexte amélioré pour Duo Code Review {#improved-duo-code-review-context}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Review fournit désormais un contexte plus complet pour une analyse améliorée. Les principales améliorations sont :

- Inclut le titre et la description d'une merge request pour mieux comprendre l'objectif des modifications proposées.
- Examine tous les diffs simultanément pour identifier les relations entre fichiers et réduire les faux positifs.
- Fournit le contenu complet des fichiers modifiés pour comprendre comment les modifications s'intègrent dans les modèles de code existants.

Ces améliorations réduisent les suggestions inexactes et produisent des revues de code plus pertinentes et de meilleure qualité.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Lister uniquement les utilisateurs Enterprise pour la réattribution des contributions sur GitLab.com {#list-only-enterprise-users-for-contributions-reassignment-on-gitlabcom}

<!-- categories: Importers -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/direct_transfer_migrations.md#user-membership-mapping) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/510673)

{{< /details >}}

Dans cette release, nous avons amélioré l'expérience de mappage des utilisateurs fictifs en limitant la liste déroulante de sélection des utilisateurs aux seuls utilisateurs Enterprise associés au groupe principal. Précédemment, lors de la réattribution des contributions des utilisateurs après une importation vers GitLab.com, vous voyiez dans la liste déroulante tous les utilisateurs actifs sur la plateforme, ce qui rendait difficile l'identification du bon utilisateur, en particulier lorsque le provisionnement SCIM avait modifié les noms d'utilisateur. Désormais, si votre groupe principal utilise la fonctionnalité des utilisateurs Enterprise, la liste déroulante n'affichera que les utilisateurs revendiqués par votre organisation, réduisant ainsi considérablement les risques d'erreurs lors de la réattribution des utilisateurs. Le même périmètre est également appliqué à la réattribution basée sur CSV, empêchant toute attribution accidentelle à des utilisateurs extérieurs à votre organisation.

### Prise en charge de plusieurs workspaces dans l'application GitLab pour Slack {#support-for-multiple-workspaces-in-the-gitlab-for-slack-app}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/424190)

{{< /details >}}

L'application GitLab pour Slack prend désormais en charge plusieurs workspaces pour les clients GitLab Self-Managed et GitLab Dedicated. La prise en charge de plusieurs workspaces permet aux organisations disposant d'environnements Slack fédérés de maintenir des intégrations GitLab fluides dans l'ensemble de leurs workspaces. Pour activer la prise en charge de plusieurs workspaces, configurez l'application GitLab pour Slack en tant qu'[application distribuée non répertoriée](https://api.slack.com/distribution#unlisted-distributed-apps).

### Suppression des groupes et des utilisateurs fictifs {#delete-groups-and-placeholder-users}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/import/mapping/post_migration_mapping.md#placeholder-user-deletion) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/473256)

{{< /details >}}

Dans GitLab 18.0, lorsque vous supprimez un groupe principal, les utilisateurs fictifs associés au groupe sont également supprimés. Si des utilisateurs fictifs sont associés à d'autres projets, ils sont uniquement retirés du groupe principal. Ainsi, les utilisateurs fictifs inutiles sont supprimés sans perturber l'historique ou les attributions des autres projets.

### Releases internes disponibles pour GitLab Dedicated {#internal-releases-available-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](https://handbook.gitlab.com/handbook/engineering/releases/internal-releases/) \| [Epic associé](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1201)

{{< /details >}}

Les clients GitLab Dedicated soumis à des exigences de sécurité strictes et à des obligations de conformité nécessitent le plus haut niveau de protection pour leurs environnements de développement. Nous introduisons aujourd'hui les Internal Releases, une nouvelle release privée qui nous permet de remédier aux vulnérabilités critiques des instances GitLab Dedicated avant leur divulgation publique, garantissant ainsi que les clients GitLab Dedicated n'y sont jamais exposés. Cette nouvelle capacité offre une protection immédiate contre les vulnérabilités critiques trouvées dans GitLab, en parallèle de la réponse pour GitLab.com. Ce nouveau processus ne nécessite aucune action de la part du client.

### Le chart GitLab 9.0 publié avec des changements majeurs {#gitlab-chart-90-released-with-breaking-changes}

<!-- categories: Cloud Native Installation, Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/charts/releases/9_0/) \| [Ticket associé](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5927)

{{< /details >}}

- [Changement majeur](../../update/deprecations.md#postgresql-14-and-15-no-longer-supported) : La prise en charge de PostgreSQL 14 et 15 a été supprimée. Assurez-vous d'exécuter PostgreSQL 16 avant de procéder à la mise à niveau.
- [Changement majeur](../../update/deprecations.md#major-update-of-the-prometheus-subchart) : Le chart Prometheus intégré a été mis à jour de la version 15.3 à la version 27.11. Parallèlement à la mise à niveau du chart Prometheus, la version de Prometheus a été mise à jour de 2.38 à 3.0. Des étapes manuelles sont nécessaires pour effectuer la mise à niveau. Si Alertmanager, Node Exporter ou Pushgateway est activé, vous devez également mettre à jour vos valeurs Helm. Pour plus d'informations, consultez le [guide de migration](https://docs.gitlab.com/charts/releases/9_0.html#prometheus-upgrade).
- [Changement majeur](../../update/deprecations.md#fallback-support-for-gitlab-nginx-chart-controller-image-v131) : l'image du contrôleur NGINX par défaut a été mise à jour de la version 1.3.1 vers la version 1.11.2. Si vous utilisez le chart GitLab NGINX et que vous avez défini vos propres règles NGINX RBAC, de nouvelles règles RBAC doivent exister. Pour plus d'informations, consultez le [guide de mise à niveau](https://docs.gitlab.com/charts/releases/8_0/#upgrade-to-86x-851-843-836).

### Collecte de données d'événements {#event-data-collection}

<!-- categories: Application Instrumentation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/settings/event_data.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)

{{< /details >}}

Dans GitLab 18.0, nous activons la collecte de données d'utilisation des produits au niveau des événements depuis les instances GitLab Self-Managed et GitLab Dedicated. Contrairement aux données agrégées, les données au niveau des événements fournissent à GitLab des informations plus approfondies sur l'utilisation, nous permettant d'améliorer l'expérience utilisateur sur la plateforme et d'augmenter l'adoption des fonctionnalités. Pour des instructions détaillées sur la façon d'ajuster les paramètres de partage des données, veuillez consulter notre documentation.

### Protection contre la suppression disponible pour tous les utilisateurs {#deletion-protection-available-for-all-users}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../administration/settings/visibility_and_access_controls.md#deletion-protection) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/17208) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/526405)

{{< /details >}}

La suppression différée de projets et de groupes est désormais disponible pour tous les utilisateurs GitLab, y compris ceux de notre édition Gratuite. Cette fonctionnalité de sécurité essentielle ajoute une période de grâce (7 jours sur GitLab.com) avant que les groupes et projets supprimés ne soient définitivement retirés. Cette fonctionnalité permet de récupérer des suppressions accidentelles sans opérations de récupération complexes.

En faisant de la sécurité des données une fonctionnalité centrale, GitLab contribue à mieux protéger votre travail contre les événements de perte de données.

### Suppression différée de projets pour les espaces de nommage utilisateur {#delayed-project-deletion-for-user-namespaces}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/working_with_projects.md#delete-a-project) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/536244)

{{< /details >}}

La suppression différée de projets est désormais disponible pour les projets dans les espaces de nommage utilisateur (projets personnels). Auparavant, cette protection contre la perte de données accidentelle n'était disponible que pour les espaces de nommage de groupe. Lorsque vous supprimez un projet dans votre espace de nommage utilisateur, il entre désormais dans un état « suppression en attente » pour la durée configurée dans les paramètres de votre instance (7 jours sur GitLab.com), plutôt que d'être immédiatement supprimé. Cela crée une fenêtre de récupération pendant laquelle vous pouvez restaurer le projet si nécessaire.

Nous espérons que cette amélioration vous apportera une plus grande tranquillité d'esprit lors de la gestion de vos projets personnels dans GitLab.

### Nouveau paramètre `active` pour les API REST Groupes et Projets {#new-active-parameter-for-groups-and-projects-rest-apis}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../api/projects.md#list-projects)

{{< /details >}}

Nous avons ajouté un nouveau paramètre `active` à nos API REST Groupes et Projets qui simplifie le filtrage des groupes en fonction de leur statut. Lorsqu'il est défini sur `true`, seuls les groupes ou projets non archivés et non marqués pour suppression sont retournés. Lorsqu'il est défini sur `false`, seuls les groupes ou projets archivés ou marqués pour suppression sont retournés. Si le paramètre est indéfini, aucun filtrage n'est appliqué. Cette amélioration vous aide à gérer efficacement vos workflows en ciblant des statuts spécifiques via de simples appels API.

Merci à [@dagaranupam](https://gitlab.com/dagaranupam) pour l'ajout de ce paramètre à l'API Projets.

### Limites de débit pour l'API Groupes, Projets et Utilisateurs {#rate-limits-for-groups-projects-and-users-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)

{{< /details >}}

Nous avons ajouté des limites de débit API pour les projets, les groupes et les utilisateurs afin d'améliorer la stabilité et les performances de la plateforme pour tous les utilisateurs. Ces modifications font suite à l'augmentation du trafic API qui affectait nos services.

Les limites ont été soigneusement définies en fonction des modèles d'utilisation moyens et devraient offrir une capacité suffisante pour la plupart des cas d'utilisation. Si vous dépassez ces limites, vous recevrez une réponse « 429 Too Many Requests ».

Pour des informations complètes sur les limites de débit spécifiques et leur implémentation, veuillez [lire l'article de blog associé](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/).

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Les scanners de sécurité prennent désormais en charge les pipelines MR {#security-scanners-now-support-mr-pipelines}

<!-- categories: API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/detect/roll_out_security_scanning.md)

{{< /details >}}

Vous pouvez désormais choisir d'exécuter des [scanners AST (Application Security Testing)](../../user/application_security/detect/_index.md) dans des [pipelines de merge request (MR)](../../ci/pipelines/merge_request_pipelines.md). Pour minimiser l'impact sur vos pipelines, il s'agit d'un comportement optionnel que vous pouvez contrôler.

Auparavant, le comportement par défaut dépendait de l'utilisation de l'[édition de template CI/CD Stable ou Latest](../../user/application_security/detect/security_configuration.md#template-editions) pour activer un scanner :

- Dans les templates Stable, les jobs de scan s'exécutaient uniquement dans les pipelines de branche. Les pipelines MR n'étaient pas pris en charge.
- Dans les templates Latest, les jobs de scan s'exécutaient dans les pipelines MR lorsqu'une MR était ouverte, et dans les pipelines de branche en l'absence de MR associée. Vous ne pouviez pas contrôler ce comportement.

Désormais, une nouvelle option, `AST_ENABLE_MR_PIPELINES`, vous permet de contrôler l'exécution des jobs dans les pipelines MR. Le comportement par défaut pour les templates Stable et Latest reste inchangé. Plus précisément :

- Les templates Stable continuent d'exécuter les jobs de scan dans les pipelines de branche par défaut, mais vous pouvez définir `AST_ENABLE_MR_PIPELINES: "true"` pour utiliser les pipelines MR à la place lorsqu'une MR est ouverte.
- Les templates Latest continuent d'exécuter les jobs de scan dans les pipelines MR par défaut lorsqu'une MR est ouverte, mais vous pouvez définir `AST_ENABLE_MR_PIPELINES: "false"` pour utiliser les pipelines de branche à la place.

Cette amélioration concerne tous les templates de scan de sécurité, à l'exception de l'API Discovery (`API-Discovery.gitlab-ci.yml`), qui utilise actuellement les pipelines MR par défaut. Nous avons également modifié le template API Discovery pour l'aligner sur les autres templates Stable dans GitLab 18.0 et utiliser les pipelines de branche par défaut.

### Afficher et filtrer les projets archivés dans le rapport de conformité des projets {#display-and-filter-archived-projects-in-the-compliance-projects-report}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : Ultimate, Premium
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md#filter-the-compliance-projects-report) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/500520)

{{< /details >}}

Dans le rapport de conformité des projets, vous pouvez consulter les frameworks de conformité appliqués aux projets au sein d'un groupe ou d'un sous-groupe.

Cependant, le rapport ne permettait pas d'indiquer si un projet est archivé ou non, ce qui pourrait être une information utile pour gérer la conformité entre les projets actifs et archivés.

C'est pourquoi nous avons ajouté un indicateur pour signaler si un projet est archivé. Cela vous offrira une meilleure visibilité et un meilleur contexte lors de la vérification des frameworks de conformité sur les projets actifs et archivés.

Cette fonctionnalité comprend :

- Un badge de statut archivé pour chaque projet dans le rapport de conformité des projets afin d'indiquer si un projet est archivé.
- Un filtre permettant de basculer entre les projets archivés, non archivés ou tous les projets.

### Créer un workspace à partir de merge requests {#create-a-workspace-from-merge-requests}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/workspace/configuration.md#create-a-workspace)

{{< /details >}}

Vous pouvez désormais créer un workspace directement depuis une merge request grâce à la nouvelle option **Ouvrir dans l'espace de travail**. Cette fonctionnalité configure automatiquement un workspace avec la branche et le contexte de la merge request, vous permettant de :

- Examiner les modifications de code dans un environnement entièrement configuré.
- Exécuter des tests sur la branche de la merge request pour vérifier la fonctionnalité.
- Apporter des modifications supplémentaires à la merge request sans configuration locale.

### Afficher les merge requests ouvertes ciblant des fichiers {#view-open-merge-requests-targeting-files}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/repository/files/_index.md#view-open-merge-requests-for-a-file) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/448868)

{{< /details >}}

Auparavant, lors du travail sur des fichiers de code, vous n'aviez aucune visibilité sur qui d'autre pourrait modifier le même fichier dans d'autres branches. Ce manque de visibilité entraînait des conflits de merge, des travaux dupliqués et une collaboration inefficace.

Vous pouvez désormais identifier facilement toutes les merge requests ouvertes qui modifient le fichier que vous consultez dans le dépôt. Cette fonctionnalité vous aide à :

- Identifier les conflits de merge potentiels avant qu'ils ne surviennent.
- Éviter de dupliquer un travail déjà en cours.
- Améliorer la collaboration en offrant une visibilité sur les modifications en cours.

Un badge affiche le nombre de merge requests ouvertes modifiant le fichier, et survoler ce badge révèle une fenêtre contextuelle avec la liste de ces merge requests.

### Espace de nommage Kubernetes partagé pour les workspaces {#shared-kubernetes-namespace-for-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/workspace/settings.md#shared_namespace)

{{< /details >}}

Vous pouvez désormais créer des workspaces GitLab dans un espace de nommage Kubernetes partagé. Cela supprime la nécessité de créer un nouvel espace de nommage pour chaque workspace et élimine l'obligation d'accorder des permissions ClusterRole élevées à l'agent. Grâce à cette fonctionnalité, vous pouvez adopter plus facilement les workspaces dans des environnements sécurisés ou restreints, offrant ainsi une voie plus simple vers la scalabilité.

Pour activer les espaces de nommage partagés, définissez le champ `shared_namespace` dans votre fichier de configuration d'agent pour spécifier l'espace de nommage Kubernetes que vous souhaitez utiliser pour tous les workspaces.

Merci à la demi-douzaine de contributeurs de la communauté qui ont contribué à la création de cette fonctionnalité grâce au [programme Co-Create de GitLab](https://about.gitlab.com/community/co-create/) !

### Visualisations améliorées du statut des pods dans le tableau de bord Kubernetes {#improved-pod-status-visualizations-in-the-dashboard-for-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/525081)

{{< /details >}}

Vous pouvez utiliser le tableau de bord Kubernetes pour surveiller vos applications déployées. Jusqu'à présent, les pods présentant des erreurs de conteneur telles que `CrashLoopBackOff` ou `ImagePullBackOff` s'affichaient avec un statut « Pending » ou « Running », ce qui rendait difficile l'identification des déploiements problématiques sans utiliser `kubectl`.

Dans GitLab 18.0, les états d'erreur dans l'interface utilisateur affichent le statut d'un conteneur spécifique, similaire à la sortie de `kubectl`. Désormais, vous pouvez rapidement identifier et résoudre les problèmes des pods défaillants sans quitter l'interface GitLab.

### Exclure des packages des règles d'approbation de licences {#exclude-packages-from-license-approval-rules}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10203)

{{< /details >}}

Dans les politiques d'approbation des merge requests, cette nouvelle amélioration des politiques d'approbation de licences offre aux équipes juridiques et de conformité un meilleur contrôle sur les packages pouvant utiliser des licences spécifiques. Vous pouvez désormais créer des exceptions pour les packages pré-approuvés, même lorsqu'ils utilisent des licences qui seraient normalement bloquées par les politiques de votre organisation.

Auparavant, dans les politiques d'approbation de licences, si vous bloquiez une licence comme AGPL-3.0, elle était bloquée pour tous les packages de votre organisation. Cela créait des difficultés lorsque :

- Votre équipe juridique avait pré-approuvé des packages spécifiques avec des licences autrement restreintes.
- Vous deviez utiliser le même package dans des centaines de projets.
- Différentes équipes nécessitaient des exceptions de licence différentes.

Avec cette release, vous pouvez maintenir une gouvernance stricte des licences tout en autorisant les exceptions nécessaires, réduisant ainsi considérablement les goulots d'étranglement des approbations et les révisions manuelles. Par exemple, vous pouvez :

- Définir des exceptions spécifiques aux packages dans vos règles d'approbation de licences en utilisant le format Package URL (PURL).
- Autoriser des packages spécifiques (ou des versions de packages) à utiliser des licences autrement restreintes.
- Bloquer des packages spécifiques (ou des versions de packages) de l'utilisation de licences généralement autorisées.

Pour ajouter des exceptions, suivez ce workflow lors de la création ou de la modification d'une politique d'approbation de licences :

1. Dans votre groupe, accédez à **Security & Compliance** > **Politiques**
1. Créez ou modifiez une politique d'approbation de licences.
1. Trouvez les nouvelles options d'exception de package dans l'éditeur visuel ou configurez-les en mode YAML.
1. Choisissez entre le mode liste d'autorisation ou liste de refus pour les licences.
1. Ajoutez des licences spécifiques à votre politique.
1. Pour chaque licence, définissez des exceptions de package au format PURL (par exemple, `pkg:npm/@angular/animation@12.3.1`).
1. Spécifiez si vous souhaitez inclure ou exclure ces packages de la règle de licence.

La politique applique alors vos règles de licence tout en respectant les exceptions définies, vous offrant un contrôle granulaire sur la conformité des licences dans toute votre organisation.

### Limiter la durée maximale des sessions utilisateur {#limit-maximum-user-session-length}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../administration/settings/account_and_limit_settings.md#set-sessions-to-expire-from-creation-date) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/395038)

{{< /details >}}

Les administrateurs peuvent désormais choisir si la durée maximale d'une session utilisateur est calculée à partir de la connexion initiale ou de la dernière activité. Les utilisateurs sont informés que la session se termine, mais ne peuvent pas empêcher l'expiration de la session ni la prolonger. Cette fonctionnalité est désactivée par défaut.

Merci à [John Parent](https://gitlab.kitware.com/john.parent) pour votre contribution !

### Améliorations des vues GitLab Query Language {#gitlab-query-language-views-enhancements}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/glql/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

Nous avons apporté des améliorations significatives aux vues GitLab Query Language (GLQL). Ces améliorations comprennent la prise en charge de :

- Les opérateurs `>=` et `<=` pour tous les types de date
- La liste déroulante **View actions** dans les vues
- L'action **Recharger**
- Les alias de champs
- L'attribution d'alias personnalisés aux colonnes dans les tableaux GLQL

Nous accueillons vos retours sur cette amélioration, et sur les vues GLQL en général, dans le [ticket 509791](https://gitlab.com/gitlab-org/gitlab/-/issues/509791).

### Améliorations des templates Pages {#pages-template-improvements}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/project/pages/getting_started/pages_new_project_template.md#project-templates)

{{< /details >}}

GitLab fournit des [templates pour les générateurs de sites statiques populaires](https://gitlab.com/pages). Nous avons effectué une analyse approfondie des templates disponibles à l'aide d'un cadre de notation, et affiné la liste pour n'inclure que les templates les plus populaires.

L'affinement des templates disponibles pour GitLab Pages simplifie le processus de création de sites web. Utilisez les templates pour lancer des sites à l'aspect professionnel avec une expertise technique minimale. Les templates améliorés offrent également des designs modernes et réactifs, éliminant ainsi le besoin de développement personnalisé.

### Configurer des tickets Jira à partir de vulnérabilités à l'aide de l'API d'intégration Jira {#configure-jira-issues-from-vulnerabilities-using-the-jira-integration-api}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../api/project_integrations.md#jira-issues) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/454574)

{{< /details >}}

Auparavant, vous deviez configurer l'intégration pour [créer des tickets Jira à partir de vulnérabilités](../../integration/jira/configure.md#create-a-jira-issue-for-a-vulnerability) depuis la page **Paramètres du projet**.

Vous pouvez désormais configurer cette intégration depuis l'API d'intégrations de projet, ce qui vous permet d'automatiser la configuration.

### Traçabilité améliorée des vulnérabilités redétectées {#improved-traceability-of-redetected-vulnerabilities}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/vulnerabilities/_index.md#vulnerability-status-values) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/523452)

{{< /details >}}

Auparavant, lorsqu'une vulnérabilité résolue était redétectée et changeait de statut, les détails de la vulnérabilité ne fournissaient pas d'informations indiquant quand et pourquoi ce changement de statut s'était produit.

GitLab ajoute désormais une note système à l'historique des vulnérabilités lorsque des vulnérabilités résolues changent de statut parce qu'elles sont apparues dans un nouveau scan. Ces informations supplémentaires aident les utilisateurs à comprendre pourquoi les vulnérabilités ont changé de statut.

### Ajouter en masse des vulnérabilités à des tickets depuis le rapport de vulnérabilités {#bulk-add-vulnerabilities-to-issues-from-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#add-vulnerabilities-to-an-existing-issue) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13216)

{{< /details >}}

Avec cette release, vous pouvez désormais ajouter en masse des vulnérabilités à des tickets GitLab nouveaux ou existants depuis le rapport de vulnérabilités. Vous pouvez désormais associer plusieurs tickets et vulnérabilités ensemble. De plus, les vulnérabilités associées sont désormais répertoriées dans la page du ticket.

### Désactiver les invitations d'utilisateurs {#disable-user-invitations}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../administration/settings/visibility_and_access_controls.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/19618)

{{< /details >}}

Vous pouvez désormais supprimer la possibilité d'inviter des membres dans des groupes ou des projets.

- Sur GitLab.com, ce paramètre est configuré par les Propriétaires de groupes avec des utilisateurs Enterprise et s'applique à tous les sous-groupes ou projets au sein du groupe principal. Aucun utilisateur ne peut envoyer d'invitations tant que ce paramètre est activé.
- Sur GitLab Self-Managed, ce paramètre est géré par les administrateurs et s'applique à l'ensemble de l'instance. Les administrateurs peuvent toujours inviter des utilisateurs directement.

Cette fonctionnalité aide les organisations à maintenir un contrôle strict sur les accès aux membres.

### Authentification LDAP avec le nom d'utilisateur GitLab {#ldap-authentication-with-gitlab-username}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/auth/ldap/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/215357)

{{< /details >}}

Les utilisateurs LDAP peuvent désormais authentifier les requêtes avec leur nom d'utilisateur GitLab. Auparavant, si le nom d'utilisateur GitLab ne correspondait pas à leur nom d'utilisateur LDAP, GitLab renvoyait une erreur d'authentification. Ce changement aide les utilisateurs à maintenir des conventions de nommage distinctes dans GitLab et les systèmes LDAP sans perturber les workflows d'approbation.

### Prise en charge des certificats SAML SHA256 {#support-for-sha256-saml-certificates}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../integration/saml.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/524624)

{{< /details >}}

GitLab détecte et prend désormais automatiquement en charge les empreintes de certificat SHA1 et SHA256 pour l'authentification SAML de groupe. Cela maintient la compatibilité ascendante avec les empreintes SHA1 existantes tout en ajoutant la prise en charge des empreintes SHA256 plus sécurisées. Cette mise à niveau est essentielle pour se préparer à la prochaine release de ruby-saml 2.x qui fera de SHA256 la valeur par défaut.

### Permissions granulaires pour les jetons de job en version bêta {#granular-permissions-for-job-tokens-in-beta}

<!-- categories: Permissions -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/fine_grained_permissions.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16199)

{{< /details >}}

La sécurité des pipelines vient de gagner en flexibilité. Les jetons de job sont des identifiants éphémères qui fournissent un accès aux ressources dans les pipelines. Jusqu'à présent, ces jetons héritaient des autorisations complètes de l'utilisateur, entraînant souvent des capacités d'accès inutilement larges.

Grâce à notre nouvelle fonctionnalité bêta de [permissions granulaires pour les jetons de job](../../ci/jobs/fine_grained_permissions.md), vous pouvez désormais contrôler précisément quelles ressources spécifiques un jeton de job peut accéder au sein d'un projet. Cela vous permet d'appliquer le principe du moindre privilège dans vos workflows CI/CD, en accordant uniquement l'accès minimal nécessaire à chaque job pour accomplir ses tâches.

Nous recherchons activement des retours de la communauté sur cette fonctionnalité. Si vous avez des questions, souhaitez partager votre expérience d'implémentation ou souhaitez vous engager directement avec notre équipe sur des améliorations potentielles, veuillez consulter notre [ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/issues/519575).

### Nouvelles autorisations pour les rôles personnalisés {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14746)

{{< /details >}}

Vous pouvez créer des rôles personnalisés avec la permission [Gérer les environnements protégés](https://gitlab.com/gitlab-org/gitlab/-/issues/471385). Les rôles personnalisés vous permettent d'accorder uniquement les permissions spécifiques dont les utilisateurs ont besoin pour accomplir leurs tâches. Cela vous aide à définir des rôles adaptés aux besoins de votre groupe et peut réduire le nombre d'utilisateurs nécessitant le rôle Maintainer ou Owner.

### Nouvelle vue d'analyse CI/CD pour les projets en disponibilité limitée {#new-cicd-analytics-view-for-projects-in-limited-availability}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](../../user/analytics/ci_cd_analytics.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/444468)

{{< /details >}}

La vue d'analyse CI/CD redessinée transforme la façon dont vos équipes de développement analysent, surveillent et optimisent les performances et la fiabilité des pipelines. Les développeurs peuvent accéder à des visualisations intuitives dans l'interface GitLab qui révèlent les tendances de performance et les métriques de fiabilité. L'intégration de ces informations dans le dépôt de votre projet élimine les changements de contexte qui perturbent le flux Developer Flow. Les équipes peuvent identifier et résoudre les goulots d'étranglement des pipelines qui nuisent à la productivité. Cette amélioration conduit à des cycles de développement plus rapides, à une meilleure collaboration et à une confiance fondée sur les données pour optimiser vos workflows CI/CD dans GitLab.

### GitLab Runner 18.0 {#gitlab-runner-180}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Dedicated
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 18.0 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Ajouter `ConfigurationError` et `ExitCodeInvalidConfiguration` aux classifications d'erreurs de build de GitLab Runner](https://gitlab.com/gitlab-org/gitlab/-/issues/514297)
- [Améliorer les messages d'erreur du fournisseur cloud pour les chargements de cache ayant échoué vers le stockage cloud](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5527)

#### Corrections de bugs {#bug-fixes}

- [GitLab Runner peut utiliser des images mises en cache même lorsque cela est interdit](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38706)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/CHANGELOG.md).md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=18.0)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
