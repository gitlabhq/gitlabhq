---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Markdown
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduction de [l'authentification obligatoire](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93727) dans GitLab 15.3 [avec un indicateur](../administration/feature_flags/_index.md) nommé `authenticate_markdown_api`. Activé par défaut.

{{< /history >}}

Utilisez cette API pour afficher le contenu [Markdown](../user/markdown.md) en HTML.

Toutes les requêtes envoyées à cette API doivent être [authentifiées](rest/authentication.md).

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

## Afficher le contenu Markdown {#render-markdown-content}

Affiche le contenu Markdown en HTML.

```plaintext
POST /markdown
```

| Attribut | Type    | Obligatoire      | Description                                |
| --------- | ------- | ------------- | ------------------------------------------ |
| `text`    | string  | oui           | Le texte Markdown à afficher                |
| `gfm`     | boolean | non            | Affiche le texte en utilisant GitLab Flavored Markdown. La valeur par défaut est `false` |
| `project` | string  | non            | Utilisez `project` comme contexte lors de la création de références avec GitLab Flavored Markdown  |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type:application/json" \
  --data '{"text":"Hello world! :tada:", "gfm":true, "project":"group_example/project_example"}' "https://gitlab.example.com/api/v4/markdown"
```

Exemple de réponse :

```json
{ "html": "<p dir=\"auto\">Hello world! <gl-emoji title=\"party popper\" data-name=\"tada\" data-unicode-version=\"6.0\">🎉</gl-emoji></p>" }
```
