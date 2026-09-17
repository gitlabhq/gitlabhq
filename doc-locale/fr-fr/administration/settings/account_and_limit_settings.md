---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "Configurer le nombre maximal de projets que les utilisateurs peuvent créer sur GitLab Self-Managed. Configurer les limites de taille applicables aux pièces jointes, aux opérations de push et aux dépôts."
title: Paramètres des comptes et des limites
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dans leur instance, les administrateurs GitLab peuvent configurer plusieurs limites applicables aux projets et aux comptes, notamment :

- Le nombre de projets qu'un utilisateur peut créer.
- Les limites de taille applicables aux pièces jointes, aux opérations de push et aux dépôts.
- La durée et l'expiration des sessions.
- Les paramètres des jetons d'accès, notamment l'expiration et les préfixes.
- Les paramètres de confidentialité et de suppression des utilisateurs.
- Les règles de création des organisations et des groupes principaux.

## Limite de projets par défaut {#default-projects-limit}

Vous pouvez configurer la limite par défaut du nombre de projets que les nouveaux utilisateurs peuvent créer dans leur espace de nommage personnel. Cette limite ne s'applique qu'aux nouveaux comptes utilisateur créés après que vous avez modifié le paramètre. Ce paramètre n'est pas rétroactif pour les utilisateurs existants, mais vous pouvez modifier séparément les [limites de projets pour les utilisateurs existants](#projects-limit-for-a-user).

Pour configurer le nombre maximal de projets dans les espaces de nommage personnels des nouveaux utilisateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Augmentez ou diminuez la valeur de **Limite de projets par défaut**.

Si vous définissez **Limite de projets par défaut** sur 0, les utilisateurs ne sont pas autorisés à créer des projets dans leur espace de nommage personnel. Des projets peuvent toutefois toujours être créés dans un groupe.

### Limite de projets pour un utilisateur {#projects-limit-for-a-user}

Vous pouvez modifier un utilisateur donné et le nombre maximal de projets que cet utilisateur peut créer dans son espace de nommage personnel :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans la liste des utilisateurs, sélectionnez un utilisateur.
1. Sélectionnez **Éditer**.
1. Augmentez ou diminuez la valeur de **Limite de projets**.

## Taille maximale des pièces jointes {#max-attachment-size}

La taille maximale des fichiers joints aux commentaires et aux réponses dans GitLab est de 100 Mo. Pour modifier la taille maximale des pièces jointes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Augmentez ou diminuez cette limite en modifiant la valeur du champ **Taille maximale des pièces jointes (Mio)**.

Si vous choisissez une taille supérieure à la valeur configurée pour le serveur web, vous pouvez rencontrer des erreurs. Pour plus d'informations, consultez la [section de dépannage](#troubleshooting).

