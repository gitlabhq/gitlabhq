import { shallowMount } from '@vue/test-utils';
import { GlNewButton, GlLoadingIcon } from '@gitlab/ui';

import PublishToolbar from '~/static_site_editor/components/publish_toolbar.vue';

import { returnUrl } from '../mock_data';

describe('Static Site Editor Toolbar', () => {
  let wrapper;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(PublishToolbar, {
      propsData: {
        saveable: false,
        ...propsData,
      },
    });
  };

  const findReturnUrlLink = () => wrapper.find({ ref: 'returnUrlLink' });
  const findSaveChangesButton = () => wrapper.find(GlNewButton);
  const findLoadingIndicator = () => wrapper.find(GlLoadingIcon);

  beforeEach(() => {
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders Submit Changes button', () => {
    expect(findSaveChangesButton().exists()).toBe(true);
  });

  it('disables Submit Changes button', () => {
    expect(findSaveChangesButton().attributes('disabled')).toBe('true');
  });

  it('does not display saving changes indicator', () => {
    expect(findLoadingIndicator().classes()).toContain('invisible');
  });

  it('does not render returnUrl link', () => {
    expect(findReturnUrlLink().exists()).toBe(false);
  });

  it('renders returnUrl link when returnUrl prop exists', () => {
    buildWrapper({ returnUrl });

    expect(findReturnUrlLink().exists()).toBe(true);
    expect(findReturnUrlLink().attributes('href')).toBe(returnUrl);
  });

  describe('when saveable', () => {
    it('enables Submit Changes button', () => {
      buildWrapper({ saveable: true });

      expect(findSaveChangesButton().attributes('disabled')).toBeFalsy();
    });
  });

  describe('when saving changes', () => {
    beforeEach(() => {
      buildWrapper({ saveable: true, savingChanges: true });
    });

    it('disables Submit Changes button', () => {
      expect(findSaveChangesButton().attributes('disabled')).toBe('true');
    });

    it('displays saving changes indicator', () => {
      expect(findLoadingIndicator().classes()).not.toContain('invisible');
    });
  });

  it('emits submit event when submit button is clicked', () => {
    buildWrapper({ saveable: true });

    findSaveChangesButton().vm.$emit('click');

    expect(wrapper.emitted('submit')).toHaveLength(1);
  });
});
