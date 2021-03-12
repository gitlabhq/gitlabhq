import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/pipelines/components/pipelines_list/empty_state.vue';

describe('Pipelines Empty State', () => {
  let wrapper;

  const findGetStartedButton = () => wrapper.find('[data-testid="get-started-pipelines"]');
  const findInfoText = () => wrapper.find('[data-testid="info-text"]').text();
  const createWrapper = () => {
    wrapper = shallowMount(EmptyState, {
      propsData: {
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
      expect(findGetStartedButton().attributes('href')).toBe('/help/ci/quick_start/index.md');
    });

    it('should render empty state information', () => {
      expect(findInfoText()).toContain(
        'GitLab CI/CD can automatically build, test, and deploy your code. Let GitLab take care of time',
        'consuming tasks, so you can spend more time creating',
      );
    });

    it('should render button text', () => {
      expect(findGetStartedButton().text()).toBe('Get started with CI/CD');
    });
  });
});
