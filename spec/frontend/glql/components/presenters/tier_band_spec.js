import { mountExtended } from 'helpers/vue_test_utils_helper';
import TierBandPresenter from '~/glql/components/presenters/tier_band.vue';

describe('TierBandPresenter', () => {
  const createWrapper = (propsData) => mountExtended(TierBandPresenter, { propsData });

  it('renders the tier name for the default thresholds', () => {
    const wrapper = createWrapper({
      data: 'tier_3',
      parameters: { thresholds: ['5', '25', '100'] },
    });

    expect(wrapper.text()).toBe('Power (100+)');
  });

  it('renders a range derived from custom thresholds', () => {
    const wrapper = createWrapper({ data: 'tier_1', parameters: { thresholds: ['10', '50'] } });

    expect(wrapper.text()).toBe('10–49');
  });
});
