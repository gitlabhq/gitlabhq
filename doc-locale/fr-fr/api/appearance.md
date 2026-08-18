---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API d'apparence de l'application"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour contrôler l'apparence de votre instance GitLab. Pour plus d'informations, consultez [GitLab Appearance](../administration/appearance.md).

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

## Récupérer l'apparence de l'application {#retrieve-application-appearance}

Récupère la configuration de l'apparence de cette instance GitLab.

```plaintext
GET /application/appearance
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/appearance"
```

Exemple de réponse :

```json
{
  "title": "GitLab Test Instance",
  "description": "gitlab-test.example.com",
  "pwa_name": "GitLab PWA",
  "pwa_short_name": "GitLab",
  "pwa_description": "GitLab as PWA",
  "pwa_icon": "/uploads/-/system/appearance/pwa_icon/1/pwa_logo.png",
  "logo": "/uploads/-/system/appearance/logo/1/logo.png",
  "header_logo": "/uploads/-/system/appearance/header_logo/1/header.png",
  "favicon": "/uploads/-/system/appearance/favicon/1/favicon.png",
  "member_guidelines": "Custom member guidelines",
  "new_project_guidelines": "Please read the FAQs for help.",
  "profile_image_guidelines": "Custom profile image guidelines",
  "header_message": "",
  "footer_message": "",
  "message_background_color": "#e75e40",
  "message_font_color": "#ffffff",
  "email_header_and_footer_enabled": false,
  "site_name": "Production"
}
```

## Mettre à jour l'apparence de l'application {#update-application-appearance}

Met à jour la configuration de l'apparence de cette instance GitLab.

```plaintext
PUT /application/appearance
```

| Attribut                         | Type    | Obligatoire | Description |
|-----------------------------------|---------|----------|-------------|
| `title`                           | string  | non       | Titre de l'instance sur la page de connexion / d'inscription |
| `description`                     | string  | non       | Texte Markdown affiché sur la page de connexion / d'inscription |
| `pwa_name`                        | string  | non       | Nom complet de l'application web progressive (Progressive Web App). Utilisé pour l'attribut `name` dans `manifest.json`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) dans GitLab 15.8. |
| `pwa_short_name`                  | string  | non       | Nom abrégé de l'application web progressive (Progressive Web App). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) dans GitLab 15.8. |
| `pwa_description`                 | string  | non       | Une explication de ce que fait l'application web progressive (Progressive Web App). Utilisé pour l'attribut `description` dans `manifest.json`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) dans GitLab 15.8. |
| `pwa_icon`                        | mixte   | non       | Icône utilisée pour l'application web progressive (Progressive Web App). Consultez [Mettre à jour le logo de l'application](#update-application-logo). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) dans GitLab 15.8. |
| `logo`                            | mixte   | non       | Image de l'instance utilisée sur la page de connexion / d'inscription. Consultez [Mettre à jour le logo de l'application](#update-application-logo) |
| `header_logo`                     | mixte   | non       | Image de l'instance utilisée pour la barre de navigation principale |
| `favicon`                         | mixte   | non       | Favicon de l'instance au format `.ico` ou `.png` |
| `member_guidelines`               | string  | non       | Texte Markdown affiché sur la page des membres du groupe ou du projet pour les utilisateurs ayant la permission de modifier les membres |
| `new_project_guidelines`          | string  | non       | Texte Markdown affiché sur la page du nouveau projet |
| `profile_image_guidelines`        | string  | non       | Texte Markdown affiché sur la page de profil sous l'avatar public |
| `header_message`                  | string  | non       | Message dans la barre d'en-tête du système |
| `footer_message`                  | string  | non       | Message dans la barre de pied de page du système |
| `message_background_color`        | string  | non       | Couleur d'arrière-plan de la barre d'en-tête / pied de page du système |
| `message_font_color`              | string  | non       | Couleur de la police pour la barre d'en-tête / pied de page du système |
| `email_header_and_footer_enabled` | boolean | non       | Ajoute un en-tête et un pied de page à tous les e-mails sortants si activé |
| `site_name`                       | string  | non       | Ajoute un nom de site après le titre de la page. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/appearance?email_header_and_footer_enabled=true&header_message=test"
```

Exemple de réponse :

```json
{
  "title": "GitLab Test Instance",
  "description": "gitlab-test.example.com",
  "pwa_name": "GitLab PWA",
  "pwa_short_name": "GitLab",
  "pwa_description": "GitLab as PWA",
  "pwa_icon": "/uploads/-/system/appearance/pwa_icon/1/pwa_logo.png",
  "logo": "/uploads/-/system/appearance/logo/1/logo.png",
  "header_logo": "/uploads/-/system/appearance/header_logo/1/header.png",
  "favicon": "/uploads/-/system/appearance/favicon/1/favicon.png",
  "member_guidelines": "Custom member guidelines",
  "new_project_guidelines": "Please read the FAQs for help.",
  "profile_image_guidelines": "Custom profile image guidelines",
  "header_message": "test",
  "footer_message": "",
  "message_background_color": "#e75e40",
  "message_font_color": "#ffffff",
  "email_header_and_footer_enabled": true,
  "site_name": ""
}
```

## Mettre à jour le logo de l'application {#update-application-logo}

Met à jour le logo de cette instance GitLab avec un fichier image inclus.

Pour téléverser un avatar depuis votre système de fichiers local, utilisez l'argument `--form` pour inclure le fichier. Cela amène cURL à publier des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `file=` doit pointer vers un fichier image sur votre système de fichiers et être précédé de `@`.

```plaintext
PUT /application/appearance
```

| Attribut  | Type  | Obligatoire | Description |
|------------|-------|----------|-------------|
| `logo`     | mixte | Oui      | Image utilisée comme logo. |
| `pwa_icon` | mixte | Oui      | Image utilisée pour l'application web progressive (Progressive Web App). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) dans GitLab 15.8. |

Exemple de requête :

```shell
curl --location --request PUT \
  --url "https://gitlab.example.com/api/v4/application/appearance?data=image/png" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: multipart/form-data" \
  --form "logo=@/path/to/logo.png"
```

Exemple de réponse :

```json
{
  "logo":"/uploads/-/system/appearance/logo/1/logo.png"
}
```
