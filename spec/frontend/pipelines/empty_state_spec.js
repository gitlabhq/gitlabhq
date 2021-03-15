import { mount } from '@vue/test-utils';
import EmptyState from '~/pipelines/components/pipelines_list/empty_state.vue';

describe('Pipelines Empty State', () => {
  let wrapper;

  const findIllustration = () => wrapper.find('img');
  const findButton = () => wrapper.find('a');

  const createWrapper = (props = {}) => {
    wrapper = mount(EmptyState, {
      propsData: {
        emptyStateSvgPath: 'foo.svg',
        canSetCi: true,
        ...props,
      },
    });
  };

  describe('when user can configure CI', () => {
    beforeEach(() => {
      createWrapper({}, mount);
    });

    afterEach(() => {
      wrapper.destroy();
      wrapper = null;
    });

    it('should render empty state SVG', () => {
      expect(findIllustration().attributes('src')).toBe('foo.svg');
    });

    it('should render empty state header', () => {
      expect(wrapper.text()).toContain('Build with confidence');
    });

    it('should render empty state information', () => {
      expect(wrapper.text()).toContain(
        'GitLab CI/CD can automatically build, test, and deploy your code. Let GitLab take care of time',
        'consuming tasks, so you can spend more time creating',
      );
    });

    it('should render button with help path', () => {
      expect(findButton().attributes('href')).toBe('/help/ci/quick_start/index.md');
    });

    it('should render button text', () => {
      expect(findButton().text()).toBe('Get started with CI/CD');
    });
  });

  describe('when user cannot configure CI', () => {
    beforeEach(() => {
      createWrapper({ canSetCi: false }, mount);
    });

    afterEach(() => {
      wrapper.destroy();
      wrapper = null;
    });

    it('should render empty state SVG', () => {
      expect(findIllustration().attributes('src')).toBe('foo.svg');
    });

    it('should render empty state header', () => {
      expect(wrapper.text()).toBe('This project is not currently set up to run pipelines.');
    });

    it('should not render a link', () => {
      expect(findButton().exists()).toBe(false);
    });
  });
});
