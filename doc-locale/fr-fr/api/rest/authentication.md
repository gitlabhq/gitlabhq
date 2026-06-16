---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Authentifiez-vous auprès de l'API REST GitLab à l'aide d'OAuth 2.0, de jetons d'accès et de jobs."
title: "Authentification à l'API REST"
---

La plupart des requêtes d'API nécessitent une authentification, ou ne renvoient que des données publiques lorsque l'authentification n'est pas fournie. Lorsque l'authentification n'est pas requise, la documentation de chaque endpoint le précise. Par exemple, [l'endpoint `/projects/:id`](../projects.md#retrieve-a-project) ne nécessite pas d'authentification.

Vous pouvez vous authentifier auprès de l'API REST GitLab de plusieurs façons :

- [Jetons OAuth 2.0](#oauth-20-tokens)
- [Jetons d'accès personnels](../../user/profile/personal_access_tokens.md)
- [Jetons d'accès au projet](../../user/project/settings/project_access_tokens.md)
- [Jetons d'accès de groupe](../../user/group/settings/group_access_tokens.md)
- [Cookie de session](#session-cookie)
- [Jetons de job CI/CD](#job-tokens) (endpoints spécifiques uniquement)

Les jetons d'accès au projet sont pris en charge par :

- GitLab Self-Managed :  Free, Premium et Ultimate.
- GitLab.com :  Premium et Ultimate.

Si vous êtes administrateur, vous ou votre application pouvez vous authentifier en tant qu'utilisateur spécifique, en utilisant l'une ou l'autre des méthodes suivantes :

- [Jetons d'usurpation d'identité](#impersonation-tokens)
- [Sudo](#sudo)

Si les informations d'authentification ne sont pas valides ou sont manquantes, GitLab renvoie un message d'erreur avec un code de statut `401` :

```json
{
  "message": "401 Unauthorized"
}
```

> [!note]
> Les jetons de déploiement ne peuvent pas être utilisés avec l'API publique GitLab. Pour plus de détails, consultez [Jetons de déploiement](../../user/project/deploy_tokens/_index.md).

## Jetons OAuth 2.0 {#oauth-20-tokens}

Vous pouvez utiliser un [jeton OAuth 2.0](../oauth2.md) pour vous authentifier auprès de l'API en le transmettant dans le paramètre `access_token` ou dans l'en-tête `Authorization`.

Exemple d'utilisation du jeton OAuth 2.0 dans un paramètre :

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects?access_token=OAUTH-TOKEN"
```

Exemple d'utilisation du jeton OAuth 2.0 dans un en-tête :

```shell
curl --request GET \
  --header "Authorization: Bearer OAUTH-TOKEN" \
  --url "https://gitlab.example.com/api/v4/projects"
```

En savoir plus sur [GitLab en tant que fournisseur OAuth 2.0](../oauth2.md).

> [!note]
> Tous les jetons d'accès OAuth sont valables deux heures après leur création. Vous pouvez utiliser le paramètre `refresh_token` pour actualiser les jetons. Consultez la documentation sur le [jeton OAuth 2.0](../oauth2.md) pour savoir comment demander un nouveau jeton d'accès à l'aide d'un jeton d'actualisation.

## Jetons d'accès personnels, de projet et de groupe {#personal-project-and-group-access-tokens}

Vous pouvez utiliser des jetons d'accès pour vous authentifier auprès de l'API. Transmettez le jeton en utilisant l'en-tête `PRIVATE-TOKEN` (recommandé) ou d'autres méthodes.

Par exemple, en utilisant la méthode d'en-tête recommandée :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects"
```

Vous pouvez également utiliser des jetons d'accès personnels, de projet ou de groupe avec des en-têtes conformes à OAuth. Par exemple :

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects"
```

## Jetons de job {#job-tokens}

Vous pouvez utiliser des jetons de job pour vous authentifier auprès d'[endpoints d'API spécifiques](../../ci/jobs/ci_job_token.md#job-token-access). Dans les jobs GitLab CI/CD, le jeton est disponible en tant que variable `CI_JOB_TOKEN`.

Transmettez le jeton en utilisant l'en-tête `JOB-TOKEN` (recommandé) ou d'autres méthodes. Pour toutes les méthodes d'authentification, consultez [Authentification par jeton de job CI/CD](../../ci/jobs/ci_job_token.md#rest-api-authentication).

Par exemple, en utilisant la méthode par en-tête :

```shell
curl --request GET \
  --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --url "https://gitlab.example.com/api/v4/projects/1/releases"
```

## Cookie de session {#session-cookie}

La connexion à l'application GitLab principale définit un cookie `_gitlab_session`. L'API utilise ce cookie pour l'authentification s'il est présent. L'utilisation de l'API pour générer un nouveau cookie de session n'est pas prise en charge.

L'utilisateur principal de cette méthode d'authentification est le frontend web de GitLab lui-même. Le frontend web peut utiliser l'API en tant qu'utilisateur authentifié pour obtenir une liste de projets sans transmettre explicitement un jeton d'accès.

## Jetons d'usurpation d'identité {#impersonation-tokens}

Les jetons d'usurpation d'identité sont un type de [jeton d'accès personnel](../../user/profile/personal_access_tokens.md). Ils peuvent être créés uniquement par un administrateur et sont utilisés pour s'authentifier auprès de l'API en tant qu'utilisateur spécifique.

Utilisez les jetons d'usurpation d'identité comme alternative à :

- Le mot de passe de l'utilisateur ou l'un de ses jetons d'accès personnels.
- La fonctionnalité [Sudo](#sudo). Le mot de passe ou le jeton de l'utilisateur ou de l'administrateur peut ne pas être connu, ou peut changer au fil du temps.

Pour plus de détails, consultez la documentation de l'[API des jetons utilisateur](../user_tokens.md#create-an-impersonation-token).

Les jetons d'usurpation d'identité s'utilisent exactement comme les jetons d'accès personnels classiques et peuvent être transmis dans le paramètre `private_token` ou dans l'en-tête `PRIVATE-TOKEN`.

### Désactiver l'usurpation d'identité {#disable-impersonation}

Par défaut, l'usurpation d'identité est activée. Pour désactiver l'usurpation d'identité :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez le fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['impersonation_enabled'] = false
   ```

1. Enregistrez le fichier, puis [reconfigurez](../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez le fichier `config/gitlab.yml` :

   ```yaml
   gitlab:
     impersonation_enabled: false
   ```

1. Enregistrez le fichier, puis [redémarrez](../../administration/restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

Pour réactiver l'usurpation d'identité, supprimez cette configuration et reconfigurez GitLab (installations avec le package Linux) ou redémarrez GitLab (installations compilées depuis les sources).

## Sudo {#sudo}

Toutes les requêtes d'API permettent d'effectuer une requête d'API comme si vous étiez un autre utilisateur, à condition d'être authentifié en tant qu'administrateur avec un jeton OAuth ou un jeton d'accès personnel ayant la portée `sudo`. Les requêtes d'API sont exécutées avec les permissions de l'utilisateur dont l'identité est usurpée.

En tant qu'[administrateur](../../user/permissions.md), transmettez le paramètre `sudo` via une chaîne de requête ou un en-tête avec l'ID ou le nom d'utilisateur (insensible à la casse) de l'utilisateur pour lequel vous souhaitez effectuer l'opération. S'il est transmis en tant qu'en-tête, le nom de l'en-tête doit être `Sudo`.

Si un jeton d'accès non administrateur est fourni, GitLab renvoie un message d'erreur avec un code de statut `403` :

```json
{
  "message": "403 Forbidden - Must be admin to use sudo"
}
```

Si un jeton d'accès sans la portée `sudo` est fourni, un message d'erreur est renvoyé avec un code de statut `403` :

```json
{
  "error": "insufficient_scope",
  "error_description": "The request requires higher privileges than provided by the access token.",
  "scope": "sudo"
}
```

Si l'ID ou le nom d'utilisateur sudo est introuvable, un message d'erreur est renvoyé avec un code de statut `404` :

```json
{
  "message": "404 User with ID or username '123' Not Found"
}
```

Exemple d'une requête d'API valide et d'une requête utilisant cURL avec une requête sudo, en fournissant un nom d'utilisateur :

```plaintext
GET /projects?private_token=<your_access_token>&sudo=username
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Sudo: username" \
  --url "https://gitlab.example.com/api/v4/projects"
```

Exemple d'une requête d'API valide et d'une requête utilisant cURL avec une requête sudo, en fournissant un ID :

```plaintext
GET /projects?private_token=<your_access_token>&sudo=23
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Sudo: 23" \
  --url "https://gitlab.example.com/api/v4/projects"
```
