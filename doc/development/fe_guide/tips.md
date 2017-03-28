# Tips and Tricks

Assorted tips and tricks

## Disable webpack live reload

```
DEV_SERVER_LIVERELOAD=false gdk run db
```

You can also add the variable to your profile (`.bash_profile`)


## Use local network IP instead of localhost

See [!27729](https://gitlab.com/gitlab-org/gitlab-ce/issues/27729)

 1. [`echo 0.0.0.0 > host` before `gdk run` (this was the normal step before webpack)](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/local_network.md)
 1. Update [`webpack.config.js` -> `config.devServer.host`](https://gitlab.com/gitlab-org/gitlab-ce/blob/80427fbd20920a99f0c02866217ade695b774707/config/webpack.config.js#L117) to local network IP.
 1. Update `config/gitlab.yml` -> [`gitlab.host`](https://gitlab.com/gitlab-org/gitlab-ce/blob/80427fbd20920a99f0c02866217ade695b774707/config/gitlab.yml.example#L32), [`webpack.dev_server.host`](https://gitlab.com/gitlab-org/gitlab-ce/blob/80427fbd20920a99f0c02866217ade695b774707/config/gitlab.yml.example#L530) to local network IP


## Testing CI/CD features locally

### Programmatic pipelines/jobs

`MockCI` isn't the same as GitLab CI and is instead considered an external service/integration
just like Jenkins or Drone. You can setup the `MockCI` integration in your project settings
and get the a simple web server running to respond to the endpoint like the [`gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service)

For more info, [see docs](user/project/integrations/mock_ci.md)


### Review apps and deployments

In order to have a project with review apps you can clone the [`review-apps-nginx` project](https://gitlab.com/gitlab-examples/review-apps-nginx/) to you local gdk and follow the steps on the README.


### Getting coverage reports

If you need to have `coverage` information in Pipeline data in your localhost, simply add a `echo "(92.22%) covered"` line to your `.gitlab-ci.yml` -> `script` section. Don't forget to use Ruby regex in CI/CD settings tab.

![](https://imgur.com/khrs5jj.png)

via https://gitlab.slack.com/archives/C0GQHHPGW/p1490641512105452
