---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Apprenez à convertir la variable CI/CD `CI_JOB_JWT` dépréciée en jetons d'ID"
title: 'Tutoriel : Mettre à jour la configuration HashiCorp Vault pour utiliser les jetons d''ID'
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> À partir de Vault 1.17, [la connexion JWT auth nécessite des audiences liées sur le rôle](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role) lorsque le JWT contient une revendication `aud`. La revendication `aud` peut être une chaîne unique ou une liste de chaînes.

Ce tutoriel montre comment convertir votre configuration de secrets CI/CD existante pour utiliser les [jetons d'ID](id_token_authentication.md).

Les variables CI/CD `CI_JOB_JWT` sont dépréciées, mais la mise à jour vers les jetons d'ID nécessite des modifications de configuration importantes pour fonctionner avec Vault. Si vous avez plus d'une poignée de jobs, tout convertir en une seule fois est une tâche intimidante.

Il n'existe pas de méthode standard unique pour migrer vers les [jetons d'ID](id_token_authentication.md), c'est pourquoi ce tutoriel présente deux variantes pour convertir vos secrets CI/CD existants. Choisissez la méthode la plus adaptée à votre cas d'utilisation :

1. Mettez à jour votre configuration Vault :
   - Méthode A : Migrer les rôles JWT vers la nouvelle méthode d'authentification Vault
     1. [Créer un second chemin d'authentification JWT dans Vault](#create-a-second-jwt-authentication-path-in-vault)
     1. [Recréer les rôles pour utiliser le nouveau chemin d'authentification](#recreate-roles-to-use-the-new-authentication-path)
   - Méthode B : Déplacer la revendication `iss` vers les rôles pour la fenêtre de migration
     1. [Ajouter la carte de revendications `bound_issuers` à chaque rôle](#add-bound_issuers-claim-map-to-each-role)
     1. [Supprimer la revendication `bound_issuers` de la méthode d'authentification](#remove-bound_issuers-claim-from-auth-method)
1. [Mettre à jour vos jobs CI/CD](#update-your-cicd-jobs)

## Prérequis {#prerequisites}

Ce tutoriel suppose que vous êtes familier avec GitLab CI/CD et Vault.

Pour suivre ce tutoriel, vous devez disposer des éléments suivants :

- Une instance exécutant GitLab 16.0 ou une version ultérieure, ou être sur GitLab.com.
- Un serveur Vault que vous utilisez déjà.
- Des jobs CI/CD récupérant des secrets depuis Vault avec `CI_JOB_JWT`.

Dans les exemples suivants, remplacez :

- `vault.example.com` par l'URL de votre serveur Vault.
- `gitlab.example.com` par l'URL de votre instance GitLab.
- `jwt` ou `jwt_v2` par vos noms de méthodes d'authentification.

## Méthode A : Migrer les rôles JWT vers la nouvelle méthode d'authentification Vault {#method-a-migrate-jwt-roles-to-the-new-vault-auth-method}

Cette méthode crée une seconde méthode d'authentification JWT en parallèle de celle existante en cours d'utilisation. Ensuite, tous les rôles Vault utilisés pour l'intégration GitLab sont recréés dans cette nouvelle méthode d'authentification.

### Créer un second chemin d'authentification JWT dans Vault {#create-a-second-jwt-authentication-path-in-vault}

Dans le cadre de la transition de `CI_JOB_JWT` vers les jetons d'ID, vous devez mettre à jour `bound_issuer` dans Vault pour inclure `https://` :

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

Après avoir effectué cette modification, les jobs qui utilisent `CI_JOB_JWT` commencent à échouer.

Vous pouvez créer plusieurs chemins d'authentification dans Vault, ce qui vous permet de passer aux jetons d'ID par projet et par job sans interruption.

1. Configurez un nouveau chemin d'authentification avec le nom `jwt_v2`, exécutez :

   ```shell
   vault auth enable -path jwt_v2 jwt
   ```

   Vous pouvez choisir un nom différent, mais le reste de ces exemples suppose que vous avez utilisé `jwt_v2`, donc mettez à jour les exemples selon vos besoins.

1. Configurez le nouveau chemin d'authentification pour votre instance :

   ```shell
   $ vault write auth/jwt_v2/config \
       oidc_discovery_url="https://gitlab.example.com" \
       bound_issuer="https://gitlab.example.com"
   ```

### Recréer les rôles pour utiliser le nouveau chemin d'authentification {#recreate-roles-to-use-the-new-authentication-path}

Les rôles sont liés à un chemin d'authentification spécifique, vous devez donc ajouter de nouveaux rôles pour chaque job. Le paramètre `bound_audiences` pour le rôle est obligatoire si le JWT contient une audience et doit correspondre à au moins une des revendications `aud` associées du JWT.

1. Recréez le rôle pour l'environnement de staging nommé `myproject-staging` :

   ```shell
   $ vault write auth/jwt_v2/role/myproject-staging - <<EOF
   {
     "role_type": "jwt",
     "policies": ["myproject-staging"],
     "token_explicit_max_ttl": 60,
     "user_claim": "user_email",
     "bound_audiences": ["https://vault.example.com"],
     "bound_claims": {
       "project_id": "22",
       "ref": "master",
       "ref_type": "branch"
     }
   }
   EOF
   ```

1. Recréez le rôle pour la production nommé `myproject-production` :

   ```shell
   $ vault write auth/jwt_v2/role/myproject-production - <<EOF
   {
     "role_type": "jwt",
     "policies": ["myproject-production"],
     "token_explicit_max_ttl": 60,
     "user_claim": "user_email",
     "bound_audiences": ["https://vault.example.com"],
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

Vous devez uniquement mettre à jour `jwt` en `jwt_v2` dans la commande `vault`, ne modifiez pas `role_type` à l'intérieur du rôle.

## Méthode B : Déplacer la revendication `iss` vers les rôles pour la fenêtre de migration {#method-b-move-iss-claim-to-roles-for-migration-window}

Cette méthode ne nécessite pas que les administrateurs Vault créent une seconde méthode d'authentification JWT et recréent tous les rôles liés à GitLab.

### Ajouter la carte de revendications `bound_issuers` à chaque rôle {#add-bound_issuers-claim-map-to-each-role}

Vault n'autorise pas plusieurs revendications `iss` au niveau de la méthode d'authentification JWT, car la directive [`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer) à ce niveau n'accepte qu'une seule valeur. Cependant, plusieurs revendications peuvent être configurées au niveau du rôle en utilisant la directive de configuration de carte [`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims).

Avec cette méthode, vous pouvez fournir à Vault plusieurs options pour la validation de la revendication `iss`. Cela prend en charge la revendication de nom d'hôte de l'instance GitLab préfixée par `https://` qui accompagne les `id_tokens`, ainsi que l'ancienne revendication sans préfixe.

Pour ajouter la configuration [`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims) aux rôles requis, exécutez :

```shell
$ vault write auth/jwt/role/myproject-staging - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-staging"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": ["https://vault.example.com"],
  "bound_claims": {
    "iss": [
      "https://gitlab.example.com",
      "gitlab.example.com"
    ],
    "project_id": "22",
    "ref": "master",
    "ref_type": "branch"
  }
}
EOF
```

Vous n'avez pas besoin de modifier les configurations de rôles existantes, à l'exception de la section `bound_claims`. Veillez à ajouter la configuration `iss` comme indiqué précédemment, pour garantir que Vault accepte la revendication `iss` avec et sans préfixe pour ce rôle.

Vous devez appliquer cette modification à tous les rôles JWT utilisés pour l'intégration GitLab avant de passer à l'étape suivante.

Vous pouvez annuler la migration de la validation de la revendication `iss` depuis la méthode d'authentification vers les rôles si vous le souhaitez, une fois que tous les projets ont été migrés et que vous n'avez plus besoin d'une prise en charge parallèle de `CI_JOB_JWT` et des jetons d'ID.

### Supprimer la revendication `bound_issuers` de la méthode d'authentification {#remove-bound_issuers-claim-from-auth-method}

Une fois que tous les rôles ont été mis à jour avec les revendications `bound_claims.iss`, vous pouvez supprimer la configuration au niveau de la méthode d'authentification pour cette validation :

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer=""
```

Définir la directive `bound_issuer` sur une chaîne vide supprime la validation de l'émetteur au niveau de la méthode d'authentification. Cependant, étant donné que cette validation se situe désormais au niveau du rôle, la configuration reste sécurisée.

## Mettre à jour vos jobs CI/CD {#update-your-cicd-jobs}

Vault dispose de deux [moteurs de secrets KV](https://developer.hashicorp.com/vault/docs/secrets/kv) différents et la version que vous utilisez a un impact sur la manière dont vous définissez les secrets en CI/CD.

Consultez l'article [Which Version is my Vault KV Mount?](https://support.hashicorp.com/hc/en-us/articles/4404288741139-Which-Version-is-my-Vault-KV-Mount) sur le portail d'assistance de HashiCorp pour vérifier votre serveur Vault.

De plus, si nécessaire, vous pouvez consulter la documentation CI/CD pour :

- [`secrets:`](../yaml/_index.md#secrets)
- [`id_tokens:`](../yaml/_index.md#id_tokens)

Les exemples suivants montrent comment obtenir le mot de passe de la base de données de staging écrit dans le champ `password` dans `secret/myproject/staging/db`.

La valeur de la variable CI/CD `VAULT_AUTH_PATH` dépend de la méthode de migration que vous avez utilisée :

- Méthode A (Migrer les rôles JWT vers la nouvelle méthode d'authentification Vault) : Utilisez `jwt_v2`.
- Méthode B (Déplacer la revendication `iss` vers les rôles pour la fenêtre de migration) : Utilisez `jwt`.

### KV Secrets Engine v1 {#kv-secrets-engine-v1}

Le mot-clé [`secrets:vault`](../yaml/_index.md#secretsvault) utilise par défaut la version v2 du montage KV, vous devez donc configurer explicitement le job pour utiliser le moteur v1 :

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    PASSWORD:
      vault:
        engine:
          name: kv-v1
          path: secret
        field: password
        path: myproject/staging/db
      file: false
```

`VAULT_SERVER_URL` et `VAULT_AUTH_PATH` peuvent être [définis en tant que variables CI/CD de projet ou de groupe](../variables/_index.md#define-a-cicd-variable-in-the-ui), si vous le préférez.

[`secrets:file`](../yaml/_index.md#secretsfile) est défini sur `false` car les jetons d'ID placent les secrets dans un fichier par défaut et il doit fonctionner comme une variable CI/CD ordinaire pour correspondre à l'ancien comportement.

### KV Secrets Engine v2 {#kv-secrets-engine-v2}

Il existe deux formats que vous pouvez utiliser pour le moteur v2.

Format long :

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    PASSWORD:
      vault:
        engine:
          name: kv-v2
          path: secret
        field: password
        path: myproject/staging/db
      file: false
```

Il s'agit du même exemple que pour le moteur v1, mais `secrets:vault:engine:name:` est défini sur `kv-v2` pour correspondre au moteur.

Vous pouvez également utiliser un format court :

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
      PASSWORD:
        vault: myproject/staging/db/password@secret
        file: false
```

Une fois que vous avez commité la configuration CI/CD mise à jour, vos jobs récupèrent les secrets avec des jetons d'ID. Félicitations !

Si vous avez migré tous les projets pour récupérer les secrets avec des jetons d'ID et utilisé la méthode B pour la migration, il est désormais possible de déplacer la validation de la revendication `iss` vers la configuration de la méthode d'authentification si vous le souhaitez.
