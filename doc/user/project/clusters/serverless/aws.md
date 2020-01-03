# Deploying AWS Lambda function using GitLab CI/CD

GitLab allows users to easily deploy AWS Lambda functions and create rich serverless applications.

GitLab supports deployment of functions to AWS Lambda using a combination of:

- [Serverless Framework with AWS](https://serverless.com/framework/docs/providers/aws/)
- GitLab CI/CD

We have prepared an example with a step-by-step guide to create a simple function and deploy it on AWS.

Additionally, in the [How To section](#how-to), you can read about different use cases,
like:

- Running a function locally.
- Working with secrets.
- Setting up CORS.

Alternatively, you can quickly [create a new project with a template](https://docs.gitlab.com/ee/gitlab-basics/create-project.html#project-templates). The [`Serverless Framework/JS` template](https://gitlab.com/gitlab-org/project-templates/serverless-framework/) already includes all parts described below.

## Example

In the following example, you will:

1. Create a basic AWS Lambda Node.js function.
1. Link the function to an API Gateway `GET` endpoint.

### Steps

The example consists of the following steps:

1. Creating a Lambda handler function
1. Creating a `serverless.yml` file
1. Crafting the `.gitlab-ci.yml` file
1. Setting up your AWS credentials with your GitLab account
1. Deploying your function
1. Testing the deployed function

Lets take it step by step.

### Creating a Lambda handler function

Your Lambda function will be the primary handler of requests. In this case we will create a very simple Node.js `hello` function:

```javascript
'use strict';

module.exports.hello = async event => {
  return {
    statusCode: 200,
    body: JSON.stringify(
      {
        message: 'Your function executed successfully!'
      },
      null,
      2
    ),
  };
};
```

Place this code in the file `src/handler.js`.

`src` is the standard location for serverless functions, but is customizable should you desire that.

In our case, `module.exports.hello` defines the `hello` handler that will be referenced later in the `serverless.yml`

You can learn more about the AWS Lambda Node.js function handler and all its various options here: <https://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-handler.html>

### Creating a `serverless.yml` file

In the root of your project, create a `serverless.yml` file that will contain configuration specifics for the Serverless Framework.

Put the following code in the file:

```yaml
service: gitlab-example
provider:
  name: aws
  runtime: nodejs10.x
  
functions:
  hello:
    handler: src/handler.hello
    events:
      - http: GET hello
```

Our function contains a handler and a event.

The handler definition will provision the Lambda function using the source code located `src/handler.hello`.

The `events` declaration will create a AWS API Gateway `GET` endpoint to receive external requests and hand them over to the Lambda function via a service integration.

You can read more about the available properties and additional configuration possibilities of the Serverless Framework here: <https://serverless.com/framework/docs/providers/aws/guide/serverless.yml/>

### Crafting the `.gitlab-ci.yml` file

In a `.gitlab-ci.yml` file in the root of your project, place the following code:

```yaml
image: node:latest

stages:
  - deploy

production:
  stage: deploy
  before_script:
    - npm config set prefix /usr/local
    - npm install -g serverless
  script:
    - serverless deploy --stage production --verbose
  environment: production
```

This example code does the following:

1. Uses the `node:latest` image for all GitLab CI builds
1. The `deploy` stage:
   - Installs the Serverless Framework.
   - Deploys the serverless function to your AWS account using the AWS credentials
     defined above.

### Setting up your AWS credentials with your GitLab account

In order to interact with your AWS account, the GitLab CI/CD pipelines require both `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to be defined in your GitLab settings under **Settings > CI/CD > Variables**.
For more information please see: <https://docs.gitlab.com/ee/ci/variables/README.html#via-the-ui>

NOTE: **Note:**
   The AWS credentials you provide must include IAM policies that provision correct access control to AWS Lambda, API Gateway, CloudFormation, and IAM resources.

### Deploying your function

`git push` the changes to your GitLab repository and the GitLab build pipeline will automatically deploy your function.

In your GitLab deploy stage log, there will be output containing your AWS Lambda endpoint URL.
The log line will look similar to this:

```
endpoints:
  GET - https://u768nzby1j.execute-api.us-east-1.amazonaws.com/production/hello
```

### Manually testing your function

Running the following `curl` command should trigger your function.

NOTE: **Note:**
  Your url should be the one retrieved from the GitLab deploy stage log.

```sh
curl https://u768nzby1j.execute-api.us-east-1.amazonaws.com/production/hello
```

That should output:

```json
{
  "message": "Your function executed successfully!"
}
```

Hooray! You now have a AWS Lambda function deployed via GitLab CI.

Nice work!

## How To

In this section, we show you how to build on the basic example to:

- Run the function locally.
- Set up secret variables.
- Set up CORS.

### Running function locally

The `serverless-offline` plugin allows to run your code locally. To run your code locally:

1. Add the following to your `serverless.yml`:

   ```yaml
   plugins:
     - serverless-offline
   ```

1. Start the service by running the following command:

   ```shell
   serverless offline
   ```

Running the following `curl` command should trigger your function.

```sh
curl http://localhost:3000/hello
```

It should output:

```json
{
  "message": "Your function executed successfully!"
}
```

### Secret variables

Secrets are injected into your functions using environment variables.

By defining variables in the provider section of the `serverless.yml`, you add them to
the environment of the deployed function:

```yaml
provider:
  ...
  environment:
    A_VARIABLE: ${env:A_VARIABLE}
```

From there, you can reference them in your functions as well.
Remember to add `A_VARIABLE` to your GitLab CI variables under **Settings > CI/CD > Variables**, and it will get picked up and deployed with your function.

NOTE: **Note:**
Anyone with access to the AWS environemnt may be able to see the values of those
variables persisted in the lambda definition.

### Setting up CORS

If you want to set up a web page that makes calls to your function, like we have done in the [template](https://gitlab.com/gitlab-org/project-templates/serverless-framework/), you need to deal with the Cross-Origin Resource Sharing (CORS).

The quick way to do that is to add the `cors: true` flag to the HTTP endpoint in your `serverless.yml`:

```yaml
functions:
  hello:
    handler: src/handler.hello
    events:
      - http: # Rewrite this part to enable CORS
          path: hello
          method: get
          cors: true # <-- CORS here
```

You also need to return CORS specific headers in your function response:

```javascript
'use strict';

module.exports.hello = async event => {
  return {
    statusCode: 200,
    headers: {
      // Uncomment the line below if you need access to cookies or authentication
      // 'Access-Control-Allow-Credentials': true,
      'Access-Control-Allow-Origin': '*'
    },
    body: JSON.stringify(
      {
        message: 'Your function executed successfully!'
      },
      null,
      2
    ),
  };
};
```

For more information, see the [Your CORS and API Gateway survival guide](https://serverless.com/blog/cors-api-gateway-survival-guide/)
blog post written by the Serverless Framework team.

### Writing automated tests

The [Serverless Framework](https://gitlab.com/gitlab-org/project-templates/serverless-framework/)
example project shows how to use Jest, Axios, and `serverless-offline` plugin to do
automated testing of both local and deployed serverless function.

## Examples and template

The example code is available:

- As a [cloneable repository](https://gitlab.com/gitlab-org/serverless/examples/serverless-framework-js).
- In a version with [tests and secret variables](https://gitlab.com/gitlab-org/project-templates/serverless-framework/).

You can also use a [template](https://docs.gitlab.com/ee/gitlab-basics/create-project.html#project-templates)
(based on the version with tests and secret variables) from within the GitLab UI (see
the `Serverless Framework/JS` template).
