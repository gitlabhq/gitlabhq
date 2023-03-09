import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import ListItem from '~/saved_replies/components/list_item.vue';
import deleteSavedReplyMutation from '~/saved_replies/queries/delete_saved_reply.mutation.graphql';

let wrapper;
let deleteSavedReplyMutationResponse;

function createComponent(propsData = {}) {
  Vue.use(VueApollo);

  deleteSavedReplyMutationResponse = jest
    .fn()
    .mockResolvedValue({ data: { savedReplyDestroy: { errors: [] } } });

  return shallowMount(ListItem, {
    propsData,
    directives: {
      GlModal: createMockDirective('gl-modal'),
    },
    apolloProvider: createMockApollo([
      [deleteSavedReplyMutation, deleteSavedReplyMutationResponse],
    ]),
  });
}

describe('Saved replies list item component', () => {
  it('renders list item', async () => {
    wrapper = createComponent({ reply: { name: 'test', content: '/assign_reviewer' } });

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('delete button', () => {
    it('calls Apollo mutate', async () => {
      wrapper = createComponent({ reply: { name: 'test', content: '/assign_reviewer', id: 1 } });

      wrapper.findComponent(GlModal).vm.$emit('primary');

      await waitForPromises();

      expect(deleteSavedReplyMutationResponse).toHaveBeenCalledWith({ id: 1 });
    });
  });
});
