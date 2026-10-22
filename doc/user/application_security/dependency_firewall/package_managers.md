---
stage: Security Risk Management
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Package managers
description: Run Java, Node.js, Python, and Ruby package managers through the dependency firewall.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

To run a package manager through the dependency firewall, prefix its command with
`glab dependency-firewall`, or its shorter alias `glab df`. Every argument after the command
name is forwarded unchanged.

No registry configuration is needed. For how the commands work, see
[Use the GitLab CLI](gitlab_cli.md).

## Supported commands

| Ecosystem | Command | Package manager |
|-----------|---------|-----------------|
| Java | `glab df maven` | Maven (`mvn`) |
| Java | `glab df gradle` | Gradle |
| Node.js | `glab df npm` | npm |
| Node.js | `glab df pnpm` | pnpm |
| Node.js | `glab df yarn` | Yarn |
| Python | `glab df pip` | pip |
| Python | `glab df uv` | `uv` |
| Python | `glab df poetry` | Poetry |
| Python | `glab df pipenv` | pipenv |
| Python | `glab df twine` | twine |
| Ruby | `glab df gem` | RubyGems (`gem`) |
| Ruby | `glab df bundle` | Bundler |

## Java

Java build tools cache resolved artifacts locally. Maven caches in `~/.m2/repository/` and
Gradle caches in `~/.gradle/caches/`. A cached artifact is never fetched, so the firewall does
not evaluate it. Clear the cache to force re-evaluation.

### Maven

```shell
glab df maven verify
glab df maven dependency:resolve
glab df maven deploy
```

The firewall evaluates `.jar`, `.pom`, `.aar`, and `.war` files, including timestamped snapshot
files for Maven snapshot versions. It does not evaluate checksum and signature files (`.md5`,
`.sha1`, `.sha256`, `.sha512`, and `.asc`).

`glab df maven` runs the `mvn` command from your `PATH`. The Maven Wrapper (`./mvnw`) is not
supported.

### Gradle

```shell
glab df gradle build
glab df gradle dependencies
```

`glab df gradle` runs the `gradle` command from your `PATH`. The Gradle Wrapper (`./gradlew`) is
not supported.

## Node.js

```shell
glab df npm install
glab df npm install left-pad
glab df npm ci
glab df npm publish
```

pnpm and Yarn take the same form:

```shell
glab df pnpm install
glab df pnpm add left-pad
```

```shell
glab df yarn install
glab df yarn add left-pad
```

Both Yarn Berry (2 and later) and Yarn Classic (1.x) are supported.

## Python

```shell
glab df pip install requests
glab df pip install -r requirements.txt
```

`uv`, Poetry, and pipenv take the same form:

```shell
glab df uv pip install requests
glab df uv sync
```

```shell
glab df poetry add requests
glab df poetry install
```

```shell
glab df pipenv install requests
```

Use twine to evaluate packages as you publish them:

```shell
glab df twine upload dist/*
```

Python package names are normalized according to PEP 503 before evaluation, so `Flask_Login`
and `flask-login` are treated as the same package.

## Ruby

```shell
glab df gem install rake
glab df gem fetch rake
```

```shell
glab df bundle install
glab df bundle update
```

Bundler installs from `vendor/bundle/` when a bundle is already vendored. Clear that directory,
or run `bundle install --force`, to force re-evaluation.

## Related topics

- [Use the GitLab CLI](gitlab_cli.md)
- [Check a single package](gitlab_cli.md#check-a-single-package)
- [Dependency firewall](_index.md)
