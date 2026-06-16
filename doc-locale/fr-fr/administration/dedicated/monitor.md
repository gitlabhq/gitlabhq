---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Gérez l'accès aux journaux d'application de votre instance GitLab Dedicated."
title: "Accéder aux journaux d'application pour GitLab Dedicated"
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

GitLab Dedicated livre automatiquement les journaux d'application de votre instance dans un compartiment Amazon S3 privé. Ces journaux contiennent des données d'infrastructure et d'application à des fins de surveillance, de dépannage et de conformité.

Le compartiment S3 contient des journaux qui sont :

- Stockés indéfiniment et chiffrés à l'aide de clés AWS KMS gérées par GitLab.
- Organisés par date au format `YYYY/MM/DD/HH`.
- Transmis en temps réel à l'aide de [Amazon Kinesis Data Firehose](https://aws.amazon.com/firehose/).

Si vous utilisez [vos propres clés de chiffrement](encryption.md#customer-managed-encryption), les journaux d'application utilisent des clés gérées par GitLab, et non votre clé fournie.

## Afficher et gérer l'accès aux journaux d'application {#view-and-manage-application-log-access}

Vous pouvez ajouter, modifier ou supprimer des utilisateurs et des rôles AWS IAM qui disposent d'un accès en lecture seule à vos journaux d'application.

Accédez à vos journaux d'application pour effectuer les opérations suivantes :

- Surveiller et dépanner votre instance GitLab Dedicated.
- Configurer des systèmes automatisés de traitement et de surveillance des journaux.
- Configurer des outils qui récupèrent les journaux depuis le compartiment S3.
- Conserver des pistes d'audit à des fins de rapports de conformité.

Prérequis :

- Vous devez disposer du chemin ARN complet pour chaque utilisateur ou rôle AWS qui nécessite un accès.

> [!note]
> Vous pouvez uniquement utiliser des ARN d'utilisateurs et de rôles IAM. Les ARN Security Token Service (STS) et les caractères génériques ne sont pas pris en charge.

Pour gérer l'accès aux journaux :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **Resource access**.
1. Sous **Application logs**, dans la section **Log access ARNs** :

   - Pour ajouter un accès :  Sélectionnez **Add ARN**, saisissez le chemin ARN complet, puis sélectionnez **Enregistrer**. Par exemple :
     - Utilisateur : `arn:aws:iam::123456789012:user/username`
     - Rôle : `arn:aws:iam::123456789012:role/rolename`
   - Pour modifier un accès :  À côté d'un ARN, sélectionnez l'icône de crayon ({{< icon name="pencil" >}}), mettez à jour l'ARN, puis sélectionnez **Enregistrer**.
   - Pour supprimer un accès :  À côté d'un ARN, sélectionnez l'icône de corbeille ({{< icon name="remove" >}}), puis sélectionnez **Supprimer**.

1. Copiez le **Logs S3 bucket name**. Vos utilisateurs ou rôles autorisés utilisent ce nom de compartiment pour accéder aux journaux.

Après avoir configuré les autorisations ARN et fourni le nom du compartiment à vos utilisateurs, ils peuvent accéder à tous les objets du compartiment S3. Pour vérifier l'accès, utilisez l'[AWS CLI](https://aws.amazon.com/cli/).

Pour plus d'informations sur la façon d'accéder aux compartiments S3 dans AWS, consultez [Accessing an Amazon S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-bucket-intro.html).

## Activer les notifications d'événements S3 {#enable-s3-event-notifications}

Vous pouvez activer les notifications d'événements S3 sur votre compartiment de journalisation GitLab Dedicated pour les intégrer à vos systèmes de surveillance de la sécurité. Les notifications sont envoyées lors de la création de fichiers journaux.

Les notifications d'événements S3 peuvent envoyer des notifications à :

- Files d'attente Amazon Simple Queue Service (SQS)
- Rubriques Amazon Simple Notification Service (SNS)

Les ressources de destination doivent se trouver dans la même région que votre instance GitLab Dedicated.

Pour activer les notifications d'événements S3 :

1. [Créez un ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Dans votre demande de support, incluez :

   - Si vous souhaitez que les notifications soient configurées pour votre région principale, votre région secondaire, ou les deux.
   - Si vous souhaitez utiliser SQS ou SNS pour les notifications.
   - L'ARN de votre file d'attente SQS ou de votre rubrique SNS.

1. Une fois que le Support GitLab a fourni la politique IAM requise, associez-la à votre file d'attente SQS ou à votre rubrique SNS.

Le Support GitLab finalise ensuite la configuration des notifications d'événements S3 sur votre compartiment de journaux S3.
