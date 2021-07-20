import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CleanupStatus from '~/registry/explorer/components/list_page/cleanup_status.vue';
import {
  ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  CLEANUP_STATUS_SCHEDULED,
  CLEANUP_STATUS_ONGOING,
  CLEANUP_STATUS_UNFINISHED,
  UNFINISHED_STATUS,
  UNSCHEDULED_STATUS,
  SCHEDULED_STATUS,
  ONGOING_STATUS,
} from '~/registry/explorer/constants';

describe('cleanup_status', () => {
  let wrapper;

  const findMainIcon = () => wrapper.findByTestId('main-icon');
  const findExtraInfoIcon = () => wrapper.findByTestId('extra-info');

  const mountComponent = (propsData = { status: SCHEDULED_STATUS }) => {
    wrapper = shallowMountExtended(CleanupStatus, {
      propsData,
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    status                | visible  | text
    ${UNFINISHED_STATUS}  | ${true}  | ${CLEANUP_STATUS_UNFINISHED}
    ${SCHEDULED_STATUS}   | ${true}  | ${CLEANUP_STATUS_SCHEDULED}
    ${ONGOING_STATUS}     | ${true}  | ${CLEANUP_STATUS_ONGOING}
    ${UNSCHEDULED_STATUS} | ${false} | ${''}
  `(
    'when the status is $status is $visible that the component is mounted and has the correct text',
    ({ status, visible, text }) => {
      mountComponent({ status });

      expect(findMainIcon().exists()).toBe(visible);
      expect(wrapper.text()).toBe(text);
    },
  );

  describe('main icon', () => {
    it('exists', () => {
      mountComponent();

      expect(findMainIcon().exists()).toBe(true);
    });

    it(`has the orange class when the status is ${UNFINISHED_STATUS}`, () => {
      mountComponent({ status: UNFINISHED_STATUS });

      expect(findMainIcon().classes('gl-text-orange-500')).toBe(true);
    });
  });

  describe('extra info icon', () => {
    it.each`
      status               | visible
      ${UNFINISHED_STATUS} | ${true}
      ${SCHEDULED_STATUS}  | ${false}
      ${ONGOING_STATUS}    | ${false}
    `(
      'when the status is $status is $visible that the extra icon is visible',
      ({ status, visible }) => {
        mountComponent({ status });

        expect(findExtraInfoIcon().exists()).toBe(visible);
      },
    );

    it(`has a tooltip`, () => {
      mountComponent({ status: UNFINISHED_STATUS });

      const tooltip = getBinding(findExtraInfoIcon().element, 'gl-tooltip');

      expect(tooltip.value.title).toBe(ASYNC_DELETE_IMAGE_ERROR_MESSAGE);
    });
  });
});
