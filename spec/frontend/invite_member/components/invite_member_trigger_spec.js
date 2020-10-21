import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';
import InviteMemberTrigger from '~/invite_member/components/invite_member_trigger.vue';
import triggerProvides from './invite_member_trigger_mock_data';

const createComponent = () => {
  return shallowMount(InviteMemberTrigger, { provide: triggerProvides });
};

describe('InviteMemberTrigger', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLink = () => wrapper.find(GlLink);

  describe('displayText', () => {
    it('includes the correct displayText for the link', () => {
      expect(findLink().text()).toBe(triggerProvides.displayText);
    });
  });

  describe('tracking', () => {
    let trackingSpy;

    afterEach(() => {
      unmockTracking();
    });

    it('send an event when go to pipelines is clicked', () => {
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

      triggerEvent(findLink().element);

      expect(trackingSpy).toHaveBeenCalledWith('_category_', triggerProvides.event, {
        label: triggerProvides.label,
      });
    });
  });
});
