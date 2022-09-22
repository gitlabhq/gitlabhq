---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference
---
# Jupyter Notebook files **(FREE)**

[Jupyter Notebook](https://jupyter.org/) (previously, IPython Notebook) files are used for
interactive computing in many fields. They contain a complete record of the
user's sessions and include:

- Code.
- Narrative text.
- Equations.
- Rich output.

When you add a Jupyter Notebook (with `.ipynb` extension) to your repository,
it's rendered into HTML when you view it:

![Jupyter Notebook Rich Output](img/jupyter_notebook.png)

Interactive features, including JavaScript plots, don't work when viewed in
GitLab.

## Cleaner diffs and raw diffs

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6589) in GitLab 14.5 as an [Alpha](../../../../policy/alpha-beta-support.md#alpha-features) release [with a flag](../../../../administration/feature_flags.md) named `jupyter_clean_diffs`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75500) in GitLab 14.9. Feature flag `jupyter_clean_diffs` removed.
> - [Reintroduced toggle](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85079) in GitLab 15.0 [with a flag](../../../../administration/feature_flags.md) named `ipynb_semantic_diff`. Enabled by default.

FLAG:
On self-managed GitLab, by default semantic diffs are available. To hide the feature, ask an administrator to [disable the feature flag](../../../../administration/feature_flags.md) named `ipynb_semantic_diff`.
On GitLab.com, this feature is available.

When commits include changes to Jupyter Notebook files, GitLab:

- Transforms the machine-readable `.ipynb` file into a human-readable Markdown file.
- Displays a cleaner version of the diff that includes syntax highlighting.
- Enables switching between raw and rendered diffs on the Commit and Compare pages. (Not available on merge request pages.)

Code suggestions are not available on diffs and merge requests for `.ipynb` files.

![Jupyter Notebook Clean Diff](img/jupyter_notebook_diff_v14_5.png)

This feature is an [Alpha](../../../../policy/alpha-beta-support.md#alpha-features) release,
and might lead to performance degradation. On self-managed GitLab, if unexpected issues
arise, disable the feature.

## Jupyter Git integration

Jupyter can be configured as an OAuth application with repository access, acting
on behalf of the authenticated user. See the
[Runbooks documentation](../../../project/clusters/runbooks/index.md) for an
example configuration.
