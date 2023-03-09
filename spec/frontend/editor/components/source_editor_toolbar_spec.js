import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButtonGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import SourceEditorToolbar from '~/editor/components/source_editor_toolbar.vue';
import SourceEditorToolbarButton from '~/editor/components/source_editor_toolbar_button.vue';
import { EDITOR_TOOLBAR_LEFT_GROUP, EDITOR_TOOLBAR_RIGHT_GROUP } from '~/editor/constants';
import getToolbarItemsQuery from '~/editor/graphql/get_items.query.graphql';
import { buildButton } from './helpers';

Vue.use(VueApollo);

describe('Source Editor Toolbar', () => {
  let wrapper;
  let mockApollo;

  const findButtons = () => wrapper.findAllComponents(SourceEditorToolbarButton);

  const createApolloMockWithCache = (items = []) => {
    mockApollo = createMockApollo();
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getToolbarItemsQuery,
      data: {
        items: {
          nodes: items,
        },
      },
    });
  };

  const createComponentWithApollo = (items = []) => {
    createApolloMockWithCache(items);
    wrapper = shallowMount(SourceEditorToolbar, {
      apolloProvider: mockApollo,
      stubs: {
        GlButtonGroup,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  describe('groups', () => {
    it.each`
      group                         | expectedGroup
      ${EDITOR_TOOLBAR_LEFT_GROUP}  | ${EDITOR_TOOLBAR_LEFT_GROUP}
      ${EDITOR_TOOLBAR_RIGHT_GROUP} | ${EDITOR_TOOLBAR_RIGHT_GROUP}
      ${undefined}                  | ${EDITOR_TOOLBAR_RIGHT_GROUP}
      ${'non-existing'}             | ${EDITOR_TOOLBAR_RIGHT_GROUP}
    `('puts item with group="$group" into $expectedGroup group', ({ group, expectedGroup }) => {
      const item = buildButton('first', {
        group,
      });
      createComponentWithApollo([item]);
      expect(findButtons()).toHaveLength(1);
      [EDITOR_TOOLBAR_RIGHT_GROUP, EDITOR_TOOLBAR_LEFT_GROUP].forEach((g) => {
        if (g === expectedGroup) {
          expect(wrapper.vm.getGroupItems(g)).toEqual([expect.objectContaining({ id: 'first' })]);
        } else {
          expect(wrapper.vm.getGroupItems(g)).toHaveLength(0);
        }
      });
    });
  });

  describe('buttons update', () => {
    it('properly updates buttons on Apollo cache update', async () => {
      const item = buildButton('first', {
        group: EDITOR_TOOLBAR_RIGHT_GROUP,
      });
      createComponentWithApollo();

      expect(findButtons()).toHaveLength(0);

      mockApollo.clients.defaultClient.cache.writeQuery({
        query: getToolbarItemsQuery,
        data: {
          items: {
            nodes: [item],
          },
        },
      });

      jest.runOnlyPendingTimers();
      await nextTick();

      expect(findButtons()).toHaveLength(1);
    });
  });

  describe('click handler', () => {
    it('emits the "click" event when a button is clicked', () => {
      const item1 = buildButton('first', {
        group: EDITOR_TOOLBAR_LEFT_GROUP,
      });
      const item2 = buildButton('second', {
        group: EDITOR_TOOLBAR_RIGHT_GROUP,
      });
      createComponentWithApollo([item1, item2]);
      jest.spyOn(wrapper.vm, '$emit');
      expect(wrapper.vm.$emit).not.toHaveBeenCalled();

      findButtons().at(0).vm.$emit('click');
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('click', item1);

      findButtons().at(1).vm.$emit('click');
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('click', item2);

      expect(wrapper.vm.$emit.mock.calls).toHaveLength(2);
    });
  });
});
