import { GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import IssuableForm from '~/vue_shared/issuable/create/components/issuable_form.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import LabelsSelect from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';
import { __ } from '~/locale';

const createComponent = ({
  descriptionPreviewPath = '/gitlab-org/gitlab-shell/preview_markdown',
  descriptionHelpPath = '/help/user/markdown',
  labelsFetchPath = '/gitlab-org/gitlab-shell/-/labels.json',
  labelsManagePath = '/gitlab-org/gitlab-shell/-/labels',
} = {}) => {
  return shallowMount(IssuableForm, {
    propsData: {
      descriptionPreviewPath,
      descriptionHelpPath,
      labelsFetchPath,
      labelsManagePath,
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

        expect(wrapper.vm.selectedLabels).toBe(labels);
      });
    });
  });

  describe('template', () => {
    it('renders issuable title input field', () => {
      const titleFieldEl = wrapper.find('[data-testid="issuable-title"]');

      expect(titleFieldEl.exists()).toBe(true);
      expect(titleFieldEl.find('label').text()).toBe('Title');
      expect(titleFieldEl.findComponent(GlFormInput).exists()).toBe(true);
      expect(titleFieldEl.findComponent(GlFormInput).attributes('placeholder')).toBe('Title');
      expect(titleFieldEl.findComponent(GlFormInput).attributes('autofocus')).toBe('true');
    });

    it('renders issuable description input field', () => {
      const descriptionFieldEl = wrapper.find('[data-testid="issuable-description"]');

      expect(descriptionFieldEl.exists()).toBe(true);
      expect(descriptionFieldEl.find('label').text()).toBe('Description');
      expect(descriptionFieldEl.findComponent(MarkdownEditor).exists()).toBe(true);
      expect(descriptionFieldEl.findComponent(MarkdownEditor).props()).toMatchObject({
        renderMarkdownPath: wrapper.vm.descriptionPreviewPath,
        markdownDocsPath: wrapper.vm.descriptionHelpPath,
        value: '',
        formFieldProps: {
          ariaLabel: __('Description'),
          class: 'rspec-issuable-form-description',
          placeholder: __('Write a comment or drag your files here…'),
          dataTestid: 'issuable-form-description-field',
          id: 'issuable-description',
          name: 'issuable-description',
        },
      });
    });

    it('renders labels select field', () => {
      const labelsSelectEl = wrapper.find('[data-testid="issuable-labels"]');

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
        .find('[data-testid="issuable-create-actions"]')
        .find('button.js-issuable-save');

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.text()).toBe('Submit issuable');
    });
  });
});
