---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pages
description: Publiez des sites web statiques depuis votre dépôt avec un déploiement CI/CD automatique.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Pages publie des sites web statiques directement depuis un dépôt dans GitLab.

Ces sites web :

- Se déploient automatiquement avec les pipelines CI/CD GitLab.
- Prennent en charge tout générateur de site statique (comme Hugo, Jekyll ou Gatsby) ou du HTML, CSS, JavaScript et Wasm bruts.
- Fonctionnent sur l'infrastructure fournie par GitLab sans coût supplémentaire.
- Se connectent avec des domaines personnalisés et des certificats SSL/TLS.
- Contrôlent l'accès via une authentification intégrée.
- Évoluent de manière fiable pour les sites personnels, professionnels ou de documentation de projet.

Pour publier un site web avec Pages, utilisez tout générateur de site statique comme Gatsby, Jekyll, Hugo, Middleman, Harp, Hexo ou Brunch. Pages prend également en charge les sites web écrits directement en HTML, CSS, JavaScript et Wasm bruts. Le traitement dynamique côté serveur (comme `.php` et `.asp`) n'est pas pris en charge. Pour en savoir plus, consultez [Sites web statiques vs dynamiques](https://about.gitlab.com/blog/ssg-overview-gitlab-pages-part-1-dynamic-x-static/).

## Premiers pas {#getting-started}

Pour créer un site web GitLab Pages :

