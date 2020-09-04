import { shallowMount } from '@vue/test-utils';
import { GlBanner } from '@gitlab/ui';
import InviteMembersBanner from '~/groups/components/invite_members_banner.vue';

const expectedTitle = 'Collaborate with your team';
const expectedBody =
  "We noticed that you haven't invited anyone to this group. Invite your colleagues so you can discuss issues, collaborate on merge requests, and share your knowledge";
const expectedSvgPath = '/illustrations/background';
const expectedInviteMembersPath = 'groups/members';
const expectedButtonText = 'Invite your colleagues';

const createComponent = (stubs = {}) => {
  return shallowMount(InviteMembersBanner, {
    provide: {
      svgPath: expectedSvgPath,
      inviteMembersPath: expectedInviteMembersPath,
    },
    stubs,
  });
};

describe('InviteMembersBanner', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('rendering', () => {
    const findBanner = () => {
      return wrapper.find(GlBanner);
    };

    beforeEach(() => {
      wrapper = createComponent();
    });

    it('uses the svgPath for the banner svgpath', () => {
      expect(findBanner().attributes('svgpath')).toBe(expectedSvgPath);
    });

    it('uses the title from options for title', () => {
      expect(findBanner().attributes('title')).toBe(expectedTitle);
    });

    it('includes the body text from options', () => {
      expect(findBanner().html()).toContain(expectedBody);
    });

    it('uses the button_text text from options for buttontext', () => {
      expect(findBanner().attributes('buttontext')).toBe(expectedButtonText);
    });

    it('uses the href from inviteMembersPath for buttonlink', () => {
      expect(findBanner().attributes('buttonlink')).toBe(expectedInviteMembersPath);
    });
  });

  describe('dismissing', () => {
    const findButton = () => {
      return wrapper.find('button');
    };
    const stubs = {
      GlBanner,
    };

    it('sets visible to false', () => {
      wrapper = createComponent(stubs);

      findButton().trigger('click');

      expect(wrapper.vm.visible).toBe(false);
    });
  });
});
