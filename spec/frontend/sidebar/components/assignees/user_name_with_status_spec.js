import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { AVAILABILITY_STATUS } from '~/set_status_modal/utils';
import UserNameWithStatus from '~/sidebar/components/assignees/user_name_with_status.vue';

const name = 'Goku';
const containerClasses = 'gl-cool-class gl-over-9000';

describe('UserNameWithStatus', () => {
  let wrapper;

  function createComponent(props = {}) {
    return shallowMount(UserNameWithStatus, {
      propsData: { name, containerClasses, ...props },
      stubs: {
        GlSprintf,
      },
    });
  }

  beforeEach(() => {
    wrapper = createComponent();
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
      wrapper = createComponent({ availability: AVAILABILITY_STATUS.BUSY });
    });

    it('will render "Busy"', () => {
      expect(wrapper.html()).toContain('Goku (Busy)');
    });
  });
});
