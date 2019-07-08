# Dependency Scanning Analyzers **(ULTIMATE)**

Dependency Scanning relies on underlying third party tools that are wrapped into
what we call "Analyzers". An analyzer is a
[dedicated project](https://gitlab.com/gitlab-org/security-products/analyzers)
that wraps a particular tool to:

- Expose its detection logic.
- Handle its execution.
- Convert its output to the common format.

This is achieved by implementing the [common API](https://gitlab.com/gitlab-org/security-products/analyzers/common).

Dependency Scanning supports the following official analyzers:

- [`bundler-audit`](https://gitlab.com/gitlab-org/security-products/analyzers/bundler-audit)
- [`gemnasium`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)
- [`gemnasium-maven`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven)
- [`gemnasium-python`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python)
- [`retire.js`](https://gitlab.com/gitlab-org/security-products/analyzers/retire.js)

The analyzers are published as Docker images that Dependency Scanning will use
to launch dedicated containers for each analysis.

Dependency Scanning is pre-configured with a set of **default images** that are
maintained by GitLab, but users can also integrate their own **custom images**.

## Official default analyzers

Any custom change to the official analyzers can be achieved by using an
[environment variable in your `.gitlab-ci.yml`](index.md#customizing-the-dependency-scanning-settings).

### Using a custom Docker mirror

You can switch to a custom Docker registry that provides the official analyzer
images under a different prefix. For instance, the following instructs Dependency
Scanning to pull `my-docker-registry/gl-images/gemnasium`
instead of `registry.gitlab.com/gitlab-org/security-products/analyzers/gemnasium`.
In `.gitlab-ci.yml` define:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_ANALYZER_IMAGE_PREFIX: my-docker-registry/gl-images
```

This configuration requires that your custom registry provides images for all
the official analyzers.

### Selecting specific analyzers

You can select the official analyzers you want to run. Here's how to enable
`bundler-audit` and `gemnasium` while disabling all the other default ones.
In `.gitlab-ci.yml` define:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_DEFAULT_ANALYZERS: "bundler-audit,gemnasium"
```

`bundler-audit` runs first. When merging the reports, Dependency Scanning will
remove the duplicates and will keep the `bundler-audit` entries.

### Disabling default analyzers

Setting `DS_DEFAULT_ANALYZERS` to an empty string will disable all the official
default analyzers. In `.gitlab-ci.yml` define:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_DEFAULT_ANALYZERS: ""
```

That's needed when one totally relies on [custom analyzers](#custom-analyzers).

## Custom analyzers

You can provide your own analyzers as a comma separated list of Docker images.
Here's how to add `analyzers/nugget` and `analyzers/perl` to the default images.
In `.gitlab-ci.yml` define:

```yaml
include:
  template: Dependency-Scanning.gitlab-ci.yml

variables:
  DS_ANALYZER_IMAGES: "my-docker-registry/analyzers/nugget,amy-docker-registry/nalyzers/perl"
```

The values must be the full path to the container registry images,
like what you would feed to the `docker pull` command.

NOTE: **Note:**
This configuration doesn't benefit from the integrated detection step. Dependency
Scanning has to fetch and spawn each Docker image to establish whether the
custom analyzer can scan the source code.

## Analyzers data

The following table lists the data available for each official analyzer.

| Property \ Tool                       |      Gemnasium     |    bundler-audit   |     Retire.js      |
|---------------------------------------|:------------------:|:------------------:|:------------------:|
| Severity                              | 𐄂                  | ✓                  | ✓                  |
| Title                                 | ✓                  | ✓                  | ✓                  |
| File                                  | ✓                  | ⚠                  | ✓                  |
| Start line                            | 𐄂                  | 𐄂                  | 𐄂                  |
| End line                              | 𐄂                  | 𐄂                  | 𐄂                  |
| External ID (e.g., CVE)               | ✓                  | ✓                  | ⚠                  |
| URLs                                  | ✓                  | ✓                  | ✓                  |
| Internal doc/explanation              | ✓                  | 𐄂                  | 𐄂                  |
| Solution                              | ✓                  | ✓                  | 𐄂                  |
| Confidence                            | 𐄂                  | 𐄂                  | 𐄂                  |
| Affected item (e.g. class or package) | ✓                  | ✓                  | ✓                  |
| Source code extract                   | 𐄂                  | 𐄂                  | 𐄂                  |
| Internal ID                           | ✓                  | 𐄂                  | 𐄂                  |
| Date                                  | ✓                  | 𐄂                  | 𐄂                  |
| Credits                               | ✓                  | 𐄂                  | 𐄂                  |

- ✓ => we have that data
- ⚠ => we have that data but it's partially reliable, or we need to extract that data from unstructured content
- 𐄂 => we don't have that data or it would need to develop specific or inefficient/unreliable logic to obtain it.

The values provided by these tools are heterogeneous so they are sometimes
normalized into common values (e.g., `severity`, `confidence`, etc).
