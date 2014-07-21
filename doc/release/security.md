# Things to do when doing an out-of-bound security release

NOTE: This is a guide for GitLab developers. If you are trying to install GitLab see the latest stable [installation guide](install/installation.md) and if you are trying to upgrade, see the [upgrade guides](update).

## When to do a security release

Do a security release when there is a critical issue that needs to be addresses before the next monthly release. Otherwise include it in the monthly release and note there was a security fix in the release announcement.

## Security vulnerability disclosure

Please report suspected security vulnerabilities in private to <support@gitlab.com>, also see the [disclosure section on the GitLab.com website](http://www.gitlab.com/disclosure/). Please do NOT create publicly viewable issues for suspected security vulnerabilities.

## Release Procedure

1. Verify that the issue can be reproduced
1. Acknowledge the issue to the researcher that disclosed it
1. Do the steps from [patch release document](doc/release/patch.md), starting with "Create an issue on private GitLab development server"
1. Create feature branches for the blog post on GitLab.com and link them from the code branch
1. Merge and publish the blog posts
1. Send tweets about the release from `@gitlabhq`
1. Send out an email to the 'GitLab Newsletter' mailing list on MailChimp (or the 'Subscribers' list if the security fix is for EE only)
1. Send out an email to [the community google mailing list](https://groups.google.com/forum/#!forum/gitlabhq)
1. Post a signed copy of our complete announcement to [oss-security](http://www.openwall.com/lists/oss-security/) and request a CVE number
1. Add the security researcher to the [Security Researcher Acknowledgments list](http://www.gitlab.com/vulnerability-acknowledgements/)
1. Thank the security researcher in an email for their cooperation
1. Update the blog post and the CHANGELOG when we receive the CVE number

The timing of the code merge into master should be coordinated in advance.

After the merge we strive to publish the announcements within 60 minutes.

## Blog post template

XXX Security Advisory for GitLab

A recently discovered critical vulnerability in GitLab allows [unauthenticated API access|remote code execution|unauthorized access to repositories|XXX|PICKSOMETHING]. All users should update GitLab and gitlab-shell immediately. We [have|haven't|XXX|PICKSOMETHING|] heard of this vulnerability being actively exploited.

### Version affected

GitLab Community Edition XXX and lower

GitLab Enterprise Edition XXX and lower

### Fixed versions

GitLab Community Edition XXX and up

GitLab Enterprise Edition XXX and up

### Impact

On GitLab installations which use MySQL as their database backend it is possible for an attacker to assume the identity of any existing GitLab user in certain API calls. This attack can be performed by [unauthenticated|authenticated|XXX|PICKSOMETHING] users.

### Workarounds

If you are unable to upgrade you should apply the following patch and restart GitLab.

XXX

### Credit

We want to thank XXX of XXX for the reponsible disclosure of this vulnerability.

## Email template

We just announced a security advisory for GitLab at XXX

Please contact us at support@gitlab.com if you have any questions.

## Tweet template

We just announced a security advisory for GitLab at XXX
