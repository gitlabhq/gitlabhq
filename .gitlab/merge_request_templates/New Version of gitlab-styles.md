<!-- Title suggestion: Upgrade `gitlab-styles` to <VERSION X.Y.Z> - dry-run -->

## What does this MR do and why?

Validating upcoming release of `gitlab-styles` <VERSION X.Y.Z>. See <LINK TO RELEASE MR>.

This MR can be reused to upgrade `gitlab-styles` in this project after a new version of `gitlab-styles` is released.

### Checklist

- [ ] Verify upcoming release of `gitlab-styles`
  - [ ] Point to "Release" MR of `gitlab-styles` in `Gemfile`
    - For example, `gem 'gitlab-styles', '~> 9.1.0', require: false, git: 'https://gitlab.com/gitlab-org/ruby/gems/gitlab-styles.git', ref: 'ddieulivol-upgrade_to_9.1.0' # rubocop:disable Cop/GemFetcher`
  - [ ] Update [bundler's checksum file](https://docs.gitlab.com/ee/development/gemfile.html#updating-the-checksum-file) via `bundle install && bundle exec bundler-checksum init`
  - [ ] Update `Gemfile.next` via `bundle install --gemfile Gemfile.next && cp Gemfile.lock Gemfile.next.lock && BUNDLE_GEMFILE=Gemfile.next bundle lock && BUNDLE_GEMFILE=Gemfile.next bundle exec bundler-checksum init`
  - [ ] `rubocop` job
    - [ ] Inspect any warnings/errors
    - [ ] (Optional) [Generate TODOs](https://docs.gitlab.com/ee/development/rubocop_development_guide.html#resolving-rubocop-exceptions) for pending offenses
      - [ ] Put :new: cop rules (or if configuration is changed) in "grace period". See [docs](https://docs.gitlab.com/ee/development/rubocop_development_guide.html#enabling-a-new-cop).
      - [ ] (Optional) Remove any offenses for disabled cops
      - Use `grep --extended-regexp -o ":[0-9]+:[0-9]+: [[:alnum:]]: \[[^[:space:]]+\] ([[:alnum:]/]+)" raw_job_output.log | awk '{print $4}' | sort | uniq -c` to get a list of cop rules with offenses. Where `raw_job_output.log` is the raw output of the `rubocop` job
    - [ ] (Optional) Autocorrect offenses (only if the changeset is small)
    - [ ] Compare the total runtime of `rubocop --parallel` scan with previous runs
  - [ ] Make sure CI passes and does not have "silenced offenses" :green_heart:
  - [ ] Don't merge this MR yet!
  - [ ] Wait for `gitlab-styles` to be released
- [ ] Upgrade released version of `gitlab-styles`
  - [ ] Make sure release is complete
  - [ ] Rephrase the title and MR description to match final upgrade
  - [ ] Point to released version in `Gemfile`
    - [ ] `gem 'gitlab-styles', '~> 9.1.0', require: false`
    - [ ] Update [bundler's checksum file](https://docs.gitlab.com/ee/development/gemfile.html#updating-the-checksum-file) via `bundle install && bundle exec bundler-checksum init`
    - [ ] Update `Gemfile.next` via `bundle install --gemfile Gemfile.next && cp Gemfile.lock Gemfile.next.lock && BUNDLE_GEMFILE=Gemfile.next bundle lock && BUNDLE_GEMFILE=Gemfile.next bundle exec bundler-checksum init`
  - [ ] (Optional) Regenerate TODOs for new/changed cop rules
  - [ ] Make sure CI passes and does not have "silenced offenses" :green_heart:
  - [ ] Let the MR being reviewed again and merged
  - [ ] (Optional) Refine this [MR template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/New%20Version%20of%20gitlab-styles.md).

## MR acceptance checklist

**Please evaluate this MR against the [MR acceptance checklist](https://docs.gitlab.com/ee/development/code_review.html#acceptance-checklist).**
It helps you analyze changes to reduce risks in quality, performance, reliability, security, and maintainability.

## After merge

- [ ] Notify team members of the upgrade by creating an announcement in relevant Slack channels (`#backend` and `#development`)
and Engineering Week In Review (EWIR).

/label ~"type::maintenance" ~"maintenance::dependency"  ~backend ~"Engineering Productivity" ~"static code analysis" 
