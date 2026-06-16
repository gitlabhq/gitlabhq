---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Licences
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dans GitLab, un endpoint d'API est disponible pour travailler avec différents modèles de licences open source. Pour plus d'informations sur les conditions des différentes licences, consultez [ce site](https://choosealicense.com/) ou l'une des nombreuses autres ressources disponibles en ligne.

Les utilisateurs avec le rôle Invité ne peuvent pas accéder aux modèles de licences. Pour plus d'informations, consultez [Visibilité des projets et des groupes](../../user/public_access.md).

## Lister tous les modèles de licences {#list-all-license-templates}

Liste tous les modèles de licences.

```plaintext
GET /templates/licenses
```

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `popular` | boolean | non       | Si transmis, renvoie uniquement les licences populaires |

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/templates/licenses?popular=1"
```

Exemple de réponse :

```json
[
  {
    "key":"apache-2.0",
    "name":"Apache License 2.0",
    "nickname":null,
    "featured":true,
    "html_url":"http://choosealicense.com/licenses/apache-2.0/",
    "source_url":"http://www.apache.org/licenses/LICENSE-2.0.html",
    "description":"A permissive license that also provides an express grant of patent rights from contributors to users.",
    "conditions":[
      "include-copyright",
      "document-changes"
    ],
    "permissions":[
      "commercial-use",
      "modifications",
      "distribution",
      "patent-use",
      "private-use"
    ],
    "limitations":[
      "trademark-use",
      "no-liability"
    ],
    "content":"                                 Apache License\n                           Version 2.0, January 2004\n [...]"
  },
  {
    "key":"gpl-3.0",
    "name":"GNU General Public License v3.0",
    "nickname":"GNU GPLv3",
    "featured":true,
    "html_url":"http://choosealicense.com/licenses/gpl-3.0/",
    "source_url":"http://www.gnu.org/licenses/gpl-3.0.txt",
    "description":"The GNU GPL is the most widely used free software license and has a strong copyleft requirement. When distributing derived works, the source code of the work must be made available under the same license.",
    "conditions":[
      "include-copyright",
      "document-changes",
      "disclose-source",
      "same-license"
    ],
    "permissions":[
      "commercial-use",
      "modifications",
      "distribution",
      "patent-use",
      "private-use"
    ],
    "limitations":[
      "no-liability"
    ],
    "content":"                    GNU GENERAL PUBLIC LICENSE\n                       Version 3, 29 June 2007\n [...]"
  },
  {
    "key":"mit",
    "name":"MIT License",
    "nickname":null,
    "featured":true,
    "html_url":"http://choosealicense.com/licenses/mit/",
    "source_url":"http://opensource.org/licenses/MIT",
    "description":"A permissive license that is short and to the point. It lets people do anything with your code with proper attribution and without warranty.",
    "conditions":[
      "include-copyright"
    ],
    "permissions":[
      "commercial-use",
      "modifications",
      "distribution",
      "private-use"
    ],
    "limitations":[
      "no-liability"
    ],
    "content":"The MIT License (MIT)\n\nCopyright (c) [year] [fullname]\n [...]"
  }
]
```

## Récupérer un modèle de licence unique {#retrieve-a-single-license-template}

Récupère un modèle de licence unique. Vous pouvez transmettre des paramètres pour remplacer l'espace réservé de la licence.

```plaintext
GET /templates/licenses/:key
```

| Attribut  | Type   | Obligatoire | Description |
|------------|--------|----------|-------------|
| `key`      | string | oui      | La clé du modèle de licence |
| `project`  | string | non       | Le nom du projet protégé par droit d'auteur |
| `fullname` | string | non       | Le nom complet du titulaire du droit d'auteur |

> [!note]
> Si vous omettez le paramètre `fullname` mais que vous authentifiez votre requête, le nom de l'utilisateur authentifié remplace l'espace réservé du titulaire du droit d'auteur.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/templates/licenses/mit?project=My+Cool+Project"
```

Exemple de réponse :

```json
{
  "key":"mit",
  "name":"MIT License",
  "nickname":null,
  "featured":true,
  "html_url":"http://choosealicense.com/licenses/mit/",
  "source_url":"http://opensource.org/licenses/MIT",
  "description":"A permissive license that is short and to the point. It lets people do anything with your code with proper attribution and without warranty.",
  "conditions":[
    "include-copyright"
  ],
  "permissions":[
    "commercial-use",
    "modifications",
    "distribution",
    "private-use"
  ],
  "limitations":[
    "no-liability"
  ],
  "content":"The MIT License (MIT)\n\nCopyright (c) 2016 John Doe\n [...]"
}
```
