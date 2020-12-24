import { shallowMount } from '@vue/test-utils';
import { GlLink, GlModal } from '@gitlab/ui';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';
import { stubComponent } from 'helpers/stub_component';
import InviteMemberModal from '~/invite_member/components/invite_member_modal.vue';

const memberPath = 'member_path';

const GlEmoji = { template: '<img />' };
const createComponent = () => {
  return shallowMount(InviteMemberModal, {
    provide: {
      membersPath: memberPath,
    },
    stubs: {
      GlEmoji,
      GlModal: stubComponent(GlModal, {
        template: '<div><slot name="modal-title"></slot><slot></slot></div>',
      }),
    },
  });
};

describe('InviteMemberModal', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLink = () => wrapper.find(GlLink);

  describe('rendering the modal', () => {
    it('renders the modal with the correct title', () => {
      expect(wrapper.text()).toContain("Oops, this feature isn't ready yet");
    });

    describe('rendering the see who link', () => {
      it('renders the correct link', () => {
        expect(findLink().attributes('href')).toBe(memberPath);
      });
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

      expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_who_can_invite_link', {
        label: 'invite_members_message',
      });
    });
  });
});
