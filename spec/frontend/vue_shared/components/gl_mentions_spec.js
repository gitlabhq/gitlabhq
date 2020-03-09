import { shallowMount } from '@vue/test-utils';
import Tribute from 'tributejs';
import GlMentions from '~/vue_shared/components/gl_mentions.vue';

describe('GlMentions', () => {
  let wrapper;

  describe('Tribute', () => {
    const mentions = '/gitlab-org/gitlab-test/-/autocomplete_sources/members?type=Issue&type_id=1';

    beforeEach(() => {
      wrapper = shallowMount(GlMentions, {
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
