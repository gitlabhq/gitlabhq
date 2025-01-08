import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import updateDesignDescriptionMutation from '~/work_items/components/design_management/graphql/update_design_description.mutation.graphql';
import DesignDescription from '~/work_items/components/design_management/design_preview/design_description.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { mockTracking } from 'helpers/tracking_helper';
import { UPDATE_DESCRIPTION_ERROR } from '~/work_items/components/design_management/constants';
import { mockUpdateDesignDescriptionResponse, designDescriptionFactory } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

Vue.use(VueApollo);

describe('DesignDescription', () => {
  let wrapper;

  const mockDesignVariables = {
    fullPath: '',
    iid: '1',
    filenames: ['test.jpg'],
    atVersion: null,
  };
  const formFieldProps = {
    id: 'design-description',
    name: 'design-description',
    placeholder: 'Write a comment or drag your files here…',
    'aria-label': 'Design description',
  };
  const updatedDescription = 'New test description';

  const mockDesign = designDescriptionFactory();

  const findDesignContent = () => wrapper.findByTestId('design-description-content');
  const findEditDescriptionButton = () => wrapper.findByTestId('edit-description');
  const findSaveDescriptionButton = () => wrapper.findByTestId('save-description');
  const findCancelDescriptionButton = () => wrapper.findByTestId('cancel');
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findCheckboxAtIndex = (index) => wrapper.findAll('input[type="checkbox"]').at(index);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findAddDesignDescriptionButton = () => wrapper.findByTestId('add-design-description');

  const updateDescriptionMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue(mockUpdateDesignDescriptionResponse);
  const mockDesignUpdateResponseHandler = jest.fn().mockResolvedValue(
    mockUpdateDesignDescriptionResponse({
      description: updatedDescription,
      descriptionHtml: `<p data-sourcepos="1:1-1:16" dir="auto">${updatedDescription}</p>`,
    }),
  );
  const updateDescriptionMutationError = jest
    .fn()
    .mockRejectedValue(new Error(UPDATE_DESCRIPTION_ERROR));

  const createComponent = ({
    design = mockDesign,
    descriptionText = '',
    isSubmitting = false,
    designUpdateMutationHandler = updateDescriptionMutationSuccessHandler,
  } = {}) => {
    wrapper = shallowMountExtended(DesignDescription, {
      apolloProvider: createMockApollo([
        [updateDesignDescriptionMutation, designUpdateMutationHandler],
      ]),
      propsData: {
        design,
        designVariables: mockDesignVariables,
        markdownPreviewPath: '/gitlab-org/gitlab-test/preview_markdown?target_type=Issue',
      },
      data() {
        return {
          formFieldProps,
          descriptionText,
          isSubmitting,
        };
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders design description', () => {
    expect(wrapper.findByTestId('design-description-content').text()).toBe(mockDesign.description);
  });

  describe('user has no updateDesign permission', () => {
    it('renders description content without edit button', () => {
      createComponent({
        design: designDescriptionFactory({
          updateDesign: false,
        }),
      });

      expect(findDesignContent().text()).toEqual('Description test');
      expect(findEditDescriptionButton().exists()).toBe(false);
    });
  });

  describe('user has updateDesign permission', () => {
    it('renders description content with the edit button', () => {
      createComponent();

      expect(findDesignContent().text()).toEqual('Description test');
      expect(findEditDescriptionButton().exists()).toBe(true);
    });

    it('renders save button when editor is open', async () => {
      createComponent();

      await findEditDescriptionButton().vm.$emit('click');

      expect(findSaveDescriptionButton().exists()).toBe(true);
      expect(findSaveDescriptionButton().attributes('disabled')).toBeUndefined();
    });

    it('renders add a description button when there is no description', () => {
      createComponent({
        design: designDescriptionFactory({
          description: '',
          descriptionHtml: '',
        }),
      });

      expect(findMarkdownEditor().exists()).toBe(false);
      expect(findAddDesignDescriptionButton().exists()).toBe(true);
    });

    it('renders description form when add a description button is clicked', async () => {
      createComponent({
        design: designDescriptionFactory({
          description: '',
          descriptionHtml: '',
        }),
      });

      expect(findAddDesignDescriptionButton().exists()).toBe(true);
      expect(findMarkdownEditor().exists()).toBe(false);

      await findAddDesignDescriptionButton().vm.$emit('click');

      expect(findMarkdownEditor().exists()).toBe(true);
      expect(findAddDesignDescriptionButton().exists()).toBe(false);
    });

    it('resets description text if empty when form is closed', async () => {
      createComponent();

      await findEditDescriptionButton().vm.$emit('click');

      findMarkdownEditor().vm.$emit('input', '');

      await findCancelDescriptionButton().vm.$emit('click');

      expect(findDesignContent().text()).toEqual('Description test');
    });

    it('triggers mutation when form is submitted and hides the form', async () => {
      const trackingSpy = mockTracking(undefined, null, jest.spyOn);
      createComponent({
        designUpdateMutationHandler: mockDesignUpdateResponseHandler,
      });

      await findEditDescriptionButton().vm.$emit('click');

      findMarkdownEditor().vm.$emit('input', updatedDescription);
      findSaveDescriptionButton().vm.$emit('click');

      await nextTick();

      expect(mockDesignUpdateResponseHandler).toHaveBeenCalledWith({
        input: {
          description: updatedDescription,
          id: 'gid:/gitlab/Design/1',
        },
      });

      await waitForPromises();

      expect(findMarkdownEditor().exists()).toBe(false);

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'save_markdown', {
        label: 'markdown_editor',
        property: 'Design',
      });
    });

    it('shows error message when mutation fails', async () => {
      createComponent({
        descriptionText: updatedDescription,
        designUpdateMutationHandler: updateDescriptionMutationError,
      });

      await findEditDescriptionButton().vm.$emit('click');
      findMarkdownEditor().vm.$emit('input', updatedDescription);
      findSaveDescriptionButton().vm.$emit('click');

      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(UPDATE_DESCRIPTION_ERROR);
    });

    describe('content has checkboxes', () => {
      const mockCheckboxDescription = '- [x] todo 1\n- [ ] todo 2';
      const mockCheckboxDescriptionHtml = `<ul dir="auto" class="task-list" data-sourcepos="1:1-4:0">
      <li class="task-list-item" data-sourcepos="1:1-2:15">
      <input checked="" class="task-list-item-checkbox" type="checkbox"> todo 1</li>
      <li class="task-list-item" data-sourcepos="2:1-2:15">
      <input class="task-list-item-checkbox" type="checkbox"> todo 2</li>
      </ul>`;
      const checkboxDesignDescription = designDescriptionFactory({
        updateDesign: true,
        description: mockCheckboxDescription,
        descriptionHtml: mockCheckboxDescriptionHtml,
      });
      const mockNoDescriptionChangeResponseHandler = jest.fn().mockResolvedValue(
        mockUpdateDesignDescriptionResponse({
          description: mockCheckboxDescription,
          descriptionHtml: mockCheckboxDescriptionHtml,
        }),
      );
      const mockCheckedDescriptionUpdateResponseHandler = jest.fn().mockResolvedValue(
        mockUpdateDesignDescriptionResponse({
          description: '- [x] todo 1\n- [x] todo 2',
          descriptionHtml: `<ul dir="auto" class="task-list" data-sourcepos="1:1-4:0">
          <li class="task-list-item" data-sourcepos="1:1-2:15">
          <input checked="" class="task-list-item-checkbox" type="checkbox"> todo 1</li>
          <li class="task-list-item" data-sourcepos="2:1-2:15">
          <input class="task-list-item-checkbox" type="checkbox"> todo 2</li>
          </ul>`,
        }),
      );
      const mockUnCheckedDescriptionUpdateResponseHandler = jest.fn().mockResolvedValue(
        mockUpdateDesignDescriptionResponse({
          description: '- [ ] todo 1\n- [ ] todo 2',
          descriptionHtml: `<ul dir="auto" class="task-list" data-sourcepos="1:1-4:0">
          <li class="task-list-item" data-sourcepos="1:1-2:15">
          <input class="task-list-item-checkbox" type="checkbox"> todo 1</li>
          <li class="task-list-item" data-sourcepos="2:1-2:15">
          <input class="task-list-item-checkbox" type="checkbox"> todo 2</li>
          </ul>`,
        }),
      );

      it.each`
        assertionName  | mockUpdateCheckboxesResponseHandler              | checkboxIndex | checked  | expectedDesignDescription
        ${'checked'}   | ${mockCheckedDescriptionUpdateResponseHandler}   | ${1}          | ${true}  | ${'- [x] todo 1\n- [x] todo 2'}
        ${'unchecked'} | ${mockUnCheckedDescriptionUpdateResponseHandler} | ${0}          | ${false} | ${'- [ ] todo 1\n- [ ] todo 2'}
      `(
        'updates the store object when checkbox is $assertionName',
        async ({
          mockUpdateCheckboxesResponseHandler,
          checkboxIndex,
          checked,
          expectedDesignDescription,
        }) => {
          createComponent({
            design: checkboxDesignDescription,
            descriptionText: mockCheckboxDescription,
            designUpdateMutationHandler: mockUpdateCheckboxesResponseHandler,
          });

          findCheckboxAtIndex(checkboxIndex).setChecked(checked);

          expect(mockUpdateCheckboxesResponseHandler).toHaveBeenCalledWith({
            input: {
              description: expectedDesignDescription,
              id: 'gid:/gitlab/Design/1',
            },
          });

          await waitForPromises();

          expect(renderGFM).toHaveBeenCalled();
        },
      );

      it('disables checkbox while updating', () => {
        createComponent({
          design: checkboxDesignDescription,
          descriptionText: mockCheckboxDescription,
        });

        findCheckboxAtIndex(1).setChecked();

        expect(findCheckboxAtIndex(1).attributes().disabled).toBeDefined();
      });

      it('re-enables the checkbox when the form is closed without making any changes', async () => {
        createComponent({
          design: checkboxDesignDescription,
          descriptionText: mockCheckboxDescription,
        });

        await findEditDescriptionButton().vm.$emit('click');
        await findCancelDescriptionButton().vm.$emit('click');
        expect(findCheckboxAtIndex(0).attributes().disabled).toBeUndefined();
      });

      it('re-enables the checkbox when the form is submitted with no changes to the description', async () => {
        createComponent({
          design: checkboxDesignDescription,
          descriptionText: mockCheckboxDescription,
          designUpdateMutationHandler: mockNoDescriptionChangeResponseHandler,
        });

        await findEditDescriptionButton().vm.$emit('click');
        findMarkdownEditor().vm.$emit('input', mockCheckboxDescription);
        findSaveDescriptionButton().vm.$emit('click');
        await nextTick();
        expect(mockNoDescriptionChangeResponseHandler).toHaveBeenCalledWith({
          input: {
            description: mockCheckboxDescription,
            id: 'gid:/gitlab/Design/1',
          },
        });
        await waitForPromises();
        expect(findCheckboxAtIndex(0).attributes().disabled).toBeUndefined();
      });
    });
  });
});
