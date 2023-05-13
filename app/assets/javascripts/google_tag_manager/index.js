import { v4 as uuidv4 } from 'uuid';
import { logError } from '~/lib/logger';

const SKU_PREMIUM = '2c92a00d76f0d5060176f2fb0a5029ff';
const SKU_ULTIMATE = '2c92a0ff76f0d5250176f2f8c86f305a';
const PRODUCT_INFO = {
  [SKU_PREMIUM]: {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    name: 'Premium',
    id: '0002',
    price: '228',
    variant: 'SaaS',
  },
  [SKU_ULTIMATE]: {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    name: 'Ultimate',
    id: '0001',
    price: '1188',
    variant: 'SaaS',
  },
};
const EMPTY_NAMESPACE_ID_VALUE = 'not available';

const generateProductInfo = (sku, quantity) => {
  const product = PRODUCT_INFO[sku];

  if (!product) {
    logError('Unexpected product sku provided to generateProductInfo');
    return {};
  }

  const productInfo = {
    ...product,
    brand: 'GitLab',
    category: 'DevOps',
    quantity,
  };

  return productInfo;
};

const isSupported = () => Boolean(window.dataLayer) && gon.features?.gitlabGtmDatalayer;
// gon.features.gitlabGtmDatalayer is set by writing
// `push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)`
// to the appropriate controller
// window.dataLayer is set by adding partials to the appropriate view found in
// views/layouts/_google_tag_manager_body.html.haml and _google_tag_manager_head.html.haml

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

const pushEnhancedEcommerceEvent = (event, args = {}) => {
  if (!window.dataLayer) {
    return;
  }

  try {
    window.dataLayer.push({ ecommerce: null }); // Clear the previous ecommerce object
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

  pushEvent('saasTrialSubmit');
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

export const trackProjectImport = () => {
  if (!isSupported()) {
    return;
  }

  const importButtons = document.querySelectorAll('.js-import-project-btn');
  importButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const { platform } = button.dataset;
      pushEvent('projectImport', { platform });
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

export const trackTrialAcceptTerms = () => {
  if (!isSupported()) {
    return;
  }

  pushEvent('saasTrialAcceptTerms');
};

export const trackCheckout = (selectedPlan, quantity) => {
  if (!isSupported()) {
    return;
  }

  const product = generateProductInfo(selectedPlan, quantity);

  if (Object.keys(product).length === 0) {
    return;
  }

  const eventData = {
    ecommerce: {
      currencyCode: 'USD',
      checkout: {
        actionField: { step: 1 },
        products: [product],
      },
    },
  };

  // eslint-disable-next-line @gitlab/require-i18n-strings
  pushEnhancedEcommerceEvent('EECCheckout', eventData);
};

export const getNamespaceId = () => {
  return window.gl.snowplowStandardContext?.data?.namespace_id || EMPTY_NAMESPACE_ID_VALUE;
};

export const trackTransaction = (transactionDetails) => {
  if (!isSupported()) {
    return;
  }

  const transactionId = uuidv4();
  const { paymentOption, revenue, tax, selectedPlan, quantity } = transactionDetails;
  const product = generateProductInfo(selectedPlan, quantity);
  const namespaceId = getNamespaceId();

  if (Object.keys(product).length === 0) {
    return;
  }

  const eventData = {
    ecommerce: {
      currencyCode: 'USD',
      purchase: {
        actionField: {
          id: transactionId,
          affiliation: 'GitLab',
          option: paymentOption,
          revenue: revenue.toString(),
          tax: tax.toString(),
        },
        products: [{ ...product, dimension36: namespaceId }],
      },
    },
  };

  pushEnhancedEcommerceEvent('EECtransactionSuccess', eventData);
};

export const pushEECproductAddToCartEvent = () => {
  if (!isSupported()) {
    return;
  }

  window.dataLayer.push({
    event: 'EECproductAddToCart',
    ecommerce: {
      currencyCode: 'USD',
      add: {
        products: [
          {
            name: 'CI/CD Minutes',
            id: '0003',
            price: '10',
            brand: 'GitLab',
            category: 'DevOps',
            variant: 'add-on',
            quantity: 1,
          },
        ],
      },
    },
  });
};

export const trackAddToCartUsageTab = () => {
  const getStartedButton = document.querySelector('.js-buy-additional-minutes');
  if (!getStartedButton) {
    return;
  }
  getStartedButton.addEventListener('click', pushEECproductAddToCartEvent);
};

export const trackCombinedGroupProjectForm = () => {
  if (!isSupported()) {
    return;
  }

  const form = document.querySelector('.js-groups-projects-form');
  form.addEventListener('submit', () => {
    pushEvent('combinedGroupProjectFormSubmit');
  });
};

export const trackCompanyForm = (aboutYourCompanyType) => {
  if (!isSupported()) {
    return;
  }

  pushEvent('aboutYourCompanyFormSubmit', { aboutYourCompanyType });
};

export const saasTrialWelcome = () => {
  if (!isSupported()) {
    return;
  }

  const saasTrialWelcomeButton = document.querySelector('.js-trial-welcome-btn');

  saasTrialWelcomeButton?.addEventListener('click', () => {
    pushEvent('saasTrialWelcome');
  });
};

export const saasTrialContinuousOnboarding = () => {
  if (!isSupported()) {
    return;
  }

  const getStartedButton = document.querySelector('.js-get-started-btn');

  getStartedButton?.addEventListener('click', () => {
    pushEvent('saasTrialContinuousOnboarding');
  });
};
