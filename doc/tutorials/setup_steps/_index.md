---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Set up CI/CD Functions'
---

This tutorial shows you how to create and use functions in your pipelines.

Steps are reusable and composable pieces of a job. Each function defines structured inputs and
outputs that can be consumed by other functions. You can configure functions in local files, GitLab.com repositories,
or any other Git source.

In this tutorial, use the GitLab CLI (`glab`) to:

1. Create a function that outputs "hello world".
1. Configure a pipeline to use the function.
1. Add multiple functions to a job.
1. Use a remote function to echo all the outputs.

## Before you begin

- You must install and sign in to the [GitLab CLI](../../editor_extensions/gitlab_cli/_index.md) (`glab`).

## Create a function

First, create a function with:

- An `exec` type.
- A `command` that's started by the executive API of the system.

1. Create a GitLab project named `zero-to-steps` in your namespace:

   ```shell
   glab project create zero-to-steps
   ```

1. Go to the root of the project repository:

   ```shell
   cd zero-to-steps
   ```

1. Create a `step.yml` file.

   ```shell
   touch step.yml
   ```

1. Use a text editor to add a specification to the `step.yml`:

   ```yaml
   spec:
     inputs:
       who:
         type: string
         default: world
   ```

   - `spec` has one input called `who`.
   - The input `who` is optional because there is a default value.

1. To add an implementation to the `step.yml`, add a second YAML document after `spec`, with the `exec` key:

   ```yaml
   spec:
     inputs:
       who:
         type: string
         default: world
   ---
   exec:
     command:
       - bash
       - -c
       - echo 'hello ${{inputs.who}}'
   ```

The triple em dash (`---`) separates the file into two YAML documents:

- The first document is the specification, like a function signature.
- The second document is the implementation, like a function body.

The `bash` and `-c` arguments start a Bash shell and take the script input from the command line arguments.
In addition to shell scripts, you can use `command` to execute programs like `docker` or `terraform`.

The `echo 'hello ${{input.name}}'` argument includes an expression inside `${{` and `}}`.
Expressions are evaluated at the last possible moment and have access to the current execution context.
This expression accesses `inputs` and reads the value of `who`:

- If `who` is provided by the caller, that value is substituted for the expression.
- If `who` is omitted, then the default `world` is substituted for the expression instead.

## Configure a pipeline to use the function

1. In the root of the repository, create a `.gitlab-ci.yml` file:

   ```shell
   touch .gitlab-ci.yml
   ```

