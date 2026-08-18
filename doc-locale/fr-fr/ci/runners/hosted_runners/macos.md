---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Runners hébergés sur macOS
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : Version bêta

{{< /details >}}

Les runners hébergés sur macOS fournissent un environnement macOS à la demande, entièrement intégré avec GitLab [CI/CD](../../_index.md). Vous pouvez utiliser ces runners pour compiler, tester et déployer des applications pour l'écosystème Apple (macOS, iOS, watchOS, tvOS). Notre [section Mobile DevOps](../../mobile_devops/mobile_devops_tutorial_ios.md#set-up-your-build-environment) fournit des fonctionnalités, de la documentation et des conseils sur la compilation et le déploiement d'applications mobiles pour iOS.

Les runners hébergés sur macOS sont en [version bêta](../../../policy/development_stages_support.md#beta) et disponibles pour les programmes open source et les clients disposant des plans Premium et Ultimate. La [disponibilité générale](../../../policy/development_stages_support.md#generally-available) des runners hébergés sur macOS est proposée dans l'[epic 8267](https://gitlab.com/groups/gitlab-org/-/epics/8267).

Consultez la liste des [problèmes connus et des contraintes d'utilisation](#known-issues-and-usage-constraints) qui affectent les runners hébergés sur macOS avant de les utiliser.

## Types de machines disponibles pour macOS {#machine-types-available-for-macos}

GitLab propose le type de machine suivant pour les runners hébergés sur macOS. Pour compiler pour une cible x86-64, vous pouvez utiliser Rosetta 2 pour émuler un environnement Intel x86-64.

| Tag du runner               | vCPU | Mémoire | Stockage |
| ------------------------ | ----- | ------ | ------- |
| `saas-macos-medium-m1`   | 4     | 8 Go   | 50 Go   |
| `saas-macos-large-m2pro` | 6     | 16 Go  | 50 Go   |

## Images macOS prises en charge {#supported-macos-images}

Contrairement à nos runners hébergés sur Linux, où vous pouvez exécuter n'importe quelle image Docker, GitLab fournit un ensemble d'images VM pour macOS.

Vous pouvez exécuter votre compilation dans l'une des images suivantes, que vous spécifiez dans votre fichier `.gitlab-ci.yml`. Chaque image exécute une version spécifique de macOS et de Xcode.

| Image VM                   | Statut       |              |
|----------------------------|--------------|--------------|
| `macos-14-xcode-15`        | `deprecated` | [Logiciels préinstallés](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-14-xcode-15/) |
| `macos-15-xcode-16`        | `GA`         | [Logiciels préinstallés](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-15-xcode-16/) |
| `macos-26-xcode-26`        | `GA`         | [Logiciels préinstallés](https://gitlab-org.gitlab.io/ci-cd/shared-runners/images/macos-image-inventory/macos-26-xcode-26/) |

Si aucune image n'est spécifiée, le runner macOS utilise `macos-15-xcode-16`.

## Politique de mise à jour des images pour macOS {#image-update-policy-for-macos}

Les images et les composants installés sont mis à jour à chaque release GitLab, afin de maintenir les logiciels préinstallés à jour. GitLab prend généralement en charge plusieurs versions de logiciels préinstallés. Pour plus d'informations, consultez la [liste complète des logiciels préinstallés](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/job-images/-/tree/main/toolchain).

Les versions majeures et mineures de macOS et de Xcode sont disponibles dans le jalon suivant la release Apple.

Une nouvelle image de version majeure est d'abord disponible en version bêta, et devient généralement disponible avec la release de la première version mineure. Étant donné que seules deux images généralement disponibles sont prises en charge à la fois, l'image la plus ancienne est dépréciée et sera supprimée après trois mois conformément au [cycle de vie des images prises en charge](_index.md#supported-image-lifecycle).

Lorsqu'une nouvelle version majeure est généralement disponible, elle devient l'image par défaut pour tous les jobs macOS.

## Exemple de fichier `.gitlab-ci.yml` {#example-gitlab-ciyml-file}

L'exemple de fichier `.gitlab-ci.yml` suivant montre comment commencer à utiliser les runners hébergés sur macOS :

```yaml
.macos_saas_runners:
  tags:
    - saas-macos-medium-m1
  image: macos-14-xcode-15
  before_script:
    - echo "started by ${GITLAB_USER_NAME} / @${GITLAB_USER_LOGIN}"

build:
  extends:
    - .macos_saas_runners
  stage: build
  script:
    - echo "running scripts in the build job"

test:
  extends:
    - .macos_saas_runners
  stage: test
  script:
    - echo "running scripts in the test job"
```

## Signature de code des projets iOS avec fastlane {#code-signing-ios-projects-with-fastlane}

Avant de pouvoir intégrer GitLab aux services Apple, installer sur un appareil ou déployer sur l'Apple App Store, vous devez [signer le code](https://developer.apple.com/documentation/security/code_signing_services) de votre application.

Chaque image VM de runner sur macOS inclut [fastlane](https://fastlane.tools/), une solution open source visant à simplifier le déploiement d'applications mobiles.

Pour savoir comment configurer la signature de code pour votre application, consultez les instructions dans la [documentation Mobile DevOps](../../mobile_devops/mobile_devops_tutorial_ios.md#configure-code-signing-with-fastlane).

Sujets connexes :

- [Apple Developer Support - Code Signing](https://forums.developer.apple.com/forums/thread/707080)
- [Code Signing Best Practice Guide](https://codesigning.guide/)
- [Guide d'authentification fastlane avec les services Apple](https://docs.fastlane.tools/getting-started/ios/authentication/)

## Optimisation de Homebrew {#optimizing-homebrew}

Par défaut, Homebrew vérifie les mises à jour au début de chaque opération. Homebrew suit un cycle de release qui peut être plus fréquent que le cycle de release des images macOS de GitLab. Cette différence de cycles de release peut entraîner des délais supplémentaires pour les étapes qui appellent `brew` pendant que Homebrew effectue ses mises à jour.

Pour réduire le temps de compilation lié aux mises à jour involontaires de Homebrew, définissez la variable `HOMEBREW_NO_AUTO_UPDATE` dans `.gitlab-ci.yml` :

```yaml
variables:
  HOMEBREW_NO_AUTO_UPDATE: 1
```

## Optimisation de CocoaPods {#optimizing-cocoapods}

Si vous utilisez CocoaPods dans un projet, vous devriez envisager les optimisations suivantes pour améliorer les performances de CI.

**CocoaPods CDN**

Vous pouvez utiliser l'accès au réseau de distribution de contenu (CDN) pour télécharger des packages depuis le CDN au lieu de devoir cloner l'intégralité d'un dépôt de projet. L'accès CDN est disponible dans CocoaPods 1.8 ou version ultérieure et est pris en charge par tous les runners GitLab hébergés sur macOS.

Pour activer l'accès CDN, assurez-vous que votre Podfile commence par :

```ruby
source 'https://cdn.cocoapods.org/'
```

**Use GitLab caching**

Utilisez la mise en cache dans les packages CocoaPods dans GitLab pour n'exécuter `pod install` que lorsque les pods changent, ce qui peut améliorer les performances de compilation.

Pour [configurer la mise en cache](../../caching/_index.md) pour votre projet :

1. Ajoutez la configuration `cache` à votre fichier `.gitlab-ci.yml` :

   ```yaml
   cache:
     key:
       files:
        - Podfile.lock
   paths:
     - Pods
   ```

1. Ajoutez le plugin [`cocoapods-check`](https://guides.cocoapods.org/plugins/optimising-ci-times.html) à votre projet.
1. Mettez à jour le script du job pour vérifier les dépendances installées avant d'appeler `pod install` :

   ```shell
   bundle exec pod check || bundle exec pod install
   ```

**Include pods in source control**

Vous pouvez également [inclure le répertoire des pods dans le contrôle de code source](https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control). Cela élimine la nécessité d'installer des pods dans le cadre du job CI, mais augmente la taille globale du dépôt de votre projet.

## Problèmes connus et contraintes d'utilisation {#known-issues-and-usage-constraints}

- Si l'image VM n'inclut pas la version spécifique du logiciel dont vous avez besoin pour votre job, le logiciel requis doit être récupéré et installé. Cela entraîne une augmentation du temps d'exécution du job.
- Il n'est pas possible d'utiliser votre propre image OS.
- Le trousseau pour l'utilisateur `gitlab` n'est pas accessible publiquement. Vous devez créer un trousseau à la place.
- Les runners hébergés sur macOS s'exécutent en mode sans interface graphique (headless). Les charges de travail nécessitant des interactions avec l'interface utilisateur, telles que `testmanagerd`, ne sont pas prises en charge.
- Les performances des jobs peuvent varier entre les exécutions, car les puces Apple silicon disposent de cœurs d'efficacité et de performances. Vous ne pouvez pas contrôler l'allocation des cœurs ni la planification, ce qui peut entraîner des incohérences.
- La disponibilité des machines macOS bare metal AWS utilisées pour les runners hébergés sur macOS est limitée. Les jobs peuvent subir des temps d'attente prolongés lorsqu'aucune machine n'est disponible.
- Les instances de runners hébergés sur macOS ne répondent parfois pas aux requêtes, ce qui entraîne le blocage des jobs jusqu'à ce que la durée maximale du job soit atteinte.
- macOS utilise par défaut un système de fichiers insensible à la casse. Ce comportement peut entraîner des erreurs inattendues si vous avez des chemins de fichiers en double qui ne diffèrent que par la casse. Ces chemins en double peuvent se trouver dans l'arborescence de travail Git ou dans les refs Git où les branches et les tags sont stockés.
