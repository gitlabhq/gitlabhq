import { GlBanner, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import InviteMembersBanner from '~/groups/components/invite_members_banner.vue';
import eventHub from '~/invite_members/event_hub';
import { setCookie, parseBoolean } from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils');

const isDismissedKey = 'invite_99_1';
const title = 'Collaborate with your team';
const body =
  "We noticed that you haven't invited anyone to this group. Invite your colleagues so you can discuss issues, collaborate on merge requests, and share your knowledge";
const svgPath = '/illustrations/background';
const inviteMembersPath = 'groups/members';
const buttonText = 'Invite your colleagues';
const trackLabel = 'invite_members_banner';

const createComponent = (stubs = {}) => {
  return shallowMount(InviteMembersBanner, {
    provide: {
      svgPath,
      inviteMembersPath,
      isDismissedKey,
      trackLabel,
    },
    stubs,
  });
};

describe('InviteMembersBanner', () => {
  let wrapper;
  let trackingSpy;

  beforeEach(() => {
    document.body.dataset.page = 'any:page';
    trackingSpy = mockTracking('_category_', undefined, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    unmockTracking();
  });

  describe('tracking', () => {
    beforeEach(() => {
      wrapper = createComponent({ GlBanner });
    });

    const trackCategory = undefined;
    const displayEvent = 'invite_members_banner_displayed';
    const buttonClickEvent = 'invite_members_banner_button_clicked';
    const dismissEvent = 'invite_members_banner_dismissed';

    it('sends the displayEvent when the banner is displayed', () => {
      expect(trackingSpy).toHaveBeenCalledWith(trackCategory, displayEvent, {
        label: trackLabel,
      });
    });

    describe('when the button is clicked', () => {
      beforeEach(() => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        wrapper.find(GlBanner).vm.$emit('primary');
      });

      it('calls openModal through the eventHub', () => {
        expect(eventHub.$emit).toHaveBeenCalledWith('openModal', {
          inviteeType: 'members',
          source: 'invite_members_banner',
        });
      });

      it('sends the buttonClickEvent with correct trackCategory and trackLabel', () => {
        expect(trackingSpy).toHaveBeenCalledWith(trackCategory, buttonClickEvent, {
          label: trackLabel,
        });
      });
    });

    it('sends the dismissEvent when the banner is dismissed', () => {
      wrapper.find(GlBanner).vm.$emit('close');

      expect(trackingSpy).toHaveBeenCalledWith(trackCategory, dismissEvent, {
        label: trackLabel,
      });
    });
  });

  describe('rendering', () => {
    const findBanner = () => {
      return wrapper.find(GlBanner);
    };

    beforeEach(() => {
      wrapper = createComponent();
    });

    it('uses the svgPath for the banner svgpath', () => {
      expect(findBanner().attributes('svgpath')).toBe(svgPath);
    });

    it('uses the title from options for title', () => {
      expect(findBanner().attributes('title')).toBe(title);
    });

    it('includes the body text from options', () => {
      expect(findBanner().html()).toContain(body);
    });

    it('uses the button_text text from options for buttontext', () => {
      expect(findBanner().attributes('buttontext')).toBe(buttonText);
    });
  });

  describe('dismissing', () => {
    const findButton = () => wrapper.findAll(GlButton).at(1);

    beforeEach(() => {
      wrapper = createComponent({ GlBanner });

      findButton().vm.$emit('click');
    });

    it('sets iDismissed to true', () => {
      expect(wrapper.vm.isDismissed).toBe(true);
    });

    it('sets the cookie with the isDismissedKey', () => {
      expect(setCookie).toHaveBeenCalledWith(isDismissedKey, true);
    });
  });

  describe('when a dismiss cookie exists', () => {
    beforeEach(() => {
      parseBoolean.mockReturnValue(true);

      wrapper = createComponent({ GlBanner });
    });

    it('sets isDismissed to true', () => {
      expect(wrapper.vm.isDismissed).toBe(true);
    });

    it('does not render the banner', () => {
      expect(wrapper.find(GlBanner).exists()).toBe(false);
    });
  });
});
