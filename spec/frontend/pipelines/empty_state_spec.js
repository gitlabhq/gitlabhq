import '~/commons';
import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import { stubExperiments } from 'helpers/experimentation_helper';
import EmptyState from '~/pipelines/components/pipelines_list/empty_state.vue';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import PipelinesCiTemplates from '~/pipelines/components/pipelines_list/empty_state/pipelines_ci_templates.vue';
import IosTemplates from '~/pipelines/components/pipelines_list/empty_state/ios_templates.vue';

describe('Pipelines Empty State', () => {
  let wrapper;

  const findIllustration = () => wrapper.find('img');
  const findButton = () => wrapper.find('a');
  const pipelinesCiTemplates = () => wrapper.findComponent(PipelinesCiTemplates);
  const iosTemplates = () => wrapper.findComponent(IosTemplates);

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(EmptyState, {
      provide: {
        pipelineEditorPath: '',
        suggestedCiTemplates: [],
        anyRunnersAvailable: true,
        ciRunnerSettingsPath: '',
      },
      propsData: {
        emptyStateSvgPath: 'foo.svg',
        canSetCi: true,
        ...props,
      },
      stubs: {
        GlEmptyState,
        GitlabExperiment,
      },
    });
  };

  describe('when user can configure CI', () => {
    describe('when the ios_specific_templates experiment is active', () => {
      beforeEach(() => {
        stubExperiments({ ios_specific_templates: 'candidate' });
        createWrapper();
      });

      it('should render the iOS templates', () => {
        expect(iosTemplates().exists()).toBe(true);
      });

      it('should not render the CI/CD templates', () => {
        expect(pipelinesCiTemplates().exists()).toBe(false);
      });
    });

    describe('when the ios_specific_templates experiment is inactive', () => {
      beforeEach(() => {
        stubExperiments({ ios_specific_templates: 'control' });
        createWrapper();
      });

      it('should render the CI/CD templates', () => {
        expect(pipelinesCiTemplates().exists()).toBe(true);
      });

      it('should not render the iOS templates', () => {
        expect(iosTemplates().exists()).toBe(false);
      });
    });
  });

  describe('when user cannot configure CI', () => {
    beforeEach(() => {
      createWrapper({ canSetCi: false });
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
