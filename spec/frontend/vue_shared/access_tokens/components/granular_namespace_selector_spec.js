import { GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import GranularNamespaceSelector from '~/vue_shared/access_tokens/components/granular_namespace_selector.vue';
import { mockGroups, mockProjects } from '../mock_data';

describe('GranularNamespaceSelector', () => {
  let wrapper;

  const selectedIds = ['gid://gitlab/Project/1', 'gid://gitlab/Group/1'];
  const selectedNamespaces = [mockProjects[0], mockGroups[0]];

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(GranularNamespaceSelector, {
      propsData: {
        groups: mockGroups,
        projects: mockProjects,
        ...props,
      },
    });
  };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSelectedNamespaces = () => wrapper.findByTestId('selected-namespaces');
  const findRemoveButtons = () => wrapper.findAllComponentsByTestId('remove-namespace');
  const findDescendantCounts = () => wrapper.findByTestId('descendant-counts');
  const findSearchHint = () => wrapper.findByTestId('search-hint');

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('renders the crud component with the default title', () => {
      expect(findCrudComponent().props('title')).toBe('Group or project');
    });

    it('renders the collapsible listbox', () => {
      expect(findListbox().props('toggleText')).toBe('Add group or project');
      expect(findListbox().props('searching')).toBe(false);
    });

    it('announces the result count to screen readers', () => {
      expect(findListbox().props('srOnlyResultsLabel')(2)).toBe('2 results');
    });

    it('does not render a search hint', () => {
      expect(findSearchHint().exists()).toBe(false);
    });

    it('renders empty text', () => {
      expect(wrapper.text()).toContain('No groups or projects added.');
    });

    describe('with a title', () => {
      beforeEach(() => {
        createComponent({ props: { title: 'Groups and projects in Acme' } });
      });

      it('renders the given title', () => {
        expect(findCrudComponent().props('title')).toBe('Groups and projects in Acme');
      });
    });

    describe('with a search hint', () => {
      const searchHint = 'Enter a full path to find more namespaces.';

      beforeEach(() => {
        createComponent({ props: { searchHint } });
      });

      it('renders the hint in the listbox footer', () => {
        expect(findSearchHint().text()).toBe(searchHint);
      });

      it('announces the hint to screen readers along with the result count', () => {
        expect(findListbox().props('srOnlyResultsLabel')(2)).toBe(`2 results. ${searchHint}`);
      });
    });

    describe('while loading', () => {
      beforeEach(() => {
        createComponent({ props: { isLoading: true } });
      });

      it('marks the listbox as searching', () => {
        expect(findListbox().props('searching')).toBe(true);
      });
    });

    describe('with an error', () => {
      beforeEach(() => {
        createComponent({ props: { error: 'At least one group or project is required.' } });
      });

      it('renders the error message', () => {
        expect(wrapper.text()).toContain('At least one group or project is required.');
      });
    });
  });

  describe('listbox items', () => {
    it('formats groups and projects into listbox items', () => {
      expect(findListbox().props('items')).toEqual([
        {
          text: 'Groups',
          options: mockGroups.map((group) => ({ value: group.id, text: group.fullPath })),
        },
        {
          text: 'Projects',
          options: mockProjects.map((project) => ({
            value: project.id,
            text: project.fullPath,
          })),
        },
      ]);
    });

    describe('when there are no groups or projects', () => {
      beforeEach(() => {
        createComponent({ props: { groups: [], projects: [] } });
      });

      it('shows the no matches message', () => {
        expect(findListbox().text()).toContain('No matches found');
      });
    });
  });

  describe('searching', () => {
    it('emits `search` with the term when the listbox searches', async () => {
      await findListbox().vm.$emit('search', 'test search');

      expect(wrapper.emitted('search')).toEqual([['test search']]);
    });
  });

  describe('selecting namespaces', () => {
    it('emits `input` with the selected groups and projects', async () => {
      await findListbox().vm.$emit('select', selectedIds);

      expect(wrapper.emitted('input')).toEqual([[selectedNamespaces]]);
    });

    describe('with a value', () => {
      const value = [];

      beforeEach(() => {
        createComponent({ props: { value } });
      });

      it('does not change the value prop', async () => {
        await findListbox().vm.$emit('select', selectedIds);

        expect(value).toEqual([]);
      });
    });

    describe('when a selected namespace is no longer among the listed items', () => {
      beforeEach(() => {
        createComponent({ props: { value: [mockGroups[0]], groups: [] } });
      });

      it('keeps it from the value', async () => {
        await findListbox().vm.$emit('select', [mockGroups[0].id, mockProjects[0].id]);

        expect(wrapper.emitted('input')).toEqual([[[mockGroups[0], mockProjects[0]]]]);
      });
    });
  });

  describe('selected namespaces', () => {
    beforeEach(() => {
      createComponent({ props: { value: selectedNamespaces } });
    });

    it('displays selected groups', () => {
      expect(findSelectedNamespaces().text()).toContain('test-group-1');
      expect(findSelectedNamespaces().text()).toContain('2 subgroups');
      expect(findSelectedNamespaces().text()).toContain('5 projects');
    });

    it('displays selected projects', () => {
      expect(findSelectedNamespaces().text()).toContain('test-group-1/test-project-1');
    });

    it('marks the selected items in the listbox', () => {
      expect(findListbox().props('selected')).toEqual(selectedIds);
      expect(findListbox().props('headerText')).toBe('2 selected');
    });

    it('displays the `aria-label` for remove buttons', () => {
      expect(findRemoveButtons().at(0).attributes('aria-label')).toBe(
        'Remove project Test Project 1',
      );
      expect(findRemoveButtons().at(1).attributes('aria-label')).toBe('Remove group Test Group 1');
    });

    it('emits `input` without the item when its remove button is clicked', async () => {
      await findRemoveButtons().at(0).vm.$emit('click');

      expect(wrapper.emitted('input')).toEqual([[[mockGroups[0]]]]);
    });
  });

  describe('pre-filling namespaces', () => {
    const value = [
      {
        id: 'gid://gitlab/Group/1',
        name: 'Test Group 1',
        fullPath: 'test-group-1',
        __typename: 'Group',
      },
    ];

    describe('without listed items', () => {
      beforeEach(() => {
        createComponent({ props: { value, groups: [], projects: [] } });
      });

      it('shows the pre-populated namespace chips', () => {
        expect(findSelectedNamespaces().text()).toContain('test-group-1');
      });

      it('does not render descendant counts when they are unavailable', () => {
        expect(findDescendantCounts().exists()).toBe(false);
      });
    });

    describe('when the pre-filled group provides descendant counts', () => {
      beforeEach(() => {
        createComponent({ props: { value: [mockGroups[0]] } });
      });

      it('renders them', () => {
        expect(findDescendantCounts().text()).toBe('2 subgroups, 5 projects');
      });
    });
  });
});
