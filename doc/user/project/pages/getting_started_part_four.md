---
last_updated: 2018-02-16
author: Marcia Ramos
author_gitlab: marcia
level: intermediate
article_type: user guide
date: 2017-02-22
---

# Creating and Tweaking GitLab CI/CD for GitLab Pages

[GitLab CI](https://about.gitlab.com/gitlab-ci/) serves
numerous purposes, to build, test, and deploy your app
from GitLab through
[Continuous Integration, Continuous Delivery, and Continuous Deployment](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/)
methods. You will need it to build your website with GitLab Pages,
and deploy it to the Pages server.

To implement GitLab CI/CD, the first thing we need is a configuration
file called `.gitlab-ci.yml` placed at your website's root directory.

What this file actually does is telling the
[GitLab Runner](https://docs.gitlab.com/runner/) to run scripts
as you would do from the command line. The Runner acts as your
terminal. GitLab CI/CD tells the Runner which commands to run.
Both are built-in in GitLab, and you don't need to set up
anything for them to work.

Explaining [every detail of GitLab CI](https://docs.gitlab.com/ce/ci/yaml/README.html)
and GitLab Runner is out of the scope of this guide, but we'll
need to understand just a few things to be able to write our own
`.gitlab-ci.yml` or tweak an existing one. It's an
[Yaml](http://docs.ansible.com/ansible/YAMLSyntax.html) file,
with its own syntax. You can always check your CI syntax with
the [GitLab CI Lint Tool](https://gitlab.com/ci/lint).

## Practical example

Let's consider you have a [Jekyll](https://jekyllrb.com/) site.
To build it locally, you would open your terminal, and run `jekyll build`.
Of course, before building it, you had to install Jekyll in your computer.
For that, you had to open your terminal and run `gem install jekyll`.
Right? GitLab CI + GitLab Runner do the same thing. But you need to
write in the `.gitlab-ci.yml` the script you want to run so
GitLab Runner will do it for you. It looks more complicated then it
is. What you need to tell the Runner:

```
$ gem install jekyll
$ jekyll build
```

### Script

To transpose this script to Yaml, it would be like this:

```yaml
script:
  - gem install jekyll
  - jekyll build
```

### Job

So far so good. Now, each `script`, in GitLab is organized by
a `job`, which is a bunch of scripts and settings you want to
apply to that specific task.

```yaml
job:
  script:
  - gem install jekyll
  - jekyll build
```

For GitLab Pages, this `job` has a specific name, called `pages`,
which tells the Runner you want that task to deploy your website
with GitLab Pages:

```yaml
pages:
  script:
  - gem install jekyll
  - jekyll build
```

### The `public` directory

We also need to tell Jekyll where do you want the website to build,
and GitLab Pages will only consider files in a directory called `public`.
To do that with Jekyll, we need to add a flag specifying the
[destination (`-d`)](https://jekyllrb.com/docs/usage/) of the
built website: `jekyll build -d public`. Of course, we need
to tell this to our Runner:

```yaml
pages:
  script:
  - gem install jekyll
  - jekyll build -d public
```

### Artifacts

We also need to tell the Runner that this _job_ generates
_artifacts_, which is the site built by Jekyll.
Where are these artifacts stored? In the `public` directory:

```yaml
pages:
  script:
  - gem install jekyll
  - jekyll build -d public
  artifacts:
    paths:
    - public
```

The script above would be enough to build your Jekyll
site with GitLab Pages. But, from Jekyll 3.4.0 on, its default
template originated by `jekyll new project` requires
[Bundler](http://bundler.io/) to install Jekyll dependencies
and the default theme. To adjust our script to meet these new
requirements, we only need to install and build Jekyll with Bundler:

```yaml
pages:
  script:
  - bundle install
  - bundle exec jekyll build -d public
  artifacts:
    paths:
    - public
```

That's it! A `.gitlab-ci.yml` with the content above would deploy
your Jekyll 3.4.0 site with GitLab Pages. This is the minimum
configuration for our example. On the steps below, we'll refine
the script by adding extra options to our GitLab CI.

Artifacts will be automatically deleted once GitLab Pages got deployed.
You can preserve artifacts for limited time by specifying the expiry time.

### Image

At this point, you probably ask yourself: "okay, but to install Jekyll
I need Ruby. Where is Ruby on that script?". The answer is simple: the
first thing GitLab Runner will look for in your `.gitlab-ci.yml` is a
[Docker](https://www.docker.com/) image specifying what do you need in
your container to run that script:

```yaml
image: ruby:2.3

pages:
  script:
  - bundle install
  - bundle exec jekyll build -d public
  artifacts:
    paths:
    - public
```

In this case, you're telling the Runner to pull this image, which
contains Ruby 2.3 as part of its file system. When you don't specify
this image in your configuration, the Runner will use a default
image, which is Ruby 2.1.

If your SSG needs [NodeJS](https://nodejs.org/) to build, you'll
need to specify which image you want to use, and this image should
contain NodeJS as part of its file system. E.g., for a
[Hexo](https://gitlab.com/pages/hexo) site, you can use `image: node:4.2.2`.

>**Note:**
We're not trying to explain what a Docker image is,
we just need to introduce the concept with a minimum viable
explanation. To know more about Docker images, please visit
their website or take a look at a
[summarized explanation](http://paislee.io/how-to-automate-docker-deployments/) here.

Let's go a little further.

### Branching

If you use GitLab as a version control platform, you will have your
branching strategy to work on your project. Meaning, you will have
other branches in your project, but you'll want only pushes to the
default branch (usually `master`) to be deployed to your website.
To do that, we need to add another line to our CI, telling the Runner
to only perform that _job_ called `pages` on the `master` branch `only`:

```yaml
image: ruby:2.3

pages:
  script:
  - bundle install
  - bundle exec jekyll build -d public
  artifacts:
    paths:
    - public
  only:
  - master
```

### Stages

Another interesting concept to keep in mind are build stages.
Your web app can pass through a lot of tests and other tasks
until it's deployed to staging or production environments.
There are three default stages on GitLab CI: build, test,
and deploy. To specify which stage your _job_ is running,
simply add another line to your CI:

```yaml
image: ruby:2.3

pages:
  stage: deploy
  script:
  - bundle install
  - bundle exec jekyll build -d public
  artifacts:
    paths:
    - public
  only:
  - master
```

You might ask yourself: "why should I bother with stages
at all?" Well, let's say you want to be able to test your
script and check the built site before deploying your site
to production. You want to run the test exactly as your
script will do when you push to `master`. It's simple,
let's add another task (_job_) to our CI, telling it to
test every push to other branches, `except` the `master` branch:

```yaml
image: ruby:2.3

pages:
  stage: deploy
  script:
  - bundle install
  - bundle exec jekyll build -d public
  artifacts:
    paths:
    - public
  only:
  - master

test:
  stage: test
  script:
  - bundle install
  - bundle exec jekyll build -d test
  artifacts:
    paths:
    - test
  except:
  - master
```

The `test` job is running on the stage `test`, Jekyll
will build the site in a directory called `test`, and
this job will affect all the branches except `master`.

The best benefit of applying _stages_ to different
_jobs_ is that every job in the same stage builds in
parallel. So, if your web app needs more than one test
before being deployed, you can run all your test at the
same time, it's not necessary to wait one test to finish
to run the other. Of course, this is just a brief
introduction of GitLab CI and GitLab Runner, which are
tools much more powerful than that. This is what you
need to be able to create and tweak your builds for
your GitLab Pages site.

### Before Script

To avoid running the same script multiple times across
your _jobs_, you can add the parameter `before_script`,
in which you specify which commands you want to run for
every single _job_. In our example, notice that we run
`bundle install` for both jobs, `pages` and `test`.
We don't need to repeat it:

```yaml
image: ruby:2.3

before_script:
  - bundle install

pages:
  stage: deploy
  script:
  - bundle exec jekyll build -d public
  artifacts:
    paths:
    - public
  only:
  - master

test:
  stage: test
  script:
  - bundle exec jekyll build -d test
  artifacts:
    paths:
    - test
  except:
  - master
```

### Caching Dependencies

If you want to cache the installation files for your
projects dependencies, for building faster, you can
use the parameter `cache`. For this example, we'll
cache Jekyll dependencies in a `vendor` directory
when we run `bundle install`:

```yaml
image: ruby:2.3

cache:
  paths:
  - vendor/

before_script:
  - bundle install --path vendor

pages:
  stage: deploy
  script:
  - bundle exec jekyll build -d public
  artifacts:
    paths:
    - public
  only:
  - master

test:
  stage: test
  script:
  - bundle exec jekyll build -d test
  artifacts:
    paths:
    - test
  except:
  - master
```

For this specific case, we need to exclude `/vendor`
from Jekyll `_config.yml` file, otherwise Jekyll will
understand it as a regular directory to build
together with the site:

```yml
exclude:
  - vendor
```

There we go! Now our GitLab CI not only builds our website,
but also **continuously test** pushes to feature-branches,
**caches** dependencies installed with Bundler, and
**continuously deploy** every push to the `master` branch.

## Advanced GitLab CI for GitLab Pages

What you can do with GitLab CI is pretty much up to your
creativity. Once you get used to it, you start creating
awesome scripts that automate most of tasks you'd do
manually in the past. Read through the
[documentation of GitLab CI](https://docs.gitlab.com/ce/ci/yaml/README.html)
to understand how to go even further on your scripts.

- On this blog post, understand the concept of
[using GitLab CI `environments` to deploy your
web app to staging and production](https://about.gitlab.com/2016/08/26/ci-deployment-and-environments/).
- On this post, learn [how to run jobs sequentially,
in parallel, or build a custom pipeline](https://about.gitlab.com/2016/07/29/the-basics-of-gitlab-ci/)
- On this blog post, we go through the process of
[pulling specific directories from different projects](https://about.gitlab.com/2016/12/07/building-a-new-gitlab-docs-site-with-nanoc-gitlab-ci-and-gitlab-pages/)
to deploy this website you're looking at, docs.gitlab.com.
- On this blog post, we teach you [how to use GitLab Pages to produce a code coverage report](https://about.gitlab.com/2016/11/03/publish-code-coverage-report-with-gitlab-pages/).
