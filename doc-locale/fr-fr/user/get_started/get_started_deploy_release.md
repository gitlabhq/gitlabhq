---
stage: none
group: none
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Déployer et gérer les dépendances.
title: Premiers pas avec le déploiement et la mise en production de votre application
---

Commencez par prévisualiser votre application et terminez par son déploiement en production devant vos utilisateurs. Gérez les conteneurs et les paquets, utilisez l'intégration continue pour livrer votre application, et utilisez les feature flags et les déploiements progressifs pour mettre en production l'application de manière contrôlée.

Ces processus font partie d'un workflow plus large :

![Schéma des principales actions à effectuer dans GitLab avec la section « Déployer et mettre en production votre application » mise en évidence.](img/get_started_release_v16_11.png)

## Étape 1 :  Stocker et accéder aux artefacts de votre projet {#step-1-store-and-access-your-projects-artifacts}

Utilisez les paquets et les registres pour stocker et distribuer les dépendances, bibliothèques et autres artefacts de votre projet en toute sécurité dans GitLab.

Le registre de paquets prend en charge divers formats de paquets, notamment Maven, NPM, NuGet, PyPI et Conan. Il fournit un emplacement centralisé pour stocker et distribuer des paquets dans l'ensemble de vos projets. Intégrez le registre de paquets aux pipelines pipeline CI/CD GitLab pour automatiser la publication des paquets et garantir des workflows de développement et de déploiement fluides.

Le registre de conteneurs fait office de registre privé pour les images Docker. Utilisez-le pour stocker, gérer et distribuer des images Docker et OCI au sein de votre organisation, ou publiquement. Intégrez le registre de conteneurs à GitLab CI/CD pour créer, tester et déployer des applications conteneurisées.

Pour plus d'informations, consultez :

- [Paquets et registres](../packages/_index.md)

## Étape 2 :  Déployer votre application dans différents environnements {#step-2-deploy-your-application-across-environments}

Utilisez les environnements pour gérer et suivre les déploiements de votre application dans différentes étapes (par exemple, développement, staging et production). Chaque environnement peut avoir sa propre configuration, ses propres variables et ses propres paramètres de déploiement.

Une fois vos environnements configurés, vous pouvez les surveiller. Bien que vous surveilliez principalement vos déploiements à l'emplacement où vous les avez déployés (par exemple, dans AWS), GitLab fournit également des tableaux de bord. Vous pouvez surveiller l'état en direct de votre cluster dans l'interface utilisateur GitLab si vous déployez sur Kubernetes.

Vous pouvez également créer des environnements temporaires dans le cadre de merge requests. Les membres de l'équipe peuvent alors réviser et tester les modifications avant de les committer dans la branche principale. Ces environnements temporaires sont appelés environnements éphémères.

Pour plus d'informations, consultez :

- [Environnements](../../ci/environments/_index.md)
- [Déployer sur AWS](../../ci/cloud_deployment/_index.md)
- [Déployer sur Kubernetes](../clusters/agent/_index.md)
- [Tableau de bord pour Kubernetes](../../ci/environments/kubernetes_dashboard.md)
- [Tableau de bord des environnements](../../ci/environments/environments_dashboard.md)
- [Tableau de bord des opérations](../operations_dashboard/_index.md)
- [Environnements éphémères](../../ci/review_apps/_index.md)

## Étape 3 :  Rester conforme grâce aux fonctionnalités de livraison continue {#step-3-stay-compliant-with-continuous-delivery-features}

Pour maintenir la stabilité et l'intégrité de vos systèmes de production en empêchant les déploiements accidentels ou non autorisés, utilisez les environnements protégés. Ils offrent un moyen de sécuriser et de contrôler les déploiements vers des environnements critiques tels que la production. En définissant des environnements protégés, vous pouvez restreindre l'accès à des utilisateurs ou des rôles spécifiques, en vous assurant que seuls les utilisateurs autorisés peuvent déployer des modifications.

