---
type: reference, howto
stage: Release
group: Release Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# New Pages website from a forked sample

To get started with GitLab Pages from a sample website, the easiest
way to do it is by using one of the [bundled templates](pages_bundled_template.md).
If you don't find one that suits your needs, you can opt by
forking (copying) a [sample project from the most popular Static Site Generators](https://gitlab.com/pages).

<table class="borderless-table center fixed-table middle width-80">
  <tr>
    <td style="width: 30%"><img src="../img/icons/fork.png" alt="Fork" class="image-noshadow half-width"></td>
    <td style="width: 10%">
      <strong>
        <i class="fa fa-angle-double-right" aria-hidden="true"></i>
      </strong>
    </td>
    <td style="width: 30%"><img src="../img/icons/terminal.png" alt="Deploy" class="image-noshadow half-width"></td>
    <td style="width: 10%">
      <strong>
        <i class="fa fa-angle-double-right" aria-hidden="true"></i>
      </strong>
    </td>
    <td style="width: 30%"><img src="../img/icons/click.png" alt="Visit" class="image-noshadow half-width"></td>
  </tr>
  <tr>
    <td><em>Fork an example project</em></td>
    <td></td>
    <td><em>Deploy your website</em></td>
    <td></td>
    <td><em>Visit your website's URL</em></td>
  </tr>
</table>

**<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Watch a [video tutorial](https://www.youtube.com/watch?v=TWqh9MtT4Bg) with all the steps below.**

1. [Fork](../../../../gitlab-basics/fork-project.md) a sample project from the [GitLab Pages examples](https://gitlab.com/pages) group.
1. From the left sidebar, navigate to your project's **CI/CD > Pipelines**
   and click **Run pipeline** to trigger GitLab CI/CD to build and deploy your
   site to the server.
1. Once the pipeline has finished successfully, find the link to visit your
   website from your project's **Settings > Pages**. It can take approximately
   30 minutes to be deployed.

You can also take some **optional** further steps:

- _Remove the fork relationship._ The fork relationship is necessary to contribute back to the project you originally forked from. If you don't have any intentions to do so, you can remove it. To do so, navigate to your project's **Settings**, expand **Advanced settings**, and scroll down to **Remove fork relationship**:

  ![Remove fork relationship](../img/remove_fork_relationship.png)

- _Make it a user or group website._ To turn a **project website** forked
  from the Pages group into a **user/group** website, you'll need to:
  - Rename it to `namespace.gitlab.io`: go to your project's
    **Settings > General** and expand **Advanced**. Scroll down to
    **Change path** and change the path to `namespace.gitlab.io`.

    For example, consider the group `https://gitlab.com/gitlab-tests`:
   `gitlab-tests` is the group's namespace, the repository path should be set
    to `gitlab-tests.gitlab.io` (yes, weird like that), and the
    resulting URL for your Pages website will be `https://gitlab-tests.gitlab.io`.

    ![Change repo's path](../img/change_path_v12_10.png)

  - Adjust your SSG's [base URL](../getting_started_part_one.md#urls-and-baseurls) from `"project-name"` to
    `""`. This setting will be at a different place for each SSG, as each of them
    have their own structure and file tree. Most likely, it will be in the SSG's
    config file.
