## GitLab CI Documentation

### CI User documentation

- [Get started with GitLab CI](quick_start/README.md)
- [Learn how to enable or disable GitLab CI](enable_or_disable_ci.md)
- [Learn how `.gitlab-ci.yml` works](yaml/README.md)
- [Configure a Runner, the application that runs your builds](runners/README.md)
- [Use Docker images with GitLab Runner](docker/using_docker_images.md)
- [Use CI to build Docker images](docker/using_docker_build.md)
- [Use variables in your `.gitlab-ci.yml`](variables/README.md)
- [Use SSH keys in your build environment](ssh_keys/README.md)
- [Trigger builds through the API](triggers/README.md)
- [Build artifacts](build_artifacts/README.md)
- [User permissions](permissions/README.md)
- [API](api/README.md)

### CI Examples

- [The .gitlab-ci.yml file for GitLab itself](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab-ci.yml)
- [Test your PHP applications](examples/php.md)
- [Test and deploy Ruby applications to Heroku](examples/test-and-deploy-ruby-application-to-heroku.md)
- [Test and deploy Python applications to Heroku](examples/test-and-deploy-python-application-to-heroku.md)
- [Test Clojure applications](examples/test-clojure-application.md)
- [Using `dpl` as deployment tool](deployment/README.md)
- Help your favorite programming language and GitLab by sending a merge request
  with a guide for that language.

### CI Services

GitLab CI uses the `services` keyword to define what docker containers should
be linked with your base image. Below is a list of examples you may use:

- [Using MySQL](services/mysql.md)
- [Using PostgreSQL](services/postgres.md)
- [Using Redis](services/redis.md)
- [Using Other Services](docker/using_docker_images.md#how-to-use-other-images-as-services)
