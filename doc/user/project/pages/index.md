# GitLab Pages

With GitLab Pages it's easy to publish your project website. GitLab Pages is a hosting service for static websites, at no additional cost.

## Getting Started

[Create a project from scratch](getting_started_part_two.md#create-a-project-from-scratch)
to get you started quickly, or,
alternatively, start from an existing project as follows:

- 1. [Fork](../../../gitlab-basics/fork-project.md#how-to-fork-a-project) an [example project](https://gitlab.com/pages):
by forking a project, you create a copy of the codebase you're forking from to start from a template instead of starting from scratch.
- 2. Change a file to trigger a GitLab CI/CD pipeline: GitLab CI/CD will build and deploy your site to GitLab Pages.
- 3. Visit your project's **Settings > Pages** to see your **website link**, and click on it. Bam! Your website is live! :)

_Further steps (optional):_

- 4. Remove the [fork relationship](getting_started_part_two.md#fork-a-project-to-get-started-from)
(_You don't need the relationship unless you intent to contribute back to the example project you forked from_).
- 5. Make it a [user/group website](getting_started_part_one.md#user-and-group-websites)

**Watch a video with the steps above: https://www.youtube.com/watch?v=TWqh9MtT4Bg**

_Advanced options:_

- [Use a custom domain](getting_started_part_three.md#adding-your-custom-domain-to-gitlab-pages)
- Apply [SSL/TLS certification](getting_started_part_three.md#ssl-tls-certificates) to your custom domain

## How Does It Work?

With GitLab Pages you can create [static websites](getting_started_part_one.md#what-you-need-to-know-before-getting-started)
for your GitLab projects, groups, or user accounts.

It supports plain static content, such as HTML, and **all** [static site generators (SSGs)](https://about.gitlab.com/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/), such as Jekyll, Middleman, Hexo, Hugo, and Pelican.

Connect as many custom domains as you like and bring your own TLS certificate
to secure them.

Your files live in a project [repository](../repository/index.md) on GitLab.
[GitLab CI](../../../ci/README.md) picks up those files and makes them available at, typically,
`http://<username>.gilab.io/<projectname>`. Please read through the docs on 
[GitLab Pages domains](getting_started_part_one.md#gitlab-pages-domain) for more info.

## Explore GitLab Pages

Read the following tutorials to know more about:

- [Static websites and GitLab Pages domains](getting_started_part_one.md): Understand what is a static website, and how GitLab Pages default domains work
- [Projects for GitLab Pages and URL structure](getting_started_part_two.md): Forking projects and creating new ones from scratch, understanding URLs structure and baseurls
- [GitLab Pages custom domains and SSL/TLS Certificates](getting_started_part_three.md): How to add custom domains and subdomains to your website, configure DNS records, and SSL/TLS certificates
- [Creating and Tweaking GitLab CI/CD for GitLab Pages](getting_started_part_four.md): Understand how to create your own `.gitlab-ci.yml` for your site
- [Technical aspects, custom 404 pages, limitations](introduction.md)
- [Hosting on GitLab.com with GitLab Pages](https://about.gitlab.com/2016/04/07/gitlab-pages-setup/) (outdated)

_Blog posts series about Static Site Generators (SSGs):_

- [SSGs part 1: Static vs dynamic websites](https://about.gitlab.com/2016/06/03/ssg-overview-gitlab-pages-part-1-dynamic-x-static/)
- [SSGs part 2: Modern static site generators](https://about.gitlab.com/2016/06/10/ssg-overview-gitlab-pages-part-2/)
- [SSGs part 3: Build any SSG site with GitLab Pages](https://about.gitlab.com/2016/06/17/ssg-overview-gitlab-pages-part-3-examples-ci/)

_Blog posts for securing GitLab Pages custom domains with SSL/TLS certificates:_

- [CloudFlare](https://about.gitlab.com/2017/02/07/setting-up-gitlab-pages-with-cloudflare-certificates/)
- [Let's Encrypt](https://about.gitlab.com/2016/04/11/tutorial-securing-your-gitlab-pages-with-tls-and-letsencrypt/) (outdated)

## Advanced use

- [Posting to your GitLab Pages blog from iOS](https://about.gitlab.com/2016/08/19/posting-to-your-gitlab-pages-blog-from-ios/)
- [GitLab CI: Run jobs sequentially, in parallel, or build a custom pipeline](https://about.gitlab.com/2016/07/29/the-basics-of-gitlab-ci/)
- [GitLab CI: Deployment & environments](https://about.gitlab.com/2016/08/26/ci-deployment-and-environments/)
- [Building a new GitLab docs site with Nanoc, GitLab CI, and GitLab Pages](https://about.gitlab.com/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/)
- [Publish code coverage reports with GitLab Pages](https://about.gitlab.com/2016/11/03/publish-code-coverage-report-with-gitlab-pages/)

## Admin GitLab Pages for CE and EE

Enable and configure GitLab Pages on your own instance (GitLab Community Edition and Enterprise Editions) with
the [admin guide](../../../administration/pages/index.md).

**Watch the video: https://www.youtube.com/watch?v=dD8c7WNcc6s**

## More information about GitLab Pages

- For an overview, visit the [feature webpage](https://about.gitlab.com/features/pages/)
- Announcement (2016-12-24): ["We're bringing GitLab Pages to CE"](https://about.gitlab.com/2016/12/24/were-bringing-gitlab-pages-to-community-edition/)
- Announcement (2017-03-06): ["We are changing the IP of GitLab Pages on GitLab.com"](https://about.gitlab.com/2017/03/06/we-are-changing-the-ip-of-gitlab-pages-on-gitlab-com/)
