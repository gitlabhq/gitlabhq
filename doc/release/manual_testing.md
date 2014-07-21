# GitLab QA

## Login
- Regular account login
- LDAP login
Use the [support document](https://docs.google.com/document/d/1cAHvbdFE6zR5WY-zhn3HsDcACssJE8Cav6WeYq3oCkM/edit#heading=h.2x3u50ukp87w) for the ldap settings.

## Forks
- fork group project
- push changes to fork
- submit merge request to origin project
- accept merge request

## Git
- add, remove ssh key
- git clone, git push over ssh
- git clone, git push over http (with both regular and ldap accounts)

## Project
- create project
- create project using import repo
- transfer project
- rename repo path
- add/remove project member
- remove project
- create git branch with UI
- create git tag with UI

## Web editor
- create, edit, remove file in web UI

## Group
- create group
- create project in group
- add/remove group member
- remove group

## Markdown
- Visit / clone [relative links repository](https://dev.gitlab.org/samples/relative-links/tree/master) and see if the links are linking to the correct documents in the repository
- Check if images are rendered in the md
- Click on a [directory link](https://dev.gitlab.org/samples/relative-links/tree/master/documents) and see if it correctly takes to the tree view
- Click on a [file link](https://dev.gitlab.org/samples/relative-links/blob/master/documents/0.md) and see if it correctly takes to the blob view
- Check if the links in the README when viewed as a [blob](https://dev.gitlab.org/samples/relative-links/blob/master/README.md) are correct
- Select the "markdown" branch and check if all links point to the files within the markdown branch

## Syntax highlighting
- Visit/clone [language highlight repository](https://dev.gitlab.org/samples/languages-highlight)
- Check for obvious errors in highlighting

## Upgrader
- Upgrade from the previous release
- Run the upgrader script in this release (it should not break)

## Rake tasks
- Check if rake gitlab:check is updated and works
- Check if rake gitlab:env:info is updated and works
