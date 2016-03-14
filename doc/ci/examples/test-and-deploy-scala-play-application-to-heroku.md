## Test and Deploy a Scala/Play application
This example guides you in setting up Gitlab CI for Play Scala web applications with automated testing and deployment to Heroku. It is accompanied with a [running example](https://gitlab-play-sample-app.herokuapp.com/) ([source](https://gitlab.com/jasperdenkers/play-scala-heroku-sample-app) and [build status](https://gitlab.com/jasperdenkers/play-scala-heroku-sample-app/builds)).

### Configure CI for your project
Add the following `.gitlab-ci.yml` to an existing project based on Play:

```yaml
image: java:8

before_script:
  # Install SBT
  - echo "deb http://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
  - apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
  - apt-get update -yq
  - apt-get install sbt -y
  - sbt sbt-version

stages:
  - test
  - deploy

test:
  stage: test
  script:
    - sbt test

deploy:
  stage: deploy
  script:
    - apt-get update -yq
    - apt-get install rubygems ruby-dev -y
    - gem install dpl
    - dpl --provider=heroku --app=gitlab-play-sample-app --api-key=$HEROKU_API_KEY
```

It consists of two stages:
1. `test` - executes tests using SBT.
2. `deploy` - automatically deploys the project to Heroku using dpl.

### Heroku application
A Heroku application is required. You can create one through the [Dashboard](https://dashboard.heroku.com/). Substitute `gitlab-play-sample-app` in the `.gitlab-ci.yml` file with your application's name.

### Heroku API key
You can look up your Heroku API key in your [account](https://dashboard.heroku.com/account). Add a variable with this value in `Project > Variables` with key `HEROKU_API_KEY`.
