---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez la messagerie, l'authentification, CI/CD, GitLab Duo et d'autres fonctionnalités après avoir installé GitLab."
title: "Étapes après l'installation de GitLab"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Voici quelques ressources que vous pourriez consulter après avoir effectué l'installation.

## Première connexion {#initial-sign-in}

Après avoir installé GitLab, vous pouvez accéder à l'URL que vous avez configurée lors de l'installation et vous connecter en tant qu'utilisateur `root`.

Si vous n'avez pas défini votre propre mot de passe lors de l'installation, un mot de passe aléatoire est attribué. Vous pouvez le trouver sur le serveur sur lequel vous avez installé GitLab, sous `/etc/gitlab/initial_root_password`.

## E-mail et notifications {#email-and-notifications}

- [SMTP](https://docs.gitlab.com/omnibus/settings/smtp/) : configurez SMTP pour assurer la prise en charge correcte des notifications par e-mail.
- [E-mail entrant](../administration/incoming_email.md) : configurez la messagerie entrante afin que les utilisateurs puissent répondre aux commentaires, créer de nouveaux tickets et des merge requests, etc. par e-mail.

## GitLab Duo {#gitlab-duo}

- [GitLab Duo](../user/gitlab_duo/_index.md) : découvrez les fonctionnalités natives d'IA que GitLab propose et comment les activer.
- [GitLab Duo Self-Hosted](../administration/gitlab_duo_self_hosted/_index.md) : déployez GitLab Duo Self-Hosted pour utiliser le LLM pris en charge par GitLab que vous préférez.
- [Utilisation des données GitLab Duo](../user/gitlab_duo/data_usage.md) : découvrez comment GitLab gère la confidentialité des données d'IA.

## CI/CD (Runner) {#cicd-runner}

- [Configurer des runners](https://docs.gitlab.com/runner/) : configurez un ou plusieurs runners, les agents responsables de l'exécution des jobs CI/CD.

## Container Registry {#container-registry}

- [Container Registry](../administration/packages/container_registry.md) : registre de conteneurs intégré pour stocker les images de conteneurs pour chaque projet GitLab.
- [GitLab Dependency Proxy](../administration/packages/dependency_proxy.md) : configurez le proxy de dépendances afin de pouvoir mettre en cache les images de conteneurs depuis Docker Hub pour des builds plus rapides et plus fiables.

## Pages {#pages}

- [GitLab Pages](../user/project/pages/_index.md) : publiez des sites web statiques directement depuis un dépôt dans GitLab.

## Sécurité {#security}

- [Sécuriser GitLab](../security/_index.md) : pratiques recommandées pour sécuriser votre instance GitLab.
- Inscrivez-vous à la [newsletter Sécurité](https://about.gitlab.com/company/preference-center/) de GitLab pour être informé des mises à jour de sécurité lors de leur release.

## Authentification {#authentication}

- [LDAP](../administration/auth/ldap/_index.md) : configurez LDAP pour l'utiliser comme mécanisme d'authentification pour GitLab.
- [SAML et OAuth](../integration/omniauth.md) : authentifiez-vous via des services en ligne tels qu'Okta, Google, Azure AD, et bien d'autres.

## Sauvegarde et mise à niveau {#backup-and-upgrade}

- [Sauvegarder et restaurer GitLab](../administration/backup_restore/_index.md) : découvrez les différentes façons de sauvegarder ou de restaurer GitLab.
- [Mettre à niveau GitLab](../update/_index.md) : chaque mois, une nouvelle version de GitLab enrichie de fonctionnalités est publiée. Découvrez comment effectuer la mise à niveau vers cette version ou vers une release intermédiaire contenant un correctif de sécurité.
- [Politique de release et de maintenance](../policy/maintenance.md) : découvrez les politiques de GitLab régissant la dénomination des versions, ainsi que le rythme des releases majeures, mineures et de correctifs.

## Licence {#license}

- [Ajouter une licence](../administration/license.md) ou [démarrer un essai gratuit](https://about.gitlab.com/free-trial/) : activez toutes les fonctionnalités de GitLab Enterprise Edition avec une licence.
- [Tarification](https://about.gitlab.com/pricing/) : tarification pour les différentes éditions.

## Recherche de code inter-dépôts {#cross-repository-code-search}

- [Recherche avancée](../integration/advanced_search/elasticsearch.md) : utilisez [Elasticsearch](https://www.elastic.co/) ou [OpenSearch](https://opensearch.org/) pour une recherche de code plus rapide et plus avancée dans l'ensemble de votre instance GitLab.

## Mise à l'échelle et réplication {#scaling-and-replication}

- [Mise à l'échelle de GitLab](../administration/reference_architectures/_index.md) : GitLab prend en charge plusieurs types de clustering.
- [Réplication Geo](../administration/geo/_index.md) : Geo est la solution pour les équipes de développement largement distribuées.

## Installer la documentation produit {#install-the-product-documentation}

Facultatif. Si vous souhaitez héberger la documentation sur votre propre serveur, découvrez comment [auto-héberger la documentation produit](../administration/docs_self_host.md).
