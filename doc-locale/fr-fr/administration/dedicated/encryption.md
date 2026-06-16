---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez le chiffrement pour GitLab Dedicated avec des clés gérées par GitLab ou vos propres clés de chiffrement.
title: Chiffrement de GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

GitLab Dedicated chiffre toutes les données au repos et en transit en utilisant le standard de chiffrement avancé (AES) avec un chiffrement 256 bits via le service de gestion de clés AWS (KMS).

## Chiffrement au repos {#encryption-at-rest}

Toutes les données au repos utilisent le chiffrement en enveloppe, où vos données sont protégées par plusieurs couches de clés de chiffrement.

Chaque service implémente le chiffrement différemment :

| Service                 | Méthode de chiffrement |
| ----------------------- | ----------------- |
| Amazon S3 (SSE-S3)      | Utilise le chiffrement par objet, où chaque objet est chiffré avec sa propre clé unique, qui est ensuite chiffrée par une clé racine gérée par AWS. |
| Amazon EBS              | Utilise le chiffrement au niveau du volume avec une clé de chiffrement de données (DEK) générée par KMS. |
| Amazon RDS (PostgreSQL) | Utilise le chiffrement au niveau du stockage avec une DEK générée par KMS. |
| KMS                     | Gère les clés de chiffrement dans une hiérarchie de clés gérée par AWS, protégée par un module de sécurité matérielle (HSM). |

Dans ce système de chiffrement en enveloppe :

- Vos données sont chiffrées avec des clés de chiffrement de données.
- Les clés de chiffrement de données elles-mêmes sont chiffrées avec des clés de chiffrement.
- Les clés de chiffrement de données chiffrées sont stockées aux côtés de vos données chiffrées.
- Les clés de chiffrement restent dans le service de gestion de clés et ne sont jamais exposées sous forme non chiffrée.
- Toutes les clés de chiffrement sont protégées par des modules de sécurité matériels.

Ce processus de chiffrement en enveloppe fonctionne en faisant dériver à KMS les clés de chiffrement de données spécifiquement pour chaque opération de chiffrement. La clé de chiffrement de données (DEK) chiffre directement vos données, tandis que la DEK elle-même est chiffrée par la clé de chiffrement, créant ainsi une enveloppe sécurisée autour de vos données.

## Chiffrement en transit {#encryption-in-transit}

Toutes les données en transit utilisent le protocole TLS (Transport Layer Security) avec des suites de chiffrement robustes pour protéger les données lors de leur déplacement entre les services et les connexions réseau.

Chaque service utilise TLS :

| Service                 | Méthode de chiffrement |
| ----------------------- | ----------------- |
| Application web         | TLS 1.2/1.3 pour la communication client-serveur |
| Amazon S3               | TLS 1.2/1.3 pour l'accès HTTPS |
| Amazon EBS              | TLS pour la réplication des données entre les centres de données AWS |
| Amazon RDS (PostgreSQL) | Secure Sockets Layer (SSL)/TLS (TLS 1.2 minimum) pour les connexions aux bases de données |
| AWS KMS                 | TLS pour les requêtes API |

Les certificats TLS sont générés et gérés par défaut. Vous pouvez éventuellement configurer des certificats TLS personnalisés pour utiliser les certificats de votre organisation à la place. Pour plus d'informations, consultez [les autorités de certification personnalisées pour les services externes](configure_instance/network_security.md#custom-certificate-authorities-for-external-services).

## Options de chiffrement {#encryption-options}

Les options de chiffrement suivantes sont disponibles :

- Chiffrement géré par GitLab (par défaut) : GitLab gère toute la configuration du chiffrement sans aucune configuration requise.
- Chiffrement géré par le client : Vous fournissez et contrôlez vos propres clés de chiffrement pour un contrôle supplémentaire sur la gestion des clés et les politiques d'accès.

### Chiffrement géré par GitLab {#gitlab-managed-encryption}

Par défaut, GitLab gère toute la configuration du chiffrement pour votre instance. Aucune configuration n'est requise et GitLab configure le chiffrement sur tous les services automatiquement.

Les clés sont protégées par des contrôles de sécurité basés sur le module de sécurité matérielle (HSM) AWS qui empêchent tout accès non autorisé à vos clés de chiffrement et garantissent que vos données restent chiffrées.

### Chiffrement géré par le client {#customer-managed-encryption}

> [!warning]
> Les clés de chiffrement gérées par le client doivent être configurées lors de l'intégration de l'instance. Une fois activées, elles ne peuvent pas être désactivées ou modifiées après le provisionnement.

Les clés de chiffrement gérées par le client vous donnent un contrôle direct sur les clés qui protègent vos données au repos.

