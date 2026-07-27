---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Activez GitLab Enterprise Edition (EE) pour débloquer les fonctionnalités Premium et Ultimate. Découvrez les étapes d'activation, les options de licence et les conseils de dépannage."
title: Activer GitLab Enterprise Edition (EE)
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lorsque vous installez une nouvelle instance GitLab sans licence, seules les fonctionnalités Free sont activées. Pour activer davantage de fonctionnalités dans GitLab Enterprise Edition (EE), activez votre instance avec un code d'activation.

## Activer GitLab EE {#activate-gitlab-ee}

Prérequis :

- [Un abonnement](https://about.gitlab.com/pricing/).
- GitLab Enterprise Edition (EE).
- Votre instance est connectée à Internet.
- Accès administrateur.

Pour activer votre instance avec un code d'activation :

1. Copiez le code d'activation, une chaîne alphanumérique de 24 caractères, depuis l'un des emplacements suivants :
   - L'e-mail de confirmation de votre abonnement.
   - Le [Portail clients](https://customers.gitlab.com/customers/sign_in), sur la page **Gérer les achats**.
1. Connectez-vous à votre instance.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Abonnement**.
1. Collez le code d'activation dans **Code d'activation**.
1. Lisez et acceptez les conditions d'utilisation.
1. Sélectionnez **Activer**.

L'abonnement est activé.

### Utiliser un seul code d'activation pour plusieurs instances {#using-one-activation-code-for-multiple-instances}

Vous pouvez utiliser un seul code d'activation ou clé de licence pour plusieurs instances GitLab Self-Managed si les utilisateurs sont :

- Identiques à votre instance de production sous licence.
- Un sous-ensemble de votre instance de production sous licence.

Le code d'activation est valide pour ces instances, quelle que soit la configuration des utilisateurs dans les groupes et les projets.

### Pour les architectures à grande échelle {#for-scaled-architectures}

Pour activer votre instance dans une architecture à grande échelle :

- Téléchargez le fichier de licence sur une seule instance d'application.

La licence est stockée dans la base de données et répliquée sur toutes les instances.

### Pour GitLab Geo {#for-gitlab-geo}

Pour activer votre instance lors de l'utilisation de GitLab Geo :

- Téléchargez la licence sur votre instance Geo principale.

La licence est stockée dans la base de données et répliquée sur toutes les instances.

### Pour les environnements hors ligne {#for-offline-environments}

Pour activer votre instance dans un environnement hors ligne :

- [Activer GitLab EE avec un fichier de licence ou une clé](license_file.md).

Si vous avez des questions ou si vous avez besoin d'aide pour activer votre instance, [contactez le support GitLab](https://about.gitlab.com/support/#contact-support).

Lorsque [la licence expire](license_file.md#what-happens-when-your-license-expires), certaines fonctionnalités sont verrouillées.

## Vérifier votre édition GitLab {#verify-your-gitlab-edition}

Pour vérifier l'édition, connectez-vous à GitLab et sélectionnez **Aide** ({{< icon name="question-o" >}}) > **Aide**. L'édition et la version de GitLab sont indiquées en haut de la page.

Si vous utilisez GitLab Community Edition (CE), vous pouvez mettre à niveau votre installation vers GitLab EE. Pour plus d'informations, consultez [les autres chemins de mise à niveau](../update/convert_to_ee/_index.md).

Si vous avez des questions ou si vous avez besoin d'aide, [contactez le support GitLab](https://about.gitlab.com/support/#contact-support).

## Dépannage {#troubleshooting}

Lors de l'activation des fonctionnalités de votre abonnement payant sur des instances GitLab Self-Managed, vous pouvez rencontrer les problèmes suivants.

### Erreur : `An error occurred while adding your subscription` {#error-an-error-occurred-while-adding-your-subscription}

Ce problème peut survenir après avoir saisi votre code d'activation.

Pour obtenir plus de détails sur l'erreur, vous pouvez utiliser les outils de développement de votre navigateur :

1. Pour ouvrir les outils de développement, faites un clic droit sur une page et sélectionnez **Inspecter**.
1. Sélectionnez l'onglet **Réseau**.
1. Dans GitLab, réessayez le code d'activation.
1. Dans l'onglet **Réseau**, sélectionnez l'entrée `graphql`.
1. Sélectionnez l'onglet **Réponse** et vérifiez si une erreur similaire à la suivante est présente :

      ```plaintext
      [{"data":{"gitlabSubscriptionActivate":{"errors":["<error> returned=1 errno=0 state=error: <error>"],"license":null,"__typename":"GitlabSubscriptionActivatePayload"}}}]
      ```

Pour résoudre le problème :

- Si la réponse GraphQL contient `only get, head, options, and trace methods are allowed in silent mode`, désactivez le [mode silencieux](silent_mode/_index.md#turn-off-silent-mode) pour votre instance.

Si vous ne parvenez pas à identifier le problème, contactez le [support GitLab](https://about.gitlab.com/support/portal/) et fournissez la réponse GraphQL dans votre description du problème.

### Erreur : `Cannot activate instance due to a connectivity issue` {#error-cannot-activate-instance-due-to-a-connectivity-issue}

Lors de l'activation de votre instance, vous pouvez rencontrer des problèmes de connectivité empêchant la connexion aux serveurs GitLab. Cela peut être causé par :

- **Les paramètres du pare-feu** :
  - Pour confirmer que votre instance GitLab peut établir une connexion chiffrée à `https://customers.gitlab.com` sur le port 443, utilisez la commande curl suivante :

    ```shell
    curl --verbose "https://customers.gitlab.com/"
    ```

  - Si la commande curl retourne une erreur, vous pouvez :
    - Vérifiez votre pare-feu ou votre proxy. Le domaine `https://customers.gitlab.com` est protégé par Cloudflare. Assurez-vous que votre pare-feu ou votre proxy autorise le trafic vers les plages [IPv4](https://www.cloudflare.com/ips-v4/) et [IPv6](https://www.cloudflare.com/ips-v6/) de Cloudflare pour que l'activation fonctionne.
    - [Configurez un proxy](https://docs.gitlab.com/omnibus/settings/environment-variables/) dans `gitlab.rb` pour pointer vers votre serveur.

    Contactez votre administrateur réseau pour apporter des modifications à un proxy ou un pare-feu existant.
  - Si un dispositif d'inspection SSL est utilisé, vous devez ajouter le certificat CA racine du dispositif dans `/etc/gitlab/trusted-certs` sur votre instance, puis exécuter `gitlab-ctl reconfigure`.
- **Le portail clients n’est pas opérationnel** :
  - Vérifiez l'existence de perturbations actives sur le Portail clients via la page [status](https://status.gitlab.com/).
- **Un environnement hors ligne** :
  - Vérifiez les [paramètres DNS](https://docs.gitlab.com/omnibus/settings/dns/).
  - Contactez :
    - Votre représentant commercial GitLab pour demander une [licence hors ligne](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#what-is-an-offline-cloud-license).
    - [Le support GitLab](https://about.gitlab.com/support/#contact-support) pour demander de l'aide concernant le [dépannage de la connectivité réseau](https://handbook.gitlab.com/handbook/support/license-and-renewals/workflows/self-managed/troubleshoot_cloud_licensing/#troubleshooting-network-connectivity).
