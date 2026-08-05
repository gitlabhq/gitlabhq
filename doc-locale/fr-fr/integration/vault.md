---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Authentification Vault avec GitLab OpenID Connect
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Vault](https://www.vaultproject.io/) est une application de gestion des secrets proposée par HashiCorp. Elle vous permet de stocker et de gérer des informations sensibles telles que des variables d'environnement secrètes, des clés de chiffrement et des jetons d'authentification.

Vault propose un accès basé sur l'identité, ce qui signifie que les utilisateurs de Vault peuvent s'authentifier via plusieurs de leurs fournisseurs cloud préférés.

Le contenu suivant explique comment les utilisateurs de Vault peuvent s'authentifier via GitLab en utilisant notre fonctionnalité d'authentification OpenID.

## Prérequis {#prerequisites}

1. [Installez Vault](https://developer.hashicorp.com/vault/install)
1. Exécutez Vault

## Obtenir l'ID client et le secret OpenID Connect depuis GitLab {#get-the-openid-connect-client-id-and-secret-from-gitlab}

Vous devez d'abord créer une application GitLab pour obtenir un ID d'application et un secret permettant de s'authentifier dans Vault. Pour ce faire, connectez-vous à GitLab et suivez ces étapes :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Applications**.
1. Renseignez le **Nom** de l'application et l'[**Redirect URI**](https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris).
1. Sélectionnez la **OpenID**.
1. Sélectionnez **Enregistrer l'application**.
1. Copiez l'**ID du client** et le **Client Secret**, ou gardez la page ouverte pour référence.

![GitLab en tant que fournisseur OAuth](img/gitlab_oauth_vault_v12_6.png)

## Activer OpenID Connect sur Vault {#enable-openid-connect-on-vault}

OpenID Connect (OIDC) n'est pas activé dans Vault par défaut.

Pour activer le fournisseur d'authentification OIDC dans Vault, ouvrez une session de terminal et exécutez la commande suivante :

```shell
vault auth enable oidc
```

Vous devriez voir la sortie suivante dans le terminal :

```plaintext
Success! Enabled oidc auth method at: oidc/
```

## Écrire la configuration OIDC {#write-the-oidc-configuration}

Pour fournir à Vault l'ID d'application et le secret générés par GitLab et permettre à Vault de s'authentifier via GitLab, exécutez la commande suivante dans le terminal :

```shell
vault write auth/oidc/config \
  oidc_discovery_url="https://gitlab.com" \
  oidc_client_id="<your_application_id>" \
  oidc_client_secret="<your_secret>" \
  default_role="demo" \
  bound_issuer="localhost"
```

Remplacez `<your_application_id>` et `<your_secret>` par l'ID d'application et le secret générés pour votre application.

Vous devriez voir la sortie suivante dans le terminal :

```shell
Success! Data written to: auth/oidc/config
```

## Écrire la configuration du rôle OIDC {#write-the-oidc-role-configuration}

Vous devez indiquer à Vault les [**Redirect URIs**](https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris) et les portées fournis à GitLab lors de la création de l'application.

Exécutez la commande suivante dans le terminal :

```shell
vault write auth/oidc/role/demo - <<EOF
{
   "user_claim": "sub",
   "allowed_redirect_uris": "<your_vault_instance_redirect_uris>",
   "bound_audiences": "<your_application_id>",
   "oidc_scopes": "<openid>",
   "role_type": "oidc",
   "policies": "demo",
   "ttl": "1h",
   "bound_claims": { "groups": ["<yourGroup/yourSubgrup>"] }
}
EOF
```

Remplacez :

- `<your_vault_instance_redirect_uris>` par les URI de redirection correspondant à l'emplacement où votre instance Vault est exécutée
- `<your_application_id>` par l'ID d'application généré pour votre application

Le champ `oidc_scopes` doit inclure `openid`.

Cette configuration est enregistrée sous le nom du rôle que vous créez. Cet exemple crée un rôle `demo`.

> [!warning]
> Si vous utilisez une instance GitLab.com publique, vous devez spécifier `bound_claims` pour n'autoriser l'accès qu'aux membres de votre groupe ou projet. Dans le cas contraire, toute personne disposant d'un compte public peut accéder à votre instance Vault.

## Se connecter à Vault {#sign-in-to-vault}

1. Accédez à l'interface utilisateur de Vault. Par exemple : <http://127.0.0.1:8200/ui/vault/auth?with=oidc>.
1. Si la méthode `OIDC` n'est pas sélectionnée, ouvrez la liste déroulante et sélectionnez-la.
1. Sélectionnez **Sign in With GitLab**, ce qui ouvre une boîte de dialogue :

   ![Se connecter à Vault avec GitLab](img/sign_into_vault_with_gitlab_v12_6.png)
1. Pour autoriser Vault à se connecter via GitLab, sélectionnez **Autoriser**. Vous êtes alors redirigé vers l'interface utilisateur de Vault en tant qu'utilisateur authentifié.

   ![Autoriser Vault à se connecter avec GitLab](img/authorize_vault_with_gitlab_v12_6.png)

## Se connecter avec la CLI Vault (facultatif) {#sign-in-using-the-vault-cli-optional}

Vous pouvez également vous connecter à Vault en utilisant le [CLI Vault](https://developer.hashicorp.com/vault/docs/commands).

1. Pour vous connecter avec la configuration de rôle créée dans l'exemple précédent, exécutez la commande suivante dans votre terminal :

   ```shell
   vault login -method=oidc port=8250 role=demo
   ```

   Cette commande définit :

   - `role=demo` afin que Vault sache quelle configuration vous souhaitez utiliser pour vous connecter.
   - `-method=oidc` pour configurer Vault afin d'utiliser la méthode de connexion `OIDC`.
   - `port=8250` pour définir le port vers lequel GitLab doit effectuer la redirection. Ce numéro de port doit correspondre au port fourni à GitLab lors de la liste des [URI de redirection](https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris).

   Après avoir exécuté cette commande, un lien devrait apparaître dans le terminal.
1. Ouvrez ce lien dans un navigateur web :

   ![Connecté à Vault via OIDC](img/signed_into_vault_via_oidc_v12_6.png)

   Vous devriez voir dans le terminal :

   ```plaintext
   Success! You are now authenticated. The token information displayed below
   is already stored in the token helper. You do NOT need to run "vault login"
   again. Future Vault requests will automatically use this token.
   ```
