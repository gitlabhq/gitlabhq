import '~/commons';
import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import PipelinesCiTemplates from '~/ci/pipelines_page/components/empty_state/pipelines_ci_templates.vue';
import CiTemplates from '~/ci/pipelines_page/components/empty_state/ci_templates.vue';

const pipelineEditorPath = '/-/ci/editor';

describe('Pipelines CI Templates', () => {
  let wrapper;
  let trackingSpy;

  const createWrapper = (propsData = {}, stubs = {}) => {
    return shallowMountExtended(PipelinesCiTemplates, {
      provide: {
        pipelineEditorPath,
        showJenkinsCiPrompt: false,
        ...propsData,
      },
      stubs,
    });
  };

  const findMigrateFromJenkinsPrompt = () => wrapper.findByTestId('migrate-from-jenkins-prompt');
  const findMigrationPlanBtn = () => findMigrateFromJenkinsPrompt().findComponent(GlButton);
  const findTestTemplateLink = () => wrapper.findByTestId('test-template-link');
  const findCiTemplates = () => wrapper.findComponent(CiTemplates);

  describe('templates', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders test template and Ci templates', () => {
      expect(findTestTemplateLink().attributes('href')).toBe(
        pipelineEditorPath.concat('?template=Getting-Started'),
      );
      expect(findCiTemplates().exists()).toBe(true);
    });

    it('does not show migrate from jenkins prompt', () => {
      expect(findMigrateFromJenkinsPrompt().exists()).toBe(false);
    });

    describe('when Jenkinsfile is detected', () => {
      beforeEach(() => {
        wrapper = createWrapper({ showJenkinsCiPrompt: true });
      });

      it('shows migrate from jenkins prompt', () => {
        expect(findMigrateFromJenkinsPrompt().exists()).toBe(true);
      });

      it('opens correct link in new tab after clicking migration plan CTA', () => {
        expect(findMigrationPlanBtn().attributes('href')).toBe(
          '/help/ci/migration/plan_a_migration',
        );
        expect(findMigrationPlanBtn().attributes('target')).toBe('_blank');
      });
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

    describe('when Jenkinsfile detected', () => {
      beforeEach(() => {
        wrapper = createWrapper({ showJenkinsCiPrompt: true });
      });

      it('creates render event on page load', () => {
        expect(trackingSpy).toHaveBeenCalledTimes(1);
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
          label: 'migrate_from_jenkins_prompt',
        });
      });

      it('sends an event when migration plan is clicked', () => {
        findMigrationPlanBtn().vm.$emit('click');

        expect(trackingSpy).toHaveBeenCalledTimes(2);
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'template_clicked', {
          label: 'migrate_from_jenkins_prompt',
        });
      });
    });
  });
});
