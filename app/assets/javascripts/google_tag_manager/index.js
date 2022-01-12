import { logError } from '~/lib/logger';

const isSupported = () => Boolean(window.dataLayer) && gon.features?.gitlabGtmDatalayer;

const pushEvent = (event, args = {}) => {
  if (!window.dataLayer) {
    return;
  }

  try {
    window.dataLayer.push({
      event,
      ...args,
    });
  } catch (e) {
    logError('Unexpected error while pushing to dataLayer', e);
  }
};

const pushAccountSubmit = (accountType, accountMethod) =>
  pushEvent('accountSubmit', { accountType, accountMethod });

const trackFormSubmission = (accountType) => {
  const form = document.getElementById('new_new_user');
  form.addEventListener('submit', () => {
    pushAccountSubmit(accountType, 'form');
  });
};

const trackOmniAuthSubmission = (accountType) => {
  const links = document.querySelectorAll('.js-oauth-login');
  links.forEach((link) => {
    const { provider } = link.dataset;
    link.addEventListener('click', () => {
      pushAccountSubmit(accountType, provider);
    });
  });
};

export const trackFreeTrialAccountSubmissions = () => {
  if (!isSupported()) {
    return;
  }

  trackFormSubmission('freeThirtyDayTrial');
  trackOmniAuthSubmission('freeThirtyDayTrial');
};

export const trackNewRegistrations = () => {
  if (!isSupported()) {
    return;
  }

  trackFormSubmission('standardSignUp');
  trackOmniAuthSubmission('standardSignUp');
};

export const trackSaasTrialSubmit = () => {
  if (!isSupported()) {
    return;
  }

  const form = document.getElementById('new_trial');
  form.addEventListener('submit', () => {
    pushEvent('saasTrialSubmit');
  });
};

export const trackSaasTrialSkip = () => {
  if (!isSupported()) {
    return;
  }

  const skipLink = document.querySelector('.js-skip-trial');
  skipLink.addEventListener('click', () => {
    pushEvent('saasTrialSkip');
  });
};

export const trackSaasTrialGroup = () => {
  if (!isSupported()) {
    return;
  }

  const form = document.querySelector('.js-saas-trial-group');
  form.addEventListener('submit', () => {
    pushEvent('saasTrialGroup');
  });
};

export const trackSaasTrialProject = () => {
  if (!isSupported()) {
    return;
  }

  const form = document.getElementById('new_project');
  form.addEventListener('submit', () => {
    pushEvent('saasTrialProject');
  });
};

export const trackSaasTrialProjectImport = () => {
  if (!isSupported()) {
    return;
  }

  const importButtons = document.querySelectorAll('.js-import-project-btn');
  importButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const { platform } = button.dataset;
      pushEvent('saasTrialProjectImport', { saasProjectImport: platform });
    });
  });
};

export const trackSaasTrialGetStarted = () => {
  if (!isSupported()) {
    return;
  }

  const getStartedButton = document.querySelector('.js-get-started-btn');
  getStartedButton.addEventListener('click', () => {
    pushEvent('saasTrialGetStarted');
  });
};
