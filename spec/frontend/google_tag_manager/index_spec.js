import { merge } from 'lodash';
import { v4 as uuidv4 } from 'uuid';
import {
  trackFreeTrialAccountSubmissions,
  trackNewRegistrations,
  trackSaasTrialSubmit,
  trackSaasTrialSkip,
  trackSaasTrialGroup,
  trackSaasTrialProject,
  trackSaasTrialProjectImport,
  trackSaasTrialGetStarted,
  trackCheckout,
  trackTransaction,
} from '~/google_tag_manager';
import { setHTMLFixture } from 'helpers/fixtures';
import { logError } from '~/lib/logger';

jest.mock('~/lib/logger');
jest.mock('uuid');

describe('~/google_tag_manager/index', () => {
  let spy;

  beforeEach(() => {
    spy = jest.fn();

    window.dataLayer = {
      push: spy,
    };
    window.gon.features = {
      gitlabGtmDatalayer: true,
    };
  });

  const createHTML = ({ links = [], forms = [] } = {}) => {
    // .foo elements are used to test elements which shouldn't do anything
    const allLinks = links.concat({ cls: 'foo' });
    const allForms = forms.concat({ cls: 'foo' });

    const el = document.createElement('div');

    allLinks.forEach(({ cls = '', id = '', href = '#', text = 'Hello', attributes = {} }) => {
      const a = document.createElement('a');
      a.id = id;
      a.href = href || '#';
      a.className = cls;
      a.textContent = text;

      Object.entries(attributes).forEach(([key, value]) => {
        a.setAttribute(key, value);
      });

      el.append(a);
    });

    allForms.forEach(({ cls = '', id = '' }) => {
      const form = document.createElement('form');
      form.id = id;
      form.className = cls;

      el.append(form);
    });

    return el.innerHTML;
  };

  const triggerEvent = (selector, eventType) => {
    const el = document.querySelector(selector);

    el.dispatchEvent(new Event(eventType));
  };

  const getSelector = ({ id, cls }) => (id ? `#${id}` : `.${cls}`);

  const createTestCase = (subject, { forms = [], links = [] }) => {
    const expectedFormEvents = forms.map(({ expectation, ...form }) => ({
      selector: getSelector(form),
      trigger: 'submit',
      expectation,
    }));

    const expectedLinkEvents = links.map(({ expectation, ...link }) => ({
      selector: getSelector(link),
      trigger: 'click',
      expectation,
    }));

    return [
      subject,
      {
        forms,
        links,
        expectedEvents: [...expectedFormEvents, ...expectedLinkEvents],
      },
    ];
  };

  const createOmniAuthTestCase = (subject, accountType) =>
    createTestCase(subject, {
      forms: [
        {
          id: 'new_new_user',
          expectation: {
            event: 'accountSubmit',
            accountMethod: 'form',
            accountType,
          },
        },
      ],
      links: [
        {
          // id is needed so that the test selects the right element to trigger
          id: 'test-0',
          cls: 'js-oauth-login',
          attributes: {
            'data-provider': 'myspace',
          },
          expectation: {
            event: 'accountSubmit',
            accountMethod: 'myspace',
            accountType,
          },
        },
        {
          id: 'test-1',
          cls: 'js-oauth-login',
          attributes: {
            'data-provider': 'gitlab',
          },
          expectation: {
            event: 'accountSubmit',
            accountMethod: 'gitlab',
            accountType,
          },
        },
      ],
    });

  describe.each([
    createOmniAuthTestCase(trackFreeTrialAccountSubmissions, 'freeThirtyDayTrial'),
    createOmniAuthTestCase(trackNewRegistrations, 'standardSignUp'),
    createTestCase(trackSaasTrialSkip, {
      links: [{ cls: 'js-skip-trial', expectation: { event: 'saasTrialSkip' } }],
    }),
    createTestCase(trackSaasTrialGroup, {
      forms: [{ cls: 'js-saas-trial-group', expectation: { event: 'saasTrialGroup' } }],
    }),
    createTestCase(trackSaasTrialProject, {
      forms: [{ id: 'new_project', expectation: { event: 'saasTrialProject' } }],
    }),
    createTestCase(trackSaasTrialProjectImport, {
      links: [
        {
          id: 'js-test-btn-0',
          cls: 'js-import-project-btn',
          attributes: { 'data-platform': 'bitbucket' },
          expectation: { event: 'saasTrialProjectImport', saasProjectImport: 'bitbucket' },
        },
        {
          // id is neeeded so we trigger the right element in the test
          id: 'js-test-btn-1',
          cls: 'js-import-project-btn',
          attributes: { 'data-platform': 'github' },
          expectation: { event: 'saasTrialProjectImport', saasProjectImport: 'github' },
        },
      ],
    }),
    createTestCase(trackSaasTrialGetStarted, {
      links: [
        {
          cls: 'js-get-started-btn',
          expectation: { event: 'saasTrialGetStarted' },
        },
      ],
    }),
  ])('%p', (subject, { links = [], forms = [], expectedEvents }) => {
    beforeEach(() => {
      setHTMLFixture(createHTML({ links, forms }));

      subject();
    });

    it.each(expectedEvents)('when %p', ({ selector, trigger, expectation }) => {
      expect(spy).not.toHaveBeenCalled();

      triggerEvent(selector, trigger);

      expect(spy).toHaveBeenCalledTimes(1);
      expect(spy).toHaveBeenCalledWith(expectation);
      expect(logError).not.toHaveBeenCalled();
    });

    it('when random link is clicked, does nothing', () => {
      triggerEvent('a.foo', 'click');

      expect(spy).not.toHaveBeenCalled();
    });

    it('when random form is submitted, does nothing', () => {
      triggerEvent('form.foo', 'submit');

      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('No listener events', () => {
    it('when trackSaasTrialSubmit is invoked', () => {
      expect(spy).not.toHaveBeenCalled();

      trackSaasTrialSubmit();

      expect(spy).toHaveBeenCalledTimes(1);
      expect(spy).toHaveBeenCalledWith({ event: 'saasTrialSubmit' });
      expect(logError).not.toHaveBeenCalled();
    });

    describe('when trackCheckout is invoked', () => {
      it('with selectedPlan: 2c92a00d76f0d5060176f2fb0a5029ff', () => {
        expect(spy).not.toHaveBeenCalled();

        trackCheckout('2c92a00d76f0d5060176f2fb0a5029ff', 1);

        expect(spy.mock.calls.flatMap((x) => x)).toEqual([
          { ecommerce: null },
          {
            event: 'EECCheckout',
            currencyCode: 'USD',
            ecommerce: {
              checkout: {
                actionField: { step: 1 },
                products: [
                  {
                    brand: 'GitLab',
                    category: 'DevOps',
                    id: '0002',
                    name: 'Premium',
                    price: 228,
                    quantity: 1,
                    variant: 'SaaS',
                  },
                ],
              },
            },
          },
        ]);
      });

      it('with selectedPlan: 2c92a0ff76f0d5250176f2f8c86f305a', () => {
        expect(spy).not.toHaveBeenCalled();

        trackCheckout('2c92a0ff76f0d5250176f2f8c86f305a', 1);

        expect(spy).toHaveBeenCalledTimes(2);
        expect(spy).toHaveBeenCalledWith({ ecommerce: null });
        expect(spy).toHaveBeenCalledWith({
          event: 'EECCheckout',
          currencyCode: 'USD',
          ecommerce: {
            checkout: {
              actionField: { step: 1 },
              products: [
                {
                  brand: 'GitLab',
                  category: 'DevOps',
                  id: '0001',
                  name: 'Ultimate',
                  price: 1188,
                  quantity: 1,
                  variant: 'SaaS',
                },
              ],
            },
          },
        });
      });

      it('with selectedPlan: Something else', () => {
        expect(spy).not.toHaveBeenCalled();

        trackCheckout('Something else', 1);

        expect(spy).not.toHaveBeenCalled();
      });

      it('with a different number of users', () => {
        expect(spy).not.toHaveBeenCalled();

        trackCheckout('2c92a0ff76f0d5250176f2f8c86f305a', 5);

        expect(spy).toHaveBeenCalledTimes(2);
        expect(spy).toHaveBeenCalledWith({ ecommerce: null });
        expect(spy).toHaveBeenCalledWith({
          event: 'EECCheckout',
          currencyCode: 'USD',
          ecommerce: {
            checkout: {
              actionField: { step: 1 },
              products: [
                {
                  brand: 'GitLab',
                  category: 'DevOps',
                  id: '0001',
                  name: 'Ultimate',
                  price: 1188,
                  quantity: 5,
                  variant: 'SaaS',
                },
              ],
            },
          },
        });
      });
    });

    describe('when trackTransactions is invoked', () => {
      describe.each([
        {
          selectedPlan: '2c92a00d76f0d5060176f2fb0a5029ff',
          revenue: 228,
          name: 'Premium',
          id: '0002',
        },
        {
          selectedPlan: '2c92a0ff76f0d5250176f2f8c86f305a',
          revenue: 1188,
          name: 'Ultimate',
          id: '0001',
        },
      ])('with %o', (planObject) => {
        it('invokes pushes a new event that references the selected plan', () => {
          const { selectedPlan, revenue, name, id } = planObject;

          expect(spy).not.toHaveBeenCalled();
          uuidv4.mockImplementationOnce(() => '123');

          const transactionDetails = {
            paymentOption: 'visa',
            revenue,
            tax: 10,
            selectedPlan,
            quantity: 1,
          };

          trackTransaction(transactionDetails);

          expect(spy.mock.calls.flatMap((x) => x)).toEqual([
            { ecommerce: null },
            {
              event: 'EECtransactionSuccess',
              currencyCode: 'USD',
              ecommerce: {
                purchase: {
                  actionField: {
                    id: '123',
                    affiliation: 'GitLab',
                    option: 'visa',
                    revenue,
                    tax: 10,
                  },
                  products: [
                    {
                      brand: 'GitLab',
                      category: 'DevOps',
                      id,
                      name,
                      price: revenue,
                      quantity: 1,
                      variant: 'SaaS',
                    },
                  ],
                },
              },
            },
          ]);
        });
      });
    });

    describe('when trackTransaction is invoked', () => {
      describe('with an invalid plan object', () => {
        it('does not get called', () => {
          expect(spy).not.toHaveBeenCalled();

          trackTransaction({ selectedPlan: 'notAplan' });

          expect(spy).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe.each([
    { dataLayer: null },
    { gon: { features: null } },
    { gon: { features: { gitlabGtmDatalayer: false } } },
  ])('when window %o', (windowAttrs) => {
    beforeEach(() => {
      merge(window, windowAttrs);
    });

    it('no ops', () => {
      setHTMLFixture(createHTML({ forms: [{ id: 'new_project' }] }));

      trackSaasTrialProject();

      triggerEvent('#new_project', 'submit');

      expect(spy).not.toHaveBeenCalled();
      expect(logError).not.toHaveBeenCalled();
    });
  });

  describe('when window.dataLayer throws error', () => {
    const pushError = new Error('test');

    beforeEach(() => {
      window.dataLayer = {
        push() {
          throw pushError;
        },
      };
    });

    it('logs error', () => {
      setHTMLFixture(createHTML({ forms: [{ id: 'new_project' }] }));

      trackSaasTrialProject();

      triggerEvent('#new_project', 'submit');

      expect(logError).toHaveBeenCalledWith(
        'Unexpected error while pushing to dataLayer',
        pushError,
      );
    });
  });
});
