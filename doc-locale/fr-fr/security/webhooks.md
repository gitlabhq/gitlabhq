---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Filtrage des requêtes sortantes
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour se protéger contre le risque de perte et d'exposition des données, les administrateurs GitLab peuvent désormais utiliser des contrôles de filtrage des requêtes sortantes afin de restreindre certaines requêtes sortantes effectuées par l'instance GitLab.

## Sécuriser les webhooks et les intégrations {#secure-webhooks-and-integrations}

Les utilisateurs disposant du rôle Maintainer ou Owner peuvent configurer des [webhooks](../user/project/integrations/webhooks.md) déclenchés lorsque des modifications spécifiques surviennent dans un projet ou un groupe. Lorsqu'il est déclenché, une requête HTTP `POST` est envoyée à une URL. Un webhook est généralement configuré pour envoyer des données à un service web externe spécifique, qui traite les données de manière appropriée.

Cependant, un webhook peut être configuré avec une URL pointant vers un service web interne plutôt qu'un service web externe. Lorsque le webhook est déclenché, des services web non-GitLab s'exécutant sur votre serveur GitLab ou dans son réseau local pourraient être exploités.

Les requêtes de webhook sont effectuées par le serveur GitLab lui-même et utilisent un token secret optionnel unique par hook pour l'autorisation, au lieu de :

- Un token utilisateur.
- Un token spécifique au dépôt.

Par conséquent, ces requêtes peuvent avoir un accès plus large que prévu, notamment l'accès à tout ce qui s'exécute sur le serveur hébergeant le webhook, y compris :

- Le serveur GitLab.
- L'API elle-même.
- Pour certains webhooks, un accès réseau à d'autres serveurs dans le réseau local du serveur de webhook, même si ces services sont autrement protégés et inaccessibles depuis l'extérieur.

Les webhooks peuvent être utilisés pour déclencher des commandes destructives à l'aide de services web qui ne nécessitent pas d'authentification. Ces webhooks peuvent amener le serveur GitLab à effectuer des requêtes HTTP `POST` vers des points de terminaison qui suppriment des ressources.

### Autoriser les requêtes vers le réseau local depuis les webhooks et les intégrations {#allow-requests-to-the-local-network-from-webhooks-and-integrations}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour prévenir l'exploitation de services web internes non sécurisés, toutes les requêtes de webhook et d'intégration vers les adresses réseau local suivantes ne sont pas autorisées :

- L'adresse du serveur de l'instance GitLab actuelle.
- Les adresses de réseau privé, notamment `127.0.0.1`, `::1`, `0.0.0.0`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, et les adresses IPv6 site-local (`ffc0::/10`).

Pour autoriser l'accès à ces adresses :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Requêtes sortantes**.
1. Cochez la case **Autoriser les requêtes vers le réseau local des crochets Web et des intégrations**.

### Empêcher les requêtes vers le réseau local depuis les crochets système {#prevent-requests-to-the-local-network-from-system-hooks}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Les [crochets système](../administration/system_hooks.md) peuvent effectuer des requêtes vers le réseau local par défaut. Pour empêcher les requêtes des crochets système vers le réseau local :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Requêtes sortantes**.
1. Décochez la case **Autoriser les requêtes vers le réseau local depuis les crochets système**.

### Imposer la protection contre les attaques par DNS rebinding {#enforce-dns-rebinding-attack-protection}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Le [DNS rebinding](https://en.wikipedia.org/wiki/DNS_rebinding) est une technique permettant de faire résoudre un nom de domaine malveillant vers une ressource de réseau interne afin de contourner les restrictions d'accès au réseau local. GitLab dispose d'une protection contre cette attaque activée par défaut. Pour désactiver cette protection :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Requêtes sortantes**.
1. Décochez la case **Imposer la protection contre les attaques par DNS-rebinding**.

## Filtrer les requêtes {#filter-requests}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/377371) dans GitLab 15.10.

{{< /history >}}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance GitLab.

Pour filtrer les requêtes en bloquant de nombreuses requêtes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Requêtes sortantes**.
1. Cochez la case **Bloquer toutes les requêtes à l'exception de celles pour les adresses IP, les plages IP et les noms de domaine définis dans la liste des permissions**.

Lorsque cette case est cochée, les requêtes vers les éléments suivants ne sont toujours pas bloquées :

