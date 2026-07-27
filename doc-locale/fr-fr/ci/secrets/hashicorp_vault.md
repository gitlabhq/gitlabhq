---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Apprenez à utiliser les secrets HashiCorp Vault dans GitLab CI/CD, notamment l'authentification, la configuration de Vault, les politiques et les moteurs de secrets."
title: 'Utiliser les secrets HashiCorp Vault dans GitLab CI/CD'
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser les secrets HashiCorp Vault dans GitLab CI/CD. Utilisez les [jetons d'ID](id_token_authentication.md) pour [vous authentifier auprès de HashiCorp Vault](https://developer.hashicorp.com/vault/docs/auth/jwt#jwt-authentication).

Vous devez configurer votre serveur Vault avant de pouvoir utiliser des secrets Vault dans un job CI/CD. Le tutoriel [Authentification et lecture des secrets avec HashiCorp Vault](hashicorp_vault_tutorial.md) fournit plus de détails sur la configuration de Vault et l'authentification avec les jetons d'ID.

Dans les exemples suivants, remplacez `vault.example.com` par l'URL de votre serveur Vault et `gitlab.example.com` par l'URL de votre instance GitLab.

## Configurer votre serveur Vault {#configure-your-vault-server}

Pour configurer votre serveur Vault :

1. Activez la méthode d'authentification en exécutant ces commandes. Elles fournissent à votre serveur Vault l'[URL de découverte OIDC](https://openid.net/specs/openid-connect-discovery-1_0.html) de votre instance GitLab, afin que Vault puisse récupérer la clé de signature publique et vérifier le jeton JWT (JSON Web Token) lors de l'authentification :

   ```shell
   $ vault auth enable jwt

   $ vault write auth/jwt/config \
     oidc_discovery_url="https://gitlab.example.com" \
     bound_issuer="gitlab.example.com"
   ```

1. Configurez des politiques sur votre serveur Vault pour accorder ou interdire l'accès à certains chemins et opérations. Cet exemple accorde un accès en lecture à l'ensemble des secrets requis par votre environnement de production :

   ```shell
   vault policy write myproject-production - <<EOF
   # Read-only permission on 'ops/data/production/*' path

   path "ops/data/production/*" {
     capabilities = [ "read" ]
   }
   EOF
   ```

1. Configurez les [rôles sur votre serveur Vault](#configure-server-roles), en restreignant les rôles à un projet ou un espace de nommage.
1. Créez les [variables CI/CD](../variables/_index.md#for-a-project) suivantes pour fournir des informations sur votre serveur Vault :
   - `VAULT_SERVER_URL` : L'URL de votre serveur Vault, par exemple `https://vault.example.com:8200`.
   - `VAULT_AUTH_ROLE` : Facultatif. Le rôle à utiliser lors d'une tentative d'authentification. Si aucun rôle n'est spécifié, Vault utilise le [rôle par défaut](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role) défini lors de la configuration de la méthode d'authentification.
   - `VAULT_AUTH_PATH` : Facultatif. Le chemin où la méthode d'authentification est montée, la valeur par défaut est `jwt`.
   - `VAULT_NAMESPACE` : Facultatif. L'[espace de nommage Vault Enterprise](https://developer.hashicorp.com/vault/docs/enterprise/namespaces) à utiliser pour la lecture des secrets et l'authentification. Avec :
     - Vault : l'espace de nommage `root` (« `/` ») est utilisé lorsqu'aucun espace de nommage n'est spécifié.
     - Vault Open source : le paramètre est ignoré.
     - [HashiCorp Cloud Platform (HCP)](https://www.hashicorp.com/cloud) Vault : un espace de nommage est requis. HCP Vault utilise l'espace de nommage `admin` comme espace de nommage racine par défaut. Par exemple, `VAULT_NAMESPACE=admin`.

### Configurer les rôles du serveur {#configure-server-roles}

Lorsqu'un job CI/CD tente de s'authentifier, il spécifie un rôle. Vous pouvez utiliser les rôles pour regrouper différentes politiques. Si l'authentification réussit, ces politiques sont associées au jeton Vault résultant.

Les [revendications liées](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims) (Bound claims) sont des valeurs prédéfinies qui sont comparées aux revendications JWT. Avec les revendications liées, vous pouvez restreindre l'accès à des utilisateurs GitLab spécifiques, des projets spécifiques, ou même des jobs s'exécutant pour des références Git spécifiques. Vous pouvez avoir autant de revendications liées que nécessaire, mais elles doivent toutes correspondre pour que l'authentification réussisse.

En combinant les revendications liées avec des fonctionnalités GitLab telles que les [rôles utilisateurs](../../user/permissions.md) et les [branches protégées](../../user/project/repository/branches/protected.md), vous pouvez adapter ces règles à votre cas d'utilisation spécifique. Dans cet exemple, l'authentification est autorisée uniquement pour les jobs s'exécutant pour des tags protégés dont les noms correspondent au modèle utilisé pour les releases de production :

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
    "project_id": "42",
    "ref_protected": "true",
    "ref_type": "tag",
    "ref": "auto-deploy-*"
  }
}
EOF
```

> [!warning]
> Restreignez toujours vos rôles à un projet ou un espace de nommage en utilisant l'une des revendications fournies comme `project_id` ou `namespace_id`. Sans ces restrictions, tout JWT généré par cette instance GitLab peut être autorisé à s'authentifier à l'aide de ce rôle.

Pour une liste complète des revendications JWT de jetons d'ID, consultez le tutoriel [Utiliser les secrets HashiCorp Vault dans GitLab CI/CD](hashicorp_vault_tutorial.md).

Vous pouvez également spécifier certains attributs pour les jetons Vault résultants, tels que la durée de vie, la plage d'adresses IP et le nombre d'utilisations. La liste complète des options est disponible dans la [documentation de Vault sur la création de rôles](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role) pour la méthode JSON Web Token.

## Utiliser les secrets Vault dans un job CI/CD {#use-vault-secrets-in-a-cicd-job}

Lorsqu'un job possède au moins un jeton d'ID défini, le mot-clé [`secrets`](../yaml/_index.md#secrets) utilise automatiquement ce jeton pour s'authentifier auprès de Vault.

Après avoir [configuré votre serveur Vault](#configure-your-vault-server), utilisez le mot-clé [`secrets:vault`](../yaml/_index.md#secretsvault) pour utiliser les secrets stockés dans Vault :

```yaml
job_using_vault:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
      token: $VAULT_ID_TOKEN
```

Dans cet exemple :

- `production/db` est le chemin vers le secret.
- `password` est le champ.
- `ops` est le chemin où le moteur de secrets est monté.
- `production/db/password@ops` correspond au chemin `ops/data/production/db`.
- L'authentification s'effectue avec `$VAULT_ID_TOKEN`.

Une fois que GitLab a récupéré le secret depuis Vault, la valeur est enregistrée dans un fichier temporaire. Le chemin vers ce fichier est stocké dans une variable CI/CD nommée `DATABASE_PASSWORD`, de façon similaire aux [variables de type `file`](../variables/_index.md#use-file-type-cicd-variables).

Pour remplacer le comportement par défaut, définissez explicitement l'option `file` :

```yaml
secrets:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  DATABASE_PASSWORD:
    vault: production/db/password@ops
    file: false
    token: $VAULT_ID_TOKEN
```

Dans cet exemple, la valeur du secret est placée directement dans la variable `DATABASE_PASSWORD` au lieu de pointer vers un fichier qui la contient.

## Moteurs de secrets {#secrets-engines}

{{< history >}}

- Option `generic` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/366492) dans GitLab Runner 16.11.

{{< /history >}}

GitLab Runner prend en charge différents moteurs de secrets avec le mot-clé [`secrets:engine:name`](../yaml/_index.md#secretsvault) :

| Moteur de secrets                                                                                                                                     | Valeur `secrets:engine:name` | Version du Runner | Détails |
|----------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|----------------|---------|
| [Moteur de secrets KV - version 2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)                                                       | `kv-v2`                     | 13.4           | `kv-v2` est le moteur par défaut utilisé par GitLab Runner lorsqu'aucun type de moteur n'est explicitement spécifié. |
| [Moteur de secrets KV - version 1](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v1)                                                       | `kv-v1` ou `generic`        | 13.4           | Prise en charge du mot-clé `generic` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/366492) dans GitLab 15.11. |
| [Moteur de secrets AWS](https://developer.hashicorp.com/vault/docs/secrets/aws)                                                                       | `generic`                   | 16.11          |         |
| [HashiCorp Vault Artifactory Secrets Plugin](https://jfrog.com/help/r/jfrog-integrations-documentation/hashicorp-vault-artifactory-secrets-plugin) | `generic`                   | 16.11          | Ce backend de secrets communique avec le serveur JFrog Artifactory (version 5.0.0 ou ultérieure) et provisionne dynamiquement des jetons d'accès avec des portées spécifiées. |

### Utiliser un moteur de secrets différent {#use-a-different-secrets-engine}

Le moteur de secrets `kv-v2` est utilisé par défaut. Pour utiliser un moteur différent, ajoutez une section `engine` sous `vault` dans la configuration.

Par exemple, pour définir le moteur de secrets et le chemin pour Artifactory :

```yaml
job_using_vault:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    JFROG_TOKEN:
      vault:
        engine:
          name: generic
          path: artifactory
        path: production/jfrog
        field: access_token
      file: false
```

Dans cet exemple, la valeur du secret est obtenue depuis `artifactory/production/jfrog` avec un champ `access_token`.

## Dépannage {#troubleshooting}

### Erreur de certificat auto-signé : `certificate signed by unknown authority` {#self-signed-certificate-error-certificate-signed-by-unknown-authority}

Lorsque le serveur Vault utilise un certificat auto-signé, l'erreur suivante s'affiche dans les job logs :

```plaintext
ERROR: Job failed (system failure): resolving secrets: initializing Vault service: preparing authenticated client: checking Vault server health: Get https://vault.example.com:8000/v1/sys/health?drsecondarycode=299&performancestandbycode=299&sealedcode=299&standbycode=299&uninitcode=299: x509: certificate signed by unknown authority
```

Vous avez deux options pour résoudre cette erreur :

- Ajoutez le certificat auto-signé au magasin d'autorités de certification (CA store) du serveur GitLab Runner. Si vous avez déployé GitLab Runner à l'aide du [chart Helm](https://docs.gitlab.com/runner/install/kubernetes/), vous devez créer votre propre image GitLab Runner.
- Utilisez la variable d'environnement `VAULT_CACERT` pour configurer GitLab Runner afin qu'il approuve le certificat :
  - Si vous utilisez systemd pour gérer GitLab Runner, consultez [comment ajouter une variable d'environnement pour GitLab Runner](https://docs.gitlab.com/runner/configuration/init/#setting-custom-environment-variables).
  - Si vous avez déployé GitLab Runner à l'aide du [chart Helm](https://docs.gitlab.com/runner/install/kubernetes/) :
    1. [Fournissez un certificat personnalisé pour accéder à GitLab](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#access-gitlab-with-a-custom-certificate), et assurez-vous d'ajouter le certificat du serveur Vault à la place du certificat de GitLab. Si votre instance GitLab utilise également un certificat auto-signé, vous devriez pouvoir ajouter les deux dans le même `Secret`.
    1. Ajoutez les lignes suivantes dans votre fichier `values.yaml` :

       ```yaml
       ## Replace both the <SECRET_NAME> and the <VAULT_CERTIFICATE>
       ## with the actual values you used to create the secret

       certsSecretName: <SECRET_NAME>

       envVars:
         - name: VAULT_CACERT
           value: "/home/gitlab-runner/.gitlab-runner/certs/<VAULT_CERTIFICATE>"
       ```

Si vous exécutez le serveur Vault en mode développement localement avec le [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit), vous pourriez également rencontrer cette erreur. Vous pouvez demander manuellement au système d'approuver le certificat auto-signé du serveur Vault. Ce [tutoriel exemple](https://iboysoft.com/tips/how-to-trust-a-certificate-on-mac.html) explique comment procéder sur macOS.

### Erreur `resolving secrets: secret not found: MY_SECRET` {#resolving-secrets-secret-not-found-my_secret-error}

Lorsque GitLab ne parvient pas à trouver le secret dans le vault, vous pourriez recevoir cette erreur :

```plaintext
ERROR: Job failed (system failure): resolving secrets: secret not found: MY_SECRET
```

Vérifiez que la valeur `vault` est [correctement configurée dans le job CI/CD](#use-vault-secrets-in-a-cicd-job).

Vous pouvez utiliser la [commande `kv` avec le CLI Vault](https://developer.hashicorp.com/vault/docs/commands/kv) pour vérifier si le secret est récupérable et déterminer la syntaxe de la valeur `vault` dans votre configuration CI/CD. Par exemple, pour récupérer le secret :

```shell
$ vault kv get -field=password -namespace=admin -mount=ops "production/db"
this-is-a-password
```
