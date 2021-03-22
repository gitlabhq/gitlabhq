import { GlAlert, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { EDITOR_READY_EVENT } from '~/editor/constants';
import CiConfigMergedPreview from '~/pipeline_editor/components/editor/ci_config_merged_preview.vue';
import { INVALID_CI_CONFIG } from '~/pipelines/constants';
import { mockLintResponse, mockCiConfigPath } from '../../mock_data';

describe('Text editor component', () => {
  let wrapper;

  const MockEditorLite = {
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
        EditorLite: MockEditorLite,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findEditor = () => wrapper.findComponent(MockEditorLite);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when status is invalid', () => {
    beforeEach(() => {
      createComponent({ props: { isValid: false } });
    });

    it('show an error message', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(wrapper.vm.$options.errorTexts[INVALID_CI_CONFIG]);
    });

    it('hides the editor', () => {
      expect(findEditor().exists()).toBe(false);
    });
  });

  describe('when status is valid', () => {
    beforeEach(() => {
      createComponent({ props: { isValid: true } });
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
