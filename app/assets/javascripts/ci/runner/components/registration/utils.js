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
    shell: 'bash',
    commandPrompt: '$',
    executable: 'gitlab-runner',
  },
  [MACOS_PLATFORM]: {
    shell: 'bash',
    commandPrompt: '$',
    executable: 'gitlab-runner',
  },
  [WINDOWS_PLATFORM]: {
    shell: 'powershell',
    commandPrompt: '>',
    executable: '.\\gitlab-runner.exe',
  },
};

const escapedParam = (param, shell = 'bash') => {
  let escaped;
  if (shell === 'bash') {
    // replace single-quotes by the sequence '\''
    escaped = param.replaceAll("'", "'\\''");
  } else if (shell === 'powershell') {
    // replace single-quotes by the sequence ''
    // https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_quoting_rules?view=powershell-7.3
    escaped = param.replaceAll("'", "''");
  }
  // surround with single quotes.
  return `'${escaped}'`;
};

export const commandPrompt = ({ platform }) => {
  return (OS[platform] || OS[DEFAULT_PLATFORM]).commandPrompt;
};

export const executable = ({ platform }) => {
  return (OS[platform] || OS[DEFAULT_PLATFORM]).executable;
};

const shell = ({ platform }) => {
  return (OS[platform] || OS[DEFAULT_PLATFORM]).shell;
};

export const registerCommand = ({
  platform,
  url = gon.gitlab_url,
  registrationToken,
  description,
}) => {
  const lines = [`${executable({ platform })} register`]; // eslint-disable-line @gitlab/require-i18n-strings
  if (url) {
    lines.push(`  --url ${url}`);
  }
  if (registrationToken) {
    lines.push(`  --registration-token ${registrationToken}`);
  }
  if (description) {
    const escapedDescription = escapedParam(description, shell({ platform }));
    lines.push(`  --description ${escapedDescription}`);
  }
  return lines;
};

export const runCommand = ({ platform }) => {
  return `${executable({ platform })} run`; // eslint-disable-line @gitlab/require-i18n-strings
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
