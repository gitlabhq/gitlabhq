import { GlButton, GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { cloneDeep } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { projectLabelsResponse } from 'jest/work_items/mock_data';
import { createAlert } from '~/alert';
import projectLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import WorkItemBulkEditLabels from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_labels.vue';
import { WIDGET_TYPE_LABELS } from '~/work_items/constants';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('WorkItemBulkEditLabels component', () => {
  let wrapper;

  const labelsManagePath = '/labels/manage/path';

  const labels = cloneDeep(projectLabelsResponse);
  labels.data.workspace.labels.nodes.push({
    __typename: 'Label',
    id: 'gid://gitlab/Label/4',
    title: 'Label 4',
    description: 'Label 4 description',
    color: '#fff',
    textColor: '#000',
  });
  const projectLabelsQueryHandler = jest.fn().mockResolvedValue(labels);

  const createComponent = ({ props = {}, searchQueryHandler = projectLabelsQueryHandler } = {}) => {
    wrapper = shallowMount(WorkItemBulkEditLabels, {
      apolloProvider: createMockApollo([[projectLabelsQuery, searchQueryHandler]]),
      propsData: {
        formLabel: 'Labels',
        formLabelId: 'labels-id',
        fullPath: 'group/project',
        ...props,
      },
      provide: {
        labelsManagePath,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findManageLabelsButton = () => wrapper.findComponent(GlButton);

  it('renders the form group', () => {
    createComponent();

    expect(findFormGroup().attributes('label')).toBe('Labels');
  });

  it('renders a header and reset button', () => {
    createComponent();

    expect(findListbox().props()).toMatchObject({
      headerText: 'Select labels',
      resetButtonLabel: 'Reset',
    });
  });

  it('renders the manage labels button with correct text for project', () => {
    createComponent();

    expect(findManageLabelsButton().text()).toBe('Manage project labels');
    expect(findManageLabelsButton().attributes('href')).toBe(labelsManagePath);
  });

  it('resets the selected labels when the Reset button is clicked', async () => {
    createComponent();

    findListbox().vm.$emit('select', ['gid://gitlab/Label/2']);
    findListbox().vm.$emit('shown');
    await waitForPromises();

    expect(findListbox().props('selected')).toEqual(['gid://gitlab/Label/2']);

    findListbox().vm.$emit('reset');
    await nextTick();

    expect(findListbox().props('selected')).toEqual([]);
  });

  describe('search labels query', () => {
    it('is not called before dropdown is shown', () => {
      createComponent();

      expect(projectLabelsQueryHandler).not.toHaveBeenCalled();
    });

    it('is called when dropdown is shown', async () => {
      createComponent();

      findListbox().vm.$emit('shown');
      await nextTick();

      expect(projectLabelsQueryHandler).toHaveBeenCalled();
    });

    it('emits an error when there is an error in the call', async () => {
      createComponent({ searchQueryHandler: jest.fn().mockRejectedValue(new Error('error!')) });

      findListbox().vm.$emit('shown');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: new Error('error!'),
        message: 'Something went wrong when fetching labels. Please try again.',
      });
    });
  });

  describe('listbox items', () => {
    describe('with no selected labels', () => {
      it('renders all labels', async () => {
        createComponent();

        findListbox().vm.$emit('shown');
        await waitForPromises();

        expect(findListbox().props('items')).toEqual([
          expect.objectContaining({ text: 'Label 1' }),
          expect.objectContaining({ text: 'Label::2' }),
          expect.objectContaining({ text: 'Label 3' }),
          expect.objectContaining({ text: 'Label 4' }),
        ]);
      });
    });

    describe('with selected labels', () => {
      it('renders a "Selected" group and an "All" group', async () => {
        createComponent();

        findListbox().vm.$emit('select', ['gid://gitlab/Label/2']);
        findListbox().vm.$emit('shown');
        await waitForPromises();

        expect(findListbox().props('items')).toEqual([
          {
            text: 'Selected',
            options: [expect.objectContaining({ text: 'Label::2' })],
          },
          {
            text: 'All',
            textSrOnly: true,
            options: [
              expect.objectContaining({ text: 'Label 1' }),
              expect.objectContaining({ text: 'Label::2' }),
              expect.objectContaining({ text: 'Label 3' }),
              expect.objectContaining({ text: 'Label 4' }),
            ],
          },
        ]);
      });
    });

    describe('with checked items', () => {
      it('only renders labels from the checked items', async () => {
        const checkedItems = [
          {
            widgets: [
              {
                type: WIDGET_TYPE_LABELS,
                labels: { nodes: [{ id: 'gid://gitlab/Label/1', title: 'Label 1' }] },
              },
            ],
          },
          {
            widgets: [
              {
                type: WIDGET_TYPE_LABELS,
                labels: {
                  nodes: [
                    { id: 'gid://gitlab/Label/1', title: 'Label 1' },
                    { id: 'gid://gitlab/Label/3', title: 'Label 3' },
                  ],
                },
              },
            ],
          },
        ];
        createComponent({ props: { checkedItems } });

        findListbox().vm.$emit('shown');
        await waitForPromises();

        expect(findListbox().props('items')).toEqual([
          expect.objectContaining({ text: 'Label 1' }),
          expect.objectContaining({ text: 'Label 3' }),
        ]);
      });
    });
  });

  describe('listbox text', () => {
    describe('with no selected labels', () => {
      it('renders "Select labels"', () => {
        createComponent();

        expect(findListbox().props('toggleText')).toBe('Select labels');
      });
    });

    describe('with fewer than 3 selected labels', () => {
      it('renders all label titles', async () => {
        createComponent({
          props: { selectedLabelsIds: ['gid://gitlab/Label/2', 'gid://gitlab/Label/3'] },
        });

        findListbox().vm.$emit('shown');
        await waitForPromises();

        expect(findListbox().props('toggleText')).toBe('Label::2 and Label 3');
      });
    });

    describe('with more than 2 selected labels', () => {
      it('renders first label title followed by the count', async () => {
        createComponent({
          props: {
            selectedLabelsIds: [
              'gid://gitlab/Label/1',
              'gid://gitlab/Label/2',
              'gid://gitlab/Label/3',
              'gid://gitlab/Label/4',
            ],
          },
        });

        findListbox().vm.$emit('shown');
        await waitForPromises();

        expect(findListbox().props('toggleText')).toBe('Label 1 +3 more');
      });
    });
  });
});
