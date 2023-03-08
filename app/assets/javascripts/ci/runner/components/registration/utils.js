/* eslint-disable @gitlab/require-i18n-strings */
import {
  DEFAULT_PLATFORM,
  LINUX_PLATFORM,
  MACOS_PLATFORM,
  WINDOWS_PLATFORM,
  DOWNLOAD_LOCATIONS,
} from '../../constants';
import linuxInstall from './scripts/linux/install.sh?raw';
import osxInstall from './scripts/osx/install.sh?raw';
import windowsInstall from './scripts/windows/install.ps1?raw';

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
    ...(registrationToken ? [`  --registration-token ${registrationToken}`] : []),
  ];
};

export const runCommand = ({ platform }) => {
  return `${executable({ platform })} run`;
};

const importInstallScript = ({ platform = DEFAULT_PLATFORM }) => {
  switch (platform) {
    case LINUX_PLATFORM:
      return linuxInstall;
    case MACOS_PLATFORM:
      return osxInstall;
    case WINDOWS_PLATFORM:
      return windowsInstall;
    default:
      return '';
  }
};

export const platformArchitectures = ({ platform }) => {
  return DOWNLOAD_LOCATIONS[platform].map(({ arch }) => arch);
};

export const installScript = ({ platform, architecture }) => {
  const downloadLocation = DOWNLOAD_LOCATIONS[platform].find(({ arch }) => arch === architecture)
    .url;

  return importInstallScript({ platform })
    .replace(
      // eslint-disable-next-line no-template-curly-in-string
      '${GITLAB_CI_RUNNER_DOWNLOAD_LOCATION}',
      downloadLocation,
    )
    .trim();
};
