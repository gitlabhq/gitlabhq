import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TargetLink from '~/contribution_events/components/target_link.vue';
import { eventApproved, eventPushed } from '../utils';

describe('TargetLink', () => {
  let wrapper;

  const defaultPropsData = {
    event: eventApproved(),
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(TargetLink, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  describe('when target is defined', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders link', () => {
      const link = findLink();
      const { web_url: webUrl, title, reference_link_text } = defaultPropsData.event.target;

      expect(link.attributes()).toMatchObject({
        href: webUrl,
        title,
      });
      expect(link.text()).toBe(reference_link_text);
    });
  });

  describe('when target type is not defined', () => {
    beforeEach(() => {
      const event = { ...eventPushed(), target: {} };
      createComponent({ propsData: { event } });
    });

    it('renders nothing', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});
