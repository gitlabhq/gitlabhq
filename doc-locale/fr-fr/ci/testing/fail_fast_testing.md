---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Exécutez uniquement les specs RSpec pertinentes par rapport aux modifications de votre merge request pour obtenir plus rapidement des retours du pipeline.
title: Tests fail fast
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les tests fail fast exécutent les specs les plus pertinentes par rapport aux modifications de votre merge request avant que le reste de la suite ne s'exécute. Si ces specs échouent, le pipeline s'arrête immédiatement pour économiser du temps et des ressources de calcul.

Pour les projets Ruby on Rails utilisant RSpec, le [template CI/CD `Verify/FailFast`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Verify/FailFast.gitlab-ci.yml) sélectionne et exécute uniquement les specs pertinentes. Il utilise le [gem `test_file_finder` (`tff`)](https://gitlab.com/gitlab-org/ruby/gems/test_file_finder), qui associe les fichiers modifiés à leurs fichiers de specs correspondants.

Par défaut, le template s'exécute dans l'[étape `.pre`](../yaml/_index.md#stage-pre), avant toutes les autres étapes du pipeline.

## Configurer les tests fail fast {#configure-fail-fast-testing}

Configurez les tests fail fast pour obtenir des retours plus rapides sur les modifications de votre merge request avant que votre suite de tests complète ne s'exécute.

Prérequis :

- Un projet Ruby on Rails utilisant RSpec.
- Les [pipelines de résultats fusionnés](../pipelines/merged_results_pipelines.md#enable-merged-results-pipelines) sont activés dans les paramètres du projet. Cela nécessite également que les [pipelines de merge request](../pipelines/merge_request_pipelines.md#prerequisites) soient activés.

Pour configurer les tests fail fast :

1. Ajoutez un job RSpec pour exécuter votre suite complète sur les pipelines de merge request :

   ```yaml
   rspec-complete:
     stage: test
     rules:
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"
     script:
       - bundle install
       - bundle exec rspec
   ```

1. Incluez le template `Verify/FailFast` dans votre configuration CI/CD :

   ```yaml
   include:
     - template: Verify/FailFast.gitlab-ci.yml
   ```

1. Facultatif. Pour utiliser une image Docker différente, définissez l'image sur le job `rspec-rails-modified-path-specs` dans votre fichier de configuration CI/CD :

   ```yaml
   include:
     - template: Verify/FailFast.gitlab-ci.yml

   rspec-rails-modified-path-specs:
     image: custom-docker-image-with-ruby
   ```

## Résultats des tests fail fast {#fail-fast-test-results}

Les exemples suivants supposent une suite de 100 specs par modèle sur 10 modèles (1 000 specs au total).

| Fichiers modifiés                            | `rspec-rails-modified-path-specs` | `rspec-complete` |
| ---------------------------------------- | --------------------------------- | ---------------- |
| Aucun fichier Ruby                            | Ne s'exécute pas                      | Exécute les 1 000 specs |
| `app/models/example.rb` (toutes les specs réussissent) | Exécute 100 specs pour `example.rb`   | Exécute les 1 000 specs |
| `app/models/example.rb` (au moins une spec échoue) | Exécute 100 specs pour `example.rb`   | Ignoré          |
