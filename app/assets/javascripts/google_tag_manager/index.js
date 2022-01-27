import { logError } from '~/lib/logger';

const SKU_PREMIUM = '2c92a00d76f0d5060176f2fb0a5029ff';
const SKU_ULTIMATE = '2c92a0ff76f0d5250176f2f8c86f305a';
const PRODUCT_INFO = {
  [SKU_PREMIUM]: {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    name: 'Premium',
    id: '0002',
    price: 228,
    variant: 'SaaS',
  },
  [SKU_ULTIMATE]: {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    name: 'Ultimate',
    id: '0001',
    price: 1188,
    variant: 'SaaS',
  },
};

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

const pushEnhancedEcommerceEvent = (event, currencyCode, args = {}) => {
  if (!window.dataLayer) {
    return;
  }

  try {
    window.dataLayer.push({ ecommerce: null });
    window.dataLayer.push({
      event,
      currencyCode,
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

  pushEvent('saasTrialSubmit');
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

export const trackCheckout = (selectedPlan, quantity) => {
  if (!isSupported()) {
    return;
  }

  const product = PRODUCT_INFO[selectedPlan];

  if (!product) {
    logError('Unexpected product sku provided to trackCheckout');
    return;
  }

  const selectedProductData = {
    ...product,
    brand: 'GitLab',
    category: 'DevOps',
    quantity,
  };

  const eventData = {
    ecommerce: {
      checkout: {
        actionField: { step: 1 },
        products: [selectedProductData],
      },
    },
  };

  // eslint-disable-next-line @gitlab/require-i18n-strings
  pushEnhancedEcommerceEvent('EECCheckout', 'USD', eventData);
};
