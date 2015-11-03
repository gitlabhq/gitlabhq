# GitLab Pages

To start using GitLab Pages add to your project .gitlab-ci.yml with special pages job.

    pages:
      image: jekyll
      script: jekyll build
      artifacts:
        paths:
        - public

TODO
