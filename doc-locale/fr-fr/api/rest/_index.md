---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'API REST GitLab pour interagir avec GitLab de manière programmatique. Inclut les requêtes, les limites de débit, la pagination, l'encodage, la gestion des versions et la gestion des réponses."
title: API REST
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Automatisez vos workflows et créez des intégrations avec l'API REST GitLab :

- Créez des outils personnalisés pour gérer vos ressources GitLab à grande échelle sans intervention manuelle.
- Améliorez la collaboration en intégrant les données GitLab directement dans vos applications.
- Gérez les processus CI/CD sur plusieurs projets avec précision.
- Contrôlez les accès utilisateurs de manière programmatique pour maintenir des permissions cohérentes au sein de votre organisation.

L'API REST utilise des méthodes HTTP standard et des formats de données JSON pour assurer la compatibilité avec vos outils et systèmes existants.

## Effectuer une requête d'API REST {#make-a-rest-api-request}

Pour effectuer une requête d'API REST :

- Soumettez une requête à un point de terminaison d'API à l'aide d'un client d'API REST.
- L'instance GitLab répond à la requête. Elle retourne un code de statut et, le cas échéant, les données demandées. Le code de statut indique le résultat de la requête et est utile lors du [dépannage](troubleshooting.md).

Une requête d'API REST doit commencer par le point de terminaison racine et le chemin.

