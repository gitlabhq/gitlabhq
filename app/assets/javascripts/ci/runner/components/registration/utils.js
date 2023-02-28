import {
  DEFAULT_PLATFORM,
  LINUX_PLATFORM,
  MACOS_PLATFORM,
  WINDOWS_PLATFORM,
} from '../../constants';

/* eslint-disable @gitlab/require-i18n-strings */
const OS = {
  [LINUX_PLATFORM]: {
    commandPrompt: '$',
    executable: 'gitlab-runner',
  },
  [MACOS_PLATFORM]: {
    commandPrompt: '$',
    executable: 'gitlab-runner',
  },
  [WINDOWS_PLATFORM]: {
    commandPrompt: '>',
    executable: '.\\gitlab-runner.exe',
  },
};

export const commandPrompt = ({ platform }) => {
  return (OS[platform] || OS[DEFAULT_PLATFORM]).commandPrompt;
};

export const executable = ({ platform }) => {
  return (OS[platform] || OS[DEFAULT_PLATFORM]).executable;
};

export const registerCommand = ({ platform, url = gon.gitlab_url, registrationToken }) => {
  return [
    `${executable({ platform })} register`,
    `  --url ${url}`,
    `  --registration-token ${registrationToken}`,
  ];
};

export const runCommand = ({ platform }) => {
  return `${executable({ platform })} run`;
};
/* eslint-enable @gitlab/require-i18n-strings */
