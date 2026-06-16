---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des modèles CI/CD
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer les [modèles CI/CD](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates) intégrés. Les modèles personnalisés ne sont pas disponibles.

Les utilisateurs avec le rôle Invité ne peuvent pas accéder aux modèles CI/CD. Pour plus d'informations, consultez [la visibilité des projets et des groupes](../../user/public_access.md).

## Lister tous les modèles CI/CD {#list-all-cicd-templates}

Liste tous les modèles YAML CI/CD de GitLab.

```plaintext
GET /templates/gitlab_ci_ymls
```

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/templates/gitlab_ci_ymls"
```

Exemple de réponse :

```json
[
  {
    "key": "5-Minute-Production-App",
    "name": "5-Minute-Production-App"
  },
  {
    "key": "Android",
    "name": "Android"
  },
  {
    "key": "Android-Fastlane",
    "name": "Android-Fastlane"
  },
  {
    "key": "Auto-DevOps",
    "name": "Auto-DevOps"
  },
  {
    "key": "Bash",
    "name": "Bash"
  },
  {
    "key": "C++",
    "name": "C++"
  },
  {
    "key": "Chef",
    "name": "Chef"
  },
  {
    "key": "Clojure",
    "name": "Clojure"
  },
  {
    "key": "Code-Quality",
    "name": "Code-Quality"
  },
  {
    "key": "Composer",
    "name": "Composer"
  },
  {
    "key": "Cosign",
    "name": "Cosign"
  },
  {
    "key": "Crystal",
    "name": "Crystal"
  },
  {
    "key": "Dart",
    "name": "Dart"
  },
  {
    "key": "Deploy-ECS",
    "name": "Deploy-ECS"
  },
  {
    "key": "Diffblue-Cover",
    "name": "Diffblue-Cover"
  },
  {
    "key": "Django",
    "name": "Django"
  },
  {
    "key": "Docker",
    "name": "Docker"
  },
  {
    "key": "Elixir",
    "name": "Elixir"
  },
  {
    "key": "Flutter",
    "name": "Flutter"
  },
  {
    "key": "Getting-Started",
    "name": "Getting-Started"
  }
]
```

## Récupérer les détails d'un modèle CI/CD {#retrieve-details-of-a-cicd-template}

Récupère les détails d'un modèle CI/CD spécifique.

```plaintext
GET /templates/gitlab_ci_ymls/:key
```

| Attribut | Type   | Obligatoire | Description |
|-----------|--------|----------|-------------|
| `key`     | string | Oui      | La clé du modèle YAML CI/CD GitLab |

Exemple de requête :

```shell
curl "https://gitlab.example.com/api/v4/templates/gitlab_ci_ymls/Ruby"
```

Exemple de réponse :

```json
{
  "name": "Ruby",
  "content": "# This file is a template, and might need editing before it works on your project.\n# You can copy and paste this template into a new `.gitlab-ci.yml` file.\n# You should not add this template to an existing `.gitlab-ci.yml` file by using the `include:` keyword.\n#\n# To contribute improvements to CI/CD templates, please follow the Development guide at:\n# https://docs.gitlab.com/development/cicd/templates/\n# This specific template is located at:\n# https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Ruby.gitlab-ci.yml\n\n# Official language image. Look for the different tagged releases at:\n# https://hub.docker.com/r/library/ruby/tags/\nimage: ruby:latest\n\n# Pick zero or more services to be used on all builds.\n# Only needed when using a docker container to run your tests in.\n# Check out: https://docs.gitlab.com/ci/services/\nservices:\n  - mysql:latest\n  - redis:latest\n  - postgres:latest\n\nvariables:\n  POSTGRES_DB: database_name\n\n# Cache gems in between builds\ncache:\n  key:\n    files:\n      - Gemfile.lock\n  paths:\n    - vendor/ruby\n\n# This is a basic example for a gem or script which doesn't use\n# services such as redis or postgres\nbefore_script:\n  - ruby -v  # Print out ruby version for debugging\n  # Uncomment next line if your rails app needs a JS runtime:\n  # - apt-get update -q && apt-get install nodejs -yqq\n  - bundle config set --local deployment true\n  - bundle config set --local path './vendor/ruby' # Install dependencies into ./vendor/ruby\n  - bundle install -j $(nproc)\n\n# Optional - Delete if not using `rubocop`\nrubocop:\n  script:\n    - rubocop\n\nrspec:\n  script:\n    - rspec spec\n\nrails:\n  variables:\n    DATABASE_URL: \"postgresql://postgres:postgres@postgres:5432/$POSTGRES_DB\"\n  script:\n    - rails db:migrate\n    - rails db:seed\n    - rails test\n\n# This deploy job uses a simple deploy flow to Heroku, other providers, e.g. AWS Elastic Beanstalk\n# are supported too: https://github.com/travis-ci/dpl\ndeploy:\n  stage: deploy\n  environment: production\n  script:\n    - gem install dpl\n    - dpl --provider=heroku --app=$HEROKU_APP_NAME --api-key=$HEROKU_PRODUCTION_KEY\n"
}
```
