export const mockGraphqlRunnerPlatforms = {
  data: {
    runnerPlatforms: {
      nodes: [
        {
          name: 'linux',
          humanReadableName: 'Linux',
          architectures: {
            nodes: [
              {
                name: 'amd64',
                downloadLocation:
                  'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64',
                __typename: 'RunnerArchitecture',
              },
              {
                name: '386',
                downloadLocation:
                  'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-386',
                __typename: 'RunnerArchitecture',
              },
              {
                name: 'arm',
                downloadLocation:
                  'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-arm',
                __typename: 'RunnerArchitecture',
              },
              {
                name: 'arm64',
                downloadLocation:
                  'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-arm64',
                __typename: 'RunnerArchitecture',
              },
            ],
            __typename: 'RunnerArchitectureConnection',
          },
          __typename: 'RunnerPlatform',
        },
        {
          name: 'osx',
          humanReadableName: 'macOS',
          architectures: {
            nodes: [
              {
                name: 'amd64',
                downloadLocation:
                  'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-darwin-amd64',
                __typename: 'RunnerArchitecture',
              },
            ],
            __typename: 'RunnerArchitectureConnection',
          },
          __typename: 'RunnerPlatform',
        },
        {
          name: 'windows',
          humanReadableName: 'Windows',
          architectures: {
            nodes: [
              {
                name: 'amd64',
                downloadLocation:
                  'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe',
                __typename: 'RunnerArchitecture',
              },
              {
                name: '386',
                downloadLocation:
                  'https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-386.exe',
                __typename: 'RunnerArchitecture',
              },
            ],
            __typename: 'RunnerArchitectureConnection',
          },
          __typename: 'RunnerPlatform',
        },
        {
          name: 'docker',
          humanReadableName: 'Docker',
          architectures: null,
          __typename: 'RunnerPlatform',
        },
        {
          name: 'kubernetes',
          humanReadableName: 'Kubernetes',
          architectures: null,
          __typename: 'RunnerPlatform',
        },
      ],
      __typename: 'RunnerPlatformConnection',
    },
    project: { id: 'gid://gitlab/Project/1', __typename: 'Project' },
    group: null,
  },
};

export const mockGraphqlInstructions = {
  data: {
    runnerSetup: {
      installInstructions:
        "# Download the binary for your system\nsudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64\n\n# Give it permissions to execute\nsudo chmod +x /usr/local/bin/gitlab-runner\n\n# Create a GitLab CI user\nsudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash\n\n# Install and run as service\nsudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner\nsudo gitlab-runner start\n",
      registerInstructions:
        'sudo gitlab-runner register --url http://192.168.1.81:3000/ --registration-token GE5gsjeep_HAtBf9s3Yz',
      __typename: 'RunnerSetup',
    },
  },
};
