---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Suggest Changes
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [suggestions de code](../user/project/merge_requests/reviews/suggestions.md).

Les suggestions offrent un moyen de proposer des modifications spécifiques qui peuvent être directement appliquées au code. Vous pouvez créer et appliquer des suggestions de code par programmation dans les discussions de merge request avec cette API. Chaque appel API aux suggestions doit être authentifié.

## Créer une suggestion {#create-a-suggestion}

Pour créer une suggestion via l'API, utilisez l'API Discussions pour [créer un nouveau fil de discussion dans le diff de la merge request](discussions.md#create-a-merge-request-thread). Le format des suggestions est le suivant :

````markdown
```suggestion:-3+0
example text
```
````

## Appliquer une suggestion {#apply-a-suggestion}

Applique un correctif suggéré dans une merge request.

Prérequis :

- Les utilisateurs doivent avoir le rôle Developer, Maintainer ou Owner.

```plaintext
PUT /suggestions/:id/apply
```

Attributs pris en charge :

| Attribut        | Type    | Obligatoire | Description |
|------------------|---------|----------|-------------|
| `id`             | integer | Oui      | ID d'une suggestion. |
| `commit_message` | string  | Non       | Message de commit personnalisé à utiliser à la place du message généré par défaut ou du message par défaut du projet. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut      | Type    | Description |
|----------------|---------|-------------|
| `applicable`   | boolean | Si `true`, la suggestion peut être appliquée. |
| `applied`      | boolean | Si `true`, la suggestion a été appliquée. |
| `from_content` | string  | Contenu original avant la suggestion. |
| `from_line`    | integer | Numéro de ligne de début de la suggestion. |
| `id`           | integer | ID de la suggestion. |
| `to_content`   | string  | Contenu suggéré pour remplacer l'original. |
| `to_line`      | integer | Numéro de ligne de fin de la suggestion. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/suggestions/5/apply"
```

Exemple de réponse :

```json
{
  "id": 5,
  "from_line": 10,
  "to_line": 10,
  "applicable": true,
  "applied": false,
  "from_content": "This is an example\n",
  "to_content": "This is an example\n"
}
```

## Appliquer plusieurs suggestions {#apply-multiple-suggestions}

Applique plusieurs correctifs suggérés dans une merge request.

Prérequis :

- Les utilisateurs doivent avoir le rôle Developer, Maintainer ou Owner.

```plaintext
PUT /suggestions/batch_apply
```

Attributs pris en charge :

| Attribut        | Type          | Obligatoire | Description |
|------------------|---------------|----------|-------------|
| `ids`            | integer array | Oui      | IDs des suggestions à appliquer. |
| `commit_message` | string        | Non       | Message de commit personnalisé à utiliser à la place du message généré par défaut ou du message par défaut du projet. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et un tableau d'objets de suggestion avec les attributs de réponse suivants :

| Attribut      | Type    | Description |
|----------------|---------|-------------|
| `applicable`   | boolean | Si `true`, la suggestion peut être appliquée. |
| `applied`      | boolean | Si `true`, la suggestion a été appliquée. |
| `from_content` | string  | Contenu original avant la suggestion. |
| `from_line`    | integer | Numéro de ligne de début de la suggestion. |
| `id`           | integer | ID de la suggestion. |
| `to_content`   | string  | Contenu suggéré pour remplacer l'original. |
| `to_line`      | integer | Numéro de ligne de fin de la suggestion. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"ids": [5, 6]}' \
  --url "https://gitlab.example.com/api/v4/suggestions/batch_apply"
```

Exemple de réponse :

```json
[
  {
    "id": 5,
    "from_line": 10,
    "to_line": 10,
    "applicable": true,
    "applied": false,
    "from_content": "This is an example\n",
    "to_content": "This is an example\n"
  },
  {
    "id": 6,
    "from_line": 19,
    "to_line": 19,
    "applicable": true,
    "applied": false,
    "from_content": "This is another example\n",
    "to_content": "This is another example\n"
  }
]
```
