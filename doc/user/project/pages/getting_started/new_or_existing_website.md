---
type: reference, howto
---

# Start a new Pages website from scratch or deploy an existing website

If you already have a website and want to deploy it with GitLab Pages,
or, if you want to start a new site from scratch, you'll need to:

- Create a new project in GitLab to hold your site content.
- Set up GitLab CI/CD to deploy your website to Pages.

To do so, follow the steps below.

1. From your **Project**'s **[Dashboard](https://gitlab.com/dashboard/projects)**,
   click **New project**, and name it according to the
   [Pages domain names](../getting_started_part_one.md#gitlab-pages-default-domain-names).
1. Clone it to your local computer, add your website
   files to your project, add, commit and push to GitLab.
   Alternativelly, you can run `git init` in your local directory,
   add the remote URL:
   `git remote add origin git@gitlab.com:namespace/project-name.git`,
   then add, commit, and push to GitLab.
1. From the your **Project**'s page, click **Set up CI/CD**:

   ![setup GitLab CI/CD](../img/setup_ci.png)

1. Choose one of the templates from the dropbox menu.
   Pick up the template corresponding to the SSG you're using (or plain HTML).

   ![gitlab-ci templates](../img/choose_ci_template.png)

   Note that, if you don't find a corresponding template, you can look into
   [GitLab Pages group of sample projects](https://gitlab.com/pages),
   you may find one among them that suits your needs, from which you
   can copy `.gitlab-ci.yml`'s content and adjust for your case.
   If you don't find it there either, [learn how to write a `.gitlab-ci.yml`
   file for GitLab Pages](../getting_started_part_four.md).

Once you have both site files and `.gitlab-ci.yml` in your project's
root, GitLab CI/CD will build your site and deploy it with Pages.
Once the first build passes, you access your site by
navigating to your **Project**'s **Settings** > **Pages**,
where you'll find its default URL. It can take approximately 30 min to be
deployed.
