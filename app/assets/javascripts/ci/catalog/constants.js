// We disable this for the entire file until the mock data is cleanup
/* eslint-disable @gitlab/require-i18n-strings */
export const CATALOG_FEEDBACK_DISMISSED_KEY = 'catalog_feedback_dismissed';

export const componentsMockData = {
  __typename: 'CiComponentConnection',
  nodes: [
    {
      id: 'gid://gitlab/Ci::Component/1',
      name: 'Ruby gal',
      description: 'This is a pretty amazing component that does EVERYTHING ruby.',
      path: 'gitlab.com/gitlab-org/ruby-gal@~latest',
      inputs: { nodes: [{ name: 'version', defaultValue: '1.0.0', required: true }] },
    },
    {
      id: 'gid://gitlab/Ci::Component/2',
      name: 'Javascript madness',
      description: 'Adds some spice to your life.',
      path: 'gitlab.com/gitlab-org/javascript-madness@~latest',
      inputs: {
        nodes: [
          { name: 'isFun', defaultValue: 'true', required: true },
          { name: 'RandomNumber', defaultValue: '10', required: false },
        ],
      },
    },
    {
      id: 'gid://gitlab/Ci::Component/3',
      name: 'Go go go',
      description: 'When you write Go, you gotta go go go.',
      path: 'gitlab.com/gitlab-org/go-go-go@~latest',
      inputs: { nodes: [{ name: 'version', defaultValue: '1.0.0', required: true }] },
    },
  ],
};
