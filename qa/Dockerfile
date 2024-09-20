ARG BUILD_OS=debian
ARG CHROME_VERSION=123
ARG DOCKER_VERSION=24.0.5
ARG GCLOUD_VERSION=413
ARG GIT_VERSION=2.45
ARG HELM_VERSION=3.14
ARG KUBECTL_VERSION=1.28
ARG LFS_VERSION=2.9
ARG OS_VERSION=bookworm
ARG QA_BUILD_TARGET=ee
ARG RUBY_VERSION=3.2.4

FROM registry.gitlab.com/gitlab-org/gitlab-build-images/${BUILD_OS}-${OS_VERSION}-ruby-${RUBY_VERSION}:git-${GIT_VERSION}-lfs-${LFS_VERSION}-chrome-${CHROME_VERSION}-docker-${DOCKER_VERSION}-gcloud-${GCLOUD_VERSION}-kubectl-${KUBECTL_VERSION}-helm-${HELM_VERSION} AS foss
LABEL maintainer="GitLab Quality Department <quality@gitlab.com>"

ENV DEBIAN_FRONTEND="noninteractive"
# Override config path to make sure local config doesn't override it when building image locally
ENV BUNDLE_APP_CONFIG=/home/gitlab/.bundle

##
# Install system libs
#
RUN apt-get update \
    && apt-get install -y xvfb unzip google-cloud-sdk-gke-gcloud-auth-plugin \
    && apt-get -yq autoremove \
    && apt-get clean -yqq \
    && rm -rf /var/lib/apt/lists/*

##
# Install 1Password CLI
#
RUN wget -P /tmp/ https://downloads.1password.com/linux/debian/$(dpkg --print-architecture)/stable/1password-cli-$(dpkg --print-architecture)-latest.deb
RUN dpkg -i /tmp/1password-cli-$(dpkg --print-architecture)-latest.deb
RUN op --version

##
# Install root certificate
#
RUN mkdir -p /usr/share/ca-certificates/gitlab
ADD ./qa/tls_certificates/authority/ca.crt /usr/share/ca-certificates/gitlab/
RUN echo 'gitlab/ca.crt' >> /etc/ca-certificates.conf
RUN chmod -R 644 /usr/share/ca-certificates/gitlab && update-ca-certificates

WORKDIR /home/gitlab/qa

##
# Install qa dependencies or fetch from cache if unchanged
#
COPY qa/Gemfile* /home/gitlab/qa/
COPY vendor/gems/ /home/gitlab/vendor/gems/
COPY gems/gitlab-utils /home/gitlab/gems/gitlab-utils
COPY qa/gems /home/gitlab/qa/gems
RUN ls -la && bundle config set --local without development \
    && bundle install --retry=3

COPY ./config/initializers/0_inject_enterprise_edition_module.rb /home/gitlab/config/initializers/
COPY ./config/feature_flags /home/gitlab/config/feature_flags
COPY ./config/bundler_setup.rb /home/gitlab/config/
COPY ./lib/gitlab_edition.rb /home/gitlab/lib/
COPY ./spec/support/fast_quarantine.rb /home/gitlab/spec/support/
COPY ./tooling/lib/tooling/fast_quarantine.rb /home/gitlab/tooling/lib/tooling/
COPY ./INSTALLATION_TYPE ./VERSION /home/gitlab/

COPY ./qa /home/gitlab/qa

ENTRYPOINT ["bin/test"]

# Add ee files when passing the parameter: `--build-arg QA_BUILD_TARGET=ee`
FROM foss AS ee
# Copy VERSION to ensure the COPY succeeds to copy at least one file since ee/app/models/license.rb isn't present in FOSS
# The [b] part makes ./ee/app/models/license.r[b] a pattern that is allowed to return no files (which is the case in FOSS)
ONBUILD COPY VERSION ./ee/app/models/license.r[b] /home/gitlab/ee/app/models/
ONBUILD COPY VERSION ./ee/config/feature_flag[s] /home/gitlab/ee/config/feature_flags/

# Add JH files when passing the parameter: `--build-arg QA_BUILD_TARGET=jhqa`
FROM ee AS jhqa
ONBUILD COPY ./jh/qa /home/gitlab/jh/qa
ONBUILD COPY ./jh/lib /home/gitlab/jh/lib
ONBUILD COPY ./jh/config/feature_flags /home/gitlab/jh/config/feature_flags

# Add solargraph gem for devcontainer
# Solargraph is only present in parent Gemfile so we just install it manually
FROM ee AS dev
RUN gem install solargraph --force

FROM $QA_BUILD_TARGET
