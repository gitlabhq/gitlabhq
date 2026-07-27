---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : Authentification et lecture de secrets avec HashiCorp Vault'
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce tutoriel montre comment authentifier, configurer et lire des secrets avec HashiCorp Vault depuis GitLab CI/CD.

## Prérequis {#prerequisites}

Ce tutoriel suppose que vous êtes familier avec GitLab CI/CD et Vault.

Pour suivre ce tutoriel, vous devez disposer des éléments suivants :

- Un compte sur GitLab.
- Un accès à un serveur Vault en cours d'exécution (au moins v1.2.0) pour configurer l'authentification et créer des rôles et des politiques. Pour HashiCorp Vault, il peut s'agir de la version Open Source ou Enterprise.

> [!note]
> Vous devez remplacer l'URL `vault.example.com` dans l'exemple suivant par l'URL de votre serveur Vault, et `gitlab.example.com` par l'URL de votre instance GitLab.

## Configurer le vault {#configure-the-vault}

> [!warning]
> Les JWT sont des identifiants pouvant accorder l'accès à des ressources. Faites attention à l'endroit où vous les collez !

Imaginez un scénario dans lequel vous stockez des mots de passe pour vos bases de données de staging et de production dans un serveur Vault. Ce scénario suppose que vous utilisez le moteur de secrets [KV v2](https://developer.hashicorp.com/vault/docs/secrets/kv#kv-version-2). Si vous utilisez [KV v1](https://developer.hashicorp.com/vault/docs/secrets/kv#version-comparison), supprimez `/data/` des chemins de politique suivants et consultez [comment configurer vos jobs CI/CD](convert-to-id-tokens.md#kv-secrets-engine-v1).

Vous pouvez récupérer les mots de passe avec la commande `vault kv get`.

```shell
$ vault kv get -field=password secret/myproject/staging/db
pa$$w0rd

$ vault kv get -field=password secret/myproject/production/db
real-pa$$w0rd
```

Votre mot de passe de staging est `pa$$w0rd`, et votre mot de passe de production est `real-pa$$w0rd`.

Pour configurer votre serveur Vault, commencez par activer la méthode [JWT Auth](https://developer.hashicorp.com/vault/docs/auth/jwt) :

```shell
$ vault auth enable jwt
Success! Enabled jwt auth method at: jwt/
```

Créez ensuite des politiques qui vous permettent de lire ces secrets (une pour chaque secret) :

```shell
$ vault policy write myproject-staging - <<EOF
# Policy name: myproject-staging
#
# Read-only permission on 'secret/data/myproject/staging/*' path
path "secret/data/myproject/staging/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-staging

$ vault policy write myproject-production - <<EOF
# Policy name: myproject-production
#
# Read-only permission on 'secret/data/myproject/production/*' path
path "secret/data/myproject/production/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-production
```

Vous avez également besoin de rôles qui relient le JWT à ces politiques.

Par exemple, un rôle pour le staging nommé `myproject-staging`. Les [bound claims](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims) sont configurés pour n'autoriser l'utilisation de la politique que pour la branche `main` dans le projet avec l'ID `22` :

```json
$ vault write auth/jwt/role/myproject-staging - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-staging"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": "https://vault.example.com",
  "bound_claims": {
    "project_id": "22",
    "ref": "main",
    "ref_type": "branch"
  }
}
EOF
```

Et un rôle pour la production nommé `myproject-production`. La section `bound_claims` de ce rôle n'autorise l'accès aux secrets qu'aux branches protégées correspondant au modèle `auto-deploy-*`.

```json
$ vault write auth/jwt/role/myproject-production - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-production"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": "https://vault.example.com",
  "bound_claims_type": "glob",
  "bound_claims": {
    "project_id": "22",
    "ref_protected": "true",
    "ref_type": "branch",
    "ref": "auto-deploy-*"
  }
}
EOF
```

Combiné avec les [branches protégées](../../user/project/repository/branches/protected.md), vous pouvez restreindre les personnes autorisées à s'authentifier et à lire les secrets.

N'importe lequel des claims [inclus dans le JWT](id_token_authentication.md#token-payload) peut être comparé à une liste de valeurs dans les bound claims. Par exemple :

```json
"bound_claims": {
  "user_login": ["alice", "bob", "mallory"]
}

"bound_claims": {
  "ref": ["main", "develop", "test"]
}

"bound_claims": {
  "namespace_id": ["10", "20", "30"]
}

"bound_claims": {
  "project_id": ["12", "22", "37"]
}
```

- Si seul `namespace_id` est utilisé, tous les projets de l'espace de nommage sont autorisés. Les projets imbriqués ne sont pas inclus, leurs ID d'espace de nommage doivent donc également être ajoutés à la liste si nécessaire.
- Si `namespace_id` et `project_id` sont tous deux utilisés, Vault vérifie d'abord si l'espace de nommage du projet est dans `namespace_id`, puis vérifie si le projet est dans `project_id`.

[`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl) spécifie que le jeton émis par Vault, après une authentification réussie, a une durée de vie maximale absolue de 60 secondes.

[`user_claim`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#user_claim) spécifie le nom de l'alias d'identité créé par Vault lors d'une connexion réussie.

[`bound_claims_type`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims_type) configure l'interprétation des valeurs `bound_claims`. Si la valeur est `glob`, les valeurs sont interprétées comme des globs, avec `*` correspondant à n'importe quel nombre de caractères.

Les [champs de claim](id_token_authentication.md#token-payload) sont également accessibles à des fins de [création de modèles de chemins de politique de Vault](https://developer.hashicorp.com/vault/tutorials/policies/policy-templating?in=vault%2Fpolicies) en utilisant le nom d'accesseur de l'authentification JWT dans Vault. Le [nom d'accesseur de montage](https://developer.hashicorp.com/vault/tutorials/auth-methods/identity#step-1-create-an-entity-with-alias) (`ACCESSOR_NAME` dans l'exemple suivant) peut être récupéré en exécutant `vault auth list`.

Exemple de modèle de politique utilisant un champ de métadonnées nommé `project_path` :

```plaintext
path "secret/data/{{identity.entity.aliases.ACCESSOR_NAME.metadata.project_path}}/staging/*" {
  capabilities = [ "read" ]
}
```

Exemple de rôle prenant en charge la politique précédente basée sur un modèle, qui mappe le champ de claim `project_path` en tant que champ de métadonnées via la configuration [`claim_mappings`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#claim_mappings) :

```json
{
  "role_type": "jwt",
  ...
  "claim_mappings": {
    "project_path": "project_path"
  }
}
```

Pour la liste complète des options, consultez la [documentation Create Role](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role) de Vault.

> [!warning]
> Limitez toujours vos rôles à un projet ou à un espace de nommage en utilisant l'un des claims fournis (par exemple, `project_id` ou `namespace_id`). Sinon, tout JWT généré par cette instance pourrait être autorisé à s'authentifier à l'aide de ce rôle.

À présent, configurez la méthode d'authentification JWT :

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

[`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer) spécifie que seul un JWT dont l'émetteur (c'est-à-dire le claim `iss`) est défini sur `gitlab.example.com` peut utiliser cette méthode pour s'authentifier, et que `oidc_discovery_url` (`https://gitlab.example.com`) doit être utilisé pour valider le jeton.

Pour la liste complète des options de configuration disponibles, consultez la [documentation de l'API](https://developer.hashicorp.com/vault/api-docs/auth/jwt#configure) de Vault.

Dans GitLab, créez les [variables CI/CD](../variables/_index.md#for-a-project) suivantes pour fournir des informations sur votre serveur Vault :

- `VAULT_SERVER_URL` : L'URL de votre serveur Vault, par exemple `https://vault.example.com:8200`.
- `VAULT_AUTH_ROLE` : Facultatif. Nom du rôle JWT Auth de Vault à utiliser lors des tentatives d'authentification. Dans ce tutoriel, vous avez déjà créé deux rôles avec les noms `myproject-staging` et `myproject-production`. Si aucun rôle n'est spécifié, Vault utilise le [rôle par défaut](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role) défini lors de la configuration de la méthode d'authentification.
- `VAULT_AUTH_PATH` : Facultatif. Le chemin où la méthode d'authentification est montée. La valeur par défaut est `jwt`.
- `VAULT_NAMESPACE` : Facultatif. L'[espace de nommage Vault Enterprise](https://developer.hashicorp.com/vault/docs/enterprise/namespaces) à utiliser pour la lecture des secrets et l'authentification. Si aucun espace de nommage n'est spécifié, Vault utilise le namespace racine (`/`). Ce paramètre est ignoré par Vault Open Source.

## Authentification automatique par jeton d'ID {#automatic-id-token-authentication}

Le job suivant, lorsqu'il est exécuté pour la branche par défaut, peut lire les secrets sous `secret/myproject/staging/`, mais pas les secrets sous `secret/myproject/production/` :

```yaml
job_with_secrets:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    STAGING_DB_PASSWORD:
      vault: myproject/staging/db/password@secret  # translates to a path of 'secret/myproject/staging/db' and field 'password'. Authenticates using $VAULT_ID_TOKEN.
  script:
    - access-staging-db.sh --token $STAGING_DB_PASSWORD
```

Dans cet exemple :

- `id_tokens` : le JSON Web Token (JWT) utilisé pour l'authentification OIDC. Le claim `aud` est défini pour correspondre au paramètre `bound_audiences` du `role` utilisé pour la méthode d'authentification JWT de Vault.
- `@secret` : le nom du vault, où vos moteurs de secrets sont activés.
- `myproject/staging/db` : l'emplacement du chemin du secret dans Vault.
- `password` : le champ à récupérer dans le secret référencé.

Si plusieurs jetons d'ID sont définis, utilisez le mot-clé `token` pour spécifier quel jeton doit être utilisé. Par exemple :

```yaml
job_with_secrets:
  id_tokens:
    FIRST_ID_TOKEN:
      aud: https://first.service.com
    SECOND_ID_TOKEN:
      aud: https://second.service.com
  secrets:
    FIRST_DB_PASSWORD:
      vault: first/db/password
      token: $FIRST_ID_TOKEN
    SECOND_DB_PASSWORD:
      vault: second/db/password
      token: $SECOND_ID_TOKEN
  script:
    - access-first-db.sh --token $FIRST_DB_PASSWORD
    - access-second-db.sh --token $SECOND_DB_PASSWORD
```

> [!note]
> À partir de Vault 1.17, [la connexion JWT auth nécessite des audiences liées sur le rôle](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role) lorsque le JWT contient une revendication `aud`. La revendication `aud` peut être une chaîne unique ou une liste de chaînes.

### Authentification manuelle {#manual-authentication}

Vous pouvez utiliser des jetons d'ID pour vous authentifier manuellement avec HashiCorp Vault. Par exemple :

```yaml
manual_authentication:
  variables:
    VAULT_ADDR: http://vault.example.com:8200
  image: vault:latest
  id_tokens:
    VAULT_ID_TOKEN:
      aud: http://vault.example.com
  script:
    - export VAULT_TOKEN="$(vault write -field=token auth/jwt/login role=myproject-example jwt=$VAULT_ID_TOKEN)"
    - export PASSWORD="$(vault kv get -field=password secret/myproject/example/db)"
    - my-authentication-script.sh $VAULT_TOKEN $PASSWORD
```

## Limiter l'accès des jetons aux secrets Vault {#limit-token-access-to-vault-secrets}

Vous pouvez contrôler l'accès des jetons d'ID aux secrets Vault en utilisant les protections de Vault et les fonctionnalités de GitLab. Par exemple, restreignez le jeton en :

- Utilisant les [audiences liées](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-audiences) de Vault pour les claims `aud` de jetons d'ID spécifiques.
- Utilisant les [bound claims](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims) de Vault pour des groupes spécifiques à l'aide de `group_claim`.
- Codant en dur des valeurs pour les bound claims de Vault basées sur `user_login` et `user_email` d'utilisateurs spécifiques.
- Définissant des limites de temps Vault pour le TTL du jeton, tel que spécifié dans [`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl), où le jeton expire après l'authentification.
- Limitant le JWT aux [branches protégées GitLab](../../user/project/repository/branches/protected.md) qui sont restreintes à un sous-ensemble d'utilisateurs du projet.
- Limitant le JWT aux [tags protégés GitLab](../../user/project/protected_tags.md), qui sont restreints à un sous-ensemble d'utilisateurs du projet.

## Dépannage {#troubleshooting}

### Message `The secrets provider can not be found. Check your CI/CD variables and try again.` {#the-secrets-provider-can-not-be-found-check-your-cicd-variables-and-try-again-message}

Vous pouvez recevoir cette erreur lorsque vous tentez de démarrer un job configuré pour accéder à HashiCorp Vault :

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

Le job ne peut pas être créé car la variable CI/CD requise n'est pas définie :

- `VAULT_SERVER_URL`

### Erreur `api error: status code 400: missing role` {#api-error-status-code-400-missing-role-error}

Vous pouvez recevoir une erreur `missing role` lorsque vous tentez de démarrer un job configuré pour accéder à HashiCorp Vault. L'erreur peut être due au fait que la variable CI/CD `VAULT_AUTH_ROLE` n'est pas définie, ce qui empêche le job de s'authentifier auprès du serveur Vault.

### Erreur `audience claim does not match any expected audience` {#audience-claim-does-not-match-any-expected-audience-error}

Si les valeurs du claim `aud:` du jeton d'ID spécifié dans le fichier YAML et le paramètre `bound_audiences` du `role` utilisé pour l'authentification JWT ne correspondent pas, vous pouvez obtenir cette erreur :

`invalid audience (aud) claim: audience claim does not match any expected audience`

Assurez-vous que ces valeurs sont identiques.
