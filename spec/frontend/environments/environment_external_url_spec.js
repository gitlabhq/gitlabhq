import { mount } from '@vue/test-utils';
import { s__, __ } from '~/locale';
import ExternalUrlComp from '~/environments/components/environment_external_url.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

describe('External URL Component', () => {
  let wrapper;
  let externalUrl;

  describe('with safe link', () => {
    beforeEach(() => {
      externalUrl = 'https://gitlab.com';
      wrapper = mount(ExternalUrlComp, { propsData: { externalUrl } });
    });

    it('should link to the provided externalUrl prop', () => {
      expect(wrapper.attributes('href')).toBe(externalUrl);
      expect(wrapper.find('a').exists()).toBe(true);
    });
  });

  describe('with unsafe link', () => {
    beforeEach(() => {
      externalUrl = 'postgres://gitlab';
      wrapper = mount(ExternalUrlComp, { propsData: { externalUrl } });
    });

    it('should show a copy button instead', () => {
      const button = wrapper.findComponent(ModalCopyButton);
      expect(button.props('text')).toBe(externalUrl);
      expect(button.text()).toBe(__('Copy URL'));
      expect(button.props('title')).toBe(s__('Environments|Copy live environment URL'));
    });
  });
});
