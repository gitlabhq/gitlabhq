import { GlForm, GlModal, GlAlert, GlFormRadio } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import WorkItemsNewSavedViewModal from '~/work_items/list/components/work_items_new_saved_view_modal.vue';
import createSavedViewMutation from '~/work_items/graphql/create_saved_view.mutation.graphql';
import updateSavedViewMutation from '~/work_items/graphql/update_saved_view.mutation.graphql';
import { CREATED_DESC } from '~/work_items/list/constants';
import { SAVED_VIEW_VISIBILITY } from '~/work_items/constants';

import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

describe('WorkItemsNewSavedViewModal', () => {
  let wrapper;
  let mockApollo;

  const successMutationHandler = jest.fn().mockResolvedValue({
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
          userPermissions: {
            updateSavedView: true,
            deleteSavedView: true,
          },
        },
      },
    },
  });

  const successUpdateMutationHandler = jest.fn().mockResolvedValue({
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
          userPermissions: {
            updateSavedView: true,
            deleteSavedView: true,
          },
        },
      },
    },
  });

  const mockToastShow = jest.fn();

  const createComponent = ({
    props,
    mutationHandler = successMutationHandler,
    updateMutationHandler = successUpdateMutationHandler,
    mockSavedView = null,
  } = {}) => {
    mockApollo = createMockApollo([
      [createSavedViewMutation, mutationHandler],
      [updateSavedViewMutation, updateMutationHandler],
    ]);

    wrapper = shallowMountExtended(WorkItemsNewSavedViewModal, {
      apolloProvider: mockApollo,
      propsData: {
        show: true,
        fullPath: 'test-project-path',
        sortKey: CREATED_DESC,
        savedView: mockSavedView,
        ...props,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(GlForm);
  const findTitleInput = () => wrapper.find('#saved-view-title');
  const findDescriptionInput = () => wrapper.find('#saved-view-description');
  const findVisibilityInputs = () => wrapper.findByTestId('saved-view-visibility');
  const findCreateButton = () => wrapper.findByTestId('create-view-button');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findVisibilityGlRadioButtons = () => findVisibilityInputs().findAllComponents(GlFormRadio);

  beforeEach(() => {
    mockToastShow.mockClear();
    createComponent();
  });

  it('correctly renders the modal, default title and the form', () => {
    expect(findForm().exists()).toBe(true);
    expect(findTitleInput().exists()).toBe(true);
    expect(findDescriptionInput().exists()).toBe(true);
    expect(findVisibilityInputs().exists()).toBe(true);
    expect(findModal().props('title')).toBe('New view');
  });

  it('correctly changes the passed title', () => {
    createComponent();
    expect(findModal().props('title')).toBe('New view');
  });

  it('autofocuses the title input when the modal is shown', async () => {
    findTitleInput().element.focus = jest.fn();

    findModal().vm.$emit('shown');
    await waitForPromises();

    expect(findTitleInput().element.focus).toHaveBeenCalled();
  });

  it('disables the submit button if invalid title is provided', async () => {
    findTitleInput().vm.$emit('input', '');

    findForm().vm.$emit('submit', {
      preventDefault: jest.fn(),
    });
    await waitForPromises();

    expect(findCreateButton().props('disabled')).toBe(true);
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

  describe('createSavedViewMutation', () => {
    it('successfully creates a saved view and shows a toast message', async () => {
      createComponent({
        mutationHandlerOverride: successMutationHandler,
      });

      findTitleInput().vm.$emit('input', 'Test View');
      findDescriptionInput().vm.$emit('input', 'Test Description');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(successMutationHandler).toHaveBeenCalledWith({
        input: {
          namespacePath: 'test-project-path',
          name: 'Test View',
          description: 'Test Description',
          private: true,
          filters: {},
          displaySettings: {},
          sort: CREATED_DESC,
        },
      });

      expect(mockToastShow).toHaveBeenCalledWith('New view created.');
      expect(wrapper.emitted('hide')).toEqual([[false]]);
    });

    it('shows an error message when mutation fails with errors in response', async () => {
      const errorMutationHandler = jest.fn().mockResolvedValue({
        data: {
          workItemSavedViewCreate: {
            errors: ['Failed to create saved view'],
            savedView: null,
          },
        },
      });

      createComponent({
        mutationHandler: errorMutationHandler,
      });

      findTitleInput().vm.$emit('input', 'Test View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(errorMutationHandler).toHaveBeenCalled();

      expect(findAlert().text()).toBe('Something went wrong while saving the view');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });

    it('shows an error message when mutation throws an exception', async () => {
      const exceptionMutationHandler = jest.fn().mockRejectedValue(new Error('Network error'));

      createComponent({
        mutationHandler: exceptionMutationHandler,
      });

      findTitleInput().vm.$emit('input', 'Test View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(exceptionMutationHandler).toHaveBeenCalled();
      expect(findAlert().text()).toBe('Something went wrong while saving the view');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });

  describe('updateSavedViewMutation', () => {
    const existingSavedView = {
      id: 'gid://gitlab/WorkItems::SavedView/123',
      name: 'Existing View',
      description: 'Existing Description',
      isPrivate: false,
      subscribed: true,
      userPermissions: {
        updateSavedView: true,
        deleteSavedView: true,
      },
    };

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

    it('successfully updates a saved view and shows a toast message', async () => {
      createComponent({ mockSavedView: existingSavedView });

      findTitleInput().vm.$emit('input', 'Updated View');
      findDescriptionInput().vm.$emit('input', 'Updated Description');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(successUpdateMutationHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItems::SavedView/123',
          name: 'Updated View',
          description: 'Updated Description',
          private: false,
          filters: {},
          displaySettings: {},
          sort: CREATED_DESC,
        },
      });

      expect(mockToastShow).toHaveBeenCalledWith('View has been saved.');
      expect(wrapper.emitted('hide')).toEqual([[false]]);
    });

    it('shows an error message when update mutation fails with errors in response', async () => {
      const errorUpdateMutationHandler = jest.fn().mockResolvedValue({
        data: {
          workItemSavedViewUpdate: {
            errors: ['Failed to update saved view'],
            savedView: null,
          },
        },
      });

      createComponent({
        mockSavedView: existingSavedView,
        updateMutationHandler: errorUpdateMutationHandler,
      });

      findTitleInput().vm.$emit('input', 'Updated View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(errorUpdateMutationHandler).toHaveBeenCalled();
      expect(findAlert().text()).toBe('Something went wrong while saving the view');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });

    it('shows an error message when update mutation throws an exception', async () => {
      const exceptionUpdateMutationHandler = jest
        .fn()
        .mockRejectedValue(new Error('Network error'));

      createComponent({
        mockSavedView: existingSavedView,
        updateMutationHandler: exceptionUpdateMutationHandler,
      });

      findTitleInput().vm.$emit('input', 'Updated View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(exceptionUpdateMutationHandler).toHaveBeenCalled();
      expect(findAlert().text()).toBe('Something went wrong while saving the view');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });
});
