---
stage: Release Notes
group: Monthly Release
date: 2023-07-22
title: "Notes de release GitLab 16.2"
description: "GitLab 16.2 publié avec une toute nouvelle expérience d'éditeur de texte enrichi"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 22 juillet 2023, GitLab 16.2 a été publié avec les fonctionnalités suivantes.

Nous tenons également à remercier tous nos contributeurs, dont le contributeur notable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

Xing Xin a été reconnu pour une récente merge request visant à [utiliser un dépôt en quarantaine pour la détection de conflits](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6008). Karthik Nayak, ingénieur senior en backend chez GitLab, a déclaré : « L'utilisation de dépôts en quarantaine permet d'éviter les objets obsolètes dans les dépôts Git si une opération échoue en cours d'exécution. Xing a su identifier un RPC où nous pouvions introduire un dépôt en quarantaine. Il a également répondu aux retours avec de bonnes pistes et a su nous convaincre sur certaines questions grâce à sa bonne connaissance de la base de code. »

Xing contribue à GitLab et au projet Gitaly depuis 2020. Développeur chez ByteDance, Xing travaille également avec Alibaba Cloud et AntGroup, en se concentrant sur l'hébergement de code et l'efficacité des équipes d'ingénierie. Xing a ajouté que « la communauté GitLab m'a beaucoup inspiré, tant pour les meilleures pratiques de gestion du code que pour les commentaires de tous les relecteurs bienveillants. J'espère grandir avec la communauté. »

Missy Davies est l'une des membres les plus récentes du programme [GitLab Heroes](https://contributors.gitlab.com/docs/previous-heroes). Elle a été reconnue pour ses [nombreuses contributions récentes](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&assignee_username=missy-davies) dans les projets GitLab, notamment plusieurs merge requests pour les groupes [Pipeline Execution](https://handbook.gitlab.com/handbook/engineering/development/ops/verify/pipeline-execution/) et [Environments](https://handbook.gitlab.com/handbook/engineering/development/ops/deploy/environments/).

Missy est également un membre actif de la communauté des contributeurs GitLab et participe régulièrement aux événements communautaires, aux permanences et sur le serveur Discord. Lee Tickett et Marco Zille, membres de l'équipe principale de la communauté GitLab, ont tous deux mis en avant l'engagement de Missy avec la communauté au sens large. Lee a ajouté que Missy a été « en accord avec nos valeurs ».

Missy a partagé qu'elle trouve un grand plaisir dans son implication croissante dans le monde de l'open source chez GitLab. Elle apprécie le fort sentiment de communauté, les opportunités d'apprentissage continu et la passion partagée pour les principes de l'open source. En tant que développeuse backend avec une expérience en Ruby on Rails et en Python, Missy est une contributrice GitLab influente depuis 2022.

Un grand merci à tous nos contributeurs de la communauté pour cette release passée 🙌

## Fonctionnalités principales {#primary-features}

### Toute nouvelle expérience d'éditeur de texte enrichi {#all-new-rich-text-editor-experience}

<!-- categories: Team Planning, Portfolio Management, Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/rich_text_editor.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10378)

{{< /details >}}

GitLab 16.2 propose une toute nouvelle expérience d'édition de texte enrichi ! Cette nouvelle fonctionnalité est disponible pour tous, comme alternative à l'expérience d'édition Markdown existante.

Pour beaucoup, l'utilisation de l'éditeur de texte brut pour les commentaires ou les descriptions constitue un obstacle à la collaboration. Se souvenir de la syntaxe pour les références d'images ou travailler avec de longs tableaux peut être fastidieux, même pour ceux qui maîtrisent relativement bien la syntaxe. L'éditeur de texte enrichi vise à supprimer ces obstacles en offrant une expérience d'édition « ce que vous voyez est ce que vous obtenez » et une base extensible sur laquelle nous pouvons construire des interfaces d'édition personnalisées pour des éléments tels que les diagrammes, les intégrations de contenu, la gestion des médias, et bien plus encore.

