---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Noms de projets et de groupes réservés
description: "Conventions de nommage, restrictions et noms réservés."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour éviter tout conflit avec les routes existantes utilisées par GitLab, certains mots ne peuvent pas être utilisés comme noms de projet ou de groupe. Ces mots sont répertoriés dans le [`path_regex.rb` fichier](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/path_regex.rb), où :

- `TOP_LEVEL_ROUTES` désigne les noms réservés aux noms d'utilisateur ou aux groupes principaux.
- `PROJECT_WILDCARD_ROUTES` désigne les noms réservés aux sous-groupes ou aux projets.
- `GROUP_ROUTES` désigne les noms réservés à tous les groupes ou projets.

## Règles pour les noms d'utilisateur, les noms de projet et de groupe, et les slugs {#rules-for-usernames-project-and-group-names-and-slugs}

Les noms d'utilisateur doivent commencer et se terminer par une lettre (`a-zA-Z`) ou un chiffre (`0-9`). Par exemple, les noms d'utilisateur suivants répondent à ces critères :

- `A_Garcia`
- `a_garcia_1`

De plus, les noms d'utilisateur et les noms de groupe ne doivent contenir que des lettres (`a-zA-Z`), des chiffres (`0-9`), des emoji, des traits de soulignement (`_`), des points (`.`), des parenthèses (`()`), des tirets (`-`) ou des espaces. Par exemple :

- Nom d'utilisateur valide : `sidney.jones` ou `sidney ⭐ jones`
- Nom de groupe valide : `Web Development Team (Frontend)`

Les noms de projet ne doivent contenir que des lettres (`a-zA-Z`), des chiffres (`0-9`), des emoji, des traits de soulignement (`_`), des points (`.`), des signes plus (`+`), des tirets (`-`) ou des espaces. Par exemple :

- `web-app-v2+features`
- `web-analytics-dashboard`
- `Backend API Service 🚀`

Noms d'utilisateur et slugs de projet ou de groupe :

- Doivent commencer et se terminer par une lettre (`a-zA-Z`) ou un chiffre (`0-9`).
- Ne doivent pas contenir de caractères spéciaux consécutifs.
- Ne peuvent pas se terminer par `.git` ou `.atom`.
- Ne doivent contenir que des lettres (`a-zA-Z`), des chiffres (`0-9`), des traits de soulignement (`_`), des points (`.`) ou des tirets (`-`).

Exemples de slugs de nom d'utilisateur valides :

- `dev_user_1`
- `zhang.wei-2024`
- `maria.lopez`

Exemples de slugs de projet valides :

- `api.service.v2`
- `user_management_portal`
- `docs_site_v3`

Exemples de slugs de groupe valides :

- `marketing-team-2024`
- `backend.services`
- `mobile-dev-team`

## Noms de projet réservés {#reserved-project-names}

Vous ne pouvez pas créer de projets avec les noms suivants :

- `\-`
- `badges`
- `blame`
- `blob`
- `builds`
- `commits`
- `create`
- `create_dir`
- `edit`
- `environments/folders`
- `files`
- `find_file`
- `gitlab-lfs/objects`
- `info/lfs/objects`
- `new`
- `preview`
- `raw`
- `refs`
- `tree`
- `update`
- `wikis`

## Noms de groupe réservés {#reserved-group-names}

Vous ne pouvez pas créer de groupes avec les noms suivants, car ils sont réservés aux groupes principaux :

- `\-`
- `.well-known`
- `404.html`
- `422.html`
- `500.html`
- `502.html`
- `503.html`
- `admin`
- `api`
- `apple-touch-icon.png`
- `assets`
- `dashboard`
- `deploy.html`
- `explore`
- `favicon.ico`
- `favicon.png`
- `files`
- `groups`
- `health_check`
- `help`
- `import`
- `jwt`
- `login`
- `oauth`
- `profile`
- `projects`
- `public`
- `robots.txt`
- `s`
- `search`
- `sitemap`
- `sitemap.xml`
- `sitemap.xml.gz`
- `slash-command-logo.png`
- `snippets`
- `unsubscribes`
- `uploads`
- `users`
- `v2`

Vous ne pouvez pas créer de sous-groupes avec les noms suivants :

- `\-`
