import { shallowMount } from '@vue/test-utils';
import BranchSwitcher from '~/pipeline_editor/components/file_nav/branch_switcher.vue';
import PipelineEditorFileNav from '~/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';

describe('Pipeline editor file nav', () => {
  let wrapper;
  const mockProvide = {
    glFeatures: {
      pipelineEditorBranchSwitcher: true,
    },
  };

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMount(PipelineEditorFileNav, {
      provide: {
        ...mockProvide,
        ...provide,
      },
    });
  };

  const findBranchSwitcher = () => wrapper.findComponent(BranchSwitcher);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the branch switcher', () => {
      expect(findBranchSwitcher().exists()).toBe(true);
    });
  });

  describe('with branch switcher feature flag OFF', () => {
    it('does not render the branch switcher', () => {
      createComponent({
        provide: {
          glFeatures: { pipelineEditorBranchSwitcher: false },
        },
      });

      expect(findBranchSwitcher().exists()).toBe(false);
    });
  });
});
