# After setup

After you set up the [database replication and configure the GitLab Geo nodes][req],
there are a few things to consider:

1. When you create a new project in the primary node, the Git repository will
   appear in the secondary only _after_ the first `git push`.
1. You need an extra step to be able to fetch code from the `secondary` and push
   to `primary`:

     1. Clone your repository as you would normally do from the `secondary` node
     1. Change the remote push URL following this example:

         ```bash
         git remote set-url --push origin git@primary.gitlab.example.com:user/repo.git
         ```

[req]: README.md#setup-instructions
