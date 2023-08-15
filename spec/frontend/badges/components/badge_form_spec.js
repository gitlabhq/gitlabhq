import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import { DUMMY_IMAGE_URL, TEST_HOST } from 'helpers/test_constants';
import BadgeForm from '~/badges/components/badge_form.vue';
import createEmptyBadge from '~/badges/empty_badge';

import createState from '~/badges/store/state';
import mutations from '~/badges/store/mutations';
import actions from '~/badges/store/actions';

import axios from '~/lib/utils/axios_utils';

Vue.use(Vuex);

describe('BadgeForm component', () => {
  let axiosMock;
  let mockedActions;
  let wrapper;

  const createComponent = (propsData, customState = {}) => {
    mockedActions = Object.fromEntries(Object.keys(actions).map((name) => [name, jest.fn()]));

    const store = new Vuex.Store({
      state: {
        ...createState(),
        ...customState,
      },
      mutations,
      actions: mockedActions,
    });

    wrapper = mount(BadgeForm, {
      store,
      propsData,
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('stops editing when cancel button is clicked', async () => {
    createComponent({ isEditing: true });

    const cancelButton = wrapper.findAll('[data-testid="action-buttons"] button').at(1);

    await cancelButton.trigger('click');

    expect(mockedActions.stopEditing).toHaveBeenCalled();
  });

  const sharedSubmitTests = (submitAction, props) => {
    const nameSelector = '#badge-name';
    const imageUrlSelector = '#badge-image-url';
    const findImageUrl = () => wrapper.find(imageUrlSelector);
    const linkUrlSelector = '#badge-link-url';
    const findLinkUrl = () => wrapper.find(linkUrlSelector);
    const setValue = (inputElementSelector, value) => {
      const input = wrapper.find(inputElementSelector);
      return input.setValue(value);
    };
    const submitForm = () => {
      const submitButton = wrapper.find('button[type="submit"]');
      return submitButton.trigger('click');
    };
    const expectInvalidInput = (inputElementSelector) => {
      const input = wrapper.find(inputElementSelector);

      expect(input.element.checkValidity()).toBe(false);
      const feedbackElement = wrapper.find(`${inputElementSelector} + .invalid-feedback`);

      expect(feedbackElement.isVisible()).toBe(true);
    };

    beforeEach(() => {
      createComponent(props, {
        badgeInAddForm: createEmptyBadge(),
        badgeInEditForm: createEmptyBadge(),
        isSaving: false,
      });

      setValue(nameSelector, 'TestBadge');
      setValue(linkUrlSelector, `${TEST_HOST}/link/url`);
      setValue(imageUrlSelector, `${window.location.origin}${DUMMY_IMAGE_URL}`);
    });

    it('returns immediately if imageUrl is empty', async () => {
      await setValue(imageUrlSelector, '');

      await submitForm();

      expectInvalidInput(imageUrlSelector);

      expect(mockedActions[submitAction]).not.toHaveBeenCalled();
    });

    it('returns immediately if imageUrl is malformed', async () => {
      await setValue(imageUrlSelector, 'not-a-url');

      await submitForm();

      expectInvalidInput(imageUrlSelector);

      expect(mockedActions[submitAction]).not.toHaveBeenCalled();
    });

    it('returns immediately if linkUrl is empty', async () => {
      await setValue(linkUrlSelector, '');

      await submitForm();

      expectInvalidInput(linkUrlSelector);

      expect(mockedActions[submitAction]).not.toHaveBeenCalled();
    });

    it('returns immediately if linkUrl is malformed', async () => {
      await setValue(linkUrlSelector, 'not-a-url');

      await submitForm();

      expectInvalidInput(linkUrlSelector);

      expect(mockedActions[submitAction]).not.toHaveBeenCalled();
    });

    it(`calls ${submitAction}`, async () => {
      await submitForm();

      expect(findImageUrl().element.checkValidity()).toBe(true);
      expect(findLinkUrl().element.checkValidity()).toBe(true);
      expect(mockedActions[submitAction]).toHaveBeenCalled();
    });
  };

  describe('if isEditing is false', () => {
    const props = { isEditing: false };

    it('renders two buttons', () => {
      createComponent(props);

      expect(wrapper.find('.row-content-block').exists()).toBe(false);
      const buttons = wrapper.findAll('[data-testid="action-buttons"] button');

      expect(buttons).toHaveLength(2);
      const buttonAddWrapper = buttons.at(0);

      expect(buttonAddWrapper.isVisible()).toBe(true);
      expect(buttonAddWrapper.text()).toBe('Add badge');
    });

    sharedSubmitTests('addBadge', props);
  });

  describe('if isEditing is true', () => {
    const props = { isEditing: true };

    it('renders two buttons', () => {
      createComponent(props);
      const buttons = wrapper.findAll('[data-testid="action-buttons"] button');

      expect(buttons).toHaveLength(2);

      const saveButton = buttons.at(0);
      expect(saveButton.isVisible()).toBe(true);
      expect(saveButton.text()).toBe('Save changes');

      const cancelButton = buttons.at(1);
      expect(cancelButton.isVisible()).toBe(true);
      expect(cancelButton.text()).toBe('Cancel');
    });

    sharedSubmitTests('saveBadge', props);
  });
});
