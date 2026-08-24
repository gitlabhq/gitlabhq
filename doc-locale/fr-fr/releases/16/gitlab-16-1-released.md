---
stage: Release Notes
group: Monthly Release
date: 2023-06-22
title: "Notes de release de GitLab 16.1"
description: "GitLab 16.1 publié avec une toute nouvelle expérience de navigation"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 22 juin 2023, GitLab 16.1 a été publié avec les fonctionnalités suivantes.

Nous tenons également à remercier tous nos contributeurs, dont le contributeur notable de ce mois-ci.

## Contributeur remarquable du mois {#this-months-notable-contributor}

Gerardo a régulièrement effectué des itérations sur plusieurs releases pour livrer les [endpoints de l'API REST pour la portée des jetons de job](https://gitlab.com/gitlab-org/gitlab/-/issues/351740). L'itération est l'une de nos [valeurs fondamentales](https://handbook.gitlab.com/handbook/values/#iteration) chez GitLab, et Gerardo l'a illustrée par ses multiples contributions pour livrer la fonctionnalité.

En raison de la modification du [comportement par défaut de `CI_JOB_TOKEN`](../../update/deprecations.md), les utilisateurs qui automatisent la création de projets ne peuvent pas également automatiser l'ajout des projets autorisés à utiliser un `CI_JOB_TOKEN` avec le projet. Cet endpoint d'API REST permet à nos clients d'automatiser à nouveau ce processus et de favoriser l'adoption accrue d'un workflow `CI_JOB_TOKEN` plus sécurisé.

Merci à Gerardo et au reste de l'équipe de Siemens !

Yuri a pris en charge un [ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/18287) enregistré il y a 6 ans, a fait preuve d'un [parti pris pour l'action](https://handbook.gitlab.com/handbook/values/#bias-for-action) (l'une de nos valeurs GitLab) et a contribué à un correctif.

Il s'agissait d'une fonctionnalité populaire qui intéressait un certain nombre de clients. Cette amélioration permet à l'administrateur système d'ignorer des projets spécifiques lors de la sauvegarde et de la restauration, sur la base d'une liste de chemins de groupes ou de projets séparés par des virgules. Grâce à cette fonctionnalité, les administrateurs système peuvent ignorer les projets obsolètes ou archivés lors de leur exécution de sauvegarde, économiser de l'espace de stockage et accélérer la sauvegarde. Ils peuvent également exclure des projets spécifiques lors de la restauration à partir d'une sauvegarde en utilisant la même option.

Merci à Yuri pour sa précieuse contribution !

## Fonctionnalités principales {#primary-features}

### Toute nouvelle expérience de navigation {#all-new-navigation-experience}

<!-- categories: Navigation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

GitLab 16.1 propose une toute nouvelle expérience de navigation ! Nous avons activé cette expérience par défaut pour tous les utilisateurs. Pour commencer, accédez à votre avatar en haut à droite de l'interface et activez le bouton **New navigation**.

La nouvelle navigation a été conçue pour résoudre trois domaines clés de retours : la navigation dans GitLab peut être déconcertante, il peut être difficile de reprendre là où vous vous étiez arrêté, et vous ne pouvez pas personnaliser la navigation.

La nouvelle navigation comprend une barre latérale gauche rationalisée et améliorée, où vous pouvez :

- Épingler 📌 les éléments fréquemment consultés.
- Masquer complètement la barre latérale et la faire réapparaître en « jetant un coup d'œil ».
- Basculer facilement entre les contextes, effectuer des recherches et afficher des sous-ensembles de données grâce aux nouvelles options **Your Work** et **Explorer**.
- Parcourir plus rapidement grâce à moins d'éléments de menu de niveau supérieur.

Nous sommes fiers de cette nouvelle navigation et avons hâte de connaître votre avis. Consultez une [liste des changements](https://gitlab.com/groups/gitlab-org/-/epics/9044#whats-different) et lisez nos articles de blog sur la [vision](https://about.gitlab.com/blog/gitlab-product-navigation/) et la [conception](https://about.gitlab.com/blog/overhauling-the-navigation-is-like-building-a-dream-home/) de la navigation.

Essayez la nouvelle navigation et faites-nous part de votre expérience dans [ce ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/409005). Nous [prenons déjà en compte](https://gitlab.com/gitlab-org/gitlab/-/issues/409005#actions-we-are-taking-from-the-feedback) les retours et nous finirons par supprimer le bouton bascule.

### Visualiser les ressources Kubernetes dans GitLab {#visualize-kubernetes-resources-in-gitlab}

<!-- categories: Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/environments/kubernetes_dashboard.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/390769)

{{< /details >}}

Comment vérifiez-vous le statut des applications exécutées dans vos clusters ? Le statut du pipeline et les pages d'environnement fournissent des informations sur les dernières exécutions de déploiement. Cependant, les versions précédentes de GitLab manquaient d'informations sur l'état de vos déploiements. Dans GitLab 16.1, vous pouvez voir une vue d'ensemble des ressources principales dans vos déploiements Kubernetes.

Cette fonctionnalité fonctionne avec chaque cluster Kubernetes connecté. Peu importe si vous déployez vos charges de travail avec l'intégration CI/CD ou GitOps. Pour améliorer davantage la fonctionnalité pour les utilisateurs de Flux, la prise en charge de l'affichage du statut de synchronisation d'un environnement est proposée dans le [ticket 391581](https://gitlab.com/gitlab-org/gitlab/-/issues/391581).

### S'authentifier avec des comptes de service {#authenticate-with-service-accounts}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/groups.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/6777)

{{< /details >}}

Il existe de nombreux cas d'utilisation pour lesquels un utilisateur non humain peut avoir besoin de s'authentifier. Auparavant, selon la portée souhaitée, les utilisateurs pouvaient utiliser des jetons d'accès personnels, de projet ou de groupe pour répondre à ce besoin. Ces jetons n'étaient pas idéaux, car ils étaient encore soit liés à un être humain (pour les jetons d'accès personnels), soit associés à un rôle disposant de privilèges inutiles (pour les jetons d'accès de groupe et de projet).

Les comptes de service ne sont pas liés à un utilisateur humain et ont une portée plus granulaire. La création et la gestion des comptes de service sont uniquement disponibles via l'API. La prise en charge d'une option d'interface utilisateur est proposée dans le [ticket 9965](https://gitlab.com/groups/gitlab-org/-/epics/9965).

### GitLab Dedicated est désormais disponible en version générale {#gitlab-dedicated-is-now-generally-available}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- Édition : Gold
- Offre : GitLab.com
- Liens : [Documentation](../../subscriptions/gitlab_dedicated/_index.md) \| [Ticket associé](https://about.gitlab.com/dedicated/)

{{< /details >}}

GitLab Dedicated est un déploiement SaaS monolocataire entièrement géré de notre plateforme DevSecOps complète, conçu pour répondre aux besoins des clients soumis à des exigences de conformité strictes.

Les clients des secteurs hautement réglementés ne peuvent pas adopter les offres SaaS multilocataires en raison d'exigences de conformité strictes, comme l'isolation des données. Avec GitLab Dedicated, les organisations peuvent accéder à tous les avantages de la plateforme DevSecOps, notamment des releases plus rapides, une meilleure sécurité et des équipes de développement plus productives, tout en satisfaisant aux exigences de conformité telles que la résidence des données, l'isolation et la mise en réseau privée.

[En savoir plus](https://about.gitlab.com/dedicated/) sur GitLab Dedicated dès aujourd'hui.

### Gérer les artefacts de job via la page Artéfacts {#manage-job-artifacts-through-the-artifacts-page}

<!-- categories: Job Artifacts -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/job_artifacts.md#view-all-job-artifacts-in-a-project)

{{< /details >}}

Auparavant, si vous souhaitiez afficher ou gérer des artefacts de job, vous deviez accéder à la page de détails de chaque job ou utiliser l'API. Désormais, vous pouvez afficher et gérer les artefacts de job via la page **Artéfacts** accessible depuis **Version > Artéfacts**.

Les utilisateurs disposant au moins du rôle Maintainer peuvent également utiliser cette nouvelle interface pour supprimer des artefacts. Vous pouvez supprimer des artefacts individuels ou effectuer une suppression en masse de jusqu'à 100 artefacts à la fois, par sélection manuelle ou en cochant l'option **Tout sélectionner** en haut de la page.

Veuillez utiliser le sondage en haut de la page Artéfacts pour partager vos commentaires sur cette nouvelle fonctionnalité. Pour voir les fonctionnalités d'interface utilisateur supplémentaires à l'étude, vous pouvez consulter l'[epic d'améliorations de la page Build Artifacts](https://gitlab.com/groups/gitlab-org/-/epics/8311).

### Vue de liste améliorée des variables CI/CD {#improved-cicd-variables-list-view}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/410383)

{{< /details >}}

Les variables CI/CD sont un élément clé de tous les pipelines et peuvent être définies à plusieurs endroits, notamment dans les paramètres du projet et du groupe. Pour préparer des améliorations plus importantes qui aideront les utilisateurs à naviguer de manière intuitive entre les variables à différents niveaux de hiérarchie, nous commençons par améliorer la convivialité et la mise en page de la liste des variables.

Dans GitLab 16.1, vous verrez la première itération de ces améliorations. Nous avons fusionné les colonnes « Type » et « Options » en une nouvelle colonne **Attributs**, qui représente mieux ces attributs associés. Nous apprécions vos retours sur la façon dont nous pouvons continuer à améliorer l'expérience des variables CI/CD. N'hésitez pas à commenter dans notre [epic d'amélioration des variables](https://gitlab.com/groups/gitlab-org/-/epics/10506).

## Mise à l'échelle et déploiements {#scale-and-deployments}

### Améliorations du chart GitLab {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/charts/)

{{< /details >}}

- GitLab 16.1 remplace l'image Docker `busybox` par l'image Docker `gitlab-base` pour partager des couches avec d'autres images Docker GitLab. Cette implémentation traite `gitlab-base` comme une image d'aide (comme `kubectl` et `certificates`), avec des remplacements locaux optionnels.

### Améliorations d'Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.1 ajoute la prise en charge de la création et de la publication de paquets sur [Debian 12 `Bookworm`](https://www.debian.org/releases/bookworm/), sorti le 10 juin 2023.

### Vérification de domaine améliorée {#improved-domain-verification}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/enterprise_user/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/375492)

{{< /details >}}

La vérification de domaine remplit plusieurs fonctions dans GitLab. Auparavant, pour vérifier un domaine, vous deviez compléter l'assistant [GitLab Pages](../../user/project/pages/_index.md), même si vous vérifiiez un domaine à des fins extérieures à GitLab Pages.

Désormais, la vérification de domaine s'effectue au niveau du groupe et a été rationalisée. Cela facilite la vérification de vos domaines.

### Afficher le rapport de vulnérabilité en tant qu'autorisation personnalisable {#view-vulnerability-report-as-customizable-permission}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/permissions.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/10160)

{{< /details >}}

La possibilité d'afficher le rapport de vulnérabilité est désormais divisée en une autorisation distincte, permettant aux administrateurs GitLab et aux propriétaires de groupe de créer un rôle personnalisé avec cette autorisation. Auparavant, l'affichage du rapport de vulnérabilité était limité au rôle Developer et aux rôles supérieurs. Désormais, tout utilisateur peut afficher le rapport de vulnérabilité, à condition de se voir attribuer un rôle personnalisé disposant de l'autorisation.

### E-mail de réinitialisation du mot de passe envoyé à n'importe quelle adresse e-mail vérifiée {#password-reset-email-sent-to-any-verified-email-address}

<!-- categories: User Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/user_passwords.md#change-your-password) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/16311)

{{< /details >}}

Si vous oubliez votre mot de passe GitLab, vous pouvez désormais le réinitialiser par e-mail avec n'importe quelle adresse e-mail vérifiée. Auparavant, seule l'adresse e-mail principale était utilisée pour les demandes de réinitialisation. Cela rendait difficile la finalisation du processus de réinitialisation du mot de passe si la boîte de réception de l'e-mail principal était inaccessible.

### Identités SCIM incluses dans la réponse de l'API des utilisateurs {#scim-identities-included-in-users-api-response}

<!-- categories: System Access, Source Code Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/users.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/324247)

{{< /details >}}

L'API des utilisateurs retourne désormais les identités SCIM d'un utilisateur. Auparavant, ces informations étaient incluses dans l'interface utilisateur, mais pas dans l'API.

### Réintroduction de la prise en charge d'OmniAuth Shibboleth {#reintroduction-of-omniauth-shibboleth-support}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../integration/shibboleth.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/393065)

{{< /details >}}

La prise en charge d'OmniAuth Shibboleth a été réintroduite dans GitLab. Elle avait précédemment été [supprimée](https://gitlab.com/gitlab-org/gitlab/-/issues/388959) dans GitLab 15.9 en raison d'un manque de support en amont. Grâce à une généreuse contribution de la communauté par [lukaskoenen](https://gitlab.com/lukaskoenen), qui a assuré le support en amont, `omniauth-shibboleth-redux` est désormais pris en charge dans GitLab auto-géré.

### Sélectionner l'accès administrateur pour les jetons d'accès personnels en mode Admin {#select-administrator-access-for-personal-access-tokens-in-admin-mode}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/profile/personal_access_tokens.md#personal-access-token-scopes) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/42692)

{{< /details >}}

Les administrateurs GitLab peuvent utiliser le mode Admin pour travailler en tant qu'utilisateur non administrateur et activer l'accès administrateur lorsque nécessaire. Auparavant, le jeton d'accès personnel (PAT) d'un administrateur disposait toujours des autorisations pour effectuer des actions API en tant qu'administrateur. Désormais, lors de l'ajout d'un PAT, un administrateur peut décider si ce PAT dispose d'un accès administrateur pour effectuer des actions API ou non, en sélectionnant la portée du mode Admin. Un administrateur doit activer le mode Admin pour l'instance afin d'utiliser cette fonctionnalité.

Merci à [Jonas Wälter](https://gitlab.com/wwwjon), [Diego Louzán](https://gitlab.com/dlouzan) et [Andreas Deicha](https://gitlab.com/TrueKalix) pour leur contribution !

### Empêcher les utilisateurs de supprimer leur compte {#prevent-user-from-deleting-account}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/account_and_limit_settings.md#prevent-users-from-deleting-their-accounts) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/26053)

{{< /details >}}

Les administrateurs peuvent empêcher les utilisateurs de supprimer leur compte grâce à un nouveau paramètre de configuration des restrictions utilisateur. Si ce paramètre est activé, les utilisateurs ne pourront plus supprimer leurs comptes, préservant ainsi les informations de compte auditables.

### Valeur `last_used` du jeton d'accès personnel mise à jour plus fréquemment {#personal-access-token-last_used-value-updated-more-frequently}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/profile/personal_access_tokens.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/410168)

{{< /details >}}

La valeur `last_used` des jetons d'accès personnels (PAT) était précédemment mise à jour toutes les 24 heures. Elle est désormais mise à jour toutes les 10 minutes. Cela améliore la visibilité de l'utilisation des PAT et, en cas de compromission d'un PAT, réduit le risque car le délai avant la détection d'une activité malveillante est raccourci.

Merci à [Jacob Torrey](https://thinkst.com/) pour votre contribution !

### Plus de détails dans le résumé d'importation de projet GitHub terminé {#more-detail-in-completed-github-project-import-summary}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/import/github.md#check-status-of-imports) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/386748)

{{< /details >}}

Lorsqu'un projet GitHub finissait d'être importé, GitLab affichait un résumé simple des entités importées. Cependant, GitLab n'indiquait pas exactement quelles entités GitHub n'avaient pas été importées ni les erreurs ayant causé les échecs d'importation. Il était donc difficile de déterminer si les résultats de l'importation étaient satisfaisants ou non.

Dans cette release, nous avons étendu le résumé d'importation pour inclure une liste des entités GitHub qui n'ont pas été importées et, si possible, fournir un lien direct vers ces entités sur GitHub. GitLab affiche désormais également une erreur pour chaque échec. Cela vous aide à comprendre comment s'est déroulée l'importation et à résoudre les problèmes.

### Afficher l'utilisateur externe comme auteur de commentaire dans les tickets Service Desk {#show-external-user-as-a-comment-author-in-service-desk-issues}

<!-- categories: Service Desk -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/service_desk/_index.md)

{{< /details >}}

Lorsqu'un demandeur répond à un e-mail du Service Desk, il est utile pour l'agent du Service Desk de savoir qui a fait le commentaire. Mais parce que le demandeur peut être un utilisateur externe sans compte GitLab ni accès au projet GitLab, ces commentaires étaient auparavant attribués au GitLab Support Bot. Désormais, les réponses par e-mail des demandeurs seront attribuées aux utilisateurs externes, ce qui rendra plus clair qui a fait les commentaires dans le ticket GitLab.

### Espace réservé pour l'URL du ticket dans les e-mails du Service Desk {#issue-url-placeholder-in-service-desk-emails}

<!-- categories: Service Desk -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/service_desk/_index.md)

{{< /details >}}

Pour les demandeurs du Service Desk, il peut être utile d'accéder directement au ticket du Service Desk plutôt que d'interagir avec la demande du Service Desk uniquement par e-mail. Nous introduisons un nouvel espace réservé `%{ISSUE_URL}`, que vous pouvez utiliser dans vos modèles d'e-mail (par exemple, l'e-mail de « remerciement ») pour rediriger les demandeurs directement vers le ticket du Service Desk.

### La sauvegarde ajoute la possibilité d'ignorer des projets {#backup-adds-the-ability-to-skip-projects}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)

{{< /details >}}

L'outil de sauvegarde et de restauration intégré ajoute la possibilité d'ignorer des dépôts spécifiques. La tâche Rake accepte désormais une liste de chemins de groupes ou de projets séparés par des virgules à ignorer lors de la sauvegarde ou de la restauration en utilisant la nouvelle variable d'environnement `SKIP_REPOSITORIES_PATHS`. Cela vous permettra d'ignorer, par exemple, les projets obsolètes ou archivés qui n'évoluent pas dans le temps, vous faisant ainsi économiser a) du temps en accélérant l'exécution de la sauvegarde, et b) de l'espace en n'incluant pas ces données dans le fichier de sauvegarde. Merci à [Yuri Konotopov](https://gitlab.com/nE0sIghT) pour cette [contribution communautaire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121865) !

### Geo ajoute le filtrage par statut de réplication à tous les composants {#geo-adds-filtering-by-replication-status-to-all-components}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/geo/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/411981)

{{< /details >}}

Geo ajoute le filtrage par statut de réplication à tous les composants gérés par le [framework en libre-service](../../development/geo/framework.md). Vous pouvez désormais filtrer les éléments dans les vues de détails de réplication par statut « En cours », « Échoué » et « Synchronisé », ce qui facilite et accélère la localisation des données dont la synchronisation échoue.

### Geo vérifie les dépôts de conception {#geo-verifies-design-repositories}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/geo/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/355660)

{{< /details >}}

Lorsque vous ajoutez une conception à un ticket, un dépôt Git de conception est créé ou mis à jour, et un objet LFS ainsi qu'un téléversement (pour les miniatures) sont créés. Geo vérifie déjà les objets LFS et les téléversements, et il vérifie désormais également les dépôts de conception. Maintenant que toutes les données sous-jacentes de [Design Management](../../user/project/issues/design_management.md) sont vérifiées, l'intégrité de vos données de conception est garantie lors du transfert et au repos. Si Geo est utilisé dans le cadre d'une stratégie de reprise après sinistre, cela vous protège contre la perte de données.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Commenter un fichier entier dans les merge requests {#comment-on-whole-file-in-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/changes.md#add-a-comment-to-a-merge-request-file)

{{< /details >}}

Les merge requests prennent désormais en charge les commentaires sur un fichier entier, car tous les retours de merge request ne sont pas spécifiques à une ligne. Si un fichier est supprimé, vous pourriez vouloir plus d'informations sur la raison. Vous pourriez également vouloir faire des commentaires sur un nom de fichier ou des remarques générales sur la structure.

### Créer un changelog depuis la CLI GitLab {#create-a-changelog-from-the-gitlab-cli}

<!-- categories: GitLab CLI -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/project/changelogs.md#from-the-gitlab-cli)

{{< /details >}}

Les changelogs génèrent des listes complètes de modifications basées sur les commits d'un projet. Ils peuvent être difficiles à automatiser ou à consulter, et nécessitent d'interagir avec l'API GitLab.

Avec la sortie de [GitLab CLI v1.30.0](https://gitlab.com/gitlab-org/cli/-/releases/v1.30.0), vous pouvez désormais générer des changelogs pour des projets directement depuis votre shell. La commande `glab changelog generate` facilite la révision, l'automatisation et la publication des changelogs.

Merci à [Michael Mead](https://gitlab.com/michael-mead) pour votre contribution !

### Fermeture en cas d'échec pour les vérifications d'approbation de politique de sécurité invalides {#fail-closed-for-invalid-security-policy-approval-checks}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/merge_requests/approvals/_index.md#invalid-rules) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/389905)

{{< /details >}}

Les politiques de sécurité et de conformité permettent aux organisations d'appliquer des contrôles et des équilibres sur plusieurs projets afin de s'aligner sur leurs programmes de sécurité et de gouvernance. Il est essentiel pour nos clients de s'assurer que les changements ayant un impact sur les politiques n'entraînent pas la suppression des garde-fous. Avec cette mise à jour, les règles invalides « échoueront en mode fermé », bloquant les MR jusqu'à ce que les règles invalides dans les politiques de résultats de scan soient corrigées.

### Installer des paquets npm depuis votre groupe ou sous-groupe {#install-npm-packages-from-your-group-or-subgroup}

<!-- categories: Package Registry -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/packages/npm_registry/_index.md#install-from-a-group) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/299834)

{{< /details >}}

Vous pouvez utiliser le registre de paquets de votre projet pour publier et installer des paquets npm. Il vous suffit de vous authentifier à l'aide d'un jeton d'accès (personnel, de job, de déploiement ou de projet) et de commencer à publier des paquets dans votre projet GitLab.

Cela fonctionne très bien si vous avez un petit nombre de projets. Malheureusement, si vous avez plusieurs projets, vous pourriez rapidement vous retrouver à ajouter des dizaines, voire des centaines de sources différentes. Il est courant pour les équipes de grandes organisations de publier des paquets dans le registre de paquets de leur projet aux côtés du code source et des pipelines. Simultanément, elles doivent pouvoir installer facilement des dépendances depuis d'autres projets au sein des groupes et sous-groupes de leur organisation.

Pour faciliter le partage de paquets entre les projets, vous pouvez désormais installer des paquets depuis votre groupe afin de ne pas avoir à vous souvenir de quel projet héberge quel paquet. En utilisant un jeton d'authentification de votre choix, vous pouvez installer n'importe lequel des paquets npm du groupe après avoir ajouté votre groupe comme source de paquets npm.

### Ajouter une description aux téléversements de conception {#add-a-description-to-design-uploads}

<!-- categories: Portfolio Management, Design Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/issues/design_management.md#add-a-design-to-an-issue) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9694)

{{< /details >}}

Actuellement, les [téléversements de conception](../../user/project/issues/design_management.md#add-a-design-to-an-issue) n'ont pas de métadonnées pour expliquer leur objectif ou la raison de leur téléversement. Nous avons ajouté une zone de texte comme description pour vous aider à mieux faire comprendre l'image aux utilisateurs.

### Configurer le répertoire de fichiers statiques dans GitLab Pages {#configure-the-static-file-directory-in-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/pages/introduction.md#customize-the-default-folder) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/10126)

{{< /details >}}

Vous pouvez désormais configurer le répertoire de fichiers statiques pour GitLab Pages avec n'importe quel nom (par défaut `public`). Cela facilite l'utilisation de Pages avec des frameworks de sites statiques populaires tels que Next.js, Astro ou Eleventy, sans avoir à modifier le dossier de sortie dans leur configuration.

### Mises à jour de l'analyseur Code Quality {#code-quality-analyzer-updates}

<!-- categories: Code Quality -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/testing/code_quality.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/412459)

{{< /details >}}

GitLab Code Quality prend en charge [l'intégration des outils que vous utilisez déjà](../../ci/testing/code_quality.md) et propose également [un template CI/CD](../../ci/testing/code_quality.md) qui exécute le système de scan CodeClimate. Nous avons publié les mises à jour suivantes de l'analyseur basé sur CodeClimate lors du jalon de release 16.1 :

- Mise à jour de CodeClimate vers la version 0.96.0. Cette version inclut :
  - Un nouveau plugin pour `golangci-lint`.
  - Une nouvelle version disponible pour le plugin `bundler-audit`.
- Ajout de la prise en charge d'un chemin configurable vers le socket de l'API Docker.
  - Merci à [`@tsjnsn`](https://gitlab.com/tsjnsn) pour cette [contribution communautaire](https://gitlab.com/gitlab-org/ci-cd/codequality/-/merge_requests/73). Les mises à jour pour inclure cette variable dans le template CI/CD sont suivies dans [un ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/409738).

Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/CHANGELOG.md?ref_type=heads#anchor-0960) pour plus de détails.

Si vous [incluez le template Code Quality géré par GitLab](../../ci/testing/code_quality.md) ([`Code-Quality.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml)), vous recevez automatiquement ces mises à jour.

Pour les modifications de Code Quality dans les releases précédentes, consultez [la mise à jour la plus récente](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates).

### Mises à jour de l'analyseur SAST {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/analyzers.md) \| [Ticket associé](../../user/application_security/_index.md)

{{< /details >}}

GitLab SAST comprend [de nombreux analyseurs de sécurité](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) que l'équipe d'analyse statique de GitLab maintient, met à jour et prend en charge activement. Nous avons publié les mises à jour suivantes lors du jalon de release 16.1 :

- L'analyseur basé sur Semgrep est mis à jour pour utiliser la version 1.23.0 du moteur Semgrep. Nous avons également [clarifié les instructions et amélioré l'efficacité](https://docs.gitlab.com/#clearer-guidance-and-better-coverage-for-sast-rules) des règles gérées par GitLab utilisées pour analyser C, C#, Go et Java. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v434) pour plus de détails.
- L'analyseur basé sur SpotBugs prend désormais en charge la modification du « niveau d'effort » en [définissant la variable CI/CD `SAST_SCANNER_ALLOWED_CLI_OPTS`](../../user/application_security/sast/_index.md#security-scanner-configuration). Cela vous permet d'améliorer les performances en réduisant la précision du scan et sa capacité à détecter des vulnérabilités. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/blob/master/CHANGELOG.md#v420) pour plus de détails.

Si vous [incluez le modèle SAST géré par GitLab](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) et exécutez GitLab 16.0 ou version ultérieure, vous recevez automatiquement ces mises à jour. Pour rester sur une version spécifique d'un analyseur et empêcher les mises à jour automatiques, vous pouvez [épingler sa version](../../user/application_security/sast/_index.md).

Pour les modifications précédentes, consultez les [mises à jour du mois dernier](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#sast-analyzer-updates).

### Réponse automatique aux secrets Google Cloud divulgués {#automatic-response-to-leaked-google-cloud-secrets}

<!-- categories: Secret Detection -->

{{< details >}}

- Édition : Gold
- Liens : [Documentation](../../user/application_security/secret_detection/automatic_response.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/8835)

{{< /details >}}

Nous avons intégré la détection des secrets à Google Cloud pour mieux protéger les clients qui utilisent GitLab pour développer des applications sur Google Cloud. Désormais, si une organisation divulgue des identifiants Google Cloud dans un projet public sur GitLab.com, GitLab peut automatiquement protéger l'organisation en collaborant avec Google Cloud pour protéger le compte.

La détection des secrets recherche trois types de secrets émis par Google Cloud :

- [Clés de compte de service](https://docs.cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
- [Clés API](https://docs.cloud.google.com/docs/authentication/api-keys)
- [Secrets clients OAuth](https://support.google.com/cloud/answer/6158849#rotate-client-secret)

Les secrets divulgués publiquement sont envoyés à Google Cloud après leur découverte. Google Cloud vérifie les fuites, puis s'efforce de protéger les comptes clients contre les abus.

Cette intégration est activée par défaut pour les projets ayant [activé la détection des secrets](../../user/application_security/secret_detection/_index.md) sur GitLab.com. L'analyse de détection des secrets est disponible dans toutes les éditions GitLab, mais une réponse automatique aux secrets exposés n'est actuellement disponible que dans les projets Ultimate.

Consultez [l'article de blog sur cette intégration](https://about.gitlab.com/blog/how-secret-detection-can-proactively-revoke-leaked-credentials/) pour plus de détails.

### Instructions plus claires et meilleure couverture des règles SAST {#clearer-guidance-and-better-coverage-for-sast-rules}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/analyzers.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/382119)

{{< /details >}}

Nous avons mis à jour les règles GitLab SAST pour :

- Expliquer plus clairement le type de faiblesse que cible chaque règle et comment la corriger. Nous avons mis à jour la description et le texte d'instruction pour les règles C, C#, Go et Java jusqu'à présent. Les langages restants sont suivis dans le [ticket 382119](https://gitlab.com/gitlab-org/gitlab/-/issues/382119).
- Détecter des vulnérabilités supplémentaires dans les règles Java existantes.

Ces améliorations font partie d'une collaboration entre les équipes d'analyse statique et de recherche sur les vulnérabilités de GitLab pour [améliorer les ensembles de règles d'analyse statique par défaut](https://gitlab.com/groups/gitlab-org/-/epics/8170). Nous accueillerions favorablement tout retour sur les règles par défaut pour SAST, la détection des secrets et IaC Scanning dans l'[epic 8170](https://gitlab.com/groups/gitlab-org/-/epics/8170).

Pour plus de détails sur les modifications apportées aux règles GitLab SAST, consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blob/main/CHANGELOG.md). À partir de GitLab 16.1, le [projet `sast-rules`](https://gitlab.com/gitlab-org/security-products/sast-rules) est la source unique de toutes les règles par défaut gérées par GitLab utilisées dans l'analyseur SAST basé sur Semgrep.

### Personnalisations d'ensemble de règles partagées dans SAST, IaC Scanning et la détection des secrets {#shared-ruleset-customizations-in-sast-iac-scanning-and-secret-detection}

<!-- categories: SAST, Secret Detection -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/customize_rulesets.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/362958)

{{< /details >}}

Vous pouvez désormais définir une variable CI/CD pour partager les personnalisations d'ensemble de règles pour [SAST](../../user/application_security/sast/customize_rulesets.md), [IaC Scanning](../../user/application_security/iac_scanning/_index.md) ou la [détection des secrets](../../user/application_security/secret_detection/pipeline/_index.md) sur plusieurs projets.

Le partage d'un ensemble de règles peut vous aider à :

- [Désactiver les règles prédéfinies](../../user/application_security/sast/customize_rulesets.md) sur lesquelles vous ne souhaitez pas vous concentrer dans vos projets.
- [Modifier les champs dans les règles prédéfinies](../../user/application_security/sast/customize_rulesets.md), notamment la description, le message, le nom ou la gravité, pour refléter les préférences organisationnelles. Par exemple, vous pouvez ajuster la gravité par défaut d'une règle ou ajouter des informations sur la façon de remédier à un résultat.
- [Créer un ensemble de règles personnalisé](../../user/application_security/sast/customize_rulesets.md) en ajoutant ou en remplaçant des règles. Cette option n'est disponible que pour certains analyseurs.

D'autres améliorations dans ce domaine sont abordées dans [un ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/257928).

### CI/CD : utiliser `needs` dans `rules` {#cicd-use-needs-in-rules}

<!-- categories: Pipeline Composition -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#rulesneeds) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/31581)

{{< /details >}}

Le mot-clé [needs:](../../ci/yaml/_index.md#needs) définit une relation de dépendance entre les jobs, que vous pouvez utiliser pour configurer des jobs à exécuter en dehors de l'ordre des étapes. Dans cette release, nous avons ajouté la possibilité de définir cette relation pour des conditions `rules` spécifiques. Lorsqu'une condition correspond à une règle, la configuration `needs` du job est complètement remplacée par le `needs` de la règle. Cela peut aider à accélérer un pipeline en fonction de vos conditions définies, lorsqu'un job peut démarrer plus tôt que prévu. Vous pouvez également utiliser cela pour forcer un job à attendre qu'un précédent soit terminé avant de démarrer. Vous disposez désormais d'options `needs` plus flexibles !

### Embellir l'interface utilisateur des pipelines et jobs CI/CD {#beautify-the-ui-of-cicd-pipelines-and-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/394768)

{{< /details >}}

L'une des fonctionnalités les plus utilisées de GitLab est CI/CD. Dans la version 16.1, nous nous sommes concentrés sur l'amélioration de la convivialité et de l'expérience des vues de liste de pipeline CI/CD et de jobs, ainsi que de la page de détails du pipeline. Il est désormais plus facile de trouver les informations que vous recherchez ! Si vous avez des commentaires sur les modifications, nous serions ravis de vous lire dans notre [ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/issues/414756).

### Stockage accru pour les runners GitLab SaaS sur Linux {#increased-storage-for-gitlab-saas-runners-on-linux}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/linux.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/384223)

{{< /details >}}

Après avoir récemment augmenté la taille de nos [runners GitLab.com SaaS sur Linux](../../ci/runners/hosted_runners/linux.md) en termes de vCPU et de RAM, nous avons désormais également augmenté le stockage pour les types de machines `medium` et `large`.

Vous pouvez désormais créer, tester et déployer en toute fluidité des applications plus volumineuses nécessitant un environnement Linux GitLab Runner sécurisé, à la demande et entièrement intégré avec GitLab CI/CD.

### Endpoint de l'API pour la portée du jeton de job CI/CD {#cicd-job-token-scope-api-endpoint}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/jobs/ci_job_token.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/351740)

{{< /details >}}

À partir de GitLab 16.0, la [portée par défaut du jeton de job CI/CD (`CI_JOB_TOKEN`) a changé](../../ci/jobs/ci_job_token.md) pour tous les nouveaux projets. Cela a renforcé la sécurité des nouveaux projets, mais a ajouté une étape supplémentaire pour les utilisateurs qui utilisaient l'automatisation pour créer des projets. L'automatisation doit parfois également configurer la portée du jeton de job, ce qui ne pouvait être fait qu'avec GraphQL (ou manuellement dans l'interface utilisateur), et non via l'API REST.

Pour rendre ce paramètre configurable via l'API REST également, [Gerardo Navarro](https://gitlab.com/gerardo-navarro) a ajouté un nouvel endpoint pour contrôler la portée du jeton de job dans la version 16.1. Il est disponible pour les utilisateurs disposant d'un rôle Maintainer ou supérieur dans le projet. Merci pour cette excellente contribution, Gerardo !

### Détails du runner - regrouper les runners partageant une configuration {#runner-details---consolidate-runners-sharing-a-configuration}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner/fleet_scaling/#reusing-a-runner-configuration) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/409388/)

{{< /details >}}

La nouvelle méthode de création de runner vous permet de réutiliser une configuration de runner pour les scénarios où vous devrez peut-être enregistrer plusieurs runners avec les mêmes capacités. Les runners enregistrés avec le même jeton d'authentification partagent une configuration et sont regroupés dans la nouvelle vue détaillée.

### GitLab Runner 16.1 {#gitlab-runner-161}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.1 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et envoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Plugin GitLab Runner Fleeting pour les machines virtuelles Azure (version expérimentale)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29410). Merci à [vincent_stchu](https://gitlab.com/vincent_stchu) pour cette contribution !

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/-/blob/16-1-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Corrections de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.1)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.1)
- [Améliorations de l'interface](https://papercuts.gitlab.com/?milestone=16.1)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
