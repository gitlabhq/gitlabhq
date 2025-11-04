---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Secret push protection
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11439) in GitLab 16.7 as an [experiment](../../../../policy/development_stages_support.md) for GitLab Dedicated customers.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/12729) to Beta and made available on GitLab.com in GitLab 17.1.
- [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156907) in GitLab 17.2 [with flags](../../../../administration/feature_flags/_index.md) named `pre_receive_secret_detection_beta_release` and `pre_receive_secret_detection_push_check`.
- Feature flag `pre_receive_secret_detection_beta_release` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/472418) in GitLab 17.4.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/13107) in GitLab 17.5.
- Feature flag `pre_receive_secret_detection_push_check` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/472419) in GitLab 17.7.

{{< /history >}}

Secret push protection blocks secrets such as keys and API tokens from being pushed to GitLab.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see the playlist [Get Started with Secret Push Protection](https://www.youtube.com/playlist?list=PL05JrBw4t0KoADm-g2vxfyR0m6QLphTv-).

Use pipeline secret detection with secret push protection to further strengthen your security.

## Secret push protection workflow

Secret push protection takes place in the pre-receive hook. When you push changes to GitLab,
push protection checks each file or commit for secrets. By default, if a secret is detected,
the push is blocked.

<!-- To edit the diagram, use either Draw.io or the VS Code extension "Draw.io Integration" -->
![A flowchart showing how secret protection can block a push](img/spp_workflow_v17_9.drawio.svg)

When a push is blocked, GitLab prompts a message that includes:

- Commit ID containing the secret.
- Filename and line containing the secret.
- Type of secret.

For example, the following is an extract of the message returned when a push using the Git CLI is
blocked. When using other clients, including the GitLab Web IDE, the format of the message is
different but the content is the same.

```plain
remote: PUSH BLOCKED: Secrets detected in code changes
remote: Secret push protection found the following secrets in commit: 37e54de5e78c31d9e3c3821fd15f7069e3d375b6
remote:
remote: -- test.txt:2 GitLab Personal Access Token
remote:
remote: To push your changes you must remove the identified secrets.
```

If secret push protection does not detect any secrets in your commits, no message is displayed.

## Detected secrets

Secret push protection scans files or commits for specific patterns. Each pattern
matches a specific type of secret. To confirm which secrets are detected by secret push protection,
see [detected secrets](../detected_secrets.md). Only high-confidence patterns were chosen for secret
push protection, to minimize the delay when pushing your commits and minimize the number of false
alerts. For example, personal access tokens that use a custom prefix are not detected by secret push protection.
You can [exclude](../exclusions.md) selected secrets from detection by secret push protection.

## Getting started

On GitLab Dedicated and GitLab Self-Managed instances, you must:

1. Allow secret push protection on the entire instance.
1. Enable secret push protection. You can either:
   - Enable secret push protection in a specific project.
   - Use the API to enable secret push protection for all projects in group.

### Allow the use of secret push protection in your GitLab instance

On GitLab Dedicated and GitLab Self-Managed instances, you must allow secret push protection before you can enable it in a project.

Prerequisites:

- You must be an administrator for your GitLab instance.

To allow the use of secret push protection in your GitLab instance:

1. Sign in to your GitLab instance as an administrator.
1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Security and compliance**.
1. Under **Secret detection**, select or clear **Allow secret push protection**.

Secret push protection is allowed on the instance. To use this feature, you must enable it per project.

### Enable secret push protection in a project

Prerequisites:

- You must have at least the Maintainer role for the project.
- On GitLab Dedicated and GitLab Self-Managed, you must allow secret push protection on the instance.

To enable secret push protection in a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. On the left sidebar, select **Secure** > **Security configuration**.
1. Turn on the **Secret push protection** toggle.

You can also enable secret push protection for all projects in a group [with the API](../../../../api/group_security_settings.md#update-secret_push_protection_enabled-setting).

## Coverage

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185882) to diff-only scanning in GitLab 17.11.

{{< /history >}}

Secret push protection does not block a secret when:

- You used the skip secret push protection option when you pushed
  the commits.
- The secret is excluded from secret push protection.
- The secret is in a path defined as an exclusion.

Secret push protection does not check a file in a commit when:

- The file is a binary file.
- The file is larger than 1 MiB.
- The diff patch for the file is larger than 1 MiB (if you use diff scanning).
- The file was renamed, deleted, or moved without changes to the content.
- The content of the file is identical to the content of another file in the source code.
- The file is contained in the initial push that created the repository.

### Diff scanning

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/469161) in GitLab 17.5 [with a flag](../../../../administration/feature_flags/_index.md) named `spp_scan_diffs`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/480092) in GitLab 17.6.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/491282) support for Web IDE pushes in GitLab 17.10 [with a flag](../../../../administration/feature_flags/_index.md) named `secret_checks_for_web_requests`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/525627) in GitLab 17.11. Feature flag `spp_scan_diffs` removed.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/525629) `secret_checks_for_web_requests` feature flag in GitLab 17.11.

{{< /history >}}

Secret push protection scans only the diffs of commits pushed over HTTP(S) and SSH.
If a secret is already present in a file and not part of the changes, it is not detected.

## Understanding the results

Secret push protection can identify various categories of secrets:

- API keys and tokens: Service-specific authentication credentials
- Database connection strings: URLs containing embedded credentials
- Private keys: Cryptographic keys for authentication or encryption
- Generic high-entropy strings: Patterns that appear to be randomly generated secrets

When a push is blocked, secret push protection provides detailed information to help you locate and address the detected secrets:

