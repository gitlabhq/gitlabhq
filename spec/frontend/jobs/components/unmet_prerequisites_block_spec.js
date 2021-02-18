import { GlAlert, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UnmetPrerequisitesBlock from '~/jobs/components/unmet_prerequisites_block.vue';

describe('Unmet Prerequisites Block Job component', () => {
  let wrapper;
  const helpPath = '/user/project/clusters/index.html#troubleshooting-failed-deployment-jobs';

  const createComponent = () => {
    wrapper = shallowMount(UnmetPrerequisitesBlock, {
      propsData: {
        helpPath,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an alert with the correct message', () => {
    const container = wrapper.find(GlAlert);
    const alertMessage =
      'This job failed because the necessary resources were not successfully created.';

    expect(container).not.toBeNull();
    expect(container.text()).toContain(alertMessage);
  });

  it('renders link to help page', () => {
    const helpLink = wrapper.find(GlLink);

    expect(helpLink).not.toBeNull();
    expect(helpLink.text()).toContain('More information');
    expect(helpLink.attributes().href).toEqual(helpPath);
  });
});
