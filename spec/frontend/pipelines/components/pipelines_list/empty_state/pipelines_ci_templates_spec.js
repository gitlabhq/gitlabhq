import '~/commons';
import { GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import PipelinesCiTemplates from '~/pipelines/components/pipelines_list/empty_state/pipelines_ci_templates.vue';
import CiTemplates from '~/pipelines/components/pipelines_list/empty_state/ci_templates.vue';
import {
  RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME,
  RUNNERS_SETTINGS_LINK_CLICKED_EVENT,
  RUNNERS_DOCUMENTATION_LINK_CLICKED_EVENT,
  RUNNERS_SETTINGS_BUTTON_CLICKED_EVENT,
  I18N,
} from '~/ci/pipeline_editor/constants';

const pipelineEditorPath = '/-/ci/editor';
const ciRunnerSettingsPath = '/-/settings/ci_cd';

jest.mock('~/experimentation/experiment_tracking');

describe('Pipelines CI Templates', () => {
  let wrapper;
  let trackingSpy;

  const createWrapper = (propsData = {}, stubs = {}) => {
    return shallowMountExtended(PipelinesCiTemplates, {
      provide: {
        pipelineEditorPath,
        ciRunnerSettingsPath,
        anyRunnersAvailable: true,
        ...propsData,
      },
      stubs,
    });
  };

  const findTestTemplateLink = () => wrapper.findByTestId('test-template-link');
  const findCiTemplates = () => wrapper.findComponent(CiTemplates);
  const findSettingsLink = () => wrapper.findByTestId('settings-link');
  const findDocumentationLink = () => wrapper.findByTestId('documentation-link');
  const findSettingsButton = () => wrapper.findByTestId('settings-button');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('renders test template', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('links to the getting started template', () => {
      expect(findTestTemplateLink().attributes('href')).toBe(
        pipelineEditorPath.concat('?template=Getting-Started'),
      );
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      wrapper = createWrapper();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('sends an event when Getting-Started template is clicked', () => {
      findTestTemplateLink().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'template_clicked', {
        label: 'Getting-Started',
      });
    });
  });

  describe('when the runners_availability_section experiment is active', () => {
    beforeEach(() => {
      stubExperiments({ runners_availability_section: 'candidate' });
    });

    describe('when runners are available', () => {
      beforeEach(() => {
        wrapper = createWrapper({ anyRunnersAvailable: true }, { GitlabExperiment, GlSprintf });
      });

      it('show the runners available section', () => {
        expect(wrapper.text()).toContain(I18N.runners.title);
      });

      it('tracks an event when clicking the settings link', () => {
        findSettingsLink().vm.$emit('click');

        expect(ExperimentTracking).toHaveBeenCalledWith(
          RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME,
        );
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith(
          RUNNERS_SETTINGS_LINK_CLICKED_EVENT,
        );
      });

      it('tracks an event when clicking the documentation link', () => {
        findDocumentationLink().vm.$emit('click');

        expect(ExperimentTracking).toHaveBeenCalledWith(
          RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME,
        );
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith(
          RUNNERS_DOCUMENTATION_LINK_CLICKED_EVENT,
        );
      });
    });

    describe('when runners are not available', () => {
      beforeEach(() => {
        wrapper = createWrapper({ anyRunnersAvailable: false }, { GitlabExperiment, GlButton });
      });

      it('show the no runners available section', () => {
        expect(wrapper.text()).toContain(I18N.noRunners.title);
      });

      it('tracks an event when clicking the settings button', () => {
        findSettingsButton().trigger('click');

        expect(ExperimentTracking).toHaveBeenCalledWith(
          RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME,
        );
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith(
          RUNNERS_SETTINGS_BUTTON_CLICKED_EVENT,
        );
      });
    });
  });

  describe.each`
    experimentVariant | anyRunnersAvailable | templatesRendered
    ${'control'}      | ${true}             | ${true}
    ${'control'}      | ${false}            | ${true}
    ${'candidate'}    | ${true}             | ${true}
    ${'candidate'}    | ${false}            | ${false}
  `(
    'when the runners_availability_section experiment variant is $experimentVariant and runners are available: $anyRunnersAvailable',
    ({ experimentVariant, anyRunnersAvailable, templatesRendered }) => {
      beforeEach(() => {
        stubExperiments({ runners_availability_section: experimentVariant });
        wrapper = createWrapper({ anyRunnersAvailable });
      });

      it(`renders the templates: ${templatesRendered}`, () => {
        expect(findTestTemplateLink().exists()).toBe(templatesRendered);
        expect(findCiTemplates().exists()).toBe(templatesRendered);
      });
    },
  );
});
