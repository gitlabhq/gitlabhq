---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez les limites de débit qui s'appliquent à GitLab.com, notamment les limites proposées pour chaque plan d'abonnement."
title: Limites de débit de GitLab.com
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Les limites de débit suivantes s'appliquent à GitLab.com.

GitLab Self-Managed et les instances GitLab Dedicated ont leurs propres limites, contrôlées par l'opérateur de l'instance. Si vous n'utilisez pas GitLab.com, consultez plutôt [les limites de débit](../../rate_limits/_index.md) ou [les limites de débit pour les utilisateurs authentifiés](../../administration/dedicated/user_rate_limits.md).

## Limites de débit par plan {#rate-limits-by-plan}

> [!note]
> Les limites de cette section sont proposées et ne sont pas encore en vigueur. Les limites décrites dans [les limites de débit actuelles](#current-rate-limits) s'appliquent aujourd'hui et continuent de s'appliquer après l'entrée en vigueur de ces changements. GitLab annonce les dates spécifiques à l'avance. Avant qu'une limite soit appliquée, GitLab exécute des fenêtres de panne programmées pendant lesquelles la nouvelle limite est brièvement active, afin que vous puissiez observer son impact sur vos charges de travail.

Les limites de débit deviennent sensibles à l'édition. Au lieu d'un chiffre unique pour tous, les limites reflètent votre plan et s'appliquent par utilisateur. Les requêtes authentifiées bénéficient du quota complet de votre plan. Les requêtes anonymes bénéficient d'un quota bien plus faible, conformément aux pratiques de plateformes similaires.

Chaque plan comporte deux limites pour le trafic authentifié, la limite soutenue ayant la priorité :

- Une limite soutenue, mesurée chaque heure. Utilisez ce chiffre pour planifier votre utilisation.
- Une limite de rafale, mesurée chaque minute. GitLab définit cette valeur par défaut afin qu'un pic court ne consomme pas l'intégralité du quota horaire en une seule fois.

Pour un travail régulier, vous atteignez d'abord la limite soutenue. L'envoi de requêtes à la limite de rafale pendant une heure entière dépasserait la limite soutenue pour tous les plans. Considérez la limite de rafale comme un plafond pour les pics courts, et non comme un débit que vous pouvez maintenir.

Les requêtes à la limite de rafale atteignent la limite soutenue en environ 50 minutes avec l'édition Gratuite, 12 minutes avec Premium et 12,5 minutes avec Ultimate.

Ces limites s'appliquent aux requêtes d'API, aux requêtes web et aux requêtes Git authentifiées via HTTPS. Les requêtes Git non authentifiées via HTTPS ne sont pas comptabilisées dans la limite non authentifiée. Elles restent soumises à la [limite actuelle pour une adresse IP](#current-rate-limits).

### Limites soutenues {#sustained-limits}

| Limite de débit                                 | Gratuite            | GitLab Premium          | GitLab Ultimate         |
| ------------------------------------------ | --------------- | ---------------- | ---------------- |
| Trafic authentifié pour un utilisateur           | 5 000 par heure | 15 000 par heure | 25 000 par heure |
| Trafic non authentifié depuis une adresse IP | 60 par heure    | 60 par heure     | 60 par heure     |

### Limites de rafale {#burst-limits}

| Limite de débit                       | Gratuite            | GitLab Premium           | GitLab Ultimate          |
| -------------------------------- | --------------- | ----------------- | ----------------- |
| Trafic authentifié pour un utilisateur | 100 par minute | 1 250 par minute | 2 000 par minute |

## Lorsque vous dépassez une limite {#when-you-exceed-a-limit}

Lorsqu'une requête fait l'objet d'une limitation de débit, GitLab répond avec le code de statut `429 Too Many Requests`. Patientez avant de retenter la requête.

Les réponses aux requêtes limitées incluent un en-tête `Retry-After` qui indique le nombre de secondes restantes avant la réinitialisation de votre quota, et un en-tête `RateLimit-ResetTime` avec les mêmes informations sous forme de date et d'heure. Toutes les réponses, limitées ou non, incluent `RateLimit-Limit`, `RateLimit-Remaining` et des en-têtes connexes que vous pouvez utiliser pour suivre votre utilisation avant d'atteindre une limite. Pour la liste complète, consultez [les en-têtes de réponse](../../administration/settings/user_and_ip_rate_limits.md#response-headers).

Pour gérer correctement les limites :

- Attendez la durée indiquée dans `Retry-After` avant de réessayer.
- Appliquez un recul exponentiel si vous continuez à être limité.
- Surveillez `RateLimit-Remaining` et ralentissez avant d'épuiser votre quota.

Les réponses de limitation de débit pour les API Projets, Groupes et Utilisateurs n'incluent pas d'en-têtes d'information. Les en-têtes de réponse ne reflètent pas non plus certaines autres limites. Vous pouvez donc recevoir une réponse `429` même lorsque les en-têtes de votre réponse précédente indiquaient un quota restant.

## Si vous avez besoin de plus de marge {#if-you-need-more-headroom}

Si vous atteignez régulièrement une limite, plusieurs options s'offrent à vous, de la moins contraignante à la plus engageante :

1. Optimisez votre utilisation de l'API. Regroupez les requêtes, mettez en cache les réponses, utilisez la pagination et respectez l'en-tête `Retry-After`. La plupart des utilisations restent en dessous des limites.
1. Authentifiez vos requêtes. Le trafic anonyme bénéficie du quota le plus bas. L'authentification avec [un jeton d'accès personnel, un jeton OAuth ou un jeton de job CI/CD](../../api/rest/authentication.md) vous accorde les limites complètes de votre plan.
1. Passez à une édition supérieure. Premium et Ultimate offrent des limites plus élevées.

Pour les besoins soutenus dépassant les limites de votre plan, une option d'achat de marge supplémentaire est en cours de conception. Les détails seront publiés à l'approche de la disponibilité.

## Limites de débit actuelles {#current-rate-limits}

Ces limites sont actuellement en vigueur sur GitLab.com et continueront de s'appliquer après l'introduction des [limites de débit par plan](#rate-limits-by-plan).

GitLab vérifie d'abord les limites de votre plan, puis les limites de ce tableau. La limite la plus basse s'applique. Une limite dans ce tableau peut être inférieure à la limite de votre plan, et vous pourriez donc l'atteindre en premier.

Par exemple, le trafic d'API authentifié pour un utilisateur est limité à 2 000 requêtes par minute. Avec les éditions Gratuite et Premium, la limite de rafale de votre plan est plus basse, et vous l'atteignez donc en premier. Avec Ultimate, la limite de rafale est également de 2 000 requêtes par minute, les deux limites sont donc identiques.

| Limite de débit                                                                                                    | Paramètre                         |
| ------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| Chemins protégés pour une adresse IP                                                                             | 10 requêtes par minute         |
| Tentatives de connexion (`POST /users/sign_in`) pour une adresse IP                                                    | 10 requêtes toutes les 5 minutes     |
| Trafic vers les endpoints bruts pour un projet, un commit ou un chemin de fichier                                                      | 300 requêtes par minute        |
| Trafic non authentifié vers les endpoints bruts pour un projet                                                            | 800 requêtes par minute        |
| Trafic non authentifié depuis une adresse IP                                                                    | 500 requêtes par minute        |
| Trafic d'API authentifié pour un utilisateur                                                                          | 2 000 requêtes par minute      |
| Trafic HTTP non-API authentifié pour un utilisateur                                                                 | 1 000 requêtes par minute      |
| Trafic Git HTTPS authentifié pour un utilisateur                                                                    | 10 000 requêtes par minute     |
| Trafic Git HTTPS non authentifié depuis une adresse IP                                                          | 15 000 requêtes par minute     |
| Opérations Git SSH pour un utilisateur, un projet et une commande Git                                                       | 600 opérations par minute      |
| Tout le trafic depuis une adresse IP                                                                                | 2 000 requêtes par minute      |
| Création de tickets                                                                                                | 200 requêtes par minute        |
| Création de notes sur les tickets et les merge requests                                                                    | 60 requêtes par minute         |
| API de recherche avancée, par projet ou par groupe pour une adresse IP                                                      | 100 requêtes par minute        |
| API de recherche avancée, par projet ou par groupe pour un utilisateur                                                             | 100 requêtes par minute        |
| Requêtes GitLab Pages pour une adresse IP                                                                       | 1 000 requêtes toutes les 50 secondes |
| Requêtes GitLab Pages pour un domaine GitLab Pages                                                               | 5 000 requêtes toutes les 10 secondes |
| Connexions TLS GitLab Pages pour une adresse IP                                                                | 1 000 requêtes toutes les 50 secondes |
| Connexions TLS GitLab Pages pour un domaine GitLab Pages                                                        | 400 requêtes toutes les 10 secondes   |
| Requêtes de création de pipeline pour un projet, un utilisateur ou un commit                                                     | 25 requêtes par minute         |
| Requêtes de création de pipeline pour un utilisateur                                                                         | 2 000 requêtes par minute      |
| Requêtes vers l'endpoint d'intégration d'alertes pour un projet                                                             | 3 600 requêtes par heure       |
| Requêtes GitLab Duo `aiAction`                                                                                | 160 requêtes toutes les 8 heures      |
| Intervalles de [mise en miroir pull](../project/repository/mirror/pull.md)                                              | 5 minutes                       |
| Requêtes d'API d'un utilisateur vers `/api/v4/users/:id`                                                               | 300 requêtes toutes les 10 minutes   |
| Requêtes vers le système d'hébergement de paquets GitLab pour une adresse IP                                                      | 1 000 requêtes par minute      |
| Requêtes d'API de fichiers de dépôt (`GET /api/v4/projects/:id/repository/files/*`) pour une adresse IP et un chemin de fichier | 500 requêtes par minute        |
| Requêtes des abonnés d'un utilisateur (`/api/v4/users/:id/followers`)                                                       | 100 requêtes par minute        |
| Requêtes des abonnements d'un utilisateur (`/api/v4/users/:id/following`)                                                       | 100 requêtes par minute        |
| Requêtes de statut d'un utilisateur (`/api/v4/users/:user_id/status`)                                                        | 240 requêtes par minute        |
| Requêtes de clés SSH d'un utilisateur (`/api/v4/users/:user_id/keys`)                                                        | 120 requêtes par minute        |
| Requêtes pour une clé SSH unique (`/api/v4/users/:id/keys/:key_id`)                                                    | 120 requêtes par minute        |
| Requêtes de clés GPG d'un utilisateur (`/api/v4/users/:id/gpg_keys`)                                                         | 120 requêtes par minute        |
| Requêtes pour une clé GPG unique (`/api/v4/users/:id/gpg_keys/:key_id`)                                                | 120 requêtes par minute        |
| Requêtes de projets d'un utilisateur (`/api/v4/users/:user_id/projects`)                                                    | 300 requêtes par minute        |
| Requêtes de projets auxquels un utilisateur a contribué (`/api/v4/users/:user_id/contributed_projects`)                            | 100 requêtes par minute        |
| Requêtes de projets suivis par un utilisateur (`/api/v4/users/:user_id/starred_projects`)                                    | 100 requêtes par minute        |
| Requêtes de liste de projets (`/api/v4/projects`)                                                                   | 2 000 requêtes toutes les 10 minutes |
| Requêtes non authentifiées de liste de projets (`/api/v4/projects`) depuis une adresse IP                                | 400 requêtes toutes les 10 minutes   |
| Requêtes de projets d'un groupe (`/api/v4/groups/:id/projects`)                                                       | 600 requêtes par minute        |
| Requêtes pour un projet unique (`/api/v4/projects/:id`)                                                              | 400 requêtes par minute        |
| Requêtes de liste de groupes (`/api/v4/groups`)                                                                       | 50 requêtes par minute         |
| Requêtes pour un groupe unique (`/api/v4/groups/:id`)                                                                  | 400 requêtes par minute        |
| Requêtes de jobs de runner utilisant un token de runner (`/api/v4/jobs/request`)                                            | 2 000 requêtes par minute      |
| Requêtes de jobs de runner utilisant un token de runner depuis une adresse IP (`/api/v4/jobs/request`)                         | 2 400 requêtes par minute      |
| Requêtes de mise à jour de trace de job de runner utilisant un token de job (`/api/v4/jobs/trace`)                                      | 200 requêtes par minute        |
| Requêtes de jobs de runner utilisant un token de job (`/api/v4/jobs/*`)                                                     | 200 requêtes par minute        |
| Lister tous les membres d'un projet                                                                         | 200 requêtes par minute        |

Des informations supplémentaires sont disponibles sur les limites de débit pour les [chemins protégés](#protected-paths-throttle) et les [endpoints bruts](../../administration/settings/rate_limits_on_raw_endpoints.md).

GitLab peut limiter le débit des requêtes à plusieurs niveaux. Ces limites sont les plus restrictives pour chaque adresse IP.

## Limite de débit des e-mails Service Desk {#service-desk-email-rate-limit}

GitLab.com limite par plan le nombre d'e-mails de notification Service Desk sortants qu'un groupe principal peut envoyer chaque heure et chaque jour :

| Plan                                   | Limite horaire | Limite journalière |
| -------------------------------------- | ------------ | ----------- |
| Gratuite, essai Premium, essai Ultimate    | 100          | 700         |
| Open Source                            | 1 500        | 10 000      |
| GitLab Premium                                | 5 000        | 50 000      |
| Ultimate, client payant de l'essai Ultimate | Illimité    | Illimité   |

Pour plus d'informations, consultez [la limite de débit des e-mails Service Desk](../../administration/instance_limits.md#service-desk-email-rate-limit).

## Import de groupes et de projets par chargement de fichiers d'export {#group-and-project-import-by-uploading-export-files}

Pour aider à prévenir les abus, GitLab.com applique des limites de débit à :

- Les imports de projets et de groupes.
- Les exports de groupes et de projets utilisant des fichiers.
- Les téléchargements d'exports.

Pour plus d'informations, consultez :

- [Limites de débit pour l'import/export de projets](../project/settings/import_export.md#rate-limits)
- [Limites de débit pour l'import/export de groupes](../project/settings/import_export.md#rate-limits-1)

## Blocages d'IP {#ip-blocks}

Des blocages d'IP peuvent survenir lorsque GitLab.com reçoit un trafic inhabituel depuis une seule adresse IP que le système considère comme potentiellement malveillant. Ces blocages peuvent être basés sur les paramètres de limite de débit. Une fois le trafic inhabituel cessé, GitLab libère automatiquement l'adresse IP. La durée de libération dépend du type de blocage, comme décrit dans la section suivante.

Si vous recevez une erreur `403 Forbidden` pour toutes les requêtes vers GitLab.com, vérifiez la présence de processus automatisés susceptibles de déclencher un blocage. Pour obtenir de l'aide, contactez [le support GitLab](https://support.gitlab.com) en précisant les détails, tels que l'adresse IP concernée.

### Bannissement suite à des échecs d'authentification Git et du registre de conteneurs {#git-and-container-registry-failed-authentication-ban}

GitLab.com répond avec le code de statut `403 Forbidden` pendant 15 minutes lorsqu'une seule adresse IP envoie 300 requêtes d'authentification échouées en une minute.

Cette réponse s'applique uniquement aux requêtes Git et aux requêtes vers le registre de conteneurs (`/jwt/auth`) (combinées).

Cette limite :

- Est réinitialisée par les requêtes qui s'authentifient avec succès. Par exemple, 299 requêtes d'authentification échouées suivies d'une requête réussie, puis de 299 autres requêtes d'authentification échouées, ne déclenchent pas de bannissement.
- Ne s'applique pas aux requêtes JWT authentifiées par `gitlab-ci-token`.

Aucun en-tête de réponse n'est fourni.

Les requêtes Git via HTTPS envoient toujours d'abord une requête non authentifiée, ce qui entraîne une erreur `401 Unauthorized` pour les dépôts privés. Git tente ensuite une requête authentifiée avec un nom d'utilisateur, un mot de passe ou un token d'accès, si disponible. Ces requêtes peuvent entraîner un blocage temporaire d'IP si trop de requêtes sont envoyées simultanément. Pour résoudre ce problème, utilisez [les clés SSH pour communiquer avec GitLab](../ssh.md).

## Limites non configurables {#non-configurable-limits}

Pour plus d'informations sur les limites de débit non configurables utilisées sur GitLab.com, consultez [les limites non configurables](../../rate_limits/non_configurable.md).

## En-têtes de réponse de pagination {#pagination-response-headers}

Pour des raisons de performance, si une requête retourne plus de 10 000 enregistrements, [GitLab exclut certains en-têtes](../../api/rest/_index.md#pagination-response-headers).

## Limitation des chemins protégés {#protected-paths-throttle}

Si la même adresse IP envoie plus de 10 requêtes POST par minute vers des chemins protégés, GitLab.com retourne le code de statut `429 Too Many Requests`.

Les chemins protégés incluent la création d'utilisateur, la confirmation d'utilisateur, la connexion d'utilisateur et la réinitialisation de mot de passe. Pour la liste complète, consultez [les chemins protégés](../../administration/settings/protected_paths.md).

Pour les en-têtes que GitLab inclut dans les requêtes bloquées, consultez [les limites de débit pour les utilisateurs et les adresses IP](../../administration/settings/user_and_ip_rate_limits.md#response-headers).

## Nombre maximal de connexions SSH {#ssh-maximum-number-of-connections}

GitLab.com définit le nombre maximal de connexions SSH simultanées non authentifiées en utilisant le [paramètre `MaxStartups`](https://man.openbsd.org/sshd_config.5#MaxStartups). Si le nombre maximal de connexions autorisées est dépassé simultanément, GitLab supprime les connexions en excès. Les utilisateurs reçoivent alors [une erreur `ssh_exchange_identification`](../../topics/git/troubleshooting_git.md#ssh_exchange_identification-error).

## Sujets connexes {#related-topics}

- [Paramètres de GitLab.com](_index.md)
- [Limites de débit](../../rate_limits/_index.md)
- [Limites de débit sur les opérations Git](../../rate_limits/git.md)
- [Authentification à l'API REST](../../api/rest/authentication.md)
