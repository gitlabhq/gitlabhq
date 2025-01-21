import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelineEditorFileTreeContainer from '~/ci/pipeline_editor/components/file_tree/container.vue';
import PipelineEditorFileTreeItem from '~/ci/pipeline_editor/components/file_tree/file_item.vue';
import { FILE_TREE_TIP_DISMISSED_KEY } from '~/ci/pipeline_editor/constants';
import { mockCiConfigPath, mockIncludes, mockIncludesHelpPagePath } from '../../mock_data';

describe('Pipeline editor file nav', () => {
  let wrapper;

  const createComponent = ({ includes = mockIncludes, stubs } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(PipelineEditorFileTreeContainer, {
        provide: {
          ciConfigPath: mockCiConfigPath,
          includesHelpPagePath: mockIncludesHelpPagePath,
        },
        propsData: {
          includes,
        },
        stubs,
      }),
    );
  };

  const findTip = () => wrapper.findComponent(GlAlert);
  const findCurrentConfigFilename = () => wrapper.findByTestId('current-config-filename');
  const fileTreeItems = () => wrapper.findAllComponents(PipelineEditorFileTreeItem);

  afterEach(() => {
    localStorage.clear();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent({ stubs: { GlAlert } });
    });

    it('renders config file as a file item', () => {
      expect(findCurrentConfigFilename().text()).toBe(mockCiConfigPath);
    });
  });

  describe('when includes list is empty', () => {
    describe('when dismiss state is not saved in local storage', () => {
      beforeEach(() => {
        createComponent({
          includes: [],
          stubs: { GlAlert },
        });
      });

      it('does not render filenames', () => {
        expect(fileTreeItems().exists()).toBe(false);
      });

      it('renders alert tip', () => {
        expect(findTip().exists()).toBe(true);
      });

      it('renders learn more link', () => {
        expect(findTip().props('secondaryButtonLink')).toBe(mockIncludesHelpPagePath);
      });

      it('can dismiss the tip', async () => {
        expect(findTip().exists()).toBe(true);

        findTip().vm.$emit('dismiss');
        await nextTick();

        expect(findTip().exists()).toBe(false);
      });
    });

    describe('when dismiss state is saved in local storage', () => {
      beforeEach(() => {
        localStorage.setItem(FILE_TREE_TIP_DISMISSED_KEY, 'true');
        createComponent({
          includes: [],
          stubs: { GlAlert },
        });
      });

      it('does not render alert tip', () => {
        expect(findTip().exists()).toBe(false);
      });
    });

    describe('when component receives new props with includes files', () => {
      beforeEach(() => {
        createComponent({ includes: [] });
      });

      it('hides tip and renders list of files', async () => {
        expect(findTip().exists()).toBe(true);
        expect(fileTreeItems()).toHaveLength(0);

        await wrapper.setProps({ includes: mockIncludes });

        expect(findTip().exists()).toBe(false);
        expect(fileTreeItems()).toHaveLength(mockIncludes.length);
      });
    });
  });

  describe('when there are includes files', () => {
    beforeEach(() => {
      createComponent({ stubs: { GlAlert } });
    });

    it('does not render alert tip', () => {
      expect(findTip().exists()).toBe(false);
    });

    it('renders the list of files', () => {
      expect(fileTreeItems()).toHaveLength(mockIncludes.length);
    });

    describe('when component receives new props with empty includes', () => {
      it('shows tip and does not render list of files', async () => {
        expect(findTip().exists()).toBe(false);
        expect(fileTreeItems()).toHaveLength(mockIncludes.length);

        await wrapper.setProps({ includes: [] });

        expect(findTip().exists()).toBe(true);
        expect(fileTreeItems()).toHaveLength(0);
      });
    });
  });
});
