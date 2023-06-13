import { GlLink } from '@gitlab/ui';
import events from 'test_fixtures/controller/users/activity.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { EVENT_TYPE_APPROVED } from '~/contribution_events/constants';
import ResourceParentLink from '~/contribution_events/components/resource_parent_link.vue';

const eventApproved = events.find((event) => event.action === EVENT_TYPE_APPROVED);

describe('ResourceParentLink', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ResourceParentLink, {
      propsData: {
        event: eventApproved,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders link', () => {
    const link = wrapper.findComponent(GlLink);

    expect(link.attributes('href')).toBe(eventApproved.resource_parent.web_url);
    expect(link.text()).toBe(eventApproved.resource_parent.full_name);
  });
});