- Commit ID: The specific commit containing the secret. Useful for tracking changes in your Git history.
- File path and line number: The exact location of the detected pattern for quick navigation.
- Secret type: The classification of the detected pattern. For example, `GitLab Personal Access Token` or `AWS Access Key`.

### Common detection categories

Not all detections require immediate action. Consider the following when evaluating results:

- True positives: Legitimate secrets that should be rotated and removed. For example:
  - Valid API keys or tokens
  - Production database credentials
  - Private cryptographic keys
  - Any credentials that could grant unauthorized access

- False positives: Detected patterns that aren't actual secrets. For example:
  - Test data that resembles secrets but has no real-world value
  - Placeholder values in configuration templates
  - Example credentials in documentation
  - Hash values or checksums that match secret patterns

Document common false positive patterns in your organization to streamline future evaluations.

## Optimization

Before deploying secret push protection widely, optimize the configuration to reduce false positives and improve accuracy for your specific environment.

### Reduce false positives

False positives can significantly impact developer productivity and lead to security fatigue.

To reduce false positives:

- Configure exclusions strategically:
  - Create path-based exclusions for test directories, documentation, and third party dependencies.
  - Use pattern-based exclusions for known false positive patterns specific to your codebase.
  - Document your exclusion rules and review them regularly.
- Create standards for placeholder values and test credentials.
- Monitor false positive rates and continue to adjust exclusions accordingly.

### Optimize performance

Large repositories or frequent pushes can have performance impacts.

To optimize the performance of secret push protection:

- Monitor push times and establish baseline metrics before deployment.
- Use diff scanning to reduce the amount of content scanned on each push.
- Consider file size limits for repositories with large binary assets.
- Implement exclusions for directories that are unlikely to contain secrets.

### Integration with existing workflows

Ensure secret push protection complements your existing development practices:

- Configure pipeline secret detection and secret push protection to be sure you have defense in depth.
- Update developer documentation to include secret push protection procedures.
- Align with security training to educate developers on secure coding practices to minimize leaked secrets.

## Roll out

Successfully deploying secret push protection at scale requires careful planning and a phased implementation:

1. Choose two or three non-critical projects with active development to test the feature and understand its impact on developer workflows.
1. Turn on secret push protection for your selected test projects and monitor developer feedback.
1. Document processes for handling blocked pushes and train your development teams on the new workflows.
1. Track the number of secrets detected, false positive rates, and developer experience feedback during the pilot phase.

You should run the pilot phase for two to four weeks to gather sufficient data and identify any workflow adjustments needed before broader deployment.

After you have completed the pilot, consider the following phases for a scaled rollout:

1. Early adopters (weeks 3-6)
   - Enable on 10-20% of active projects, prioritizing security-sensitive repositories.
   - Focus on teams with strong security awareness and buy-in.
   - Monitor performance impacts and developer experience.
   - Refine processes based on real-world usage.
1. Broad deployment (weeks 7-12)
   - Gradually enable across remaining projects in batches.
   - Provide ongoing support and training to development teams.
   - Monitor system performance and scale infrastructure if needed.
   - Continue optimizing exclusion rules based on usage patterns.
1. Full coverage (weeks 13-16)
   - Enable secret push protection on all remaining projects.
   - Establish ongoing maintenance and review processes.
   - Implement regular audits of exclusion rules and detected patterns.

## Resolve a blocked push

When secret push protection blocks a push, you can either:

- [Remove the secret](../remove_secrets_tutorial.md).
- Skip secret push protection.

### Skip secret push protection

In some cases, it might be necessary to skip secret push protection. For example, a developer might need
to commit a placeholder secret for testing, or a user might want to skip secret push protection due to
a Git operation timeout.

Audit events are logged when
secret push protection is skipped. Audit event details include:

- Skip method used.
- GitLab account name.
- Date and time at which secret push protection was skipped.
- Name of project that the secret was pushed to.
- Target branch. (Introduced in GitLab 17.4)
- Commits that skipped secret push protection. (Introduced in GitLab 17.9)

If pipeline secret detection is enabled, the content of all commits are
scanned after they are pushed to the repository.

To skip secret push protection for all commits in a push, either:

- If you're using the Git CLI client, instruct Git to skip secret push protection.
- If you're using any other client, add `[skip secret push protection]` to one of the commit messages.

#### For the Git CLI client

To skip secret push protection from the command line:

- Use the `secret_push_protection.skip_all` push option.

  For example, you have several commits that are blocked from being pushed because one of them
  contains a secret. To skip secret push protection, you append the push option to the Git command.

  ```shell
  git push -o secret_push_protection.skip_all
  ```

#### For any Git client

To skip secret push protection:

- Add `[skip secret push protection]` to one of the commit messages, on either an existing line or a new
  line, then push the commits.

  For example, you are using the GitLab Web IDE and have several commits that are blocked from being
  pushed because one of them contains a secret. To skip secret push protection, edit the latest
  commit message and add `[skip secret push protection]`, then push the commits.

## Troubleshooting

When working with secret push protection, you might encounter the following situations.

### Push blocked unexpectedly

Before GitLab 17.11, secret push protection scanned the contents of all modified files.
This can cause a push to be unexpectedly blocked if a modified file contains a secret,
even if the secret is not part of the diff.

On GitLab 17.11 and earlier, enable the `spp_scan_diffs` feature flag
to ensure that only newly committed changes are scanned. To push a Web IDE change to a
file that contains a secret, you need to additionally enable the
`secret_checks_for_web_requests` feature flag.

### File was not scanned

Some files are excluded from scanning. For details, see the coverage.
