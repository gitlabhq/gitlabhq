## Test a Scala application

This example demonstrates the integration of Gitlab CI with Scala
applications using SBT. Checkout the example
[project](https://gitlab.com/gitlab-examples/scala-sbt) and
[build status](https://gitlab.com/gitlab-examples/scala-sbt/builds).

### Add `.gitlab-ci.yml` file to project

The following `.gitlab-ci.yml` should be added in the root of your
repository to trigger CI:

``` yaml
image: java:8

before_script:
  - apt-get update -y
  - apt-get install apt-transport-https -y
  # Install SBT
  - echo "deb http://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
  - apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
  - apt-get update -y
  - apt-get install sbt -y
  - sbt sbt-version

test:
  script:
    - sbt clean coverage test coverageReport
```

The `before_script` installs [SBT](http://www.scala-sbt.org/) and
displays the version that is being used. The `test` stage executes SBT
to compile and test the project.
[scoverage](https://github.com/scoverage/sbt-scoverage) is used as an SBT
plugin to measure test coverage.

You can use other versions of Scala and SBT by defining them in
`build.sbt`.

### Display test coverage in build

Add the `Coverage was \[\d+.\d+\%\]` regular expression in the
**Settings > Edit Project > Test coverage parsing** project setting to
retrieve the test coverage rate from the build trace and have it
displayed with your builds.

**Builds** must be enabled for this option to appear.
