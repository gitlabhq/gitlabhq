import { GlCollapsibleListbox, GlDisclosureDropdown } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { TYPE_EPIC, TYPE_ISSUE, TYPE_MERGE_REQUEST, TYPE_TEST_CASE } from '~/issues/constants';
import DropdownContentsCreateView from '~/sidebar/components/labels/labels_select_widget/dropdown_contents_create_view.vue';
import EditToggleButton from '~/sidebar/components/labels/labels_select_widget/edit_toggle_button.vue';
import DropdownValue from '~/sidebar/components/labels/labels_select_widget/dropdown_value.vue';
import EmbeddedLabelsList from '~/sidebar/components/labels/labels_select_widget/embedded_labels_list.vue';
import DropdownContents from '~/sidebar/components/labels/labels_select_widget/dropdown_contents.vue';
import issueLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/issue_labels.query.graphql';
import projectLabelsQuery from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
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
  workspaceLabelsQueryResponse,
  mockLabels,
  mockRegularLabel,
} from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

// Stub that renders toggle and footer slots so their buttons are accessible in tests.
const GlCollapsibleListboxStub = stubComponent(GlCollapsibleListbox, {
  template: `
    <div>
      <slot name="toggle" :accessibility-attributes="{}" />
      <slot name="footer" />
    </div>
  `,
});

// Stub that renders toggle and default slots so buttons inside are accessible in tests.
const GlDisclosureDropdownStub = stubComponent(GlDisclosureDropdown, {
  template: `<div><slot name="toggle" :toggle-props="{}" /><slot /></div>`,
});

