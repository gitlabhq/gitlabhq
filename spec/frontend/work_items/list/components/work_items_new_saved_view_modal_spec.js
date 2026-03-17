import { nextTick } from 'vue';
import {
  GlForm,
  GlModal,
  GlAlert,
  GlFormRadio,
  GlIcon,
  GlLink,
  GlFormCharacterCount,
  GlFormGroup,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { saveSavedView } from 'ee_else_ce/work_items/list/utils';
import WorkItemsNewSavedViewModal from '~/work_items/list/components/work_items_new_saved_view_modal.vue';
import { CREATED_DESC, UPDATED_DESC } from '~/work_items/list/constants';
import { SAVED_VIEW_VISIBILITY } from '~/work_items/constants';
import { helpPagePath } from '~/helpers/help_page_helper';

jest.mock('ee_else_ce/work_items/list/utils', () => ({
  saveSavedView: jest.fn(),
}));

describe('WorkItemsNewSavedViewModal', () => {
  let wrapper;

  const successCreateResponse = {
    data: {
      workItemSavedViewCreate: {
        errors: [],
        savedView: {
          id: 'gid://gitlab/SavedView/1',
          name: 'Test View',
          description: 'Test Description',
          isPrivate: true,
          subscribed: true,
          filters: {},
          displaySettings: {},
          sort: CREATED_DESC,
          userPermissions: {
            updateSavedView: true,
            deleteSavedView: true,
            updateSavedViewVisibility: true,
            __typename: 'SavedViewPermissions',
          },
        },
      },
    },
  };

  const successUpdateResponse = {
    data: {
      workItemSavedViewUpdate: {
        errors: [],
        savedView: {
          id: 'gid://gitlab/WorkItems::SavedView/123',
          name: 'Updated View',
          description: 'Updated Description',
          isPrivate: true,
          subscribed: true,
          filters: {},
          displaySettings: {},
          sort: CREATED_DESC,
          userPermissions: {
            updateSavedView: true,
            deleteSavedView: true,
            updateSavedViewVisibility: true,
            __typename: 'SavedViewPermissions',
          },
        },
      },
    },
  };

  const existingSavedView = {
    id: 'gid://gitlab/WorkItems::SavedView/123',
    name: 'Existing View',
    description: 'Existing Description',
    isPrivate: false,
    subscribed: true,
    filters: {},
    displaySettings: {},
    sort: CREATED_DESC,
    userPermissions: {
      updateSavedView: true,
      deleteSavedView: true,
      updateSavedViewVisibility: true,
      __typename: 'SavedViewPermissions',
    },
  };

  const sharedSavedView = {
    ...existingSavedView,
    userPermissions: {
      ...existingSavedView.userPermissions,
      updateSavedViewVisibility: false,
      __typename: 'SavedViewPermissions',
    },
  };

  const mockToastShow = jest.fn();

  const createComponent = ({ props, mockSavedView = null, isGroup = false } = {}) => {
    wrapper = shallowMountExtended(WorkItemsNewSavedViewModal, {
      propsData: {
        show: true,
        fullPath: 'test-project-path',
        sortKey: CREATED_DESC,
        savedView: mockSavedView,
        filters: {},
        displaySettings: {},
        ...props,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
        $router: {
          push: jest.fn(),
        },
      },
      stubs: {
        GlFormRadio: stubComponent(GlFormRadio, {
          template: `<div>
                       <div class="help"><slot name="help"></slot></div>
                     </div>`,
        }),
        GlFormCharacterCount,
        GlFormGroup,
      },
      provide: {
        subscribedSavedViewLimit: 5,
        isGroup,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(GlForm);
  const findTitleInput = () => wrapper.find('#saved-view-title');
  const findTitleFormGroup = () => wrapper.findByTestId('saved-view-title');
  const findDescriptionInput = () => wrapper.find('#saved-view-description');
  const findDescriptionFormGroup = () => wrapper.findByTestId('saved-view-description');
  const findVisibilityInputs = () => wrapper.findByTestId('saved-view-visibility');
  const findReadOnlyVisibility = () => wrapper.findByText('Shared');
  const findCreateButton = () => wrapper.findByTestId('create-view-button');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findVisibilityGlRadioButtons = () => findVisibilityInputs().findAllComponents(GlFormRadio);
  const findWarningMessage = () => wrapper.findByTestId('subscription-limit-warning');
  const findWarningIcon = () => findWarningMessage().findComponent(GlIcon);
  const findLearnMoreLink = () => findWarningMessage().findComponent(GlLink);
  const findSharedRadioButton = () => findVisibilityGlRadioButtons().at(1);
  const findSharedReadOnlyHelpText = () => wrapper.findByTestId('shared-read-only-help-text');

  beforeEach(() => {
    mockToastShow.mockClear();
    saveSavedView.mockResolvedValue(successCreateResponse);
    createComponent();
  });

  it('correctly renders the modal, default title and the form', () => {
    expect(findForm().exists()).toBe(true);
    expect(findTitleInput().exists()).toBe(true);
    expect(findDescriptionInput().exists()).toBe(true);
    expect(findVisibilityInputs().exists()).toBe(true);
    expect(findModal().props('title')).toBe('New view');
  });

  it('autofocuses the title input when the modal is shown', async () => {
    findTitleInput().element.focus = jest.fn();

    findModal().vm.$emit('shown');
    await waitForPromises();

    expect(findTitleInput().element.focus).toHaveBeenCalled();
  });

  it('creates new saved view and hides modal when submitting a form', async () => {
    findTitleInput().vm.$emit('input', 'view title');

    findForm().vm.$emit('submit', {
      preventDefault: jest.fn(),
    });

    await waitForPromises();

    expect(wrapper.emitted('hide')).toEqual([[false]]);
    expect(findModal().exists()).toBe(true);
  });

  it.each`
    namespace    | isGroup
    ${'group'}   | ${true}
    ${'project'} | ${false}
  `('shows $namespace specific help text for shared radio button', ({ namespace, isGroup }) => {
    createComponent({ isGroup });
    const unexpectedText = namespace === 'group' ? 'project' : 'group';
    expect(findSharedRadioButton().text()).toContain(namespace);
    expect(findSharedRadioButton().text()).not.toContain(unexpectedText);
  });
  it.each`
    namespace    | isGroup
    ${'group'}   | ${true}
    ${'project'} | ${false}
  `('shows $namespace specific help text for read only shared option', ({ namespace, isGroup }) => {
    createComponent({ isGroup, mockSavedView: sharedSavedView });
    const unexpectedText = namespace === 'group' ? 'project' : 'group';
    expect(findSharedReadOnlyHelpText().text()).toContain(namespace);
    expect(findSharedReadOnlyHelpText().text()).not.toContain(unexpectedText);
  });

  describe('form validation', () => {
    const validTitle = 'Valid title';
    const invalidTitle = 'This sentence is over 40 characters long.';
    const validDescription = 'This is a valid description that is less than the character limit.';
    const invalidDescription = 'a'.repeat(150);

    describe('title validation', () => {
      it('disables the submit button when title is empty', async () => {
        findTitleInput().vm.$emit('input', '');

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });
        await waitForPromises();

        expect(findTitleInput().props().state).toBe(false);
        expect(findCreateButton().props('disabled')).toBe(true);
      });

      it('disables the submit button when title exceeds 40 characters', async () => {
        findTitleInput().vm.$emit('input', invalidTitle);

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });
        await waitForPromises();

        expect(findCreateButton().props('disabled')).toBe(true);
      });

      it('enables the submit button if title is entered after invalid title error', async () => {
        findTitleInput().vm.$emit('input', undefined);

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });
        await waitForPromises();

        expect(findTitleInput().props().state).toBe(false);
        expect(findCreateButton().props('disabled')).toBe(true);

        findTitleInput().vm.$emit('input', 'New view');
        await nextTick();

        expect(findTitleInput().props().state).toBe(true);
        expect(findCreateButton().props('disabled')).toBe(false);
      });

      it('displays the character count text when exceeding the character limit', async () => {
        findTitleInput().vm.$emit('input', invalidTitle);
        await nextTick();

        const charCount = findTitleFormGroup().findComponent(GlFormCharacterCount);
        expect(charCount.exists()).toBe(true);
        expect(charCount.props('value')).toBe(invalidTitle);

        const countText = findTitleFormGroup().find('#title-character-count-text');
        expect(countText.text()).toContain('over limit');
      });

      it('does not display the character count text when below the character limit', async () => {
        findTitleInput().vm.$emit('input', validTitle);
        await nextTick();

        const charCount = findTitleFormGroup().findComponent(GlFormCharacterCount);
        expect(charCount.exists()).toBe(true);
        expect(charCount.props('value')).toBe(validTitle);

        const countText = findTitleFormGroup().find('#title-character-count-text');
        expect(countText.text()).not.toContain('over limit');
      });
    });

    describe('description validation', () => {
      it('disables the submit button when description exceeds 140 characters', async () => {
        findTitleInput().vm.$emit('input', validTitle);
        findDescriptionInput().vm.$emit('input', invalidDescription);

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });
        await waitForPromises();

        expect(findCreateButton().props('disabled')).toBe(true);
      });

      it('displays the character count text when exceeding the character limit', async () => {
        findTitleInput().vm.$emit('input', validTitle);
        findDescriptionInput().vm.$emit('input', invalidDescription);
        await nextTick();

        const charCount = findDescriptionFormGroup().findComponent(GlFormCharacterCount);
        expect(charCount.exists()).toBe(true);
        expect(charCount.props('value')).toBe(invalidDescription);

        const countText = findDescriptionFormGroup().find('#description-character-count-text');
        expect(countText.text()).toContain('over limit');
      });

      it('does not display the character count text when below the character limit', async () => {
        findTitleInput().vm.$emit('input', validTitle);
        findDescriptionInput().vm.$emit('input', validDescription);
        await nextTick();

        const charCount = findDescriptionFormGroup().findComponent(GlFormCharacterCount);
        expect(charCount.exists()).toBe(true);
        expect(charCount.props('value')).toBe(validDescription);

        const countText = findDescriptionFormGroup().find('#description-character-count-text');
        expect(countText.text()).not.toContain('over limit');
      });
    });
  });

  describe('subscription limit warning', () => {
    describe('when showSubscriptionLimitWarning is false', () => {
      it('does not show the warning message', () => {
        createComponent({ props: { showSubscriptionLimitWarning: false } });

        expect(findWarningMessage().exists()).toBe(false);
      });
    });

    describe('when showSubscriptionLimitWarning is true', () => {
      beforeEach(() => {
        createComponent({ props: { showSubscriptionLimitWarning: true } });
      });

      it('shows the warning message with icon and link', () => {
        expect(findWarningMessage().exists()).toBe(true);
        expect(findWarningIcon().props('name')).toBe('warning');
        expect(findLearnMoreLink().exists()).toBe(true);
        expect(findLearnMoreLink().attributes('href')).toBe(
          helpPagePath('user/work_items/saved_views.md', { anchor: 'saved-view-limits' }),
        );
      });

      it('contains the correct warning text', () => {
        expect(findWarningMessage().text()).toContain(
          'You have reached the maximum number of views in your list.',
        );
        expect(findWarningMessage().text()).toContain(
          'If you add a view, the last view in your list will be removed.',
        );
      });
    });

    describe('when in edit mode', () => {
      it('does not show the warning even when showSubscriptionLimitWarning is true', () => {
        createComponent({
          props: { showSubscriptionLimitWarning: true },
          mockSavedView: existingSavedView,
        });

        expect(findWarningMessage().exists()).toBe(false);
      });
    });
  });

  describe('createSavedViewMutation', () => {
    const filters = { filters: { search: 'text' } };
    const displaySettings = { hiddenMetadataKeys: ['assignee'] };
    const sortKey = UPDATED_DESC;

    it.each`
      scenario                   | props                                    | expectedSortKey | expectedFilters   | expectedDisplaySettings
      ${'with no config'}        | ${{}}                                    | ${CREATED_DESC} | ${{}}             | ${{}}
      ${'with sort'}             | ${{ sortKey }}                           | ${UPDATED_DESC} | ${{}}             | ${{}}
      ${'with filters'}          | ${{ filters }}                           | ${CREATED_DESC} | ${{ ...filters }} | ${{}}
      ${'with display settings'} | ${{ displaySettings }}                   | ${CREATED_DESC} | ${{}}             | ${{ ...displaySettings }}
      ${'with all config'}       | ${{ filters, displaySettings, sortKey }} | ${UPDATED_DESC} | ${{ ...filters }} | ${{ ...displaySettings }}
    `(
      'successfully creates a saved view $scenario and shows a toast message',
      async ({ props, expectedSortKey, expectedFilters, expectedDisplaySettings }) => {
        createComponent({ props });

        findTitleInput().vm.$emit('input', 'Test View');
        findDescriptionInput().vm.$emit('input', 'Test Description');

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });

        await waitForPromises();

        expect(saveSavedView).toHaveBeenCalledWith({
          apolloClient: undefined,
          id: undefined,
          isEdit: false,
          isForm: true,
          namespacePath: 'test-project-path',
          name: 'Test View',
          description: 'Test Description',
          isPrivate: true,
          filters: expectedFilters,
          displaySettings: expectedDisplaySettings,
          sort: expectedSortKey,
          mutationKey: 'workItemSavedViewCreate',
          subscribed: undefined,
          userPermissions: undefined,
          subscribedSavedViewLimit: 5,
        });

        expect(mockToastShow).toHaveBeenCalledWith('New view created.');
        expect(wrapper.emitted('hide')).toEqual([[false]]);
      },
    );

    it.each`
      scenario                            | mockSetup                                                                                              | expectedError
      ${'with errors in response'}        | ${{ data: { workItemSavedViewCreate: { errors: ['Failed to create saved view'], savedView: null } } }} | ${'Failed to create saved view'}
      ${'with empty errors in response'}  | ${{ data: { workItemSavedViewCreate: { errors: [''], savedView: null } } }}                            | ${'Something went wrong while creating the view'}
      ${'when mutation throws exception'} | ${new Error('Network error')}                                                                          | ${'Something went wrong while creating the view'}
    `('shows an error message $scenario', async ({ mockSetup, expectedError }) => {
      if (mockSetup instanceof Error) {
        saveSavedView.mockRejectedValue(mockSetup);
      } else {
        saveSavedView.mockResolvedValue(mockSetup);
      }

      createComponent();

      findTitleInput().vm.$emit('input', 'Test View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(saveSavedView).toHaveBeenCalled();
      expect(findAlert().text()).toBe(expectedError);
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });

  describe('updateSavedViewMutation', () => {
    it('renders the modal with edit title when savedView has an id', () => {
      createComponent({ mockSavedView: existingSavedView });

      expect(findModal().props('title')).toBe('Edit view');
    });

    it('renders the submit button with "Save" label in edit mode', () => {
      createComponent({ mockSavedView: existingSavedView });

      expect(findCreateButton().text()).toBe('Save');
    });

    it('pre-populates the form with existing saved view data', () => {
      createComponent({ mockSavedView: existingSavedView });

      expect(findTitleInput().attributes('value')).toBe('Existing View');
      expect(findDescriptionInput().attributes('value')).toBe('Existing Description');
    });

    it('sets visibility to shared when savedView.isPrivate is false', () => {
      createComponent({ mockSavedView: existingSavedView });

      expect(findVisibilityGlRadioButtons().at(1).props().checked).toBe(
        SAVED_VIEW_VISIBILITY.SHARED,
      );
    });

    describe('visibility permission', () => {
      it('shows visibility radio buttons when user can update visibility', () => {
        createComponent({ mockSavedView: existingSavedView });

        expect(findVisibilityInputs().exists()).toBe(true);
      });

      it('shows read-only visibility when user cannot update visibility', () => {
        createComponent({ mockSavedView: sharedSavedView });

        expect(findVisibilityInputs().exists()).toBe(false);
        expect(findReadOnlyVisibility().exists()).toBe(true);
      });
    });

    // Note: The form is not supposed to update the filters, display settings and sort key
    it('successfully updates a saved view and shows a toast message', async () => {
      saveSavedView.mockResolvedValue(successUpdateResponse);

      createComponent({ mockSavedView: existingSavedView });

      findTitleInput().vm.$emit('input', 'Updated View');
      findDescriptionInput().vm.$emit('input', 'Updated Description');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(saveSavedView).toHaveBeenCalledWith({
        apolloClient: undefined,
        id: 'gid://gitlab/WorkItems::SavedView/123',
        name: 'Updated View',
        description: 'Updated Description',
        isPrivate: false,
        filters: {},
        displaySettings: {},
        sort: CREATED_DESC,
        isEdit: true,
        isForm: true,
        mutationKey: 'workItemSavedViewUpdate',
        namespacePath: 'test-project-path',
        subscribed: true,
        subscribedSavedViewLimit: 5,
        userPermissions: {
          deleteSavedView: true,
          updateSavedView: true,
          updateSavedViewVisibility: true,
          __typename: 'SavedViewPermissions',
        },
      });

      expect(mockToastShow).toHaveBeenCalledWith('View has been saved.');
      expect(wrapper.emitted('hide')).toEqual([[false]]);
    });

    it('shows an error message when update mutation fails with errors in response', async () => {
      saveSavedView.mockResolvedValue({
        data: {
          workItemSavedViewUpdate: {
            errors: ['Only the author can change visibility settings'],
            savedView: null,
          },
        },
      });

      createComponent({
        mockSavedView: existingSavedView,
      });

      findTitleInput().vm.$emit('input', 'Updated View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(saveSavedView).toHaveBeenCalled();
      expect(findAlert().text()).toBe('Only the author can change visibility settings');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });

    it('shows an error message when update mutation throws an exception', async () => {
      saveSavedView.mockRejectedValue(new Error('Network error'));

      createComponent({
        mockSavedView: existingSavedView,
      });

      findTitleInput().vm.$emit('input', 'Updated View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(saveSavedView).toHaveBeenCalled();
      expect(findAlert().text()).toBe('Something went wrong while saving the view');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });
});
