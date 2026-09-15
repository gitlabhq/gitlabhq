---
stage: Release Notes
group: Monthly Release
date: 2023-08-22
title: "Notes de release de GitLab 16.3"
description: "GitLab 16.3 est disponible avec de nouvelles métriques de vélocité dans le tableau de bord Value Streams"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 22 août 2023, GitLab 16.3 a été publié avec les fonctionnalités suivantes.

Nous tenons également à remercier tous nos contributeurs, dont le contributeur notable de ce mois-ci.

## Contributeur notable du mois : Thomas Spear {#this-months-notable-contributor-thomas-spear}

Thomas a contribué [15 merge requests](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/merge_requests?scope=all&state=merged&author_username=tspearconquest) au [chart Helm de l'agent GitLab pour Kubernetes](https://gitlab.com/gitlab-org/charts/gitlab-agent) au cours du dernier mois !

Thomas a rendu le chart plus mature en termes de sécurité et d'observabilité, a simplifié la résolution des problèmes avec agentk et a amélioré le pipeline CI/CD pour détecter les changements majeurs.

En tant qu'ingénieur en sécurité, Thomas prend plaisir à collaborer avec l'équipe pour fournir un déploiement par défaut plus sécurisé de l'agent GitLab. Thomas a exprimé sa gratitude pour toutes les revues et les retours fournis en temps voulu, que les membres de l'équipe ont été ravis de partager.

Merci Thomas, vos contributions sont immensément appréciées ! 🙌

Nous souhaitons également saisir l'occasion de remercier [Shane Maglangit](https://gitlab.com/ShaneMaglangit) et [Batuhan Apaydın](https://gitlab.com/batuhan.apaydin) pour leurs excellentes contributions.

## Fonctionnalités principales {#primary-features}

### Nouvelles métriques de vélocité dans le tableau de bord Value Streams {#new-velocity-metrics-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/383665)

{{< /details >}}

Le [tableau de bord Value Streams](https://about.gitlab.com/blog/getting-started-with-value-streams-dashboard/) a été enrichi de nouvelles métriques : **Merge request (MR) throughput** et **Total closed issues** (Vélocité). Dans GitLab, le **MR throughput** correspond au nombre de merge requests fusionnées par mois, et le **Total closed issues** représente le nombre d'éléments de flux fermés à un instant donné.

Grâce à ces métriques, vous pouvez identifier les mois de faible ou de forte productivité, ainsi que l'efficacité des [processus de merge request et de revue de code](../../user/analytics/merge_request_analytics.md). Vous pouvez ensuite évaluer si la [livraison Value Stream](../../user/group/value_stream_analytics/_index.md) s'accélère ou non.

Au fil du temps, les métriques accumulent des données historiques provenant des MR et des tickets. Les équipes peuvent utiliser ces données pour déterminer si les cadences de livraison s'accélèrent ou nécessitent des améliorations, et fournir des estimations ou des prévisions plus précises quant à la quantité de travail qu'elles peuvent livrer.

Pour nous aider à améliorer le tableau de bord Value Streams, veuillez partager vos retours sur votre expérience dans cette [enquête](https://gitlab.fra1.qualtrics.com/jfe/form/SV_50guMGNU2HhLeT4).

### Se connecter aux Workspaces via SSH {#connect-to-workspaces-with-ssh}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/configuration.md#connect-to-a-workspace-with-ssh)

{{< /details >}}

Avec les Workspaces, vous pouvez créer des environnements d'exécution reproductibles, éphémères et basés sur le cloud. Depuis l'introduction de cette fonctionnalité dans GitLab 16.0, la seule façon d'utiliser un workspace était via le Web IDE basé sur navigateur s'exécutant directement dans l'environnement. Cependant, le Web IDE n'est pas toujours l'outil le mieux adapté à vos besoins.

Avec GitLab 16.3, vous pouvez désormais vous connecter de façon sécurisée à un workspace depuis votre ordinateur de bureau via SSH et utiliser vos outils et extensions locaux. La première itération prend en charge les connexions SSH directement dans VS Code ou depuis la ligne de commande avec des éditeurs comme Vim ou Emacs. La prise en charge d'autres éditeurs, tels que les IDE JetBrains et JupyterLab, est prévue dans les prochaines itérations.

### Visualisation du statut de synchronisation Flux {#flux-sync-status-visualization}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md#flux-sync-status) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/391581)

{{< /details >}}

Dans les versions précédentes, vous utilisiez probablement `kubectl` ou un autre outil tiers pour vérifier le statut de vos déploiements Flux. À partir de GitLab 16.3, vous pouvez vérifier vos déploiements depuis l'interface des environnements.

Les déploiements s'appuient sur les ressources Flux `Kustomization` et `HelmRelease` pour collecter le statut d'un environnement donné, ce qui nécessite qu'un espace de nommage soit configuré pour l'environnement. Par défaut, GitLab recherche dans les ressources `Kustomization` et `HelmRelease` le nom du slug du projet. Vous pouvez personnaliser le nom que GitLab recherche dans les paramètres de l'environnement.

### Filtrage supplémentaire pour les politiques de résultat d'analyse {#additional-filtering-for-scan-result-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/6826)

{{< /details >}}

Déterminer quels résultats d'une analyse de sécurité ou de conformité sont exploitables représente un défi majeur pour les équipes chargées de la sécurité et de la conformité. Les filtres granulaires pour les politiques de résultat d'analyse vous aideront à faire le tri et à identifier les vulnérabilités ou violations qui requièrent le plus votre attention. Ces nouveaux filtres et mises à jour de filtres optimiseront vos workflows :

- Statut : les modifications des règles de statut introduisent une application plus intuitive de la notion de vulnérabilités « nouvelles » par rapport aux vulnérabilités « existantes antérieurement ». Un nouveau champ de statut `new_needs_triage` vous permet de filtrer uniquement les nouvelles vulnérabilités à trier.
- Ancienneté : créez des politiques pour imposer des approbations lorsqu'une vulnérabilité dépasse le SLA (jours, mois ou années) en fonction de la date de détection.
- Correctif disponible : concentrez votre politique sur les dépendances pour lesquelles un correctif est disponible.
- Faux positif : excluez les faux positifs détectés par notre outil d'extraction des vulnérabilités, pour les résultats SAST, et via Rezilion pour nos résultats de Container Scanning et d'analyse des dépendances.

### Résultats de sécurité dans VS Code {#security-findings-in-vs-code}

<!-- categories: Editor Extensions, API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis, Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../editor_extensions/visual_studio_code/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10407)

{{< /details >}}

Vous pouvez désormais consulter les résultats de sécurité directement dans Visual Studio Code (VS Code), comme vous le feriez dans une merge request.

Vous pouviez déjà surveiller le statut de votre pipeline CI/CD, consulter les job logs CI/CD et parcourir votre workflow de développement dans le panneau GitLab Workflow. Désormais, après avoir créé une merge request pour votre branche, vous pouvez également consulter la liste des nouveaux résultats de sécurité qui n'avaient pas été trouvés précédemment sur la branche par défaut.

Cette nouvelle fonctionnalité fait partie de [GitLab Workflow](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow) pour VS Code. Les résultats des analyses de sécurité sont récupérés depuis une API ; cette fonctionnalité est donc disponible pour les développeurs utilisant GitLab.com ou des instances auto-hébergées exécutant GitLab 16.1 ou une version ultérieure.

### Utiliser le mot-clé `needs` avec des jobs parallèles {#use-the-needs-keyword-with-parallel-jobs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#needsparallelmatrix) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/254821)

{{< /details >}}

Le mot-clé `needs` est utilisé pour définir les relations de dépendance entre les jobs. Vous pouvez utiliser ce mot-clé pour configurer des jobs dépendant de jobs antérieurs spécifiques au lieu de suivre l'ordre des étapes. Lorsque les jobs dépendants sont terminés, le job peut démarrer immédiatement, accélérant ainsi votre pipeline.

Auparavant, il était impossible d'utiliser le mot-clé `needs` pour définir des jobs de [matrice parallèle](../../ci/yaml/_index.md#parallelmatrix) comme dépendants, mais dans cette version, nous avons activé la possibilité d'utiliser `needs` avec des jobs de matrice parallèle également. Vous pouvez désormais définir une relation de dépendance flexible avec les jobs de matrice parallèle, ce qui peut contribuer à accélérer encore davantage votre pipeline ! Plus vos jobs peuvent démarrer tôt, plus votre pipeline peut se terminer rapidement !

### Des runners GitLab SaaS plus puissants sur Linux {#more-powerful-gitlab-saas-runners-on-linux}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/linux.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/388165)

{{< /details >}}

Après avoir récemment mis à niveau l'ensemble de nos runners SaaS Linux, nous introduisons désormais les runners [SaaS sur Linux](../../ci/runners/hosted_runners/linux.md) `xlarge` et `2xlarge`. Équipés respectivement de 16 et 32 vCPU et entièrement intégrés à GitLab CI/CD, ces runners vous permettront de compiler et de tester votre application plus rapidement que jamais.

Nous sommes déterminés à offrir la vitesse de compilation CI/CD la plus rapide du secteur et attendons avec impatience de voir les équipes atteindre des cycles de retour encore plus courts et livrer des logiciels plus rapidement.

### Prise en charge du gestionnaire de secrets Azure Key Vault {#azure-key-vault-secrets-manager-support}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/secrets/azure_key_vault.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/271271)

{{< /details >}}

Les secrets stockés dans Azure Key Vault peuvent désormais être récupérés et utilisés facilement dans les jobs CI/CD. Notre nouvelle intégration simplifie le processus d'interaction avec Azure Key Vault via GitLab CI/CD, vous aidant à optimiser vos processus de compilation et de déploiement !

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Inclure ou exclure des projets archivés des résultats de recherche de projets {#include-or-exclude-archived-projects-from-project-search-results}

<!-- categories: Global Search -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/_index.md#include-archived-projects-in-search-results) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/413237)

{{< /details >}}

Vous pouvez désormais choisir d'inclure ou d'exclure les projets archivés des résultats de recherche. Par défaut, les projets archivés sont exclus. Cette fonctionnalité est disponible pour la recherche de projets dans GitLab. La prise en charge d'autres [portées de recherche globale](../../user/search/_index.md) est prévue dans les prochaines versions.

### Améliorations d'Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.3 inclut [Mattermost 8.0](https://mattermost.com/blog/mattermost-v8-0-is-now-available/). Cette version inclut des [mises à jour de sécurité](https://mattermost.com/security-updates/) et la mise à niveau depuis les versions antérieures est recommandée.
- Nos compilations Amazon Linux utilisent désormais [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/). Amazon Linux 2022 n'a jamais été officiellement disponible en version générale et a été remplacé par Amazon Linux 2023 ; nous avons donc adapté notre offre à la release mise à jour.

### Événement d'audit enregistré pour les modifications des paramètres d'application {#audit-event-recorded-for-applications-settings-change}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/282428)

{{< /details >}}

Les modifications des paramètres d'application au niveau de l'instance, du projet et du groupe sont désormais enregistrées dans le journal d'audit, accompagnées de l'indication de l'utilisateur ayant effectué la modification. Cela améliore l'audit des paramètres d'application aussi bien pour les instances auto-hébergées que pour les instances SaaS.

### Conserver les relecteurs de pull requests lors d'une importation depuis BitBucket Server {#preserve-pull-request-reviewers-when-importing-from-bitbucket-server}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/bitbucket.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/416611)

{{< /details >}}

Jusqu'à présent, l'importateur BitBucket Server n'importait pas les relecteurs de pull request (PR) et les classait à la place en tant que participants. Les informations sur les relecteurs de PR sont importantes d'un point de vue audit et conformité.

Dans GitLab 16.3, nous avons ajouté la prise en charge de l'importation correcte des relecteurs de PR depuis BitBucket. Dans GitLab, ils deviennent des relecteurs de merge request.

### Limites d'importation configurables disponibles dans les paramètres d'application {#configurable-import-limits-available-in-application-settings}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/_index.md#limits)

{{< /details >}}

Des limites codées en dur existent pour la migration par transfert direct et par importation de fichiers d'exportation.

Dans cette version, nous avons rendu certaines de ces limites configurables dans les paramètres d'application afin de permettre aux administrateurs GitLab auto-hébergés de les ajuster selon leurs besoins :

- [Taille maximale de la relation pouvant être téléchargée depuis l'instance source lors d'un transfert direct](../../administration/settings/account_and_limit_settings.md). Auparavant fixée à 5 Go. Sur GitLab.com, nous avons défini cette limite à 5 Go.
- [Taille maximale d'un fichier d'importation distant pouvant être téléchargé depuis des stockages d'objets distants (tels qu'AWS S3)](../../administration/settings/account_and_limit_settings.md). Auparavant fixée à 10 Go. Sur GitLab.com, nous avons défini cette limite à 10 Go.

Nous avons également ajouté un nouveau paramètre d'application [taille maximale du fichier décompressé pour les archives importées](../../administration/settings/account_and_limit_settings.md), qui remplace le feature flag `validate_import_decompressed_archive_size`. Cette limite était fixée à 10 Go. Sur GitLab.com, nous avons défini cette limite à 25 Go.

Grâce à ces nouveaux paramètres d'application, les administrateurs de GitLab auto-hébergé et de GitLab.com peuvent ajuster ces limites selon leurs besoins.

### La nouvelle navigation propose des thèmes de couleur {#new-navigation-has-color-themes-available}

<!-- categories: Navigation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/profile/preferences.md)

{{< /details >}}

Avec la nouvelle navigation activée, vous pouvez désormais sélectionner l'un des cinq thèmes de couleur disponibles et choisir la variante claire ou sombre pour chacun d'eux. Utilisez les thèmes pour identifier différents environnements ou choisissez votre couleur préférée.

### Aucun délai d'expiration d'exportation d'entité pour les migrations par transfert direct {#no-entity-export-timeout-for-migrations-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/import/_index.md#limits) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/392725)

{{< /details >}}

Jusqu'à présent, la migration de groupes et de projets par transfert direct était soumise à un délai d'expiration d'exportation de 90 minutes. Cette limite excluait de fait les grands projets de la migration, car seuls les projets pouvant être migrés en moins de 90 minutes étaient autorisés.

La limite supérieure du délai global de migration est de 4 heures ; le délai d'expiration d'exportation de 90 minutes n'était donc pas nécessaire. Dans ce jalon, la limite a été supprimée, permettant ainsi la migration de projets de plus grande taille.

### Prise en charge de la revendication de dépassement Azure AD {#support-for-azure-ad-overage-claim}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/group/saml_sso/group_sync.md#microsoft-azure-active-directory-integration) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/414875)

{{< /details >}}

GitLab SAML Group Sync prend désormais en charge la revendication de dépassement Azure AD (désormais connu sous le nom d'Entra ID), qui permet à un utilisateur d'avoir plus de 150 groupes associés à son compte. Le maximum précédent était de 150 groupes. Pour plus d'informations, consultez [les dépassements de groupes Microsoft](https://learn.microsoft.com/en-us/security/zero-trust/develop/configure-tokens-group-claims-app-roles#group-overages).

### Geo vérifie les wikis de groupe {#geo-verifies-group-wikis}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/geo/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/323897)

{{< /details >}}

Geo est désormais en mesure de détecter et de corriger la corruption de données des [wikis de groupe](../../user/project/wiki/group.md) au repos et en transit. Si vous utilisez Geo dans le cadre de votre stratégie de reprise après sinistre, cela contribue à vous protéger contre la perte de données en cas de basculement.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Validation de la syntaxe et du format du fichier CODEOWNERS {#codeowners-file-syntax-and-format-validation}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/codeowners/reference.md)

{{< /details >}}

Vous pouvez désormais voir dans l'interface si votre fichier `CODEOWNERS` contient des erreurs de syntaxe ou de formatage. La possibilité de spécifier des propriétaires du code offre une grande flexibilité, permettant aux utilisateurs de configurer plusieurs emplacements de fichiers, sections et règles. Grâce à cette nouvelle validation de syntaxe, les erreurs dans votre fichier `CODEOWNERS` seront affichées dans l'interface GitLab, facilitant ainsi la détection et la correction des problèmes. Les erreurs suivantes seront affichées :

- Entrées contenant des espaces.
- Sections non analysables.
- Propriétaires mal formés.
- Propriétaires inaccessibles.
- Aucun propriétaire.
- Moins d'une approbation requise.

Auparavant, le fichier `CODEOWNERS` ne validait pas les informations saisies dans le fichier. Cela pouvait conduire à la création de :

- Règles pour des fichiers/chemins qui n'existent pas.
- Règles qui créent des conflits avec d'autres règles existantes.
- Règles qui ne s'appliquent pas en raison d'une syntaxe incorrecte.

### Prise en charge de Kubernetes 1.27 {#kubernetes-127-support}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/420859)

{{< /details >}}

Cette version ajoute la prise en charge complète de Kubernetes version 1.27, publiée en avril 2023. Si vous utilisez Kubernetes, vous pouvez désormais mettre à niveau vos clusters vers la version la plus récente et profiter de toutes ses fonctionnalités.

Vous pouvez en savoir plus sur [notre politique de prise en charge de Kubernetes](../../user/clusters/agent/_index.md) et les autres versions de Kubernetes prises en charge.

### Afficher les noms des feature flags par retour à la ligne plutôt que par troncature {#wrap-feature-flag-names-instead-of-truncating}

<!-- categories: Feature Flags -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../operations/feature_flags.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/418147)

{{< /details >}}

Si vous avez utilisé des feature flags dans des versions précédentes de GitLab, vous avez peut-être remarqué que les noms de feature flags longs étaient tronqués. Cela rendait difficile la différenciation rapide de noms de feature flags similaires.

Dans GitLab 16.3, le nom complet du feature flag est affiché. Les noms longs passent à la ligne sur plusieurs lignes, si nécessaire.

### Noms pour les flux d'événements d'audit {#names-for-audit-event-streams}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Auparavant, les destinations de streaming d'événements d'audit étaient identifiées par l'URL de destination. Cela pouvait prêter à confusion lorsque vous configuriez plusieurs flux pour un même groupe ou une même instance, car vous deviez développer la destination dans l'interface pour voir quels filtres et en-têtes personnalisés avaient été appliqués.

Avec GitLab 16.3, vous pouvez désormais nommer les destinations de streaming d'événements d'audit afin de les identifier et de les distinguer lorsque vous disposez de plusieurs destinations de streaming définies.

### Expliquer cette vulnérabilité {#explain-this-vulnerability}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/application_security/vulnerabilities/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10368)

{{< /details >}}

GitLab met en évidence les vulnérabilités contenant des informations pertinentes ; cependant, il n'est parfois pas évident de savoir par où commencer. Il faut du temps pour rechercher et synthétiser les informations présentées dans l'enregistrement de vulnérabilité. De plus, il peut être difficile de déterminer comment corriger une vulnérabilité donnée. Avec cette version bêta, vous pouvez cliquer sur un bouton pour obtenir une explication et une recommandation sur la façon de remédier à la vulnérabilité, générées par l'IA.

### Les rapports de conformité renommés en Centre de conformité {#compliance-reports-renamed-to-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

Afin de faciliter la croissance des fonctionnalités liées à la conformité au-delà du simple reporting et vers la gestion, la section Rapports de conformité de GitLab a été renommée pour refléter le périmètre en expansion de ce domaine.

À partir de GitLab 16.3, les Rapports de conformité sont désormais connus sous le nom de Centre de conformité.

### Améliorer la précision des politiques de résultat d'analyse {#improve-accuracy-of-scan-result-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) \| [Epic associé](https://gitlab.com/gitlab-org/gitlab/-/issues/379108)

{{< /details >}}

Une politique de résultat d'analyse est un type de politique de sécurité permettant d'évaluer et de bloquer les merge requests en cas de violation de règles particulières. Les approbateurs peuvent examiner et approuver la modification, ou collaborer avec leurs équipes de développement pour résoudre les problèmes (tels que la correction de vulnérabilités de sécurité critiques).

Auparavant, nous comparions les vulnérabilités dans les dernières branches source et cible pour détecter toute nouvelle violation des règles de politique. Cependant, cela pourrait ne pas capturer les vulnérabilités détectées par des analyses s'exécutant à la suite de diverses sources de pipeline. Pour améliorer la précision, nous comparons désormais les derniers pipelines terminés pour chaque source de pipeline (à l'exception des pipelines parent-enfant). Cela garantira une évaluation plus complète et réduira les cas où des approbations sont requises de manière inattendue.

### Filtres d'événements d'audit de streaming au niveau de l'instance {#instance-level-streaming-audit-event-filters}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Dans GitLab 16.2, nous avons introduit le streaming d'événements d'audit au niveau de l'instance. Cependant, aucun filtre n'était disponible pour s'appliquer à ces flux.

Dans GitLab 16.3, vous pouvez désormais appliquer des filtres par type d'événement d'audit aux flux d'événements d'audit au niveau de l'instance. Grâce à l'ajout de ces filtres dans l'interface, vous pouvez capturer un sous-ensemble d'événements d'audit à envoyer à chaque emplacement de streaming, en vous concentrant uniquement sur les événements qui vous sont pertinents.

### Bot de sécurité pour déclencher les pipelines de politiques d'exécution d'analyse {#security-bot-to-trigger-scan-execution-policies-pipelines}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/scan_execution_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10756)

{{< /details >}}

Des utilisateurs bots de sécurité seront créés pour prendre en charge la gestion des tâches en arrière-plan et pour appliquer les politiques de sécurité pour tous les liens de projets de politique de sécurité nouvellement créés ou mis à jour. Cela simplifiera le processus pour les membres des équipes de sécurité et de conformité lors de la configuration et de l'application des politiques, en supprimant notamment la nécessité pour les mainteneurs de projets de politiques de sécurité de maintenir également l'accès `Developer` dans les projets de développement. Les utilisateurs bots de politiques de sécurité permettront également de clarifier davantage, pour les utilisateurs au sein d'un projet soumis à des politiques, quand les pipelines sont exécutés au nom d'une politique de sécurité, car cet utilisateur bot sera l'auteur du pipeline.

Lorsqu'un projet de politique de sécurité est lié à un groupe ou un sous-groupe, un bot de politique de sécurité sera créé dans chaque projet du groupe ou sous-groupe. Lorsqu'un lien est établi avec un groupe, un sous-groupe ou un projet individuel, un utilisateur bot de sécurité sera créé pour le projet concerné ou pour tout projet appartenant au groupe ou sous-groupe. Les groupes, sous-groupes ou projets disposant déjà d'un lien vers un projet de politique de sécurité ne seront pas affectés pour l'instant, mais les utilisateurs peuvent rétablir les liens existants pour bénéficier de cette fonctionnalité. Dans GitLab 16.4, nous prévoyons d'[activer les bots de sécurité](https://gitlab.com/gitlab-org/gitlab/-/issues/414376) sur tous les projets hébergés sur GitLab.com disposant de liens vers des projets de politique de sécurité existants.

### Mises à jour de l'analyseur SAST {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/analyzers.md) \| [Ticket associé](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST comprend [de nombreux analyseurs de sécurité](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) que l'équipe d'analyse statique de GitLab maintient, met à jour et prend en charge activement. Nous avons publié les mises à jour suivantes au cours du jalon de la release 16.3 :

- L'analyseur basé sur Kics a été mis à jour pour utiliser la version 1.7.5 du moteur Kics. Cette mise à jour inclut diverses corrections de bugs et apporte également des améliorations à la gestion des erreurs pour les auto-références dans JSON et YAML. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md?ref_type=heads#v414) pour plus de détails.
- L'analyseur basé sur Semgrep a été mis à jour pour ajouter la prise en charge de la spécification de références ambiguës lors des configurations personnalisées en passthrough. Nous avons également mis à jour le parseur SARIF pour utiliser le Nom plutôt que le Titre et ne plus faire échouer les analyses en cas de `toolExecutionNotifications` SARIF de niveau erreur. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md?ref_type=heads#v446) pour plus de détails.

Si vous [incluez le modèle SAST géré par GitLab](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) et exécutez GitLab 16.0 ou version ultérieure, vous recevez automatiquement ces mises à jour. Pour rester sur une version spécifique d'un analyseur et empêcher les mises à jour automatiques, vous pouvez [épingler sa version](../../user/application_security/sast/_index.md).

Pour les modifications précédentes, consultez les [mises à jour du mois dernier](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/#sast-analyzer-updates).

### Prise en charge de l'analyse des dépendances et des licences pour Java v21 {#dependency-and-license-scanning-support-for-java-v21}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/387307)

{{< /details >}}

L'analyse des dépendances et l'analyse des licences GitLab prennent désormais en charge l'analyse des fichiers de verrouillage Maven Java v21.

### Les tags de runner activent la configuration basée sur l'interface pour les analyses DAST à la demande {#runner-tags-enable-ui-based-configuration-of-on-demand-dast-scans}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/on-demand_scan.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/345430)

{{< /details >}}

Vous pouvez désormais utiliser des tags pour spécifier les runners à utiliser pour les analyses DAST à la demande. Avant la version 16.3, vous pouviez configurer les analyses DAST à l'aide de runners privés via des fichiers de configuration CI. Cette configuration basée sur l'interface permet une configuration efficace via l'interface pour la gestion des analyses DAST.

### Amélioration du suivi des vulnérabilités SAST {#improved-sast-vulnerability-tracking}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/5144)

{{< /details >}}

Le [suivi avancé des vulnérabilités](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) GitLab SAST rend le triage plus efficace en suivant les résultats à mesure que le code évolue. Nous avons publié deux améliorations dans GitLab 16.3 :

1. Prise en charge étendue des langages : en plus de sa [couverture existante](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking), nous avons activé le suivi avancé des vulnérabilités pour :
  - C et C++, dans l'analyseur basé sur Flawfinder.
  - Java, dans l'analyseur basé sur MobSF.
  - JavaScript, dans l'analyseur basé sur NodeJS-Scan.
1. Meilleur suivi : nous avons amélioré l'algorithme de suivi pour gérer les fonctions anonymes en JavaScript.

Cela s'appuie sur les extensions et améliorations précédentes [publiées dans GitLab 16.2](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/#improved-sast-vulnerability-tracking). Nous suivons les améliorations supplémentaires, notamment l'extension à d'autres langages, une meilleure gestion de davantage de constructions de langage, et un meilleur suivi pour Python et Ruby, dans l'epic [5144](https://gitlab.com/groups/gitlab-org/-/epics/5144).

Ces modifications sont incluses dans les [versions mises à jour](https://docs.gitlab.com/#sast-analyzer-updates) des [analyseurs](../../user/application_security/sast/analyzers.md) GitLab SAST. Les résultats de vulnérabilités de votre projet sont mis à jour avec de nouvelles signatures de suivi après que le projet a été analysé avec les analyseurs mis à jour. Vous n'avez pas besoin d'agir pour recevoir cette mise à jour, sauf si vous avez [épinglé les analyseurs SAST à une version spécifique](../../user/application_security/sast/_index.md).

### Réponse automatique aux clés API Postman exposées {#automatic-response-to-leaked-postman-api-keys}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gold
- Liens : [Documentation](../../user/application_security/secret_detection/automatic_response.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/403825)

{{< /details >}}

Nous avons intégré la détection des secrets à Postman pour mieux protéger les clients qui utilisent Postman dans leurs projets GitLab.

La détection des secrets recherche les [clés API Postman](https://learning.postman.com/docs/developer/postman-api/authentication/). Si une clé est exposée dans un projet public sur GitLab.com, GitLab envoie la clé exposée à Postman. Postman vérifie la clé, puis [notifie le propriétaire de la clé API Postman](https://learning.postman.com/docs/administration/token-scanner/#protecting-postman-api-keys-in-gitlab).

Cette intégration est activée par défaut pour les projets ayant [activé la détection des secrets](../../user/application_security/secret_detection/_index.md) sur GitLab.com. L'analyse de détection des secrets est disponible dans toutes les éditions GitLab, mais une réponse automatique aux secrets exposés n'est actuellement disponible que dans les projets Ultimate.

Consultez [l'article de blog Postman sur cette intégration](https://blog.postman.com/protecting-your-postman-api-keys-in-gitlab/) pour plus de détails.

### Exposer le nom du pipeline en tant que variable CI/CD prédéfinie {#expose-pipeline-name-as-a-predefined-cicd-variable}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/variables/predefined_variables.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/420002)

{{< /details >}}

Les noms de pipeline définis avec le mot-clé [`workflow:name`](../../ci/yaml/_index.md#workflowname) sont désormais accessibles via la variable CI/CD prédéfinie `$CI_PIPELINE_NAME`.

### GitLab Runner 16.3 {#gitlab-runner-163}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.3 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Configurer le répertoire de clonage du projet comme sûr par défaut](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29022)

#### Corrections de bugs {#bug-fixes}

- [Runner v16.2.0 non disponible dans le dépôt Debian/RHEL](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36048)
- [GitLab-runner avec l'exécuteur shell échoue parfois à récupérer les sous-modules](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26993)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-3-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Corrections de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.3)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.3)
- [Améliorations de l'interface](https://papercuts.gitlab.com/?milestone=16.3)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
