import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { TYPE_EPIC, TYPE_ISSUE, TYPE_MERGE_REQUEST, TYPE_TEST_CASE } from '~/issues/constants';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import DropdownContents from '~/sidebar/components/labels/labels_select_widget/dropdown_contents.vue';
import DropdownValue from '~/sidebar/components/labels/labels_select_widget/dropdown_value.vue';
import EmbeddedLabelsList from '~/sidebar/components/labels/labels_select_widget/embedded_labels_list.vue';
import issueLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/issue_labels.query.graphql';
import updateIssueLabelsMutation from '~/boards/graphql/issue_set_labels.mutation.graphql';
import updateMergeRequestLabelsMutation from '~/sidebar/queries/update_merge_request_labels.mutation.graphql';
import issuableLabelsSubscription from 'ee_else_ce/sidebar/queries/issuable_labels.subscription.graphql';
import updateEpicLabelsMutation from '~/sidebar/components/labels/labels_select_widget/graphql/epic_update_labels.mutation.graphql';
import updateTestCaseLabelsMutation from '~/sidebar/components/labels/labels_select_widget/graphql/update_test_case_labels.mutation.graphql';
import LabelsSelectRoot from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import {
  mockConfig,
  issuableLabelsQueryResponse,
  updateLabelsMutationResponse,
  issuableLabelsSubscriptionResponse,
  mockLabels,
  mockRegularLabel,
} from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const successfulQueryHandler = jest.fn().mockResolvedValue(issuableLabelsQueryResponse);
const successfulMutationHandler = jest.fn().mockResolvedValue(updateLabelsMutationResponse);
const subscriptionHandler = jest.fn().mockResolvedValue(issuableLabelsSubscriptionResponse);
const errorQueryHandler = jest.fn().mockRejectedValue('Houston, we have a problem');

const updateLabelsMutation = {
  [TYPE_ISSUE]: updateIssueLabelsMutation,
  [TYPE_MERGE_REQUEST]: updateMergeRequestLabelsMutation,
  [TYPE_EPIC]: updateEpicLabelsMutation,
  [TYPE_TEST_CASE]: updateTestCaseLabelsMutation,
};

