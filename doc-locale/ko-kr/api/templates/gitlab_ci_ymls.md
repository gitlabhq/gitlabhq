---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 템플릿 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 기본 제공 [CI/CD 템플릿](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)을 검색합니다. 사용자 정의 템플릿은 사용할 수 없습니다.

게스트 역할을 가진 사용자는 CI/CD 템플릿에 액세스할 수 없습니다. 자세한 내용은 [프로젝트 및 그룹 가시성](../../user/public_access.md)을 참조하세요.

## 모든 CI/CD 템플릿 나열 {#list-all-cicd-templates}

모든 GitLab CI/CD YAML 템플릿을 나열합니다.

```plaintext
GET /templates/gitlab_ci_ymls
```

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/templates/gitlab_ci_ymls"
```

응답 예:

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

## CI/CD 템플릿의 세부 정보 검색 {#retrieve-details-of-a-cicd-template}

특정 CI/CD 템플릿의 세부 정보를 검색합니다.

```plaintext
GET /templates/gitlab_ci_ymls/:key
```

| 속성 | 유형   | 필수 | 설명 |
|-----------|--------|----------|-------------|
| `key`     | 문자열 | 예      | GitLab CI/CD YAML 템플릿의 키 |

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/templates/gitlab_ci_ymls/Ruby"
```

응답 예:

```json
{
  "name": "Ruby",
  "content": "# This file is a template, and might need editing before it works on your project.\n# You can copy and paste this template into a new `.gitlab-ci.yml` file.\n# You should not add this template to an existing `.gitlab-ci.yml` file by using the `include:` keyword.\n#\n# To contribute improvements to CI/CD templates, please follow the Development guide at:\n# https://docs.gitlab.com/development/cicd/templates/\n# This specific template is located at:\n# https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Ruby.gitlab-ci.yml\n\n# Official language image. Look for the different tagged releases at:\n# https://hub.docker.com/r/library/ruby/tags/\nimage: ruby:latest\n\n# Pick zero or more services to be used on all builds.\n# Only needed when using a docker container to run your tests in.\n# Check out: https://docs.gitlab.com/ci/services/\nservices:\n  - mysql:latest\n  - redis:latest\n  - postgres:latest\n\nvariables:\n  POSTGRES_DB: database_name\n\n# Cache gems in between builds\ncache:\n  key:\n    files:\n      - Gemfile.lock\n  paths:\n    - vendor/ruby\n\n# This is a basic example for a gem or script which doesn't use\n# services such as redis or postgres\nbefore_script:\n  - ruby -v  # Print out ruby version for debugging\n  # Uncomment next line if your rails app needs a JS runtime:\n  # - apt-get update -q && apt-get install nodejs -yqq\n  - bundle config set --local deployment true\n  - bundle config set --local path './vendor/ruby' # Install dependencies into ./vendor/ruby\n  - bundle install -j $(nproc)\n\n# Optional - Delete if not using `rubocop`\nrubocop:\n  script:\n    - rubocop\n\nrspec:\n  script:\n    - rspec spec\n\nrails:\n  variables:\n    DATABASE_URL: \"postgresql://postgres:postgres@postgres:5432/$POSTGRES_DB\"\n  script:\n    - rails db:migrate\n    - rails db:seed\n    - rails test\n\n# This deploy job uses a simple deploy flow to Heroku, other providers, e.g. AWS Elastic Beanstalk\n# are supported too: https://github.com/travis-ci/dpl\ndeploy:\n  stage: deploy\n  environment: production\n  script:\n    - gem install dpl\n    - dpl --provider=heroku --app=$HEROKU_APP_NAME --api-key=$HEROKU_PRODUCTION_KEY\n"
}
```
