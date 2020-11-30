import { shallowMount } from '@vue/test-utils';
import Tribute from 'tributejs';
import GfmAutocomplete from '~/vue_shared/components/gfm_autocomplete/gfm_autocomplete.vue';

describe('GfmAutocomplete', () => {
  let wrapper;

  describe('tribute', () => {
    const mentions = '/gitlab-org/gitlab-test/-/autocomplete_sources/members?type=Issue&type_id=1';

    beforeEach(() => {
      wrapper = shallowMount(GfmAutocomplete, {
        propsData: {
          dataSources: {
            mentions,
          },
        },
        slots: {
          default: ['<input/>'],
        },
      });
    });

    it('is set to tribute instance variable', () => {
      expect(wrapper.vm.tribute instanceof Tribute).toBe(true);
    });

    it('contains the slot input element', () => {
      wrapper.find('input').setValue('@');

      expect(wrapper.vm.tribute.current.element).toBe(wrapper.find('input').element);
    });
  });
});
