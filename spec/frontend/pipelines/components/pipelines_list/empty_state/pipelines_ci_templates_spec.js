import '~/commons';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import PipelinesCiTemplates from '~/pipelines/components/pipelines_list/empty_state/pipelines_ci_templates.vue';
import CiTemplates from '~/pipelines/components/pipelines_list/empty_state/ci_templates.vue';

const pipelineEditorPath = '/-/ci/editor';

describe('Pipelines CI Templates', () => {
  let wrapper;
  let trackingSpy;

  const createWrapper = (propsData = {}, stubs = {}) => {
    return shallowMountExtended(PipelinesCiTemplates, {
      provide: {
        pipelineEditorPath,
        ...propsData,
      },
      stubs,
    });
  };

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
});
