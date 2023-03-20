import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import InviteMembersBanner from '~/groups/components/invite_members_banner.vue';
import eventHub from '~/invite_members/event_hub';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/lib/utils/common_utils');

const title = 'Collaborate with your team';
const body =
  "We noticed that you haven't invited anyone to this group. Invite your colleagues so you can discuss issues, collaborate on merge requests, and share your knowledge";
const buttonText = 'Invite your colleagues';
const provide = {
  svgPath: '/illustrations/background',
  inviteMembersPath: 'groups/members',
  trackLabel: 'invite_members_banner',
  calloutsPath: 'call/out/path',
  calloutsFeatureId: 'some-feature-id',
  groupId: '1',
};

const createComponent = (stubs = {}) => {
  return shallowMount(InviteMembersBanner, {
    provide,
    stubs,
  });
};

describe('InviteMembersBanner', () => {
  let wrapper;
  let trackingSpy;
  let mockAxios;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    document.body.dataset.page = 'any:page';
    trackingSpy = mockTracking('_category_', undefined, jest.spyOn);
  });

  afterEach(() => {
    mockAxios.restore();
    unmockTracking();
  });

  describe('tracking', () => {
    const mockTrackingOnWrapper = () => {
      unmockTracking();
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
    };

    beforeEach(() => {
      wrapper = createComponent({ GlBanner });
    });

    const trackCategory = undefined;

    it('sends the displayEvent when the banner is displayed', () => {
      const displayEvent = 'invite_members_banner_displayed';

      expect(trackingSpy).toHaveBeenCalledWith(trackCategory, displayEvent, {
        label: provide.trackLabel,
      });
    });

    describe('when the button is clicked', () => {
      beforeEach(() => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
        wrapper.findComponent(GlBanner).vm.$emit('primary');
      });

      it('calls openModal through the eventHub', () => {
        expect(eventHub.$emit).toHaveBeenCalledWith('openModal', {
          source: 'invite_members_banner',
        });
      });
    });

    it('sends the dismissEvent when the banner is dismissed', () => {
      mockTrackingOnWrapper();
      mockAxios.onPost(provide.calloutsPath).replyOnce(HTTP_STATUS_OK);
      const dismissEvent = 'invite_members_banner_dismissed';

      wrapper.findComponent(GlBanner).vm.$emit('close');

      expect(trackingSpy).toHaveBeenCalledWith(trackCategory, dismissEvent, {
        label: provide.trackLabel,
      });
    });
  });

  describe('rendering', () => {
    const findBanner = () => {
      return wrapper.findComponent(GlBanner);
    };

    beforeEach(() => {
      wrapper = createComponent();
    });

    it('uses the svgPath for the banner svgpath', () => {
      expect(findBanner().attributes('svgpath')).toBe(provide.svgPath);
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
    beforeEach(() => {
      wrapper = createComponent({ GlBanner });
    });

    it('should render the banner when not dismissed', () => {
      expect(wrapper.findComponent(GlBanner).exists()).toBe(true);
    });

    it('should close the banner when dismiss is clicked', async () => {
      mockAxios.onPost(provide.calloutsPath).replyOnce(HTTP_STATUS_OK);
      expect(wrapper.findComponent(GlBanner).exists()).toBe(true);
      wrapper.findComponent(GlBanner).vm.$emit('close');

      await nextTick();
      expect(wrapper.findComponent(GlBanner).exists()).toBe(false);
    });
  });
});
