import { GlLink } from '@gitlab/ui';
import events from 'test_fixtures/controller/users/activity.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { EVENT_TYPE_APPROVED } from '~/contribution_events/constants';
import TargetLink from '~/contribution_events/components/target_link.vue';

const eventApproved = events.find((event) => event.action === EVENT_TYPE_APPROVED);

describe('TargetLink', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(TargetLink, {
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

    expect(link.attributes()).toMatchObject({
      href: eventApproved.target.web_url,
      title: eventApproved.target.title,
    });
    expect(link.text()).toBe(eventApproved.target.reference_link_text);
  });
});
