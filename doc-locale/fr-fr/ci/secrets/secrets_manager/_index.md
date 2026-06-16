---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gestionnaire de secrets GitLab
ignore_in_report: true
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/16319) dans GitLab 18.3 [avec les flags](../../../development/feature_flags/_index.md) `secrets_manager` et `ci_tanukey_ui`. Désactivé par défaut.
- Le feature flag `ci_tanukey_ui` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/549940) dans GitLab 18.4.
- Rendu disponible pour certains utilisateurs en bêta fermée dans GitLab 18.8.
- Le gestionnaire de secrets de groupe a été [introduit](https://gitlab.com/groups/gitlab-org/-/work_items/17904) et rendu disponible aux utilisateurs de la bêta fermée dans la version 18.10 [avec le flag](../../../development/feature_flags/_index.md) `group_secrets_manager`.
- La bêta publique a été [introduite](https://gitlab.com/groups/gitlab-org/-/work_items/21731) dans GitLab 19.0.

{{< /history >}}

Les secrets représentent des informations sensibles dont vos jobs CI/CD ont besoin pour fonctionner. Les secrets peuvent être des jetons d'accès, des identifiants de base de données, des clés privées ou autres éléments similaires.

Contrairement aux variables CI/CD, qui sont toujours disponibles par défaut pour les jobs, les secrets doivent être explicitement demandés par un job.

Utilisez le Gestionnaire de secrets GitLab pour stocker et gérer de manière sécurisée les secrets et les identifiants de vos projets et groupes.

La bêta publique du Gestionnaire de secrets GitLab est disponible pour les clients **GitLab Premium and Ultimate**. Vous pouvez participer à la bêta publique sur GitLab.com ou sur une instance self-managed.

## Participer sur GitLab.com {#opt-in-on-gitlabcom}

Sur GitLab.com, un propriétaire de groupe principal peut activer le Gestionnaire de secrets GitLab pour son groupe. La participation au niveau du groupe principal le rend disponible pour tous les sous-groupes et projets au sein de ce groupe.

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe principal.
- Votre groupe doit être sur le niveau **GitLab Premium ou Ultimate**.

Pour participer :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal.
1. Sélectionnez **Paramètres** > **Général**.
1. Développez **Permissions et fonctionnalités du groupe**.
1. Activez le bouton **Gestionnaire de secrets**.

Après avoir participé, les propriétaires de groupes et de projets peuvent activer indépendamment le Gestionnaire de secrets pour leurs sous-groupes et projets. Pour les instructions, consultez [Activer pour un groupe ou un projet](#enable-for-a-group-or-project).

## Participer sur self-managed {#opt-in-on-self-managed}

Sur une instance self-managed, un administrateur doit d'abord activer le Gestionnaire de secrets GitLab au niveau de l'instance. Après avoir participé, les propriétaires peuvent l'activer pour leurs groupes et projets.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance GitLab.
- GitLab 19.0 ou version ultérieure.
- OpenBao doit être installé et configuré. Pour plus d'informations, consultez [l'administration](../../../administration/secrets_manager/_index.md).

Pour participer :

1. Dans la barre latérale gauche, en bas, sélectionnez **Admin**.
1. Sélectionnez **Paramètres** > **Général**.
1. Développez **Gestionnaire de secrets GitLab**.
1. Activez le bouton **Gestionnaire de secrets**.

Après avoir participé, les propriétaires de groupes et de projets peuvent activer le Gestionnaire de secrets pour leurs espaces de nommage. Pour les instructions, consultez [Activer pour un groupe ou un projet](#enable-for-a-group-or-project).

## Activer pour un groupe ou un projet {#enable-for-a-group-or-project}

### Pour un projet {#for-a-project}

Prérequis :

- Vous devez avoir le rôle Owner pour le projet.

Pour activer ou désactiver le Gestionnaire de secrets GitLab pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Activez le bouton **Gestionnaire de secrets** et attendez que le gestionnaire de secrets soit provisionné.

   > [!warning]
   > Si vous désactivez ultérieurement le Gestionnaire de secrets pour le projet, tous les secrets du projet sont définitivement supprimés. Ces secrets ne peuvent pas être récupérés.

Les secrets définis pour un projet ne sont accessibles que par les pipelines du même projet.

### Pour un groupe {#for-a-group}

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

Pour activer ou désactiver le Gestionnaire de secrets GitLab pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Permissions et fonctionnalités du groupe**.
1. Activez le bouton **Gestionnaire de secrets** et attendez que le gestionnaire de secrets soit provisionné.

   > [!warning]
   > Si vous désactivez ultérieurement le Gestionnaire de secrets pour le groupe, tous les secrets du groupe sont définitivement supprimés. Ces secrets ne peuvent pas être récupérés.

Les secrets définis pour un groupe ne sont accessibles que par les pipelines d'un projet directement sous le groupe ou dans sa hiérarchie de sous-groupes.

## Définir un secret {#define-a-secret}

Vous pouvez ajouter des secrets au gestionnaire de secrets afin qu'il puisse être utilisé pour des pipelines CI/CD et des workflows sécurisés.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet
1. Sélectionnez **Sécurisation** > **Gestionnaire de secrets**.
1. Sélectionnez **Ajouter un secret** et renseignez les détails :
   - **Nom** : Doit être unique dans le projet.
   - **Valeur** : Doit être inférieur ou égal à 10 Ko (10 000 octets).
   - **Description** : Maximum de 200 caractères.
   - **Environnements** : Peut être :
     - **Tous (par défaut)** (`*`)
     - Un [environnement](../../environments/_index.md#types-of-environments) spécifique.
     - Un [environnement avec caractère générique](../../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).
   - **Branche** : Cette option n'existe que dans les paramètres du projet. Peut être :
     - Une branche spécifique.
     - Une branche avec caractère générique (doit contenir le caractère `*`).
   - **Protégée** : Cette option n'existe que dans les paramètres du groupe. Facultatif. Exporter les secrets vers les pipelines s'exécutant uniquement sur des branches protégées.
   - **Rappel de remplacement** : Facultatif. Envoyer un rappel par e-mail pour effectuer la rotation du secret après le nombre de jours défini. Minimum 7 jours.

Après avoir créé un secret, vous pouvez l'utiliser dans la configuration du pipeline ou dans les scripts de job.

> [!warning]
> La valeur d'un secret est accessible à tous les jobs de pipeline CI/CD s'exécutant pour l'environnement ou la branche spécifique défini lors de la création ou de la mise à jour du secret. Assurez-vous que seuls les utilisateurs autorisés à accéder à la valeur de ces secrets peuvent exécuter des jobs pour l'environnement ou la branche spécifiés.

## Utiliser les secrets dans les scripts de job {#use-secrets-in-job-scripts}

### Pour les secrets de projet {#for-project-secrets}

Prérequis :

- GitLab Runner 19.0 ou version ultérieure.

Pour accéder aux secrets définis avec le Gestionnaire de secrets, utilisez les mots-clés [`secrets`](../../yaml/_index.md#secrets) et `gitlab_secrets_manager`.

Similairement aux [variables de type fichier](../../variables/_index.md#use-file-type-cicd-variables), le secret est mis à disposition en tant que variable d'environnement avec :

- La clé du secret comme nom de la variable d'environnement.
- La valeur du secret enregistrée dans un fichier temporaire. Contrairement aux variables masquées, les secrets peuvent contenir des espaces et des sauts de ligne.
- Le chemin vers le fichier temporaire comme valeur de la variable d'environnement.

Par exemple :

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube-cert
  script:
   - kubectl config set-cluster e2e --server="https://example.com" --certificate-authority="$KUBE_CA_PEM"
```

Si un job affiche la valeur d'un secret, par exemple en exécutant `cat $KUBE_CA_PEM`, GitLab remplace la valeur dans le job log par `[MASKED]`.

### Pour les secrets de groupe {#for-group-secrets}

Prérequis :

- GitLab Runner 19.0 ou version ultérieure.

Pour accéder aux secrets de groupe :

- Utilisez les mots-clés [`secrets`](../../yaml/_index.md#secrets) et `gitlab_secrets_manager`.
- Spécifiez la source du gestionnaire de secrets avec le champ `source` au format `group/<full-path-to-group>`.

Par exemple :

```yaml
job:
  secrets:
    TEST_SECRET:
      gitlab_secrets_manager:
        name: foo
        source: group/<full-path-to-group>
  script:
   - cat $TEST_SECRET
```

## Gérer les autorisations des secrets {#manage-secrets-permissions}

### Pour un projet {#for-a-project-1}

Prérequis :

- Vous devez avoir le rôle Owner pour le projet afin de gérer les autorisations des secrets.
- Les utilisateurs avec le rôle Maintainer pour le projet peuvent consulter les autorisations définies.
- Le Gestionnaire de secrets doit être activé pour le projet.

Pour mettre à jour les autorisations des secrets pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Sous **Gestionnaire de secrets**, dans la section **Autorisations des utilisateurs et utilisatrices du gestionnaire de secrets**, vous pouvez gérer les autorisations des utilisateurs :
   - Sélectionnez **Ajouter** pour ajouter des règles d'autorisation pour des utilisateurs, groupes ou rôles spécifiques.
   - Vous pouvez définir les portées des autorisations pour lire, écrire (créer & mettre à jour) et supprimer des secrets.

### Pour un groupe {#for-a-group-1}

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe afin de gérer les autorisations des secrets. Seuls les utilisateurs avec le rôle Owner pour le groupe peuvent consulter les autorisations définies.
- Le Gestionnaire de secrets doit être activé pour le groupe.

Pour mettre à jour les autorisations des secrets pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Permissions et fonctionnalités du groupe**.
1. Sous **Gestionnaire de secrets**, dans la section **Autorisations des utilisateurs et utilisatrices du gestionnaire de secrets**, vous pouvez gérer les autorisations des utilisateurs :
   - Sélectionnez **Ajouter** pour ajouter des règles d'autorisation pour des utilisateurs, groupes ou rôles spécifiques.
   - Vous pouvez définir les portées des autorisations pour lire, écrire (créer & mettre à jour) et supprimer des secrets.

Les utilisateurs avec le rôle Owner pour le groupe ont toujours les autorisations pour effectuer toutes les opérations dans le Gestionnaire de secrets.

## Suppression d'un projet ou d'un groupe {#deletion-of-a-project-or-group}

Lorsque vous [supprimez un projet](../../../user/project/working_with_projects.md#delete-a-project) ou [supprimez un groupe](../../../user/group/_index.md#schedule-a-group-for-deletion) avec des secrets :

- Le gestionnaire de secrets du projet ou du groupe est désactivé et supprimé du moteur de stockage des secrets.
- Tous les secrets sont définitivement supprimés.

## Transfert d'un projet ou d'un groupe {#transfer-of-a-project-or-group}

Lorsque vous [transférez un projet](../../../user/project/working_with_projects.md#transfer-a-project) ou [transférez un groupe](../../../user/group/manage.md#transfer-a-group) avec des secrets :

- Les secrets définis pour le projet ou le groupe ne sont pas transférés vers le projet ou le groupe dans son nouvel espace de nommage.
- Le gestionnaire de secrets du projet ou du groupe est désactivé et supprimé du moteur de stockage des secrets.
- Tous les secrets sont définitivement supprimés.

## Notifications de rotation des secrets {#secret-rotation-notifications}

Les utilisateurs avec le rôle Owner dans le projet reçoivent une notification par e-mail pour effectuer la rotation d'un secret le jour spécifié dans la configuration du secret.

## Tarification lors de la disponibilité générale {#pricing-at-general-availability}

Le Gestionnaire de secrets GitLab est gratuit pendant la bêta ouverte, mais consommera des GitLab Credits lors de sa disponibilité générale. Pour éviter une interruption de service, nous vous notifierons avant la disponibilité générale afin de vous donner le temps d'opter pour la facturation à la demande des GitLab Credits.

## Fournir des commentaires {#provide-feedback}

Pour partager des commentaires ou signaler des problèmes pendant la bêta publique, utilisez le [Gestionnaire de secrets GitLab : ticket Customer Feedback in Public Beta](https://gitlab.com/gitlab-org/gitlab/-/work_items/598100).

## Dépannage {#troubleshooting}

### Erreur : `reading from Vault: api error: status code 403` {#error-reading-from-vault-api-error-status-code-403}

Lorsqu'un job de pipeline CI/CD tente de récupérer un secret, il peut renvoyer cette erreur :

```plaintext
ERROR: Job failed (system failure): resolving secrets: getting secret: get secret data: reading from Vault: api error: status code 403: 1 error occurred: * permission denied
```

Cette erreur se produit lorsqu'un job tente de récupérer un secret qui n'existe pas ou qui a été supprimé.

### Erreur : `inline auth JWT is required` {#error-inline-auth-jwt-is-required}

Lorsqu'un job de pipeline CI/CD tente de récupérer un secret, il peut renvoyer cette erreur :

```plaintext
ERROR: Job failed (system failure): resolving secrets: creating vault client: configuring inline auth: inline auth JWT is required
```

Cette erreur se produit lorsque l'instance du gestionnaire de secrets n'a pas encore été provisionnée pour le projet ou le groupe auquel le secret est censé appartenir. Le runner ne peut pas configurer l'authentification car aucun rôle de gestionnaire de secrets n'existe encore.

Pour résoudre cette erreur, [activez le Gestionnaire de secrets](#enable-for-a-group-or-project) pour votre projet ou groupe.

Attendez que le provisionnement soit terminé et créez le secret avant de relancer le pipeline.
