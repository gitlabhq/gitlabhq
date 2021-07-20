import '~/commons';
import { mount } from '@vue/test-utils';
import EmptyState from '~/pipelines/components/pipelines_list/empty_state.vue';
import PipelinesCiTemplates from '~/pipelines/components/pipelines_list/pipelines_ci_templates.vue';

describe('Pipelines Empty State', () => {
  let wrapper;

  const findIllustration = () => wrapper.find('img');
  const findButton = () => wrapper.find('a');
  const pipelinesCiTemplates = () => wrapper.findComponent(PipelinesCiTemplates);

  const createWrapper = (props = {}) => {
    wrapper = mount(EmptyState, {
      provide: {
        pipelineEditorPath: '',
        suggestedCiTemplates: [],
      },
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

    it('should render the CI/CD templates', () => {
      expect(pipelinesCiTemplates()).toExist();
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
