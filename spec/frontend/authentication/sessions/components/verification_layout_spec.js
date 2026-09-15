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
  const findTitle = () => wrapper.find('h1');

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

  // The title is the page heading on every screen that uses this layout: each is a
  // standalone auth page rendering one instance, with no other h1 in the layout chain.
  it('renders the title as the page heading', () => {
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
