---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial: Set up CI/CD steps

This tutorial shows you how to create and use steps in your pipelines.

Steps are reusable and composable pieces of a job. Each step defines structured inputs and
outputs that can be consumed by other steps. You can configure steps in local files, GitLab.com repositories,
or any other Git source.

In this tutorial, use the GitLab CLI (`glab`) to:

1. Create a step that outputs "hello world".
1. Configure a pipeline to use the step.
1. Add multiple steps to a job.
1. Use a remote step to echo all the outputs.

## Before you begin

To complete this tutorial, you must install [GitLab CLI](../../editor_extensions/gitlab_cli/index.md) (`glab`)
and be signed in.

## Create a step

First, create a step with:

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
         default: world
   ```

    - `spec` has one input called `who`.
    - The input `who` is optional because there is a default value.

1. To add an implementation to the `step.yml`, add a second YAML document after `spec`, with the `exec` key:

    ```yaml
    spec:
      inputs:
        who:
          default: world
    ---
    exec:
      command:
        - bash
        - -c
        - "echo hello ${{ inputs.who }}"
    ```

The triple em dash (`---`) separates the file into two YAML documents:

- The first document is the specification, like a function signature.
- The second document is the implementation, like a function body.

The `bash` and `-c` arguments start a Bash shell and take the script input from the command line arguments.
In addition to shell scripts, you can use `command` to execute programs like `docker` or `terraform`.

The `"echo hello ${{ input.name }}"` argument includes an expression inside `${{` and `}}`.
Expressions are evaluated at the last possible moment and have access to the current execution context.
This expression accesses `inputs` and reads the value of `who`:

- If `who` is provided by the caller, that value is substituted for the expression.
- If `who` is omitted, then the default `world` is substituted for the expression instead.

## Configure a pipeline to use the step

1. In the root of the repository, create a `.gitlab-ci.yml` file:

   ```shell
   touch .gitlab-ci.yml
   ```

1. In the `.gitlab-ci.yml`, add the following job:

   ```yaml
    hello-world:
      variables:
        STEPS:
          expand: false
          value: |
            - name: hello_world
              step: .
      image: registry.gitlab.com/gitlab-org/step-runner:v0
      script:
        - /step-runner ci
   ```

   - The steps are given in an environment variable called `STEPS`. `STEPS` is a list of step invocations.
     - Each invocation is given a `name` so you can reference the outputs in later steps.
     - Each invocations specifies a `step` to run. A local reference (`.`) points to the root of the repository.
   - The job script invokes `step-runner ci` which is in the `step-runner:v0` image.

   For an example of how this code should look in your repository, see [this example](https://gitlab.com/josephburnett/zero-to-steps/-/tree/part-1?ref_type=tags).

1. Commit both files and push the project repository. This triggers a pipeline that runs the job:

    ```shell
    git add .
    git commit -m 'Part 1 complete'
    git push --set-upstream origin master
    glab ci status
    ```

1. Follow the job under "View Logs" until the pipeline completes. Here's an example of a successful job:

   ```shell
   $ /step-runner ci
   hello world
   trace written to step-results.json
   Cleaning up project directory and file based variables
   Job succeeded
   ```

NOTE:
Usage of an environment variable is a temporary work-around until the `run` keyword is implemented.
See [the `run` keyword epic](https://gitlab.com/groups/gitlab-org/-/epics/11846).

You've now created and used your first step!

## Add multiple steps to a job

You can have more than one step in a job.

1. In the `.gitlab-ci.yml` file, add another step called `hello_steps` to your job:

   ```yaml
   hello-world:
     variables:
       STEPS:
         expand: false
         value: |
           - name: hello_world
             step: .
           - name: hello_steps
             step: .
             inputs:
               who: gitlab steps
     image: registry.gitlab.com/gitlab-org/step-runner:v0
     script:
       - /step-runner ci
   ```

   This `hello_steps` step provides a non-default input `who` of `gitlab steps`.

   For an example of how this code should look in your repository, see [this example](https://gitlab.com/josephburnett/zero-to-steps/-/tree/part-2-a?ref_type=tags).

1. Commit and push the changes:

   ```shell
   git commit -a -m 'Added another step'
   git push
   glab ci status
   ```

1. In the terminal, select **View Logs** and follow the pipeline until it completes. Here's an example of a successful output:

   ```shell
   $ /step-runner ci
   hello world
   hello gitlab steps
   trace written to step-results.json
   Cleaning up project directory and file based variables
   Job succeeded
   ```

## Refactor your step

To refactor your steps, move them from the `.gitlab-ci.yml` to a dedicated file:
To refactor your steps by moving them from CI Config into a dedicated file:

1. Move the first step you created to a directory called `hello`:

   ```shell
   mkdir hello
   mv step.yml hello/
   ```

1. Create a new step at the root of the repository.

   ```shell
   touch step.yml
   ```

1. Add the following configuration to the new `step.yml`:

   ```yaml
   spec: {}
   ---
   steps:
     - name: hello_world
       step: ./hello
     - name: hello_steps
       step: ./hello
       inputs:
         who: gitlab steps
   ```

   This new step has no inputs, so the `spec` is empty (`{}`).
   It is a `steps` type, which has the same syntax as steps in `.gitlab-ci.yml`.
   However, the local reference now points to your step in the `hello` directory.

1. To use the new step, modify `.gitlab-ci.yml`:

   ```yaml
   hello-world:
     variables:
        STEPS:
          expand: false
          value: |
            - name: hello_everybody
              step: .
     image: registry.gitlab.com/gitlab-org/step-runner:v0
     script:
       - /step-runner ci
   ```

   Now your job invokes only the new step with no inputs.
   You've refactored the details of the job into a separate file.

   For an example of how this code should look in your repository, see [this example](https://gitlab.com/josephburnett/zero-to-steps/-/tree/part-2-b?ref_type=tags).

1. Commit and push the changes:

   ```shell
   git add .
   git commit -m 'Refactored step config'
   git push
   glab ci status
   ```

1. In the terminal, select **View Logs**.
1. To verify that the refactored step performs the same function as the step you first created, view the log output. The log output should match the output of the step you created previously. Here's an example:

   ```shell
   $ /step-runner ci
   hello world
   hello gitlab steps
   trace written to step-results.json
   Cleaning up project directory and file based variables
   Job succeeded
   ```

### Add an output to the step

Add an output to your `hello` step.

1. In `hello/step.yml`, add an `outputs` structure to the `spec`:

   ```yaml
   spec:
     inputs:
       who:
         default: world
     outputs:
       greeting: {}
   ---
   exec:
     command:
       - bash
       - -c
       - "echo greeting=hello ${{ inputs.who }} | tee ${{ output_file }}"
   ```

   - In this `spec`, you've defined a single output `greeting` without a default. Because
     there is no default, the output `greeting` is required.
   - Outputs are written to a file `${{ output_file }}` (provided at run time) in the form `key=value`.
   - This step runs `echo greeting=hello ${{ inputs.name }}` and sends the output to the logs and the output file (`tee ${{ output_file }}`).

1. In `step.yml`, add an output to the step:

   ```yaml
   spec:
     outputs:
       all_greetings: {}
   ---
   steps:
     - name: hello_world
       step: ./hello
     - name: hello_steps
       step: ./hello
       inputs:
         who: gitlab steps
   outputs:
     all_greetings: "${{ steps.hello_world.outputs.greeting }} and ${{ steps.hello_steps.outputs.greeting }}"
   ```

You've now added an output to this step called `all_greetings`.

This output shows the use of a new expression syntax: `${{ steps.hello_world.outputs.greeting }}`.
This expression reads the `outputs` of the two sub-steps, `hello_world` and `hello_steps`.
Both sub-step outputs are concatenated into a single string output.

## Use a remote step

Before you commit and run your code, add another step to your job to see the final `all_greetings` output of your main `step.yml`.

This step invocation references a remote step named `echo-step`.
The echo step takes a single input `echo`, prints it to the logs, and outputs it as `echo`.

1. Edit the `.gitlab-ci.yml`:

   ```yaml
   hello-world:
     variables:
       STEPS:
         expand: false
         value: |
           - name: hello_everybody
             step: .
           - name: all_my_greetings
             step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@master
             inputs:
               echo: "all my greetings say ${{ steps.hello_everybody.outputs.all_greetings }}"
     image: registry.gitlab.com/gitlab-org/step-runner:v0
     script:
       - /step-runner ci
   ```

   For an example of how this code should look in your repository, see [this example](https://gitlab.com/josephburnett/zero-to-steps/-/tree/part-2-c?ref_type=tags).

1. Commit and push the changes:

   ```shell
   git commit -a -m 'Added outputs'
   git push
   glab ci status
   ```

1. Follow the job under "View Logs" until the pipeline completes completes. Here's an example of a successful output:

   ```shell
   $ /step-runner ci
   greeting=hello world
   greeting=hello gitlab steps
   echo=all my greetings say hello world and hello gitlab steps
   trace written to step-results.json
   Cleaning up project directory and file based variables
   Job succeeded
   ```

That's it! You've just created and implemented steps in your pipeline.
For more information about the syntax for steps, see [CI/CD Steps](../../ci/steps/index.md).
