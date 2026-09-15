---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Limites de débit
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Pour GitLab.com, consultez [les limites de débit spécifiques à GitLab.com](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom).
>
> Pour GitLab Dedicated, consultez [les limites de débit pour les utilisateurs authentifiés](../administration/dedicated/user_rate_limits.md).

La limitation de débit est une technique courante utilisée pour améliorer la sécurité et la durabilité d'une application web.

Par exemple, un script simple peut effectuer des milliers de requêtes web par seconde. Ces requêtes peuvent être :

- Malveillantes
- Indifférentes
- Simplement dues à un bug

Votre application et votre infrastructure peuvent ne pas être en mesure de supporter la charge. Pour plus de détails, consultez [Attaque par déni de service](https://en.wikipedia.org/wiki/Denial-of-service_attack). La plupart des cas peuvent être atténués en limitant le débit des requêtes provenant d'une seule adresse IP.

La plupart des [attaques par force brute](https://en.wikipedia.org/wiki/Brute-force_attack) sont également atténuées par une limite de débit.

> [!note]
> Les limites de débit pour les requêtes API n'affectent pas les requêtes effectuées par le frontend, car ces requêtes sont toujours comptabilisées comme du trafic web.

## Limites configurables {#configurable-limits}

Vous pouvez définir ces limites de débit dans la zone **Admin** de votre instance :

- [Limites de débit d'import/export](../administration/settings/import_export_rate_limits.md)
- [Limites de débit des tickets](../administration/settings/rate_limit_on_issues_creation.md)
- [Limites de débit des notes](../administration/settings/rate_limit_on_notes_creation.md)
- [Chemins protégés](../administration/settings/protected_paths.md)
- [Limites de débit des endpoints bruts](../administration/settings/rate_limits_on_raw_endpoints.md)
- [Limites de débit des utilisateurs et des adresses IP](../administration/settings/user_and_ip_rate_limits.md)
- [Limites de débit du registre de paquets](../administration/settings/package_registry_rate_limits.md)
- [Limites de débit de Git LFS](../administration/settings/git_lfs_rate_limits.md)
- [Limites de débit sur les opérations Git SSH](../administration/settings/rate_limits_on_git_ssh_operations.md)
- [Limites de débit de l'API Files](../administration/settings/files_api_rate_limits.md)
- [Limites de débit de l'API obsolète](../administration/settings/deprecated_api_rate_limits.md)
- [Limites de débit de GitLab Pages](../administration/pages/_index.md#rate-limits)
- [Limites de débit des pipelines](../administration/settings/rate_limit_on_pipelines_creation.md)
- [Limites de débit de la gestion des incidents](../administration/settings/incident_management_rate_limits.md)
- [Limites de débit de l'API Projects](../administration/settings/rate_limit_on_projects_api.md)
- [Limites de débit de l'API Groups](../administration/settings/rate_limit_on_groups_api.md)
- [Limites de débit de l'API Users](../administration/settings/rate_limit_on_users_api.md)
- [Limites de débit de l'API Organizations](../administration/settings/rate_limit_on_organizations_api.md)
- [Limites de débit des opérations webhook](../administration/settings/rate-limit-on-webhook-operations.md)

Vous pouvez définir ces limites de débit à l'aide de l'[API ApplicationSettings](../api/settings.md) :

- [Limite de débit de la saisie semi-automatique des utilisateurs](../administration/instance_limits.md#autocomplete-users-rate-limit)

Vous pouvez définir ces limites de débit à l'aide de la console Rails :

- [Limite de débit des webhooks](../administration/instance_limits.md#webhook-rate-limit)

## Bannissement en cas d'échec d'authentification pour Git et le registre de conteneurs {#failed-authentication-ban-for-git-and-container-registry}

GitLab renvoie le code de statut HTTP `403` pendant 1 heure si 30 requêtes d'authentification échouées ont été reçues en l'espace de 3 minutes depuis une seule adresse IP. Ceci s'applique uniquement aux combinaisons suivantes :

- Requêtes Git
- Requêtes du registre de conteneurs (`/jwt/auth`)

Cette limite :

- Est réinitialisée par les requêtes qui s'authentifient avec succès. Par exemple, 29 requêtes d'authentification échouées suivies d'1 requête réussie, puis de 29 autres requêtes d'authentification échouées ne déclencheraient pas de bannissement.
- Ne s'applique pas aux requêtes JWT authentifiées par `gitlab-ci-token`.
- Est désactivée par défaut.

Aucun en-tête de réponse n'est fourni.

Pour éviter d'être soumis à une limite de débit, vous pouvez :

- Échelonner l'exécution de vos pipelines automatisés.
- Configurer un [recul exponentiel et une nouvelle tentative](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html) en cas d'échec d'authentification.
- Utiliser un processus documenté et les [bonnes pratiques](https://about.gitlab.com/blog/access-token-lifetime-limits/#how-to-minimize-the-impact) pour gérer l'expiration des jetons.

Pour les informations de configuration, consultez [les options de configuration du package Linux](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban).

## Limites non configurables {#non-configurable-limits}

### Archives du dépôt {#repository-archives}

Une limite de débit pour le [téléchargement des archives du dépôt](../api/repositories.md#retrieve-file-archive-from-a-repository) est disponible. La limite s'applique au projet et à l'utilisateur qui lance le téléchargement, que ce soit via l'interface utilisateur ou l'API.

La limite de débit est de 5 requêtes par minute et par utilisateur.

### Inscription des utilisateurs {#users-sign-up}

Il existe une limite de débit par adresse IP sur l'endpoint `/users/sign_up`. Ceci vise à atténuer les tentatives d'utilisation abusive de l'endpoint. Par exemple, pour découvrir en masse les noms d'utilisateur ou les adresses e-mail utilisés.

La limite de débit est de 20 appels par minute et par adresse IP.

### Modification du nom d'utilisateur {#update-username}

Il existe une limite de débit sur la fréquence à laquelle un nom d'utilisateur peut être modifié. Cette limite est appliquée pour atténuer les utilisations abusives de la fonctionnalité. Par exemple, pour découvrir en masse quels noms d'utilisateur sont utilisés.

La limite de débit est de 10 appels par minute et par utilisateur authentifié.

### Existence du nom d'utilisateur {#username-exists}

Il existe une limite de débit pour l'endpoint interne `/users/:username/exists`, utilisé lors de l'inscription pour vérifier si un nom d'utilisateur choisi a déjà été pris. Ceci vise à atténuer le risque d'abus, tel que la découverte en masse des noms d'utilisateur utilisés.

La limite de débit est de 20 appels par minute et par adresse IP.

### Endpoint de l'API Project Jobs {#project-jobs-api-endpoint}

Il existe une limite de débit pour l'endpoint `project/:id/jobs`, appliquée afin de réduire les délais d'attente lors de la récupération des jobs.

La limite de débit est par défaut de 600 appels par utilisateur authentifié. Vous pouvez [configurer la limite de débit](../administration/settings/user_and_ip_rate_limits.md).

### Action IA {#ai-action}

Il existe une limite de débit pour la mutation GraphQL `aiAction`, appliquée pour empêcher tout abus de cet endpoint.

La limite de débit est de 160 appels par 8 heures et par utilisateur authentifié.

### Suppression d'un membre via l'API {#delete-a-member-using-the-api}

Il existe une limite de débit pour la [suppression de membres de projet ou de groupe via les endpoints API](../api/group_members.md#remove-a-group-member) `/groups/:id/members` ou `/project/:id/members`.

La limite de débit est de 60 suppressions par minute.

### Liste des membres du projet via l'API {#list-project-members-using-the-api}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211239) dans GitLab 18.6.

{{< /history >}}

Définit une limite de débit pour lister tous les membres d'un projet dans un groupe ou un projet. Par défaut, 200 requêtes par minute sur les endpoints suivants :

```plaintext
GET /groups/:id/members/all
GET /projects/:id/members/all
```

Les administrateurs peuvent [configurer la limite de débit](../administration/settings/rate_limit_on_groups_api.md) pour l'endpoint des projets.

### Accès aux blobs et fichiers du dépôt {#repository-blob-and-file-access}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/security/gitlab/-/issues/1302) dans GitLab 18.1.

{{< /history >}}

Des limites de débit s'appliquent lors de l'accès à des fichiers volumineux via des endpoints spécifiques de l'API du dépôt. Pour les fichiers de plus de 10 Mo, la limite de débit est de 5 appels par minute par objet et par projet pour :

- [Endpoint blob du dépôt](../api/repositories.md#retrieve-a-blob-from-a-repository) : `/projects/:id/repository/blobs/:sha`
- [Endpoint fichier du dépôt](../api/repository_files.md#retrieve-a-file-from-a-repository) : `/projects/:id/repository/files/:file_path`

Ces limites aident à prévenir une utilisation excessive des ressources lors de l'accès à des fichiers volumineux du dépôt via l'API.

### E-mails de notification {#notification-emails}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/439101) dans GitLab 17.1 [avec le feature flag](../administration/feature_flags/_index.md) `rate_limit_notification_emails`. Désactivées par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/439101) dans GitLab 17.2. Suppression du feature flag `rate_limit_notification_emails`.

{{< /history >}}

Il existe une limite de débit pour les e-mails de notification liés à un projet ou un groupe.

La limite de débit est de 1 000 notifications par 24 heures par projet ou groupe et par utilisateur.

### Import GitHub {#github-import}

Il existe une limite de débit pour le déclenchement d'imports de projet depuis GitHub.

La limite de débit est de 6 imports déclenchés par minute et par utilisateur.

### Import FogBugz {#fogbugz-import}

{{< history >}}

- Introduit dans GitLab 17.6.

{{< /history >}}

Il existe une limite de débit pour le déclenchement d'imports de projet depuis FogBugz.

La limite de débit est de 1 import déclenché par minute et par utilisateur.

### Fichiers de diff de commit {#commit-diff-files}

Il s'agit d'une limite de débit pour les fichiers de diff de commit développés (`/[group]/[project]/-/commit/[:sha]/diff_files?expanded=1`), appliquée pour empêcher tout abus de cet endpoint.

La limite de débit est de 6 requêtes par minute et par utilisateur (authentifié) ou par adresse IP (non authentifié).

### Génération du changelog {#changelog-generation}

Il existe une limite de débit par utilisateur et par projet sur l'endpoint `:id/repository/changelog`. Ceci vise à atténuer les tentatives d'utilisation abusive de l'endpoint. La limite de débit est partagée entre les actions GET et POST.

La limite de débit est de 5 appels par minute et par utilisateur et par projet.

### Suppression d'un déploiement {#delete-a-deployment}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243738) dans GitLab 19.2.

{{< /history >}}

Une limite de débit s'applique à la [suppression d'un déploiement](../api/deployments.md#delete-a-deployment) via l'endpoint `DELETE /projects/:id/deployments/:deployment_id`. Cette limite réduit l'impact sur l'infrastructure des suppressions de déploiements en masse.

La limite de débit est de 500 requêtes par minute et par utilisateur authentifié.

## Dépannage {#troubleshooting}

### Rack Attack met le load balancer sur liste de refus {#rack-attack-is-denylisting-the-load-balancer}

Rack Attack peut bloquer votre load balancer si tout le trafic semble provenir du load balancer. Dans ce cas, vous devez :

1. [Configurer `nginx[real_ip_trusted_addresses]`](https://docs.gitlab.com/omnibus/settings/nginx/#configure-gitlab-trusted-proxies-and-nginx-real_ip-module). Ceci empêche les adresses IP des utilisateurs d'être répertoriées comme les adresses IP du load balancer.
1. Ajouter les adresses IP du load balancer à la liste d'autorisation.
1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Supprimer les adresses IP bloquées de Rack Attack avec Redis {#remove-blocked-ips-from-rack-attack-with-redis}

Pour supprimer une adresse IP bloquée :

1. Recherchez les adresses IP qui ont été bloquées dans le journal de production :

   ```shell
   grep "Rack_Attack" /var/log/gitlab/gitlab-rails/auth.log
   ```

1. La liste de refus est stockée dans Redis. Vous devez donc ouvrir `redis-cli` :

   ```shell
   /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
   ```

1. Vous pouvez supprimer le blocage en utilisant la syntaxe suivante, en remplaçant `<ip>` par l'adresse IP réelle qui est sur la liste de refus :

   ```plaintext
   del cache:gitlab:rack::attack:allow2ban:ban:<ip>
   ```

1. Vérifiez que la clé associée à l'adresse IP n'apparaît plus :

   ```plaintext
   keys *rack::attack*
   ```

   Par défaut, la [commande `keys` est désactivée](https://docs.gitlab.com/omnibus/settings/redis/#renamed-commands).

1. Le cas échéant, ajoutez [l'adresse IP à la liste d'autorisation](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban) pour éviter qu'elle ne soit à nouveau mise sur liste de refus.
