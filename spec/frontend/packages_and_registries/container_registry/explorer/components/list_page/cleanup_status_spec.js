import { GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import CleanupStatus from '~/packages_and_registries/container_registry/explorer/components/list_page/cleanup_status.vue';
import {
  CLEANUP_STATUS_SCHEDULED,
  CLEANUP_STATUS_ONGOING,
  CLEANUP_STATUS_UNFINISHED,
  UNFINISHED_STATUS,
  UNSCHEDULED_STATUS,
  SCHEDULED_STATUS,
  ONGOING_STATUS,
} from '~/packages_and_registries/container_registry/explorer/constants';

describe('cleanup_status', () => {
  let wrapper;

  const findMainIcon = () => wrapper.findByTestId('main-icon');
  const findExtraInfoIcon = () => wrapper.findByTestId('extra-info');
  const findPopover = () => wrapper.findComponent(GlPopover);

  const cleanupPolicyHelpPage = helpPagePath(
    'user/packages/container_registry/reduce_container_registry_storage.html',
    { anchor: 'how-the-cleanup-policy-works' },
  );

  const mountComponent = (propsData = { status: SCHEDULED_STATUS }) => {
    wrapper = shallowMountExtended(CleanupStatus, {
      propsData,
      stubs: {
        GlLink,
        GlPopover,
        GlSprintf,
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
      expect(wrapper.text()).toContain(text);
    },
  );

  describe('main icon', () => {
    it('exists', () => {
      mountComponent();

      expect(findMainIcon().exists()).toBe(true);
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

    it(`has a popover with a learn more link`, () => {
      mountComponent({ status: UNFINISHED_STATUS });

      expect(findPopover().exists()).toBe(true);
      expect(findPopover().findComponent(GlLink).exists()).toBe(true);
      expect(findPopover().findComponent(GlLink).attributes('href')).toBe(cleanupPolicyHelpPage);
    });
  });
});
