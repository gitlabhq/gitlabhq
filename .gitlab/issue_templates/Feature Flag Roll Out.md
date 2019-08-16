<!-- Title suggestion: [Feature flag] Enable description of feature -->

## What

Remove the `:feature_name` feature flag ...

## Owners

- Team: NAME_OF_TEAM
- Most appropriate slack channel to reach out to: `#g_TEAM_NAME`
- Best individual to reach out to: NAME

## Expectations

### What are we expecting to happen?

### What might happen if this goes wrong?

### What can we monitor to detect problems with this?

<!-- Which dashboards from https://dashboards.gitlab.net are most relevant? -->

## Beta groups/projects

If applicable, any groups/projects that are happy to have this feature turned on early. Some organizations may wish to test big changes they are interested in with a small subset of users ahead of time for example.

- `gitlab-org/gitlab-ce`/`gitlab-org/gitlab-ee` projects
- `gitlab-org`/`gitlab-com` groups
- ...

## Roll Out Steps

- [ ] Enable on staging
- [ ] Test on staging
- [ ] Ensure that documentation has been updated
- [ ] Enable on GitLab.com for individual groups/projects listed above and verify behaviour
- [ ] Announce on the issue an estimated time this will be enabled on GitLab.com
- [ ] Enable on GitLab.com by running chatops command in `#production`
- [ ] Cross post chatops slack command to `#support_gitlab-com` and in your team channel
- [ ] Announce on the issue that the flag has been enabled
- [ ] Remove feature flag and add changelog entry
- [ ] After the flag removal is deployed, [clean up the feature flag](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up) by running chatops command in `#production` channel

/label ~"feature flag"
