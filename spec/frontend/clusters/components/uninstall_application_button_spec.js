import { shallowMount } from '@vue/test-utils';
import UninstallApplicationButton from '~/clusters/components/uninstall_application_button.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
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
    status          | loading  | disabled | label
    ${INSTALLED}    | ${false} | ${false} | ${'Uninstall'}
    ${UPDATING}     | ${false} | ${true}  | ${'Uninstall'}
    ${UNINSTALLING} | ${true}  | ${true}  | ${'Uninstalling'}
  `('when app status is $status', ({ loading, disabled, status, label }) => {
    it(`renders a loading=${loading}, disabled=${disabled} button with label="${label}"`, () => {
      createComponent({ status });
      expect(wrapper.find(LoadingButton).props()).toMatchObject({ loading, disabled, label });
    });
  });
});
