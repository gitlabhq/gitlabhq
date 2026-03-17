import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelineEditorFileTreeContainer from '~/ci/pipeline_editor/components/file_tree/container.vue';
import PipelineEditorFileTreeItem from '~/ci/pipeline_editor/components/file_tree/file_item.vue';
import { mockCiConfigPath, mockIncludes, mockSpecIncludes } from '../../mock_data';

describe('Pipeline editor file nav', () => {
  let wrapper;

  const createComponent = ({ includes = mockIncludes, stubs } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(PipelineEditorFileTreeContainer, {
        provide: {
          ciConfigPath: mockCiConfigPath,
        },
        propsData: {
          includes,
        },
        stubs,
      }),
    );
  };

  const findEmptyStateText = () => wrapper.findByTestId('empty-state-text');
  const findCurrentConfigFilename = () => wrapper.findByTestId('current-config-filename');
  const fileTreeItems = () => wrapper.findAllComponents(PipelineEditorFileTreeItem);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders config file as a file item', () => {
      expect(findCurrentConfigFilename().text()).toBe(mockCiConfigPath);
    });
  });

  describe('when includes list is empty', () => {
    beforeEach(() => {
      createComponent({
        includes: [],
      });
    });

    it('does not render filenames', () => {
      expect(fileTreeItems().exists()).toBe(false);
    });

    it('renders empty state text', () => {
      const sprintf = findEmptyStateText().findComponent(GlSprintf);
      expect(sprintf.exists()).toBe(true);
      expect(sprintf.attributes('message')).toContain('%{codeStart}include%{codeEnd}');
    });

    describe('when component receives new props with includes files', () => {
      it('hides empty state and renders list of files', async () => {
        expect(findEmptyStateText().exists()).toBe(true);
        expect(fileTreeItems()).toHaveLength(0);

        await wrapper.setProps({ includes: mockIncludes });

        expect(findEmptyStateText().exists()).toBe(false);
        expect(fileTreeItems()).toHaveLength(mockIncludes.length);
      });
    });
  });

  describe('when there are includes files', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render empty state text', () => {
      expect(findEmptyStateText().exists()).toBe(false);
    });

    it('renders the list of files', () => {
      expect(fileTreeItems()).toHaveLength(mockIncludes.length);
    });

    describe('when component receives new props with empty includes', () => {
      it('shows empty state and does not render list of files', async () => {
        expect(findEmptyStateText().exists()).toBe(false);
        expect(fileTreeItems()).toHaveLength(mockIncludes.length);

        await wrapper.setProps({ includes: [] });

        expect(findEmptyStateText().exists()).toBe(true);
        expect(fileTreeItems()).toHaveLength(0);
      });
    });
  });

  describe('when there are spec:include files', () => {
    beforeEach(() => {
      createComponent({ includes: mockSpecIncludes });
    });

    it('does not render empty state text', () => {
      expect(findEmptyStateText().exists()).toBe(false);
    });

    it('renders the list of spec:include files', () => {
      expect(fileTreeItems()).toHaveLength(mockSpecIncludes.length);
    });

    it('renders local include from spec:include', () => {
      const firstItem = fileTreeItems().at(0);
      expect(firstItem.props('file')).toMatchObject({
        location: 'ci/inputs.yml',
        type: 'local',
      });
    });

    it('renders remote include from spec:include', () => {
      const secondItem = fileTreeItems().at(1);
      expect(secondItem.props('file')).toMatchObject({
        type: 'remote',
      });
      expect(secondItem.props('file').location).toContain('http://');
    });

    it('renders project include from spec:include', () => {
      const thirdItem = fileTreeItems().at(2);
      expect(thirdItem.props('file')).toMatchObject({
        location: 'ci/sample.yml',
        type: 'file',
        contextProject: 'flightjs/ci-commit-ref-name',
      });
    });
  });
});
