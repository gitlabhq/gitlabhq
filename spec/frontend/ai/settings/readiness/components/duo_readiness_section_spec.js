import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DuoReadinessSection from '~/ai/settings/readiness/components/duo_readiness_section.vue';

describe('DuoReadinessSection', () => {
  let wrapper;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMountExtended(DuoReadinessSection, {
      propsData: { title: 'Agent and flow setup', ...props },
      slots,
    });
  };

  const findTitle = () => wrapper.findByTestId('readiness-section-title');
  const findSubtitle = () => wrapper.findByTestId('readiness-section-subtitle');

  it('renders the title as a level two heading by default', () => {
    createComponent();

    expect(findTitle().element.tagName).toBe('H2');
    expect(findTitle().text()).toBe('Agent and flow setup');
  });

  it('renders the heading at the level the page needs', () => {
    createComponent({ headingTag: 'h3' });

    expect(findTitle().element.tagName).toBe('H3');
  });

  it('renders the subtitle when given', () => {
    createComponent({ subtitle: 'All four are needed for full agent and flow support.' });

    expect(findSubtitle().text()).toBe('All four are needed for full agent and flow support.');
  });

  it('renders no subtitle line without one', () => {
    createComponent();

    expect(findSubtitle().exists()).toBe(false);
  });

  it('renders the rows inside the bordered container', () => {
    createComponent({}, { default: '<div data-testid="row">GitLab Duo</div>' });

    expect(wrapper.findByTestId('row').text()).toBe('GitLab Duo');
  });
});
