import '~/commons';
import { GlButton, GlSprintf } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import PipelinesCiTemplate from '~/pipelines/components/pipelines_list/pipelines_ci_templates.vue';
import {
  RUNNERS_AVAILABILITY_SECTION_EXPERIMENT_NAME,
  RUNNERS_SETTINGS_LINK_CLICKED_EVENT,
  RUNNERS_DOCUMENTATION_LINK_CLICKED_EVENT,
  RUNNERS_SETTINGS_BUTTON_CLICKED_EVENT,
  I18N,
} from '~/pipeline_editor/constants';

const pipelineEditorPath = '/-/ci/editor';
const suggestedCiTemplates = [
  { name: 'Android', logo: '/assets/illustrations/logos/android.svg' },
  { name: 'Bash', logo: '/assets/illustrations/logos/bash.svg' },
  { name: 'C++', logo: '/assets/illustrations/logos/c_plus_plus.svg' },
];

jest.mock('~/experimentation/experiment_tracking');

describe('Pipelines CI Templates', () => {
  let wrapper;
  let trackingSpy;

  const createWrapper = (propsData = {}, stubs = {}) => {
    return shallowMountExtended(PipelinesCiTemplate, {
      provide: {
        pipelineEditorPath,
        suggestedCiTemplates,
      },
      propsData,
      stubs,
    });
  };

  const findTestTemplateLinks = () => wrapper.findAll('[data-testid="test-template-link"]');
  const findTemplateDescriptions = () => wrapper.findAll('[data-testid="template-description"]');
  const findTemplateLinks = () => wrapper.findAll('[data-testid="template-link"]');
  const findTemplateNames = () => wrapper.findAll('[data-testid="template-name"]');
  const findTemplateLogos = () => wrapper.findAll('[data-testid="template-logo"]');
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
      expect(findTestTemplateLinks().at(0).attributes('href')).toBe(
        pipelineEditorPath.concat('?template=Getting-Started'),
      );
    });
  });

  describe('renders template list', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders all suggested templates', () => {
      const content = wrapper.text();

      expect(content).toContain('Android', 'Bash', 'C++');
    });

    it('has the correct template name', () => {
      expect(findTemplateNames().at(0).text()).toBe('Android');
    });

    it('links to the correct template', () => {
      expect(findTemplateLinks().at(0).attributes('href')).toBe(
        pipelineEditorPath.concat('?template=Android'),
      );
    });

    it('has the description of the template', () => {
      expect(findTemplateDescriptions().at(0).text()).toBe(
        sprintf(I18N.templates.description, { name: 'Android' }),
      );
    });

    it('has the right logo of the template', () => {
      expect(findTemplateLogos().at(0).attributes('src')).toBe(
        '/assets/illustrations/logos/android.svg',
      );
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      wrapper = createWrapper();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('sends an event when template is clicked', () => {
      findTemplateLinks().at(0).vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'template_clicked', {
        label: 'Android',
      });
    });

    it('sends an event when Getting-Started template is clicked', () => {
      findTestTemplateLinks().at(0).vm.$emit('click');

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

      it('renders the templates', () => {
        expect(findTestTemplateLinks().exists()).toBe(true);
        expect(findTemplateLinks().exists()).toBe(true);
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

      it('does not render the templates', () => {
        expect(findTestTemplateLinks().exists()).toBe(false);
        expect(findTemplateLinks().exists()).toBe(false);
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
});
