---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API NuGet
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec le [client NuGet package manager](../../user/packages/nuget_repository/_index.md).

> [!warning]
> Cette API est utilisée par le [client NuGet package manager](https://www.nuget.org/) et n'est généralement pas destinée à une utilisation manuelle.

Ces points de terminaison ne respectent pas les méthodes d'authentification standard de l'API. Consultez la [documentation du registre de paquets NuGet](../../user/packages/nuget_repository/_index.md) pour plus de détails sur les en-têtes et les types de jetons pris en charge. Les méthodes d'authentification non documentées pourraient être supprimées à l'avenir.

## Récupérer un index de paquet {#retrieve-a-package-index}

Récupère l'index d'un paquet spécifié, qui comprend une liste des versions disponibles.

```plaintext
GET projects/:id/packages/nuget/download/:package_name/index
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | oui      | L'ID ou le chemin complet du projet. |
| `package_name` | string | oui      | Le nom du paquet. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/index"
```

Exemple de réponse :

```json
{
  "versions": [
    "1.3.0.17"
  ]
}
```

## Télécharger un fichier de paquet {#download-a-package-file}

Télécharge un fichier de paquet NuGet spécifié pour un projet. Le [service de métadonnées](#retrieve-package-metadata) fournit cette URL.

```plaintext
GET projects/:id/packages/nuget/download/:package_name/:package_version/:package_filename
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | oui      | L'ID ou le chemin complet du projet. |
| `package_name`    | string | oui      | Le nom du paquet. |
| `package_version` | string | oui      | La version du paquet. |
| `package_filename`| string | oui      | Le nom du fichier. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/mynugetpkg.1.3.0.17.nupkg"
```

Écrire la sortie dans un fichier :

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/mynugetpkg.1.3.0.17.nupkg" > MyNuGetPkg.1.3.0.17.nupkg
```

Cette opération écrit le fichier téléchargé dans `MyNuGetPkg.1.3.0.17.nupkg` dans le répertoire courant.

> [!note]
> Cette API renvoie un statut `404` lorsque vous utilisez les [points de terminaison de groupe](#group-level). Utilisez le CLI NuGet package manager pour [installer des paquets](../../user/packages/nuget_repository/_index.md#install-a-package) avec les points de terminaison de groupe afin d'éviter cette erreur.

## Charger un fichier de paquet {#upload-a-package-file}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/416404) dans GitLab 16.2 pour le flux NuGet v2.

{{< /history >}}

Charge un fichier de paquet NuGet pour un projet spécifié.

- Pour le flux NuGet v3 :

  ```plaintext
  PUT projects/:id/packages/nuget
  ```

- Pour le flux NuGet V2 :

  ```plaintext
  PUT projects/:id/packages/nuget/v2
  ```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | oui      | L'ID ou le chemin complet du projet. |
| `package_name`    | string | oui      | Le nom du paquet. |
| `package_version` | string | oui      | La version du paquet. |
| `package_filename`| string | oui      | Le nom du fichier. |

- Pour le flux NuGet v3 :

  ```shell
  curl --request PUT \
      --form 'package=@path/to/mynugetpkg.1.3.0.17.nupkg' \
      --user <username>:<personal_access_token> \
      --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/"
  ```

- Pour le flux NuGet v2 :

  ```shell
  curl --request PUT \
      --form 'package=@path/to/mynugetpkg.1.3.0.17.nupkg' \
      --user <username>:<personal_access_token> \
      --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"
  ```

## Charger un fichier de paquet de symboles {#upload-a-symbol-package-file}

Charge un fichier de paquet de symboles NuGet spécifié (`.snupkg`) pour un projet.

```plaintext
PUT projects/:id/packages/nuget/symbolpackage
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | oui      | L'ID ou le chemin complet du projet. |
| `package_name`    | string | oui      | Le nom du paquet. |
| `package_version` | string | oui      | La version du paquet. |
| `package_filename`| string | oui      | Le nom du fichier. |

```shell
curl --request PUT \
     --form 'package=@path/to/mynugetpkg.1.3.0.17.snupkg' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolpackage"
```

## Préfixe de route {#route-prefix}

Pour les routes restantes, il existe deux ensembles de routes identiques qui effectuent chacune des requêtes dans des portées différentes :

- Utilisez le préfixe de niveau groupe pour effectuer des requêtes dans la portée d'un groupe.
- Utilisez le préfixe de niveau projet pour effectuer des requêtes dans la portée d'un seul projet.

Les exemples de ce document utilisent tous le préfixe de niveau projet.

### Niveau groupe {#group-level}

```plaintext
/groups/:id/-/packages/nuget
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'ID du groupe ou le chemin complet du groupe. |

### Niveau projet {#project-level}

```plaintext
/projects/:id/packages/nuget
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'ID du projet ou le chemin complet du projet. |

## Index de service {#service-index}

### Flux/protocole source V2 {#v2-source-feedprotocol}

Récupère un document XML représentant l'index de service du flux source NuGet v2. L'authentification n'est pas requise.

```plaintext
GET <route-prefix>/v2
```

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"
```

Exemple de réponse :

```xml
<?xml version="1.0" encoding="utf-8"?>
<service xmlns="http://www.w3.org/2007/app" xmlns:atom="http://www.w3.org/2005/Atom" xml:base="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2">
  <workspace>
    <atom:title type="text">Default</atom:title>
    <collection href="Packages">
      <atom:title type="text">Packages</atom:title>
    </collection>
  </workspace>
</service>
```

### Flux/protocole source V3 {#v3-source-feedprotocol}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/214674) pour être public dans GitLab 16.1.

{{< /history >}}

Récupère une liste des ressources API disponibles. L'authentification n'est pas requise.

```plaintext
GET <route-prefix>/index
```

Exemple de requête :

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/index"
```

Exemple de réponse :

```json
{
  "version": "3.0.0",
  "resources": [
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query",
      "@type": "SearchQueryService",
      "comment": "Filter and search for packages by keyword."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query",
      "@type": "SearchQueryService/3.0.0-beta",
      "comment": "Filter and search for packages by keyword."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query",
      "@type": "SearchQueryService/3.0.0-rc",
      "comment": "Filter and search for packages by keyword."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata",
      "@type": "RegistrationsBaseUrl",
      "comment": "Get package metadata."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata",
      "@type": "RegistrationsBaseUrl/3.0.0-beta",
      "comment": "Get package metadata."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata",
      "@type": "RegistrationsBaseUrl/3.0.0-rc",
      "comment": "Get package metadata."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download",
      "@type": "PackageBaseAddress/3.0.0",
      "comment": "Get package content (.nupkg)."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget",
      "@type": "PackagePublish/2.0.0",
      "comment": "Push and delete (or unlist) packages."
    },
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolpackage",
      "@type": "SymbolPackagePublish/4.9.0",
      "comment": "Push symbol packages."
    }
  ]
}
```

Les URL dans la réponse ont le même préfixe de route que celui utilisé pour les demander. Si vous les demandez avec la route de niveau groupe, les URL renvoyées contiennent `/groups/:id/-`.

## Récupérer les métadonnées d'un paquet {#retrieve-package-metadata}

Récupère les métadonnées d'un paquet spécifié.

```plaintext
GET <route-prefix>/metadata/:package_name/index
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `package_name` | string | oui      | Le nom du paquet. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/index"
```

Exemple de réponse :

```json
{
  "count": 1,
  "items": [
    {
      "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
      "lower": "1.3.0.17",
      "upper": "1.3.0.17",
      "count": 1,
      "items": [
        {
          "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
          "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
          "catalogEntry": {
            "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
            "authors": "Author1, Author2",
            "dependencyGroups": [],
            "id": "MyNuGetPkg",
            "version": "1.3.0.17",
            "tags": "",
            "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
            "description": "Description of the package",
            "summary": "Description of the package",
            "published": "2023-05-08T17:23:25Z",
          }
        }
      ]
    }
  ]
}
```

## Récupérer les métadonnées de version {#retrieve-version-metadata}

Récupère les métadonnées d'une version de paquet spécifiée.

```plaintext
GET <route-prefix>/metadata/:package_name/:package_version
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `package_name`    | string | oui      | Le nom du paquet.    |
| `package_version` | string | oui      | La version du paquet. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17"
```

Exemple de réponse :

```json
{
  "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
  "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
  "catalogEntry": {
    "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
    "authors": "Author1, Author2",
    "dependencyGroups": [],
    "id": "MyNuGetPkg",
    "version": "1.3.0.17",
    "tags": "",
    "packageContent": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/MyNuGetPkg/1.3.0.17/helloworld.1.3.0.17.nupkg",
    "description": "Description of the package",
    "summary": "Description of the package",
    "published": "2023-05-08T17:23:25Z",
  }
}
```

## Rechercher des paquets {#search-for-packages}

Recherche des paquets NuGet dans le dépôt en fonction d'une requête spécifiée.

```plaintext
GET <route-prefix>/query
```

| Attribut    | Type    | Obligatoire | Description |
| ------------ | ------- | -------- | ----------- |
| `q`          | string  | oui      | La requête de recherche. |
| `skip`       | integer | non       | Le nombre de résultats à ignorer. |
| `take`       | integer | non       | Le nombre de résultats à retourner. |
| `prerelease` | boolean | non       | Inclure les versions préliminaires. Par défaut à `true` si aucune valeur n'est fournie. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/query?q=MyNuGet"
```

Exemple de réponse :

```json
{
  "totalHits": 1,
  "data": [
    {
      "@type": "Package",
      "authors": "Author1, Author2",
      "id": "MyNuGetPkg",
      "title": "MyNuGetPkg",
      "description": "Description of the package",
      "summary": "Description of the package",
      "totalDownloads": 0,
      "verified": true,
      "version": "1.3.0.17",
      "versions": [
        {
          "@id": "https://gitlab.example.com/api/v4/projects/1/packages/nuget/metadata/MyNuGetPkg/1.3.0.17.json",
          "version": "1.3.0.17",
          "downloads": 0
        }
      ],
      "tags": ""
    }
  ]
}
```

## Supprimer un paquet {#delete-a-package}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/38275) dans GitLab 16.5.

{{< /history >}}

Supprime un paquet NuGet spécifié.

```plaintext
DELETE projects/:id/packages/nuget/:package_name/:package_version
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | oui      | L'ID ou le chemin complet du projet. |
| `package_name`    | string | oui      | Le nom du paquet. |
| `package_version` | string | oui      | La version du paquet. |

```shell
curl --request DELETE \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/MyNuGetPkg/1.3.0.17"
```

Réponses possibles à la requête :

| Statut | Description |
| ------ | ----------- |
| `204`  | Paquet supprimé |
| `401`  | Non autorisé |
| `403`  | Interdit |
| `404`  | Introuvable |

## Télécharger un fichier de symboles de débogage `.pdb` {#download-a-debugging-symbol-file-pdb}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/416178) dans GitLab 16.7.

{{< /history >}}

Télécharge un fichier de symboles de débogage spécifié (`.pdb`).

```plaintext
GET <route-prefix>/symbolfiles/:file_name/:signature/:file_name
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `file_name`       | string | oui      | Le nom du fichier. |
| `signature`       | string | oui      | La signature du fichier. |
| `Symbolchecksum` | string | oui      | En-tête requis. La somme de contrôle du fichier. |

```shell
curl --header "Symbolchecksum: SHA256:<file_checksum>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolfiles/:file_name/:signature/:file_name"
```

Écrire la sortie dans un fichier :

```shell
curl --header "Symbolchecksum: SHA256:<file_checksum>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/symbolfiles/mynugetpkg.pdb/k813f89485474661234z7109cve5709eFFFFFFFF/mynugetpkg.pdb" > mynugetpkg.pdb
```

Réponses possibles à la requête :

| Statut | Description |
| ------ | ----------- |
| `200`  | Fichier téléchargé |
| `400`  | Requête incorrecte |
| `403`  | Interdit |
| `404`  | Introuvable |

## Points de terminaison de métadonnées du flux V2 {#v2-feed-metadata-endpoints}

{{< history >}}

- Introduit dans GitLab 16.3.

{{< /history >}}

### Point de terminaison $metadata {#metadata-endpoint}

L'authentification n'est pas requise. Renvoie les métadonnées pour les points de terminaison disponibles d'un flux V2 :

```plaintext
GET <route-prefix>/v2/$metadata
```

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/$metadata"
```

Exemple de réponse :

```xml
<edmx:Edmx xmlns:edmx="http://schemas.microsoft.com/ado/2007/06/edmx" Version="1.0">
  <edmx:DataServices xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" m:DataServiceVersion="2.0" m:MaxDataServiceVersion="2.0">
    <Schema xmlns="http://schemas.microsoft.com/ado/2006/04/edm" Namespace="NuGetGallery.OData">
      <EntityType Name="V2FeedPackage" m:HasStream="true">
        <Key>
          <PropertyRef Name="Id"/>
          <PropertyRef Name="Version"/>
        </Key>
        <Property Name="Id" Type="Edm.String" Nullable="false"/>
        <Property Name="Version" Type="Edm.String" Nullable="false"/>
        <Property Name="Authors" Type="Edm.String"/>
        <Property Name="Dependencies" Type="Edm.String"/>
        <Property Name="Description" Type="Edm.String"/>
        <Property Name="DownloadCount" Type="Edm.Int64" Nullable="false"/>
        <Property Name="IconUrl" Type="Edm.String"/>
        <Property Name="Published" Type="Edm.DateTime" Nullable="false"/>
        <Property Name="ProjectUrl" Type="Edm.String"/>
        <Property Name="Tags" Type="Edm.String"/>
        <Property Name="Title" Type="Edm.String"/>
        <Property Name="LicenseUrl" Type="Edm.String"/>
      </EntityType>
    </Schema>
    <Schema xmlns="http://schemas.microsoft.com/ado/2006/04/edm" Namespace="NuGetGallery">
      <EntityContainer Name="V2FeedContext" m:IsDefaultEntityContainer="true">
        <EntitySet Name="Packages" EntityType="NuGetGallery.OData.V2FeedPackage"/>
        <FunctionImport Name="FindPackagesById" ReturnType="Collection(NuGetGallery.OData.V2FeedPackage)" EntitySet="Packages">
          <Parameter Name="id" Type="Edm.String" FixedLength="false" Unicode="false"/>
        </FunctionImport>
      </EntityContainer>
    </Schema>
  </edmx:DataServices>
</edmx:Edmx>
```

### Points de terminaison d'entrée de paquet OData {#odata-package-entry-endpoints}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127667) dans GitLab 16.4.

{{< /history >}}

| Point de terminaison | Description |
| -------- | ----------- |
| `GET projects/:id/packages/nuget/v2/Packages()?$filter=(tolower(Id) eq '<package_name>')` | Renvoie un document XML OData contenant des informations sur le paquet portant le nom donné. |
| `GET projects/:id/packages/nuget/v2/FindPackagesById()?id='<package_name>'` | Renvoie un document XML OData contenant des informations sur le paquet portant le nom donné. |
| `GET projects/:id/packages/nuget/v2/Packages(Id='<package_name>',Version='<package_version>')` | Renvoie un document XML OData contenant des informations sur le paquet portant le nom et la version donnés. |

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='1.0.0')"
```

Exemple de réponse :

```xml
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xml:base="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2">
    <id>https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='1.0.0')</id>
    <category term="V2FeedPackage" scheme="http://schemas.microsoft.com/ado/2007/08/dataservices/scheme"/>
    <title type="text">mynugetpkg</title>
    <content type="application/zip" src="https://gitlab.example.com/api/v4/projects/1/packages/nuget/download/mynugetpkg/1.0.0/mynugetpkg.1.0.0.nupkg"/>
    <m:properties>
      <d:Version>1.0.0</d:Version>
    </m:properties>
 </entry>
```

> [!note]
> GitLab ne reçoit pas de jeton d'authentification pour les points de terminaison `Packages()` et `FindPackagesByID()`, donc la dernière version du paquet ne peut pas être renvoyée. Vous devez fournir la version lorsque vous installez ou mettez à niveau un paquet avec le flux NuGet v2.

```shell
curl --url "https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages()?$filter=(tolower(Id) eq 'mynugetpkg')"
```

Exemple de réponse :

```xml
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" xmlns:georss="http://www.georss.org/georss" xmlns:gml="http://www.opengis.net/gml" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xml:base="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2">
    <id>https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2/Packages(Id='mynugetpkg',Version='')</id>
    <category term="V2FeedPackage" scheme="http://schemas.microsoft.com/ado/2007/08/dataservices/scheme"/>
    <title type="text">mynugetpkg</title>
    <content type="application/zip" src="https://gitlab.example.com/api/v4/projects/1/packages/nuget/v2"/>
    <m:properties>
      <d:Version></d:Version>
    </m:properties>
 </entry>
```
