# Performance testing tools for AI features

## Code Suggestions

These tests are based on [examples from testing of the Code Suggestions Model Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/77).

### Apache Bench

If you're using a Mac you may already have the [Apache Bench](https://httpd.apache.org/docs/current/programs/ab.html) tool installed:

```shell
$ which ab
/usr/sbin/ab
```

#### Build a Docker image

If you don't already have Apache Bench installed, [`Dockerfile.ab`](Dockerfile.ab) allows you to build a Docker image that you can use to run it.

To build the image, from the `qa/perf/ai` directory run:

```shell
docker build -t ab -f Dockerfile.ab .
```

That will create an image named `ab`. When you start a container via `docker run <image>` any arguments that follow will be passed to `ab` inside
the container. The command in the section below assumes you have Apache Bench installed, but you can use the image you built if you
add `docker run --rm` in front of the command. For example, instead of `ab -n 1000 ...` use `docker run --rm ab -n 1000 ...`.

### Run tests

WARNING:
Be mindful of the potential impact before running a performance test. It could disrupt accessibility for other users and could be problematic for our use of third-party services. If you're unsure, consult the relevant teams (those working on the Code Suggestions feature, the [AI-powered:AI Framework](https://about.gitlab.com/handbook/product/categories/#ai-framework-group) group, the [Create:Code Creation](https://about.gitlab.com/handbook/product/categories/#code-creation-group) group, and the [`#g_code_suggestions` Slack channel (internal)](https://gitlab.slack.com/archives/C048Z2DHWGP))

To run performance tests using Apache Bench, execute the following from the `qa/perf/ai` directory:

```shell
export GITLAB_PAT=<your personal access token>
export URL=<the code suggestions endpoint to test>
ab -n 1000 -c 20 -H "Authorization: Bearer $GITLAB_PAT" -T 'application/json' -p prompt.json $URL
```

For example, if `$URL` were `https://staging.gitlab.com/api/v4/code_suggestions/completions` that command would `POST` 1000 requests, 20 at a time, to the staging Code Suggestions completions endpoint, using the data in [`prompt.json`](prompt.json) as the prompt.
