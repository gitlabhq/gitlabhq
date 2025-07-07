import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import projectMilestonesQuery from '~/sidebar/queries/project_milestones.query.graphql';
import WorkItemBulkEditMilestone from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_milestone.vue';
import { projectMilestonesResponse } from 'ee_else_ce_jest/work_items/mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const listResults = [
  {
    expired: false,
    text: 'v4.0',
    value: 'gid://gitlab/Milestone/5',
  },
  {
    expired: false,
    text: 'v3.0',
    value: 'gid://gitlab/Milestone/4',
  },
];

describe('WorkItemBulkEditMilestone component', () => {
  let wrapper;

  const milestoneSearchQueryHandler = jest.fn().mockResolvedValue(projectMilestonesResponse);

  const createComponent = ({
    props = {},
    searchQueryHandler = milestoneSearchQueryHandler,
  } = {}) => {
    wrapper = mount(WorkItemBulkEditMilestone, {
      apolloProvider: createMockApollo([[projectMilestonesQuery, searchQueryHandler]]),
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

    expect(findFormGroup().attributes('label')).toBe('Milestone');
  });

  it('renders a header and reset button', () => {
    createComponent();

    expect(findListbox().props()).toMatchObject({
      headerText: 'Select milestone',
      resetButtonLabel: 'Reset',
    });
  });

  it('resets the selected milestone when the Reset button is clicked', async () => {
    createComponent();

    await openListboxAndSelect('gid://gitlab/Milestone/5');

    expect(findListbox().props('selected')).toBe('gid://gitlab/Milestone/5');

    findListbox().vm.$emit('reset');
    await nextTick();

    expect(findListbox().props('selected')).toEqual([]);
  });

  describe('milestones query', () => {
    it('is not called before dropdown is shown', () => {
      createComponent();

      expect(milestoneSearchQueryHandler).not.toHaveBeenCalled();
    });

    it('is called when dropdown is shown', async () => {
      createComponent();

      findListbox().vm.$emit('shown');
      await nextTick();

      expect(milestoneSearchQueryHandler).toHaveBeenCalled();
    });

    it('emits an error when there is an error in the call', async () => {
      createComponent({ searchQueryHandler: jest.fn().mockRejectedValue(new Error('error!')) });

      findListbox().vm.$emit('shown');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: new Error('error!'),
        message: 'Failed to load milestones. Please try again.',
      });
    });
  });

  describe('listbox items', () => {
    it('renders all milestones', async () => {
      createComponent();

      findListbox().vm.$emit('shown');
      await waitForPromises();

      expect(findListbox().props('items')).toEqual(listResults);
    });

    describe('with search', () => {
      it('displays search results', async () => {
        createComponent();

        findListbox().vm.$emit('shown');
        findListbox().vm.$emit('search', 'search query');
        await waitForPromises();

        expect(findListbox().props('items')).toEqual(listResults);
        expect(milestoneSearchQueryHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            title: 'search query',
          }),
        );
      });
    });
  });

  describe('listbox text', () => {
    describe('with no selected milestone', () => {
      it('renders "Select milestone"', () => {
        createComponent();

        expect(findListbox().props('toggleText')).toBe('Select milestone');
      });
    });

    describe('with selected milestone', () => {
      it('renders the milestone title', async () => {
        createComponent();

        await openListboxAndSelect('gid://gitlab/Milestone/5');

        expect(findListbox().props('toggleText')).toBe('v4.0');
      });
    });
  });
});
