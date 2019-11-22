# SAST Analyzers **(ULTIMATE)**

SAST relies on underlying third party tools that are wrapped into what we call
"Analyzers". An analyzer is a
[dedicated project](https://gitlab.com/gitlab-org/security-products/analyzers)
that wraps a particular tool to:

- Expose its detection logic.
- Handle its execution.
- Convert its output to the common format.

This is achieved by implementing the [common API](https://gitlab.com/gitlab-org/security-products/analyzers/common).

SAST supports the following official analyzers:

- [`bandit`](https://gitlab.com/gitlab-org/security-products/analyzers/bandit) (Bandit)
- [`brakeman`](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman) (Brakeman)
- [`eslint`](https://gitlab.com/gitlab-org/security-products/analyzers/eslint) (ESLint (JavaScript and React))
- [`flawfinder`](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder) (Flawfinder)
- [`gosec`](https://gitlab.com/gitlab-org/security-products/analyzers/gosec) (Gosec)
- [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec) (Kubesec)
- [`nodejs-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan) (NodeJsScan)
- [`phpcs-security-audit`](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit) (PHP CS security-audit)
- [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex) (PMD (Apex only))
- [`secrets`](https://gitlab.com/gitlab-org/security-products/analyzers/secrets) (Secrets (Gitleaks & TruffleHog secret detectors))
- [`security-code-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan) (Security Code Scan (.NET))
- [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow) (Sobelow (Elixir Phoenix))
- [`spotbugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) (SpotBugs with the Find Sec Bugs plugin (Ant, Gradle and wrapper, Grails, Maven and wrapper, SBT))
- [`tslint`](https://gitlab.com/gitlab-org/security-products/analyzers/tslint) (TSLint (TypeScript))

The analyzers are published as Docker images that SAST will use to launch
dedicated containers for each analysis.

SAST is pre-configured with a set of **default images** that are maintained by
GitLab, but users can also integrate their own **custom images**.

## Official default analyzers

Any custom change to the official analyzers can be achieved by using an
[environment variable in your `.gitlab-ci.yml`](index.md#customizing-the-sast-settings).

### Using a custom Docker mirror

You can switch to a custom Docker registry that provides the official analyzer
images under a different prefix. For instance, the following instructs
SAST to pull `my-docker-registry/gl-images/bandit`
instead of `registry.gitlab.com/gitlab-org/security-products/analyzers/bandit`.
In `.gitlab-ci.yml` define:

```yaml
include:
  template: SAST.gitlab-ci.yml

variables:
  SAST_ANALYZER_IMAGE_PREFIX: my-docker-registry/gl-images
```

This configuration requires that your custom registry provides images for all
the official analyzers.

### Selecting specific analyzers

You can select the official analyzers you want to run. Here's how to enable
`bandit` and `flawfinder` while disabling all the other default ones.
In `.gitlab-ci.yml` define:

```yaml
include:
  template: SAST.gitlab-ci.yml

variables:
  SAST_DEFAULT_ANALYZERS: "bandit,flawfinder"
```

`bandit` runs first. When merging the reports, SAST will
remove the duplicates and will keep the `bandit` entries.

### Disabling default analyzers

Setting `SAST_DEFAULT_ANALYZERS` to an empty string will disable all the official
default analyzers. In `.gitlab-ci.yml` define:

```yaml
include:
  template: SAST.gitlab-ci.yml

variables:
  SAST_DEFAULT_ANALYZERS: ""
```

That's needed when one totally relies on [custom analyzers](#custom-analyzers).

## Custom Analyzers

You can provide your own analyzers as a comma separated list of Docker images.
Here's how to add `analyzers/csharp` and `analyzers/perl` to the default images:
In `.gitlab-ci.yml` define:

```yaml
include:
  template: SAST.gitlab-ci.yml

variables:
  SAST_ANALYZER_IMAGES: "my-docker-registry/analyzers/csharp,amy-docker-registry/analyzers/perl"
```

The values must be the full path to the container registry images,
like what you would feed to the `docker pull` command.

NOTE: **Note:**
This configuration doesn't benefit from the integrated detection step.
SAST has to fetch and spawn each Docker image to establish whether the
custom analyzer can scan the source code.

CAUTION: **Caution:**
Custom analyzers are not spawned automatically when [Docker In Docker](index.md#disabling-docker-in-docker-for-sast) is disabled.

## Analyzers Data

| Property \ Tool                         | Apex                 | Bandit               | Brakeman             | ESLint security      | Find Sec Bugs        | Flawfinder           | Go AST Scanner       | Kubesec Scanner      | NodeJsScan           | Php CS Security Audit   | Security code Scan (.NET)   | Sobelow            | TSLint Security    |
| --------------------------------------- | :------------------: | :------------------: | :------------------: | :------------------: | :------------------: | :------------------: | :------------------: | :------------------: | :------------------: | :---------------------: | :-------------------------: | :----------------: | :-------------:    |
| Severity                                | ✓                    | ✓                    | 𐄂                    | 𐄂                    | ✓                    | 𐄂                    | ✓                    | ✓                    | 𐄂                    | ✓                       | 𐄂                           | 𐄂                  | ✓                  |
| Title                                   | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                       | ✓                           | ✓                  | ✓                  |
| Description                             | ✓                    | 𐄂                    | 𐄂                    | ✓                    | ✓                    | 𐄂                    | 𐄂                    | ✓                    | ✓                    | 𐄂                       | 𐄂                           | ✓                  | ✓                  |
| File                                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                       | ✓                           | ✓                  | ✓                  |
| Start line                              | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | 𐄂                    | ✓                    | ✓                       | ✓                           | ✓                  | ✓                  |
| End line                                | ✓                    | ✓                    | 𐄂                    | ✓                    | ✓                    | 𐄂                    | 𐄂                    | 𐄂                    | 𐄂                    | 𐄂                       | 𐄂                           | 𐄂                  | ✓                  |
| Start column                            | ✓                    | 𐄂                    | 𐄂                    | ✓                    | ✓                    | ✓                    | ✓                    | 𐄂                    | 𐄂                    | ✓                       | ✓                           | 𐄂                  | ✓                  |
| End column                              | ✓                    | 𐄂                    | 𐄂                    | ✓                    | ✓                    | 𐄂                    | 𐄂                    | 𐄂                    | 𐄂                    | 𐄂                       | 𐄂                           | 𐄂                  | ✓                  |
| External id (e.g. CVE)                  | 𐄂                    | 𐄂                    | ⚠                    | 𐄂                    | ⚠                    | ✓                    | 𐄂                    | 𐄂                    | 𐄂                    | 𐄂                       | 𐄂                           | 𐄂                  | 𐄂                  |
| URLs                                    | ✓                    | 𐄂                    | ✓                    | 𐄂                    | ⚠                    | 𐄂                    | ⚠                    | 𐄂                    | 𐄂                    | 𐄂                       | 𐄂                           | 𐄂                  | 𐄂                  |
| Internal doc/explanation                | ✓                    | ⚠                    | ✓                    | 𐄂                    | ✓                    | 𐄂                    | 𐄂                    | 𐄂                    | 𐄂                    | 𐄂                       | 𐄂                           | ✓                  | 𐄂                  |
| Solution                                | ✓                    | 𐄂                    | 𐄂                    | 𐄂                    | ⚠                    | ✓                    | 𐄂                    | 𐄂                    | 𐄂                    | 𐄂                       | 𐄂                           | 𐄂                  | 𐄂                  |
| Affected item (e.g. class or package)   | ✓                    | 𐄂                    | ✓                    | 𐄂                    | ✓                    | ✓                    | 𐄂                    | ✓                    | 𐄂                    | 𐄂                       | 𐄂                           | 𐄂                  | 𐄂                  |
| Confidence                              | 𐄂                    | ✓                    | ✓                    | 𐄂                    | ✓                    | ✓                    | ✓                    | ✓                    | 𐄂                    | 𐄂                       | 𐄂                           | ✓                  | 𐄂                  |
| Source code extract                     | 𐄂                    | ✓                    | ✓                    | ✓                    | 𐄂                    | ✓                    | ✓                    | 𐄂                    | 𐄂                    | 𐄂                       | 𐄂                           | 𐄂                  | 𐄂                  |
| Internal ID                             | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | ✓                    | 𐄂                    | 𐄂                    | ✓                       | ✓                           | ✓                  | ✓                  |

- ✓ => we have that data
- ⚠ => we have that data but it's partially reliable, or we need to extract it from unstructured content
- 𐄂 => we don't have that data or it would need to develop specific or inefficient/unreliable logic to obtain it.

The values provided by these tools are heterogeneous so they are sometimes
normalized into common values (e.g., `severity`, `confidence`, etc).
