---
stage: Release Notes
group: Monthly Release
date: 2025-02-20
title: "Notes de release de GitLab 17.9"
description: "GitLab 17.9 est disponible avec GitLab Duo Self-Hosted en disponibilité générale"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 20 février 2025, GitLab 17.9 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

Nous sommes ravis de désigner [Salihu Dickson](https://gitlab.com/salihudickson) comme notre MVP pour ses contributions exceptionnelles au développement des [commentaires sur les pages Wiki](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171764), une fonctionnalité très demandée qui a recueilli [plus de 200 réactions positives](https://gitlab.com/groups/gitlab-org/-/epics/14062) de la communauté !

Son investissement s'est étalé sur plus de six mois, aboutissant à une implémentation des [discussions de haut niveau sur le wiki](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171764) avec près de 4 000 lignes de code. Salihu a également créé plusieurs implémentations de preuve de concept et amélioré l'expérience Wiki avec des fonctionnalités supplémentaires et des corrections de bugs.

« Salihu a été un contributeur communautaire exceptionnel dans le développement des commentaires sur les pages Wiki ! » témoigne [Matthew Macfarlane](https://gitlab.com/mmacfarlane), Product Manager, Plan:Knowledge chez GitLab. « La connaissance approfondie du produit de Salihu nous a permis de livrer cette fonctionnalité clé plus efficacement. En tant que Product Manager, c'est un plaisir de travailler avec des contributeurs comme Salihu ! »

« Une réalisation incroyable ! » témoigne [Alex Fracazo](https://gitlab.com/afracazo), Senior Product Designer, Plan:Knowledge chez GitLab. « Salihu n'a pas seulement développé les fonctionnalités de base, mais a livré une fonctionnalité complète de bout en bout, des discussions de haut niveau sur les pages Wiki jusqu'à la gestion des erreurs et la couverture des tests. » De nombreux membres de l'équipe GitLab ont manifesté une forte appréciation pour le travail de Salihu, notamment Natalia Tepluhina, ingénieure principale et membre de l'équipe principale Vue.js, ainsi que [Vladimir Shushlin](https://gitlab.com/vshushlin), Engineering Manager, Plan:Knowledge chez GitLab, soulignant ses compétences techniques et sa capacité à collaborer.

Salihu, ingénieur front-end chez Elixir Cloud et mentor GSoC à deux reprises, a partagé : « Je tiens à remercier toutes les personnes qui ont travaillé étroitement avec moi pour rendre cela possible. Un remerciement tout particulier à [Himanshu Kapoor](https://gitlab.com/himkp) (Staff Frontend Engineer, Plan:Knowledge chez GitLab) : votre mentorat au cours des derniers mois a été déterminant pour tout le travail que j'ai accompli ici, et j'apprécie sincèrement tous les conseils et le soutien que vous m'avez apportés. Donner vie à cette fonctionnalité a vraiment été un effort d'équipe — des relecteurs qui ont méticuleusement parcouru des centaines de lignes de code, aux développeurs backend comme [Piotr Skorupa](https://gitlab.com/pskorupa) (Backend Engineer, Plan:Knowledge chez GitLab), qui ont rendu cela possible. » Il a exprimé son enthousiasme à l'idée de collaborer avec l'équipe et de « contribuer à de nombreuses autres fonctionnalités impactantes à l'avenir ! »

Nous sommes très reconnaissants envers Salihu pour toutes ses contributions, ainsi qu'envers l'ensemble de notre communauté open source pour ses contributions à GitLab !

## Fonctionnalités principales {#primary-features}

### GitLab Duo Self-Hosted est en disponibilité générale {#gitlab-duo-self-hosted-is-generally-available}

<!-- categories: Model Selection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../administration/gitlab_duo_self_hosted/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/517102)

{{< /details >}}

Vous pouvez désormais héberger des grands modèles de langage (LLM) sélectionnés dans votre propre infrastructure et configurer ces modèles comme source pour GitLab Duo Code Suggestions et Chat. Cette fonctionnalité est désormais en disponibilité générale sur les environnements GitLab Self-Managed avec les licences applicables.

Avec GitLab Duo Self-Hosted, vous pouvez utiliser des modèles hébergés sur site ou dans un cloud privé comme source pour GitLab Duo Chat ou Code Suggestions. Nous prenons actuellement en charge les modèles Mistral open source sur vLLM ou AWS Bedrock, Claude 3.5 Sonnet sur AWS Bedrock, et les modèles OpenAI sur Azure OpenAI. En activant les modèles auto-hébergés, vous pouvez tirer parti de la puissance de l'IA générative tout en maintenant une souveraineté et une confidentialité complètes des données.

Veuillez laisser vos commentaires dans le [ticket 512753](https://gitlab.com/gitlab-org/gitlab/-/issues/512753).

### Exécuter plusieurs sites Pages avec des déploiements parallèles {#run-multiple-pages-sites-with-parallel-deployments}

<!-- categories: Pages -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/_index.md#parallel-deployments) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14434)

{{< /details >}}

Vous pouvez désormais créer plusieurs versions de vos sites GitLab Pages simultanément grâce aux déploiements parallèles. Chaque déploiement obtient une URL unique basée sur votre préfixe configuré. Par exemple, avec un domaine unique, votre site sera accessible à `project-123456.gitlab.io/prefix`, ou sans domaine unique à `namespace.gitlab.io/project/prefix`.

Cette fonctionnalité est particulièrement utile lorsque vous avez besoin de :

- Prévisualiser des modifications de design ou des mises à jour de contenu.
- Tester des modifications du site en développement.
- Réviser les modifications issues des merge requests.
- Maintenir plusieurs versions du site (par exemple, avec du contenu localisé).

Les déploiements parallèles expirent après 24 heures par défaut pour aider à gérer l'espace de stockage, bien que vous puissiez personnaliser cette durée ou définir des déploiements qui n'expirent jamais. Pour un nettoyage automatique, les déploiements parallèles créés à partir de merge requests sont supprimés lorsque la merge request est fusionnée ou fermée.

### Ajouter des fichiers de projet à Duo Chat dans VS Code et les IDE JetBrains {#add-project-files-to-duo-chat-in-vs-code-and-jetbrains-ides}

<!-- categories: VS Code, JetBrains, Web Chat -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/gitlab_duo_chat/examples.md#ask-about-specific-files-in-the-ide) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/15183)

{{< /details >}}

Ajoutez vos fichiers de projet directement à Duo Chat dans VS Code et JetBrains pour bénéficier d'une assistance IA plus puissante et sensible au contexte.

En ajoutant des fichiers de projet, Duo Chat acquiert une compréhension approfondie de votre base de code spécifique, lui permettant de fournir des réponses hautement contextuelles et précises. Cette prise en compte du contexte vous offre des explications de code plus pertinentes, une aide au débogage précise et des suggestions qui s'intègrent harmonieusement à votre base de code existante. Nous accueillons volontiers vos retours sur cette nouvelle fonctionnalité passionnante. Veuillez partager vos commentaires dans notre ticket de [feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/492443).

### Prise en charge des conteneurs de workspaces avec Sysbox {#workspaces-container-support-with-sysbox}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/configuration.md#build-and-run-containers-in-a-workspace)

{{< /details >}}

Les workspaces GitLab prennent désormais en charge la création et l'exécution de conteneurs directement dans votre environnement de développement. Lorsque votre workspace s'exécute sur un cluster Kubernetes configuré [avec Sysbox](../../user/workspace/configuration.md#with-sysbox), vous pouvez créer et exécuter des conteneurs sans configuration supplémentaire.

Introduite dans GitLab 17.4 dans le cadre de notre [fonctionnalité d'accès sudo](https://about.gitlab.com/releases/2024/09/19/gitlab-17-4-released/#secure-sudo-access-for-workspaces), cette capacité vous permet de maintenir l'intégralité de votre workflow de conteneurs dans votre environnement de workspace GitLab.

### Créer des workspaces sans devfile personnalisé {#create-workspaces-without-a-custom-devfile}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/_index.md#gitlab-default-devfile)

{{< /details >}}

Auparavant, la configuration d'un workspace nécessitait la création d'un fichier de configuration `devfile.yaml`. GitLab vous fournit désormais un fichier par défaut qui inclut des outils de développement courants. Cette amélioration :

- Supprime les obstacles de configuration.
- Vous permet de créer rapidement un workspace depuis n'importe quel projet.
- Inclut des outils de développement courants préconfigurés et prêts à l'emploi.
- Vous permet de vous concentrer sur le développement plutôt que sur la configuration.

Commencez à développer et créez un workspace immédiatement sans étapes de configuration ou d'installation supplémentaires.

### Ressources Kubernetes gérées par GitLab {#gitlab-managed-kubernetes-resources}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/managed_kubernetes_resources.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16130)

{{< /details >}}

Déployez vos applications sur Kubernetes avec plus de contrôle et d'automatisation grâce aux [ressources Kubernetes gérées par GitLab](../../user/clusters/agent/managed_kubernetes_resources.md). Auparavant, vous deviez configurer manuellement les ressources Kubernetes pour chaque environnement. Désormais, vous pouvez utiliser les ressources Kubernetes gérées par GitLab pour provisionner et gérer automatiquement ces ressources.

Avec les ressources Kubernetes gérées par GitLab, vous pouvez :

- Créer automatiquement des espaces de nommage et des comptes de service pour les nouveaux environnements
- Gérer les permissions d'accès via des liaisons de rôles
- Configurer d'autres ressources Kubernetes requises

Lorsque vos équipes de développement déploient des applications, GitLab crée automatiquement les ressources Kubernetes nécessaires à partir des modèles de ressources fournis, rationalisant votre processus de déploiement et maintenant la cohérence entre les environnements.

### Accès simplifié aux déploiements dans les environnements de projet {#simplified-access-to-deployments-within-project-environments}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/505770)

{{< /details >}}

Avez-vous déjà eu du mal à obtenir une vue d'ensemble de vos déploiements au sein d'un projet ? Vous pouvez désormais consulter les détails des déploiements récents dans la liste des environnements sans avoir à développer chaque environnement. Pour chaque environnement, la liste affiche votre dernier déploiement réussi et, s'il est différent, votre tentative de déploiement la plus récente.

### Commentaires sur les pages Wiki {#wiki-page-comments}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/discussions/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14062)

{{< /details >}}

Vous pouvez désormais ajouter des commentaires directement sur les pages Wiki, transformant votre documentation en un espace de collaboration interactif.

Les commentaires et les fils de discussion sur les pages Wiki aident les équipes à :

- Discuter du contenu directement en contexte.
- Suggérer des améliorations et des corrections.
- Maintenir la documentation exacte et à jour.
- Partager les connaissances et l'expertise.

Grâce aux commentaires wiki, les équipes peuvent maintenir une documentation vivante qui évolue avec leurs projets grâce aux retours directs et aux discussions.

### Amélioration de la visibilité des workflows : nouveaux éclairages sur le temps de revue des merge requests {#enhancing-workflow-visibility-new-insights-into-merge-request-review-time}

<!-- categories: Value Stream Management, Code Review Workflow -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/503754)

{{< /details >}}

Pour améliorer le suivi des workflows de développement, [Value Stream Analytics](https://about.gitlab.com/solutions/value-stream-management/) (VSA) a été enrichi d'un nouvel événement : *Merge request last approved at*. L'événement d'[approbation de merge request](../../user/project/merge_requests/approvals/_index.md) marque la fin de la phase de revue et le début de l'exécution du pipeline final ou de l'étape de fusion. Par exemple, pour calculer le temps total de revue d'une merge request, vous pouvez créer une étape VSA avec *Merge request reviewer first assigned* comme événement de début et *Merge request last approved at* comme événement de fin.

Grâce à cette amélioration, les équipes acquièrent une compréhension plus approfondie des opportunités d'optimisation des temps de revue, contribuant à réduire le temps de cycle global du développement et à accélérer la livraison de logiciels.

### Données EPSS, KEV et CVSS pour la priorisation des risques de vulnérabilité {#epss-kev-and-cvss-data-for-vulnerability-risk-prioritization}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerabilities/risk_assessment_data.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11544)

{{< /details >}}

Nous avons ajouté la prise en charge des données de risque de vulnérabilité suivantes :

- Exploit Prediction Scoring System (EPSS)
- Known Exploited Vulnerabilities (KEV)
- Common Vulnerabilities and Exposures (CVE)

Vous pouvez désormais prioriser efficacement les risques liés aux vulnérabilités de vos dépendances et images de conteneurs à l'aide de ces données. Vous pouvez trouver ces données dans le rapport des vulnérabilités et dans la page de détails des vulnérabilités.

### Configurer les analyses DAST via l'interface utilisateur avec un contrôle total {#configure-dast-scans-through-the-ui-with-full-control}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/on-demand_scan.md)

{{< /details >}}

Pour tester efficacement des applications complexes, les équipes de sécurité ont besoin de flexibilité lorsqu'elles configurent des analyses DAST. Auparavant, les analyses DAST configurées via l'interface utilisateur disposaient d'options de configuration limitées, ce qui empêchait l'analyse réussie d'applications avec des exigences de sécurité spécifiques. Cela signifiait que vous deviez utiliser des analyses basées sur les pipelines même pour des évaluations de sécurité rapides.

Vous pouvez désormais configurer des analyses DAST via l'interface utilisateur avec le même contrôle granulaire que celui disponible dans les analyses basées sur les pipelines. Cela inclut :

- La configuration complète de l'authentification, incluant les en-têtes personnalisés et les cookies
- Des paramètres d'exploration précis tels que le nombre maximum de pages, la profondeur maximale et les URL exclues
- Des délais d'expiration d'analyse avancés et des tentatives de relance
- Le comportement personnalisé du scanner, comme le nombre maximum de liens à explorer et la profondeur du DOM
- Des modes d'analyse ciblés pour des types de vulnérabilités spécifiques

Enregistrez ces configurations en tant que profils réutilisables pour maintenir des tests de sécurité cohérents dans toutes vos applications. Chaque modification de configuration est suivie via des événements d'audit, vous permettant de savoir quand des paramètres d'analyse sont ajoutés, modifiés ou supprimés.

Ce contrôle amélioré vous aide à effectuer des analyses de sécurité plus efficaces tout en maintenant la conformité grâce à des pistes d'audit détaillées. Au lieu de passer du temps à gérer les configurations de pipelines, vous pouvez rapidement lancer l'analyse adaptée à chaque application pour détecter et corriger les vulnérabilités plus rapidement.

### Nettoyage automatique des pipelines CI/CD {#automatic-cicd-pipeline-cleanup}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/settings.md#automatic-pipeline-cleanup) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/338480)

{{< /details >}}

Par le passé, si vous souhaitiez supprimer d'anciens pipelines CI/CD, vous ne pouviez le faire que via l'API REST.

Dans GitLab 17.9, nous avons introduit un paramètre de projet vous permettant de définir un délai d'expiration des pipelines CI/CD. Tous les pipelines et les artefacts associés plus anciens que la période de rétention définie sont supprimés. Cela peut contribuer à réduire l'utilisation du disque dans les projets qui exécutent de nombreux pipelines générant de grands artefacts, et même à améliorer les performances globales.

## Agentic Core {#agentic-core}

### Identité composite pour des connexions IA plus sécurisées {#composite-identity-for-more-secure-ai-connections}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../development/ai_features/composite_identity.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/506641)

{{< /details >}}

Auparavant, une requête adressée à GitLab ne pouvait être authentifiée qu'en tant qu'utilisateur unique. Avec l'identité composite, nous avons rendu possible l'authentification d'une requête en tant que compte de service et utilisateur simultanément. Les cas d'usage des agents d'IA nécessitent souvent que les permissions soient basées sur l'utilisateur qui a initié les tâches dans un système, tout en affichant simultanément une identité distincte, séparée de l'utilisateur initiateur. Une identité composite est notre nouveau principal d'identité, qui représente l'identité d'un agent d'IA. Cette identité est liée à l'identité de l'utilisateur humain qui demande des actions à l'agent. Chaque fois qu'une action d'un agent d'IA tente d'accéder à une ressource, un jeton d'identité composite est utilisé. Ce jeton appartient à un compte de service et est également lié à l'utilisateur humain qui instruit l'agent. Les vérifications d'autorisation effectuées sur le jeton prennent en compte les deux principaux avant d'accorder l'accès à une ressource. Les deux identités doivent avoir accès à la ressource, sinon l'accès est refusé. Cette nouvelle fonctionnalité renforce notre capacité à protéger les ressources stockées dans GitLab. Pour plus d'informations sur la façon dont l'identité composite pour les comptes de service peut être utilisée, consultez la [documentation](../../development/ai_features/composite_identity.md).

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Empêcher les utilisateurs de rendre leur profil privé {#restrict-users-from-making-their-profile-private}

<!-- categories: User Management, User Profile -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/account_and_limit_settings.md#prevent-users-from-making-their-profiles-private) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/421310)

{{< /details >}}

Les utilisateurs peuvent choisir de rendre leur profil utilisateur public ou privé. Les administrateurs peuvent désormais contrôler si les utilisateurs ont la possibilité de rendre leurs profils privés sur leur instance GitLab. Dans la zone d'administration, le paramètre « Allow users to make their profiles private » contrôle ce réglage. Ce paramètre est activé par défaut, permettant aux utilisateurs de choisir des profils privés.

### Gérer les intégrations de projet depuis un groupe via l'API REST {#manage-project-integrations-from-a-group-with-the-rest-api}

<!-- categories: Source Code Management, Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/group_integrations.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/328496)

{{< /details >}}

Auparavant, vous ne pouviez gérer les intégrations de projet depuis un groupe que dans l'interface utilisateur GitLab. Avec cette release, il est également possible de gérer ces intégrations via l'API REST.

Merci à [Van](https://gitlab.com/van.m.anderson) pour sa [contribution initiale à la communauté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148283), qui a ensuite été reprise et complétée par GitLab.

### Amélioration de la visibilité du partage de groupes {#group-sharing-visibility-enhancement}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/members/sharing_projects_groups.md#view-shared-groups) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/378629)

{{< /details >}}

Nous sommes ravis d'annoncer une visibilité étendue pour le partage de groupes dans GitLab. Auparavant, bien que vous puissiez voir les projets partagés sur la page de présentation d'un groupe, vous ne pouviez pas voir dans quels groupes votre groupe avait été invité à rejoindre. Vous pouvez désormais consulter les onglets **Projets partagés** et **Groupes partagés** sur la page de présentation du groupe, ce qui vous donne une vue complète de la façon dont vos groupes sont connectés et partagés au sein de votre organisation. Cela facilite l'audit et la gestion des accès aux groupes dans votre organisation.

Nous accueillons volontiers vos retours sur ce changement dans l'[epic 16777](https://gitlab.com/groups/gitlab-org/-/epics/16777).

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Activer l'analyse des dépendances via SBOM pour les projets Cargo, Conda, Cocoapods et Swift {#enable-dependency-scanning-using-sbom-for-cargo-conda-cocoapods-and-swift-projects}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/519597)

{{< /details >}}

Dans GitLab 17.9, l'équipe Composition Analysis entame la transition vers l'analyse des dépendances via SBOM avec le nouvel analyseur d'analyse des dépendances. Cet analyseur remplacera Gemnasium, dont la fin de support interviendra dans la version 18.0, tout en restant disponible jusqu'à GitLab 19.0.

L'approche d'analyse des dépendances via SBOM permettra de mieux accompagner les clients grâce à l'élargissement de la prise en charge des langages, une intégration et une expérience plus étroites au sein de la plateforme GitLab, et une orientation vers les types de rapports standard du secteur (analyse et reporting basés sur SBOM). À partir de GitLab 17.9, le nouvel analyseur d'analyse des dépendances sera activé par défaut dans le template CI/CD d'analyse des dépendances `latest` (`Dependency-Scanning.latest.gitlab-ci.yml`) pour les types de projets et de fichiers suivants :

- Projets C/C++/Fortran/Go/Python/R utilisant conda avec un fichier `conda-lock.yml`.
- Projets Objective-C utilisant Cocoapods avec un fichier `podfile.lock`.
- Projets Rust utilisant Cargo avec un fichier `cargo.lock`.
- Projets Swift utilisant Swift avec un fichier `package.resolved`.

Avec ce changement, nous introduisons une nouvelle variable CI/CD : `DS_ENFORCE_NEW_ANALYZER` qui est définie sur `false` par défaut.

Cette approche garantit que tous les clients existants du template `latest` continuent d'utiliser l'analyseur Gemnasium par défaut et active automatiquement le nouvel analyseur d'analyse des dépendances pour les types de fichiers listés ci-dessus.

Les clients existants qui souhaitent migrer vers le nouvel analyseur d'analyse des dépendances peuvent définir `DS_ENFORCE_NEW_ANALYZER` sur `true` (au niveau du projet, du groupe ou de l'instance). Vous pouvez en savoir plus sur ce changement dans l'[annonce de dépréciation](../../update/deprecations.md#dependency-scanning-upgrades-to-the-gitlab-sbom-vulnerability-scanner) et le [guide de migration](../../user/application_security/dependency_scanning/migration_guide_to_sbom_based_scans.md) associé.

Les clients qui souhaitent entièrement empêcher l'utilisation du nouvel analyseur d'analyse des dépendances doivent définir la variable CI/CD `DS_EXCLUDED_ANALYZERS` sur `dependency-scanning`.

### Prise en charge de l'analyse des licences pour les packages Swift {#license-scanning-support-for-swift-packages}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/506730)

{{< /details >}}

Dans GitLab 17.9, nous avons ajouté la prise en charge de l'analyse des licences pour les packages Swift. Cela permettra aux utilisateurs qui utilisent Swift dans leurs projets de mieux comprendre les licences de leurs packages Swift.

Ces données sont disponibles pour les utilisateurs de l'analyse de composition via la liste des dépendances, les rapports SBOM et l'API GraphQL.

### L'Advanced SAST multicœur offre des analyses plus rapides {#multi-core-advanced-sast-offers-faster-scans}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/_index.md#security-scanner-configuration) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/514156)

{{< /details >}}

GitLab Advanced SAST propose désormais l'analyse multicœur en tant que fonctionnalité opt-in pour améliorer les performances. Cela peut réduire significativement la durée des analyses, en particulier pour les bases de code plus volumineuses.

Pour l'activer, définissez la variable CI/CD `SAST_SCANNER_ALLOWED_CLI_OPTS` sur `--multi-core N`, où `N` est le nombre de cœurs souhaité. Vous ne devez définir cette variable que sur le job `gitlab-advanced-sast`, et non sur d'autres jobs. Consultez [la documentation](../../user/application_security/sast/_index.md#security-scanner-configuration) pour obtenir des conseils importants sur la sélection de la valeur appropriée.

Nous travaillons à activer cette amélioration des performances par défaut ; cela est suivi dans le [ticket 517409](https://gitlab.com/gitlab-org/gitlab/-/issues/517409).

### Appliquer un référentiel de conformité en utilisant le centre de conformité d'un projet {#apply-a-compliance-framework-by-using-a-projects-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : Ultimate, Premium
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md) \| [Epic associé](https://gitlab.com/gitlab-org/gitlab/-/issues/507986)

{{< /details >}}

Dans GitLab 17.2, nous avons publié la possibilité pour les propriétaires de groupes d'appliquer et de supprimer des référentiels de conformité pour tous les projets d'un groupe en utilisant le centre de conformité du groupe.

Nous avons étendu cette fonctionnalité pour permettre désormais aux propriétaires de groupes d'appliquer et de supprimer également des référentiels de conformité au niveau du projet. Cela facilitera encore davantage l'application et le suivi des référentiels de conformité au niveau du projet pour les propriétaires de groupes.

La possibilité d'appliquer et de supprimer des référentiels de conformité au niveau du projet est uniquement disponible pour les propriétaires de groupes et non pour les propriétaires de projets.

### Les extensions de workspace prennent désormais en charge les API proposées {#workspace-extensions-now-support-proposed-apis}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/_index.md#extension-marketplace)

{{< /details >}}

Les extensions de workspace prennent désormais en charge l'activation des API proposées, améliorant ainsi la compatibilité et la fiabilité dans les environnements de production. Cette mise à jour permet aux extensions qui dépendent des API proposées de s'exécuter sans erreurs, y compris les outils de développement essentiels tels que le Python Debugger. Ce changement élargit l'accès aux API tout en maintenant la stabilité.

### Implémenter GitOps basé sur OCI avec le composant CI/CD FluxCD {#implement-oci-based-gitops-with-the-fluxcd-cicd-component}

<!-- categories: Container Registry, Deployment Management, Component Catalog -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](https://gitlab.com/components/fluxcd/) \| [Ticket associé](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/experiments/fluxcd-ci-cd-component/-/issues/1)

{{< /details >}}

Vous êtes-vous déjà demandé comment implémenter les meilleures pratiques GitOps avec GitLab ? Le nouveau [composant FluxCD](https://gitlab.com/components/fluxcd/) facilite la tâche. Utilisez le composant FluxCD pour packager des manifestes Kubernetes dans des images OCI et stocker les images dans des registres de conteneurs compatibles OCI. Vous pouvez éventuellement signer les images et déclencher une réconciliation FluxCD immédiate.

### Démarrer avec l'intégration GitLab et Kubernetes {#get-started-with-the-gitlab-integration-with-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/getting_started.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/505216)

{{< /details >}}

Dans cette release, nous avons ajouté de nouveaux guides de démarrage Kubernetes qui vous montrent comment utiliser GitLab pour déployer des applications sur Kubernetes directement et avec FluxCD. Ces tutoriels faciles à suivre ne nécessitent pas de connaissances approfondies de Kubernetes, ce qui permet aux utilisateurs novices comme expérimentés d'apprendre à intégrer GitLab et Kubernetes.

Pour compléter les guides de démarrage Kubernetes, nous avons également inclus une série de recommandations pour l'intégration de GitLab dans les environnements Kubernetes.

### Découvrir et migrer les clusters Kubernetes basés sur des certificats {#discover-and-migrate-certificate-based-kubernetes-clusters}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/cluster_discovery.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/512420)

{{< /details >}}

L'intégration Kubernetes basée sur des certificats sera désactivée sur GitLab.com pour tous les utilisateurs entre le 6 mai 2025 à 9h00 UTC et le 8 mai 2025 à 22h00 UTC, et sera supprimée des instances GitLab Self-Managed dans GitLab 19.0 (prévue en mai 2026).

Pour aider les utilisateurs à migrer, nous avons ajouté un nouveau point de terminaison d'API de cluster que les propriétaires de groupes peuvent interroger pour [découvrir tous les clusters basés sur des certificats](../../api/cluster_discovery.md) enregistrés dans un groupe, un sous-groupe ou un projet. Nous avons également mis à jour la [documentation de migration](../../user/infrastructure/clusters/migrate_to_gitlab_agent.md) pour fournir des instructions adaptées aux différents types de cas d'utilisation.

Nous encourageons tous les utilisateurs de GitLab.com à vérifier s'ils sont concernés et à planifier leurs migrations dès que possible.

### Appliquer des étapes personnalisées dans les politiques d'exécution de pipeline {#enforce-custom-stages-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#inject_policy-type) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/475152)

{{< /details >}}

Nous sommes ravis d'introduire une nouvelle fonctionnalité pour les politiques d'exécution de pipeline qui vous permet d'appliquer des **custom stages** dans vos pipelines CI/CD en mode `Inject`. Cette fonctionnalité offre une plus grande flexibilité et un meilleur contrôle sur la structure de votre pipeline tout en maintenant les exigences de sécurité et de conformité, vous fournissant :

- **Enhanced pipeline customization** : définissez et injectez des étapes personnalisées à des points spécifiques de votre pipeline, permettant un contrôle plus granulaire sur l'ordre d'exécution des jobs.
- **Improved security and compliance** : assurez-vous que les analyses de sécurité et les vérifications de conformité s'exécutent aux moments les plus appropriés dans votre pipeline, par exemple après la compilation mais avant le déploiement.
- **Flexible policy management** : maintenez un contrôle centralisé des politiques tout en permettant aux équipes de développement de personnaliser leurs pipelines dans des limites définies.
- **Seamless integration** : les étapes personnalisées fonctionnent en parallèle des étapes de projet existantes et d'autres types de politiques, offrant une façon non perturbatrice d'améliorer vos workflows CI/CD.

**How does it work?**

La nouvelle stratégie `inject_policy` améliorée pour les politiques d'exécution de pipeline vous permet de définir des étapes personnalisées dans votre configuration de politique. Ces étapes sont ensuite fusionnées intelligemment avec les étapes existantes de votre projet à l'aide d'un algorithme de graphe acyclique dirigé (DAG), garantissant un ordonnancement correct et prévenant les conflits.

Par exemple, vous pouvez désormais facilement injecter une étape d'analyse de sécurité personnalisée entre vos étapes de compilation et de déploiement.

L'étape `inject_policy` remplace `inject_ci` qui sera dépréciée, vous permettant d'opter pour le mode `inject_policy` afin d'en tirer les bénéfices. Le mode `inject_policy` deviendra le mode par défaut lors de la configuration des politiques avec `Inject` dans l'éditeur de politiques.

### Faire pivoter les jetons d'accès avec la portée `self_rotate` {#rotate-access-tokens-with-self_rotate-scope}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/personal_access_tokens.md#personal-access-token-scopes) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/430748)

{{< /details >}}

Vous pouvez désormais utiliser la portée `self_rotate` pour faire pivoter les jetons d'accès. Cette portée est disponible pour les jetons d'accès personnels, de projet ou de groupe. Auparavant, cela nécessitait deux requêtes : une pour obtenir un nouveau jeton, puis une autre pour effectuer la rotation du jeton.

Merci à [Stéphane Talbot](https://gitlab.com/stalb) et [Anthony Juckel](https://gitlab.com/ajuckel) pour votre contribution !

### Afficher les jetons d'accès de projet et de groupe inactifs {#view-inactive-project-and-group-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : Free, Premium, Ultimate, Silver, Gold
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/settings/project_access_tokens.md#view-your-access-tokens) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)

{{< /details >}}

Vous pouvez désormais afficher les jetons d'accès de groupe et de projet inactifs dans l'interface utilisateur. Auparavant, GitLab supprimait instantanément les jetons d'accès de projet et de groupe après leur expiration ou leur révocation. Cette absence d'enregistrement des jetons inactifs rendait les audits et les révisions de sécurité plus difficiles. GitLab conserve désormais les enregistrements des jetons d'accès de groupe et de projet inactifs pendant 30 jours, ce qui aide les équipes à suivre l'utilisation et l'expiration des jetons à des fins de conformité et de surveillance.

### Afficher les adresses IP des jetons d'accès {#view-access-token-ip-addresses}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/personal_access_tokens.md#view-token-usage-information) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/428577)

{{< /details >}}

Auparavant, lorsque vous consultiez vos jetons d'accès personnels, les seules informations d'utilisation disponibles étaient le nombre de minutes écoulées depuis la dernière utilisation du jeton. Désormais, vous pouvez également voir jusqu'aux sept dernières adresses IP depuis lesquelles les jetons ont été utilisés. Ces informations combinées peuvent vous aider à suivre l'endroit où votre jeton est utilisé.

Merci à [Jayce Martin](https://jrm2k.us), [Avinash Koganti](http://www.linkedin.com/in/avinash-koganti-38b511162), [Austin Dixon](https://austindixon.net/) et [Rohit Kala](https://www.linkedin.com/in/rohit-kala-1b891a179) pour votre contribution !

### Contrôler l'accès à GitLab Pages pour les groupes {#control-access-to-gitlab-pages-for-groups}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/pages_access_control.md#remove-public-access-for-group-pages)

{{< /details >}}

Vous pouvez désormais restreindre l'accès à GitLab Pages au niveau du groupe. Les propriétaires de groupes peuvent activer un seul paramètre pour rendre tous les sites Pages d'un groupe et de ses sous-groupes visibles uniquement par les membres du projet. Ce contrôle centralisé simplifie la gestion de la sécurité sans modifier les paramètres de chaque projet individuellement.

### Changer le type d'élément de travail en un autre {#change-work-item-type-to-another}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/tasks.md#convert-a-task-into-another-item-type) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/385131)

{{< /details >}}

Vous pouvez désormais modifier facilement le type de vos éléments de travail, ce qui vous donne la flexibilité de gérer vos projets plus efficacement.

### Accélérer l'ajout de nouveaux éléments enfants en maintenant le formulaire ouvert {#speed-up-adding-new-child-items-by-keeping-the-form-open}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/work_items/child_items.md#work-with-multi-level-hierarchies) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/497767)

{{< /details >}}

Nous avons simplifié le processus de création de plusieurs éléments enfants en maintenant le formulaire ouvert après chaque soumission, facilitant l'ajout de plusieurs entrées sans clics supplémentaires. Cette mise à jour vous fait gagner du temps et garantit un workflow plus fluide lors de la gestion de vos tâches.

### API GraphQL des éléments de travail - filtres de requête supplémentaires {#work-items-graphql-api---additional-query-filters}

<!-- categories: Portfolio Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/graphql/reference/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/513308)

{{< /details >}}

L'API GraphQL des éléments de travail inclut désormais des filtres de requête supplémentaires vous permettant de filtrer par :

- Dates de création, de mise à jour, de clôture et d'échéance
- Statut de santé
- Poids

Ces nouveaux filtres vous offrent plus de contrôle lors de l'interrogation et de l'organisation des éléments de travail via l'API.

### Bloquer la suppression des projets de politiques de sécurité actifs {#block-deletion-of-active-security-policy-projects}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/_index.md) \| [Epic associé](https://gitlab.com/gitlab-org/gitlab/-/issues/482967)

{{< /details >}}

Pour garantir une gestion sécurisée des politiques de sécurité et éviter toute perturbation des politiques activées et appliquées, nous avons ajouté une protection empêchant la suppression des projets de politiques de sécurité en cours d'utilisation.

Si un projet de politique de sécurité est lié à des groupes ou des projets, les liens doivent être supprimés avant que le projet de politique de sécurité puisse être supprimé.

### Filtrer la liste des dépendances par composant dans les projets {#dependency-list-filter-by-component-in-projects}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md#filter-dependency-list) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/16490)

{{< /details >}}

Dans la liste des dépendances d'un projet, vous pouvez désormais filtrer par nom de package à l'aide du filtre Composant.

Auparavant, vous ne pouviez pas rechercher des packages dans la liste des dépendances au niveau d'un projet. Désormais, le filtre Composant vous permet de trouver les packages contenant la chaîne spécifiée.

### Filtrer par identifiant dans le rapport de vulnérabilités du projet {#filter-by-identifier-in-the-project-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13340)

{{< /details >}}

Dans le rapport de vulnérabilités d'un projet, vous pouvez désormais filtrer les résultats par identifiant de vulnérabilité afin de trouver des vulnérabilités spécifiques (telles que des CVE ou des CWE) présentes dans votre projet. Vous pouvez utiliser l'identifiant en conjonction avec d'autres filtres tels que la gravité, le statut ou les filtres d'outils. Le filtre d'identifiant de vulnérabilité est limité aux rapports comportant 20 000 vulnérabilités ou moins.

### Prendre en charge les rôles personnalisés dans les politiques d'approbation des merge requests {#support-custom-roles-in-merge-request-approval-policies}

<!-- categories: Permissions, Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#require_approval-action-type) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13550)

{{< /details >}}

Nous avons rendu les politiques d'approbation des merge requests plus flexibles en ajoutant la possibilité d'assigner des rôles personnalisés en tant qu'approbateurs.

Vous pouvez désormais adapter les exigences d'approbation aux structures d'équipes et aux responsabilités uniques de votre organisation, garantissant que les bons rôles sont impliqués dans le processus de revue en fonction de la politique. Par exemple, exigez l'approbation des rôles AppSec Engineering pour les revues de sécurité et des rôles Compliance pour les approbations de licences.

### Rechercher et filtrer l'inventaire des identifiants {#search-and-filter-the-credentials-inventory}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/credentials_inventory.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/345734)

{{< /details >}}

Vous pouvez désormais utiliser des fonctionnalités de recherche et de filtrage dans l'inventaire des identifiants. Cela facilite l'identification des jetons et des clés qui correspondent à certains paramètres définis par l'utilisateur, y compris les jetons qui expirent dans une certaine plage temporelle. Auparavant, les entrées de l'inventaire des identifiants étaient présentées sous forme de liste statique.

### Événement d'audit d'autorisation d'application OAuth {#oauth-application-authorization-audit-event}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : Ultimate, Premium
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/audit_event_types.md#authorization) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/514152)

{{< /details >}}

Auparavant, lorsqu'un utilisateur autorisait une application OAuth, aucun événement d'audit n'était généré. Cependant, cet événement est important pour que les équipes de sécurité puissent surveiller les applications OAuth autorisées par les utilisateurs sur une instance GitLab spécifique.

Avec cette release, GitLab fournit désormais un événement d'audit **User authorized an OAuth application** pour suivre les autorisations réussies d'applications OAuth par les utilisateurs. Ce nouvel événement d'audit améliore encore davantage votre capacité à auditer votre instance GitLab.

### Utiliser l'API pour désactiver la 2FA pour des utilisateurs enterprise individuels {#use-api-to-disable-2fa-for-individual-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../api/group_enterprise_users.md#disable-two-factor-authentication-for-an-enterprise-user) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/383319)

{{< /details >}}

Vous pouvez désormais utiliser l'API pour effacer toutes les inscriptions à l'authentification à deux facteurs (2FA) pour un utilisateur enterprise individuel. Auparavant, cela n'était possible que dans l'interface utilisateur. L'utilisation de l'API permet des opérations automatisées et en masse, économisant du temps lorsque les réinitialisations de 2FA doivent être effectuées à grande échelle.

### Notifications par e-mail pour les comptes de service {#email-notifications-for-service-accounts}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/service_accounts.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/428750)

{{< /details >}}

Vous pouvez désormais définir une adresse e-mail personnalisée pour recevoir des notifications par e-mail pour les comptes de service. Lorsqu'une adresse e-mail personnalisée est spécifiée lors de la création d'un compte de service, GitLab envoie des notifications à cette adresse. Chaque compte de service doit utiliser une adresse e-mail unique. Cela peut vous aider à surveiller les processus et les événements plus efficacement.

Merci à [Gilles Dehaudt](https://gitlab.com/tonton1728), [Étienne Girondel](https://gitlab.com/lenaing), [Kevin Caborderie](https://gitlab.com/Densett), [Geoffrey McQuat](https://gitlab.com/gmcquat), [Raphaël Bihore](https://gitlab.com/rbihore) de l'[équipe SNCF Connect & Tech](https://www.sncf-connect-tech.fr/) pour votre contribution !

### Prise en charge des appartenances à des groupes supplémentaires avec plusieurs fournisseurs OIDC {#support-for-additional-group-memberships-with-multiple-oidc-providers}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/auth/oidc.md#configure-multiple-openid-connect-providers) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/408248)

{{< /details >}}

Vous pouvez désormais configurer des appartenances à des groupes supplémentaires lors de l'utilisation de plusieurs fournisseurs OIDC. Auparavant, si vous configuriez plusieurs fournisseurs OIDC, vous étiez limité à une seule appartenance de groupe.

### Date d'expiration personnalisée pour les jetons de comptes de service ayant subi une rotation {#custom-expiration-date-for-rotated-service-account-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/service_accounts.md#rotate-a-personal-access-token-for-a-group-service-account) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/505671)

{{< /details >}}

Lors de la rotation d'un jeton d'accès pour un compte de service, vous pouvez désormais utiliser l'attribut `expires_at` pour définir une date d'expiration personnalisée. Auparavant, les jetons expiraient automatiquement sept jours après la rotation. Cela permet une gestion plus granulaire des durées de vie des jetons, améliorant votre capacité à maintenir des contrôles d'accès sécurisés.

### Prendre en charge les variables de merge request dans les politiques d'exécution de pipeline {#support-merge-request-variables-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/pipeline_execution_policies.md) \| [Epic associé](https://gitlab.com/gitlab-org/gitlab/-/issues/512916)

{{< /details >}}

Les politiques d'exécution de pipeline prennent désormais en charge des variables de merge request supplémentaires, vous permettant de créer des politiques plus sophistiquées qui tiennent compte des informations relatives à la merge request. Cela offre un contrôle plus ciblé et plus efficace sur l'application des règles CI/CD. Les variables suivantes sont désormais prises en charge :

- `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`
- `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`
- `CI_MERGE_REQUEST_DIFF_BASE_SHA`

Avec cette amélioration, vous pouvez :

- Implémenter des analyses de sécurité avancées qui comparent les modifications entre les branches source et cible, garantissant une revue de code approfondie et une détection des vulnérabilités.
- Créer des configurations de pipeline dynamiques qui s'adaptent en fonction des spécificités de chaque merge request, rationalisant votre processus de développement.

### Nouvelles autorisations pour les rôles personnalisés {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/custom_roles/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/14746)

{{< /details >}}

Vous pouvez créer des rôles personnalisés avec la permission [Read compliance dashboard](https://gitlab.com/gitlab-org/gitlab/-/issues/465324). Les rôles personnalisés vous permettent d'accorder uniquement les permissions spécifiques dont les utilisateurs ont besoin pour accomplir leurs tâches. Cela vous aide à définir des rôles adaptés aux besoins de votre groupe et peut réduire le nombre d'utilisateurs nécessitant le rôle Maintainer ou Owner.

### GitLab Runner 17.9 {#gitlab-runner-179}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 17.9 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Ajouter un contrôle de santé pour les instances autoscaler du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38271)
- [Ajouter des métriques d'histogramme pour la durée de l'étape de préparation du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37471)
- [Ajouter la prise en charge des noms de conteneurs de service personnalisés pour l'exécuteur Kubernetes](https://gitlab.com/gitlab-org/gitlab/-/issues/421131)

#### Corrections de bugs {#bug-fixes}

- [GitLab Runner ne parvient pas à récupérer le cache depuis S3 Express One Zone](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38484)
- [GitLab Runner sur Kubernetes signale 'script_failure' au lieu de 'runner_system_failure' pour les instances AWS Spot](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37911)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-9-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.9)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.9)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.9)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