describe('LabelsSelectRoot', () => {
  let wrapper;

  const findSidebarEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findDropdownValue = () => wrapper.findComponent(DropdownValue);
  const findDropdownContents = () => wrapper.findComponent(DropdownContents);
  const findEmbeddedLabelsList = () => wrapper.findComponent(EmbeddedLabelsList);

  const createComponent = ({
    config = mockConfig,
    slots = {},
    issuableType = TYPE_ISSUE,
    queryHandler = successfulQueryHandler,
    mutationHandler = successfulMutationHandler,
  } = {}) => {
    const mockApollo = createMockApollo([
      [issueLabelsQuery, queryHandler],
      [updateLabelsMutation[issuableType], mutationHandler],
      [issuableLabelsSubscription, subscriptionHandler],
    ]);

    wrapper = shallowMount(LabelsSelectRoot, {
      slots,
      apolloProvider: mockApollo,
      propsData: {
        ...config,
        issuableType,
        labelCreateType: 'project',
        workspaceType: 'project',
      },
      stubs: {
        SidebarEditableItem,
      },
      provide: {
        canUpdate: true,
        allowLabelEdit: true,
        allowLabelCreate: true,
        labelsManagePath: 'test',
      },
    });
  };

  it('renders component with classes `labels-select-wrapper gl-relative`', () => {
    createComponent();
    expect(wrapper.classes()).toEqual(['labels-select-wrapper', 'gl-relative']);
  });

  it.each`
    variant         | cssClass
    ${'standalone'} | ${'is-standalone'}
    ${'embedded'}   | ${'is-embedded'}
  `(
    'renders component root element with CSS class `$cssClass` when `state.variant` is "$variant"',
    async ({ variant, cssClass }) => {
      createComponent({
        config: { ...mockConfig, variant },
      });

      await nextTick();
      expect(wrapper.classes()).toContain(cssClass);
    },
  );

  describe('if dropdown variant is `sidebar`', () => {
    it('renders sidebar editable item', () => {
      createComponent();
      expect(findSidebarEditableItem().exists()).toBe(true);
    });

    it('passes true `loading` prop to sidebar editable item when loading labels', () => {
      createComponent();
      expect(findSidebarEditableItem().props('loading')).toBe(true);
    });

    describe('when labels are fetched successfully', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('passes true `loading` prop to sidebar editable item', () => {
        expect(findSidebarEditableItem().props('loading')).toBe(false);
      });

      it('renders dropdown value component when query labels is resolved', () => {
        expect(findDropdownValue().exists()).toBe(true);
        expect(findDropdownValue().props('selectedLabels')).toEqual([
          {
            __typename: 'Label',
            color: '#330066',
            description: null,
            id: 'gid://gitlab/ProjectLabel/1',
            title: 'Label1',
            textColor: '#000000',
          },
        ]);
      });

      it('emits `onLabelRemove` event on dropdown value label remove event', () => {
        const label = { id: 'gid://gitlab/ProjectLabel/1' };
        findDropdownValue().vm.$emit('onLabelRemove', label);
        expect(wrapper.emitted('onLabelRemove')).toEqual([[label]]);
      });
    });

    it('creates alert with error message when query is rejected', async () => {
      createComponent({ queryHandler: errorQueryHandler });
      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({ message: 'Error fetching labels.' });
    });
  });

  describe('if dropdown variant is `embedded`', () => {
    it('shows the embedded labels list', () => {
      createComponent({
        config: { ...mockConfig, iid: '', variant: 'embedded', showEmbeddedLabelsList: true },
      });

      expect(findEmbeddedLabelsList().props()).toMatchObject({
        disabled: false,
        selectedLabels: [],
        allowLabelRemove: false,
        labelsFilterBasePath: mockConfig.labelsFilterBasePath,
        labelsFilterParam: mockConfig.labelsFilterParam,
      });
    });

    it('passes the selected labels if provided', () => {
      createComponent({
        config: {
          ...mockConfig,
          iid: '',
          variant: 'embedded',
          showEmbeddedLabelsList: true,
          selectedLabels: mockLabels,
        },
      });

      expect(findEmbeddedLabelsList().props('selectedLabels')).toStrictEqual(mockLabels);
      expect(findDropdownContents().props('selectedLabels')).toStrictEqual(mockLabels);
    });

    it('emits the `onLabelRemove` when the embedded list triggers a removal', () => {
      createComponent({
        config: {
          ...mockConfig,
          iid: '',
          variant: 'embedded',
          showEmbeddedLabelsList: true,
          selectedLabels: [mockRegularLabel],
        },
      });

      findEmbeddedLabelsList().vm.$emit('onLabelRemove', [mockRegularLabel.id]);
      expect(wrapper.emitted('onLabelRemove')).toStrictEqual([[[mockRegularLabel.id]]]);
    });
  });

  it('emits `updateSelectedLabels` event on dropdown contents `setLabels` event if iid is not set', () => {
    const label = { id: 'gid://gitlab/ProjectLabel/1' };
    createComponent({ config: { ...mockConfig, iid: undefined } });

    findDropdownContents().vm.$emit('setLabels', [label]);
    expect(wrapper.emitted('updateSelectedLabels')).toEqual([[{ labels: [label] }]]);
  });

  describe.each`
    issuableType
    ${TYPE_ISSUE}
    ${TYPE_MERGE_REQUEST}
    ${TYPE_EPIC}
    ${TYPE_TEST_CASE}
  `('when updating labels for $issuableType', ({ issuableType }) => {
    const label = { id: 'gid://gitlab/ProjectLabel/2' };

    it('sets the loading state', async () => {
      createComponent({ issuableType });
      await nextTick();
      findDropdownContents().vm.$emit('setLabels', [label]);
      await nextTick();

      expect(findSidebarEditableItem().props('loading')).toBe(true);
    });

    it('updates labels correctly after successful mutation', async () => {
      createComponent({ issuableType });

      await nextTick();
      findDropdownContents().vm.$emit('setLabels', [label]);
      await waitForPromises();

      expect(findDropdownValue().props('selectedLabels')).toEqual(
        updateLabelsMutationResponse.data.updateIssuableLabels.issuable.labels.nodes,
      );
    });

    it('displays an error if mutation was rejected', async () => {
      createComponent({ issuableType, mutationHandler: errorQueryHandler });
      await nextTick();
      findDropdownContents().vm.$emit('setLabels', [label]);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.anything(),
        message: 'An error occurred while updating labels.',
      });
    });

    it('emits `updateSelectedLabels` event when the subscription is triggered', async () => {
      createComponent();
      await waitForPromises();

      expect(wrapper.emitted('updateSelectedLabels')).toEqual([
        [
          {
            id: '1',
            labels: issuableLabelsSubscriptionResponse.data.issuableLabelsUpdated.labels.nodes,
          },
        ],
      ]);
    });
  });
});