const successfulQueryHandler = jest.fn().mockResolvedValue(issuableLabelsQueryResponse);
const successfulLabelsQueryHandler = jest.fn().mockResolvedValue(workspaceLabelsQueryResponse);
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

  const findListbox = () => wrapper.findComponent(GlCollapsibleListboxStub);
  const findCreateFormDropdown = () => wrapper.findComponent(GlDisclosureDropdownStub);
  const findEditButton = () => wrapper.findComponent(EditToggleButton);
  const findDropdownValue = () => wrapper.findComponent(DropdownValue);
  const findEmbeddedLabelsList = () => wrapper.findComponent(EmbeddedLabelsList);
  const findDropdownContents = () => wrapper.findComponent(DropdownContents);
  const findCreateView = () => wrapper.findComponent(DropdownContentsCreateView);
  const findCreateLabelButton = () => wrapper.findByTestId('create-label');

  const createComponent = ({
    config = mockConfig,
    slots = {},
    issuableType = TYPE_ISSUE,
    queryHandler = successfulQueryHandler,
    labelsQueryHandler = successfulLabelsQueryHandler,
    mutationHandler = successfulMutationHandler,
  } = {}) => {
    const mockApollo = createMockApollo([
      [issueLabelsQuery, queryHandler],
      [projectLabelsQuery, labelsQueryHandler],
      [updateLabelsMutation[issuableType], mutationHandler],
      [issuableLabelsSubscription, subscriptionHandler],
    ]);

    wrapper = shallowMountExtended(LabelsSelectRoot, {
      slots,
      apolloProvider: mockApollo,
      propsData: {
        ...config,
        issuableType,
        labelCreateType: 'project',
        workspaceType: 'project',
      },
      stubs: {
        GlCollapsibleListbox: GlCollapsibleListboxStub,
        GlDisclosureDropdown: GlDisclosureDropdownStub,
      },
      provide: {
        canUpdate: true,
        allowLabelEdit: true,
        allowLabelCreate: true,
        allowScopedLabels: false,
        labelsManagePath: 'test/manage',
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
    it('renders the listbox and the edit toggle button', () => {
      createComponent();
      expect(findListbox().exists()).toBe(true);
      expect(findEditButton().exists()).toBe(true);
    });

    describe('when labels are fetched successfully', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('renders dropdown value component with the fetched labels', () => {
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

    describe('listbox interaction', () => {
      it('reflects the toggled selection on the listbox', async () => {
        createComponent();
        const ids = ['gid://gitlab/ProjectLabel/1', 'gid://gitlab/ProjectLabel/2'];
        findListbox().vm.$emit('select', ids);
        await nextTick();
        expect(findListbox().props('selected')).toEqual(ids);
      });

      it('does not submit a mutation when the listbox closes with no changes', async () => {
        createComponent();
        await waitForPromises();
        findListbox().vm.$emit('hidden');
        await waitForPromises();
        expect(successfulMutationHandler).not.toHaveBeenCalled();
      });

      it('submits a mutation when the listbox closes with changed selection', async () => {
        createComponent();
        await waitForPromises();
        findListbox().vm.$emit('select', ['gid://gitlab/ProjectLabel/2']);
        findListbox().vm.$emit('hidden');
        await waitForPromises();
        expect(successfulMutationHandler).toHaveBeenCalled();
      });

      it('clears the search when a selection is made', async () => {
        createComponent();
        findListbox().vm.$emit('shown');
        await waitForPromises();

        findListbox().vm.$emit('search', 'Label');
        await nextTick();
        // While searching, the listbox shows the flat search results (not the grouped list)
        expect(findListbox().props('items')).not.toContainEqual(
          expect.objectContaining({ text: 'Selected' }),
        );

        findListbox().vm.$emit('select', ['gid://gitlab/ProjectLabel/1']);
        await nextTick();
        // After selecting, the search is cleared and the grouped Selected/All list returns
        expect(findListbox().props('items')[0]).toMatchObject({ text: 'Selected' });
      });
    });

    describe('create label form', () => {
      const openCreateForm = async () => {
        findCreateLabelButton().vm.$emit('click', new Event('click'));
        await nextTick();
      };

      it('shows the create form dropdown and hides the listbox when the create button is clicked', async () => {
        createComponent();
        expect(findCreateFormDropdown().exists()).toBe(false);
        expect(findCreateView().exists()).toBe(false);
        await openCreateForm();
        expect(findListbox().exists()).toBe(false);
        expect(findCreateFormDropdown().exists()).toBe(true);
        expect(findCreateView().exists()).toBe(true);
      });

      it('restores the listbox when hideCreateView is emitted', async () => {
        createComponent();
        await openCreateForm();
        findCreateView().vm.$emit('hideCreateView');
        await nextTick();
        expect(findCreateFormDropdown().exists()).toBe(false);
        expect(findListbox().exists()).toBe(true);
      });

      it('restores the listbox when the disclosure dropdown is dismissed', async () => {
        createComponent();
        await openCreateForm();
        findCreateFormDropdown().vm.$emit('hidden');
        await nextTick();
        expect(findCreateFormDropdown().exists()).toBe(false);
        expect(findListbox().exists()).toBe(true);
      });

      it('auto-selects the created label and hides the form', async () => {
        createComponent();
        await openCreateForm();
        const newLabel = { id: 'gid://gitlab/ProjectLabel/99', title: 'New', color: '#FF0000' };
        findCreateView().vm.$emit('labelCreated', newLabel);
        await nextTick();
        expect(findCreateFormDropdown().exists()).toBe(false);
        expect(findListbox().props('selected')).toContain(newLabel.id);
      });
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

  it('emits `updateSelectedLabels` when the listbox closes with a selection and iid is not set', async () => {
    createComponent({ config: { ...mockConfig, iid: undefined } });

    const id = 'gid://gitlab/ProjectLabel/1';
    findListbox().vm.$emit('select', [id]);
    findListbox().vm.$emit('hidden');
    await nextTick();

    expect(wrapper.emitted('updateSelectedLabels')).toEqual([[{ labels: [{ id }] }]]);
  });

  describe.each`
    issuableType
    ${TYPE_ISSUE}
    ${TYPE_MERGE_REQUEST}
    ${TYPE_EPIC}
    ${TYPE_TEST_CASE}
  `('when updating labels for $issuableType', ({ issuableType }) => {
    const labelId = 'gid://gitlab/ProjectLabel/2';

    it('sets the loading state on the edit button while mutation is in progress', async () => {
      createComponent({ issuableType });
      await nextTick();
      findListbox().vm.$emit('select', [labelId]);
      findListbox().vm.$emit('hidden');
      await nextTick();

      expect(findEditButton().props('loading')).toBe(true);
    });

    it('updates labels correctly after successful mutation', async () => {
      createComponent({ issuableType });
      await nextTick();
      findListbox().vm.$emit('select', [labelId]);
      findListbox().vm.$emit('hidden');
      await waitForPromises();

      expect(findDropdownValue().props('selectedLabels')).toEqual(
        updateLabelsMutationResponse.data.updateIssuableLabels.issuable.labels.nodes,
      );
    });

    it('displays an error if the mutation was rejected', async () => {
      createComponent({ issuableType, mutationHandler: errorQueryHandler });
      await nextTick();
      findListbox().vm.$emit('select', [labelId]);
      findListbox().vm.$emit('hidden');
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
