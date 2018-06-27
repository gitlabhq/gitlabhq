# Dependencies

## Adding Dependencies.

GitLab uses `yarn` to manage dependencies. These dependencies are defined in
two groups within `package.json`, `dependencies` and `devDependencies`. For
our purposes, we consider anything that is required to compile our production
assets a "production" dependency. That is, anything required to run the
`webpack` script with `NODE_ENV=production`. Tools like `eslint`, `karma`, and
various plugins and tools used in development are considered `devDependencies`.
This distinction is used by omnibus to determine which dependencies it requires
when building GitLab.

Exceptions are made for some tools that we require in the
`gitlab:assets:compile` CI job such as `webpack-bundle-analyzer` to analyze our
production assets post-compile.

---

> TODO: Add Dependencies
