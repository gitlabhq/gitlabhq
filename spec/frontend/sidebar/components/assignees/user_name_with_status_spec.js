import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';
import UserNameWithStatus from '~/sidebar/components/assignees/user_name_with_status.vue';

const name = 'Administrator';
const containerClasses = 'gl-cool-class gl-over-9000';

describe('UserNameWithStatus', () => {
  let wrapper;

  const findBusyBadge = () => wrapper.find('[data-testid="busy-badge"]');
  const findAgentBadge = () => wrapper.find('[data-testid="user-name-with-status-agent-badge"]');

  function createComponent(props = {}) {
    wrapper = shallowMount(UserNameWithStatus, {
      propsData: { name, containerClasses, ...props },
      stubs: {
        GlSprintf,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('will render the users name', () => {
    expect(wrapper.html()).toContain(name);
  });

  it('will render all relevant containerClasses', () => {
    const classes = wrapper.find('span').classes().join(' ');
    expect(classes).toBe(containerClasses);
  });

  describe('when user is not busy and is not agent', () => {
    it('will not render "Busy" badge', () => {
      expect(findBusyBadge().exists()).toBe(false);
    });

    it('will not render agent badge', () => {
      expect(findAgentBadge().exists()).toBe(false);
    });
  });

  describe(`when user is busy`, () => {
    beforeEach(() => {
      createComponent({ availability: AVAILABILITY_STATUS.BUSY });
    });

    it('will render "Busy" badge', () => {
      expect(findBusyBadge().exists()).toBe(true);
      expect(findBusyBadge().text()).toBe('Busy');
    });

    it('will not render agent badge', () => {
      expect(findAgentBadge().exists()).toBe(false);
    });
  });

  describe('when user is agent', () => {
    beforeEach(() => {
      createComponent({ compositeIdentityEnforced: true });
    });

    it('will render agent badge', () => {
      expect(findAgentBadge().exists()).toBe(true);
      expect(findAgentBadge().text()).toBe('AI');
    });

    it('will not render busy badge', () => {
      expect(findBusyBadge().exists()).toBe(false);
    });
  });

  describe('when user is busy and is agent', () => {
    beforeEach(() => {
      createComponent({
        availability: AVAILABILITY_STATUS.BUSY,
        compositeIdentityEnforced: true,
      });
    });

    it('will render both busy and agent badges', () => {
      expect(findBusyBadge().exists()).toBe(true);
      expect(findAgentBadge().exists()).toBe(true);
    });
  });

  describe('when user has pronouns set', () => {
    const pronouns = 'they/them';

    beforeEach(() => {
      createComponent({ pronouns });
    });

    it("renders user's name with pronouns", () => {
      expect(wrapper.text()).toMatchInterpolatedText(`${name}(${pronouns})`);
    });
  });

  describe('when user does not have pronouns set', () => {
    describe.each`
      pronouns
      ${undefined}
      ${null}
      ${''}
      ${'   '}
    `('when `pronouns` prop is $pronouns', ({ pronouns }) => {
      it("renders only the user's name", () => {
        createComponent({ pronouns });

        expect(wrapper.text()).toMatchInterpolatedText(name);
      });
    });
  });
});