- Le point de terminaison racine est le nom d'hôte GitLab.
- Le chemin doit commencer par `/api/v4` (`v4` représente la version de l'API).

Dans l'exemple suivant, la requête d'API récupère la liste de tous les projets sur l'hôte GitLab `gitlab.example.com` :

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects"
```

L'accès à certains points de terminaison nécessite une authentification. Pour plus d'informations, consultez [Authentification](authentication.md).

## Limites de débit {#rate-limits}

Les requêtes d'API REST sont soumises aux paramètres de limite de débit. Ces paramètres réduisent le risque de surcharge d'une instance GitLab.

- Pour plus de détails, consultez [Limites de débit](../../security/rate_limits.md).
- Pour plus de détails sur les paramètres de limite de débit utilisés par GitLab.com, consultez [Limites de débit spécifiques à GitLab.com](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom).

## Format de réponse {#response-format}

Les réponses de l'API REST sont retournées au format JSON. Certains points de terminaison d'API prennent également en charge le format texte brut. Pour confirmer quel type de contenu un point de terminaison prend en charge, consultez les [ressources de l'API REST](../api_resources.md).

## Exigences des requêtes {#request-requirements}

Certaines requêtes d'API REST ont des exigences spécifiques, notamment le format de données et l'encodage utilisés.

### Charge utile de la requête {#request-payload}

Les requêtes d'API peuvent utiliser des paramètres envoyés sous forme de [chaînes de requête](https://en.wikipedia.org/wiki/Query_string) ou de [corps de charge utile](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-p3-payload-14#section-3.2). Les requêtes GET envoient généralement une chaîne de requête, tandis que les requêtes PUT ou POST envoient généralement le corps de la charge utile :

- Chaîne de requête :

  ```shell
  curl --request POST \
    --url "https://gitlab.example.com/api/v4/projects?name=<example-name>&description=<example-description>"
  ```

- Charge utile de la requête (JSON) :

  ```shell
  curl --request POST \
    --header "Content-Type: application/json" \
    --data '{"name":"<example-name>", "description":"<example-description>"}' "https://gitlab.example.com/api/v4/projects"
  ```

Les chaînes de requête encodées en URL ont une limitation de longueur. Les requêtes trop volumineuses génèrent un message d'erreur `414 Request-URI Too Large`. Ce problème peut être résolu en utilisant un corps de charge utile à la place.

### Paramètres de chemin {#path-parameters}

Si un point de terminaison comporte des paramètres de chemin, la documentation les affiche précédés d'un signe deux-points.

Par exemple :

```plaintext
DELETE /projects/:id/share/:group_id
```

Le paramètre de chemin `:id` doit être remplacé par l'ID du projet, et `:group_id` doit être remplacé par l'ID du groupe. Les deux-points `:` ne doivent pas être inclus.

La requête cURL résultante pour un projet avec l'ID `5` et un ID de groupe `17` est alors :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/share/17"
```

Les paramètres de chemin qui doivent être encodés en URL doivent être respectés. Dans le cas contraire, ils ne correspondent pas à un point de terminaison d'API et la réponse est une erreur 404. Si quelque chose se trouve devant l'API (par exemple, Apache), assurez-vous qu'il ne décode pas les paramètres de chemin encodés en URL.

### `id` vs `iid` {#id-vs-iid}

Certaines ressources d'API ont deux champs portant des noms similaires. Par exemple, [les tickets](../issues.md) , [les merge requests](../merge_requests.md) et [les jalons de projet](../milestones.md). Les champs sont :

- `id` :  ID unique pour tous les projets.
- `iid` :  ID interne supplémentaire (affiché dans l'interface web) unique dans la portée d'un seul projet.

Si une ressource possède à la fois le champ `iid` et le champ `id`, le champ `iid` est généralement utilisé à la place de `id` pour récupérer la ressource.

Par exemple, supposons qu'un projet avec `id: 42` ait un ticket avec `id: 46` et `iid: 5`. Dans ce cas :

- Une requête d'API valide pour récupérer le ticket est `GET /projects/42/issues/5`.
- Une requête d'API invalide pour récupérer le ticket est `GET /projects/42/issues/46`.

Toutes les ressources avec le champ `iid` ne sont pas récupérées par `iid`. Pour savoir quel champ utiliser, consultez la documentation de la ressource spécifique.

### Encodage {#encoding}

Lors d'une requête d'API REST, certains contenus doivent être encodés pour tenir compte des caractères spéciaux et des structures de données.

#### Chemins avec espace de nommage {#namespaced-paths}

Si vous utilisez des requêtes d'API avec un espace de nommage, assurez-vous que `NAMESPACE/PROJECT_PATH` est encodé en URL.

Par exemple, `/` est représenté par `%2F` :

```plaintext
GET /api/v4/projects/diaspora%2Fdiaspora
```

Le chemin d'un projet n'est pas nécessairement identique à son nom. Le chemin d'un projet se trouve dans l'URL du projet ou dans les paramètres du projet, sous **Général** > **Paramètres avancés** > **Changer le chemin**.

#### Chemin de fichier, branches et nom de balise {#file-path-branches-and-tags-name}

Si un chemin de fichier, une branche ou une balise contient un `/`, assurez-vous qu'il est encodé en URL.

Par exemple, `/` est représenté par `%2F` :

```plaintext
GET /api/v4/projects/1/repository/files/src%2FREADME.md?ref=master
GET /api/v4/projects/1/branches/my%2Fbranch/commits
GET /api/v4/projects/1/repository/tags/my%2Ftag
```

#### Types tableau et hash {#array-and-hash-types}

Vous pouvez interroger l'API avec des paramètres de types `array` et `hash` :

##### `array` {#array}

`import_sources` est un paramètre de type `array` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  -d "import_sources[]=github" \
  -d "import_sources[]=bitbucket" \
  --url "https://gitlab.example.com/api/v4/some_endpoint"
```

##### `hash` {#hash}

`override_params` est un paramètre de type `hash` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "namespace=email" \
  --form "path=impapi" \
  --form "file=@/path/to/somefile.txt" \
  --form "override_params[visibility]=private" \
  --form "override_params[some_other_param]=some_value" \
  --url "https://gitlab.example.com/api/v4/projects/import"
```

##### Tableau de hashes {#array-of-hashes}

`variables` est un paramètre de type `array` contenant des paires clé/valeur hash `[{ 'key': 'UPLOAD_TO_S3', 'value': 'true' }]` :

```shell
curl --globoff --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/169/pipeline?ref=master&variables[0][key]=VAR1&variables[0][value]=hello&variables[1][key]=VAR2&variables[1][value]=world"

curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{ "ref": "master", "variables": [ {"key": "VAR1", "value": "hello"}, {"key": "VAR2", "value": "world"} ] }' \
  --url "https://gitlab.example.com/api/v4/projects/169/pipeline"
```

#### Encodage de `+` dans les dates ISO 8601 {#encoding--in-iso-8601-dates}

Si vous devez inclure un `+` dans un paramètre de requête, vous devrez peut-être utiliser `%2B` à la place, en raison d'une [recommandation du W3](https://www.w3.org/Addressing/URL/4_URI_Recommentations.html) qui entraîne l'interprétation de `+` comme un espace. Par exemple, dans une date ISO 8601, vous pouvez inclure une heure spécifique au format ISO 8601, telle que :

```plaintext
2017-10-17T23:11:13.000+05:30
```

L'encodage correct pour le paramètre de requête serait :

```plaintext
2017-10-17T23:11:13.000%2B05:30
```

## Évaluation d'une réponse {#evaluating-a-response}

Dans certaines circonstances, la réponse de l'API peut ne pas correspondre à ce que vous attendez. Les problèmes peuvent inclure des valeurs nulles et des redirections. Si vous recevez un code de statut numérique dans la réponse, consultez [Codes de statut](troubleshooting.md#status-codes).

### `null` vs `false` {#null-vs-false}

Dans les réponses d'API, certains champs booléens peuvent avoir des valeurs `null`. Un booléen `null` n'a pas de valeur par défaut et n'est ni `true` ni `false`. GitLab traite les valeurs `null` dans les champs booléens de la même manière que `false`.

Dans les arguments booléens, vous ne devez définir que les valeurs `true` ou `false` (pas `null`).

### Redirections {#redirects}

{{< history >}}

- Introduit dans GitLab 16.4 [avec un flag](../../administration/feature_flags/_index.md) nommé `api_redirect_moved_projects`. Désactivé par défaut. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137578) dans GitLab 16.7. L'indicateur de fonctionnalité `api_redirect_moved_projects` a été supprimé.

{{< /history >}}

Après des [modifications de chemin](../../user/project/repository/_index.md#repository-path-changes), l'API REST peut répondre avec un message indiquant que le point de terminaison a été déplacé. Dans ce cas, utilisez le point de terminaison spécifié dans l'en-tête `Location`.

Exemple d'un projet déplacé vers un chemin différent :

```shell
curl --request GET \
  --verbose \
  --url "https://gitlab.example.com/api/v4/projects/gitlab-org%2Fold-path-project"
```

La réponse est :

```plaintext
...
< Location: http://gitlab.example.com/api/v4/projects/81
...
This resource has been moved permanently to https://gitlab.example.com/api/v4/projects/81
```

## Pagination {#pagination}

GitLab prend en charge les méthodes de pagination suivantes :

- Pagination par décalage. La méthode par défaut, disponible sur tous les points de terminaison, sauf, dans GitLab 16.5 et versions ultérieures, le point de terminaison `users`.
- Pagination par jeu de clés. Ajoutée à certains points de terminaison, mais [progressivement déployée](https://gitlab.com/groups/gitlab-org/-/epics/2039).

Pour les grandes collections, vous devriez utiliser la pagination par jeu de clés (lorsqu'elle est disponible) plutôt que la pagination par décalage, pour des raisons de performance.

### Pagination par décalage {#offset-based-pagination}

{{< history >}}

- Le point de terminaison `users` a été [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/426547) pour la pagination par décalage dans GitLab 16.5 et sa suppression est prévue dans la version 17.0. Ce changement est un changement majeur. Utilisez plutôt la pagination par jeu de clés pour ce point de terminaison.
- Le point de terminaison `users` impose la pagination par jeu de clés lorsque le nombre d'enregistrements demandés est supérieur à 50 000 dans GitLab 17.0.

{{< /history >}}

Parfois, le résultat retourné s'étend sur plusieurs pages. Lors du listage des ressources, vous pouvez passer les paramètres suivants :

| Paramètre  | Description                                                   |
|:-----------|:--------------------------------------------------------------|
| `page`     | Numéro de page (par défaut : `1`).                                   |
| `per_page` | Nombre d'éléments à lister par page (par défaut : `20`, max : `100`). |

L'exemple suivant liste 50 [espaces de nommage](../namespaces.md) par page :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces?per_page=50"
```

> [!note]
> Il existe une [limite maximale de décalage autorisé](../../administration/instance_limits.md#max-offset-allowed-by-the-rest-api-for-offset-based-pagination) pour la pagination par décalage. Vous pouvez modifier la limite dans les instances GitLab Self-Managed.

#### En-tête de pagination `Link` {#pagination-link-header}

[Les en-têtes `Link`](https://www.w3.org/wiki/LinkHeader) sont retournés avec chaque réponse. Ils ont `rel` défini sur `prev`, `next`, `first` ou `last` et contiennent l'URL pertinente. Assurez-vous d'utiliser ces liens plutôt que de générer vos propres URL.

Pour les utilisateurs de GitLab.com, [certains en-têtes de pagination peuvent ne pas être retournés](../../user/gitlab_com/_index.md#pagination-response-headers).

L'exemple cURL suivant limite la sortie à trois éléments par page (`per_page=3`) et demande la deuxième page (`page=2`) des [commentaires](../notes.md) du ticket avec l'ID `8` appartenant au projet avec l'ID `9` :

```shell
curl --request GET \
  --head \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/9/issues/8/notes?per_page=3&page=2"
```

La réponse est :

```http
HTTP/2 200 OK
cache-control: no-cache
content-length: 1103
content-type: application/json
date: Mon, 18 Jan 2016 09:43:18 GMT
link: <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="prev", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="next", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="first", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="last"
status: 200 OK
vary: Origin
x-next-page: 3
x-page: 2
x-per-page: 3
x-prev-page: 1
x-request-id: 732ad4ee-9870-4866-a199-a9db0cde3c86
x-runtime: 0.108688
x-total: 8
x-total-pages: 3
```

#### Autres en-têtes de pagination {#other-pagination-headers}

GitLab retourne également les en-têtes de pagination supplémentaires suivants :

| En-tête          | Description |
|:----------------|:------------|
| `x-next-page`   | L'index de la page suivante. |
| `x-page`        | L'index de la page actuelle (à partir de 1). |
| `x-per-page`    | Le nombre d'éléments par page. |
| `x-prev-page`   | L'index de la page précédente. |
| `x-total`       | Le nombre total d'éléments. |
| `x-total-pages` | Le nombre total de pages. |

Pour les utilisateurs de GitLab.com, [certains en-têtes de pagination peuvent ne pas être retournés](../../user/gitlab_com/_index.md#pagination-response-headers).

### Pagination par jeu de clés {#keyset-based-pagination}

La pagination par jeu de clés permet une récupération plus efficace des pages et, contrairement à la pagination par décalage, son temps d'exécution est indépendant de la taille de la collection.

Cette méthode est contrôlée par les paramètres suivants. `order_by` et `sort` sont tous deux obligatoires.

| Paramètre    | Obligatoire | Description |
|--------------|----------|-------------|
| `pagination` | oui      | `keyset` (pour activer la pagination par jeu de clés). |
| `per_page`   | non       | Nombre d'éléments à lister par page (par défaut : `20`, max : `100`). |
| `order_by`   | oui      | Colonne selon laquelle effectuer le tri. |
| `sort`       | oui      | Ordre de tri (`asc` ou `desc`) |

L'exemple suivant liste 50 [projets](../projects.md) par page, triés par `id` par ordre croissant.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc"
```

L'en-tête de réponse inclut un lien vers la page suivante. Par exemple :

```http
HTTP/1.1 200 OK
...
Link: <https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc&id_after=42>; rel="next"
Status: 200 OK
...
```

Le lien vers la page suivante contient un filtre supplémentaire `id_after=42` qui exclut les enregistrements déjà récupérés.

Autre exemple : la requête suivante liste 50 [groupes](../groups.md) par page, triés par `name` par ordre croissant, en utilisant la pagination par jeu de clés :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups?pagination=keyset&per_page=50&order_by=name&sort=asc"
```

L'en-tête de réponse inclut un lien vers la page suivante :

```http
HTTP/1.1 200 OK
...
Link: <https://gitlab.example.com/api/v4/groups?pagination=keyset&per_page=50&order_by=name&sort=asc&cursor=eyJuYW1lIjoiRmxpZ2h0anMiLCJpZCI6IjI2IiwiX2tkIjoibiJ9>; rel="next"
Status: 200 OK
...
```

Le lien vers la page suivante contient un filtre supplémentaire `cursor=eyJuYW1lIjoiRmxpZ2h0anMiLCJpZCI6IjI2IiwiX2tkIjoibiJ9` qui exclut les enregistrements déjà récupérés.

L'en-tête `X-NEXT-CURSOR` contient la valeur du curseur pour récupérer les enregistrements de la page suivante, tandis que l'en-tête `X-PREV-CURSOR` contient la valeur du curseur pour récupérer ceux de la page précédente, lorsqu'elle est disponible.

Le type de filtre dépend de l'option `order_by` utilisée, et vous pouvez avoir plus d'un filtre supplémentaire.

> [!warning]
> L'en-tête `Links` a été supprimé pour s'aligner sur la [spécification W3C `Link`](https://www.w3.org/wiki/LinkHeader). L'en-tête `Link` doit être utilisé à la place.

Lorsque la fin de la collection est atteinte et qu'il n'y a plus d'enregistrements supplémentaires à récupérer, l'en-tête `Link` est absent et le tableau résultant est vide.

Vous devez utiliser uniquement le lien fourni pour récupérer la page suivante plutôt que de construire votre propre URL. Hormis les en-têtes affichés, aucun en-tête de pagination supplémentaire n'est exposé.

#### Ressources prises en charge {#supported-resources}

La pagination par jeu de clés n'est prise en charge que pour certaines ressources et options de tri :

| Ressource                                                                       | Options                                                                                                                                                                               | Disponibilité |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| [Événements d'audit de groupe](../audit_events.md#list-all-group-audit-events)       | `order_by=id`, `sort=desc` uniquement                                                                                                                                                       | Utilisateurs authentifiés uniquement. |
| [Groupes](../groups.md#list-groups)                                             | `order_by=name`, `sort=asc` uniquement                                                                                                                                                      | Utilisateurs non authentifiés uniquement. |
| [Événements d'audit d'instance](../audit_events.md#list-all-instance-audit-events) | `order_by=id`, `sort=desc` uniquement                                                                                                                                                       | Utilisateurs authentifiés uniquement. |
| [Pipelines de packages](../packages.md#list-package-pipelines)                     | `order_by=id`, `sort=desc` uniquement                                                                                                                                                       | Utilisateurs authentifiés uniquement. |
| [Jobs de projet](../jobs.md#list-all-jobs-for-a-project)                         | `order_by=id`, `sort=desc` uniquement                                                                                                                                                       | Utilisateurs authentifiés uniquement. |
| [Événements d'audit de projet](../audit_events.md#list-all-project-audit-events)   | `order_by=id`, `sort=desc` uniquement                                                                                                                                                       | Utilisateurs authentifiés uniquement. |
| [Projets](../projects.md)                                                     | `order_by=id` uniquement                                                                                                                                                                    | Utilisateurs authentifiés et non authentifiés. |
| [Utilisateurs](../users.md)                                                           | `order_by=id`, `order_by=name`, `order_by=username`, `order_by=created_at` ou `order_by=updated_at`.                                                                                 | Utilisateurs authentifiés et non authentifiés. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/419556) dans GitLab 16.5. |
| [Tags de dépôt de registre](../container_registry.md)                           | `order_by=name`, `sort=asc` ou `sort=desc` uniquement.                                                                                                                                     | Utilisateurs authentifiés uniquement. |
| [Lister l'arborescence du dépôt](../repositories.md#list-all-repository-trees-in-a-project)                | N/A                                                                                                                                                                                   | Utilisateurs authentifiés et non authentifiés. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154897) dans GitLab 17.1. |
| [Tickets de projet](../issues.md#list-all-project-issues)                             | `order_by=created_at`, `order_by=updated_at`, `order_by=title`, `order_by=id`, `order_by=weight`, `order_by=due_date`, `order_by=relative_position`, `sort=asc` ou `sort=desc` uniquement. | Utilisateurs authentifiés et non authentifiés. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199887/) dans GitLab 18.3. |

### En-têtes de réponse de pagination {#pagination-response-headers}

Pour des raisons de performance, si une requête retourne plus de 10 000 enregistrements, GitLab ne retourne pas les en-têtes suivants :

- `x-total`.
- `x-total-pages`.
- `rel="last"` `link`

## Gestion des versions et dépréciations {#versioning-and-deprecations}

La version de l'API REST est conforme à la spécification de gestion sémantique de version. Le numéro de version majeure est `4`. Les modifications incompatibles avec les versions antérieures nécessitent le changement de ce numéro de version.

- La version mineure n'est pas explicite, ce qui permet d'avoir un point de terminaison d'API stable.
- Les nouvelles fonctionnalités sont ajoutées à l'API avec le même numéro de version.
- Les changements de version majeure de l'API, ainsi que la suppression de versions entières de l'API, sont effectués en parallèle avec les releases majeures de GitLab.
- Toutes les dépréciations et les modifications entre les versions sont notées dans la documentation.

Les éléments suivants sont exclus du processus de dépréciation et peuvent être supprimés à tout moment sans préavis :

- Éléments étiquetés dans les [ressources de l'API REST](../api_resources.md) comme [expérimentaux ou en version bêta](../../policy/development_stages_support.md).
- Champs masqués par un feature flag et désactivés par défaut.

Pour GitLab Self-Managed, [le retour](../../update/convert_to_ee/revert.md) d'une instance EE vers CE entraîne des changements majeurs.
