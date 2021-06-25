import { GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import IssuableForm from '~/issuable_create/components/issuable_form.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

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
      MarkdownField,
    },
  });
};

describe('IssuableForm', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
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
      expect(titleFieldEl.find(GlFormInput).exists()).toBe(true);
      expect(titleFieldEl.find(GlFormInput).attributes('placeholder')).toBe('Title');
      expect(titleFieldEl.find(GlFormInput).attributes('autofocus')).toBe('true');
    });

    it('renders issuable description input field', () => {
      const descriptionFieldEl = wrapper.find('[data-testid="issuable-description"]');

      expect(descriptionFieldEl.exists()).toBe(true);
      expect(descriptionFieldEl.find('label').text()).toBe('Description');
      expect(descriptionFieldEl.find(MarkdownField).exists()).toBe(true);
      expect(descriptionFieldEl.find(MarkdownField).props()).toMatchObject({
        markdownPreviewPath: wrapper.vm.descriptionPreviewPath,
        markdownDocsPath: wrapper.vm.descriptionHelpPath,
        addSpacingClasses: false,
        showSuggestPopover: true,
        textareaValue: '',
      });
      expect(descriptionFieldEl.find('textarea').exists()).toBe(true);
      expect(descriptionFieldEl.find('textarea').attributes('placeholder')).toBe(
        'Write a comment or drag your files here…',
      );
    });

    it('renders labels select field', () => {
      const labelsSelectEl = wrapper.find('[data-testid="issuable-labels"]');

      expect(labelsSelectEl.exists()).toBe(true);
      expect(labelsSelectEl.find('label').text()).toBe('Labels');
      expect(labelsSelectEl.find(LabelsSelect).exists()).toBe(true);
      expect(labelsSelectEl.find(LabelsSelect).props()).toMatchObject({
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
