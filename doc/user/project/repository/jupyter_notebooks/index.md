---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---
# Jupyter Notebook Files **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/2508/) in GitLab 9.1.

[Jupyter](https://jupyter.org/) Notebook (previously IPython Notebook) files are used for
interactive computing in many fields and contain a complete record of the
user's sessions and include code, narrative text, equations, and rich output.

When added to a repository, Jupyter Notebooks with a `.ipynb` extension are
rendered to HTML when viewed:

![Jupyter Notebook Rich Output](img/jupyter_notebook.png)

Interactive features, including JavaScript plots, don't work when viewed in
GitLab.

## Jupyter Git integration

Jupyter can be configured as an OAuth application with repository access, acting
on behalf of the authenticated user. See the
[Runbooks documentation](../../../project/clusters/runbooks/index.md) for an
example configuration.
