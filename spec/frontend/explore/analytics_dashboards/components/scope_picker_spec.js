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
import getGroupChildrenQuery from '~/explore/analytics_dashboards/graphql/get_group_children.query.graphql';
import getSubgroupProjectsQuery from '~/explore/analytics_dashboards/graphql/get_subgroup_projects.query.graphql';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');

describe('ScopePicker', () => {
  let wrapper;
  let requestHandler;
  let subgroupRequestHandler;

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

  const mockSubgroup = ({ id, name, path, projectsCount = 0, descendantGroupsCount = 0 }) => ({
    __typename: TYPENAME_GROUP,
    id: `gid://gitlab/Group/${id}`,
    name,
    fullName: `GitLab.org / ${name}`,
    fullPath: `${groupFullPath}/${path}`,
    projectsCount,
    descendantGroupsCount,
  });

  const mockProjects = [mockProject(1, 'GitLab', 'gitlab'), mockProject(2, 'Charts', 'charts')];

  const mockFrontend = mockSubgroup({
    id: 10,
    name: 'Frontend',
    path: 'frontend',
    projectsCount: 1,
    descendantGroupsCount: 1,
  });
  const mockQuality = mockSubgroup({ id: 11, name: 'Quality', path: 'quality' });
  const mockSubgroups = [mockFrontend, mockQuality];

  const mockTools = {
    __typename: TYPENAME_GROUP,
    id: 'gid://gitlab/Group/12',
    name: 'Tools',
    fullPath: `${groupFullPath}/frontend/tools`,
  };

  // One project directly in the expanded subgroup, one from a subgroup nested below it.
  const mockSubgroupProjects = [
    {
      ...mockProject(3, 'GitLab UI', 'frontend/gitlab-ui'),
      namespace: {
        __typename: TYPENAME_GROUP,
        id: mockFrontend.id,
        name: mockFrontend.name,
        fullPath: mockFrontend.fullPath,
      },
    },
    {
      ...mockProject(4, 'Design tools', 'frontend/tools/design'),
      namespace: mockTools,
    },
  ];

  const respondWith = ({ projects = mockProjects, subgroups = mockSubgroups } = {}) =>
    jest.fn().mockResolvedValue({
      data: {
        group: {
          ...mockGroup,
          projects: { __typename: 'ProjectConnection', nodes: projects },
          descendantGroups: { __typename: 'GroupConnection', nodes: subgroups },
        },
      },
    });

  const respondWithSubgroupProjects = (projects = mockSubgroupProjects) =>
    jest.fn().mockResolvedValue({
      data: {
        group: {
          __typename: TYPENAME_GROUP,
          id: mockFrontend.id,
          projects: { __typename: 'ProjectConnection', nodes: projects },
        },
      },
    });

  const asNamespace = ({ id, name, fullName, fullPath, __typename }) => ({
    id,
    name,
    fullName,
    fullPath,
    type: __typename,
  });

  // The real listbox renders a header per group, then its list-item slot per option.
  const listboxStub = stubComponent(GlCollapsibleListbox, {
    template: `
      <div>
        <div v-for="section in items" :key="section.text">
          <div v-for="item in section.options" :key="item.value">
            <slot name="list-item" :item="item"></slot>
          </div>
        </div>
        <slot name="footer"></slot>
      </div>`,
    methods: { close: closeListbox },
  });

  const createWrapper = ({
    handler = respondWith(),
    subgroupHandler = respondWithSubgroupProjects(),
  } = {}) => {
    requestHandler = handler;
    subgroupRequestHandler = subgroupHandler;

    wrapper = shallowMountExtended(ScopePicker, {
      apolloProvider: createMockApollo([
        [getGroupChildrenQuery, requestHandler],
        [getSubgroupProjectsQuery, subgroupRequestHandler],
      ]),
      propsData: { groupFullPath },
      stubs: { GlCollapsibleListbox: listboxStub },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSections = () => findListbox().props('items');
  const findOptions = () => findSections().flatMap(({ options }) => options);
  const findDoneButton = () => wrapper.findComponent(GlButton);
  const findItems = () => wrapper.findAllComponents(ScopePickerItem);
  const findItemAt = (index) => findItems().at(index);
  const findEmptyItem = () => wrapper.findByTestId('scope-picker-empty-item');
  const findItemFor = ({ fullPath }) =>
    findItems().wrappers.find((item) => item.props('value') === fullPath);

  // Mirrors what the listbox emits on click: the whole selection, with the clicked item toggled.
  const toggleSelected = ({ fullPath }) => {
    const selected = findListbox().props('selected');
    const paths = selected.includes(fullPath)
      ? selected.filter((path) => path !== fullPath)
      : [...selected, fullPath];

    return findListbox().vm.$emit('select', paths);
  };
  const toggleExpanded = (namespace = mockGroup) =>
    findItemFor(namespace).vm.$emit('toggle-expanded');

  describe('while loading', () => {
    beforeEach(() => createWrapper());

    it('requests the group, its projects and its subgroups', () => {
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

    it('splits the listbox into a top-level group section and a subgroups section', () => {
      expect(findSections().map(({ text }) => text)).toEqual([
        'Projects in top-level group (GitLab.org)',
        'Subgroups incl. nested',
      ]);
    });

    it('lists the group above its projects, then its subgroups', () => {
      expect(findOptions().map(({ value, text }) => ({ value, text }))).toEqual([
        { value: mockGroup.fullPath, text: mockGroup.name },
        ...mockProjects.map(({ fullPath, name }) => ({ value: fullPath, text: name })),
        ...mockSubgroups.map(({ fullPath, name }) => ({ value: fullPath, text: name })),
      ]);
    });

    it('renders an item for each listbox entry', () => {
      expect(findItems().wrappers.map((item) => item.props('value'))).toEqual([
        mockGroup.fullPath,
        ...mockProjects.map(({ fullPath }) => fullPath),
        ...mockSubgroups.map(({ fullPath }) => fullPath),
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

    it('renders a subgroup with content as a collapsed parent', () => {
      expect(findItemFor(mockFrontend).props()).toMatchObject({
        text: mockFrontend.name,
        namespaceType: TYPENAME_GROUP,
        expandable: true,
        expanded: false,
        expanding: false,
        nested: false,
      });
    });

    it('does not offer to expand a subgroup with no projects and no subgroups', () => {
      expect(findItemFor(mockQuality).props('expandable')).toBe(false);
    });

    it('requests no subgroup projects until a subgroup is expanded', () => {
      expect(subgroupRequestHandler).not.toHaveBeenCalled();
    });
  });

  describe('when the group has no subgroups', () => {
    beforeEach(async () => {
      createWrapper({ handler: respondWith({ subgroups: [] }) });
      await waitForPromises();
    });

    it('drops the subgroups section', () => {
      expect(findSections().map(({ text }) => text)).toEqual([
        'Projects in top-level group (GitLab.org)',
      ]);
    });
  });

  describe('when the group has no projects', () => {
    beforeEach(async () => {
      createWrapper({ handler: respondWith({ projects: [], subgroups: [] }) });
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
      expect(findItems()).toHaveLength(mockSubgroups.length + 1);
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

      expect(findItems()).toHaveLength(mockProjects.length + mockSubgroups.length + 1);
    });
  });

  describe('when a subgroup is expanded', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
      await toggleExpanded(mockFrontend);
    });

    it('requests every project beneath it', () => {
      expect(subgroupRequestHandler).toHaveBeenCalledWith({ fullPath: mockFrontend.fullPath });
    });

    it('marks the subgroup as expanding while the request is in flight', () => {
      expect(findItemFor(mockFrontend).props('expanding')).toBe(true);
    });

    it('does not fire a second request while the first is in flight', async () => {
      await toggleExpanded(mockFrontend);
      await toggleExpanded(mockFrontend);

      expect(subgroupRequestHandler).toHaveBeenCalledTimes(1);
    });

    describe('once its projects load', () => {
      beforeEach(() => waitForPromises());

      it('stops marking the subgroup as expanding', () => {
        expect(findItemFor(mockFrontend).props()).toMatchObject({
          expanded: true,
          expanding: false,
        });
      });

      it('lists them beneath the subgroup, above the remaining subgroups', () => {
        expect(findItems().wrappers.map((item) => item.props('value'))).toEqual([
          mockGroup.fullPath,
          ...mockProjects.map(({ fullPath }) => fullPath),
          mockFrontend.fullPath,
          ...mockSubgroupProjects.map(({ fullPath }) => fullPath),
          mockQuality.fullPath,
        ]);
      });

      it('renders them flat, whatever their real depth', () => {
        expect(
          mockSubgroupProjects.map(({ fullPath }) => findItemFor({ fullPath }).props('nested')),
        ).toEqual([true, true]);
      });

      it('names the parent group only for projects nested below the subgroup', () => {
        expect(
          mockSubgroupProjects.map(({ fullPath }) => findItemFor({ fullPath }).props('parentName')),
        ).toEqual([null, mockTools.name]);
      });

      describe('and then collapsed', () => {
        beforeEach(() => toggleExpanded(mockFrontend));

        it('hides its projects', () => {
          expect(findItems()).toHaveLength(mockProjects.length + mockSubgroups.length + 1);
        });

        it('does not request them again when expanded a second time', async () => {
          await toggleExpanded(mockFrontend);

          expect(subgroupRequestHandler).toHaveBeenCalledTimes(1);
        });

        it('keeps the toggle text of a project selected while expanded', async () => {
          await toggleExpanded(mockFrontend);
          await toggleSelected(mockSubgroupProjects[0]);
          await toggleExpanded(mockFrontend);

          expect(findListbox().props('toggleText')).toBe(mockSubgroupProjects[0].name);
        });
      });

      describe('and one of its projects is selected', () => {
        beforeEach(() => toggleSelected(mockSubgroupProjects[1]));

        it('emits change with the selected namespace', () => {
          expect(wrapper.emitted('change')).toEqual([[asNamespace(mockSubgroupProjects[1])]]);
        });

        it('renders both the subgroup and the top-level group as indeterminate', () => {
          expect(findItemFor(mockFrontend).props('indeterminate')).toBe(true);
          expect(findItemAt(0).props('indeterminate')).toBe(true);
        });
      });

      describe('and the subgroup itself is selected', () => {
        beforeEach(() => toggleSelected(mockFrontend));

        it('emits change with the subgroup namespace', () => {
          expect(wrapper.emitted('change')).toEqual([[asNamespace(mockFrontend)]]);
        });

        it('checks and locks the projects it covers', () => {
          expect(
            mockSubgroupProjects.map(({ fullPath }) => findItemFor({ fullPath }).props()),
          ).toMatchObject([
            { selected: true, disabled: true },
            { selected: true, disabled: true },
          ]);
        });

        it('leaves the top-level group indeterminate', () => {
          expect(findItemAt(0).props('indeterminate')).toBe(true);
        });
      });
    });
  });

  describe('when an expanded subgroup turns out to have no projects', () => {
    beforeEach(async () => {
      createWrapper({ subgroupHandler: respondWithSubgroupProjects([]) });
      await waitForPromises();
      await toggleExpanded(mockFrontend);
      await waitForPromises();
    });

    it('renders a placeholder in place of its projects', () => {
      expect(findEmptyItem().text()).toBe('No projects');
    });

    it('renders no extra selectable item', () => {
      expect(findItems()).toHaveLength(mockProjects.length + mockSubgroups.length + 1);
    });

    it('marks the placeholder as unselectable', () => {
      expect(findOptions().find(({ placeholder }) => placeholder)).toMatchObject({
        disabled: true,
      });
    });
  });

  describe('when a subgroup is expanded while the top-level group is selected', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
      await toggleSelected(mockGroup);
      await toggleExpanded(mockFrontend);
      await waitForPromises();
    });

    it('still offers the chevron on the locked subgroup', () => {
      expect(findItemFor(mockFrontend).props()).toMatchObject({
        disabled: true,
        expandable: true,
        expanded: true,
      });
    });

    it('fetches and reveals its projects, so the scope can be inspected before committing', () => {
      expect(subgroupRequestHandler).toHaveBeenCalledWith({ fullPath: mockFrontend.fullPath });
      expect(findItems().wrappers.map((item) => item.props('value'))).toEqual([
        mockGroup.fullPath,
        ...mockProjects.map(({ fullPath }) => fullPath),
        mockFrontend.fullPath,
        ...mockSubgroupProjects.map(({ fullPath }) => fullPath),
        mockQuality.fullPath,
      ]);
    });

    it('shows the revealed projects as covered by the selection', () => {
      expect(
        mockSubgroupProjects.map(({ fullPath }) => findItemFor({ fullPath }).props()),
      ).toMatchObject([
        { selected: true, disabled: true },
        { selected: true, disabled: true },
      ]);
    });
  });

  describe('when a subgroup project has no readable namespace', () => {
    beforeEach(async () => {
      createWrapper({
        subgroupHandler: respondWithSubgroupProjects([
          { ...mockProject(9, 'Hidden parent', 'frontend/hidden'), namespace: null },
        ]),
      });
      await waitForPromises();
      await toggleExpanded(mockFrontend);
      await waitForPromises();
    });

    it('still renders the project, without naming a parent', () => {
      expect(findItemFor({ fullPath: `${groupFullPath}/frontend/hidden` }).props()).toMatchObject({
        text: 'Hidden parent',
        parentName: null,
      });
    });
  });

  describe('when the subgroup goes missing between the two requests', () => {
    beforeEach(async () => {
      createWrapper({
        subgroupHandler: jest.fn().mockResolvedValue({ data: { group: null } }),
      });
      await waitForPromises();
      await toggleExpanded(mockFrontend);
      await waitForPromises();
    });

    it('treats it as empty rather than throwing', () => {
      expect(findEmptyItem().text()).toBe('No projects');
    });

    it('emits no error, since the request itself succeeded', () => {
      expect(wrapper.emitted('error')).toBeUndefined();
    });
  });

  describe('when the subgroup projects request fails', () => {
    const error = new Error('oh no');

    beforeEach(async () => {
      createWrapper({ subgroupHandler: jest.fn().mockRejectedValue(error) });
      await waitForPromises();
      await toggleExpanded(mockFrontend);
      await waitForPromises();
    });

    it('emits error', () => {
      expect(wrapper.emitted('error')).toHaveLength(1);
    });

    it('logs the error to sentry', () => {
      expect(sentryBrowserWrapper.captureException).toHaveBeenCalled();
    });

    it('collapses the subgroup again', () => {
      expect(findItemFor(mockFrontend).props()).toMatchObject({
        expanded: false,
        expanding: false,
      });
    });

    it('retries the request when the subgroup is expanded again', async () => {
      await toggleExpanded(mockFrontend);

      expect(subgroupRequestHandler).toHaveBeenCalledTimes(2);
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
        false,
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
          false,
          false,
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

    it('checks everything it covers, including the subgroups', () => {
      expect(findItems().wrappers.map((item) => item.props('selected'))).toEqual([
        true,
        true,
        true,
        true,
        true,
      ]);
    });

    it('locks everything it covers', () => {
      expect(findItems().wrappers.map((item) => item.props('disabled'))).toEqual([
        false,
        true,
        true,
        true,
        true,
      ]);
      expect(findOptions().map(({ disabled }) => disabled)).toEqual([
        false,
        true,
        true,
        true,
        true,
      ]);
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