Pour connaître les limites de taille des dépôts sur GitLab.com, consultez la section [Paramètres des comptes et des limites](../../user/gitlab_com/_index.md#account-and-limit-settings).

## Taille maximale des opérations de push {#max-push-size}

Vous pouvez modifier la taille maximale des opérations de push dans votre instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Augmentez ou diminuez cette limite en modifiant la valeur du champ **Taille maximale de poussée (Mio)**.

Pour connaître les limites de taille des opérations de push sur GitLab.com, consultez la section [Paramètres des comptes et des limites](../../user/gitlab_com/_index.md#account-and-limit-settings).

> [!note]
> Lorsque vous [ajoutez des fichiers à un dépôt](../../user/project/repository/web_editor.md#create-a-file) depuis l'interface web, la taille maximale des pièces jointes constitue la limite. En effet, le serveur web doit recevoir le fichier avant que GitLab puisse générer le commit. Utilisez [Git LFS](../../topics/git/lfs/_index.md) pour ajouter des fichiers volumineux à un dépôt. Ce paramètre ne s'applique pas lorsque vous effectuez un push d'objets Git LFS.

## Limite de taille des dépôts {#repository-size-limit}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les dépôts de votre instance GitLab peuvent augmenter rapidement en taille, surtout si vous utilisez LFS. Leur taille peut augmenter de façon exponentielle et consommer rapidement l'espace de stockage disponible. Pour éviter cela, vous pouvez définir une limite stricte de taille pour vos dépôts. Cette limite peut être définie globalement, par groupe ou par projet. Les limites définies par projet prévalent.

La limite de taille des dépôts s'applique aux projets privés comme aux projets publics. Elle inclut les fichiers du dépôt et les objets Git LFS, même lorsqu'ils sont stockés dans un stockage d'objets externe, mais n'inclut pas :

- les artefacts ;
- les conteneurs ;
- les paquets ;
- les snippets ;
- les téléversements ;
- les wikis.

Il existe de nombreux cas d'utilisation dans lesquels vous pouvez mettre en place une limite de taille des dépôts. Prenez par exemple le flux de travail suivant :

1. Votre équipe développe des applications dont le dépôt doit contenir des fichiers volumineux.
1. Bien que vous ayez activé [Git LFS](../../topics/git/lfs/_index.md) pour votre projet, votre stockage a considérablement augmenté.
1. Avant de dépasser l'espace de stockage disponible, vous définissez une limite de 10 Go par dépôt.

Dans GitLab Self-Managed et GitLab Dedicated, seul un administrateur GitLab peut définir ces limites. Si vous définissez la limite sur `0`, aucune restriction ne s'applique. Pour connaître les limites de taille des dépôts sur GitLab.com, consultez la section [Paramètres des comptes et des limites](../../user/gitlab_com/_index.md#account-and-limit-settings).

Ces paramètres sont disponibles aux emplacements suivants :

- Dans les paramètres de chaque projet :
  1. Depuis la page d'accueil du projet, accédez à **Paramètres** > **Généralités**.
  1. Renseignez le champ **Limite de taille du dépôt (Mio)** dans la section **Nommage, sujets, avatar**.
  1. Sélectionnez **Enregistrer les modifications**.
- Dans les paramètres de chaque groupe :
  1. Depuis la page d'accueil du groupe, accédez à **Paramètres** > **Généralités**.
  1. Renseignez le champ **Limite de taille du dépôt (Mio)** dans la section **Nommage, visibilité**.
  1. Sélectionnez **Enregistrer les modifications**.
- Dans les paramètres globaux de GitLab :
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Sélectionnez **Paramètres** > **Généralités**.
  1. Développez la section **Limitations du compte**.
  1. Renseignez le champ **Limite de taille par dépôt (Mio)**.
  1. Sélectionnez **Enregistrer les modifications**.

Le premier push d'un nouveau projet fait l'objet d'une vérification de taille, objets LFS compris. Si leur taille totale dépasse la taille maximale autorisée pour le dépôt, le push est rejeté.

### Vérifier la taille du dépôt {#check-repository-size}

Pour déterminer si un projet approche de la limite de taille configurée pour son dépôt :

1. [Consultez votre utilisation du stockage](../../user/storage_usage_quotas.md#view-storage). La taille du **Dépôt** inclut à la fois les fichiers du dépôt Git et les objets [Git LFS](../../topics/git/lfs/_index.md).
1. Comparez l'utilisation actuelle à la limite de taille configurée pour le dépôt afin d'estimer la capacité restante.

Vous pouvez également utiliser l'[API des projets](../../api/projects.md) pour récupérer les statistiques du dépôt.

Pour réduire la taille du dépôt, consultez les [méthodes de réduction de la taille du dépôt](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).

## Durée de session {#session-duration}

### Personnaliser la durée de session par défaut {#customize-the-default-session-duration}

Vous pouvez modifier la durée pendant laquelle les utilisateurs peuvent rester connectés en l'absence d'activité.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Durée de session (minutes)**.
   > [!warning]
   > Définir **Durée de session (minutes)** sur `0` empêche votre instance GitLab de fonctionner. Pour plus d'informations, consultez le [ticket 19469](https://gitlab.com/gitlab-org/gitlab/-/issues/19469).
1. Sélectionnez **Enregistrer les modifications**.
1. Redémarrez GitLab pour appliquer les modifications.
   > [!note]
   > Pour GitLab Dedicated, soumettez un [ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) pour demander le redémarrage de votre instance.

Si l'[option **Se souvenir de moi**](#configure-the-remember-me-option) est activée, les sessions des utilisateurs peuvent rester actives pendant une durée indéfinie.

Pour plus de détails, consultez les [cookies utilisés lors de la connexion](../../user/profile/_index.md#cookies-used-for-sign-in).

### Configurer l'expiration des sessions à partir de leur date de création {#set-sessions-to-expire-from-creation-date}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/395038) dans GitLab 18.0 avec un [feature flag](../feature_flags/_index.md) nommé `session_expire_from_init`. Activé par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198734) dans GitLab 18.3. Suppression du feature flag `session_expire_from_init`.

{{< /history >}}

Par défaut, les sessions expirent après un délai défini à compter du moment où elles deviennent inactives. Vous pouvez plutôt configurer les sessions pour qu'elles expirent après un délai défini à compter de leur création.

Lorsque la durée de session est atteinte, la session prend fin et l'utilisateur est déconnecté, même si :

- l'utilisateur utilise encore activement la session ;
- l'utilisateur a sélectionné [**Se souvenir de moi**](#configure-the-remember-me-option) lors de la connexion.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Cochez la case **Faire expirer les sessions à partir de leur date de création**.

À la fin d'une session, une fenêtre invite l'utilisateur à se reconnecter.

### Configurer l'option Se souvenir de moi {#configure-the-remember-me-option}

Les utilisateurs peuvent cocher la case **Se souvenir de moi** lors de la connexion. Leur session reste active pendant une durée indéfinie lorsqu'elle est utilisée depuis ce navigateur précis. Désactivez ce paramètre pour faire expirer les sessions pour des raisons de sécurité ou de conformité. Si vous désactivez ce paramètre, les sessions des utilisateurs expirent après le nombre de minutes d'inactivité défini lorsque vous [personnalisez la durée de session](#customize-the-default-session-duration).

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Cochez ou décochez la case **Se souvenir de moi** pour activer ou désactiver ce paramètre.

### Personnaliser la durée de session pour les opérations Git lorsque l'authentification à deux facteurs (2FA) est activée {#customize-session-duration-for-git-operations-when-2fa-is-enabled}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

<!-- The history line is too old, but must remain until `feature_flags/development/two_factor_for_cli.yml` is removed -->

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/296669) dans GitLab 13.9 avec un [feature flag](../feature_flags/_index.md) nommé `two_factor_for_cli`. Désactivé par défaut. Ce feature flag affecte également [l'authentification à deux facteurs pour les opérations Git via SSH](../../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations).

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique. Cette fonctionnalité n'est pas prête pour une utilisation en production.

Les administrateurs GitLab peuvent choisir de personnaliser la durée de session, en minutes, pour les opérations Git lorsque l'authentification à deux facteurs est activée. La valeur par défaut est 15, et ce paramètre peut être défini sur une valeur comprise entre 1 et 10 080.

Pour limiter la durée de validité de ces sessions :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Durée de session pour les opérations Git lorsque l'A2F est activée (minutes)**.
1. Sélectionnez **Enregistrer les modifications**.

## Autoriser les Propriétaires de groupes principaux à créer des comptes de service {#allow-top-level-group-owners-to-create-service-accounts}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726) dans GitLab 17.5 [avec un feature flag](../feature_flags/_index.md) nommé `allow_top_level_group_owners_to_create_service_accounts` pour GitLab Self-Managed. Désactivé par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502) dans GitLab 17.6. Suppression du feature flag `allow_top_level_group_owners_to_create_service_accounts`.

{{< /history >}}

Par défaut, seuls les administrateurs peuvent créer des comptes de service. Vous pouvez configurer GitLab pour autoriser également les Propriétaires de groupes principaux à créer des comptes de service.

Prérequis :

- Vous devez disposer d'un accès administrateur.

Pour autoriser les Propriétaires de groupes principaux à créer des comptes de service :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Dans la section **Création d'un compte de service**, cochez la case **Autoriser les Propriétaires de groupes principaux à créer des comptes de service**.
1. Sélectionnez **Enregistrer les modifications**.

## Exiger des dates d'expiration pour les nouveaux jetons d'accès {#require-expiration-dates-for-new-access-tokens}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/470192) dans GitLab 17.3.

{{< /history >}}

Prérequis :

- Vous devez être administrateur.

Vous pouvez exiger que tous les nouveaux jetons d'accès aient une date d'expiration. Ce paramètre est activé par défaut et s'applique aux éléments suivants :

- Les jetons d'accès personnels des utilisateurs qui ne sont pas des comptes de service.
- Les jetons d'accès de groupe.
- Les jetons d'accès au projet.

Pour les jetons d'accès personnels des comptes de service, utilisez le paramètre `service_access_tokens_expiration_enforced` dans l'[API des paramètres d'application](../../api/settings.md).

Pour exiger des dates d'expiration pour les nouveaux jetons d'accès :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Cochez la case **Expiration des jetons d'accès personnels, de projet et de groupe**.
1. Sélectionnez **Enregistrer les modifications**.

Lorsque vous exigez des dates d'expiration pour les nouveaux jetons d'accès :

- Les utilisateurs doivent définir une date d'expiration qui ne dépasse pas la durée de vie autorisée pour les nouveaux jetons d'accès.
- Pour contrôler la durée de vie maximale des jetons d'accès, utilisez le [paramètre **Limiter la durée de vie des jetons d'accès**](#limit-the-lifetime-of-access-tokens).

## Période de conservation des jetons d'accès inactifs de projet et de groupe {#inactive-project-and-group-access-token-retention-period}

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Par défaut, GitLab supprime les jetons d'accès de groupe et de projet ainsi que leur [famille de jetons](../../api/personal_access_tokens.md#automatic-reuse-detection) 30 jours après que le dernier jeton actif de cette famille est devenu inactif. Cette suppression retire tous les jetons de la famille de jetons et l'utilisateur bot associé, et transfère toutes les contributions du bot vers un [utilisateur fantôme](../../user/profile/account/delete_account.md#associated-records).

Prérequis :

- Disposer d'un accès administrateur.

Pour modifier la période de conservation des jetons inactifs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Dans la zone de texte **Période de conservation des jetons d'accès inactifs de projet et de groupe**, modifiez la période de conservation.
   - Si un nombre est défini, tous les jetons d'accès de groupe et de projet sont supprimés une fois inactifs pendant le nombre de jours spécifié.
   - Si le champ est vide, les jetons inactifs ne sont jamais supprimés.
1. Sélectionnez **Enregistrer les modifications**.

Vous pouvez également utiliser l'[API des paramètres d'application](../../api/settings.md) pour modifier l'attribut `inactive_resource_access_tokens_delete_after_days`.

## Préfixe des jetons d'accès personnels {#personal-access-token-prefix}

Vous pouvez spécifier un préfixe pour les jetons d'accès personnels. L'utilisation d'un préfixe personnalisé présente notamment les avantages suivants :

- Les jetons sont distincts et identifiables.
- Les jetons divulgués sont plus faciles à identifier lors des analyses de sécurité.
- Risque réduit de confusion entre les jetons de différentes instances.

Le préfixe par défaut des jetons d'accès personnels est `glpat-`, mais les administrateurs peuvent le modifier. Les [jetons d'accès au projet](../../user/project/settings/project_access_tokens.md) et les [jetons d'accès de groupe](../../user/group/settings/group_access_tokens.md) héritent également de ce préfixe.

> [!warning]
> Par défaut, la détection des secrets côté client, la protection contre le push de secrets et la détection des secrets dans les pipelines ne détectent pas les jetons qui utilisent un préfixe personnalisé. Cela pourrait entraîner une augmentation des faux négatifs. Vous pouvez toutefois [personnaliser la détection des secrets dans les pipelines](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets) afin qu'elle détecte ces jetons.

### Définir un préfixe {#set-a-prefix}

Pour modifier le préfixe global par défaut :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Préfixe des jetons d'accès personnels**.
1. Sélectionnez **Enregistrer les modifications**.

Vous pouvez également configurer le préfixe à l'aide de l'[API des paramètres](../../api/settings.md).

## Préfixe du jeton d'instance {#instance-token-prefix}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179852) dans GitLab 17.10 [avec un feature flag](../feature_flags/_index.md) nommé `custom_prefix_for_all_token_types`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible pour être testée, mais elle n'est pas prête pour une utilisation en production.

Vous pouvez définir un préfixe personnalisé qui est ajouté au début de tous les jetons générés sur votre instance. L'utilisation d'un préfixe personnalisé présente notamment les avantages suivants :

- Les jetons sont distincts et identifiables.
- Les jetons divulgués sont plus faciles à identifier lors des analyses de sécurité.
- Risque réduit de confusion entre les jetons de différentes instances.

> [!warning]
> Par défaut, la détection des secrets côté client, la protection contre le push de secrets et la détection des secrets dans les pipelines ne détectent pas les jetons qui utilisent un préfixe personnalisé. Cela pourrait entraîner une augmentation des faux négatifs. Vous pouvez toutefois [personnaliser la détection des secrets dans les pipelines](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets) afin qu'elle détecte ces jetons.

Les préfixes de jetons personnalisés s'appliquent uniquement aux jetons suivants :

- [Jetons de job CI/CD](../../security/tokens/_index.md#cicd-job-tokens)
- [Jetons d'agent de cluster](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)
- [Jetons de déploiement](../../user/project/deploy_tokens/_index.md)
- [Jetons client des feature flags](../../operations/feature_flags.md#get-access-credentials)
- [Jetons de flux](../../security/tokens/_index.md#feed-token)
- [Jetons d'e-mail entrant](../../security/tokens/_index.md#incoming-email-token)
- [Secrets d'application OAuth](../../integration/oauth_provider.md)
- [Jetons d'accès personnels](../../user/profile/personal_access_tokens.md)
- [Jetons de déclenchement de pipeline](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)
- [Jetons d'authentification du runner](../../security/tokens/_index.md#runner-authentication-tokens)
- [Jetons SCIM](../../security/tokens/_index.md#token-prefixes)
- [Jetons de workspace](../../security/tokens/_index.md#workspace-token)

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour définir un préfixe personnalisé pour les jetons :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Dans le champ **Préfixe du jeton d'instance**, saisissez votre préfixe personnalisé.
1. Sélectionnez **Enregistrer les modifications**.

`gl` est un préfixe réservé. Les instances qui ont sauvegardé leurs paramètres d'application avant que GitLab ne modifie le préfixe de jeton d'instance par défaut de `gl` vers aucun préfixe ont toujours `gl` stocké comme valeur. GitLab traite désormais une valeur `gl` stockée de la même façon qu'aucun préfixe, vous ne pouvez donc pas définir le préfixe de jeton d'instance sur `gl`.

## Limiter la durée de vie des jetons d'accès {#limit-the-lifetime-of-access-tokens}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) de la limite de durée de vie maximale autorisée à une valeur augmentée de 400 jours dans GitLab 17.6 [avec un feature flag](../feature_flags/_index.md) nommé `buffered_token_expiration_limit`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de la limite étendue de durée de vie maximale autorisée. Pour plus d'informations, consultez l'historique. Le feature flag n'est pas disponible sur GitLab Dedicated.

Les utilisateurs peuvent éventuellement spécifier une durée de vie maximale en jours pour les jetons d'accès. Cela inclut les jetons d'accès [personnels](../../user/profile/personal_access_tokens.md), [de groupe](../../user/group/settings/group_access_tokens.md) et [de projet](../../user/project/settings/project_access_tokens.md). Cette durée de vie n'est pas obligatoire et peut être définie sur toute valeur supérieure à 0 et inférieure ou égale à :

- 365 jours par défaut.
- 400 jours si vous activez le feature flag `buffered_token_expiration_limit`. La limite portée à 400 jours n'est pas disponible sur GitLab Dedicated.

Si ce paramètre n'est pas renseigné, la durée de vie autorisée par défaut des jetons d'accès est la suivante :

- 365 jours par défaut.
- 400 jours si vous activez le feature flag `buffered_token_expiration_limit`. La limite portée à 400 jours n'est pas disponible sur GitLab Dedicated.

Les jetons d'accès sont les seuls jetons nécessaires pour accéder à GitLab par programmation. Toutefois, les organisations soumises à des exigences de sécurité peuvent vouloir imposer des mesures de protection supplémentaires en exigeant la rotation régulière de ces jetons.

### Définir la durée de vie {#set-a-lifetime}

Seul un administrateur GitLab peut définir cette durée de vie. Si aucune valeur n'est renseignée, aucune restriction ne s'applique.

Pour définir la durée de validité des jetons d'accès :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Durée de vie maximale autorisée pour les jetons d'accès (jours)**.
1. Sélectionnez **Enregistrer les modifications**.

Une fois la durée de vie des jetons d'accès définie, GitLab :

- Applique la durée de vie pour les nouveaux jetons d'accès personnels et oblige les utilisateurs à définir une date d'expiration ne dépassant pas la durée de vie autorisée.
- Au bout de trois heures, révoque les anciens jetons sans date d'expiration ou dont la durée de vie est supérieure à la durée de vie autorisée. Ce délai permet aux administrateurs de modifier la durée de vie autorisée, ou de la supprimer, avant la révocation des jetons.

## Limiter la durée de vie des clés SSH {#limit-the-lifetime-of-ssh-keys}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les utilisateurs peuvent choisir de définir une durée de vie pour les [clés SSH](../../user/ssh.md). Cette durée de vie n'est pas obligatoire et peut être définie sur le nombre de jours choisi.

Les clés SSH constituent des identifiants utilisateur pour accéder à GitLab. Toutefois, les organisations soumises à des exigences de sécurité peuvent vouloir renforcer la protection en exigeant la rotation régulière de ces clés.

### Définir la durée de vie {#set-a-lifetime-1}

Seul un administrateur GitLab peut définir cette durée de vie. Si aucune valeur n'est renseignée, aucune restriction ne s'applique.

Pour définir la durée de validité des clés SSH :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Durée de vie maximale autorisée pour les clés SSH (jours)**.
1. Sélectionnez **Enregistrer les modifications**.

Une fois la durée de vie des clés SSH définie, GitLab :

- Exige des utilisateurs qu'ils définissent pour les nouvelles clés SSH une date d'expiration ne dépassant pas la durée de vie autorisée. La durée de vie maximale autorisée est la suivante :
  - 365 jours par défaut.
  - 400 jours si vous activez le feature flag `buffered_token_expiration_limit`. La limite portée à 400 jours n'est pas disponible sur GitLab Dedicated.
- Applique la restriction de durée de vie aux clés SSH existantes. Les clés sans expiration ou dont la durée de vie dépasse la durée maximale deviennent immédiatement non valides.

> [!note]
> Lorsqu'une de ses clés SSH devient non valide, l'utilisateur peut la supprimer, puis l'ajouter de nouveau.

## Paramètre « Applications OAuth de l'utilisateur » {#user-oauth-applications-setting}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Être administrateur.

Le paramètre **Applications OAuth de l'utilisateur** détermine si les utilisateurs peuvent enregistrer des applications qui utilisent GitLab comme fournisseur OAuth. Ce paramètre concerne les applications OAuth qui appartiennent à des utilisateurs, mais pas celles qui appartiennent à des groupes.

Pour activer ou désactiver le paramètre **Applications OAuth de l'utilisateur** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Cochez ou décochez la case **Applications OAuth de l'utilisateur**.
1. Sélectionnez **Enregistrer les modifications**.

### Limiter la durée de vie des jetons d'accès OAuth {#limit-the-lifetime-of-oauth-access-tokens}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237354) dans GitLab 19.1.

{{< /history >}}

Par défaut, les jetons d'accès OAuth expirent au bout de deux heures (7 200 secondes). Les administrateurs d'instance peuvent configurer une durée de vie personnalisée pour les jetons d'accès OAuth.

La valeur minimale est de 300 secondes (5 minutes). Si aucune valeur n'est définie, la valeur par défaut de 7 200 secondes (2 heures) s'applique. Ce paramètre s'applique à tous les nouveaux jetons d'accès OAuth émis par l'instance.

Prérequis :

- Être administrateur.

Pour définir la durée de vie des jetons d'accès OAuth :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Renseignez le champ **Durée de vie des jetons d'accès OAuth (secondes)**.
1. Sélectionnez **Enregistrer les modifications**.

Vous pouvez également configurer ce paramètre à l'aide de l'[API des paramètres d'application](../../api/settings.md) avec l'attribut `oauth_access_token_expires_in`.

### Désactiver l'enregistrement dynamique des clients OAuth {#turn-off-oauth-dynamic-client-registration}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248615) dans GitLab 19.3.

{{< /history >}}

Les clients OAuth, tels que les clients MCP et les outils d'IA, utilisent l'enregistrement dynamique des clients OAuth (DCR) pour enregistrer automatiquement des applications en envoyant une requête à `POST /oauth/register`. Par défaut, le DCR est activé.

Lorsque vous désactivez le DCR, les résultats suivants s'appliquent aux clients OAuth :

- Les clients OAuth ne peuvent pas enregistrer des applications automatiquement. Les clients doivent utiliser une application OAuth pré-enregistrée à la place.
- GitLab supprime les applications OAuth enregistrées dynamiquement et révoque leurs jetons d'accès et leurs autorisations.

Prérequis :

- Être administrateur.

Pour désactiver l'enregistrement dynamique des clients OAuth, utilisez l'[API des paramètres d'application](../../api/settings.md) pour définir l'attribut `dynamic_client_registration_enabled` sur `false`.

## Désactiver la modification du nom de profil des utilisateurs {#disable-user-profile-name-changes}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour préserver l'intégrité des informations sur les utilisateurs consignées dans les [événements d'audit](../compliance/audit_event_reports.md), les administrateurs GitLab peuvent empêcher les utilisateurs de modifier leur nom de profil.

Pour cela :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Sélectionnez **Empêcher les utilisateurs de modifier leur nom de profil**.

Lorsque cette option est sélectionnée, les administrateurs GitLab peuvent toujours mettre à jour les noms d'utilisateur dans la [zone **Admin**](../admin_area.md#administering-users) ou à l'aide de l'[API](../../api/users.md#modify-a-user).

## Empêcher les utilisateurs de créer des organisations {#prevent-users-from-creating-organizations}

{{< details >}}

- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/423302) dans GitLab 16.7 [avec un feature flag](../feature_flags/_index.md) nommé `ui_for_organizations`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité n'est pas disponible par défaut. Pour rendre cette fonctionnalité disponible, un administrateur peut [activer le feature flag](../feature_flags/_index.md) nommé `ui_for_organizations`. Sur GitLab.com et GitLab Dedicated, cette fonctionnalité n'est pas disponible. Cette fonctionnalité n'est pas prête pour une utilisation en production.

Par défaut, les utilisateurs peuvent créer des organisations. Les administrateurs GitLab peuvent empêcher les utilisateurs de créer des organisations.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Décochez la case **Autoriser les utilisateurs à créer des organisations**.

## Empêcher les nouveaux utilisateurs de créer des groupes principaux {#prevent-new-users-from-creating-top-level-groups}

Par défaut, les nouveaux utilisateurs peuvent créer des groupes principaux. Les administrateurs GitLab peuvent empêcher les nouveaux utilisateurs de créer des groupes principaux de deux manières :

- Dans l'interface utilisateur GitLab, avec les étapes de cette section.
- Au moyen de l'[API des paramètres d'application](../../api/settings.md#update-application-settings).

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Décochez la case **Autoriser les nouveaux utilisateurs à créer des groupes de premier niveau**.

> [!note]
> Ce paramètre s'applique uniquement aux utilisateurs ajoutés après que vous avez désactivé ce paramètre. Les utilisateurs existants peuvent toujours créer des groupes principaux.

## Empêcher les non-membres de créer des projets et des groupes {#prevent-non-members-from-creating-projects-and-groups}

Par défaut, les utilisateurs auxquels le rôle Invité est attribué peuvent créer des projets et des groupes. Les administrateurs GitLab peuvent empêcher cette création :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Décochez la case **Autoriser les utilisateurs ayant jusqu'au rôle Invité à créer des groupes et des projets personnels**.
1. Sélectionnez **Enregistrer les modifications**.

## Empêcher les utilisateurs de rendre leur profil privé {#prevent-users-from-making-their-profiles-private}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/421310) dans GitLab 17.1 [avec le feature flag](../feature_flags/_index.md) `disallow_private_profiles`. Désactivé par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/427400) dans GitLab 17.9. Suppression du feature flag `disallow_private_profiles`.

{{< /history >}}

Par défaut, les utilisateurs peuvent rendre leur profil privé. Les administrateurs GitLab peuvent désactiver ce paramètre pour exiger que tous les profils des utilisateurs soient publics. Ce paramètre n'a aucune incidence sur les [utilisateurs internes](../internal_users.md) (parfois appelés « bots »).

Pour empêcher les utilisateurs de rendre leur profil privé :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Décochez la case **Autoriser les utilisateurs à rendre leurs profils privés**.
1. Sélectionnez **Enregistrer les modifications**.

Lorsque vous désactivez ce paramètre :

- Tous les profils privés des utilisateurs deviennent publics
- L'option [Rendre les profils des nouveaux utilisateurs privés par défaut](#set-profiles-of-new-users-to-private-by-default) est également désactivée

Lorsque vous réactivez ce paramètre, la [visibilité du profil que l'utilisateur avait définie précédemment](../../user/profile/_index.md#make-your-user-profile-page-private) est de nouveau sélectionnée.

## Rendre les profils des nouveaux utilisateurs privés par défaut {#set-profiles-of-new-users-to-private-by-default}

Par défaut, les nouveaux utilisateurs ont un profil public. Les administrateurs GitLab peuvent définir un profil privé par défaut pour les nouveaux utilisateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Cochez la case **Rendre les profils des nouveaux utilisateurs privés par défaut**.
1. Sélectionnez **Enregistrer les modifications**.

> [!note]
> Si [**Autoriser les utilisateurs à rendre leurs profils privés**](#prevent-users-from-making-their-profiles-private) est désactivé, ce paramètre est également désactivé.

## Empêcher les utilisateurs de supprimer leur compte {#prevent-users-from-deleting-their-accounts}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Par défaut, les utilisateurs peuvent supprimer leur propre compte. Les administrateurs GitLab peuvent empêcher les utilisateurs de supprimer leur propre compte :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Décochez la case **Autorise les utilisateurs à supprimer leur propre compte**.

## Accepter automatiquement les succès pour tous les utilisateurs {#automatically-accept-achievements-for-all-users}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/607750) dans GitLab 19.4.

{{< /history >}}

Par défaut, les utilisateurs doivent explicitement accepter un [succès](../../user/profile/achievements.md) avant qu'il n'apparaisse sur leur profil utilisateur. À la place, vous pouvez configurer un paramètre pour accepter automatiquement les succès nouvellement attribués pour tous les utilisateurs de l'instance.

Lorsqu'il est activé, les nouveaux succès sont acceptés immédiatement et affichés sur le profil utilisateur du destinataire. GitLab envoie toujours une notification par e-mail pour le succès, mais l'e-mail ne contient plus de lien d'acceptation. Ce paramètre ne s'applique pas aux succès attribués avant l'activation du paramètre.

Les destinataires peuvent toujours [masquer le succès depuis leur profil](../../user/profile/achievements.md#change-visibility-of-specific-achievements).

Pour accepter automatiquement les succès pour tous les utilisateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Limitations du compte**.
1. Cochez la case **Automatically accept achievements for all users**.
1. Sélectionnez **Enregistrer les modifications**.

## Dépannage {#troubleshooting}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

### 413 Request Entity Too Large {#413-request-entity-too-large}

Lorsque vous joignez un fichier à un commentaire ou à une réponse dans GitLab, la [taille maximale des pièces jointes](#max-attachment-size) est probablement supérieure à la valeur autorisée par le serveur web.

Pour porter la taille maximale des pièces jointes à 200 Mo dans une installation par [paquet Linux](https://docs.gitlab.com/omnibus/) :

1. Ajoutez la ligne suivante à `/etc/gitlab/gitlab.rb` :

   ```ruby
   nginx['client_max_body_size'] = "200m"
   ```

1. Augmentez la taille maximale des pièces jointes.

### Ce dépôt a dépassé sa limite de taille {#this-repository-has-exceeded-its-size-limit}

Si vous voyez des erreurs de push intermittentes dans le [journal des exceptions Rails](../logs/_index.md#exceptions_jsonlog), comme celle-ci :

```plaintext
Your push to this repository cannot be completed because this repository has exceeded the allocated storage for your project.
```

Les tâches de [maintenance](../housekeeping.md) peuvent faire augmenter la taille du dépôt. Pour résoudre ce problème à court ou à moyen terme, utilisez l'une des options suivantes :

- Augmenter la [limite de taille du dépôt](#repository-size-limit).
- [Réduire la taille du dépôt](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).
