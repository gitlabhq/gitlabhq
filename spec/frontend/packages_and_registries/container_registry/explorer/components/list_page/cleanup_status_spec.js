import { GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
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
  const findMainIconName = () => wrapper.findByTestId('main-icon').findComponent(GlIcon);
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

    it.each`
      status                | visible  | iconName
      ${UNFINISHED_STATUS}  | ${true}  | ${'expire'}
      ${SCHEDULED_STATUS}   | ${true}  | ${'clock'}
      ${ONGOING_STATUS}     | ${true}  | ${'clock'}
      ${UNSCHEDULED_STATUS} | ${false} | ${''}
    `('matches "$iconName" when the status is "$status"', ({ status, visible, iconName }) => {
      mountComponent({ status });

      expect(findMainIcon().exists()).toBe(visible);
      if (visible) {
        const actualIcon = findMainIconName();
        expect(actualIcon.exists()).toBe(true);
        expect(actualIcon.props('name')).toBe(iconName);
      }
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
        mountComponent({ status, expirationPolicy: { next_run_at: '2063-04-08T01:44:03Z' } });

        expect(findExtraInfoIcon().exists()).toBe(visible);
      },
    );

    it(`when the status is ${UNFINISHED_STATUS} & expirationPolicy does not exist the extra icon is not visible`, () => {
      mountComponent({
        status: UNFINISHED_STATUS,
      });

      expect(findExtraInfoIcon().exists()).toBe(false);
    });

    it(`has a popover with a learn more link and a time frame for the next run`, () => {
      jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());

      mountComponent({
        status: UNFINISHED_STATUS,
        expirationPolicy: { next_run_at: '2063-04-08T01:44:03Z' },
      });

      expect(findPopover().exists()).toBe(true);
      expect(findPopover().text()).toContain('The cleanup will continue within 4 days. Learn more');
      expect(findPopover().findComponent(GlLink).exists()).toBe(true);
      expect(findPopover().findComponent(GlLink).attributes('href')).toBe(cleanupPolicyHelpPage);
    });

    it('id matches popover target attribute', () => {
      mountComponent({
        status: UNFINISHED_STATUS,
        expirationPolicy: { next_run_at: '2063-04-08T01:44:03Z' },
      });

      const id = findExtraInfoIcon().attributes('id');

      expect(id).toMatch(/status-info-[0-9]+/);
      expect(findPopover().props('target')).toEqual(id);
    });
  });
});
