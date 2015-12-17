# GitLab Pages

_**Note:** This feature was introduced in GitLab EE 8.3_

To start using GitLab Pages add to your project `.gitlab-ci.yml` the special
`pages` job. The example below is using [jekyll][] and assumes the created
HTML files are generated under the `public/` directory which resides under the
root directory of your Git repository.

```yaml
pages:
  image: jekyll
  script: jekyll build
  artifacts:
    paths:
    - public
```

- The pages are created when build artifacts for `pages` job are uploaded
- Pages serve the content under: http://group.pages.domain.com/project
- Pages can be used to serve the group page, special project named as host: group.pages.domain.com
- User can provide own 403 and 404 error pages by creating 403.html and 404.html in group page project
- Pages can be explicitly removed from the project by clicking Remove Pages in Project Settings
- The size of pages is limited by Application Setting: max pages size, which limits the maximum size of unpacked archive (default: 100MB)
- The public/ is extracted from artifacts and content is served as static pages
- Pages asynchronous worker use `dd` to limit the unpacked tar size
- Pages needs to be explicitly enabled and domain needs to be specified in gitlab.yml
- Pages are part of backups
- Pages notify the deployment status using Commit Status API
- Pages use a new sidekiq queue: pages
- Pages use a separate nginx config which needs to be explicitly added

## Examples

- Add example with stages. `test` using a linter tool, `deploy` in `pages`
- Add examples of more static tool generators

```yaml
image: jekyll

stages:
  - test
  - deploy

lint:
  script: jekyll build
  stage: test

pages:
  script: jekyll build
  stage: deploy
  artifacts:
    paths:
    - public
```

## Current limitations

- We currently support only http and port 80. It will be extended in the future.

[jekyll]: http://jekyllrb.com/