L'éditeur de texte enrichi est désormais disponible dans tous les tickets, epics et merge requests. Nous prévoyons de le rendre disponible dans d'autres endroits de GitLab prochainement. Vous pouvez suivre notre progression [ici](https://gitlab.com/groups/gitlab-org/-/epics/10378).

Nous sommes fiers de la nouvelle expérience d'édition et sommes impatients de connaître votre avis. Veuillez essayer le nouvel éditeur de texte enrichi et nous faire part de votre expérience dans [ce ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/416293).

### GitLab déclenche une synchronisation Flux sans aucune configuration {#gitlab-triggers-a-flux-synchronization-without-any-configuration}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/gitops.md#immediate-git-repository-reconciliation) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/392852)

{{< /details >}}

Par défaut, Flux synchronise les manifestes Kubernetes à intervalles réguliers. Le déclenchement d'une réconciliation immédiatement lorsqu'un manifeste change nécessite par défaut une configuration supplémentaire. Avec l'agent GitLab pour Kubernetes, vous pouvez pousser une modification vers votre manifeste et déclencher une synchronisation Flux automatiquement.

### Prise en charge de la signature sans clé avec Cosign {#support-for-keyless-signing-with-cosign}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Free, Silver, Gold
- Liens : [Documentation](../../ci/yaml/signing_examples.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/10254)

{{< /details >}}

Le stockage, la rotation et la gestion corrects des clés de signature peuvent s'avérer difficiles et nécessitent généralement la mise en place d'un système de gestion des clés (KMS) distinct. GitLab prend désormais en charge la signature sans clé grâce à une intégration native avec l'outil Sigstore Cosign, qui permet une signature facile, pratique et sécurisée dans le pipeline CI/CD de GitLab. La signature est effectuée à l'aide d'une clé de signature à durée de vie très courte. La clé est générée via un jeton obtenu auprès du serveur GitLab en utilisant l'identité OIDC de l'utilisateur qui a exécuté le pipeline. Ce jeton inclut des revendications uniques qui certifient que le jeton a été généré par un pipeline CI/CD.

Pour commencer à utiliser la signature sans clé pour vos artefacts de build, images de conteneurs et packages, les utilisateurs n'ont qu'à ajouter quelques lignes à leur fichier CI/CD, comme [indiqué dans notre documentation](../../ci/yaml/signing_examples.md).

### Palette de commandes {#command-palette}

<!-- categories: Navigation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/command_palette.md)

{{< /details >}}

Si vous êtes un utilisateur avancé, utiliser le clavier pour naviguer et effectuer des actions peut s'avérer frustrant. Désormais, une nouvelle palette de commandes vous aide à accomplir davantage de tâches au clavier.

Pour activer la palette de commandes, ouvrez la barre latérale gauche et cliquez sur **Search GitLab** (🔍) ou utilisez la touche /.

Saisissez l'un des caractères spéciaux :

- > - Créer un nouvel objet ou trouver un élément de menu
- @ - Rechercher un utilisateur
- : - Rechercher un projet
- / - Rechercher des fichiers de projet dans la branche par défaut du dépôt

### Améliorations de GitLab Duo Code Suggestions propulsées par Google AI {#gitlab-duo-code-suggestions-improvements-powered-by-google-ai}

<!-- categories: Code Suggestions -->

{{< details >}}

- Édition : Gold, Silver, Free
- Liens : [Documentation](../../user/project/repository/code_suggestions/_index.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/9814)

{{< /details >}}

Code Suggestions utilise désormais les modèles de fondation personnalisables de Google Cloud et l'infrastructure d'IA générative ouverte, avec la prise en charge de l'IA générative dans Vertex AI.

Les suggestions de code GitLab sont acheminées via la [gouvernance des données](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/zero-data-retention) et l'[IA responsable](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/responsible-ai) de l'API Google Vertex AI Codey. Depuis le 22 juillet, Code Suggestions effectue des inférences sur le fichier actuellement ouvert et dispose d'une fenêtre de contexte de 2 048 jetons et d'une limite de 8 192 caractères. Cette limite inclut le contenu avant et après le curseur, le nom du fichier et le type d'extension.

