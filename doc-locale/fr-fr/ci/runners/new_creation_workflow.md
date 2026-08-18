---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Migration vers le nouveau workflow d'enregistrement des runners"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!disclaimer]

GitLab 16.0 a introduit un nouveau workflow de création de runners qui utilise des jetons d'authentification de runner pour enregistrer les runners. Le workflow hérité qui utilise des jetons d'enregistrement n'est pas recommandé. Utilisez plutôt le [workflow de création de runners](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token).

Pour obtenir des informations sur le statut de développement actuel du nouveau workflow, consultez l'[epic 7663](https://gitlab.com/groups/gitlab-org/-/epics/7663).

Pour obtenir des informations sur la conception technique et les raisons de la nouvelle architecture, consultez [next GitLab Runner Token architecture](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/runner_tokens/).

Si vous rencontrez des problèmes ou avez des préoccupations concernant le nouveau workflow d'enregistrement des runners, ou si vous avez besoin de plus d'informations, faites-le nous savoir dans le [ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/387993).

## Le nouveau workflow d'enregistrement des runners {#the-new-runner-registration-workflow}

Pour le nouveau workflow d'enregistrement des runners, vous devez :

1. [Créer un runner](runners_scope.md) directement dans l'interface GitLab ou [de manière programmatique](#creating-runners-programmatically).
1. Recevoir un jeton d'authentification de runner.
1. Utiliser le jeton d'authentification de runner à la place du jeton d'enregistrement lorsque vous enregistrez un runner avec cette configuration. Les gestionnaires de runners enregistrés sur plusieurs hôtes apparaissent sous le même runner dans l'interface GitLab, mais avec un ID système d'identification.

Le nouveau workflow d'enregistrement des runners présente les avantages suivants :

