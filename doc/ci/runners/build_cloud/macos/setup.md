---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Set up macOS runners

To run a CI/CD job on a macOS runner, complete the following steps in order.

When you're done, GitLab Runner will be running on your macOS machine
and an individual runner will be ready to process jobs.

- Change the system shell to Bash.
- Install Homebrew, rbenv, and GitLab Runner.
- Configure rbenv and install Ruby.
- Install Xcode.
- Register a runner.
- Configure CI/CD.

## Prerequisites

Before you begin:

- Install a recent version of macOS. This guide was developed on 11.4.
- Ensure you have terminal or SSH access to the machine.

## Change the system shell to Bash

Newer versions of macOS ship with Zsh as the default shell.
You must change it to Bash.

1. Connect to your machine and determine the default shell:

   ```shell
   echo $shell
   ```

1. If the result is not `/bin/bash`, change the shell by running:
  
   ```shell
   chsh -s /bin/bash
   ```

1. Enter your password.
1. Restart your terminal or reconnect by using SSH.
1. Run `echo $SHELL` again. The result should be `/bin/bash`.

## Install Homebrew, rbenv, and GitLab Runner

The runner needs certain environment options to connect to the machine and run a job.

1. Install the [Homebrew package manager](https://brew.sh/):

   ```shell
   /bin/bash -c "$(curl "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")"
   ```

1. Set up [`rbenv`](https://github.com/rbenv/rbenv), which is a Ruby version manager, and GitLab Runner:
  
   ```shell
   brew install rbenv gitlab-runner
   brew services start gitlab-runner
   ```

## Configure rbenv and install Ruby

Now configure rbenv and install Ruby.

1. Add rbenv to the Bash environment:

   ```shell
   echo 'if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi' >> ~/.bash_profile
   source ~/.bash_profile
   ```

1. Install Ruby 2.74 and set it as the machine's global default:

   ```shell
   rbenv install 2.7.4
   rbenv global 2.7.4
   ```

## Install Xcode

Now install and configure Xcode.

1. Go to one of these locations and install Xcode:

   - The Apple App Store.
   - The [Apple Developer Portal](https://developer.apple.com/download/all/?q=xcode).
   - [`xcode-install`](https://github.com/xcpretty/xcode-install). This project aims to make it easier to download various
     Apple dependencies from the command line.

1. Agree to the license and install the recommended additional components.
   You can do this by opening Xcode and following the prompts, or by running the following command in the terminal:

   ```shell
   sudo xcodebuild -runFirstLaunch
   ```

1. Update the active developer directory so that Xcode loads the proper command line tools during your build:

   ```shell
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

### Register a runner

Now register a runner to start picking up your CI/CD jobs.

1. In GitLab, on the top bar, select **Menu > Projects** or **Menu > Group** to find your project or group.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Runners**.
1. Note the URL and registration token.
1. In a terminal, start the interactive setup:

   ```shell
   gitlab-runner register
   ```

1. Enter the GitLab URL.
1. Enter the registration token.
1. Enter a description for the runner.
   You will use the description to identify the runner in GitLab, and the name is associated with jobs executed on this instance.

1. Enter tags, which direct specific jobs to specific instances. You will use these tags later to ensure macOS jobs
   run on this macOS machine. In this example, enter:

   ```shell
   macos
   ```

1. Type `shell` to select the shell [executor](https://docs.gitlab.com/runner/executors/).

A success message is displayed:

```shell
> Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

To view the runner, go to **Settings > CI/CD** and expand **Runners**.

### Configure CI/CD

In your GitLab project, configure CI/CD and start a build. You can use this sample `.gitlab-ci.yml` file.
Notice the tags match the tags you used to register the runner.

```yaml
stages:
  - build
  - test

variables:
  LANG: "en_US.UTF-8"

before_script:
  - gem install bundler
  - bundle install
  - gem install cocoapods
  - pod install

build:
  stage: build
  script:
    - bundle exec fastlane build
  tags:
    - macos

test:
  stage: test
  script:
    - bundle exec fastlane test
  tags:
    - macos
```

The macOS runner should now build your project.
