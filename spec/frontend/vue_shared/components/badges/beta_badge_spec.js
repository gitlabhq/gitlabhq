import { shallowMount } from '@vue/test-utils';
import BetaBadge from '~/vue_shared/components/badges/beta_badge.vue';

describe('Beta badge component', () => {
  let wrapper;

  it('renders the badge', () => {
    wrapper = shallowMount(BetaBadge);

    expect(wrapper.element).toMatchSnapshot();
  });
});
