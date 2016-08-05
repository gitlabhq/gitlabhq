# Project Pipeline Settings

This section covers project level pipeline settings.

## Clone vs Fetch

You can select to either `git fetch` or `git clone` your project before
each build. Fetching is faster as you are only pulling recent updates
but cloning has the advantage of giving you a clean project.

## Timeout

This is the total time in minutes that a build is allowed to run. The
default is 222 minutes.

## Custom CI Config File

>  - [Introduced][ce-15041] in GitLab 8.13.

By default we look for the `.gitlab-ci.yml` file in the projects root
directory. If you require a different location **within** the repository 
you can set a custom filepath that will be used to lookup the config file, 
this filepath should be **relative** to the root.

Here are some valid examples:

> * .gitlab-ci.yml
> * .my-custom-file.yml
> * my/path/.gitlab-ci.yml
> * my/path/.my-custom-file.yml

## Test Coverage Parsing

As each testing framework has different output, you need to specify a
regex to extract the summary code coverage information from your test
commands output. The regex will be applied to the `STDOUT` of your command.

Here are some examples of popular testing frameworks/languages:

> * Simplecov (Ruby) - `\(\d+.\d+\%\) covered`
> * pytest-cov (Python) - `\d+\%\s*$`
> * phpunit --coverage-text --colors=never (PHP) - `^\s*Lines:\s*\d+.\d+\%`
> * gcovr (C/C++) - `^TOTAL.*\s+(\d+\%)$`
> * tap --coverage-report=text-summary (Node.js) - `^Statements\s*:\s*([^%]+)`


## Public Pipelines

You can select if the pipeline should be publicly accessible or not.

## Runners Token

This is a secure token that is used to checkout the project from the
Gitlab instance. This should be a cryptographically secure random hash.
