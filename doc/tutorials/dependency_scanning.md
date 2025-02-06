---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Set up dependency scanning'
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com

Dependency Scanning can automatically find security vulnerabilities in your software dependencies
while you're developing and testing your applications. For example, dependency scanning lets you
know if your application uses an external (open source) library that is known to be vulnerable. You
can then take action to protect your application.

This tutorial shows you how to create a sample vulnerable application, then:

- How to detect, triage, and resolve vulnerabilities in the application's dependencies.
- How to detect vulnerabilities in a merge request.

To set up dependency scanning:

- [Create example application files](#create-example-application-files).
- [Triage the vulnerabilities](#triage-the-vulnerabilities).
- [Resolve the high severity vulnerability](#resolve-the-high-severity-vulnerability).
- [Test vulnerability detection in a merge request](#test-vulnerability-detection-in-a-merge-request).

## Before you begin

Make sure you have Gitpod enabled. Gitpod is an on-demand cloud development
environment. For details, see [Gitpod](../integration/gitpod.md). Alternatively you can use your
own development setup. In this case you need to have Yarn and Node.js installed.

## Create example application files

First, in a new project, create files to configure your pipeline, and add dependencies that can be
scanned for vulnerabilities.

1. Create a blank project, using the default values.

1. Create the following files in the `main` branch.

   Filename: `.gitlab-ci.yml`

   ```yaml
   stages:
   - build
   - test

   include:
   - template: Jobs/Dependency-Scanning.gitlab-ci.yml

   # override the dependency scanning job
   gemnasium-dependency_scanning:
     tags: [ saas-linux-large-amd64 ]
     rules:
       - if: $CI_COMMIT_BRANCH == "main"
       - if: $CI_MERGE_REQUEST_IID
   ```

   Filename: `index.js`

   ```javascript
   // Require the framework and instantiate it
   const fastify = require('fastify')({ logger: true })
   const path = require('path')
   //const fetch = require('node-fetch')

   fastify.register(require('fastify-static'), {
     root: path.join(__dirname, 'public'),
     prefix: '/'
   })

   fastify.register(require('./routes'), {
     message: "hello"
   })

   // fastify.register(require('fastify-redis'), { url: constants.redisUrl, /* other redis options */ })

   // Run the server!
   const start = async () => {
     try {
       await fastify.listen(8080, "0.0.0.0")
       fastify.log.info(`server listening on ${fastify.server.address().port}`)

     } catch (error) {
       fastify.log.error(error)
       //process.exit(1)
     }
   }
   start()
   ```

   Filename `package.json`

   ```json
   {
     "dependencies": {
       "fastify": "2.14.1",
       "fastify-static": "2.0.0"
     }
   }
   ```

   Filename `yarn.lock`

   Use the content shown in the [Yarn lockfile](#yarn-lock-file-content) section.

1. Go to **Build > Pipelines** and confirm that the latest pipeline completed successfully.

In the pipeline, dependency scanning runs and the vulnerabilities are detected automatically.

## Triage the vulnerabilities

The vulnerability report provides vital information on vulnerabilities. You would usually triage
vulnerabilities according to your organization's policies. For this tutorial, you'll dismiss the
medium severity vulnerabilities and confirm only the high severity vulnerability.

To triage the vulnerabilities:

1. Go to **Secure > Vulnerability report**.
1. Select each of the medium severity vulnerabilities by selecting the checkbox in each row.
1. From the **Set status** dropdown list select **Dismiss**. From the **Dismissal reason** dropdown
   list select **Used in tests**, add the comment "Used in tests", then select **Change status**.

   The medium severity vulnerabilities are filtered out of the view, leaving only the high
   severity vulnerability remaining.

1. Select the **High** vulnerability's description.

   The recommended solution is to upgrade the `fastify` package. You would usually investigate
   this further, but for this tutorial, you can consider this vulnerability confirmed.

1. From the **Status** dropdown list select **Confirm**, then select **Change status**.

## Resolve the high severity vulnerability

Only the high severity vulnerability remains to be resolved. From the triage step you know that you
need to upgrade the `fastify` package.

To fix the vulnerability:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the upper right, select **Edit > Gitpod** and open
   Gitpod in a new tab.
1. If you are prompted to, select **Continue with GitLab**, then select **Authorize**.
1. On the **New Workspace** page, select **Continue**.
1. In the **Terminal** pane, enter the following command to create a new branch.

   ```plaintext
   git checkout -b update_packages main
   ```

1. In the **Terminal** pane, run the command `yarn upgrade --latest`. This updates the project's
   dependencies and the `yarn.lock` file.
1. In the **Terminal** pane, run the following commands to commit your changes. This triggers a CI/CD
   pipeline.

   ```plaintext
   git add package.json yarn.lock
   git commit -m "Update package versions"
   git push --set-upstream origin update_packages
   ```

1. Switch to the GitLab browser tab.
1. Go to **Code > Merge requests**, then select **Create merge request**.
1. On the **New merge request** page, scroll to the bottom and select **Create merge request**.
   Wait for the merge request pipeline to complete.
1. Refresh the page, then select **Merge**.
1. Wait for the pipeline to complete successfully.
1. Go to **Secure > Vulnerability report**.
1. Select the **High** vulnerability's description.

   A banner confirms that the vulnerability has been resolved in the `main` branch. You would
   usually confirm that manually by verifying the version of the `fastify` package specified in the
   `yarn.lock` file. For this tutorial, you can skip the verification step.

1. In the **Status** dropdown list, select **Resolve**, then select **Change status**.
1. Go to **Secure > Vulnerability report**.

   You should now see _no_ vulnerabilities listed in the vulnerability report.

## Test vulnerability detection in a merge request

You now know how to triage and resolve vulnerabilities. Now, to see how to detect new potential
vulnerabilities in a merge request, add a dependency known to have vulnerabilities.

To add a new vulnerability:

1. Switch to the Gitpod tab. If it's timed out, select **Open Workspace**.
1. In the **Terminal** pane run the following command to update the local `main` branch:

   ```plaintext
   git checkout main
   git fetch origin
   git rebase origin/main
   ```

1. In the **Terminal** pane run the following command to create a new branch:

   ```plaintext
   git checkout -b add_dependency main
   ```

1. In the file explorer sidebar, select the `package.json` file.
1. Add the following line to the `dependencies` section of the `package.json` file.

   ```json
   "axios": "0.21.0",
   ```

1. In the **Terminal** pane, run the following command to install the dependency added to the
   `package.json` file.

   ```plaintext
   yarn install
   ```

1. In the **Terminal** pane, run the following commands to commit your changes. This triggers a
   CI/CD pipeline on GitLab.

   ```plaintext
   git add package.json yarn.lock
   git commit -m "Add dependency"
   git push --set-upstream origin add_dependency
   ```

1. Switch to the GitLab browser tab.
1. Go to **Code > Merge requests**, then select **Create merge request**.
1. On the **New merge request** page, scroll to the bottom and select **Create merge request**.

Wait for the merge request pipeline to complete, then refresh the page. The merge
request security widget warns of new potential vulnerabilities. These vulnerabilities exist
only in the `add_dependency` branch, not the `main` branch.

You now know how to:

- Detect vulnerabilities in an application's dependencies.
- Triage and resolve vulnerabilities.
- Detect new vulnerabilities in a merge request.

### Yarn lock file content

```yaml
# THIS IS AN AUTOGENERATED FILE. DO NOT EDIT THIS FILE DIRECTLY.
# yarn lockfile v1

abstract-logging@^2.0.0:
  version "2.0.1"
  resolved "https://registry.yarnpkg.com/abstract-logging/-/abstract-logging-2.0.1.tgz#6b0c371df212db7129b57d2e7fcf282b8bf1c839"
  integrity sha512-2BjRTZxTPvheOvGbBslFSYOUkr+SjPtOnrLP33f+VIWLzezQpZcqVg7ja3L4dBXmzzgwT+a029jRx5PCi3JuiA==

ajv@^6.10.2, ajv@^6.11.0, ajv@^6.12.0:
  version "6.12.6"
  resolved "https://registry.yarnpkg.com/ajv/-/ajv-6.12.6.tgz#baf5a62e802b07d977034586f8c3baf5adf26df4"
  integrity sha512-j3fVLgvTo527anyYyJOGTYJbG+vnnQYvE0m5mmkc1TK+nxAppkCLMIL0aZ4dblVCNoGShhm+kzE4ZUykBoMg4g==
  dependencies:
    fast-deep-equal "^3.1.1"
    fast-json-stable-stringify "^2.0.0"
    json-schema-traverse "^0.4.1"
    uri-js "^4.2.2"

archy@^1.0.0:
  version "1.0.0"
  resolved "https://registry.yarnpkg.com/archy/-/archy-1.0.0.tgz#f9c8c13757cc1dd7bc379ac77b2c62a5c2868c40"
  integrity sha512-Xg+9RwCg/0p32teKdGMPTPnVXKD0w3DfHnFTficozsAgsvq2XenPJq/MYpzzQ/v8zrOyJn6Ds39VA4JIDwFfqw==

atomic-sleep@^1.0.0:
  version "1.0.0"
  resolved "https://registry.yarnpkg.com/atomic-sleep/-/atomic-sleep-1.0.0.tgz#eb85b77a601fc932cfe432c5acd364a9e2c9075b"
  integrity sha512-kNOjDqAh7px0XWNI+4QbzoiR/nTkHAWNud2uvnJquD1/x5a7EQZMJT0AczqK0Qn67oY/TTQ1LbUKajZpp3I9tQ==

avvio@^6.3.1:
  version "6.5.0"
  resolved "https://registry.yarnpkg.com/avvio/-/avvio-6.5.0.tgz#d2cf119967fe90d2156afc29de350ced800cdaab"
  integrity sha512-BmzcZ7gFpyFJsW8G+tfQw8vJNUboA9SDkkHLZ9RAALhvw/rplfWwni8Ee1rA11zj/J7/E5EvZmweusVvTHjWCA==
  dependencies:
    archy "^1.0.0"
    debug "^4.0.0"
    fastq "^1.6.0"

cookie@^0.4.0:
  version "0.4.2"
  resolved "https://registry.yarnpkg.com/cookie/-/cookie-0.4.2.tgz#0e41f24de5ecf317947c82fc789e06a884824432"
  integrity sha512-aSWTXFzaKWkvHO1Ny/s+ePFpvKsPnjc551iI41v3ny/ow6tBG5Vd+FuqGNhh1LxOmVzOlGUriIlOaokOvhaStA==

debug@2.6.9:
  version "2.6.9"
  resolved "https://registry.yarnpkg.com/debug/-/debug-2.6.9.tgz#5d128515df134ff327e90a4c93f4e077a536341f"
  integrity sha512-bC7ElrdJaJnPbAP+1EotYvqZsb3ecl5wi6Bfi6BJTUcNowp6cvspg0jXznRTKDjm/E7AdgFBVeAPVMNcKGsHMA==
  dependencies:
    ms "2.0.0"

debug@^4.0.0:
  version "4.3.4"
  resolved "https://registry.yarnpkg.com/debug/-/debug-4.3.4.tgz#1319f6579357f2338d3337d2cdd4914bb5dcc865"
  integrity sha512-PRWFHuSU3eDtQJPvnNY7Jcket1j0t5OuOsFzPPzsekD52Zl8qUfFIPEiswXqIvHWGVHOgX+7G/vCNNhehwxfkQ==
  dependencies:
    ms "2.1.2"

deepmerge@^4.2.2:
  version "4.2.2"
  resolved "https://registry.yarnpkg.com/deepmerge/-/deepmerge-4.2.2.tgz#44d2ea3679b8f4d4ffba33f03d865fc1e7bf4955"
  integrity sha512-FJ3UgI4gIl+PHZm53knsuSFpE+nESMr7M4v9QcgB7S63Kj/6WqMiFQJpBBYz1Pt+66bZpP3Q7Lye0Oo9MPKEdg==

depd@~1.1.2:
  version "1.1.2"
  resolved "https://registry.yarnpkg.com/depd/-/depd-1.1.2.tgz#9bcd52e14c097763e749b274c4346ed2e560b5a9"
  integrity sha512-7emPTl6Dpo6JRXOXjLRxck+FlLRX5847cLKEn00PLAgc3g2hTZZgr+e4c2v6QpSmLeFP3n5yUo7ft6avBK/5jQ==

destroy@~1.0.4:
  version "1.0.4"
  resolved "https://registry.yarnpkg.com/destroy/-/destroy-1.0.4.tgz#978857442c44749e4206613e37946205826abd80"
  integrity sha512-3NdhDuEXnfun/z7x9GOElY49LoqVHoGScmOKwmxhsS8N5Y+Z8KyPPDnaSzqWgYt/ji4mqwfTS34Htrk0zPIXVg==

ee-first@1.1.1:
  version "1.1.1"
  resolved "https://registry.yarnpkg.com/ee-first/-/ee-first-1.1.1.tgz#590c61156b0ae2f4f0255732a158b266bc56b21d"
  integrity sha512-WMwm9LhRUo+WUaRN+vRuETqG89IgZphVSNkdFgeb6sS/E4OrDIN7t48CAewSHXc6C8lefD8KKfr5vY61brQlow==

encodeurl@~1.0.2:
  version "1.0.2"
  resolved "https://registry.yarnpkg.com/encodeurl/-/encodeurl-1.0.2.tgz#ad3ff4c86ec2d029322f5a02c3a9a606c95b3f59"
  integrity sha512-TPJXq8JqFaVYm2CWmPvnP2Iyo4ZSM7/QKcSmuMLDObfpH5fi7RUGmd/rTDf+rut/saiDiQEeVTNgAmJEdAOx0w==

escape-html@~1.0.3:
  version "1.0.3"
  resolved "https://registry.yarnpkg.com/escape-html/-/escape-html-1.0.3.tgz#0258eae4d3d0c0974de1c169188ef0051d1d1988"
  integrity sha512-NiSupZ4OeuGwr68lGIeym/ksIZMJodUGOSCZ/FSnTxcrekbvqrgdUxlJOMpijaKZVjAJrWrGs/6Jy8OMuyj9ow==

etag@~1.8.1:
  version "1.8.1"
  resolved "https://registry.yarnpkg.com/etag/-/etag-1.8.1.tgz#41ae2eeb65efa62268aebfea83ac7d79299b0887"
  integrity sha512-aIL5Fx7mawVa300al2BnEE4iNvo1qETxLrPI/o05L7z6go7fCw1J6EQmbK4FmJ2AS7kgVF/KEZWufBfdClMcPg==

fast-decode-uri-component@^1.0.0:
  version "1.0.1"
  resolved "https://registry.yarnpkg.com/fast-decode-uri-component/-/fast-decode-uri-component-1.0.1.tgz#46f8b6c22b30ff7a81357d4f59abfae938202543"
  integrity sha512-WKgKWg5eUxvRZGwW8FvfbaH7AXSh2cL+3j5fMGzUMCxWBJ3dV3a7Wz8y2f/uQ0e3B6WmodD3oS54jTQ9HVTIIg==

fast-deep-equal@^3.1.1:
  version "3.1.3"
  resolved "https://registry.yarnpkg.com/fast-deep-equal/-/fast-deep-equal-3.1.3.tgz#3a7d56b559d6cbc3eb512325244e619a65c6c525"
  integrity sha512-f3qQ9oQy9j2AhBe/H9VC91wLmKBCCU/gDOnKNAYG5hswO7BLKj09Hc5HYNz9cGI++xlpDCIgDaitVs03ATR84Q==

fast-json-stable-stringify@^2.0.0:
  version "2.1.0"
  resolved "https://registry.yarnpkg.com/fast-json-stable-stringify/-/fast-json-stable-stringify-2.1.0.tgz#874bf69c6f404c2b5d99c481341399fd55892633"
  integrity sha512-lhd/wF+Lk98HZoTCtlVraHtfh5XYijIjalXck7saUtuanSDyLMxnHhSXEDJqHxD7msR8D0uCmqlkwjCV8xvwHw==

fast-json-stringify@^1.18.0:
  version "1.21.0"
  resolved "https://registry.yarnpkg.com/fast-json-stringify/-/fast-json-stringify-1.21.0.tgz#51bc8c6d77d8c7b2cc7e5fa754f7f909f9e1262f"
  integrity sha512-xY6gyjmHN3AK1Y15BCbMpeO9+dea5ePVsp3BouHCdukcx0hOHbXwFhRodhcI0NpZIgDChSeAKkHW9YjKvhwKBA==
  dependencies:
    ajv "^6.11.0"
    deepmerge "^4.2.2"
    string-similarity "^4.0.1"

fast-redact@^2.0.0:
  version "2.1.0"
  resolved "https://registry.yarnpkg.com/fast-redact/-/fast-redact-2.1.0.tgz#dfe3c1ca69367fb226f110aa4ec10ec85462ffdf"
  integrity sha512-0LkHpTLyadJavq9sRzzyqIoMZemWli77K2/MGOkafrR64B9ItrvZ9aT+jluvNDsv0YEHjSNhlMBtbokuoqii4A==

fast-safe-stringify@^2.0.7:
  version "2.1.1"
  resolved "https://registry.yarnpkg.com/fast-safe-stringify/-/fast-safe-stringify-2.1.1.tgz#c406a83b6e70d9e35ce3b30a81141df30aeba884"
  integrity sha512-W+KJc2dmILlPplD/H4K9l9LcAHAfPtP6BY84uVLXQ6Evcz9Lcg33Y2z1IVblT6xdY54PXYVHEv+0Wpq8Io6zkA==

fastify-plugin@^1.2.0:
  version "1.6.1"
  resolved "https://registry.yarnpkg.com/fastify-plugin/-/fastify-plugin-1.6.1.tgz#122f5a5eeb630d55c301713145a9d188e6d5dd5b"
  integrity sha512-APBcb27s+MjaBIerFirYmBLatoPCgmHZM6XP0K+nDL9k0yX8NJPWDY1RAC3bh6z+AB5ULS2j31BUfLMT3uaZ4A==
  dependencies:
    semver "^6.3.0"

fastify-static@2.0.0:
  version "2.0.0"
  resolved "https://registry.yarnpkg.com/fastify-static/-/fastify-static-2.0.0.tgz#674f3f3180e8b055e5e1ee1bcee68114cfb09a8f"
  integrity sha512-8YQ4QWcSR3YJTFLpExXIej2GzCHThowyLUUxt1uZN8rBEEI2T2ZcaRXPmkaNcaUiKzLXceGjdbJm5yByp5dlkA==
  dependencies:
    fastify-plugin "^1.2.0"
    readable-stream "^3.0.2"
    send "^0.16.0"

fastify@2.14.1:
  version "2.14.1"
  resolved "https://registry.yarnpkg.com/fastify/-/fastify-2.14.1.tgz#2946e8e9adebcd1b4f634178c8fb7162fb816cf4"
  integrity sha512-nSL8AgIdFCpZmFwjqB5Zzv+3/1KpwwVtB/h88Q4Og8njYbkddKGpuQlQ2tHUULXPTJrLZ7wop6olzx6HEbHdpw==
  dependencies:
    abstract-logging "^2.0.0"
    ajv "^6.12.0"
    avvio "^6.3.1"
    fast-json-stringify "^1.18.0"
    find-my-way "^2.2.2"
    flatstr "^1.0.12"
    light-my-request "^3.7.3"
    middie "^4.1.0"
    pino "^5.17.0"
    proxy-addr "^2.0.6"
    readable-stream "^3.6.0"
    rfdc "^1.1.2"
    secure-json-parse "^2.1.0"
    tiny-lru "^7.0.2"

fastq@^1.6.0:
  version "1.13.0"
  resolved "https://registry.yarnpkg.com/fastq/-/fastq-1.13.0.tgz#616760f88a7526bdfc596b7cab8c18938c36b98c"
  integrity sha512-YpkpUnK8od0o1hmeSc7UUs/eB/vIPWJYjKck2QKIzAf71Vm1AAQ3EbuZB3g2JIy+pg+ERD0vqI79KyZiB2e2Nw==
  dependencies:
    reusify "^1.0.4"

find-my-way@^2.2.2:
  version "2.2.5"
  resolved "https://registry.yarnpkg.com/find-my-way/-/find-my-way-2.2.5.tgz#86ce825266fa28cd962e538a45ec2aaa84c3d514"
  integrity sha512-GjRZZlGcGmTh9t+6Xrj5K0YprpoAFCAiCPgmAH9Kb09O4oX6hYuckDfnDipYj+Q7B1GtYWSzDI5HEecNYscLQg==
  dependencies:
    fast-decode-uri-component "^1.0.0"
    safe-regex2 "^2.0.0"
    semver-store "^0.3.0"

flatstr@^1.0.12:
  version "1.0.12"
  resolved "https://registry.yarnpkg.com/flatstr/-/flatstr-1.0.12.tgz#c2ba6a08173edbb6c9640e3055b95e287ceb5931"
  integrity sha512-4zPxDyhCyiN2wIAtSLI6gc82/EjqZc1onI4Mz/l0pWrAlsSfYH/2ZIcU+e3oA2wDwbzIWNKwa23F8rh6+DRWkw==

forwarded@0.2.0:
  version "0.2.0"
  resolved "https://registry.yarnpkg.com/forwarded/-/forwarded-0.2.0.tgz#2269936428aad4c15c7ebe9779a84bf0b2a81811"
  integrity sha512-buRG0fpBtRHSTCOASe6hD258tEubFoRLb4ZNA6NxMVHNw2gOcwHo9wyablzMzOA5z9xA9L1KNjk/Nt6MT9aYow==

fresh@0.5.2:
  version "0.5.2"
  resolved "https://registry.yarnpkg.com/fresh/-/fresh-0.5.2.tgz#3d8cadd90d976569fa835ab1f8e4b23a105605a7"
  integrity sha512-zJ2mQYM18rEFOudeV4GShTGIQ7RbzA7ozbU9I/XBpm7kqgMywgmylMwXHxZJmkVoYkna9d2pVXVXPdYTP9ej8Q==

http-errors@~1.6.2:
  version "1.6.3"
  resolved "https://registry.yarnpkg.com/http-errors/-/http-errors-1.6.3.tgz#8b55680bb4be283a0b5bf4ea2e38580be1d9320d"
  integrity sha512-lks+lVC8dgGyh97jxvxeYTWQFvh4uw4yC12gVl63Cg30sjPX4wuGcdkICVXDAESr6OJGjqGA8Iz5mkeN6zlD7A==
  dependencies:
    depd "~1.1.2"
    inherits "2.0.3"
    setprototypeof "1.1.0"
    statuses ">= 1.4.0 < 2"

inherits@2.0.3:
  version "2.0.3"
  resolved "https://registry.yarnpkg.com/inherits/-/inherits-2.0.3.tgz#633c2c83e3da42a502f52466022480f4208261de"
  integrity sha512-x00IRNXNy63jwGkJmzPigoySHbaqpNuzKbBOmzK+g2OdZpQ9w+sxCN+VSB3ja7IAge2OP2qpfxTjeNcyjmW1uw==

inherits@^2.0.3:
  version "2.0.4"
  resolved "https://registry.yarnpkg.com/inherits/-/inherits-2.0.4.tgz#0fa2c64f932917c3433a0ded55363aae37416b7c"
  integrity sha512-k/vGaX4/Yla3WzyMCvTQOXYeIHvqOKtnqBduzTHpzpQZzAskKMhZ2K+EnBiSM9zGSoIFeMpXKxa4dYeZIQqewQ==

ipaddr.js@1.9.1:
  version "1.9.1"
  resolved "https://registry.yarnpkg.com/ipaddr.js/-/ipaddr.js-1.9.1.tgz#bff38543eeb8984825079ff3a2a8e6cbd46781b3"
  integrity sha512-0KI/607xoxSToH7GjN1FfSbLoU0+btTicjsQSWQlh/hZykN8KpmMf7uYwPW3R+akZ6R/w18ZlXSHBYXiYUPO3g==

json-schema-traverse@^0.4.1:
  version "0.4.1"
  resolved "https://registry.yarnpkg.com/json-schema-traverse/-/json-schema-traverse-0.4.1.tgz#69f6a87d9513ab8bb8fe63bdb0979c448e684660"
  integrity sha512-xbbCH5dCYU5T8LcEhhuh7HJ88HXuW3qsI3Y0zOZFKfZEHcpWiHU/Jxzk629Brsab/mMiHQti9wMP+845RPe3Vg==

light-my-request@^3.7.3:
  version "3.8.0"
  resolved "https://registry.yarnpkg.com/light-my-request/-/light-my-request-3.8.0.tgz#7da96786e4d479371b25cfd524ee05d5d583dae8"
  integrity sha512-cIOWmNsgoStysmkzcv2EwvLwMb2hEm6oqKMerG/b5ey9F0we2Qony8cAZgBktmGPYUvPyKsDCzMcYU6fXbpWew==
  dependencies:
    ajv "^6.10.2"
    cookie "^0.4.0"
    readable-stream "^3.4.0"
    set-cookie-parser "^2.4.1"

middie@^4.1.0:
  version "4.1.0"
  resolved "https://registry.yarnpkg.com/middie/-/middie-4.1.0.tgz#0fe986c83d5081489514ca1a2daba5ca36263436"
  integrity sha512-eylPpZA+K3xO9kpDjagoPkEUkNcWV3EAo5OEz0MqsekUpT7KbnQkk8HNZkh4phx2vvOAmNNZuLRWF9lDDHPpVQ==
  dependencies:
    path-to-regexp "^4.0.0"
    reusify "^1.0.2"

mime@1.4.1:
  version "1.4.1"
  resolved "https://registry.yarnpkg.com/mime/-/mime-1.4.1.tgz#121f9ebc49e3766f311a76e1fa1c8003c4b03aa6"
  integrity sha512-KI1+qOZu5DcW6wayYHSzR/tXKCDC5Om4s1z2QJjDULzLcmf3DvzS7oluY4HCTrc+9FiKmWUgeNLg7W3uIQvxtQ==

ms@2.0.0:
  version "2.0.0"
  resolved "https://registry.yarnpkg.com/ms/-/ms-2.0.0.tgz#5608aeadfc00be6c2901df5f9861788de0d597c8"
  integrity sha512-Tpp60P6IUJDTuOq/5Z8cdskzJujfwqfOTkrwIwj7IRISpnkJnT6SyJ4PCPnGMoFjC9ddhal5KVIYtAt97ix05A==

ms@2.1.2:
  version "2.1.2"
  resolved "https://registry.yarnpkg.com/ms/-/ms-2.1.2.tgz#d09d1f357b443f493382a8eb3ccd183872ae6009"
  integrity sha512-sGkPx+VjMtmA6MX27oA4FBFELFCZZ4S4XqeGOXCv68tT+jb3vk/RyaKWP0PTKyWtmLSM0b+adUTEvbs1PEaH2w==

on-finished@~2.3.0:
  version "2.3.0"
  resolved "https://registry.yarnpkg.com/on-finished/-/on-finished-2.3.0.tgz#20f1336481b083cd75337992a16971aa2d906947"
  integrity sha512-ikqdkGAAyf/X/gPhXGvfgAytDZtDbr+bkNUJ0N9h5MI/dmdgCs3l6hoHrcUv41sRKew3jIwrp4qQDXiK99Utww==
  dependencies:
    ee-first "1.1.1"

path-to-regexp@^4.0.0:
  version "4.0.5"
  resolved "https://registry.yarnpkg.com/path-to-regexp/-/path-to-regexp-4.0.5.tgz#2d4fd140af9a369bf7b68f77a7fdc340490f4239"
  integrity sha512-l+fTaGG2N9ZRpCEUj5fG1VKdDLaiqwCIvPngpnxzREhcdobhZC4ou4w984HBu72DqAJ5CfcdV6tjqNOunfpdsQ==

pino-std-serializers@^2.4.2:
  version "2.5.0"
  resolved "https://registry.yarnpkg.com/pino-std-serializers/-/pino-std-serializers-2.5.0.tgz#40ead781c65a0ce7ecd9c1c33f409d31fe712315"
  integrity sha512-wXqbqSrIhE58TdrxxlfLwU9eDhrzppQDvGhBEr1gYbzzM4KKo3Y63gSjiDXRKLVS2UOXdPNR2v+KnQgNrs+xUg==

pino@^5.17.0:
  version "5.17.0"
  resolved "https://registry.yarnpkg.com/pino/-/pino-5.17.0.tgz#b9def314e82402154f89a25d76a31f20ca84b4c8"
  integrity sha512-LqrqmRcJz8etUjyV0ddqB6OTUutCgQULPFg2b4dtijRHUsucaAdBgSUW58vY6RFSX+NT8963F+q0tM6lNwGShA==
  dependencies:
    fast-redact "^2.0.0"
    fast-safe-stringify "^2.0.7"
    flatstr "^1.0.12"
    pino-std-serializers "^2.4.2"
    quick-format-unescaped "^3.0.3"
    sonic-boom "^0.7.5"

proxy-addr@^2.0.6:
  version "2.0.7"
  resolved "https://registry.yarnpkg.com/proxy-addr/-/proxy-addr-2.0.7.tgz#f19fe69ceab311eeb94b42e70e8c2070f9ba1025"
  integrity sha512-llQsMLSUDUPT44jdrU/O37qlnifitDP+ZwrmmZcoSKyLKvtZxpyV0n2/bD/N4tBAAZ/gJEdZU7KMraoK1+XYAg==
  dependencies:
    forwarded "0.2.0"
    ipaddr.js "1.9.1"

punycode@^2.1.0:
  version "2.1.1"
  resolved "https://registry.yarnpkg.com/punycode/-/punycode-2.1.1.tgz#b58b010ac40c22c5657616c8d2c2c02c7bf479ec"
  integrity sha512-XRsRjdf+j5ml+y/6GKHPZbrF/8p2Yga0JPtdqTIY2Xe5ohJPD9saDJJLPvp9+NSBprVvevdXZybnj2cv8OEd0A==

quick-format-unescaped@^3.0.3:
  version "3.0.3"
  resolved "https://registry.yarnpkg.com/quick-format-unescaped/-/quick-format-unescaped-3.0.3.tgz#fb3e468ac64c01d22305806c39f121ddac0d1fb9"
  integrity sha512-dy1yjycmn9blucmJLXOfZDx1ikZJUi6E8bBZLnhPG5gBrVhHXx2xVyqqgKBubVNEXmx51dBACMHpoMQK/N/AXQ==

range-parser@~1.2.0:
  version "1.2.1"
  resolved "https://registry.yarnpkg.com/range-parser/-/range-parser-1.2.1.tgz#3cf37023d199e1c24d1a55b84800c2f3e6468031"
  integrity sha512-Hrgsx+orqoygnmhFbKaHE6c296J+HTAQXoxEF6gNupROmmGJRoyzfG3ccAveqCBrwr/2yxQ5BVd/GTl5agOwSg==

readable-stream@^3.0.2, readable-stream@^3.4.0, readable-stream@^3.6.0:
  version "3.6.0"
  resolved "https://registry.yarnpkg.com/readable-stream/-/readable-stream-3.6.0.tgz#337bbda3adc0706bd3e024426a286d4b4b2c9198"
  integrity sha512-BViHy7LKeTz4oNnkcLJ+lVSL6vpiFeX6/d3oSH8zCW7UxP2onchk+vTGB143xuFjHS3deTgkKoXXymXqymiIdA==
  dependencies:
    inherits "^2.0.3"
    string_decoder "^1.1.1"
    util-deprecate "^1.0.1"

ret@~0.2.0:
  version "0.2.2"
  resolved "https://registry.yarnpkg.com/ret/-/ret-0.2.2.tgz#b6861782a1f4762dce43402a71eb7a283f44573c"
  integrity sha512-M0b3YWQs7R3Z917WRQy1HHA7Ba7D8hvZg6UE5mLykJxQVE2ju0IXbGlaHPPlkY+WN7wFP+wUMXmBFA0aV6vYGQ==

reusify@^1.0.2, reusify@^1.0.4:
  version "1.0.4"
  resolved "https://registry.yarnpkg.com/reusify/-/reusify-1.0.4.tgz#90da382b1e126efc02146e90845a88db12925d76"
  integrity sha512-U9nH88a3fc/ekCF1l0/UP1IosiuIjyTh7hBvXVMHYgVcfGvt897Xguj2UOLDeI5BG2m7/uwyaLVT6fbtCwTyzw==

rfdc@^1.1.2:
  version "1.3.0"
  resolved "https://registry.yarnpkg.com/rfdc/-/rfdc-1.3.0.tgz#d0b7c441ab2720d05dc4cf26e01c89631d9da08b"
  integrity sha512-V2hovdzFbOi77/WajaSMXk2OLm+xNIeQdMMuB7icj7bk6zi2F8GGAxigcnDFpJHbNyNcgyJDiP+8nOrY5cZGrA==

safe-buffer@~5.2.0:
  version "5.2.1"
  resolved "https://registry.yarnpkg.com/safe-buffer/-/safe-buffer-5.2.1.tgz#1eaf9fa9bdb1fdd4ec75f58f9cdb4e6b7827eec6"
  integrity sha512-rp3So07KcdmmKbGvgaNxQSJr7bGVSVk5S9Eq1F+ppbRo70+YeaDxkw5Dd8NPN+GD6bjnYm2VuPuCXmpuYvmCXQ==

safe-regex2@^2.0.0:
  version "2.0.0"
  resolved "https://registry.yarnpkg.com/safe-regex2/-/safe-regex2-2.0.0.tgz#b287524c397c7a2994470367e0185e1916b1f5b9"
  integrity sha512-PaUSFsUaNNuKwkBijoAPHAK6/eM6VirvyPWlZ7BAQy4D+hCvh4B6lIG+nPdhbFfIbP+gTGBcrdsOaUs0F+ZBOQ==
  dependencies:
    ret "~0.2.0"

secure-json-parse@^2.1.0:
  version "2.5.0"
  resolved "https://registry.yarnpkg.com/secure-json-parse/-/secure-json-parse-2.5.0.tgz#f929829df2adc7ccfb53703569894d051493a6ac"
  integrity sha512-ZQruFgZnIWH+WyO9t5rWt4ZEGqCKPwhiw+YbzTwpmT9elgLrLcfuyUiSnwwjUiVy9r4VM3urtbNF1xmEh9IL2w==

semver-store@^0.3.0:
  version "0.3.0"
  resolved "https://registry.yarnpkg.com/semver-store/-/semver-store-0.3.0.tgz#ce602ff07df37080ec9f4fb40b29576547befbe9"
  integrity sha512-TcZvGMMy9vodEFSse30lWinkj+JgOBvPn8wRItpQRSayhc+4ssDs335uklkfvQQJgL/WvmHLVj4Ycv2s7QCQMg==

semver@^6.3.0:
  version "6.3.0"
  resolved "https://registry.yarnpkg.com/semver/-/semver-6.3.0.tgz#ee0a64c8af5e8ceea67687b133761e1becbd1d3d"
  integrity sha512-b39TBaTSfV6yBrapU89p5fKekE2m/NwnDocOVruQFS1/veMgdzuPcnOM34M6CwxW8jH/lxEa5rBoDeUwu5HHTw==

send@^0.16.0:
  version "0.16.2"
  resolved "https://registry.yarnpkg.com/send/-/send-0.16.2.tgz#6ecca1e0f8c156d141597559848df64730a6bbc1"
  integrity sha512-E64YFPUssFHEFBvpbbjr44NCLtI1AohxQ8ZSiJjQLskAdKuriYEP6VyGEsRDH8ScozGpkaX1BGvhanqCwkcEZw==
  dependencies:
    debug "2.6.9"
    depd "~1.1.2"
    destroy "~1.0.4"
    encodeurl "~1.0.2"
    escape-html "~1.0.3"
    etag "~1.8.1"
    fresh "0.5.2"
    http-errors "~1.6.2"
    mime "1.4.1"
    ms "2.0.0"
    on-finished "~2.3.0"
    range-parser "~1.2.0"
    statuses "~1.4.0"

set-cookie-parser@^2.4.1:
  version "2.5.1"
  resolved "https://registry.yarnpkg.com/set-cookie-parser/-/set-cookie-parser-2.5.1.tgz#ddd3e9a566b0e8e0862aca974a6ac0e01349430b"
  integrity sha512-1jeBGaKNGdEq4FgIrORu/N570dwoPYio8lSoYLWmX7sQ//0JY08Xh9o5pBcgmHQ/MbsYp/aZnOe1s1lIsbLprQ==

setprototypeof@1.1.0:
  version "1.1.0"
  resolved "https://registry.yarnpkg.com/setprototypeof/-/setprototypeof-1.1.0.tgz#d0bd85536887b6fe7c0d818cb962d9d91c54e656"
  integrity sha512-BvE/TwpZX4FXExxOxZyRGQQv651MSwmWKZGqvmPcRIjDqWub67kTKuIMx43cZZrS/cBBzwBcNDWoFxt2XEFIpQ==

sonic-boom@^0.7.5:
  version "0.7.7"
  resolved "https://registry.yarnpkg.com/sonic-boom/-/sonic-boom-0.7.7.tgz#d921de887428208bfa07b0ae32c278de043f350a"
  integrity sha512-Ei5YOo5J64GKClHIL/5evJPgASXFVpfVYbJV9PILZQytTK6/LCwHvsZJW2Ig4p9FMC2OrBrMnXKgRN/OEoAWfg==
  dependencies:
    atomic-sleep "^1.0.0"
    flatstr "^1.0.12"

"statuses@>= 1.4.0 < 2":
  version "1.5.0"
  resolved "https://registry.yarnpkg.com/statuses/-/statuses-1.5.0.tgz#161c7dac177659fd9811f43771fa99381478628c"
  integrity sha512-OpZ3zP+jT1PI7I8nemJX4AKmAX070ZkYPVWV/AaKTJl+tXCTGyVdC1a4SL8RUQYEwk/f34ZX8UTykN68FwrqAA==

statuses@~1.4.0:
  version "1.4.0"
  resolved "https://registry.yarnpkg.com/statuses/-/statuses-1.4.0.tgz#bb73d446da2796106efcc1b601a253d6c46bd087"
  integrity sha512-zhSCtt8v2NDrRlPQpCNtw/heZLtfUDqxBM1udqikb/Hbk52LK4nQSwr10u77iopCW5LsyHpuXS0GnEc48mLeew==

string-similarity@^4.0.1:
  version "4.0.4"
  resolved "https://registry.yarnpkg.com/string-similarity/-/string-similarity-4.0.4.tgz#42d01ab0b34660ea8a018da8f56a3309bb8b2a5b"
  integrity sha512-/q/8Q4Bl4ZKAPjj8WerIBJWALKkaPRfrvhfF8k/B23i4nzrlRj2/go1m90In7nG/3XDSbOo0+pu6RvCTM9RGMQ==

string_decoder@^1.1.1:
  version "1.3.0"
  resolved "https://registry.yarnpkg.com/string_decoder/-/string_decoder-1.3.0.tgz#42f114594a46cf1a8e30b0a84f56c78c3edac21e"
  integrity sha512-hkRX8U1WjJFd8LsDJ2yQ/wWWxaopEsABU1XfkM8A+j0+85JAGppt16cr1Whg6KIbb4okU6Mql6BOj+uup/wKeA==
  dependencies:
    safe-buffer "~5.2.0"

tiny-lru@^7.0.2:
  version "7.0.6"
  resolved "https://registry.yarnpkg.com/tiny-lru/-/tiny-lru-7.0.6.tgz#b0c3cdede1e5882aa2d1ae21cb2ceccf2a331f24"
  integrity sha512-zNYO0Kvgn5rXzWpL0y3RS09sMK67eGaQj9805jlK9G6pSadfriTczzLHFXa/xcW4mIRfmlB9HyQ/+SgL0V1uow==

uri-js@^4.2.2:
  version "4.4.1"
  resolved "https://registry.yarnpkg.com/uri-js/-/uri-js-4.4.1.tgz#9b1a52595225859e55f669d928f88c6c57f2a77e"
  integrity sha512-7rKUyy33Q1yc98pQ1DAmLtwX109F7TIfWlW1Ydo8Wl1ii1SeHieeh0HHfPeL2fMXK6z0s8ecKs9frCuLJvndBg==
  dependencies:
    punycode "^2.1.0"

util-deprecate@^1.0.1:
  version "1.0.2"
  resolved "https://registry.yarnpkg.com/util-deprecate/-/util-deprecate-1.0.2.tgz#450d4dc9fa70de732762fbd2d4a28981419a0ccf"
  integrity sha512-EPD5q1uXyFxJpCrLnCc1nHnq3gOa6DZBocAIiI2TaSCA7VCJ1UJDMagCzIkXNsUYfD1daK//LTEQ8xiIbrHtcw==
```
