---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Monorepo package management workflows

One project or Git repository can contain multiple different subprojects or submodules that are all
packaged and published individually.

## Publishing different packages to the parent project

The number and name of packages you can publish to one project is not limited.
You can accomplish this by setting up different configuration files for each
package. See the documentation for the package manager of your choice since
each has its own specific files and instructions to follow to publish
a given package.

The example here uses [NPM](../npm_registry/index.md).
In this example, `MyProject` is the parent project. It contains a sub-project `Foo` in the
`components` directory:

```plaintext
MyProject/
  |- src/
  |   |- components/
  |       |- Foo/
  |- package.json
```

The goal is to publish the packages for `MyProject` and `Foo`. Following the instructions in the
[GitLab NPM registry documentation](../npm_registry/index.md),
you can publish `MyProject` by modifying the `package.json` file with a `publishConfig` section,
and by doing one of the following:

- Modify your local NPM configuration with CLI commands like `npm config set`.
- Save a `.npmrc` file in the root of the project specifying these configuration settings.

If you follow the instructions, you can publish `MyProject` by running `npm publish` from the root
directory.

Publishing `Foo` is almost exactly the same. Simply follow the same steps while in the `Foo`
directory. `Foo` needs its own `package.json` file, which you can add manually by using `npm init`.
`Foo` also needs its own configuration settings. Since you are publishing to the same place, if you
used `npm config set` to set the registry for the parent project, then no additional setup is
necessary. If you used an `.npmrc` file, you need an additional `.npmrc` file in the `Foo` directory.
Be sure to add `.npmrc` files to the `.gitignore` file or use environment variables in place of your
access tokens to prevent your tokens from being exposed. This `.npmrc` file can be identical to the
one you used in `MyProject`. You can now run `npm publish` from the `Foo` directory and you can
publish `Foo` separately from `MyProject`.

You could follow a similar process for Conan packages. However, instead of `.npmrc` and
`package.json`, you have `conanfile.py` in multiple locations within the project.

## Publishing to other projects

A package is associated with a project on GitLab, but the package does not need to be associated
with the code in that project. When configuring NPM or Maven, you only use the `Project ID` to set
the registry URL that the package uploads to. If you set this to any project that you have access to
and update any other configuration similarly depending on the package type, your packages are
published to that project. This means you can publish multiple packages to one project, even if
their code does not exist in the same place. See the [project registry workflow documentation](project_registry.md)
for more information.
