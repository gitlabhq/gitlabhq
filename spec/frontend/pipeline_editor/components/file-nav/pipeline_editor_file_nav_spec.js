import { shallowMount } from '@vue/test-utils';
import BranchSwitcher from '~/pipeline_editor/components/file_nav/branch_switcher.vue';
import PipelineEditorFileNav from '~/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';

describe('Pipeline editor file nav', () => {
  let wrapper;

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMount(PipelineEditorFileNav, {
      provide: {
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
});
