import { GlEmptyState } from '@gitlab/ui';
import ObservabilityNoDataEmptyState from '~/observability/components/observability_no_data_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('ObservabilityNoDataEmptyState', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMountExtended(ObservabilityNoDataEmptyState);
  });

  it('passes the correct title', () => {
    expect(wrapper.findComponent(GlEmptyState).props('title')).toBe(
      'Sorry, your filter produced no results',
    );
  });

  it('displays the correct description', () => {
    const description = wrapper.find('span').text();
    expect(description).toBe('To widen your search, change or remove filters above');
  });
});
