import { shallowMount } from '@vue/test-utils';
import { GlNewButton } from '@gitlab/ui';

import PublishToolbar from '~/static_site_editor/components/publish_toolbar.vue';

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

  const findSaveChangesButton = () => wrapper.find(GlNewButton);

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

  describe('when saveable', () => {
    it('enables Submit Changes button', () => {
      buildWrapper({ saveable: true });

      expect(findSaveChangesButton().attributes('disabled')).toBeFalsy();
    });
  });
});
