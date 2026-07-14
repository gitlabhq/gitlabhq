---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Proxying Geo pour les sites secondaires
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Le proxying HTTP pour les sites secondaires avec des URL distinctes a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/346112) dans GitLab 14.5 [avec un flag](../../feature_flags/_index.md) nommé `geo_secondary_proxy_separate_urls`. Désactivé par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/346112) dans GitLab 15.1.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Le feature flag `geo_secondary_proxy_separate_urls` est prévu d'être déprécié et supprimé dans une prochaine release. La prise en charge des sites Geo secondaires en lecture seule est proposée dans l'[issue 366810](https://gitlab.com/gitlab-org/gitlab/-/issues/366810).

Les sites secondaires se comportent comme des instances GitLab complètes en lecture-écriture. Ils redirigent de manière transparente toutes les opérations vers le site principal, avec [quelques exceptions notables](#features-accelerated-by-secondary-geo-sites).

Ce comportement permet des cas d'utilisation tels que :

- Placer tous les sites Geo derrière une seule URL, afin d'offrir une expérience cohérente, fluide et complète quel que soit le site sur lequel l'utilisateur atterrit. Les utilisateurs n'ont pas besoin de jongler avec plusieurs URL GitLab.
- Équilibrage de charge du trafic géographiquement sans se soucier de l'accès en écriture.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [Geo proxying for secondary sites](https://www.youtube.com/watch?v=TALLy7__Na8).
<!-- Video published on 2022-01-26 -->

Pour les problèmes connus, consultez [les éléments liés au proxying dans la documentation Geo](../_index.md#known-issues).

## Configurer une URL unifiée pour les sites Geo {#set-up-a-unified-url-for-geo-sites}

Les sites secondaires peuvent servir de manière transparente le trafic en lecture-écriture. Par conséquent, vous pouvez utiliser une seule URL externe afin que les requêtes puissent atteindre le site Geo principal ou l'un des sites Geo secondaires. Cela offre une expérience cohérente, fluide et complète quel que soit le site sur lequel l'utilisateur atterrit. Les utilisateurs n'ont pas besoin de jongler avec plusieurs URL ni même d'être conscients de l'existence de plusieurs sites.

Vous pouvez router le trafic vers les sites Geo avec :

- DNS géolocalisation. Pour router le trafic vers le site Geo le plus proche, qu'il soit principal ou secondaire. Pour un exemple, suivez [Configurer un DNS géolocalisé](#configure-location-aware-dns).
- DNS round-robin.
- Un équilibreur de charge. Il doit utiliser des sessions persistantes (sticky sessions) pour éviter les échecs d'authentification et les erreurs de requêtes cross-site. Le routage DNS est intrinsèquement persistant (sticky), il n'est donc pas soumis à cette contrainte.

### Configurer un DNS géolocalisé {#configure-location-aware-dns}

Suivez cet exemple pour router le trafic vers le site Geo le plus proche, qu'il soit principal ou secondaire.

#### Prérequis {#prerequisites}

Cet exemple crée un sous-domaine `gitlab.example.com` qui dirige automatiquement les requêtes :

- Depuis l'Europe vers un site **secondaire**.
- Depuis tous les autres emplacements vers le site **principal**.

Pour cet exemple, vous avez besoin de :

- Un site Geo **principal** et un site **secondaire** fonctionnels, consultez les [instructions de configuration Geo](../setup/_index.md).
- Une zone DNS gérant votre domaine. Bien que les instructions suivantes utilisent [AWS Route53](https://aws.amazon.com/route53/) et [GCP cloud DNS](https://cloud.google.com/dns/), d'autres services tels que [Cloudflare](https://www.cloudflare.com/) peuvent également être utilisés.

#### AWS Route53 {#aws-route53}

Dans cet exemple, vous utilisez une Zone Hébergée Route53 gérant votre domaine pour la configuration Route53.

Dans une Zone Hébergée Route53, les politiques de trafic peuvent être utilisées pour configurer différentes configurations de routage. Pour créer une politique de trafic :

1. Accédez au [tableau de bord Route53](https://console.aws.amazon.com/route53/home) et sélectionnez **Traffic policies**.
1. Sélectionnez **Create traffic policy**.
1. Renseignez le champ **Policy Name** avec `Single Git Host` et sélectionnez **Suivant**.
1. Laissez **DNS type** sur `A: IP Address in IPv4 format`.
1. Sélectionnez **Connect to**, puis sélectionnez **Geolocation rule**.
1. Pour le premier **Emplacement** :
   1. Laissez-le sur `Default`.
   1. Sélectionnez **Connect to**, puis sélectionnez **New endpoint**.
   1. Choisissez **Type** `value` et renseignez-le avec `<your **primary** IP address>`.
1. Pour le second **Emplacement** :
   1. Choisissez `Europe`.
   1. Sélectionnez **Connect to**, puis sélectionnez **New endpoint**.
   1. Choisissez **Type** `value` et renseignez-le avec `<your **secondary** IP address>`.

   ![Éditeur de politique de trafic Route53 affichant une règle de géolocalisation avec deux emplacements - Default et Europe - chacun connecté à des points de terminaison avec des adresses IP différentes](img/single_url_add_traffic_policy_endpoints_v14_5.png)

1. Sélectionnez **Create traffic policy**.
1. Renseignez **Policy record DNS name** avec `gitlab`.

   ![Formulaire Web pour créer des enregistrements de politique DNS avec des champs pour la politique de trafic, la version, la zone hébergée et les paramètres de configuration DNS](img/single_url_create_policy_records_with_traffic_policy_v14_5.png)

1. Sélectionnez **Create policy records**.

Vous avez correctement configuré un hôte unique, tel que `gitlab.example.com`, qui distribue le trafic vers vos sites Geo par géolocalisation.

#### GCP {#gcp}

Dans cet exemple, vous créez une zone GCP Cloud DNS gérant votre domaine.

Lors de la création d'ensembles d'enregistrements basés sur la géolocalisation, GCP applique la correspondance la plus proche pour la région source lorsque la source du trafic ne correspond exactement à aucun élément de politique. Pour créer un ensemble d'enregistrements basé sur la géolocalisation :

1. Sélectionnez **Network Services** > **Cloud DNS**.
1. Sélectionnez la Zone configurée pour votre domaine.
1. Sélectionnez **Add Record Set**.
1. Saisissez le nom DNS pour votre URL publique géolocalisée, par exemple, `gitlab.example.com`.
1. Sélectionnez la **Routing Policy** :  **Geo-Based**.
1. Sélectionnez **Add Managed RRData**.
   1. Sélectionnez **Source Region** : **us-central1**.
   1. Saisissez votre `<**primary** IP address>`.
   1. Sélectionnez **Terminé**.
1. Sélectionnez **Add Managed RRData**.
   1. Sélectionnez **Source Region** : **europe-west1**.
   1. Saisissez votre `<**secondary** IP address>`.
   1. Sélectionnez **Terminé**.
1. Sélectionnez **Créer**.

Vous avez correctement configuré un hôte unique, tel que `gitlab.example.com`, qui distribue le trafic vers vos sites Geo en utilisant une URL géolocalisée.

### Configurer chaque site pour utiliser la même URL externe {#configure-each-site-to-use-the-same-external-url}

Une fois que vous avez configuré le routage depuis une seule URL vers tous vos sites Geo, suivez les étapes ci-dessous si vos sites utilisent des URL différentes :

1. Sur chaque site GitLab, connectez-vous en SSH à **each** nœud exécutant Rails (Puma, Sidekiq, Log-Cursor) et définissez `external_url` sur l'URL unique :

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

1. Reconfigurez les nœuds mis à jour pour que la modification prenne effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Pour correspondre à la nouvelle URL externe définie sur les sites Geo secondaires, la base de données principale doit refléter ce changement.

   Dans la page d'administration Geo du site **principal**, modifiez chaque site secondaire Geo qui utilise le proxying secondaire et définissez le champ `URL` sur l'URL unique. Assurez-vous que le site principal utilise également cette URL.

   Pour permettre aux sites de communiquer entre eux, [assurez-vous que le champ `Internal URL` est unique pour chaque site](../../geo_sites.md#set-up-the-internal-urls).

Dans Kubernetes, vous pouvez [utiliser le même domaine sous `global.hosts.domain` que pour le site principal](https://docs.gitlab.com/charts/advanced/geo/).

## Configurer une URL distincte pour un site Geo secondaire {#set-up-a-separate-url-for-a-secondary-geo-site}

Vous pouvez utiliser des URL externes différentes par site. Vous pouvez utiliser ceci pour proposer un site spécifique à un ensemble spécifique d'utilisateurs. Vous pouvez également donner aux utilisateurs le contrôle du site qu'ils utilisent, bien qu'ils doivent comprendre les implications de leur choix.

> [!note]
> GitLab ne prend pas en charge plusieurs URL externes, consultez l'[issue 21319](https://gitlab.com/gitlab-org/gitlab/-/issues/21319). Un problème inhérent est qu'il existe de nombreux cas où un site doit produire une URL absolue en dehors du contexte d'une requête HTTP, par exemple lors de l'envoi d'e-mails qui n'ont pas été déclenchés par une requête.

### Configurer un site Geo secondaire avec une URL externe différente de celle du site principal {#configure-a-secondary-geo-site-to-a-different-external-url-than-the-primary-site}

Si votre site secondaire utilise la même URL externe que le site principal, mais que vous souhaitez la changer pour utiliser une URL différente :

1. Sur le site secondaire, connectez-vous en SSH à **each** nœud exécutant Rails (Puma, Sidekiq, Log-Cursor) et définissez `external_url` sur l'URL souhaitée pour le site secondaire :

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

1. Reconfigurez les nœuds mis à jour pour que la modification prenne effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Pour correspondre à la nouvelle URL externe définie sur le site Geo secondaire, la base de données principale doit refléter ce changement.

   Dans la page d'administration Geo du site **principal**, modifiez le site secondaire cible et définissez le champ `URL` sur l'URL souhaitée.

   Pour permettre aux sites de communiquer entre eux, [assurez-vous que le champ `Internal URL` est unique pour chaque site](../../geo_sites.md#set-up-the-internal-urls). Si l'URL souhaitée est unique à ce site, vous pouvez effacer le champ `Internal URL`. Lors de l'enregistrement, la valeur par défaut est l'URL externe.

## Comportement des sites secondaires lorsque le site Geo principal est indisponible {#behavior-of-secondary-sites-when-the-primary-geo-site-is-down}

Étant donné que le trafic Web est proxyfié vers le site principal, le comportement des sites secondaires diffère lorsque le site principal est inaccessible :

- Le trafic UI et API retourne les mêmes erreurs que le site principal (ou échoue si le site principal n'est pas du tout accessible) car il est proxyfié.
- Pour les dépôts qui sont entièrement à jour sur le site secondaire spécifique consulté, les opérations de lecture Git fonctionnent toujours comme prévu, y compris l'authentification via HTTP(s) ou SSH. Cependant, les lectures Git effectuées par les GitLab Runners échoueront.
- Les opérations Git pour les dépôts qui ne sont pas répliqués sur le site secondaire retournent les mêmes erreurs que le site principal car elles sont proxyfiées.
- Toutes les opérations d'écriture Git retournent les mêmes erreurs que le site principal car elles sont proxyfiées.

## Fonctionnalités accélérées par les sites Geo secondaires {#features-accelerated-by-secondary-geo-sites}

La plupart du trafic HTTP envoyé à un site Geo secondaire est proxyfié vers le site Geo principal. Avec cette architecture, les sites Geo secondaires peuvent prendre en charge les requêtes d'écriture et éviter les problèmes de lecture après écriture. Certaines requêtes de **read** sont traitées localement par les sites secondaires pour améliorer la latence et la bande passante à proximité.

Le tableau suivant détaille les composants testés via le proxy Workhorse du site Geo secondaire. Il ne couvre pas tous les types de données.

Dans ce contexte, les lectures accélérées désignent les requêtes de lecture servies depuis le site secondaire, à condition que les données soient à jour pour le composant sur le site secondaire. Si les données sur le site secondaire sont jugées obsolètes, la requête est transmise au site principal. Les requêtes de lecture pour les composants non listés dans le tableau ci-dessous sont toujours automatiquement transmises au site principal.

| Fonctionnalité / composant                                 | Lectures accélérées ?                   | Notes |
|:----------------------------------------------------|:-------------------------------------|-------|
| Ressources statiques Rails (JavaScript, CSS, polices, images) | {{< icon name="check-circle" >}} Oui | Les ressources sous `/assets/` sont servies directement depuis le système de fichiers local du site secondaire par Workhorse, sans être proxyfiées vers le site principal. Cela s'applique à tous les sites secondaires, qu'une URL unifiée ou des URL distinctes soient utilisées. Après la requête initiale du navigateur, ces ressources sont également généralement mises en cache par le navigateur. |
| Projet, wiki, dépôt de conception (via l'interface Web) | {{< icon name="dotted-circle" >}} Non |       |
| Projet, dépôt wiki (via Git)                | {{< icon name="check-circle" >}} Oui | Les lectures Git sont servies depuis le site secondaire local tandis que les push sont proxifiés vers le site principal. Si un dépôt n'existe pas localement sur le site Geo secondaire, par exemple en raison d'une exclusion par la synchronisation sélective, la requête est proxyfiée vers le site principal. |
| Projet, Snippet personnel (via l'interface Web)        | {{< icon name="dotted-circle" >}} Non |       |
| Projet, Snippet personnel (via Git)               | {{< icon name="check-circle" >}} Oui | Les lectures Git sont servies depuis le site secondaire local tandis que les push sont proxifiés vers le site principal. Si un dépôt n'existe pas localement sur le site Geo secondaire, par exemple en raison d'une exclusion par la synchronisation sélective, la requête est proxyfiée vers le site principal. |
| Dépôt wiki de groupe (via l'interface Web)            | {{< icon name="dotted-circle" >}} Non |       |
| Dépôt wiki de groupe (via Git)                   | {{< icon name="check-circle" >}} Oui | Les lectures Git sont servies depuis le site secondaire local tandis que les push sont proxifiés vers le site principal. Si un dépôt n'existe pas localement sur le site Geo secondaire, par exemple en raison d'une exclusion par la synchronisation sélective, la requête est proxyfiée vers le site principal. |
| Téléversements utilisateur                                        | {{< icon name="dotted-circle" >}} Non |       |
| Objets LFS (via l'interface Web)                      | {{< icon name="dotted-circle" >}} Non |       |
| Objets LFS (via Git)                             | {{< icon name="check-circle" >}} Oui |       |
| Pages                                               | {{< icon name="dotted-circle" >}} Non | Les Pages peuvent utiliser la même URL (sans contrôle d'accès), mais doivent être configurées séparément et ne sont pas proxyfiées. |
| Recherche avancée (via l'interface Web)                  | {{< icon name="dotted-circle" >}} Non |       |
| Registre de conteneurs                                  | {{< icon name="dotted-circle" >}} Non | Le registre de conteneurs n'est recommandé que pour les scénarios de reprise après sinistre. Si le registre de conteneurs du site secondaire n'est pas à jour, la requête de lecture est servie avec des données obsolètes car la requête n'est pas transmise au site principal. L'accélération du registre de conteneurs est prévue, votez ou commentez dans l'[issue](https://gitlab.com/gitlab-org/gitlab/-/issues/365864) pour indiquer votre intérêt ou demandez à votre représentant GitLab de le faire en votre nom. |
| Proxy de dépendances                                    | {{< icon name="dotted-circle" >}} Non | Les requêtes de lecture vers le proxy de dépendances d'un site Geo secondaire sont toujours proxyfiées vers le site principal. |
| Toutes les autres données                                      | {{< icon name="dotted-circle" >}} Non | Les requêtes de lecture pour les composants non listés dans ce tableau sont toujours automatiquement transmises au site principal. |

Pour demander l'accélération d'une fonctionnalité, vérifiez si une issue existe déjà dans l'[epic 8239](https://gitlab.com/groups/gitlab-org/-/epics/8239) et votez ou commentez pour indiquer votre intérêt ou demandez à votre représentant GitLab de le faire en votre nom. Si aucune issue applicable n'existe, ouvrez-en une et mentionnez-la dans l'epic.

## Désactiver le proxying HTTP du site secondaire {#disable-secondary-site-http-proxying}

Le proxying HTTP du site secondaire est activé par défaut sur un site secondaire lorsqu'il utilise une URL unifiée, c'est-à-dire lorsqu'il est configuré avec le même `external_url` que le site principal. La désactivation du proxying dans ce cas n'est généralement pas utile en raison d'un comportement complètement différent servi à la même URL, selon le routage. Lorsque le proxying HTTP est désactivé sur un site Geo secondaire, le site fonctionne en mode lecture seule, avec plusieurs limitations importantes dont vous devez être conscient.

### Que se passe-t-il si vous désactivez le proxying secondaire {#what-happens-if-you-disable-secondary-proxying}

La désactivation du feature flag de proxying a les effets généraux suivants.

#### Requêtes HTTP et Git {#http-and-git-requests}

- Le site secondaire ne proxyifie pas les requêtes HTTP vers le site principal. Au lieu de cela, il tente de les servir lui-même, ou échoue.
- Les requêtes Git réussissent généralement. Les push Git sont redirigés ou proxifiés vers le site principal.
- En dehors des requêtes Git, toute requête HTTP susceptible d'écrire des données échoue. Les requêtes de lecture réussissent généralement.

| Fonctionnalité / composant                                 | Réussit                                 | Notes |
|:----------------------------------------------------|:----------------------------------------|-------|
| Projet, wiki, dépôt de conception (via l'interface Web) | {{< icon name="dotted-circle" >}} Peut-être | Les lectures sont servies depuis les données stockées localement. Les écritures provoquent une erreur. |
| Projet, dépôt wiki (via Git)                | {{< icon name="check-circle" >}} Oui    | Les lectures Git sont servies depuis les données stockées localement, tandis que les push sont proxifiés vers le site principal. Si un dépôt n'existe pas localement sur le site Geo secondaire, par exemple en raison d'une exclusion par la synchronisation sélective, cela provoque une erreur « introuvable ». |
| Projet, Snippet personnel (via l'interface Web)        | {{< icon name="dotted-circle" >}} Peut-être | Les lectures sont servies depuis les données stockées localement. Les écritures provoquent une erreur. |
| Projet, Snippet personnel (via Git)               | {{< icon name="check-circle" >}} Oui    | Les lectures Git sont servies depuis les données stockées localement, tandis que les push sont proxifiés vers le site principal. Si un dépôt n'existe pas localement sur le site Geo secondaire, par exemple en raison d'une exclusion par la synchronisation sélective, cela provoque une erreur « introuvable ». |
| Dépôt wiki de groupe (via l'interface Web)            | {{< icon name="dotted-circle" >}} Peut-être | Les lectures sont servies depuis les données stockées localement. Les écritures provoquent une erreur. |
| Dépôt wiki de groupe (via Git)                   | {{< icon name="check-circle" >}} Oui    | Les lectures Git sont servies depuis les données stockées localement, tandis que les push sont proxifiés vers le site principal. Si un dépôt n'existe pas localement sur le site Geo secondaire, par exemple en raison d'une exclusion par la synchronisation sélective, cela provoque une erreur « introuvable ». |
| Téléversements utilisateur                                        | {{< icon name="dotted-circle" >}} Peut-être | Les fichiers téléversés sont servis depuis les données stockées localement. Toute tentative de téléversement d'un fichier sur un site secondaire provoque une erreur. |
| Objets LFS (via l'interface Web)                      | {{< icon name="dotted-circle" >}} Peut-être | Les lectures sont servies depuis les données stockées localement. Les écritures provoquent une erreur. |
| Objets LFS (via Git)                             | {{< icon name="check-circle" >}} Oui    | Les objets LFS sont servis depuis les données stockées localement, tandis que les push sont proxifiés vers le site principal. Si un objet LFS n'existe pas localement sur le site Geo secondaire, par exemple en raison d'une exclusion par la synchronisation sélective, cela provoque une erreur « introuvable ». |
| Pages                                               | {{< icon name="dotted-circle" >}} Peut-être | Les Pages peuvent utiliser la même URL (sans contrôle d'accès), mais doivent être configurées séparément et ne sont pas proxyfiées. |
| Recherche avancée (via l'interface Web)                  | {{< icon name="dotted-circle" >}} Non    |       |
| Registre de conteneurs                                  | {{< icon name="dotted-circle" >}} Non    | Le registre de conteneurs n'est recommandé que pour les scénarios de reprise après sinistre. Si le registre de conteneurs du site secondaire n'est pas à jour, la requête de lecture est servie avec des données obsolètes car la requête n'est pas transmise au site principal. L'accélération du registre de conteneurs est prévue, votez ou commentez dans l'[issue](https://gitlab.com/gitlab-org/gitlab/-/issues/365864) pour indiquer votre intérêt ou demandez à votre représentant GitLab de le faire en votre nom. |
| Proxy de dépendances                                    | {{< icon name="dotted-circle" >}} Non    |       |
| Toutes les autres données                                      | {{< icon name="dotted-circle" >}} Peut-être | Les lectures sont servies depuis les données stockées localement. Les écritures provoquent une erreur. |

Vous devriez utiliser le feature flag plutôt que la variable d'environnement `GEO_SECONDARY_PROXY`.

Le proxying HTTP est activé par défaut dans GitLab 15.1 sur un site secondaire, même sans URL unifiée.

#### Acceptation des conditions d'utilisation {#terms-of-service-acceptance}

Lorsque le proxying est désactivé, les utilisateurs qui accèdent uniquement au site secondaire ne peuvent pas accepter correctement les conditions d'utilisation ou d'autres accords juridiques. Cela crée les problèmes suivants :

- **No record of acceptance** :  Si un employé se connecte uniquement au site secondaire, son acceptation des conditions générales n'est pas enregistrée dans la base de données principale, car les opérations d'écriture (y compris l'acceptation des conditions) ne sont pas proxyfiées lorsque le proxying secondaire est désactivé, même s'ils peuvent voir le message relatif aux conditions.
- **Legal compliance concerns** :  Les organisations peuvent manquer d'une couverture juridique adéquate si les employés utilisent les services GitLab via un modèle d'accès exclusivement secondaire, car il n'existe aucune preuve vérifiable de leur accord aux conditions générales.

Pour contourner ce problème, vous devez accéder au site principal au moins une fois pour accepter correctement les conditions générales. Une fois acceptées sur le site principal, ces informations sont répliquées vers les sites secondaires via la synchronisation Geo normale.

> [!note]
> Cette limitation affecte les organisations qui exigent une acceptation documentée des conditions générales à des fins de conformité ou juridiques. Assurez-vous que les utilisateurs ont accès au site principal pour l'acceptation initiale des conditions.

### Désactiver le proxy sur tous les sites secondaires {#disable-proxy-on-all-secondary-sites}

Si vous devez désactiver le proxying sur tous les sites secondaires, le plus simple est de désactiver le feature flag :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Connectez-vous en SSH à un nœud exécutant Puma ou Sidekiq sur votre site Geo principal et exécutez :

   ```shell
   sudo gitlab-rails runner "Feature.disable(:geo_secondary_proxy_separate_urls)"
   ```

1. Redémarrez Puma sur tous les nœuds qui l'exécutent sur votre site Geo secondaire :

   ```shell
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Sur votre site Geo principal, exécutez cette commande dans le pod Toolbox :

   ```shell
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner "Feature.disable(:geo_secondary_proxy_separate_urls)"
   ```

1. Redémarrez les pods Webservice sur votre site Geo secondaire :

   ```shell
   kubectl rollout restart deployment -l app=webservice
   ```

{{< /tab >}}

{{< /tabs >}}

Pour annuler les modifications afin que le proxying du site secondaire soit à nouveau activé :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Connectez-vous en SSH à un nœud exécutant Puma ou Sidekiq sur votre site Geo principal et exécutez :

   ```shell
   sudo gitlab-rails runner "Feature.enable(:geo_secondary_proxy_separate_urls)"
   ```

1. Redémarrez Puma sur tous les nœuds qui l'exécutent sur votre site Geo secondaire :

   ```shell
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Sur votre site Geo principal, exécutez cette commande dans le pod Toolbox :

   ```shell
   kubectl exec -it <toolbox-pod-name> -- gitlab-rails runner "Feature.enable(:geo_secondary_proxy_separate_urls)"
   ```

1. Redémarrez les pods Webservice sur votre site Geo secondaire :

   ```shell
   kubectl rollout restart deployment -l app=webservice
   ```

{{< /tab >}}

{{< /tabs >}}

### Désactiver le proxying HTTP du site secondaire par site {#disable-secondary-site-http-proxying-per-site}

S'il existe plusieurs sites secondaires, vous pouvez désactiver le proxying HTTP sur chaque site secondaire séparément, en suivant ces étapes :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Connectez-vous en SSH à chaque nœud applicatif (servant directement le trafic utilisateur) sur votre site Geo secondaire et ajoutez la variable d'environnement suivante :

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_workhorse['env'] = {
     "GEO_SECONDARY_PROXY" => "0"
   }
   ```

1. Reconfigurez les nœuds mis à jour pour que la modification prenne effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Vous pouvez utiliser `--set gitlab.webservice.extraEnv.GEO_SECONDARY_PROXY="0"`, ou spécifier ce qui suit dans votre fichier de valeurs :

```yaml
gitlab:
  webservice:
    extraEnv:
      GEO_SECONDARY_PROXY: "0"
```

{{< /tab >}}

{{< /tabs >}}

### Désactiver le proxying Git du site secondaire {#disable-secondary-site-git-proxying}

Il n'est pas possible de désactiver la transmission de :

- Push Git via SSH
- Pull Git via SSH lorsque le dépôt Git est obsolète sur le site secondaire
- Push Git via HTTP
- Pull Git via HTTP lorsque le dépôt Git est obsolète sur le site secondaire
