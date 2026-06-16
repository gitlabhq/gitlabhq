---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Composants CI/CD
description: Composants CI/CD réutilisables et versionnés pour les pipelines.
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduit en tant que [fonctionnalité expérimentale](../../policy/development_stages_support.md#experiment) dans GitLab 16.0, [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_namespace_catalog_experimental`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/9897) dans GitLab 16.2.
- [Feature flag `ci_namespace_catalog_experimental` supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/394772) dans GitLab 16.3.
- [Déplacé](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/130824) vers [la version bêta](../../policy/development_stages_support.md#beta) dans GitLab 16.6.
- [Rendu généralement disponible](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062) dans GitLab 17.0.

{{< /history >}}

Un composant CI/CD est une unité de configuration de pipeline unique et réutilisable. Utilisez des composants pour créer une petite partie d'un pipeline plus grand, ou même pour composer une configuration de pipeline complète.

Un composant peut être configuré avec des [paramètres d'entrée](../inputs/_index.md) pour un comportement plus dynamique.

Les composants CI/CD sont similaires aux autres types de [configuration ajoutés avec le mot-clé `include`](../yaml/includes.md), mais présentent plusieurs avantages :

- Les composants peuvent être répertoriés dans le [Catalogue CI/CD](#cicd-catalog).
- Les composants peuvent être publiés en release et utilisés avec une version spécifique.
- Plusieurs composants peuvent être définis dans le même projet et versionnés ensemble.

Plutôt que de créer vos propres composants, vous pouvez également rechercher des composants publiés qui ont les fonctionnalités dont vous avez besoin dans le [Catalogue CI/CD](#cicd-catalog).

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une introduction et des exemples pratiques, voir [Efficient DevSecOps workflows with reusable CI/CD components](https://www.youtube.com/watch?v=-yvfSFKAgbA).
<!-- Video published on 2024-01-22. DRI: Developer Relations, <https://gitlab.com/groups/gitlab-com/marketing/developer-relations/-/epics/399> -->

Pour les questions fréquentes et une assistance supplémentaire, consultez la [FAQ : GitLab CI/CD Catalog](https://about.gitlab.com/blog/faq-gitlab-ci-cd-catalog/) (article de blog).

## Projet de composant {#component-project}

{{< history >}}

- Le nombre maximum de composants par projet [a été modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/436565) de 10 à 30 dans GitLab 16.9.
- Le nombre maximum de composants par projet [a été modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/569158) de 30 à 100 dans GitLab 18.5.

{{< /history >}}

Un projet de composant est un projet GitLab avec un dépôt qui héberge un ou plusieurs composants. Tous les composants du projet sont versionnés ensemble, avec un maximum de 30 composants par projet.

Si un composant nécessite un versionnage différent des autres composants, le composant doit être déplacé vers un projet de composant dédié.

### Créer un projet de composant {#create-a-component-project}

Pour créer un projet de composant, vous devez :

1. [Créer un nouveau projet](../../user/project/_index.md#create-a-blank-project) avec un fichier `README.md` :
   - Assurez-vous que la description donne une introduction claire au composant.
   - Facultatif. Une fois le projet créé, vous pouvez [ajouter un avatar de projet](../../user/project/working_with_projects.md#add-a-project-avatar).

   Les composants publiés dans le [catalogue CI/CD](#cicd-catalog) utilisent à la fois la description et l'avatar lors de l'affichage du résumé du projet de composant.

1. Ajoutez un fichier de configuration YAML pour chaque composant, en suivant la [structure de répertoire requise](#directory-structure). Par exemple :

   ```yaml
   spec:
     inputs:
       stage:
         default: test
   ---
   component-job:
     script: echo job 1
     stage: $[[ inputs.stage ]]
   ```

Vous pouvez [utiliser le composant](#use-a-component) immédiatement, mais vous souhaiterez peut-être envisager de publier le composant dans le [catalogue CI/CD](#cicd-catalog).

### Structure de répertoire {#directory-structure}

Le dépôt doit contenir :

- Un fichier Markdown `README.md` documentant les détails de tous les composants dans le dépôt.
- Un répertoire `templates/` de niveau supérieur qui contient toutes les configurations de composants. Dans ce répertoire, vous pouvez :
  - Utiliser des fichiers uniques se terminant par `.yml` pour chaque composant, comme `templates/secret-detection.yml`.
  - Créer des sous-répertoires avec un `template.yml` pour chaque composant, comme `templates/secret-detection/template.yml`. Seul le fichier `template.yml` est utilisé par d'autres projets utilisant le composant. Les autres fichiers dans ces répertoires ne sont pas publiés avec le composant, mais peuvent être utilisés pour des choses comme les tests ou la construction d'images de conteneur.

> [!note]
> Chaque composant peut également avoir son propre fichier `README.md` qui fournit des informations plus détaillées, et peut être lié depuis le fichier `README.md` de niveau supérieur. Cela permet de fournir une meilleure vue d'ensemble de votre projet de composant et de son utilisation.

Vous devriez également :

- Configurer le `.gitlab-ci.yml` du projet pour [tester les composants](#test-the-component) et [publier de nouvelles versions](#publish-a-new-release).
- Ajouter un fichier `LICENSE.md` avec une licence de votre choix qui couvre l'utilisation de votre composant. Par exemple les licences open source [MIT](https://opensource.org/license/mit) ou [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0#apply).

Par exemple :

- Si le projet contient un seul composant, la structure de répertoire doit être similaire à :

  ```plaintext
  ├── templates/
  │   └── my-component.yml
  ├── LICENSE.md
  ├── README.md
  └── .gitlab-ci.yml
  ```

- Si le projet contient plusieurs composants, la structure de répertoire doit être similaire à :

  ```plaintext
  ├── templates/
  │   ├── my-component.yml
  │   └── my-other-component/
  │       ├── template.yml
  │       ├── Dockerfile
  │       └── test.sh
  ├── LICENSE.md
  ├── README.md
  └── .gitlab-ci.yml
  ```

  Dans cet exemple :

  - La configuration du composant `my-component` est définie dans un seul fichier.
  - La configuration du composant `my-other-component` contient plusieurs fichiers dans un répertoire. Seul le fichier `template.yml` peut être utilisé par d'autres projets utilisant le composant.

## Utiliser un composant {#use-a-component}

Prérequis :

Si vous êtes membre d'un groupe parent qui contient le groupe ou le projet actuel :

- Vous devez avoir le rôle minimum défini par le niveau de visibilité du groupe parent du projet. Par exemple, vous devez avoir le rôle Reporter, Developer, Maintainer ou Owner si un projet parent est défini sur **Privé**.

Pour ajouter un composant à la configuration CI/CD d'un projet, utilisez le mot-clé [`include: component`](../yaml/_index.md#includecomponent). La référence du composant est formatée comme `<fully-qualified-domain-name>/<project-path>/<component-name>@<specific-version>`, par exemple :

```yaml
include:
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@1.0.0
    inputs:
      stage: build
```

Dans cet exemple :

- `$CI_SERVER_FQDN` est une [variable prédéfinie](../variables/predefined_variables.md) pour le nom de domaine pleinement qualifié (FQDN) correspondant à l'hôte GitLab. Vous pouvez uniquement référencer des composants dans la même instance GitLab que votre projet.
- `my-org/security-components` est le chemin complet du projet contenant le composant.
- `secret-detection` est le nom du composant qui est défini soit comme un fichier unique `templates/secret-detection.yml` soit comme un répertoire `templates/secret-detection/` contenant un `template.yml`.
- `1.0.0` est la [version](#component-versions) du composant.

La configuration du pipeline et la configuration du composant ne sont pas traitées indépendamment. Lorsqu'un pipeline démarre, toute configuration de composant incluse [fusionne](../yaml/includes.md#merge-method-for-include) dans la configuration du pipeline. Si votre pipeline et le composant contiennent tous deux une configuration avec le même nom, ils peuvent interagir de manière inattendue.

Par exemple, deux jobs avec le même nom fusionneraient en un seul job. De même, un composant utilisant `extends` pour la configuration avec le même nom qu'un job dans votre pipeline pourrait étendre la mauvaise configuration. Assurez-vous que votre pipeline et le composant ne partagent aucune configuration avec le même nom, sauf si vous avez l'intention de [remplacer](../yaml/includes.md#override-included-configuration-values) la configuration du composant.

Pour utiliser des composants GitLab.com sur une instance GitLab Self-Managed, vous devez [mettre en miroir le projet de composant](#use-a-gitlabcom-component-on-gitlab-self-managed).

> [!warning]
> Si un composant nécessite l'utilisation de jetons, de mots de passe ou d'autres données sensibles pour fonctionner, assurez-vous d'auditer le code source du composant afin de vérifier que les données ne sont utilisées que pour effectuer des actions que vous attendez et autorisez. Vous devez également utiliser des jetons et des secrets avec les permissions minimales, l'accès ou la portée requis pour effectuer l'action.

### Versions de composant {#component-versions}

Par ordre de priorité décroissante, la version du composant peut être :

- Un SHA de commit, par exemple `e3262fdd0914fa823210cdb79a8c421e2cef79d8`.
- Un tag, par exemple : `1.0.0`. Si un tag et un SHA de commit existent avec le même nom, le SHA de commit est prioritaire sur le tag. Les composants publiés dans le Catalogue CI/CD doivent être taggés avec une [version sémantique](#semantic-versioning).
- Un nom de branche, par exemple `main`. Si une branche et un tag existent avec le même nom, le tag est prioritaire sur la branche.
- `~latest` ou une version sémantique partielle, qui sélectionne la dernière version dans le modèle spécifié publié dans le Catalogue CI/CD. Utilisez `~latest` uniquement si vous souhaitez utiliser la toute dernière version en permanence, ce qui pourrait inclure des modifications avec rupture. `~latest` n'inclut pas les pré-versions, par exemple `1.0.1-rc`, qui ne sont pas considérées comme prêtes pour la production.

Vous pouvez utiliser n'importe quelle version prise en charge par le composant, mais l'utilisation d'une version publiée dans le catalogue CI/CD est recommandée. La version référencée avec un SHA de commit ou un nom de branche peut ne pas être publiée dans le catalogue CI/CD, mais pourrait être utilisée à des fins de test.

#### Versions sémantiques partielles {#partial-semantic-versions}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/450835) dans GitLab 16.11

{{< /history >}}

Vous pouvez utiliser des numéros de version sémantique partiels et le mot-clé `~latest` lors du référencement d'un composant CI/CD de catalogue pour sélectionner la dernière version publiée correspondant à votre spécification.

Ces formats ne fonctionnent qu'avec des composants CI/CD de catalogue publiés, pas avec des composants de projet ordinaires. Cela garantit que lorsque vous utilisez des formats tels que `1.2` ou `~latest`, vous ne récupérez que des composants qui ont été validés et publiés dans le catalogue, plutôt que du code potentiellement non testé provenant de n'importe quel dépôt.

Cette approche offre des avantages significatifs tant pour les utilisateurs que pour les auteurs de composants :

- Pour les utilisateurs, l'utilisation de versions partielles est un excellent moyen de recevoir automatiquement des mises à jour mineures ou de correctifs sans risquer des modifications avec rupture provenant des versions majeures. Cela garantit que vos pipelines restent à jour avec les dernières corrections de bogues et correctifs de sécurité tout en maintenant la stabilité.
- Pour les auteurs de composants, la prise en charge des versions partielles permet des publications de versions majeures sans risque de rompre immédiatement les pipelines existants. Les utilisateurs qui ont spécifié des versions partielles continuent à utiliser la dernière version mineure ou de correctif compatible, ce qui leur donne le temps de mettre à jour leurs pipelines à leur propre rythme.

Utilisez :

- `1.2` pour sélectionner la dernière version `1.2.*`
- `1` pour sélectionner la dernière version `1.*.*`
- `~latest` pour sélectionner la dernière version publiée

Par exemple, un composant a les versions : `1.0.0`, `1.1.0`, `1.1.1`, `1.2.0`, `2.0.0`, `2.0.1`, `2.1.0`

Lors du référencement du composant :

- `1` sélectionne `1.2.0`
- `1.1` sélectionne `1.1.1`
- `~latest` sélectionne `2.1.0`

Les versions pré-release ne sont jamais récupérées lors de l'utilisation de la sélection de version partielle. Pour récupérer une version pré-release, spécifiez la version complète, par exemple `1.0.1-rc`.

### Utiliser le contexte de composant dans les composants {#use-component-context-in-components}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438275) dans GitLab 18.6 en tant que [bêta](../../policy/development_stages_support.md#beta) [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_component_context_interpolation`. Activé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/571986) dans GitLab 18.7. Feature flag `ci_component_context_interpolation` supprimé.

{{< /history >}}

Les composants peuvent accéder à leurs propres métadonnées grâce à une [expression CI/CD](../yaml/expressions.md) de contexte de composant. Utilisez cette expression dans les templates de composants pour référencer la version, le SHA de commit et d'autres métadonnées de manière dynamique.

Pour utiliser le contexte de composant dans un composant, vous devez :

1. Déclarez les champs de contexte de composant dont le composant a besoin dans l'en-tête [`spec:component`](../yaml/_index.md#speccomponent). `spec:component` prend en charge les champs `name`, `sha`, `version` et `reference`.
1. Référencez les champs de contexte en utilisant l'expression CI/CD `$[[ component.field-name ]]` dans le template de composant.

Par exemple, un composant qui référence une image Docker construite avec la même version :

```yaml
spec:
  component: [name, version, reference]
  inputs:
    stage:
      default: build
---

build-image:
  stage: $[[ inputs.stage ]]
  image: registry.example.com/$[[ component.name ]]:$[[ component.version ]]
  script:
    - echo "Building with component version $[[ component.version ]]"
    - echo "Component reference: $[[ component.reference ]]"
```

Vous pouvez également utiliser le contexte de composant pour [référencer des ressources versionnées](examples.md#use-component-context-to-reference-versioned-resources).

### Section `spec` du composant {#component-spec-section}

La section `spec` dans un template de composant définit la configuration et les entrées du composant. Vous pouvez utiliser les mots-clés suivants dans la section `spec` :

- [`description`](../yaml/_index.md#specdescription) :  Fournissez une courte description du composant qui est affichée dans le Catalogue CI/CD.
- [`inputs`](../yaml/_index.md#specinputs) :  Définissez des paramètres d'entrée pour que les utilisateurs puissent personnaliser la configuration du composant.
- [`component`](../yaml/_index.md#speccomponent) :  Déclarez les champs de contexte de composant à rendre disponibles pour l'interpolation (comme `name`, `sha`, `version` et `reference`).

> [!note]
> Vous ne pouvez pas utiliser [`spec:include`](../yaml/_index.md#specinclude) dans les composants. Les composants doivent être autonomes et ne pas dépendre de fichiers externes. Définissez les entrées directement dans le composant au lieu de les inclure depuis des fichiers séparés.

## Écrire un composant {#write-a-component}

Cette section décrit quelques bonnes pratiques pour créer des projets de composants de haute qualité.

### Gérer les dépendances {#manage-dependencies}

Bien qu'il soit possible pour un composant d'utiliser d'autres composants à son tour, assurez-vous de sélectionner soigneusement les dépendances. Pour gérer les dépendances, vous devez :

- Réduire les dépendances au minimum. Une petite quantité de duplication est généralement préférable à l'utilisation de dépendances.
- Utiliser des dépendances locales chaque fois que possible. Par exemple, utiliser [`include:local`](../yaml/_index.md#includelocal) est un bon moyen de s'assurer que le même SHA Git est utilisé dans plusieurs fichiers.
- Lorsque vous dépendez de composants d'autres projets, épinglez leur version à une release du catalogue plutôt que d'utiliser des versions cibles mobiles telles que `~latest` ou une référence Git. L'utilisation d'une release ou d'un SHA Git garantit que vous récupérez toujours la même révision et que les utilisateurs de votre composant obtiennent un comportement cohérent.
- Mettez régulièrement à jour vos dépendances en les épinglant à des versions plus récentes. Publiez ensuite une nouvelle release de vos composants avec les dépendances mises à jour.
- Évaluez les permissions des dépendances et utilisez des dépendances qui nécessitent le moins de permissions possible. Par exemple, si vous avez besoin de construire une image, envisagez d'utiliser [Buildah](https://buildah.io/) plutôt que Docker, afin de ne pas nécessiter un runner avec un démon Docker privilégié.

### Rédiger un `README.md` clair {#write-a-clear-readmemd}

Chaque projet de composant doit avoir une documentation claire et complète. Pour rédiger un bon fichier `README.md` :

- Commencez par un résumé des capacités que les composants fournissent.
- Si le projet contient plusieurs composants, utilisez une [table des matières](../../user/markdown.md#table-of-contents) pour aider les utilisateurs à accéder rapidement aux détails d'un composant spécifique.
- Ajoutez une section `## Components` avec des sous-sections comme `### Component A` pour chaque composant.
- Dans chaque section de composant :
  - Décrivez ce que fait le composant.
  - Ajoutez au moins un exemple YAML montrant comment l'utiliser.
  - Utilisez [`spec:inputs:description`](../yaml/_index.md#specinputsdescription) pour documenter toutes les variables ou tous les secrets utilisés par le composant.
  - Ne dupliquez pas la documentation des entrées dans le `README`. Les entrées apparaissent automatiquement sur la page du composant. À la place, créez un lien vers le composant publié.
- Ajoutez une section `## Contribute` si les contributions sont les bienvenues.

Si un composant nécessite plus d'instructions, ajoutez de la documentation supplémentaire dans un fichier Markdown dans le répertoire du composant et créez un lien vers celui-ci depuis le fichier principal `README.md`. Par exemple :

```plaintext
README.md    # with links to the specific docs.md
templates/
├── component-1/
│   ├── template.yml
│   └── docs.md
└── component-2/
    ├── template.yml
    └── docs.md
```

Pour un exemple, consultez le [README des composants AWS](https://gitlab.com/components/aws/-/blob/main/README.md).

### Tester le composant {#test-the-component}

Il est fortement recommandé de tester les composants CI/CD dans le cadre du workflow de développement, ce qui permet de garantir un comportement cohérent.

Testez les modifications dans un pipeline CI/CD (comme tout autre projet) en créant un `.gitlab-ci.yml` dans le répertoire racine. Assurez-vous de tester à la fois le comportement et les effets secondaires potentiels du composant. Vous pouvez utiliser l'[API GitLab](../../api/rest/_index.md) si nécessaire.

Par exemple :

```yaml
include:
  # include the component located in the current project from the current SHA
  - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/my-component@$CI_COMMIT_SHA
    inputs:
      stage: build

stages: [build, test, release]

# Check if `component job of my-component` is added.
# This example job could also test that the included component works as expected.
# You can inspect data generated by the component, use GitLab API endpoints, or third-party tools.
ensure-job-added:
  stage: test
  image: badouralix/curl-jq
  # Replace "component job of my-component" with the job name in your component.
  script:
    - |
      route="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/jobs"
      count=`curl --silent --header "JOB-TOKEN: ${CI_JOB_TOKEN}" "$route" | jq 'map(select(.name | contains("component job of my-component"))) | length'`
      if [ "$count" != "1" ]; then
        exit 1; else
        echo "Component Job present"
      fi

# If the pipeline is for a new tag with a semantic version, and all previous jobs succeed,
# create the release.
create-release:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  script: echo "Creating release $CI_COMMIT_TAG"
  rules:
    - if: $CI_COMMIT_TAG
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG of components repository $CI_PROJECT_PATH"
```

Après avoir commité et poussé les modifications, le pipeline teste le composant, puis crée une release si les jobs précédents réussissent.

> [!note]
> Une authentification est nécessaire si le projet est privé.

#### Tester un composant avec des exemples de fichiers {#test-a-component-against-sample-files}

Dans certains cas, les composants nécessitent des fichiers sources avec lesquels interagir. Par exemple, un composant qui construit du code source Go a probablement besoin de quelques exemples de Go à tester. De même, un composant qui construit des images Docker a probablement besoin de quelques exemples de Dockerfiles à tester.

Vous pouvez inclure ces exemples de fichiers directement dans le projet de composant, afin qu'ils soient utilisés pendant les tests du composant.

Vous pouvez en savoir plus dans [les exemples de test d'un composant](examples.md#test-a-component).

### Éviter le codage en dur de valeurs spécifiques à l'instance ou au projet {#avoid-hard-coding-instance-or-project-specific-values}

Lors de l'[utilisation d'un autre composant](#use-a-component) dans votre composant, utilisez `$CI_SERVER_FQDN` à la place du nom de domaine pleinement qualifié de votre instance (comme `gitlab.com`).

Lors de l'accès à l'API GitLab dans votre composant, utilisez `$CI_API_V4_URL` plutôt que l'URL et le chemin complets de votre instance (comme `https://gitlab.com/api/v4`).

Ces [variables prédéfinies](../variables/predefined_variables.md) garantissent que votre composant fonctionne également lorsqu'il est utilisé sur une autre instance, par exemple lors de l'utilisation de [composants GitLab.com sur une instance GitLab Self-Managed](#use-a-gitlabcom-component-on-gitlab-self-managed).

### Ne supposez pas que les ressources API sont toujours publiques {#do-not-assume-api-resources-are-always-public}

Assurez-vous que le composant et son pipeline de test fonctionnent également [sur GitLab Self-Managed](#use-a-gitlabcom-component-on-gitlab-self-managed). Alors que certaines ressources API de projets publics sur GitLab.com peuvent être accessibles avec des requêtes non authentifiées, sur une instance GitLab Self-Managed, un projet de composant peut être mis en miroir en tant que projet privé ou interne.

Il est important qu'un jeton d'accès puisse éventuellement être fourni via des entrées ou des variables pour authentifier les requêtes sur les instances GitLab Self-Managed.

### Éviter l'utilisation de mots-clés globaux {#avoid-using-global-keywords}

Évitez d'utiliser des [mots-clés globaux](../yaml/_index.md#global-keywords) dans un composant. L'utilisation de ces mots-clés dans un composant affecte tous les jobs d'un pipeline, y compris les jobs directement définis dans le fichier principal `.gitlab-ci.yml` ou dans d'autres composants inclus.

En remplacement des mots-clés globaux :

- Ajoutez la configuration directement à chaque job, même si cela crée une certaine duplication dans la configuration du composant.
- Utilisez le mot-clé [`extends`](../yaml/_index.md#extends) dans le composant, mais utilisez des noms uniques qui réduisent le risque de conflits de noms lorsque le composant est fusionné dans la configuration.

Par exemple, évitez d'utiliser le mot-clé global `default` :

```yaml
# Not recommended
default:
  image: ruby:3.0

rspec-1:
  script: bundle exec rspec dir1/

rspec-2:
  script: bundle exec rspec dir2/
```

À la place, vous pouvez :

- Ajouter la configuration à chaque job explicitement :

  ```yaml
  rspec-1:
    image: ruby:3.0
    script: bundle exec rspec dir1/

  rspec-2:
    image: ruby:3.0
    script: bundle exec rspec dir2/
  ```

- Utiliser `extends` pour réutiliser la configuration :

  ```yaml
  .rspec-image:
    image: ruby:3.0

  rspec-1:
    extends:
      - .rspec-image
    script: bundle exec rspec dir1/

  rspec-2:
    extends:
      - .rspec-image
    script: bundle exec rspec dir2/
  ```

### Remplacer les valeurs codées en dur par des entrées {#replace-hardcoded-values-with-inputs}

Évitez d'utiliser des valeurs codées en dur dans les composants CI/CD. Les valeurs codées en dur peuvent obliger les utilisateurs du composant à examiner les détails internes du composant et à adapter leur pipeline pour travailler avec le composant.

Un mot-clé commun avec des valeurs codées en dur problématiques est `stage`. Si l'étape d'un job de composant est codée en dur, tous les pipelines utilisant le composant **must** soit définir exactement la même étape, soit [remplacer](../yaml/includes.md#override-included-configuration-values) la configuration.

La méthode préférée est d'utiliser le [mot-clé `input`](../inputs/_index.md) pour la configuration dynamique des composants. L'utilisateur du composant peut spécifier la valeur exacte dont il a besoin.

Par exemple, pour créer un composant avec une configuration `stage` pouvant être définie par les utilisateurs :

- Dans la configuration du composant :

  ```yaml
  spec:
    inputs:
      stage:
        default: test
  ---
  unit-test:
    stage: $[[ inputs.stage ]]
    script: echo unit tests

  integration-test:
    stage: $[[ inputs.stage ]]
    script: echo integration tests
  ```

- Dans un projet utilisant le composant :

  ```yaml
  stages: [verify, release]

  include:
    - component: $CI_SERVER_FQDN/myorg/ruby/test@1.0.0
      inputs:
        stage: verify
  ```

#### Définir les noms de jobs avec des entrées {#define-job-names-with-inputs}

Comme pour les valeurs du mot-clé `stage`, vous devriez éviter de coder en dur les noms de jobs dans les composants CI/CD. Lorsque les utilisateurs de votre composant peuvent personnaliser les noms de jobs, ils peuvent éviter les conflits avec les noms existants dans leurs pipelines. Les utilisateurs pourraient également inclure un composant plusieurs fois avec différentes options d'entrée en utilisant des noms différents.

Utilisez `inputs` pour permettre aux utilisateurs de votre composant de définir un nom de job spécifique, ou un préfixe pour le nom du job. Par exemple :

```yaml
spec:
  inputs:
    job-prefix:
      description: "Define a prefix for the job name"
    job-name:
      description: "Alternatively, define the job's name"
    job-stage:
      default: test
---

"$[[ inputs.job-prefix ]]-scan-website":
  stage: $[[ inputs.job-stage ]]
  script:
    - scan-website-1

"$[[ inputs.job-name ]]":
  stage: $[[ inputs.job-stage ]]
  script:
    - scan-website-2
```

### Remplacer les variables CI/CD personnalisées par des entrées {#replace-custom-cicd-variables-with-inputs}

Lors de l'utilisation de variables CI/CD dans un composant, évaluez si le mot-clé `inputs` doit être utilisé à la place. Évitez de demander aux utilisateurs de définir des variables personnalisées pour configurer des composants lorsque `inputs` est une meilleure solution.

Les entrées sont explicitement définies dans la section `spec` du composant et ont une meilleure validation que les variables. Par exemple, si une entrée requise n'est pas transmise au composant, GitLab renvoie une erreur de pipeline. En revanche, si une variable n'est pas définie, sa valeur est vide et il n'y a pas d'erreur.

Par exemple, utilisez `inputs` à la place de variables pour configurer le format de sortie d'un scanner :

- Dans la configuration du composant :

  ```yaml
  spec:
    inputs:
      scanner-output:
        default: json
  ---
  my-scanner:
    script: my-scan --output $[[ inputs.scanner-output ]]
  ```

- Dans le projet utilisant le composant :

  ```yaml
  include:
    - component: $CI_SERVER_FQDN/path/to/project/my-scanner@1.0.0
      inputs:
        scanner-output: yaml
  ```

Dans d'autres cas, les variables CI/CD peuvent toujours être préférées. Par exemple :

- Utilisez des [variables prédéfinies](../variables/predefined_variables.md) pour configurer automatiquement un composant en fonction du projet d'un utilisateur.
- Demandez aux utilisateurs de stocker les valeurs sensibles en tant que [variables CI/CD masquées ou protégées dans les paramètres du projet](../variables/_index.md#define-a-cicd-variable-in-the-ui).

## Catalogue CI/CD {#cicd-catalog}

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/407249) en tant qu'[expérience](../../policy/development_stages_support.md#experiment) dans GitLab 16.1.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/432045) vers [la version bêta](../../policy/development_stages_support.md#beta) dans GitLab 16.7.
- [Rendu généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/454306) dans GitLab 17.0.

{{< /history >}}

Le [Catalogue CI/CD](https://gitlab.com/explore/catalog) est une liste de projets avec des composants CI/CD publiés que vous pouvez utiliser pour étendre votre workflow CI/CD.

N'importe qui peut [créer un projet de composant](#create-a-component-project) et l'ajouter au Catalogue CI/CD, ou contribuer à un projet existant pour améliorer les composants disponibles.

Pour une démonstration interactive, voir [la visite guidée du produit CI/CD Catalog en version bêta](https://gitlab.navattic.com/cicd-catalog).
<!-- Demo published on 2024-01-24 -->

### Afficher le Catalogue CI/CD {#view-the-cicd-catalog}

Pour accéder au Catalogue CI/CD et afficher les composants publiés disponibles :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à**.
1. Sélectionnez **Explorer**.
1. Sélectionnez **Catalogue CI/CD**.

Autrement, si vous êtes déjà dans l'[éditeur de pipeline](../pipeline_editor/_index.md) de votre projet, vous pouvez sélectionner **Catalogue CI/CD**.

La visibilité des composants dans le catalogue CI/CD suit le [paramètre de visibilité](../../user/public_access.md) du projet source du composant. Les composants dont les projets sources sont définis sur :

- Privé ne sont visibles que par les utilisateurs ayant le rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet de composant source. Pour utiliser un composant, vous devez avoir le rôle Reporter, Developer, Maintainer ou Owner.
- Interne ne sont visibles que par les utilisateurs connectés à l'instance GitLab.
- Public sont visibles par toute personne ayant accès à l'instance GitLab.

### Afficher les données d'analyse des ressources du catalogue {#view-catalog-resource-analytics}

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/14027) dans GitLab 18.9.

{{< /history >}}

Si vous gérez des ressources du catalogue CI/CD, vous pouvez afficher des données d'analyse d'utilisation pour comprendre comment vos composants sont adoptés dans les projets.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour un ou plusieurs projets de ressources du catalogue.

Pour afficher les données d'analyse des ressources du catalogue :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** > **Explorer**.
1. Sélectionnez **Catalogue CI/CD**.
1. Sélectionnez l'onglet **Données d'analyse**.

La vue Données d'analyse affiche les ressources du catalogue pour lesquelles vous avez le rôle Maintainer ou Owner. Cette vue affiche :

- **Projets** :  Le nom de la ressource du catalogue et sa dernière version publiée.
- **Statistiques d'utilisation** :  Le nombre de projets uniques ayant utilisé un composant de cette ressource du catalogue dans un pipeline au cours des 30 derniers jours.
- **Composants** :  Une liste des composants disponibles dans la dernière version de la ressource du catalogue.

Par exemple :

![Page d'analyse des ressources du catalogue affichant 3 composants et leurs chiffres d'utilisation.](img/catalog_analytics_v18_10.png)

Vous pouvez utiliser ces informations pour :

- Identifier les ressources du catalogue les plus largement adoptées.
- Suivre les tendances d'utilisation de vos composants au fil du temps.
- Comprendre quels projets utilisent vos ressources du catalogue.
- Prendre des décisions éclairées concernant la maintenance et la dépréciation des composants.

### Afficher les détails d'utilisation des composants {#view-component-usage-details}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/579460) dans GitLab 19.0.

{{< /history >}}

Si vous gérez des projets de composants CI/CD du catalogue, vous pouvez afficher des informations détaillées sur l'utilisation des composants afin de comprendre quels projets les utilisent et quelles versions ils emploient. Cela vous aide à planifier les mises à niveau, communiquer les dépréciations et identifier les projets qui utilisent des versions obsolètes.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet de ressource du catalogue.

Pour afficher les détails d'utilisation des composants :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** > **Explorer**.
1. Sélectionnez **Catalogue CI/CD**.
1. Sélectionnez un projet de composant dans le catalogue.
1. Sur la page de détails, sélectionnez l'onglet **Utilisation**.

Cet onglet liste les projets qui ont inclus l'un des composants de ce projet dans un pipeline au cours des 30 derniers jours. La liste inclut uniquement les projets que vous avez la permission de consulter.

Les détails incluent :

- **Chemin d'accès au projet** :  Le chemin complet du projet, avec un lien vers le projet.
- **Statut** :  Si le projet a utilisé la dernière version du composant, il est étiqueté comme **À jour**. Sinon, il est **Obsolète**.
- **Composants utilisés** :  Les noms et versions des composants utilisés par le projet.

Les projets non visibles pour vous sont affichés comme **Private project** sans lien.

Vous pouvez utiliser ces informations pour :

- Identifier les projets qui utilisent des versions de composants obsolètes et qui doivent être mis à niveau.
- Notifier les responsables de projet lorsqu'une nouvelle version est disponible ou lors de la dépréciation d'un composant.
- Comprendre l'adoption de versions spécifiques de composants au sein de votre organisation.

### Publier un projet de composant {#publish-a-component-project}

Pour publier un projet de composant dans le catalogue CI/CD, vous devez :

1. Définir le projet en tant que projet de catalogue.
1. Publier une nouvelle release.

#### Définir un projet de composant en tant que projet de catalogue {#set-a-component-project-as-a-catalog-project}

Pour rendre les versions publiées d'un projet de composant visibles dans le catalogue CI/CD, vous devez définir le projet en tant que projet de catalogue.

Prérequis :

- Vous devez avoir le rôle Owner pour le projet.

Pour définir le projet en tant que projet de catalogue :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Activez le bouton bascule **Projet du catalogue CI/CD**.

Le projet ne devient trouvable dans le catalogue qu'après la publication d'une nouvelle release.

Pour utiliser l'automatisation afin d'activer ce paramètre, vous pouvez utiliser le point de terminaison GraphQL [`mutationcatalogresourcescreate`](../../api/graphql/reference/_index.md#mutationcatalogresourcescreate). [Le ticket 463043](https://gitlab.com/gitlab-org/gitlab/-/issues/463043) propose d'exposer cela également dans l'API REST.

#### Publier une nouvelle release {#publish-a-new-release}

Les composants CI/CD peuvent être [utilisés](#use-a-component) sans être répertoriés dans le catalogue CI/CD. Cependant, la publication des releases d'un composant dans le catalogue le rend découvrable par d'autres utilisateurs.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.
- Le projet doit :
  - Être défini comme un [projet de catalogue](#set-a-component-project-as-a-catalog-project).
  - Avoir une [description de projet](../../user/project/working_with_projects.md#edit-a-project) définie.
  - Avoir un fichier `README.md` dans le répertoire racine pour le SHA de commit du tag en cours de publication.
  - Avoir au moins un [composant CI/CD dans le répertoire `templates/`](#directory-structure) pour le SHA de commit du tag en cours de publication.
- Vous devez utiliser le [mot-clé `release`](../yaml/_index.md#release) dans un job CI/CD pour créer la release, et non l'[API Releases](../../api/releases/_index.md#create-a-release).

Pour publier une nouvelle version du composant dans le catalogue :

1. Ajoutez un job au fichier `.gitlab-ci.yml` du projet qui utilise le mot-clé `release` pour créer la nouvelle release lorsqu'un tag est créé. Vous devriez configurer le pipeline de tag pour [tester les composants](#test-the-component) avant d'exécuter le job de release. Par exemple :

   ```yaml
   create-release:
     stage: release
     image: registry.gitlab.com/gitlab-org/cli:latest
     script: echo "Creating release $CI_COMMIT_TAG"
     rules:
       - if: $CI_COMMIT_TAG
     release:
       tag_name: $CI_COMMIT_TAG
       description: "Release $CI_COMMIT_TAG of components in $CI_PROJECT_PATH"
   ```

1. Créez un [nouveau tag](../../user/project/repository/tags/_index.md#create-a-tag) pour la release, ce qui devrait déclencher un pipeline de tag contenant le job responsable de la création de la release. Le tag doit utiliser la [gestion sémantique de version](#semantic-versioning).

Une fois le job de release terminé avec succès, la release est créée et la nouvelle version est publiée dans le catalogue CI/CD.

#### Gestion sémantique de version {#semantic-versioning}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/427286) dans GitLab 16.10.

{{< /history >}}

Lors du tagging et de la [publication de nouvelles versions](#publish-a-new-release) de composants dans le Catalogue, vous devez utiliser la [gestion sémantique de version](https://semver.org). La gestion sémantique de version est le standard pour indiquer qu'un changement est majeur, mineur, correctif ou d'un autre type.

Par exemple, `1.0.0`, `2.3.4` et `1.0.0-alpha` sont toutes des versions sémantiques valides.

### Dépublier un projet de composant {#unpublish-a-component-project}

Pour supprimer un projet de composant du catalogue, désactivez le bouton bascule [**CI/CD Catalog resource**](#set-a-component-project-as-a-catalog-project) dans les paramètres du projet.

> [!warning]
> Cette action détruit les métadonnées sur le projet de composant et ses versions publiées dans le catalogue. Le projet et son dépôt existent toujours, mais ne sont pas visibles dans le catalogue.

Pour publier à nouveau le projet de composant dans le catalogue, vous devez [publier une nouvelle release](#publish-a-new-release).

### Créateurs de composants vérifiés {#verified-component-creators}

{{< history >}}

- [Introduit pour GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/433443) dans GitLab 16.11
- [Introduit pour GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/460125) dans GitLab 18.1

{{< /history >}}

Certains composants CI/CD sont marqués d'une icône pour indiquer que le composant a été créé et est maintenu par des utilisateurs vérifiés par GitLab ou l'administrateur de l'instance :

- GitLab-maintained ({{< icon name="tanuki-verified" >}}) :  Composants GitLab.com créés et maintenus par GitLab.
- GitLab Partner ({{< icon name="partner-verified" >}}) :  Composants GitLab.com créés et maintenus de manière indépendante par un partenaire vérifié par GitLab.

  Les partenaires GitLab peuvent contacter un membre de la GitLab Partner Alliance pour faire marquer leur espace de nommage sur GitLab.com comme vérifié par GitLab. Tous les composants CI/CD situés dans l'espace de nommage sont alors marqués comme composants GitLab Partner. Le membre de la Partner Alliance crée un [ticket de demande interne (membres de l'équipe GitLab uniquement)](https://gitlab.com/gitlab-com/support/internal-requests/-/issues/new?description_template=CI%20Catalog%20Badge%20Request) au nom du partenaire vérifié.

  > [!warning]
  > Les composants créés par des partenaires GitLab sont fournis **as-is**, sans garantie d'aucune sorte. L'utilisation par un utilisateur final d'un composant créé par un partenaire GitLab est à ses propres risques et GitLab n'aura aucune obligation d'indemnisation ni aucune responsabilité de quelque nature que ce soit en ce qui concerne l'utilisation du composant par l'utilisateur final. L'utilisation par l'utilisateur final d'un tel contenu et toute responsabilité y afférente incombent à l'éditeur du contenu et à l'utilisateur final.

- Créateur vérifié ({{< icon name="check-sm" >}}) :  Composants créés et maintenus par un utilisateur vérifié par un administrateur.

#### Définir un composant comme maintenu par un créateur vérifié {#set-a-component-as-maintained-by-a-verified-creator}

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit pour GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/460125) dans GitLab 18.1

{{< /history >}}

Un administrateur GitLab peut définir un composant CI/CD comme créé et maintenu par un créateur vérifié :

1. Ouvrez GraphiQL dans l'instance avec votre compte administrateur, par exemple à : `https://gitlab.example.com/-/graphql-explorer`.
1. Exécutez cette requête, en remplaçant `root-level-group` par l'espace de nommage racine du composant à vérifier :

   ```graphql
   mutation {
     verifiedNamespaceCreate(input: { namespacePath: "root-level-group",
       verificationLevel: VERIFIED_CREATOR_SELF_MANAGED
       }) {
       errors
     }
   }
   ```

Une fois la requête terminée, tous les composants dans les projets de l'espace de nommage racine sont vérifiés. Le badge **Créateur vérifié** s'affiche à côté des noms des composants dans le catalogue CI/CD.

Pour supprimer le badge d'un composant, répétez la requête avec `UNVERIFIED` pour `verificationLevel`.

## Convertir un template CI/CD en composant {#convert-a-cicd-template-to-a-component}

Tout template CI/CD existant que vous utilisez dans des projets avec la syntaxe `include:` peut être converti en composant CI/CD :

1. Décidez si vous souhaitez regrouper le composant avec d'autres composants dans le cadre d'un [projet de composant](#component-project) existant, ou [créer un nouveau projet de composant](#create-a-component-project).
1. Créez un fichier YAML dans le projet de composant selon la [structure de répertoire](#directory-structure).
1. Copiez le contenu du fichier YAML du template d'origine dans le nouveau fichier YAML du composant.
1. Refactorisez la configuration du nouveau composant pour :
   - Suivre les recommandations sur la [rédaction d'un composant](#write-a-component).
   - Améliorer la configuration, par exemple en activant les [pipelines de merge request](../pipelines/merge_request_pipelines.md) ou en la rendant [plus efficace](../pipelines/pipeline_efficiency.md).
1. Utilisez le `.gitlab-ci.yml` dans le dépôt de composants pour [tester les modifications du composant](#test-the-component).
1. Taggez et [publiez le composant en release](#publish-a-new-release).

Vous pouvez en savoir plus en suivant un exemple pratique de [migration du template CI/CD Go vers un composant CI/CD](examples.md#cicd-component-migration-example-go).

## Utiliser un composant GitLab.com sur GitLab Self-Managed {#use-a-gitlabcom-component-on-gitlab-self-managed}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le catalogue CI/CD d'une nouvelle installation d'une instance GitLab ne contient aucun composant CI/CD publié. Pour remplir le catalogue de votre instance, vous pouvez :

- [Publier vos propres composants](#publish-a-component-project).
- Mettre en miroir des composants GitLab.com dans votre instance GitLab Self-Managed.

Pour mettre en miroir un composant GitLab.com dans votre instance GitLab Self-Managed :

1. Assurez-vous que les [requêtes réseau sortantes](../../security/webhooks.md) sont autorisées pour `gitlab.com`.
1. [Créez un groupe](../../user/group/_index.md#create-a-group) pour héberger les projets de composants (groupe recommandé : `components`).
1. [Créez un miroir du projet de composant](../../user/project/repository/mirror/pull.md) dans le nouveau groupe.
1. Rédigez une [description de projet](../../user/project/working_with_projects.md#edit-a-project) pour le miroir du projet de composant, car la mise en miroir des dépôts ne copie pas la description.
1. [Définissez le projet de composant auto-hébergé en tant que ressource de catalogue](#set-a-component-project-as-a-catalog-project).
1. Publiez [une nouvelle release](../../user/project/releases/_index.md) dans le projet de composant auto-hébergé en [exécutant un pipeline](../pipelines/_index.md#run-a-pipeline-manually) pour un tag (généralement le dernier tag).

## Bonnes pratiques de sécurité pour les composants CI/CD {#cicd-component-security-best-practices}

### Pour les utilisateurs de composants {#for-component-users}

Comme n'importe qui peut publier des composants dans le catalogue, vous devez examiner soigneusement les composants avant de les utiliser dans votre projet. L'utilisation des composants CI/CD GitLab se fait à vos propres risques et GitLab ne peut pas garantir la sécurité des composants tiers.

Lors de l'utilisation de composants CI/CD tiers, tenez compte des bonnes pratiques de sécurité suivantes :

- **Audit and review component source code** :  Examinez soigneusement le code pour vous assurer qu'il est exempt de contenu malveillant.
- **Minimize access to credentials and tokens** :
  - Auditez le code source du composant pour vérifier que les identifiants ou les jetons ne sont utilisés que pour effectuer des actions que vous attendez et autorisez.
  - Utilisez des jetons d'accès à portée minimale.
  - Évitez d'utiliser des jetons d'accès ou des identifiants à longue durée de vie.
  - Auditez l'utilisation des identifiants et des jetons utilisés par les composants CI/CD.
- **Use pinned versions** :  Épinglez les composants CI/CD à un SHA de commit spécifique (recommandé) ou à un tag de version de release pour garantir l'intégrité du composant utilisé dans un pipeline. N'utilisez des tags de release que si vous faites confiance au responsable du composant. Évitez d'utiliser `latest`.
- **Store secrets securely** :  Ne stockez pas les secrets dans les fichiers de configuration CI/CD. Évitez de stocker des secrets et des identifiants dans les paramètres du projet si vous pouvez utiliser une solution externe de gestion des secrets à la place.
- **Use ephemeral, isolated runner environments** :  Exécutez les jobs de composants dans des environnements temporaires et isolés lorsque c'est possible. Soyez conscient des [risques de sécurité](https://docs.gitlab.com/runner/security) liés aux runners auto-gérés.
- **Securely handle cache and artifacts** :  Ne transmettez pas le cache ou les artefacts d'autres jobs de votre pipeline aux jobs de composants CI/CD, sauf si absolument nécessaire.
- **Limit CI_JOB_TOKEN access** :  Restreignez [l'accès au projet et les permissions du jeton de job CI/CD (`CI_JOB_TOKEN`)](../jobs/ci_job_token.md#control-job-token-access-to-your-project) pour les projets utilisant des composants CI/CD.
- **Review CI/CD component changes** :  Examinez soigneusement toutes les modifications apportées à la configuration du composant CI/CD avant de passer à l'utilisation d'un SHA de commit mis à jour ou d'un tag de release pour le composant.
- **Audit custom container images** :  Examinez soigneusement toutes les images de conteneur personnalisées utilisées par le composant CI/CD pour vous assurer qu'elles sont exemptes de contenu malveillant.

### Pour les responsables de composants {#for-component-maintainers}

Pour maintenir des composants CI/CD sécurisés et fiables et garantir l'intégrité de la configuration du pipeline que vous fournissez aux utilisateurs, suivez ces bonnes pratiques :

- **Use two-factor authentication (2FA)** :  Assurez-vous que tous les responsables et propriétaires de projets de composants CI/CD ont la [2FA activée](../../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication) , ou imposez la [2FA pour tous les utilisateurs du groupe](../../security/two_factor_authentication.md#enforce-2fa-for-all-users-in-a-group).
- **Use protected branches** :
  - Utilisez des [branches protégées](../../user/project/repository/branches/protected.md) pour les publications de releases des projets de composants.
  - Protégez la branche par défaut et toutes les branches de release [en utilisant des règles de caractères génériques](../../user/project/repository/branches/protected.md#use-wildcard-rules).
  - Exigez que tout le monde soumette des merge requests pour les modifications apportées aux branches protégées. Définissez l'option **Autorisés à pousser et fusionner** sur `No one` pour les branches protégées.
  - Bloquez les push forcés vers les branches protégées.
- **Sign all commits** :  [Signez tous les commits](../../user/project/repository/signed_commits/_index.md) vers le projet de composant.
- **Déconseiller l'utilisation de `latest`** :  Évitez d'inclure des exemples dans votre `README.md` qui utilisent `@latest`.
- **Limit dependency on caches and artifacts from other jobs** :  N'utilisez le cache et les artefacts d'autres jobs dans les composants CI/CD que si c'est absolument nécessaire
- **Update CI/CD component dependencies** :  Vérifiez et appliquez régulièrement les mises à jour des dépendances.
- **Review changes carefully** :
  - Examinez soigneusement toutes les modifications apportées à la configuration du pipeline du composant CI/CD avant de les fusionner dans les branches par défaut ou de release.
  - Utilisez des [approbations de merge request](../../user/project/merge_requests/approvals/_index.md) pour toutes les modifications visibles par les utilisateurs dans les projets du catalogue de composants CI/CD.

## Dépannage {#troubleshooting}

### Message `content not found` {#content-not-found-message}

Vous pourriez recevoir un message d'erreur similaire à celui ci-dessous lors de l'utilisation de `~latest` ou d'un qualificateur de version sémantique partielle pour référencer un composant hébergé par un [projet de catalogue](#set-a-component-project-as-a-catalog-project) :

```plaintext
This GitLab CI configuration is invalid: Component 'gitlab.com/my-namespace/my-project/my-component@~latest' - content not found
```

Le comportement de `~latest` [a été mis à jour](https://gitlab.com/gitlab-org/gitlab/-/issues/442238) dans GitLab 16.10. Il fait désormais référence à la dernière version sémantique de la ressource du catalogue. Pour résoudre ce problème, [créez une nouvelle release](#publish-a-new-release).

### Erreur : `Build component error: Spec must be a valid json schema` {#error-build-component-error-spec-must-be-a-valid-json-schema}

Si un composant a un formatage invalide, vous pourriez ne pas être en mesure de créer une release et pourriez recevoir une erreur comme `Build component error: Spec must be a valid json schema`.

Cette erreur peut être causée par une section `spec:inputs` vide. Si votre configuration n'utilise pas d'entrées, vous pouvez laisser la section `spec` vide à la place. Par exemple :

```yaml
spec:
---

my-component:
  script: echo
```
