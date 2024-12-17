import { GlFormInput, GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import IssuableForm from '~/vue_shared/issuable/create/components/issuable_form.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import LabelsSelect from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';
import { TYPE_TEST_CASE } from '~/issues/constants';

const createComponent = ({
  descriptionPreviewPath = '/gitlab-org/gitlab-shell/preview_markdown',
  descriptionHelpPath = '/help/user/markdown',
  labelsFetchPath = '/gitlab-org/gitlab-shell/-/labels.json',
  labelsManagePath = '/gitlab-org/gitlab-shell/-/labels',
  issuableType = TYPE_TEST_CASE,
} = {}) => {
  return shallowMountExtended(IssuableForm, {
    propsData: {
      descriptionPreviewPath,
      descriptionHelpPath,
      labelsFetchPath,
      labelsManagePath,
      issuableType,
    },
    slots: {
      actions: `
        <button class="js-issuable-save">Submit issuable</button>
      `,
    },
    stubs: {
      MarkdownEditor,
    },
  });
};

describe('IssuableForm', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('methods', () => {
    describe('handleUpdateSelectedLabels', () => {
      it('sets provided `labels` param to prop `selectedLabels`', () => {
        const labels = [
          {
            id: 1,
            color: '#BADA55',
            text_color: '#ffffff',
            title: 'Documentation',
          },
        ];

        wrapper.vm.handleUpdateSelectedLabels(labels);

        expect(wrapper.vm.selectedLabels).toStrictEqual(labels);
      });
    });
  });

  describe('template', () => {
    it('renders issuable title input field', () => {
      const titleFieldEl = wrapper.findByTestId('issuable-title');

      expect(titleFieldEl.exists()).toBe(true);
      expect(titleFieldEl.find('label').text()).toBe('Title');
      expect(titleFieldEl.findComponent(GlFormInput).exists()).toBe(true);
      expect(titleFieldEl.findComponent(GlFormInput).attributes('placeholder')).toBe('Title');
      expect(titleFieldEl.findComponent(GlFormInput).attributes('autofocus')).toBe('true');
    });

    it('renders issuable description input field', () => {
      const descriptionFieldEl = wrapper.findByTestId('issuable-description');

      expect(descriptionFieldEl.exists()).toBe(true);
      expect(descriptionFieldEl.find('label').text()).toBe('Description');
      expect(descriptionFieldEl.findComponent(MarkdownEditor).exists()).toBe(true);
      expect(descriptionFieldEl.findComponent(MarkdownEditor).props()).toMatchObject({
        renderMarkdownPath: wrapper.vm.descriptionPreviewPath,
        markdownDocsPath: wrapper.vm.descriptionHelpPath,
        value: '',
        formFieldProps: {
          ariaLabel: 'Description',
          class: 'rspec-issuable-form-description',
          placeholder: 'Write a comment or drag your files here…',
          dataTestid: 'issuable-form-description-field',
          id: 'issuable-description',
          name: 'issuable-description',
        },
      });
    });

    it('renders issuable confidential checkbox', () => {
      const confidentialCheckboxEl = wrapper.findByTestId('issuable-confidential');
      expect(confidentialCheckboxEl.exists()).toBe(true);

      expect(confidentialCheckboxEl.findComponent(GlFormGroup).exists()).toBe(true);
      expect(confidentialCheckboxEl.findComponent(GlFormGroup).attributes('label')).toBe(
        'Confidentiality',
      );

      expect(confidentialCheckboxEl.findComponent(GlFormCheckbox).exists()).toBe(true);
      expect(confidentialCheckboxEl.findComponent(GlFormCheckbox).text()).toBe(
        'This test case is confidential and should only be visible to team members with at least the Planner role.',
      );
    });

    it('renders labels select field', () => {
      const labelsSelectEl = wrapper.findByTestId('issuable-labels');

      expect(labelsSelectEl.exists()).toBe(true);
      expect(labelsSelectEl.find('label').text()).toBe('Labels');
      expect(labelsSelectEl.findComponent(LabelsSelect).exists()).toBe(true);
      expect(labelsSelectEl.findComponent(LabelsSelect).props()).toMatchObject({
        allowLabelEdit: true,
        allowLabelCreate: true,
        allowMultiselect: true,
        allowScopedLabels: true,
        labelsFetchPath: wrapper.vm.labelsFetchPath,
        labelsManagePath: wrapper.vm.labelsManagePath,
        selectedLabels: wrapper.vm.selectedLabels,
        labelsListTitle: 'Select label',
        footerCreateLabelTitle: 'Create project label',
        footerManageLabelTitle: 'Manage project labels',
        variant: 'embedded',
      });
    });

    it('renders contents for slot "actions"', () => {
      const buttonEl = wrapper
        .findByTestId('issuable-create-actions')
        .find('button.js-issuable-save');

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.text()).toBe('Submit issuable');
    });
  });
});
