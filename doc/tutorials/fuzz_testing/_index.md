---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Perform fuzz testing in GitLab'
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

[Coverage-guided fuzz testing](../../user/application_security/coverage_fuzzing/_index.md#coverage-guided-fuzz-testing-process) sends unexpected, malformed, or random data to your application, and then monitors
your application for unstable behaviors and crashes.

This helps you discover bugs and potential security issues that other QA processes may miss.

You should use fuzz testing in addition to other security scanners and your own test processes.
If you're using GitLab CI/CD, you can run fuzz tests as part your CI/CD workflow.

To set up, configure, and perform coverage-guided fuzz testing
using JavaScript in this tutorial, you:

1. [Fork the project template](#fork-the-project-template) to create a project
   to run the fuzz tests in.
1. [Create the fuzz targets](#create-the-fuzz-targets).
1. [Enable coverage-guided fuzz testing](#enable-coverage-guided-fuzz-testing)
   in your forked project.
1. [Run the fuzz test](#run-the-fuzz-test) to identify security vulnerabilities.
1. [Fix any vulnerabilities](#fix-the-vulnerabilities) identified by the fuzz test.

## Fork the project template

First, to create a project to try out fuzz testing in, you must fork the `fuzz-testing`
project template:

1. Open the [`fuzz-testing` project template](https://gitlab.com/gitlab-org/tutorial-project-templates/fuzz-testing).
1. [Fork the project template](../../user/project/repository/forking_workflow.md).
1. When forking the project template:
   - Name the forked project `fuzz-testing-demo`.
   - Select an appropriate [namespace](../../user/namespace/_index.md).
   - Set [project visibility](../../user/public_access.md) to **Private**.

You have successfully forked the `fuzz-testing` project template. Before you can
start fuzz testing, remove the relationship between the project template and the fork:

1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. In the **Remove fork relationship** section, select **Remove fork relationship**.
   Enter the name of the project when prompted.

Your project is ready and you can now create the fuzz test. Next you will create
the fuzz targets.

## Create the fuzz targets

Now you have a project for fuzz testing, you create the fuzz targets. A fuzz target
is a function or program that, given an input, makes a call to the application
being tested.

In this tutorial, the fuzz targets call a function of the `my-tools.js` file using
a random buffer as a parameter.

To create the two fuzz target files:

1. On the left sidebar, select **Search or go to** and find the `fuzz-testing-demo` project.
1. Create a file in the root directory of the project.
1. Name the file `fuzz-sayhello.js` and add the following code:

   ```javascript
   let tools = require('./my-tools')

   function fuzz(buf) {
     const text = buf.toString()
     tools.sayHello(text)
   }

   module.exports = {
     fuzz
   }
   ```

   You can also copy this code from the `fuzz-testing-demo/fuzzers/fuzz-sayhello.js`
   project file.

1. Name the **Target Branch** `add-fuzz-test` and write a descriptive commit message.
   - Do not select the **Start a new merge request with these changes** checkbox yet.
1. Select **Commit changes**.
1. Return to the root directory of the project.
1. Make sure you are in the `add-fuzz-test` branch.
1. Create the second file named `fuzz-readme.js` and add the following code:

   ```javascript
   let tools = require('./my-tools')
   function fuzz(buf) {
       const text = buf.toString()
       tools.readmeContent(text)
   }
   module.exports = {
       fuzz
   }
   ```

   You can also copy this code from the `fuzz-testing-demo/fuzzers/fuzz-readme.js`
   project file.

1. Write a descriptive commit message.
1. Make sure the **Target Branch** is `add-fuzz-test`.
1. Select **Commit changes**.

You now have two fuzz targets that can make calls to the application being tested.
Next you will enable the fuzz testing.

## Enable coverage-guided fuzz testing

To enable coverage-guided fuzz testing, create a CI/CD pipeline running
the `gitlab-cov-fuzz` CLI to execute the fuzz test on the two fuzz targets.

To create the pipeline file:

1. Make sure you are in the `add-fuzz-test` branch.
1. In the root directory of the `fuzz-testing-demo` project, create a new file.
1. Name the file `.gitlab-ci.yml` and add the following code:

   ```yaml
   default:
     image: node:18

   stages:
     - fuzz

   include:
     - template: Coverage-Fuzzing.gitlab-ci.yml

   readme_fuzz_target:
     extends: .fuzz_base
     tags: [saas-linux-large-amd64] # Optional
     variables:
       COVFUZZ_ADDITIONAL_ARGS: '--fuzzTime=60'
     script:
       - npm config set @gitlab-org:registry https://gitlab.com/api/v4/packages/npm/ && npm i -g @gitlab-org/jsfuzz
       - ./gitlab-cov-fuzz run --engine jsfuzz -- fuzz-readme.js

   hello_fuzzing_target:
     extends: .fuzz_base
     tags: [saas-linux-large-amd64] # Optional
     variables:
       COVFUZZ_ADDITIONAL_ARGS: '--fuzzTime=60'
     script:
       - npm config set @gitlab-org:registry https://gitlab.com/api/v4/packages/npm/ && npm i -g @gitlab-org/jsfuzz
       - ./gitlab-cov-fuzz run --engine jsfuzz -- fuzz-sayhello.js
   ```

   This step adds the following to your pipeline:
   - A `fuzz` stage using a template.
   - Two jobs, `readme_fuzz_target` and `hello_fuzzing_target`. Each job runs using
     the `jsfuzz` engine, which reports unhandled exceptions as crashes.

   You can also copy this code from the `fuzz-testing-demo/fuzzers/fuzzers.yml`
   project file.

1. Write a descriptive commit message.
1. Make sure the **Target Branch** is `add-fuzz-test`.
1. Select **Commit changes**.

You have successfully enabled coverage-guided fuzz testing. Next you will run the
fuzz test using the pipeline you've just created.

## Run the fuzz test

To run the fuzz test:

1. On the left sidebar, select **Code > Merge requests**.
1. Select **New merge request**.
1. In the **Source branch** section, select the `add-fuzz-test` branch.
1. In the **Target branch** section, make sure that your namespace and the `main` branch are selected.
1. Select **Compare branches and continue**.
1. [Create the merge request](../../user/project/merge_requests/creating_merge_requests.md).

Creating the merge request triggers a new pipeline, which runs the fuzz test.
When the pipeline is finished running, you should see a security vulnerability
alert on the merge request page.

To see more information on each vulnerability, select the individual **Uncaught-exception** links.

You have successfully run the fuzz test and identified vulnerabilities to fix.

## Fix the vulnerabilities

The fuzz test identified two security vulnerabilities. To fix those
vulnerabilities, you use the `my-tools.js` library.

To create the `my-tools.js` file:

1. Make sure you are in the `add-fuzz-test` branch of the project.
1. Go to the root directory of your project and open the `my-tools.js` file.
1. Replace the contents of this file with the following code:

   ```javascript
   const fs = require('fs')

   function sayHello(name) {
     if(name.includes("z")) {
       //throw new Error("😡 error name: " + name)
       console.log("😡 error name: " + name)
     } else {
       return "😀 hello " + name
     }
   }

   function readmeContent(name) {

     let fileName = name => {
       if(name.includes("w")) {
         return "./README.txt"
       } else {
         return "./README.md"
       }
     }

     //const data = fs.readFileSync(fileName(name), 'utf8')
     try {
       const data = fs.readFileSync(fileName(name), 'utf8')
       return data
     } catch (err) {
       console.error(err.message)
       return ""
     }

   }

   module.exports = {
     sayHello, readmeContent
   }
   ```

   You can also copy the code from the `fuzz-testing-demo/javascript/my-tools.js`
   project file.

1. Select **Commit changes**. This triggers another pipeline to run another fuzz test.
1. When the pipeline is finished, check the merge request **Overview** page. You
   should see that the security scan detected no new potential vulnerabilities.
1. Merge your changes.

Congratulations, you've successfully run a fuzz test and fixed the identified
security vulnerabilities!

For more information, see [coverage-guided fuzz testing](../../user/application_security/coverage_fuzzing/_index.md).
