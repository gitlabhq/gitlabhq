---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mobile DevOps
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Créez, signez et publiez des applications mobiles natives et multiplateformes pour Android et iOS à l'aide de GitLab CI/CD. GitLab Mobile DevOps fournit des outils et des bonnes pratiques pour automatiser votre workflow de développement d'applications mobiles.

GitLab Mobile DevOps intègre des fonctionnalités clés de développement mobile dans la plateforme GitLab DevSecOps :

- Environnements de build pour le développement iOS et Android
- Signature de code sécurisée et gestion des certificats
- Distribution via les stores d'applications pour Google Play et Apple App Store

## Environnements de build {#build-environments}

Pour un contrôle total sur l'environnement de build, vous pouvez utiliser des [runners hébergés par GitLab](../runners/_index.md) ou configurer des [runners autogérés](https://docs.gitlab.com/runner/#use-self-managed-runners).

## Signature de code {#code-signing}

Toutes les applications Android et iOS doivent être signées de manière sécurisée avant d'être distribuées via les différents stores d'applications. La signature garantit que les applications n'ont pas été altérées avant d'atteindre l'appareil de l'utilisateur.

Avec les [fichiers sécurisés au niveau du projet](../secure_files/_index.md), vous pouvez stocker les éléments suivants dans GitLab afin de les utiliser pour signer les applications de manière sécurisée dans les builds CI/CD :

- Keystores
- Profils de provisionnement
- Certificats de signature

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez la [démonstration des fichiers sécurisés au niveau du projet](https://youtu.be/O7FbJu3H2YM).

## Distribution {#distribution}

Les builds signés peuvent être téléversés vers le Google Play Store ou l'Apple App Store à l'aide des intégrations de distribution Mobile DevOps.

## Sujets connexes {#related-topics}

Pour des instructions détaillées sur la mise en œuvre de Mobile DevOps, consultez :

- [Tutoriel : Créer des applications Android avec GitLab Mobile DevOps](mobile_devops_tutorial_android.md)
- [Tutoriel : Créer des applications iOS avec GitLab Mobile DevOps](mobile_devops_tutorial_ios.md)
