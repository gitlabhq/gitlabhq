import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import data from 'test_fixtures/deploy_keys/keys.json';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import enableKeyMutation from '~/deploy_keys/graphql/mutations/enable_key.mutation.graphql';
import actionBtn from '~/deploy_keys/components/action_btn.vue';

Vue.use(VueApollo);

describe('Deploy keys action btn', () => {
  const deployKey = data.enabled_keys[0];
  let wrapper;
  let enableKeyMock;

  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    enableKeyMock = jest.fn();

    const mockResolvers = {
      Mutation: {
        enableKey: enableKeyMock,
      },
    };

    const apolloProvider = createMockApollo([], mockResolvers);
    wrapper = shallowMount(actionBtn, {
      propsData: {
        deployKey,
        category: 'primary',
        variant: 'confirm',
        icon: 'edit',
        mutation: enableKeyMutation,
      },
      slots: {
        default: 'Enable',
      },
      apolloProvider,
    });
  });

  it('renders the default slot', () => {
    expect(wrapper.text()).toBe('Enable');
  });

  it('passes the button props on', () => {
    expect(findButton().props()).toMatchObject({
      category: 'primary',
      variant: 'confirm',
      icon: 'edit',
    });
  });

  it('fires the passed mutation', async () => {
    findButton().vm.$emit('click');

    await nextTick();
    expect(enableKeyMock).toHaveBeenCalledWith(
      expect.anything(),
      { id: deployKey.id },
      expect.anything(),
      expect.anything(),
    );
  });

  it('emits the mutation error', async () => {
    const error = new Error('oops!');
    enableKeyMock.mockRejectedValue(error);
    findButton().vm.$emit('click');

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[error]]);
  });

  it('shows loading spinner after click', async () => {
    findButton().vm.$emit('click');

    await nextTick();
    expect(findButton().props('loading')).toBe(true);
  });
});
