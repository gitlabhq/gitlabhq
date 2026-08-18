---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configuration chiffrée
description: Activez les paramètres de configuration chiffrés pour certaines fonctionnalités.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab peut lire les paramètres de certaines fonctionnalités à partir de fichiers de paramètres chiffrés. Les fonctionnalités prises en charge sont :

- [E-mail entrant `user` et `password`](incoming_email.md#use-encrypted-credentials).
- [LDAP `bind_dn` et `password`](auth/ldap/_index.md#use-encrypted-credentials).
- [E-mail du Service Desk `user` et `password`](../user/project/service_desk/configure.md#use-encrypted-credentials).
- [SMTP `user_name` et `password`](raketasks/smtp.md#secrets).

Pour activer les paramètres de configuration chiffrés, une nouvelle clé de base doit être générée pour `encrypted_settings_key_base`. Le secret peut être généré de l'une des façons suivantes :

- Pour les installations de packages Linux, le nouveau secret est automatiquement généré pour vous, mais vous devez vous assurer que votre `/etc/gitlab/gitlab-secrets.json` contient les mêmes valeurs sur tous les nœuds.
- Pour les installations de chart Helm, le nouveau secret est automatiquement généré si vous avez le chart `shared-secrets` activé. Sinon, vous devez suivre le [guide des secrets pour ajouter le secret](https://docs.gitlab.com/charts/installation/secrets/#gitlab-rails-secret).
- Pour les installations compilées manuellement, le nouveau secret peut être généré en exécutant :

  ```shell
  bundle exec rake gitlab:env:info RAILS_ENV=production GITLAB_GENERATE_ENCRYPTED_SETTINGS_KEY_BASE=true
  ```

  Cela affiche des informations générales sur l'instance GitLab et génère la clé dans `<path-to-gitlab-rails>/config/secrets.yml`.
