import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MetadataDatabaseAlert from '~/packages_and_registries/shared/components/container_registry_metadata_database_alert.vue';
import * as utils from '~/lib/utils/common_utils';

describe('container registry metadata database alert', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(MetadataDatabaseAlert);
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('with no cookie set', () => {
    beforeEach(() => {
      utils.setCookie = jest.fn();

      mountComponent();
    });

    it('displays the alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('does not call setCookie', () => {
      expect(utils.setCookie).not.toHaveBeenCalled();
    });

    describe('when the close button is clicked', () => {
      beforeEach(() => {
        findAlert().vm.$emit('dismiss');
      });

      it('sets the dismissed cookie', () => {
        expect(utils.setCookie).toHaveBeenCalledWith('hide_metadata_database_alert', 'true');
      });

      it('does not display the alert', () => {
        expect(findAlert().exists()).toBe(false);
      });
    });
  });

  describe('with the dismissed cookie set', () => {
    beforeEach(() => {
      jest.spyOn(utils, 'getCookie').mockReturnValue('true');

      mountComponent();
    });

    it('does not display the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });
});
