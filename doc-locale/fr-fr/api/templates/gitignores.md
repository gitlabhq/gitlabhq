---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API .gitignore
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer des modèles .gitignore. Pour plus d'informations, consultez la [documentation Git pour `.gitignore`](https://git-scm.com/docs/gitignore).

Les utilisateurs disposant du rôle Invité ne peuvent pas accéder aux modèles `.gitignore`. Pour plus d'informations, consultez [Visibilité des projets et des groupes](../../user/public_access.md).

## Lister tous les modèles `.gitignore` {#list-all-gitignore-templates}

Liste tous les modèles `.gitignore`.

```plaintext
GET /templates/gitignores
```

En cas de succès, renvoie [`200 OK`](../rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type   | Description |
|-----------|--------|-------------|
| `key`     | string | Identifiant clé du modèle `.gitignore`. |
| `name`    | string | Nom d'affichage du modèle `.gitignore`. |

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/templates/gitignores"
```

Exemple de réponse :

```json
[
  {
    "key": "Actionscript",
    "name": "Actionscript"
  },
  {
    "key": "Ada",
    "name": "Ada"
  },
  {
    "key": "Agda",
    "name": "Agda"
  },
  {
    "key": "Android",
    "name": "Android"
  },
  {
    "key": "AppEngine",
    "name": "AppEngine"
  },
  {
    "key": "AppceleratorTitanium",
    "name": "AppceleratorTitanium"
  },
  {
    "key": "ArchLinuxPackages",
    "name": "ArchLinuxPackages"
  },
  {
    "key": "Autotools",
    "name": "Autotools"
  },
  {
    "key": "C",
    "name": "C"
  },
  {
    "key": "C++",
    "name": "C++"
  },
  {
    "key": "CFWheels",
    "name": "CFWheels"
  },
  {
    "key": "CMake",
    "name": "CMake"
  },
  {
    "key": "CUDA",
    "name": "CUDA"
  },
  {
    "key": "CakePHP",
    "name": "CakePHP"
  },
  {
    "key": "ChefCookbook",
    "name": "ChefCookbook"
  },
  {
    "key": "Clojure",
    "name": "Clojure"
  },
  {
    "key": "CodeIgniter",
    "name": "CodeIgniter"
  },
  {
    "key": "CommonLisp",
    "name": "CommonLisp"
  },
  {
    "key": "Composer",
    "name": "Composer"
  },
  {
    "key": "Concrete5",
    "name": "Concrete5"
  }
]
```

## Récupérer un seul modèle `.gitignore` {#retrieve-a-single-gitignore-template}

Récupère un seul modèle `.gitignore`.

```plaintext
GET /templates/gitignores/:key
```

Attributs pris en charge :

| Attribut | Type   | Obligatoire | Description |
|-----------|--------|----------|-------------|
| `key`     | string | Oui      | Clé du modèle `.gitignore`. |

En cas de succès, renvoie [`200 OK`](../rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type   | Description |
|-----------|--------|-------------|
| `content` | string | Contenu du modèle `.gitignore`. |
| `name`    | string | Nom d'affichage du modèle `.gitignore`. |

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/templates/gitignores/Ruby"
```

Exemple de réponse :

```json
{
  "name": "Ruby",
  "content": "*.gem\n*.rbc\n/.config\n/coverage/\n/InstalledFiles\n/pkg/\n/spec/reports/\n/spec/examples.txt\n/test/tmp/\n/test/version_tmp/\n/tmp/\n\n# Used by dotenv library to load environment variables.\n# .env\n\n## Specific to RubyMotion:\n.dat*\n.repl_history\nbuild/\n*.bridgesupport\nbuild-iPhoneOS/\nbuild-iPhoneSimulator/\n\n## Specific to RubyMotion (use of CocoaPods):\n#\n# We recommend against adding the Pods directory to your .gitignore. However\n# you should judge for yourself, the pros and cons are mentioned at:\n# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control\n#\n# vendor/Pods/\n\n## Documentation cache and generated files:\n/.yardoc/\n/_yardoc/\n/doc/\n/rdoc/\n\n## Environment normalization:\n/.bundle/\n/vendor/bundle\n/lib/bundler/man/\n\n# for a library or gem, you might want to ignore these files since the code is\n# intended to run in multiple environments; otherwise, check them in:\n# Gemfile.lock\n# .ruby-version\n# .ruby-gemset\n\n# unless supporting rvm < 1.11.0 or doing something fancy, ignore this:\n.rvmrc\n"
}
```
