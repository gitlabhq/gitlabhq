---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des modèles de projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer une version spécifique au projet de ces endpoints :

- [Modèles Dockerfile](templates/dockerfiles.md)
- [Modèles Gitignore](templates/gitignores.md)
- [Modèles de configuration GitLab CI/CD](templates/gitlab_ci_ymls.md)
- [Modèles de licences open source](templates/licenses.md)
- [Modèles de tickets et de merge requests](../user/project/description_templates.md)

Ces endpoints sont dépréciés et leur suppression est prévue dans la version 5 de l'API.

En plus des modèles communs à toute l'instance, les modèles spécifiques au projet sont également disponibles depuis cet endpoint d'API.

La prise en charge est également disponible pour les [modèles de fichiers pour les groupes](../user/group/manage.md#group-file-templates).

## Lister tous les modèles d'un type particulier {#list-all-templates-of-a-particular-type}

Liste tous les modèles d'un type spécifié pour un projet.

```plaintext
GET /projects/:id/templates/:type
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `type`    | string            | Oui      | Type du modèle. Les valeurs acceptées sont : `dockerfiles`, `gitignores`, `gitlab_ci_ymls`, `licenses`, `issues` ou `merge_requests`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type   | Description |
|-----------|--------|-------------|
| `key`     | string | Identifiant unique du modèle. |
| `name`    | string | Nom lisible par l'humain du modèle. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/templates/licenses"
```

Exemple de réponse (licences) :

```json
[
  {
    "key": "epl-1.0",
    "name": "Eclipse Public License 1.0"
  },
  {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0"
  },
  {
    "key": "unlicense",
    "name": "The Unlicense"
  },
  {
    "key": "agpl-3.0",
    "name": "GNU Affero General Public License v3.0"
  },
  {
    "key": "gpl-3.0",
    "name": "GNU General Public License v3.0"
  },
  {
    "key": "bsd-3-clause",
    "name": "BSD 3-clause \"New\" or \"Revised\" License"
  },
  {
    "key": "lgpl-2.1",
    "name": "GNU Lesser General Public License v2.1"
  },
  {
    "key": "mit",
    "name": "MIT License"
  },
  {
    "key": "apache-2.0",
    "name": "Apache License 2.0"
  },
  {
    "key": "bsd-2-clause",
    "name": "BSD 2-clause \"Simplified\" License"
  },
  {
    "key": "mpl-2.0",
    "name": "Mozilla Public License 2.0"
  },
  {
    "key": "gpl-2.0",
    "name": "GNU General Public License v2.0"
  }
]
```

## Récupérer un modèle d'un type particulier {#retrieve-a-template-of-a-particular-type}

Récupère un modèle d'un type spécifié pour un projet.

```plaintext
GET /projects/:id/templates/:type/:name
```

Attributs pris en charge :

| Attribut                    | Type              | Obligatoire | Description |
|------------------------------|-------------------|----------|-------------|
| `id`                         | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `name`                       | string            | Oui      | Clé du modèle, telle qu'obtenue depuis l'endpoint de la collection. |
| `type`                       | string            | Oui      | Type du modèle. L'un des suivants : `dockerfiles`, `gitignores`, `gitlab_ci_ymls`, `licenses`, `issues` ou `merge_requests`. |
| `fullname`                   | string            | Non       | Nom complet du détenteur des droits d'auteur à utiliser lors du développement des espaces réservés dans le modèle. Affecte uniquement les licences. |
| `project`                    | string            | Non       | Nom du projet à utiliser lors du développement des espaces réservés dans le modèle. Affecte uniquement les licences. |
| `source_template_project_id` | integer           | Non       | ID du projet où un modèle donné est stocké. Utile lorsque plusieurs modèles de différents projets portent le même nom. Si plusieurs modèles portent le même nom, la correspondance de l'ancêtre le plus proche est renvoyée si `source_template_project_id` n'est pas spécifié. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut     | Type     | Description                                                   |
|---------------|----------|---------------------------------------------------------------|
| `conditions`  | array    | Tableau des conditions de la licence. Disponible uniquement pour les licences.    |
| `content`     | string   | Contenu du modèle.                                             |
| `description` | string   | Description de la licence. Disponible uniquement pour les licences.     |
| `html_url`    | string   | URL vers la page d'informations sur la licence. Disponible uniquement pour les licences. |
| `key`         | string   | Identifiant unique du modèle. Disponible uniquement pour les licences. |
| `limitations` | array    | Tableau des limitations de la licence. Disponible uniquement pour les licences.   |
| `name`        | string   | Nom lisible par l'humain du modèle.                          |
| `nickname`    | string   | Surnom courant de la licence. Disponible uniquement pour les licences. |
| `permissions` | array    | Tableau des permissions de la licence. Disponible uniquement pour les licences.   |
| `popular`     | boolean  | Si `true`, indique qu'il s'agit d'une licence populaire. Disponible uniquement pour les licences. |
| `source_url`  | string   | URL vers la source de la licence. Disponible uniquement pour les licences.      |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/templates/dockerfiles/Binary"
```

Exemple de réponse (Dockerfile) :

```json
{
  "name": "Binary",
  "content": "# This file is a template, and might need editing before it works on your project.\n# This Dockerfile installs a compiled binary into a bare system.\n# You must either commit your compiled binary into source control (not recommended)\n# or build the binary first as part of a CI/CD pipeline.\n\nFROM buildpack-deps:buster\n\nWORKDIR /usr/local/bin\n\n# Change `app` to whatever your binary is called\nAdd app .\nCMD [\"./app\"]\n"
}
```

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/templates/licenses/mit"
```

Exemple de réponse (licence) :

```json
{
  "key": "mit",
  "name": "MIT License",
  "nickname": null,
  "popular": true,
  "html_url": "http://choosealicense.com/licenses/mit/",
  "source_url": "https://opensource.org/licenses/MIT",
  "description": "A short and simple permissive license with conditions only requiring preservation of copyright and license notices. Licensed works, modifications, and larger works may be distributed under different terms and without source code.",
  "conditions": [
    "include-copyright"
  ],
  "permissions": [
    "commercial-use",
    "modifications",
    "distribution",
    "private-use"
  ],
  "limitations": [
    "liability",
    "warranty"
  ],
  "content": "MIT License\n\nCopyright (c) 2018 [fullname]\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.\n"
}
```
