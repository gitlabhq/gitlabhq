import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';
import { EVENT_TYPE_PRIVATE } from '~/contribution_events/constants';
import { eventApproved } from '../utils';

describe('ResourceParentLink', () => {
  let wrapper;

  const defaultPropsData = {
    event: eventApproved(),
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ResourceParentLink, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  describe('when resource parent is defined', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders link', () => {
      const link = wrapper.findComponent(GlLink);
      const { web_url, full_name } = defaultPropsData.event.resource_parent;

      expect(link.attributes('href')).toBe(web_url);
      expect(link.text()).toBe(full_name);
    });
  });

  describe('when resource parent is not defined', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          event: {
            type: EVENT_TYPE_PRIVATE,
          },
        },
      });
    });

    it('renders nothing', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});
