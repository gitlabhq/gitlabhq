import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import groupWorkItemsQuery from '~/work_items/graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import workItemsByReferencesQuery from '~/work_items/graphql/work_items_by_references.query.graphql';
import WorkItemBulkEditParent from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_parent.vue';
import { BULK_EDIT_NO_VALUE } from '~/work_items/constants';
import {
  availableObjectivesResponse,
  mockWorkItemReferenceQueryResponse,
  groupEpicsWithMilestonesQueryResponse,
} from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const listResults = [
  {
    text: 'Objective 101',
    value: 'gid://gitlab/WorkItem/716',
  },
  {
    text: 'Objective 103',
    value: 'gid://gitlab/WorkItem/712',
  },
  {
    text: 'Objective 102',
    value: 'gid://gitlab/WorkItem/711',
  },
];

describe('WorkItemBulkEditParent component', () => {
  let wrapper;

  const groupWorkItemsHandler = jest.fn().mockResolvedValue(groupEpicsWithMilestonesQueryResponse);
  const projectWorkItemsHandler = jest.fn().mockResolvedValue(availableObjectivesResponse);
  const workItemsByReferenceHandler = jest
    .fn()
    .mockResolvedValue(mockWorkItemReferenceQueryResponse);

  const createComponent = ({
    props = {},
    projectHandler = projectWorkItemsHandler,
    groupHandler = groupWorkItemsHandler,
    searchHandler = workItemsByReferenceHandler,
  } = {}) => {
    wrapper = mount(WorkItemBulkEditParent, {
      apolloProvider: createMockApollo([
        [groupWorkItemsQuery, groupHandler],
        [projectWorkItemsQuery, projectHandler],
        [workItemsByReferencesQuery, searchHandler],
      ]),
      propsData: {
        fullPath: 'group/project',
        isGroup: false,
        ...props,
      },
      stubs: {
        GlCollapsibleListbox,
        GlFormGroup: true,
      },
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const openListboxAndSelect = async (value) => {
    findListbox().vm.$emit('shown');
    findListbox().vm.$emit('select', value);
    await waitForPromises();
  };

  it('renders the form group', () => {
    createComponent();

    expect(findFormGroup().attributes('label')).toBe('Parent');
  });

  it('renders a header and reset button', () => {
    createComponent();

    expect(findListbox().props()).toMatchObject({
      headerText: 'Select parent',
      resetButtonLabel: 'Reset',
    });
  });

  it('resets the selected parent when the Reset button is clicked', async () => {
    createComponent();

    await openListboxAndSelect('gid://gitlab/WorkItem/5');

    expect(findListbox().props('selected')).toBe('gid://gitlab/WorkItem/5');

    findListbox().vm.$emit('reset');
    await nextTick();

    expect(findListbox().props('selected')).toEqual([]);
  });

  describe('work items query', () => {
    describe('when project', () => {
      it('is not called before dropdown is shown', () => {
        createComponent();

        expect(projectWorkItemsHandler).not.toHaveBeenCalled();
      });

      it('is called when dropdown is shown', async () => {
        createComponent();

        findListbox().vm.$emit('shown');
        await nextTick();

        expect(projectWorkItemsHandler).toHaveBeenCalled();
      });

      it('emits an error when there is an error in the call', async () => {
        createComponent({ projectHandler: jest.fn().mockRejectedValue(new Error('error!')) });

        findListbox().vm.$emit('shown');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          error: new Error('error!'),
          message: 'Failed to load work items. Please try again.',
        });
      });
    });

    describe('when group', () => {
      it('is not called before dropdown is shown', () => {
        createComponent({ props: { isGroup: true } });

        expect(groupWorkItemsHandler).not.toHaveBeenCalled();
      });

      it('is called when dropdown is shown', async () => {
        createComponent({ props: { isGroup: true } });

        findListbox().vm.$emit('shown');
        await nextTick();

        expect(groupWorkItemsHandler).toHaveBeenCalled();
      });

      it('emits an error when there is an error in the call', async () => {
        createComponent({
          props: { isGroup: true },
          groupHandler: jest.fn().mockRejectedValue(new Error('error!')),
        });

        findListbox().vm.$emit('shown');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          error: new Error('error!'),
          message: 'Failed to load work items. Please try again.',
        });
      });
    });
  });

  describe('listbox items', () => {
    it('renders all work items and "No parent" by default', async () => {
      createComponent();

      findListbox().vm.$emit('shown');
      await waitForPromises();

      expect(findListbox().props('items')).toEqual([
        {
          text: 'No parent',
          textSrOnly: true,
          options: [{ text: 'No parent', value: BULK_EDIT_NO_VALUE }],
        },
        {
          text: 'All',
          textSrOnly: true,
          options: listResults,
        },
      ]);
    });

    describe('with search', () => {
      it('displays search results', async () => {
        createComponent();

        findListbox().vm.$emit('shown');
        findListbox().vm.$emit('search', 'search query');
        await waitForPromises();

        expect(findListbox().props('items')).toEqual(listResults);
        expect(projectWorkItemsHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            searchByIid: false,
            searchByText: true,
            searchTerm: 'search query',
          }),
        );
      });

      describe('when searching by reference', () => {
        it('handles URL searches with workItemsByReference query', async () => {
          const searchUrl = 'http://localhost/gitlab-org/test-project-path/-/work_items/111';
          createComponent();

          findListbox().vm.$emit('shown');
          findListbox().vm.$emit('search', searchUrl);
          await waitForPromises();

          expect(findListbox().props('items')).toEqual([
            {
              text: 'Objective _linked_ items 104',
              value: 'gid://gitlab/WorkItem/705',
            },
          ]);
          expect(workItemsByReferenceHandler).toHaveBeenCalledWith(
            expect.objectContaining({
              refs: [searchUrl],
            }),
          );
        });

        it('handles reference searches with workItemsByReference query', async () => {
          const searchReference = 'gitlab-org/test-project-path#111';
          createComponent();

          findListbox().vm.$emit('shown');
          findListbox().vm.$emit('search', searchReference);
          await waitForPromises();

          expect(findListbox().props('items')).toEqual([
            {
              text: 'Objective _linked_ items 104',
              value: 'gid://gitlab/WorkItem/705',
            },
          ]);
          expect(workItemsByReferenceHandler).toHaveBeenCalledWith(
            expect.objectContaining({
              refs: [searchReference],
            }),
          );
        });
      });
    });
  });

  describe('listbox text', () => {
    describe('with no selected parent', () => {
      it('renders "Select parent"', () => {
        createComponent();

        expect(findListbox().props('toggleText')).toBe('Select parent');
      });
    });

    describe('with selected milestone', () => {
      it('renders the milestone title', async () => {
        createComponent();

        await openListboxAndSelect('gid://gitlab/WorkItem/711');

        expect(findListbox().props('toggleText')).toBe('Objective 102');
      });
    });

    describe('with "No parent"', () => {
      it('renders "No parent"', async () => {
        createComponent();

        await openListboxAndSelect(BULK_EDIT_NO_VALUE);

        expect(findListbox().props('toggleText')).toBe('No parent');
      });
    });
  });
});
