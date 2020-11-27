import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/pipelines/components/pipelines_list/empty_state.vue';

describe('Pipelines Empty State', () => {
  let wrapper;

  const findGetStartedButton = () => wrapper.find('[data-testid="get-started-pipelines"]');
  const findInfoText = () => wrapper.find('[data-testid="info-text"]').text();
  const createWrapper = () => {
    wrapper = shallowMount(EmptyState, {
      propsData: {
        helpPagePath: 'foo',
        emptyStateSvgPath: 'foo',
        canSetCi: true,
      },
    });
  };

  describe('renders', () => {
    beforeEach(() => {
      createWrapper();
    });

    afterEach(() => {
      wrapper.destroy();
      wrapper = null;
    });

    it('should render empty state SVG', () => {
      expect(wrapper.find('img').attributes('src')).toBe('foo');
    });

    it('should render empty state header', () => {
      expect(wrapper.find('[data-testid="header-text"]').text()).toBe('Build with confidence');
    });

    it('should render a link with provided help path', () => {
      expect(findGetStartedButton().attributes('href')).toBe('foo');
    });

    it('should render empty state information', () => {
      expect(findInfoText()).toContain(
        'Continuous Integration can help catch bugs by running your tests automatically',
        'while Continuous Deployment can help you deliver code to your product environment',
      );
    });

    it('should render a button', () => {
      expect(findGetStartedButton().text()).toBe('Get started with Pipelines');
    });
  });
});