1. In the `.gitlab-ci.yml`, add the following job:

   ```yaml
   hello-world:
     run:
       - name: hello_world
         step: .
   ```

   - The `run` keyword has a list of function invocations.
     - Each invocation is given a `name` so you can reference the outputs in later functions.
     - Each invocation specifies a `step` to run. A local reference (`.`) points to the root of the repository.

   For an example of how this code should look in your repository, see the [Steps tutorial, part 1](https://gitlab.com/gitlab-org/step-runner/-/tree/main/examples/tutorial_part_1).

1. Commit both files and push the project repository. This triggers a pipeline that runs the job:

   ```shell
   git add .
   git commit -m 'Part 1 complete'
   git push --set-upstream origin main
   glab ci status
   ```

1. Follow the job under "View Logs" until the pipeline completes. Here's an example of a successful job:

   ```shell
   Step Runner version: a7c7c8fd
   See https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md for changes.
   ...
   hello world
   Cleaning up project directory and file based variables
   Job succeeded
   ```

You've now created and used your first function!

## Add multiple functions to a job

You can have more than one function in a job.

1. In the `.gitlab-ci.yml` file, add another function called `hello_steps` to your job:

   ```yaml
   hello-world:
     run:
       - name: hello_world
         step: .
       - name: hello_steps
         step: .
         inputs:
           who: gitlab functions
   ```

   This `hello_steps` function provides a non-default input `who` of `gitlab functions`.

   For an example of how this code should look in your repository, see the [Steps tutorial, part 2a](https://gitlab.com/gitlab-org/step-runner/-/tree/main/examples/tutorial_part_2a).

1. Commit and push the changes:

   ```shell
   git commit -a -m 'Added another function'
   git push
   glab ci status
   ```

1. In the terminal, select **View Logs** and follow the pipeline until it completes. Here's an example of a successful output:

   ```shell
   Step Runner version: a7c7c8fd
   See https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md for changes.
   ...
   hello world
   hello gitlab functions
   Cleaning up project directory and file based variables
   Job succeeded
   ```

## Refactor your function

To refactor your functions, move them from the `.gitlab-ci.yml` to a dedicated file:

1. Move the first function you created to a directory called `hello`:

   ```shell
   mkdir hello
   mv step.yml hello/
   ```

1. Create a new function at the root of the repository.

   ```shell
   touch step.yml
   ```

1. Add the following configuration to the new `step.yml`:

   ```yaml
   spec:
   ---
   run:
     - name: hello_world
       step: ./hello
     - name: hello_steps
       step: ./hello
       inputs:
         who: gitlab functions
   ```

   This new function has no inputs, so the `spec` is empty.
   It is a `steps` type, which has the same syntax as functions in `.gitlab-ci.yml`.
   However, the local reference now points to your function in the `hello` directory.

1. To use the new function, modify `.gitlab-ci.yml`:

   ```yaml
   hello-world:
     run:
       - name: hello_everybody
         step: .
   ```

   Now your job invokes only the new function with no inputs.
   You've refactored the details of the job into a separate file.

   For an example of how this code should look in your repository, see the [Steps tutorial, part 2b](https://gitlab.com/gitlab-org/step-runner/-/tree/main/examples/tutorial_part_2b).

1. Commit and push the changes:

   ```shell
   git add .
   git commit -m 'Refactored function config'
   git push
   glab ci status
   ```

1. In the terminal, select **View Logs**.
1. To verify that the refactored function performs the same function as the function you first created, view the log output. The log output should match the output of the function you created previously. Here's an example:

   ```shell
   $ /step-runner ci
   hello world
   hello gitlab functions
   Cleaning up project directory and file based variables
   Job succeeded
   ```

### Add an output to the function

Add an output to your `hello` function.

1. In `hello/step.yml`, add an `outputs` structure to the `spec`:

   ```yaml
   spec:
     inputs:
       who:
         type: string
         default: world
     outputs:
       greeting:
         type: string
   ---
   exec:
     command:
       - bash
       - -c
       - echo '{"name":"greeting","value":"hello ${{inputs.who}}"}' | tee ${{output_file}}
   ```

   - In this `spec`, you've defined a single output `greeting` without a default. Because
     there is no default, the output `greeting` is required.
   - Outputs are written to the `${{output_file}}` file provided at run time in JSON Line format. Each line written to the
     output file must be a JSON object with two keys, `name` and `value`.
   - This function runs `echo '{"name":"greeting","value":"hello ${{inputs.who}}"}'` and sends the output to the job log and
     the output file (`tee ${{output_file}}`).

1. In `step.yml`, add an output to the step:

   ```yaml
   spec:
     outputs:
       all_greetings:
         type: string
   ---
   run:
     - name: hello_world
       step: ./hello
     - name: hello_steps
       step: ./hello
       inputs:
         who: gitlab functions
   outputs:
     all_greetings: "${{steps.hello_world.outputs.greeting}} and ${{steps.hello_steps.outputs.greeting}}"
   ```

   You've now added an output to this function called `all_greetings`.

   This output shows the expression syntax: `${{steps.hello_world.outputs.greeting}}`.
   `all_greetings` reads the outputs of the two sub-steps, `hello_world` and `hello_steps`.
   Both sub-step outputs are concatenated into a single string output.

## Use a remote function

Before you commit and run your code, add another function to your job to see the final `all_greetings` output of your main
`step.yml`.

This function invocation references a remote function named `echo-step`.
The echo function takes a single input `echo`, prints it to the logs, and outputs it as `echo`.

1. Edit the `.gitlab-ci.yml`:

   ```yaml
   hello-world:
     run:
       - name: hello_everybody
         step: .
       - name: all_my_greetings
         step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@main
         inputs:
           echo: "all my greetings say ${{steps.hello_everybody.outputs.all_greetings}}"
   ```

   For an example of how this code should look in your repository, see the [Steps tutorial, part 2c](https://gitlab.com/gitlab-org/step-runner/-/tree/main/examples/tutorial_part_2c).

1. Commit and push the changes:

   ```shell
   git commit -a -m 'Added outputs'
   git push
   glab ci status
   ```

1. Follow the job under "View Logs" until the pipeline completes. Here's an example of a successful output:

   ```shell
   Step Runner version: a7c7c8fd
   See https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md for changes.
   ...
   {"name":"greeting","value":"hello world"}
   {"name":"greeting","value":"hello gitlab functions"}
   all my greetings say hello world and hello gitlab functions
   Cleaning up project directory and file based variables
   Job succeeded
   ```

That's it! You've just created and implemented functions in your pipeline.
For more information about the syntax for functions, see [CI/CD Steps](../../ci/steps/_index.md).
