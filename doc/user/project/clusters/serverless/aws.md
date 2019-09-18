# Deploying AWS Lambda function using GitLab CI/CD

GitLab allows users to easily deploy AWS Lambda functions and create rich serverless applications.

GitLab supports deployment of functions to AWS Lambda using a combination of:

- [Serverless Framework](https://serverless.com)
- GitLab CI/CD

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
1. Testing your function

Lets take it step by step.

### Creating a Lambda handler function

Your Lambda function will be the primary handler of requests. In this case we will create a very simple Node.js "Hello" function:

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

### Creating a serverless.yml file

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

### Crafting the .gitlab-ci.yml file

In a `.gitlab-ci.yml` file, place the following code:

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

- Installs the `serverless framework`.
- Deploys the serverless function to your AWS account using the AWS credentials defined above.

### Setting up your AWS credentials with your GitLab account

In order to interact with your AWS account, the .gitlab-ci.yml requires both `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` be defined in your GitLab settings under **Settings > CI/CD > Variables**.
For more information please see: <https://docs.gitlab.com/ee/ci/variables/README.html#via-the-ui>

NOTE: **Note:**
   The AWS credentials you provide must include IAM policies that provision correct access control to AWS Lambda, API Gateway, and CloudFormation resources.

### Deploying your function

Deploying your function is very simple, just `git push` to your GitLab repository and the GitLab build pipeline will automatically deploy your function.

In your GitLab deploy stage log, there will be output containing your AWS Lambda endpoint URL.
The log line will look similar to this:

```
endpoints:
  GET - https://u768nzby1j.execute-api.us-east-1.amazonaws.com/production/hello
```

### Testing your function

Running the following `curl` command should trigger your function.

NOTE: **Note:**
  Your url should be the one retrieved from the GitLab deploy stage log.

```sh
curl https://u768nzby1j.execute-api.us-east-1.amazonaws.com/production/hello
```

Should output:

```json
{
  "message": "Your function executed successfully!"
}
```

Hooray! You now have a AWS Lambda function deployed via GitLab CI.

Nice work!

## Example code

To see the example code for this example please follow the link below:

- [Node.js example](https://gitlab.com/gitlab-org/serverless/examples/serverless-framework-js): Deploy a AWS Lambda Javascript function + API Gateway using Serverless Framework and GitLab CI/CD