[Les API Google Vertex AI Codey](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview#supported_coding_languages) prennent directement en charge : C++, C#, Go, Google SQL, Java, JavaScript, Kotlin, PHP, Python, Ruby, Rust, Scala, Swift, TypeScript. Et pour les fichiers d'infrastructure, prennent en charge : Google Cloud CLI, Kubernetes Resource Model (KRM) et Terraform.

Nous itérons en permanence pour améliorer Code Suggestions. Essayez-le et [partagez vos commentaires avec nous](https://gitlab.com/gitlab-org/gitlab/-/issues/405152).

### Suivez vos expériences de modèles d'apprentissage automatique {#track-your-machine-learning-model-experiments}

<!-- categories: MLOps -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/ml/experiment_tracking/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125758)

{{< /details >}}

Lorsque les équipes de data science créent des modèles d'apprentissage automatique (ML), elles expérimentent souvent différents paramètres, configurations et techniques d'ingénierie des caractéristiques afin d'améliorer les performances du modèle. Les équipes de data science doivent garder une trace de toutes ces métadonnées et des artefacts associés afin de pouvoir reproduire l'expérience ultérieurement. Ce travail n'est pas trivial et les solutions existantes nécessitent une configuration complexe.

Grâce aux expériences de modèles d'apprentissage automatique, les équipes de data science peuvent enregistrer des paramètres, des métriques et des artefacts directement dans GitLab, facilitant ainsi l'accès à leurs modèles les plus performants. Cette fonctionnalité est en version expérimentale.

### Nouvelle couche de personnalisation pour le tableau de bord des flux de valeur {#new-customization-layer-for-the-value-streams-dashboard}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/analytics/value_streams_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/388890)

{{< /details >}}

Nous avons ajouté un nouveau fichier de configuration au [tableau de bord des flux de valeur](https://youtu.be/EA9Sbks27g4) pour faciliter la personnalisation des données et de l'apparence du tableau de bord. Dans ce fichier, vous pouvez définir différents paramètres et réglages, tels que le titre, la description, ainsi que le nombre de panneaux et de filtres. Le fichier est piloté par un schéma et géré avec des systèmes de contrôle de version tels que Git. Cela permet de suivre et de conserver un historique des modifications de configuration, de revenir à des versions précédentes si nécessaire, et de collaborer efficacement avec les membres de l'équipe.

La nouvelle configuration inclut également la possibilité de filtrer les métriques par labels. Vous pouvez ajuster le [panneau de comparaison des métriques](https://about.gitlab.com/blog/getting-started-with-value-streams-dashboard/) en fonction de vos domaines d'intérêt, filtrer les informations non pertinentes et vous concentrer sur les données les plus pertinentes pour votre analyse ou votre processus de prise de décision.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Le wiki au niveau du groupe désormais disponible dans la recherche avancée {#group-level-wiki-now-available-in-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/search/advanced_search.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/336100)

{{< /details >}}

Avec cette release, nous avons étendu la recherche avancée pour inclure les [wikis au niveau du groupe](../../user/project/wiki/group.md). Les utilisateurs pourront désormais trouver du contenu dans ces wikis plus facilement et plus rapidement qu'auparavant.

### Améliorations d'Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- Notre version de Redis est mise à jour vers la dernière version stable, [`7.0.12`](https://raw.githubusercontent.com/redis/redis/7.0/00-RELEASENOTES).
- Pour les nouvelles installations de GitLab, vous pouvez désormais opter pour [PostgreSQL 14](https://www.postgresql.org/docs/14/release-14.html#id-1.11.6.12.4).

### Afficher les déploiements à partir des tickets Jira mentionnés dans les commits GitLab {#view-deployments-from-jira-issues-mentioned-in-gitlab-commits}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/jira/development_panel.md#information-displayed-in-the-development-panel) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/300031)

{{< /details >}}

Auparavant, les déploiements GitLab étaient liés depuis le panneau de développement Jira uniquement lorsqu'un ticket Jira était mentionné dans la branche ou la merge request associée au déploiement. Cela était souvent peu pratique pour les utilisateurs, car cela les obligeait à déployer à partir de merge requests, ce qui ne correspond pas au workflow habituel.

Avec cette release, les déploiements GitLab analysent également les mentions de tickets Jira dans les messages des 5 000 derniers commits effectués sur la branche après le dernier déploiement réussi. Le déploiement GitLab est associé à tous les tickets Jira mentionnés.

### Suppression automatique des utilisateurs non confirmés {#automatic-deletion-of-unconfirmed-users}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/moderate_users.md#automatically-delete-unconfirmed-users) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)

{{< /details >}}

Lorsque des invitations sont envoyées à une adresse e-mail incorrecte, elles ne peuvent jamais être confirmées. Auparavant, les administrateurs devaient supprimer manuellement ces comptes. Désormais, les administrateurs peuvent activer la suppression automatique des utilisateurs non confirmés après un nombre de jours spécifié. De même, sur GitLab.com, les comptes non confirmés seront automatiquement supprimés après [le nombre de jours spécifié](../../user/gitlab_com/_index.md).

### Sécurité améliorée pour les jetons de flux {#improved-security-for-feed-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../security/tokens/_index.md#feed-token) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/414257)

{{< /details >}}

Les jetons de flux ont été rendus plus sécurisés en ne fonctionnant que pour l'URL pour laquelle ils ont été générés. Cela réduit la portée des flux pouvant être lus si le jeton a été divulgué.

### Application GitLab pour Slack disponible sur GitLab auto-géré {#gitlab-for-slack-app-available-on-self-managed-gitlab}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/slack_app.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/358872)

{{< /details >}}

Avec cette release, l'application GitLab pour Slack est disponible sur les instances auto-gérées. Sur GitLab auto-géré, vous pouvez créer une copie de l'application GitLab pour Slack à partir d'un [fichier manifeste](https://api.slack.com/reference/manifests#creating_apps) et installer cette copie dans votre espace de travail Slack. Chaque copie est privée et ne peut pas être distribuée publiquement.

Pour créer et configurer l'application, consultez [l'administration de l'application GitLab pour Slack](../../administration/settings/slack_app.md).

### Accélérer les imports depuis GitHub en utilisant plusieurs jetons d'accès {#speed-up-imports-from-github-using-multiple-access-tokens}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/import.md#import-repository-from-github) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/337232)

{{< /details >}}

Par défaut, l'importateur GitHub utilise un seul jeton d'accès lors de l'importation de projets depuis GitHub vers GitLab. Un jeton d'accès pour un compte utilisateur est généralement soumis à une limite de débit de 5 000 requêtes par heure. Cela peut réduire considérablement la vitesse de l'importateur dans les cas suivants :

- Importation de plusieurs projets de petite à moyenne taille.
- Importation d'un seul projet massif avec beaucoup de données.

Avec cette release, vous pouvez transmettre une liste de jetons d'accès à l'API de l'importateur GitHub afin que l'API puisse les faire pivoter lorsque la limite de débit est atteinte. Lors de l'utilisation de plusieurs jetons d'accès :

- Les jetons ne peuvent pas provenir du même compte, car ils partageraient tous la même limite de débit.
- Les jetons doivent avoir les mêmes autorisations et des privilèges suffisants sur les dépôts à importer.

### Synchroniser le rôle auditeur avec le fournisseur OIDC {#sync-auditor-role-with-oidc-provider}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/auth/oidc.md#auditor-groups) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/389321)

{{< /details >}}

Vous pouvez désormais synchroniser les groupes OIDC avec le rôle `auditor` dans GitLab. Cela permet à la gestion automatisée du cycle de vie des utilisateurs facilitée par OIDC d'utiliser le rôle `auditor`, qui n'était auparavant pas pris en charge dans le mappage des rôles.

Merci à [Marin Hannache](https://gitlab.com/mareo) pour sa contribution !

### Pages de connexion et d'inscription améliorées {#improved-sign-in-and-sign-up-pages}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/sign_up_restrictions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/385651)

{{< /details >}}

Les pages de connexion et d'inscription de GitLab ont été améliorées :

- Mise en page à deux colonnes lorsque du texte personnalisé est présent.
- Correction du problème avec la case à cocher `Remember me` avec plusieurs LDAP.
- Expérience en mode sombre améliorée.
- Boutons d'authentification unique plus grands.
- Pied de page déplacé en bas de la page pour éviter de masquer les éléments de la page.
- Sélecteur de langue ajouté à la page de connexion SAML.
- Vérifications du mot de passe activées dans la page d'essai d'inscription.

### La sauvegarde ajoute la possibilité d'ignorer des projets {#backup-adds-the-ability-to-skip-projects}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)

{{< /details >}}

L'outil de sauvegarde et de restauration intégré ajoute la possibilité d'ignorer des dépôts spécifiques. La tâche Rake accepte désormais une liste de chemins de groupes ou de projets séparés par des virgules à ignorer lors de la sauvegarde ou de la restauration en utilisant la nouvelle variable d'environnement `SKIP_REPOSITORIES_PATHS`. Cela vous permettra d'ignorer, par exemple, les projets obsolètes ou archivés qui n'évoluent pas dans le temps, vous faisant ainsi économiser a) du temps en accélérant l'exécution de la sauvegarde, et b) de l'espace en n'incluant pas ces données dans le fichier de sauvegarde. Merci à [Yuri Konotopov](https://gitlab.com/nE0sIghT) pour cette [contribution communautaire](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/196) !

### Geo ajoute la resynchronisation et la revérification individuelles pour tous les composants {#geo-add-individual-resync-and-reverification-for-all-components}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/geo/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/364727)

{{< /details >}}

Geo ajoute la possibilité de resynchroniser et de revérifier des éléments individuels pour tous les types de composants gérés par le [framework en libre-service](../../development/geo/framework.md). Vous pouvez désormais forcer une opération de resynchronisation ou de revérification sur n'importe quel élément individuel géré par Geo via l'interface utilisateur. Cela peut aider à accélérer une opération de resynchronisation ou de revérification pour les éléments en échec, ou après l'application de modifications pour corriger des erreurs de synchronisation ou de vérification.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Amélioration des performances de téléchargement Git LFS {#improve-git-lfs-download-performance}

<!-- categories: Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../topics/git/lfs/_index.md)

{{< /details >}}

Pour les instances qui stockent des objets LFS dans un stockage d'objets sans [téléchargement par proxy activé](../../administration/object_storage.md#proxy-download), GitLab traite désormais les requêtes LFS en masse. Cela améliore considérablement les performances du téléchargement d'un grand nombre d'objets LFS.

Auparavant, en raison de la façon dont les objets LFS étaient récupérés, GitLab créait de nombreuses requêtes très petites qui vérifiaient les autorisations des utilisateurs et redirigeaient vers l'objet stocké en externe. Cela avait le potentiel de provoquer une charge importante et une réduction des performances. Avec ce correctif, nous avons réduit la charge sur l'instance GitLab principale et offert une expérience de téléchargement plus rapide à nos utilisateurs.

### Installer l'agent pour Kubernetes en utilisant des volumes supplémentaires dans le chart Helm {#install-the-agent-for-kubernetes-using-extra-volumes-in-the-helm-chart}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/install/_index.md#customize-the-helm-installation) \| [Ticket associé](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/issues/33)

{{< /details >}}

Le composant `agentk` de l'agent pour Kubernetes nécessite un jeton pour s'authentifier auprès de GitLab. Auparavant, vous pouviez fournir le jeton tel quel, ou en tant que référence au secret Kubernetes contenant le jeton. Cependant, vous pourriez opérer dans un environnement où le secret est déjà disponible dans un volume, et préférer monter ce volume plutôt que de créer un secret distinct. Depuis GitLab 16.2, le chart Helm de l'agent GitLab intègre cette fonctionnalité supplémentaire grâce à une contribution communautaire de [Thomas Spear](https://gitlab.com/tspearconquest).

### Prise en charge des variables CI personnalisées dans l'éditeur de politiques d'exécution de scan {#support-for-custom-ci-variables-in-the-scan-execution-policies-editor}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/scan_execution_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9566)

{{< /details >}}

Vous pouvez désormais définir des variables CI personnalisées, y compris leurs valeurs, dans l'éditeur de politiques d'exécution de scan. Les variables CI définies dans une politique remplacent les variables correspondantes définies dans les projets appliqués par la politique. Par exemple, une politique peut définir une variable CI `SAST_EXCLUDED_ANALYZERS` sur `brakeman`. Lorsque le scanner est appliqué dans un projet, il s'exécutera avec la variable définie sur `brakeman`, indépendamment de toute variable définie dans la configuration CI du projet. Pour chaque type de scan, vous pouvez définir des valeurs pour les variables par défaut et créer des paires clé-valeur personnalisées pour les variables CI personnalisées. Cela rend la personnalisation d'une politique d'exécution de scan plus rapide et plus facile.

### Autoriser les politiques d'exécution de scan à activer les pipelines CI/CD dans les projets en développement {#allow-scan-execution-policies-to-enable-cicd-pipelines-in-development-projects}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/scan_execution_policies.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/6880)

{{< /details >}}

Dans les versions précédentes de GitLab, les politiques de sécurité n'étaient pas appliquées aux projets sans fichier `.gitlab-ci.yml`, ni là où AutoDevOps était désactivé. Dans GitLab 16.2, les politiques de sécurité activent implicitement les pipelines CI/CD sur les projets ne contenant pas de fichier `.gitlab-ci.yml`. Il s'agit d'une nouvelle étape dans la garantie de la conformité des politiques de sécurité et vous permet d'appliquer la détection des secrets, l'analyse statique, ou tout autre job pour lequel des builds ne sont pas nécessaires.

### Cibler les branches « Default » ou « Protected » dans les politiques de sécurité {#target-default-or-protected-branches-in-security-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9468)

{{< /details >}}

Les politiques d'exécution de scan et les politiques de résultat de scan vous permettront de définir la portée d'application aux branches qui sont des branches « Default » ou des « Protected branches » dans les nombreux projets appliqués par une politique. Plutôt que d'exiger que les politiques spécifient explicitement les noms de branches, les politiques peuvent être appliquées de manière plus large et s'assurer que les branches avec des noms atypiques ne sont pas exclues de la conformité.

Les règles de branche peuvent être configurées dans nos différents types de règles de politique de sécurité en utilisant le champ `branch_type` :

- [Types de règles Scan_finding pour les politiques de résultat de scan](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type)
- [Types de règles License_finding pour les politiques de résultat de scan](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type)
- [Types de règles Pipeline pour les politiques d'exécution de scan](../../user/application_security/policies/scan_execution_policies.md#pipeline-rule-type)
- [Types de règles Schedule pour les politiques d'exécution de scan](../../user/application_security/policies/scan_execution_policies.md#schedule-rule-type)

### Diffusion des événements d'audit vers Google Cloud Logging {#audit-event-streaming-to-google-cloud-logging}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Vous pouvez désormais sélectionner Google Cloud Logging comme destination pour les flux d'événements d'audit.

Auparavant, vous deviez utiliser les en-têtes pour tenter de construire une requête que Google Cloud Logging accepterait. Cette méthode était sujette aux erreurs et pouvait être difficile à déboguer.

Désormais, vous pouvez sélectionner Google Cloud Logging comme destination pour le flux et fournir votre ID de projet, votre e-mail client, votre ID de journal et votre clé privée pour une intégration plus fluide.

### Export du rapport sur les cadres de conformité {#compliance-frameworks-report-export}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md#export-a-report-of-compliance-frameworks-on-projects-in-a-group)

{{< /details >}}

Vous pouvez désormais exporter un rapport sur les cadres de conformité et leurs projets associés dans un fichier CSV.

Avec l'ajout du rapport sur les cadres de conformité au niveau du groupe, vous avez pu voir et gérer les projets auxquels s'appliquent vos cadres de conformité.

Avec le nouvel export, vous pouvez conserver une copie de ce fichier à titre de référence. Vous pourriez conserver ce fichier comme source unique de vérité pour l'état idéal de vos relations entre projets et cadres de conformité. Ou vous pourriez envoyer ce fichier aux personnes de votre organisation qui ne travaillent pas dans GitLab, mais qui souhaitent savoir quels projets sont associés à quels cadres.

### Liste des dépendances au niveau du groupe/sous-groupe {#groupsub-group-level-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/8090)

{{< /details >}}

Lors de la révision d'une liste de dépendances, il est important d'avoir une vue d'ensemble. La gestion des dépendances au niveau du projet est problématique pour les grandes organisations qui souhaitent auditer leurs dépendances dans l'ensemble de leurs projets. Avec cette release, vous pouvez voir toutes les dépendances au niveau du projet ou du groupe, y compris les sous-groupes. Cette fonctionnalité est désactivée par défaut derrière le feature flag `group_level_dependencies`.

### Autoriser le push initial vers les branches protégées {#allow-initial-push-to-protected-branches}

<!-- categories: Compliance Management, Source Code Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/repository/branches/default.md#protect-initial-default-branches)

{{< /details >}}

Dans les versions précédentes de GitLab, lorsqu'une branche par défaut était entièrement protégée, seuls les mainteneurs et les propriétaires du projet pouvaient pousser un commit initial vers une branche par défaut.

Cela posait des problèmes aux développeurs qui créaient un nouveau projet, mais ne pouvaient pas pousser un commit initial car seule la branche par défaut existait.

Avec le paramètre **Entièrement protégée après la poussée initiale**, les développeurs peuvent pousser le commit initial vers la branche par défaut d'un dépôt, mais ne peuvent plus pousser de commits vers la branche par défaut par la suite. Comme lorsqu'une branche est entièrement protégée, les mainteneurs du projet peuvent toujours pousser vers la branche par défaut, mais personne ne peut forcer le push.

### Diffusion des événements d'audit au niveau de l'instance {#instance-level-streaming-audit-events}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Avant GitLab 16.1, seuls les événements d'audit provenant des groupes principaux pouvaient être diffusés vers une destination externe.

Désormais, les administrateurs d'instance peuvent ajouter une destination de diffusion pour les événements d'audit produits au niveau de l'instance.

### Interface de filtrage des événements d'audit en streaming {#streaming-audit-event-filtering-ui}

<!-- categories: Audit Events -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

Dans les versions précédentes de GitLab, vous deviez utiliser l'API GraphQL pour ajouter des filtres de type d'événement d'audit à vos flux d'événements d'audit.

Désormais, vous pouvez utiliser le menu déroulant de filtre dans l'interface GitLab pour voir tous les types d'événements d'audit disponibles, regroupés par domaine GitLab auquel ils sont pertinents, et rechercher les types exacts que vous souhaitez envoyer dans un flux.

Cela réduit considérablement le temps nécessaire pour ajouter un filtrage aux flux d'événements d'audit, car vous n'avez plus besoin d'extraire l'intégralité de la liste via l'API ni de la parcourir manuellement.

### Suggestions de diff interactives dans les merge requests {#interactive-diff-suggestions-in-merge-requests}

<!-- categories: Team Planning, Portfolio Management, Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/reviews/suggestions.md#using-the-rich-text-editor) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/406726)

{{< /details >}}

Lorsque vous suggérez des modifications dans une merge request, vous pouvez désormais modifier vos suggestions plus rapidement. Dans un commentaire, passez à l'éditeur de texte enrichi et utilisez l'interface pour vous déplacer de haut en bas dans les lignes de texte. Avec cette modification, vous pouvez visualiser vos suggestions exactement telles qu'elles apparaîtront lorsque le commentaire sera publié.

L'éditeur de texte enrichi est une nouvelle façon d'éditer dans GitLab. Il est disponible dans les merge requests, mais aussi aux côtés de l'éditeur de texte brut dans les tickets et les epics.

Nous prévoyons de rendre l'éditeur de texte enrichi disponible dans d'autres zones de GitLab prochainement et nous travaillons activement sur ce point. Vous pouvez suivre notre progression [ici](https://gitlab.com/groups/gitlab-org/-/epics/10378).

### Importer des packages PyPI avec des pipelines CI/CD {#import-pypi-packages-with-cicd-pipelines}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/package_registry/_index.md#to-import-packages) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/389339)

{{< /details >}}

Vous envisagez de migrer votre dépôt PyPI vers GitLab, mais vous n'avez pas encore pu investir le temps nécessaire pour la migration ? Dans cette release, GitLab lance la première version d'un importateur de packages PyPI.

Vous pouvez désormais utiliser l'outil Packages Importer pour importer des packages depuis n'importe quel registre compatible PyPI, comme Artifactory.

### Ajouter des réactions emoji aux commentaires sur les designs importés {#add-emoji-reactions-to-comments-on-uploaded-designs}

<!-- categories: Design Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/emoji_reactions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/29756)

{{< /details >}}

Vous pouvez désormais exprimer vos pensées de manière plus créative en ajoutant des réactions emoji aux commentaires dans [Design Management](../../user/project/issues/design_management.md). Cette fonctionnalité ajoute une touche de convivialité et de facilité à la collaboration, favorisant une meilleure communication et permettant aux équipes de fournir des retours rapides de manière plus expressive.

### Mises à jour de l'analyseur SAST {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/analyzers.md) \| [Ticket associé](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST comprend [de nombreux analyseurs de sécurité](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) que l'équipe d'analyse statique de GitLab maintient, met à jour et prend en charge activement.

Au cours du jalon de release 16.2, nos modifications se sont concentrées sur l'analyseur basé sur Semgrep et les règles maintenues par GitLab qu'il utilise pour l'analyse. Nous avons publié les modifications suivantes :

- Clarification des explications et des conseils pour les règles JavaScript, en s'appuyant sur les [améliorations pour d'autres langages publiées dans GitLab 16.1](https://about.gitlab.com/releases/2023/06/22/gitlab-16-1-released/#clearer-guidance-and-better-coverage-for-sast-rules)
- Mise à jour des règles pour détecter des vulnérabilités supplémentaires en Java et JavaScript.
- Modification de la configuration par défaut pour les fichiers ignorés lors des analyses, en :
  - Supprimant l'exclusion de `.gitignore`. Merci à [`@SimonGurney`](https://gitlab.com/SimonGurney) pour cette contribution communautaire.
  - Prenant en compte les fichiers `.semgrepignore` définis localement. Merci à [`@hmrc.colinameigh`](https://gitlab.com/hmrc.colinameigh) pour cette contribution communautaire.
- Amélioration d'une règle liée à l'aliasing de mémoire en Go. Merci à [`@tyage`](https://gitlab.com/tyage) pour cette contribution communautaire.
- Suppression d'un suffixe `-1` ajouté aux ID de règles Semgrep pour les règles JavaScript. Cela a été ajouté dans GitLab 16.0 comme effet secondaire d'une modification non liée, mais interférait avec les commentaires `semgrepignore` existants des clients.

Consultez le [CHANGELOG de `semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v440) et le [CHANGELOG de `sast-rules`](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blame/main/CHANGELOG.md) pour plus de détails. Nous suivons les améliorations supplémentaires apportées aux ensembles de règles gérés par GitLab dans l'epic [10907](https://gitlab.com/groups/gitlab-org/-/epics/10907).

Si vous [incluez le modèle SAST géré par GitLab](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) et exécutez GitLab 16.0 ou version ultérieure, vous recevez automatiquement ces mises à jour. Pour rester sur une version spécifique d'un analyseur et empêcher les mises à jour automatiques, vous pouvez [épingler sa version](../../user/application_security/sast/_index.md).

Pour les modifications précédentes, consultez les [mises à jour du mois dernier](https://about.gitlab.com/releases/2023/06/22/gitlab-16-1-released/#sast-analyzer-updates).

### Mises à jour de la détection des secrets {#secret-detection-updates}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/_index.md) \| [Ticket associé](../../user/application_security/_index.md)

{{< /details >}}

Nous publions régulièrement des mises à jour de l'analyseur de détection des secrets GitLab. Au cours du jalon GitLab 16.2, nous avons :

- Ajouté des [règles de détection gérées par GitLab](../../user/application_security/secret_detection/_index.md) pour :
  - Les clés API OpenAI.
  - Les jetons d'accès personnels et de projet CircleCI. Merci à [`@nathanwfish`](https://gitlab.com/nathanwfish) pour cette contribution communautaire.
- Amélioration des performances des règles utilisant l'optimisation `keywords`.
- Correction d'[un ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/358073) où les résultats de la détection des secrets créaient des liens permanents vers le mauvais emplacement dans le dépôt.

Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/CHANGELOG.md#v514) pour plus de détails.

Si vous [utilisez le modèle de détection des secrets géré par GitLab](../../user/application_security/secret_detection/_index.md) ([`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)) et exécutez GitLab 16.0 ou version ultérieure, vous recevez automatiquement ces mises à jour. Pour rester sur une version spécifique d'un analyseur et empêcher les mises à jour automatiques, vous pouvez [épingler sa version](../../user/application_security/secret_detection/_index.md).

Pour les modifications précédentes, consultez [la mise à jour la plus récente de la détection des secrets](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#secret-detection-updates).

### Prise en charge de NuGet v2 dans l'analyse des dépendances et des licences {#support-for-nuget-v2-in-dependency-and-license-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/398680)

{{< /details >}}

En plus des fichiers de verrouillage NuGet `v1`, GitLab Dependency Scanning et License Scanning prennent désormais tous deux en charge l'analyse des dépendances définies dans les fichiers de verrouillage NuGet `v2`.

### Amélioration du suivi des vulnérabilités SAST {#improved-sast-vulnerability-tracking}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/5144)

{{< /details >}}

Le [suivi avancé des vulnérabilités](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) GitLab SAST rend le triage plus efficace en suivant les résultats à mesure que le code évolue. Nous avons publié deux améliorations dans GitLab 16.2 :

1. Prise en charge étendue des langages : le suivi avancé des vulnérabilités est désormais activé pour C#.
1. Meilleur suivi : nous avons amélioré l'algorithme de suivi pour mieux gérer les espaces blancs et les commentaires en C, C#, Go, Java, JavaScript et Python. Nous avons également corrigé des problèmes liés au suivi de certaines fonctions Go.

Nous suivons les améliorations supplémentaires, notamment l'extension à d'autres langages, une meilleure gestion de davantage de constructions de langage, et un meilleur suivi pour Python et Ruby, dans l'epic [5144](https://gitlab.com/groups/gitlab-org/-/epics/5144).

Ces modifications sont incluses dans les [versions mises à jour](https://docs.gitlab.com/#sast-analyzer-updates) des [analyseurs](../../user/application_security/sast/analyzers.md) GitLab SAST. Les résultats de vulnérabilités de votre projet sont mis à jour avec de nouvelles signatures de suivi après que le projet a été analysé avec les analyseurs mis à jour. Vous n'avez pas besoin d'agir pour recevoir cette mise à jour, sauf si vous avez [épinglé les analyseurs SAST à une version spécifique](../../user/application_security/sast/_index.md).

### CI/CD : prise en charge de `when: never` sur les inclusions conditionnelles {#cicd-support-for-when-never-on-conditional-includes}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/includes.md#include-with-rulesif) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/348146)

{{< /details >}}

[`include`](../../ci/yaml/_index.md#include) est l'un des mots-clés les plus utilisés lors de l'écriture d'un pipeline CI/CD complet. Si vous construisez des pipelines plus importants, vous utilisez probablement le mot-clé `include` pour intégrer une configuration YAML externe dans votre pipeline.

Dans cette release, nous étendons la puissance du mot-clé afin que vous puissiez utiliser `when: never` lors de l'utilisation de [`rules` avec `include`](../../ci/yaml/includes.md#use-rules-with-include). Désormais, vous pouvez décider quand la configuration CI/CD externe sera exclue lorsqu'une règle spécifique est satisfaite. Cela vous aidera à rédiger un pipeline standardisé avec une meilleure capacité à se modifier dynamiquement en fonction des conditions que vous choisissez.

### Les runners SaaS de taille moyenne sur Linux disponibles pour toutes les éditions {#medium-saas-runners-on-linux-available-to-all-tiers}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/linux.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/418124)

{{< /details >}}

Nous avons désormais rendu notre [runner GitLab SaaS de taille moyenne sur Linux](../../ci/runners/hosted_runners/linux.md) avec 4 vCPU et 16 Go de RAM disponible pour toutes les éditions.

Auparavant, les utilisateurs de l'édition Gratuite ne pouvaient utiliser que notre petit runner Linux, entraînant parfois des temps d'exécution CI/CD plus longs. Nous sommes ravis de voir nos utilisateurs de l'édition Gratuite accélérer la vitesse de leurs pipelines.

### GitLab Runner 16.2 {#gitlab-runner-162}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.2 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Réessayer tous les appels d'API k8s dans l'exécuteur Kubernetes du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4143)

#### Corrections de bugs {#bug-fixes}

- [Les scripts de job CI ne se terminent pas lorsque dockerd ou un autre processus s'exécute en arrière-plan](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2880)
- [Image servercore de GitLab-runner-helper manquante pour v16.1.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/33918)
- [Erreur : impossible de créer l'adaptateur de cache](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3802)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-2-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Corrections de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.2)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.2)
- [Améliorations de l'interface](https://papercuts.gitlab.com/?milestone=16.2)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
