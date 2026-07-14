import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VerificationDivider from '~/authentication/sessions/components/verification_divider.vue';

describe('VerificationDivider', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(VerificationDivider);
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the label', () => {
    expect(wrapper.findByTestId('verification-divider').text()).toBe('or verify with');
  });

  it('renders two horizontal rules around the label', () => {
    expect(wrapper.findAll('hr')).toHaveLength(2);
  });
});
