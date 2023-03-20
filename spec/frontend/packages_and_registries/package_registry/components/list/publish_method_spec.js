import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PublishMethod from '~/packages_and_registries/package_registry/components/list/publish_method.vue';
import { packagePipelines } from '../../mock_data';

const [pipelineData] = packagePipelines();

describe('publish_method', () => {
  let wrapper;

  const findPipelineRef = () => wrapper.findByTestId('pipeline-ref');
  const findPipelineSha = () => wrapper.findByTestId('pipeline-sha');
  const findManualPublish = () => wrapper.findByTestId('manually-published');

  const mountComponent = (pipeline = pipelineData) => {
    wrapper = shallowMountExtended(PublishMethod, {
      propsData: {
        pipeline,
      },
    });
  };

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('pipeline information', () => {
    it('displays branch and commit when pipeline info exists', () => {
      mountComponent();

      expect(findPipelineRef().exists()).toBe(true);
      expect(findPipelineSha().exists()).toBe(true);
    });

    it('does not show any pipeline details when no information exists', () => {
      mountComponent(null);

      expect(findPipelineRef().exists()).toBe(false);
      expect(findPipelineSha().exists()).toBe(false);
      expect(findManualPublish().text()).toBe(PublishMethod.i18n.MANUALLY_PUBLISHED);
    });
  });
});