Vous créez et gérez des clés AWS KMS dans votre propre compte AWS, puis vous les configurez lorsque vous [créez votre instance](create_instance/_index.md). GitLab utilise vos clés pour chiffrer les données, mais vous conservez le contrôle total sur les politiques d'accès aux clés, la rotation et la gestion du cycle de vie via votre compte AWS.

Vous pouvez configurer des clés à différents niveaux :

- Une clé pour tous les services dans toutes les régions : Utilisez une seule clé multi-région avec des réplicas dans chaque région où vous avez des instances Geo.
- Une clé pour tous les services dans chaque région : Utilisez des clés distinctes pour chaque région où vous avez des instances Geo.
- Clés par service par région : Utilisez des clés différentes pour différents services (sauvegarde, EBS, RDS, S3, recherche avancée) dans chaque région.

#### Créer des clés de chiffrement {#create-encryption-keys}

En raison des exigences de rotation des clés, votre instance ne prend en charge que les clés pour lesquelles AWS génère le matériel de clé cryptographique (le type d'origine `AWS_KMS`), plutôt que les clés pour lesquelles vous importez votre propre matériel de clé. Pour plus d'informations, consultez [créer des clés primaires multi-régions](https://docs.aws.amazon.com/kms/latest/developerguide/create-primary-keys.html).

Prérequis :

- Vous devez avoir reçu votre identifiant de compte GitLab AWS de la part de l'équipe de compte GitLab Dedicated.

Pour créer vos propres clés de chiffrement :

1. Connectez-vous à la console de gestion AWS et accédez au service KMS.
1. Sélectionnez la région dans laquelle vous souhaitez créer une clé.
1. Sélectionnez **Create key**.
1. Dans la section **Configure key** :
   - Pour **Key type**, sélectionnez **Symmetric**.
   - Pour **Key usage**, sélectionnez **Encrypt and decrypt**.
   - Sous **Advanced options** :
     - Pour **Key material origin**, sélectionnez **AWS_KMS**.
     - Pour **Regionality**, sélectionnez **Multi-Region key**.
1. Saisissez un alias, une description et des balises pour votre clé.
1. Sélectionnez les utilisateurs et rôles IAM pouvant administrer la clé.
1. Facultatif. Décochez **Allow key administrators to delete this key** pour éviter toute suppression accidentelle.
1. Sur la page **Define key usage permissions**, dans la section **Other AWS accounts**, saisissez l'identifiant de compte GitLab AWS fourni par votre équipe de compte.
1. Vérifiez que la politique de clé KMS correspond à l'exemple suivant. Remplacez les valeurs de remplacement par vos identifiants de compte et noms d'utilisateur. Les restrictions supplémentaires au-delà de cette politique ne sont pas prises en charge.

   > [!note]
   > Supprimez toutes les conditions ou restrictions supplémentaires, y compris celles qu'AWS pourrait générer automatiquement comme `kms:GrantIsForAWSResource`.

```json
{
    "Version": "2012-10-17",
    "Id": "byok-key-policy",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<CUSTOMER-ACCOUNT-ID>:user/<CUSTOMER-USER>"
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion",
                "kms:ReplicateKey",
                "kms:UpdatePrimaryRegion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::<GITLAB-ACCOUNT-ID>:root"
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*"
        }
    ]
}
```

#### Créer des clés de réplica {#create-replica-keys}

Créez des clés de réplica lorsque vous souhaitez utiliser la même clé de chiffrement sur plusieurs instances Geo dans différentes régions. Pour plus d'informations, consultez [créer des clés de réplica multi-régions](https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-replicate.html).

Prérequis :

- Vous devez avoir créé une clé primaire multi-région.
- Vous devez disposer d'instances Geo supplémentaires dans différentes régions AWS.

Pour créer des clés de réplica :

1. Dans la console AWS KMS, choisissez la clé que vous avez précédemment créée.
1. Sélectionnez l'onglet **Regionality**.
1. Dans la section **Related multi-Region keys**, sélectionnez **Create new replica keys**.
1. Choisissez les régions AWS dans lesquelles vous avez des instances Geo supplémentaires.
1. Conservez l'alias d'origine ou saisissez un alias différent pour la clé de réplica.
1. Facultatif. Saisissez une description et ajoutez des balises.
1. Sélectionnez les utilisateurs et rôles Identity and Access Management (IAM) pouvant administrer la clé de réplica.
1. Facultatif. Cochez ou décochez la case **Allow key administrators to delete this key**.
1. Sur la page **Define key usage permissions**, vérifiez que le compte GitLab AWS est répertorié sous **Other AWS accounts**.
1. Vérifiez la politique et vos paramètres.
1. Sélectionnez **Finish**.
