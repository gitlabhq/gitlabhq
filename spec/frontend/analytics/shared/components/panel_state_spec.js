import { GlButton, GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PanelState from '~/analytics/shared/components/panel_state.vue';
import {
  PANEL_STATE_ERROR,
  PANEL_STATE_ERROR_NO_RETRY,
  PANEL_STATE_NO_ACCESS,
  PANEL_STATE_NO_DATA,
  PANEL_STATE_NOT_CONFIGURED,
  PANEL_STATE_UNAVAILABLE,
} from '~/analytics/shared/constants';

describe('AnalyticsPanelState', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(PanelState, {
      propsData: { variant: PANEL_STATE_NO_DATA, ...props },
    });
  };

  const findRetryButton = () => wrapper.findComponent(GlButton);
  const findLink = () => wrapper.findComponent(GlLink);
  const findIcon = () => wrapper.findComponent(GlIcon);

  it.each`
    variant                       | title                         | retry    | link     | icon
    ${PANEL_STATE_NO_DATA}        | ${'No data yet'}              | ${false} | ${false} | ${false}
    ${PANEL_STATE_NO_ACCESS}      | ${"You don't have access"}    | ${false} | ${false} | ${false}
    ${PANEL_STATE_NOT_CONFIGURED} | ${'Configuration required'}   | ${false} | ${true}  | ${false}
    ${PANEL_STATE_UNAVAILABLE}    | ${"Data isn't available yet"} | ${false} | ${true}  | ${false}
    ${PANEL_STATE_ERROR}          | ${'Something went wrong'}     | ${true}  | ${false} | ${true}
    ${PANEL_STATE_ERROR_NO_RETRY} | ${'Something went wrong'}     | ${false} | ${false} | ${true}
  `('renders the $variant state', ({ variant, title, retry, link, icon }) => {
    createWrapper({ variant });

    expect(wrapper.findByTestId(`panel-state-${variant}`).text()).toContain(title);
    expect(findRetryButton().exists()).toBe(retry);
    expect(findLink().exists()).toBe(link);
    expect(findIcon().exists()).toBe(icon);
  });

  it('emits retry when the retry button is clicked', () => {
    createWrapper({ variant: PANEL_STATE_ERROR });

    findRetryButton().vm.$emit('click');

    expect(wrapper.emitted('retry')).toHaveLength(1);
  });

  // A stat-sized tile cannot fit both; the button says what the description would.
  it('drops the description in favor of the retry button when compact', () => {
    createWrapper({ variant: PANEL_STATE_ERROR, compact: true });

    expect(wrapper.text()).not.toContain("We couldn't load this data. Try again.");
    expect(findRetryButton().exists()).toBe(true);
  });

  it('keeps the description for a compact state without retry', () => {
    createWrapper({ variant: PANEL_STATE_ERROR_NO_RETRY, compact: true });

    expect(wrapper.text()).toContain('Please try again later.');
  });

  it('overrides the default copy when title and description are given', () => {
    createWrapper({
      variant: PANEL_STATE_NO_DATA,
      title: 'No data in this range',
      description: 'Once your team uses Duo, activity shows up here.',
    });

    const text = wrapper.text();
    expect(text).toContain('No data in this range');
    expect(text).toContain('Once your team uses Duo, activity shows up here.');
    expect(text).not.toContain('No data yet');
  });

  it('centers the full state and not the compact one', () => {
    createWrapper({ variant: PANEL_STATE_NO_DATA });
    expect(wrapper.find('div').classes()).toContain('gl-justify-center');

    createWrapper({ variant: PANEL_STATE_NO_DATA, compact: true });
    expect(wrapper.find('div').classes()).not.toContain('gl-justify-center');
  });
});
