# Download the binary for your system
sudo curl --output /usr/local/bin/gitlab-runner ${GITLAB_CI_RUNNER_DOWNLOAD_LOCATION}

# Give it permissions to execute
sudo chmod +x /usr/local/bin/gitlab-runner

# The rest of commands execute as the user who will run the Runner
# Register the Runner (steps below), then run
cd ~
gitlab-runner install
gitlab-runner start
