import { GlAlert, GlForm } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EditedAt from '~/issues/show/components/edited.vue';
import { updateDraft } from '~/lib/utils/autosave';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ENTER_KEY } from '~/lib/utils/keys';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemDescriptionRendered from '~/work_items/components/work_item_description_rendered.vue';
import WorkItemDescriptionTemplatesListbox from '~/work_items/components/work_item_description_template_listbox.vue';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemDescriptionTemplateQuery from '~/work_items/graphql/work_item_description_template.query.graphql';
import { autocompleteDataSources, markdownPreviewPath, newWorkItemId } from '~/work_items/utils';
import { ROUTES } from '~/work_items/constants';
import {
  updateWorkItemMutationResponse,
  workItemByIidResponseFactory,
  workItemQueryResponse,
} from '../mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
jest.mock('~/lib/utils/autosave');

describe('WorkItemDescription', () => {
  let wrapper;
  let router;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
  const findForm = () => wrapper.findComponent(GlForm);
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findRenderedDescription = () => wrapper.findComponent(WorkItemDescriptionRendered);
  const findEditedAt = () => wrapper.findComponent(EditedAt);
  const findConflictsAlert = () => wrapper.findComponent(GlAlert);
  const findConflictedDescription = () => wrapper.findByTestId('conflicted-description');
  const findDescriptionTemplateListbox = () =>
    wrapper.findComponent(WorkItemDescriptionTemplatesListbox);
  const findDescriptionTemplateWarning = () => wrapper.findByTestId('description-template-warning');
  const findApplyTemplate = () => wrapper.findByTestId('template-apply');
  const findCancelApplyTemplate = () => wrapper.findByTestId('template-cancel');

  const editDescription = (newText) => findMarkdownEditor().vm.$emit('input', newText);

  const findCancelButton = () => wrapper.findByTestId('cancel');
  const findSubmitButton = () => wrapper.findByTestId('save-description');
  const clickCancel = () => findForm().vm.$emit('reset', new Event('reset'));

  const successfulTemplateHandler = jest.fn().mockResolvedValue({
    data: {
      workItemDescriptionTemplateContent: {
        content: 'A template',
        __typename: 'WorkItemDescriptionTemplate',
      },
    },
  });

  const createComponent = async ({
    mutationHandler = mutationSuccessHandler,
    canUpdate = true,
    workItemResponse = workItemByIidResponseFactory({ canUpdate }),
    workItemResponseHandler = jest.fn().mockResolvedValue(workItemResponse),
    isEditing = false,
    isGroup = false,
    workItemId = workItemQueryResponse.data.workItem.id,
    workItemIid = '1',
    workItemTypeId = workItemQueryResponse.data.workItem.workItemType.id,
    workItemTypeName = workItemQueryResponse.data.workItem.workItemType.name,
    editMode = false,
    showButtonsBelowField,
    descriptionTemplateHandler = successfulTemplateHandler,
    routeName = '',
    routeQuery = {},
  } = {}) => {
    router = {
      replace: jest.fn(),
    };

    wrapper = shallowMountExtended(WorkItemDescription, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemResponseHandler],
        [updateWorkItemMutation, mutationHandler],
        [workItemDescriptionTemplateQuery, descriptionTemplateHandler],
      ]),
      propsData: {
        fullPath: 'test-project-path',
        workItemId,
        workItemIid,
        workItemTypeId,
        workItemTypeName,
        editMode,
        showButtonsBelowField,
      },
      provide: {
        isGroup,
        glFeatures: {
          workItemDescriptionTemplates: true,
        },
      },
      mocks: {
        $route: {
          name: routeName,
          query: routeQuery,
        },
        $router: router,
      },
      stubs: {
        GlAlert,
      },
    });

    await waitForPromises();

    if (isEditing) {
      findRenderedDescription().vm.$emit('startEditing');

      await nextTick();
    }
  };

  describe('editing description', () => {
    it('passes correct autocompletion data and preview markdown sources and enables quick actions', async () => {
      const {
        iid,
        namespace: { fullPath },
      } = workItemQueryResponse.data.workItem;

      await createComponent({ isEditing: true });

      expect(findMarkdownEditor().props()).toMatchObject({
        supportsQuickActions: true,
        renderMarkdownPath: markdownPreviewPath({ fullPath, iid }),
        autocompleteDataSources: autocompleteDataSources({ fullPath, iid }),
      });
    });

    it('passes correct autocompletion data sources when it is a group work item', async () => {
      const {
        iid,
        namespace: { fullPath },
      } = workItemQueryResponse.data.workItem;

      const workItemResponse = workItemByIidResponseFactory();

      const groupWorkItem = {
        data: {
          workspace: {
            __typename: 'Group',
            id: 'gid://gitlab/Group/24',
            workItem: {
              ...workItemResponse.data.workspace.workItem,
              namespace: {
                id: 'gid://gitlab/Group/24',
                fullPath: 'gitlab-org',
                name: 'Gitlab Org',
                fullName: 'Gitlab Org',
                __typename: 'Namespace',
              },
            },
          },
        },
      };

      createComponent({ isEditing: true, workItemResponse: groupWorkItem, isGroup: true });

      await waitForPromises();

      expect(findMarkdownEditor().props()).toMatchObject({
        supportsQuickActions: true,
        renderMarkdownPath: markdownPreviewPath({ fullPath, iid, isGroup: true }),
        autocompleteDataSources: autocompleteDataSources({
          fullPath,
          iid,
          isGroup: true,
        }),
      });
    });

    it('shows edited by text', async () => {
      const lastEditedAt = '2022-09-21T06:18:42Z';
      const lastEditedBy = {
        name: 'Administrator',
        webPath: '/root',
      };

      await createComponent({
        workItemResponse: workItemByIidResponseFactory({ lastEditedAt, lastEditedBy }),
      });

      expect(findEditedAt().props()).toMatchObject({
        updatedAt: lastEditedAt,
        updatedByName: lastEditedBy.name,
        updatedByPath: lastEditedBy.webPath,
      });
    });

    it('does not show edited by text', async () => {
      await createComponent();

      expect(findEditedAt().exists()).toBe(false);
    });

    it('cancels when clicking cancel', async () => {
      await createComponent({
        isEditing: true,
      });

      clickCancel();

      await nextTick();

      expect(confirmAction).not.toHaveBeenCalled();
      expect(findMarkdownEditor().exists()).toBe(false);
    });

    it('prompts for confirmation when clicking cancel after changes', async () => {
      await createComponent({
        isEditing: true,
      });

      editDescription('updated desc');

      clickCancel();

      await nextTick();

      expect(confirmAction).toHaveBeenCalled();
    });

    it('autosaves description', async () => {
      await createComponent({
        isEditing: true,
      });

      editDescription('updated desc');

      expect(updateDraft).toHaveBeenCalled();
    });

    it('maps submit and cancel buttons to form actions', async () => {
      await createComponent({
        isEditing: true,
      });

      expect(findCancelButton().attributes('type')).toBe('reset');
      expect(findSubmitButton().attributes('type')).toBe('submit');
    });

    it('hides buttons when showButtonsBelowField is false', async () => {
      await createComponent({
        isEditing: true,
        showButtonsBelowField: false,
      });

      expect(findCancelButton().exists()).toBe(false);
      expect(findSubmitButton().exists()).toBe(false);
    });
  });

  it('calls the project work item query', () => {
    const workItemResponseHandler = jest.fn().mockResolvedValue(workItemByIidResponseFactory());
    createComponent({ workItemResponseHandler });

    expect(workItemResponseHandler).toHaveBeenCalled();
  });

  describe('when edit mode is inactive', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not show edit mode of markdown editor in default mode', () => {
      expect(findMarkdownEditor().exists()).toBe(false);
    });
  });

  describe('when edit mode is active', () => {
    it('shows markdown editor in edit mode only when the correct props are passed', () => {
      createComponent({ editMode: true });

      expect(findMarkdownEditor().exists()).toBe(true);
    });

    it('emits the `updateDraft` event when the description is updated', () => {
      createComponent({ editMode: true });
      const updatedDesc = 'updated desc with inline editing disabled';

      findMarkdownEditor().vm.$emit('input', updatedDesc);

      expect(wrapper.emitted('updateDraft')).toEqual([[updatedDesc]]);
    });

    it('emits the `updateWorkItem` event when submitting the description', async () => {
      await createComponent({ isEditing: true });
      editDescription('updated description');
      findMarkdownEditor().vm.$emit(
        'keydown',
        new KeyboardEvent('keydown', { key: ENTER_KEY, ctrlKey: true }),
      );

      expect(wrapper.emitted('updateWorkItem')).toEqual([[{ clearDraft: expect.any(Function) }]]);
    });

    describe('description templates', () => {
      it('displays the description template selection listbox', async () => {
        await createComponent({ isEditing: true });
        expect(findDescriptionTemplateListbox().exists()).toBe(true);
      });

      describe('selecting a template successfully', () => {
        beforeEach(async () => {
          await createComponent({
            isEditing: true,
            workItemId: newWorkItemId(workItemQueryResponse.data.workItem.workItemType.name),
          });
          findDescriptionTemplateListbox().vm.$emit('selectTemplate', {
            name: 'example',
            projectId: 1,
            catagory: 'catagory',
          });
          await nextTick();
          await waitForPromises();
        });

        it('queries for the template content when a template is selected', () => {
          expect(successfulTemplateHandler).toHaveBeenCalledWith({
            name: 'example',
            projectId: 1,
          });
        });

        it('displays a warning when a description template is selected', () => {
          expect(findDescriptionTemplateWarning().exists()).toBe(true);
          expect(findCancelApplyTemplate().exists()).toBe(true);
          expect(findApplyTemplate().exists()).toBe(true);
        });

        it('hides the warning when the cancel button is clicked', async () => {
          expect(findDescriptionTemplateWarning().exists()).toBe(true);
          findCancelApplyTemplate().vm.$emit('click');
          await nextTick();
          expect(findDescriptionTemplateWarning().exists()).toBe(false);
        });

        it('applies the template when the apply button is clicked', async () => {
          findApplyTemplate().vm.$emit('click');
          await nextTick();
          expect(findMarkdownEditor().props('value')).toBe('A template');
        });

        it('hides the warning when the template is applied', async () => {
          findApplyTemplate().vm.$emit('click');
          await nextTick();
          expect(findDescriptionTemplateWarning().exists()).toBe(false);
        });

        describe('clearing a template', () => {
          it('sets the description to be empty when cleared', async () => {
            // apply a template
            findApplyTemplate().vm.$emit('click');
            await nextTick();
            expect(findMarkdownEditor().props('value')).toBe('A template');
            // clear the template
            findDescriptionTemplateListbox().vm.$emit('clear');
            await nextTick();
            // check we have cleared correctly
            expect(findMarkdownEditor().props('value')).toBe('');
          });
        });

        describe('resetting a template', () => {
          it('sets the description back to the original template value when reset', async () => {
            // apply a template
            findApplyTemplate().vm.$emit('click');
            // write something else
            findMarkdownEditor().vm.$emit('input', 'some other value');
            await nextTick();
            // reset the template
            findDescriptionTemplateListbox().vm.$emit('reset');
            await nextTick();
            // check we have reset correctly
            expect(findMarkdownEditor().props('value')).toBe('A template');
          });
        });
      });

      describe('selecting a template unsuccessfully', () => {
        beforeEach(async () => {
          await createComponent({
            isEditing: true,
            descriptionTemplateHandler: jest.fn().mockRejectedValue(new Error()),
          });
          findDescriptionTemplateListbox().vm.$emit('selectTemplate', {
            name: 'example',
            projectId: 1,
            category: 'category',
          });
          await nextTick();
          await waitForPromises();
        });

        it('emits an error event', () => {
          expect(wrapper.emitted('error')).toEqual([['Unable to find selected template.']]);
        });
      });

      describe('URL param handling', () => {
        describe('when on new work item route', () => {
          describe('description_template param', () => {
            beforeEach(async () => {
              await createComponent({
                routeName: ROUTES.new,
                routeQuery: { description_template: 'bug', other_param: 'some_value' },
                isEditing: true,
              });
            });

            it('sets selected template from URL on mount', () => {
              expect(findDescriptionTemplateListbox().props().template).toMatchObject({
                name: 'bug',
                category: null,
                projectId: null,
              });
            });

            it('updates URL when applying template', async () => {
              findDescriptionTemplateListbox().vm.$emit('selectTemplate', {
                name: 'example-template',
                projectId: 1,
                category: 'category',
              });
              await nextTick();
              await waitForPromises();

              findApplyTemplate().vm.$emit('click');

              expect(router.replace).toHaveBeenCalledWith({
                query: {
                  description_template: 'example-template',
                  other_param: 'some_value',
                },
              });
            });

            it('removes template param (and not other params) from URL when canceling template', async () => {
              findDescriptionTemplateListbox().vm.$emit('selectTemplate', {
                name: 'example-template',
                projectId: 1,
                category: 'category',
              });
              await nextTick();
              await waitForPromises();

              findCancelApplyTemplate().vm.$emit('click');

              expect(router.replace).toHaveBeenCalledWith({
                query: {
                  other_param: 'some_value',
                },
              });
            });
          });

          describe('issuable_template param', () => {
            beforeEach(async () => {
              await createComponent({
                routeName: ROUTES.new,
                routeQuery: { issuable_template: 'my issue template', other_param: 'some_value' },
                isEditing: true,
              });
            });

            it('sets selected template from old template param', () => {
              expect(findDescriptionTemplateListbox().props().template).toMatchObject({
                name: 'my issue template',
                category: null,
                projectId: null,
              });
            });

            it('removes old template param on apply', async () => {
              findDescriptionTemplateListbox().vm.$emit('selectTemplate', {
                name: 'example-template',
                projectId: 1,
                category: 'category',
              });
              await nextTick();
              await waitForPromises();

              findApplyTemplate().vm.$emit('click');

              expect(router.replace).toHaveBeenCalledWith({
                query: {
                  description_template: 'example-template',
                  other_param: 'some_value',
                },
              });
            });

            it('removes old template param on cancel', async () => {
              await createComponent({
                routeName: ROUTES.new,
                routeQuery: { issuable_template: 'my issue template', other_param: 'some_value' },
                isEditing: true,
              });

              findDescriptionTemplateListbox().vm.$emit('selectTemplate', {
                name: 'example-template',
                projectId: 1,
                category: 'category',
              });
              await nextTick();
              await waitForPromises();

              findCancelApplyTemplate().vm.$emit('click');

              expect(router.replace).toHaveBeenCalledWith({
                query: {
                  other_param: 'some_value',
                },
              });
            });
          });
        });

        describe('when not on new work item route', () => {
          beforeEach(async () => {
            await createComponent({
              routeName: ROUTES.workItem,
              routeQuery: { description_template: 'my issue template' },
              isEditing: true,
            });
          });

          it('does not set selected template from URL on mount', () => {
            expect(findDescriptionTemplateListbox().props().template).toBe(null);
          });

          it('does not update URL when applying template', async () => {
            findDescriptionTemplateListbox().vm.$emit('selectTemplate', {
              name: 'example-template',
              projectId: 1,
              category: 'category',
            });
            await nextTick();
            await waitForPromises();

            findApplyTemplate().vm.$emit('click');

            expect(router.replace).not.toHaveBeenCalled();
          });

          it('does not update URL when canceling template', async () => {
            findDescriptionTemplateListbox().vm.$emit('selectTemplate', {
              name: 'example-template',
              projectId: 1,
              category: 'category',
            });
            await nextTick();
            await waitForPromises();

            findCancelApplyTemplate().vm.$emit('click');

            expect(router.replace).not.toHaveBeenCalled();
          });
        });
      });
    });

    describe('when description has conflicts', () => {
      beforeEach(async () => {
        const workItemResponseHandler = jest
          .fn()
          .mockResolvedValueOnce(workItemByIidResponseFactory())
          .mockResolvedValueOnce(
            workItemByIidResponseFactory({
              descriptionText: 'description updated by someone else',
            }),
          );
        await createComponent({ isEditing: true, workItemResponseHandler });

        editDescription('updated description');

        // Trigger a refetch of the work item data
        await wrapper.vm.$apollo.queries.workItem.refetch();
      });

      it('shows conflict warning when description is updated while editing', () => {
        expect(findConflictsAlert().exists()).toBe(true);
        expect(findConflictsAlert().text()).toContain(
          'Someone edited the description at the same time you did',
        );
        expect(findConflictedDescription().attributes('value')).toBe(
          'description updated by someone else',
        );

        expect(findSubmitButton().text()).toBe('Save and overwrite');
        expect(findCancelButton().text()).toBe('Discard changes');
      });

      it('clears conflict warning on save', async () => {
        findSubmitButton().vm.$emit('click');

        await nextTick();

        expect(findConflictsAlert().exists()).toBe(false);
      });
    });

    it('does not show conflict warning when in create flow', async () => {
      const workItemResponseHandler = jest
        .fn()
        .mockResolvedValueOnce(workItemByIidResponseFactory())
        .mockResolvedValueOnce(
          workItemByIidResponseFactory({
            descriptionText: 'description updated by someone else',
          }),
        );
      await createComponent({
        workItemId: newWorkItemId(workItemQueryResponse.data.workItem.workItemType.name),
        isEditing: true,
        workItemResponseHandler,
      });

      editDescription('updated description');

      // Trigger a refetch of the work item data
      await wrapper.vm.$apollo.queries.workItem.refetch();

      expect(findConflictsAlert().exists()).toBe(false);
    });
  });

  describe('checklist count visibility', () => {
    const taskCompletionStatus = {
      completedCount: 0,
      count: 4,
    };

    describe('when checklist exists', () => {
      it('when edit mode is active, checklist count is not visible', async () => {
        await createComponent({
          editMode: true,
          workItemResponse: workItemByIidResponseFactory({ taskCompletionStatus }),
        });

        expect(findEditedAt().exists()).toBe(false);
      });

      it('when edit mode is inactive, checklist count is visible', async () => {
        await createComponent({
          editMode: false,
          workItemResponse: workItemByIidResponseFactory({ taskCompletionStatus }),
        });

        expect(findEditedAt().exists()).toBe(true);
        expect(findEditedAt().props()).toMatchObject({
          taskCompletionStatus,
        });
      });
    });

    describe('when checklist does not exist', () => {
      it('checklist count is not visible', async () => {
        await createComponent({
          workItemResponse: workItemByIidResponseFactory({ taskCompletionStatus: null }),
        });

        expect(findEditedAt().exists()).toBe(false);
      });
    });
  });
});
