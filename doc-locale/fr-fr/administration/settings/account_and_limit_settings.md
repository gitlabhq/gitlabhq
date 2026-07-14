---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "Configurez le nombre maximum de projets que les utilisateurs peuvent créer sur GitLab Self-Managed. Configurez les limites de taille pour les pièces jointes, les poussées et la taille du dépôt."
title: Paramètres du compte et des limites
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les administrateurs GitLab peuvent configurer les limites de projet et de compte sur leur instance, comme :

- Le nombre de projets qu'un utilisateur peut créer.
- Les limites de taille pour les pièces jointes, les poussées et les dépôts.
- La durée et l'expiration des sessions.
- Les paramètres des jetons d'accès, tels que l'expiration et les préfixes.
- Les paramètres de confidentialité et de suppression des utilisateurs.
- Les règles de création pour les organisations et les groupes principaux.

## Limite de projets par défaut {#default-projects-limit}

Vous pouvez configurer le nombre maximum par défaut de projets que les nouveaux utilisateurs peuvent créer dans leur espace de nommage personnel. Cette limite s'applique uniquement aux nouveaux comptes utilisateur créés après la modification du paramètre. Ce paramètre n'est pas rétroactif pour les utilisateurs existants, mais vous pouvez modifier séparément les [limites de projets pour les utilisateurs existants](#projects-limit-for-a-user).

Pour configurer le nombre maximum de projets dans les espaces de nommage personnels pour les nouveaux utilisateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Augmentez ou diminuez la valeur de **Limite de projets par défaut**.

Si vous définissez **Limite de projets par défaut** à 0, les utilisateurs ne sont pas autorisés à créer des projets dans leur espace de nommage personnel. Cependant, des projets peuvent toujours être créés dans un groupe.

### Limite de projets pour un utilisateur {#projects-limit-for-a-user}

Vous pouvez modifier un utilisateur spécifique et changer le nombre maximum de projets que cet utilisateur peut créer dans son espace de nommage personnel :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la liste des utilisateurs, sélectionnez un utilisateur.
1. Sélectionnez **Éditer**.
1. Augmentez ou diminuez la valeur de **Limite des projets**.

## Taille maximale des pièces jointes {#max-attachment-size}

La taille de fichier maximale pour les pièces jointes dans les commentaires et réponses GitLab est de 100 Mo. Pour modifier la taille maximale des pièces jointes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Augmentez ou diminuez en modifiant la valeur dans **Taille maximale des pièces jointes (Mio)**.

Si vous choisissez une taille supérieure à la valeur configurée pour le serveur web, vous pourriez recevoir des erreurs. Pour plus d'informations, consultez la [section de dépannage](#troubleshooting).

Pour les limites de taille de dépôt sur GitLab.com, consultez les [paramètres du compte et des limites](../../user/gitlab_com/_index.md#account-and-limit-settings).

## Taille maximale de poussée {#max-push-size}

Vous pouvez modifier la taille maximale de poussée pour votre instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Augmentez ou diminuez en modifiant la valeur dans **Taille maximale de poussée (Mio)**.

Pour les limites de taille de poussée sur GitLab.com, consultez les [paramètres du compte et des limites](../../user/gitlab_com/_index.md#account-and-limit-settings).

> [!note]
> Lorsque vous [ajoutez des fichiers à un dépôt](../../user/project/repository/web_editor.md#create-a-file) via l'interface web, la taille maximale des pièces jointes est le facteur limitant. Cela se produit car le serveur web doit recevoir le fichier avant que GitLab puisse générer le commit. Utilisez [Git LFS](../../topics/git/lfs/_index.md) pour ajouter des fichiers volumineux à un dépôt. Ce paramètre ne s'applique pas lors de la poussée d'objets Git LFS.

## Limite de taille du dépôt {#repository-size-limit}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les dépôts de votre instance GitLab peuvent croître rapidement, en particulier si vous utilisez LFS. Leur taille peut croître de façon exponentielle, consommant rapidement le stockage disponible. Pour éviter que cela se produise, vous pouvez définir une limite stricte pour la taille de vos dépôts. Cette limite peut être définie globalement, par groupe ou par projet, les limites par projet ayant la priorité la plus élevée.

La limite de taille du dépôt s'applique aux projets privés et publics. Elle inclut les fichiers du dépôt et les objets Git LFS (même lorsqu'ils sont stockés dans un stockage d'objets externe), mais n'inclut pas :

- Artefacts
- Conteneurs
- Paquets
- Extraits de code
- Téléchargements
- Wikis

Il existe de nombreux cas d'utilisation où vous pourriez définir une limite pour la taille du dépôt. Par exemple, considérez le flux de travail suivant :

1. Votre équipe développe des applications qui nécessitent le stockage de fichiers volumineux dans le dépôt d'applications.
1. Bien que vous ayez activé [Git LFS](../../topics/git/lfs/_index.md) pour votre projet, votre stockage a considérablement augmenté.
1. Avant de dépasser le stockage disponible, vous définissez une limite de 10 Go par dépôt.

Sur GitLab Self-Managed et GitLab Dedicated, seul un administrateur GitLab peut définir ces limites. Définir la limite à `0` signifie qu'il n'y a aucune restriction. Pour les limites de taille de dépôt sur GitLab.com, consultez les [paramètres du compte et des limites](../../user/gitlab_com/_index.md#account-and-limit-settings).

Ces paramètres se trouvent dans :

- Les paramètres de chaque projet :
  1. Depuis la page d'accueil du projet, accédez à **Paramètres** > **Général**.
  1. Renseignez le champ **Limite de taille du dépôt (Mio)** dans la section **Naming, topics, avatar**.
  1. Sélectionnez **Sauvegarder les modifications**.
- Les paramètres de chaque groupe :
  1. Depuis la page d'accueil du groupe, accédez à **Paramètres** > **Général**.
  1. Renseignez le champ **Limite de taille du dépôt (Mio)** dans la section **Nommage, visibilité**.
  1. Sélectionnez **Sauvegarder les modifications**.
- Paramètres globaux GitLab :
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Sélectionnez **Paramètres** > **Général**.
  1. Développez la section **Limitations du compte**.
  1. Renseignez le champ **Limite de taille par dépôt (Mio)**.
  1. Sélectionnez **Sauvegarder les modifications**.

La première poussée d'un nouveau projet, y compris les objets LFS, est vérifiée quant à sa taille. Si la somme de leurs tailles dépasse la taille maximale autorisée du dépôt, la poussée est rejetée.

### Vérifier la taille du dépôt {#check-repository-size}

Pour déterminer si un projet approche de sa limite de taille de dépôt configurée :

1. [Consultez l'utilisation de votre stockage](../../user/storage_usage_quotas.md#view-storage). La taille du **Dépôt** inclut à la fois les fichiers du dépôt Git et les objets [Git LFS](../../topics/git/lfs/_index.md).
1. Comparez l'utilisation actuelle à votre limite de taille de dépôt configurée pour estimer la capacité restante.

Vous pouvez également utiliser l'[API Projects](../../api/projects.md) pour récupérer les statistiques du dépôt.

Pour réduire la taille du dépôt, consultez les [méthodes pour réduire la taille du dépôt](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).

## Durée de session {#session-duration}

### Personnaliser la durée de session par défaut {#customize-the-default-session-duration}

Vous pouvez modifier la durée pendant laquelle les utilisateurs peuvent rester connectés sans activité.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Renseignez le champ **Session duration (minutes)**.
   > [!warning]
   > Définir **Session duration (minutes)** à `0` provoque une défaillance de votre instance GitLab. Pour plus d'informations, consultez le [ticket 19469](https://gitlab.com/gitlab-org/gitlab/-/issues/19469).
1. Sélectionnez **Sauvegarder les modifications**.
1. Redémarrez GitLab pour appliquer les modifications.
   > [!note]
   > Pour GitLab Dedicated, soumettez un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) pour demander un redémarrage de votre instance.

Si l'[option **Se souvenir de moi**](#configure-the-remember-me-option) est activée, les sessions des utilisateurs peuvent rester actives indéfiniment.

Pour plus de détails, consultez les [cookies utilisés pour la connexion](../../user/profile/_index.md#cookies-used-for-sign-in).

### Définir l'expiration des sessions à partir de la date de création {#set-sessions-to-expire-from-creation-date}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/395038) dans GitLab 18.0 avec un [feature flag](../feature_flags/_index.md) nommé `session_expire_from_init`. Activé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198734) dans GitLab 18.3. Indicateur de feature flag `session_expire_from_init` supprimé.

{{< /history >}}

Par défaut, les sessions expirent après un délai défini suivant l'inactivité de la session. À la place, vous pouvez configurer les sessions pour qu'elles expirent après un délai défini suivant la création de la session.

Lorsque la durée de session est atteinte, la session se termine et l'utilisateur est déconnecté même si :

- L'utilisateur utilise encore activement la session.
- L'utilisateur a sélectionné [**Se souvenir de moi**](#configure-the-remember-me-option) lors de la connexion.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Cochez la case **Expire session from creation date**.

Après la fin d'une session, une fenêtre invite l'utilisateur à se reconnecter.

### Configurer l'option Se souvenir de moi {#configure-the-remember-me-option}

{{< history >}}

- L'activation et la désactivation du paramètre **Se souvenir de moi** ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/369133) dans GitLab 16.0.

{{< /history >}}

Les utilisateurs peuvent cocher la case **Se souvenir de moi** lors de la connexion. Leur session reste active indéfiniment lorsqu'elle est accédée depuis ce navigateur spécifique. Désactivez ce paramètre pour faire expirer les sessions à des fins de sécurité ou de conformité. La désactivation de ce paramètre garantit que les sessions des utilisateurs expirent après le nombre de minutes d'inactivité défini lorsque vous [personnalisez la durée de votre session](#customize-the-default-session-duration).

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Cochez ou décochez la case **Se souvenir de moi** pour activer ou désactiver ce paramètre.

### Personnaliser la durée de session pour les opérations Git lorsque l'authentification à deux facteurs est activée {#customize-session-duration-for-git-operations-when-2fa-is-enabled}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

<!-- The history line is too old, but must remain until `feature_flags/development/two_factor_for_cli.yml` is removed -->

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/296669) dans GitLab 13.9 avec un [feature flag](../feature_flags/_index.md) nommé `two_factor_for_cli`. Désactivé par défaut. Ce feature flag affecte également l'[authentification à deux facteurs pour les opérations Git via SSH](../../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations).

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité n'est pas prête pour une utilisation en production.

Les administrateurs GitLab peuvent choisir de personnaliser la durée de session (en minutes) pour les opérations Git lorsque l'authentification à deux facteurs est activée. La valeur par défaut est 15 et peut être définie sur une valeur comprise entre 1 et 10080.

Pour définir une limite sur la durée de validité de ces sessions :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Durée de session pour les opérations Git lorsque l'A2F est activée (minutes)**.
1. Sélectionnez **Sauvegarder les modifications**.

## Autoriser les propriétaires de groupe principal à créer des comptes de service {#allow-top-level-group-owners-to-create-service-accounts}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726) dans GitLab 17.5 [avec un feature flag](../feature_flags/_index.md) nommé `allow_top_level_group_owners_to_create_service_accounts` pour GitLab Self-Managed. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502) dans GitLab 17.6. Indicateur de feature flag `allow_top_level_group_owners_to_create_service_accounts` supprimé.

{{< /history >}}

Par défaut, seuls les administrateurs peuvent créer des comptes de service. Vous pouvez configurer GitLab pour permettre également aux propriétaires de groupe principal de créer des comptes de service.

Prérequis :

- Vous devez disposer d'un accès administrateur.

Pour autoriser les propriétaires de groupe principal à créer des comptes de service :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Sous **Création d'un compte de service**, cochez la case **Allow top-level group owners to create Service accounts**.
1. Sélectionnez **Sauvegarder les modifications**.

## Exiger des dates d'expiration pour les nouveaux jetons d'accès {#require-expiration-dates-for-new-access-tokens}

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/470192) dans GitLab 17.3.

{{< /history >}}

Prérequis :

- Vous devez être un administrateur.

Vous pouvez exiger que tous les nouveaux jetons d'accès aient une date d'expiration. Ce paramètre est activé par défaut et s'applique à :

- Les jetons d'accès personnels pour les utilisateurs non liés à un compte de service.
- Les jetons d'accès de groupe.
- Les jetons d'accès au projet.

Pour les jetons d'accès personnels des comptes de service, utilisez le paramètre `service_access_tokens_expiration_enforced` dans l'[API des paramètres d'application](../../api/settings.md).

Pour exiger des dates d'expiration pour les nouveaux jetons d'accès :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Cochez la case **Personal / Project / Group access token expiration**.
1. Sélectionnez **Sauvegarder les modifications**.

Lorsque vous exigez des dates d'expiration pour les nouveaux jetons d'accès :

- Les utilisateurs doivent définir une date d'expiration qui ne dépasse pas la durée de vie autorisée pour les nouveaux jetons d'accès.
- Pour contrôler la durée de vie maximale des jetons d'accès, utilisez le [paramètre **Limit the lifetime of access tokens**](#limit-the-lifetime-of-access-tokens).

## Période de conservation des jetons d'accès inactifs de projet et de groupe {#inactive-project-and-group-access-token-retention-period}

{{< details >}}

- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Par défaut, GitLab supprime les jetons d'accès de groupe et de projet ainsi que leur [famille de jetons](../../api/personal_access_tokens.md#automatic-reuse-detection) 30 jours après que le dernier jeton actif de la famille de jetons devient inactif. Cette suppression retire tous les jetons de la famille de jetons, l'utilisateur bot associé, et déplace toutes les contributions du bot vers un [utilisateur fantôme](../../user/profile/account/delete_account.md#associated-records).

Prérequis :

- Accès administrateur.

Pour modifier la période de conservation des jetons inactifs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Dans la zone de texte **Période de conservation des jetons d'accès inactifs de projet et de groupe**, modifiez la période de conservation.
   - Si un nombre est défini, tous les jetons d'accès de groupe et de projet sont supprimés après avoir été inactifs pendant le nombre de jours spécifié.
   - Si le champ est vide, les jetons inactifs ne sont jamais supprimés.
1. Sélectionnez **Sauvegarder les modifications**.

Vous pouvez également utiliser l'[API des paramètres d'application](../../api/settings.md) pour modifier l'attribut `inactive_resource_access_tokens_delete_after_days`.

## Préfixe des jetons d'accès personnels {#personal-access-token-prefix}

Vous pouvez spécifier un préfixe pour les jetons d'accès personnels. Les avantages de l'utilisation d'un préfixe personnalisé incluent :

- Les jetons sont distincts et identifiables.
- Les jetons divulgués sont plus facilement identifiables lors des analyses de sécurité.
- Réduit le risque de confusion entre les jetons de différentes instances.

Le préfixe par défaut pour les jetons d'accès personnels est `glpat-`, mais les administrateurs peuvent le modifier. Les [jetons d'accès au projet](../../user/project/settings/project_access_tokens.md) et les [jetons d'accès de groupe](../../user/group/settings/group_access_tokens.md) héritent également de ce préfixe.

> [!warning]
> Par défaut, la détection des secrets côté client, la protection contre la poussée de secrets et la détection des secrets dans les pipelines ne détectent pas les jetons ayant un préfixe personnalisé. Cela pourrait entraîner une augmentation des faux négatifs. Cependant, vous pouvez [personnaliser la détection des secrets dans les pipelines](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets) pour détecter ces jetons.

### Définir un préfixe {#set-a-prefix}

Pour modifier le préfixe global par défaut :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Personal access token prefix**.
1. Sélectionnez **Sauvegarder les modifications**.

Vous pouvez également configurer le préfixe en utilisant l'[API des paramètres](../../api/settings.md).

## Préfixe du jeton d'instance {#instance-token-prefix}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179852) dans GitLab 17.10 [avec un flag](../feature_flags/_index.md) nommé `custom_prefix_for_all_token_types`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible pour les tests, mais n'est pas prête pour une utilisation en production.

Vous pouvez définir un préfixe personnalisé qui est ajouté au début de tous les jetons générés sur votre instance. Les avantages de l'utilisation d'un préfixe personnalisé incluent :

- Les jetons sont distincts et identifiables.
- Les jetons divulgués sont plus facilement identifiables lors des analyses de sécurité.
- Réduit le risque de confusion entre les jetons de différentes instances.

> [!warning]
> Par défaut, la détection des secrets côté client, la protection contre la poussée de secrets et la détection des secrets dans les pipelines ne détectent pas les jetons ayant un préfixe personnalisé. Cela pourrait entraîner une augmentation des faux négatifs. Cependant, vous pouvez [personnaliser la détection des secrets dans les pipelines](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets) pour détecter ces jetons.

Les préfixes de jetons personnalisés s'appliquent uniquement aux jetons suivants :

- [Jetons de job CI/CD](../../security/tokens/_index.md#cicd-job-tokens)
- [Jetons d'agent de cluster](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)
- [Jetons de déploiement](../../user/project/deploy_tokens/_index.md)
- [Jetons client de feature flag](../../operations/feature_flags.md#get-access-credentials)
- [Jetons de flux](../../security/tokens/_index.md#feed-token)
- [Jetons d'e-mail entrant](../../security/tokens/_index.md#incoming-email-token)
- [Secrets d'application OAuth](../../integration/oauth_provider.md)
- [Jetons d'accès personnels](../../user/profile/personal_access_tokens.md)
- [Jetons de déclenchement de pipeline](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)
- [Jetons d'authentification du runner](../../security/tokens/_index.md#runner-authentication-tokens)
- [Jetons SCIM](../../security/tokens/_index.md#token-prefixes)
- [Jetons de workspace](../../security/tokens/_index.md#workspace-token)

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour définir un préfixe de jeton personnalisé :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Limitations du compte**.
1. Dans le champ **Préfixe du jeton d'instance**, saisissez votre préfixe personnalisé.
1. Sélectionnez **Sauvegarder les modifications**.

## Limiter la durée de vie des jetons d'accès {#limit-the-lifetime-of-access-tokens}

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) de la limite de durée de vie maximale autorisée à une valeur augmentée de 400 jours dans GitLab 17.6 [avec un flag](../feature_flags/_index.md) nommé `buffered_token_expiration_limit`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de la limite de durée de vie maximale autorisée étendue est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Le feature flag n'est pas disponible sur GitLab Dedicated.

Les utilisateurs peuvent optionnellement spécifier une durée de vie maximale en jours pour les jetons d'accès ; cela inclut les jetons d'accès [personnels](../../user/profile/personal_access_tokens.md), [de groupe](../../user/group/settings/group_access_tokens.md) et [de projet](../../user/project/settings/project_access_tokens.md). Cette durée de vie n'est pas une obligation et peut être définie sur n'importe quelle valeur supérieure à 0 et inférieure ou égale à :

- 365 jours par défaut.
- 400 jours, si vous activez le feature flag `buffered_token_expiration_limit`. Cette limite étendue n'est pas disponible sur GitLab Dedicated.

Si ce paramètre est laissé vide, la durée de vie maximale autorisée par défaut des jetons d'accès est :

- 365 jours par défaut.
- 400 jours, si vous activez le feature flag `buffered_token_expiration_limit`. Cette limite étendue n'est pas disponible sur GitLab Dedicated.

Les jetons d'accès sont les seuls jetons nécessaires pour l'accès programmatique à GitLab. Cependant, les organisations ayant des exigences de sécurité peuvent souhaiter renforcer la protection en exigeant la rotation régulière de ces jetons.

### Définir une durée de vie {#set-a-lifetime}

Seul un administrateur GitLab peut définir une durée de vie. La laisser vide signifie qu'il n'y a aucune restriction.

Pour définir une durée de vie sur la validité des jetons d'accès :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Maximum allowable lifetime for access tokens (days)**.
1. Sélectionnez **Sauvegarder les modifications**.

Après la définition d'une durée de vie pour les jetons d'accès, GitLab :

- Applique la durée de vie pour les nouveaux jetons d'accès personnels et exige que les utilisateurs définissent une date d'expiration ne dépassant pas la durée de vie autorisée.
- Après trois heures, révoque les anciens jetons sans date d'expiration ou dont la durée de vie est supérieure à la durée de vie autorisée. Trois heures sont accordées pour permettre aux administrateurs de modifier la durée de vie autorisée, ou de la supprimer, avant que la révocation n'ait lieu.

## Limiter la durée de vie des clés SSH {#limit-the-lifetime-of-ssh-keys}

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les utilisateurs peuvent optionnellement spécifier une durée de vie pour les [clés SSH](../../user/ssh.md). Cette durée de vie n'est pas une obligation et peut être définie sur n'importe quel nombre de jours arbitraire.

Les clés SSH sont des identifiants utilisateur pour accéder à GitLab. Cependant, les organisations ayant des exigences de sécurité peuvent souhaiter renforcer la protection en exigeant la rotation régulière de ces clés.

### Définir une durée de vie {#set-a-lifetime-1}

Seul un administrateur GitLab peut définir une durée de vie. La laisser vide signifie qu'il n'y a aucune restriction.

Pour définir une durée de vie sur la validité des clés SSH :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Maximum allowable lifetime for SSH keys (days)**.
1. Sélectionnez **Sauvegarder les modifications**.

Après la définition d'une durée de vie pour les clés SSH, GitLab :

- Exige que les utilisateurs définissent une date d'expiration ne dépassant pas la durée de vie autorisée pour les nouvelles clés SSH. La durée de vie maximale autorisée est :
  - 365 jours par défaut.
  - 400 jours, si vous activez le feature flag `buffered_token_expiration_limit`. Cette limite étendue n'est pas disponible sur GitLab Dedicated.
- Applique la restriction de durée de vie aux clés SSH existantes. Les clés sans expiration ou dont la durée de vie est supérieure au maximum deviennent immédiatement invalides.

> [!note]
> Lorsque la clé SSH d'un utilisateur devient invalide, il peut supprimer et rajouter la même clé.

## Paramètre des applications OAuth de l'utilisateur {#user-oauth-applications-setting}

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Vous devez être un administrateur.

Le paramètre **Applications OAuth de l'utilisateur** contrôle si les utilisateurs peuvent enregistrer des applications pour utiliser GitLab comme fournisseur OAuth. Ce paramètre affecte les applications OAuth appartenant aux utilisateurs, mais n'affecte pas les applications OAuth appartenant aux groupes.

Pour activer ou désactiver le paramètre **Applications OAuth de l'utilisateur** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Limitations du compte**.
1. Cochez ou décochez la case **Applications OAuth de l'utilisateur**.
1. Sélectionnez **Sauvegarder les modifications**.

## Désactiver les modifications du nom de profil utilisateur {#disable-user-profile-name-changes}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour maintenir l'intégrité des informations utilisateur dans les [événements d'audit](../compliance/audit_event_reports.md), les administrateurs GitLab peuvent empêcher les utilisateurs de modifier leur nom de profil.

Pour ce faire :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Sélectionnez **Empêcher les utilisateurs de modifier leur nom de profil**.

Lorsque cette option est sélectionnée, les administrateurs GitLab peuvent toujours mettre à jour les noms d'utilisateur dans la [zone **Admin**](../admin_area.md#administering-users) ou via l'[API](../../api/users.md#modify-a-user).

## Empêcher les utilisateurs de créer des organisations {#prevent-users-from-creating-organizations}

{{< details >}}

- Statut :  Expérimentation

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/423302) dans GitLab 16.7 [avec un flag](../feature_flags/_index.md) nommé `ui_for_organizations`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité n'est pas disponible par défaut. Pour la rendre disponible, un administrateur peut [activer le feature flag](../feature_flags/_index.md) nommé `ui_for_organizations`. Sur GitLab.com et GitLab Dedicated, cette fonctionnalité n'est pas disponible. Cette fonctionnalité n'est pas prête pour une utilisation en production.

Par défaut, les utilisateurs peuvent créer des organisations. Les administrateurs GitLab peuvent empêcher les utilisateurs de créer des organisations.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Décochez la case **Autoriser les utilisateurs à créer des organisations**.

## Empêcher les nouveaux utilisateurs de créer des groupes principaux {#prevent-new-users-from-creating-top-level-groups}

Par défaut, les nouveaux utilisateurs peuvent créer des groupes principaux. Les administrateurs GitLab peuvent empêcher les nouveaux utilisateurs de créer des groupes principaux :

- Dans l'interface utilisateur GitLab, avec les étapes de cette section.
- Avec l'[API des paramètres d'application](../../api/settings.md#update-application-settings).

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Décochez la case **Autoriser les nouveaux utilisateurs à créer des groupes de premier niveau**.

> [!note]
> Ce paramètre s'applique uniquement aux utilisateurs ajoutés après la désactivation du paramètre. Les utilisateurs existants peuvent toujours créer des groupes principaux.

## Empêcher les non-membres de créer des projets et des groupes {#prevent-non-members-from-creating-projects-and-groups}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/426279) dans GitLab 16.8.

{{< /history >}}

Par défaut, les utilisateurs ayant le rôle Invité peuvent créer des projets et des groupes. Les administrateurs GitLab peuvent empêcher ce comportement :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Décochez la case **Autoriser les utilisateurs ayant jusqu'au rôle Invité à créer des groupes et des projets personnels**.
1. Sélectionnez **Sauvegarder les modifications**.

## Empêcher les utilisateurs de rendre leurs profils privés {#prevent-users-from-making-their-profiles-private}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/421310) dans GitLab 17.1 [avec un flag](../feature_flags/_index.md) nommé `disallow_private_profiles`. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/427400) dans GitLab 17.9. Indicateur de feature flag `disallow_private_profiles` supprimé.

{{< /history >}}

Par défaut, les utilisateurs peuvent rendre leurs profils privés. Les administrateurs GitLab peuvent désactiver ce paramètre pour exiger que tous les profils utilisateur soient publics. Ce paramètre n'affecte pas les [utilisateurs internes](../internal_users.md) (parfois appelés « bots »).

Pour empêcher les utilisateurs de rendre leurs profils privés :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Décochez la case **Autoriser les utilisateurs à rendre leurs profils privés**.
1. Sélectionnez **Sauvegarder les modifications**.

Lorsque vous désactivez ce paramètre :

- Tous les profils utilisateur privés deviennent publics.
- L'option pour [définir les profils des nouveaux utilisateurs comme privés par défaut](#set-profiles-of-new-users-to-private-by-default) est également désactivée.

Lorsque vous réactivez ce paramètre, la [visibilité de profil définie précédemment](../../user/profile/_index.md#make-your-user-profile-page-private) par l'utilisateur est sélectionnée.

## Définir les profils des nouveaux utilisateurs comme privés par défaut {#set-profiles-of-new-users-to-private-by-default}

Par défaut, les utilisateurs nouvellement créés ont un profil public. Les administrateurs GitLab peuvent définir les nouveaux utilisateurs avec un profil privé par défaut :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Cochez la case **Rendre les profils des nouveaux utilisateurs privés par défaut**.
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> Si [**Autoriser les utilisateurs à rendre leurs profils privés**](#prevent-users-from-making-their-profiles-private) est désactivé, ce paramètre est également désactivé.

## Empêcher les utilisateurs de supprimer leurs comptes {#prevent-users-from-deleting-their-accounts}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/26053) dans GitLab 16.1 [avec un flag](../feature_flags/_index.md) nommé `deleting_account_disabled_for_users`. Activé par défaut.

{{< /history >}}

Par défaut, les utilisateurs peuvent supprimer leurs propres comptes. Les administrateurs GitLab peuvent empêcher les utilisateurs de supprimer leurs propres comptes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Limitations du compte**.
1. Décochez la case **Autorise les utilisateurs à supprimer leur propre compte**.

## Dépannage {#troubleshooting}

{{< details >}}

- Offre :  GitLab Self-Managed

{{< /details >}}

### 413 Request Entity Too Large {#413-request-entity-too-large}

Lorsque vous joignez un fichier à un commentaire ou une réponse dans GitLab, la [taille maximale des pièces jointes](#max-attachment-size) est probablement supérieure à la valeur autorisée par le serveur web.

Pour augmenter la taille maximale des pièces jointes à 200 Mo dans une installation de [paquet Linux](https://docs.gitlab.com/omnibus/) :

1. Ajoutez cette ligne à `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['client_max_body_size'] = "200m"
   ```

1. Augmentez la taille maximale des pièces jointes.

### Ce dépôt a dépassé sa limite de taille {#this-repository-has-exceeded-its-size-limit}

Si vous recevez des erreurs de poussée intermittentes dans votre [journal des exceptions Rails](../logs/_index.md#exceptions_jsonlog), comme ceci :

```plaintext
Your push to this repository cannot be completed because this repository has exceeded the allocated storage for your project.
```

Les tâches de [maintenance](../housekeeping.md) peuvent entraîner la croissance de la taille de votre dépôt. Pour résoudre ce problème, l'une ou l'autre de ces options aide à court ou moyen terme :

- Augmentez la [limite de taille du dépôt](#repository-size-limit).
- [Réduire la taille du dépôt](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).
