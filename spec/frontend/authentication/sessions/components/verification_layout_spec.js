import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VerificationLayout from '~/authentication/sessions/components/verification_layout.vue';

describe('VerificationLayout', () => {
  let wrapper;

  const createComponent = (slots = {}) => {
    wrapper = shallowMountExtended(VerificationLayout, {
      propsData: {
        svgPath: '/illustration.svg',
        title: 'Enter authenticator app code',
      },
      slots: {
        description: 'A helpful description',
        default: '<form data-testid="body">form body</form>',
        ...slots,
      },
    });
  };

  const findIllustration = () => wrapper.find('img');
  const findTitle = () => wrapper.find('h2');

  beforeEach(() => {
    createComponent();
  });

  it('renders the illustration from svgPath with empty alt (decorative)', () => {
    // Read the `src` DOM property (not the attribute): under Vue 3 jest, the image shim
    // stores a bound src as a property, so attributes('src') is empty. See
    // spec/frontend/__helpers__/dom_shims/image_element_properties.js
    expect(findIllustration().element.src).toBe('/illustration.svg');
    expect(findIllustration().attributes('alt')).toBe('');
  });

  it('renders the title', () => {
    expect(findTitle().text()).toBe('Enter authenticator app code');
  });

  it('renders the description slot', () => {
    expect(wrapper.text()).toContain('A helpful description');
  });

  it('does not render the description paragraph when no description slot is provided', () => {
    wrapper = shallowMountExtended(VerificationLayout, {
      propsData: { svgPath: '/illustration.svg', title: 'Enter authenticator app code' },
    });

    expect(wrapper.find('p').exists()).toBe(false);
  });

  it('renders the default slot', () => {
    expect(wrapper.findByTestId('body').exists()).toBe(true);
  });
});
