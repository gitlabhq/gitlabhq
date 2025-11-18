# Maven Base Image for GitLab E2E Tests
#
# This image pre-caches Maven plugins to eliminate downloads during test execution,
# reducing Maven package registry test execution times.
#
# The image has been manually built and pushed to:
#   registry.gitlab.com/gitlab-org/gitlab-qa/gitlab-qa-maven-base:3.6-jdk-11
#
# To rebuild and push (requires access to gitlab-org/gitlab-qa):
#   docker build -t registry.gitlab.com/gitlab-org/gitlab-qa/gitlab-qa-maven-base:3.6-jdk-11 .
#   docker push registry.gitlab.com/gitlab-org/gitlab-qa/gitlab-qa-maven-base:3.6-jdk-11

FROM maven:3.6-jdk-11

WORKDIR /tmp

# Pre-cache Maven plugins by running a dummy build
RUN echo '<project><modelVersion>4.0.0</modelVersion><groupId>warm</groupId><artifactId>cache</artifactId><version>1.0</version></project>' > pom.xml \
    && mvn -B deploy install -DskipTests -DaltDeploymentRepository=local::default::file:./target/repo \
    && rm -rf /tmp/*

WORKDIR /builds
