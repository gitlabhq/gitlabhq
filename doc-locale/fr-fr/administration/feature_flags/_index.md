---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 'Administrateur GitLab : activer et désactiver les fonctionnalités GitLab déployées derrière des feature flags'
title: Activer et désactiver les fonctionnalités GitLab déployées derrière des feature flags
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab a adopté des stratégies de feature flag pour déployer des fonctionnalités à un stade précoce du développement afin qu'elles puissent être déployées de manière progressive.

Avant de les rendre définitivement disponibles, les fonctionnalités peuvent être déployées derrière des flags pour plusieurs raisons, notamment :

- Pour tester la fonctionnalité.
- Pour recueillir les retours des utilisateurs et des clients à un stade précoce du développement de la fonctionnalité.
- Pour évaluer l'adoption par les utilisateurs.
- Pour évaluer l'impact sur les performances de GitLab.
- Pour le construire en plus petites parties tout au long des releases.

Les fonctionnalités derrière des flags peuvent être déployées progressivement, généralement :

1. La fonctionnalité commence désactivée par défaut.
1. La fonctionnalité devient activée par défaut.
1. Le feature flag est supprimé.

Ces fonctionnalités peuvent être activées et désactivées pour autoriser ou empêcher les utilisateurs de les utiliser. Cela peut être effectué par les administrateurs GitLab ayant accès à la [console Rails](#how-to-enable-and-disable-features-behind-flags) ou à l'[API Feature flags](../../api/features.md).

Lorsque vous désactivez un feature flag, la fonctionnalité est masquée pour les utilisateurs et toutes les fonctionnalités sont désactivées. Par exemple, les données ne sont pas enregistrées et les services ne s'exécutent pas.

Si vous avez utilisé une certaine fonctionnalité et identifié un bug, un comportement incorrect ou une erreur, il est très important que vous [**fournissiez des retours**](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issue[title]=Docs%20-%20feature%20flag%20feedback%3A%20Feature%20Name&issue[description]=Describe%20the%20problem%20you%27ve%20encountered.%0A%0A%3C!--%20Don%27t%20edit%20below%20this%20line%20--%3E%0A%0A%2Flabel%20~%22docs%5C-comments%22%20) à GitLab dès que possible afin que nous puissions l'améliorer ou le corriger pendant qu'il est derrière un flag. Lorsque vous mettez à niveau GitLab, le statut du feature flag peut changer.

## Risques lors de l'activation de fonctionnalités encore en développement {#risks-when-enabling-features-still-in-development}

Avant d'activer un feature flag désactivé dans un environnement GitLab de production, il est essentiel de comprendre les risques potentiels impliqués.

> [!warning]
> Une corruption des données, une dégradation de la stabilité, une dégradation des performances et des problèmes de sécurité peuvent survenir si vous activez une fonctionnalité désactivée par défaut.

Les fonctionnalités désactivées par défaut peuvent être modifiées ou supprimées sans préavis dans une future version de GitLab.

Les fonctionnalités derrière des feature flags désactivés par défaut ne sont pas recommandées pour une utilisation en environnement de production et les problèmes causés par l'utilisation de fonctionnalités désactivées par défaut ne sont pas couverts par le support GitLab.

Les problèmes de sécurité détectés dans les fonctionnalités désactivées par défaut sont corrigés dans les releases régulières et ne suivent pas notre [politique de maintenance](../../policy/maintenance.md#patch-releases) habituelle en ce qui concerne le backport du correctif.

## Risques lors de la désactivation de fonctionnalités publiées {#risks-when-disabling-released-features}

Dans la plupart des cas, le code du feature flag est supprimé dans une future version de GitLab. Si et quand cela se produit, à partir de ce moment, vous ne pouvez plus maintenir la fonctionnalité dans un état désactivé.

## Comment activer et désactiver les fonctionnalités derrière des flags {#how-to-enable-and-disable-features-behind-flags}

Chaque fonctionnalité possède son propre flag qui doit être utilisé pour l'activer et la désactiver. La documentation de chaque fonctionnalité derrière un flag comprend une section indiquant le statut du flag et la commande pour l'activer ou le désactiver.

### Démarrer la console Rails GitLab {#start-the-gitlab-rails-console}

La première chose à faire pour activer ou désactiver une fonctionnalité derrière un flag est de démarrer une session sur la console Rails GitLab.

Pour les installations avec le package Linux :

```shell
sudo gitlab-rails console
```

Pour les installations depuis les sources :

```shell
sudo -u git -H bundle exec rails console -e production
```

Pour plus de détails, consultez [démarrer une session de console Rails](../operations/rails_console.md#starting-a-rails-console-session).

### Activer ou désactiver la fonctionnalité {#enable-or-disable-the-feature}

Une fois la session de console Rails démarrée, exécutez les commandes `Feature.enable` ou `Feature.disable` en conséquence. Le flag spécifique se trouve dans la documentation de la fonctionnalité elle-même.

Pour activer une fonctionnalité, exécutez :

```ruby
Feature.enable(:<feature flag>)
```

Exemple, pour activer un feature flag fictif nommé `example_feature` :

```ruby
Feature.enable(:example_feature)
```

Pour désactiver une fonctionnalité, exécutez :

```ruby
Feature.disable(:<feature flag>)
```

Exemple, pour désactiver un feature flag fictif nommé `example_feature` :

```ruby
Feature.disable(:example_feature)
```

Certains feature flags peuvent être activés ou désactivés par projet :

```ruby
Feature.enable(:<feature flag>, Project.find(<project id>))
```

Par exemple, pour activer le feature flag `:example_feature` pour le projet `1234` :

```ruby
Feature.enable(:example_feature, Project.find(1234))
```

Certains feature flags peuvent être activés ou désactivés par utilisateur. Par exemple, pour activer le flag `:example_feature` pour l'utilisateur `sidney_jones` :

```ruby
Feature.enable(:example_feature, User.find_by_username("sidney_jones"))
```

`Feature.enable` et `Feature.disable` renvoient toujours `true`, même si l'application n'utilise pas le flag :

```ruby
irb(main):001:0> Feature.enable(:example_feature)
=> true
```

Lorsque la fonctionnalité est prête, GitLab supprime le feature flag, et l'option pour l'activer et le désactiver n'existe plus. La fonctionnalité devient disponible dans toutes les instances.

### Vérifier si un feature flag est activé {#check-if-a-feature-flag-is-enabled}

Pour vérifier si un flag est activé ou désactivé, utilisez `Feature.enabled?` ou `Feature.disabled?`. Par exemple, pour un feature flag nommé `example_feature` qui est déjà activé :

```ruby
Feature.enabled?(:example_feature)
=> true
Feature.disabled?(:example_feature)
=> false
```

Lorsque la fonctionnalité est prête, GitLab supprime le feature flag, et l'option pour l'activer et le désactiver n'existe plus. La fonctionnalité devient disponible dans toutes les instances.

### Afficher les feature flags définis {#view-set-feature-flags}

Vous pouvez afficher tous les feature flags définis par l'administrateur GitLab :

```ruby
Feature.all
=> [#<Flipper::Feature:198220 name="example_feature", state=:on, enabled_gate_names=[:boolean], adapter=:memoizable>]

# Nice output
Feature.all.map {|f| [f.name, f.state]}
```

### Annuler la définition d'un feature flag {#unset-feature-flag}

Vous pouvez annuler la définition d'un feature flag afin que GitLab revienne aux valeurs par défaut actuelles pour ce flag :

```ruby
Feature.remove(:example_feature)
=> true
```
