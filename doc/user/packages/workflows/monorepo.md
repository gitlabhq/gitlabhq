---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Monorepo package management workflows

Oftentimes, one project or Git repository may contain multiple different
sub-projects or submodules that all get packaged and published individually.

## Publishing different packages to the parent project

The number and name of packages you can publish to one project is not limited.
You can accomplish this by setting up different configuration files for each
package. See the documentation for the package manager of your choice since
each has its own specific files and instructions to follow to publish
a given package.

Here, we take a walk through how to do this with [NPM](../npm_registry/index.md).

Let us say we have a project structure like so:

```plaintext
MyProject/
  |- src/
  |   |- components/
  |       |- Foo/
  |- package.json
```

`MyProject` is the parent project, which contains a sub-project `Foo` in the
`components` directory. We would like to publish packages for both `MyProject`
as well as `Foo`.

Following the instructions in the
[GitLab NPM registry documentation](../npm_registry/index.md),
publishing `MyProject` consists of modifying the `package.json` file with a
`publishConfig` section, as well as either modifying your local NPM configuration with
CLI commands like `npm config set`, or saving a `.npmrc` file in the root of the
project specifying these configuration settings.

If you follow the instructions you can publish `MyProject` by running
`npm publish` from the root directory.

Publishing `Foo` is almost exactly the same, you simply have to follow the steps
while in the `Foo` directory. `Foo` needs its own `package.json` file,
which can be added manually or using `npm init`. It also needs its own
configuration settings. Since you are publishing to the same place, if you
used `npm config set` to set the registry for the parent project, then no
additional setup is necessary. If you used a `.npmrc` file, you need an
additional `.npmrc` file in the `Foo` directory (be sure to add `.npmrc` files
to the `.gitignore` file or use environment variables in place of your access
tokens to prevent them from being exposed). It can be identical to the
one you used in `MyProject`. You can now run `npm publish` from the `Foo`
directory and you can publish `Foo` separately from `MyProject`

A similar process could be followed for Conan packages, instead of dealing with
`.npmrc` and `package.json`, you just deal with `conanfile.py` in
multiple locations within the project.

## Publishing to other projects

A package is associated with a project on GitLab, but the package does not
need to be associated with the code in that project. Notice when configuring
NPM or Maven, you only use the `Project ID` to set the registry URL that the
package is to be uploaded to. If you set this to any project that you have
access to and update any other configuration similarly depending on the package type,
your packages are published to that project. This means you can publish
multiple packages to one project, even if their code does not exist in the same
place. See the [project registry workflow documentation](project_registry.md)
for more details.

## CI workflows for automating packaging

CI pipelines open an entire world of possibilities for dealing with the patterns
described in the previous sections. A common desire would be to publish
specific packages only if changes were made to those directories.

Using the example project above, this `gitlab-ci.yml` file publishes
`Foo` anytime changes are made to the `Foo` directory on the `master` branch,
and publish `MyPackage` anytime changes are made to anywhere _except_ the `Foo`
directory on the `master` branch.

```yaml
image: node:latest

stages:
  - build

build-foo-package:
  stage: build
  variables:
    PACKAGE: "Foo"
  script:
    - cd src/components/Foo
    - echo "Building $PACKAGE"
    - npm publish
  only:
    refs:
      - master
      - merge_requests
    changes:
      - "src/components/Foo/**/*"

build-my-project-package:
  stage: build
  variables:
    PACKAGE: "MyPackage"
  script:
    - echo "Building $PACKAGE"
    - npm publish
  only:
    refs:
      - master
      - merge_requests
  except:
    changes:
      - "src/components/Foo/**/*"
```
