import { shallowMount } from '@vue/test-utils';

import PublishToolbar from '~/static_site_editor/components/publish_toolbar.vue';

import { returnUrl } from '../mock_data';

describe('Static Site Editor Toolbar', () => {
  let wrapper;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(PublishToolbar, {
      propsData: {
        hasSettings: false,
        saveable: false,
        ...propsData,
      },
    });
  };

  const findReturnUrlLink = () => wrapper.find({ ref: 'returnUrlLink' });
  const findSaveChangesButton = () => wrapper.find({ ref: 'submit' });
  const findEditSettingsButton = () => wrapper.find({ ref: 'settings' });

  beforeEach(() => {
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('does not render Settings button', () => {
    expect(findEditSettingsButton().exists()).toBe(false);
  });

  it('renders Submit Changes button', () => {
    expect(findSaveChangesButton().exists()).toBe(true);
  });

  it('disables Submit Changes button', () => {
    expect(findSaveChangesButton().attributes('disabled')).toBe('true');
  });

  it('does not render the Submit Changes button with a loader', () => {
    expect(findSaveChangesButton().props('loading')).toBe(false);
  });

  it('does not render returnUrl link', () => {
    expect(findReturnUrlLink().exists()).toBe(false);
  });

  it('renders returnUrl link when returnUrl prop exists', () => {
    buildWrapper({ returnUrl });

    expect(findReturnUrlLink().exists()).toBe(true);
    expect(findReturnUrlLink().attributes('href')).toBe(returnUrl);
  });

  describe('when providing settings CTA', () => {
    it('enables Submit Changes button', () => {
      buildWrapper({ hasSettings: true });

      expect(findEditSettingsButton().exists()).toBe(true);
    });
  });

  describe('when saveable', () => {
    it('enables Submit Changes button', () => {
      buildWrapper({ saveable: true });

      expect(findSaveChangesButton().attributes('disabled')).toBeFalsy();
    });
  });

  describe('when saving changes', () => {
    beforeEach(() => {
      buildWrapper({ savingChanges: true });
    });

    it('renders the Submit Changes button with a loading indicator', () => {
      expect(findSaveChangesButton().props('loading')).toBe(true);
    });
  });

  it('emits submit event when submit button is clicked', () => {
    buildWrapper({ saveable: true });

    findSaveChangesButton().vm.$emit('click');

    expect(wrapper.emitted('submit')).toHaveLength(1);
  });
});
