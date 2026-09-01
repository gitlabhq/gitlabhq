import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import * as sentryBrowserWrapper from '~/sentry/sentry_browser_wrapper';
import ScopePicker from '~/explore/analytics_dashboards/components/scope_picker.vue';
import ScopePickerItem from '~/explore/analytics_dashboards/components/scope_picker_item.vue';
import getGroupProjectsQuery from '~/explore/analytics_dashboards/graphql/get_group_projects.query.graphql';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');

describe('ScopePicker', () => {
  let wrapper;
  let requestHandler;

  const groupFullPath = 'gitlab-org';
  const closeListbox = jest.fn();

  const mockGroup = {
    __typename: TYPENAME_GROUP,
    id: 'gid://gitlab/Group/1',
    name: 'GitLab.org',
    fullName: 'GitLab.org',
    fullPath: groupFullPath,
  };

  const mockProject = (id, name, path) => ({
    __typename: TYPENAME_PROJECT,
    id: `gid://gitlab/Project/${id}`,
    name,
    fullName: `GitLab.org / ${name}`,
    fullPath: `${groupFullPath}/${path}`,
  });

  const mockProjects = [mockProject(1, 'GitLab', 'gitlab'), mockProject(2, 'Charts', 'charts')];

  const respondWith = (projects) =>
    jest.fn().mockResolvedValue({
      data: {
        group: {
          ...mockGroup,
          projects: { __typename: 'ProjectConnection', nodes: projects },
        },
      },
    });

  const asNamespace = ({ __typename, ...namespace }) => ({ ...namespace, type: __typename });

  // The real listbox only renders its list-item slot for each item, and the footer below it.
  const listboxStub = stubComponent(GlCollapsibleListbox, {
    template: `
      <div>
        <div v-for="item in items" :key="item.value">
          <slot name="list-item" :item="item"></slot>
        </div>
        <slot name="footer"></slot>
      </div>`,
    methods: { close: closeListbox },
  });

  const createWrapper = ({ handler = respondWith(mockProjects) } = {}) => {
    requestHandler = handler;

    wrapper = shallowMountExtended(ScopePicker, {
      apolloProvider: createMockApollo([[getGroupProjectsQuery, requestHandler]]),
      propsData: { groupFullPath },
      stubs: { GlCollapsibleListbox: listboxStub },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDoneButton = () => wrapper.findComponent(GlButton);
  const findItems = () => wrapper.findAllComponents(ScopePickerItem);
  const findItemAt = (index) => findItems().at(index);

  // Mirrors what the listbox emits on click: the whole selection, with the clicked item toggled.
  const toggleSelected = ({ fullPath }) => {
    const selected = findListbox().props('selected');
    const paths = selected.includes(fullPath)
      ? selected.filter((path) => path !== fullPath)
      : [...selected, fullPath];

    return findListbox().vm.$emit('select', paths);
  };
  const toggleExpanded = () => findItemAt(0).vm.$emit('toggle-expanded');

  describe('while loading', () => {
    beforeEach(() => createWrapper());

    it('requests the group and its projects', () => {
      expect(requestHandler).toHaveBeenCalledWith({ fullPath: groupFullPath });
    });

    it('sets the listbox to loading', () => {
      expect(findListbox().props('loading')).toBe(true);
      expect(findListbox().props('searching')).toBe(true);
    });

    it('renders no items', () => {
      expect(findItems()).toHaveLength(0);
    });
  });

  describe('once loaded', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('stops loading', () => {
      expect(findListbox().props('loading')).toBe(false);
    });

    it('allows multiple selected values, so the listbox stays open while picking', () => {
      expect(findListbox().props('multiple')).toBe(true);
    });

    it('titles the listbox', () => {
      expect(findListbox().props('headerText')).toBe('Scope');
    });

    it('prompts for a selection', () => {
      expect(findListbox().props('toggleText')).toBe('Select a group or project');
    });

    it('lists the group above its projects', () => {
      expect(
        findListbox()
          .props('items')
          .map(({ value, text }) => ({ value, text })),
      ).toEqual([
        { value: mockGroup.fullPath, text: mockGroup.name },
        ...mockProjects.map(({ fullPath, name }) => ({ value: fullPath, text: name })),
      ]);
    });

    it('renders an item for each listbox entry', () => {
      expect(findItems().wrappers.map((item) => item.props('value'))).toEqual([
        mockGroup.fullPath,
        ...mockProjects.map(({ fullPath }) => fullPath),
      ]);
    });

    it('renders the group item as an expanded parent', () => {
      expect(findItemAt(0).props()).toMatchObject({
        text: mockGroup.name,
        namespaceType: TYPENAME_GROUP,
        expandable: true,
        expanded: true,
        nested: false,
        selected: false,
        disabled: false,
      });
    });

    it('renders the project items as nested children', () => {
      expect(findItemAt(1).props()).toMatchObject({
        text: mockProjects[0].name,
        namespaceType: TYPENAME_PROJECT,
        expandable: false,
        nested: true,
        selected: false,
        disabled: false,
      });
    });
  });

  describe('when the group has no projects', () => {
    beforeEach(async () => {
      createWrapper({ handler: respondWith([]) });
      await waitForPromises();
    });

    it('renders only the group item, without an expand toggle', () => {
      expect(findItems()).toHaveLength(1);
      expect(findItemAt(0).props('expandable')).toBe(false);
    });
  });

  describe('when the group item is collapsed', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
      await toggleExpanded();
    });

    it('hides the project items', () => {
      expect(findItems()).toHaveLength(1);
      expect(findItemAt(0).props('expanded')).toBe(false);
    });

    it('keeps the toggle text of a selection made while expanded', async () => {
      await toggleExpanded();
      await toggleSelected(mockProjects[0]);
      await toggleExpanded();

      expect(findListbox().props('toggleText')).toBe(mockProjects[0].name);
    });

    it('expands again when toggled', async () => {
      await toggleExpanded();

      expect(findItems()).toHaveLength(mockProjects.length + 1);
    });
  });

  describe('when a project is selected', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
      await toggleSelected(mockProjects[0]);
    });

    it('emits change with the selected namespace', () => {
      expect(wrapper.emitted('change')).toEqual([[asNamespace(mockProjects[0])]]);
    });

    it('displays the selection in the toggle text', () => {
      expect(findListbox().props('toggleText')).toBe(mockProjects[0].name);
    });

    it('marks only the selected item in the listbox', () => {
      expect(findListbox().props('selected')).toEqual([mockProjects[0].fullPath]);
    });

    it('checks only the selected item', () => {
      expect(findItems().wrappers.map((item) => item.props('selected'))).toEqual([
        false,
        true,
        false,
      ]);
    });

    it('leaves the other items enabled', () => {
      expect(findItems().wrappers.every((item) => item.props('disabled'))).toBe(false);
    });

    it('renders the group it belongs to as indeterminate', () => {
      expect(findItems().wrappers.map((item) => item.props('indeterminate'))).toEqual([
        true,
        false,
        false,
      ]);
    });

    describe('and then unselected', () => {
      beforeEach(() => toggleSelected(mockProjects[0]));

      it('emits change with null', () => {
        expect(wrapper.emitted('change')[1]).toEqual([null]);
      });

      it('restores the prompt', () => {
        expect(findListbox().props('toggleText')).toBe('Select a group or project');
      });
    });

    describe('and another project is selected', () => {
      beforeEach(() => toggleSelected(mockProjects[1]));

      it('replaces the selection', () => {
        expect(wrapper.emitted('change')[1]).toEqual([asNamespace(mockProjects[1])]);
        expect(findItems().wrappers.map((item) => item.props('selected'))).toEqual([
          false,
          false,
          true,
        ]);
      });
    });

    describe('and the indeterminate group is selected', () => {
      beforeEach(() => toggleSelected(mockGroup));

      it('emits change with null', () => {
        expect(wrapper.emitted('change')[1]).toEqual([null]);
      });

      it('clears the selection instead of selecting the group', () => {
        expect(findListbox().props('selected')).toEqual([]);
        expect(findItemAt(0).props('indeterminate')).toBe(false);
      });
    });
  });

  describe('when the group is selected', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
      await toggleSelected(mockGroup);
    });

    it('emits change with the group namespace', () => {
      expect(wrapper.emitted('change')).toEqual([[asNamespace(mockGroup)]]);
    });

    it('checks the projects it covers', () => {
      expect(findItems().wrappers.map((item) => item.props('selected'))).toEqual([
        true,
        true,
        true,
      ]);
    });

    it('locks the projects it covers', () => {
      expect(findItems().wrappers.map((item) => item.props('disabled'))).toEqual([
        false,
        true,
        true,
      ]);
      expect(
        findListbox()
          .props('items')
          .map(({ disabled }) => disabled),
      ).toEqual([false, true, true]);
    });

    it('renders no indeterminate items', () => {
      expect(findItems().wrappers.some((item) => item.props('indeterminate'))).toBe(false);
    });

    describe('and then unselected', () => {
      beforeEach(() => toggleSelected(mockGroup));

      it('clears the selection', () => {
        expect(wrapper.emitted('change')[1]).toEqual([null]);
        expect(findListbox().props('selected')).toEqual([]);
      });
    });
  });

  describe('when Done is clicked', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('closes the listbox', () => {
      findDoneButton().vm.$emit('click');

      expect(closeListbox).toHaveBeenCalled();
    });
  });

  describe('when the query fails', () => {
    const error = new Error('oh no');

    beforeEach(async () => {
      createWrapper({ handler: jest.fn().mockRejectedValue(error) });
      await waitForPromises();
    });

    it('emits error', () => {
      expect(wrapper.emitted('error')).toEqual([[error]]);
    });

    it('logs the error to sentry', () => {
      expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(error);
    });

    it('renders no items', () => {
      expect(findItems()).toHaveLength(0);
    });
  });
});
