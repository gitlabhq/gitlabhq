# Guidelines for implementing Enterprise Edition feature

## Write the code and the tests

Implement the wanted feature.
Implemented feature needs to have the full test coverage.
For now, exception is the code that needs to query a LDAP server.

## Write the documentation

Any feature needs to be well documented. Add the documentation to `/doc` directory, describe the main use of the newly implemented feature and, if applicable, add screenshots.

## Submit the MR to `about.gitlab.com`

Submit the MR to [about.gitlab.com site repository](https://gitlab.com/gitlab-com/www-gitlab-com) to add the new feature to the [EE feature comparison page](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/source/gitlab-ee/index.html)
