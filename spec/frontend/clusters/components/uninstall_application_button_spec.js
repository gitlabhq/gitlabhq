import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import UninstallApplicationButton from '~/clusters/components/uninstall_application_button.vue';
import { APPLICATION_STATUS } from '~/clusters/constants';

const { INSTALLED, UPDATING, UNINSTALLING } = APPLICATION_STATUS;

describe('UninstallApplicationButton', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(UninstallApplicationButton, {
      propsData: { ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    status          | loading  | disabled | text
    ${INSTALLED}    | ${false} | ${false} | ${'Uninstall'}
    ${UPDATING}     | ${false} | ${true}  | ${'Uninstall'}
    ${UNINSTALLING} | ${true}  | ${true}  | ${'Uninstalling'}
  `('when app status is $status', ({ loading, disabled, status, text }) => {
    beforeAll(() => {
      createComponent({ status });
    });

    it(`renders a button with loading=${loading} and disabled=${disabled}`, () => {
      expect(wrapper.find(GlButton).props()).toMatchObject({ loading, disabled });
    });

    it(`renders a button with text="${text}"`, () => {
      expect(wrapper.find(GlButton).text()).toBe(text);
    });
  });
});
