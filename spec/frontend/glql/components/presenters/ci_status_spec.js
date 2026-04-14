import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import CiStatusPresenter from '~/glql/components/presenters/ci_status.vue';

describe('CiStatusPresenter', () => {
  const createWrapper = (data) => shallowMountExtended(CiStatusPresenter, { propsData: { data } });

  it.each`
    status        | expectedIcon         | expectedText
    ${'SUCCESS'}  | ${'status_success'}  | ${'Passed'}
    ${'FAILED'}   | ${'status_failed'}   | ${'Failed'}
    ${'RUNNING'}  | ${'status_running'}  | ${'Running'}
    ${'PENDING'}  | ${'status_pending'}  | ${'Pending'}
    ${'CANCELED'} | ${'status_canceled'} | ${'Canceled'}
  `('renders CiIcon for status "$status"', ({ status, expectedIcon, expectedText }) => {
    const wrapper = createWrapper(status);
    const ciIcon = wrapper.findComponent(CiIcon);

    expect(ciIcon.exists()).toBe(true);
    expect(ciIcon.props('status')).toEqual({ icon: expectedIcon, text: expectedText });
    expect(ciIcon.props('showStatusText')).toBe(true);
    expect(ciIcon.props('useLink')).toBe(false);
  });

  it('renders plain text for unknown status', () => {
    const wrapper = createWrapper('unknown_status');

    expect(wrapper.findComponent(CiIcon).exists()).toBe(false);
    expect(wrapper.text()).toBe('unknown_status');
  });
});
