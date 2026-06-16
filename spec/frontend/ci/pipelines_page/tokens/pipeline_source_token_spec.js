import { GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { PIPELINE_SOURCES } from 'ee_else_ce/ci/pipelines_page/tokens/constants';
import { stubComponent } from 'helpers/stub_component';
import PipelineSourceToken from '~/ci/pipelines_page/tokens/pipeline_source_token.vue';

describe('Pipeline Source Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);

  const defaultProps = {
    config: {
      type: 'source',
      icon: 'trigger-source',
      title: 'Source',
      unique: true,
    },
    value: {
      data: '',
    },
    cursorPosition: 'start',
  };

  const createComponent = () => {
    wrapper = shallowMount(PipelineSourceToken, {
      propsData: {
        ...defaultProps,
      },
      stubs: {
        GlFilteredSearchToken: stubComponent(GlFilteredSearchToken, {
          template: `<div><slot name="suggestions"></slot></div>`,
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('passes config correctly', () => {
    expect(findFilteredSearchToken().props('config')).toEqual(defaultProps.config);
  });

  describe('shows sources correctly', () => {
    it('renders all pipeline sources available', () => {
      expect(findAllFilteredSearchSuggestions()).toHaveLength(PIPELINE_SOURCES.length);
    });

    it.each(PIPELINE_SOURCES)(
      'renders a suggestion for "$text" with value "$value"',
      ({ text, value }) => {
        const match = findAllFilteredSearchSuggestions().wrappers.find(
          (s) => s.props('value') === value,
        );

        expect(match).toBeDefined();
        expect(match.text()).toBe(text);
      },
    );

    it('includes the dependency_management_security_update source', () => {
      const source = PIPELINE_SOURCES.find(
        (s) => s.value === 'dependency_management_security_update',
      );

      expect(source).toMatchObject({
        value: 'dependency_management_security_update',
        text: 'Dependency Management Security Update',
      });
    });
  });
});
