# SAST Rules Release X.Y.Z

## Actions for ~"group::vulnerability research" team member

1. [ ] Create this issue and replace X.Y.Z with the actual version number of the sast-rules release to be published.

/assign @gitlab-org/secure/static-analysis/reaction-rotation

Note: If the rules release includes support for a new file type, the engineer(s) on reaction rotation will refine and schedule the for an upcoming milestone.

## Actions for ~"group::static analysis" team member

Release the new Semgrep SAST ruleset version X.Y.Z by going through the sequence of steps below:

1. [ ] If support for a new file type is required, refine and schedule the issue for an upcoming milestone.
1. [ ] Set `SAST_RULES_VERSION=X.Y.Z` in [Dockerfile](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/Dockerfile) and
   [Dockerfile.fips](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/Dockerfile.fips).
1. [ ] Add a [Changelog entry](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md).
   ``` md 
   - Update sast-rules version X.Y.Z.
     - List all rule changes since the last release here.
   ```
1. [ ] If support for a new file type is required:
   1. [ ] Add new extension to https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/plugin/plugin.go.
   1. [ ] Update [SAST components template](https://gitlab.com/components/sast/-/blob/main/templates/sast.yml) to add support for new file type.
   1. [ ] Update the SAST templates [SAST.latest.gitlab-ci.yml](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml).
      and [SAST.gitlab-ci.yml](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) to support new file types.
   1. [ ] Update the [SAST documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/user/application_security/sast/_index.md).
1. [ ] Update `SAST_RULES_VERSION` in the [sast-scanner-service .gitlab-ci.yml](https://gitlab.com/gitlab-org/secure/sast-scanner-service/-/blob/main/.gitlab-ci.yml?ref_type=heads)
1. [ ] Update `sast-rules` submodule branch in [sast-ide-integration](https://gitlab.com/gitlab-org/secure/sast-ide-integration) to point to the `X.Y.Z` tag.
1. [ ] Once the branch is merged, deploy the updated SAST service to the staging and/or production environments by manually triggering the `Trigger runway deployment` jobs.


/label ~"group::static analysis" ~"devops::application security testing" ~"section::sec" ~"Category:SAST" ~"type::feature" ~"workflow::refinement" 
