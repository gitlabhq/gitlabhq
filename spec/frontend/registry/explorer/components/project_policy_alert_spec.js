import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlSprintf, GlAlert, GlLink } from '@gitlab/ui';
import * as dateTimeUtils from '~/lib/utils/datetime_utility';
import component from '~/registry/explorer/components/project_policy_alert.vue';
import {
  EXPIRATION_POLICY_ALERT_TITLE,
  EXPIRATION_POLICY_ALERT_PRIMARY_BUTTON,
} from '~/registry/explorer/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Project Policy Alert', () => {
  let wrapper;
  let store;

  const defaultState = {
    config: {
      expirationPolicy: {
        enabled: true,
      },
      settingsPath: 'foo',
      expirationPolicyHelpPagePath: 'bar',
    },
    images: [],
    isLoading: false,
  };

  const findAlert = () => wrapper.find(GlAlert);
  const findLink = () => wrapper.find(GlLink);

  const createComponent = (state = defaultState) => {
    store = new Vuex.Store({
      state,
    });
    wrapper = shallowMount(component, {
      localVue,
      store,
      stubs: {
        GlSprintf,
      },
    });
  };

  const documentationExpectation = () => {
    it('contain a documentation link', () => {
      createComponent();
      expect(findLink().attributes('href')).toBe(defaultState.config.expirationPolicyHelpPagePath);
      expect(findLink().text()).toBe('documentation');
    });
  };

  beforeEach(() => {
    jest.spyOn(dateTimeUtils, 'approximateDuration').mockReturnValue('1 day');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('is hidden', () => {
    it('when expiration policy does not exist', () => {
      createComponent({ config: {} });
      expect(findAlert().exists()).toBe(false);
    });

    it('when expiration policy exist but is disabled', () => {
      createComponent({
        ...defaultState,
        config: {
          expirationPolicy: {
            enabled: false,
          },
        },
      });
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('is visible', () => {
    it('when expiration policy exists and is enabled', () => {
      createComponent();
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('full info alert', () => {
    beforeEach(() => {
      createComponent({ ...defaultState, images: [1] });
    });

    it('has a primary button', () => {
      const alert = findAlert();
      expect(alert.props('primaryButtonText')).toBe(EXPIRATION_POLICY_ALERT_PRIMARY_BUTTON);
      expect(alert.props('primaryButtonLink')).toBe(defaultState.config.settingsPath);
    });

    it('has a title', () => {
      const alert = findAlert();
      expect(alert.props('title')).toBe(EXPIRATION_POLICY_ALERT_TITLE);
    });

    it('has the full message', () => {
      expect(findAlert().html()).toContain('<strong>1 day</strong>');
    });

    documentationExpectation();
  });

  describe('compact info alert', () => {
    beforeEach(() => {
      createComponent({ ...defaultState, images: [] });
    });

    it('does not have a button', () => {
      const alert = findAlert();
      expect(alert.props('primaryButtonText')).toBe(null);
    });

    it('does not have a title', () => {
      const alert = findAlert();
      expect(alert.props('title')).toBe(null);
    });

    it('has the short message', () => {
      expect(findAlert().html()).not.toContain('<strong>1 day</strong>');
    });

    documentationExpectation();
  });
});
