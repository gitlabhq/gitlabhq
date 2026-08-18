---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: "Stockage d'objets"
description: "Configurer un service de stockage d'objets pour les données."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab prend en charge l'utilisation d'un service de stockage d'objets pour héberger de nombreux types de données. Il est recommandé par rapport à NFS et, en général, il est préférable dans les configurations plus importantes, car le stockage d'objets est généralement beaucoup plus performant, fiable et évolutif.

Pour configurer le stockage d'objets, vous disposez de deux options :

- Recommandé. [Configurer une connexion de stockage unique pour tous les types d'objets](#configure-a-single-storage-connection-for-all-object-types-consolidated-form) : Un seul identifiant est partagé par tous les types d'objets pris en charge. C'est ce qu'on appelle le formulaire consolidé.
- [Configurer chaque type d'objet pour définir sa propre connexion de stockage](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form) : Chaque objet définit sa propre connexion et configuration de stockage d'objets. C'est ce qu'on appelle le formulaire spécifique au stockage.

  Si vous utilisez déjà le formulaire spécifique au stockage, découvrez comment [passer au formulaire consolidé](#transition-to-consolidated-form).

Si vous stockez des données localement, découvrez comment [migrer vers le stockage d'objets](#migrate-to-object-storage).

## Prise en charge des fournisseurs de stockage d'objets {#object-storage-provider-support}

GitLab utilise la [bibliothèque Fog](https://fog.github.io/about/supported_services.html) pour le stockage d'objets et prend en charge les trois types de connexion suivants. Les autres fournisseurs Fog ne sont pas pris en charge.

| Type de connexion      | Valeur de `provider` | Utiliser avec |
|:---------------------|:-----------------|:---------|
| Compatible S3        | `AWS`            | Amazon S3 et tout service compatible S3 |
| Google Cloud Storage | `Google`         | Google Cloud Storage |
| Azure Blob Storage   | `AzureRM`        | Azure Blob Storage |

Si votre service de stockage d'objets est compatible avec l'un de ces types de connexion, configurez-le en utilisant les paramètres de connexion correspondants ci-dessous. Le choix du fournisseur vous appartient.

### Fournisseurs avec couverture de test active {#providers-with-active-test-coverage}

GitLab teste activement les fournisseurs suivants :

- [Amazon S3](https://aws.amazon.com/s3/) \- type de connexion `AWS`. [Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html) n'est pas pris en charge. Pour plus d'informations, consultez le [ticket 335775](https://gitlab.com/gitlab-org/gitlab/-/issues/335775).
- [Google Cloud Storage](https://cloud.google.com/storage) \- type de connexion `Google`.
- [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction) \- type de connexion `AzureRM`.

### Fournisseurs documentés par la communauté {#community-documented-providers}

Les fournisseurs suivants ont été documentés par la communauté. GitLab ne teste pas ces fournisseurs. Des exemples de configuration sont fournis à titre de commodité. Si vous utilisez l'un de ces fournisseurs et rencontrez des problèmes, le support GitLab pourrait ne pas être en mesure de vous aider.

- [Digital Ocean Spaces](https://www.digitalocean.com/products/spaces). Compatible S3, consultez les [exemples de configuration spécifiques aux fournisseurs](#provider-specific-configuration-examples).
- [Oracle Cloud Infrastructure](https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/s3compatibleapi.htm). Compatible S3, consultez les [exemples de configuration spécifiques aux fournisseurs](#provider-specific-configuration-examples).
- [OpenStack Swift](https://docs.openstack.org/swift/latest/s3_compat.html) (mode compatible S3).
- [Storj Gateway](https://www.storj.io/). Compatible S3, consultez les [exemples de configuration spécifiques aux fournisseurs](#provider-specific-configuration-examples).
- [Ceph RGW](https://docs.ceph.com/en/reef/cephadm/services/rgw/). Compatible S3, consultez les [exemples de configuration spécifiques aux fournisseurs](#provider-specific-configuration-examples)
- [Hitachi Vantara HCP](https://docs.hitachivantara.com/r/en-us/content-platform/9.7.x/mk-95hcph001/hcp-management-api-reference/introduction-to-the-hcp-management-api/support-for-the-amazon-s3-api). Compatible S3, consultez les [exemples de configuration spécifiques aux fournisseurs](#provider-specific-configuration-examples).
- Matériel et appliances sur site qui exposent une API compatible S3.

## Configurer une connexion de stockage unique pour tous les types d'objets (formulaire consolidé) {#configure-a-single-storage-connection-for-all-object-types-consolidated-form}

La plupart des types d'objets, tels que les artefacts CI, les fichiers LFS et les pièces jointes importées, peuvent être enregistrés dans le stockage d'objets en spécifiant un seul identifiant pour le stockage d'objets avec plusieurs buckets.

> [!note]
> Pour les charts Helm GitLab, découvrez comment [configurer le formulaire consolidé](https://docs.gitlab.com/charts/charts/globals/#consolidated-object-storage).

La configuration du stockage d'objets à l'aide du formulaire consolidé présente plusieurs avantages :

- Cela peut simplifier votre configuration GitLab, car les détails de connexion sont partagés entre les types d'objets.
- Cela permet l'utilisation de [buckets S3 chiffrés](#encrypted-s3-buckets).
- Il [importe les fichiers vers S3 avec les en-têtes `Content-MD5` appropriés](https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/222).

Lorsque le formulaire consolidé est utilisé, l'importation directe est activée automatiquement. Ainsi, seuls les fournisseurs suivants peuvent être utilisés :

- [Fournisseurs compatibles S3](#s3-compatible-providers)
- [Google Cloud Storage](#google-cloud-storage-gcs)
- [Azure Blob storage](#azure-blob-storage)

La configuration du formulaire consolidé ne peut pas être utilisée pour les sauvegardes ou Mattermost. Les sauvegardes peuvent être configurées séparément avec le [chiffrement côté serveur](backup_restore/backup_gitlab.md#s3-encrypted-buckets). Consultez le [tableau pour la liste complète](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form) des types de stockage d'objets pris en charge.

L'activation du formulaire consolidé active le stockage d'objets pour tous les types d'objets. Si tous les buckets ne sont pas spécifiés, vous pourriez voir une erreur telle que :

```plaintext
Object storage for <object type> must have a bucket specified
```

Si vous souhaitez utiliser le stockage local pour des types d'objets spécifiques, vous pouvez [désactiver le stockage d'objets pour des fonctionnalités spécifiques](#disable-object-storage-for-specific-features).

### Configurer les paramètres communs {#configure-the-common-parameters}

Dans le formulaire consolidé, la section `object_store` définit un ensemble commun de paramètres.

| Paramètre           | Description                       |
|-------------------|-----------------------------------|
| `enabled`         | Activer ou désactiver le stockage d'objets. |
| `proxy_download`  | Définir sur `true` pour [activer le proxy pour tous les fichiers servis](#proxy-download). Cette option permet de réduire le trafic sortant, car elle permet aux clients de télécharger directement depuis le stockage distant au lieu de proxier toutes les données. |
| `connection`      | Diverses [options de connexion](#configure-the-connection-settings) décrites ci-dessous. |
| `storage_options` | Options à utiliser lors de l'enregistrement de nouveaux objets, telles que le [chiffrement côté serveur](#server-side-encryption-headers). |
| `objects`         | [Configuration spécifique aux objets](#configure-the-parameters-of-each-object). |

Pour un exemple, découvrez comment [utiliser le formulaire consolidé et Amazon S3](#full-example-using-the-consolidated-form-and-amazon-s3).

### Configurer les paramètres de chaque objet {#configure-the-parameters-of-each-object}

Chaque type d'objet doit au moins définir le nom du bucket dans lequel il sera stocké.

Le tableau suivant répertorie les `objects` valides qui peuvent être utilisés :

| Type               | Description |
|--------------------|-------------|
| `artifacts`        | [Artefacts de job CI/CD](cicd/job_artifacts.md) |
| `external_diffs`   | [Diffs de merge request](merge_request_diffs.md) |
| `uploads`          | [Importations des utilisateurs](uploads.md) |
| `lfs`              | [Objets Git Large File Storage](lfs/_index.md) |
| `packages`         | [Packages de projet (par exemple, PyPI, Maven ou NuGet)](packages/_index.md) |
| `dependency_proxy` | [Proxy de dépendances](packages/dependency_proxy.md) |
| `terraform_state`  | [Fichiers d'état Terraform](terraform_state.md) |
| `pages`            | [Pages](pages/_index.md) |
| `ci_secure_files`  | [Fichiers sécurisés](cicd/secure_files.md) |

Au sein de chaque type d'objet, trois paramètres peuvent être définis :

| Paramètre          | Requis ?              | Description                         |
|------------------|------------------------|-------------------------------------|
| `bucket`         | {{< icon name="check-circle" >}} Oui* | Nom du bucket pour le type d'objet. Non requis si `enabled` est défini sur `false`. |
| `enabled`        | {{< icon name="dotted-circle" >}} Non | Remplace le [paramètre commun](#configure-the-common-parameters).     |
| `proxy_download` | {{< icon name="dotted-circle" >}} Non | Remplace le [paramètre commun](#configure-the-common-parameters).     |

Pour un exemple, découvrez comment [utiliser le formulaire consolidé et Amazon S3](#full-example-using-the-consolidated-form-and-amazon-s3).

#### Désactiver le stockage d'objets pour des fonctionnalités spécifiques {#disable-object-storage-for-specific-features}

Comme vu précédemment, le stockage d'objets peut être désactivé pour des types spécifiques en définissant le flag `enabled` sur `false`. Par exemple, pour désactiver le stockage d'objets pour les artefacts CI :

```ruby
gitlab_rails['object_store']['objects']['artifacts']['enabled'] = false
```

Un bucket n'est pas nécessaire si la fonctionnalité est entièrement désactivée. Par exemple, aucun bucket n'est nécessaire si les artefacts CI sont désactivés avec ce paramètre :

```ruby
gitlab_rails['artifacts_enabled'] = false
```

## Configurer chaque type d'objet pour définir sa propre connexion de stockage (formulaire spécifique au stockage) {#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form}

Avec le formulaire spécifique au stockage, chaque objet définit sa propre connexion et configuration de stockage d'objets. Vous devriez [utiliser le formulaire consolidé](#transition-to-consolidated-form) à la place, sauf pour les types de stockage non pris en charge par le formulaire consolidé. Lorsque vous utilisez les charts Helm GitLab, référez-vous à la façon dont les charts gèrent le [formulaire consolidé pour le stockage d'objets](https://docs.gitlab.com/charts/charts/globals/#consolidated-object-storage).

L'utilisation des [buckets S3 chiffrés](#encrypted-s3-buckets) avec le formulaire non consolidé n'est pas prise en charge. Vous pouvez obtenir des [erreurs de non-correspondance ETag](#etag-mismatch) si vous l'utilisez.

> [!note]
> Pour le formulaire spécifique au stockage, [l'importation directe peut devenir la valeur par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/27331) car elle ne nécessite pas de dossier partagé.

Pour les types de stockage non pris en charge par le formulaire consolidé, reportez-vous aux guides suivants :

| Type de stockage d'objets | Pris en charge par le formulaire consolidé ? |
|---------------------|------------------------------------------|
| [Sauvegardes](backup_restore/backup_gitlab.md#upload-backups-to-a-remote-cloud-storage) | {{< icon name="dotted-circle" >}} Non |
| [Registre de conteneurs](packages/container_registry.md#use-object-storage) (fonctionnalité optionnelle) | {{< icon name="dotted-circle" >}} Non |
| [Mattermost](https://docs.mattermost.com/configure/file-storage-configuration-settings.html)| {{< icon name="dotted-circle" >}} Non |
| [Mise en cache des runners en mise à l'échelle automatique](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching) (optionnel pour améliorer les performances) | {{< icon name="dotted-circle" >}} Non |
| [Fichiers sécurisés](cicd/secure_files.md#using-object-storage) | {{< icon name="check-circle" >}} Oui |
| [Artefacts de job](cicd/job_artifacts.md#using-object-storage) incluant les job logs archivés | {{< icon name="check-circle" >}} Oui |
| [Objets LFS](lfs/_index.md#storing-lfs-objects-in-remote-object-storage) | {{< icon name="check-circle" >}} Oui |
| [Importations](uploads.md#using-object-storage) | {{< icon name="check-circle" >}} Oui |
| [Diffs de merge request](merge_request_diffs.md#using-object-storage) | {{< icon name="check-circle" >}} Oui |
| [Packages](packages/_index.md#migrate-packages-between-object-storage-and-local-storage) (fonctionnalité optionnelle) | {{< icon name="check-circle" >}} Oui |
| [Proxy de dépendances](packages/dependency_proxy.md#using-object-storage) (fonctionnalité optionnelle) | {{< icon name="check-circle" >}} Oui |
| [Fichiers d'état Terraform](terraform_state.md#using-object-storage) | {{< icon name="check-circle" >}} Oui |
| [Contenu Pages](pages/_index.md#object-storage-settings) | {{< icon name="check-circle" >}} Oui |

## Configurer les paramètres de connexion {#configure-the-connection-settings}

Les formulaires consolidé et spécifique au stockage doivent tous deux configurer une connexion. Les sections suivantes décrivent les paramètres pouvant être utilisés dans le paramètre `connection`.

### Fournisseurs compatibles S3 {#s3-compatible-providers}

Ces paramètres s'appliquent à Amazon S3 et à tout service compatible S3 utilisant le type de connexion `AWS`. Lorsque vous n'utilisez pas AWS directement, définissez `endpoint` sur l'URL de votre fournisseur.

Les services compatibles S3 varient dans la façon dont ils implémentent l'API AWS S3. GitLab utilise des comportements S3 spécifiques, notamment les URL pré-signées, les importations en plusieurs parties et, en option, la diffusion de signatures fragmentées, que toutes les implémentations compatibles S3 ne prennent pas en charge de manière identique. Si un fournisseur fonctionne avec d'autres outils mais pas avec GitLab, les paramètres qui nécessitent le plus probablement un ajustement sont :

- `aws_signature_version`.
- `enable_signature_v4_streaming`.

Les paramètres de connexion correspondent à ceux fournis par [fog-aws](https://github.com/fog/fog-aws) :

| Paramètre                                     | Description                        | Valeur par défaut |
|---------------------------------------------|------------------------------------|---------|
| `provider`                                  | Toujours `AWS` pour les hôtes compatibles. | `AWS` |
| `aws_access_key_id`                         | Identifiants AWS, ou compatibles.    | |
| `aws_secret_access_key`                     | Identifiants AWS, ou compatibles.    | |
| `aws_signature_version`                     | Version de signature AWS à utiliser. `2` ou `4` sont des options valides. Certains fournisseurs compatibles S3 peuvent nécessiter `2`. | `4` |
| `enable_signature_v4_streaming`             | Définir sur `true` pour activer les transferts HTTP fragmentés avec les [signatures AWS v4](https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-streaming.html). Certains fournisseurs compatibles S3 nécessitent que cette valeur soit `false`. GitLab 17.4 a modifié la valeur par défaut de `true` à `false`. | `false` |
| `region`                                    | Région AWS.                        | |
| `host`                                      | DÉPRÉCIÉ : Utilisez plutôt `endpoint`. Hôte compatible S3 à utiliser lorsque vous n'utilisez pas AWS. Par exemple, `localhost` ou `storage.example.com`. HTTPS et le port 443 sont supposés. | `s3.amazonaws.com` |
| `endpoint`                                  | Peut être utilisé lors de la configuration d'un service compatible S3, en saisissant une URL telle que `http://127.0.0.1:9000`. Cela prend la priorité sur `host`. Utilisez toujours `endpoint` pour le formulaire consolidé. | (optionnel) |
| `path_style`                                | Définir sur `true` pour utiliser des chemins de style `host/bucket_name/object` au lieu de `bucket_name.host/object`. Définir sur `true` pour les services compatibles S3 qui nécessitent un adressage par chemin. Laisser sur `false` pour AWS S3. | `false` |
| `use_iam_profile`                           | Définir sur `true` pour utiliser le profil IAM au lieu des clés d'accès. | `false` |
| `aws_credentials_refresh_threshold_seconds` | Définit le [seuil de rafraîchissement automatique](https://github.com/fog/fog-aws#controlling-credential-refresh-time-with-iam-authentication) en secondes lors de l'utilisation d'identifiants temporaires dans IAM. | `15` |
| `disable_imds_v2`                           | Force l'utilisation d'IMDS v1 en désactivant l'accès au point de terminaison IMDS v2 qui récupère `X-aws-ec2-metadata-token`. | `false` |

#### Compatibilité S3 et modes d'échec connus {#s3-compatibility-and-known-failure-modes}

Revendiquer la compatibilité S3 ne garantit pas qu'un fournisseur fonctionne correctement avec GitLab. Si vous rencontrez des erreurs avec un fournisseur compatible S3, essayez les ajustements suivants avant de soumettre une demande de support :

- **Signature streaming** : Certains fournisseurs rejettent l'encodage de transfert fragmenté utilisé par la diffusion AWS Signature Version 4. Définir `enable_signature_v4_streaming: false`.
- **Signature version** : Certains fournisseurs ne prennent pas entièrement en charge Signature Version 4. Définir `aws_signature_version: 2`.
- **Path-style URLs** : Certains fournisseurs nécessitent un adressage de bucket par chemin. Définir `path_style: true`.
- **ETag validation** : Certains fournisseurs renvoient des ETags qui ne correspondent pas au MD5 de l'objet importé, que GitLab valide. Consultez [Non-correspondance ETag](#etag-mismatch).

Le support GitLab peut vous aider à résoudre les problèmes de configuration, mais ne peut pas garantir la résolution des problèmes spécifiques aux fournisseurs qui ne font pas partie de l'[ensemble testé](#providers-with-active-test-coverage).

#### Utiliser des profils d'instance Amazon {#use-amazon-instance-profiles}

Au lieu de fournir des clés d'accès et secrètes AWS dans la configuration du stockage d'objets, vous pouvez configurer GitLab pour utiliser les rôles Amazon Identity Access and Management (IAM) afin de configurer un [profil d'instance Amazon](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html). Lorsque cette option est utilisée, GitLab récupère des identifiants temporaires chaque fois qu'un bucket S3 est accédé, de sorte qu'aucune valeur codée en dur n'est nécessaire dans la configuration.

Prérequis :

- GitLab doit être en mesure de se connecter au [point de terminaison des métadonnées d'instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html).
- Si GitLab est [configuré pour utiliser un proxy Internet](https://docs.gitlab.com/omnibus/settings/environment-variables/), l'adresse IP du point de terminaison doit être ajoutée à la liste `no_proxy`.
- Pour l'accès IMDS v2, assurez-vous que la [limite de sauts](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html) est suffisante. Si GitLab s'exécute dans un conteneur, vous devrez peut-être augmenter la limite de 1 à 2.

Pour configurer un profil d'instance :

1. Créez un rôle IAM avec les autorisations nécessaires. L'exemple suivant est un rôle pour un bucket S3 nommé `test-bucket` :

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject"
               ],
               "Resource": "arn:aws:s3:::test-bucket/*"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "s3:ListBucket"
               ],
               "Resource": "arn:aws:s3:::test-bucket"
           }
       ]
   }
   ```

1. [Associez ce rôle](https://repost.aws/knowledge-center/attach-replace-ec2-instance-profile) à l'instance EC2 hébergeant votre instance GitLab.
1. Définissez l'option de configuration GitLab `use_iam_profile` sur `true`.

#### Buckets S3 chiffrés {#encrypted-s3-buckets}

Lorsqu'il est configuré avec un profil d'instance ou avec le formulaire consolidé, GitLab Workhorse importe correctement les fichiers vers des buckets S3 dont le [chiffrement SSE-S3 ou SSE-KMS est activé par défaut](https://docs.aws.amazon.com/kms/latest/developerguide/overview.html). Les clés AWS KMS et le chiffrement SSE-C [ne sont pas pris en charge car cela nécessite l'envoi des clés de chiffrement dans chaque requête](https://gitlab.com/gitlab-org/gitlab/-/issues/226006).

#### En-têtes de chiffrement côté serveur {#server-side-encryption-headers}

Définir un chiffrement par défaut sur un bucket S3 est le moyen le plus simple d'activer le chiffrement, mais vous pouvez [définir une politique de bucket pour garantir que seuls les objets chiffrés sont importés](https://repost.aws/knowledge-center/s3-bucket-store-kms-encrypted-objects). Pour ce faire, vous devez configurer GitLab pour envoyer les en-têtes de chiffrement appropriés dans la section de configuration `storage_options` :

| Paramètre                             | Description                              |
|-------------------------------------|------------------------------------------|
| `server_side_encryption`            | Mode de chiffrement (`AES256` ou `aws:kms`). |
| `server_side_encryption_kms_key_id` | Nom de ressource Amazon. Nécessaire uniquement lorsque `aws:kms` est utilisé dans `server_side_encryption`. Consultez la [documentation Amazon sur l'utilisation du chiffrement KMS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html). |

Comme dans le cas du chiffrement par défaut, ces options ne fonctionnent que lorsque le client S3 Workhorse est activé. L'une des deux conditions suivantes doit être remplie :

- `use_iam_profile` est `true` dans les paramètres de connexion.
- Le formulaire consolidé est utilisé.

Des [erreurs de non-correspondance ETag](#etag-mismatch) se produisent si des en-têtes de chiffrement côté serveur sont utilisés sans activer le client S3 Workhorse.

### Google Cloud Storage (GCS) {#google-cloud-storage-gcs}

{{< history >}}

- Le paramètre `universe_domain` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221401) dans GitLab 18.9.

{{< /history >}}

Voici les paramètres de connexion valides pour GCS :

| Paramètre                      | Description       | Exemple |
|------------------------------|-------------------|---------|
| `provider`                   | Nom du fournisseur.    | `Google` |
| `google_project`             | Nom du projet GCP. | `gcp-project-12345` |
| `google_json_key_location`   | Chemin de la clé JSON.    | `/path/to/gcp-project-12345-abcde.json` |
| `google_json_key_string`     | Chaîne de clé JSON.  | `{ "type": "service_account", "project_id": "example-project-382839", ... }` |
| `google_application_default` | Définir sur `true` pour utiliser les [identifiants par défaut des applications Google Cloud](https://cloud.google.com/docs/authentication#adc) pour localiser les identifiants du compte de service. | |
| `universe_domain`            | Domaine universe à utiliser pour les requêtes Google Cloud. Utilisez ceci pour vous connecter à [Google Cloud Dedicated](https://cloud.google.com/sovereign-cloud) ou à d'autres domaines universe non définis par défaut. | `googleapis.com` |

GitLab lit la valeur de `google_json_key_location`, puis `google_json_key_string`, et enfin `google_application_default`. Il utilise le premier de ces paramètres qui a une valeur.

Le compte de service doit avoir l'autorisation d'accéder au bucket. Pour plus d'informations, consultez la [documentation sur l'authentification Cloud Storage](https://cloud.google.com/storage/docs/authentication).

#### Identifiants par défaut des applications Google Cloud {#google-cloud-application-default-credentials}

Les [identifiants par défaut des applications Google Cloud (ADC)](https://cloud.google.com/docs/authentication/application-default-credentials) sont généralement utilisés avec GitLab pour utiliser le compte de service par défaut ou la [fédération d'identité de charge de travail](https://cloud.google.com/iam/docs/workload-identity-federation). Définissez `google_application_default` sur `true` et omettez `google_json_key_location` et `google_json_key_string`.

Si vous utilisez ADC, assurez-vous que :

- Le compte de service que vous utilisez dispose de l'[autorisation `iam.serviceAccounts.signBlob`](https://cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/signBlob). Cela se fait généralement en accordant le rôle `Service Account Token Creator` au compte de service.
- Si vous utilisez des machines virtuelles Google Compute, assurez-vous qu'elles disposent des [portées d'accès correctes pour accéder aux API Google Cloud](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#changeserviceaccountandscopes). Si les machines ne disposent pas de la bonne portée, les journaux d'erreurs peuvent afficher :

  ```shell
  Google::Apis::ClientError (insufficientPermissions: Request had insufficient authentication scopes.)
  ```

> [!note]
> Pour utiliser le chiffrement de bucket avec des [clés de chiffrement gérées par le client](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys), utilisez le [formulaire consolidé](#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes, en remplaçant les valeurs souhaitées :

   ```ruby
   gitlab_rails['object_store']['connection'] = {
    'provider' => 'Google',
    'google_project' => '<GOOGLE PROJECT>',
    'google_json_key_location' => '<FILENAME>'
   }
   ```

   Pour utiliser ADC, utilisez plutôt `google_application_default` :

   ```ruby
   gitlab_rails['object_store']['connection'] = {
    'provider' => 'Google',
    'google_project' => '<GOOGLE PROJECT>',
    'google_application_default' => true
   }
   ```

   Pour utiliser un domaine universe non défini par défaut (par exemple, [Google Cloud Dedicated](https://cloud.google.com/sovereign-cloud)) :

   ```ruby
   gitlab_rails['object_store']['connection'] = {
    'provider' => 'Google',
    'google_project' => '<GOOGLE PROJECT>',
    'google_application_default' => true,
    'universe_domain' => '<UNIVERSE DOMAIN>'
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `object_storage.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#connection) :

   ```yaml
   provider: Google
   google_project: <GOOGLE PROJECT>
   google_json_key_location: '<FILENAME>'
   ```

   Pour utiliser ADC, utilisez plutôt `google_application_default` :

   ```yaml
   provider: Google
   google_project: <GOOGLE PROJECT>
   google_application_default: true
   ```

   Pour utiliser un domaine universe non défini par défaut (par exemple, [Google Cloud Dedicated](https://cloud.google.com/sovereign-cloud)) :

   ```yaml
   provider: Google
   google_project: <GOOGLE PROJECT>
   google_application_default: true
   universe_domain: <UNIVERSE DOMAIN>
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
   ```

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
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'Google',
             'google_project' => '<GOOGLE PROJECT>',
             'google_json_key_location' => '<FILENAME>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   Pour utiliser ADC, utilisez plutôt `google_application_default` :

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'Google',
     'google_project' => '<GOOGLE PROJECT>',
     'google_application_default' => true
   }
   ```

   Pour utiliser un domaine universe non défini par défaut (par exemple, [Google Cloud Dedicated](https://cloud.google.com/sovereign-cloud)) :

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'Google',
     'google_project' => '<GOOGLE PROJECT>',
     'google_application_default' => true,
     'universe_domain' => '<UNIVERSE DOMAIN>'
   }
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< /tabs >}}

### Azure Blob storage {#azure-blob-storage}

Bien qu'Azure utilise le terme `container` pour désigner une collection de blobs, GitLab standardise le terme `bucket`. Assurez-vous de configurer les noms de conteneurs Azure dans les paramètres `bucket`.

Azure Blob storage ne peut être utilisé qu'avec le [formulaire consolidé](#configure-a-single-storage-connection-for-all-object-types-consolidated-form), car un seul ensemble d'identifiants est utilisé pour accéder à plusieurs conteneurs. Le [formulaire spécifique au stockage](#configure-each-object-type-to-define-its-own-storage-connection-storage-specific-form) n'est pas pris en charge. Pour plus de détails, consultez [comment passer au formulaire consolidé](#transition-to-consolidated-form).

Les paramètres de connexion valides pour Azure sont les suivants. Pour plus d'informations, consultez la [documentation Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction).

| Paramètre                      | Description    | Exemple   |
|------------------------------|----------------|-----------|
| `provider`                   | Nom du fournisseur. | `AzureRM` |
| `azure_storage_account_name` | Nom du compte Azure Blob Storage utilisé pour accéder au stockage. | `azuretest` |
| `azure_storage_access_key`   | Clé d'accès du compte de stockage utilisée pour accéder au conteneur. Il s'agit généralement d'une clé de chiffrement secrète de 512 bits encodée en base64. Ceci est optionnel pour les [identités de charge de travail et identités managées Azure](#azure-workload-and-managed-identities). | `czV2OHkvQj9FKEgrTWJRZVRoV21ZcTN0Nnc5eiRDJkYpSkBOY1JmVWpYbjJy\nNHU3eCFBJUQqRy1LYVBkU2dWaw==\n` |
| `azure_storage_domain`       | Nom de domaine utilisé pour contacter l'API Azure Blob Storage (optionnel). Par défaut, `blob.core.windows.net`. Définissez cette valeur si vous utilisez Azure China, Azure Germany, Azure US Government ou tout autre domaine Azure personnalisé. | `blob.core.windows.net` |

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes, en remplaçant les valeurs souhaitées :

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
   gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
   gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
   gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   Si vous utilisez [une identité de charge de travail](#azure-workload-and-managed-identities), omettez `azure_storage_access_key` :

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `object_storage.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#connection) :

   ```yaml
   provider: AzureRM
   azure_storage_account_name: <YOUR_AZURE_STORAGE_ACCOUNT_NAME>
   azure_storage_access_key: <YOUR_AZURE_STORAGE_ACCOUNT_KEY>
   azure_storage_domain: blob.core.windows.net
   ```

   Si vous utilisez [une identité de charge de travail ou une identité managée](#azure-workload-and-managed-identities), omettez `azure_storage_access_key` :

   ```yaml
   provider: AzureRM
   azure_storage_account_name: <YOUR_AZURE_STORAGE_ACCOUNT_NAME>
   azure_storage_domain: blob.core.windows.net
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
   ```

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
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'AzureRM',
             'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
             'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
             'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

    Si vous utilisez [une identité managée](#azure-workload-and-managed-identities), omettez `azure_storage_access_key`.

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>'
   }
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Pour les installations compilées manuellement, Workhorse doit également être configuré avec les identifiants Azure. Cela n'est pas nécessaire dans les installations du package Linux car les paramètres Workhorse sont renseignés à partir des paramètres précédents.

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   production: &base
     object_store:
       enabled: true
       proxy_download: false
       connection:
         provider: AzureRM
         azure_storage_account_name: '<AZURE STORAGE ACCOUNT NAME>'
         azure_storage_access_key: '<AZURE STORAGE ACCESS KEY>'
       objects:
         artifacts:
           bucket: gitlab-artifacts
         external_diffs:
           bucket: gitlab-mr-diffs
         lfs:
           bucket: gitlab-lfs
         uploads:
           bucket: gitlab-uploads
         packages:
           bucket: gitlab-packages
         dependency_proxy:
           bucket: gitlab-dependency-proxy
         terraform_state:
           bucket: gitlab-terraform-state
         ci_secure_files:
           bucket: gitlab-ci-secure-files
         pages:
           bucket: gitlab-pages
   ```

1. Modifiez `/home/git/gitlab-workhorse/config.toml` et ajoutez ou modifiez les lignes suivantes :

     ```toml
     [object_storage]
       provider = "AzureRM"

     [object_storage.azurerm]
       azure_storage_account_name = "<AZURE STORAGE ACCOUNT NAME>"
       azure_storage_access_key = "<AZURE STORAGE ACCESS KEY>"
     ```

   Si vous utilisez un domaine de stockage Azure personnalisé, `azure_storage_domain` ne doit **pas** être défini dans la configuration Workhorse. Ces informations sont échangées dans un appel API entre GitLab Rails et Workhorse.

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

#### Identités de charge de travail et identités managées Azure {#azure-workload-and-managed-identities}

{{< history >}}

- [Introduit dans GitLab 17.9](https://gitlab.com/gitlab-org/gitlab/-/issues/242245)

{{< /history >}}

Pour utiliser les [identités de charge de travail Azure](https://azure.github.io/azure-workload-identity/docs/) ou les [identités managées](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/), omettez `azure_storage_access_key` de la configuration. Lorsque `azure_storage_access_key` est vide, GitLab tente de :

1. Obtenir des identifiants temporaires avec [une identité de charge de travail](https://learn.microsoft.com/en-us/entra/workload-id/workload-identities-overview). `AZURE_TENANT_ID`, `AZURE_CLIENT_ID` et `AZURE_FEDERATED_TOKEN_FILE` doivent être dans l'environnement.
1. Si une identité de charge de travail n'est pas disponible, demandez des identifiants auprès du [service de métadonnées d'instance Azure](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token).
1. Obtenez une [clé de délégation d'utilisateur](https://learn.microsoft.com/en-us/rest/api/storageservices/get-user-delegation-key).
1. Générez un jeton SAS avec cette clé pour accéder à un blob de compte de stockage.

Assurez-vous que l'identité a le rôle `Storage Blob Data Contributor` qui lui est attribué.

### Exemples de configuration spécifiques aux fournisseurs {#provider-specific-configuration-examples}

Les exemples suivants montrent la configuration pour des fournisseurs compatibles S3 spécifiques qui nécessitent des paramètres non définis par défaut. Pour tout fournisseur compatible S3 non répertorié ici, utilisez la [configuration de base compatible S3](#s3-compatible-providers) avec le `endpoint` approprié pour votre fournisseur.

#### Oracle Cloud Infrastructure {#oracle-cloud-infrastructure}

Oracle Cloud Infrastructure S3 nécessite les paramètres suivants :

| Paramètre                         | Valeur |
|:--------------------------------|:------|
| `enable_signature_v4_streaming` | `false` |
| `path_style`                    | `true` |

Si `enable_signature_v4_streaming` est défini sur `true`, vous pouvez voir l'erreur suivante dans `production.log` :

```plaintext
STREAMING-AWS4-HMAC-SHA256-PAYLOAD is not supported
```

#### Storj Gateway (SJ) {#storj-gateway-sj}

> [!note]
> Le Storj Gateway [ne prend pas en charge](https://github.com/storj/gateway-st/blob/4b74c3b92c63b5de7409378b0d1ebd029db9337d/docs/s3-compatibility.md) la copie multi-threads (voir `UploadPartCopy` dans le tableau). Bien qu'une implémentation [soit prévue](https://github.com/storj/roadmap/issues/40), vous devez [désactiver la copie multi-threads](#multi-threaded-copying) jusqu'à sa réalisation.

Le [réseau Storj](https://www.storj.io/) fournit une passerelle API compatible S3. Utilisez l'exemple de configuration suivant :

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://gateway.storjshare.io',
  'path_style' => true,
  'region' => 'eu1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'aws_signature_version' => 2,
  'enable_signature_v4_streaming' => false
}
```

La version de signature doit être `2`. L'utilisation de v4 entraîne une erreur HTTP 411 Length Required. Pour plus d'informations, consultez le [ticket #4419](https://gitlab.com/gitlab-org/gitlab/-/issues/4419).

#### Hitachi Vantara HCP {#hitachi-vantara-hcp}

> [!note]
> Les connexions à HCP peuvent renvoyer une erreur indiquant `SignatureDoesNotMatch - The request signature we calculated does not match the signature you provided. Check your HCP Secret Access key and signing method.` Dans ces cas, définissez `endpoint` sur l'URL du locataire au lieu du namespace, et assurez-vous que les chemins de bucket sont configurés comme `<namespace_name>/<bucket_name>`.

[HCP](https://docs.hitachivantara.com/r/en-us/content-platform/9.7.x/mk-95hcph001/hcp-management-api-reference/introduction-to-the-hcp-management-api/support-for-the-amazon-s3-api) fournit une API compatible S3. Utilisez l'exemple de configuration suivant :

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://<tenant_endpoint>',
  'path_style' => true,
  'region' => 'eu1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'aws_signature_version' => 4,
  'enable_signature_v4_streaming' => false
}

# Example of <namespace_name/bucket_name> formatting
gitlab_rails['object_store']['objects']['artifacts']['bucket'] = '<namespace_name>/<bucket_name>'
```

#### Ceph RGW {#ceph-rgw}

[Ceph RGW](https://docs.ceph.com/en/reef/cephadm/services/rgw/) est une API compatible S3 pour Ceph. Utilisez l'exemple de configuration suivant :

```ruby
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'endpoint' => 'https://rgw-ceph.example.com',
  'region' => 'us-west-1',
  'aws_access_key_id' => 'ACCESS_KEY',
  'aws_secret_access_key' => 'SECRET_KEY',
  'path_style': true
}
```

Pour activer le [chiffrement côté serveur](#server-side-encryption-headers) avec Ceph RGW, vous devez vous connecter via HTTPS. Ceph rejette les requêtes de chiffrement sur les connexions non sécurisées.

## Exemple complet utilisant le formulaire consolidé et Amazon S3 {#full-example-using-the-consolidated-form-and-amazon-s3}

L'exemple suivant utilise AWS S3 pour activer le stockage d'objets pour tous les services pris en charge :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes, en remplaçant les valeurs souhaitées :

   ```ruby
   # Consolidated object storage configuration
   gitlab_rails['object_store']['enabled'] = true
   gitlab_rails['object_store']['proxy_download'] = false
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => '<AWS_ACCESS_KEY_ID>',
     'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
   }
   # OPTIONAL: The following lines are only needed if server side encryption is required
   gitlab_rails['object_store']['storage_options'] = {
     'server_side_encryption' => '<AES256 or aws:kms>',
     'server_side_encryption_kms_key_id' => '<arn:aws:kms:xxx>'
   }
   gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
   gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
   gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
   gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
   gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
   gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
   gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
   gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
   gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   Si vous utilisez des [profils IAM AWS](#use-amazon-instance-profiles), omettez la paire clé/valeur de la clé d'accès AWS et de la clé d'accès secrète. Par exemple :

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `object_storage.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#connection) :

   ```yaml
   provider: AWS
   region: us-east-1
   aws_access_key_id: <AWS_ACCESS_KEY_ID>
   aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
   ```

   Si vous utilisez des [profils IAM AWS](#use-amazon-instance-profiles), omettez la paire clé/valeur de la clé d'accès AWS et de la clé d'accès secrète. Par exemple :

   ```yaml
   provider: AWS
   region: us-east-1
   use_iam_profile: true
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-object-storage --from-file=connection=object_storage.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
        artifacts:
          bucket: gitlab-artifacts
        ciSecureFiles:
          bucket: gitlab-ci-secure-files
          enabled: true
        dependencyProxy:
          bucket: gitlab-dependency-proxy
          enabled: true
        externalDiffs:
          bucket: gitlab-mr-diffs
          enabled: true
        lfs:
          bucket: gitlab-lfs
        object_store:
          connection:
            secret: gitlab-object-storage
          enabled: true
          proxy_download: false
        packages:
          bucket: gitlab-packages
        terraformState:
          bucket: gitlab-terraform-state
          enabled: true
        uploads:
          bucket: gitlab-uploads
   ```

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
           # Consolidated object storage configuration
           gitlab_rails['object_store']['enabled'] = true
           gitlab_rails['object_store']['proxy_download'] = false
           gitlab_rails['object_store']['connection'] = {
             'provider' => 'AWS',
             'region' => 'eu-central-1',
             'aws_access_key_id' => '<AWS_ACCESS_KEY_ID>',
             'aws_secret_access_key' => '<AWS_SECRET_ACCESS_KEY>'
           }
           # OPTIONAL: The following lines are only needed if server side encryption is required
           gitlab_rails['object_store']['storage_options'] = {
             'server_side_encryption' => '<AES256 or aws:kms>',
             'server_side_encryption_kms_key_id' => '<arn:aws:kms:xxx>'
           }
           gitlab_rails['object_store']['objects']['artifacts']['bucket'] = 'gitlab-artifacts'
           gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = 'gitlab-mr-diffs'
           gitlab_rails['object_store']['objects']['lfs']['bucket'] = 'gitlab-lfs'
           gitlab_rails['object_store']['objects']['uploads']['bucket'] = 'gitlab-uploads'
           gitlab_rails['object_store']['objects']['packages']['bucket'] = 'gitlab-packages'
           gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = 'gitlab-dependency-proxy'
           gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = 'gitlab-terraform-state'
           gitlab_rails['object_store']['objects']['ci_secure_files']['bucket'] = 'gitlab-ci-secure-files'
           gitlab_rails['object_store']['objects']['pages']['bucket'] = 'gitlab-pages'
   ```

   Si vous utilisez des [profils IAM AWS](#use-amazon-instance-profiles), omettez la paire clé/valeur de la clé d'accès AWS et de la clé d'accès secrète. Par exemple :

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   production: &base
     object_store:
       enabled: true
       proxy_download: false
       connection:
         provider: AWS
         aws_access_key_id: <AWS_ACCESS_KEY_ID>
         aws_secret_access_key: <AWS_SECRET_ACCESS_KEY>
         region: eu-central-1
       storage_options:
         server_side_encryption: <AES256 or aws:kms>
         server_side_encryption_key_kms_id: <arn:aws:kms:xxx>
       objects:
         artifacts:
           bucket: gitlab-artifacts
         external_diffs:
           bucket: gitlab-mr-diffs
         lfs:
           bucket: gitlab-lfs
         uploads:
           bucket: gitlab-uploads
         packages:
           bucket: gitlab-packages
         dependency_proxy:
           bucket: gitlab-dependency-proxy
         terraform_state:
           bucket: gitlab-terraform-state
         ci_secure_files:
           bucket: gitlab-ci-secure-files
         pages:
           bucket: gitlab-pages
   ```

   Si vous utilisez des [profils IAM AWS](#use-amazon-instance-profiles), omettez la paire clé/valeur de la clé d'accès AWS et de la clé d'accès secrète. Par exemple :

   ```yaml
   connection:
     provider: AWS
     region: eu-central-1
     use_iam_profile: true
   ```

1. Modifiez `/home/git/gitlab-workhorse/config.toml` et ajoutez ou modifiez les lignes suivantes :

   ```toml
   [object_storage]
     provider = "AWS"

   [object_storage.s3]
     aws_access_key_id = "<AWS_ACCESS_KEY_ID>"
     aws_secret_access_key = "<AWS_SECRET_ACCESS_KEY>"
   ```

   Si vous utilisez des [profils IAM AWS](#use-amazon-instance-profiles), omettez la paire clé/valeur de la clé d'accès AWS et de la clé d'accès secrète. Par exemple :

   ```yaml
   [object_storage.s3]
     use_iam_profile = true
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## Migrer vers le stockage d'objets {#migrate-to-object-storage}

Pour migrer les données locales existantes vers le stockage d'objets, consultez les guides suivants :

- [Artefacts de job](cicd/job_artifacts.md#migrating-to-object-storage) incluant les job logs archivés
- [Objets LFS](lfs/_index.md#migrating-to-object-storage)
- [Importations](raketasks/uploads/migrate.md#migrate-to-object-storage)
- [Diffs de merge request](merge_request_diffs.md#using-object-storage)
- [Packages](packages/_index.md#migrate-packages-between-object-storage-and-local-storage) (fonctionnalité optionnelle)
- [Proxy de dépendances](packages/dependency_proxy.md#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage)
- [Fichiers d'état Terraform](terraform_state.md#migrate-to-object-storage)
- [Contenu Pages](pages/_index.md#migrate-pages-deployments-to-object-storage)
- [Fichiers sécurisés au niveau du projet](cicd/secure_files.md#migrate-to-object-storage)

## Passer au formulaire consolidé {#transition-to-consolidated-form}

Dans la configuration spécifique au stockage :

- La configuration du stockage d'objets pour tous les types d'objets tels que les artefacts CI/CD, les fichiers LFS et les pièces jointes importées est configurée indépendamment.
- Les paramètres de connexion au stockage d'objets tels que les mots de passe et les URL de point de terminaison sont dupliqués pour chaque type.

Par exemple, une installation de package Linux pourrait avoir la configuration suivante :

```ruby
# Original object storage configuration
gitlab_rails['artifacts_object_store_enabled'] = true
gitlab_rails['artifacts_object_store_direct_upload'] = true
gitlab_rails['artifacts_object_store_proxy_download'] = false
gitlab_rails['artifacts_object_store_remote_directory'] = 'artifacts'
gitlab_rails['artifacts_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
gitlab_rails['uploads_object_store_enabled'] = true
gitlab_rails['uploads_object_store_direct_upload'] = true
gitlab_rails['uploads_object_store_proxy_download'] = false
gitlab_rails['uploads_object_store_remote_directory'] = 'uploads'
gitlab_rails['uploads_object_store_connection'] = { 'provider' => 'AWS', 'aws_access_key_id' => 'access_key', 'aws_secret_access_key' => 'secret' }
```

Bien que cela offre une flexibilité en permettant à GitLab de stocker des objets chez différents fournisseurs de cloud, cela crée également une complexité supplémentaire et une redondance inutile. Étant donné que les composants GitLab Rails et Workhorse ont tous deux besoin d'accéder au stockage d'objets, le formulaire consolidé évite la duplication excessive des identifiants.

Le formulaire consolidé n'est utilisé que si toutes les lignes du formulaire d'origine sont omises. Pour passer au formulaire consolidé, supprimez la configuration d'origine (par exemple, `artifacts_object_store_enabled`, ou `uploads_object_store_connection`)

## Migrer des objets vers un autre fournisseur de stockage d'objets {#migrate-objects-to-a-different-object-storage-provider}

Vous devrez peut-être migrer les données GitLab dans le stockage d'objets vers un autre fournisseur de stockage d'objets. Les étapes suivantes vous montrent comment procéder en utilisant [Rclone](https://rclone.org/).

Les étapes supposent que vous déplacez le bucket `uploads`, mais le même processus fonctionne pour d'autres buckets.

Prérequis :

- Choisissez l'ordinateur sur lequel exécuter Rclone. Selon la quantité de données que vous migrez, Rclone peut devoir s'exécuter pendant une longue période, vous devriez donc éviter d'utiliser un ordinateur portable ou de bureau susceptible de passer en mode économie d'énergie. Vous pouvez utiliser votre serveur GitLab pour exécuter Rclone.

1. [Installez](https://rclone.org/downloads/) Rclone.
1. Configurez Rclone en exécutant la commande suivante :

   ```shell
   rclone config
   ```

   Le processus de configuration est interactif. Ajoutez au moins deux « remotes » : un pour le fournisseur de stockage d'objets sur lequel se trouvent actuellement vos données (`old`), et un pour le fournisseur vers lequel vous migrez (`new`).

1. Vérifiez que vous pouvez lire les anciennes données. L'exemple suivant fait référence au bucket `uploads`, mais votre bucket peut avoir un nom différent :

   ```shell
   rclone ls old:uploads | head
   ```

   Cela devrait afficher une liste partielle des objets actuellement stockés dans votre bucket `uploads`. Si vous obtenez une erreur, ou si la liste est vide, revenez en arrière et mettez à jour votre configuration Rclone en utilisant `rclone config`.

1. Effectuez une copie initiale. Vous n'avez pas besoin de mettre votre serveur GitLab hors ligne pour cette étape.

   ```shell
   rclone sync -P old:uploads new:uploads
   ```

1. Une fois la première synchronisation terminée, utilisez l'interface web ou l'interface en ligne de commande de votre nouveau fournisseur de stockage d'objets pour vérifier qu'il y a des objets dans le nouveau bucket. S'il n'y en a aucun, ou si vous rencontrez une erreur lors de l'exécution de `rclone sync`, vérifiez votre configuration Rclone et réessayez.

Après avoir effectué au moins une copie Rclone réussie de l'ancien emplacement vers le nouvel emplacement, planifiez une maintenance et mettez votre serveur GitLab hors ligne. Pendant votre fenêtre de maintenance, vous devez effectuer deux choses :

1. Effectuez une dernière exécution de `rclone sync`, sachant que vos utilisateurs ne peuvent pas ajouter de nouveaux objets, de sorte que vous ne laissez aucun objet dans l'ancien bucket.
1. Mettez à jour la configuration du stockage d'objets de votre serveur GitLab pour utiliser le nouveau fournisseur pour `uploads`.

## Alternatives au stockage sur système de fichiers {#alternatives-to-file-system-storage}

Si vous travaillez à la [mise à l'échelle](reference_architectures/_index.md) de votre implémentation GitLab, ou à l'ajout de tolérance aux pannes et de redondance, vous envisagez peut-être de supprimer les dépendances envers les systèmes de fichiers en bloc ou réseau. Consultez les guides supplémentaires suivants :

1. Assurez-vous que le [répertoire personnel de l'utilisateur `git`](https://docs.gitlab.com/omnibus/settings/configuration/#move-the-home-directory-for-a-user) se trouve sur le disque local.
1. Configurez la [recherche des clés SSH dans la base de données](operations/fast_ssh_key_lookup.md) pour éliminer le besoin d'un fichier `authorized_keys` partagé.
1. [Empêcher l'utilisation du disque local pour les job logs](cicd/job_logs.md#prevent-local-disk-usage).
1. [Désactiver le stockage local de Pages](pages/_index.md#disable-pages-local-storage).

## Dépannage {#troubleshooting}

### Les objets ne sont pas inclus dans les sauvegardes GitLab {#objects-are-not-included-in-gitlab-backups}

Comme indiqué dans [la documentation sur les sauvegardes](backup_restore/backup_gitlab.md#object-storage), les objets ne sont pas inclus dans les sauvegardes GitLab. Vous pouvez activer les sauvegardes avec votre fournisseur de stockage d'objets à la place.

### Utiliser des buckets séparés {#use-separate-buckets}

L'utilisation de buckets séparés pour chaque type de données est l'approche recommandée pour GitLab. Cela garantit qu'il n'y a pas de collisions entre les différents types de données que GitLab stocke. Le [ticket 292958](https://gitlab.com/gitlab-org/gitlab/-/issues/292958) propose d'activer l'utilisation d'un seul bucket.

Avec les installations de packages Linux et les installations compilées manuellement, il est possible de diviser un seul bucket réel en plusieurs buckets virtuels. Si votre bucket de stockage d'objets s'appelle `my-gitlab-objects`, vous pouvez configurer les importations pour aller dans `my-gitlab-objects/uploads`, les artefacts dans `my-gitlab-objects/artifacts`, etc. L'application se comporte comme si ce sont des buckets séparés. L'utilisation de préfixes de bucket [peut ne pas fonctionner correctement avec les sauvegardes Helm](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3376).

Les installations basées sur Helm nécessitent des buckets séparés pour [gérer les restaurations de sauvegardes](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files).

### Problèmes de compatibilité avec l'API S3 {#s3-api-compatibility-issues}

Si vous rencontrez des erreurs avec un fournisseur compatible S3, consultez [la compatibilité S3 et les modes d'échec connus](#s3-compatibility-and-known-failure-modes) pour les causes courantes et les ajustements de configuration. Une erreur `411 Length Required` dans `production.log` est généralement causée par la diffusion de signature. Définissez `enable_signature_v4_streaming: false` pour résoudre le problème.

### Artefacts toujours téléchargés avec le nom de fichier `download` {#artifacts-always-downloaded-with-filename-download}

Les noms de fichiers des artefacts téléchargés sont définis avec l'en-tête `response-content-disposition` dans la [requête GetObject](https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html). Si le fournisseur S3 ne prend pas en charge cet en-tête, le fichier téléchargé est toujours enregistré sous `download`.

### Proxy Download {#proxy-download}

Les clients peuvent télécharger des fichiers dans le stockage d'objets en recevant une URL pré-signée à durée limitée, ou en faisant en sorte que GitLab proxy les données du stockage d'objets vers le client. Le téléchargement de fichiers directement depuis le stockage d'objets permet de réduire la quantité de trafic sortant que GitLab doit traiter.

Lorsque les fichiers sont stockés sur un stockage en bloc local ou NFS, GitLab doit agir comme un proxy. Ce n'est pas le comportement par défaut avec le stockage d'objets.

Le paramètre `proxy_download` contrôle ce comportement : la valeur par défaut est `false`. Vérifiez cela dans la documentation pour chaque cas d'utilisation.

Définissez `proxy_download` sur `true` si vous souhaitez que GitLab proxy les fichiers. La performance du serveur GitLab peut être fortement impactée si `proxy_download` est défini sur `true`. Les déploiements serveur de GitLab ont `proxy_download` défini sur `false`.

Lorsque `proxy_download` est défini sur `false`, GitLab renvoie une [redirection HTTP 302 avec une URL de stockage d'objets pré-signée à durée limitée](https://gitlab.com/gitlab-org/gitlab/-/issues/32117#note_218532298). Cela peut entraîner certains des problèmes suivants :

- Si GitLab utilise HTTP non sécurisé pour accéder au stockage d'objets, les clients peuvent générer des erreurs de déclassement `https->http` et refuser de traiter la redirection. La solution est que GitLab utilise HTTPS. LFS, par exemple, génère cette erreur :

  ```plaintext
  LFS: lfsapi/client: refusing insecure redirect, https->http
  ```

- Les clients doivent faire confiance à l'autorité de certification qui a émis le certificat de stockage d'objets, ou peuvent renvoyer des erreurs TLS courantes telles que :

  ```plaintext
  x509: certificate signed by unknown authority
  ```

- Les clients ont besoin d'un accès réseau au stockage d'objets. Les pare-feux réseau pourraient bloquer l'accès. Les erreurs qui pourraient résulter de l'absence de cet accès incluent :

  ```plaintext
  Received status code 403 from server: Forbidden
  ```

- Les buckets de stockage d'objets doivent autoriser l'accès Cross-Origin Resource Sharing (CORS) depuis l'URL de l'instance GitLab. Tenter de charger un PDF dans la page du dépôt peut afficher l'erreur suivante :

  ```plaintext
  An error occurred while loading the file. Please try again later.
  ```

  Consultez [la documentation LFS](lfs/_index.md#error-viewing-a-pdf-file) pour plus de détails.

> [!warning]
> Les URL pré-signées sont limitées dans le temps mais ne sont pas liées à un utilisateur spécifique. Tout utilisateur qui obtient une URL pré-signée peut accéder à l'objet sans authentification pendant la durée de validité de l'URL. Les téléchargements directs peuvent également entraîner des frais de bande passante entre votre fournisseur de stockage d'objets et le client.

### Non-correspondance ETag {#etag-mismatch}

En utilisant les paramètres GitLab par défaut, certains systèmes de stockage d'objets compatibles S3 tels qu'[Alibaba](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1564) peuvent générer des erreurs `ETag mismatch`.

#### Chiffrement Amazon S3 {#amazon-s3-encryption}

Si vous observez cette erreur de non-correspondance ETag avec Amazon Web Services S3, c'est probablement dû aux [paramètres de chiffrement de votre bucket](https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonResponseHeaders.html). Pour résoudre ce problème, vous avez deux options :

- [Utiliser le formulaire consolidé](#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
- [Utiliser des profils d'instance Amazon](#use-amazon-instance-profiles).

Le formulaire consolidé est recommandé pour les services compatibles S3. Certains services peuvent également nécessiter une configuration côté serveur supplémentaire, comme l'activation d'un mode de compatibilité, pour résoudre les erreurs de non-correspondance ETag.

Sans le formulaire consolidé ou les profils d'instance activés, GitLab Workhorse importe des fichiers vers S3 en utilisant des URL pré-signées qui n'ont pas d'en-tête HTTP `Content-MD5` calculé pour elles. Pour s'assurer que les données ne sont pas corrompues, Workhorse vérifie que le hachage MD5 des données envoyées est égal à l'en-tête ETag renvoyé par le serveur S3. Lorsque le chiffrement est activé, ce n'est pas le cas, ce qui amène Workhorse à signaler une erreur `ETag mismatch` lors d'une importation.

Lorsque le formulaire consolidé est :

- Utilisé avec un stockage d'objets compatible S3 ou un profil d'instance, Workhorse utilise son client S3 interne qui dispose des identifiants S3 afin de pouvoir calculer l'en-tête `Content-MD5`. Cela élimine le besoin de comparer les en-têtes ETag renvoyés par le serveur S3.
- Non utilisé avec un stockage d'objets compatible S3, Workhorse revient à l'utilisation des URL pré-signées.

#### Chiffrement Google Cloud Storage {#google-cloud-storage-encryption}

{{< history >}}

- [Introduit dans GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/issues/441782).

{{< /history >}}

Des erreurs de non-correspondance ETag se produisent également dans Google Cloud Storage (GCS) lors de l'activation du [chiffrement des données avec des clés de chiffrement gérées par le client (CMEK)](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys).

Pour utiliser CMEK, utilisez le [formulaire consolidé](#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

### Copie multi-threads {#multi-threaded-copying}

GitLab utilise l'[API S3 Upload Part Copy](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPartCopy.html) pour accélérer la copie de fichiers dans un bucket. Cette fonctionnalité n'est pas prise en charge par certains fournisseurs compatibles S3 et ils [renvoient une erreur 404 lors de l'importation](https://gitlab.com/gitlab-org/gitlab/-/issues/300604).

Pour désactiver la copie multi-threads, demandez à un administrateur GitLab avec un [accès à la console Rails](feature_flags/_index.md#how-to-enable-and-disable-features-behind-flags) d'exécuter la commande suivante :

```ruby
Feature.disable(:s3_multithreaded_uploads)
```

### Tests manuels via la console Rails {#manual-testing-through-rails-console}

Utilisez cette approche pour vérifier la connectivité du stockage d'objets lorsque vous suspectez une mauvaise configuration. L'exemple suivant teste une connexion, écrit un objet de test et le relit.

1. Démarrez une [console Rails](operations/rails_console.md).
1. Configurez la connexion au stockage d'objets, en utilisant les mêmes paramètres que vous avez configurés dans `/etc/gitlab/gitlab.rb`, au format d'exemple suivant :

   Exemple de connexion utilisant la configuration d'importation existante :

   ```ruby
   settings = Gitlab.config.uploads.object_store.connection.deep_symbolize_keys
   connection = Fog::Storage.new(settings)
   ```

   Exemple de connexion utilisant des clés d'accès :

   ```ruby
   connection = Fog::Storage.new(
     {
       provider: 'AWS',
       region: 'eu-central-1',
       aws_access_key_id: '<AWS_ACCESS_KEY_ID>',
       aws_secret_access_key: '<AWS_SECRET_ACCESS_KEY>'
     }
   )
   ```

   Exemple de connexion utilisant des profils IAM AWS :

   ```ruby
   connection = Fog::Storage.new(
     {
       provider: 'AWS',
       use_iam_profile: true,
       region: 'us-east-1'
     }
   )
   ```

1. Spécifiez le nom du bucket à tester, écrivez, puis lisez un fichier de test.

   ```ruby
   dir = connection.directories.new(key: '<bucket-name-here>')
   f = dir.files.create(key: 'test.txt', body: 'test')
   pp f
   pp dir.files.head('test.txt')
   ```

#### Activer le débogage supplémentaire {#enable-additional-debugging}

{{< history >}}

- Prise en charge de la variable d'environnement `AWS_DEBUG` [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198651) dans GitLab 18.3.

{{< /history >}}

Vous pouvez également activer un débogage supplémentaire pour voir les requêtes HTTP. Vous devriez le faire dans la [console Rails](operations/rails_console.md) pour éviter de divulguer des identifiants dans les fichiers journaux. Ce qui suit montre comment activer le débogage des requêtes pour différents fournisseurs :

{{< tabs >}}

{{< tab title="Amazon S3" >}}

Définissez la variable d'environnement `EXCON_DEBUG` :

```ruby
ENV['EXCON_DEBUG'] = "1"
```

Vous pouvez également activer la journalisation des en-têtes de requête et de réponse HTTP S3 dans les journaux GitLab Workhorse en définissant la variable d'environnement `AWS_DEBUG` sur `1`. Pour le package Linux (Omnibus) :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez les lignes suivantes :

   ```ruby
   gitlab_workhorse['env'] = {
     'AWS_DEBUG' => '1'
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   Les en-têtes de requête et de réponse du stockage compatible S3 sont consignés dans `/var/log/gitlab/gitlab-workhorse/current`.

{{< /tab >}}

{{< tab title="Google Cloud Storage" >}}

Configurez le logger pour qu'il enregistre dans `STDOUT` :

```ruby
Google::Apis.logger = Logger::new(STDOUT)
```

{{< /tab >}}

{{< tab title="Azure Blob Storage" >}}

Définissez la variable d'environnement `DEBUG` :

```ruby
ENV['DEBUG'] = "1"
```

{{< /tab >}}

{{< /tabs >}}

### Réinitialiser la base de données de suivi Geo pour garantir la cohérence complète des objets {#reset-the-geo-tracking-database-to-ensure-full-objects-consistency}

Supposons le scénario Geo suivant :

- Un environnement est composé d'un nœud Geo principal et d'un nœud secondaire.
- Vous avez [migré vers le stockage d'objets](#migrate-to-object-storage) sur le principal.
  - Le secondaire utilise des compartiments de stockage d'objets distincts.
  - L'option « Allow this secondary site to replicate content on Object Storage » est activée.

De telles migrations peuvent amener les objets à être marqués comme synchronisés dans la base de données de suivi alors qu'ils sont physiquement absents du stockage d'objets. Dans ce cas, [réinitialisez la réplication de votre site Geo secondaire](geo/replication/troubleshooting/synchronization_verification.md#resetting-geo-secondary-site-replication) pour garantir que l'état des objets reste cohérent après la migration.

### Incohérences après la migration vers le stockage d'objets {#inconsistencies-after-migrating-to-object-storage}

Des incohérences de données peuvent se produire lors de la migration du stockage local vers le stockage d'objets. En particulier en combinaison avec [Geo](geo/replication/object_storage.md), lorsque des fichiers ont été supprimés manuellement avant la migration.

Par exemple, un administrateur d'instance supprime manuellement plusieurs artefacts sur le système de fichiers local. Ces modifications ne sont pas correctement propagées à la base de données et entraînent des incohérences. Après la migration vers le stockage d'objets, ces incohérences persistent et peuvent provoquer des frictions. Les secondaires Geo peuvent continuer à essayer de répliquer ces fichiers car ils sont toujours référencés dans la base de données mais n'existent plus.

#### Identifier les incohérences lors de l'utilisation de Geo {#identify-inconsistencies-when-using-geo}

Supposons le scénario Geo suivant :

- Un environnement est composé d'un nœud Geo principal et d'un nœud secondaire
- Les deux systèmes ont été migrés vers le stockage d'objets
  - Le secondaire utilise le même stockage d'objets que le principal
  - L'option `Allow this secondary site to replicate content on Object Storage` est désactivée
- Plusieurs téléversements ont été supprimés manuellement avant la migration vers le stockage d'objets
  - Pour cet exemple, deux images qui ont été téléversées vers un ticket

Dans un tel scénario, le secondaire n'a plus besoin de répliquer des données puisqu'il utilise le même stockage d'objets que le principal. En raison des incohérences, les administrateurs peuvent observer que le secondaire essaie toujours de répliquer des données :

Sur le site principal :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Examinez le **site principal** et vérifiez les informations de vérification. Tous les téléversements ont été vérifiés : ![Le tableau de bord des sites Geo affichant la vérification réussie du principal.](img/geo_primary_uploads_verification_v17_11.png)
1. Examinez le **site secondaire** et vérifiez les informations de vérification. Notez que deux téléversements sont toujours en cours de synchronisation, même si le secondaire devrait utiliser le même stockage d'objets. Cela signifie qu'il ne devrait pas avoir à synchroniser les téléversements : ![Le tableau de bord des sites Geo affichant les incohérences du secondaire.](img/geo_secondary_uploads_inconsistencies_v17_11.png)

#### Nettoyer les incohérences {#clean-up-inconsistencies}

> [!warning]
> Assurez-vous de disposer d'une sauvegarde récente et fonctionnelle avant d'exécuter toute commande de suppression.

Sur la base du scénario précédent, plusieurs **téléversements** causent des incohérences, utilisées comme exemple ci-dessous.

Procédez comme suit pour supprimer correctement les éventuels résidus :

1. Associez les incohérences identifiées à leurs noms de modèle respectifs. Le nom du modèle est nécessaire dans les étapes suivantes.

   | Type de stockage d'objets      | Nom du modèle                                              |
   |--------------------------|---------------------------------------------------------|
   | Sauvegardes                  | non applicable                                          |
   | Registre de conteneurs       | non applicable                                          |
   | Mattermost               | non applicable                                          |
   | Cache de runner à mise à l'échelle automatique | non applicable                                          |
   | Fichiers sécurisés             | `Ci::SecureFile`                                        |
   | Artefacts de job            | `Ci::JobArtifact` et `Ci::PipelineArtifact`            |
   | Objets LFS              | `LfsObject`                                             |
   | Importations                  | `Upload`                                                |
   | Diffs de merge request      | `MergeRequestDiff`                                      |
   | Packages                 | `Packages::PackageFile`                                 |
   | Proxy de dépendances         | `DependencyProxy::Blob` et `DependencyProxy::Manifest` |
   | Fichiers d'état Terraform    | `Terraform::StateVersion`                               |
   | Contenu Pages            | `PagesDeployment`                                       |

1. Démarrez une [console Rails](operations/rails_console.md).
1. Interrogez tous les « fichiers » qui sont encore stockés localement (au lieu du stockage d'objets) sur la base du nom de modèle de l'étape précédente. Dans ce cas, comme les téléversements sont concernés, le nom de modèle `Upload` est utilisé. Observez comment `openbao.png` est toujours stocké localement :

   ```ruby
   Upload.with_files_stored_locally
   ```

   ```ruby
   #<Upload:0x00007d35b69def68
     id: 108,
     size: 13346,
     path: "c95c1c9bf91a34f7d97346fd3fa6a7be/openbao.png",
     checksum: "db29d233de49b25d2085dcd8610bac787070e721baa8dcedba528a292b6e816b",
     model_id: 2,
     model_type: "Project",
     uploader: "FileUploader",
     created_at: Wed, 02 Apr 2025 05:56:47.941319000 UTC +00:00,
     store: 1,
     mount_point: nil,
     secret: "[FILTERED]",
     version: 2,
     uploaded_by_user_id: 1,
     organization_id: nil,
     namespace_id: nil,
     project_id: 2,
     verification_checksum: nil>]
   ```

1. Utilisez l'`id` des ressources identifiées pour les supprimer correctement. Tout d'abord, vérifiez qu'il s'agit de la bonne ressource en utilisant `find`, puis exécutez `destroy` :

   ```ruby
   Upload.find(108)
   Upload.find(108).destroy
   ```

1. En option, vérifiez que la ressource a été supprimée correctement en exécutant à nouveau `find`, qui ne devrait plus la trouver :

   ```ruby
   Upload.find(108)
   ```

   ```ruby
   ActiveRecord::RecordNotFound: Couldn't find Upload with 'id'=108
   ```

Répétez les étapes pour tous les types de stockage d'objets concernés.

### Les job logs sont manquants dans une instance GitLab multi-nœuds {#job-logs-are-missing-in-a-multi-node-gitlab-instance}

Sur les instances GitLab comportant plus d'un nœud Rails (serveurs exécutant les services web ou Sidekiq), un mécanisme doit être mis en place pour rendre les job logs disponibles sur tous les nœuds après leur envoi depuis le runner. Les job logs peuvent être stockés sur le disque local ou dans le stockage d'objets.

Si NFS n'est pas utilisé et que la [fonctionnalité de journalisation incrémentale](cicd/job_logs.md#incremental-logging) n'a pas été activée, les job logs peuvent être perdus :

1. Le nœud qui reçoit le log du runner écrit le log sur le disque local.
1. Lorsque GitLab tente d'archiver le log, le job s'exécute souvent sur un serveur différent qui ne peut pas accéder au log.
1. Le téléversement vers le stockage d'objets échoue.

L'erreur suivante peut également être consignée dans `/var/log/gitlab/gitlab-rails/exceptions_json.log` :

```yaml
{
  "severity": "ERROR",
  "exception.class": "Ci::AppendBuildTraceService::TraceRangeError",
  "extra.build_id": 425187,
  "extra.body_end": 12955,
  "extra.stream_size": 720,
  "extra.stream_class": {},
  "extra.stream_range": "0-12954"
}
```

Si les artefacts CI sont écrits dans le stockage d'objets dans un environnement multi-nœuds, vous devez [activer la fonctionnalité de journalisation incrémentale](cicd/job_logs.md#configure-incremental-logging).
