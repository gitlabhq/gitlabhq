---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer OpenID Connect dans AWS pour récupérer des informations d'identification temporaires"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> `CI_JOB_JWT_V2` a été [déprécié dans GitLab 15.9](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) et est prévu d'être supprimé dans GitLab 17.0. Utilisez plutôt les [jetons d'ID](../../secrets/id_token_authentication.md).

Ce tutoriel vous explique comment utiliser un job GitLab CI/CD avec un JSON web token (JWT) pour récupérer des informations d'identification temporaires depuis AWS sans stocker de secrets. Pour ce faire, vous devez configurer OpenID Connect (OIDC) pour la fédération d'identités entre GitLab et AWS. Pour les informations générales et les prérequis pour l'intégration de GitLab avec OIDC, consultez [Se connecter aux services cloud](../_index.md).

Pour suivre ce tutoriel :

1. [Ajouter le fournisseur d'identité](#add-the-identity-provider)
1. [Configurer le rôle et l'approbation](#configure-a-role-and-trust)
1. [Récupérer des informations d'identification temporaires](#retrieve-temporary-credentials)

## Ajouter le fournisseur d'identité {#add-the-identity-provider}

Créez GitLab en tant que fournisseur OIDC IAM dans AWS en suivant ces [instructions](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html).

Incluez les informations suivantes :

- **URL du fournisseur** : L'adresse de votre instance GitLab, par exemple `https://gitlab.com` ou `http://gitlab.example.com`. Cette adresse doit être accessible publiquement. Si elle n'est pas accessible publiquement, consultez la procédure pour [configurer une instance GitLab non publique](#configure-a-non-public-gitlab-instance)
- **Audience** : Le nom logique du service cible avec lequel vous souhaitez utiliser le jeton de sécurité demandé.
  - Dans les intégrations AWS OIDC, cette valeur correspond généralement à la valeur d'audience configurée dans votre fournisseur d'identité OIDC IAM (souvent `sts.amazonaws.com` ou l'URL de votre instance GitLab).
  - Cette valeur est validée par AWS pour s'assurer que le jeton était bien destiné à votre fournisseur d'identité spécifique.

  > [!note]
  > L'utilisation de `https://gitlab.com` ou de l'URL de votre instance GitLab peut fonctionner si la référence du fournisseur d'identité AWS correspond, mais cela est sémantiquement trompeur. L'audience doit représenter le service qui valide et accepte le jeton.

## Configurer un rôle et l'approbation {#configure-a-role-and-trust}

Après avoir créé le fournisseur d'identité, configurez un [rôle d'identité web](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html) avec des conditions pour limiter l'accès aux ressources GitLab. Les informations d'identification temporaires sont obtenues à l'aide d'[AWS Security Token Service](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html). Définissez donc `Action` sur [`sts:AssumeRoleWithWebIdentity`](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html).

Vous pouvez créer une [politique d'approbation personnalisée](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-custom.html) pour le rôle afin de limiter l'autorisation à un groupe, un projet, une branche ou un tag spécifique. Pour la liste complète des types de filtrage pris en charge, consultez [Se connecter aux services cloud](../_index.md#configure-a-conditional-role-with-oidc-claims).

Sur GitLab.com, AWS prend en charge des clés de condition supplémentaires pour le fournisseur d'identité OIDC `gitlab.com`, notamment `namespace_id` et `project_id`. Incluez des conditions sur ces identifiants stables et uniques dans vos politiques d'approbation de rôle. Ces identifiants étant indépendants des chemins, les politiques d'approbation qui les référencent ne sont pas affectées par les modifications de chemins, telles que les renommages de groupes ou de projets.

Ces clés de condition supplémentaires sont disponibles uniquement pour le fournisseur d'identité OIDC `gitlab.com`. Pour GitLab Self-Managed et GitLab Dedicated, seule la revendication `sub` est actuellement prise en charge en tant que clé de condition AWS. Pour ces déploiements, définissez la portée de votre politique d'approbation en utilisant uniquement `sub` (par exemple, `gitlab.example.com:sub`).

`project_id` est unique au niveau mondial et reste identique pendant toute la durée de vie du projet, y compris lors des renommages de groupes, de projets et des transferts de projets. `namespace_id` est stable tant que le projet reste dans son espace de nommage actuel. Si le projet est transféré vers un autre espace de nommage, `namespace_id` change, ce qui invalide intentionnellement une politique d'approbation qui y est rattachée.

Pour trouver les valeurs `namespace_id` et `project_id` d'un projet, consultez la page des paramètres du projet ou l'[API Projects](../../../api/projects.md). Pour la liste complète des revendications disponibles en tant que clés de condition, consultez la section [Charge utile du jeton d'ID](../../secrets/id_token_authentication.md#token-payload).

L'exemple de politique d'approbation suivant utilise `sub` conjointement avec `namespace_id` et `project_id` pour ancrer l'approbation à un groupe, un projet et une branche spécifiques sur GitLab.com :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::AWS_ACCOUNT:oidc-provider/gitlab.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "gitlab.com:sub": "project_path:mygroup/myproject:ref_type:branch:ref:main",
          "gitlab.com:namespace_id": "12345",
          "gitlab.com:project_id": "67890"
        }
      }
    }
  ]
}
```

Une fois le rôle créé, associez une politique définissant les autorisations pour un service AWS (S3, EC2, Secrets Manager).

## Récupérer des informations d'identification temporaires {#retrieve-temporary-credentials}

Après avoir configuré l'OIDC et le rôle, le job GitLab CI/CD peut récupérer des informations d'identification temporaires auprès d'[AWS Security Token Service (STS)](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html).

```yaml
assume role:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.example.com
  script:
    # this is split out for correct exit code handling
    - >
      aws_sts_output=$(aws sts assume-role-with-web-identity
      --role-arn ${ROLE_ARN}
      --role-session-name "GitLabRunner-${CI_PROJECT_ID}-${CI_PIPELINE_ID}"
      --web-identity-token ${GITLAB_OIDC_TOKEN}
      --duration-seconds 3600
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]'
      --output text)
    - export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" $aws_sts_output)
    - aws sts get-caller-identity
```

- `ROLE_ARN` :  L'ARN du rôle défini dans cette [étape](#configure-a-role-and-trust).
- `GITLAB_OIDC_TOKEN` :  Un [jeton d'ID](../../secrets/id_token_authentication.md) OIDC.

## Exemples concrets {#working-examples}

- Consultez ce [projet de référence](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws) pour le provisionnement d'OIDC dans AWS à l'aide de Terraform et d'un exemple de script permettant de récupérer des informations d'identification temporaires.
- [OIDC et déploiement multi-comptes avec GitLab et ECS](https://gitlab.com/guided-explorations/aws/oidc-and-multi-account-deployment-with-ecs).
- Blog AWS Partner (APN) : [Setting up OpenID Connect with GitLab CI/CD](https://aws.amazon.com/blogs/apn/setting-up-openid-connect-with-gitlab-ci-cd-to-provide-secure-access-to-environments-in-aws-accounts/).
- [GitLab à l'AWS re:Inforce 2023 : Sécuriser les pipelines GitLab CD vers AWS avec OpenID et JWT](https://www.youtube.com/watch?v=xWQGADDVn8g).

## Configurer une instance GitLab non publique {#configure-a-non-public-gitlab-instance}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/391928) dans GitLab 18.1

{{< /history >}}

> [!warning]
> Cette solution de contournement est une option de configuration avancée impliquant des considérations de sécurité à prendre en compte. Vous devez veiller à synchroniser correctement la configuration OpenID et les clés publiques de votre instance GitLab Self-Managed privée vers un emplacement accessible publiquement, tel qu'un bucket S3. Vous devez également vous assurer que le bucket S3 et les fichiers qu'il contient sont correctement sécurisés. Ne pas sécuriser correctement le bucket S3 pourrait entraîner la prise de contrôle de tout compte cloud associé à cette identité OpenID Connect.

Si votre instance GitLab n'est pas accessible publiquement, la configuration d'OpenID Connect dans AWS n'est pas possible par défaut. Vous pouvez utiliser une solution de contournement pour rendre certaines configurations spécifiques accessibles publiquement, permettant ainsi la configuration d'OpenID Connect pour l'instance :

1. Stockez les détails d'authentification de votre instance GitLab dans un emplacement accessible publiquement, par exemple dans des fichiers S3 :

   - Hébergez la configuration OpenID de votre instance dans un fichier S3. La configuration est disponible à l'adresse `/.well-known/openid-configuration`, comme `http://gitlab.example.com/.well-known/openid-configuration`. Mettez à jour les valeurs `issuer:` et `jwks_uri:` dans le fichier de configuration pour qu'elles pointent vers les emplacements accessibles publiquement.
   - Hébergez les clés publiques de l'URL de votre instance dans un fichier S3. Les clés sont disponibles à l'adresse `/oauth/discovery/keys`, comme `http://gitlab.example.com/oauth/discovery/keys`.

   Par exemple :

   - Fichier de configuration OpenID : `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com/.well-known/openid-configuration`.
   - JWKS (JSON Web Key Sets) : `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com/oauth/discovery/keys`.
   - La revendication d'émetteur `iss:` dans les jetons d'ID et la valeur `issuer:` dans la configuration OpenID seraient : `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`

1. facultatif. Utilisez un validateur de configuration OpenID tel que [OpenID Configuration Endpoint Validator](https://www.oauth2.dev/tools/openid-configuration-validator) pour valider votre configuration OpenID accessible publiquement.
1. Configurez une revendication d'émetteur personnalisée pour vos jetons d'ID. Par défaut, les jetons d'ID GitLab ont la revendication d'émetteur `iss:` définie comme l'adresse de votre instance GitLab, par exemple : `http://gitlab.example.com`.

1. Mettez à jour l'URL de l'émetteur :

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   1. Modifiez `/etc/gitlab/gitlab.rb` :

      ```ruby
      gitlab_rails['ci_id_tokens_issuer_url'] = '<public_url_with_openid_configuration_and_keys>'
      ```

      Remplacez `<public_url_with_openid_configuration_and_keys>` par une URL telle que `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`.

   1. Enregistrez le fichier et [reconfigurez GitLab](../../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

   {{< /tab >}}

   {{< tab title="Helm chart (Kubernetes)" >}}

   1. Exportez les valeurs Helm :

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Modifiez `gitlab_values.yaml` :

      ```yaml
      global:
        appConfig:
          ciIdTokens:
            issuerUrl: '<public_url_with_openid_configuration_and_keys>'
      ```

      Remplacez `<public_url_with_openid_configuration_and_keys>` par une URL telle que `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`.

   1. Enregistrez le fichier et appliquez les nouvelles valeurs :

      ```shell
      helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
      ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   1. Modifiez `docker-compose.yml` :

      ```yaml
      version: "3.6"
      services:
        gitlab:
          environment:
            GITLAB_OMNIBUS_CONFIG: |
              gitlab_rails['ci_id_tokens_issuer_url'] = '<public_url_with_openid_configuration_and_keys>'
      ```

      Remplacez `<public_url_with_openid_configuration_and_keys>` par une URL telle que `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`.

   1. Enregistrez le fichier et redémarrez GitLab :

      ```shell
      docker compose up -d
      ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

      ```yaml
       production: &base
         ci_id_tokens:
           issuer_url: '<public_url_with_openid_configuration_and_keys>'
      ```

      Remplacez `<public_url_with_openid_configuration_and_keys>` par une URL telle que `https://example-oidc-configuration-s3-bucket.s3.eu-north-1.amazonaws.com`.

   1. Enregistrez le fichier et [reconfigurez GitLab](../../../administration/restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

   {{< /tab >}}

   {{< /tabs >}}

1. Exécutez la [tâche Rake `ci:validate_id_token_configuration`](../../../administration/raketasks/tokens/_index.md#validate-custom-issuer-url-configuration-for-cicd-id-tokens) pour valider la configuration du jeton d'ID CI/CD.

## Dépannage {#troubleshooting}

### Erreur : `Not authorized to perform sts:AssumeRoleWithWebIdentity` {#error-not-authorized-to-perform-stsassumerolewithwebidentity}

Si vous voyez cette erreur :

```plaintext
An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation:
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

Elle peut survenir pour plusieurs raisons :

- L'administrateur cloud n'a pas configuré le projet pour utiliser OIDC avec GitLab.
- Le rôle est restreint et ne peut pas être exécuté sur la branche ou le tag. Consultez [configurer un rôle conditionnel](../_index.md).
- `StringEquals` est utilisé à la place de `StringLike` lors de l'utilisation d'une condition avec caractère générique. Consultez le [ticket associé](https://gitlab.com/guided-explorations/aws/configure-openid-connect-in-aws/-/issues/2#note_852901934).

### Erreur `Could not connect to openid configuration of provider` {#could-not-connect-to-openid-configuration-of-provider-error}

Après avoir ajouté le fournisseur d'identité dans AWS IAM, vous pourriez obtenir l'erreur suivante :

```plaintext
Your request has a problem. Please see the following details.
  - Could not connect to openid configuration of provider: `https://gitlab.example.com`
```

Cette erreur se produit lorsque l'émetteur du fournisseur d'identité OIDC présente une chaîne de certificats dans le mauvais ordre, ou contient des certificats en double ou supplémentaires.

Vérifiez la chaîne de certificats de votre instance GitLab. La chaîne doit commencer par le domaine ou l'URL de l'émetteur, puis le certificat intermédiaire, et se terminer par le certificat racine. Utilisez cette commande pour examiner la chaîne de certificats, en remplaçant `gitlab.example.com` par le nom d'hôte de votre GitLab :

```shell
echo | /opt/gitlab/embedded/bin/openssl s_client -connect gitlab.example.com:443
```

### Erreur `Couldn't retrieve verification key from your identity provider` {#couldnt-retrieve-verification-key-from-your-identity-provider-error}

Vous pourriez recevoir une erreur similaire à :

- `An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithWebIdentity operation: Couldn't retrieve verification key from your identity provider, please reference AssumeRoleWithWebIdentity documentation for requirements`

Cette erreur peut être due aux raisons suivantes :

- L'URL `.well_known` et `jwks_uri` du fournisseur d'identité (IdP) ne sont pas accessibles depuis l'internet public.
- Un pare-feu personnalisé bloque les requêtes.
- Il y a une latence de plus de 5 secondes dans les requêtes API de l'IdP pour atteindre le point de terminaison AWS STS.
- STS envoie trop de requêtes à votre URL `.well_known` ou au `jwks_uri` de l'IdP.

Comme indiqué dans l'[article du Centre de connaissances AWS pour cette erreur](https://repost.aws/knowledge-center/iam-sts-invalididentitytoken), votre instance GitLab doit être accessible publiquement pour que l'URL `.well_known` et `jwks_uri` puissent être résolues. Si ce n'est pas possible, par exemple si votre instance GitLab se trouve dans un environnement hors ligne, consultez la procédure pour [configurer une instance GitLab non publique](#configure-a-non-public-gitlab-instance)
