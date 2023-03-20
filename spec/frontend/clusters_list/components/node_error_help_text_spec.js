import { GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import NodeErrorHelpText from '~/clusters_list/components/node_error_help_text.vue';

describe('NodeErrorHelpText', () => {
  let wrapper;

  const createWrapper = async (propsData) => {
    wrapper = shallowMount(NodeErrorHelpText, { propsData, stubs: { GlPopover } });
    await nextTick();
  };

  const findPopover = () => wrapper.findComponent(GlPopover);

  it.each`
    errorType                 | wrapperText                 | popoverText
    ${'authentication_error'} | ${'Unable to Authenticate'} | ${'GitLab failed to authenticate'}
    ${'connection_error'}     | ${'Unable to Connect'}      | ${'GitLab failed to connect to the cluster'}
    ${'http_error'}           | ${'Unable to Connect'}      | ${'There was an HTTP error when connecting to your cluster'}
    ${'default'}              | ${'Unknown Error'}          | ${'An unknown error occurred while attempting to connect to Kubernetes.'}
    ${'unknown_error_type'}   | ${'Unknown Error'}          | ${'An unknown error occurred while attempting to connect to Kubernetes.'}
    ${null}                   | ${'Unknown Error'}          | ${'An unknown error occurred while attempting to connect to Kubernetes.'}
  `('displays error text', ({ errorType, wrapperText, popoverText }) => {
    return createWrapper({ errorType, popoverId: 'id' }).then(() => {
      expect(wrapper.text()).toContain(wrapperText);
      expect(findPopover().text()).toContain(popoverText);
    });
  });
});
