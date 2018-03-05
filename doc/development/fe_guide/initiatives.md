# Initiatives

These are the long term iniatives of the frontend team.

## CSS refactor

Our existing CSS is large, difficult to maintain and often creates UI regressions.
It does not consistently follow a CSS paradigm.
We are in the process of creating a new CSS framework that will ensure consistency and maintainability.
It will be based on Bootstrap 3 and added to GitLab component by component.

For more details about this initative, please visit issue [#42325](https://gitlab.com/gitlab-org/gitlab-ce/issues/42325)

## Improve webpack code splitting

> TODO: Add information about webpack code splitting

For more details about this initative, please visit issue #TODO

## Use gitlab-svgs

A lot of images and icons are loaded on GitLab.
We are in the process of moving all of that into our [gitlab-svgs](https://gitlab.com/gitlab-org/gitlab-svgs) project. This project automatically optimizes the SVGs and creates a sprite sheet. A sprite sheet enables icons to be fetched and cached once. Previously, GitLab would perform a network request to get the icon image each time the icon was displayed on a single page.

For more details about this initative, please visit issue #TODO