- Conservation des enregistrements de propriété des runners et minimisation de l'impact sur les utilisateurs.
- L'ajout d'un ID système unique vous permet de réutiliser le même jeton d'authentification sur plusieurs runners. Pour plus d'informations, consultez [Reusing a GitLab Runner configuration](https://docs.gitlab.com/runner/fleet_scaling/#reusing-a-gitlab-runner-configuration).

## Calendrier estimé des changements prévus {#estimated-time-frame-for-planned-changes}

- Dans GitLab 15.10 et les versions ultérieures, vous pouvez utiliser le nouveau workflow d'enregistrement des runners.

## Empêcher votre workflow d'enregistrement des runners de dysfonctionner {#prevent-your-runner-registration-workflow-from-breaking}

Dans GitLab 16.11 et les versions antérieures, vous pouvez utiliser le workflow hérité d'enregistrement des runners.

Dans GitLab 17.0 et les versions ultérieures, le workflow hérité d'enregistrement des runners peut être désactivé par les administrateurs d'instance ou les propriétaires de groupe. Pour plus d'informations, consultez [Utilisation des jetons d'enregistrement après GitLab 17.0](#using-registration-tokens-after-gitlab-170).

Si vous enregistrez un runner sans migrer vers le nouveau workflow, l'enregistrement du runner échoue et la commande `gitlab-runner register` retourne une erreur `410 Gone - runner registration disallowed`.

Pour éviter un workflow dysfonctionnel, vous devez :

1. [Créer un runner](runners_scope.md) et obtenir le jeton d'authentification.
1. Remplacer le jeton d'enregistrement dans votre workflow d'enregistrement des runners par le jeton d'authentification.

## Utilisation des jetons d'enregistrement après GitLab 17.0 {#using-registration-tokens-after-gitlab-170}

Pour continuer à utiliser des jetons d'enregistrement après GitLab 17.0 :

- Sur GitLab.com, vous pouvez manuellement [activer le processus d'enregistrement hérité des runners](runners_scope.md#enable-use-of-runner-registration-tokens-in-projects-and-groups) dans les paramètres du groupe principal.
- Sur GitLab Self-Managed, vous pouvez manuellement [activer le processus d'enregistrement hérité des runners](../../administration/settings/continuous_integration.md#control-runner-registration) dans les paramètres de la zone **Admin**.

## Impact sur les runners existants {#impact-on-existing-runners}

Les runners existants continueront à fonctionner normalement après la mise à niveau vers GitLab 17.0. Cette modification affecte uniquement l'enregistrement des nouveaux runners.

Le [chart Helm GitLab Runner](https://docs.gitlab.com/runner/install/kubernetes/) génère de nouveaux pods de runner à chaque exécution d'un job. Pour ces runners, [activez l'enregistrement hérité des runners](#using-registration-tokens-after-gitlab-170) pour utiliser les jetons d'enregistrement.

## Modifications de la syntaxe de la commande `gitlab-runner register` {#changes-to-the-gitlab-runner-register-command-syntax}

La commande `gitlab-runner register` accepte des jetons d'authentification de runner à la place des jetons d'enregistrement. Vous pouvez générer des jetons depuis la page **Runners** dans la zone **Admin**. Les jetons d'authentification de runner sont reconnaissables par leur préfixe `glrt-`.

Lorsque vous créez un runner dans l'interface GitLab, vous spécifiez des valeurs de configuration qui étaient auparavant des options de ligne de commande demandées par la commande `gitlab-runner register`.

Si vous spécifiez un jeton d'authentification de runner avec :

- l'option de ligne de commande `--token`, la commande `gitlab-runner register` n'accepte pas les valeurs de configuration.
- l'option de ligne de commande `--registration-token`, la commande `gitlab-runner register` ignore les valeurs de configuration.

| Jeton                                  | Commande d'enregistrement |
|----------------------------------------|----------------------|
| Jeton d'authentification de runner            | `gitlab-runner register --token $RUNNER_AUTHENTICATION_TOKEN` |
| Jeton d'enregistrement de runner (hérité)     | `gitlab-runner register --registration-token $RUNNER_REGISTRATION_TOKEN <runner configuration arguments>` |

Les jetons d'authentification ont le préfixe `glrt-`.

Pour assurer une interruption minimale de votre workflow d'automatisation, le [traitement d'enregistrement compatible avec le mode hérité](https://docs.gitlab.com/runner/register/#legacy-compatible-registration-process) se déclenche si un jeton d'authentification de runner est spécifié dans le paramètre hérité `--registration-token`.

Exemple de commande pour GitLab 15.9 :

```shell
gitlab-runner register \
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --tag-list "shell,mac,gdk,test" \
    --run-untagged "false" \
    --locked "false" \
    --access-level "not_protected" \
    --registration-token "REDACTED"
```

Dans GitLab 15.10 et les versions ultérieures, vous pouvez créer le runner et définir des attributs dans l'interface, tels que la liste de tags, le statut de verrouillage et le niveau d'accès. Dans GitLab 15.11 et les versions ultérieures, ces attributs ne sont plus acceptés comme arguments de `register` lorsqu'un jeton d'authentification de runner avec le préfixe `glrt-` est spécifié.

L'exemple suivant montre la nouvelle commande :

```shell
gitlab-runner register \
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --token "REDACTED"
```

## Impact sur la mise à l'échelle automatique {#impact-on-autoscaling}

Dans les scénarios de mise à l'échelle automatique tels que GitLab Runner Operator ou GitLab Runner Helm Chart, le jeton d'authentification de runner généré depuis l'interface remplace le jeton d'enregistrement. Cela signifie que la même configuration de runner est réutilisée pour les jobs, au lieu de créer un runner pour chaque job. Le runner spécifique peut être identifié par l'ID système unique qui est généré au démarrage du processus du runner.

## Création de runners de manière programmatique {#creating-runners-programmatically}

Dans GitLab 15.11 et les versions ultérieures, vous pouvez utiliser l'[API REST POST /user/runners](../../api/users.md#create-a-runner-linked-to-a-user) pour créer un runner en tant qu'utilisateur authentifié. Cette méthode ne doit être utilisée que si la configuration du runner est dynamique ou non réutilisable. Si la configuration du runner est statique, vous devez réutiliser le jeton d'authentification de runner d'un runner existant.

Pour obtenir des instructions sur la façon d'automatiser la création et l'enregistrement des runners, consultez le tutoriel [Automate runner creation and registration](../../tutorials/automate_runner_creation/_index.md).

## Installation de GitLab Runner avec un chart Helm {#installing-gitlab-runner-with-helm-chart}

Plusieurs options de configuration des runners ne peuvent pas être définies lors de l'enregistrement des runners si les jetons d'enregistrement des runners sont désactivés. Ces options ne peuvent être configurées que :

- Lorsque vous créez un runner dans l'interface.
- Avec le point de terminaison d'API REST `user/runners`.

Les options de configuration suivantes ne sont pas prises en charge dans [`values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/main/values.yaml) dans ce scénario :

```yaml
## If a runner authentication token is specified in runnerRegistrationToken, the registration will succeed, however the
## other values will be ignored.
runnerRegistrationToken: ""
locked: true
tags: ""
maximumTimeout: ""
runUntagged: true
protected: true
```

Pour GitLab Runner sur Kubernetes, le déploiement Helm transmet le jeton d'authentification de runner au pod worker du runner et crée la configuration du runner. Dans GitLab 17.0 et les versions ultérieures, si vous utilisez le champ de jeton `runnerRegistrationToken` sur les runners hébergés sur Kubernetes attachés à GitLab.com, le pod worker du runner tente d'utiliser la méthode API d'enregistrement héritée lors de la création.

Remplacez le champ `runnerRegistrationToken` non valide par le champ `runnerToken`. Vous devez également modifier le jeton d'authentification de runner stocké dans `secrets`.

Dans le workflow hérité d'enregistrement des runners, les champs étaient spécifiés avec :

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner-secret
type: Opaque
data:
  runner-registration-token: "REDACTED" # DEPRECATED, set to ""
  runner-token: ""
```

Dans le nouveau workflow d'enregistrement des runners, vous devez utiliser `runner-token` à la place :

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner-secret
type: Opaque
data:
  runner-registration-token: "" # need to leave as an empty string for compatibility reasons
  runner-token: "REDACTED"
```

> [!note]
> Si votre solution de gestion des secrets ne vous permet pas de définir une chaîne vide pour `runner-registration-token`, vous pouvez la définir sur n'importe quelle chaîne. Cette valeur est ignorée lorsque `runner-token` est présent.

## Problèmes connus {#known-issues}

### Le nom du pod n'est pas visible dans la page de détails du runner {#pod-name-is-not-visible-in-runner-details-page}

Lorsque vous utilisez le nouveau workflow d'enregistrement pour enregistrer vos runners avec un chart Helm, le nom du pod n'apparaît pas dans la page de détails du runner. Pour plus d'informations, consultez le [ticket 423523](https://gitlab.com/gitlab-org/gitlab/-/issues/423523).

### Le jeton d'authentification de runner ne se met pas à jour lors de la rotation {#runner-authentication-token-does-not-update-when-rotated}

#### Rotation du jeton avec le même runner enregistré dans plusieurs gestionnaires de runners {#token-rotation-with-the-same-runner-registered-in-multiple-runner-managers}

Lorsque vous enregistrez des runners sur plusieurs machines hôtes via le nouveau workflow avec la rotation automatique des jetons, seul le premier gestionnaire de runners reçoit le nouveau jeton. Les gestionnaires de runners restants continuent à utiliser le jeton non valide et se déconnectent. Vous devez mettre à jour ces gestionnaires manuellement pour utiliser le nouveau jeton.

#### Rotation des jetons dans GitLab Operator {#token-rotation-in-gitlab-operator}

Lors de l'enregistrement des runners avec GitLab Operator via le nouveau workflow, le jeton d'authentification de runner dans la Custom Resource Definition ne se met pas à jour lors de la rotation des jetons. Cela se produit lorsque :

- Vous utilisez un jeton d'authentification de runner (préfixé par `glrt-`) dans un secret [référencé par une Custom Resource Definition](https://docs.gitlab.com/runner/install/operator/#install-gitlab-runner).
- Le jeton d'authentification de runner est sur le point d'expirer. Pour plus d'informations sur l'expiration des jetons d'authentification de runner, consultez [Authentication token security](configure_runners.md#authentication-token-security).

Pour plus d'informations, consultez le [ticket 186](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/186).
