---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage du basculement Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Correction des erreurs lors d'un basculement ou lors de la promotion d'un site secondaire en site principal {#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site}

Voici les messages d'erreur possibles qui peuvent être rencontrés lors d'un basculement ou lors de la promotion d'un site secondaire en site principal, avec les stratégies pour les résoudre.

### Message : `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken` {#message-activerecordrecordinvalid-validation-failed-name-has-already-been-taken}

Lors de la [promotion d'un site **secondaire**](_index.md#step-2-promoting-a-secondary-site), vous pourriez rencontrer le message d'erreur suivant :

```plaintext
Running gitlab-rake gitlab:geo:set_secondary_as_primary...

rake aborted!
ActiveRecord::RecordInvalid: Validation failed: Name has already been taken
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:236:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:221:in `block (2 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => gitlab:geo:set_secondary_as_primary
(See full trace by running task with --trace)

You successfully promoted this node!
```

Si vous rencontrez ce message lors de l'exécution de `gitlab-rake gitlab:geo:set_secondary_as_primary` ou de `gitlab-ctl promote-to-primary-node`, ouvrez une console Rails et exécutez :

  ```ruby
  Rails.application.load_tasks; nil
  Gitlab::Geo.expire_cache!
  Rake::Task['gitlab:geo:set_secondary_as_primary'].invoke
  ```

### Message : ``NoMethodError: undefined method `secondary?' for nil:NilClass`` {#message-nomethoderror-undefined-method-secondary-for-nilnilclass}

Lors de la [promotion d'un site **secondaire**](_index.md#step-2-promoting-a-secondary-site), vous pourriez rencontrer le message d'erreur suivant :

```plaintext
sudo gitlab-rake gitlab:geo:set_secondary_as_primary

rake aborted!
NoMethodError: undefined method `secondary?' for nil:NilClass
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:232:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:221:in `block (2 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => gitlab:geo:set_secondary_as_primary
(See full trace by running task with --trace)
```

Cette commande est destinée à être exécutée uniquement sur un site secondaire, et ce message d'erreur s'affiche si vous tentez d'exécuter cette commande sur un site principal.

### Artefacts expirés {#expired-artifacts}

Si vous constatez pour une raison quelconque qu'il y a plus d'artefacts sur le site Geo **secondaire** que sur le site Geo **principal**, vous pouvez utiliser la tâche Rake pour [nettoyer les fichiers d'artefacts orphelins](../../raketasks/cleanup.md#remove-orphan-artifact-files)

Sur un site Geo **secondaire**, cette commande nettoie également tous les enregistrements de registre Geo liés aux fichiers orphelins sur le disque.

### Correction des erreurs de connexion {#fixing-sign-in-errors}

#### Message :  L'URI de redirection incluse n'est pas valide {#message-the-redirect-uri-included-is-not-valid}

Si vous pouvez vous connecter à l'interface web du site **principal**, mais que vous recevez ce message d'erreur lorsque vous tentez de vous connecter à l'interface web d'un site **secondaire**, vous devez vérifier que l'URL du site Geo correspond à son URL externe.

Prérequis :

- Accès administrateur.

Sur le site **principal** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Trouvez le site **secondaire** concerné et sélectionnez **Éditer**.
1. Assurez-vous que le champ **URL** correspond à la valeur trouvée dans `/etc/gitlab/gitlab.rb` dans `external_url "https://gitlab.example.com"` sur le site des **Rails nodes of the secondary**.

#### L'authentification avec SAML sur le site secondaire atterrit toujours sur le site principal {#authenticating-with-saml-on-the-secondary-site-always-lands-on-the-primary-site}

Ce [problème est généralement rencontré lors de la mise à niveau vers GitLab 15.1](../../../update/versions/gitlab_15_changes.md#1510). Pour résoudre ce problème, consultez [la configuration du SAML à l'échelle de l'instance dans Geo avec l'authentification unique](../replication/single_sign_on.md#configuring-instance-wide-saml).

## Récupération après un basculement partiel {#recovering-from-a-partial-failover}

Le basculement partiel vers un site Geo secondaire peut être le résultat d'un ticket temporaire/transitoire. Par conséquent, tentez d'abord d'exécuter à nouveau la commande de promotion.

1. Connectez-vous en SSH à chaque nœud Sidekiq, PostgreSQL, Gitaly et Rails du site **secondaire** et exécutez l'une des commandes suivantes :

   - Pour promouvoir le site secondaire en site principal :

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Pour promouvoir le site secondaire en site principal **sans aucune confirmation supplémentaire** :

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Vérifiez que vous pouvez vous connecter au site **principal** nouvellement promu en utilisant l'URL précédemment utilisée pour le site **secondaire**.
1. En cas de **succès**, le site **secondaire** est maintenant promu en site **principal**.

Si les étapes précédentes **n'ont pas réussi**, passez aux étapes suivantes :

1. Connectez-vous en SSH à chaque nœud Sidekiq, PostgreSQL, Gitaly et Rails du site **secondaire** et effectuez les opérations suivantes :

   - Créez un fichier `/etc/gitlab/gitlab-cluster.json` avec le contenu suivant :

     ```shell
     {
       "primary": true,
       "secondary": false
     }
     ```

   - Reconfigurez GitLab pour que les modifications prennent effet :

     ```shell
     sudo gitlab-ctl reconfigure
     ```

1. Vérifiez que vous pouvez vous connecter au site **principal** nouvellement promu en utilisant l'URL précédemment utilisée pour le site **secondaire**.
1. Si l'opération réussit, le site **secondaire** est maintenant promu en site **principal**.
