---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Service anti-spam Spamcheck
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

> [!warning]
> Spamcheck est disponible pour tous les niveaux, mais uniquement sur les instances utilisant GitLab Enterprise Edition (EE). Pour des [raisons de licence](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6259#note_726605397), il n'est pas inclus dans le package GitLab Community Edition (CE). Vous pouvez [migrer de CE vers EE](../../update/convert_to_ee/package.md).

[Spamcheck](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck) est un moteur anti-spam développé par GitLab, initialement pour lutter contre la quantité croissante de spam sur GitLab.com, et rendu public par la suite pour être utilisé dans les instances GitLab Self-Managed.

## Activer Spamcheck {#enable-spamcheck}

Spamcheck est uniquement disponible pour les installations basées sur des packages :

1. Modifiez `/etc/gitlab/gitlab.rb` et activez Spamcheck :

   ```ruby
   spamcheck['enable'] = true
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Vérifiez que les nouveaux services `spamcheck` et `spam-classifier` sont opérationnels :

   ```shell
   sudo gitlab-ctl status
   ```

## Configurer GitLab pour utiliser Spamcheck {#configure-gitlab-to-use-spamcheck}

Prérequis :

- Accès administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rapports**.
1. Développez **Protection anti‐spam et anti‐robot**.
1. Mettez à jour les paramètres de Spam Check :
   1. Cochez la case « Enable Spam Check via external API endpoint ».
   1. Pour **URL du point de terminaison Spam Check externe**, utilisez `grpc://localhost:8001`.
   1. Laissez **Clé d'API de Spamcheck** vide.
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> Dans les instances à nœud unique, Spamcheck s'exécute via `localhost` et fonctionne donc en mode non authentifié. Dans le cas d'instances multi-nœuds où GitLab s'exécute sur un serveur et Spamcheck sur un autre serveur écoutant via un point de terminaison public, il est recommandé d'appliquer un mécanisme d'authentification en utilisant un proxy inverse devant le service Spamcheck, qui peut être utilisé conjointement avec une clé API. Un exemple serait d'utiliser l'authentification `JWT` à cet effet et de spécifier un jeton bearer comme clé API. [L'authentification native pour Spamcheck est en cours de développement](https://gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/spam/spamcheck/-/issues/171).

## Exécution de Spamcheck via TLS {#running-spamcheck-over-tls}

Le service Spamcheck ne peut pas communiquer directement avec GitLab via TLS. Cependant, Spamcheck peut être déployé derrière un proxy inverse qui effectue la terminaison TLS. Dans ce scénario, GitLab peut être configuré pour communiquer avec Spamcheck via TLS en spécifiant le schéma `tls://` pour l'URL Spamcheck externe au lieu de `grpc://` dans les paramètres de la zone **Admin**.
