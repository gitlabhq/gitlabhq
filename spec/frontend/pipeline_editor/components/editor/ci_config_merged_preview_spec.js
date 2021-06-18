import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { EDITOR_READY_EVENT } from '~/editor/constants';
import CiConfigMergedPreview from '~/pipeline_editor/components/editor/ci_config_merged_preview.vue';
import { mockLintResponse, mockCiConfigPath } from '../../mock_data';

describe('Text editor component', () => {
  let wrapper;

  const MockSourceEditor = {
    template: '<div/>',
    props: ['value', 'fileName', 'editorOptions'],
    mounted() {
      this.$emit(EDITOR_READY_EVENT);
    },
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(CiConfigMergedPreview, {
      propsData: {
        ciConfigData: mockLintResponse,
        ...props,
      },
      provide: {
        ciConfigPath: mockCiConfigPath,
      },
      stubs: {
        SourceEditor: MockSourceEditor,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findEditor = () => wrapper.findComponent(MockSourceEditor);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when status is valid', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows an information message that the section is not editable', () => {
      expect(findIcon().exists()).toBe(true);
      expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.viewOnlyMessage);
    });

    it('contains an editor', () => {
      expect(findEditor().exists()).toBe(true);
    });

    it('editor contains the value provided', () => {
      expect(findEditor().props('value')).toBe(mockLintResponse.mergedYaml);
    });

    it('editor is configured for the CI config path', () => {
      expect(findEditor().props('fileName')).toBe(mockCiConfigPath);
    });

    it('editor is readonly', () => {
      expect(findEditor().props('editorOptions')).toMatchObject({
        readOnly: true,
      });
    });
  });
});
