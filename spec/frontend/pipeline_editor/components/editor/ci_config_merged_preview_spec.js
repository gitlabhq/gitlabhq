import { GlIcon, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { EDITOR_READY_EVENT } from '~/editor/constants';
import CiConfigMergedPreview from '~/pipeline_editor/components/editor/ci_config_merged_preview.vue';
import { mockLintResponse, mockCiConfigPath } from '../../mock_data';

const DEFAULT_BRANCH = 'main';

describe('Text editor component', () => {
  let wrapper;

  const MockSourceEditor = {
    template: '<div/>',
    props: ['value', 'fileName', 'editorOptions'],
    mounted() {
      this.$emit(EDITOR_READY_EVENT);
    },
  };

  const createComponent = ({ props = {}, currentBranch = DEFAULT_BRANCH } = {}) => {
    wrapper = shallowMount(CiConfigMergedPreview, {
      propsData: {
        ciConfigData: mockLintResponse,
        ...props,
      },
      provide: {
        ciConfigPath: mockCiConfigPath,
        defaultBranch: DEFAULT_BRANCH,
      },
      stubs: {
        SourceEditor: MockSourceEditor,
      },
      data() {
        return {
          currentBranch,
        };
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEditor = () => wrapper.findComponent(MockSourceEditor);

  afterEach(() => {
    wrapper.destroy();
  });

  // This is testing a temporary feature.
  // It may be slightly hacky code that doesn't follow best practice.
  // See the related MR for more information.
  // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65972#note_626095644
  describe('on a non-default branch', () => {
    beforeEach(() => {
      createComponent({ currentBranch: 'feature' });
    });

    it('does not load the editor', () => {
      expect(findEditor().exists()).toBe(false);
    });

    it('renders an informational alert', () => {
      expect(findAlert().exists()).toBe(true);
    });
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