| Document                                                                             | Description                                                                                  |
|--------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| [Utiliser l'interface utilisateur GitLab pour créer un fichier `.gitlab-ci.yml` simple](getting_started/pages_ui.md) | Ajouter un site Pages à un projet existant. Utilisez l'interface utilisateur pour configurer un fichier `.gitlab-ci.yml` simple.     |
| [Créer un fichier `.gitlab-ci.yml` de zéro](getting_started/pages_from_scratch.md) | Ajouter un site Pages à un projet existant. Apprenez à créer et configurer votre propre fichier CI. |
| [Utiliser un modèle `.gitlab-ci.yml`](getting_started/pages_ci_cd_template.md)           | Ajouter un site Pages à un projet existant. Utilisez un fichier de modèle CI pré-rempli.               |
| [Dupliquer un projet d'exemple](getting_started/pages_forked_sample_project.md)              | Créer un nouveau projet avec Pages déjà configuré en dupliquant un projet d'exemple.              |
| [Utiliser un modèle de projet](getting_started/pages_new_project_template.md)              | Créer un nouveau projet avec Pages déjà configuré en utilisant un modèle.                      |

Pour mettre à jour un site web GitLab Pages :

| Document | Description |
|----------|-------------|
| [Noms de domaine, URLs et URLs de base GitLab Pages](getting_started_part_one.md) | En savoir plus sur les domaines par défaut de GitLab Pages. |
| [Explorer GitLab Pages](introduction.md) | Prérequis, aspects techniques, options de configuration spécifiques à GitLab CI/CD, contrôle d'accès, pages 404 personnalisées, limitations et FAQ. |
| [Domaines personnalisés et certificats SSL/TLS](custom_domains_ssl_tls_certification/_index.md) | Domaines et sous-domaines personnalisés, enregistrements DNS et certificats SSL/TLS. |
| [Intégration Let's Encrypt](custom_domains_ssl_tls_certification/lets_encrypt_integration.md) | Sécurisez vos sites Pages avec les certificats Let's Encrypt, qui sont automatiquement obtenus et renouvelés par GitLab. |
| [Redirections](redirects.md) | Configurez des redirections HTTP pour transférer une page vers une autre. |

Pour plus d'informations, consultez :

| Document | Description |
|----------|-------------|
| [Sites web statiques vs dynamiques](https://about.gitlab.com/blog/ssg-overview-gitlab-pages-part-1-dynamic-x-static/) | Aperçu des sites statiques versus dynamiques. |
| [Générateurs de sites statiques modernes](https://about.gitlab.com/blog/ssg-overview-gitlab-pages-part-2/) | Aperçu des SSG. |
| [Créer n'importe quel site SSG avec GitLab Pages](https://about.gitlab.com/blog/ssg-overview-gitlab-pages-part-3-examples-ci/) | Utiliser des SSG pour GitLab Pages. |

## Utilisation de GitLab Pages {#using-gitlab-pages}

Pour utiliser GitLab Pages, vous devez créer un projet dans GitLab afin d'y téléverser les fichiers de votre site web. Ces projets peuvent être publics, internes ou privés.

Par défaut, GitLab déploie votre site web depuis un dossier spécifique appelé `public` dans votre dépôt. Vous pouvez également [définir un dossier personnalisé à déployer avec Pages](introduction.md#customize-the-default-folder). Lorsque vous créez un nouveau projet dans GitLab, un [dépôt](../repository/_index.md) devient automatiquement disponible.

Pour déployer votre site, GitLab utilise son outil intégré appelé [GitLab CI/CD](../../../ci/_index.md) pour construire votre site et le publier sur le serveur GitLab Pages. La séquence de scripts que GitLab CI/CD exécute pour accomplir cette tâche est créée à partir d'un fichier nommé `.gitlab-ci.yml`, que vous pouvez [créer et modifier](getting_started/pages_from_scratch.md). Un `job` défini par l'utilisateur avec la propriété `pages: true` dans le fichier de configuration indique à GitLab que vous déployez un site web GitLab Pages.

Vous pouvez utiliser le [domaine par défaut de GitLab Pages](getting_started_part_one.md#gitlab-pages-default-domain-names), `*.gitlab.io`, ou votre propre domaine (`example.com`). Dans ce cas, vous devez être administrateur auprès du registraire de votre domaine (ou panneau de contrôle) pour le configurer avec Pages.

## Accès à votre site Pages {#access-to-your-pages-site}

Si vous utilisez le domaine par défaut de GitLab Pages (`.gitlab.io`), votre site web est automatiquement sécurisé et disponible via HTTPS. Si vous utilisez votre propre domaine personnalisé, vous pouvez éventuellement le sécuriser avec des certificats SSL/TLS.

Si vous utilisez GitLab.com, votre site web est accessible publiquement sur internet. Pour restreindre l'accès à votre site web, activez le [contrôle d'accès GitLab Pages](pages_access_control.md).

Si vous utilisez une instance GitLab Self-Managed, vos sites web sont publiés sur votre propre serveur, selon les [paramètres Pages](../../../administration/pages/_index.md) choisis par votre administrateur système, qui peut les rendre publics ou internes.

## Exemples de Pages {#pages-examples}

Ces exemples de sites web GitLab Pages vous permettent d'apprendre des techniques avancées à utiliser et à adapter selon vos besoins :

- [Publier sur votre blog GitLab Pages depuis iOS](https://about.gitlab.com/blog/posting-to-your-gitlab-pages-blog-from-ios/).
- [GitLab CI : Exécuter des jobs séquentiellement, en parallèle, ou créer un pipeline personnalisé](https://about.gitlab.com/blog/basics-of-gitlab-ci-updated/).
- [GitLab CI : Déploiement & environnements](https://about.gitlab.com/blog/ci-deployment-and-environments/).
- [Création d'un nouveau site de documentation GitLab avec Nanoc, GitLab CI et GitLab Pages](https://about.gitlab.com/blog/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/).
- [Publier des rapports de couverture de code avec GitLab Pages](https://about.gitlab.com/blog/publish-code-coverage-report-with-gitlab-pages/).

## Administrer GitLab Pages pour les instances GitLab Self-Managed {#administer-gitlab-pages-for-gitlab-self-managed-instances}

Si vous exécutez une instance GitLab Self-Managed, [suivez les étapes d'administration](../../../administration/pages/_index.md) pour configurer Pages.

<i class="fa-youtube-play" aria-hidden="true"></i> Regardez un [tutoriel vidéo](https://www.youtube.com/watch?v=dD8c7WNcc6s) sur la prise en main de l'administration de GitLab Pages.

### Configurer GitLab Pages dans une instance Helm Chart (Kubernetes) {#configure-gitlab-pages-in-a-helm-chart-kubernetes-instance}

Pour configurer GitLab Pages sur des instances déployées avec Helm chart (Kubernetes), utilisez l'une ou l'autre des options suivantes :

- [Le sous-chart `gitlab-pages`](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/).
- [Une instance GitLab Pages externe](https://docs.gitlab.com/charts/advanced/external-gitlab-pages/).

## Sécurité pour GitLab Pages {#security-for-gitlab-pages}

### Espaces de nommage contenant `.` {#namespaces-that-contain-}

Si votre nom d'utilisateur est `example`, votre site web GitLab Pages est situé à l'adresse `example.gitlab.io`. GitLab autorise les noms d'utilisateur à contenir un `.`, donc un utilisateur nommé `bar.example` pourrait créer un site web GitLab Pages `bar.example.gitlab.io` qui est effectivement un sous-domaine de votre site web `example.gitlab.io`. Soyez prudent si vous utilisez JavaScript pour définir des cookies pour votre site web. La méthode sûre pour définir manuellement des cookies avec JavaScript est de ne pas spécifier le `domain` du tout :

```javascript
// Safe: This cookie is only visible to example.gitlab.io
document.cookie = "key=value";

// Unsafe: This cookie is visible to example.gitlab.io and its subdomains,
// regardless of the presence of the leading dot.
document.cookie = "key=value;domain=.example.gitlab.io";
document.cookie = "key=value;domain=example.gitlab.io";
```

Ce problème n'affecte pas les utilisateurs disposant d'un domaine personnalisé, ni ceux qui ne définissent pas de cookies manuellement avec JavaScript.

### Cookies partagés {#shared-cookies}

Par défaut, chaque projet d'un groupe partage le même domaine, par exemple `group.gitlab.io`. Cela signifie que les cookies sont également partagés pour tous les projets d'un groupe.

Pour que chaque projet utilise des cookies différents, activez la fonctionnalité [domaines uniques](#unique-domains) de Pages pour votre projet.

## Domaines uniques {#unique-domains}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/9347) dans GitLab 15.9 [avec un flag](../../../administration/feature_flags/_index.md) nommé `pages_unique_domain`. Désactivé par défaut.
- [Activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/388151) dans GitLab 15.11.
- [Feature flag supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122229) dans GitLab 16.3.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163523) des URLs de domaine unique pour les rendre plus courtes dans GitLab 17.4.

{{< /history >}}

Par défaut, chaque nouveau projet utilise des domaines uniques Pages pour éviter que les projets d'un même groupe ne partagent des cookies.

Le mainteneur du projet peut désactiver cette fonctionnalité sur :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déploiement** > **Pages**.
1. Décochez la case **Utiliser un domaine unique**.
1. Sélectionnez **Sauvegarder les modifications**.

Pour des exemples d'URLs, consultez [Noms de domaine par défaut GitLab Pages](getting_started_part_one.md#gitlab-pages-default-domain-names).

## Domaine principal {#primary-domain}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/481334) dans GitLab 17.8.

{{< /history >}}

Lorsque vous utilisez GitLab Pages avec des domaines personnalisés, vous pouvez rediriger toutes les requêtes vers GitLab Pages vers un domaine principal. Lorsque le domaine principal est sélectionné, les utilisateurs reçoivent un statut `308 Permanent Redirect` qui redirige le navigateur vers le domaine principal sélectionné. Les navigateurs peuvent mettre en cache cette redirection.

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.
- Un [domaine personnalisé](custom_domains_ssl_tls_certification/_index.md#set-up-a-custom-domain) doit être configuré.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déploiement** > **Pages**.
1. Dans la liste déroulante **Domaine principal**, sélectionnez le domaine vers lequel effectuer la redirection.
1. Sélectionnez **Sauvegarder les modifications**.

## Déploiements expirants {#expiring-deployments}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162826) dans GitLab 17.4.
- La prise en charge des variables a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/492289) dans GitLab 17.11.

{{< /history >}}

Vous pouvez configurer vos déploiements Pages pour qu'ils soient automatiquement supprimés après un certain délai en spécifiant une durée dans [`pages.expire_in`](../../../ci/yaml/_index.md#pagesexpire_in) :

```yaml
create-pages:
  stage: deploy
  script:
    - ...
  pages:  # specifies that this is a Pages job and publishes the default public directory
    expire_in: 1 week
```

Les déploiements expirés sont arrêtés par un cron job qui s'exécute toutes les 10 minutes. Les déploiements arrêtés sont ensuite supprimés par un autre cron job qui s'exécute également toutes les 10 minutes. Pour le récupérer, suivez les étapes décrites dans [Récupérer un déploiement arrêté](#recover-a-stopped-deployment).

Un déploiement arrêté ou supprimé n'est plus disponible sur le web. Une page d'erreur 404 Non trouvé s'affiche à son URL, jusqu'à ce qu'un autre déploiement soit créé avec la même configuration d'URL.

L'exemple YAML précédent utilise des [noms de job définis par l'utilisateur](#user-defined-job-names).

### Récupérer un déploiement arrêté {#recover-a-stopped-deployment}

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour récupérer un déploiement arrêté qui n'a pas encore été supprimé :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déploiement** > **Pages**.
1. À proximité de **Déploiements**, activez le bouton **Inclure les déploiements interrompus**. Si votre déploiement n'a pas encore été supprimé, il devrait figurer dans la liste.
1. Développez le déploiement que vous souhaitez récupérer et sélectionnez **Restaurer**.

### Supprimer un déploiement {#delete-a-deployment}

Pour supprimer un déploiement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déploiement** > **Pages**.
1. Sous **Déploiements**, sélectionnez n'importe quelle zone du déploiement que vous souhaitez supprimer. Les détails du déploiement se développent.
1. Sélectionnez **Supprimer**.

Lorsque vous sélectionnez **Supprimer**, votre déploiement est arrêté immédiatement. Les déploiements arrêtés sont supprimés par un cron job s'exécutant toutes les 10 minutes.

Pour restaurer un déploiement arrêté qui n'a pas encore été supprimé, consultez [Récupérer un déploiement arrêté](#recover-a-stopped-deployment).

## Noms de job définis par l'utilisateur {#user-defined-job-names}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/232505) dans GitLab 17.5 avec un flag `customizable_pages_job_name`, désactivé par défaut.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169095) dans GitLab 17.6. L'indicateur de fonctionnalité `customizable_pages_job_name` a été supprimé.

{{< /history >}}

Pour déclencher un déploiement Pages depuis n'importe quel job, incluez la propriété `pages` dans la définition du job. Il peut s'agir soit d'un booléen défini à `true`, soit d'un hash.

Par exemple, en utilisant `true` :

```yaml
deploy-my-pages-site:
  stage: deploy
  script:
    - npm run build
  pages: true  # specifies that this is a Pages job and publishes the default public directory
```

Par exemple, en utilisant un hash :

```yaml
deploy-pages-review-app:
  stage: deploy
  script:
    - npm run build
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: '_staging'
```

Si la propriété `pages` d'un job nommé `pages` est définie à `false`, aucun déploiement n'est déclenché :

```yaml
pages:
  pages: false
```

> [!warning]
> Si vous avez plusieurs jobs Pages dans votre pipeline avec la même valeur pour `path_prefix`, le dernier à se terminer est déployé avec Pages.

## Déploiements parallèles {#parallel-deployments}

Pour créer plusieurs déploiements pour votre projet en même temps, par exemple pour créer des environnements éphémères, consultez la documentation sur les [déploiements parallèles](parallel_deployments.md).