La sécurité des déploiements fait partie du pipeline de livraison continue et contribue à garantir la fiabilité et la sécurité de vos déploiements. GitLab fournit des mécanismes de sécurité intégrés, tels que les rollbacks automatiques en cas d'échec de déploiement, et la possibilité de définir des vérifications de l'état personnalisées pour vérifier la réussite d'un déploiement.

Les approbations de déploiement ajoutent une couche supplémentaire de contrôle et de collaboration à votre processus de déploiement. Vous pouvez définir des règles d'approbation qui obligent les approbateurs désignés à réviser et à approuver les déploiements avant qu'ils puissent être effectués. Les approbations peuvent être configurées selon différents critères, tels que l'environnement, la branche ou les modifications spécifiques en cours de déploiement.

Pour plus d'informations, consultez :

- [Environnements protégés](../../ci/environments/protected_environments.md)
- [Sécurité des déploiements](../../ci/environments/deployment_safety.md)
- [Approbations de déploiement](../../ci/environments/deployment_approvals.md)

## Étape 4 :  Livrer les artefacts de release aux utilisateurs publics ou internes {#step-4-ship-release-artifacts-to-the-public-or-internal-users}

Utilisez les releases pour packager et distribuer votre application aux utilisateurs finaux, avec notamment les notes de release, les ressources binaires et d'autres informations pertinentes. Vous pouvez créer une release à partir de n'importe quelle branche.

Intégrez les releases aux environnements pour créer automatiquement une release chaque fois que vous déployez dans un environnement spécifique (par exemple, la production). Vous pouvez être notifié chaque fois qu'une release est effectuée, et spécifier des permissions si vous souhaitez contrôler qui est autorisé à créer, mettre à jour et supprimer des releases.

Pour plus d'informations, consultez :

- [Releases](../project/releases/_index.md)

## Étape 5 :  Déployer les modifications en toute sécurité {#step-5-roll-out-changes-safely}

Pour déployer progressivement votre application auprès d'un sous-ensemble d'utilisateurs ou de serveurs, utilisez les déploiements progressifs. Vous pouvez surveiller et évaluer l'impact à plus petite échelle avant de déployer auprès de l'ensemble de la base d'utilisateurs.

Les feature flags dans GitLab offrent un moyen d'activer ou de désactiver des fonctionnalités spécifiques dans votre application sans nécessiter un déploiement complet. Vous pouvez utiliser les feature flags pour tester en toute sécurité de nouvelles fonctionnalités, effectuer des tests A/B ou introduire progressivement des modifications pour vos utilisateurs.

En utilisant les feature flags, vous pouvez découpler le déploiement du code de la mise en production des fonctionnalités, ce qui vous donne plus de contrôle sur l'expérience utilisateur et réduit le risque d'introduire des bugs ou des comportements inattendus.

Pour plus d'informations, consultez :

- [Déploiements progressifs](../../ci/environments/incremental_rollouts.md)
- [Feature flags](../../operations/feature_flags.md)

## Étape 6 :  Déployer un site web statique {#step-6-deploy-a-static-website}

Avec GitLab Pages, vous pouvez mettre en valeur la documentation, les démonstrations ou les pages marketing de votre projet. Créez des sites web statiques directement à partir d'un dépôt dans GitLab. GitLab Pages prend en charge les générateurs de sites statiques tels que Jekyll, Hugo et Middleman, ainsi que le HTML, le CSS et le JavaScript simples. Pour commencer, créez un nouveau projet ou utilisez un projet existant, configurez les paramètres de GitLab Pages et poussez votre contenu vers le dépôt. GitLab crée et déploie automatiquement votre site web chaque fois que vous poussez des modifications vers la branche désignée.

Pour plus d'informations, consultez :

- [GitLab Pages](../project/pages/_index.md)

## Étape 7 :  Adopter une approche structurée avec Auto Deploy {#step-7-go-opinionated-with-auto-deploy}

Auto Deploy est un modèle CI structuré qui, entre autres choses, se charge de la création et du déploiement de votre application. Vous pouvez affiner le pipeline Auto DevOps avec des variables d'environnement.

Pour plus d'informations, consultez :

- [Auto Deploy](../../topics/autodevops/stages.md#auto-deploy)
