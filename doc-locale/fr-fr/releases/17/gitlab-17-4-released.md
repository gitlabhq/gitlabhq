---
stage: Release Notes
group: Monthly Release
date: 2024-09-19
title: "Notes de release de GitLab 17.4"
description: "GitLab 17.4 est disponible avec des suggestions de code GitLab Duo plus contextuelles grâce aux onglets ouverts"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 19 septembre 2024, GitLab 17.4 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Archish Thakkar {#this-months-notable-contributor-archish-thakkar}

Tout le monde peut [nommer des contributeurs de la communauté GitLab](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490) ! Montrez votre soutien à nos candidats actifs ou ajoutez une nouvelle nomination ! 🙌

Archish Thakkar est l'un des meilleurs contributeurs de GitLab cette année, avec [46 tickets fermés](https://gitlab.com/groups/gitlab-org/-/issues/?sort=created_date&state=closed&assignee_username%5B%5D=archish27&first_page_size=100) et [119 MR fusionnées](https://gitlab.com/groups/gitlab-org/-/merge_requests?assignee_username%5B%5D=archish27&first_page_size=100&sort=created_date&state=merged). Ces contributions ont permis à Archish de se classer parmi les premiers lors des deux derniers [GitLab Hackathons](https://gitlab-community.gitlab.io/community-projects/merge-request-leaderboard/?&createdAfter=2024-08-26&createdBefore=2024-09-02&mergedBefore=2024-10-03&label=Hackathon). Il est Senior Software Engineer chez [Middleware](https://middleware.io/) et contributeur passionné d'open source.

Archish a été nominé par [Peter Leitzen](https://gitlab.com/splattael), Staff Backend Engineer, Engineering Productivity chez GitLab. La nomination a été soutenue par [Max Woolf](https://gitlab.com/mwoolf), Staff Backend Engineer chez GitLab, et [James Nutt](https://gitlab.com/jnutt), Senior Backend Engineer chez GitLab. Les contributions d'Archish ont augmenté au cours des deux derniers mois, au cours desquels il a constamment démontré un engagement exceptionnel envers l'amélioration de la base de code de GitLab, en contribuant à de multiples correctifs QoL (Qualité de vie) et en réduisant la dette technique.

Un grand merci à Archish et au reste des contributeurs open source de GitLab pour leur co-création de GitLab !

## Fonctionnalités principales {#primary-features}

### Des suggestions de code GitLab Duo plus contextuelles grâce aux onglets ouverts {#more-context-aware-gitlab-duo-code-suggestions-using-open-tabs}

<!-- categories: Editor Extensions, Code Suggestions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Pro, Duo Enterprise
- Liens : [Documentation](../../user/project/repository/code_suggestions/context.md) \| [Ticket associé](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/206)

{{< /details >}}

Améliorez votre workflow de codage et recevez des suggestions de code plus contextuelles grâce au contenu des autres onglets ouverts.

Cette amélioration des suggestions de code utilise désormais le contenu de vos onglets d'éditeur ouverts pour fournir des recommandations de code plus pertinentes et précises.

### Fusion automatique lorsque toutes les vérifications sont réussies {#auto-merge-when-all-checks-pass}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/auto_merge.md)

{{< /details >}}

Les merge requests nécessitent de nombreuses vérifications obligatoires qui doivent être réussies avant qu'elles puissent être fusionnées. Ces vérifications peuvent inclure des approbations, des fils de discussion non résolus, des pipelines et d'autres éléments devant être satisfaits. Lorsque vous êtes responsable de la fusion du code, il peut être difficile de suivre tous ces événements et de savoir quand revenir vérifier si une merge request peut être fusionnée.

GitLab prend désormais en charge **Auto-merge** pour toutes les vérifications dans les merge requests. Auto-merge permet à tout utilisateur éligible à la fusion de définir une merge request sur **Auto-merge**, même avant que toutes les vérifications requises aient été réussies. Au fil du cycle de vie de la merge request, celle-ci fusionne automatiquement après que la dernière vérification en échec est réussie.

Nous sommes vraiment enthousiastes à propos de cette amélioration visant à accélérer vos workflows de merge request. Vous pouvez laisser vos commentaires sur cette fonctionnalité dans le [ticket 438395](https://gitlab.com/gitlab-org/gitlab/-/issues/438395).

### La marketplace d'extensions est désormais disponible dans le Web IDE {#extension-marketplace-now-available-in-the-web-ide}

<!-- categories: Web IDE -->

{{< details >}}

- Édition : Free, Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../user/project/web_ide/_index.md#manage-extensions)

{{< /details >}}

Nous sommes ravis d'annoncer le lancement de la marketplace d'extensions dans le Web IDE sur GitLab.com. Grâce à la marketplace d'extensions, vous pouvez découvrir, installer et gérer des extensions tierces, et améliorer votre expérience de développement. Certaines extensions ne sont pas compatibles avec la version web uniquement, car elles nécessitent un environnement d'exécution local. Cependant, vous pouvez toujours choisir parmi des milliers d'extensions pour améliorer votre productivité ou personnaliser votre workflow.

La marketplace d'extensions est désactivée par défaut. Pour commencer, vous pouvez activer la marketplace d'extensions dans la section **Intégrations** de vos [préférences utilisateur](https://gitlab.com/-/profile/preferences). Pour les [utilisateurs d'entreprise](../../user/enterprise_user/_index.md), seuls les utilisateurs ayant le rôle Owner pour un groupe principal peuvent activer la marketplace d'extensions.

### Accès sudo sécurisé pour les workspaces {#secure-sudo-access-for-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/configuration.md#configure-sudo-access-for-a-workspace)

{{< /details >}}

Vous pouvez désormais configurer l'accès sudo pour votre workspace, ce qui facilite plus que jamais l'installation, la configuration et l'exécution de dépendances directement dans votre environnement de développement. Nous avons mis en œuvre trois méthodes sécurisées pour garantir une expérience de développement fluide :

- Sysbox
- Kata Containers
- Espaces de nommage utilisateur

Grâce à cette fonctionnalité, vous pouvez entièrement personnaliser votre environnement pour l'adapter à votre workflow et aux besoins de votre projet.

### Lister les événements de ressources Kubernetes {#list-kubernetes-resource-events}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/470041)

{{< /details >}}

GitLab fournit une vue en temps réel de vos pods et des journaux de pods en streaming. Jusqu'à présent, nous n'affichions pas les informations d'événements spécifiques aux ressources dans l'interface utilisateur, vous obligeant à utiliser des outils tiers pour déboguer les déploiements Kubernetes. Cette release ajoute des événements à la vue des détails de ressource de [le tableau de bord pour Kubernetes](../../ci/environments/kubernetes_dashboard.md).

C'est la première fois que nous ajoutons des événements à l'interface utilisateur. Actuellement, les événements sont actualisés chaque fois que vous ouvrez la vue des détails de ressource. Vous pouvez suivre le développement du streaming d'événements en temps réel dans le [ticket 470042](https://gitlab.com/gitlab-org/gitlab/-/issues/470042).

### GitLab Pages sans DNS générique est en disponibilité générale {#gitlab-pages-without-wildcard-dns-is-generally-available}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/pages/_index.md#dns-configuration-for-single-domain-sites) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/13404)

{{< /details >}}

Auparavant, pour créer un projet GitLab Pages, vous aviez besoin d'un domaine formaté comme `name.example.io` ou `name.pages.example.io`. Cette exigence impliquait la configuration d'enregistrements DNS génériques et d'un certificat TLS. Dans cette release, la configuration d'un projet GitLab Pages sans DNS générique est passée de la version bêta à la disponibilité générale.

La suppression de l'exigence de certificats génériques réduit la charge administrative associée à GitLab Pages. Certains clients ne peuvent pas utiliser GitLab Pages en raison de restrictions organisationnelles sur les enregistrements DNS génériques ou les certificats.

### Déploiements parallèles GitLab Pages en version bêta {#gitlab-pages-parallel-deployments-in-beta}

<!-- categories: Pages -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/_index.md#parallel-deployments) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10914)

{{< /details >}}

Cette release introduit les déploiements parallèles de Pages en version bêta. Vous pouvez désormais facilement prévisualiser les modifications et gérer les déploiements parallèles pour vos sites GitLab Pages. Cette amélioration permet d'expérimenter facilement de nouvelles idées, afin de tester et d'affiner vos sites en toute confiance. En détectant les problèmes tôt, vous pouvez vous assurer que le site en production reste stable et soigné, en s'appuyant sur les bases déjà solides de GitLab Pages.

Par ailleurs, les déploiements parallèles peuvent être utiles pour la localisation lorsque vous déployez différentes versions linguistiques d'une application ou d'un site web.

### Résumer les discussions de tickets avec GitLab Duo Chat {#summarize-issue-discussions-with-gitlab-duo-chat}

<!-- categories: Team Planning -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Modules complémentaires : Duo Enterprise
- Liens : [Documentation](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)

{{< /details >}}

Se mettre à niveau sur de longues discussions de tickets peut représenter un investissement en temps considérable. Avec cette release, la synthèse des discussions de tickets générée par l'IA a été intégrée à Duo Chat et est désormais en disponibilité générale pour les clients GitLab.com, auto-hébergés et Dedicated.

### Le SAST avancé est en disponibilité générale {#advanced-sast-is-generally-available}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

Nous sommes ravis d'annoncer que notre scanner Advanced Static Application Security Testing (SAST) est désormais en disponibilité générale pour tous les clients GitLab Ultimate.

Le SAST avancé est un nouveau scanner alimenté par la technologie que nous avons [acquise d'Oxeye](https://about.gitlab.com/blog/oxeye-joins-gitlab-to-advance-application-security-capabilities/) plus tôt cette année. Il utilise un moteur de détection propriétaire avec des règles informées par des recherches de sécurité internes pour identifier les vulnérabilités exploitables dans le code propriétaire. Il fournit des résultats plus précis afin que les développeurs et les équipes de sécurité n'aient pas à trier les faux positifs.

En plus du nouveau moteur d'analyse, GitLab 17.4 inclut :

- Une nouvelle [vue du flux de code](../../user/application_security/vulnerabilities/_index.md#vulnerability-code-flow) qui trace le chemin d'une vulnérabilité à travers les fichiers et les fonctions.
- Une migration automatique qui permet au SAST avancé de « prendre en charge » les résultats existants des précédents scanners SAST GitLab.

Pour en savoir plus, consultez [le blog d'annonce](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/).

### Masquer les valeurs des variables CI/CD dans l'interface utilisateur {#hide-cicd-variable-values-in-the-ui}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](https://new.docs.gitlab.com/ci/variables/#define-a-cicd-variable-in-the-ui) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/29674)

{{< /details >}}

Vous ne souhaitez peut-être pas que quiconque voie la valeur d'une variable après son enregistrement dans les paramètres du projet. Vous pouvez désormais sélectionner la nouvelle option de visibilité **Masquée et cachée** lors de la création d'une variable CI/CD. La sélection de cette option masquera définitivement la valeur de la variable dans l'interface des paramètres CI/CD, empêchant ainsi l'affichage de la valeur à quiconque à l'avenir et réduisant la visibilité de vos données.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.4 inclut PostgreSQL 16 par défaut pour les nouvelles installations de GitLab.

GitLab 17.7 inclura OpenSSL V3. Cela affectera les instances Omnibus avec des configurations d'intégration externe ne respectant pas les exigences minimales de TLS 1.2 ou supérieur pour les connexions sortantes, ainsi que d'au moins 112 bits de chiffrement pour les certificats TLS. Veuillez consulter notre [documentation de mise à niveau OpenSSL](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3/) pour plus d'informations ou si vous n'êtes pas sûr que votre instance sera affectée.

### Lister les groupes invités à un groupe ou à un projet via l'API Groups ou Projects {#list-groups-invited-to-a-group-or-project-using-the-groups-or-projects-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/groups.md#list-invited-groups) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/465207)

{{< /details >}}

Nous avons ajouté de nouveaux points de terminaison à l'API Groups et à l'API Projects pour récupérer les groupes qui ont été invités à un groupe ou à un projet. Cette fonctionnalité est disponible uniquement sur la page Membres d'un groupe ou d'un projet. Nous espérons que cet ajout facilitera l'automatisation de la gestion des membres de vos groupes et projets. Les points de terminaison sont soumis à une limite de débit de 60 requêtes par minute par utilisateur.

### Restreindre l'accès aux groupes par domaine avec l'API Groups {#restrict-group-access-by-domain-with-the-groups-api}

<!-- categories: Source Code Management, Groups & Projects -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/groups.md#update-group-attributes) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/351494)

{{< /details >}}

Auparavant, vous pouviez uniquement ajouter des restrictions de domaine au niveau du groupe dans l'interface utilisateur. Désormais, vous pouvez également le faire en utilisant le nouvel attribut `allowed_email_domains_list` dans l'API Groups.

### Affichage amélioré de la source pour les membres de groupe et de projet {#improved-source-display-for-group-and-project-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/members/_index.md#membership-types) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/431066)

{{< /details >}}

Nous avons simplifié l'affichage de la colonne source sur la page Membres pour les groupes et les projets. Les membres directs sont toujours indiqués comme `Direct member`. Les membres hérités sont désormais répertoriés comme `Inherited from` suivi du nom du groupe. Les membres ajoutés en invitant un groupe au groupe ou au projet sont répertoriés comme `Invited group` suivi du nom du groupe. Pour les membres qui ont hérité d'un groupe invité ajouté à un groupe parent, nous affichons désormais la dernière étape afin de maintenir l'affichage exploitable pour les utilisateurs gérant les membres.

### E-mail d'attribution de siège GitLab Duo {#gitlab-duo-seat-assignment-email}

<!-- categories: Seat Cost Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Modules complémentaires : Duo Pro
- Liens : [Documentation](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164104)

{{< /details >}}

Les utilisateurs sur les instances auto-hébergées recevront désormais un e-mail lorsqu'un siège GitLab Duo leur est attribué. Auparavant, vous ne saviez pas qu'un siège vous avait été attribué à moins que quelqu'un vous le signale, ou que vous remarquiez une nouvelle fonctionnalité dans l'interface utilisateur GitLab.

Pour désactiver cet e-mail, un administrateur peut désactiver le feature flag `duo_seat_assignment_email_for_sm`.

### Renvoyer les requêtes webhook échouées avec l'API {#resend-failed-webhook-requests-with-the-api}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/project_webhooks.md#resend-a-project-webhook-event) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/372826)

{{< /details >}}

Auparavant, GitLab permettait de renvoyer les requêtes webhook uniquement dans l'interface utilisateur, ce qui était inefficace si de nombreuses requêtes échouaient.

Afin de vous permettre de gérer les requêtes webhook échouées de manière programmatique, dans cette release, grâce à une contribution de la communauté, nous avons ajouté des points de terminaison API pour les renvoyer :

- [Requêtes webhook de projet](../../api/project_webhooks.md#resend-a-project-webhook-event)
- [Requêtes webhook de groupe](../../api/group_webhooks.md#resend-group-hook-event) (éditions Premium et Ultimate uniquement)

Vous pouvez désormais :

1. Obtenir la liste des événements de [hook de projet](../../api/project_webhooks.md#list-project-webhook-events) ou de [hook de groupe](../../api/group_webhooks.md#list-all-group-hook-events).
1. Filtrer la liste pour voir les échecs.
1. Utiliser le `id` de n'importe quel événement pour le renvoyer.

Merci à [Phawin](https://gitlab.com/lifez) pour [cette contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130) !

### Clés d'idempotence pour les requêtes webhook {#idempotency-keys-for-webhook-requests}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhooks.md#delivery-headers) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/388692)

{{< /details >}}

À partir de cette release, nous prenons en charge une clé d'idempotence dans les en-têtes des requêtes webhook. Une clé d'idempotence est un identifiant unique qui reste cohérent lors des nouvelles tentatives webhook, ce qui permet aux clients webhook de détecter ces nouvelles tentatives. Utilisez l'en-tête `Idempotency-Key` pour garantir l'idempotence des effets webhook sur les intégrations.

Merci à [Van](https://gitlab.com/van.m.anderson) pour cette [contribution de la communauté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160952) !

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Composant CI/CD pour l'intelligence de code {#cicd-component-for-code-intelligence}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/code_intelligence.md#with-the-cicd-component)

{{< /details >}}

L'intelligence de code dans GitLab fournit des fonctionnalités de navigation dans le code lors de la navigation dans un dépôt. La mise en route avec la navigation dans le code est souvent complexe, car vous devez configurer un job CI/CD. Ce job peut nécessiter des scripts personnalisés pour fournir la sortie et les artefacts appropriés.

GitLab prend désormais en charge un [composant CI/CD d'intelligence de code](https://gitlab.com/explore/catalog/components/code-intelligence) officiel pour une configuration plus facile. Ajoutez ce composant à votre projet en suivant les instructions pour [utiliser un composant](../../ci/components/_index.md#use-a-component). Cela simplifie grandement l'adoption de l'intelligence de code dans GitLab.

Actuellement, le composant prend en charge les langages suivants :

- Go version 1.21 ou ultérieure.
- TypeScript ou JavaScript.

Nous continuerons à évaluer les [indexeurs SCIP disponibles](https://github.com/sourcegraph/scip?tab=readme-ov-file#tools-using-scip) dans l'optique d'élargir la prise en charge des langages pour le nouveau composant. Si vous souhaitez ajouter la prise en charge d'un langage, veuillez ouvrir une merge request dans le projet [composant d'intelligence de code](https://gitlab.com/components/code-intelligence).

### Les fichiers liés dans la merge request s'affichent en premier {#linked-files-in-merge-request-show-first}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/changes.md#show-a-linked-file-first)

{{< /details >}}

Lorsque vous partagez un lien vers un fichier spécifique dans une merge request, c'est souvent parce que vous souhaitez que la personne examine quelque chose dans ce fichier. Les merge requests devaient auparavant charger tous les fichiers avant de faire défiler jusqu'à la position spécifique que vous avez référencée. Créer un lien direct vers un fichier est un excellent moyen d'améliorer la vitesse de collaboration dans les merge requests :

1. Trouvez le fichier que vous souhaitez afficher en premier. Faites un clic droit sur le nom du fichier pour copier le lien vers celui-ci.
1. Lorsque vous visitez ce lien, le fichier que vous avez choisi s'affiche en haut de la liste. Le navigateur de fichiers affiche une icône de lien à côté du nom du fichier.

Les commentaires sur les fichiers liés peuvent être laissés dans le [ticket 439582](https://gitlab.com/gitlab-org/gitlab/-/issues/439582).

### S'authentifier avec OAuth pour GitLab Duo dans les IDE JetBrains {#authenticate-with-oauth-for-gitlab-duo-in-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../editor_extensions/jetbrains_ide/setup.md#configure-gitlab-duo) \| [Epic associé](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/70)

{{< /details >}}

Notre plugin GitLab Duo pour JetBrains offre désormais un processus d'intégration plus sécurisé et plus rationalisé. Connectez-vous rapidement et en toute sécurité avec OAuth. Il s'intègre parfaitement à votre workflow existant, sans jeton d'accès personnel requis !

### Les jobs non liés aux déploiements vers des environnements protégés ne sont pas convertis en jobs manuels {#non-deployment-jobs-to-protected-environments-arent-turned-into-manual-jobs}

<!-- categories: Environment Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/job_control.md#types-of-manual-jobs) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/390025)

{{< /details >}}

En raison d'un problème d'implémentation, les jobs `action: prepare`, `action: verify` et `action: access` deviennent des jobs manuels lorsqu'ils s'exécutent sur un environnement protégé. Ces jobs nécessitent une interaction manuelle pour s'exécuter, bien qu'ils ne nécessitent pas d'approbations supplémentaires.

[Le ticket 390025](https://gitlab.com/gitlab-org/gitlab/-/issues/390025) propose de corriger l'implémentation, afin que ces jobs ne soient plus convertis en jobs manuels. Après ce changement proposé, pour maintenir le comportement actuel, vous devrez [définir explicitement les jobs comme manuels](../../ci/jobs/job_control.md#types-of-manual-jobs).

Pour l'instant, vous pouvez basculer vers la nouvelle implémentation en activant le feature flag `prevent_blocking_non_deployment_jobs`.

Tout changement disruptif proposé vise à différencier le comportement des valeurs `environment.action: prepare | verify | access`. Le mot-clé `environment.action: access` restera le plus proche de son comportement actuel.

Pour éviter de futurs problèmes de compatibilité, vous devriez examiner dès maintenant votre utilisation de ces mots-clés. Vous pouvez en savoir plus sur ces changements proposés dans les tickets suivants :

- [Ticket 437132](https://gitlab.com/gitlab-org/gitlab/-/issues/437132)
- [Ticket 437133](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)
- [Ticket 437142](https://gitlab.com/gitlab-org/gitlab/-/issues/437142)

### Déclencher une réconciliation Flux depuis l'interface utilisateur du cluster {#trigger-a-flux-reconciliation-from-the-cluster-ui}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/434248)

{{< /details >}}

Bien que vous puissiez configurer Flux pour déclencher des réconciliations à des intervalles spécifiés, il existe des situations où vous pourriez souhaiter une réconciliation immédiate. Dans les releases précédentes, vous pouviez déclencher la réconciliation depuis un pipeline CI/CD ou depuis la ligne de commande. Dans GitLab 17.4, vous pouvez désormais déclencher une réconciliation depuis un tableau de bord pour Kubernetes sans configuration supplémentaire.

Pour déclencher une réconciliation, accédez à un tableau de bord configuré et sélectionnez le badge de statut Flux.

### Expiration optionnelle des jetons {#optional-token-expiration}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/470192)

{{< /details >}}

Les administrateurs peuvent désormais décider s'ils souhaitent appliquer une date d'expiration obligatoire pour les jetons d'accès personnels, de projet et de groupe. Si les administrateurs désactivent ce paramètre, tout nouveau jeton d'accès généré ne sera pas obligatoirement soumis à une date d'expiration. Par défaut, ce paramètre est activé et une expiration inférieure à la durée de vie maximale autorisée est requise. Ce paramètre est disponible dans GitLab 16.11 et versions ultérieures.

### Rechercher par plusieurs référentiels de conformité {#search-by-multiple-compliance-frameworks}

<!-- categories: Compliance Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/compliance/compliance_center/compliance_projects_report.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/462943)

{{< /details >}}

Dans GitLab 17.3, nous avons donné aux utilisateurs la possibilité d'ajouter plusieurs référentiels de conformité à un projet.

Vous pouvez désormais effectuer des recherches par plusieurs référentiels de conformité, ce qui facilite la recherche de projets auxquels plusieurs référentiels de conformité sont associés.

### Accorder un accès en lecture aux fichiers YAML d'exécution de pipeline dans les projets liés aux politiques de sécurité {#grant-read-access-to-pipeline-execution-yaml-files-in-projects-linked-to-security-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/469439)

{{< /details >}}

Dans GitLab 17.4, nous avons ajouté un paramètre aux politiques de sécurité que vous pouvez utiliser pour accorder un accès en lecture aux fichiers `pipeline-execution.yml` pour tous les projets liés. Ce paramètre vous offre plus de flexibilité pour permettre aux utilisateurs, bots ou jetons d'appliquer l'exécution de pipeline globalement dans les projets. Par exemple, vous pouvez vous assurer que les jetons d'accès de groupe ou de projet peuvent lire les configurations de politiques de sécurité afin de déclencher des pipelines lors de l'exécution du pipeline. Vous ne pouvez toujours pas consulter directement le dépôt du projet de politique de sécurité ni le YAML. La configuration est utilisée uniquement lors de la création du pipeline.

Pour configurer le paramètre, accédez au projet de politique de sécurité que vous souhaitez partager. Sélectionnez **Paramètres > Général > Visibilité, fonctionnalités du projet, autorisations**, faites défiler jusqu'à **Stratégies d'exécution des pipelines** et activez le bouton **Grant access to this repository for projects linked to it as the security policy project source for security policies**.

### Prise en charge des suffixes pour les jobs avec des collisions de noms dans les pipelines de politique d'exécution de pipeline {#support-suffix-for-jobs-with-name-collisions-in-pipeline-execution-policy-pipelines}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/pipeline_execution_policies.md#pipeline_execution_policy-schema) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/473189)

{{< /details >}}

En tant qu'amélioration de la [release 17.2 des politiques d'exécution de pipeline](https://about.gitlab.com/releases/2024/07/18/gitlab-17-2-released/#pipeline-execution-policy-type), les créateurs de politiques peuvent désormais configurer les politiques d'exécution de pipeline pour gérer les collisions de noms de jobs de manière fluide. Avec le fichier `policy.yml` pour la politique d'exécution de pipeline, vous pouvez désormais configurer les options suivantes :

- `suffix: on_conflict` configure la politique pour gérer les collisions de manière fluide en renommant les jobs de la politique, ce qui est le nouveau comportement par défaut
- `suffix: never` impose que tous les noms de jobs soient uniques et fera échouer les pipelines en cas de collisions, ce qui était le comportement par défaut depuis la version 17.2

Grâce à cette amélioration, vous pouvez vous assurer que les jobs de sécurité et de conformité exécutés dans le cadre d'une politique d'exécution de pipeline s'exécutent toujours, tout en évitant des impacts inutiles sur les développeurs en aval.

Dans une amélioration ultérieure, nous introduirons l'option de configuration dans l'éditeur de politiques.

### Barre latérale wiki redimensionnable {#resizable-wiki-sidebar}

<!-- categories: Wiki -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/wiki/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154167)

{{< /details >}}

Vous pouvez désormais ajuster la barre latérale du wiki pour voir les titres de page plus longs, améliorant ainsi la découvrabilité globale du contenu. À mesure que le contenu du wiki s'enrichit, disposer d'une barre latérale redimensionnable aide à gérer et à parcourir plus efficacement les hiérarchies complexes ou les listes de pages étendues.

### Prise en charge de l'ingestion des SBOMs CycloneDX 1.6 {#support-for-ingesting-cyclonedx-16-sboms}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/472837)

{{< /details >}}

GitLab 15.3 a ajouté la prise en charge de [l'ingestion des SBOMs CycloneDX](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx).

Dans GitLab 17.4, nous avons ajouté la prise en charge de l'ingestion des SBOMs CycloneDX version 1.6.

Les champs relatifs au matériel (HBOM), aux services (SaaSBOM) et aux modèles IA/ML (AI/ML-BOM) ne sont actuellement pas pris en charge. Les SBOMs contenant des données relatives à ces BOMs seront traités, mais les données ne seront pas analysées ni présentées aux utilisateurs. La prise en charge de ces autres types de BOM est suivie dans cet [epic](https://gitlab.com/groups/gitlab-org/-/epics/14989).

### Nettoyage automatique pour les analyseurs SAST supprimés {#automatic-cleanup-for-removed-sast-analyzers}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/analyzers.md#analyzers-that-have-reached-end-of-support)

{{< /details >}}

Dans [GitLab 17.0](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170), [16.0](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-160) et [15.4](../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes), nous avons rationalisé le SAST GitLab afin qu'il utilise moins d'analyseurs distincts pour analyser votre code à la recherche de vulnérabilités.

Désormais, après la mise à niveau vers GitLab 17.3.1 ou une version ultérieure, une migration de données unique résoudra automatiquement les vulnérabilités restantes provenant des [analyseurs ayant atteint la fin du support](../../user/application_security/sast/analyzers.md#analyzers-that-have-reached-end-of-support). Cela permet de nettoyer votre rapport de vulnérabilités afin que vous puissiez vous concentrer sur les vulnérabilités encore détectées par les analyseurs les plus récents.

La migration résout uniquement les vulnérabilités que vous n'avez pas confirmées ou rejetées, et elle n'affecte pas les vulnérabilités qui ont été [automatiquement transférées vers l'analyse basée sur Semgrep](../../user/application_security/sast/analyzers.md#transition-to-semgrep-based-scanning).

### Prise en charge de la détection des secrets pour les clés API Anthropic {#secret-detection-support-for-anthropic-api-keys}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/secret_detection/detected_secrets.md)

{{< /details >}}

La détection des secrets de pipeline et côté client prend désormais en charge la détection des clés API [Anthropic](https://www.anthropic.com/).

### Prise en charge de JaCoCo pour la visualisation de la couverture de test disponible en version bêta {#jacoco-support-for-test-coverage-visualization-available-in-beta}

<!-- categories: Code Testing and Coverage -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/testing/code_coverage/jacoco.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/227345)

{{< /details >}}

Vous pouvez désormais utiliser les rapports de couverture JaCoCo, une norme populaire pour le calcul de la couverture, dans vos merge requests. La fonctionnalité est disponible en version bêta, mais elle est prête à être testée par quiconque souhaitant utiliser immédiatement les rapports de couverture JaCoCo. Si vous avez des commentaires, n'hésitez pas à contribuer au [ticket de commentaires](https://gitlab.com/gitlab-org/gitlab/-/issues/479804).

### GitLab Runner 17.4 {#gitlab-runner-174}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 17.4 aujourd'hui ! GitLab Runner est l'agent de build hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Plugin fleeting GitLab Runner pour Azure compute (GA)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29223)

#### Corrections de bugs {#bug-fixes}

- [L'intégralité du contenu de `step_script` apparaît dans la section `after_script` du job log lorsqu'un job avec l'exécuteur Kubernetes est annulé avant la fin](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37952)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-4-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.4)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.4)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=17.4)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