- Les services principaux tels que Git, GitLab Shell, Gitaly, PostgreSQL et Redis.
- Le stockage d'objets.
- Les adresses IP et les domaines figurant dans la [liste des permissions](#allow-outbound-requests-to-certain-ip-addresses-and-domains).

Lorsque ce paramètre est activé, GitLab peut effectuer une résolution DNS sur les URL incluses dans d'autres objets, tels que les liens de release. Si la résolution DNS échoue, la requête échoue. Pour résoudre ce problème, ajoutez le nom d'hôte à la [liste des permissions](#allow-outbound-requests-to-certain-ip-addresses-and-domains), même si GitLab n'a jamais besoin d'établir une connexion sortante vers cet hôte.

Ce paramètre est respecté uniquement par l'application principale GitLab ; d'autres services comme Gitaly peuvent donc toujours effectuer des requêtes qui enfreignent la règle. De plus, [certaines zones de GitLab](https://gitlab.com/groups/gitlab-org/-/epics/8029) ne respectent pas les règles de filtrage des requêtes sortantes.

## Autoriser les requêtes sortantes vers certaines adresses IP et certains domaines {#allow-outbound-requests-to-certain-ip-addresses-and-domains}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour autoriser les requêtes sortantes vers certaines adresses IP et certains domaines :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Requêtes sortantes**.
1. Dans **Adresses IP locales et noms de domaines auxquels les crochets et les intégrations peuvent accéder**, saisissez vos adresses IP et vos domaines.

Les entrées peuvent :

- Être séparées par des points-virgules, des virgules ou des espaces (y compris des sauts de ligne).
- Être dans différents formats tels que des noms d'hôte, des adresses IP, des plages d'adresses IP. IPv6 est pris en charge. Les noms d'hôte contenant des caractères Unicode doivent utiliser l'encodage [Internationalized Domain Names in Applications](https://www.icann.org/en/icann-acronyms-and-terms/internationalized-domain-names-in-applications-en) (IDNA).
- Inclure des ports. Par exemple, `127.0.0.1:8080` autorise uniquement les connexions au port 8080 sur `127.0.0.1`. Si aucun port n'est spécifié, tous les ports de cette adresse IP ou de ce domaine sont autorisés. Une plage d'adresses IP autorise tous les ports sur toutes les adresses IP de cette plage.
- Ne pas dépasser 1 000 entrées de 255 caractères maximum chacune.
- Ne pas contenir de caractères génériques (par exemple, `*.example.com`).

Par exemple :

```plaintext
example.com;gitlab.example.com
127.0.0.1,1:0:0:0:0:0:0:1
127.0.0.0/8 1:0:0:0:0:0:0:0/124
[1:0:0:0:0:0:0:1]:8080
127.0.0.1:8080
example.com:8080
```

## Dépannage {#troubleshooting}

Lors du filtrage des requêtes sortantes, vous pouvez rencontrer les problèmes suivants.

### Les URL configurées sont bloquées {#configured-urls-are-blocked}

Vous pouvez cocher la case **Bloquer toutes les requêtes à l'exception de celles pour les adresses IP, les plages IP et les noms de domaine définis dans la liste des permissions** uniquement si aucune URL configurée ne serait bloquée. Sinon, vous pourriez recevoir un message d'erreur indiquant que l'URL est bloquée.

Si vous ne pouvez pas activer ce paramètre, effectuez l'une des opérations suivantes :

- Désactivez le paramètre d'URL.
- Configurez une autre URL ou laissez le paramètre d'URL vide.
- Ajoutez l'URL configurée à la [liste des permissions](#allow-requests-to-the-local-network-from-webhooks-and-integrations).

### L'URL de publication des runners publics est bloquée {#public-runner-releases-url-is-blocked}

La plupart des instances GitLab ont leur `public_runner_releases_url` défini sur `https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab-runner/releases`, ce qui peut vous empêcher de [filtrer les requêtes](#filter-requests).

Pour résoudre ce problème, [configurez GitLab pour qu'il ne récupère plus les données de version des releases de runner depuis GitLab.com](../administration/settings/continuous_integration.md#control-runner-version-management).

### La gestion des abonnements GitLab est bloquée {#gitlab-subscription-management-is-blocked}

Lorsque vous [filtrez les requêtes](#filter-requests), la [gestion des abonnements GitLab](../subscriptions/manage_subscription.md) est bloquée.

Pour contourner ce problème, ajoutez `customers.gitlab.com:443` à la [liste des permissions](#allow-outbound-requests-to-certain-ip-addresses-and-domains).

### La documentation GitLab est bloquée {#gitlab-documentation-is-blocked}

Lorsque vous [filtrez les requêtes](#filter-requests), vous pourriez obtenir une erreur indiquant `Help page documentation base url is blocked: Requests to hosts and IP addresses not on the Allow List are denied`. Pour contourner cette erreur :

1. Annulez la modification afin que le message d'erreur `Help page documentation base url is blocked` n'apparaisse plus.
1. Ajoutez `docs.gitlab.com` ou [l'URL de redirection des pages d'aide de la documentation](../administration/settings/help_page.md#redirect-help-pages) à la [liste des permissions](#allow-outbound-requests-to-certain-ip-addresses-and-domains).
1. Sélectionnez **Enregistrer les modifications**.

### La fonctionnalité GitLab Duo est bloquée {#gitlab-duo-functionality-is-blocked}

Lorsque vous [filtrez les requêtes](#filter-requests), vous pourriez voir des erreurs `401` en essayant d'utiliser les [fonctionnalités GitLab Duo](../user/gitlab_duo/_index.md).

Cette erreur peut survenir lorsque les requêtes sortantes vers le serveur cloud GitLab ne sont pas autorisées. Pour contourner cette erreur :

1. Ajoutez `https://cloud.gitlab.com:443` à la [liste des permissions](#allow-outbound-requests-to-certain-ip-addresses-and-domains).
1. Sélectionnez **Enregistrer les modifications**.
1. Une fois que GitLab a accès au [serveur cloud](../user/gitlab_duo/_index.md), [synchronisez manuellement votre licence](../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)
