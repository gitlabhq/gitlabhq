import { mount } from '@vue/test-utils';
import { AVAILABILITY_STATUS } from '~/set_status_modal/utils';
import UserNameWithStatus from '~/sidebar/components/assignees/user_name_with_status.vue';

const name = 'Administrator';
const containerClasses = 'gl-cool-class gl-over-9000';

describe('UserNameWithStatus', () => {
  let wrapper;

  function createComponent(props = {}) {
    wrapper = mount(UserNameWithStatus, {
      propsData: { name, containerClasses, ...props },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('will render the users name', () => {
    expect(wrapper.html()).toContain(name);
  });

  it('will not render "Busy"', () => {
    expect(wrapper.html()).not.toContain('Busy');
  });

  it('will render all relevant containerClasses', () => {
    const classes = wrapper.find('span').classes().join(' ');
    expect(classes).toBe(containerClasses);
  });

  describe(`with availability="${AVAILABILITY_STATUS.BUSY}"`, () => {
    beforeEach(() => {
      createComponent({ availability: AVAILABILITY_STATUS.BUSY });
    });

    it('will render "Busy"', () => {
      expect(wrapper.text()).toContain('(Busy)');
    });
  });

  describe('when user has pronouns set', () => {
    const pronouns = 'they/them';

    beforeEach(() => {
      createComponent({ pronouns });
    });

    it("renders user's name with pronouns", () => {
      expect(wrapper.text()).toMatchInterpolatedText(`${name} (${pronouns})`);
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
