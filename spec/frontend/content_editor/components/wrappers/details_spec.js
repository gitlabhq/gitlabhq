import { NodeViewContent } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DetailsWrapper from '~/content_editor/components/wrappers/details.vue';

describe('content/components/wrappers/details', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMountExtended(DetailsWrapper, {
      propsData: {
        node: {},
      },
    });
  };

  it('renders a node-view-content as a ul element', () => {
    createWrapper();

    expect(wrapper.findComponent(NodeViewContent).props().as).toBe('ul');
  });

  it('is "open" by default', () => {
    createWrapper();

    expect(wrapper.findByTestId('details-toggle-icon').classes()).toContain('is-open');
    expect(wrapper.findComponent(NodeViewContent).classes()).toContain('is-open');
  });

  it('closes the details block on clicking the details toggle icon', async () => {
    createWrapper();

    await wrapper.findByTestId('details-toggle-icon').trigger('click');
    expect(wrapper.findByTestId('details-toggle-icon').classes()).not.toContain('is-open');
    expect(wrapper.findComponent(NodeViewContent).classes()).not.toContain('is-open');
  });
});
