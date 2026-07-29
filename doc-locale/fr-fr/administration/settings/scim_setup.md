---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer SCIM pour GitLab Self-Managed ou GitLab Dedicated
description: Gérez le cycle de vie des utilisateurs avec le provisionnement automatique des comptes.
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser le standard ouvert System for Cross-domain Identity Management (SCIM) pour automatiquement :

- Créer des utilisateurs.
- Bloquer des utilisateurs.
- Réajouter des utilisateurs (réactiver l'identité SCIM).

L'[API SCIM GitLab interne](../../development/internal_api/_index.md#instance-scim-api) implémente une partie du [protocole RFC7644](https://www.rfc-editor.org/rfc/rfc7644).

Si vous êtes un utilisateur de GitLab.com, consultez [la configuration de SCIM pour les groupes GitLab.com](../../user/group/saml_sso/scim_setup.md).

## Configurer GitLab {#configure-gitlab}

Prérequis :

- [Authentification unique SAML](../../integration/saml.md) configurée.
- Accès administrateur.

Pour configurer GitLab SCIM :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Jeton SCIM** et sélectionnez **Générer un jeton SCIM**.
1. Pour la configuration de votre fournisseur d'identité, enregistrez les éléments suivants :
   - Le jeton du champ **Votre jeton SCIM**.
   - L'URL du champ **URL du point de terminaison de l'API SCIM**.

## Configurer un fournisseur d'identité {#configure-an-identity-provider}

GitLab prend en charge SCIM avec plusieurs fournisseurs d'identité. D'autres fournisseurs d'identité peuvent encore fonctionner avec GitLab, mais ils n'ont pas été testés et ne sont pas pris en charge. Pour obtenir de l'aide avec un fournisseur non pris en charge, contactez directement le fournisseur. Le support GitLab peut aider à examiner les entrées de journal associées.

### Configurer Okta {#configure-okta}

L'application SAML créée lors de la configuration de l'[authentification unique](../../integration/saml.md) pour Okta doit être configurée pour SCIM.

Prérequis :

- Vous devez utiliser le produit [Okta Lifecycle Management](https://www.okta.com/products/lifecycle-management/). Ce niveau de produit est requis pour utiliser SCIM sur Okta.
- [GitLab est configuré](#configure-gitlab) pour SCIM.
- L'application SAML pour [Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/) configurée comme décrit dans les [notes de configuration d'Okta](../../integration/saml.md#set-up-okta).
- Votre configuration SAML Okta correspond aux [étapes de configuration](_index.md), en particulier la configuration NameID.

Pour configurer Okta pour SCIM :

1. Connectez-vous à Okta.
1. Dans le coin supérieur droit, sélectionnez **Admin**. Le bouton n'est pas visible depuis la zone **Admin**.
1. Dans l'onglet **Application**, sélectionnez **Browse App Catalog**.
1. Recherchez et sélectionnez l'application **GitLab**.
1. Sur la page de présentation de l'application GitLab, sélectionnez **Add Integration**.
1. Sous **Application Visibility**, cochez les deux cases. L'application GitLab ne prend pas en charge l'authentification SAML, donc l'icône ne doit pas être affichée aux utilisateurs.
1. Sélectionnez **Terminé** pour terminer l'ajout de l'application.
1. Dans l'onglet **Provisioning**, sélectionnez **Configure API integration**.
1. Sélectionnez **Enable API integration**.
   - Pour **Base URL**, collez l'URL que vous avez copiée depuis **URL du point de terminaison de l'API SCIM** sur la page de configuration SCIM de GitLab.
   - Pour **API Token**, collez le jeton SCIM que vous avez copié depuis **Votre jeton SCIM** sur la page de configuration SCIM de GitLab.
1. Pour vérifier la configuration, sélectionnez **Test API Credentials**.
1. Sélectionnez **Enregistrer**.
1. Après avoir enregistré les détails d'intégration de l'API, de nouveaux onglets de paramètres apparaissent à gauche. Sélectionnez **To App**.
1. Sélectionnez **Éditer**.
1. Cochez la case **Activer** pour **Create Users** et **Deactivate Users**.
1. Sélectionnez **Enregistrer**.
1. Affectez des utilisateurs dans l'onglet **Affectations**. Les utilisateurs affectés sont créés et gérés dans votre groupe GitLab.

### Configurer Microsoft Entra ID {#configure-microsoft-entra-id}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143146) de la terminologie vers Microsoft Entra ID dans GitLab 16.10.

{{< /history >}}

Prérequis :

- [GitLab est configuré](#configure-gitlab) pour SCIM.
- L'[application SAML pour Microsoft Entra ID est configurée](../../integration/saml.md#set-up-microsoft-entra-id).

L'application SAML créée lors de la configuration de l'[authentification unique](../../integration/saml.md) pour [Azure Active Directory](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/view-applications-portal) doit être configurée pour SCIM. Pour un exemple, consultez la [configuration exemple](../../user/group/saml_sso/example_saml_config.md#scim-mapping).

> [!note]
> Vous devez configurer le provisionnement SCIM exactement comme indiqué dans les instructions suivantes. En cas de mauvaise configuration, vous rencontrerez des problèmes avec le provisionnement des utilisateurs et la connexion, qui nécessitent beaucoup d'efforts pour être résolus. Si vous avez des difficultés ou des questions concernant une étape, contactez le support GitLab.

Pour configurer Microsoft Entra ID, vous configurez :

- Microsoft Entra ID pour SCIM.
- Les paramètres.
- Les mappings, y compris les mappings d'attributs.

#### Configurer Microsoft Entra ID pour SCIM {#configure-microsoft-entra-id-for-scim}

1. Dans votre application, accédez à l'onglet **Provisioning** et sélectionnez **Démarrer**.
1. Définissez le **Provisioning Mode** sur **Automatic**.
1. Remplissez les **Admin Credentials** en utilisant la valeur de :
   - **URL du point de terminaison de l'API SCIM** dans GitLab pour le champ **Tenant URL**.
   - **Votre jeton SCIM** dans GitLab pour le champ **Secret Token**.
1. Sélectionnez **Test Connection**.

   Si le test réussit, enregistrez votre configuration.

   Si le test échoue, consultez le [dépannage](../../user/group/saml_sso/troubleshooting.md) pour tenter de résoudre le problème.
1. Sélectionnez **Enregistrer**.

Après l'enregistrement, les sections **Mappings** et **Paramètres** apparaissent.

#### Configurer les mappings {#configure-mappings}

Sous la section **Mappings**, provisionnez d'abord les groupes :

1. Sélectionnez **Provision Microsoft Entra ID Groups**.
1. Sur la page Attribute Mapping, désactivez le bouton **Activé**.

   Le provisionnement de groupes SCIM n'est pas pris en charge dans GitLab. Laisser le provisionnement de groupe activé ne perturbe pas le provisionnement des utilisateurs SCIM, mais provoque des erreurs dans le journal de provisionnement SCIM d'Entra ID qui peuvent être déroutantes et trompeuses.

   > [!note]
   > Même lorsque **Provision Microsoft Entra ID Groups** est désactivé, la section des mappings peut afficher **Activé : Oui**. Ce comportement est un bug d'affichage que vous pouvez ignorer en toute sécurité.

1. Sélectionnez **Enregistrer**.

Ensuite, provisionnez les utilisateurs :

1. Sélectionnez **Provision Microsoft Entra ID Users**.
1. Assurez-vous que le bouton **Activé** est défini sur **Oui**.
1. Assurez-vous que toutes les **Target Object Actions** sont activées.
1. Sous **Attribute Mappings**, configurez les mappings pour correspondre aux [mappings d'attributs configurés](#configure-attribute-mappings) :
   1. Facultatif. Dans la colonne **customappsso Attribute**, recherchez `externalId` et supprimez-le.
   1. Modifiez le premier attribut pour qu'il ait :
      - Un **source attribute** de `objectId`.
      - Un **target attribute** de `externalId`.
      - Une **matching precedence** de `1`.
   1. Mettez à jour les attributs **customappsso** existants pour correspondre aux [mappings d'attributs configurés](#configure-attribute-mappings).
   1. Supprimez tout attribut supplémentaire qui n'est pas présent dans le [tableau des mappings d'attributs](#configure-attribute-mappings). Ils ne posent pas de problème s'ils ne sont pas supprimés, mais GitLab ne consomme pas ces attributs.
1. Sous la liste des mappings, cochez la case **Show advanced options**.
1. Sélectionnez le lien **Edit attribute list for customappsso**.
1. Assurez-vous que `id` est le champ principal et obligatoire, et que `externalId` est également obligatoire.
1. Sélectionnez **Enregistrer**, ce qui vous ramène à la page de configuration Attribute Mapping.
1. Pour fermer la page de configuration **Attribute Mapping**, sélectionnez `X` dans le coin supérieur droit.

##### Configurer les mappings d'attributs {#configure-attribute-mappings}

> [!note]
> Pendant que Microsoft effectue la transition d'Azure Active Directory vers les schémas de nommage d'Entra ID, vous pourriez remarquer des incohérences dans votre interface utilisateur. Si vous rencontrez des difficultés, vous pouvez consulter une version plus ancienne de ce document ou contacter le support GitLab.

Lors de la configuration d'Entra ID pour SCIM, vous configurez les mappings d'attributs. Pour un exemple, consultez la [configuration exemple](../../user/group/saml_sso/example_saml_config.md#scim-mapping).

Le tableau suivant fournit les mappings d'attributs requis pour GitLab.

| Attribut source                                                           | Attribut cible               | Priorité de correspondance |
|:---------------------------------------------------------------------------|:-------------------------------|:--------------------|
| `objectId`                                                                 | `externalId`                   | 1                   |
| `userPrincipalName` OU `mail` <sup>1</sup>                                 | `emails[type eq "work"].value` |                     |
| `mailNickname`                                                    | `userName`                     |                     |
| `displayName` OU `Join(" ", [givenName], [surname])` <sup>2</sup>          | `name.formatted`               |                     |
| `Switch([IsSoftDeleted], , "False", "True", "True", "False")` <sup>3</sup> | `active`                       |                     |

**Footnotes** :

1. Utilisez `mail` comme attribut source lorsque `userPrincipalName` n'est pas une adresse e-mail ou n'est pas délivrable.
1. Utilisez l'expression `Join` si votre `displayName` ne correspond pas au format `Firstname Lastname`.
1. Il s'agit d'un type de mapping par expression, et non d'un mapping direct. Sélectionnez **Expression** dans la liste déroulante **Mapping type**.

Chaque mapping d'attribut possède :

- Un **customappsso Attribute**, qui correspond à l'**target attribute**.
- Un **Microsoft Entra ID Attribute**, qui correspond à l'**source attribute**.
- Une priorité de correspondance.

Pour chaque attribut :

1. Modifiez l'attribut existant ou ajoutez un nouvel attribut.
1. Sélectionnez les mappings d'attributs source et cible requis dans les listes déroulantes.
1. Sélectionnez **Ok**.
1. Sélectionnez **Enregistrer**.

Si votre configuration SAML diffère des [paramètres SAML recommandés](../../integration/saml.md), sélectionnez les attributs de mapping et modifiez-les en conséquence. L'attribut source que vous mappez à l'attribut cible `externalId` doit correspondre à l'attribut utilisé pour le SAML `NameID`.

Si un mapping n'est pas répertorié dans le tableau, utilisez les valeurs par défaut de Microsoft Entra ID. Pour obtenir la liste des attributs requis, consultez la documentation de l'[API SCIM d'instance interne](../../development/internal_api/_index.md#instance-scim-api).

#### Configurer les paramètres {#configure-settings}

Sous la section **Paramètres** :

1. Facultatif. Si vous le souhaitez, cochez la case **Send an email notification when a failure occurs**.
1. Facultatif. Si vous le souhaitez, cochez la case **Prevent accidental deletion**.
1. Si nécessaire, sélectionnez **Enregistrer** pour vous assurer que toutes les modifications ont été sauvegardées.

Après avoir configuré les mappings et les paramètres, revenez à la page de présentation de l'application et sélectionnez **Start provisioning** pour démarrer le provisionnement SCIM automatique des utilisateurs dans GitLab.

> [!warning]
> Une fois synchronisé, la modification du champ mappé sur `id` et `externalId` peut provoquer des erreurs. Cela inclut des erreurs de provisionnement, des utilisateurs en double, et peut empêcher les utilisateurs existants d'accéder au groupe GitLab.

## Supprimer l'accès {#remove-access}

La suppression ou la désactivation d'un utilisateur sur le fournisseur d'identité bloque l'utilisateur sur l'instance GitLab, tandis que l'identité SCIM reste liée à l'utilisateur GitLab.

Pour mettre à jour l'identité SCIM de l'utilisateur, utilisez l'[API SCIM GitLab interne](../../development/internal_api/_index.md#update-a-single-scim-provisioned-user-1).

## Réactiver l'accès {#reactivate-access}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/379149) dans GitLab 16.0 [avec un indicateur](../feature_flags/_index.md) nommé `skip_saml_identity_destroy_during_scim_deprovision`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121226) dans GitLab 16.4. Indicateur de feature flag `skip_saml_identity_destroy_during_scim_deprovision` supprimé.

{{< /history >}}

Après la suppression ou la désactivation d'un utilisateur via SCIM, vous pouvez réactiver cet utilisateur en l'ajoutant au fournisseur d'identité SCIM.

Après que le fournisseur d'identité effectue une synchronisation selon son calendrier configuré, l'identité SCIM de l'utilisateur est réactivée et son accès à l'instance GitLab est rétabli.

## Synchronisation des groupes avec SCIM {#group-synchronization-with-scim}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/15990) dans GitLab 18.0 [avec un indicateur](../feature_flags/_index.md) nommé `self_managed_scim_group_sync`. Désactivé par défaut.
- [Activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/553662) par défaut dans GitLab 18.2.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/554271) dans GitLab 18.6. Indicateur de feature flag `self_managed_scim_group_sync` supprimé.

{{< /history >}}

En plus du provisionnement des utilisateurs, vous pouvez utiliser SCIM pour synchroniser les appartenances aux groupes entre votre fournisseur d'identité et GitLab. Avec cette méthode, vous pouvez ajouter et supprimer automatiquement des utilisateurs des groupes GitLab en fonction de leurs appartenances aux groupes dans votre fournisseur d'identité.

Prérequis :

- Les [liens de groupe SAML](../../user/group/saml_sso/group_sync.md#configure-saml-group-links) doivent être configurés en premier.
- Les noms de groupes SAML dans votre fournisseur d'identité doivent correspondre aux noms de groupes SAML configurés dans GitLab.

La synchronisation des groupes SCIM fonctionne avec les liens de groupe SAML pour gérer les appartenances aux groupes. Lorsque votre fournisseur d'identité envoie des modifications d'appartenance aux groupes via l'API SCIM, GitLab met à jour les appartenances des utilisateurs dans tous les groupes GitLab qui ont des liens de groupe SAML associés à ce groupe SCIM.

SCIM est un protocole unidirectionnel : les modifications transitent de votre fournisseur d'identité vers GitLab. Si vous apportez des modifications aux liens de groupe SAML dans GitLab (par exemple en les ajoutant ou en les supprimant), votre fournisseur d'identité n'a aucun moyen de détecter ces modifications via SCIM.

### Limitation connue des nouveaux liens de groupe {#known-limitation-of-new-group-links}

Lorsque votre fournisseur d'identité provisionne un groupe SCIM pour la première fois (via `POST /Groups`), GitLab associe l'ID du groupe SCIM à tous les liens de groupe SAML existants qui ont un nom de groupe correspondant. Cependant, si vous ajoutez de nouveaux liens de groupe SAML avec le même nom de groupe après le provisionnement initial, les nouveaux liens de groupe ne sont pas automatiquement associés à l'ID du groupe SCIM. Cela signifie que les mises à jour d'appartenance SCIM de votre fournisseur d'identité n'affectent pas les utilisateurs dans les liens de groupe nouvellement ajoutés.

La prise en charge des améliorations est proposée dans l'[issue 582729](https://gitlab.com/gitlab-org/gitlab/-/issues/582729).

> [!note]
> Pour vous assurer que tous les liens de groupe sont associés au groupe SCIM dès le départ, vous devez configurer tous les liens de groupe SAML avant de configurer le provisionnement de groupe SCIM dans votre fournisseur d'identité.

Si vous devez ajouter des liens de groupe après le provisionnement initial, vous pouvez re-provisionner le groupe SCIM dans votre fournisseur d'identité en supprimant le provisionnement du groupe SCIM (et non le groupe IdP lui-même), puis en le recréant. Cette action ré-associe tous les liens de groupe SAML actuels au groupe SCIM. Pour plus d'informations, consultez la documentation de votre fournisseur d'identité pour la gestion du provisionnement de groupe SCIM.

Si vous supprimez un lien de groupe SAML dans GitLab, les membres de ce groupe via ce lien restent dans le groupe. Cependant, SCIM ne gère plus leur appartenance à ce groupe car le lien de groupe a été supprimé. Si nécessaire, vous pouvez manuellement [supprimer des membres du groupe](../../user/group/_index.md#remove-a-member-from-the-group).

### Configurer la synchronisation des groupes dans votre fournisseur d'identité {#configure-group-synchronization-in-your-identity-provider}

Pour des instructions détaillées sur la configuration de la synchronisation des groupes dans votre fournisseur d'identité, consultez la documentation du fournisseur. Exemples ci-dessous :

- [Okta Groups API](https://developer.okta.com/docs/reference/api/groups/)
- [Microsoft Entra ID (Azure AD) SCIM Groups](https://learn.microsoft.com/en-us/entra/identity/app-provisioning/use-scim-to-provision-users-and-groups) \- Par défaut, l'attribut source `displayName` est utilisé pour trouver les liens de groupe SAML avec des noms conviviaux. - Cependant, si vos liens de groupe SAML utilisent un ID d'objet comme nom, vous devez mettre à jour l'attribut source vers `objectId`.

> [!warning]
> Lorsque plusieurs liens de groupe SAML correspondent au même groupe GitLab, les utilisateurs se voient attribuer le rôle le plus élevé parmi tous les liens de groupe de mapping. Les utilisateurs retirés d'un groupe IdP restent dans un groupe GitLab s'ils appartiennent à un autre groupe SAML qui y est lié.

L'application SCIM GitLab standard du catalogue d'applications Okta ne prend pas en charge la synchronisation des groupes. Vous pouvez également créer une intégration SCIM personnalisée pour la synchronisation des groupes avec Okta. Pour plus d'informations, consultez l'[issue 582729](https://gitlab.com/gitlab-org/gitlab/-/issues/582729).

## Dépannage {#troubleshooting}

Consultez notre [guide de dépannage SCIM](../../user/group/saml_sso/troubleshooting_scim.md).
