import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import SourceEditorToolbarButton from '~/editor/components/source_editor_toolbar_button.vue';
import getToolbarItemQuery from '~/editor/graphql/get_item.query.graphql';
import updateToolbarItemMutation from '~/editor/graphql/update_item.mutation.graphql';
import { buildButton } from './helpers';

Vue.use(VueApollo);

describe('Source Editor Toolbar button', () => {
  let wrapper;
  let mockApollo;
  const defaultBtn = buildButton();

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponentWithApollo = ({ propsData } = {}) => {
    mockApollo = createMockApollo();
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getToolbarItemQuery,
      variables: { id: defaultBtn.id },
      data: {
        item: {
          ...defaultBtn,
        },
      },
    });

    wrapper = shallowMount(SourceEditorToolbarButton, {
      propsData,
      apolloProvider: mockApollo,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    mockApollo = null;
  });

  describe('default', () => {
    const defaultProps = {
      category: 'primary',
      variant: 'default',
    };
    const customProps = {
      category: 'secondary',
      variant: 'info',
    };
    it('renders a default button without props', async () => {
      createComponentWithApollo();
      const btn = findButton();
      expect(btn.exists()).toBe(true);
      expect(btn.props()).toMatchObject(defaultProps);
    });

    it('renders a button based on the props passed', async () => {
      createComponentWithApollo({
        propsData: {
          button: customProps,
        },
      });
      const btn = findButton();
      expect(btn.props()).toMatchObject(customProps);
    });
  });

  describe('button updates', () => {
    it('it properly updates button on Apollo cache update', async () => {
      const { id } = defaultBtn;

      createComponentWithApollo({
        propsData: {
          button: {
            id,
          },
        },
      });

      expect(findButton().props('selected')).toBe(false);

      mockApollo.clients.defaultClient.cache.writeQuery({
        query: getToolbarItemQuery,
        variables: { id },
        data: {
          item: {
            ...defaultBtn,
            selected: true,
          },
        },
      });

      jest.runOnlyPendingTimers();
      await nextTick();

      expect(findButton().props('selected')).toBe(true);
    });
  });

  describe('click handler', () => {
    it('fires the click handler on the button when available', () => {
      const spy = jest.fn();
      createComponentWithApollo({
        propsData: {
          button: {
            onClick: spy,
          },
        },
      });
      expect(spy).not.toHaveBeenCalled();
      findButton().vm.$emit('click');
      expect(spy).toHaveBeenCalled();
    });
    it('emits the "click" event', () => {
      createComponentWithApollo();
      jest.spyOn(wrapper.vm, '$emit');
      expect(wrapper.vm.$emit).not.toHaveBeenCalled();
      findButton().vm.$emit('click');
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('click');
    });
    it('triggers the mutation exposing the changed "selected" prop', () => {
      const { id } = defaultBtn;
      createComponentWithApollo({
        propsData: {
          button: {
            id,
          },
        },
      });
      jest.spyOn(wrapper.vm.$apollo, 'mutate');
      expect(wrapper.vm.$apollo.mutate).not.toHaveBeenCalled();
      findButton().vm.$emit('click');
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updateToolbarItemMutation,
        variables: {
          id,
          propsToUpdate: {
            selected: true,
          },
        },
      });
    });
  });
});
