FROM registry.gitlab.com/gitlab-org/gitlab-development-kit/asdf-bootstrapped-gdk-installed-gitlab-e2e:ml-create-image-for-gitlab-qa-tests

ENV CHROME_DRIVER_VERSION="107.0.5304.62"
ENV CHROME_VERSION="107.0.5304.87-1"
ENV CHROME_DEB="google-chrome-stable_${CHROME_VERSION}_amd64.deb"
ENV CHROME_URL="https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab-build-images/packages/generic/google-chrome-stable/${CHROME_VERSION}/${CHROME_DEB}"

WORKDIR /home/gdk/gdk

COPY --chown=gdk qa/gdk/gdk.yml .

RUN cat gdk.yml && \
    gdk update && \
    gdk restart && \
    ./support/test_url http://gdk.test:3000 && \
    gdk stop && sleep 5 && \
    GDK_KILL_CONFIRM=true gdk kill && \
    ps -ef && \
    cd gitlab && git reset --hard && \
    sudo rm -rf "$HOME/gdk/gitaly/_build/deps/git/source" \
        "$HOME/gdk/gitaly/_build/deps/libgit2/source" \
        "$HOME/gdk/gitaly/_build/cache" \
        "$HOME/gdk/gitaly/_build/deps" \
        "$HOME/gdk/gitaly/_build/intermediate" \
        "$HOME/.cache/" \
        "$HOME/gdk/gdk/gitlab" \
        /tmp/*

# Install Google Chrome version with headless support
# Download from our local S3 bucket, populated by https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/scripts/cache-google-chrome
#
RUN echo "${CHROME_URL}" && \
    curl --silent --show-error --fail -O "${CHROME_URL}" && \
    sudo apt update && \
    sudo dpkg -i "./${CHROME_DEB}" || true && \
    sudo apt install -f -y && \
    rm -f "./${CHROME_DEB}"

WORKDIR /home/gdk/gdk/gitlab

RUN bundle install --jobs=$(nproc) --retry=3 --quiet
RUN cd qa && \
    bundle install --jobs=$(nproc) --retry=3 --quiet && \
    bundle exec rake -f tasks/webdrivers.rake webdrivers:chromedriver:update[${CHROME_DRIVER_VERSION}]

RUN git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

COPY --chown=gdk qa/gdk/launch .

ENTRYPOINT ["./launch"]
