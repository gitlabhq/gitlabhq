---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Ruby gems
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [clients de gestionnaire de packages Ruby gems et Bundler](../../user/packages/rubygems_registry/_index.md).

> [!warning]
> Cette API est utilisée par les [clients de gestionnaire de packages Ruby gems et Bundler](https://maven.apache.org/) et n'est généralement pas destinée à une utilisation manuelle. Cette API est en cours de développement et n'est pas prête pour une utilisation en production en raison de fonctionnalités limitées.

Ces endpoints ne respectent pas les méthodes d'authentification API standard. Consultez la [documentation du registre Ruby gems](../../user/packages/rubygems_registry/_index.md) pour plus de détails sur les en-têtes et les types de jetons pris en charge. Les méthodes d'authentification non documentées pourraient être supprimées à l'avenir.

## Activer l'API Ruby gems {#enable-the-ruby-gems-api}

L'API Ruby gems pour GitLab est protégée par un feature flag désactivé par défaut. Les administrateurs GitLab ayant accès à la console GitLab Rails peuvent activer cette API pour votre instance.

Pour l'activer :

```ruby
Feature.enable(:rubygem_packages)
```

Pour la désactiver :

```ruby
Feature.disable(:rubygem_packages)
```

Pour l'activer ou la désactiver pour des projets spécifiques :

```ruby
Feature.enable(:rubygem_packages, Project.find(1))
Feature.disable(:rubygem_packages, Project.find(2))
```

## Télécharger un fichier gem {#download-a-gem-file}

Télécharge un fichier gem spécifié pour un projet.

```plaintext
GET projects/:id/packages/rubygems/gems/:file_name
```

| Attribut    | Type   | Obligatoire | Description |
| ------------ | ------ | -------- | ----------- |
| `id`         | string | oui      | L'ID ou le chemin complet du projet. |
| `file_name`  | string | oui      | Le nom du fichier `.gem`. |

```shell
curl --header "Authorization:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/gems/my_gem-1.0.0.gem"
```

Écrire la sortie dans un fichier :

```shell
curl --header "Authorization:<personal_access_token>" "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/gems/my_gem-1.0.0.gem" >> my_gem-1.0.0.gem
```

Cela écrit le fichier téléchargé dans `my_gem-1.0.0.gem` dans le répertoire actuel.

## Télécharger un fichier gemspec {#download-a-gemspec-file}

Télécharge un fichier gemspec au format Marshal pour une version de gem spécifique.

```plaintext
GET projects/:id/packages/rubygems/quick/Marshal.4.8/:file_name
```

| Attribut    | Type   | Obligatoire | Description |
| ------------ | ------ | -------- | ----------- |
| `id`         | string | oui      | L'ID ou le chemin complet du projet. |
| `file_name`  | string | oui      | Le nom du fichier gemspec au format `<gem_name>-<version>.gemspec.rz`. |

La réponse est un objet `Gem::Specification` compressé par deflate et sérialisé avec Marshal.

```shell
curl --header "Authorization:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/quick/Marshal.4.8/my_gem-1.0.0.gemspec.rz"
```

## Récupérer les dépendances {#retrieve-dependencies}

Récupère une liste de dépendances pour les gems spécifiés.

La réponse est un tableau sérialisé avec Marshal de hachages pour toutes les versions des gems demandés. Étant donné que la réponse est sérialisée avec Marshal, vous pouvez la stocker dans un fichier.

```plaintext
GET projects/:id/packages/rubygems/api/v1/dependencies
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'ID ou le chemin complet du projet. |
| `gems`    | string | non       | Liste de gems séparés par des virgules pour lesquels récupérer les dépendances. |

```shell
curl --header "Authorization:<personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/dependencies?gems=my_gem,foo"
```

Si Ruby est installé, vous pouvez utiliser la commande Ruby suivante pour lire la réponse. Pour que cela fonctionne, vous devez soit [définir vos identifiants dans `~/.gem/credentials`](../../user/packages/rubygems_registry/_index.md#authenticate-to-the-package-registry), soit passer votre jeton d'accès à la requête :

```shell
$ ruby -ropen-uri -rpp -e \
  'pp Marshal.load(URI.open("https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/dependencies?gems=my_gem,rails,foo", "Authorization" => <personal_access_token>))'

[{:name=>"my_gem", :number=>"0.0.1", :platform=>"ruby", :dependencies=>[]},
 {:name=>"my_gem",
  :number=>"0.0.3",
  :platform=>"ruby",
  :dependencies=>
   [["dependency_1", "~> 1.2.3"],
    ["dependency_2", "= 3.0.0"],
    ["dependency_3", ">= 1.0.0"],
    ["dependency_4", ">= 0"]]},
 {:name=>"my_gem",
  :number=>"0.0.2",
  :platform=>"ruby",
  :dependencies=>
   [["dependency_1", "~> 1.2.3"],
    ["dependency_2", "= 3.0.0"],
    ["dependency_3", ">= 1.0.0"],
    ["dependency_4", ">= 0"]]},
 {:name=>"foo",
  :number=>"0.0.2",
  :platform=>"ruby",
  :dependencies=>
    ["dependency_2", "= 3.0.0"],
    ["dependency_4", ">= 0"]]}]
```

## Téléverser un gem {#upload-a-gem}

Téléverse un gem pour un projet spécifié.

```plaintext
POST projects/:id/packages/rubygems/api/v1/gems
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'ID ou le chemin complet du projet. |

```shell
curl --request POST \
     --upload-file path/to/my_gem_file.gem \
     --header "Authorization:<personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/rubygems/api/v1/gems"
```
